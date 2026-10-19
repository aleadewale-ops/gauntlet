---
name: gauntlet
description: Use before building anything. Runs a business idea or market pain through ordered kill gates — can you reach the first ten buyers, legality, is-it-already-free, the graveyard of who tried and died, incumbent economics, evidence of money moving, and whether the arithmetic reaches your target. Its job is to KILL the idea cheaply, not to validate it. Trigger on "should I build this", "validate this idea", "kill this idea", "is this worth it", "find pains in <industry>", "invent an idea", "watchtower", or before scoping any new product.
argument-hint: <idea · industry to hunt pains in · "invent" for a generated idea · "watch" for the watchtower sweep>
---

# Gauntlet

An idea goes in. Almost always, a **KILL with a reason** comes out. Occasionally a GO that
has earned it.

**You read every verdict.** Nothing gets built off an unread GO.

In the commands below, `$SKILL_DIR` is this skill's directory (Claude Code prints it when the
skill loads). Your own files live in `gauntlet/` in the project you run Claude Code from (or in
`$GAUNTLET_HOME`); templates for them are in `$SKILL_DIR/templates/`.

## The constraint being removed

The usual founder process is: find a pain → narrow the niche → start solving → *then* research →
discover on the third pass that it is illegal, licensed, or already free. Weeks in.

**The order is the bug.** Validation runs last, so it can only ever deliver bad news
expensively. And it is usually the same two killers:

1. **Regulation** — a licence, a monopoly profession, a compliance regime
2. **It is already free** — an official free route, a platform-native feature, an incumbent's
   free tier

Both are cheap to check and both are fatal. Running them last is the most expensive possible
ordering.

## The principle

> **Order the gates by (cost of checking) ÷ (probability that it kills).**
> **The gate with the smallest ratio runs first.** Every gate is a hard STOP.

Cheap and lethal gives the smallest ratio, so it runs first. Expensive and unlikely to kill
gives the largest, so it runs last — or never, because something earlier already killed the
idea. (An early version wrote this as `cheapness ÷ lethality`, which sorts harmless gates first.
Only the sentence after it kept the ordering right. Formulas get read literally; check them.)

And:

> **Default to kill.** Ambiguity is a kill, not a maybe. A GO must be *earned* by naming the
> specific evidence that would have killed the idea and showing it is absent.

This skill is adversarial on purpose. A research pass that sets out to confirm an idea will
confirm it — and then reality will disconfirm it later, when it costs more.

## Two anti-patterns to refuse

**Do not narrow the niche before the idea has survived.** Narrowing feels like progress and is
the opposite: a narrower niche has *less* available evidence and the *same* regulatory
exposure. Narrowing is a reward for surviving the gauntlet, never a step inside it.

**Do not report "no competitors found" as a positive.** It almost always means the search was
wrong, or everyone who tried is dead and you did not look in the graveyard. Treat an empty
competitor result as a **failed search**, and say so.

---

## Before anything else — two reads and one rule

**Read `gauntlet/my-situation.md`.** If it does not exist, copy
`$SKILL_DIR/templates/my-situation.md` there, ask the user to fill it in, and stop: every gate
from G0 to G6 depends on it. It holds the user's constraints (budget, channels, languages, the
monthly revenue target), their assets, and the **recurring killers** — properties of the
user's situation, not of any idea. Check those before the gates, because they are cheaper than
every gate below.

**Read `gauntlet/killed-ideas.md`.** Killed ideas stay killed. Do not re-propose anything in it
unless its named revival trigger has actually fired.

**Obey the 🟢 Green flag section of `my-situation.md`.** What is listed there is the user's own
settled conclusion — usually the business they already run — not a research output. It is not a
candidate, it does not get gated, it does not get a score, and it is never "re-checked to see if
it still holds". Presenting someone's own established business back to them as a discovery
wastes their time; this happened in August 2026 and is why the section exists.

**The flag covers derivations of the product — and the boundary is the product, not the buyer.**
A generalisation of it ("the same pattern applied to other vendors"), an extension of it, or a
restatement of it in different words is still the flagged item. Do not score it, do not present
it as a hunt survivor, and do not put it in the corpse table either. It is simply out of play.
But **the same buyer with a genuinely different product is not a derivation** — a buyer the user
already reaches has twenty pains beside the flagged one, and those are in play.

**Never end on a green-flagged task.** The "cheapest next step" must not be something already
recorded under the flag.

**If a hunt's only survivor derives from the flag, the hunt returned nothing.** Say "nothing",
name what was searched, and stop. Do not fill the gap with a rewritten version of the user's
own work.

**🔒 Reserved areas.** `my-situation.md` may list populations or markets that are already
covered by a separate effort. The hunt does not seed from them and does not propose candidates
whose reach runs through them. A finding that lands inside them is **noted for that effort**,
never opened as a new hunt here. When that effort reports, its survivors enter **Mode B** like
any other idea; being reserved is a routing rule, not a free pass through the gates.

**Read the user's earlier research.** If `my-situation.md` lists due-diligence reports or past
verdicts, read them. In August 2026 this skill proposed an idea its user had killed that same
morning, because nobody looked.

### The source rule — binding, no exceptions

> **A number without a primary source and a date is not a number.**

This is the failure this skill exists to prevent, and it happened anyway in August 2026: search
summaries of SEO articles were carried into a finished presentation as facts, and an external
review traced one market-size figure to a report on cigarette smuggling.

**Never acceptable as a source for any figure:**
- Comparison blogs and "20 best X software" listicles — these exist to farm affiliate revenue
- A summary of a summary — if the search tool paraphrased a blog that paraphrased a report, you have nothing
- A vendor's own marketing page for a claim about the *market* (fine for that vendor's own price)
- Any figure you cannot restate as: *"<number>, from <named source>, published <date>"*

**Required instead:** the statute itself, the regulator's own publication, a survey with a
stated sample size and method, a real price page with the date you read it, or the actual words
of a named person with a URL. When you have only a weak source, **say the number is unverified
in the same sentence you use it** — never in a footnote.

State how many *independent* sources support each figure. One anecdote is one anecdote.

---

## Modes

**Mode A — Hunt.** `/gauntlet` with no argument, or with a domain.
Go find pains the user has not thought of, screen them, propose products. See Step H below.

**Mode B — Single idea.** `/gauntlet <a concrete idea>`
Run one idea through all gates in order. Start at Step 0.

**Mode C — Invented idea.** `/gauntlet invent`
Generate one idea, then try to kill it. See the Mode C section below.

**Mode D — Watchtower.** `/gauntlet watch`
Watch for breaks instead of hunting for gaps. See the Mode D section below.

If the argument is a specific proposition, use Mode B. `invent` (or an explicit ask to
generate) is Mode C. `watch` is Mode D. Anything else — a domain, a group of people, or
nothing at all — is Mode A.

### Mode D — Watchtower

**The one method the August 2026 measurements did not refute.** Twelve harvest hunts and four
Mode C generation runs showed that anything findable through a public signal is already taken —
but **when something breaks, the cards are re-dealt for weeks or months.** Google breaks
Timeline → Dawarich collects €15/mo. DipJar dies → Zeffy closes the gap within a year.
Productiv dies → the gap closes the same week. Every one of those breaks was learned about
post mortem. This mode exists so the next one is not.

**The watchlist is the asset.** Every killed idea leaves a named revival trigger; nobody watches
them unless something does. That list — plus the standing sweep angles — lives in
**`gauntlet/watchlist.md`** (template in `$SKILL_DIR/templates/watchlist.md`).

Procedure:

1. Read `gauntlet/watchlist.md`. It is the whole worklist.
2. Run the **four standing angles** (giant function breaks · tool deaths with orphaned
   payers · incumbent price shocks · **new giants of the last month and their gaps**) and
   then the **named watchlist**, using the checks written in each row — `g34_wayback.sh`
   and `h7_competitor_check.sh` are the fetchers; no new machinery.
3. **Report only changes.** "All quiet" is one sentence. Update the "Last checked" dates.
4. **On a fired trigger: straight to Mode B, speed over analysis.** The window is shorter
   than a year, often shorter than a quarter. A month of analysis is a missed window.
5. New triggers from future verdicts get a row in `watchlist.md` at verdict time.

For the "new giants" angle specifically: a sudden riser's gaps are harvested from **its own
users' words** (1★/2★ reviews, "is there an app that works with X" threads), never invented;
the **platform-ToS check is mandatory** (Niantic killing the IV-checker ecosystem is the
pattern); and a gap already visible in comparison blogs is already taken.

**Cadence — two rhythms:** the four standing angles run **weekly**, reporting only hits —
silence costs nothing and the fast windows (Productiv closed in a week) justify the frequency.
The named watchlist runs **monthly** — those companies move slowly. Angle 1 watches
**announcements, not deaths**: an announced sunset date is a starting gun with months of lead;
a death is old news. Be honest about regions: the systematic sources are English/US-leaning;
breaks in other markets are visible only through the named list and local-language searches.

### Mode C — Invented idea

Twelve harvest hunts in a row returned zero survivors and exhausted every reachable source
class. This mode inverts the funnel: instead of harvesting a real complaint, **invent an idea and
let the gates do all the work.**

Market posture for this mode: **worldwide, English first.** The user's home markets are an edge
to check when relevant, not the frame.

**The buyer in this mode is a consumer — B2C, not B2B.** That changes what G0 means, because a
consumer cannot be phoned or cold-emailed:

- **Admissible unfunded channels:** a shelf with built-in discovery — an app store, a
  marketplace (Etsy, Gumroad, Steam, Amazon, Chrome Web Store), organic content/SEO, or an
  existing community entered within its rules. The G0 question becomes: **which shelf, and
  is there evidence consumers already search that shelf for this?**
- **Not admissible:** paid ads (unless `my-situation.md` says there is an ad budget), and cold
  email to consumers — even where an opt-out regime makes it technically lawful, acquiring a
  consumer list puts an EU-based founder in GDPR territory with no defensible basis, and it does
  not convert. It is not a channel.
- **G6 sharpens:** consumer prices are small, so the monthly target means volume — say out loud
  how many paying consumers that is at the proposed price, and which shelf delivers that many
  without an ad budget. Platform ceilings apply with full force (Patreon averages roughly
  $75 per creator; most app categories are hit lotteries; most creator populations follow a
  power law).

**Generation heuristic — unbundle a giant.** Random invention dies because it enters with zero
evidence of money (in August 2026 the random-seed generator hit its own exhaustion criterion:
three runs, no candidate reached G5). Unbundling enters with G5 half-answered: **a function
inside a giant's paid product is already being paid for** — the question is only whether it is
neglected enough for a specialist to be 10× better. Calendly, Loom and Grammarly all lived in a
giant's neglected function.

**Aim only at giants (≥100M users / consumer platforms).** Aimed at small vertical SaaS, the
vendor ships the fix next quarter. A function worth $10M/yr is noise to Microsoft, and that
neglect is structural, not accidental.

Per iteration: seed → associate to a **giant consumer product** → enumerate its functions →
pick the one its own users say is neglected, **from their words** (1★/2★ app-store reviews
naming the function, forum threads asking "is there a standalone app for just X"). The
complaint harvest makes the candidate part-evidenced, not invented — label it **UNBUNDLED —
from users' words** and carry the quotes.

Three kill checks specific to this heuristic, run inside the existence check:

1. **Sherlock risk** — has the giant shipped improvements to this function in the last
   two years? A function under active development gets absorbed (Loom vs Teams recording).
2. **Good-enough inertia** — bundled-and-free next door is the default; G5 must show
   someone already pays for a standalone version, or begs for one in public.
3. **Standalone already exists** — the usual check; "X alternative" categories are
   often full.

Procedure — **an invent-until-it-does-not-exist loop, with a hard ceiling:**

1. Read `my-situation.md` and `killed-ideas.md` once, before the loop: the green flag, the
   reserved areas and the corpse list apply to every iteration. An invented idea that lands on
   a corpse counts as "exists".
2. `bash "$SKILL_DIR/seed-niches.sh" 3` — random seeds are **mandatory**, same rule as H0: a
   model-authored idea list carries the model's biases, and three hunts measured that. The seed
   breaks the chain; the model only interprets it.
3. From the seeds, invent **one concrete product proposition** — not a niche, a proposition
   with a buyer and a price. Bold, abstract, funny or practical — all allowed.
4. **Existence check, ten minutes maximum:** the G2.0 questions only — a SaaS or app doing
   this? a free tool? a native feature of the platform the buyer already uses? One search,
   one alternate phrasing. **If it exists: one-line kill row, pull a fresh seed, back to
   step 3.** No full gates on it, no mourning.
5. **Ceiling: five inventions per run.** An iteration is spent the moment its proposition
   is stated. Five out of five existing is a valid result — record it and stop. The loop
   may NOT run until it "wins"; a loop that may not finish without a survivor will
   eventually manufacture one, and that is the exact failure this skill exists to prevent.
6. The first proposition where the check finds nothing is **not good news yet** — an empty
   competitor result is a failed search until proven. Re-search it with different phrasing
   and run the graveyard (`g3_graveyard.sh`) before believing it. If it still comes up
   empty, remember: **unoccupied and profitable at the same time is rare for a reason** — the
   usual reason is that the buyer does not buy.
7. Only then: state it as the Step 0 falsifiable claim, **labelled INVENTED — no evidence**,
   and run the **full Mode B gates**, G0 downward, stop at first failure. The burden of proof
   lands on **G5**: an idea that exists nowhere must show real, sourced money moving toward the
   problem, or non-existence was the market's verdict, not a gap.
8. The verdict table lists every iteration's kill row alongside the survivor — corpses are
   what make a survivor trustworthy.

**The one rule that is different, and it is binding:** an invented idea enters with zero
evidence that the pain exists. Harvested candidates carry a real person's words; this one
carries nothing. Therefore **G5 — evidence of money — may never be left UNANSWERED in a Mode C
verdict.** A Mode C idea that dies early dies normally; but a Mode C idea cannot get a GO, or
even a "KILL, unless", until G5 has been answered with real, sourced payments. The idea
supplies the direction; the gates supply every fact.

Keep H1's warning in view: *a model inventing plausible problems produces plausible-sounding
rubbish.* That is why this mode is a **gate-first** exercise and not an idea generator — expect
the kill rate to be even higher than in harvest mode, and treat any survivor with double
suspicion. Default-to-kill applies twice here.

---

## Step H — The hunt (Mode A only)

`/gauntlet` **with no argument, or with only a domain**, is a hunt. The full procedure —
niche selection, harvest sources ranked by signal, the fit filter, the cheap-gate order, the
output shape and the cadence — lives in **`hunt.md`** in this skill directory. Read it now,
then work from it.

**A free hunt starts with the seed script, not with a list you wrote:**

```bash
bash "$SKILL_DIR/seed-niches.sh" 5
```

Random dictionary words seed the niches, and every proposed subreddit is verified before use.
This is step H0 in `hunt.md` and it is not optional — three hunts run off model-authored lists
landed in the same saturated categories every time. When `/gauntlet` is given a domain, that
domain replaces the seed, but the subreddit verification still applies.

For a single concrete idea, ignore `hunt.md` and continue at Step 0 below.

---

### Start Mode B with the driver

```bash
bash "$SKILL_DIR/gates.sh" "<the idea>" \
     --competitor <name> --pricing <url>          # both repeatable
```

It runs the two gates that can be run — **G3** through `g3_graveyard.sh` for the idea and for
every named competitor, and **G4** through `h7_competitor_check.sh` for every pricing URL — and
writes `verdict_<slug>_<timestamp>.md`: the full verdict skeleton with the gate table, the /35
grid, the falsifiable-claim template and the mandatory closing sections, every unrun gate marked
**UNANSWERED**. Evidence lands in `evidence_<slug>_<timestamp>/`.

**It does not judge, and that is deliberate.** G1 means reading the statute and deciding whether
it touches a protected profession. G2 means walking the free official route and naming the step
where people give up. G5 means reading the one-star reviews. None of that is scriptable —
**gathering is scriptable, judging is not.** The empty slots are the point: a blank in a file is
visible, a gate skipped in someone's head is not.

Fill it from G0 downwards and **stop at the first gate that fails.**

## Step 0 — State the idea as a falsifiable claim

Rewrite whatever the user said into this exact shape, and show it to them:

> **<Who>** currently does **<what>**, which costs them **<how much time or money>**.
> They would pay **<how much>** for **<what specific outcome>**.
> Today they solve it by **<current alternative>**.

If any slot cannot be filled, **that is the first finding.** An idea with an empty
"current alternative" slot has not been researched at all — nobody has a problem they solve
in no way whatsoever.

Then name the three things that, if true, would kill it. Those become the priority.

---

## Step 1 — Run the gates, in order

Read `references/research-sources.md` first. It maps each gate to the sites and APIs that
answer it, so you go straight to known sources instead of discovering where to look. That
registry is the efficiency mechanism — use it before any open web search.

**Its "Rules of engagement" section is binding and overrides anything below.** In short:
never more than three pages open · and **the moment a page asks to verify you are human, close
it and move on** — never click the checkbox, never log in, never work around it. Report the
blocked URL as a gap.

**The gates run sequentially, and so does everything inside them.** No agents are spawned.
(An early version promised "four agents at a time, in parallel within the gate", and none of
that ever happened — a documented capability that does not exist invites inventing more of
them.) The sequencing between gates is the whole point either way: a killed idea must not pay
for gates 4, 5 and 6.

### G0 — Can you reach the first ten? *(five minutes, and it goes first)*

Reach used to be the last gate. For a founder with no ad budget it is the binding constraint, so
every idea either died there or would have — after paying for five gates first. Three hunts with
zero survivors exposed that ordering as the bug.

Answer in one line, before anything else:

> **Can the user reach the first ten buyers through a channel listed as available in
> `my-situation.md` — a phone call, a relationship they already have, a referral, a shelf?**

That is the whole gate. Read the channels from `my-situation.md`; do not assume an ad budget,
an audience or reference customers the user did not list.

**Cold outreach is a legal question, not a tactic.** Check the buyer's jurisdiction from a
primary source. Examples recorded in August 2026 (verify before relying on them):

- **Cold B2B email is opt-in in several EU countries** — Austrian TKG 2021 §174, Italian Codice
  della Privacy art. 130, Slovenian ZEKom-2 art. 226 treat legal persons like natural ones;
  prior consent is required.
- **A LinkedIn connection is not consent to email advertising** (a German court decision,
  AG Düsseldorf, June 2026). Do not treat LinkedIn as a grey area.
- **The US is opt-out:** 15 U.S.C. §7704 (CAN-SPAM) allows commercial email until the recipient
  opts out, B2B or B2C alike, on conditions — no false headers, no deceptive subject line, the
  message identified as an advertisement, a valid postal address, opt-out honoured within
  **10 business days**. GDPR still governs how an EU-based sender processes prospect data
  (legitimate interest is the usual basis for B2B prospecting).

What usually remains lawful and unfunded: **the telephone**, an existing relationship, a
referral, a trade association, physical presence at a fair, and slow inbound content.

G0 does not soften: the idea must still name its channel and its first ten buyers. "Worldwide"
is a market, not a channel.

> **Kill if:** the only route to the first ten buyers is a channel unlawful in the buyer's
> jurisdiction, or one the user does not have (paid advertising without a budget). Do not run G1.
> Say which channel would have worked and why it is unavailable.

### G0.5 — Does it stand on something you already have?

An idea that starts from zero starts with distribution at zero. Three hunts in a row confirmed
this.

Read the **Assets** section of `my-situation.md`: proprietary data or measurements nobody else
has, a list of reachable buyers, signed partner terms, an API, languages, skills.

> **Not an automatic kill**, but state plainly which asset the idea reuses. "None" is a finding
> and it means the idea must clear G0 on strength alone.

### G1 — Legality and licensing

*The cheapest legal check, and it kills hardest.*

- Is this a regulated or licensed activity in each target country?
- Is there a **protected profession** whose monopoly this touches? Lawyers, accountants,
  tax advisers, estate agents, doctors, architects, insurance brokers, financial advisers.
  Guilds and chambers defend their perimeter and they lobby.
- Is there a criminal, not merely administrative, sanction? Ask this explicitly — it changes
  a fine into a prosecution.
- What data does it touch, and does that make the user a GDPR processor? A DPA, a sub-processor
  list, a data location and a 72-hour incident procedure are a real cost.
- Sector regimes: AI Act, DSA, PSD2, MiCA, medical devices, food, gambling.

**Country by country, in the local language, from primary sources.** Do not accept a blog's
summary of a statute. Get the statute, quote the article, name its number.

> **Kill if:** it requires a licence the user cannot get, or it touches a protected profession
> without a documented, current carve-out.

### G2 — Is it already free?

*The second cheapest, and the one founders keep missing.*

Ask in this order:

0. **Is there already a ~$39/month SaaS doing this?** Five minutes of search, and in August 2026
   it was the single most lethal check of the day: a $39/mo tool killed a whole service business
   idea, and it marketed itself explicitly against "$500–2,000/month retainers". A **tool**
   competing with it needs a reason to exist that is not "mine is nicer".

   **But an existing tool is not a kill on its own.** Every industry will have competition; look
   where money can still be made, not where nobody is. A licence price is the ceiling for a
   *product* and the floor for *work*. So when a tool exists, ask the second question before
   killing anything:

   > **What does it cost to make that tool actually work at a customer?** Implementation, data
   > migration, integrations, configuration against real pricing, maintenance.

   - **Self-serve in ten minutes, no integrations → the kill stands.** There is no work to sell
     beside it.
   - **Implementation is a multiple of the annual licence → that is the business**, and only
     G0 (reach) and G6 (arithmetic) may kill it. Worked example: a product configurator was
     killed on its €697/mo licence, while its own page stated implementation at €30,000–60,000
     and 4.8 months to go-live. That number was in the evidence the whole time.

   **Therefore read a pricing page for two things, not one:** the price, and the evidence of
   implementation work (setup fees, "typical project", time-to-go-live, an implementation
   partner programme).

   **And comparison blogs reverse meaning.** For a *product* they are proof a category is
   closed. For **work sold beside the product** they are proof that enough buyers exist to
   sustain an affiliate industry — a demand signal, not a tombstone.

   **The cost of this rule, stated honestly:** these gates are softer, so more ideas survive
   G2/G4 and the burden moves onto G0 and G6, which are more expensive to answer. That is the
   intended trade. Default-to-kill still applies — it just has to be earned at reach and
   arithmetic rather than at "someone else already sells software here".
1. Is there an **official free route**? Government portal, regulator, ombudsman, EU body.
   If yes: walk it end to end and describe every step. Then answer honestly — how hard is it,
   really? "It is complicated" is not a business model unless you can show where a normal
   person actually gets stuck.
2. Is it a **native feature** of a platform they already pay for? Could the incumbent ship
   it in one release?
3. Is there an **open-source or free tool** that does 80 % of it?
4. Does an incumbent's **free tier** cover it?
5. Is it a **feature, not a product**? If the whole thing is one screen, someone bigger will
   absorb it.

> **Kill if:** a free path exists and you cannot name, concretely, the step where real people
> abandon it. Advertising a paid service alongside a free official procedure also carries its
> own legal duty of disclosure — check that too.

### G3 — The graveyard

*The most informative gate and the one almost everyone skips.*

Do not look for competitors. Look for **corpses.**

- Who tried this and shut down? What did they say on the way out? Founders write generous
  post-mortems.
- Product Hunt launches with no activity since. Dead GitHub repos with real stars.
  Abandoned domains — check the Wayback Machine.
- Shutdown posts on Indie Hackers, r/SaaS, r/Entrepreneur, Hacker News.
- Acquired-then-killed products.

A dead competitor tells you more than a live one, because it tells you the failure mode
rather than the pitch.

```bash
bash "$SKILL_DIR/g3_graveyard.sh" "dipjar"               # a named tool
bash "$SKILL_DIR/g3_graveyard.sh" "restaurant inventory"  # a category
bash "$SKILL_DIR/g3_graveyard.sh" --deep "veevart"        # both directions

bash "$SKILL_DIR/g34_wayback.sh" --quick onwardapp.com    # is the domain a corpse?
```

**Reddit is where founders *talk* about dying; the archive is where the corpse actually is.**
A shut-down product vanishes from Google — its domain stops ranking, its pages 404 — but the
Wayback Machine still holds it, usually including the farewell notice on the last snapshot.
`g34_wayback.sh` compares the last archived snapshot against whether the live domain still
answers, and prints the link to that last snapshot. Verified in August 2026: `onwardapp.com`
(co-parenting, funded, shut down) → no answer from the domain, archived to 2025-06-21 →
flagged as a corpse. `carezone.com` → still answers 200 but unseen by the archive for 2,066
days → flagged as parked/abandoned rather than dead, which is the honest distinction.

**Search the product name, not the death word.** A product name is rare and therefore cheap;
"failed" and "shutting down" are common and the archive returns 422 for them. Searching the name
`dipjar` returns the tool's whole history back to 2019 in one call, including *"DipJar has ceased
operations"* dated 2025-02-14. The first version of the script searched the other way round,
pulled 606 posts carrying death words, and matched **none** of them to DipJar — a false negative
on a tool known to be dead. Death phrases are matched **locally**, where they are free: that
post says *"ceased operations"*, which no server-side word list contained.

For a multi-word niche the server cannot help at all, so the script falls back to harvesting
death words and filtering locally, and says so.

> **A 422 is "not looked at", never "nothing there".** The script names every combination the
> archive refused and refuses to let an incomplete sweep read as an empty graveyard.

> **Kill if:** several independent attempts died of the *same* cause and nothing structural
> has changed since. "I will just execute better" is not a structural change.
> **Note:** an empty graveyard AND an empty competitor set means the search failed. Go again
> with different phrasing before drawing any conclusion. `g3_graveyard.sh` covers **Reddit
> only**; dead domains are covered by `g34_wayback.sh`. **Product Hunt is still manual.**

### G4 — Live incumbents and their economics

Only reached by ideas that survived G1–G3.

- Who charges for this now, and **what exactly** — get real prices off real price pages,
  quoted, with dates. **Prices are read through the Jina Reader API** with
  `bash "$SKILL_DIR/h7_competitor_check.sh" <url>`. It renders the page, so JavaScript-built
  pricing tables come through, and it **saves** the page — which is the source and the date the
  source rule demands. Never a comparison blog, never a search summary.
- **Today's price is one frame of a film. Get the film.**
  `bash "$SKILL_DIR/g34_wayback.sh" <domain>/pricing` reads the incumbent's own pricing page
  back through the Wayback archive and prints what it said on each date it changed. Direction
  beats level: rising prices mean the incumbent has power and the market bears more; falling
  prices mean a race to the bottom you would be entering late; a **new lower tier** means they
  are already defending the cheap slot you were planning to enter; a pricing page that
  disappears behind "contact us" means they left the small customer. Verified in August 2026 on
  `gohighlevel.com/pricing`: $97/$297 steady through 2024, then $220/$497 appearing by 2025-03.
- What is the cheapest legitimate alternative? That is the ceiling.
- What does the manual version cost on Fiverr or Upwork? That is the floor.
- How well funded are they, and how fast could they cover this?
- What do their **one- and two-star reviews** say? That is the wedge, in the customer's own
  words — and it is the highest-value text in this entire gate.

> **Kill if:** the price gap between the free path and the cheapest incumbent is too narrow to
> live in, or a funded incumbent is already moving into it.
>
> That gap is the room for a competing *product*. Before killing, price the **work beside the
> incumbent** too — implementation, migration, integration, maintenance. A market with no room
> for another tool can still pay well for getting the existing tool to work. If that work is
> real, this gate does not kill; G0 and G6 decide.

### G5 — Evidence of money, not of complaining

Complaints are free. Payments are evidence.

- Where does the money **already** go for this problem? Some budget exists somewhere — find it.
- Are people paying for a worse version right now? Grey market, freelancers, agencies,
  manual services, or someone's cousin doing it in a spreadsheet.
- How often does the problem actually occur, per customer, per year? A severe pain that
  strikes once every five years is not a business.
- Is the buyer the same person as the sufferer? If not, the sale is much harder — name who
  signs.

> **Kill if:** you find complaints but no transactions. And be explicit about how many
> *independent* data points support any price figure. One Reddit anecdote is one anecdote.

### G6 — Does the arithmetic work

Reach moved to G0, where it belongs. What is left here is the maths. Read the **Target** and
**Capacity** sections of `my-situation.md`.

- **Use a reachable first target, not the dream number.** A large entry target (say €50k/month)
  forces you into large markets, large markets are the saturated ones, and every small real
  opportunity reads as a failure against it. In August 2026 lowering the entry target from
  €50k to €15k/month was the single biggest change in what survived. The big number is reached
  *from* the first one, not directly.
- How many customers at what price reach the target? If the answer needs more than about 40
  customers, ask how the fortieth is acquired without a budget.
- Cost to serve one customer, including the user's own hours and the failure cases.
- What breaks at ten customers, and at forty?
- **Does this compete with the current priority** listed in `my-situation.md`? An idea that
  survives every gate but eats the quarter's goal is a "not now, and here is when", not
  necessarily a kill.

> **Kill if:** the arithmetic to the target needs a customer count the user cannot acquire
> through the channel that passed G0.

---

## Step 2 — Verdict

One screen. Three allowed verdicts, and **a bare GO is not one of them.**

```
## <idea>

**Verdict: KILL — <reason in one sentence>**
      or  **KILL, unless <condition> — test: <cheapest experiment>, cost: <hours>, by: <date>**
      or  **GO, with conditions: <listed>**

**Score: <n>/35**   ·   Killed at gate **G<n>**. Later gates were not run.

| Gate | Result | Key finding | Source | Date |
|---|---|---|---|---|
| G0 reach the first ten | ✅ / ⛔ | ... | ... | ... |
| G0.5 which asset | asset name or "none" | | | |
| G1 legal | ... | | | |
| G2 already free | ... | | | |
| G3 graveyard | ... | | | |
| G4 incumbents | ... | | | |
| G5 evidence of money | ... | | | |
| G6 arithmetic | ... | | | |

**Closest working variant**
- <a concrete rework that survives the gate where the original fell — or "none, and why">

**What would revive it**
- <a concrete change in market, law or scale that would flip the verdict>

**What I did not check**
- <an angle, language or source type not looked at, and why>

**Cheapest next step**
- <one thing the user can do this week to settle the open gate for good>
```

### Score: seven dimensions, five points each

A binary verdict loses information. An idea at 11/35 and an idea at 26/35 can both come out as
"KILL", and they are not the same: the first is dead, the second is worth reworking.

| Dimension | 1 | 5 |
|---|---|---|
| Pain intensity | a nuisance | stops the business |
| Urgency | someday | has a date |
| Willingness to pay | no budget | paying today |
| Competitive gap | saturated | nobody covers it |
| **Distribution** | no lawful channel | can call tomorrow |
| Solo feasibility | needs a team | doable alone |
| Scalability to target | never | the path is clear |

Below 15/35 is dead. 15 to 24 goes to the closest variant. Above 24 goes ahead with conditions.

### Closest working variant — mandatory on every KILL

**This is the most important rule in the verdict.** In August 2026 three hunts produced
seventeen corpses and not one rework, because the verdict was a dead end.

Do not end with "KILL". End with **"KILL as stated; the closest thing that survives that gate
is X."**

Worked example: a candidate died because an existing configurator covered the market for
€697 a month. The closest variant was not "nothing" but **an implementation partner for that
configurator** — a different business that uses the same knowledge and gets distribution
through the vendor's existing partner programme.

If there really is no closest variant, say why. But look for it first.

### A conditional KILL carries a deadline

A watchlist that only ever grows is a graveyard with better manners. Every **"KILL, unless"**
must name three things in the verdict line itself: the **cheapest experiment** that resolves
the condition, its **cost in hours**, and a **date**. On that date the experiment has either
run or the kill finalises — no third state.

This is different from "What would revive it". A revival trigger is **external** — a law
changes, an incumbent dies — and is watched without a deadline (it goes into
`gauntlet/watchlist.md`), because the user cannot act on it. An "unless" condition is
**internal** — resolvable by the user's own action — and parking it without a date converts a
decision into a permanent maybe, which is the exact ambiguity this skill exists to kill.

For a GO, the table must show, gate by gate, **what would have killed it and why it did not.**
A GO without that is not a GO, it is an unexamined idea.

**"What would revive it"** is mandatory even on a kill. Markets move — a kill today with a named
trigger becomes a watchlist item instead of a dead end.

### On a GO — what runs next

This skill stops at the verdict. It does not scope and it does not build. On a GO, the next
steps are, in order: the cheapest real proof (talk to five of the first ten buyers), a short
product brief, and a cut-down MVP scope.

**Feed the next step the verdict, not the original idea.** Generic product and validation
prompts answer from priors unless they are handed the evidence, the prices and the sources this
gauntlet produced. Pass the verdict file.

Avoid tools that score ideas with a **compensatory scorecard** (where a high score on one
dimension averages away a fatal flaw on another) and competitor matrices with no source or date
requirement: they undo exactly what the gates established.

---

## Step 3 — Record it

On the user's confirmation:

- Verdict and reasoning → `gauntlet/verdicts/<slug>.md`. Killed ideas also get one row in
  `gauntlet/killed-ideas.md` with the reason and the revival trigger. Killed ideas are the most
  reusable asset here — they stop the same idea coming back in four months.
- A named revival trigger → one row in `gauntlet/watchlist.md`.
- If it changed a decision, say so plainly.

Never write without confirmation.

---

## Guardrails

- **Never return a bare GO.** Conditions, or it is not a GO.
- **Never treat "no competitors found" as good news.** It is a failed search until proven.
- **Never run a later gate after an earlier one killed it.** That is the saving.
- **Never narrow the niche to rescue an idea.** A narrower version of an illegal idea is
  still illegal.
- **Never cite a statute from a secondary source.** Get the article, quote it, name its number.
- **Never state a price without a source and a date**, and say how many independent sources
  support it.
- **Do not soften a kill.** A kill delivered clearly this week is worth more than a GO that
  collapses in month three. That is the entire purpose of this skill.
- **Never end on a bare KILL either.** Every kill carries a *closest working variant* or an
  explicit statement that none exists.
- **Never park a conditional kill without a dated experiment.** "KILL, unless" names the
  test, the hours and the date, or it is a plain KILL.

### The stopping rule

> **Three consecutive ideas killed at the same gate means the brief is wrong, not the ideas.**

Stop hunting. Do not look for a fourth. Put the constraints themselves on the table and say
which one is doing the killing.

In August 2026 seventeen ideas died, most of them at G2.0 or at reach, and the skill kept
producing more candidates instead of saying the obvious: the brief asked for a market that was
simultaneously big enough for paid ads and young enough that nobody had built a €39/month tool
for it. That intersection is close to empty, and three hunts were spent proving it.

### When you commission external deep research

The prompt must ask for **three** things, not one:

1. the strongest case **FOR**, with sources
2. the strongest case **AGAINST**, with sources
3. **"what would have to be true for this to work"**

A prompt that says *"your job is to kill this, a confirmatory answer is a failed answer"*
returns a kill every time, and it overreaches to get there. Two such reports came back in
August 2026: one "refuted" a market-size figure by string-matching it to a report on cigarette
smuggling, the other inflated the EU Machinery Regulation into existential liability for a tool
that produces a commercial quote. Both distortions ran in the kill direction because the prompt
demanded it. Adversarial is right; adversarial-only is not.

### Training wheels

Read every verdict yourself until three verdicts have held up against what you later learned
building or selling. Only then trust a verdict you have not read.
