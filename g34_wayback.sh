#!/bin/bash
# g34_wayback.sh — G3 (dead domains) + G4 (when did the pricing page change)
#
# Spec: 2026-08-16.
#
# Why it exists: g3_graveyard.sh admits in its own output that "dead
# domains and Wayback stay manual". SKILL.md said it twice. It was the
# only hole in G3 that had a free fix and nobody had closed it.
#
# What it solves:
#   G3 — is the domain dead? Last snapshot in the archive + whether the live
#        domain still answers. A dead domain disappears from Google, but NOT from the archive.
#   G4 — when and how the incumbent changed its pricing. This is the "changelog test":
#        the price from two years ago versus today tells you whether the market grows or crumbles.
#
# ── WHAT WAS MEASURED 2026-08-16 (not assumed) ──
#   CDX API with no key, no login:
#     http://web.archive.org/cdx/search/cdx?url=X&output=json&limit=N
#     → HTTP 200, JSON table. The first row is COLUMN NAMES, not data.
#   collapse=digest → returns ONLY snapshots where the content REALLY changed.
#     That is the whole changelog test in one parameter.
#   Archived page: http://web.archive.org/web/<TS>id_/<url>
#     The `id_` suffix gives the original without the archive's navigation. Without it
#     you also fetch Wayback's own HTML and get false hits.
#   The Availability API (archive.org/wayback/available) returned 429 the same day.
#     Hence: pause between calls and back off, or the archive silences you mid-job.
#   NOT EVERY SNAPSHOT RETURNS CONTENT. Live test on gohighlevel.com/pricing:
#     snapshot 2024-05 → "$297 $97 $99", snapshot 2023-12 → EMPTY.
#     So the script tries SEVERAL snapshots and does not declare an empty one "no prices".
#   Claude Code WebFetch cannot reach web.archive.org (tool block).
#     curl from your machine can. That is why this is a script and not an agent call.
#
# Usage:
#   ./g34_wayback.sh stripe.com/pricing          # pricing history
#   ./g34_wayback.sh gohighlevel.com             # is the domain alive?
#   SNAPSHOTS=8 ./g34_wayback.sh vendor.com/pricing
#   ./g34_wayback.sh --quick vendor.com/pricing  # no page downloads

set -euo pipefail

CDX="http://web.archive.org/cdx/search/cdx"
WEB="http://web.archive.org/web"
UA="gauntlet-research/1.0 (personal research)"
PAUSE="${PAUSE:-1.5}"         # the archive returned 429 the same day — don't rush
SNAPSHOTS="${SNAPSHOTS:-6}"   # how many archived pages we actually download
DEAD_AGE=550                  # days without a snapshot → suspect a dead domain

QUICK=0
if [ "${1:-}" = "--quick" ]; then QUICK=1; shift; fi

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "ERROR: missing domain or URL." >&2
  echo "Usage: $0 [--quick] <domain[/path]>" >&2
  echo "  example: $0 stripe.com/pricing" >&2
  echo "  example: $0 gohighlevel.com" >&2
  exit 1
fi
command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }

# strip the scheme if the user pasted it
TARGET="${TARGET#http://}"; TARGET="${TARGET#https://}"
DOMAIN="${TARGET%%/*}"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

uri() { jq -rn --arg x "$1" '$x|@uri'; }

# curl with backoff. A 429 from the archive is not a program error, it is a request to wait.
fetch() {
  local url="$1" out="$2" label="$3" code attempt=1
  while [ "$attempt" -le 3 ]; do
    code=$(curl -sS -A "$UA" -m 90 -o "$out" -w "%{http_code}" "$url" 2>"$TMP/curl.err") || {
      echo "  ⚠️ curl failed ($label): $(head -c 150 "$TMP/curl.err")" >&2
      return 1
    }
    case "$code" in
      200) return 0 ;;
      429|502|503|504)
        # 429 = silenced, 502/503/504 = the archive is overloaded. Both pass.
        echo "  ⏳ HTTP $code ($label) — archive can't cope, waiting $((attempt*5))s" >&2
        sleep $((attempt*5)); attempt=$((attempt+1)) ;;
      *)
        echo "  ⚠️ HTTP $code ($label)" >&2
        return 1 ;;
    esac
  done
  echo "  ⚠️ $label — still silenced after three attempts. UNCHECKED." >&2
  return 1
}

echo "═══ Wayback: $TARGET ═══" >&2
echo >&2

# ── 1. SNAPSHOT HISTORY ─────────────────────────────────────────────
# collapse=digest: only snapshots where the content really changed.
URL_CDX="$CDX?url=$(uri "$TARGET")&output=json&collapse=digest&filter=statuscode:200&limit=400"
if ! fetch "$URL_CDX" "$TMP/cdx.json" "CDX"; then
  echo "ERROR: CDX did not answer. This is NOT 'no snapshots' — it is not looked at." >&2
  exit 1
fi

# the first row is column names; if that is all there is, there are no snapshots
ROWS=$(jq 'length' "$TMP/cdx.json" 2>/dev/null || echo 0)
if [ "$ROWS" -le 1 ]; then
  echo "The archive has NO snapshots for \"$TARGET\"."
  echo
  echo "That means one of two things, and the difference matters:"
  echo "  · the page never existed at this path (try just the domain)"
  echo "  · or it was missed (the archive is not complete)"
  echo "Before you record this as an outcome, try: $0 $DOMAIN"
  exit 0
fi

# CDX columns: urlkey timestamp original mimetype statuscode digest length
# The seventh (length) is key — see snapshot selection below.
jq -r '.[1:][] | [.[1], .[2], (.[6] // "0")] | @tsv' "$TMP/cdx.json" > "$TMP/snapshots.tsv"
CHANGES=$(wc -l < "$TMP/snapshots.tsv" | tr -d ' ')
FIRST=$(head -1 "$TMP/snapshots.tsv" | cut -f1)
LAST=$(tail -1 "$TMP/snapshots.tsv" | cut -f1)

dat() { echo "${1:0:4}-${1:4:2}-${1:6:2}"; }

# days since the last snapshot (macOS date)
DAYS_SINCE=$(( ( $(date +%s) - $(date -j -f "%Y%m%d" "${LAST:0:8}" +%s 2>/dev/null || echo 0) ) / 86400 ))

echo "  first snapshot : $(dat "$FIRST")" >&2
echo "  last           : $(dat "$LAST")  ($DAYS_SINCE days ago)" >&2
echo "  content changes: $CHANGES" >&2
echo >&2

# ── 2. G3 — is the domain dead? ─────────────────────────────────────
echo "═══ G3 — signs of death ═══"
ALIVE="?"
if CODE=$(curl -sS -A "$UA" -m 20 -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null); then
  ALIVE="$CODE"
else
  ALIVE="no answer"
fi
echo "  live domain https://$DOMAIN → $ALIVE"

if [ "$ALIVE" = "no answer" ] || [ "$ALIVE" = "000" ]; then
  echo "  🪦 THE DOMAIN DOES NOT ANSWER, but the archive has it until $(dat "$LAST")."
  echo "     This is a corpse. Look at the last snapshot — it often has a farewell post:"
  echo "     $WEB/${LAST}/https://$DOMAIN"
elif [ "$DAYS_SINCE" -gt "$DEAD_AGE" ]; then
  echo "  ⚠️ The domain answers, but the archive has not seen it for $DAYS_SINCE days."
  echo "     Parked domain or abandoned product — check by hand."
else
  echo "  ✓ Alive and archived recently — no corpse for G3, this is material for G4."
fi
echo

[ "$QUICK" -eq 1 ] && { echo "(--quick: archived page downloads skipped)"; exit 0; }

# ── 3. G4 — changelog test: what the page said over time ────────────
# We pick SNAPSHOTS snapshots spread evenly over the history,
# always including the first and the last.
echo "═══ G4 — changelog test ═══"

# ── SNAPSHOT SELECTION: persist, don't guess ────────────────────────
# The first version of this script picked snapshots evenly over time and, after
# five empty ones, reported "no prices" for a page that clearly HAS prices.
# A false negative — exactly what G3/G4 must never produce.
#
# The second version tried to drop empty shells by the CDX column
# `length`. THAT WAS WRONG, AND BACKWARDS. Measured 2026-08-16
# on gohighlevel.com/pricing:
#     snapshot        CDX length   actual download   prices
#     2024-05-27         74.993         553.228      $297 $97 $99
#     2023-12-14        114.262         113.933      -
#     2025-07-19        111.278         110.273      -
# CDX `length` is the size of the COMPRESSED record. A server-rendered page
# is long and compresses very well; an empty JS shell does not. The snapshot with
# prices therefore had the SMALLEST listed length — filtering by size
# picked exactly the wrong ones. And you cannot know the decompressed size
# until you download the page. So pre-filtering is NOT POSSIBLE.
#
# Hence: don't select, PERSIST. Spread candidates over time (so you get
# a timeline), then keep downloading until you collect SNAPSHOTS hits or
# exhaust ATTEMPTS. The cost is time, not correctness.
ATTEMPTS="${ATTEMPTS:-14}"
CANDIDATES=$ATTEMPTS
[ "$CANDIDATES" -gt "$CHANGES" ] && CANDIDATES=$CHANGES

if [ "$CANDIDATES" -ge "$CHANGES" ]; then
  cp "$TMP/snapshots.tsv" "$TMP/selection.tsv"
else
  awk -v n="$CANDIDATES" -v total="$CHANGES" 'BEGIN{step=(n>1)?(total-1)/(n-1):0}
    { rows[NR]=$0 }
    END { for (i=0;i<n;i++) { idx=int(i*step)+1; if (!(idx in seen)) { print rows[idx]; seen[idx]=1 } } }' \
    "$TMP/snapshots.tsv" > "$TMP/selection.tsv"
fi
echo "  (trying up to $CANDIDATES snapshots, stopping at $SNAPSHOTS with prices)" >&2

# Prices: $97 / €99 / 99 EUR / 1,299 / 49.99 — collect generously, filter locally.
PRICE_RE='(\$|€|£)[0-9][0-9,.]*|[0-9][0-9,.]*[[:space:]]?(EUR|USD|GBP)\b'

FOUND=0
EMPTY=0
while IFS=$'\t' read -r TS URL_ORIG LENGTH; do
  [ -z "$TS" ] && continue
  sleep "$PAUSE"
  if ! fetch "$WEB/${TS}id_/${URL_ORIG}" "$TMP/page.html" "$(dat "$TS")"; then
    EMPTY=$((EMPTY+1)); continue
  fi
  PRICES=$(grep -oE "$PRICE_RE" "$TMP/page.html" 2>/dev/null \
         | tr -d ' ' | sort -u \
         | awk 'length($0)<=12' | head -14 | tr '\n' ' ' || true)
  if [ -n "$PRICES" ]; then
    echo "  $(dat "$TS") : $PRICES"
    FOUND=$((FOUND+1))
    # enough hits for a timeline — stop loading the archive
    [ "$FOUND" -ge "$SNAPSHOTS" ] && break
  else
    EMPTY=$((EMPTY+1))
  fi
done < "$TMP/selection.tsv"

echo
if [ "$FOUND" -eq 0 ]; then
  echo "No prices could be read from any snapshot."
  echo "This is NOT proof that there is no pricing page. The most common cause is that prices"
  echo "load with JavaScript and the archive did not capture them. Try:"
  echo "  · another path: /plans, /pricing-plans, /cenik, /preise"
  echo "  · more attempts: ATTEMPTS=30 $0 $TARGET"
  echo "  · open by hand: $WEB/${LAST}/${TARGET}"
  echo
  echo "⚠️ This is UNCHECKED, not 'no prices'. Do not record it as a G4 outcome."
else
  echo "Read it as a CHANGE, not as a list. What it tells you:"
  echo "  · prices rise        → the incumbent has power, the market bears more"
  echo "  · prices fall        → race to the bottom, margins shrink"
  echo "  · new lower tier     → they are attacking the low end (your entry point)"
  echo "  · pricing disappears → they moved to 'contact us' = enterprise"
fi
[ "$EMPTY" -gt 0 ] && echo "($EMPTY snapshots without prices — normal, not an outcome.)"
exit 0
