# How-To Guides

End-to-end recipes for the workflows the han plugin was built around. Each guide walks the whole loop: what to type, what decisions you make between steps, and what you should expect along the way.

> See also: [Plugin landing page](../../README.md) · [Quickstart](../quickstart.md) · [Concepts](../concepts.md) · [Skills](../skills/README.md) · [Agents](../agents/README.md)

How-to guides are for people who already know roughly what the plugin does and want to use it on a real piece of work. If you are not there yet, start with [Concepts](../concepts.md) and the [Quickstart](../quickstart.md).

## Which guide do you need?

- **[Plan a feature, end to end](./plan-a-feature.md).** You have a feature idea and want to walk it from a rough concept through spec, phased build, implementation plan, and individual work items. The longest of the three; covers most of the planning skills.
- **[Triage and investigate a bug](./triage-and-investigate-a-bug.md).** Something is broken or behaving oddly and you want a root cause backed by evidence, not a guess. Optionally captures the report for later when the work is queued, not immediate.
- **[Research a decision and capture it](./research-a-decision.md).** Nothing is broken; you have a question (a new library, a hosting move, a build-vs-buy call) and want the options, prior art, and a recommendation, then record the chosen direction as an ADR.

## How the guides are structured

Every guide opens with two short blocks: **Before you begin** (prerequisites the workflow assumes) and **What you'll end up with** (the artifacts and outcomes you should expect). Read those first to confirm the guide matches your situation.

The steps are grouped into named phases of three to four steps each. The phases give you a place to pause, look at what you have, and decide whether to keep going or stop. Inside each phase the steps are numbered. When a step has a fork (different starting state, different scope), the branch is written inline as "if X, do Y; otherwise, do Z" rather than as a separate track.

Each guide documents the happy path first — the most common way through the workflow — and groups variations (different starting points, alternate flows, optional follow-ons) under a final **Variations** section. When you are new to a workflow, follow the happy path. Come back for variations once you understand what each step produces.

## How these relate to skill documentation

The [skill long-form docs](../skills/README.md) are the canonical reference for any individual skill: when to use it, how to invoke it, what it returns, what it costs. They answer the question *"what does this skill do?"*

These how-to guides answer a different question: *"how do I run an end-to-end workflow that uses several of these skills?"* They reference the skills by name and link out to the long-form docs for detail. When in doubt, the skill doc is canonical for the skill; the how-to is canonical for the workflow.

## Where to go next

- Pick a guide above and follow the happy path.
- Skim the [Skills Index](../skills/README.md) if you want to know what every individual skill does.
- Read [Sizing](../sizing.md) if a step in a guide says "small / medium / large" and you want to know how the team scales.
- Read [YAGNI](../yagni.md) if a skill defers something to a "Deferred (YAGNI)" section and you want to know why.
