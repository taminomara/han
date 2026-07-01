# /implement-work-items

Operator documentation for the `/implement-work-items` skill in the han plugin. This document helps you decide *when* and *how* to use the skill. For what the skill does internally, read the skill definition at [`han-coding/skills/implement-work-items/SKILL.md`](../../../han-coding/skills/implement-work-items/SKILL.md).

> See also: [Plugin landing page](../../../README.md) · [All skills](../README.md) · [All agents](../../agents/README.md) · [YAGNI](../../yagni.md)

## TL;DR

- **What it does.** Drives a trusted `work-items.md` end to end: for each item in dependency order it builds with `/tdd`, verifies against the project's own checks, reviews at full specialist coverage, fixes to a quality gate, and commits, one item per commit on a dedicated branch, unattended after a single confirmation.
- **When to use it.** You have a set of already-planned, AFK-typed work items and you want them built, reviewed, and committed without hand-invoking `/tdd` and `/code-review` per item.
- **What you get back.** A dedicated branch with one clean commit per completed item, a completion summary, and a durable review record per item, or a legible five-part halt on the first item the run cannot finish cleanly, with the items completed so far left committed.

## Key concepts

- **The per-item loop.** Each item runs a fixed build, verify, review, fix, commit loop. The driver dispatches the build to a `/tdd` sub-agent and the review to a `/code-review` sub-agent, but runs verification and every commit itself, so the sub-agents never commit and their "all green" is never trusted on faith.
- **Halt the whole run.** The core has no interactive recovery menu. The first item the driver cannot finish cleanly halts the entire run, leaving the completed items committed and the halting item's work in the tree. Every halt uses one five-part frame: status line, one-sentence reason, tree-state disclosure, supporting evidence, and what to do next.
- **The scope check.** After building an item, the driver compares the changed files against that item's declared `expected-paths` (produced by `/plan-work-items`). A change outside the declared paths halts the run rather than being silently committed. Project-ignored files, generation or sync output, and the driver's own artifacts are excluded from the comparison.
- **The planning-artifact commit.** The run's first commit is the work items file and the spec, plan, and research it references, carrying a marker trailer that lets a later invocation refuse to rebuild a branch that already carries a run. Each item's own code then lands as its own subsequent commit.
- **Scope-check-only mode.** When the project defines no verification commands, the driver says so in the plan preview and gates on the scope check alone (no test, lint, or build re-run). Confirming the plan is the conscious confirm of that reduced gate.

## When to use it

**Invoke when:**

- You have run `/plan-work-items` and hold a `work-items.md` whose items are all AFK-typed and dependency-ordered, and you want them driven to committed code unattended.
- You want each item independently verified against the project's own checks and reviewed at full specialist coverage before it is committed, not only built.
- You want a legible, fail-closed stop when something cannot be finished, rather than a partial or silently-degraded run.

**Do not invoke for:**

- **Producing or hardening the work items.** Use [`/plan-work-items`](../han-planning/plan-work-items.md) to break a plan into items first. This skill consumes a trusted result.
- **Building a single change test-first.** Use [`/tdd`](./tdd.md) directly. This skill is for driving a whole planned set, not one behavior.
- **Reviewing code without driving the loop.** Use [`/code-review`](./code-review.md) on a branch or files. This skill only reviews as one stage inside the per-item loop.

## How to invoke it

Run `/implement-work-items` in Claude Code.

Give it:

1. **A path to a `work-items.md`.** The file `/plan-work-items` produced. Every item must carry an `Expected paths` block and a `Type` marker, and every item must be `AFK`; the driver refuses to start otherwise.
2. **Optional inputs, all defaulted.** `--gate critical|warning` (the severity at and above which a review finding blocks; default `warning`), `--fix-cap N` (maximum fix rounds per item; default `3`), `--model M` (the model the build and fix sub-agents run on; default `inherit`, the operator's session model), `--branch NAME` (the run's branch; default `feat/<feature-dir>`), and `--verify "CMD"` (override the auto-detected verification commands).

The driver runs read-only checks first, then shows a plan preview (the effective configuration, the verification mode, and the planning-artifact set) and waits for a single confirm or decline. On confirm it runs unattended: it either completes every item or halts on the first it cannot finish. Declining mutates nothing.

Example prompts:

- `/implement-work-items`. *"Drive docs/plans/user-invite-flow/work-items.md."*
- `/implement-work-items docs/plans/bulk-export/work-items.md --gate critical --fix-cap 1`. *"Only Critical findings block, and try at most one fix round per item."*

## What you get back

Committed code on a dedicated branch, not a report. Specifically:

- **A dedicated branch** (`feat/<feature-dir>` by default) whose first commit is the run's planning artifacts, followed by **one clean commit per completed item**, staged explicitly by path and following the project's commit convention. The driver never runs `git add -A`.
- **A completion summary** naming the branch, each item's outcome (committed with its short reference, or the one item that halted the run and why), the items not reached, and your next action (review and push the branch).
- **A durable review record per item** at `.implement-work-items/reviews/<W-N>.md`, plus an uncommitted work-state file at `.implement-work-items/state.md`. Both live in a self-ignoring directory (its `.gitignore` is a single `*`), so they never enter a commit and never show in `git status`. The review record holds the full findings; the condensed verdict the driver gates on references it by task ID.
- **On a halt, the five-part frame** instead of a summary of success: which item and phase stopped the run, the one-sentence reason, the tree state, the supporting evidence (with a pointer to the review record when the halt is review-gated), and what to do next, including that a re-invocation starts a fresh run and must be on a clean tree and a branch that does not already carry this run's commits.

## How to get the most out of it

- **Pair it downstream of `/plan-work-items`.** The driver reads the `expected-paths` and `Type` fields that skill produces. Run [`/plan-work-items`](../han-planning/plan-work-items.md) first; if an item's paths were flagged low-confidence because the plan gave no file-level detail, sharpen them before the run so the scope check is meaningful.
- **Use a real test suite to exercise the real gate.** The build, independent verification, and fix loop only get exercised on a project that defines verification commands and has a green suite. Point the driver at a repository with a real `pytest`/`npm test`/`go test` and so on. On a docs-only repository the run takes the scope-check-only path and never runs the verify or fix machinery.
- **Know the platform prerequisite.** The review stage runs in a sub-agent that fans out `/code-review`'s specialist panel one level deeper. That needs **Claude Code v2.1.172 or later**; below it the run halts rather than degrading the review, because the core carries no reduced-coverage fallback.
- **Grant the runner if verification will not run.** The driver's `allowed-tools` covers the common runners (`npm`, `pytest`, `go`, `cargo`, `make`, and so on). A project whose verify command falls outside that set surfaces as a tooling-unavailable halt; add a Bash grant in the project's CLAUDE.md or route the command through `make`.
- **The build skill is `/tdd`, and only `/tdd`.** The core drives every item with `/tdd`; per-item skill selection is deliberately deferred. An item that needs a different or interactive build is not a fit for this core.

## YAGNI

`/implement-work-items` is itself the YAGNI-simplest slice of a larger driver design: it ships the core build/verify/review/fix/commit loop and nothing else. The human-in-the-loop item path, clean-stop, cross-session resume, compaction recovery, stall handling, and the interactive blocker-recovery menu are all deferred, each with a named reopening trigger in the feature's plan. The core's answer to any state it cannot resolve is the fail-closed halt, not an added recovery affordance.

The code the driver produces is gated by the skills it dispatches: `/tdd` applies YAGNI to its test list and refactor step, and `/code-review` surfaces YAGNI findings as a separate advisory class. The driver itself adds no speculative machinery. See [YAGNI](../../yagni.md) for the two gates, the acceptable-evidence list, the named anti-patterns, and the deferral format.

## Cost and latency

The driver runs on your session model and stays resident for the whole run, reading each sub-agent's compact report rather than its full output. Per item it dispatches at least two sub-agents: one build sub-agent running `/tdd`, and one review sub-agent (depth 1) that fans out `/code-review`'s specialist panel (depth 2). Each fix round adds another build-style sub-agent plus a re-review fan-out, so an item that takes the full `--fix-cap` is the most expensive shape. The driver also re-runs the project's full verification suite itself once per verify and once per re-verify. This is an infrequent, high-fan-out run built to drive a planned batch unattended, not a tight interactive loop; the levers on cost are the item count, the fix cap, and the suite's runtime.

## In more detail

The run is **single-pass with no resume**. The work-state file is an uncommitted convenience for the current session, not a durable ledger, so a halted run does not resume where it stopped; re-invoking starts fresh from the first item. To keep a fresh run from rebuilding already-committed items, the planning-artifact commit carries a marker trailer, and startup refuses a branch that already carries it. That is why the halt's what-to-do-next tells you to start a fresh branch (or cherry-pick the completed items forward) rather than re-run in place.

The **halt posture is deliberately absolute**. The larger driver design offers an operator a recovery menu (triage, accept a flagged change, override the gate, repair an upstream item, defer, skip); the core offers none of that. It halts on the first unresolvable item and reports where and why, on the stated assumption that the operator would rather read a clean stop than have the driver guess. A verification command that *reports failures* enters the fix loop; a command that *fails to execute* (a missing tool, a downed service) is a tooling-or-environment halt, never fed to the fix loop as if the code were at fault. The panel never reviews known-broken code: a red verify routes straight to a fix.

This is the suite's **first skill-to-skill orchestrator**. Earlier skills dispatch agents; this one dispatches sub-agents that themselves run skills (`/tdd`, `/code-review`), and the review sub-agent fans out a further panel. That topology is what the v2.1.172 prerequisite buys, and it is why the review runs one level down: the panel's deliberation stays out of the driver's context, and only the condensed verdict returns.

## Sources

The skill composes existing practice rather than introducing its own; its one load-bearing external dependency is the platform capability that makes the review fan-out possible.

### Claude Code sub-agents documentation (nested sub-agents)

The review stage dispatches a sub-agent that itself dispatches the `/code-review` specialist panel. Nested sub-agent dispatch, and the depth limit it operates under, are the documented platform capability the review topology and the v2.1.172 prerequisite rest on.

URL: https://code.claude.com/docs/en/sub-agents.md

## Related documentation

- [Plugin landing page](../../../README.md). The front door. Start here if you arrived from outside the docs tree.
- [YAGNI](../../yagni.md). The evidence-based "You Aren't Gonna Need It" rule. The driver ships the simplest slice of a larger design; the deferrals follow this rule's format.
- [`/plan-work-items`](../han-planning/plan-work-items.md). Produces the `work-items.md` this skill consumes, including the `expected-paths` and `Type` fields the driver reads. Run it first.
- [`/tdd`](./tdd.md). The build skill the driver dispatches for every item, and for every fix round.
- [`/code-review`](./code-review.md). The review skill the driver dispatches as its per-item gate; its panel and severity vocabulary are what the condensed verdict summarizes.
- [Skill building guidance](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/). The progressive-disclosure, description-frontmatter, script-execution, and bash-permission rules this skill follows.
