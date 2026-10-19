# Watchlist

Used by `/gauntlet watch` (Mode D). Anything findable through a public signal is usually taken
already, but **when something breaks, the cards are re-dealt for weeks or months.** This file is
where breaks are watched for, instead of learned about post mortem. Corpses are an asset only if
someone watches them.

**Last updated:** <date> · **Rhythm:** standing angles weekly, named list monthly

## Protocol

1. Two rhythms: the four standing angles **weekly** (report only hits), the named list
   **monthly** (those companies move slowly).
2. Report **only changes**. "All quiet" is one sentence, not a report.
3. On a fired trigger: **straight to Mode B, speed over analysis.** The window is shorter than a
   year, often shorter than a quarter.
4. Never delete rows. Mark fired / dead / closed with a date.
5. Every run: update "Last checked" and the date at the top.
6. New triggers from future verdicts are added here, not only in `killed-ideas.md`.

## Standing angles

### 1. Announced shutdowns and price rises — announcements, not deaths
Large companies announce shutdowns in advance ("this feature ends on 1 January"). An
announcement is a starting gun with months of lead; a death is old news (when Productiv died,
the gap closed the same week).
Where: official sunset/deprecation notices, killedbygoogle.com, sunsetproof.com/tracker (the
future-dates section), sudden waves of 1★ reviews that **name the function**. Signal: a forced
migration of users with data or habits, with a date in the future (pattern: Google Timeline →
Dawarich).

### 2. Tool deaths with orphaned payers
Where: sunsetproof.com/tracker, shutdown posts (Indie Hackers, r/SaaS, HN), and
`bash "$SKILL_DIR/g34_wayback.sh" --quick <domain>` on the names below. Enterprise deaths rarely
matter (unreachable buyer); SMB and consumer ones do.

### 3. Incumbent price shocks
Where: `bash "$SKILL_DIR/g34_wayback.sh" <domain>/pricing` on the names below. Signals: a rise
that leaves refugees (pattern: Canva Teams $120 → $500); a cheap plan removed; the pricing page
disappearing behind "contact us" (leaving the small customer).

### 4. New giants of the last month and their gaps
Where: top-chart movements in app stores, Google Trends breakouts, "fastest growing" coverage.
For each sudden riser:
- gaps **in its users' words** — its 1★/2★ reviews, "is there an app that works with X"
  threads (harvested, not guessed)
- **ToS risk is mandatory** — does the platform tolerate, support or sue companion tools
  (Niantic versus the IV checkers is the pattern of a killed ecosystem)
- the window is months; a gap already visible in comparison blogs is taken

## Regions — what the watchtower can see

The systematic sources are English and US-leaning. Breaks in other markets show up only through
the named list below and local-language searches. Do not read "nothing found in market X" as
"nothing happening in market X".

## Named watchlist

| What | Break signal | Check | Last checked | Status |
|---|---|---|---|---|
| <company or product> | <what would revive which killed idea> | `h7_competitor_check.sh <url>` or `g34_wayback.sh --quick <domain>` | | watching |
