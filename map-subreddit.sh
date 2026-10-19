#!/bin/bash
# map-subreddit.sh — hunt step 2: map a niche to a VERIFIED subreddit
#
# Idea: 2026-08-15. The model invents subreddits, and an invented name
# reads as "this industry has no pain", which is a false death of the niche.
#
# Why it does not use reddit.com/r/X/about.json like the original script:
#   Reddit returns 403 on this machine, checked 2026-08-15 on three subreddits.
#   The source is therefore arctic-shift, which besides the member count also returns the archive volume.
#
# Fixes against the original:
#   1. reddit about.json → 403. Replaced with arctic-shift subreddits/search
#   2. a threshold on members alone throws away useful sources: r/selfstorage has 4,870 members
#      and 3,192 posts. The sieve is now DOUBLE — members AND archive volume
#   3. the original took the first hit with `break`; now it scores all and sorts
#   4. `sleep 1` was after `break`/`continue`, so it never ran
#   5. adds subreddit_type — "restricted" means a closed door, worth knowing
#
# Usage:  ./map-subreddit.sh sub1 sub2 sub3 ...
#         ./map-subreddit.sh --min-members 3000 --min-posts 500 sub1 sub2

set -u
API="https://arctic-shift.photon-reddit.com/api/subreddits/search"
UA="gauntlet-research/1.0 (personal research)"
MIN_MEMBERS=3000    # lower than the original 5000, because archive volume says more
MIN_POSTS=500       # without this even a large community is useless for harvesting

while [ $# -gt 0 ]; do
  case "$1" in
    --min-members) MIN_MEMBERS="$2"; shift 2 ;;
    --min-posts)   MIN_POSTS="$2";   shift 2 ;;
    *) break ;;
  esac
done

[ $# -eq 0 ] && { echo "Usage: map-subreddit.sh [--min-members N] [--min-posts N] <sub> [...]" >&2; exit 1; }

TMP=$(mktemp) || exit 1
trap 'rm -f "$TMP"' EXIT

printf "%-26s %10s %8s %9s %-11s %s\n" "SUBREDDIT" "MEMBERS" "POSTS" "COMMENTS" "TYPE" "RESULT"
printf '%.0s─' {1..92}; echo

for SUB in "$@"; do
  # WARNING: there used to be `2>/dev/null` on curl here. A network failure left $TMP
  # empty, jq returned MISSING and the output reported "DOES NOT EXIST — the name is
  # invented". A false death of the niche, which this script exists to prevent.
  CERR=$(mktemp)
  HTTP=$(curl -sS -m 25 -A "$UA" -o "$TMP" -w "%{http_code}" "$API?subreddit_prefix=${SUB}&limit=10" 2>"$CERR") || {
    printf "%-26s %10s %8s %9s %-11s %s\n" "r/$SUB" "?" "?" "?" "?" "✖ CURL — $(head -c 40 "$CERR")"
    rm -f "$CERR"; sleep 0.6; continue
  }
  rm -f "$CERR"
  if [ "$HTTP" != "200" ]; then
    printf "%-26s %10s %8s %9s %-11s %s\n" "r/$SUB" "?" "?" "?" "?" "✖ HTTP $HTTP — NOT a finding, try again"
    sleep 0.6; continue
  fi
  # the archive returns a timeout with status 200 — otherwise it looks like a non-existent subreddit
  if grep -qi '"error"' "$TMP"; then
    printf "%-26s %10s %8s %9s %-11s %s\n" "r/$SUB" "?" "?" "?" "?" "✖ API error with HTTP 200 — try again"
    sleep 0.6; continue
  fi

  # WARNING: in jq, [a, b|tostring] pipes the WHOLE array through tostring.
  # Every tostring needs its own parentheses. On 2026-08-15 this bug reported all
  # subreddits as non-existent — exactly the false death this script
  # prevents.
  ERRF=$(mktemp)
  ROW=$(jq -r --arg q "$SUB" '
    (.data // [])
    | map(select((.display_name|ascii_downcase) == ($q|ascii_downcase)))
    | .[0]
    | if . == null then "MISSING"
      else [ .display_name,
             ((.subscribers // 0)|tostring),
             ((._meta.num_posts // 0)|tostring),
             ((._meta.num_comments // 0)|tostring),
             (.subreddit_type // "?") ] | join("\t")
      end' "$TMP" 2>"$ERRF")
  JQERR=$(cat "$ERRF"); rm -f "$ERRF"

  # NEVER silently turn errors into "does not exist"
  if [ -n "$JQERR" ]; then
    printf "%-26s %10s %8s %9s %-11s %s\n" "r/$SUB" "?" "?" "?" "?" "✖ ERROR — ${JQERR:0:44}"
    sleep 0.6
    continue
  fi

  if [ "$ROW" = "MISSING" ] || [ -z "$ROW" ]; then
    printf "%-26s %10s %8s %9s %-11s %s\n" "r/$SUB" "-" "-" "-" "-" "⛔ DOES NOT EXIST — the name is invented"
    sleep 0.6
    continue
  fi

  NAME=$(echo "$ROW" | cut -f1); SUBS=$(echo "$ROW" | cut -f2)
  POSTS=$(echo "$ROW" | cut -f3); COMS=$(echo "$ROW" | cut -f4); TYPE=$(echo "$ROW" | cut -f5)

  if   [ "$SUBS"  -lt "$MIN_MEMBERS" ] && [ "$POSTS" -lt "$MIN_POSTS" ]; then RESULT="⛔ too small on both"
  elif [ "$POSTS" -lt "$MIN_POSTS" ];   then RESULT="⚠️ many members, few posts — dead community"
  elif [ "$SUBS"  -lt "$MIN_MEMBERS" ]; then RESULT="✅ small but live archive — usable"
  else RESULT="✅ usable"
  fi
  [ "$TYPE" = "restricted" ] && RESULT="$RESULT · closed to posting"
  [ "$TYPE" = "private" ]    && RESULT="⛔ private — unreachable"

  printf "%-26s %10s %8s %9s %-11s %s\n" "r/$NAME" "$SUBS" "$POSTS" "$COMS" "$TYPE" "$RESULT"
  sleep 0.6
done

echo
echo "Take the one with the most POSTS, not the most members. For harvesting, the archive is what counts."
echo "If all are ⛔, the niche has no reachable source. That is a finding, not a failure —"
echo "record it and go back to H0 for a new seed."
