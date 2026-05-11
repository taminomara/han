# Han: For the Solo Product Engineer

<img src="images/han-banner.png">

Han is a suite of AI skills and agents for solo (or small-team) product engineers. It combines evidence-based planning, full documentation maintenance, deep code review, and architectural analysis into a team of specialists you can dispatch from Claude Code.

## Which path are you on?

- **New to han?** → Start with [Concepts](./docs/concepts.md), then the [Quickstart](./docs/quickstart.md).
- **Looking for a specific skill?** → [Skills Index](./docs/skills/README.md) — 15 skills grouped by purpose.
- **Looking for a specific agent?** → [Agents Index](./docs/agents/README.md) — 21 agents grouped by role.
- **Wondering how the agent swarms scale?** → [Sizing](./docs/sizing.md) — the small / medium / large dispatch model used by `/code-review`, `/gap-analysis`, `/iterative-plan-review`, `/plan-a-feature`, and `/plan-implementation`.
- **Wondering why a skill said "YAGNI"?** → [YAGNI](./docs/yagni.md) — the evidence-based rule every planning, review, and architecture skill applies before committing items to an artifact.
- **Writing or editing a skill or agent?** → [Contributing](./docs/contributing.md).

## What this plugin does

Han turns planning, review, and documentation work that would normally take a team into a set of deterministic skills you can run from Claude Code. Each skill dispatches specialist agents — project managers, adversarial reviewers, investigators, architectural analysts, testing and security specialists — to do the judgment-heavy work, then folds their findings into an artifact you can trust.

The skills are designed to compose. You can plan a feature, then plan its implementation, then iterate on the plan, then review the resulting code, then write the PR description — all through named skills that hand off to each other cleanly.

Read [Concepts](./docs/concepts.md) for the skill-and-agent model that runs through the whole plugin.

## You probably want

Three skills cover the majority of first-contact use:

- **[`/plan-a-feature`](./docs/skills/plan-a-feature.md)** — Build a feature specification from scratch through an evidence-based interview.
- **[`/code-review`](./docs/skills/code-review.md)** — Comprehensive code review of the current branch or specified files.
- **[`/investigate`](./docs/skills/investigate.md)** — Evidence-based investigation of a bug, with adversarial validation of the proposed fix.

The [Quickstart](./docs/quickstart.md) has path-by-path guidance for every other situation.

## Installation

Add the Test Double skills marketplace to Claude Code, then install the plugin:

```
/plugin marketplace add testdouble/skills-internal
/plugin install han@testdouble-skills-internal
```

## Documentation map

- [Concepts](./docs/concepts.md) — Skill vs. agent, and how they compose. Read once before using the plugin.
- [Quickstart](./docs/quickstart.md) — Four paths for four common situations. Each path is a short sequence of skills.
- [Skills Index](./docs/skills/README.md) — All 15 skills, grouped by purpose.
- [Agents Index](./docs/agents/README.md) — All 21 agents, grouped by role.
- [Sizing](./docs/sizing.md) — The small / medium / large model that decides how many agents the swarming skills dispatch.
- [YAGNI](./docs/yagni.md) — The evidence-based "You Aren't Gonna Need It" rule every planning, review, and architecture skill applies.
- [Contributing](./docs/contributing.md) — Adding or editing skills, agents, and documentation.
- [IA Analysis](./docs/ia-analysis.md) — The information architecture findings that shaped this documentation.
- [Release Notes](./release-notes.md) — What's new in each version of the plugin.
