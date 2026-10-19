#!/bin/bash
# h2_validate.sh — checks whether any stem catches English by accident
#
# Why it exists: a dictionary without a validator rots quietly. Every new stem
# anyone adds can quietly double the noise. This script shows it in a second.
#
# Run it on EVERY stem you add. The corpus should be mostly English —
# that is where clashes show up.
#
# Usage:  ./h2_validate.sh <corpus.jsonl> [threshold]

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/_corpus.sh"
trap corpus_cleanup EXIT
CORPUS="${1:?Usage: h2_validate.sh <corpus.jsonl> [threshold]}"
THRESHOLD="${2:-3}"  # kept for compatibility, the measure is now the difference

# Without normalisation this script returned ALL ZEROS on an array — which
# looks like "no stem clashes", when in fact it read nothing.
# Now _corpus.sh handles that and fails loudly instead of silently.
corpus_normalize "$CORPUS"   # NOT inside $(...) — it sets globals
CORPUS="$CORPUS_FILE"
N=$CORPUS_N
echo "corpus: $N units"
echo "ℹ️ \\b removed N = the anchor already fixed the clash, the filter is safe."
echo "◐ BROAD = the stem catches >5% of the corpus, too general, works only in a pair."
echo "For REAL clashes look at the WHAT IT MATCHES column — if it shows words in the wrong"
echo "sense (spor→sport, lent→talent), lengthen the stem in the dictionary."
echo

for FILE in tech_stems.txt pain_stems.txt process_stems.txt shop_stems.txt; do
  echo "── $FILE ──"
  printf "%-16s %6s %6s  %s\n" "STEM" "FREE" "W/ \\b" "WHAT IT MATCHES"
  grep -v '^#' "$DIR/$FILE" | grep -v '^[[:space:]]*$' | while read -r s; do
    s=$(echo "$s" | sed 's/[[:space:]]*$//')
    # WARNING: there used to be `2>/dev/null` in three places here. A stem with a broken
    # regex (unbalanced parenthesis, trailing \) would report 0 hits and would be
    # read as "a clean stem with no clashes". An error dressed up as an empty
    # result — exactly what this pipeline forbids. Now it shows.
    ERR=$(corpus_tempfile)
    # jq prefixes "jq: error (at /var/folders/.../t.abc123:1): " — the path to the
    # temp file is junk to the reader and eats all the space in the column.
    jqerror() { tr '\n' ' ' < "$ERR" | sed 's/jq: error (at [^)]*): //g' | head -c 84; }
    a=$(jq -r --arg s "$s"    'select((.body!=null) and (.body|test($s;"i"))) | .id' "$CORPUS" 2>"$ERR" | wc -l | tr -d ' ')
    if [ -s "$ERR" ]; then
      printf "%-16s %6s %6s  %s\n" "$s" "?" "?" "✖ INVALID REGEX — $(jqerror)"
      continue
    fi
    b=$(jq -r --arg s "\\b$s" 'select((.body!=null) and (.body|test($s;"i"))) | .id' "$CORPUS" 2>"$ERR" | wc -l | tr -d ' ')
    if [ -s "$ERR" ]; then
      printf "%-16s %6s %6s  %s\n" "$s" "$a" "?" "✖ INVALID REGEX with \\b — $(jqerror)"
      continue
    fi
    # grep may fail silently here: it only serves the "WHAT IT MATCHES" display,
    # the verdict rests on the numbers a and b, which are now both checked.
    words=$(jq -r --arg s "\\b$s" 'select((.body!=null) and (.body|test($s;"i"))) | .body' "$CORPUS" \
            | grep -oiE "\b${s}[a-zščćžđ]*" 2>/dev/null | sort -u | head -4 | tr '\n' ' ')
    # TWO DIFFERENT PROBLEMS, not one:
    #  1) CLASH — free matches more than anchored => the stem catches MID-word
    #     (hate 9→5 because of "w-hate-ver", alat 1→0). That is a bug, lengthen or anchor.
    #  2) BROAD — anchored matches >5% of the corpus => the stem is too general and
    #     carries no signal on its own ("program" in a fitness corpus = "training program").
    #     That is not a bug, it is poor resolution. It works only paired with another stem.
    flag=""
    MID=$((a-b))
    LIMIT=$(( N / 20 ))
    # WARNING: the filter uses the ANCHORED version, so a difference a-b means
    # \b has ALREADY fixed the clash. That is information, not a warning. A misleading
    # warning is worse than none — the same lesson as 2>/dev/null.
    [ "$MID" -gt 0 ] && flag="ℹ️ \\b removed $MID"
    if [ "$b" -gt "$LIMIT" ] && [ "$LIMIT" -gt 0 ]; then
      [ -n "$flag" ] && flag="$flag · " ; flag="${flag}◐ BROAD: $b of $N"
    fi
    printf "%-16s %6s %6s  %s %s\n" "$s" "$a" "$b" "$words" "$flag"
  done
  echo
done
echo "Judge a real clash by the WHAT IT MATCHES column, not by the numbers."
echo "◐ BROAD is a warning, not an error — such a stem works only in a pair, never alone."
echo "Example from 2026-08-15: spor→sporo (8→0), lent→lento (6→0)."
