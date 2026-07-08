# Decision Log: implement-work-items First-Run Hardening

This file records every decision settled while specifying the first-run hardening bundle. Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the history, rationale, evidence, and rejected alternatives for each decision. The source of most evidence is the operator's first-run feedback document (`docs/implement-work-items-first-run-feedback.md`, a provided source) and the current skill definition (`han-coding/skills/implement-work-items/`, a codebase source). This feature has no `feature-technical-notes.md`: the one load-bearing mechanic (the harness nested-agent limitation) went with the flat-dispatch item that was scoped out to a separate feature, so no `T#` is cited anywhere.

## Full decisions

### D1: Scope is implement-work-items only

- **Question:** The first-run feedback spans ~13 improvement threads, two of which (concretely pinning shared contracts, and emitting a follow-the-skill-guidance instruction) are really changes to the work-items planning skill. Does this spec cover both skills or only the driver?
- **Decision:** Scope this spec to implement-work-items only. The two planning-skill threads are captured as an inbound coordination and deferred; the implement-work-items side of the guidance thread (its own sub-agents get the follow-the-guidance directive) stays in scope.
- **Rationale:** Keeping the spec to one skill keeps it coherent and shippable, and avoids coupling two skills' evolution in one plan.
- **Evidence:** user input (interview Q1).
- **Rejected alternatives:**
  - One combined spec covering both skills — rejected because it couples the driver's and the planner's evolution and widens the blast radius of a single plan.
  - A tight startup+fix-loop-only subset — rejected because the operator wanted the full driver-side bundle.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D11 (the in-scope guidance directive); the Deferred entries for the two planning-skill threads.
- **Referenced in spec:** Coordinations, Out of Scope, Deferred (YAGNI).

### D2: Base resolution when the current branch is ahead

- **Question:** The first run branched off the default remote base, which was far behind and missing the very skill the plan edits. How should the driver pick the base?
- **Decision:** On a fresh run, when the current branch is ahead of the resolved default base (the base is missing commits the current branch carries), the driver surfaces the current branch as an alternative base, shows the ahead/behind counts, recommends branching from the current branch, and asks the operator to confirm. On a resume, the base is read from the run's recorded opening and is not re-resolved or re-confirmed. When the branch has diverged (both ahead and behind), the driver shows the ahead/behind counts for both candidates and asks without computing a recommendation. When the fetch fails or is partial, it marks the counts as possibly stale and asks. When there is no current branch (detached state) or no base resolves, it falls back to asking. When the branch is in sync with the base, behavior is unchanged.
- **Rationale:** The wrong-base failure is expensive, but silently auto-picking a base removes operator control at a high-stakes moment. The real first-run failure was a base missing a *dependency* (a commit the branch already carried), which the ahead/behind signal detects directly. The recommend-and-confirm is therefore anchored on the ahead-of-base signal, not on the outputs the work items produce. The interactive step is fresh-only because re-resolving on resume would re-prompt on nearly every active-branch resume and could reclassify the run against a different base than the branch was built from.
- **Evidence:** user input (base-resolution interview question); source feedback "What failed or was awkward" (base resolution) and improvement #1; the current base-resolution behavior (Step 1.6, "prefer origin/main, never HEAD") and the base→classify ordering (Step 1.6 before 1.7) that made the resume re-prompt possible; `Expected paths` are parsed at Step 1.5 before base resolution, so output paths are knowable but do not indicate which base holds the dependency.
- **Rejected alternatives:**
  - Auto-prefer the current branch whenever it is ahead — rejected because it selects a base without confirmation at a high-consequence step.
  - Always ask without a recommendation for the ahead case — rejected because it drops the evidence-based recommendation the ahead/behind counts support.
  - A diverged-case recommendation of "the base that contains the paths the work items target" — rejected because output paths are often newly created (absent from both candidates, no signal) or long-lived (present in both), so the heuristic does not detect the dependency-missing failure it was meant to catch; a plain ahead/behind view plus operator choice satisfies the same evidence (F2).
- **Linked technical notes:** —
- **Driven by findings:** F1, F2, F3, F4.
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Edge Cases and Failure Modes, User Interactions.

### D3: Clean-tree allowance covers the plan folder

- **Question:** The clean-tree gate halted on the operator's own just-produced planning outputs. How wide should the allowance be, and what does the run then commit?
- **Decision:** On a fresh run the working tree must be clean before the first item. The run's own just-produced planning outputs — the work-items file and the artifacts it links — are the allowed exception: the driver stages exactly that planning content as its opening commit, and the plan-preview enumerates what that commit will contain. Anything else uncommitted — a stray draft, an unrelated edit, a work item's own already-dirty target file, or a stale run-artifact area from a prior run — the driver offers to commit or stash (or, for a prior run's artifacts, clean) before starting, rather than halting outright or silently folding it in. When the work-items file is not inside a folder with an artifacts subfolder, the driver degrades: it treats the file's own folder as the plan folder rather than refusing.
- **Rationale:** The clean-tree gate exists to stop stray files being folded into the first commit; the first run showed it was too blunt, halting on the operator's own planning outputs. The fix is not to widen toleration to the whole plan folder — that silently absorbs stale cruft, a prior run's leftover artifacts, and a work item's own already-dirty targets — but to keep the tree clean, treat only the run's planning content as the committed exception, and offer commit-or-stash for everything else. The offer is made at startup, where the operator is present.
- **Evidence:** source feedback "What failed or was awkward" (clean-tree gate) and improvement #2; operator feedback #1 (run-artifact area inside the plan folder); the current clean-tree gate (Step 1.8) and opening-commit staging (Step 2.2 step 3), which co-commit only the linked planning artifacts today; the current arbitrary-path input contract (Step 1.2) that does not require a plan folder.
- **Rejected alternatives:**
  - Tolerate the whole plan folder as expected content and decouple that from opening-commit staging — rejected on review: it silently absorbs stale cruft, a prior run's leftover artifacts, and a work item's own already-dirty target files; offering commit-or-stash for anything that is not the run's planning content is simpler and keeps the tree genuinely clean (F22).
  - Refuse a work-items file that is not in a plan-folder-with-artifacts — rejected because the current skill accepts an arbitrary path and hand-authored runs should still work (F9).
- **Linked technical notes:** —
- **Driven by findings:** F5, F6, F7, F8, F9; F22 (iterative review).
- **Dependent decisions:** D4 (run-artifact placement anchors on the same plan folder).
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, Edge Cases and Failure Modes, User Interactions, Coordinations.

### D4: Run artifacts live inside the plan folder

- **Question:** The driver's run-artifact area lived at the repository root, disconnected from the plan it serves. Where should it live?
- **Decision:** The run-artifact area moves from the repository root to inside the plan folder (the folder that holds the work-items file). A fresh run that finds a leftover artifact area from an earlier stopped or aborted run under that folder surfaces it and asks rather than silently adopting or committing it.
- **Rationale:** A root-level artifact area is disconnected from the plan and clutters the repo root; co-locating it with the plan is cleaner and makes the committed run record travel with the plan. The stale-remnant check is needed because D3's whole-folder toleration would otherwise absorb an old run's artifacts.
- **Evidence:** operator feedback #1; the current root-level artifact area and its self-ignoring setup (Step 2.2 step 2).
- **Rejected alternatives:**
  - Keep it at the repository root — rejected as disconnected from the plan and cluttering the root.
- **Linked technical notes:** —
- **Driven by findings:** F8, F9.
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes.

### D5: Operator-directed fixes do not consume the automated fix-cap

- **Question:** A thorough reviewer plus operator-directed refinement burned the automated fix-cap and forced a mid-collaboration halt. Which fix rounds should count against the cap?
- **Decision:** Only fix rounds driven by automated churn spend a slot of the automated fix budget. A round the operator directs by hand does not count, both inside the per-item loop and in the recovery-menu re-attempt path. An item the operator drives entirely by hand (an interactive item) is not gated by the automated cap at all; the operator is steering it. The operator can intervene to steer a fix at any point in the loop, not only after the cap is hit.
- **Rationale:** The cap exists to stop runaway automated churn, not to limit operator collaboration; counting operator-directed rounds makes a thorough reviewer punish the operator, and an automated cap over a hand-driven item is meaningless.
- **Evidence:** source feedback "What failed or was awkward" (the fix-cap fought the operator) and improvement #3; the existing recovery-menu rule that "a manual fix does not consume an automated fix-round" (Halt Procedure, "Re-attempting after a fix"), which this decision extends into the in-loop path; the current loop's auto-re-dispatch with no operator-choice branch (Step 3.3 Gate "Not cleared").
- **Rejected alternatives:**
  - Count every not-cleared round regardless of who drove it (status quo) — rejected because it halts operator refinement mid-collaboration.
  - Raise the default cap instead — rejected because it does not distinguish automated churn from operator collaboration.
- **Linked technical notes:** —
- **Driven by findings:** F18.
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States.

### D6: Below-threshold findings may be addressed by judgement

- **Question:** A green gate currently means the driver stops reviewing. Should findings below the gate threshold ever be fixed, and how is that done safely?
- **Decision:** A green gate means "do not run another review after minor findings are addressed," not "never address anything below threshold." On a green gate the driver may, by its own judgement, address below-threshold findings that genuinely matter or deliberately leave them, and may fold such findings into a fix it is already dispatching. Because the review verdict returns below-threshold findings as counts only, the driver reads the durable review record for their detail before acting. It re-runs available verification before committing any post-gate fix; in scope-check-only mode, where there is no suite, the scope check still runs and a fix the driver judges risky is re-reviewed rather than committed unchecked. Each fix/leave disposition is recorded in the item's committed record at decision time (not only in the terminal summary) and named in the run summary. A below-threshold finding that needs a scope or approach change escalates through the recovery menu.
- **Rationale:** Sub-threshold findings sometimes genuinely matter; a blanket "never touch them" is wrong and a blanket "always re-review to zero" reintroduces churn. But a driver-made edit past the gate with no re-check could commit a new above-threshold defect undetected, most dangerously in scope-check-only mode (the mode the source-feedback run used). Re-verification plus a durable, per-item disposition record makes the judgement safe and auditable and gives OI-1 an implementable default.
- **Evidence:** source feedback, operator feedback #3 (comments below threshold can be fixed if they genuinely matter; orchestrator applies its own judgement); the review-verdict contract's "below threshold: counts only, detail in the durable record"; the current green-gate path (Step 3.3 Gate "Cleared" jumps to record-done) and scope-check-only mode (Step 3.3 skips verification).
- **Rejected alternatives:**
  - Never address anything below threshold — rejected by the operator directly.
  - Always re-review until no findings remain at any severity — rejected because it reintroduces automated churn.
  - Fix below-threshold findings with no re-verification — rejected because it can commit a new above-threshold defect undetected, especially in scope-check-only mode (F14).
- **Linked technical notes:** —
- **Driven by findings:** F14, F15.
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Edge Cases and Failure Modes, User Interactions, Open Items (OI-1).

### D7: Coherence spillover is surfaced for approval, not flagged

- **Question:** A fix legitimately needed to edit already-committed sibling files for coherence, but the per-item scope check treated it as a finding. How should approved spillover work, and stay approved?
- **Decision:** The scope check surfaces edits to already-committed sibling files that are outside the item's own expected paths as a coherence-approval choice rather than a hard finding; an already-committed file the item's own expected paths predicted is ordinary expected work, not spillover. On approval the edits are recorded as intended, threaded to the item's later review rounds so a subsequent review does not re-raise them, and durable across a stop/resume because the approval is committed; they do not block the gate. On rejection they remain a scope finding routed through the normal fix loop.
- **Rationale:** The spillover in the first run was intended coherence surfaced ad hoc; a surface-and-approve model matches how it arises. But because the scope check recomputes the full diff on every review round from a fresh reviewer, an approval that is not persisted would be re-raised each round — a gate that can never clear — and the chained shared-file pattern the feedback validated (several items editing one file in order) would wrongly trigger a coherence prompt unless the item's own expected paths are excluded.
- **Evidence:** user input (coherence-spillover interview question); source feedback "What failed or was awkward" (fixes needed to touch sibling files) and improvement #5; the chained W-4..W-7 shared-file pattern the feedback called correct; the review-verdict contract's per-dispatch full-diff scope computation.
- **Rejected alternatives:**
  - Pre-declare coherence-companion paths up front — rejected as requiring foresight; deferred.
  - Approve once with no persistence across rounds — rejected because the fresh per-round reviewer re-raises the edit, stalling the gate (F13).
- **Linked technical notes:** —
- **Driven by findings:** F13.
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States, Edge Cases and Failure Modes, User Interactions.

### D8: A clean tree at every dispatch removes the preserve-set need

- **Question:** A build sub-agent silently reverted an uncommitted fix by "restoring it to committed state." How should the driver prevent this class of silent data loss?
- **Decision:** The driver commits any in-flight work — its own, a sub-agent's output, or the operator's hand-edits — as an iteration before dispatching the next sub-agent, so the working tree is clean at every dispatch boundary. A sub-agent that restores files to their committed state therefore cannot discard the driver's or operator's work, because that work is already committed. No preserve-set is passed and no post-dispatch revert check is run: the commit cadence (D10) makes both unnecessary. A sub-agent that rewrites already-committed history is a separate, more severe class outside this feature's scope.
- **Rationale:** The first-run incident was a sub-agent discarding uncommitted work by restoring to committed state. Once the driver commits every iteration (D10), there is no uncommitted driver or operator work in the tree when a sub-agent is dispatched, so the incident cannot recur — the clean tree is a structural guarantee, stronger and simpler than a preserve-set instruction plus a post-dispatch check, and it removes the machinery of computing, passing, and verifying a preserve-set on every dispatch.
- **Evidence:** source feedback "What failed or was awkward" (sub-agents mis-coordinated on uncommitted state) and improvement #6; the commit cadence in D10 (every iteration committed) and the operator's note that with the new commit cadence the tree stays clean before every build, review, and fix; the recovery-menu "Build further" path, whose operator hand-edits are committed as an iteration before the dispatch so they too are safe.
- **Rejected alternatives:**
  - Pass a preserve-set and verify it held after each dispatch — rejected on review: with the commit cadence the tree is already clean at dispatch, so the preserve-set would guard an empty window; the structural clean-tree guarantee is simpler and stronger (F23).
  - Have sub-agents infer intent from the diff and self-restore — rejected because that inference produced the original silent revert.
- **Linked technical notes:** —
- **Driven by findings:** F12; F23 (iterative review).
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Edge Cases and Failure Modes.

### D9: Operator corrections accumulate within the run

- **Question:** The operator re-corrected the same style classes on every item because the driver has no memory across items. How far should the accumulated corrections persist, and how do they interact with item-specific instructions?
- **Decision:** General style corrections accumulate in the run's committed record and inject into every subsequent build's baseline instructions this run; they survive a stop and are restored on resume, and are run-scoped (never shared with another run). They are advisory: an item's own explicit instruction wins for that item, and an item-specific one-off correction is not itself accumulated into later builds — only general corrections accumulate. Cross-run persistence and de-duplication are deferred. The criterion by which the driver names a reusable correction class is an open item (OI-2), with the default above.
- **Rationale:** Re-threading the same corrections by hand is the manual toil the run surfaced; within-run accumulation removes it, and because resume exists the memory must be durable. Accumulating item-specific one-offs would over-correct later items, and letting a growing general set outweigh an item's explicit instruction would follow stale advice over the operator's current intent.
- **Evidence:** user input (preference-memory interview question); source feedback "What failed or was awkward" (style drift repeated every item) and improvement #7; the existing resume/re-grounding behavior (Steps 1.7, 2.3) the durability must survive.
- **Rejected alternatives:**
  - Within-session only (lost on stop/resume) — rejected because a resumed run would re-make the corrections.
  - Cross-run / project-global store — rejected as unjustified surface with staleness risk; deferred.
  - Accumulate every correction including item-specific one-offs — rejected because a one-off exception would silently propagate as a general rule (F17).
- **Linked technical notes:** —
- **Driven by findings:** F11, F17.
- **Dependent decisions:** D10 (its durable storage is the committed run record).
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States, Edge Cases and Failure Modes, User Interactions, Open Items (OI-2).

### D10: Every iteration and the bookkeeping are committed

- **Question:** A plain diff cannot show changes to untracked per-iteration records, and the reviewer wanted to diff the actual code to confirm a fix. How should iteration history be retained?
- **Decision:** The driver commits every build and fix iteration of the code, and commits its bookkeeping (the run record, review records, and accumulated preferences) too, keeping code commits and bookkeeping commits separate and never mixed. Each review-addressing fix commit carries a marker that lets the operator later collapse it into the item's initial commit; bookkeeping commits are likewise marked so they are identifiable. All commits are retained by default — the driver never performs an autosquash, strip, or any post-run history rewrite; the markers only enable the operator (or a later tool) to do so. Git history is therefore the durable, diffable, authoritative run record, and a reviewer confirms a fix by comparing the latest committed iteration against the prior one. Because in-flight work is committed before the next dispatch, the working tree is clean at every dispatch boundary, which is what makes a separate preserve-set unnecessary (D8).
- **Rationale:** The operator's real need was diffing code between iterations to confirm a fix, which requires each iteration to be its own commit. Committing everything also makes the durable run store git history itself — durable by construction, diffable, and authoritative on resume — which dissolves the integrity, tracked/ignored-boundary, and write-ordering gaps the review team raised against a separately-maintained store. Keeping code and bookkeeping commits separate preserves clean per-item code history and lets the operator collapse or strip either stream later; the driver not rewriting history keeps the run's own behavior simple and non-destructive.
- **Evidence:** user input (iteration-history interview question and the follow-up redirect: commit each iteration, keep code and bookkeeping commits separate, tag review-addressing commits for optional later fixup, keep all commits, do not modify history after the run); source feedback, operator feedback #4 (diff can't show untracked files; iteration history valuable to fix/review agents); the current run-artifact ignore rule (Step 2.2, tracks only the progress record) that made review records untracked and undiffable.
- **Rejected alternatives:**
  - Keep iteration records ignored and forward only residual findings (status quo) — rejected: undiffable, loses the history the operator valued.
  - Retain records durably but as untracked prose — rejected: does not let a reviewer diff the actual code between iterations.
  - Have the driver autosquash to one clean commit per item at completion — rejected by the operator: modifying git history after the run is out of scope; keep all commits, the marker enables an optional later manual collapse.
  - Strip bookkeeping commits before merge by default — rejected by the operator: keep all commits as an audit trail; the marker enables an optional later strip.
- **Linked technical notes:** —
- **Driven by findings:** F10.
- **Dependent decisions:** D12 (the single committed run record is part of this commit model); D8 (the clean-tree-at-dispatch guarantee follows from committing before each dispatch).
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States, Coordinations, User Interactions.

### D11: Sub-agents receive a role-scoped instruction set

- **Question:** The driver restated common instructions by hand every dispatch, sub-agents did not follow the named skill's guidance, and it was unclear which inputs a build vs a review sub-agent should receive.
- **Decision:** The driver gives every dispatched sub-agent a consistent baseline instruction set plus a role-scoped payload. A build sub-agent receives the baseline, the directive to follow the item's implementation-skill guidance, and the accumulated corrections (D9). A review sub-agent receives the baseline, the directive to follow the item's review-skill guidance, and the paths of already-approved coherence edits so it does not re-raise them; the style corrections are for building, so a reviewer receives them only as context for judging that the build honored them, not as new review criteria. (Neither role receives a preserve-set: the clean tree at every dispatch, D8, removes the need.)
- **Rationale:** A shared baseline removes hand-restatement toil and closes the skipped-guidance gap, but an item names both an implementation skill and a review skill, so a single undifferentiated payload would tell reviewers to follow the wrong skill or apply style corrections as review criteria. A role-scoped payload is what a builder can implement.
- **Evidence:** source feedback, operator feedback #2 (a file of common sub-agent instructions) and #5 (sub-agents didn't use skill guidance); the current distinct build vs review dispatch prompts (Step 3.3) and the read-only review-verdict contract.
- **Rejected alternatives:**
  - Continue restating instructions per dispatch (status quo) — rejected as manual toil that drifts and omits the guidance directive.
  - One undifferentiated shared payload to every sub-agent — rejected because build and review roles need different inputs and different skill guidance (F16).
- **Linked technical notes:** —
- **Driven by findings:** F16; F23 (iterative review, preserve-set removed from the payload).
- **Dependent decisions:** —
- **Referenced in spec:** Actors and Triggers, Primary Flow, Deferred (YAGNI).

### D12: The run record is a single committed file

- **Question:** The run's state transitions, baseline capture, and review-record scaffolding were maintained by hand as prose across a tracked progress file and an ignored state file, and a finalization turn failed and needed a retry. How should the run record be shaped and made reliable?
- **Decision:** The run record collapses from the tracked-progress-plus-ignored-state split into a single file that both records progress and holds the machine state, committed to the branch as bookkeeping (D10). Because state transitions are recorded by committing, the record is deterministic and durable by construction and needs no hand-maintained parallel state file; a genuine bookkeeping-commit failure surfaces as a resumable stop, not a silently corrupted record, and is never routed through the code-fix loop. The specific file shape is left to implementation.
- **Rationale:** Hand-maintained bookkeeping across two files is error-prone and already failed once; collapsing to one committed file makes the record single-sourced and its history the authority, which is exactly the deterministic bookkeeping the skill's own hardening rule calls for. Committing everything (D10) makes this collapse natural: git history supplies the durability the separate ignored state file was providing badly.
- **Evidence:** source feedback "What failed or was awkward" (bookkeeping is all manual prose; a finalization turn did not complete cleanly) and improvement #8; the current split of a tracked `progress.md` and an ignored `state.json` (Step 2.2) and the "state.json is untrusted, rebuild it" resume rule that the single committed record supersedes.
- **Rejected alternatives:**
  - Keep the two-file tracked-progress + ignored-state split (status quo) — rejected: it already failed and needed a manual retry, and it maintains a parallel untrusted state file the committed record makes redundant.
- **Linked technical notes:** —
- **Driven by findings:** F10.
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States, Edge Cases and Failure Modes, Coordinations.
