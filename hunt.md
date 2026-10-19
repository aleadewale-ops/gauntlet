# Step H — The hunt (Mode A only)

Read this file only when `/gauntlet` is called **with no argument or with a domain**. For a
single concrete idea, stay in `SKILL.md` and start at Step 0.

`$SKILL_DIR` is this skill's directory (Claude Code prints it when the skill loads).

The binding rules in `SKILL.md` still apply here in full: read `gauntlet/my-situation.md` and
`gauntlet/killed-ideas.md` first, read any earlier verdicts in `gauntlet/verdicts/`, and obey
the source rule.

**Anything listed as a settled conclusion (green flag) in `gauntlet/my-situation.md` is out of
scope for the hunt.** It is settled, it is your own conclusion, and it never appears as a
candidate. Adjacent findings are presented as extensions of it, not as discoveries.

**The reserved areas in `gauntlet/my-situation.md` are out of scope too.** These are customer
populations, partners or ecosystems that another piece of research is already covering. Do not
seed from them, do not propose candidates whose reach runs through them; route any finding that
lands there to that research and say so.

## Bounded hunting — five rounds, and "nothing" is a valid outcome

```bash
bash "$SKILL_DIR/rounds.sh" start
bash "$SKILL_DIR/rounds.sh" angles                       # the five angles
bash "$SKILL_DIR/rounds.sh" round <angle> <sub...>
bash "$SKILL_DIR/rounds.sh" finding "<candidate>"
bash "$SKILL_DIR/rounds.sh" end
```

Use this when the instruction is "keep looking", not for a single hunt. It was added in August
2026 after four hunts produced 43 candidates and zero survivors.

> **A loop that may not finish without a green light will eventually produce one.** That is
> exactly the failure this skill was built against: research that sets out to confirm will
> confirm, and reality disconfirms later, when it costs more. Without an exit, the twelfth
> candidate starts looking like 25/35 by round fifteen, because it has to.

So: **five rounds, a hard ceiling, and finishing with nothing is a valid result.** The script
exists so the ceiling cannot be quietly stepped over — round six exits 1 and points at the
stopping rule. A round is **spent the moment it starts**, even if `hunt-run.sh` then fails,
because a free failed round is not a ceiling. Subreddits already tried are refused, so round 3
cannot re-harvest round 1 — and that refusal does **not** consume a round.

### The criterion changes for these rounds

The lesson behind it: three earlier hunts all died on saturation; the fourth died on **buyer
adoption in an unsaturated niche** — a dairy farmer with a measured 60 hours of savings still
said *"people hate change"*.

> **Do not hunt pain. Do not hunt unoccupied niches.**
> **Hunt for an industry where the buyer already pays for a worse version.**

Unoccupied is not a signal — where nothing is occupied, the buyer often does not buy, and that
is the reason rather than an accident. Pain is not a signal either. **Switching has to be
already proven:** someone paying a freelancer, an agency, a cousin with a spreadsheet, or a bad
tool. That is where the budget sits and where the habit of buying already exists.

### Each round takes a different angle, and an angle cannot be repeated

The first version let all five rounds run off H0, meaning off a random seed. **Five random seeds
is the same search five times** — the one that has already returned nothing four times. A random
seed fixes bias in *which industry*; it does nothing about money not being visible in a random
industry. And this hunt's criterion cannot be searched by random word at all: `curdler` does not
tell you who pays whom.

So each round spends one of five angles, ordered by how firmly switching is already proven:

| Angle | What it looks for | Tooled? |
|---|---|---|
| `orphaned` | **orphaned users of a dead tool** — budget exists, buying habit exists, switching is forced | `g3_graveyard.sh` |
| `switching` | people **announcing a switch right now** — they usually name the incumbent and the price | `hunt-run.sh` + the buying signal |
| `paying` | **what people say they pay**, verbatim — and which part of the pricing model angers them | `prices.sh --scan` |
| `salary` | **a salary already spent** on repetitive work — a job ad is a spec with a budget | manual |
| `agency` | **agency and freelance rate cards** for the manual version — the price floor | manual |

Two warnings carried into the angle descriptions from earlier hunts, so they cannot be
forgotten: orphaned users are a signal **with a short shelf life** (DipJar died on 2025-02-11
and Zeffy had closed the gap within a year), and freelance marketplaces are a good signal for
money but a **bad** one for differentiation (the tasks with the most listings are exactly the
ones a cheap tool attacks first).

Each round still writes its corpses to `gauntlet/killed-ideas.md`, including the rounds that
find nothing — especially those.

## H0 — Niche selection: industry by money criterion first, randomness inside it

**Amended August 2026:** a random seed across ALL industries fixes model bias but decorrelates
the hunt from money — and four hunts proved it. So: **pick the industry by a money criterion
first** (the buyer already pays for a worse version; many tools in play; a platform shift under
~1.5 years old), then let randomness work *inside* it — which subreddit, which angle, which
competitor. The random dictionary seed remains the fallback when no money-qualified industry is
on the table, and everything below still applies to it.

**This step is mandatory and it runs first.**

A niche list written by the model carries the model's biases. In August 2026 three hunts ran
off lists this skill authored, and they kept landing in the same saturated consumer categories.
A random dictionary word breaks that chain. One day's seeds were *dolabra*, *untabled*, *ataxy*,
*arca* and *loveful* — no model reaches those associations on its own.

```bash
bash "$SKILL_DIR/seed-niches.sh" 5                          # 1. seeds
bash "$SKILL_DIR/map-subreddit.sh" sub1 sub2 sub3 ...       # 2. verify the mapping
```

**How to work it:**

1. Run `seed-niches.sh`. Each seed is a random 4–8 letter lowercase dictionary word.
2. From each seed derive **two ultra-specific B2B niches or micro-professions**. The link to
   the word may be semantic, phonetic or associative — be bold, that is the point. Avoid
   general categories: never "business", "small business", "entrepreneurs".
3. For each niche, propose **two or three** candidate subreddit names, not one.
4. Run `map-subreddit.sh` over all of them. **Never skip this.** A model invents subreddit
   names, and an invented name reads as "this industry has no pain" — a false kill.

`map-subreddit.sh` reports members, archived posts, archived comments and subreddit type, and
separates three states that used to look identical: *does not exist*, *exists but too small*,
*usable*. It also refuses to report an error as a missing subreddit.

> **Take the one with the most POSTS, not the most members.** For harvesting, the archive is
> what matters. `r/selfstorage` has 4,870 members but 3,192 archived posts and is perfectly
> usable; a 5,000-member floor would have thrown it away.

> **A niche with no live source under any name is a finding, not a failure.** No community
> means no reachable pain source, however real the problem is. Record it and pull a new seed.

Two things this step caught on its first day: `fitnessbusiness` and `gymowners` do not exist at
all — an entire industry was nearly written off on a spelling — and five more invented names
(`nonprofit_governance`, `BoardGovernance`, `ArtHandlers`, `homecare`, `Museum_Registrars`)
returned nothing.

Note on the source: `reddit.com/r/X/about.json` returned **403** in testing (August 2026,
verified on three subreddits), so member counts come from the arctic-shift archive instead.

**The script never calls a model.** It prints the seed and the instruction; the main model
derives the niches. The seed is the part that breaks the bias, not the model that reads it.
See the no-API-key rule under H3.

---

### `hunt-run.sh` — H1, H2 and H4 in one run

```bash
bash "$SKILL_DIR/hunt-run.sh" msp TheBrewery escaperooms dairyfarming
bash "$SKILL_DIR/hunt-run.sh" --window 220 --top 25 msp dairyfarming
```

The arguments are subreddit names (`msp` is r/msp, managed service providers). It harvests
every subreddit, merges into `master_corpus.json`, filters, ranks, archives the raw captures
into `archive/<timestamp>/`, and prints a per-subreddit breakdown. **Verify the names with
`map-subreddit.sh` first** — `hunt-run.sh` will harvest whatever you type.

Four things it deliberately does differently from the obvious implementation:

- **It merges an explicit file list, never `harvest_*.json`.** The glob also picks up captures
  left over from earlier runs and folds industries you did not ask for into the corpus, with
  nothing on screen to show it.
- **It archives the raw captures, it does not delete them.** `prices.sh` reads prices out of
  the harvested corpus, so deleting it would remove the second of H3's two price sources.
- **A failed subreddit does not stop the run**, and the summary names it separately: *"these
  are not industries without pain, these are industries I did not look at."*
- **It keeps per-subreddit counts** alongside the merged corpus. In one run r/msp gave 11 hits
  and r/escaperooms gave 0 of 381 — and that zero was itself the finding (a player community,
  not an operator one). Merged into one corpus it would have vanished.

Related fix at the source: `h1_harvest.sh` builds into a temp file and only moves it into place
on success, so **a failed harvest leaves no file at all**. It used to leave an empty
`harvest_<sub>.json` behind, which the next `jq -s add` would happily merge as valid data.

## H1 — Do not generate. Harvest.

> **A model inventing plausible problems produces plausible-sounding rubbish.**
> It fails on first contact because nothing about it was ever true.

Every candidate must come from **a real person who wrote the complaint down unprompted**, with
a URL and a date. If a candidate has no such source, it is not a candidate. This single rule
is what separates this from an idea-generator.

Sources are in `references/research-sources.md` under **G0 — Pain harvest**. Ranked by how
strong the signal is:

| Signal | Why it is strong |
|---|---|
| **Freelance gigs with volume** | Money already moves, for the manual version. Strongest signal there is. |
| **1★ and 2★ reviews** | They already pay, and they are telling you exactly what is broken |
| **Job ads for repetitive roles** | A salary is being spent on it. The ad is a spec with a budget attached |
| **Agency and consultant rate cards** | What they charge for is what hurts |
| **Regulatory deadlines** | Forced demand, with a date on it |
| **Repeated questions with no good answer** | A gap, visible in public |
| **"We track this in a spreadsheet"** | An admission of a manual process |
| **Dying or discontinued tools** | Orphaned users with an existing budget and no home |

Run these **English-first, worldwide** by default, then add a supplementary sweep in each other
language listed in `gauntlet/my-situation.md` where the niche touches that region. A pain found
in your own region is still worth more *per finding*, because you can phone the person who
wrote it; it just should not set the frame. The lesson: a founder working in Slovenian and
Croatian ran twelve hunts before accepting that a small-language source base is too thin to
carry a hunt — the open business forums were dead or walled.

**When a source is unreachable, say so and do not substitute.** In one August 2026 hunt Reddit,
Upwork and RemoteOK were all blocked, and the hunt proceeded on search-engine summaries instead.
That is how the strongest signal in the table above — real people's words — silently dropped
out of a hunt that still reported confident findings.

### The calls you are already making — capture, do not interview

If your work already puts you on the phone with buyers (sales calls, support calls, customer
check-ins), each call ends with a buyer on the line — the one signal class the sources above
struggle to reach. Ask one discovery question at the end of each call, after the business of
the call is done, in the buyer's language:

> *"Apart from this, what eats most of your time? What do you already pay an outside person or
> a tool for?"*

The verbatim answer, with the date and the organisation's name, goes into `harvest_calls.json`
in the same flat shape H1 produces — `{"id":…,"type":"call","body":"<verbatim answer>",
"created_utc":…,"score":0,"permalink":"<organisation>"}` — so `h2_filter.sh`, `prices.sh` and
`h4_rank.sh` read it with no changes. An answer here outranks every row in the signal table
above: a real, dated, *reachable* person, often naming what they already pay for — G5 evidence
collected for free.

Routing respects the reserved areas at the top of this file: an answer whose opportunity runs
through a reserved population is passed to the research that covers it, not hunted here. What
feeds the hunt is the rest — the supplier the customer complains about, a third party's broken
process, the tool someone else charges them for.

### Harvest comments, not just posts

```bash
bash "$SKILL_DIR/h1_harvest.sh" <subreddit>   # → harvest_<sub>.json
```

**The complaints are in the comments.** In August 2026 a hunt pulled 5,400 posts and fetched
comments for exactly eight hand-picked ones. The best find of that day — Veevart, with two
named weaknesses from two independent users — sat on a post with **two comments** and nearly
slipped past.

The script uses a **1:3 ratio**: one call for posts (context, the shape of the problem), three
for comments (candour, swearing, and the names of the tools people actually pay for), paginated
backwards with `before=<oldest created_utc>`, and `sleep 2` between every single call.

> **The N+1 trap it avoids:** pulling 100 posts and then calling the comments endpoint per post
> is 101 calls per subreddit, which exhausts the rate limit or takes hours.
> `comments/search?subreddit=X` works at subreddit level — **one call for 100 comments.**

Output is a **flat JSON array** in `harvest_<sub>.json`, posts and comments normalised into one
shape so H2 has an easy job. A post's title and selftext are merged into `body`:
`{"id":…,"type":"post"|"comment","body":…,"created_utc":…,"score":…,"permalink":…}`

**Strict mode, and it is the point of the rewrite.** No `2>/dev/null` anywhere in the code.
Three failure modes all look like "empty result" if you do not catch them, and all three
happened on the same day:

1. HTTP is not 200
2. **the body carries `{"error":"Timeout. Maybe slow down a bit"}` at HTTP 200** — the sneaky one
3. the response is not valid JSON, or has no `.data`

Any of them prints the reason and exits 1. It never continues quietly. A zero-unit harvest is
also an error, not a result — check the subreddit name with `map-subreddit.sh`.

Downstream scripts accept both this array and the older JSONL, so nothing breaks.

Target 20–40 raw candidates. Do not filter yet.

## H2 — Filter the corpus, then fit-filter what survives

### Machine filter: four languages in one pass

```bash
bash "$SKILL_DIR/h2_filter.sh" harvest_<sub>.json [window] > filtered.jsonl
bash "$SKILL_DIR/h2_validate.sh" harvest_<sub>.json        # run on every dictionary change
```

The architecture: **data separated from logic.** Word stems live in four text files; the script
assembles them into a proximity regex at runtime. Adding a term is one line in a text file,
never a code change.

| File | Signal | Why it is separate |
|---|---|---|
| `tech_stems.txt` | a tool is being discussed | the anchor — everything must sit near one of these |
| `pain_stems.txt` | **emotion** | "I hate this system", "it's a catastrophe" |
| `process_stems.txt` | **friction** | "every month I retype this into a spreadsheet" |
| `shop_stems.txt` | **buying intent** | "we are looking to switch CRM databases" |

`NEGATIVE_SIGNAL = pain | process`, and the filter matches **tech within the window of
(negative | shopping)**. The output breaks the hits down by which signal fired.

**Friction beats emotion.** Anger says something is disliked; friction says *what is being done
by hand*, which is the part that can actually be removed. Keep them separate so you can see
which kind of find you have.

The shipped dictionaries cover English, Slovenian, Croatian and Italian. Add stems for your own
languages the same way, and run `h2_validate.sh` after every change.

Stems, not whole words, because Slavic and Romance languages inflect: `drag[oiae]` covers
Slovenian drago/draga/dragi (expensive), `pocas` covers pocasi/pocasen (slow). **No language
detection** — the Croatian *"Ovaj sustav je sporo smeće"* is caught by the same net as *"This
software is slow garbage"*, and detection would only add latency and bugs.

> **Some stems are domain-dependent and no amount of lengthening fixes them.** Measured on 385
> units of r/MuseumPros: `support` hit 22 times meaning *donor support* and *supportive
> colleagues*, and `ticket` hit `TICKETING` — which in a museum is **admission tickets**, the
> core business vocabulary, not a helpdesk ticket. In r/msp both would be true friction signals.
> They were narrowed to phrases that carry friction in any domain: `support ticket`,
> `raise a ticket`, `helpdesk`. The problem was meaning in context, not word shape.

> **Measured against real Slovenian, Croatian and Italian material in August 2026**, 1,032 units
> from r/Slovenia, r/croatia and r/italy. Until then these dictionaries stood on the model's
> knowledge of the languages and six sentences written by hand. The measurement found three
> false positives that lengthening does not fix: `sporo` (slow) matched Slovenian
> **sporočilo** (message), `zanic` (lousy) matched **Zanicchi** (an Italian singer), and `ručn`
> (by hand) matched **ručnik** — which is Croatian for *towel*. The fix was a **trailing
> anchor**, not a longer stem: a `.txt` line written `sporo\b` becomes `\bsporo\b`. Use that
> when the stem is already a whole word. Regression after the fix: six true SL/HR/IT/EN
> complaints still pass, all three false positives now blocked, including the Croatian greeting
> *"Drago mi je"* (nice to meet you).

> **One stem is knowingly imprecise.** `drag[oiae]` runs at about half precision — right on
> *"draga stvar"* (an expensive thing) and *"stanovanja so draga"* (flats are expensive), wrong
> on the place name *Draga* and on *"Drago mi je"*. It stays, because it still has to sit within
> 160 characters of a tool stem, and dropping it would lose real complaints about price.
> `predrag`, `preskup` and `previsok` (too expensive, too high) were added alongside it as the
> unambiguous forms.

> **Every stem is anchored with `\b`, and this is not optional.** Measured on 318 English units:
> unanchored `hate` matched **"w-hate-ver"**, `lent` matched equivalent/plenty/talent, `spor`
> matched sport/sports, `stran` matched stranger. Anchoring fixed most of it; where it did not,
> the stem was **lengthened** in the dictionary — `spor`→`sporo` (8→0), `lent`→`lento` (6→0).

**`h2_validate.sh` exists because a dictionary without a validator rots silently.** Run it
whenever anyone adds a stem. It separates two different problems:

- **⚠️ CLASH** — free hits exceed anchored hits, so the stem matches mid-word. A bug. Lengthen it.
- **◐ BROAD** — anchored hits exceed 5 % of the corpus, so the stem is too common to carry
  signal alone. Not a bug: `program` hit 28 of 318 in a fitness corpus because it means
  "training program" there. Such a stem only works paired with another.

### `_corpus.sh` — every consumer reads the corpus through one door

`h2_filter.sh`, `h2_validate.sh` and `prices.sh` all take the same input, and all three used to
carry their own copy of "is this a JSON array or JSONL". Two of those copies were wrong, in the
same way and on the same day: **a read failure that came out looking like a legitimate empty
result.** The validator reported every stem as zero hits because it could not parse the array
format at all.

Source it, set one trap, call it once. It never returns a value — it sets globals, so it must
not be wrapped in `$(...)`, which runs in a subshell where those globals die.

```bash
. "$DIR/_corpus.sh"
trap corpus_cleanup EXIT          # ONE trap for the whole script
corpus_normalize "$1"             # sets $CORPUS, $CORPUS_N, $CORPUS_FORMAT
```

It refuses, loudly and with a specific message, on all seven ways this input goes wrong: file
missing, zero bytes, HTML error page saved instead of data, truncated array, one unparseable
JSONL line, valid JSON with zero units, and units with no `.body` field. **None of them may
come out as "no hits".** That distinction is the whole point of the file — the same rule as the
ban on `2>/dev/null`.

### Then the fit filter

Most discovered pain is real and useless to you. Filter hard, and filter first — it is free.

Read `gauntlet/my-situation.md` (constraints, assets, channels, capacity) and the recurring
killers recorded in `gauntlet/killed-ideas.md`.

### The asset rule

> **At least three of every five candidates must reuse something you already have.**

Three hunts produced seventeen candidates and zero survivors. Every one of them started from
zero: no audience, no reference customer, no data nobody else has. They all died at reach,
because an idea that starts from zero starts with distribution at zero.

Take your assets from the assets list in `gauntlet/my-situation.md`, and make each candidate
name which one it stands on. Typical assets: a measurement you took yourself that nobody else
has; a list of prospective customers you can phone; a signed partner agreement or API access;
the languages you speak; the ability to build the thing yourself, so no engineering cost.

An asset can sit inside a reserved area (see the top of this file). It still counts as
something an idea can stand on technically — the data, the API knowledge, the languages — but a
candidate whose *distribution* runs through a reserved population belongs to the research that
covers it, not to the hunt.

A candidate that reuses none of your assets is not banned, but it must clear reach on its own
strength, and it almost never does.

### Then drop anything where you cannot answer yes

Every answer comes from `gauntlet/my-situation.md`. If the file does not say, ask once and add
the answer to the file.

- **Reach** — can you get to this buyer **through a channel that is lawful in the buyer's
  jurisdiction and that you can actually use** (no ad budget means no paid ads; a ban on cold
  email means no cold email)? Check the channel rules of the *buyer's* country from a primary
  source, not your own. Example: a founder in Slovenia found that cold B2B email is unlawful in
  SI, AT and IT, and that a June 2026 German court ruling (AG Düsseldorf) had closed LinkedIn
  InMail for those buyers too — but those bans bind EU buyers; for a US buyer, CAN-SPAM is
  opt-out, not opt-in. The candidate names its channel either way.
- **Language** — one you work in. English means worldwide is in play, not just one region.
- **Build** — something you can deliver yourself with Claude as co-builder: software,
  automations, integrations, structured data, quoting, documents, analysis, content, research
  work. Still not: hardware, physical logistics, a marketplace needing two-sided liquidity, or
  anything needing a team — unless your situation file says you have one.
- **Constraints** — your hard limits from the situation file. Common ones: never holding
  customer passwords; GDPR-processor duties, which carry a real cost; hard-SLA duties you would
  carry alone.
- **Capacity** — your hours, energy and deadlines as the situation file states them. A solo
  founder with a fixed build window cannot take on an idea that needs a year of support.

Say how many candidates the fit filter removed. That number is information.

## H3 — Cheap gates only

Survivors go through **G1, G2 and G3 only**. Never G4–G6 at this stage — that is what makes
the hunt affordable. G4–G6 are for the one you pick.

Add one gate before G1, because it is cheaper than all of them and has killed more ideas than
any other single check:

> **Is there already a ~$39/month SaaS doing this?** Five minutes of search. If yes, a service
> reselling the same work is dead, and so is a tool competing with it.

### Prices come from two primary sources, never from a blog

```bash
bash "$SKILL_DIR/prices.sh" harvest_<sub>.json --scan          # what mentions money at all
bash "$SKILL_DIR/prices.sh" harvest_<sub>.json "Mindbody" ...  # a named tool
```

| Source | Method | Good for |
|---|---|---|
| **1. The vendor's own page** | `h7_competitor_check.sh <url>`, then read the saved Markdown | Tools with a public SaaS price |
| **2. What users say they pay** | `prices.sh` over the H1 corpus | Everything hidden behind "Contact sales" |

```bash
bash "$SKILL_DIR/h7_competitor_check.sh" veevart.com/pricing
# → competitor_<host>_<path>_<timestamp>.md          the raw page
# → competitor_<host>_<path>_<timestamp>.prompt.txt  the extraction prompt
```

**No API key lives in any script in this directory.** A key in a script ends up in a commit
eventually, and those calls bill separately from the Claude Code you already pay for. Claude
Code is already an authenticated agent, so the scripts are pure **fetchers** — bash does the
dirty work of retrieval, the main model does the judging. `h7_competitor_check.sh` saves the
page and writes the extraction prompt beside it; read the prompt, then read the page, then
extract. `seed-niches.sh` likewise emits the seed and the instruction, never a model call.

It reads through **Jina Reader** (`r.jina.ai`) rather than WebFetch because Jina renders the
page, so JavaScript-built pricing tables come through, and because the response is **saved** —
which is the source and the date the source rule demands.

> **Four failure modes, and three of them look like a valid page.** Measured in August 2026:
> curl failure, **HTTP 422 for a domain that will not resolve**, HTTP 429 rate limit, and the
> nasty one — **a missing page on a real domain returns HTTP 200 with ~3 KB of navigation and an
> empty `Title:` line.** On that input a model honestly reports "no prices published", and you
> read it as a finding about the company instead of a typo in your URL. The script warns loudly
> and stamps the warning into both output files.

> **Filenames carry host, path and seconds, and the script refuses to overwrite.** The first
> version used host plus minute only, and testing immediately clobbered the real pricing page
> with a 404 page fetched from the same domain in the same minute. Silent data loss, same family
> as an error that reads as an empty result.

First real run: `veevart.com/pricing` returned 4,049 bytes and **no prices at all** — "Contact
Us for Pricing", "Book a Demo", tailored to institution size. That is a legitimate G4 finding,
not a gap, and it is exactly the case where source 2 becomes the better one.

Source 2 is often the better one: it gives the price **and** the part of the pricing model that
angers people — the lock-in, the transaction fee, the setup fee, the increase. That is the wedge,
in the customer's own words.

**Do not use a search engine for either.** Comparison blogs and "20 best X software" listicles
are affiliate SEO; their figures are stale or invented, and most B2B tools hide price behind a
demo call so the blog is guessing. Three notes from testing in August 2026:

- `site:` **is not honoured** by WebSearch. The `site:reddit.com "<tool>" "$/mo"` approach does
  not work — it returns generic articles.
- arctic-shift *does* support server-side `body=` text search, but it is expensive and starts
  returning `{"error":"Timeout. Maybe slow down a bit"}` after a handful of queries, even for a
  nonsense word. Unusable in a pipeline.
- Hence: **harvest once with H1, search locally.** Zero extra calls, instant, rate-limit proof.

A first run over 318 units of r/personaltraining surfaced SKOOL, Go High Level and a $100/day
ad spend — none of which appears on any pricing page.

## H4 — Output

### `h4_rank.sh` — read the hits in the right order

```bash
bash "$SKILL_DIR/h4_rank.sh" filtered.jsonl [count]
```

`hunt-run.sh` runs this for you. H2 returns fifteen hits that all look alike, and in one hunt
the best find of the day — an Italian thread about paperwork in dairy barns, with a measured 60
hours — was read near the bottom by luck. Ranked, the same comment came **second**.

Points and the reason for each are printed together, because an opaque score is worse than none:

| Signal | Points | Why |
|---|---|---|
| money named (`$`, `€`, `/mo`, "we pay") | **+3** | payments are evidence, complaints are free |
| process friction | **+3** | says *what* is done by hand, so it can be removed |
| a measured quantity ("60 hours", Slovenian "3 ure") | **+2** | someone counted, which is rare |
| emotion, buying intent | +2 each | |
| upvotes ≥ 5 / ≥ 20 | +1 / +2 | the community agreed |
| under 120 characters | **−2** | too short to carry a finding |

> **The score measures what is worth reading, not whether the idea is good.** The /35 in
> `SKILL.md` is a different judgement and a human makes it after the gates.

Show **survivors and corpses together.** The corpses are what make the survivors trustworthy —
without them you are back to reacting to an unscreened list, which is the habit this replaces.

```
## Hunt: <domain or "open">
<n> candidates harvested · <n> dropped on fit · <n> killed at G1–G3 · <n> survived

**Survivors**

### 1. <the pain in one sentence>
**Who:** <a concrete group, not "businesses">
**Evidence:** <quote from a real person> — <URL>, <date>
**How many such pieces of evidence:** <n independent>
**How they solve it today:** <current alternative>
**What you would build:** <one sentence>
**G1** ✅ <why> · **G2** ✅ <why> · **G3** ✅ <why>
**What could still kill it:** <the most likely killer not yet checked>

**Killed** — briefly, one line each
| Idea | Gate | Reason |
|---|---|---|

**Where I looked and where I did not**
- <sources and languages covered, and which were not>
```

Then stop. You pick at most one. That one goes through Mode B in full.

## H5 — Remember the hunt

On your confirmation, append to `gauntlet/killed-ideas.md`, and add each revival trigger to
`gauntlet/watchlist.md`.

**Killed ideas are the point of this file.** They stop the same idea returning in four months
and being researched from scratch. Record each with its gate, its reason, its date, and the
**trigger that would revive it** — a law changing, an incumbent dying, a price moving.

## Cadence

Worth running roughly monthly, or when you are between things. Not weekly — the sources do not
refresh that fast and you would mostly re-harvest the same complaints.

Adjacent but different: finding automations inside **your own** work is a different job. This
hunts for products to **sell**. Do not conflate them.
