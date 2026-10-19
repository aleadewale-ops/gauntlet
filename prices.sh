#!/bin/bash
# prices.sh — H3, source 2: real prices from users' mouths, no blogs
#
# Why it exists: comparison blogs are SEO junk. Their prices are stale, invented
# or affiliate. The skill forbids them, yet they were used anyway on 2026-08-13/15,
# because WebSearch returns nothing else.
#
# Why NOT `site:reddit.com "tool" "$/mo"` from the original plan:
#   WebSearch IGNORES the site: operator. Tested several times on 2026-08-13.
#
# Why NOT the arctic-shift `body=` search, even though it exists:
#   Tested 2026-08-15. Body search is expensive on the server and after
#   just a few queries returns {"error":"Timeout. Maybe slow down a bit"} —
#   even for a nonsense word. Useless for a pipeline.
#
# Hence: H1 fetches the corpus ONCE with h1_harvest.sh, H3 searches LOCALLY.
#   No extra calls, instant, immune to rate limits.
#
# H3 has two sources and both are primary:
#   SOURCE 1  the tool's official page → WebFetch on domain.com/pricing (done by the main model)
#   SOURCE 2  this script              → what people actually pay, even if the price is hidden
#
# Source 2 is often better: it tells you not only the price, but which part of the pricing
# model annoys people most — lock-in, commission, setup fee, price increase.
#
# Usage:
#   ./h1_harvest.sh personaltraining
#   ./prices.sh corpus.jsonl "Mindbody" ["Zen Planner" ...]
#   ./prices.sh corpus.jsonl --scan          # find ALL tool names with a price

set -u
DIR_P="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR_P/_corpus.sh"
trap corpus_cleanup EXIT
CORPUS="${1:?Usage: prices.sh <corpus.jsonl> \"<tool>\" [...]  |  prices.sh <corpus.jsonl> --scan}"
shift

# WATCH the escapes: in SINGLE quotes '\\$' stays a double backslash
# and jq reads it as "backslash + end of string". It needs a SINGLE one: '\$'.
# This bug returned 0 hits on 2026-08-15 on a corpus that had 5.
MONEY='(\$[0-9][0-9,]*|€[0-9][0-9,.]*|[0-9][0-9,]+ ?(usd|eur|dollars|euros))'
TERMS='(per month|/mo\b|a month|monthly|per year|per annum|annually|quoted|quote|charged|paying|we pay|i pay|setup fee|onboarding fee|contract|per seat|per user|price (increase|hike)|raised .{0,14}price|locked in)'

INPUT="$CORPUS"
corpus_normalize "$CORPUS"   # NOT inside $(...) — it sets globals
CORPUS="$CORPUS_FILE"
echo "corpus: $CORPUS_N units from $INPUT"

# ---------- --scan mode: what do people mention together with a price ----------
# WARNING: without requiring a TOOL nearby, this mode returns SALARIES, not software
# prices, in subreddits with career content. Measured 2026-08-15 on
# r/MuseumPros: the first three hits were "$20/hr", "$15" and an ALL-staff salary.
# Hence the third condition is mandatory — money AND payment terms AND a tool name.
TECH_P=$(grep -v '^#' "$DIR_P/tech_stems.txt" | grep -v '^[[:space:]]*$'          | sed 's/[[:space:]]*$//' | sed 's/^/\\b/' | paste -sd '|' -)

if [ "${1:-}" = "--scan" ]; then
  echo "═══ units that mention a TOOL + money + payment terms ═══"
  jq -r --arg m "$MONEY" --arg t "$TERMS" --arg w "$TECH_P" '
    select((.body|test($m;"i")) and (.body|test($t;"i")) and (.body|test($w;"i")))
    | "\(.score)\t\(.created_utc // .created)\t\(.permalink)\t\(.body|gsub("\n";" "))"' "$CORPUS" \
  | sort -t$'\t' -k1 -rn | head -25 \
  | while IFS=$'\t' read -r sc ts perm body; do
      d=$(date -r "$ts" +%Y-%m-%d 2>/dev/null || echo "$ts")
      echo
      echo "  [$sc · $d] ${body:0:340}"
      echo "    reddit.com$perm"
    done
  echo
  echo "Look at which proper names repeat in these quotes — those are the tools"
  echo "worth running through this script by name and through source 1."
  exit 0
fi

# ---------- by tool name ----------
[ $# -eq 0 ] && { echo "Name at least one tool or use --scan." >&2; exit 1; }
TOTAL=0
for TOOL in "$@"; do
  echo
  echo "═══ \"$TOOL\" ═══"
  MENT=$(jq -r --arg k "$TOOL" 'select(.body|test($k;"i")) | .id' "$CORPUS" | wc -l | tr -d ' ')
  HITS=$(jq -r --arg k "$TOOL" --arg m "$MONEY" --arg t "$TERMS" '
    select(.body|test($k;"i"))
    | select((.body|test($m;"i")) and (.body|test($t;"i")))
    | "\(.score)\t\(.created_utc // .created)\t\(.permalink)\t\(.body|gsub("\n";" "))"' "$CORPUS")
  C=$(echo "$HITS" | grep -c . || true)
  echo "  $MENT mentions, $C with a price or terms"
  TOTAL=$((TOTAL+C))
  [ -n "$HITS" ] && echo "$HITS" | sort -t$'\t' -k1 -rn | while IFS=$'\t' read -r sc ts perm body; do
      d=$(date -r "$ts" +%Y-%m-%d 2>/dev/null || echo "$ts")
      echo "    [$sc · $d] ${body:0:340}"
      echo "      reddit.com$perm"
    done
done

echo
if [ "$TOTAL" -eq 0 ]; then
  echo "Nothing. This is NOT proof that the tool is cheap — it is proof that in this corpus"
  echo "nobody talks about its price. Fetch more pages with h1_harvest.sh, add"
  echo "neighbouring subreddits, or take the price from the official page (source 1)."
  echo "Never from a blog."
else
  echo "$TOTAL quotes. Each is verbatim, with score, date and link —"
  echo "so it satisfies the sourcing rule. A blog does not."
fi
