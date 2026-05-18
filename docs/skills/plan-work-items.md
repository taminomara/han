# /implementation-plan-to-issues

Operator documentation for the `/implementation-plan-to-issues` skill in the han plugin. This document helps you decide *when* and *how* to use the skill. For what the skill does internally, read the skill definition at [`plugin/skills/implementation-plan-to-issues/SKILL.md`](../../plugin/skills/implementation-plan-to-issues/SKILL.md).

> See also: [Plugin landing page](../../README.md) · [All skills](./README.md) · [All agents](../agents/README.md) · [YAGNI](../yagni.md)

## TL;DR

- **What it does.** Takes an implementation plan and divides it up into individual, focused units of work, which we will call issues.
- **When to use it.** You have an implementation plan and now you need to divide it up into issues and determine dependencies (e.g., which issues can and can't be worked on in parallel). These issues will be ready to be assigned to an implementor.
- **What you get back.** `<repo-name>.work-items.md`, a list of the work items generated for the targeted repo.

## Key concepts

- **Vertical slice.** Each unit of work is a narrow but complete path through the relevant layers (schema, API, UI, tests) for a single repo. A completed slice is demoable or verifiable on its own: not a layer, not a stub.
- **HITL and AFK.** Every slice is classified as HITL (requires a human sync: architectural decision, design review) or AFK (can be implemented and merged without one). The skill prefers AFK and prefers many thin slices over few thick ones.
- **Symbolic ID.** Each slice gets a per-repo identifier (`SYM-N`) assigned before GitHub issue numbers exist. Symbolic IDs are for cross-referencing slices within and across work-items files. They are replaced by actual issue numbers (`#NNN`) when issues are created.
- **Work-items file.** The primary output is one `<repo-name>.work-items.md` file per affected repo, written alongside the plan. It contains a preamble (cross-repo integration table, shared artifacts) followed by one section per slice.
- **Cross-repo vs. within-repo dependencies.** Slices in the same repo use native `Depends on` ordering. Dependencies that cross repo boundaries are never native blockers. They live in the preamble integration table as integration contracts, and the table's Precedence rule wins over per-ticket ordering hints.

## When to use it

**Invoke when:**

- You have a high degree of confidence in a plan and you're ready to start implementing it.

**Do not invoke for:**

- **Thinking about a feature.** Use [`/plan-a-feature`](./plan-a-feature.md) to start a feature from scratch, developing specifications through asking questions.
- **Turning feature specs into an implementation plan.** Use [`/plan-implementation`](./plan-implementation.md) to turn a feature specification into an implementation plan through a project-manager-led team conversation.
- **Reviewing a plan.** Use [`/iterative-plan-review`](./iterative-plan-review.md) to stress-test an existing plan through multiple codebase-grounded review passes.
- **Any work where there isn't an existing implementation plan.** If there isn't an implementation plan yet, use one of the above entry points to create one before trying to divide it into issues.

## How to invoke it

Run `/implementation-plan-to-issues` in Claude Code.

Give it:

1. **The feature name or implementation plan, optional.** The default is to look for the plan within the project.

Example prompts that work well:

- `/implementation-plan-to-issues docs/features/my-feature/feature-implementation-plan.md`. Divides the plan described in `feature-implementation-plan.md` up into issues.
- `/implementation-plan-to-issues my-feature`. Looks for a plan implementation under `docs/features/my-feature` to divide up into issues.

## What you get back

One file on disk per affected repo plus an in-channel summary:

- The **`<repo-name>.work-items.md`**. The stakeholder-readable artifact. Each section is a work item.
- An **in-channel summary** with the work item list path and any open recommendations.

## How to get the most out of it

- **Be explicit about the feature.** The default direction is to make a best guess, based on which feature (with an implementation plan) was most currently worked on. Give the feature name explicitly to help guide the agent to the desired result.
- **Pair with `/plan-implementation` upstream.** This skill is highly-dependent on there being a plan in place.
- **Pair with `/iterative-plan-review` upstream.** A highly-trusted, reviewed-and-battle-tested plan makes the work of divvying up issues much easier.

## Cost and latency

One sub-agent dispatch: `project-manager` on `sonnet` for slice drafting (Step 4). All other work runs in-process: locating and reading the plan, inventorying reference artifacts, assigning symbolic IDs, presenting the breakdown for confirmation, and writing the work-items files. The project-manager dispatch is the most expensive step. For a typical feature plan, expect a single dispatch plus a few minutes of in-process work. The skill is designed for a once-per-plan cadence after planning is complete. Re-run it only after the plan has materially changed. For iterating on the plan itself, use `/iterative-plan-review`.

## YAGNI (when applicable)

YAGNI does not gate this skill's output. The work-items file is a structural decomposition of an already-committed implementation plan: the slice boundaries, HITL/AFK classification, and reference artifact links derive from what the plan already decided. This skill does not introduce new behavioral commitments or speculative infrastructure. YAGNI enforcement belongs upstream, in `/plan-implementation` and `/iterative-plan-review`, before the plan reaches this stage.

If the plan you are decomposing has not yet been through a YAGNI sweep, run `/iterative-plan-review` first.

See [YAGNI](../yagni.md) for the two gates, the acceptable-evidence list, and the named anti-patterns.

## Related documentation

- [Plugin landing page](../../README.md). The front door. Start here if you arrived from outside the docs tree.
- [Skills Index](./README.md). All 18 skills, grouped by purpose.
- [`project-manager`](../agents/project-manager.md). Dispatched in Step 4 to draft the vertical slice breakdown.
- [`/iterative-plan-review`](./iterative-plan-review.md). Pair upstream when splitting up an implementation plan you do not yet trust. Hardening the desired state makes breaking down into issues easier.
- [`/plan-implementation`](./plan-implementation.md). Pair upstream when splitting up a simpler or more trusted implementation plan.
- [Report template](../../plugin/skills/implementation-plan-to-issues/references/issue-template.md). The template the skill renders for each issue.
