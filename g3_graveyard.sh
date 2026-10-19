#!/bin/bash
# g3_graveyard.sh — G3: look for CORPSES, not competitors
#
# Spec: 2026-08-15.
#
# Why it exists: G3 is the most telling gate and the only one without a tool.
# Three times it came back empty, and the fourth time, on 2026-08-15, it killed
# the best candidate of the day by hand — in the last minute instead of the
# first. A dead competitor tells you more than a live one, because it tells
# you the MODE OF FAILURE instead of a sales story.
#
# ── WHAT THE API ACTUALLY DOES (measured 2026-08-15, not assumed) ──
#   q=                     → HTTP 400, "Unknown query parameter: 'q'"
#   title= without subreddit → HTTP 400, "requires one of: author, subreddit"
#   title=shutting%20down  → HTTP 422 Timeout. MULTI-WORD TERMS ARE TOO EXPENSIVE.
#   selftext=failed        → HTTP 422 Timeout. TOO-COMMON WORDS ARE TOO EXPENSIVE.
#   subreddit=SaaS,Entrepreneur&selftext=X → HTTP 200 and ZERO RESULTS,
#       while each subreddit on its own returns 10. COMMAS SILENTLY RETURN EMPTY —
#       a failure dressed up as a valid empty result. Hence one sub per call.
#
# ── WHY TWO DIRECTIONS (and why the first version gave a FALSE NEGATIVE) ──
# The first version searched for DEATH WORDS and then filtered locally for the
# niche. Test on DipJar, which is known to have died on 11 Feb 2025:
# it fetched 606 posts with death words and NONE mentioned DipJar.
# A false negative on a tool known to be dead — exactly what G3 must
# never do.
#
# Cause: searching in the wrong direction. A PRODUCT NAME IS RARE AND CHEAP,
# a death word is common and expensive. `selftext=dipjar` returns 4 posts going
# back to 2019 in ONE call, among them "DipJar has ceased operations" dated
# 14 Feb 2025.
#
# And a second lesson from the same test: the phrase in that post is
# "ceased operations", which was on NO list of death words. That is why the
# phrase list is LOCAL and generous — locally a phrase is free, on the server
# it is a 422.
#
#   DIRECTION A (default, if the niche is one word): search the NAME, filter death locally
#   DIRECTION B (required for a multi-word niche):   search a DEATH WORD, filter the name
#
# Usage:
#   ./g3_graveyard.sh "dipjar"
#   ./g3_graveyard.sh "restaurant inventory"        # direction B only
#   ./g3_graveyard.sh --deep "veevart"              # both directions
#   SUBS="SaaS nonprofit msp" ./g3_graveyard.sh "connectwise"

set -euo pipefail

API="https://arctic-shift.photon-reddit.com/api/posts/search"
UA="gauntlet-research/1.0 (personal research)"
PAUSE=2
LIMIT=100

SUBS="${SUBS:-SaaS Entrepreneur startups nonprofit}"

# SINGLE WORDS, for the SERVER. Too-common ones ("failed", "closing") return 422.
DEATH_WORDS="${DEATH_WORDS:-shutting sunsetting shutdown discontinued}"

# PHRASES, for the LOCAL filter. Here they are free, so they are generous.
# "ceased operations" is here because that exact phrase killed the first
# version of this script on 2026-08-15 — DipJar's death post used it.
DEATH_RE='(cease[ds]? operat|shut(ting|s)? down|shut down|shutdown|sunset|winding down|wind[- ]down|no longer (be )?(available|supported|operat|in business)|out of business|closing (our |its |the )?(doors|shop)|end of life|\bEOL\b|discontinu|post[- ]?mortem|we (are|re) done|final day|acquired by|acqui[- ]?hire|went under|folded|dead|RIP\b)'

DEEP=0
if [ "${1:-}" = "--deep" ]; then DEEP=1; shift; fi

NICHE="${1:-}"
if [ -z "$NICHE" ]; then
  echo "ERROR: missing niche or tool name." >&2
  echo "Usage: $0 [--deep] \"<niche or tool>\"" >&2
  echo "  example: $0 \"dipjar\"" >&2
  echo "  example: $0 \"restaurant inventory\"" >&2
  exit 1
fi
command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }

case "$SUBS" in
  *,*) echo "ERROR: SUBS must not contain commas." >&2
       echo "  subreddit=A,B returns HTTP 200 and ZERO results, even though each works on its own." >&2
       echo "  Use spaces: SUBS=\"SaaS Entrepreneur\"" >&2
       exit 1 ;;
esac

# one word → direction A is possible. Several words → direction B only.
case "$NICHE" in
  *[[:space:]]*) SINGLE_WORD=0 ;;
  *)             SINGLE_WORD=1 ;;
esac

uri() { jq -rn --arg x "$1" '$x|@uri'; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "[]" > "$TMP/all.json"

CALLS=0; SUCCEEDED=0
UNCHECKED=""   # combinations the API could not handle — they are NOT "no corpses"

# fetch <sub> <parameter> <value> <label>
fetch() {
  local sub="$1" param="$2" val="$3" label="$4" code n
  sleep "$PAUSE"
  CALLS=$((CALLS+1))
  local url="$API?subreddit=$(uri "$sub")&${param}=$(uri "$val")&limit=$LIMIT&sort=desc"

  code=$(curl -sS -A "$UA" -m 60 -o "$TMP/r.json" -w "%{http_code}" "$url" 2>"$TMP/curl.err") || {
    echo "ERROR: curl failed on $label." >&2
    echo "  $(head -c 200 "$TMP/curl.err")" >&2
    exit 1
  }

  # 422 means the archive rejected this query as too expensive. That is NOT
  # the absence of corpses, it is an angle not looked at. The difference between
  # "no corpses" and "I did not look" is the whole value of this gate.
  if [ "$code" = "422" ]; then
    echo "  ⚠️ $label — API overloaded (422), UNCHECKED" >&2
    UNCHECKED="${UNCHECKED}${label} "
    return 0
  fi
  if [ "$code" != "200" ]; then
    echo "ERROR: HTTP $code on $label." >&2
    echo "  $(head -c 300 "$TMP/r.json")" >&2
    exit 1
  fi
  if grep -qi '"error"' "$TMP/r.json"; then
    echo "ERROR: API returned an error with HTTP 200 ($label)." >&2
    echo "  $(jq -r '.error // "unknown"' "$TMP/r.json")" >&2
    exit 1
  fi
  if ! jq -e 'has("data")' "$TMP/r.json" >/dev/null; then
    echo "ERROR: response has no .data field ($label)." >&2
    echo "  $(head -c 300 "$TMP/r.json")" >&2
    exit 1
  fi

  n=$(jq '(.data // []) | length' "$TMP/r.json")
  SUCCEEDED=$((SUCCEEDED+1))
  [ "$n" -gt 0 ] && echo "  $label → $n" >&2

  jq --arg sub "$sub" '[ (.data // [])[]
      | { date: (.created_utc | strftime("%Y-%m-%d")),
          subreddit: (.subreddit // $sub),
          title: (.title // ""),
          text: ((.title // "") + " " + (.selftext // "")),
          score: (.score // 0),
          permalink: (.permalink // "") } ]' \
    "$TMP/r.json" > "$TMP/new.json"
  jq -s 'add' "$TMP/all.json" "$TMP/new.json" > "$TMP/m.json"
  mv "$TMP/m.json" "$TMP/all.json"
}

echo "═══ G3 graveyard: \"$NICHE\" ═══" >&2
echo "    subreddits: $SUBS" >&2
if [ "$SINGLE_WORD" -eq 1 ]; then
  echo "    direction A: searching the name, filtering death locally" >&2
  [ "$DEEP" -eq 1 ] && echo "    direction B: also death words ($DEATH_WORDS)" >&2
else
  echo "    niche is multi-word → direction B only ($DEATH_WORDS)" >&2
  echo "    (the server cannot handle multi-word terms, it returns 422)" >&2
fi
echo >&2

# ── DIRECTION A ─────────────────────────────────────────────────────
if [ "$SINGLE_WORD" -eq 1 ]; then
  for SUB in $SUBS; do
    fetch "$SUB" title    "$NICHE" "r/$SUB title=$NICHE"
    fetch "$SUB" selftext "$NICHE" "r/$SUB selftext=$NICHE"
  done
fi

# ── DIRECTION B ─────────────────────────────────────────────────────
if [ "$SINGLE_WORD" -eq 0 ] || [ "$DEEP" -eq 1 ]; then
  for SUB in $SUBS; do
    for WORD in $DEATH_WORDS; do
      fetch "$SUB" selftext "$WORD" "r/$SUB × $WORD"
    done
  done
fi

RAW=$(jq 'length' "$TMP/all.json")

# local filter on the niche — multi-word is cheap here, it never goes to the server
jq --arg n "$NICHE" '[ .[] | select(.text | test($n; "i")) ]
  | unique_by(.permalink) | sort_by(.date) | reverse' \
  "$TMP/all.json" > "$TMP/mentions.json"
MENTIONS=$(jq 'length' "$TMP/mentions.json")

jq --arg s "$DEATH_RE" '[ .[] | select(.text | test($s; "i")) ]' \
   "$TMP/mentions.json" > "$TMP/corpses.json"
CORPSES=$(jq 'length' "$TMP/corpses.json")

echo >&2
echo "═══════════════════════════════════════════════" >&2
echo "$CALLS calls · $SUCCEEDED succeeded · $RAW posts fetched" >&2
echo "$MENTIONS mention \"$NICHE\" · of those $CORPSES with death language" >&2
echo >&2

if [ "$CORPSES" -eq 0 ]; then
  echo "No evidence of death found for this niche/tool."
  echo
  if [ "$MENTIONS" -gt 0 ]; then
    echo "BUT $MENTIONS posts mention the niche without death language — that is material for G4,"
    echo "not for G3. The competitors are therefore ALIVE, which is a finding in itself:"
    echo
    jq -r '.[] | "[\(.date)] | r/\(.subreddit) | \(.title)\n              reddit.com\(.permalink)"' \
      "$TMP/mentions.json" | head -30
    echo
  fi
  if [ -n "$UNCHECKED" ]; then
    echo "⚠️ THE SEARCH WAS NOT COMPLETE. Unchecked: $UNCHECKED"
    echo "   This is NOT an empty graveyard, it is an unfinished check. Run it again."
  else
    echo "By the skill's rule, an empty graveyard NEXT TO an empty set of competitors"
    echo "is a failed search, not a finding. Before you record it as an outcome:"
    echo "  · try another name (synonym, abbreviation, category name)"
    echo "  · add the industry's subreddits: SUBS=\"SaaS <industry>\" $0 \"$NICHE\""
    [ "$SINGLE_WORD" -eq 1 ] && [ "$DEEP" -eq 0 ] && \
      echo "  · run --deep to add direction B as well"
    echo "  · remember this covers ONLY Reddit. For DEAD DOMAINS run:"
    echo "      ./g34_wayback.sh --quick <domain>"
    echo "    A dead domain disappears from Google, but NOT from the archive — so"
    echo "    that is often the only place where the corpse still exists."
    echo "  · Product Hunt stays manual"
  fi
  exit 0
fi

echo "═══ CORPSES ═══"
jq -r '.[] | "[\(.date)] | r/\(.subreddit) | \(.title)\n              reddit.com\(.permalink)"' "$TMP/corpses.json"

if [ "$MENTIONS" -gt "$CORPSES" ]; then
  echo
  echo "═══ other mentions (live competitors, material for G4) ═══"
  jq -r --arg s "$DEATH_RE" '.[] | select((.text | test($s;"i")) | not)
     | "[\(.date)] | r/\(.subreddit) | \(.title)"' "$TMP/mentions.json" | head -20
fi

echo
echo "Read the corpses by CAUSE of failure, not by count. G3 kills when"
echo "several independent attempts died for the SAME reason and nothing has"
echo "changed structurally since. \"I will execute better\" is not a change."
# WARNING: `[ -n "$X" ] && { ... }` as the LAST command of a script returns exit code 1
# when X is empty — so a successful run without unchecked combinations
# would look like a crashed script. Hence if, and an explicit exit 0.
if [ -n "$UNCHECKED" ]; then
  echo
  echo "⚠️ Unchecked (422): $UNCHECKED"
fi
exit 0
