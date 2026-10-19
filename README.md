# gauntlet

A Claude Code skill that tries to **kill your business idea** before you build it.

An idea goes in. Almost always, a **KILL with a reason** comes out. Occasionally a GO that has
earned it, with conditions.

## Why

The usual order is: find a pain → narrow the niche → start building → *then* research → find out
on the third pass that it is illegal, needs a licence, or is already free. Weeks in.

**The order is the bug.** Gauntlet runs the checks from cheapest-and-most-lethal to
most-expensive, and stops at the first one that kills:

| Gate | Question |
|---|---|
| G0 | Can you reach the first ten buyers through a channel you actually have and that is lawful? |
| G0.5 | Does it stand on something you already have? |
| G1 | Is it legal, licensed, or a protected profession? (from the statute, not a blog) |
| G2 | Is it already free — an official route, a native feature, a $39/month SaaS? |
| G3 | The graveyard: who tried this and died, and of what? |
| G4 | Live incumbents: real prices, with dates, and how they changed over time |
| G5 | Evidence of money, not of complaining |
| G6 | Does the arithmetic reach your target with the channel that passed G0? |

Rules it enforces:
- **Default to kill.** Ambiguity is a kill, not a maybe.
- **A number without a primary source and a date is not a number.**
- **"No competitors found" is a failed search**, not good news.
- **Never a bare KILL:** every kill names the closest variant that would survive, and what would
  revive the idea.
- **Never a bare GO:** a GO lists the conditions and, gate by gate, what would have killed it.
- **Three kills in a row at the same gate means the brief is wrong**, not the ideas.

## Where it comes from

It was built and used in August 2026 by one founder, on real ideas. In that month it killed
seventeen of them, twelve hunts in a row found no survivor, and the lessons from those kills are
written into the skill (the DipJar graveyard search, a configurator killed on its licence price
while implementation was the real business, a market-size figure traced to a report on cigarette
smuggling). A skill that kills almost everything is working as designed: each kill took minutes
instead of weeks.

## Modes

| Command | What it does |
|---|---|
| `/gauntlet <idea>` | Runs one idea through the gates (Mode B) |
| `/gauntlet` or `/gauntlet <industry>` | Hunts for real pains in people's own words, then gates them (Mode A, see `hunt.md`) |
| `/gauntlet invent` | Invents an idea from random seeds and tries to kill it (Mode C) |
| `/gauntlet watch` | Watches for breaks: shutdowns, price shocks, new giants with gaps (Mode D) |

## Install

```bash
git clone https://github.com/aleadewale-ops/gauntlet ~/.claude/skills/gauntlet
```

Then, in the project where you run Claude Code, create your own files from the templates:

```bash
mkdir -p gauntlet
cp ~/.claude/skills/gauntlet/templates/*.md gauntlet/
```

Fill in `gauntlet/my-situation.md` first: your target, channels, assets, the killers that come
from your situation, and your own settled business (so the skill never "discovers" it back to
you). The gates are only as good as this file.

**Requirements:** bash, curl, jq. No API keys: the scripts use the public Reddit archive
(arctic-shift), the Wayback Machine and the Jina Reader. Be gentle with them; the scripts are
built to make few calls.

## Files

| File | Role |
|---|---|
| `SKILL.md` | the gates, the modes, the verdict format, the guardrails |
| `hunt.md` | the hunt procedure (Mode A) |
| `references/research-sources.md` | where to look, gate by gate |
| `gates.sh` | Mode B driver: runs G3 and G4, writes a verdict skeleton with every unrun gate marked UNANSWERED |
| `g3_graveyard.sh`, `g34_wayback.sh` | the graveyard: Reddit post-mortems and dead domains, pricing history |
| `h7_competitor_check.sh`, `prices.sh` | real prices from real pricing pages, saved with the date |
| `seed-niches.sh`, `map-subreddit.sh`, `hunt-run.sh`, `rounds.sh`, `h1_harvest.sh`, `h2_filter.sh`, `h2_validate.sh`, `h4_rank.sh`, `_corpus.sh`, `*_stems.txt` | the hunt: random seeds, harvesting complaints, filtering in four languages, ranking |
| `templates/` | your own files: `my-situation.md`, `killed-ideas.md`, `watchlist.md` |

The scripts **gather, they do not judge.** Reading a statute, walking a free official route and
reading one-star reviews stay with the model and with you.

## Credits

Gauntlet was built inside [AIS-OS](https://www.skool.com/ai-automation-society), Nate Herk's
MIT-licensed AI Operating System starter kit for Claude Code. "The Three Ms of AI" is Nate
Herk's trademark; this skill does not use the framework's name.

## License

MIT
