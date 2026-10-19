#!/bin/bash
# h4_rank.sh — H4: rank the filter's hits by which ones are worth reading
#
# Spec: 2026-08-15 ("signal ranker").
#
# Why it exists: H2 returns 17 hits and they all look the same. They were read
# in order and the best one — an Italian thread about paper records in a barn — was
# almost at the bottom. The order was random, so the finding of the day was a matter of luck.
#
# What the points MEASURE and what they don't: they measure how likely it is that a unit is worth
# your reading. They do NOT measure whether the idea is good. The /35 score in SKILL.md is something
# else, and a human gives it after the gates, not this script.
#
# Every point is printed with its reason. An opaque score is worse than none.
#
# Usage:  ./h4_rank.sh <filtered.jsonl> [count]

set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/_corpus.sh"
trap corpus_cleanup EXIT

INPUT="${1:?Usage: h4_rank.sh <filtered.jsonl> [count]}"
COUNT="${2:-15}"

corpus_normalize "$INPUT"   # NOT inside $(...) — it sets globals

build() {
  grep -v '^#' "$1" | grep -v '^[[:space:]]*$' | sed 's/[[:space:]]*$//' \
  | sed 's/^/\\b/' | paste -sd '|' -
}
PAIN=$(build "$DIR/pain_stems.txt")
PROCESS=$(build "$DIR/process_stems.txt")
SHOP=$(build "$DIR/shop_stems.txt")

# money is evidence, a complaint is free — this is G5 in one regex
MONEY='(\$[0-9]|€[0-9]|[0-9][0-9,.]* ?(usd|eur|dollars|euros)\b|per month|/mo\b|a month|monthly|per seat|per user|we pay|i pay|paying|quoted|invoice)'
# measured quantity: "60 hours", "3 ure na teden", "20 minutes each"
QUANTITY='([0-9]{1,4}[ +]*(hours?|hrs?|ure|urah|minutes?|min\b|days?|dni|weeks?|tednov|ore|giorni))'

echo "corpus: $CORPUS_N units from $INPUT" >&2
echo >&2

jq -r --arg pain "$PAIN" --arg proc "$PROCESS" --arg shop "$SHOP" \
      --arg money "$MONEY" --arg qty "$QUANTITY" '
  def has($re): (.body // "") | test($re; "i");

  # _corpus.sh has already normalised the input to JSONL objects, so jq treats each line
  # as its own input. The first version had `[ .[]? // . ] | .[]` here,
  # which on an OBJECT iterates its VALUES — i.e. strings — and every subsequent
  # `.body` failed with "Cannot index string with string". Do not wrap the input.
  (if has($proc) then 3 else 0 end)   as $s_proc
  | (if has($pain) then 2 else 0 end)   as $s_pain
  | (if has($shop) then 2 else 0 end)   as $s_shop
  | (if has($money) then 3 else 0 end)  as $s_money
  | (if has($qty)  then 2 else 0 end)   as $s_qty
  | ((.score // 0) | if . >= 20 then 2 elif . >= 5 then 1 else 0 end) as $s_votes
  | (((.body // "") | length) | if . < 120 then -2 else 0 end)        as $s_short
  | ($s_proc + $s_pain + $s_shop + $s_money + $s_qty + $s_votes + $s_short) as $total
  | [ (if $s_proc > 0 then "friction+3" else empty end),
      (if $s_pain > 0 then "pain+2" else empty end),
      (if $s_shop > 0 then "buying+2" else empty end),
      (if $s_money > 0 then "MONEY+3" else empty end),
      (if $s_qty  > 0 then "measured+2" else empty end),
      (if $s_votes > 0 then "votes+\($s_votes)" else empty end),
      (if $s_short < 0 then "short-2" else empty end) ] as $why
  | [ ($total|tostring),
      ((.score // 0)|tostring),
      (.created_utc // 0 | strftime("%Y-%m-%d")),
      (.type // "?"),
      ($why | join(" ")),
      (.permalink // ""),
      ((.body // "") | gsub("[\n\r]+"; " ")) ]
  | @tsv' "$CORPUS_FILE" 2>"$_CORPUS_DIR/jq.err" | sort -t$'\t' -k1 -rn | head -"$COUNT" \
| while IFS=$'\t' read -r points votes date type why perm body; do
    printf '\n[%s pts · %s votes · %s · %s]  %s\n' "$points" "$votes" "$date" "$type" "$why"
    printf '   %s\n' "${body:0:420}"
    printf '   reddit.com%s\n' "$perm"
  done

if [ -s "$_CORPUS_DIR/jq.err" ]; then
  echo >&2
  echo "jq ERROR while ranking: $(head -c 300 "$_CORPUS_DIR/jq.err")" >&2
  exit 1
fi

echo >&2
echo "Points measure what is worth READING, not whether the idea is good." >&2
echo "MONEY and measured count the most, because they are evidence. Anger is free." >&2
exit 0
