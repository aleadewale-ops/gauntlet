#!/bin/bash
# rounds.sh — bounded hunt: AT MOST FIVE ROUNDS, and "nothing" is a valid outcome
#
# Spec: 2026-08-15.
#
# ── WHY BOUNDED AND NOT "UNTIL IT FINDS SOMETHING" ──
# A loop that may not end without a green light will end up producing one.
# That is exactly the failure this skill is built against: research that sets
# out to confirm an idea will confirm it — and reality will refute it later,
# when it is more expensive. Without an exit, after the fifteenth round the
# twelfth candidate would suddenly look like 25/35, because it had to.
#
# So: five rounds, a hard ceiling, and ENDING WITHOUT A FINDING IS A VALID OUTCOME.
# This script exists so that the ceiling cannot be skipped silently.
#
# ── CHANGED CRITERION, lesson from the August 2026 hunts ──
# Four hunts, 43 candidates, zero survivors. Three hunts died on saturation;
# the fourth died on BUYER ADOPTION in an UNsaturated niche — a farmer with a
# measured 60 hours of savings still said "people hate change".
#
#   Being unoccupied is not a signal. Pain is not a signal.
#   THE SIGNAL IS THAT THE BUYER ALREADY PAYS TODAY FOR A WORSE VERSION.
#
# So a round does not look for industries with pain, but for industries where
# money already flows: freelance listings with real budgets, agency price
# lists, job ads for repetitive work, and tools people already pay for.
#
# ── WHY A DIFFERENT ANGLE EACH ROUND, AND NOT FIVE RANDOM SEEDS ──
# The first version let all five rounds run on H0, i.e. on a random seed.
# That was caught right away: five random seeds are the SAME search five
# times, and it had returned nothing four times.
#
# A random seed fixes the bias in choosing the INDUSTRY. It does not fix that
# in a random industry the money is not visible. And the criterion of this
# hunt — "the buyer already pays for a worse version" — cannot be searched with
# a random word at all: from the word "curdler" you do not learn who pays whom.
#
# So each round has its own ANGLE on proven money, and an angle cannot be
# repeated. Five rounds are thus five different searches, not five draws.
#
# Usage:
#   ./rounds.sh start                          # new hunt, resets the counter
#   ./rounds.sh angles                         # which angles are available
#   ./rounds.sh status                         # where am I
#   ./rounds.sh round <angle> <sub1> <sub2>... # next round
#   ./rounds.sh finding "<description>"        # record this round's candidate
#   ./rounds.sh end                            # final report

set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="rounds_state.json"
MAX_ROUNDS=5

# Five angles, each on PROVEN money and not on pain. Ordered by how proven
# the switch already is — the first is the strongest.
ANGLES="orphaned switching paying salary agency"

angle_description() {
  case "$1" in
    orphaned)  echo "ORPHANED USERS of a dead tool — they paid for it, now they have no home.
      Strongest angle: the budget exists, the buying habit exists, the switch is FORCED.
      Tool: g3_graveyard.sh with the names of the industry's tools.
      Lesson from an earlier hunt: the shelf life is short. DipJar died on 11 Feb 2025
      and the gap closed within a year (Zeffy for free, Kind Kiosk as successor).
      So look for deaths LESS THAN A YEAR OLD." ;;
    switching) echo "PEOPLE WHO ARE SWITCHING RIGHT NOW — 'we are looking to switch CRM'.
      The switch is not an assumption, it is announced. They often name the price and the reason too.
      Tool: hunt-run.sh, then read the matches tagged 'buying' in h4_rank.sh.
      On 2026-08-15 this was the most frequent signal: 14 of 15 matches." ;;
    paying)    echo "WHAT PEOPLE SAY THEY PAY — literal numbers from their own mouths.
      Tells you the price AND which part of the pricing model angers them: lock-in, commission, setup fee.
      Tool: prices.sh <corpus> --scan, then by tool name.
      Works even where the price is hidden behind 'Contact sales'." ;;
    salary)    echo "SALARY ALREADY SPENT ON REPETITIVE WORK — a job ad is a
      spec with a budget. Whoever pays a person has already made the switch.
      Source: job ads, manual. There is no tool, and say so in the outcome." ;;
    agency)    echo "AGENCY AND FREELANCER PRICE LISTS for the MANUAL version — this is the FLOOR
      of the price and at the same time proof that someone already buys it.
      Source: manual. WATCH OUT, lesson from an earlier hunt: freelance marketplaces are a good signal for money and
      a BAD one for differentiation — the tasks with the most listings are the ones a cheap tool
      attacks first. Use it for the price, not for choosing the niche." ;;
    *) return 1 ;;
  esac
}

command -v jq >/dev/null || { echo "ERROR: jq is missing." >&2; exit 1; }

read_state() {
  if [ ! -f "$STATE" ]; then
    echo "ERROR: no hunt started ($STATE does not exist)." >&2
    echo "  Start with:  $0 start" >&2
    exit 1
  fi
  if ! jq -e . "$STATE" >/dev/null 2>"$STATE.err"; then
    echo "ERROR: $STATE is not valid JSON: $(head -c 200 "$STATE.err")" >&2
    rm -f "$STATE.err"; exit 1
  fi
  rm -f "$STATE.err"
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in

start)
  if [ -f "$STATE" ]; then
    R=$(jq -r '.round' "$STATE")
    echo "ERROR: a hunt is already running, round $R of $MAX_ROUNDS." >&2
    echo "  Continue with:  $0 round <angle> <sub...>   or finish with:  $0 end" >&2
    echo "  For a new hunt, move $STATE away first." >&2
    exit 1
  fi
  jq -n --arg d "$(date +%Y-%m-%d)" --argjson max "$MAX_ROUNDS" \
    '{started:$d, round:0, max:$max, tried:[], used_angles:[], findings:[], log:[]}' > "$STATE"
  cat <<'INTRO'
╔═══════════════════════════════════════════════════════════════╗
║  BOUNDED HUNT — AT MOST 5 ROUNDS                              ║
╚═══════════════════════════════════════════════════════════════╝

THE CRITERION OF THIS HUNT (changed after the August 2026 hunts):

  You are not looking for pain. You are not looking for an unoccupied niche.
  You are looking for an industry where THE BUYER ALREADY PAYS TODAY FOR A WORSE VERSION.

  Being unoccupied is not a signal — where nothing is occupied, the buyer often
  does not buy, and that is the reason, not a coincidence. Pain is not a signal
  either — a farmer with a measured 60 hours of savings still refused to switch.

  The switch must be ALREADY PROVEN: someone pays a freelancer, an agency,
  a cousin with a spreadsheet, or a bad tool. That is where the budget is and
  where the buying habit is.

EACH ROUND HAS ITS OWN ANGLE, AND AN ANGLE CANNOT BE REPEATED.

  Five random seeds are the same search five times, and it had returned
  nothing four times. A random seed fixes the bias in choosing the industry —
  it does not fix that in a random industry the money is not visible.

  See the angles with:  ./rounds.sh angles

BEFORE EVERY ROUND:
  · read gauntlet/killed-ideas.md and the 🟢 green flag section of
    gauntlet/my-situation.md
  · check subreddit names with map-subreddit.sh, otherwise an invented name
    reads as a dead industry

AFTER EVERY ROUND:
  · the bodies go into gauntlet/killed-ideas.md, even if there are none
  · "nothing" is a VALID outcome of a round AND of the whole hunt

Start the first round:  ./rounds.sh round <angle> <sub1> <sub2> ...
INTRO
  ;;

angles)
  echo "FIVE ANGLES ON PROVEN MONEY, ordered by how proven the switch already is."
  echo "Each round uses one, and an angle cannot be repeated."
  echo
  I=0
  for A in $ANGLES; do
    I=$((I+1))
    echo "  $I. $A"
    angle_description "$A" | sed 's/^/     /'
    echo
  done
  ;;

status)
  read_state
  jq -r '"hunt started: \(.started)
round: \(.round) of \(.max)
used angles (\(.used_angles|length)): \(.used_angles|join(", "))
subreddits tried (\(.tried|length)): \(.tried|join(", "))
findings (\(.findings|length)):"' "$STATE"
  USED=$(jq -r '.used_angles | join(" ")' "$STATE")
  REMAINING=""
  for A in $ANGLES; do
    case " $USED " in *" $A "*) ;; *) REMAINING="$REMAINING $A" ;; esac
  done
  [ -n "$REMAINING" ] && echo "still available:$REMAINING"
  jq -r '.findings[] | "  · [round \(.round)] \(.description)"' "$STATE"
  R=$(jq -r '.round' "$STATE")
  if [ "$R" -ge "$MAX_ROUNDS" ]; then
    echo
    echo "CEILING REACHED. The next command is:  $0 end"
  fi
  ;;

round)
  read_state
  R=$(jq -r '.round' "$STATE")

  # hard ceiling — the only reason this script exists
  if [ "$R" -ge "$MAX_ROUNDS" ]; then
    echo "STOP: $MAX_ROUNDS rounds are used up." >&2
    echo >&2
    echo "  A sixth round does not exist. If there is no green light after five rounds," >&2
    echo "  that is a finding about the BRIEF, not about the number of attempts — the" >&2
    echo "  stopping rule in SKILL.md says the same." >&2
    echo >&2
    echo "  Finish with:  $0 end" >&2
    exit 1
  fi

  ANGLE="${1:-}"
  if [ -z "$ANGLE" ] || ! angle_description "$ANGLE" >/dev/null 2>&1; then
    echo "ERROR: the first argument must be an ANGLE, not a subreddit." >&2
    echo "  Usage: $0 round <angle> <sub1> <sub2> ..." >&2
    echo >&2
    USED=$(jq -r '.used_angles | join(" ")' "$STATE")
    echo "  Available:" >&2
    for A in $ANGLES; do
      case " $USED " in
        *" $A "*) printf "    %-11s ✖ already used\n" "$A" >&2 ;;
        *)        printf "    %-11s ✅\n" "$A" >&2 ;;
      esac
    done
    echo >&2
    echo "  Descriptions:  $0 angles" >&2
    exit 1
  fi
  shift

  # an angle cannot be repeated — otherwise five rounds are five draws of the same search
  if jq -e --arg a "$ANGLE" '.used_angles | index($a)' "$STATE" >/dev/null; then
    echo "ERROR: angle \"$ANGLE\" has already been used in this hunt." >&2
    echo "  The round is NOT used up. Pick another one:  $0 angles" >&2
    exit 1
  fi

  [ $# -eq 0 ] && { echo "ERROR: give at least one subreddit." >&2; exit 1; }

  # for the "orphaned" angle the arguments are TOOL NAMES, for the others subreddits.
  # The list of tried items is shared anyway: searching the same name twice is
  # the same waste no matter what the name means.
  # do not repeat what was already tried — otherwise round 3 picks up round 1 again
  NEW=(); REPEATED=()
  for S in "$@"; do
    if jq -e --arg s "$S" '.tried | index($s)' "$STATE" >/dev/null; then
      REPEATED+=("$S")
    else
      NEW+=("$S")
    fi
  done

  if [ ${#REPEATED[@]} -gt 0 ]; then
    echo "⚠️ already tried in an earlier round, skipping: ${REPEATED[*]}" >&2
  fi
  if [ ${#NEW[@]} -eq 0 ]; then
    echo "ERROR: all the given subreddits have already been tried." >&2
    echo "  The round is NOT used up. Find other ones." >&2
    exit 1
  fi

  R=$((R+1))
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  ROUND $R of $MAX_ROUNDS · angle: $ANGLE"
  echo "║  ${NEW[*]}"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo "$(angle_description "$ANGLE")"
  echo

  # the round counts IMMEDIATELY, even if the hunt fails. Otherwise a failed
  # round would become free and the ceiling would not be a ceiling.
  jq --argjson r "$R" --arg angle "$ANGLE" \
     --argjson n "$(printf '%s\n' "${NEW[@]}" | jq -R . | jq -s .)" \
     --arg d "$(date +%Y-%m-%d_%H%M)" \
     '.round=$r | .tried += $n | .used_angles += [$angle]
      | .log += [{round:$r, time:$d, angle:$angle, subreddits:$n}]' \
     "$STATE" > "$STATE.new" && mv "$STATE.new" "$STATE"

  # WATCH OUT: THE ANGLE DECIDES THE TOOL. The first version ran hunt-run.sh
  # for every angle, which made the angles decorative — "orphaned" needs
  # g3_graveyard, not a subreddit harvest. An angle that does not change what
  # runs is not an angle.
  case "$ANGLE" in

    orphaned)
      # the arguments are TOOL NAMES, not subreddits
      echo "  (the arguments are read as TOOL NAMES, not subreddits)"
      echo
      ERRORS=0
      for T in "${NEW[@]}"; do
        bash "$DIR/g3_graveyard.sh" --deep "$T" || ERRORS=$((ERRORS+1))
        echo
      done
      [ "$ERRORS" -gt 0 ] && { echo "⚠️ $ERRORS queries failed. Round $R is used up anyway." >&2; exit 1; }
      ;;

    switching)
      bash "$DIR/hunt-run.sh" "${NEW[@]}" || {
        echo >&2; echo "⚠️ hunt-run.sh failed. Round $R is used up anyway." >&2; exit 1; }
      ;;

    paying)
      bash "$DIR/hunt-run.sh" "${NEW[@]}" || {
        echo >&2; echo "⚠️ hunt-run.sh failed. Round $R is used up anyway." >&2; exit 1; }
      echo
      echo "▶ angle paying — what people say they pay"
      bash "$DIR/prices.sh" master_corpus.json --scan || {
        echo "⚠️ prices.sh failed. Round $R is used up anyway." >&2; exit 1; }
      ;;

    salary|agency)
      # HAS NO TOOL, and that has to show. Silently running hunt-run.sh instead
      # would mean reporting the round as done when it was not.
      echo "  ⚠️ THIS ANGLE HAS NO TOOL. The work is manual, and that is not a flaw of the script."
      echo
      case "$ANGLE" in
        salary) cat <<'MANUAL'
    Look for job ads for REPETITIVE work in these industries:
      · "data entry", "transcription", "order processing", "back office"
      · part-time admin positions in a small business
    The salary in the ad is a PROVEN, recurring budget. Whoever pays a person
    has already made the switch — the only question is what they switch to next.
MANUAL
        ;;
        agency) cat <<'MANUAL'
    Look for agency and freelancer price lists for the MANUAL version.
    This is the FLOOR of the price and at the same time proof that someone already buys it.
    WATCH OUT (lesson from an earlier hunt): the tasks with the MOST listings are the ones
    a cheap tool attacks first. Use it for the PRICE, not for choosing the niche.
MANUAL
        ;;
      esac
      echo
      echo "    The round's arguments are recorded as search terms: ${NEW[*]}"
      ;;
  esac

  echo
  echo "───────────────────────────────────────────────────────"
  echo "Round $R of $MAX_ROUNDS finished."
  echo
  echo "  Now judge by this hunt's criterion:"
  echo "    does anyone in these matches ALREADY PAY for a worse version?"
  echo "    If the answer is 'no', the round returned nothing — and write that down."
  echo
  echo "  Record a candidate:  $0 finding \"<description>\""
  if [ "$R" -ge "$MAX_ROUNDS" ]; then
    echo "  CEILING REACHED. Next command:  $0 end"
  else
    echo "  Next round:          $0 round <other-angle> <sub...>"
    echo "  Which angles remain: $0 status"
  fi
  ;;

finding)
  read_state
  DESCRIPTION="${1:?Usage: rounds.sh finding \"<description>\"}"
  R=$(jq -r '.round' "$STATE")
  jq --arg o "$DESCRIPTION" --argjson r "$R" '.findings += [{round:$r, description:$o}]' \
     "$STATE" > "$STATE.new" && mv "$STATE.new" "$STATE"
  echo "recorded in round $R: $DESCRIPTION"
  ;;

end)
  read_state
  R=$(jq -r '.round' "$STATE")
  N=$(jq -r '.findings | length' "$STATE")
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  END OF THE BOUNDED HUNT"
  echo "╚═══════════════════════════════════════════════════════╝"
  jq -r '"  started:      \(.started)
  rounds:       \(.round) of \(.max)
  subreddits:   \(.tried|length)  (\(.tried|join(", ")))
  findings:     \(.findings|length)"' "$STATE"
  echo
  if [ "$N" -eq 0 ]; then
    cat <<END_REPORT
  NOTHING. This is a VALID outcome and not a failure of the hunt.

  After $R rounds with the criterion "the buyer already pays for a worse
  version", nobody survived. That is a finding about the BRIEF, not about the
  number of attempts — a sixth round would say the same, only more expensively.

  The stopping rule in SKILL.md: three ideas in a row dying at the same gate
  mean the brief is wrong. Now put the constraints themselves on the table and
  say which one is doing the killing.
END_REPORT
  else
    echo "  Candidates:"
    jq -r '.findings[] | "    · [round \(.round)] \(.description)"' "$STATE"
    echo
    echo "  Each one now goes through the FULL gates, one at a time:"
    echo "    $DIR/gates.sh \"<candidate>\" --competitor <name> --pricing <url>"
  fi
  echo
  echo "  MANDATORY: record this hunt in gauntlet/killed-ideas.md,"
  echo "  with the bodies and the reasons. Even if there are no findings — especially then."
  echo
  echo "  The state stays in $STATE. For a new hunt, move it away."
  ;;

*)
  echo "Usage: $0 {start|angles|status|round <angle> <sub...>|finding \"<description>\"|end}" >&2
  echo >&2
  echo "  Bounded hunt, at most $MAX_ROUNDS rounds. \"Nothing\" is a valid outcome." >&2
  exit 1
  ;;
esac
exit 0
