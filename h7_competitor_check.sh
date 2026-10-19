#!/bin/bash
# h7_competitor_check.sh — a competitor's official price, with no search engine and no browser
#
# Spec: 2026-08-15.
#
# Why it exists: G2 and G4 stand on REAL prices. Comparison blogs are
# affiliate SEO and their numbers are stale or made up, and WebSearch
# ignores the site: operator (measured 2026-08-13), so it cannot be
# forced onto the official page. This script goes straight to the pricing page.
#
# Why Jina Reader and not WebFetch: Jina RENDERS the page and returns clean
# Markdown, so it also covers pricing pages built with JavaScript, and it does
# not launch a local browser. The response is also SAVED, which gives the date and source
# that the sourcing rule requires.
#
# ── WHY THIS SCRIPT CALLS NO MODEL ───────────────────────────────────
# Decision, 2026-08-15: NO API key in bash scripts.
# A key that lives in a script ends up in a commit sooner or later, and the calls are billed
# separately from what you already have.
#
# Claude Code IS already an authenticated agent. So this script is a pure FETCHER:
# it pulls the Markdown and saves it. The extraction is done by the main model, using the prompt
# the script writes to .prompt.txt — so the text does not drift from SKILL.md.
# Bash does the dirty work, the model does the judgement.
# ─────────────────────────────────────────────────────────────────────
#
# Usage:
#   ./h7_competitor_check.sh veevart.com/pricing
#   ./h7_competitor_check.sh https://mindbodyonline.com/pricing
#
# Output:
#   competitor_<host>_<path>_<date>_<time>.md          raw page
#   competitor_<host>_<path>_<date>_<time>.prompt.txt  instructions for the model

set -euo pipefail

UA="gauntlet-research/1.0 (personal research)"
MAX_CHARS=120000   # safeguard: some pricing pages are huge. Truncation is REPORTED.

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "ERROR: missing pricing page URL." >&2
  echo "Usage: $0 <url>     example: $0 veevart.com/pricing" >&2
  exit 1
fi
command -v curl >/dev/null || { echo "ERROR: curl is missing." >&2; exit 1; }

# ── 2. scheme prefix, if missing ─────────────────────────────────────
case "$URL" in
  http://*|https://*) : ;;
  *) URL="https://$URL"; echo "  (added https://)" >&2 ;;
esac

# WATCH the file name: the first version carried only the HOST and the MINUTE.
# In a test on 2026-08-15, veevart.com/pricing and veevart.com/404-page
# got the same name in the same minute, and the second run SILENTLY OVERWROTE the pricing page with the 404
# page. Silent data loss, the same family as an error that reads as an
# empty result. Hence: host + PATH + seconds, and never over an existing file.
HOST=$(echo "$URL" | sed -E 's#^https?://##; s#/.*##; s#[^A-Za-z0-9.-]#_#g')
URLPATH=$(echo "$URL" | sed -E 's#^https?://[^/]*##; s#^/##; s#/+$##; s#[^A-Za-z0-9._-]#_#g')
[ -z "$URLPATH" ] && URLPATH="root"
STAMP=$(date +%Y-%m-%d_%H%M%S)
READ_DATE=$(date +%Y-%m-%d)
BASE="competitor_${HOST}_${URLPATH}_${STAMP}"
RAW="${BASE}.md"
PROMPT="${BASE}.prompt.txt"
for f in "$RAW" "$PROMPT"; do
  [ -e "$f" ] && { echo "ERROR: $f already exists. Not overwriting — rename or move the old one." >&2; exit 1; }
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ─────────────────────────────────────────────────────────────────────
# 3. + 4. Jina Reader, with strict error handling
#
# FOUR failure modes, measured 2026-08-15, and three of them look like
# valid content if you don't catch them:
#   a) curl fails (DNS, network)              → exit code != 0
#   b) non-existent domain                    → HTTP 422 with a JSON error
#   c) Jina rate limit                        → HTTP 429
#   d) NON-EXISTENT PAGE ON A REAL DOMAIN     → HTTP 200, ~3 KB of navigation only
#      and an EMPTY "Title:" line. This is the sneakiest: on such a page the model
#      would honestly report "prices are not published", and you would read that
#      as a finding about the company, not as a wrong URL.
# ─────────────────────────────────────────────────────────────────────
echo "═══ $URL ═══" >&2
echo "  → reading via Jina Reader ..." >&2

CODE=$(curl -sSL -A "$UA" -m 90 -o "$TMP/page.md" -w "%{http_code}" \
       "https://r.jina.ai/$URL" 2>"$TMP/curl.err") || {
  echo "ERROR: curl failed." >&2
  echo "  $(head -c 200 "$TMP/curl.err")" >&2
  exit 1
}

if [ "$CODE" != "200" ]; then
  echo "ERROR: Jina returned HTTP $CODE." >&2
  echo "  body: $(head -c 300 "$TMP/page.md" | tr '\n' ' ')" >&2
  case "$CODE" in
    422) echo "  → 422 usually means the domain cannot be resolved. Check the spelling." >&2 ;;
    429) echo "  → 429 is the rate limit. Wait a minute and try again." >&2 ;;
  esac
  exit 1
fi

BYTES=$(wc -c < "$TMP/page.md" | tr -d ' ')
if [ "$BYTES" -lt 200 ]; then
  echo "ERROR: the response has only $BYTES bytes — that is not a pricing page." >&2
  echo "  $(head -c 200 "$TMP/page.md")" >&2
  exit 1
fi

# a Jina error that arrives with status 200
if head -c 1 "$TMP/page.md" | grep -q '{'; then
  echo "ERROR: Jina returned a JSON error with HTTP 200, not a page." >&2
  echo "  $(head -c 300 "$TMP/page.md")" >&2
  exit 1
fi

# soft-404: real domain, wrong path. A warning, not an abort — but LOUD,
# because otherwise it would read as a finding about the company.
WARNING=""
if head -3 "$TMP/page.md" | grep -qE '^Title:[[:space:]]*$'; then
  WARNING="⚠️ WARNING: the page has no title (empty 'Title:' line). On
veevart.com/thispagedoesnotexist this was the sign of a NON-EXISTENT PAGE on a real
domain: HTTP 200, ~3 KB of navigation only. Check the path in the URL BEFORE
you read this as 'prices are not publicly listed'."
  echo "$WARNING" >&2
fi

CHARS=$(wc -m < "$TMP/page.md" | tr -d ' ')
TRUNCATED=""
if [ "$CHARS" -gt "$MAX_CHARS" ]; then
  TRUNCATED="⚠️ TRUNCATED: the page has $CHARS characters, the first $MAX_CHARS are saved."
  echo "  $TRUNCATED" >&2
  head -c "$MAX_CHARS" "$TMP/page.md" > "$TMP/shorter.md"
  mv "$TMP/shorter.md" "$TMP/page.md"
fi

# ── header with source and date, because the sourcing rule requires it ──
{ echo "<!-- source: $URL"
  echo "     read: $READ_DATE via r.jina.ai"
  echo "     bytes: $BYTES"
  [ -n "$WARNING" ] && echo "     $WARNING"
  [ -n "$TRUNCATED" ] && echo "     $TRUNCATED"
  echo "-->"
  cat "$TMP/page.md"
} > "$RAW"

# ── prompt for the main model, word for word per the spec ────────────
# It lives here and not in SKILL.md, so the two texts don't drift apart.
cat > "$PROMPT" <<PROMPT_END
You are a B2B analyst. The file $RAW holds the raw content of the official pricing page
($URL, read $READ_DATE), converted to Markdown.

Your only task is to extract the actual numbers.
Return a structured listing:
- Plan name
- Price (monthly/yearly)
- Main limits (number of users, features)
- Is there a hidden "Contact Sales" price?

If there are no prices on the page, write plainly: "Prices are not publicly listed."

Summarising marketing copy (e.g. "This tool helps you
grow...") is FORBIDDEN. Only bare facts and numbers.

Do not fill in prices from memory, from a blog or from any other source. What is not on this
page is not on this page — and that is a valid finding, not a gap.
${WARNING:+
$WARNING}
${TRUNCATED:+
$TRUNCATED If plans are missing, fetch the page again without the limit.}
PROMPT_END

echo >&2
echo "  ✅ $BYTES bytes saved" >&2
echo "     page:   $RAW" >&2
echo "     prompt: $PROMPT" >&2
echo >&2
echo "No model was called — this script has no API key and never will." >&2
echo "The main model does the extraction: read $PROMPT and then $RAW." >&2
echo >&2
echo "For the sourcing rule, cite: price from $URL, read $READ_DATE." >&2
echo "Never from a comparison blog." >&2
