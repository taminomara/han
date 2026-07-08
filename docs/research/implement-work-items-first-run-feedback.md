# implement-work-items: first end-to-end run feedback

Feedback from the first full end-to-end run of the `implement-work-items` driver. The
run drove a 10-item `work-items.md` that built the resume, halt-recovery, and
re-grounding feature into the `implement-work-items` skill itself (so the run was also a
dogfood of the driver editing its own definition). Verification ran in scope-check-only
mode (the repo defines no test suite). All 10 items built, reviewed, and committed;
none halted, none went unreached.

This first section is the driver's (Claude's) retrospective. The operator will add their
own feedback below.

## What worked

- **The plan-work-items breakdown was solid.** Ten items, a correct dependency graph, and
  correct marker classification: `general-purpose`/`none`-HITL for skill-markdown edits,
  `tdd`/`code-review` for the one shell script, `project-documentation`/`content-auditor`
  for the operator doc. The shared-file linearization (W-4 through W-7 all editing
  `SKILL.md`, chained in order) was right and never produced a conflict.
- **The HITL review gate earned its keep.** Every human review caught something real: the
  planning-decision-ID citation leak (W-1), the undefined ledger format plus the unlinked
  protocol (W-6), and the scattered resume routing (W-7). The AFK reviews did too: W-2's
  `code-review` found a real git argument-injection, and W-10's `content-auditor` verified
  181 facts survived the doc rewrite. The gate does real work.
- **Per-item commit discipline produced a clean, revertable history.** Eleven commits, a
  clean tree at every item boundary, the scope check catching drift, one commit per item
  staged by path. The build-report and review-verdict fail-closed contracts held; no
  untrustworthy report slipped through.
- **The opt-in "pause after review" on an unattended item (W-2) worked as designed.**

## What failed or was awkward

- **Startup nearly derailed on a realistic dev state.** The clean-tree gate would have
  halted on the uncommitted planning artifacts, and base resolution would have branched
  off `origin/main`, which was 78 commits behind and missing the very skill the plan
  edits. The "never default to HEAD, prefer origin/main" rule produced a wrong base and
  forced an escalation before item 1. The driver assumes `main` is the right base and the
  tree is clean apart from planning artifacts; both are false on an active feature branch.
- **The fix-cap fought the operator.** W-3 hit fix-round 3 (the cap), and W-6 and W-7 went
  several rounds, all operator-directed refinement rather than automated churn. Under the
  current driver every not-cleared review burns a cap slot, so a thorough reviewer forces
  a halt mid-collaboration. This is a live validation of the feature being built: D7 ("a
  manual fix does not consume an automated fix-round") exists for exactly this.
- **The decomposition split a single contract across three items.** The ledger format was
  defined nowhere (W-1), invented by the scanner (W-2), and retrofitted into the writer
  (W-6), and only operator review caught the drift. One file per item is clean for
  isolation but wrong for a cross-cutting contract; the format should have been pinned
  concretely in the foundation item with its consumers sequenced to conform.
- **Fixes legitimately needed to touch sibling files, and the scope model resisted it.**
  W-6's fix spilled into `durable-record-protocol.md` and `re-grounding-routine.md` (both
  other items' already-committed files) for coherence the operator asked for. The per-item
  Expected-paths scope check treats that as a finding, not a feature. The natural work
  boundary here is a coherence unit, not a file.
- **Sub-agents mis-coordinated on uncommitted state.** W-7 restructure agent silently
  reverted an uncommitted `re-grounding-routine.md` fix by "restoring it to committed
  state." Build sub-agents act on the working tree but do not know which uncommitted
  changes belong to the orchestrator's in-flight work.
- **Style drift repeated on every item until it was hard-coded into the briefs.** The
  operator corrected the same class repeatedly: meta-commentary ("whose responsibility"),
  backward-references ("unchanged", "as today", "authored later"), planning-decision-ID
  citations, and dangling references. The driver has no memory to accumulate operator
  preferences across items, so each was threaded into the next brief by hand. An
  autonomous run would re-make the same mistakes on every item.
- **The bookkeeping is all manual prose.** `state.json` was maintained by hand via `jq`,
  every review record was hand-written, and each commit and its trailers were hand-built.
  A finalization turn did not complete cleanly and needed a retry. This is precisely the
  deterministic work the hardening rule says to script.

## What to improve

1. **Base resolution.** Detect when `origin/main` lacks commits the plan depends on, or
   when the current branch is far ahead, and offer the current branch rather than blindly
   preferring `origin/main`.
2. **Clean-tree gate.** Treat the whole plan folder (including `artifacts/`) as allowed, or
   have `plan-work-items` link it, so the driver does not halt on the operator's own
   just-produced planning outputs.
3. **Fix-cap.** Do not count operator-directed manual fixes against the automated cap
   (ship D7).
4. **Contracts.** Make the foundation item define shared contracts concretely, and flag
   consumers; do not let a format live only in its reader.
5. **Scope.** Allow operator-approved coherence spillover into sibling files without a
   scope finding, or decompose by coherence unit instead of by file.
6. **Sub-agents.** Pass them the set of uncommitted paths that belong to the orchestrator
   and must be preserved.
7. **Preference memory.** Accumulate review corrections and auto-inject them into every
   subsequent build brief.
8. **Script the bookkeeping.** State transitions, scope-baseline capture, and
   review-record scaffolding.

## The meta-point

This run is a strong argument for the feature it produced. The worst friction (no resume
across a very long session, the fix-cap halting operator refinement, and the dead-end
halt rather than a recovery menu) are the exact problems the resume, recovery, and
re-grounding work addresses. Dogfooding it surfaced its own justification.

## Operator feedback

- .implement-work-items should be a sub-directory within implementation plan folder
- need file for impl/review sub-agents with common instructions so driver doesn't have to restate them
- comments below threshold can be fixed as well, if they genuinely matter. when dispatching fix,
  fixing them is ok; when gate green, orchestrator can manually fix or reject some of them. no items below
  threshold means "don't run another review after minor things are addressed", not "never address anything
  below threshold". orchestrator can apply its own judgement on what to fix.
- git diff can't show changes for untracked file -- decide what to do, e.g. commit each iteration durably
  or ignore. iteration history can be valuable for fix/review agents
- subagents didn't use skill guidance, plan-work-items doesn't emit a clear instruction to use it

## Harness bug: nested sub-agents cannot wait or be stopped

This run prompted a separate investigation into the Claude Code harness, because the
driver's dispatch model (an orchestrator that dispatches build and review sub-agents, with
the review step fanning out to several reviewer agents) sits directly on top of two harness
defects in nested-agent handling. Both were reproduced deterministically on Linux, Claude
Code v2.1.195, and are independently confirmed on macOS v2.1.201 in the upstream tracker.

### What we hit

Two distinct failures whenever a sub-agent spawns its own sub-agent (a sub-sub-agent from
the top-level session's view):

- **A sub-agent cannot wait for a child.** When a sub-agent ends a turn with a background
  child still running, the harness reports the sub-agent as `completed` to its parent and
  never resumes it. The child's completion notification is delivered to the top-level
  session instead of to the sub-agent that spawned it, so the sub-agent's real result is
  lost and the parent receives the sub-agent's pre-yield message as if it were final. A
  sub-agent also has no `TaskGet`/`TaskOutput`/`TaskList` tool to fetch a child's output,
  and a bare foreground `sleep` used as a wait is blocked, so the model improvises
  background `until test -f artifact; do sleep 2; done` poll loops to watch for a child's
  file. Reproduced with a background child agent and, minimally, with a plain background
  Bash command and no nesting at all.
- **A sub-agent cannot stop a child it spawned.** `TaskStop` on the child fails with an
  ownership error, verbatim `Task <child> is owned by <child>; agent <parent> cannot stop
  it`, and the child runs to completion regardless. Reproduced on the first, direct stop
  call, with no `SendMessage` resume involved.

### Root cause

Background tasks spawned by a sub-agent are owned by the top-level session, not by the
sub-agent. A sub-agent has no suspend/resume loop, so ending a turn is treated as terminal
completion, and the ownership guard blocks it from stopping work it started. The top-level
session's own wait, stop, and notification paths all work correctly; only nested
(sub-agent-spawned) agents are broken.

### Upstream tracking

Already reported, do not file new issues. The canonical open issue covering both is
anthropics/claude-code#75043 (labelled `bug`, `has repro`, `area:agents`). Related open:
#69824, #69212, #68997 (wait and notification routing) and #73916, #74423 (stop and
orphaned tasks). The stop lineage traces back to #17764 and #23154, both closed without a
fix. A corroborating comment carrying the Linux/2.1.195 confirmation and the no-resume
`TaskStop` finding is drafted for #75043.

### Fixes for the driver

The wait bug is fixable at the prompt level; the stop bug is not, but its blast radius can
be contained. Concretely for `implement-work-items`:

1. **Keep dispatch flat.** The driver runs at the top level, where await, stop, and
   notifications all work. Dispatch build and review agents directly from the driver, and
   spawn the review fan-out from the top-level driver rather than from inside a build or
   review sub-agent. Flat dispatch sidesteps both bugs entirely and is the cheapest fix.
2. **If a dispatched agent must spawn its own children, supply the plumbing.** The child
   writes its result atomically to an agreed absolute path (`... > out.tmp && mv out.tmp
   out`); the parent, in the same turn, blocks on a bounded foreground loop
   (`for i in $(seq 1 60); do [ -f out ] && break; sleep 3; done; cat out`), then reads the
   file. Never end a turn waiting for a child, and never rely on a completion notification
   reaching the parent. This pattern was validated: a sub-agent awaited a ~35s background
   child in a single turn and retrieved the correct result, and the foreground poll loop
   was not blocked.
3. **Bound every dispatched agent so orphans self-terminate.** Since a hung child cannot be
   stopped, wrap long or risky work in `timeout`, cap loops with a max iteration count, and
   give the driver a cooperative kill file (the child polls for an abort sentinel and exits)
   when early cancellation matters. Otherwise an orphaned agent keeps consuming tokens until
   it finishes on its own.

### Residual risks

Even with the workaround, orphaned children burn tokens until they self-terminate, the
top-level session receives stray completion notifications for grandchildren it never
spawned, and deeper nesting compounds both and risks recursive fan-out. Prefer flat
orchestration until the harness is fixed.
