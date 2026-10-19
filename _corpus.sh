#!/bin/bash
# _corpus.sh — shared normalization of the input corpus. SOURCE it, do not run it.
#
# Why it exists: h1_harvest.sh emits a JSON ARRAY, older harvests emitted
# JSONL. Each of the three consumers (h2_filter, h2_validate, prices) had its
# own copy of the same logic, and twice it was wrong:
#
#   2026-08-15  h2_validate.sh could not read an array → reported ALL ZEROS.
#               It looked like "no stem matches". It had read nothing.
#   2026-08-15  h2_filter.sh set a second trap EXIT next to mktemp — the second
#               one overwrote the first, so NORM stayed behind in /tmp.
#
# Same family of bug as `2>/dev/null`: AN ERROR DISGUISED AS AN EMPTY RESULT.
# An empty result is a valid answer and nobody checks it. So this file fails
# loudly on EVERY ambiguity, never silently to nothing.
#
# ─────────────────────────────────────────────────────────────────────────
# WATCH OUT FOR SUBSHELLS. corpus_normalize SETS globals and therefore MUST
# NOT sit inside `$(...)`. Command substitution runs in a subshell and every
# global the function sets there vanishes when it ends. The first version of
# this file was written as `CORPUS=$(corpus_normalize ...)` and died with
# "CORPUS_N: unbound variable" — the same class of bug it fixes.
# That is why the function deliberately prints NOTHING: if someone puts it in
# $(...), they get an empty string right away, not half a pipeline later.
# ─────────────────────────────────────────────────────────────────────────
#
# Usage in a consumer:
#     DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#     . "$DIR/_corpus.sh"
#     trap corpus_cleanup EXIT          # ONE trap, this one and no other
#     corpus_normalize "$1"             # NOT in $(...)
#     # from here on: $CORPUS_FILE (path to JSONL), $CORPUS_N, $CORPUS_FORMAT
#
# If you need a temp file of your own, do not catch it with a new trap:
#     TMP=$(corpus_tempfile)            # this one IS safe in $(...)

CORPUS_FILE=""
CORPUS_N=0
CORPUS_FORMAT=""

# One temp directory for everything. Created at source time, so cleanup needs
# no global state that a subshell could lose.
_CORPUS_DIR=$(mktemp -d) || { echo "ERROR: mktemp -d failed." >&2; exit 1; }

corpus_cleanup() {
  [ -n "${_CORPUS_DIR:-}" ] && [ -d "$_CORPUS_DIR" ] && rm -rf "$_CORPUS_DIR"
  return 0
}

# Safe in command substitution: mktemp itself guarantees uniqueness, no counter.
corpus_tempfile() {
  mktemp "$_CORPUS_DIR/t.XXXXXX" || { echo "ERROR: mktemp failed." >&2; exit 1; }
}

# corpus_normalize <path>  →  sets $CORPUS_FILE, $CORPUS_N, $CORPUS_FORMAT
corpus_normalize() {
  local input="$1" first out err
  CORPUS_FILE=""
  CORPUS_N=0
  CORPUS_FORMAT=""

  command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }

  if [ ! -f "$input" ]; then
    echo "ERROR: no corpus: $input" >&2
    echo "  Run this first:  ./h1_harvest.sh <subreddit>" >&2
    exit 1
  fi
  if [ ! -s "$input" ]; then
    echo "ERROR: corpus $input is an empty file (0 bytes)." >&2
    echo "  This is NOT 'no matches' — it is a failed harvest. Run h1_harvest.sh again." >&2
    exit 1
  fi

  # the first NON-BLANK character decides the format. Anything other than [ or {
  # is junk: an HTML error page, gzip, plain text. Do NOT try to read it.
  first=$(head -c 512 "$input" | tr -d '[:space:]' | head -c 1)
  out=$(corpus_tempfile)
  err=$(corpus_tempfile)

  case "$first" in
    '[')
      CORPUS_FORMAT="array"
      if ! jq -c '.[]' "$input" > "$out" 2>"$err"; then
        echo "ERROR: $input starts with [ but is not a valid JSON array." >&2
        echo "  jq: $(head -c 200 "$err")" >&2
        exit 1
      fi
      ;;
    '{')
      CORPUS_FORMAT="jsonl"
      # NOT just `cat`. If a single line is broken, every consumer must learn
      # it here, not half a pipeline later from an empty output.
      if ! jq -c . "$input" > "$out" 2>"$err"; then
        echo "ERROR: $input is not valid JSONL — at least one line does not parse." >&2
        echo "  jq: $(head -c 200 "$err")" >&2
        exit 1
      fi
      ;;
    *)
      echo "ERROR: $input is neither a JSON array nor JSONL." >&2
      echo "  first character: '${first:-<empty>}'" >&2
      echo "  start of file: $(head -c 200 "$input" | tr '\n' ' ')" >&2
      echo "  Most often this is an HTML error page saved instead of the data." >&2
      exit 1
      ;;
  esac

  CORPUS_N=$(wc -l < "$out" | tr -d ' ')
  if [ "$CORPUS_N" -eq 0 ]; then
    echo "ERROR: $input is valid JSON but contains 0 items." >&2
    echo "  Check the subreddit name with map-subreddit.sh and repeat the harvest." >&2
    exit 1
  fi

  # Every consumer filters on .body. If it is missing, they return 0 matches and
  # that looks like "the niche is clean" — in fact the format is wrong. Third
  # variant of the same bug; it stops here.
  if ! jq -e -s 'any(.[]; has("body") and (.body != null))' "$out" >/dev/null; then
    echo "ERROR: no item in $input has a .body field." >&2
    echo "  Incompatible format. h1_harvest.sh emits {id,type,body,created_utc,score,permalink}." >&2
    echo "  First item: $(head -1 "$out" | head -c 200)" >&2
    exit 1
  fi

  CORPUS_FILE="$out"
}
