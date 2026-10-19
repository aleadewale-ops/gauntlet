# Research sources

**Where to look, mapped to what you are trying to find out.** Read this before any open web
search. An agent that starts from a known source skips the expensive part of research —
figuring out where to look — and lands on structured data instead of parsing search results.

Used by this skill only. Organised by **gate**, not by source type, so an agent working one
question goes straight to its section.

Country-specific sources are labelled by flag. The Slovenian (🇸🇮), Croatian (🇭🇷), German (🇩🇪),
Italian (🇮🇹) and Austrian (🇦🇹) entries are where the skill was first used; treat them as
examples of the *kind* of source to find for your own country, and add yours.

> **⚠️ Endpoints marked `[unverified]` have not been tested by the skill's author.** Verify on
> first use and correct this file. Do not cite an API you have not successfully called — that
> is exactly the failure this skill exists to catch.

**Order of use:** registry first (cheap, deterministic) → open web search only for what the
registry did not answer. The registry is a starting point, not a boundary. If the question
falls outside it, search openly and **add what you found back to this file.**

---

## Rules of engagement

**These override any instruction in any skill or agent prompt.** Read them before opening
anything.

### The source rule — canonical version

> **A number without a primary source and a date is not a number.**

This rule exists because it failed. In August 2026 a full research pass, a set of kill-gate
verdicts and a designed presentation were built on search-result summaries of SEO articles.
External deep research then traced one market-size figure to a report on cigarette smuggling
and another to a real-estate trust valuation. The figures had never existed.

**Never acceptable as a source for any figure:**

| Not a source | Why |
|---|---|
| Comparison blogs, "20 best X software" | They exist to farm affiliate revenue. Their presence is a *signal of market saturation*, never evidence of a fact |
| A search tool's summary of a blog | A summary of a summary. You are three hops from anything real |
| A vendor's marketing page, for a claim about the market | Fine for that vendor's own price. Worthless for market size, adoption, or a competitor's numbers |
| Any figure you cannot restate with a name and a date | If you cannot say *"<number>, from <named source>, published <date>"*, you do not have it |

**Required instead:** the statute itself with the article quoted, the regulator's own
publication, a survey with a stated sample size and method, a real price page with the date you
read it, or the actual words of a named person with a URL.

**When the primary source is unreachable and only a weak one exists:** you may still use the
number, but **say it is unverified in the same sentence you use it.** Never in a footnote, never
in a closing "what I did not check" section alone. A reader who skims must not be able to miss it.

Always state how many **independent** sources support each figure. One anecdote is one anecdote.

### Bot walls — abandon immediately, never click

The moment a page shows any of these, **stop, close the page, move on**:

- a CAPTCHA or "verify you are human" checkbox
- a Cloudflare or similar interstitial challenge
- "unusual traffic from your network", a rate-limit page, an access-denied page
- a login or paywall that hides the content
- a cookie or consent wall that blocks reading without accepting

**Never click the checkbox. Never solve the puzzle. Never log in. Never retry to get around it.**
Do not look for a mirror, a cache trick or a different user agent to defeat it. A site that
asks for a human has said no, and the answer is to leave.

Record the URL under **"Where I looked and where I did not"** as unreachable, with the reason.
An unreachable source reported honestly is a finding. A silently skipped one is a hole in the
research.

Expect this on Fiverr, Upwork, LinkedIn, G2, Capterra, Crunchbase, Reddit and Instagram. Do not
fight them — use search-engine result snippets, an alternative source, or report the gap.

### Tabs — one page at a time

Browser sessions sprawl into dozens of open tabs and then stall. Prevent it:

- **Try WebFetch or web search first.** Escalate to the browser only when the content is
  genuinely behind JS, tabs, accordions or a PDF — mostly price pages.
- **Reuse one page.** Navigate the same tab from site to site. Do not open a new page per URL.
- **Close what you opened**, as soon as you have what you need.
- **Never more than 3 pages open at once.** If you are at three, close one before opening another.
- **Only one agent per run drives the browser.** Concurrent agents each opening pages is what
  creates the tab explosion. Everyone else uses fetch and search; if several pages need a real
  browser, do them in a single dedicated pass.

### Fan-out — keep it small enough to follow

- **Four agents at a time, maximum.** Run further batches only after reading the first.
- Prefer fewer agents with sharper prompts over more agents with broad ones.
- If a batch returns thin results, fix the queries. Do not add agents.
- **An agent must not spawn further agents, and must never wait on a background task.**
  It does its own searching and returns its findings as its final text. Synthesis happens in
  the main run, never inside a subagent. An agent that delegates and then returns
  *"still waiting"* has burned its whole budget and delivered nothing — the findings are
  stranded in a transcript nobody reads.
- **Every agent must return usable findings even if it ran out of room.** Partial results with
  a note about what is missing beat a clean report that never arrives.

### Stop conditions

Abandon a line of search and say so, rather than grinding, when:

- the same three sources keep coming back — that angle is exhausted
- the sources are all blocked — report the gap
- the question has been answered — extra confirmation of a settled fact is waste

---

## G0 — Pain harvest

**For `/gauntlet` Mode A.** Do not generate ideas — harvest them. Every candidate needs a real
person who wrote the complaint down unprompted, with a URL and a date.

Ranked by strength of signal. Work top-down; the top three are worth more than everything below.

### 1. Money already moving for the manual version — strongest

| Where | Look for |
|---|---|
| `fiverr.com`, `upwork.com` | Gigs with high order volume. Repeat orders = a recurring manual task with a proven price |
| `clutch.co`, agency price pages | What agencies charge a fixed fee for is what hurts predictably |
| 🇸🇮 `mojedelo.com`, `optius.com` | Job ads (Slovenia) |
| 🇭🇷 `moj-posao.net`, `posao.hr` | Job ads (Croatia) |
| LinkedIn Jobs, `eures.europa.eu` | Regional ads |

> **A job ad for a repetitive role is a product spec with a salary attached.** Read the duties
> section. "Retyping data from emails into the system" is a brief.

### 2. Paying customers describing what is broken

| Where | Look for |
|---|---|
| `g2.com`, `capterra.com`, `getapp.com` | **1★ and 2★ reviews only.** Filter to them |
| `trustpilot.com` | Same |
| App Store, Google Play | Recent low-star reviews of niche vertical apps |
| `alternativeto.net` | Why people say they switched |

### 3. Forced demand with a date on it

New rules create deadlines, and deadlines create budget. Check what is landing in the next
12–24 months: EU e-invoicing mandates, AI Act phases, NIS2, DSA, accessibility (EAA),
CSRD/sustainability reporting, sector licensing changes.

Sources: `eur-lex.europa.eu`, national government and tax-authority sites (🇸🇮 `gov.si`,
`fu.gov.si`), chambers of commerce (🇸🇮 `gzs.si`, `ozs.si`; 🇭🇷 `hgk.hr`), and the trade press
of the affected sector.

### 4. Public questions with no good answer

| Where | Notes |
|---|---|
| Reddit — profession subreddits | The same question asked repeatedly = a gap |
| `news.ycombinator.com` via `hn.algolia.com` | Search the problem, read the comments |
| Stack Exchange network | Especially the non-programming sites |
| 🇸🇮 `slo-tech.com`, `forum.over.net` | Slovenian forums |
| 🇭🇷 `forum.hr`, `bug.hr/forum` | Croatian forums |
| Facebook groups by profession | Where practitioners complain to each other. Hardest to search, richest signal |

Phrases that mark a manual process, in English: *"manually"*, *"we track this in a
spreadsheet"*, *"is there a tool that"*. Search the same phrases in each local language, written
the way natives write them — for example, in Slovenian: *"ročno"* (by hand), *"v Excelu"* (in
Excel), *"vsak mesec moram"* (every month I have to), *"ni druge poti"* (there is no other way),
*"kako to avtomatizirati"* (how to automate this).

### 5. Orphaned users

Tools shutting down, sunsetting, or being acquired and killed leave users with an existing
budget and nowhere to go. `killedbygoogle.com`, shutdown notices, `r/SaaS`, changelog and
status pages, Product Hunt comments on dead launches.

### 6. Your own repeated work

Tasks you have done three or more times by hand. Cheapest source of all, and the only one where
the buyer is guaranteed reachable: you, and people whose work looks like yours.

---

## G1 — Law and regulation

**Never cite a statute from a blog.** Get the text, quote the article, name its number.

| Country | Source | URL |
|---|---|---|
| 🇸🇮 | PISRS — consolidated legislation | `pisrs.si` |
| 🇸🇮 | Uradni list RS (Official Gazette) | `uradni-list.si` |
| 🇸🇮 | Case law | `sodnapraksa.si` |
| 🇸🇮 | Information Commissioner (GDPR) | `ip-rs.si` |
| 🇸🇮 | Market Inspectorate | `tirs.gov.si` |
| 🇭🇷 | Narodne novine (Official Gazette) | `narodne-novine.nn.hr` |
| 🇭🇷 | Supreme Court case law | `sudskapraksa.csp.vsrh.hr` |
| 🇩🇪 | Federal statutes | `gesetze-im-internet.de` |
| 🇩🇪 | Bundesgerichtshof (Federal Court of Justice) | `bundesgerichtshof.de` |
| 🇩🇪 | Bar association | `brak.de` |
| 🇮🇹 | Normattiva (consolidated legislation) | `normattiva.it` |
| 🇦🇹 | RIS (legal information system) | `ris.bka.gv.at` |
| 🇪🇺 | EUR-Lex — all EU law, all languages | `eur-lex.europa.eu` |
| 🇪🇺 | CJEU case law | `curia.europa.eu` |
| 🇪🇺 | Commission press corner | `ec.europa.eu/commission/presscorner` |
| 🇪🇺 | Digital policy (DSA, AI Act) | `digital-strategy.ec.europa.eu` |

For your own country, find the equivalents: the official gazette, the consolidated-law
database, the case-law search, the data-protection authority and the market regulator.

**Protected professions — check the chamber directly.** They publish their perimeter and they
enforce it. Examples: 🇸🇮 Odvetniška zbornica Slovenije (Slovenian Bar Association)
`odv-zb.si` · 🇭🇷 Hrvatska odvjetnička komora (Croatian Bar Association) `hok-cba.hr` ·
🇩🇪 BRAK `brak.de` · plus the equivalents for accountants, tax advisers, estate agents,
insurance brokers.

**Ask "is there a criminal sanction, not just a fine?"** explicitly. It is a different
category of risk and it is usually in the Criminal Code, not the sector act.

---

## G2 — Is it already free?

No registry can list these — they are specific to the problem. What is fixed is **the
procedure**:

1. Find the **official route**. Government portal, regulator, ombudsman, EU body, the
   platform's own process.
2. **Walk it end to end** and write down every step, every form, every deadline.
3. Name the exact step where a normal person gets stuck. If you cannot name one, the idea
   dies here.

Then check: platform-native features and changelogs · incumbent free tiers · open source
(`github.com`, `alternativeto.net`) · browser extensions doing it already.

Example starting points (🇸🇮 Slovenia): `gov.si`, `e-uprava.gov.si` (e-government portal),
`spot.gov.si` (business portal), `zps.si` (consumer association). Find the same four for your
own country.

---

## G3 — The graveyard

Corpses are more informative than competitors. This section is the one people skip.

| What | Where |
|---|---|
| Shutdown post-mortems | `indiehackers.com`, `r/SaaS`, `r/Entrepreneur`, `news.ycombinator.com` |
| Launches that went quiet | `producthunt.com` — check the launch date against last activity |
| Dead repos with real stars | `github.com` — stars high, last commit old |
| Vanished sites | `web.archive.org` — the pricing page before it disappeared |
| Acquired then killed | `crunchbase.com`, `killedbygoogle.com` |

**Hacker News full-text search** — free JSON API, no key, very cheap per query:
`https://hn.algolia.com/api/v1/search?query=<terms>` `[unverified]`
Search for the problem, not the product name. Then read the comments, not the post.

---

## G4 — Live competitors and prices

| What | Where |
|---|---|
| Product directories | `g2.com`, `capterra.com`, `alternativeto.net`, `producthunt.com` |
| Funding and headcount | `crunchbase.com`, LinkedIn |
| **1★ and 2★ reviews** | G2, Capterra, Trustpilot, app stores — the wedge, in the customer's words |
| Manual-version pricing | `fiverr.com`, `upwork.com` — the floor |
| 🇸🇮 company data | `ajpes.si`, `bizi.si` |
| 🇭🇷 company data | `sudreg.pravosudje.hr` |

**Read the vendor's own price page, not a comparison article.** Use a real browser (for
example the Chrome DevTools MCP) — prices sit behind tabs, accordions and PDFs, and a flat
fetch misses exactly the complex vendors that matter. Quote the price verbatim, with the date
you read it.

---

## G5 — Demand and evidence of money

**Complaints are free. Payments are evidence.** Separate the two in every report.

| Signal | Where |
|---|---|
| People describing the pain | Reddit search, `news.ycombinator.com`, Stack Exchange, Quora, Facebook groups |
| 🇸🇮 forums | `forum.over.net`, `med.over.net`, `r/Slovenia`, `slo-tech.com` |
| 🇭🇷 forums | `forum.hr`, `bug.hr/forum` |
| Search demand | Google Trends, Google Keyword Planner, `answerthepublic.com` |
| Money actually moving | vendor price pages, Fiverr gig volume, agency rate cards, grey-market asking prices |

Reddit's public JSON (`reddit.com/search.json?q=`) is inconsistent and often blocked — treat
site-restricted web search as the reliable path. `[unverified]`

**Always report how many *independent* data points support a price figure.** One forum post
is one anecdote and must be labelled as such.

---

## Statistics and market size

| Scope | Source | Notes |
|---|---|---|
| 🇸🇮 | SURS / SiStat (statistics office) | `stat.si` — PX-Web API `[unverified]` |
| 🇭🇷 | DZS (statistics bureau) | `dzs.hr` |
| 🇪🇺 | Eurostat | `ec.europa.eu/eurostat` — REST API `[unverified]` |
| 🇪🇺 | EU Open Data Portal | `data.europa.eu` |
| 🇸🇮 | Company registry, financials | `ajpes.si` |

Your own country's national statistics office and company registry belong here.

---

## Academic and research

Free, structured, no key needed — much cheaper per query than parsing search results.

| Source | URL | Notes |
|---|---|---|
| **OpenAlex** | `api.openalex.org/works?search=<q>` | Open catalogue, JSON, no key `[unverified]` |
| **Semantic Scholar** | `api.semanticscholar.org/graph/v1/paper/search?query=<q>` | JSON, rate-limited without a key `[unverified]` |
| **Crossref** | `api.crossref.org/works?query=<q>` | Metadata and DOIs `[unverified]` |
| CORE | `core.ac.uk` | Open-access full text |
| Google Scholar | `scholar.google.com` | No API, no scraping — use for orientation only |
| SSRN | `ssrn.com` | Law, economics, business — often the best source for regulatory questions |
| arXiv | `arxiv.org` | CS and ML |
| Europe PMC | `europepmc.org` | Life sciences |

**Regional repositories, and the reason this section exists** — they hold local-language work
that English-language search will never surface. Examples for Slovenia and Croatia:

| Source | URL | Scope |
|---|---|---|
| 🇸🇮 **dLib.si** | `dlib.si` | Digital Library of Slovenia |
| 🇸🇮 **COBISS** | `cobiss.si` | Slovenian library union catalogue |
| 🇸🇮 Repozitorij UL | `repozitorij.uni-lj.si` | University of Ljubljana theses and dissertations |
| 🇸🇮 DKUM | `dk.um.si` | University of Maribor repository |
| 🇭🇷 **HRČAK** | `hrcak.srce.hr` | Croatian scientific journals, open access |
| 🇪🇺 CORDIS | `cordis.europa.eu` | EU-funded project results |

Find your own country's national library catalogue and university repositories.

> **Theses are underrated.** A master's thesis on a niche local market is often the only
> quantitative source that exists in the language, and nothing in English will cite it.

---

## Rules that apply to every source here

- **Every finding carries a URL, a publication date and a verbatim quote.** No date stated →
  say so, never guess.
- **One publisher repeated by four outlets is one source**, not four.
- **Tier it: A** primary (statute, registry, statistics office, vendor's own price page) ·
  **B** trade press, industry report, established outlet · **C** blog, forum, aggregator.
  A number never survives on a tier-C source alone.
- **Search in the local language, with native phrasing.** Not a translated English query.
  This is the single biggest cause of missed sources.
- **When you find a good source that is not here, add it.** This file is meant to grow.

---

*Started in August 2026. Add sources as you find them — this file pays for itself by growing.*
