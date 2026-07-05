# Team Findings: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

This file records every finding raised by the review team, and how each was resolved. Behavioral outcomes live in [../feature-specification.md](../feature-specification.md); decisions the findings affected live in [decision-log.md](decision-log.md); load-bearing mechanics live in [feature-technical-notes.md](feature-technical-notes.md).

Review team dispatched (feature size: medium): `han-core:junior-developer`, `han-core:edge-case-explorer`, `han-core:user-experience-designer`, `han-core:on-call-engineer`. All four returned; findings converged strongly on git-history re-entry safety.

## Major findings

### F1: The code commit and the done marker are two non-atomic writes; a clean-tree committed item is rebuilt and double-committed

- **Agent:** on-call-engineer (OCE-001), edge-case-explorer (EC2)
- **Finding:** A session dying between an item's code commit and its done-marker commit leaves the item committed with a clean tree and a start marker but no done marker. The draft's in-progress-item entry condition requires uncommitted work in the tree, so this state has no classified path; resume treats the item as unfinished and rebuilds it, double-committing. The reconciliation was asserted in D13, not specified.
- **Resolution:** Added a forward-reconcile rule: before treating a started-but-not-done item as unfinished, the driver checks whether that item's code already landed in history and cleared its gate; if so, it records the missing done marker and advances rather than rebuilding. Made this a named resume state.
- **Resolved by:** evidence
- **Affected decisions:** D6, D16
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Alternate Flows (Resuming an in-progress item), Edge Cases

### F2: Divergence handling is an allowlist with an implicit "else, proceed on the markers"

- **Agent:** on-call-engineer (OCE-002)
- **Finding:** The mismatch flow and edge table enumerate specific divergences and fail closed on each, but any state not on the list falls through to the happy resume path that trusts the markers. The safety property is only as strong as the enumeration.
- **Resolution:** Added a default-deny catch-all: any marker/history state the driver cannot positively classify as safe-to-resume is surfaced-and-asked, the enumerated cases being examples of that rule. Restated the in-progress inspection default as "when in doubt, surface."
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Ledger and history disagree on resume; Resuming an in-progress item), Edge Cases

### F3: The scope baseline (start-of-item marker) is not integrity-checked; a rebase or foreign commit pollutes the range and stages another item's files

- **Agent:** on-call-engineer (OCE-003), edge-case-explorer (EC6)
- **Finding:** The changed-file set is measured from the start-of-item marker, but only done-marker resolution is integrity-checked. An out-of-band rebase, or a routine operator commit on the branch between sessions, can put another item's or an unrelated file's changes in the start-marker→HEAD range, so the scope check and by-path staging pull in files the item never touched — and a foreign commit's scope finding can never be cleared through the recovery menu, permanently stranding the item.
- **Resolution:** Deferred as YAGNI (operator decision, after verifying the fallback). The dedicated range pre-check is not built: the item's re-review already computes its changed-file set from the start-of-item entry and flags files beyond the item's work as a scope finding (`review-verdict-contract.md#scope`), which gates when the reach is substantial (a reordered item's work, an unrelated feature), and the recovery menu then lets the operator drop the commit and re-attempt, skip, or stop. A mid-run history rewrite is low-probability (cleanup lands after a run completes), and a general "is this commit foreign" test is not reliably buildable for a foreground item whose skill commits its own work. Kept the cheaper, higher-value checks the range check was bundled with: the committed-but-unmarked forward-reconcile (D16) and the done-entry-commit-still-resolves check (D11), which guard the far more likely killed-session-between-commit-and-done-marker case. Residual accepted: a below-threshold one-liner pollution after a rare mid-run rewrite may ride into the commit (the review judged it trivial). Recorded in the spec's Deferred (YAGNI) with a reopen trigger.
- **Resolved by:** user input
- **Affected decisions:** D11
- **Affected tech-notes:** T1
- **Changed in spec:** Deferred (YAGNI), Alternate Flows (Resuming an in-progress item; Ledger and history disagree on resume), Edge Cases

### F4: Skip does not clean the tree; the skipped item's uncommitted work contaminates the next item

- **Agent:** edge-case-explorer (EC1)
- **Finding:** "Skip this item, continue" abandons the item and continues, but says nothing about its uncommitted working-tree changes (the normal state at a fix-cap-exceeded halt). Those files then sit in the next item's start→HEAD range, get flagged as scope findings, and can be committed under the next item's identity.
- **Resolution:** Skip returns the working tree to the last clean committed baseline before the next item begins, inspecting and confirming before discarding and never discarding an interactive item's hand-built work — the defer-cleanup discipline the prior attempt required.
- **Resolved by:** evidence
- **Affected decisions:** D15
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (A run reaches a state it cannot settle), Edge Cases

### F5: The in-progress inspection needs a completeness signal the durable record deliberately does not keep

- **Agent:** junior-developer (JD-001), edge-case-explorer (EC11)
- **Finding:** The inspection is asked to tell "complete and verified but not reviewed" from "genuinely partial," but verify/review transitions are exactly what the durable record does not capture, so the classification cannot be made from the start marker plus the tree alone.
- **Resolution:** Specified the completeness signal: the driver re-runs verification against the in-progress tree as the inspection. Verification passing (with the changed-file set matching the item's work) means keep-and-re-review; verification failing, or an empty/partial tree, means discard-and-rebuild; when the result is not clean, surface and ask. This resolves the classification without a stored inner-phase flag.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming an in-progress item), Edge Cases

### F6: The fate of the existing in-session state store is unaddressed, and the committed ledger must be excluded from stage-by-path and the scope check

- **Agent:** junior-developer (JD-002, JD-009)
- **Finding:** The whole of the current Step 3 writes per-transition state to a gitignored store, and the scope check and by-path staging both rely on that store being gitignored (`.implement-work-items/` excluded). The spec never says whether the store is removed or retained, nor that the durable ledger (which may be a committed file) must also be excluded from staging and scope, or it will pollute code commits or produce spurious scope findings on the driver's own bookkeeping.
- **Resolution:** Stated that the durable branch record is the source of truth for resume and supersedes the in-session store; whatever within-session inner tracking persists (inner phase, fix-round count) is authoritative only within a live session and is reconstructed on resume from the markers plus tree inspection. Stated that the driver's own progress markers are never staged into an item's code commit and never counted as a scope finding, extending today's artifact exclusion to the durable ledger.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Coordinations, Edge Cases

### F7: Reworking Step 1.6 into marker-detection drops the "branch already carries commits" safety refusal

- **Agent:** junior-developer (JD-003)
- **Finding:** Today's Step 1.6 refuses any branch carrying prior commits. Under pure marker-detection, a branch with non-marker commits (a hand-made branch, unrelated prior work) classifies as fresh, and setup would pile per-item commits onto that arbitrary base with no refusal.
- **Resolution:** Kept a refusal for the no-marker-but-non-empty case: a target branch that carries commits but no run markers for this file is refused (as today), so the run never commits onto a foreign base; only a branch with this run's markers resumes, and a branch with no prior run commits proceeds fresh.
- **Resolved by:** evidence
- **Affected decisions:** D10
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases

### F8: The reused five-part halt frame's part 5 now contradicts the recovery menu

- **Agent:** junior-developer (JD-006), user-experience-designer (UX-A)
- **Finding:** The frame's part 5 today reads "the run does not resume; start a fresh branch" — the opposite of this feature. Reusing the frame verbatim would print, directly beneath a menu offering a resumable stop, an instruction to abandon the branch.
- **Resolution:** Rewrote halt-frame part 5 ("what to do next") to point at resume, and made the recovery menu itself be part 5 rather than a block wedged between the evidence and a stale paragraph.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, Alternate Flows (A run reaches a state it cannot settle), User Interactions

### F9: The code-vs-spec re-attempt is a hidden mode that can discard hand edits, with no "both"/"neither" path

- **Agent:** user-experience-designer (UX-D), edge-case-explorer (EC9)
- **Finding:** Making the operator declare "code changed" vs "spec changed" is a mode switch whose real stake — are my hand edits kept or rebuilt away? — is not surfaced, and it has no branch for changing both or neither (an environment/flake fix).
- **Resolution:** Reworked the re-attempt to be detection-first and non-destructive: the driver shows what it detects changed since the start marker and offers (a) re-check the current tree as-is — re-verify and re-review without a build (covers a code-only fix and a "neither" environment fix), or (b) build further toward the item from the current tree — dispatch a build that continues from the operator's edits (never resetting them) with the changed item/findings as context, then verify and review (covers a spec change and the "both" case). A manual fix never consumes an automated fix-round.
- **Resolved by:** evidence
- **Affected decisions:** D7
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Operator fixes an issue and re-attempts), User Interactions, Edge Cases

### F10: A cross-session resume mutates with no go-ahead at the exact re-orientation moment the feature exists to serve

- **Agent:** user-experience-designer (UX-B)
- **Finding:** The resume summary reports state but not the concrete next action, and a clean resume continues into building (and possible discard) with no confirm, unlike the fresh run's Step 2.1 gate.
- **Resolution:** (User decision — confirm before mutate/discard.) On a cross-session resume the driver announces the concrete next action (which item, which phase, what happens to the in-progress item) and waits for a go-ahead before the first build or any discard; in-session re-grounds after a foreground or review pause skip this because the operator is already present.
- **Resolved by:** user input
- **Affected decisions:** D19
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming a partially complete run), User Interactions

### F11: Skip and stop are not consequence-labeled, and skip strands dependents after the choice, not before

- **Agent:** user-experience-designer (UX-C)
- **Finding:** "Stop (resumable)" and "Skip (continue)" both read as "give up on this item"; their real difference is in prose. Skip is durable and hard to reverse, yet the stranded-dependent set is named as part of the skip action, after the operator has chosen.
- **Resolution:** The recovery-menu options carry consequence labels (matching the reconciliation prompts), and the stranded-dependent set is computed and shown next to the skip option before the choice is committed. The stop label states the re-invoke-to-resume path.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (A run reaches a state it cannot settle), User Interactions

### F12: A red verification baseline on resume (between-session drift) is not handled

- **Agent:** junior-developer (JD-012), on-call-engineer (OCE-007), edge-case-explorer (EC4)
- **Finding:** Resume relaxes the green-suite gate and trusts done items as green-at-commit. If the committed floor is now red (a merge from main, a lockfile change, a toolchain bump), resume adopts a red baseline, and every subsequent item is measured against a red floor so genuine new regressions can pass.
- **Resolution:** On resume, after removing the in-progress item's work, the driver re-runs the verification baseline; a red floor is surfaced as a distinct condition (named failing tests, noted green-at-commit) with a stop-or-abort choice, rather than silently adopted — the resume analogue of today's red-suite startup refusal.
- **Resolved by:** evidence
- **Affected decisions:** D12
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming a partially complete run; Resuming an in-progress item), Edge Cases

### F13: Marker commits coordinate with the same commit hooks that gate code commits, and a rejected bookkeeping commit is an unrecoverable halt

- **Agent:** on-call-engineer (OCE-008)
- **Finding:** A repo with a commit-message-convention gate or a no-empty-commit hook can reject the driver's start-of-item marker (written before any build), halting at item 1 on every invocation including resume. The fix loop is the wrong recovery (there is no code to fix).
- **Resolution:** Stated in Coordinations that marker commits conform to the repo's commit convention so hooks accept them, and that a marker-write failure is a distinct class from a code-commit failure — surface-and-stop, never routed into the fix loop. Noted an optional early read-only probe at run-start so a strict-hook repo is caught at plan-confirmation. Recorded the hook-compatibility constraint on the marker form in T1.
- **Resolved by:** evidence
- **Affected decisions:** D20
- **Affected tech-notes:** T1
- **Changed in spec:** Coordinations, Edge Cases

### F14: A mid-run compaction that leaves the driver able to proceed on truncated instructions can falsely mark an item done

- **Agent:** on-call-engineer (OCE-005)
- **Finding:** Re-invocation-only recovery handles the driver that stops, but not the driver that keeps going on truncated instructions between re-grounding points and commits a wrongly-gated item and its done marker. Resume trusts done items and never re-reviews them, so the blast radius is a falsely-trusted done item no later step re-examines.
- **Resolution:** The driver runs the re-grounding routine's "re-read own instructions, reload if truncated" step at the commit boundary (once per item, the highest-consequence action), bounding a truncated driver's blast radius to the in-progress item, which resume re-inspects. This reuses existing capability and is not the deferred compaction hook.
- **Resolved by:** evidence
- **Affected decisions:** D18
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases

### F15: There is no single-writer interlock and the single-writer assumption is unstated

- **Agent:** on-call-engineer (OCE-004)
- **Finding:** Re-invocation is the designed resume path, so the driver cannot refuse one, and the committed markers record progress, not liveness — a second concurrent invocation on the same checkout looks identical to a clean-stop resume, risking interleaved commits and a scrambled range.
- **Resolution:** Stated the single-writer assumption as a precondition and in Out of Scope — one live driver per checkout; concurrent invocation on the same working tree is unsupported. Did not add a lock (YAGNI); the deferred out-of-tree run-active marker is the reopen trigger if concurrent runs become real.
- **Resolved by:** evidence
- **Affected decisions:** D17
- **Affected tech-notes:** —
- **Changed in spec:** Actors and Triggers, Out of Scope

### F16: Resume does not re-honor skip-strands, and "proceed from first unmatched" can violate a newly-added dependency edge

- **Agent:** on-call-engineer (OCE-006), edge-case-explorer (EC3)
- **Finding:** The stranded-dependent set is in-session only; only skip markers survive, so a later resume can pick a dependent of a skipped item. And "proceed from first unmatched," computed against the re-parsed file, can place the resumption point before a dependency the operator added between runs.
- **Resolution:** Stated that resume re-derives the dependency graph from the work-items file and re-honors skip-strands, so "first neither-done-nor-skipped" is filtered by unmet dependencies. The "proceed from first unmatched" option is offered only when the driver can show the dependency order still places the resumption point after its dependencies; otherwise it surfaces the ordering change and asks.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming a partially complete run; Ledger and history disagree on resume), Edge Cases

### F17: A run-start-marker write failure produces a fresh run on re-invocation, not a resume; "stops resumably" is inaccurate for it

- **Agent:** edge-case-explorer (EC8)
- **Finding:** Every marker after the run-start marker leaves enough prior markers to resume, but a failed run-start marker leaves none, so re-invocation classifies as fresh. "Stops resumably" is true for later markers, not this one.
- **Resolution:** Distinguished the run-start-marker failure: it stops the run, and a re-invocation starts fresh rather than resuming; the driver says so at the failure rather than implying a resume is available.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases

### F18: "Identifies the work-items file" has no stated basis, but it routes the mismatch handling

- **Agent:** junior-developer (JD-005)
- **Finding:** Whether file identity is by path, content, or a stored id decides which mismatch bucket an invocation lands in; identity-by-path misses a rename, identity-by-content flags every edit.
- **Resolution:** File identity is by the work-items file's repo-root-relative path (the natural key, matching the folder-derived branch default). An edited-but-same-path file is reconciled by comparing the recorded item ids to the file's current items, not by content hash; a different path is a different run.
- **Resolved by:** evidence
- **Affected decisions:** D10
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Alternate Flows (Ledger and history disagree on resume)

### F19: CLI flags supplied on resume that conflict with the restored config are silently ignored

- **Agent:** junior-developer (JD-008), on-call-engineer (OCE-011)
- **Finding:** Resume restores the config from the run-start marker; a supplied flag (e.g. `--fix-cap 5`) is silently overridden, and a passive display of the restored value is easy to miss.
- **Resolution:** On resume, a supplied flag that conflicts with the restored config is named as ignored in the resume summary (not merely shown as the restored value), so the operator sees their override did not take and that changing config requires a fresh run.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming a partially complete run), User Interactions

### F20: The fix-round cap is a within-session bound; a cross-session stop silently re-arms it

- **Agent:** junior-developer (JD-007), on-call-engineer (OCE-010), edge-case-explorer (EC10)
- **Finding:** The counter is ephemeral, so a plain cross-session stop mid-fix-loop resets the cap on resume; D13's "resets consciously" overclaims for a session that simply ended, and granted extra rounds do not survive a stop either.
- **Resolution:** Documented the re-arm as accepted behavior bounded by the operator being in the loop at every resume (each resume is operator-initiated and each halt is loud), and softened D13's "consciously" claim. Noted, in the resume summary, how many prior sessions touched the in-progress item so a repeatedly-stuck item is visible; and stated that fix rounds granted at the recovery menu are within-session and do not survive a stop.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resuming a partially complete run; A run reaches a state it cannot settle), Edge Cases

### F21: Resuming an interrupted foreground item accepts "complete" on operator recall without surfacing the tree

- **Agent:** user-experience-designer (UX-F), edge-case-explorer (EC7)
- **Finding:** The driver accepts "the hand-built work is complete" and proceeds to verify without showing the operator the uncommitted files and commits since the start marker, so a partial hand-build is verified toward a bad commit, and the completeness judgment rests on unreliable multi-day recall.
- **Resolution:** Before accepting the "treat as complete" confirmation, the driver surfaces the interrupted item's commits and uncommitted diff since its start marker as recognition support, turning the recall question into a recognition one.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Affected tech-notes:** T2
- **Changed in spec:** Alternate Flows (Resuming an interrupted foreground item), Edge Cases

### F22: An edited already-done item is trusted by id and silently not rebuilt

- **Agent:** edge-case-explorer (EC5)
- **Finding:** If the operator edits an already-done item's body while stopped, its id still matches the done marker, so resume treats it as done and reports the run complete while the updated body is never built — a silent correctness failure.
- **Resolution:** (User decision — trust the item id.) A done item whose id still matches is treated as done regardless of body edits; detecting body edits is deliberately not built. Recorded as an accepted limitation: the operator restarts the run (or re-plans) to rebuild an already-done item, and the completion/resume messaging notes that done items are trusted by id.
- **Resolved by:** user input
- **Affected decisions:** D21
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases, Out of Scope

### F23: The spec over-pins the commit-based marker form while T1 defers it, and internal "ledger/marker" vocabulary leaks into operator-facing copy

- **Agent:** user-experience-designer (spec-hygiene, UX-H)
- **Finding:** Primary Flow and Coordinations commit to "marker commits, committed separately, located by scanning history" while T1 explicitly defers the marker form; and the feedback copy uses internal nouns ("ledger-file disagreement," "markers") an operator does not model.
- **Resolution:** Led each ledger reference with the behavioral guarantee (progress is recorded durably on the branch so it travels with a clone and is reconstructed on the next invocation) and kept the commit-separately and greppable properties (the operator's chosen design) without over-pinning the exact form, which T1 owns. Specified operator-facing copy in plain terms ("the driver's recorded progress in the branch history"), reserving "ledger"/"marker" for internal spec and tech-notes text.
- **Resolved by:** evidence
- **Affected decisions:** D2
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Coordinations, User Interactions

### F24: Classification is undefined when a complete or partially-stripped marker set is found

- **Agent:** junior-developer (JD-013)
- **Finding:** D8 leaves markers in history after completion, so re-invocation can find an all-done marker set or a partially-stripped one; the binary classifier's behavior for those is unstated.
- **Resolution:** A marker set in which every item is done classifies as an already-complete run (the driver reports completion and starts nothing, rather than resuming to immediate completion or restarting). A partially-stripped or internally-inconsistent marker set is a divergence and routes to the default-deny surface-and-ask (F2).
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases

### F25 (YAGNI): The durable pre-work-decision marker covers a sub-second interrupt window

- **Agent:** junior-developer (JD-014), corroborated by edge-case-explorer (EC11)
- **Finding:** The durable decision marker only earns its keep when a session stops between the decision being captured and the build dispatching; for interactive items the decision and build are one stretch. No evidence stops land in that window or that re-asking a decision is costly.
- **Resolution:** (User decision — re-ask on resume.) Dropped the durable pre-work-decision marker and the "decision recorded but build never started" inspection state; on resume, an item that needs a pre-work decision and is not done re-asks it. Reopening trigger recorded in the spec's Deferred section.
- **Resolved by:** user input
- **Affected decisions:** D13
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Alternate Flows (Resuming an in-progress item), Deferred (YAGNI)

### F26 (YAGNI): The per-mismatch bespoke option sets read as completeness inherited from the over-scoped attempt

- **Agent:** junior-developer (JD-015, JD-016)
- **Finding:** The load-bearing, evidenced behavior is the safety invariant; the tailored option menus per mismatch inherit their granularity from the deferred prior attempt, not from stated need.
- **Resolution:** Collapsed the bespoke per-mismatch menus into one uniform option set (inspect/abort to reconcile; restart, which supersedes the prior markers; and proceed-from-first-unmatched only where provably safe), while keeping and strengthening the safety invariant (F2) and the enumerated detection triggers. The "wholly different file on a foreign branch" case folds into the uniform handling.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Ledger and history disagree on resume), Edge Cases

## Minor edits

- F27: "resumed items are gated exactly as the committed ones" overclaims (a fresh review is non-deterministic); softened to "against the same criteria as the committed ones." — junior-developer (JD-011) — feature-specification.md#resuming-a-partially-complete-run
- F28: The Summary asserted 0 open items and 0 evidence-settled decisions before the review ran; counts are finalized at synthesis. — junior-developer (JD-017) — feature-specification.md#summary
- F29: "scan the branch before anything else" is circular; clarified the ordering as resolve the target branch (from `--branch` or the folder default), then scan it. — junior-developer (JD-004) — feature-specification.md#primary-flow
- F30: "Run more automated fix rounds" did not state the grant size; the option states how many rounds it grants before halting again. — user-experience-designer (UX-G) — feature-specification.md#a-run-reaches-a-state-it-cannot-settle
- F31: Reconciliation prompts named the mismatch in internal/VCS terms; each now adds a one-line plain-language cause and marks the safe (inspect/abort) option. — user-experience-designer (UX-E) — feature-specification.md#ledger-and-history-disagree-on-resume
