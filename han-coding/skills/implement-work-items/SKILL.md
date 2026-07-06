---
name: implement-work-items
description: >
  Drive a trusted work-items.md through a build, verify, review, fix, and commit
  loop, one item at a time on a dedicated branch. Routes each item by its recorded
  markers: builds it unattended in a sub-agent or in the foreground with the
  operator steering, reviews it through one normalized verdict (code review, a
  non-code review agent, or a human read), verifies every build itself, and commits per
  item. Use when a planned work-items.md mixes items that run unattended with items
  that need a human: a pre-work decision, an interactive build, or a human review.
  The run confirms a plan once, then either completes every item or halts on the
  first it cannot finish cleanly, leaving the finished items committed. Does not
  produce or harden work items (use plan-work-items). Does not build a single
  change test-first (use tdd). Does not review without driving the loop (use
  code-review). Requires Claude Code v2.1.172 or later for the review fan-out.
argument-hint: "[path to work-items.md] [--gate critical|warning] [--fix-cap N] [--model M] [--branch NAME] [--verify \"CMD\"]"
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, TaskCreate, TaskUpdate, Bash(git *), Bash(find *), Bash(cp *), Bash(claude --version), Bash(npm *), Bash(npx *), Bash(pnpm *), Bash(yarn *), Bash(pytest *), Bash(python3 *), Bash(go *), Bash(cargo *), Bash(make *), Bash(bundle *), Bash(rake *), Bash(mix *), Bash(mvn *), Bash(gradle *), Bash(dotnet *), Bash(jq *)
---

# Implement Work Items

## Pre-requisites

- Claude Code version: !`claude --version || echo "unknown"`

This skill needs Claude Code `2.1.172` or later for the review fan-out (nested
sub-agents); Step 1.1 gates on the version above.

## Project Context

- git version: !`git --version 2>/dev/null || echo "not installed"`
- current branch: !`git branch --show-current 2>/dev/null || echo "unknown"`
- CLAUDE.md: !`find . -maxdepth 1 -name "CLAUDE.md" -type f`
- project-discovery.md: !`find . -maxdepth 3 -name "project-discovery.md" -type f`
- jq: !`which jq || echo "not installed"`

## Step 1: Prepare and Validate (read-only)

### 1.1 Version preflight

Read the `Claude Code version` from Pre-requisites. If it's below `2.1.172`,
halt: name the version found and tell the user to upgrade Claude Code
because the review fan-out needs nested sub-agents.

### 1.2 Resolve inputs

Resolve the target `work-items.md` from the argument or the conversation; if it
cannot be found or read, halt and name the path tried. Resolve the optional
inputs and their defaults:

- `--gate` (default `warning`): the severity at and above which a review finding
  blocks the gate.
- `--fix-cap` (default `3`): the maximum fix rounds per item, counted after the
  initial build.
- `--model` (default `inherit`): the model the build and fix sub-agents run on.
- `--branch` (default `feat/<feature-dir>`, where `<feature-dir>` is the
  basename of the folder holding the work-items file): the branch the per-item
  commits land on.
- `--verify "CMD"` (default: auto-detected, see 1.3): an override for the
  project's verification commands.

### 1.3 Detect the environment

Run `${CLAUDE_SKILL_DIR}/scripts/detect-driver-context.sh` once and capture its
output: git availability, the current and default branch, the uncommitted-file
list (between the `uncommitted-start` and `uncommitted-end` markers), and the
manifest-inferred commands. If it reports `git-available: false`, halt: this
skill commits per item and cannot run without git.

Resolve the project's verification commands in this order: read CLAUDE.md's
`## Project Discovery` section for the test, lint, and build commands; fall back
to `project-discovery.md`; fall back to the script's manifest-inferred commands.
A `--verify` override replaces the detected set. When nothing resolves, the run
uses **scope-check-only** mode (the changed-file check with no test, lint, or
build re-run).

### 1.4 Identify the planning artifacts

The planning artifacts are the work-items file plus the local `.md` files it
links in its preamble (the intro paragraph and any Shared reference artifacts
section) as its context. Parse those links from the preamble. Source files
the work items target are not included in context.

### 1.5 Validate the work items

Parse the work items from the file: each heading of the form `## <W-N>`
begins an item whose body runs to the next heading. Then validate, halting
on the first failure with the offending items named:

- **Not empty.** The file has at least one buildable work item. An empty file or
  one with no buildable items is a startup refusal.
- **Fields present.** Every item carries an `**Expected paths.**` block and the
  three per-item fields the producer records: `**Requires pre-work decisions.**`,
  `**Suggested implementation.**`, and `**Suggested review.**`. If they are not
  present, instruct user to update and re-run `plan-work-items` skill.
- **Drivable.** Each of `Suggested implementation` and `Suggested review` records a
  skill or agent plus an `AFK` or `HITL` marker, and `Requires pre-work decisions`
  is `yes` or `no`. Every named implementation skill or sub-agent must be installed
  and invocable (`general-purpose` is a built-in agent, always available). A bare
  `none` implementation needs no skill and is drivable as a free-form foreground
  build; likewise a bare `none` review is a free-form human read. A `none`, AFK
  build is a refusal: a bare `none` build is always foreground.
- **Type and no-output guards.** Read each item's `Type` (absent means
  `deliverable`, so older files drive unchanged); a present value outside
  `deliverable`, `audit`, `spike` is a refusal. Keyed on that
  `Type`: `Expected paths: None` on a non-`audit` item is a refusal (only an
  audit may produce nothing), and an `AFK` review on an `audit` item or
  any item declaring `Expected paths: None` is a refusal (its review is a human
  confirmation).
- **Well-formed graph.** Build the dependency graph from each item's
  `**Depends on.**` field. Halt on a duplicate item identifier, a `Depends on`
  that names an absent item, a self-dependency, or a cycle.

Build the run order as a topological sort of the graph, preserving the file's
order wherever the graph allows it.

### 1.6 Resolve the base branch

Run `git fetch --all`, then resolve the base the run will branch from, to show
in the preview. Prefer, in order of freshness: a local `main` or `master`;
then `origin/main`, `origin/master`, `upstream/main`, or `upstream/master`. Never
default to the current HEAD: the skill may be invoked from arbitrary git state.
If none of those bases exist, or the intended base is genuinely ambiguous,
ask the user which base to branch from before proceeding.

### 1.7 Classify the invocation

With the work-items path (1.2) and the base (1.6) resolved, classify this
invocation. Run
`${CLAUDE_SKILL_DIR}/scripts/scan-run-history.sh <work-items-path> <base-ref>`,
passing the resolved work-items path repo-root-relative and the base from 1.6,
and read its `classification:` line. Branch on it:

- **fresh** — the branch carries no prior run commits. Proceed as a fresh run:
  the clean-tree gate (1.8) applies in full, then setup (Step 2).
- **resume** — the branch carries this run's progress record. Enter the
  cross-session resume path: run the
  [re-grounding routine](./references/re-grounding-routine.md), then **announce
  the concrete next action** — the specific next item, the phase it resumes at,
  and the disposition of any in-progress item — and **wait for the operator's
  go-ahead before the first build, discard, or durable write.**
- **refuse** — the branch carries commits but no run record for this file: a
  foreign base. Halt and direct the user to a fresh branch.
- **no-base** — the base did not resolve to a commit. Surface it and ask the
  user which base to branch from before proceeding, rather than continuing.

### 1.8 Confirm a clean tree and green suite

On a **fresh** run, from the script's uncommitted-file
list, treat the run's planning artifacts (1.4) and the driver's own
`.implement-work-items/` directory as allowed. If any other file is uncommitted,
halt and tell the user to commit or stash it first, otherwise extra files might
be folded into the first commit.

Where verification commands resolved, run them once now and confirm the suite is
green. If it is red, halt: the driver cannot tell newly introduced breakage
from pre-existing breakage, so name the remedy (get the suite green, or narrow
the verification command to exclude the known-failing tests, then re-invoke). In
scope-check-only mode there is no suite to run, so skip this check.

On a **resume**, the single in-progress item's uncommitted work is the one
allowed exception to this precondition: the gate does not refuse that expected
dirty tree. Its green-suite re-check is re-established after that item's work is
inspected.

## Step 2: Confirm the Plan, then Set Up

### 2.1 Preview and confirm

Show the user the run plan in plain language: the effective gate threshold,
the fix-loop cap, the build/fix model, the branch the per-item commits will land
on and the base it branches from, the verification configuration (the resolved
commands, or **scope-check-only** when the project defines none, naming what will
and will not be checked), and the resolved planning-artifact set. Then list the
items in run order, each named with its implementation (skill + `AFK`/`HITL`/`none`
build marker), its review (skill/agent + `AFK`/`HITL`/`none` review marker), and
whether it `Requires pre-work decisions`. Wait for the user
to **confirm** or **decline**.

On **decline**, halt and confirm that no branch was created and nothing was
committed.

### 2.2 Set up

After the user confirms, mutate the repository. If any step fails (the branch
cannot be created, a commit is rejected by a hook), report exactly what failed
and stop before processing any item.

Detect the commit convention: read CLAUDE.md or `project-discovery.md` for a
stated convention; default to Conventional Commits (`type(scope): subject`) when
none is stated. Then fork on the Step 1.7 verdict.

**On a fresh run,** in this order:

1. Create the dedicated branch off the base resolved in Step 1.6. If the branch
   already exists, switch to it.
2. Create the driver's artifact directory and make it self-ignoring: create
   `.implement-work-items/` and write its `.gitignore` as two lines — `*` then
   `!progress.md` — so `progress.md` is tracked while `state.json` and the review
   records stay ignored.
3. Write the **opening entry** to `.implement-work-items/progress.md`: the run's
   effective configuration (gate threshold, fix-loop cap, build/fix model, branch,
   verification configuration) and the work-items file's normalized
   repo-root-relative path. Commit it together with any uncommitted planning
   artifacts (1.4) as one commit, staged explicitly by path, following the detected
   convention and carrying the trailer `Implement-Work-Items-Run: <normalized path>`.
4. Initialize the **work-state file** `.implement-work-items/state.json`. For each
   item `N`, save its state and `fix-round` counter:
   `{"W-1": {"state": "pending", "fix-round": 0, "scope-baseline": null, "decision": null, "commit-range": null}, ...}`.
   If jq is available, you can use it to query or modify this file without full re-read:
   `cp -f state.json state.json.bak && jq '."W-1".state = "build"' state.json.bak > state.json`.
5. Use `TaskCreate` to set up a task for each work item (visual help for user).
   Use template: `W-X of Y: title`.

**On a resume,** switch to the existing run branch. Do not branch off the base,
commit planning artifacts, or write an opening entry: the run's branch and record
already exist.

## Step 3: Per-Item Loop

Process items one at a time in run order. For each item, run the following loop:

### 3.1 Prepare

Read next item from work-items. Use `TaskUpdate` tool to set item's task status
to `in_progress`. Assert a clean working tree (only `.implement-work-items/`
allowed); a prior no-output item's stray files halt here. Save current commit
`git log HEAD -n1 --format='format:%H'` as item's `"scope-baseline"`.

### 3.2 Decide

If `Requires pre-work decisions` is `yes`, pause before any build, present what the
item says must be decided to the user. When user gives back the decision, save it
to `state.json` and proceed. This runs once per item; skip it on a fix round.

### 3.3 Build, verify, review loop

**1. Build.** Set item's state in `state.json` to `"build"`, then route by the item's
build marker:

- **AFK build.** Dispatch a build sub-agent through `Agent` with the resolved
  `--model`: when the item's implementation is a skill, dispatch `general-purpose`
  and instruct it to run that skill on this item; when it names an agent, dispatch
  that agent directly. Have it build against the item's `References` and the
  committed spec or plan, and not commit. For a `spike` or a no-output `audit`,
  give it the item's `Expected paths` as the output target: a `spike` writes its
  finding there, and a no-output `audit` is told an empty file set is the
  expected result. If work item required decisions, pass
  resolution to the builder. On a fix round, also give it the previous iteration's
  residual findings. Copy the
  [build-report contract](./references/build-report-contract.md) verbatim;
  parse the return fail-closed and apply the Halt Procedure on its halt conditions.
- **HITL or `none` build.** Hand off to the user per
  [foreground-handoff-protocol.md](./references/foreground-handoff-protocol.md).
  After interactive part finishes, re-ground and go to step **2. Verify**.

**2. Verify.** Set item's state in `state.json` to `"verify"`, then verify
builder's work: run the project's verification commands one at a time,
distinguishing a command that **reports failures** from one that
**fails to execute**.

On red tests, go to step **4. Gate**. On test command failure, halt and inform
the user of what went wrong.

In scope-check-only mode there are no commands to run; skip this step and go to
**3. Review**.

**3. Review.** Set item's state in `state.json` to `"review"`, then route
by the item's review marker:

- **AFK review.** Dispatch a review sub-agent: when the item's review is a skill
  (for example `han-coding:code-review`), dispatch `general-purpose` and instruct it
  to run that skill; when it names an agent (for example `han-core:content-auditor`
  or `han-core:information-architect`), dispatch that agent directly. Have it review
  the item's implementation and scope.
  Give it the reference material, the scope-baseline commit hash, and the item's
  expected paths, and copy the
  [review-verdict contract](./references/review-verdict-contract.md) verbatim; it
  computes the diff and judges scope itself.
  Direct it to return only the normalized verdict and persist the record at
  `.implement-work-items/reviews/<W-N>-iter<fix-round>.md`. Parse fail-closed;
  an untrustworthy verdict halts. The user may opt into a pause per
  [human-review-capture.md](./references/human-review-capture.md).
- **HITL or `none` review.** Capture the user's read into the same verdict per
  [human-review-capture.md](./references/human-review-capture.md).
  After interactive part finishes, re-ground and go to step **4. Gate**.

**4. Gate.** The item clears when verification passed and the verdict reports no finding
at or above the threshold (scope findings included). In scope-check-only mode,
verification counts as passed. A failed verification blocks the gate on its own, no
verdict required.

- **Cleared:** Set item's state in `state.json` to `"commit"`, then leave the inner loop
  and go to Commit (3.4).
- **Needs a human decision:** when the review verdict escalates an issue a fix round
  cannot resolve (the scope or approach must change for the feature to work or be
  secure, an unforeseen architectural problem, or an unresolvable RAID item), halt
  through the Halt Procedure instead of looping.
- **Not cleared:** bump the `fix-round` counter in `state.json`. If `fix-round` now
  exceeds `--fix-cap`, halt. Otherwise set its state to `"build"` and go to step
  **1. Build**, passing review findings or verification failure message to the builder.

### 3.4 Commit

For a no-output `audit` (`Expected paths: None`), do not commit: record it per
[no-output-completion.md](./references/no-output-completion.md) (assert a clean tree,
set `done-no-commit`, label the summary), then skip to the next item.
Otherwise commit the item as one clean commit following the detected convention, staging by
path the files changed since `scope-baseline` (never `git add -A`), never the driver's
artifacts. Review cleared these as in scope and the tree was clean at item start, so
nothing out-of-scope is left behind for the next item. When a foreground build already
committed part or all of the item's work, keep those commits and commit only the
uncommitted remainder, per
[foreground-handoff-protocol.md](./references/foreground-handoff-protocol.md).

If a pre-commit hook fails the commit, look at what it reported:

- **Trivial and auto-fixable** — a formatter or auto-fixing linter rewrote files, or
  the fix is a one-liner the orchestrator can make directly: apply it (re-stage the
  hook's own edits, or run the project's formatter), then retry the commit once. If it
  passes, continue.
- **Anything else, or the retry still fails** — treat it as a gate not cleared: bump
  the `fix-round` counter in `state.json`; if `fix-round` now exceeds `--fix-cap`, halt;
  otherwise set its state to `"build"` and return to step **1. Build**, passing the
  hook's output to the builder.

After a successful commit, set item's state in `state.json` to `"done"`.

## Step 4: Completion Summary

When every item is complete, report the completion summary: the branch name,
each item's execution mode and outcome (built and committed with its commit reference
or range; a no-output `audit` recorded `done-no-commit`, named with its `Type`
and a count per [no-output-completion.md](./references/no-output-completion.md); or the
item that halted the run and why), the items not reached,
and the next action for the user (review and push the branch;
sharing the branch stays with the user).

## Halt Procedure

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
   record at `.implement-work-items/reviews/<W-N>-iter<fix-round>.md`.
5. **What to do next.** The run does not resume, so a re-invocation starts a
   fresh run from the first item. Name a resolution suited to the halt kind
   (amend the spec, fix the item, or build it by hand); state that a fresh
   re-invocation must be on a clean tree and a branch that does not already
   carry this run's commits (so the user commits or stashes the halting
   item's work and starts a fresh branch, or cherry-picks the completed items
   forward by hand); and name the branch and the commit range of the completed
   items so the user can reference them (a no-output `audit` recorded
   `done-no-commit` carries no commit and is not in that range; see
   [no-output-completion.md](./references/no-output-completion.md)).
