#!/bin/bash
# gates.sh — mode B: runs what CAN be run for a single idea, and prepares the verdict
#
# Spec: 2026-08-15.
#
# Why it exists: all ten scripts served the hunt. `/gauntlet <idea>` was pure
# manual work, even though it goes through the same gates.
#
# ── WHAT THIS SCRIPT DOES NOT DO, AND WHY ──
# It does not judge. G1 means reading the statute and deciding whether it
# touches a protected profession. G2 means walking the free official route and
# naming the step where people give up. G5 means reading the one-star reviews.
# None of that is scriptable — the COLLECTION is scriptable, not the verdict.
#
# So it collects EVIDENCE for the gates it knows, and for all the others it
# prepares an empty slot with a question. An empty slot in a file is visible;
# a missing gate in your head is not.
#
# What it knows:
#   G3 graveyard     → g3_graveyard.sh, for the idea and for every competitor
#   G4 prices        → h7_competitor_check.sh, for every pricing URL given
#   G0, G0.5, G1,    → skeleton with questions and the default verdict UNANSWERED
#   G2, G5, G6
#
# Usage:
#   ./gates.sh "quote automation for cabinet makers"
#   ./gates.sh "X" --competitor veevart --competitor tessitura
#   ./gates.sh "X" --competitor veevart --pricing veevart.com/pricing

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IDEA=""
COMPETITORS=()
PRICING_URLS=()

usage() {
  echo "Usage: $0 \"<idea>\" [--competitor <name>]... [--pricing <url>]..." >&2
  echo "  example: $0 \"all-in-one for small museums\" --competitor veevart --pricing veevart.com/pricing" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --competitor) COMPETITORS+=("$2");  shift 2 ;;
    --pricing)    PRICING_URLS+=("$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "ERROR: unknown flag $1" >&2; exit 1 ;;
    *) if [ -z "$IDEA" ]; then IDEA="$1"; else
         echo "ERROR: more than one idea. Put it in quotes." >&2; exit 1; fi
       shift ;;
  esac
done

if [ -z "$IDEA" ]; then
  echo "ERROR: idea is missing." >&2
  echo >&2
  usage
  exit 1
fi

TS=$(date +%Y-%m-%d_%H%M%S)
# WATCH OUT: `sed 's/x\+/-/'` does NOT work on macOS — BSD sed does not know
# \+ in basic regex, so the slug stayed equal to the input and file names got
# spaces. It needs -E. A space in a file name is a mine in a pipeline.
SLUG=$(echo "$IDEA" | tr '[:upper:]' '[:lower:]' \
       | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-48)
[ -z "$SLUG" ] && SLUG="idea"
OUTPUT="verdict_${SLUG}_${TS}.md"
EVIDENCE="evidence_${SLUG}_${TS}"
mkdir -p "$EVIDENCE"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║  GATES: $IDEA"
echo "╚═══════════════════════════════════════════════════════╝"
echo

# ─────────── G3: graveyard ───────────
echo "▶ G3 — graveyard"
G3_SUMMARY=""
{
  echo "# G3 — graveyard"
  echo
  echo "## by idea: \"$IDEA\""
  echo '```'
} > "$EVIDENCE/g3.md"

if bash "$DIR/g3_graveyard.sh" "$IDEA" >> "$EVIDENCE/g3.md" 2>&1; then
  echo "    idea: run"
else
  echo "    ⚠️ idea: g3 failed, see $EVIDENCE/g3.md" | tee -a "$EVIDENCE/g3.md"
fi
echo '```' >> "$EVIDENCE/g3.md"

for C in ${COMPETITORS[@]+"${COMPETITORS[@]}"}; do
  echo "    competitor: $C"
  { echo; echo "## by competitor: $C"; echo '```'; } >> "$EVIDENCE/g3.md"
  if ! bash "$DIR/g3_graveyard.sh" "$C" >> "$EVIDENCE/g3.md" 2>&1; then
    echo "    ⚠️ $C: g3 failed" >&2
  fi
  echo '```' >> "$EVIDENCE/g3.md"
done

BODIES=$(grep -c '^\[20' "$EVIDENCE/g3.md" || true)
if [ "$BODIES" -gt 0 ]; then
  G3_SUMMARY="$BODIES findings with death language — READ $EVIDENCE/g3.md, and do it BEFORE the other gates"
else
  G3_SUMMARY="nothing. This is not an empty graveyard until you have tried another name for it"
fi
echo "    → $G3_SUMMARY"

# ─────────── G4: official prices ───────────
echo
echo "▶ G4 — official pricing pages"
if [ ${#PRICING_URLS[@]} -eq 0 ]; then
  echo "    (no --pricing was given)"
  G4_SUMMARY="UNANSWERED — no pricing page was looked at"
else
  for U in "${PRICING_URLS[@]}"; do
    echo "    $U"
    if ! ( cd "$EVIDENCE" && bash "$DIR/h7_competitor_check.sh" "$U" ) >/dev/null 2>>"$EVIDENCE/g4.log"; then
      echo "    ⚠️ $U: reading failed, see $EVIDENCE/g4.log" >&2
    fi
  done
  G4_SUMMARY="$(ls "$EVIDENCE"/competitor_*.md 2>/dev/null | wc -l | tr -d ' ') pages collected — extract them with the .prompt.txt files"
fi
echo "    → $G4_SUMMARY"

# ─────────── verdict skeleton ───────────
cat > "$OUTPUT" <<VERDICT
# $IDEA

**Verdict: UNANSWERED** — until you fill in this file, it is not a verdict.
**Score: —/35** · Killed at gate **G?**

> The gates are ordered by (cost of checking) ÷ (probability that it kills),
> smallest ratio first. Once one fails, the LATER ONES ARE NOT RUN. That is the whole saving.

## Step 0 — a claim that can be refuted

> **<who>** today does **<what>**, which costs them **<how much time or money>**.
> They would pay **<how much>** for **<which concrete outcome>**.
> Today they solve it with **<current alternative>**.

If you cannot fill in a field, THAT is the first finding. An empty
"current alternative" means the idea was not researched — nobody has a
problem they solve in no way at all.

**Three things that would kill this if true:**
1.
2.
3.

## Gates

| Gate | Result | Key finding | Source | Date |
|---|---|---|---|---|
| G0 reach the first ten | ⬜ | | | |
| G0.5 which asset | ⬜ | | | |
| G1 legal | ⬜ | | | |
| G2 already free | ⬜ | | | |
| G3 graveyard | ⬜ | $G3_SUMMARY | \`$EVIDENCE/g3.md\` | $(date +%Y-%m-%d) |
| G4 competition | ⬜ | $G4_SUMMARY | \`$EVIDENCE/\` | $(date +%Y-%m-%d) |
| G5 proof of money | ⬜ | | | |
| G6 the math | ⬜ | | | |

### G0 — reach *(five minutes, and it goes first)*
Can you reach the first ten buyers **by phone or through an existing relationship**?
Check the channels you can and cannot use in \`gauntlet/my-situation.md\`.
Cold B2B email is illegal in several EU countries (e.g. Austria TKG 2021 §174,
Italy Codice della Privacy art. 130, Slovenia ZEKom-2 art. 226), LinkedIn InMail
can be closed off (AG Düsseldorf, June 2026), and paid ads may not be an option.
If the only way left is one of those blocked channels — **KILL, and do not run G1.**

- Answer:

### G0.5 — which asset does it stand on
List the assets from \`gauntlet/my-situation.md\` (data, relationships, contracts,
APIs, languages, skills) and name the one this idea reuses.

- Asset it reuses ("none" is a valid answer):

### G1 — legal
Per country, in the local language, from **primary sources**. Cite the article and number.
Protected profession? Criminal and not only administrative sanction? Do you become a GDPR processor?

- Finding:

### G2 — already free
First: **is there a SaaS for ~\$39 a month?** Then the official free route,
a built-in platform feature, open source, a free tier. And: is there an
**ecosystem of comparison blogs** — if yes, the category is taken.

- Finding:

### G3 — graveyard
Collected by machine, see \`$EVIDENCE/g3.md\`. Reddit is covered by \`g3_graveyard.sh\`,
dead domains by \`g34_wayback.sh --quick <domain>\`. Product Hunt stays manual.

- Recurring cause of failure:
- Has anything STRUCTURALLY changed since then:

### G4 — competition
Reviews with **one and two stars** are the most valuable text here, because they
are the wedge in the buyer's own words. Prices only via h7_competitor_check.sh, never from a blog.

- Cheapest legal alternative (ceiling):
- Manual version on Fiverr/Upwork (floor):
- What the one- and two-star reviews say:

### G5 — proof of money
Complaints are free, payments are proof. Where does the money flow **already today**?
How many times a year does the problem happen? Is the buyer the same person as the sufferer?

- Finding, and how many INDEPENDENT sources support it:

### G6 — the math
**Use the monthly revenue target from \`gauntlet/my-situation.md\`, not a bigger one.**
How many customers at what price? If you need more than ~40, how do you get to
the fortieth without a budget? Does this compete with your current priority?

- The math:

## Score, seven dimensions of five points

| Dimension | 1 | 5 | Points |
|---|---|---|---|
| Pain intensity | nuisance | stops the business | |
| Urgency | someday | has a date | |
| Willingness to pay | no budget | already paying today | |
| Gap in the competition | saturated | nobody covers it | |
| **Distribution** | no legal channel | you can call them tomorrow | |
| Solo feasibility | needs a team | doable alone | |
| Scalability to the target | never | the path is clear | |

Below 15 is dead · 15–24 goes to the closest variant · above 24 goes on, with conditions.

## Closest working variant
**Mandatory with every KILL.** Do not end with "KILL", end with
"KILL as framed; the closest thing that survives that gate is X."
If there really is none, write why — but look for it first.

-

## What would revive this
-

## What I did not check
- A language, angle or source type that was not looked at, and why.

## Next cheapest step
- One thing this week that settles this gate for good.
- **It must not be something already settled under the green flag in \`gauntlet/my-situation.md\` or killed in \`gauntlet/killed-ideas.md\`.**
VERDICT

echo
echo "╔═══════════════════════════════════════════════════════╗"
echo "║  DONE"
echo "╚═══════════════════════════════════════════════════════╝"
printf '  %-18s %s\n' "verdict:"  "$OUTPUT"
printf '  %-18s %s\n' "evidence:" "$EVIDENCE/"
echo
echo "  The script does not judge. It collected G3 and G4, the rest is empty ON PURPOSE —"
echo "  an empty slot in a file is visible, a missing gate in your head is not."
echo
echo "  Next: read gauntlet/killed-ideas.md and the green flag section of"
echo "  gauntlet/my-situation.md, then fill in from G0 down"
echo "  and STOP at the first gate that fails."
exit 0
