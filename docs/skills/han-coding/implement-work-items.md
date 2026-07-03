# /implement-work-items

Operator documentation for the `/implement-work-items` skill in the han plugin. This document helps you decide *when* and *how* to use the skill. For what the skill does internally, read the skill definition at [`han-coding/skills/implement-work-items/SKILL.md`](../../../han-coding/skills/implement-work-items/SKILL.md).

> See also: [Plugin landing page](../../../README.md) · [All skills](../README.md) · [All agents](../../agents/README.md) · [YAGNI](../../yagni.md)

## TL;DR

- **What it does.** Drives a trusted `work-items.md` end to end, routing each item by its recorded markers so it drives needs-a-human items (a pre-work decision, a foreground interactive or free-form build, a human review) alongside fully-autonomous ones, pausing in-session where a human is needed and resuming the moment you respond. For each item in dependency order the loop is constant: build with the item's recorded implementation skill, verify against the project's own checks, review the change with the item's recorded review, fix to a quality gate, and commit, one item per commit on a dedicated branch.
- **When to use it.** You have an already-planned `work-items.md` that mixes items running unattended with items that need you (a decision, an interactive build, or a human read), and you want the whole set built, reviewed, and committed without hand-invoking each skill per item.
- **What you get back.** A dedicated branch with one clean commit per completed item, a completion summary naming each item's execution mode, and a durable review record per reviewed item, or a legible five-part halt on the first item the run cannot finish cleanly, with the items completed so far left committed.

## Key concepts

- **The per-item loop.** Each item runs a fixed decide, build, verify, review, fix, commit loop, and the driver processes one item at a time in dependency order, finishing each before the next begins. For a fully-autonomous item the driver dispatches the build to a sub-agent running the item's recorded implementation skill and the review to a sub-agent running its recorded review; for a needs-a-human item it pauses in the foreground instead. Whoever built the item, the driver runs verification and every commit itself, so a sub-agent never commits and its "all green" is never trusted on faith.
- **Routing by recorded markers.** The driver never calls a skill itself. It reads each item's `Suggested implementation`, `Suggested review`, and `Requires pre-work decisions` markers (each build and review tagged `AFK` or `HITL`) and routes each phase from them: an `AFK` build dispatches a sub-agent, a `HITL` or bare `none` build hands off to you in the foreground; an `AFK` review dispatches a review sub-agent, a `HITL` or bare `none` review is your own read captured into the verdict; a `Requires pre-work decisions` of `yes` pauses for a decision before the build.
- **One normalized review verdict.** Every review path returns the same verdict shape, and the driver gates on it identically: a `/code-review` sub-agent at full specialist coverage, a non-code review agent (`content-auditor` or `information-architect`), or your own read captured into that shape. The item clears the gate when the verdict reports no finding at or above the threshold, scope findings included.
- **Foreground hand-off.** A `HITL` build or a bare `none` build is a hand-off to you, not a skill the driver calls. It recommends a manual compaction, marks the boundary, waits for you to confirm the work is done, then catches up on run state and verifies the item exactly as it would a sub-agent's build. A `HITL` review works the same way: you read the change and the driver captures your findings into the one verdict.
- **Halt the whole run.** The driver has no interactive recovery menu. The first item it cannot finish cleanly halts the entire run, leaving the completed items committed and the halting item's work in the tree. A needs-a-human item is no longer a reason it cannot finish; those are driven now. Every halt uses one five-part frame: status line, one-sentence reason, tree-state disclosure, supporting evidence, and what to do next.

## When to use it

**Invoke when:**

- You have run `/plan-work-items` and hold a dependency-ordered `work-items.md` whose items may mix fully-autonomous work with items that need you (a pre-work decision, a foreground build, or a human review), and you want the whole set driven to committed code in one run.
- You want each item independently verified against the project's own checks and reviewed through its recorded review before it is committed, not only built.
- You want a legible, fail-closed stop when something cannot be finished, rather than a partial or silently-degraded run.

**Do not invoke for:**

- **Producing or hardening the work items.** Use [`/plan-work-items`](../han-planning/plan-work-items.md) to break a plan into items first. This skill consumes a trusted result.
- **Building a single change test-first.** Use [`/tdd`](./tdd.md) directly. This skill is for driving a whole planned set, not one behavior.
- **Reviewing code without driving the loop.** Use [`/code-review`](./code-review.md) on a branch or files. This skill only reviews as one stage inside the per-item loop.

## How to invoke it

Run `/implement-work-items` in Claude Code.

Give it:

1. **A path to a `work-items.md`.** The file `/plan-work-items` produced. Every item must carry an `Expected paths` block plus the three per-item fields (`Requires pre-work decisions`, `Suggested implementation`, `Suggested review`), the build and review each tagged `AFK` or `HITL`, or recorded as a bare `none`. The driver runs one whole-run startup check that confirms every item is **drivable**: each item's recorded implementation skill resolves to an installed, invocable skill (or is a bare `none` free-form build), and its review is one the driver can turn into a verdict or a human read. It aborts the whole run before branching only when a named implementation skill is neither dispatchable nor invocable, or when the file is a pre-feature file that still carries the old `Type` field.
2. **Optional inputs, all defaulted.** `--gate critical|warning` (the severity at and above which a review finding blocks; default `warning`), `--fix-cap N` (maximum fix rounds per item; default `3`), `--model M` (the model the `AFK` build and fix sub-agents run on, never a foreground build or an inline fix; default `inherit`, your session model), `--branch NAME` (the run's branch; default `feat/<feature-dir>`), and `--verify "CMD"` (override the auto-detected verification commands).

The driver runs read-only checks first, then shows a plan preview (the effective configuration, the verification mode, the planning-artifact set, and each item's execution mode so you see where the run will pause) and waits for a single confirm or decline. It discloses once that the run has no mid-run stop. On confirm it works through the items, running unattended where it can and pausing in-session for each decision, foreground build, and human review; it either completes every item or halts on the first it cannot finish. Declining mutates nothing.

Example prompts:

- `/implement-work-items`. *"Drive docs/plans/user-invite-flow/work-items.md."*
- `/implement-work-items docs/plans/bulk-export/work-items.md --gate critical --fix-cap 1`. *"Only Critical findings block, and try at most one fix round per item."*

## What you get back

Committed code on a dedicated branch, not a report. Specifically:

- **A dedicated branch** (`feat/<feature-dir>` by default) whose first commit is the run's planning artifacts, followed by **one clean commit per completed item**, staged explicitly by path and following the project's commit convention. An item whose foreground skill committed its own work contributes that adopted commit range instead, and a pre-work decision recorded to a committed file adds its own decision commit. The driver never runs `git add -A`.
- **A completion summary** naming the branch, each item's execution mode and outcome (committed with its commit reference or range, or the one item that halted the run and why), the items not reached, and your next action (review and push the branch).
- **A durable review record per item** at `.implement-work-items/reviews/<W-N>-iter<fix-round>.md` (one per review round), plus an uncommitted work-state file at `.implement-work-items/state.json`. Both live in a self-ignoring directory (its `.gitignore` is a single `*`), so they never enter a commit and never show in `git status`. The review record holds the full findings; the condensed verdict the driver gates on references it by task ID.
- **On a halt, the five-part frame** instead of a summary of success: which item and phase stopped the run, the one-sentence reason, the tree state, the supporting evidence (with a pointer to the review record when the halt is review-gated), and what to do next, including that a re-invocation starts a fresh run and must be on a clean tree and a branch that does not already carry this run's commits.

## How to get the most out of it

- **Pair it downstream of `/plan-work-items`.** The driver reads the `Expected paths`, `Suggested implementation`, and `Suggested review` fields that skill produces. Run [`/plan-work-items`](../han-planning/plan-work-items.md) first; if an item's paths were flagged low-confidence because the plan gave no file-level detail, sharpen them before the run so the scope check is meaningful.
- **Use a real test suite to exercise the real gate.** The build, independent verification, and fix loop only get exercised on a project that defines verification commands and has a green suite. Point the driver at a repository with a real `pytest`/`npm test`/`go test` and so on. On a docs-only repository the run takes the scope-check-only path: it skips verification, though a review finding can still drive a fix.
- **Know the platform prerequisite.** An `AFK` `/code-review` review runs in a sub-agent that fans out its specialist panel one level deeper. That needs **Claude Code v2.1.172 or later**; below it the run refuses at startup rather than degrading the review, because the driver carries no reduced-coverage fallback.
- **Grant the runner if verification will not run.** The driver's `allowed-tools` covers the common runners (`npm`, `pytest`, `go`, `cargo`, `make`, and so on). A project whose verify command falls outside that set surfaces as a tooling-unavailable halt; add a Bash grant in the project's CLAUDE.md or route the command through `make`.
- **Set each item's markers before the run.** The driver routes each item by its recorded `AFK`/`HITL` markers and pre-work-decision flag, so sharpen or correct them in the `work-items.md` first, and the run pauses exactly where you intend and stays unattended everywhere else. An item whose implementation skill is not installed and invocable aborts the run at startup, so install or replace it before you start.

## YAGNI

`/implement-work-items` ships a deliberately small slice of a larger driver design: the decide, build, verify, review, fix, commit loop with in-session pauses for the human, and nothing more. Cross-session resume, a mid-run clean-stop, compaction-survival re-grounding, the rich interactive blocker menu (triage, accept-a-flagged-change, gate override, repair-upstream), and skip/defer are all deferred, each with a named reopening trigger in the feature's plan. The driver's answer to any state it cannot resolve is the fail-closed halt, not an added recovery affordance.

The code the driver produces is gated by the skills and agents it drives: a `/tdd` build applies YAGNI to its test list and refactor step, and a `/code-review` review surfaces YAGNI findings as a separate advisory class. The driver itself adds no speculative machinery. See [YAGNI](../../yagni.md) for the two gates, the acceptable-evidence list, the named anti-patterns, and the deferral format.

## Cost and latency

The driver runs on your session model and stays resident for the whole run, reading each sub-agent's compact report rather than its full output. What it dispatches depends on each item's markers. A fully-autonomous item dispatches a build sub-agent running its implementation skill and a review sub-agent (depth 1); a `/code-review` review fans its specialist panel out one level deeper (depth 2), the most expensive review shape. A `HITL` or `none` build and a `HITL` review dispatch no sub-agent at all: they run in your own session, so their cost is your time, not tokens. Each fix round adds another build-style dispatch plus a re-review through the same path, so a fully-autonomous item that takes the full `--fix-cap` is the most expensive shape. The driver also re-runs the project's full verification suite itself once per verify and once per re-verify. This is an infrequent, high-fan-out run built to drive a planned batch, not a tight interactive loop; the levers on cost are the item count, the fix cap, and the suite's runtime.

## In more detail

The run is a **mixed run driven by markers**. The driver reads each item's `Suggested implementation`, `Suggested review`, and `Requires pre-work decisions` markers and routes each phase from them. The plan preview lists every item with its build marker, its review marker, and whether it needs a pre-work decision, so you see before confirming where the run will pause; the completion summary names each item's execution mode and outcome. Whatever the mode, the middle of the loop is constant: the driver verifies every build itself, gates every review on one normalized verdict, and owns every commit. A foreground build or a human read changes who does the work, not whether the driver checks it.

The run is **single-pass with no resume**. The work-state file is an uncommitted convenience for the current session, not a durable ledger, so a halted run does not resume where it stopped; re-invoking starts fresh from the first item. The pauses this run takes for a decision, a foreground build, or a human review are all in-session; resuming a partially-complete run in a later session is a separate deferred feature. To keep a fresh run from rebuilding already-committed items, startup refuses a branch that already carries a prior run's commits. That is why the halt's what-to-do-next tells you to start a fresh branch (or cherry-pick the completed items forward) rather than re-run in place.

The driver **judges scope in the review and owns the commits**. The review compares the item's changed files (committed and uncommitted, since a sub-agent build does not commit) against that item's declared `Expected paths` (from `/plan-work-items`), which are a hint, not a hard boundary: a change that reaches genuinely beyond the item's work is a `SCOPE` finding that gates at the same `--gate` threshold as any other finding, rather than a mechanical halt on any path deviation. The run's first commit is the work items file and the spec, plan, and research it references; each item's own code then lands as its own subsequent commit, staged by path. When the project defines no verification commands, the driver runs in scope-check-only mode: it skips verification but still reviews each item for scope and quality, says so in the plan preview, and treats confirming the plan as the conscious confirm of the reduced gate.

The **halt posture is deliberately absolute**. The larger driver design offers an operator a recovery menu (triage, accept a flagged change, override the gate, repair an upstream item, defer, skip); the driver offers none of that. It halts on the first unresolvable item and reports where and why, on the stated assumption that you would rather read a clean stop than have the driver guess. A verification command that *reports failures* enters the fix loop; a command that *fails to execute* (a missing tool, a downed service) is a tooling-or-environment halt, never fed to the fix loop as if the code were at fault. No review sees known-broken code: a red verify routes straight to a fix.

This is the suite's **first skill-to-skill orchestrator**. Earlier skills dispatch agents; this one dispatches sub-agents that themselves run skills (`/tdd`, `/code-review`, and the item's other recorded skills), and an `AFK` `/code-review` review sub-agent fans out a further panel. That topology is what the v2.1.172 prerequisite buys, and it is why the review runs one level down: the panel's deliberation stays out of the driver's context, and only the condensed verdict returns. The driver itself never calls the `Skill` tool; a `HITL` or `none` build runs the skill in your own session, and the driver picks the item back up when you confirm it is done.

## Sources

The skill composes existing practice rather than introducing its own; its one load-bearing external dependency is the platform capability that makes the review fan-out possible.

### Claude Code sub-agents documentation (nested sub-agents)

The review stage dispatches a sub-agent that itself dispatches the `/code-review` specialist panel. Nested sub-agent dispatch, and the depth limit it operates under, are the documented platform capability the review topology and the v2.1.172 prerequisite rest on.

URL: https://code.claude.com/docs/en/sub-agents.md

## Related documentation

- [Plugin landing page](../../../README.md). The front door. Start here if you arrived from outside the docs tree.
- [YAGNI](../../yagni.md). The evidence-based "You Aren't Gonna Need It" rule. The driver ships the simplest slice of a larger design; the deferrals follow this rule's format.
- [`/plan-work-items`](../han-planning/plan-work-items.md). Produces the `work-items.md` this skill consumes, including the `Expected paths`, `Suggested implementation`, and `Suggested review` fields the driver reads. Run it first.
- [`/tdd`](./tdd.md). The build skill the driver dispatches for a testable-code item's `AFK` build and its fix rounds; other items record other implementation skills.
- [`/code-review`](./code-review.md). The review the driver dispatches for a code item's `AFK` review; its panel and severity vocabulary are one source the normalized verdict summarizes, alongside a non-code review agent or your own read.
- [Skill building guidance](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/). The progressive-disclosure, description-frontmatter, script-execution, and bash-permission rules this skill follows.
