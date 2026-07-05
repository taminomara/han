# Decision Log: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

This file records every decision settled while specifying the resume, halt-recovery, and re-grounding feature for the work-item driver (`implement-work-items`). Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the history, rationale, evidence, and rejected alternatives. Decisions D1–D13 were settled in the interview; D15–D21 were added or reshaped by the review team (see [team-findings.md](team-findings.md)).

## Trivial decisions

- D14: Output folder — the spec and artifacts are written to `docs/plans/implement-work-items-resume/`, alongside the untouched prior over-scoped attempt at `docs/plans/autonomous-implementation-driver/`. — Referenced in spec: — (process decision, not a spec behavior).

## Full decisions

### D1: Feature scope and reopened deferrals

- **Question:** What is this feature, and how does it relate to the driver's existing deferred scope?
- **Decision:** Add three behaviors to the existing `implement-work-items` driver: (1) cross-session resume of a partially complete run, (2) an in-session recovery menu at a halt so the operator can fix an issue and resume, and (3) one properly-defined, shared re-grounding routine. This reopens two behaviors the driver's own docs list as deliberately deferred — cross-session resume and compaction-survival re-grounding — while narrowing the second to re-invocation-driven re-grounding only ([D4](#d4-re-invocation-only-recovery)).
- **Rationale:** The current skill is a deliberately small slice; its Halt Procedure states "The run does not resume, so a re-invocation starts a fresh run from the first item," and its long-form doc names cross-session resume and compaction-survival re-grounding as deferred. The operator asked for exactly restart plus better halt handling, and to check that re-grounding is defined. Keeping this feature to those three behaviors avoids the over-scope of the prior attempt.
- **Evidence:** `han-coding/skills/implement-work-items/SKILL.md` (Halt Procedure, Step 1.6, re-ground references at lines 209/240); `docs/skills/han-coding/implement-work-items.md` lines 70, 82; user request.
- **Rejected alternatives:**
  - Rebuild the full autonomous driver as the prior attempt did — rejected because the user explicitly called that attempt over-scoped and inconsistent, and the current reconciled skill is the baseline to extend.
  - Add resume without touching the halt — rejected because the user asked for halt handling that lets them fix and resume, which the recovery menu provides.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D2, D4, D5, D9
- **Referenced in spec:** Outcome

### D2: Committed, greppable per-item ledger

- **Question:** How should run progress persist so a later session — or a fresh clone of the branch — can resume it?
- **Decision:** Record run progress durably in the branch history as distinguishable entries — an opening run entry (carrying the run configuration and the work-items file), a start-of-item entry per item, a done entry per completed item referencing its code commit, and a skip entry — recorded separately from the per-item code commits and reconstructed by scanning branch history rather than by storing commit hashes. The start-of-item entry replaces today's in-session scope-baseline reference. Operator-facing copy describes this in plain terms ("the driver's recorded progress in the branch history"); "ledger"/"marker" is internal vocabulary (F23).
- **Rationale:** A committed record travels with the branch, so resume works across sessions and in a fresh clone, unlike today's gitignored `.implement-work-items/state.json`. The operator specified greppable "implementation start"/"implementation end" markers instead of stored hashes, which removes the fragile-hash integrity burden that dominated the prior attempt.
- **Evidence:** User input (state-store decision). Current baseline: `.implement-work-items/state.json` is gitignored (SKILL.md Step 2.2; `docs/skills/han-coding/implement-work-items.md` line 57), so it does not travel and a `git clean` wipes it.
- **Rejected alternatives:**
  - Keep the gitignored `state.json` and just read it back — rejected by the operator because it does not travel to another clone/machine and is wiped by `git clean`.
  - Store commit hashes in a committed state file — rejected in favor of greppable entries so a rebase or reset does not silently invalidate a stored hash, and to avoid the commit-reference-integrity machinery of the prior attempt.
- **Linked technical notes:** T1
- **Driven by findings:** F23
- **Dependent decisions:** D3, D10, D11, D12, D13, D16, D20
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, User Interactions, Coordinations

### D3: Per-item resume granularity

- **Question:** At what granularity does the durable record capture progress, and therefore where does a resume pick up?
- **Decision:** Bracket each item with a start-of-item entry and a done entry, but do not commit the inner build/verify/review/fix transitions. Resume granularity is per item: a run stopped mid-item resumes at that item, not at an exact inner phase.
- **Rationale:** The operator asked that "transitions within the loop are not committed so that we don't add a bunch of transitional commits with no code in-between." Per-item granularity keeps history clean and is sufficient because the in-progress item is re-attempted through inspection anyway ([D6](#d6-in-progress-item-inspect-and-decide)).
- **Evidence:** User input (state-store decision).
- **Rejected alternatives:**
  - Commit each inner-loop transition so resume can pick up at the exact phase — rejected by the operator as history spam with no code between commits, and unnecessary given per-item re-attempt.
- **Linked technical notes:** T1
- **Driven by findings:** —
- **Dependent decisions:** D6
- **Referenced in spec:** Primary Flow, Alternate Flows (Resuming an in-progress item)

### D4: Re-invocation-only recovery

- **Question:** Which context-loss events must resume survive — only an explicit re-invocation, or also a mid-run auto-compaction with no re-invocation?
- **Decision:** Recovery is driven only by the operator re-invoking the driver (a new session, or after fixing a halt) or steering it at the recovery menu. The driver carries no automatic mid-run compaction trigger; a mid-run auto-compaction that strands the run is recovered by re-invoking, and a truncated-but-proceeding driver is bounded by the commit-boundary self-check ([D18](#d18-commit-boundary-self-check)).
- **Rationale:** A re-invocation reloads the full driver body and can re-ground from the durable record, covering both cases the operator asked for. Building an external trigger (a session-lifecycle hook plus a durable out-of-tree run-active marker) was the prior attempt's heaviest and most inconsistent machinery, and the operator chose to leave it out.
- **Evidence:** User input (compaction decision). Prior attempt's re-grounding research (`docs/plans/autonomous-implementation-driver/research/re-grounding-after-compaction.md`) documents the hook-plus-git-config-marker design this declines.
- **Rejected alternatives:**
  - Add a session-lifecycle hook plus a durable run-active marker so a mid-run compaction self-recovers — deferred (spec Deferred (YAGNI)) because re-invocation covers the asked-for cases far more simply.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D9, D18
- **Referenced in spec:** Outcome, Edge Cases, Out of Scope, Deferred (YAGNI)

### D5: In-session recovery menu

- **Question:** What shape should "better halt handling that lets the operator fix an issue and resume" take?
- **Decision:** Keep the existing five-part halt frame, and make its fifth part ("what to do next") an in-session recovery menu offering, with each option's consequence stated on its label: fix in place then re-attempt; run a stated number of automated fix rounds (when the halt was fix-cap-exceeded); skip this item and continue (naming the stranded dependents before the choice); and stop the run (always present, resumable). The menu is filtered to what the halting state allows. It does not offer gate override, upstream repair, an on-demand triage pass, or accept-a-flagged-change. The frame's fifth part is rewritten from today's "the run does not resume; start a fresh branch" to point at resumption (F8).
- **Rationale:** The operator chose the in-session recovery menu over an absolute halt, and chose the minimal option set. Review found the reused frame's part 5 now contradicts the menu (F8) and that skip/stop needed consequence labels and pre-choice disclosure of stranded dependents (F11); making the menu the frame's fifth part resolves both.
- **Evidence:** User input (halt-handling decision and recovery-menu composition). Current baseline halts absolutely (SKILL.md Halt Procedure part 5, lines 305-311; `docs/skills/han-coding/implement-work-items.md` lines 19, 86). F8, F11.
- **Rejected alternatives:**
  - Keep the halt absolute and only make re-invocation resume — rejected by the operator in favor of an in-session menu.
  - Offer the fuller menu (gate override, repair-upstream, triage, accept-flagged-change) — rejected by the operator to keep scope tight; deferred with a reopening trigger.
  - Reuse the five-part frame verbatim — rejected because its part 5 asserts no-resume, which this feature contradicts (F8).
- **Linked technical notes:** —
- **Driven by findings:** F8, F11
- **Dependent decisions:** D7, D15
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, Alternate Flows (A run reaches a state it cannot settle), User Interactions, Out of Scope, Edge Cases

### D6: In-progress item, inspect and decide

- **Question:** When a run resumes and the halting item has a start entry but no done entry, what happens to its work, and what signal classifies it?
- **Decision:** Inspect and decide, with re-running verification as the completeness signal. First, if the item's code already landed in history and cleared its gate, reconcile forward ([D16](#d16-committed-but-unmarked-forward-reconcile)) rather than rebuild. Otherwise, re-run verification against the in-progress tree: work whose verification passes and whose changed-file set is the item's own is kept and re-reviewed; an empty or partial tree, or failing verification, is treated as partial and rebuilt from the start-of-item entry; an item that still needs a pre-work decision re-asks it (the decision is not durable, [D13](#d13-durable-ledger-content-vs-ephemeral-state)). Any state that cannot be positively classified as safe is surfaced and asked ([D11](#d11-ledger-and-history-integrity-safety)). A foreground item's hand-built work is never discarded without explicit agreement, and the driver surfaces the interrupted foreground item's commits and diff as recognition support before asking whether it is complete (F21).
- **Rationale:** The operator chose inspect-and-decide. Review found the classification could not be made from the durable record alone because inner transitions are not recorded (F5); re-running verification — which the driver owns — is the available completeness signal. Review also found the entry condition missed the committed-but-clean-tree state (F1, resolved via [D16](#d16-committed-but-unmarked-forward-reconcile)) and that foreground completeness rested on recall (F21).
- **Evidence:** User input (in-progress-item decision). Prior attempt's resume flow enumerates similar states. F1, F5, F21.
- **Rejected alternatives:**
  - Discard AFK partial work and rebuild, protecting only HITL — rejected by the operator in favor of inspecting every item so complete-but-unreviewed AFK work is salvaged.
  - Always rebuild from the start entry — rejected because it discards hand-built foreground work and correctly-built AFK work.
  - Rely on a stored inner-phase signal — rejected because inner transitions are deliberately not recorded (F5); re-running verification is the signal instead.
- **Linked technical notes:** T2
- **Driven by findings:** F1, F5, F21
- **Dependent decisions:** D16
- **Referenced in spec:** Alternate Flows (Resuming an in-progress item; Resuming an interrupted foreground item), Edge Cases

### D7: Re-attempt, detection-first and non-destructive

- **Question:** After the operator says "I fixed it," how does the driver re-attempt the item without a hidden mode that discards hand edits?
- **Decision:** The driver shows what it detected changed since the item's start-of-item entry (the tree, and the item's text if edited) and offers two non-destructive paths, each labeled with what it does to the operator's edits: (a) re-check the current tree as-is — re-verify and re-review without a build (covers a code-only fix and a "nothing in the repo changed" environment/flake fix); (b) build further toward the item from the current tree — dispatch a build that continues from the operator's edits, never resetting them, with the changed item and residual findings as context, then verify and review (covers a changed item, and the "both code and spec changed" case). A manual fix never consumes an automated fix-round.
- **Rationale:** The operator chose a split between re-check and rebuild. Review found the raw split was a hidden mode that could rebuild away hand edits and had no path for "both" or "neither" (F9); reframing it as detection-first, with "build further" continuing from the tree rather than resetting it, keeps the operator's split intent while making every case non-destructive.
- **Evidence:** User input (re-attempt decision). The driver already re-dispatches a fix build with residual findings as context and does not reset the tree (SKILL.md Step 3.3). F9.
- **Rejected alternatives:**
  - Always re-verify and re-review the current tree, never build — rejected as wasteful when the item's target moved and the code has not caught up.
  - Always rebuild via a fresh sub-agent from the start baseline — rejected because it discards correct hand edits (F9).
  - A bare "code changed vs spec changed" question — rejected as a hidden mode with no "both"/"neither" branch (F9).
- **Linked technical notes:** —
- **Driven by findings:** F9
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows (A run reaches a state it cannot settle; Operator fixes an issue and re-attempts), User Interactions, Edge Cases

### D8: Ledger markers left in history

- **Question:** What happens to the progress record in history at the end of a completed run?
- **Decision:** Leave the record in the branch history. The completion summary notes it is present, that a re-invocation on the same file recognizes the completed run, and that the operator may strip the record by hand at the cost of resumability. No cleanup flow is built.
- **Rationale:** The operator chose to leave the record in. Greppable entries are low-noise, and leaving them keeps the branch resumable. An automated cleanup that rewrites history and ends resumability was a complexity source in the prior attempt.
- **Evidence:** User input (marker-cleanup decision).
- **Rejected alternatives:**
  - Offer an end-of-run cleanup that strips the record — deferred (spec Deferred (YAGNI)) because a manual rebase meets the tidiness need.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, User Interactions, Edge Cases, Out of Scope

### D9: Re-grounding as one shared routine

- **Question:** The word "re-ground" appears across the skill but is never defined as a routine. How should it be defined and reused?
- **Decision:** Define re-grounding once as a single shared routine and run it at every point the driver re-enters an in-progress run: after a foreground hand-off, after a human review, on a cross-session resume, and after a recovery-menu re-attempt. The routine re-reads the durable record to reconstruct run state, re-derives the dependency graph from the work-items file, re-reads the working tree, re-reads its own instructions (reloading if truncated), and announces where it is before acting.
- **Rationale:** Today re-grounding is referenced three times but only partially defined inline; the operator asked to check it is properly defined and to reuse it for restart. One routine reused everywhere removes the inconsistency and gives cross-session resume the same re-establishment as an in-session hand-off. The "re-read own instructions, reload if truncated" step is reused at the commit boundary ([D18](#d18-commit-boundary-self-check)).
- **Evidence:** SKILL.md lines 209, 240 (undefined "re-ground"); `references/foreground-handoff-protocol.md` lines 19-22 (the only partial definition); `references/human-review-capture.md` line 27. User request.
- **Rejected alternatives:**
  - Leave re-grounding as scattered inline references — rejected because it is undefined and inconsistent, which the operator flagged.
  - Define a separate restart routine distinct from re-grounding — rejected because restart's needs are re-grounding's needs; one routine serves both.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D18
- **Referenced in spec:** Outcome, Alternate Flows (Resuming a partially complete run), Edge Cases, User Interactions

### D10: Fresh-vs-resume detection

- **Question:** How does the driver decide, on invocation, whether it is starting fresh or resuming — and what becomes of today's refusal of a prior-run branch?
- **Decision:** On invocation the driver resolves the target branch (from the branch input or the folder-derived default), then reads that branch's history for this run's durable record. If a record for this work-items file is present, it resumes; if the branch carries no prior run commits, it proceeds fresh; if the branch carries commits but no record for this file, it refuses rather than commit onto a foreign base. Run identity is keyed on the work-items file's repo-root-relative path (F18). Today's Step 1.6 refusal is reworked: this run's own branch is recognized and resumed, but the guardrail against committing onto a foreign base is preserved for the no-record-but-non-empty case (F7).
- **Rationale:** The durable, greppable record ([D2](#d2-committed-greppable-per-item-ledger)) is the signal needed to classify the invocation. Review found that reworking Step 1.6 naively would drop its safety refusal for a branch carrying non-record commits (F7), and that "identify the work-items file" needed a stated basis to route mismatch handling (F18); keying on path preserves the guardrail and the folder-derived branch default.
- **Evidence:** SKILL.md Step 1.6 ("Refuse a prior-run branch"), Step 1.2 (branch resolution), Step 1.8; `docs/skills/han-coding/implement-work-items.md` line 82. F7, F18.
- **Rejected alternatives:**
  - Require an explicit `--resume` flag — rejected because re-invoking on the same file is an unambiguous signal once the record exists.
  - Pure marker-detection with no refusal for a non-empty non-record branch — rejected because it would commit a run onto a foreign base (F7).
  - Identity by file content — rejected because it would flag every edit as a mismatch (F18); path is the key.
- **Linked technical notes:** T1
- **Driven by findings:** F7, F18
- **Dependent decisions:** D11, D12
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, Alternate Flows (Resuming a partially complete run), Edge Cases, User Interactions

### D11: Ledger and history integrity safety

- **Question:** What does the driver do on a resume when the durable record and the current state disagree, or when it cannot positively classify the state?
- **Decision:** Default-deny. The driver never proceeds on a guessed base or reports an item done whose commit is gone; any resume state it cannot positively classify as safe is surfaced-and-asked. It surfaces the specific divergence with the unmatched entries named, adds a plain-language cause and meaning, and offers one uniform, consequence-labeled option set with the safe option marked: abort to reconcile; restart (which supersedes the prior record); or, only where provably safe, proceed from the first unmatched item. "Proceed" is withheld when the resumption point would fall before a dependency or when the record is internally inconsistent. The enumerated divergences (missing branch, unresolved done-commit, edited/renumbered file, foreign file on the branch, partially-stripped record) are examples of the rule, not a closed list. Resume re-derives the dependency graph and re-honors skip-strands (F16). The done-entry-commit-still-resolves check is kept (an item is never reported done on an entry whose commit is gone), but a dedicated pre-check that the in-progress item's commit range contains only that item's work was deferred as YAGNI (F3; see spec Deferred): a foreign or reordered commit's files instead surface through the item's re-review scope check and are resolved at the recovery menu.
- **Rationale:** A committed record can diverge from history through resets, rebases, or file edits. Review found the draft was an allowlist with an implicit "else, proceed" (F2), that a foreign or reordered commit's files can land in the item's range (F3) — resolved by deferring a dedicated pre-check to the existing scope check plus the recovery menu, since a mid-run rewrite is rare and a general foreign-commit test is not buildable for foreground items — that "proceed from first unmatched" could violate a newly-added dependency edge and that skip-strands were not re-honored on resume (F16), and that the bespoke per-mismatch menus were over-scoped completeness inherited from the prior attempt (F26). Default-deny plus a uniform option set resolves all of these while keeping the safety invariant.
- **Evidence:** User request (resume must be safe). Prior attempt's D20-driven edge cases enumerate the mismatches. F2, F3, F16, F24, F26; F31 (plain-language cause).
- **Rejected alternatives:**
  - Trust the markers and proceed on anything not explicitly caught — rejected as fail-open (F2).
  - A bespoke tailored option menu per named mismatch — rejected as over-scoped; collapsed to a uniform set (F26).
  - Add a dedicated pre-check that the start-of-item range contains only the item's work — deferred as YAGNI (F3; see spec Deferred): the review scope check plus the recovery menu already surface and resolve a polluted range, a mid-run history rewrite is rare, and a general foreign-commit test is not buildable for a foreground item whose skill commits its own work. The done-entry-commit-still-resolves check is kept.
- **Linked technical notes:** T1
- **Driven by findings:** F2, F3, F16, F24, F26, F31
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows (Resuming a partially complete run; Resuming an in-progress item; Ledger and history disagree on resume), Edge Cases, User Interactions

### D12: Resume preconditions

- **Question:** How do the fresh-run start preconditions (clean tree, green suite) apply on a resume, when the in-progress item's work is expected in the tree and the committed floor may have drifted?
- **Decision:** On a resume, the uncommitted work of the single in-progress item is the one allowed exception to the clean-tree precondition; the driver inspects it ([D6](#d6-in-progress-item-inspect-and-decide)) rather than refusing. The driver completes inspection and any discard before re-establishing the verification baseline, so leftover partial work cannot redden the baseline and be misread as a regression. After removing the in-progress work it re-runs the baseline; a baseline that is now red (a done item regressed from between-session drift) is surfaced as a distinct condition — named failing tests, noted green-at-commit — with a stop-or-abort choice, not silently adopted as a red floor.
- **Rationale:** The current clean-tree and green-suite checks would refuse a legitimate resume. Review found that trusting done items green-at-commit and skipping the green re-check let between-session drift adopt a red floor against which new regressions pass (F12); re-running the baseline and surfacing a red floor restores the fresh-run protection.
- **Evidence:** SKILL.md Step 1.5 (clean tree and green suite); user request. F12.
- **Rejected alternatives:**
  - Refuse any dirty tree on resume — rejected because the in-progress item's work is expected.
  - Trust done items green-at-commit with no re-check — rejected because between-session drift can redden the floor silently (F12).
- **Linked technical notes:** —
- **Driven by findings:** F12
- **Dependent decisions:** —
- **Referenced in spec:** Actors and Triggers, Alternate Flows (Resuming a partially complete run; Resuming an in-progress item), Edge Cases, User Interactions

### D13: Durable ledger content vs ephemeral state

- **Question:** What exactly is durable in the committed record, and what stays ephemeral?
- **Decision:** Durable (recorded to the branch): the opening run entry with the run configuration and work-items file, per-item start and done entries, each item's code-commit reference, and skip entries. The durable record is the source of truth for resume and supersedes the in-session store; whatever within-session inner tracking persists (inner phase, fix-round count) is authoritative only within a live session and is reconstructed on resume from the record plus tree inspection. The driver's own progress entries are never staged into an item's code commit and never counted as a scope finding. Ephemeral / not durable: the per-item review records stay local and a resume re-reviews; the automated fix-round counter is within-session, so a cross-session stop re-arms it (accepted because each resume is operator-initiated and each halt is loud; the resume summary notes prior-session touches); rounds granted at the recovery menu do not survive a stop; a captured pre-work decision is not recorded, so a resume re-asks it ([D6](#d6-in-progress-item-inspect-and-decide)). On resume, config is restored from the opening entry and is immutable within the run; a conflicting supplied flag is named as ignored, not silently applied. A failure to record the opening entry stops the run and a re-invocation starts fresh; a failure to record a later entry stops resumably.
- **Rationale:** Configuration and progress must survive to resume correctly and gate resumed items against the same criteria as committed ones. Review clarified the fate of the in-session store and that the durable record must be excluded from staging/scope (F6), that the fix-round counter's re-arm was overclaimed as "conscious" (F20), that a run-start-entry failure is not resumable like later entries (F17), and that a conflicting resume flag was silently ignored (F19). The pre-work decision is not durable (F25, user decision); review records stay ephemeral because resume re-reviews.
- **Evidence:** User input (state-store decision; decision-persistence decision). Current per-item review record path and gitignored directory (`docs/skills/han-coding/implement-work-items.md` line 57). F6, F17, F19, F20, F25.
- **Rejected alternatives:**
  - Commit the review records and the fix-round counter — rejected as noise; resume re-reviews and the counter is a within-session bound.
  - Persist the pre-work decision durably — rejected (F25, YAGNI): re-ask on resume; the interrupt window is narrow.
  - Re-derive the run configuration on resume — rejected because it could gate resumed items differently.
  - Apply a conflicting resume flag silently — rejected; name it as ignored (F19).
- **Linked technical notes:** T1
- **Driven by findings:** F6, F17, F19, F20, F25
- **Dependent decisions:** D16, D21
- **Referenced in spec:** Primary Flow, Alternate Flows (Resuming a partially complete run; Resuming an interrupted foreground item; A run reaches a state it cannot settle), Coordinations, Edge Cases, User Interactions, Deferred (YAGNI)

### D15: Skip returns the tree to a clean baseline

- **Question:** What happens to the halting item's uncommitted work when the operator skips it?
- **Decision:** Before continuing to the next item, the driver returns the working tree to the last clean committed baseline — inspecting and confirming before discarding, and never discarding an interactive item's hand-built work — so the skipped item's files do not contaminate the next item's start-of-item range, scope check, or commit. It records a skip entry and continues to the next item whose dependencies are met.
- **Rationale:** Review found that skip abandoned the item without cleaning the tree, so its uncommitted files (the normal state at a fix-cap-exceeded halt) would land in the next item's range and be committed under the next item's identity (F4). This is the defer-cleanup discipline the prior attempt required, applied to skip.
- **Evidence:** Prior attempt's spec ("A blocker is raised" required returning the tree to the last clean committed baseline before continuing after a defer). F4.
- **Rejected alternatives:**
  - Abandon and continue without cleanup — rejected because it contaminates the next item's commit (F4).
  - Discard blindly, including hand-built work — rejected; inspect and confirm, protect interactive work.
- **Linked technical notes:** —
- **Driven by findings:** F4
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows (A run reaches a state it cannot settle), Edge Cases

### D16: Committed-but-unmarked forward-reconcile

- **Question:** What does resume do when an item's code committed but its done entry did not (the two writes are non-atomic and a session died between them)?
- **Decision:** Before treating a started-but-not-done item as unfinished, the driver checks whether the item's code already landed in history — a code commit exists in its start-of-item-to-HEAD range that cleared its gate. If it did, the driver reconciles forward: it records the missing done entry and advances, and announces it did so, rather than rebuilding and double-committing.
- **Rationale:** Review found the code commit and the done entry are two non-atomic writes; a clean-tree committed-but-unmarked item was not covered by the in-progress entry condition (uncommitted work in the tree), so resume would rebuild it and double-commit (F1). Specifying the forward-reconcile closes the gap the draft asserted but did not define.
- **Evidence:** F1 (on-call-engineer OCE-001, edge-case-explorer EC2). The item's start-to-HEAD range makes "did the code land" answerable.
- **Rejected alternatives:**
  - Rebuild the item (draft's implicit behavior) — rejected; it double-commits already-committed, gated work (F1).
  - Collapse the two writes into one atomic commit — noted for plan-implementation as defense in depth; the resume-side reconciliation is required regardless because a rejected done entry or a kill is always possible.
- **Linked technical notes:** T1
- **Driven by findings:** F1
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows (Resuming an in-progress item), Edge Cases

### D17: Single-writer per checkout

- **Question:** What happens if a second driver is invoked on the same checkout while one is live?
- **Decision:** Unsupported by assumption: one live driver per checkout. The driver does not lock, detect, or arbitrate a concurrent invocation; the assumption is stated as a precondition and in Out of Scope so the operator does not unknowingly violate it.
- **Rationale:** Review noted that re-invocation is the designed resume path (so the driver cannot refuse one), the committed record carries progress not liveness, and two drivers on one working tree would interleave commits and scramble the range (F15). A lock is deferred (YAGNI); the deferred out-of-tree run-active marker is the reopen trigger.
- **Evidence:** F15 (on-call-engineer OCE-004). D4 deferred the out-of-tree marker that would signal liveness.
- **Rejected alternatives:**
  - Add an advisory lock now — deferred (YAGNI); no evidence operators run concurrent drivers, and it would revive the deferred marker machinery.
- **Linked technical notes:** —
- **Driven by findings:** F15
- **Dependent decisions:** —
- **Referenced in spec:** Actors and Triggers, Edge Cases, Out of Scope

### D18: Commit-boundary self-check

- **Question:** How is a driver bounded when a mid-run compaction truncates its own instructions but leaves it able to proceed?
- **Decision:** The driver re-reads its own instructions, reloading if truncated, at the commit boundary — the highest-consequence action — before committing an item and recording it done. This bounds a truncated driver's blast radius to the in-progress item (which resume re-inspects) rather than a falsely-trusted done item that no later step re-examines. It reuses the re-grounding routine's existing instruction-reload step, not the deferred compaction hook.
- **Rationale:** Review found that re-invocation-only recovery ([D4](#d4-re-invocation-only-recovery)) handles the driver that stops, but not the driver that keeps going on partial instructions and commits a wrongly-gated item; because resume trusts done items and never re-reviews them, a falsely-trusted done item is the worst outcome (F14). Guarding the commit boundary is the cheapest safe mitigation.
- **Evidence:** F14 (on-call-engineer OCE-005). The re-grounding routine already re-reads instructions (`references/foreground-handoff-protocol.md`).
- **Rejected alternatives:**
  - Do nothing until the operator re-invokes — rejected because a truncated driver can commit a falsely-trusted done item before the operator notices (F14).
  - Add the compaction hook to re-ground continuously — deferred (D4); the commit-boundary check bounds the residual without it.
- **Linked technical notes:** —
- **Driven by findings:** F14
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases, Deferred (YAGNI)

### D19: Cross-session resume go-ahead

- **Question:** Should a cross-session resume mutate automatically after the summary, or wait for the operator?
- **Decision:** On a cross-session resume the driver announces the concrete next action (the specific next item, the phase it will resume at, and the disposition of any in-progress item) and waits for the operator's go-ahead before the first build or any discard. In-session re-grounds after a foreground or review pause do not require this, because the operator is already present.
- **Rationale:** The operator chose confirm-before-mutate/discard. Review found the resume summary reported state but not the next action, and a clean resume continued into building and possible discard with no checkpoint at the exact re-orientation moment the feature serves (F10).
- **Evidence:** User input (resume-confirm decision). Contrast the fresh-run confirm gate (SKILL.md Step 2.1). F10.
- **Rejected alternatives:**
  - Auto-continue after the summary — rejected by the operator; the resume is the moment state most needs verifying, and a silent discard of salvageable work is the risk.
  - Confirm at every re-ground (including in-session) — rejected as needless friction where the operator is already present.
- **Linked technical notes:** —
- **Driven by findings:** F10
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows (Resuming a partially complete run; Resuming an in-progress item), User Interactions, Edge Cases

### D20: Marker commits conform to convention and fail as a distinct class

- **Question:** How do the driver's bookkeeping commits interact with the repo's commit hooks, and how is a rejected bookkeeping commit handled?
- **Decision:** The progress-record commits conform to the repo's commit convention so the project's commit hooks accept them. A bookkeeping-commit rejection is a distinct failure class from a code-commit failure: it is surface-and-stop, never routed into the fix loop (there is no code to fix). The driver may probe read-only at run-start whether the branch will accept a bookkeeping commit, so a strict-hook repo is caught at plan-confirmation rather than at item 1.
- **Rationale:** Review found that a repo with a commit-message-convention gate or a no-empty-commit rule could reject the start-of-item entry (written before any build), halting at item 1 on every invocation, and that routing a marker-write failure through the fix loop would loop uselessly (F13). Conforming to convention and classing the failure distinctly avoids the poison-pill.
- **Evidence:** F13 (on-call-engineer OCE-008). Baseline routes code-commit hook failures into the fix loop (SKILL.md Step 3.4); a marker commit has no code to fix.
- **Rejected alternatives:**
  - Bypass hooks for bookkeeping commits — noted as a plan-implementation option but not required at the spec level; conforming to convention is the default expectation.
  - Route a marker-write failure through the fix loop — rejected; there is no code to fix (F13).
- **Linked technical notes:** T1
- **Driven by findings:** F13
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Coordinations, Edge Cases

### D21: Done items trusted by identifier

- **Question:** If the operator edits an already-done item's body while stopped, does resume detect and rebuild it, or trust the identifier?

- **Decision:** A done item whose identifier still matches is treated as done regardless of body edits; the driver does not detect the change and does not rebuild it. To rebuild an already-done item the operator restarts the run. The completion and resume messaging note that done items are trusted by identifier.
- **Rationale:** The operator chose to trust the identifier. Review flagged the silent-correctness risk that an edited already-done item is never rebuilt (F22); the operator accepted the limitation over adding a per-item body-identity record and comparison for a case restarting the run already covers.
- **Evidence:** User input (edited-items decision). F22 (edge-case-explorer EC5).
- **Rejected alternatives:**
  - Record a body identity on the done entry and surface a changed body on resume — deferred (spec Deferred (YAGNI)) per the operator's choice; the operator restarts to rebuild.
- **Linked technical notes:** —
- **Driven by findings:** F22
- **Dependent decisions:** —
- **Referenced in spec:** Edge Cases, Out of Scope, Deferred (YAGNI)
