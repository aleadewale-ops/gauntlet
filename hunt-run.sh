#!/bin/bash
# hunt-run.sh — orchestration: H1 harvest → merge → H2 filter → H4 ranking
#
# Spec: 2026-08-15.
#
# Why it exists: until then every step ran by hand and files were carried
# between them by hand. That is not a pipeline, that is a pipeline in your
# head. Three seams between the scripts only broke once they were connected,
# and each one looked like a valid empty result.
#
# ── FOUR DEVIATIONS FROM THE ORIGINAL SPEC, and why ──
#
# 1. NOT `jq -s 'add' harvest_*.json`. The glob also picks up harvests from
#    PREVIOUS runs left in the directory and silently merges them in. The
#    result is a corpus that contains industries you did not search for, and
#    nothing shows it. It merges an EXPLICIT list of files created by THIS run.
#
# 2. It does NOT delete `harvest_*.json`. `prices.sh` searches the harvested
#    corpus for prices and `h1` is the only one that can make it — deleting
#    it would kill the second price source in H3. Raw harvests go to
#    `archive/<date_time>/`.
#
# 3. `set -e` is on, but the harvest runs inside a conditional, because one
#    failed subreddit must leave the others alive. Conditionals are not
#    subject to `-e`, so both hold at once.
#
# 4. Besides the merged corpus it keeps NUMBERS PER SUBREDDIT. In August 2026
#    r/msp gave 11 matches and r/escaperooms 0 out of 381 — and that zero was
#    a finding in itself (a players' community, not an operators' one). In the
#    merged corpus it would have vanished without a trace.
#
# Usage:
#   ./hunt-run.sh msp TheBrewery escaperooms dairyfarming
#   ./hunt-run.sh --window 220 --top 25 msp TheBrewery

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINDOW=160
TOP=15

usage() {
  echo "Usage: $0 [--window N] [--top N] <sub1> [sub2 ...]" >&2
  echo "  example: $0 msp TheBrewery escaperooms" >&2
  echo >&2
  echo "Check the names first, otherwise you read an invented name as a dead industry:" >&2
  echo "  $DIR/map-subreddit.sh <sub1> <sub2> ..." >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --window) WINDOW="$2"; shift 2 ;;
    --top)    TOP="$2";    shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "ERROR: unknown flag $1" >&2; exit 1 ;;
    *) break ;;
  esac
done

if [ $# -eq 0 ]; then
  echo "ERROR: at least one subreddit is missing." >&2
  echo >&2
  usage
  exit 1
fi

command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }
for s in h1_harvest.sh h2_filter.sh h4_rank.sh; do
  [ -x "$DIR/$s" ] || { echo "ERROR: $DIR/$s is missing or not executable." >&2; exit 1; }
done

TS=$(date +%Y-%m-%d_%H%M%S)
ARCHIVE="archive/$TS"
MASTER="master_corpus.json"
FILTERED="filtered_${TS}.jsonl"

SUCCEEDED=()       # files created by THIS run — no glob
FAILED=()
declare -a REPORT

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  HUNT $TS"
echo "║  subreddits: $*"
echo "╚═══════════════════════════════════════════════════════╝"

# ─────────────── H1: harvest ───────────────
echo
echo "▶ H1 — harvest ($# subreddits)"
for SUB in "$@"; do
  # conditional, so `set -e` does not stop the whole hunt here
  if bash "$DIR/h1_harvest.sh" "$SUB" 2>&1 | sed 's/^/    /'; then
    if [ -s "harvest_${SUB}.json" ]; then
      SUCCEEDED+=("harvest_${SUB}.json")
    else
      echo "    ⚠️ r/$SUB: the script succeeded, but there is no file — treating it as a failure" >&2
      FAILED+=("$SUB")
    fi
  else
    echo "    ✖ r/$SUB: HARVEST FAILED, moving on to the next one" >&2
    FAILED+=("$SUB")
  fi
done

if [ ${#SUCCEEDED[@]} -eq 0 ]; then
  echo >&2
  echo "ERROR: no harvest succeeded. Check the names with map-subreddit.sh." >&2
  exit 1
fi

# ─────────────── merge ───────────────
echo
echo "▶ merging ${#SUCCEEDED[@]} harvests → $MASTER"
if ! jq -s 'add' "${SUCCEEDED[@]}" > "$MASTER" 2>"$MASTER.err"; then
  echo "ERROR while merging: $(head -c 300 "$MASTER.err")" >&2
  rm -f "$MASTER.err"; exit 1
fi
rm -f "$MASTER.err"
TOTAL=$(jq 'length' "$MASTER")
[ "$TOTAL" -eq 0 ] && { echo "ERROR: the merged corpus has 0 items." >&2; exit 1; }
echo "    $TOTAL items"

# ─────────────── H2: filter, overall and per subreddit ───────────────
echo
echo "▶ H2 — filter, window $WINDOW characters"
# WATCH OUT: h2_filter writes matches to stdout and the summary to stderr. `2>&1`
# would pour both into the same file and the summary would land IN BETWEEN the
# matches, which breaks the JSONL for everything downstream. Keep them apart.
SUMMARY=$(mktemp)
bash "$DIR/h2_filter.sh" "$MASTER" "$WINDOW" > "$FILTERED" 2>"$SUMMARY" || {
  echo "ERROR: the filter failed: $(head -c 300 "$SUMMARY")" >&2
  rm -f "$SUMMARY"; exit 1; }
sed 's/^/    /' "$SUMMARY"; rm -f "$SUMMARY"
MATCHES=$(wc -l < "$FILTERED" | tr -d ' ')

echo
echo "▶ per subreddit"
for F in "${SUCCEEDED[@]}"; do
  SUB="${F#harvest_}"; SUB="${SUB%.json}"
  N=$(jq 'length' "$F")
  # we do not need the summary here, but do NOT throw it into /dev/null — a
  # failed filter would show up as "0 matches", i.e. as an industry without pain
  PERR=$(mktemp)
  if ! Z=$(bash "$DIR/h2_filter.sh" "$F" "$WINDOW" 2>"$PERR" | wc -l | tr -d ' '); then
    echo "ERROR: the filter failed on $F: $(head -c 200 "$PERR")" >&2
    rm -f "$PERR"; exit 1
  fi
  rm -f "$PERR"
  REPORT+=("$(printf '%-22s %5s items → %3s matches' "r/$SUB" "$N" "$Z")")
  printf '    %-22s %5s items → %3s matches%s\n' "r/$SUB" "$N" "$Z" \
    "$([ "$Z" -eq 0 ] && echo '   ⚠️ nothing — check whether this is the right community' || true)"
done

# ─────────────── H4: ranking ───────────────
echo
echo "▶ H4 — ranking, top $TOP"
if [ "$MATCHES" -eq 0 ]; then
  echo "    The filter returned no match out of $TOTAL items."
  echo "    That is not necessarily a finding. Check three things before you write it down:"
  echo "      · are these the right communities (operators, not users)"
  echo "      · $DIR/h2_validate.sh $MASTER   — is some stem silently rotting"
  echo "      · a wider window: $0 --window 260 $*"
else
  bash "$DIR/h4_rank.sh" "$FILTERED" "$TOP"
fi

# ─────────────── archive ───────────────
mkdir -p "$ARCHIVE"
mv "${SUCCEEDED[@]}" "$ARCHIVE/"

echo
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  DONE"
echo "╚═══════════════════════════════════════════════════════╝"
printf '  %-24s %s\n' "subreddits harvested:" "${#SUCCEEDED[@]} of $(( ${#SUCCEEDED[@]} + ${#FAILED[@]} ))"
printf '  %-24s %s\n' "items total:" "$TOTAL"
printf '  %-24s %s\n' "filter matches:" "$MATCHES"
printf '  %-24s %s\n' "merged corpus:" "$MASTER"
printf '  %-24s %s\n' "filtered:" "$FILTERED"
printf '  %-24s %s\n' "raw harvests:" "$ARCHIVE/"

if [ ${#FAILED[@]} -gt 0 ]; then
  echo
  echo "  ✖ FAILED AND NOT IN THE CORPUS: ${FAILED[*]}"
  echo "    These are not industries without pain, these are industries nobody looked at."
fi

echo
echo "  Next:"
echo "    $DIR/prices.sh $MASTER --scan          # what people pay"
echo "    $DIR/g3_graveyard.sh \"<tool>\"          # who tried this and died"
echo "    $DIR/h7_competitor_check.sh <url>      # official pricing page"
exit 0
