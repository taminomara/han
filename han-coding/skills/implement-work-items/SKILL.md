---
name: implement-work-items
description: >
  Drive a trusted work-items.md through an unattended build, verify, review,
  fix, and commit loop, one item at a time on a dedicated branch. Use when a set
  of AFK-typed work items is already planned and you want each one built with
  tdd, independently verified against the project's own checks, reviewed at full
  specialist coverage, fixed to a quality gate, and committed without
  hand-invoking each skill per item. The run confirms a plan once, then either
  completes every item or halts on the first it cannot finish cleanly, leaving
  the finished items committed. Does not produce or harden work items (use
  plan-work-items). Does not build a single change test-first on its own (use
  tdd). Does not review code without driving the loop (use code-review). Requires
  Claude Code v2.1.172 or later for the review fan-out.
argument-hint: "[path to work-items.md] [--gate critical|warning] [--fix-cap N] [--model M] [--branch NAME] [--verify \"CMD\"]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(find *), Bash(claude --version), Bash(npm *), Bash(npx *), Bash(pnpm *), Bash(yarn *), Bash(pytest *), Bash(python3 *), Bash(go *), Bash(cargo *), Bash(make *), Bash(bundle *), Bash(rake *)
---

## Project Context

- Claude Code version: !`claude --version`
- git version: !`git --version 2>/dev/null || echo "not installed"`
- current branch: !`git branch --show-current 2>/dev/null || true`
- CLAUDE.md: !`find . -maxdepth 1 -name "CLAUDE.md" -type f`
- project-discovery.md: !`find . -maxdepth 3 -name "project-discovery.md" -type f`

## Constraints (read before anything else)

This skill mutates a real repository: it creates a branch and writes one commit
per completed work item. It is an orchestration skill that dispatches build and
review sub-agents, runs the project's verification itself, and owns every
commit. It never asks the sub-agents to commit. These constraints shape every
step and override any instinct to move faster.

- **The review fan-out needs nested sub-agents.** The review stage runs in a
  sub-agent (depth 1) that fans out `han-coding:code-review`'s specialist panel
  (depth 2), which requires Claude Code v2.1.172 or later. The running version
  is probed at load (see Project Context) and Step 1 refuses to start below it,
  because the core carries no reduced-coverage single-reviewer fallback and a
  below-version review verdict cannot be trusted as a full-coverage pass.
- **A verification command that will not run is a tooling-unavailable halt.**
  `allowed-tools` grants a fixed per-prefix set of runners, so a target
  project's verify command outside that set cannot execute. Treat it as a
  tooling-unavailable halt, never a silent skip, and name the remedy in the halt
  (grant the prefix in the project's CLAUDE.md, or route the command through
  `make`).
- **Never `git add -A`; the driver's own artifacts stay out of history.** Every
  per-item commit stages the item's own code changes explicitly by path. The
  driver's working artifacts live in a git-excluded directory inside the plan
  folder, `.implement-work-items/` (the uncommitted work-state file at
  `.implement-work-items/state.md` and the per-item durable review records at
  `.implement-work-items/reviews/<W-N>.md`). These are excluded from the
  changed-file scope check and from every commit. A stray add-all that folds a
  work-state file or a review record into a code commit breaks the clean-history
  invariant.
- **Fail closed on any untrustworthy sub-agent return.** The build-report and
  review-verdict contracts are imposed by dispatch instruction; the platform
  does not validate the returns against a schema. Parse every return
  defensively and treat a malformed or incomplete report as untrustworthy, which
  halts the run. The two contracts are defined in
  [references/build-report-contract.md](./references/build-report-contract.md)
  and [references/review-verdict-contract.md](./references/review-verdict-contract.md);
  their text is copied verbatim into the matching dispatch prompt so the
  sub-agent returns exactly what the driver parses.

# Implement Work Items

## Step 1: Prepare and Validate (read-only)

Run only read-only checks in this step, so a refusal or a declined plan leaves
the repository untouched. Do not branch or commit anything here.

**Preflight.** Confirm the probed Claude Code version (see Project Context) is
v2.1.172 or later. Refuse to start below it, naming the version found and the
remedy (upgrade Claude Code), because the review fan-out needs nested sub-agents
and the core has no reduced-coverage fallback.

Then, still read-only:

- Resolve the target `work-items.md` and the optional inputs: gate threshold,
  fix-loop cap, build/fix model, branch name, and a `--verify` override.
- Resolve the project's verification commands from the project's own
  configuration: read CLAUDE.md's `## Project Discovery` section for the test,
  lint, and build commands; fall back to `project-discovery.md`; then infer from
  the project's manifest. When none resolve, use scope-check-only mode. Confirm
  the tooling those commands need is available.
- Confirm the working tree is clean apart from the run's own planning artifacts.
- Where verification commands exist, confirm the suite is green.
- Confirm the target branch does not already carry a prior run's
  planning-artifacts commit.
- Validate the items: a well-formed dependency graph (no cycles, no duplicate
  identifiers, every `Depends on` naming a present item), the presence of the
  `expected-paths` and `Type` fields on every item, and that no item is typed
  `HITL`.

Refuse on an empty file, a file with no buildable items, or any `HITL`-typed
item: these are startup refusals, not partial runs. Name the condition, the
reason, and the remedy in every refusal.

*(The version comparison, the exact detection and validation checks, the
planning-artifact identification, and the prior-run marker check are authored in
W-3.)*

## Step 2: Confirm the Plan, then Set Up

Show the operator the run plan and wait for a single confirmation before any
repository mutation. In the preview, state the effective run configuration (the
review gate threshold, the fix-loop cap, the build/fix model, the branch the
per-item commits will land on, the verification configuration or
scope-check-only mode in plain language, and the planning-artifact set that will
be committed first), then list the items in dependency order, each named with
its build skill (`han-coding:tdd`).

On **decline**, stop and confirm that no branch was created and nothing was
committed. On **confirm**, and only then, mutate the repository: create the
dedicated branch, commit the planning artifacts as the first commit (carrying
the prior-run marker), detect the project's commit convention, and initialize
the uncommitted work-state file.

*(The preview rendering, branch creation, planning-artifact commit,
commit-convention detection, and work-state initialization are authored in W-3.)*

## Step 3: Per-Item Loop (Build, Verify, Review, Fix, Commit)

Process items one at a time in dependency order. For each item, drive this fixed
loop, owning the verification and the commit yourself:

1. **Build.** Dispatch a build sub-agent through the `Agent` tool with a per-call
   model, instructing it to run `han-coding:tdd` and copying the
   [build-report contract](./references/build-report-contract.md) verbatim into
   the prompt. The sub-agent leaves its changes in the working tree and returns
   the compact report; it never commits.
2. **Verify.** Re-run the project's own verification commands directly (not
   through the sub-agent), and run the scope check comparing the changed files
   against the item's `expected-paths`, after exclusions.
3. **Review.** Dispatch one review sub-agent at depth 1 through the `Agent` tool.
   It retains the `Agent` tool so it can run `han-coding:code-review` and fan out
   that skill's specialist panel at depth 2. Copy the
   [review-verdict contract](./references/review-verdict-contract.md) verbatim
   into the prompt and direct it to persist the durable record at
   `.implement-work-items/reviews/<W-N>.md` and return only the condensed
   verdict.
4. **Fix to the gate.** When verify reports failures or the review returns a
   finding at or above the gate threshold, run the bounded fix loop.
5. **Commit.** When verification is green and the review clears the gate, stage
   the item's own code changes explicitly by path (never `git add -A`), commit
   one clean commit for the item, and record the item done in the work-state
   file with its commit reference and review-record path.

Halt the whole run through the Halt Procedure below on any state you cannot
resolve unattended.

*(The happy-path logic and the pre-fix halts are authored in W-3; the bounded
fix loop and its fix-round halts are authored in W-4.)*

### Halt Procedure

When the run hits a state it cannot resolve unattended, stop advancing and
present the halt using this frame with five named parts, in order:

1. **Status line.** Which item and which phase halted, and the item's position
   in the run order (for example, "W-4 (item 4 of 7), Review").
2. **One-sentence reason.** The single condition that stopped the run, stated
   plainly.
3. **Tree-state disclosure.** The uncommitted files belonging to the halting
   item that remain in the working tree, and an explicit statement that the
   items completed before the halt stay committed on the branch.
4. **Supporting evidence.** Which sub-agent or check raised it, the relevant
   spec or acceptance criteria, and the raw verification output or the residual
   findings. When the halt is review-gated, add a pointer to the durable review
   record at `.implement-work-items/reviews/<W-N>.md`.
5. **What to do next.** The run does not resume, so a re-invocation starts a
   fresh run from the first item. Name a resolution suited to the halt kind
   (amend the spec, fix the item, or build it by hand); state that a fresh
   re-invocation must be on a clean tree and a branch that does not already
   carry this run's commits (so the operator commits or stashes the halting
   item's work and starts a fresh branch, or cherry-picks the completed items
   forward by hand); and name the branch and the commit range of the completed
   items so the operator can reference them.

## Step 4: Completion Summary

When every item is complete or the run has halted, report the completion
summary: the branch name, each item's outcome (built and committed with its
commit reference, or the one item that halted the run and why), the items not
reached, and the next action for the operator (review and push the branch;
sharing the branch stays with the operator).
