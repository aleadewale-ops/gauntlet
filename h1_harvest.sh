#!/bin/bash
# h1_harvest.sh — H1 production harvest from arctic-shift
#
# Spec: 2026-08-15.
#   ratio 1:3 · sleep 2 between every call · normalised flat JSON array
#   · strict mode without 2>/dev/null · output to harvest_<subreddit>.json
#
# Why comments: complaints live there. Measured 2026-08-15 on four
# subreddits — there are 5.3x to 17.6x more comments than usable posts.
# r/travelagents had 19 posts and 335 comments; the posts gave ZERO hits,
# the comments gave a finding. Without them the subreddit would look dead.
#
# Why NOT N+1: `comments/search?subreddit=X` works at subreddit level.
# 100 comments = 1 call, not 101.
#
# Usage:  ./h1_harvest.sh <subreddit>

set -euo pipefail

API="https://arctic-shift.photon-reddit.com/api"
UA="gauntlet-research/1.0 (personal research)"
PAUSE=2                     # mandatory, no exceptions — arctic-shift times out quickly
COMMENT_PAGES=3             # ratio 1:3

SUB="${1:-}"
if [ -z "$SUB" ]; then
  echo "ERROR: missing subreddit name." >&2
  echo "Usage: $0 <subreddit>" >&2
  exit 1
fi
command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }

OUTPUT="harvest_${SUB}.json"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ─────────────────────────────────────────────────────────────────────
# api_call <url> <label> <output_file>
#
# STRICT: no 2>/dev/null anywhere. Every error is visible and stops the script.
# Three failure modes that all look like an "empty result" if you
# don't catch them — and all three actually happened on 2026-08-15:
#   1. HTTP != 200
#   2. the body contains {"error":"Timeout. Maybe slow down a bit"} WITH HTTP 200
#   3. the response is not valid JSON or has no .data
# ─────────────────────────────────────────────────────────────────────
api_call() {
  local url="$1" label="$2" out="$3"
  local code

  echo "  → $label" >&2
  code=$(curl -sS -o "$out" -w "%{http_code}" -m 60 -A "$UA" "$url") || {
    echo "ERROR [$label]: curl failed (exit code $?)." >&2
    exit 1
  }

  if [ "$code" != "200" ]; then
    echo "ERROR [$label]: HTTP $code" >&2
    echo "  response body: $(head -c 300 "$out")" >&2
    exit 1
  fi

  # the timeout arrives with status 200 and is therefore the sneakiest
  if grep -qi '"error"' "$out"; then
    echo "ERROR [$label]: API returned an error with HTTP 200." >&2
    echo "  $(jq -r '.error // "unknown"' "$out")" >&2
    exit 1
  fi

  if ! jq -e 'has("data")' "$out" >/dev/null; then
    echo "ERROR [$label]: response has no .data field or is not valid JSON." >&2
    echo "  $(head -c 300 "$out")" >&2
    exit 1
  fi
}

echo "═══ harvest r/$SUB ═══" >&2

# ─────────────────── 1 call: posts ───────────────────
api_call "$API/posts/search?subreddit=${SUB}&limit=100&sort=desc" \
         "posts (1/1)" "$TMPDIR/posts.json"

# title AND text merged into one body field, so H2 has something to work with
jq '[ (.data // [])[]
      | select((.selftext // "") != "[removed]" and (.selftext // "") != "[deleted]")
      | { id: .id,
          type: "post",
          body: ((.title // "") + " \n " + (.selftext // "")),
          created_utc: .created_utc,
          score: (.score // 0),
          permalink: (.permalink // "") } ]' \
   "$TMPDIR/posts.json" > "$TMPDIR/norm_posts.json"

N_POSTS=$(jq 'length' "$TMPDIR/norm_posts.json")
echo "    $N_POSTS posts" >&2

# ─────────────────── 3 calls: comments, paginated via before ───────────────────
BEFORE=""
: > "$TMPDIR/norm_comments.json"
echo "[]" > "$TMPDIR/norm_comments.json"

for i in $(seq 1 "$COMMENT_PAGES"); do
  sleep "$PAUSE"

  URL="$API/comments/search?subreddit=${SUB}&limit=100&sort=desc"
  if [ -n "$BEFORE" ]; then URL="${URL}&before=${BEFORE}"; fi

  api_call "$URL" "comments ($i/$COMMENT_PAGES)" "$TMPDIR/c$i.json"

  N=$(jq '(.data // []) | length' "$TMPDIR/c$i.json")
  if [ "$N" -eq 0 ]; then
    echo "    page $i empty — archive exhausted, ending pagination" >&2
    break
  fi

  jq '[ (.data // [])[]
        | select((.body // "") != "[removed]" and (.body // "") != "[deleted]" and (.body // "") != "")
        | { id: .id,
            type: "comment",
            body: (.body // ""),
            created_utc: .created_utc,
            score: (.score // 0),
            permalink: (.permalink // "") } ]' \
     "$TMPDIR/c$i.json" > "$TMPDIR/norm_c$i.json"

  jq -s 'add' "$TMPDIR/norm_comments.json" "$TMPDIR/norm_c$i.json" > "$TMPDIR/merged.json"
  mv "$TMPDIR/merged.json" "$TMPDIR/norm_comments.json"

  # the oldest timestamp on this page becomes the boundary for the next one
  BEFORE=$(jq '[(.data // [])[].created_utc] | min' "$TMPDIR/c$i.json")
  if [ "$BEFORE" = "null" ]; then
    echo "    no timestamp for pagination — stopping" >&2
    break
  fi

  echo "    page $i: $N comments, next boundary before=$BEFORE" >&2
done

N_COMMENTS=$(jq 'length' "$TMPDIR/norm_comments.json")

# ─────────────────── merge into one flat array ───────────────────
# WARNING: build into a TEMPORARY file and move it into place only on success.
# Earlier the script wrote straight to $OUTPUT and, with 0 units, left behind
# an empty harvest_<sub>.json. The next `jq -s add harvest_*.json` would silently
# pick it up and the empty harvest would merge into the corpus as valid data.
# No file = no harvest. That has to be visible.
jq -s 'add | sort_by(.created_utc) | reverse' \
   "$TMPDIR/norm_posts.json" "$TMPDIR/norm_comments.json" > "$TMPDIR/final.json"

TOTAL=$(jq 'length' "$TMPDIR/final.json")

if [ "$TOTAL" -eq 0 ]; then
  echo "ERROR: the harvest returned 0 units. Check the subreddit name with map-subreddit.sh." >&2
  echo "  I did NOT create $OUTPUT — an empty harvest is not a corpus." >&2
  exit 1
fi

mv "$TMPDIR/final.json" "$OUTPUT"

echo "═══════════════════════════════════════" >&2
echo "r/$SUB: $N_POSTS posts + $N_COMMENTS comments = $TOTAL units" >&2
echo "saved to $OUTPUT" >&2
