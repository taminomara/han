---
name: implement-work-items
description: >
  Drive a trusted work-items.md through an unattended build, verify, review,
  fix, and commit loop, one item at a time on a dedicated branch. Use when a set
  of fully-autonomous work items is already planned and you want each one built with
  tdd, independently verified against the project's own checks, reviewed at full
  specialist coverage, fixed to a quality gate, and committed without
  hand-invoking each skill per item. The run confirms a plan once, then either
  completes every item or halts on the first it cannot finish cleanly, leaving
  the finished items committed. Does not produce or harden work items (use
  plan-work-items). Does not build a single change test-first on its own (use
  tdd). Does not review code without driving the loop (use code-review). Requires
  Claude Code v2.1.172 or later for the review fan-out.
argument-hint: "[path to work-items.md] [--gate critical|warning] [--fix-cap N] [--model M] [--branch NAME] [--verify \"CMD\"]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(find *), Bash(claude --version), Bash(npm *), Bash(npx *), Bash(pnpm *), Bash(yarn *), Bash(pytest *), Bash(python3 *), Bash(go *), Bash(cargo *), Bash(make *), Bash(bundle *), Bash(rake *), Bash(mix *), Bash(mvn *), Bash(gradle *), Bash(dotnet *)
---

# Implement Work Items

This skill mutates a real repository: it creates a branch and writes one commit
per completed work item. It is an orchestration skill that dispatches build and
review sub-agents, runs the project's verification itself, and owns every
commit. It never asks the sub-agents to commit. These constraints shape every
step and override any instinct to move faster.

## Project Context

- Claude Code version: !`claude --version`
- git version: !`git --version 2>/dev/null || echo "not installed"`
- current branch: !`git branch --show-current 2>/dev/null || true`
- CLAUDE.md: !`find . -maxdepth 1 -name "CLAUDE.md" -type f`
- project-discovery.md: !`find . -maxdepth 3 -name "project-discovery.md" -type f`

## Step 1: Prepare and Validate (read-only)

Run only read-only checks in this step. Do not create a branch, write a file, or
commit anything here, so a refusal or a declined plan leaves the repository
untouched. Every refusal below names the condition, the reason, and the remedy,
then stops the run before anything is branched or committed.

### 1.1 Version preflight

Read the `Claude Code version` from Project Context. If it's below `2.1.172`,
refuse: name the version found and tell the operator to upgrade Claude Code,
because the review fan-out needs nested sub-agents and the core has no
reduced-coverage fallback.

### 1.2 Resolve inputs

Resolve the target `work-items.md` from the argument or the conversation; if it
cannot be found or read, refuse and name the path tried. Resolve the optional
inputs and their defaults:

- `--gate` (default `warning`): the severity at and above which a review finding
  blocks the gate (any Critical or Warning by default).
- `--fix-cap` (default `3`): the maximum fix rounds per item (consumed in W-4;
  previewed here).
- `--model` (default `inherit`): the model the build and fix sub-agents run on.
  `inherit` runs them on the operator's session model (there is no variable that
  reads the session model; `inherit` is the value that selects it).
- `--branch` (default `feat/<feature-dir>`, where `<feature-dir>` is the
  basename of the folder holding the work-items file): the branch the per-item
  commits land on.
- `--verify "CMD"` (default: auto-detected, see 1.3): an override for the
  project's verification commands.

### 1.3 Detect the environment

Run `${CLAUDE_SKILL_DIR}/scripts/detect-driver-context.sh` once and capture its
output: git availability, the current and default branch, the uncommitted-file
list (between the `uncommitted-start` and `uncommitted-end` markers), and the
manifest-inferred commands. If it reports `git-available: false`, refuse: this
skill commits per item and cannot run without git.

Resolve the project's verification commands in this order: read CLAUDE.md's
`## Project Discovery` section for the test, lint, and build commands; fall back
to `project-discovery.md`; fall back to the script's manifest-inferred commands.
A `--verify` override replaces the detected set. When nothing resolves, the run
uses **scope-check-only** mode (the changed-file check with no test, lint, or
build re-run).

For every resolved verification command, confirm its tool is on PATH (for
example with `which`) and runnable under this skill's Bash grants. If a required
tool is missing, or a command's runner falls outside those grants so it cannot
execute, refuse and name every affected command together: tell the operator to
install the tool and make it runnable, grant its prefix in the project's
CLAUDE.md, route the command through `make`, or narrow the verification set with
`--verify`, before re-invoking. An un-runnable verification command is a
tooling-unavailable refusal, never a silent skip.

### 1.4 Identify the planning artifacts

The planning artifacts are the work-items file plus the local `.md` files it
links in its preamble (the intro paragraph and any Shared reference artifacts
section) as its context: the spec, plan, and research it references. Parse those
links from the preamble. Source files the work items target do not qualify. This
set is committed first in Step 2 and is the one exception to the clean-tree
check.

### 1.5 Confirm a clean tree and green suite

From the script's uncommitted-file list, treat the run's planning artifacts
(1.4) and the driver's own `.implement-work-items/` directory as allowed. If any
other file is uncommitted, refuse and tell the operator to commit or stash it
first, because the unrelated-change check runs before anything is committed so
nothing extra is folded into the first commit.

Where verification commands resolved, run them once now and confirm the suite is
green. If it is red, refuse: the driver cannot tell newly introduced breakage
from pre-existing breakage, so name the remedy (get the suite green, or narrow
the verification command to exclude the known-failing tests, then re-invoke). In
scope-check-only mode there is no suite to run, so skip this check.

### 1.6 Refuse a prior-run branch

Check whether the target branch already exists and carries a prior run's marker.
If the branch does not exist yet, it carries no prior run and this check passes.
If it exists, look for the `Implement-Work-Items-Run` trailer in its history with
`git log`; if the trailer is present, refuse and name the branch, because the run
is single-pass with no resume and re-running on it would rebuild
already-committed items. Direct the operator to a fresh branch.

### 1.7 Validate the work items

Parse the work items from the file: each heading of the form `## <W-N>` (the
work-item template heading) begins an item whose body runs to the next heading.
Then validate, refusing on the first failure with the offending items named:

- **Not empty.** The file has at least one buildable work item. An empty file or
  one with no buildable items is a startup refusal.
- **Fields present.** Every item carries an `**Expected paths.**` block and the
  three per-item fields the producer records: `**Requires pre-work decisions.**`,
  `**Suggested implementation.**`, and `**Suggested review.**` (these field names
  are defined in the work-item template; read them verbatim). An item that omits
  these fields but carries an old `**Type.**` field is a **pre-feature file**:
  refuse and tell the operator to re-run `plan-work-items`, which produces the new
  fields. An item missing them with no `**Type.**` is refused with the same re-run
  remedy.
- **All fully autonomous.** Each of `Suggested implementation` and `Suggested
  review` records a skill or agent plus an `AFK` or `HITL` marker, and `Requires
  pre-work decisions` is `yes` or `no`. An item is fully autonomous only when both
  markers are `AFK` and `Requires pre-work decisions` is `no`. Refuse any item that
  is not fully autonomous (a `HITL` implementation or review, a required pre-work
  decision, or a bare `Suggested implementation` of `none`), naming those items:
  this core drives only fully-autonomous items, so tell the operator to build them
  by hand or wait for the human-in-the-loop follow-on.
- **Supported combination.** Of the fully-autonomous items, this core drives only
  the combination whose `Suggested implementation` is `han-coding:tdd` and whose
  `Suggested review` is `han-coding:code-review`. Refuse any fully-autonomous item
  whose combination differs, naming those items and giving this reason distinctly
  from the not-fully-autonomous refusal: their skill or review is one this core does
  not yet drive, so tell the operator to run the named skill directly (a follow-on
  expands the supported set).
- **Well-formed graph.** Build the dependency graph from each item's
  `**Depends on.**` field. Refuse on a duplicate item identifier, a `Depends on`
  that names an absent item, a self-dependency, or a cycle, naming each fault and
  its fix (de-duplicate the id, repair the reference, break the cycle).

Build the run order as a topological sort of the graph, preserving the file's
order wherever the graph allows it.

### 1.8 Resolve the base branch

Resolve the base the run will branch from, to show in the preview. Prefer, in
order: a local `main` or `master`; then `origin/main`, `origin/master`,
`upstream/main`, or `upstream/master`. Never default to the current HEAD: the
skill may be invoked from another feature's branch or a detached state, so the
current branch is not a safe base. If none of those bases exist, or the intended
base is genuinely ambiguous, ask the operator which base to branch from before
proceeding. This is a read-only clarification, not the run's one confirmation.
The `git fetch --all` that freshens the base, and the branch creation itself,
happen in Step 2.2.

## Step 2: Confirm the Plan, then Set Up

### 2.1 Preview and confirm

Show the operator the run plan in plain language: the effective gate threshold,
the fix-loop cap, the build/fix model, the branch the per-item commits will land
on and the base it branches from (Step 1.8), the verification configuration (the
resolved commands, or that the run is
**scope-check-only** because the project defines none, naming what will and will
not be checked), and the planning-artifact set that will be committed first.
Then list the items in run order, each named with its recorded implementation
skill and review (for a drivable run these are `han-coding:tdd` and
`han-coding:code-review`). Wait for the operator to **confirm** or **decline**.

On **decline**, stop and confirm that no branch was created and nothing was
committed.

### 2.2 Set up (only after confirm)

Only after the operator confirms, mutate the repository, in this order. If any
step fails (the branch cannot be created, the commit is rejected by a hook),
report exactly what failed and stop before processing any item.

1. Run `git fetch --all` to freshen remote-tracking refs, then create the
   dedicated branch (the resolved `--branch`, or the `feat/<feature-dir>`
   default) off the base resolved in Step 1.8, never off the current HEAD.
2. Create the driver's artifact directory and make it self-ignoring, so git
   never sees its contents: create `.implement-work-items/` and write a
   `.gitignore` there whose only line is `*`.
3. Detect the commit convention: read CLAUDE.md or `project-discovery.md` for a
   stated convention; default to Conventional Commits (`type(scope): subject`)
   when none is stated.
4. Mark the branch as a driver run. If any planning artifacts (1.4) are
   uncommitted, commit them as the first commit, staged explicitly by path,
   carrying an `Implement-Work-Items-Run: <feature-dir>` trailer (the marker 1.6
   reads). If they are already committed so there is nothing to stage, make an
   empty commit (`git commit --allow-empty`) carrying the same trailer rather
   than failing, so the branch is marked either way.
5. Initialize the **work-state file** `.implement-work-items/state.md`. It contains
   the run configuration (work-items path, branch, gate threshold, fix-loop cap,
   build/fix model, and the verification configuration or scope-check-only) followed
   by each item's status. Initialize every item to `pending`. As the loop runs,
   mark the active item `in-progress`, then `done` with its commit reference and
   review-record path, or `halted` with the reason.

## Step 3: Per-Item Loop (Build, Verify, Review, Commit)

Process items one at a time in run order. Keep the run legible: narrate each item
as it begins (the item, its position in the run order, and the phase starting),
each sub-agent dispatch, and each verification command with a one-line result.
Update `.implement-work-items/state.md` as the item moves through the loop. Drive
this loop for each item, owning the verification and the commit yourself.

### 3.1 Build

Dispatch a build sub-agent (general-purpose) through the `Agent` tool, passing
the resolved `--model` as its `model` (the default `inherit` runs it on the
operator's session model), instructing it to run the item's recorded
implementation skill (for a drivable run, `han-coding:tdd`) on this item
and to build against
the item's `References` and the committed spec or plan the work-items file names.
Hand it the item, and copy the
[build-report contract](./references/build-report-contract.md) verbatim into the
prompt. The sub-agent leaves its changes in the working tree and returns the
compact report; it does not commit.

Parse the report fail-closed against the contract. If parse fails (contract's
halt conditions are met), apply Halt Procedure.

### 3.2 Verify (independent)

Do not trust the report's FINAL GATE. Verify the item independently, in two
parts:

1. **Run the project's verification commands** yourself, one at a time (not
   through the sub-agent). Distinguish a command that **runs and reports
   failures** (a genuine test, lint, or build failure) from one that **fails to
   execute** (a missing tool, a service down, a full disk): the latter is a
   tooling-or-environment halt, not a code failure (Halt Procedure). In
   scope-check-only mode there are no commands to run.
2. **Scope check.** Compare the item's changed files (`git status` and `git diff`
   against the item's base commit) to its `Expected paths`, treating each added,
   modified, or deleted path (a rename is a delete plus an add, so an item that
   renames a file must declare both paths). Exclude files the project ignores,
   any code-generation or sync output produced by the build or verify steps,
   and the driver's own `.implement-work-items/` artifacts. A build that changed
   no files after exclusions, or a changed file outside the declared paths,
   halts the run (Halt Procedure), naming the file.

If a verification command reported failures (part 1), do not continue to the
review: route to the fix loop (3.4) directly, so the panel never reviews
known-broken code.

### 3.3 Review

When verification passed, dispatch one review sub-agent at depth 1 through the
`Agent` tool, using a general-purpose sub-agent that retains the `Agent` tool so
`han-coding:code-review` can fan out its specialist panel at depth 2. Direct it
to run the item's recorded review (for a drivable run, `han-coding:code-review`)
on the item's changes, giving it the item and the
spec sections the item references so it judges the change against what the item asked
for, and to persist the full review record at `.implement-work-items/reviews/<W-N>.md`.
Copy the [review-verdict contract](./references/review-verdict-contract.md)
verbatim into the prompt, and direct it to return only the condensed verdict.

Parse the verdict fail-closed against the contract. If parse fails (contract's
halt conditions are met), apply Halt Procedure.

### 3.4 Fix to the gate (bounded loop)

The item clears the gate when verification passed and the review verdict reports
no finding at or above the configured threshold; a cleared item goes straight to
the commit (3.5).

Enter the fix loop when the initial verification reported failures, or the
initial review returned a gate-blocking finding. A `--fix-cap` of `0` enters no
round: halt immediately on that first verification failure or gate-blocking
finding (the safe cap-zero behavior), with the residual findings or the failing
output as the halt's supporting evidence.

Otherwise run up to `--fix-cap` rounds, narrating each as `fix round N of <cap>`.
Each round:

1. **Fix.** Dispatch a fresh fix sub-agent (general-purpose) through the `Agent`
   tool with the resolved `--model`, instructing it to run the item's recorded
   implementation skill (for a drivable run, `han-coding:tdd`). Give
   it the original build context (the item, its `References`, the spec sections)
   and the current cumulative diff (the working tree against the item's base
   commit, the commit at item start). When the round follows a review that
   returned findings, also give it the durable review record at
   `.implement-work-items/reviews/<W-N>.md`; when the round follows a
   verification failure, give it the failing verification output instead (no
   review record exists on that path). Copy the
   [build-report contract](./references/build-report-contract.md) verbatim; parse
   the return fail-closed and apply the Halt Procedure on its halt conditions.
2. **Re-verify.** Run the verification commands and the scope check as in 3.2. A
   command that **fails to execute** halts as a tooling-or-environment problem
   (Halt Procedure), not a not-cleared round. An **out-of-path change** halts
   immediately, naming the file (Halt Procedure), not a not-cleared round. A
   command that **reports failures** is a **not-cleared round**: loop to the next
   fix without re-reviewing, so the panel never reviews known-broken code. A
   **pass** advances to re-review. In scope-check-only mode there are no commands,
   so re-verify can only pass or halt on an out-of-path change; it never produces
   a verification-failure not-cleared round.
3. **Re-review.** Dispatch the review sub-agent again as in 3.3. An
   **untrustworthy verdict** halts immediately (Halt Procedure), not a
   not-cleared round. A **clean verdict** clears the gate: commit the item (3.5).
   **Gate-blocking findings** make it a **not-cleared round**: loop to the next
   fix.

If the cap is reached with the gate still not clear, halt (Halt Procedure) with
the residual findings or failing verification output listed and reported as
**gate not cleared**. Reserve
"unsatisfiable" for a build sub-agent's own escalation that the item cannot be
built as written (3.1); a cap-reached halt is "gate not cleared", not
"unsatisfiable".

### 3.5 Commit

When the item clears the gate, commit it as one clean commit following the
detected convention, staging only the item's own code changes explicitly by path
(never `git add -A`) and never the driver's artifacts. Record the item `done` in
the work-state file with the commit's short reference and the review-record path,
report the commit reference to the operator, and advance to the next item. If the
commit is rejected (a pre-commit hook, a lock), halt (Halt Procedure), leaving
the verified, reviewed work in the tree.

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
