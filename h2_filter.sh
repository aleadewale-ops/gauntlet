#!/bin/bash
# h2_filter.sh — H2: multilingual proximity filter, SL/HR/IT/EN at once
#
# Architecture: 2026-08-15. Data (dictionaries) separate from logic.
# A new term is one line in a .txt, not a code change.
#
# Why stems and not whole words: Slavic and Romance languages inflect.
# "drag" covers drago/draga/dragi, "pocas" covers pocasi/pocasen.
#
# Why \b at the start of every stem (an addition to the original design):
#   Without an anchor, short stems catch English. Measured 2026-08-15 on
#   318 units of r/personaltraining:
#     hate  → 9 hits, among them "w-hate-ver"
#     lent  → 6: equivalent, plenty, talent
#     spor  → 8: sport, sports
#     stran → 1: stranger
#   With \b: hate 9→5 (all real), lent 6→0, stran remains → stem lengthened.
#   Where \b is not enough, the stem is LENGTHENED in the dictionary: spor→sporo, lent→lento.
#
# Input: JSON array from h1_harvest.sh OR older JSONL. Both are read by _corpus.sh.
#
# Usage:  ./h2_filter.sh corpus.jsonl [window] > filtered.jsonl

set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/_corpus.sh"
trap corpus_cleanup EXIT        # ONE trap for the whole script, this one and no other
CORPUS="${1:?Usage: h2_filter.sh <corpus.jsonl> [window]}"
WIN="${2:-160}"

build() {
  grep -v '^#' "$1" | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*$//' \
  | sed 's/^/\\b/' | paste -sd '|' -
}
TECH=$(build "$DIR/tech_stems.txt")
PAIN=$(build "$DIR/pain_stems.txt")
PROCESS=$(build "$DIR/process_stems.txt")
SHOP=$(build "$DIR/shop_stems.txt")
[ -z "$TECH" ] && { echo "ERROR: tech_stems.txt is empty." >&2; exit 1; }
[ -z "$PAIN" ] && { echo "ERROR: pain_stems.txt is empty." >&2; exit 1; }

# ── THREE SIGNALS, not one ──────────────────────────────────────────
#
# NEGATIVE SIGNAL = PAIN | FRICTION
#   PAIN is emotion:   "I hate this system", "it's a disaster".
#   FRICTION is work:  "every month I copy this by hand into excel".
#   Friction is more useful — anger tells you something is disliked, friction tells you
#   WHAT exactly is done by hand and can therefore be removed.
#
# The BUYING SIGNAL is a separate axis and is not negative. Measured 2026-08-15:
#   MuseumPros 3 pain : 22 buying · Dentistry 0 : 18
#   nonprofit  1 : 19             · travelagents 1 : 17
#   Six to eighteen times more frequent AND commercially stronger — whoever writes
#   "we are looking to switch CRM databases" is a buyer in the market.
#
NEGATIVE_SIGNAL="${PAIN}"
[ -n "$PROCESS" ] && NEGATIVE_SIGNAL="${PAIN}|${PROCESS}"

SIG="${NEGATIVE_SIGNAL}"
[ -n "$SHOP" ] && SIG="${NEGATIVE_SIGNAL}|${SHOP}"

W=".{0,${WIN}}?"
RE="(?:(?:${TECH})${W}(?:${SIG}))|(?:(?:${SIG})${W}(?:${TECH}))"

corpus_normalize "$CORPUS"   # NOT inside $(...) — it sets globals
CORPUS="$CORPUS_FILE"
IN=$CORPUS_N

# DO NOT use `jq | tee /dev/stdout | wc -l`: when tee is in a pipe to wc,
# /dev/stdout IS that pipe, so everything goes into wc and nothing comes out. Bug from
# 2026-08-15 — the filter reported 4 hits and emitted empty output.
TMP=$(corpus_tempfile)
if ! jq -c --arg re "$RE" 'select((.body != null) and (.body|test($re;"i")))' "$CORPUS" > "$TMP" 2>"$TMP.err"; then
  echo "jq ERROR: $(head -c 200 "$TMP.err")" >&2
  rm -f "$TMP.err"; exit 1
fi
rm -f "$TMP.err"
cat "$TMP"

HITS=$(wc -l < "$TMP" | tr -d ' ')
# breakdown by WHICH signal fired — tells you what kind of finding it is
N_PAIN=$(jq -r --arg r "$PAIN"    'select(.body|test($r;"i")) | .id' "$TMP" | wc -l | tr -d ' ')
N_PROC=$(jq -r --arg r "$PROCESS" 'select(.body|test($r;"i")) | .id' "$TMP" | wc -l | tr -d ' ')
N_SHOP=$(jq -r --arg r "$SHOP"    'select(.body|test($r;"i")) | .id' "$TMP" | wc -l | tr -d ' ')
echo "H2: $IN units → $HITS hits, window ${WIN} characters" >&2
echo "    of which: pain $N_PAIN · friction $N_PROC · buying signal $N_SHOP  (a unit can fire several)" >&2
