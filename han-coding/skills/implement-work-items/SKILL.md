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

Resolve the base the run will branch from. Never default to the current HEAD:
the skill may be invoked from arbitrary git state.

Run `git fetch --all` and note whether it completed; a failed or partial fetch
means the ahead/behind counts may be stale. Set `IWI_FETCH_STATUS` to `ok` or
`failed` accordingly, then re-run the detector and read its `candidate:` and
`fetch-status:` lines so the counts reflect the post-fetch refs (the Step 1.3 run
predates the fetch).

Pick the default base from the first `candidate:` line that resolves, in this
order of freshness: a local `main` or `master`; then `origin`/`upstream`
`main`/`master`. Each `candidate:` line reports that ref's `behind:` and `ahead:`
counts against the current branch.

The recommend-and-confirm below is a **fresh-run** interaction; 1.7 classifies the
invocation using this default base as its scan target. On a **resume**, the base
is read from the recorded opening (Step 2.3), so skip this interaction. On a
**fresh** run, key off the default base's counts:

- **Current branch ahead** (`ahead` > 0, `behind` = 0): the base is missing commits
  the current branch already carries. Surface the current branch as an alternative
  base with both candidates' ahead/behind counts, **recommend** branching from the
  current branch, and **confirm** before proceeding.
- **Diverged** (`ahead` > 0 and `behind` > 0), or the **fetch did not complete**:
  present the counts, note stale counts when the fetch failed, and ask which base to
  use **without a recommendation**.
- **Detached HEAD** (no current branch) or **no base resolves**: ask which base to
  branch from.
- **Not ahead** (`ahead` = 0, whether in sync or behind): the current branch adds
  nothing the base lacks, so resolve the default base with no prompt.

### 1.7 Classify the invocation

With the work-items path (1.2) and the base (1.6) resolved, classify this
invocation. Run
`${CLAUDE_SKILL_DIR}/scripts/scan-run-history.sh <work-items-path> <base-ref>`,
passing the resolved work-items path repo-root-relative and the base from 1.6,
and read its `classification:` line. Branch on it:

- **fresh** — the branch carries no prior run commits; drive it as a fresh run.
- **resume** — the branch carries this run's progress record. Run the
  [re-grounding routine](./references/re-grounding-routine.md) to reconstruct the
  run state.
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

Fork on the Step 1.7 verdict: a **fresh** run does 2.1 then 2.2; a **resume**
does 2.3.

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
none is stated. Then, in this order:

1. Create the dedicated branch off the base resolved in Step 1.6. If the branch
   already exists, switch to it.
2. Create the run-artifact area inside the plan folder: `<plan-folder>/.implement-work-items/`,
   where `<plan-folder>` is the directory holding the work-items file. The whole area is
   tracked and travels with the branch.
3. Write the **opening entry** with `${CLAUDE_SKILL_DIR}/scripts/write-run-record.sh init
   <record> <gate> <fix-cap> <model> <base> <branch> <verify> <work-items>` and commit it per
   [durable-record-protocol.md](./references/durable-record-protocol.md), where `<record>` is
   `<plan-folder>/.implement-work-items/progress.md`. Co-commit it with any uncommitted planning
   artifacts (1.4) as one commit, so a failed opening leaves an empty fresh branch.
4. Use `TaskCreate` to set up a task for each work item (visual help for user).
   Use template: `W-X of Y: title`.

### 2.3 Resume

The re-grounding routine (Step 1.7) has reconstructed which items are done, in
progress, or skipped and re-derived the dependency graph; work from that. Switch to
the run branch — do not branch off the base, commit planning artifacts, or write an
opening entry, since the branch and record already exist.

Sync the task list to the reconstructed state: create a task per work item with
`TaskCreate` and set each with `TaskUpdate` — done and skipped completed, the
in-progress item in progress, the rest pending.

Show the **resume summary**: the items done, the ones completed without a commit, the
skipped ones, any in-progress item, the items remaining, and the restored run
configuration and branch. Then **announce the concrete next action** — the specific
next item, the phase it resumes at, and the disposition of any in-progress item — and
**wait for the operator's go-ahead before the first build, discard, or durable
write.** If the operator edited the tree before re-invoking, route to
[Re-attempting after a fix](#re-attempting-after-a-fix).

On the go-ahead, proceed from the first item that is neither done, skipped, nor
blocked by a skipped dependency, and enter the Step 3 loop there. Done and skipped
items are not rebuilt. A record in which every item is done — committed or completed
without a commit — is an already-complete run: report it and start nothing.

Before continuing past a clean between-items point, re-establish the verification
baseline by re-running the resolved verification commands. A baseline that is now red — a
done item regressed from between-session drift — is a distinct condition, not a floor to
adopt: name the failing tests, note they were green when the done items committed, and
offer a stop-or-abort choice.

#### Resuming an in-progress item

An item may carry a start-of-item entry with no terminal entry. Classify it by kind,
foreground first, completing this inspection and any discard before re-establishing the
baseline so leftover partial work cannot redden it:

- **Foreground or HITL item.** Re-verify and re-review before any forward-reconcile.
  Surface its commits and its uncommitted diff since the start-of-item entry as
  recognition support, then offer to re-drive it or — if the operator confirms the shown
  work is complete — resume at Step 3.3 **2. Verify**. Never discard its hand-built work.
- **No-output `audit`.** Re-run the audit (constrained to side-effect-free checks) and
  re-ask the operator to confirm, then record it done through Step 3.4 (the no-commit-done
  outcome). Never forward-reconcile it from a clean tree: a clean tree does not prove the
  confirmation happened.
- **Output (AFK) item.** A start-of-item entry with no `done` entry is not done, whatever
  committed iterations or a clean tree suggest: re-verify its latest committed iteration and
  re-review it, re-entering the loop at Step 3.3 **2. Verify**, then gate — record it done on
  a clear, else continue the fix loop. If nothing landed since the start-of-item entry,
  rebuild from it. If a commit in the start-of-item-to-HEAD range reaches beyond the item's
  scope (foreign, or a foreground pre-gate commit), surface-and-ask.
- Any state not positively classified as safe → surface-and-ask.

#### Ledger and history disagree

When the durable record and the current state disagree, or a state cannot be positively
classified as safe, default-deny: never proceed on a guessed base or report done an item
whose commit is gone. Surface the specific divergence with a one-line plain-language cause
(the unmatched entries and why — the integrity table in
[durable-record-protocol.md](./references/durable-record-protocol.md) classifies each),
and offer one uniform, consequence-labeled option set with the safe option marked:

- **Abort to reconcile** (safe) — stop so the operator reconciles by hand.
- **Restart the run** — supersedes the prior record, so a later resume reads only the new run.
- **Proceed from the first unmatched item** — offered only where the driver can show it is
  safe; withheld, surfacing-and-asking instead, when the resumption point would fall before
  a dependency or the record is internally inconsistent.

## Step 3: Per-Item Loop

Process items one at a time in run order. For each item, run the following loop:

### 3.1 Prepare

Read next item from work-items. Use `TaskUpdate` tool to set item's task status
to `in_progress`. Assert a clean working tree, allowing only paths with a
`.implement-work-items/` segment at any depth; a prior no-output item's stray files
halt here.

Before any build, add a **start-of-item entry** with
`${CLAUDE_SKILL_DIR}/scripts/write-run-record.sh log <record> start-of-item <W-N>` and commit
`progress.md` per [durable-record-protocol.md](./references/durable-record-protocol.md). That
commit is the item's changed-file-set baseline, carrying the item's baseline trailer; recover
the item's `scope-baseline` from it. A rejected bookkeeping commit is a marker-write failure —
see 3.4.

### 3.2 Decide

If `Requires pre-work decisions` is `yes`, pause before any build, present what the
item says must be decided to the user. When user gives back the decision, hold it in
the running session and proceed. This runs once per item; skip it on a fix round.

### 3.3 Build, verify, review loop

Per-item loop state — the loop phase and the fix-round counter — lives in the
running session. Every build and fix iteration is committed; the driver never
dispatches onto a dirty tree.

**1. Build.** Route by the item's build marker.

- **AFK build.** Dispatch a build sub-agent through `Agent` with the resolved
  `--model`: when the item's implementation is a skill, dispatch `general-purpose`
  and instruct it to run that skill on this item; when it names an agent, dispatch
  that agent directly. Construct the prompt by copying the **Shared baseline** plus
  the **Build payload** from
  [sub-agent-instructions.md](./references/sub-agent-instructions.md) verbatim,
  substituting the run-scoped values (the item's implementation skill, the
  accumulated corrections, and on a fix round the residual findings), and copy the
  [build-report contract](./references/build-report-contract.md) verbatim. The
  sub-agent does not commit. Parse the return fail-closed; apply the Halt Procedure
  on its halt conditions.
- **HITL or `none` build.** Hand off per
  [foreground-handoff-protocol.md](./references/foreground-handoff-protocol.md).

After the build (or the foreground edits) return, **commit the iteration**: stage
by path since `scope-baseline` (never `git add -A`, never a `.implement-work-items/`
path at any depth), carrying `Implement-Work-Items-Item: <W-N>` on the item's
initial build commit and `Implement-Work-Items-Fixup: <W-N>` on a fix-round commit,
per [durable-record-protocol.md](./references/durable-record-protocol.md). A no-output
`audit` changes no files and has no iteration to commit.

**2. Verify.** Verify the committed iteration by running the project's verification
commands one at a time, distinguishing a command that **reports failures** from one
that **fails to execute**.

On red tests, go to step **4. Gate**. On command failure, halt and inform the user
of what went wrong. In scope-check-only mode there are no commands to run; skip this
step and go to **3. Review**.

**3. Review.** Route by the item's review marker.

- **AFK review.** Dispatch a review sub-agent: when the item's review is a skill
  (for example `han-coding:code-review`), dispatch `general-purpose` and instruct it
  to run that skill; when it names an agent (for example `han-core:content-auditor`
  or `han-core:information-architect`), dispatch that agent directly. Construct the
  prompt by copying the **Shared baseline** plus the **Review payload** from
  [sub-agent-instructions.md](./references/sub-agent-instructions.md) verbatim,
  substituting the run-scoped values (the item's review skill, `scope-baseline`, the
  expected paths, the already-approved coherence paths, and on a fix round the prior
  committed iteration), and copy the
  [review-verdict contract](./references/review-verdict-contract.md) verbatim. Direct
  it to persist the record at `.implement-work-items/reviews/<W-N>-iter<fix-round>.md`
  and return only the normalized verdict; parse fail-closed, and an untrustworthy
  verdict halts. The user may opt into a pause per
  [human-review-capture.md](./references/human-review-capture.md).
- **HITL or `none` review.** Capture the user's read into the same verdict per
  [human-review-capture.md](./references/human-review-capture.md).

**4. Gate.** The item clears when verification passed and the verdict reports no
finding at or above the threshold (scope findings included). In scope-check-only
mode, verification counts as passed. A failed verification blocks the gate on its
own, no verdict required.

- **Cleared:** leave the inner loop and go to **Record the item done** (3.4).
- **Needs a human decision:** when the review verdict escalates an issue a fix round
  cannot resolve (the scope or approach must change for the feature to work or be
  secure, an unforeseen architectural problem, or an unresolvable RAID item), halt
  through the Halt Procedure instead of looping.
- **Not cleared:** bump the session fix-round counter. If it now exceeds `--fix-cap`,
  halt. Otherwise go to step **1. Build** for a fix round, passing the review
  findings or the verification-failure message to the builder.

### 3.4 Record the item done

The item's code is already committed as its iterations, so there is no separate clean
commit. When an item clears its gate, record it done in this order:

1. **Terminal entry.** Add the `done` entry (or, for a no-output `audit`, the
   `no-commit-done` entry per
   [no-output-completion.md](./references/no-output-completion.md)) with
   `${CLAUDE_SKILL_DIR}/scripts/write-run-record.sh log <record> <done|no-commit-done> <W-N>`
   and commit `progress.md` per
   [durable-record-protocol.md](./references/durable-record-protocol.md). This
   bookkeeping commit is the last write per item, after the item's code commits.
2. **Mark done.** Update the session state and the task (`TaskUpdate`).

**Commit-failure rules.** Keep these two commit-failure classes distinct:

- A rejected **AFK code-iteration** commit (a hook rejecting an AFK build or fix
  output) is a gate not cleared: re-stage the formatter's own edits and retry the commit
  once; on anything else, or a still-failing retry, treat it as not-cleared and return
  to the Build step (3.3) as a fix round, passing the hook's output to the builder,
  halting once the fix-round counter exceeds `--fix-cap`.
- A rejected **bookkeeping** commit (the terminal entry), or a rejected commit of a
  **foreground or `none` build's** iteration (the operator's own hand-edits), is a
  marker-write / resumable stop: surface it through the Halt Procedure so the operator
  addresses it, never the fix loop. Distinguish a clean-tree no-op from a hook rejection
  via `git status --porcelain`.

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
   item that remain in the working tree; that the items completed before the halt
   stay committed on the branch; and any no-output audits completed without a
   commit, named separately rather than folded into the committed set.
4. **Supporting evidence.** Which sub-agent or check raised it, the relevant
   spec or acceptance criteria, and the raw verification output or the residual
   findings. When the halt is review-gated, add a pointer to the durable review
   record at `.implement-work-items/reviews/<W-N>-iter<fix-round>.md`.
5. **What to do next — the recovery menu.** Present the options below, filtered to
   what the halting state allows, each option's consequence stated on its label:
   - **Fix in place, then re-attempt** — the operator addresses the issue and the
     driver re-attempts the item; see [Re-attempting after a fix](#re-attempting-after-a-fix).
   - **Run more automated fix rounds** — a stated number of further rounds, re-entering
     the fix loop (Step 3.3 **1. Build**) with no hand edits; offered only when the halt
     was fix-cap-exceeded; within-session, so it does not survive a stop. Halts again if
     the gate does not clear.
   - **Skip this item, continue** — name the dependents the skip will strand before the
     operator commits to it; on skip, return the working tree to the last clean committed
     baseline (inspect and confirm before discarding, never discarding an interactive
     item's hand-built work), add a skip entry and commit `progress.md` per
     [durable-record-protocol.md](./references/durable-record-protocol.md), and continue
     to the next item whose dependencies are met.
   - **Stop the run (resumable)** — always present; all completed work is preserved
     (output items committed; any no-output audits recorded without a commit, named
     separately, per [no-output-completion.md](./references/no-output-completion.md)),
     and the run resumes on a later invocation on the same file.

   A rejected bookkeeping commit is a **marker-write failure**: surface it as its own
   class, distinct from a code-commit failure (which routes through the fix loop, Step
   3.4), and stop resumably — only **Stop the run** applies.

### Re-attempting after a fix

Show what changed since the item's start-of-item entry — the working tree, and the
item's text if the item itself was edited — then offer two non-destructive paths, each
labeled with what it does to the operator's edits:

- **Re-check as-is** — re-verify and re-review the current tree with no build. Covers a
  hand-edited code fix and an environment, dependency, or flake fix. Never rebuilds away
  the operator's edits.
- **Build further** — dispatch a build sub-agent that continues from the current tree
  (never resetting the operator's edits), with the changed item and the residual findings
  as context, then verify and review.

A manual fix does not consume an automated fix-round. On clear, record the item done
(Step 3.4) — or the no-commit-done outcome for a no-output `audit`; if it does not clear,
return to the recovery menu.
