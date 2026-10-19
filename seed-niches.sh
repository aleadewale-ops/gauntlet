#!/bin/bash
# seed-niches.sh — random dictionary word → niche suggestions → VERIFIED subreddit
#
# Why it exists: a list of niches typed out by a model carries the model's
# biases. A random dictionary word breaks that chain. Idea: 2026-08-15.
#
# Fixes against the original:
#   1. macOS has no `shuf`  → `sort -R | head -1`
#   2. every suggested subreddit is checked against the archive. Models invent
#      subreddits. On 2026-08-15 r/fitnessbusiness returned 0 posts and the
#      industry looked empty, when only the name was wrong.
#   3. curl and jq had `2>/dev/null`. A network failure came out as n=0, i.e.
#      "subreddit does not exist" — a false death of the niche. Now it returns ERROR.
#
# ── WHY THIS SCRIPT CALLS NO MODEL ───────────────────────────────────
# Decision, 2026-08-15: NO API key in bash scripts.
# A key that lives in a script sooner or later ends up in a commit, and the
# calls are billed separately from what you already pay for. Claude Code IS
# already an authenticated agent. So this script gives the seed and the
# instruction, and the main model derives the niches.
# The seed is what breaks the bias, not the model that reads it.
# ─────────────────────────────────────────────────────────────────────
#
# Usage:  ./seed-niches.sh [number_of_seeds]
#         ./seed-niches.sh --check <subreddit> [...]

set -u
DICT=/usr/share/dict/words
N="${1:-1}"
ARCTIC="https://arctic-shift.photon-reddit.com/api/posts/search"
UA="gauntlet-research/1.0 (personal research)"

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [number_of_seeds]"
  echo "       $0 --check <subreddit> [...]"
  echo
  echo "  Without --check: prints N random dictionary seeds with the instruction"
  echo "  for deriving niches from them (default 1). No model is called."
  echo "  --check: verifies that each subreddit exists and has content."
  exit 0
fi

[ -f "$DICT" ] || { echo "No dictionary at $DICT" >&2; exit 1; }

# --- check whether the subreddit exists at all and has content ---
#
# WATCH OUT: there were two `2>/dev/null` here, on curl and on jq. A network
# failure or an archive timeout came out as n=0, which read as "subreddit does
# not exist" and the niche was discarded. A false death — exactly what this
# step is meant to prevent. It returns "ERROR", not 0, and the caller tells
# the two apart.
check_sub() {
  local sub="$1" body code
  body=$(curl -sS -m 20 -A "$UA" -w '\n%{http_code}' "$ARCTIC?subreddit=${sub}&limit=100") || {
    echo "ERROR"; return 0
  }
  code=$(echo "$body" | tail -1)
  body=$(echo "$body" | sed '$d')
  [ "$code" != "200" ] && { echo "ERROR"; return 0; }
  # the archive returns a timeout WITH STATUS 200 — without this it looks like an empty subreddit
  echo "$body" | grep -qi '"error"' && { echo "ERROR"; return 0; }
  echo "$body" | jq -r '(.data // []) | length' 2>/dev/null || echo "ERROR"
}

# --- mode: only check subreddits, no seed ---
#     bash seed-niches.sh --check sub1 sub2 sub3 ...
if [ "${1:-}" = "--check" ]; then
  shift
  [ $# -eq 0 ] && { echo "Usage: seed-niches.sh --check <subreddit> [...]" >&2; exit 1; }
  for s in "$@"; do
    c=$(check_sub "$s")
    if   [ "$c" = "ERROR" ]; then m="✖ QUERY FAILED — this is NOT 'does not exist', try again"; c="?"
    elif [ "$c" -ge 25 ];    then m="✅ usable"
    elif [ "$c" -gt 0 ];     then m="⚠️ too thin"
    else                          m="⛔ does not exist or is empty"; fi
    printf "r/%-26s %4s posts  %s\n" "$s" "$c" "$m"
  done
  exit 0
fi

for i in $(seq 1 "$N"); do
  SEED=$(grep -E '^[a-z]{4,8}$' "$DICT" | sort -R | head -1)
  echo "════════════════════════════════════════════"
  echo "SEED: $SEED"
  echo "════════════════════════════════════════════"

  # Decision, 2026-08-15: NO API key in bash scripts.
  # A key that lives in a script sooner or later ends up in a commit, and the
  # calls are billed separately from what you already pay for. Claude Code IS
  # already an authenticated agent, so this script is a pure fetcher: it gives
  # the seed, it does not think.
  cat <<END_PROMPT

→ From the seed "$SEED" derive 2 ultra-specific, profitable B2B niches or
  micro-professions. The link to the word can be semantic, phonetic or
  associative. Be bold — that is the only point of a random seed.

  Avoid generic niches: not "business", not "small business", not
  "entrepreneurs". You are looking for niche ones: msp, cabinetry, TheBrewery.

  For each niche suggest 2 or 3 subreddit candidates, never one,
  and VERIFY them. An invented name reads as "this industry has no pain",
  which is a false death of the niche:

     bash .claude/skills/gauntlet/seed-niches.sh --check <sub1> <sub2> ...
     bash .claude/skills/gauntlet/map-subreddit.sh <sub1> <sub2> ...

END_PROMPT
done
