# Review Iteration History: Autonomous Work-Item Implementation Driver

<!--
Iterative-plan-review rounds for feature-specification.md. Spec-aware mode engaged.
Findings are in review-findings.md (F#). No feature-technical-notes.md exists.
-->

## R1: Research integration and team verification

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** research-integration (folding in the superpowers research, F1-F3), then han-core:junior-developer, han-core:adversarial-validator, han-core:on-call-engineer. han-core:evidence-based-investigator was not included: the behavioral spec contains no codebase claims (no file paths, line numbers, or symbols) to verify.
- **Findings raised:** F1, F2, F3 (research integration); F4, F5, F6, F7, F8, F9, F10, F11, F12, F13 (team).
- **Changed in plan:** Decision D14 (recast to per-role, capability-matched model selection with a capable-session precondition); Decision D8 (review-level scope check added); Decision D13 (fresh fix sub-agent with build context, can read codebase); Decision D10 (mid-fix stall discards mixed tree); Decision D17 (names stall cause, stronger-model retry); Actors and Triggers (Preconditions); Primary Flow (Review, Fix); User Interactions; Coordinations; Edge Cases and Failure Modes; Open Items (OI-1 removed, OI-2 sharpened); Deferred (YAGNI, two borrowables added).
- **Stability:** the round surfaced a major convergent cluster (three agents independently found the just-integrated per-item model tiering violated Han's cost-not-a-factor standard, rested on an undefined signal, and made an unenforceable conductor commitment). All resolved by evidence; one open item (OI-2) and the recast warranted a verification round.
- **Next step:** run a focused verification round on the recast D14 and the conductor precondition.

## R2: Recast verification

- **Mode:** team (focused verification)
- **Spec-aware mode:** engaged
- **Specialists engaged:** han-core:adversarial-validator.
- **Findings raised:** F14 (major: a Deferred item still carried pre-recast per-item-complexity and cost language); F15 (minor: "D15-class" precondition label could imply enforceability).
- **Changed in plan:** Deferred (YAGNI, adaptive-router item rewritten); Decision D14 (precondition label reworded).
- **Stability:** the verification confirmed the recast D14 resolves all three round-1 problems with no new contradiction (cost language gone, conductor reframed as an honest operator precondition, per-item tiering replaced by per-role with an operator override). The only residuals were stale text in two places, both fixed. The medium-size round cap (2) is reached.
- **Next step:** surface the one remaining open item (OI-2, the wrong-files scope fork) to the operator for a judgment call; the spec is otherwise ready for implementation planning.

## Post-round resolution (OI-2)

After the rounds, the operator chose to close OI-2 by adding a declared expected-paths field to each work item (a second companion change to the work-item producer), rather than accept the review-only gate's wrong-files blind spot. This was applied to D8, the Preconditions, the Primary Flow Verify step, the Coordinations row, and the Open Items section (review-findings.md F13). No open items remain.

## R4: Full-spec usability and consistency sweep

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** han-core:junior-developer, han-core:adversarial-validator, han-core:on-call-engineer, han-core:edge-case-explorer, han-core:user-experience-designer (a fresh usability lens, not on prior rounds). han-core:evidence-based-investigator was not included: the behavioral spec has no codebase claims.
- **Focus (operator's request):** under-specified items, inconsistencies, potential risks, and missing functionality critical to skill usability.
- **Findings raised:** F19-F42 (F19-F37 major, F38-F42 minor). Strong convergence: the HITL-proceed build/fix gap was flagged by four agents independently; the planning-artifact identification/ordering and the cross-item-regression recovery by two each.
- **Changed in plan:** Decisions D24, D25 (new full); Decisions D6, D7, D8, D12, D13, D14, D15, D17, D18, D19, D20, D21, D22 (extended or recast); the spec was rewritten in full to integrate the run-preparation ordering, the split HITL proceed paths, durable skip/defer, declared-skill validation, review-call stall coverage, cross-item-regression recovery, the clean-stop signal mechanism, and a cluster of usability additions (run-status visibility, the plan preview, a consistent escalation frame, and an actionable completion summary).
- **Two operator decisions:** add a plan-preview-and-confirm step (D25); descope the proactive per-item model override, keeping the whole-run override and the stall retry-on-a-stronger-model (D14, Deferred).
- **Stability:** the sweep was deliberately broad and surfaced a large batch on the R3-era additions (multi-skill, workspace prep) that prior rounds had not attacked. All major findings resolved by evidence or the two operator decisions; no open items remain. The large-size round cap (3) was not exhausted; the breadth came from the five-lens roster rather than repeated rounds.
- **Next step:** the spec is ready for implementation planning.

## R6: Skill-to-sub-agent dispatch mechanism

- **Mode:** design conversation (operator question) with claude-code-guide doc verification
- **Spec-aware mode:** engaged
- **Findings raised:** F46 (the dispatch mechanism was unspecified, and D11 rested on a now-stale "sub-agents cannot nest" constraint).
- **Changed in plan:** Decision D11 (rationale and evidence updated). The behavioral spec was unchanged: its Coordinations commitment ("review runs where its panel can fan out; only the verdict returns") is still accurate and now better supported.
- **Stability:** live Claude Code docs confirm nested sub-agents are permitted as of v2.1.172, lifting the constraint the earlier D11 mechanism worked around. The clean mechanism is a review-worker sub-agent that fans out the panel as nested sub-agents (verdict only returns); skills reach workers by preloading (`skills:` on the worker agent), not by `context: fork` on the shared skills. Dispatch topology and the version floor are deferred to plan-implementation. No open items.
- **Next step:** implementation planning, with the preload-skills worker pattern and the v2.1.172 floor as inputs.

## R5: HITL interaction-structure refinement

- **Mode:** design conversation (operator-led)
- **Spec-aware mode:** engaged
- **Specialists engaged:** none (operator-directed refinement of the human-in-the-loop flow).
- **Findings raised:** F43 (decide proceed/skip before the work, not after), F44 (confirm-the-work-is-complete gate for interactive items), F45 (context guards: re-ground from the ledger after a HITL item and recommend compaction, because inline HITL work erodes orchestrator context).
- **Changed in plan:** Decision D26 (new); Decisions D6, D24 (restructured / extended); Alternate Flows (Item needs a human, rewritten into a decision gate, two proceed paths, and a context guard); User Interactions.
- **Stability:** the operator restructured the HITL flow so the keep/skip decision precedes any work, added an explicit completion checkpoint for operator-run interactive skills, and tied the durable progress ledger to a context re-grounding guard plus a compaction recommendation, which closes the loop back to the feature's original motivation (per-item context cost forcing compaction). No open items.
- **Next step:** the spec is ready for implementation planning.

## R3: Scope-clarification design conversation

- **Mode:** design conversation (not a team round)
- **Spec-aware mode:** engaged
- **Specialists engaged:** none (operator-led clarification; codebase checks confirmed the planning-skill closing messages and the AFK/interactive nature of `tdd`, `refactor`, `skill-builder`).
- **Findings raised:** F16 (multi-skill dispatch), F17 (minimum workspace preparation), F18 (planning-skill pointer to the driver).
- **Changed in plan:** Decisions D21, D22 (new full), D23 (new trivial); Decisions D6, D12, D15 (wired to the new decisions); Primary Flow (preparation step, generalized Build step); Alternate Flows (interactive-skill items take the human-needed path); Actors and Triggers (Preconditions); Edge Cases and Failure Modes; Coordinations; Deferred (YAGNI, full workspace isolation).
- **Stability:** the operator clarified three scope questions and chose the minimum workspace preparation, deferring full worktree provisioning to a possible separate reusable skill. The key insight (a disposable sub-agent cannot run an interactive skill, so interactive-skill items are inherently human-required) unified multi-skill dispatch with the existing HITL flow rather than adding a new path. No open items.
- **Next step:** the spec is ready for implementation planning. Note the interaction verified during integration: `tdd`'s one blocking point (asking for the test command) is covered by D22's up-front tooling check, so it stays AFK; and the planning-artifact first commit carries no item reference, so the resume ledger (D20) ignores it.

## R7: Review-restructuring hardening (self-contained review stage)

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** han-core:junior-developer, han-core:adversarial-validator, han-core:user-experience-designer, han-core:edge-case-explorer, han-core:on-call-engineer. han-core:evidence-based-investigator was not included: the behavioral spec has no codebase claims to verify.
- **Focus (operator's request):** the major flow change introduced in R6 (review offloaded to a self-contained stage that fans out its panel as nested sub-agents and returns only a verdict), checked for consistency, under-specification, UX, and other hidden risks.
- **Findings raised:** F47-F56 (F47-F54 major, F55-F56 minor). Strong convergence on a single theme: offloading review created a trust-and-completeness gap. The gate-completeness gap (F47) was raised by three agents; the empty/partial/non-evaluable verdict (F48) by two; the build-distrusted / review-trusted asymmetry (F49) by two; the review stage's own model gap (F52) by two.
- **Changed in plan:** Decision D27 (new full: durable review record, condensed verdict gate, spot-check, fail-closed verdict handling); Decisions D4, D8, D11, D12, D13, D14, D17, D24 (updated); the spec's Actors and Triggers, Primary Flow (Review, Fix), Edge Cases and Failure Modes, User Interactions, and Coordinations.
- **Two operator decisions:** borrow the documentation-track and ledger model from an internal precedent (`cls-grafana-server-alert`) so the review persists a full record and returns only a condensed verdict (F47), with an orchestrator spot-check added (F49); and remove the pre-nesting fallback entirely, targeting current Claude Code (F54). The operator also deprioritized the review-phase liveness signal (F50) and confirmed rejecting a commit-with-review-deferred degrade mode (F53).
- **Stability:** the round attacked exactly one change with five lenses and converged on the trust-and-completeness gap; D27 resolves it by separating the durable record (completeness, on disk) from the condensed verdict (gate input, context-cheap), which dissolved the original budget-versus-completeness tension rather than trading one for the other. No open items.
- **Next step:** the spec is ready for implementation planning. A non-convergence detector (diffing persisted review-iteration records to escalate a finding that survives a claimed fix) is recorded as an available future sharpening, not adopted (formally deferred under YAGNI in R8).

## R8: Platform-capability and simplification refinements

- **Mode:** design conversation (operator-led), with claude-code-guide capability verification
- **Spec-aware mode:** engaged
- **Findings raised:** F57-F63.
- **Capability verification:** a claude-code-guide pass confirmed against current Claude Code that (1) continuing a returned sub-agent with full context retention is GA for custom agents, (2) bounded and background-monitored dispatch, command timeouts, and scheduled wake-ups are GA, and (3) schema-enforced structured output is GA for the main session and workflows but unconfirmed for skill-dispatched sub-agents.
- **Changed in plan:** Decision D20 (recast to a committed resume ledger) and D24 (unified into it); Decision D13 (fix round now prefers continuing the original builder, the stale no-continue-primitive rejection corrected); Decision D17 (stall-tracking feasibility, in-progress-on-retry discard-and-rebuild, the explicit-command-timeout companion); Decision D12 (structured-output recorded as an implementation option); Decisions D6, D21, D26 (interactive-skill items run in the foreground; the confirm-complete gate gains a proceed-mode choice); a new Deferred (YAGNI) item (non-convergence detection); plus the spec's Primary Flow (Fix, Commit), Alternate Flows (Item needs a human; Resuming), Edge Cases, User Interactions, and Coordinations.
- **Stability:** the round folded operator simplifications and two now-resolved platform-capability questions into the spec. Two platform constraints that shaped earlier decisions had lifted (continue-a-subagent, like the nesting constraint in R6), so D13 was updated the same way D11 was; the resume mechanism was simplified to a committed ledger; and the HITL gate gained a proceed-mode choice. No new behavioral commitments were left unresolved; no open items.
- **Next step:** the spec is ready for implementation planning. Plan-implementation inputs now include the committed-ledger layout, the continue-the-builder fix mechanism (with the fresh-agent fallback), the stall-tracking and command-timeout mechanisms, and the optional structured-output mode for the building-block skills (to be verified for skill-dispatched sub-agents).

## R9: Team review of the R8 deltas

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** han-core:junior-developer, han-core:adversarial-validator, han-core:edge-case-explorer, han-core:on-call-engineer, han-core:user-experience-designer. han-core:evidence-based-investigator was not included: the behavioral spec has no codebase claims to verify. A claude-code-guide pass verified the platform's auto-compaction behavior.
- **Focus:** the R8 changes (committed resume ledger, continue-the-builder, three-mode HITL gate), checked for consistency, new gaps, and underwater rocks.
- **Findings raised:** F64-F76 (F64-F69 and F71-F74 major, F70, F75, F76 minor). Two convergent clusters dominated: continue-without-review broke the headline review promise (junior-developer, adversarial-validator, user-experience-designer), and continue-the-builder was hollow for the long-run compaction case (adversarial-validator, on-call-engineer, junior-developer, edge-case-explorer).
- **Two operator decisions:** remove the continue-without-review mode entirely (rather than guardrail it), restoring the honest "reviewed at full coverage" promise; and reframe continue-the-builder from the preferred mechanism to an optional within-session optimization with the fresh-agent path as standard.
- **Compaction verification:** confirmed against current Claude Code that auto-compaction re-injects skills only truncated (most-recent invocation, roughly 5k tokens each, 25k total) and CLAUDE.md in full, but does not preserve read-file contents or sub-agent handles verbatim, so a long orchestrator must re-read its durable ledger after a compaction. This validated the committed-ledger architecture, settled the continue-the-builder reframe (handles do not survive compaction), and drove the re-ground-after-any-compaction commitment (D26).
- **Changed in plan:** Decision D6 (continue-without-review removed, pause-after-each-review clarified, mode recorded durably); D13 (continue-the-builder reframed); D20 (per-item and ledger-only commit-failure handling, immediate skip/defer commits, scoped exclusion, unparseable-ledger handling, stable-commit-reference); D24, D9, D22 (immediate skip/defer commits, the ledger-only exception, ledger initialization); D8 (scoped exclusion); D17 (review stall keeps the verified build, command-timeout non-load-bearing); D26 (re-ground after any compaction, proceed-mode recorded before re-ground, hand-off and tip timing); plus the spec's Alternate Flows, Primary Flow (Verify), Edge Cases, and User Interactions.
- **Stability:** the round attacked the R8 deltas with five lenses plus a platform verification. The two headline R8 mechanisms were both corrected (one removed, one demoted to an optimization); the committed-ledger model was hardened against its new failure modes (commit rejection, skip timing, initialization, corruption, the scope blind spot); and the compaction story was closed by making the ledger the re-ground authority at every boundary. No open items.
- **Next step:** the spec is ready for implementation planning.

## R10: Independent single-sub-agent review

- **Mode:** independent single-sub-agent review (a general-purpose opus sub-agent dispatched from the main session, applying the `iterative-plan-review` spec-aware lens, persisting a full review to a document and returning a condensed structured verdict), followed by operator-directed resolution.
- **Spec-aware mode:** engaged.
- **Context:** this round doubled as a live test of the spec's own review-worker pattern (D11, D27). The dispatched reviewer returned a condensed JSON verdict (gate, severity counts, findings), which is the D12/D27 contract; the prose-instructed structured return worked (the F60 baseline). The fresh-context dispatch demonstrated the bias-isolation value (D11), finding a cluster the nine prior rounds missed.
- **Findings raised:** F77-F85 (S1-S9 in the sub-agent's verdict; F77-F82 the six warnings, F83-F85 the three suggestions). The two highest-value: the headline-overclaim pattern generalized (F77 "independently verified" and F83 "built test-first," the same class F64 fixed for "reviewed at full coverage"), and the mid-run-edit data-loss path (F80).
- **Operator decision:** recast the ledger commit discipline. Rather than folding the ledger update into each item's code commit (too complex, and a barrier to a clean history), all run bookkeeping lands as separate marked, droppable commits, interleaved with clean per-item code commits, with in-progress/done bracketing for unambiguous resume; the ledger now carries the run config and branch (F82, which subsumes the S6 finding).
- **Changed in plan:** Decision D20 (ledger recast); D24, D9, D22 (aligned to the marked-commit model, config and branch in the ledger); D19 (missing-field reconciled to apply-the-fallback); D25 (reorder constrained, preview-skip durability, resume summary); D6 (mid-run edits committed durably); D7 (repair-upstream lifecycle, D20-mismatch mis-reference corrected); D27 (spot-check reframed as best-effort); plus the spec's Outcome, Summary, Primary Flow (Prepare, Confirm, Review, Commit, completion), Alternate Flows (Item needs a human; A blocker is raised; Resuming), Edge Cases, and Coordinations.
- **Stability:** an independent fresh-context pass found nine real, new issues after nine prior rounds, all resolved; the ledger recast was the one architecture change (operator-directed) and it dissolved both the S6 gap and the R9 self-referential-hash concern while giving the operator a clean-history path. No open items.
- **Next step:** the spec is ready for implementation planning.

## R11: Platform-capability correction (sub-agent resume)

- **Mode:** operator hands-on verification, followed by deferral.
- **Spec-aware mode:** engaged.
- **Findings raised:** F86.
- **Trigger:** the operator verified first-hand whether a sub-agent can be resumed with its context (the primitive R8/R9 leaned on for continuing the original builder). It is experimental: `SendMessage` belongs to the off-by-default Agent Teams feature (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) and is reported broken for plain sub-agents (GitHub #35240, #42737, #37051, #48160). This corrected the R8 doc-research claim that it was generally available, an instance of the evidence rule: a single-source doc claim overturned by hands-on verification. Findings recorded at `research/sendmessage-subagent-resume.md`.
- **Changed in plan:** Decision D13 (continue-the-builder deferred; fresh-agent is the sole fix mechanism; evidence corrected); a new Deferred (YAGNI) item with the reopen trigger; the Coordinations implementation-skill row and the compaction edge-case row (fresh agent only).
- **Open risk surfaced (not resolved this round):** the same single-source method (R6 doc-research) that backed D11's nested review-worker (a sub-agent fanning out the `code-review` panel as its own sub-agents) is the method that over-claimed the resume primitive. D11 already defers the nesting-capability check to `plan-implementation`, but R7 also removed the pre-nesting fallback on the assumption nesting is solid; that assumption now warrants the same hands-on verification, or restoring a fallback. Flagged to the operator.
- **Stability:** a focused, hands-on correction of one platform assumption; the affected mechanism (continue-the-builder) was already the demoted optimization, so the fix is a clean deferral with no ripple into the standard fix path. One open risk (D11 nesting) surfaced for the operator's decision.
- **Next step:** decide whether to verify or hedge D11's nested review-worker; otherwise the spec remains ready for implementation planning.

## R12: Review-worker nested-panel review

- **Mode:** review-worker with a fanned-out nested panel, the spec's own D11/D27 topology exercised live, followed by operator-directed resolution. A dispatched review-worker sub-agent fanned out a five-lens `han-core` panel as its own nested sub-agents (junior-developer, adversarial-validator, edge-case-explorer, on-call-engineer, user-experience-designer), reconciled their findings, and returned a condensed structured verdict.
- **Spec-aware mode:** engaged.
- **Topology validated:** nested dispatch worked on the default platform (`nesting_worked: true`, five panel agents); the full-review-to-doc plus condensed-JSON-return is the D12/D27 contract. The nested panel substantially outperformed the R10 single-agent pass, finding 4 Criticals and 12 Warnings it missed, concentrated on the late-round state-reconciliation machinery (the R10 ledger recast, F81/F82), live evidence for D11's panel-over-single-reviewer claim. The D11 nesting open risk from R11 is thereby also retired (the operator had independently confirmed nesting works).
- **Findings raised:** P1-P22 (4 Critical, 12 Warning, 6 Suggestion) in the panel verdict.
- **Resolved this round (operator reframe):** the four Criticals and three related findings, recorded as F87-F90. The operator reframed rather than built the machinery the Criticals exposed: repair-upstream drops the rebuild dance for an in-context fix with optional fixup/autosquash (F87, P1-P3); resume reconciliation becomes a judgment, inspect, decide, ask if unclear, instead of trusting a marker-plus-commit pattern (F88, P4); one-commit-per-item becomes a target not an invariant and resume inspects rather than blindly discards, protecting hand-built work (F89, P6/P16); and the done-marker-failure wording is corrected (F90, P7).
- **Changed in plan (reframe):** Decision D7 (repair-upstream reframed); D9 (single-commit as target); D10 (inspect-decide-ask, hand-built-work protection); D20 (judgment-based reconciliation); plus the spec's Alternate Flows (A blocker is raised; Resuming) and Edge Cases.
- **Folded in (same round):** the operator folded thirteen of the remaining fifteen (F91-F103) and deferred two under YAGNI (F104 a concurrent-invocation guard, F105 a systematic-review-failure diagnosis). The thirteen cover the clean-stop dispatch boundary and stop acknowledgement (F91, F97), the cleanup rebase deleting the ledger or planning commits (F92, F93), resume re-checking the green suite (F94), preparation mutating before the gates (F95), mid-run command-execution failure (F96), and a cluster of overclaim and inconsistency fixes (F98-F103).
- **Changed in plan (fold-in):** Decision D18 (stop before each dispatch, ack on receipt); D20 (cleanup at full completion, distinct planning marker, missing-branch resume); D6 (distinct planning marker); D10 (resume green-suite re-check); D22 and D25 (read-only-before-mutate ordering, decline option); D8 (command-execution failure); D1 (compaction-cost scope); D12 (red-to-green build-specific); D7 (continue split); D24 (self-owned skip); plus the spec's Outcome, Primary Flow (Prepare, Confirm, completion), Alternate Flows, Edge Cases, User Interactions, and two Deferred (YAGNI) items.
- **Next step:** the four Criticals and thirteen of the remaining findings are resolved, two deferred; the spec is ready for implementation planning.

## R13: The re-grounding routine and its durable trigger

- **Mode:** design conversation (operator-led), with claude-code-guide capability verification.
- **Spec-aware mode:** engaged.
- **Question:** where the post-compaction re-ground reminder lives so a compaction that truncates the skill cannot erase it, and how the orchestrator should recognize a pause/resume-after-time re-entry rather than misread it as a cold start.
- **Findings raised:** F106.
- **Capability verification:** a claude-code-guide pass (recorded at `research/re-grounding-after-compaction.md`) confirmed neither Claude Code nor Codex has a compaction-surviving session-local memory; skills re-inject only truncated (so a skill-body reminder is unreliable); lifecycle hooks (SessionStart/PreCompact/PostCompact) are GA on both targets; and git config holds a branch-scoped value durably outside the working tree and commit history.
- **Operator design:** store the run-active marker in version-control config (the operator's branch-config idea, refined to a custom key to avoid colliding with the conventional branch description), guarded by a conditional hook so it injects only when a run is active. Name the routine "re-grounding."
- **Changed in plan:** Decision D26 renamed to "The re-grounding routine" and generalized, the name, three triggers (compaction, resume-after-pause, inline human-required work), the procedure, and the durable conditional trigger (version-control-config marker plus a bundled conditional hook), with the marker/hook mechanics left to plan-implementation. Plus the spec's Alternate Flows (the HITL context guard, framed as the routine) and two Edge Cases (auto-compaction, and pause/resume). A research file was added.
- **Stability:** closed the bootstrap hole in the prior compaction commitment (the re-ground reminder was itself compaction-vulnerable) and named the resume pattern so the orchestrator does not misread a resumed message as a cold start. The durable trigger is portable (both targets share the hook model and plain git config) and conditional (never fires when idle). No open items.
- **Next step:** the spec is ready for implementation planning; the marker key and hook are plan-implementation inputs.

## R14: Fresh team-mode review via a review-worker nested panel

- **Mode:** team (dispatched through a review-worker sub-agent that fanned out a nested spec-aware panel; the spec's own review topology exercised live again, as in R12).
- **Spec-aware mode:** engaged.
- **Question:** with the spec near done, does a fresh team find new soundness holes, contradictions, underspecification, UX gaps, or unhandled failure modes the prior rounds missed?
- **Panel:** `han-core:junior-developer`, `han-core:adversarial-validator`, `han-core:edge-case-explorer`, `han-core:user-experience-designer`, `han-core:on-call-engineer` (the spec-aware roster; `han-core:evidence-based-investigator` again not required, no codebase claims). The worker reported nesting worked with all five panel agents.
- **Findings raised:** F107-F140 (one Critical, F107; nineteen Major; fifteen Minor in the worker's own count, recorded here as F108-F126 major and F127-F140 minor after dedup and the W23-into-F125 merge).
- **Resolution split:** thirty-one of the thirty-five deduped findings were folded (W23's missing-marker fail-open angle merged with W19 into F125); three were declined and one deferred to plan-implementation. Declined: F112 (mid-run structural work-items edit, covered by the platform's forced re-read on the next write), F115 (guarding the orchestrator's own hanging git operations, over-guarding), F116 (bounding a no-progress re-grounding loop, not a realistic oscillation); deferred: F138 (idempotent/keyed markers, an implementation detail whose behavioral invariant D20's reconciliation already implies).
- **Changed in plan:** the Critical (F107) moved the repair-upstream `--fixup`/`--autosquash` attribution to the end-of-run cleanup, unifying all history rewrites under one completion-only rule so a mid-run rewrite cannot dangle the ledger's recorded commit references (D7, D20). Two clusters the late rounds reshaped without fully re-checking were hardened: ledger reference integrity under history rewrite (F107, F109) and the R13 re-grounding machinery (the marker lifecycle F113, mid-run re-grounding fail-closed F114, durable per-item state across compaction F117/F118, the compaction-during-interview case F111). Plus HITL proceed-path completeness (F110, F121, F125, F126), start-precondition consistency (F119, F120, F130, F131, F132), and a band of UX and resume refinements (F122-F124, F127-F129, F133-F137, F139, F140). Decisions touched: D5, D6, D7, D8, D9, D10, D15, D18, D19, D20, D21, D22, D24, D26. No new decisions; the evidence/user-input decision counts are unchanged.
- **Stability:** the spec holds at its headline invariants (no commit without verify and review, the ledger drives resume, one gate-cleared commit per item); the round closed seams rather than reopening structural decisions. No open items.
- **Next step:** the spec is ready for `plan-implementation`; the marker key, the bundled hook, the active-attention-signal mechanism, and the marker idempotency/keying (F138) are plan-implementation inputs.

## R15: Fresh large-team review of the near-final spec

- **Mode:** team (five `han-core` specialists dispatched directly in parallel, each with a domain-scoped, spec-aware, prior-findings-aware brief instructing it to find only genuinely new seams and not re-raise any of F1–F140).
- **Spec-aware mode:** engaged.
- **Panel:** `han-core:junior-developer`, `han-core:adversarial-validator`, `han-core:on-call-engineer`, `han-core:edge-case-explorer`, `han-core:user-experience-designer`. `han-core:evidence-based-investigator` again not required: a grep of the spec body found no codebase claims (no source-file paths, line numbers, or `src/`-style references).
- **Question:** at 14 rounds and "ready for implementation," does a fresh five-lens team find soundness holes, contradictions, underspecification, UX gaps, or unhandled failure modes the prior rounds missed?
- **Findings raised:** F141–F163 (F141–F156 major including one Critical, F141; F157–F163 minor). Strong convergence: the mid-item compaction / transient-state seam was hit independently by junior-developer, on-call-engineer, and adversarial-validator (folded into F143); the end-of-run-cleanup-erases-the-override-audit contradiction by junior-developer and on-call-engineer (F142).
- **Four operator decisions (R15 questions):** repair-upstream hardened to the middle path (the folded-commit review gets both items' context and the upstream done marker is annotated, F148/F149); the re-grounding hook-distribution evidence flag accepted as a plan-implementation verification input with no fallback added (F151, consistent with the R7 no-fallback reasoning); the by-design-red-baseline path deferred under YAGNI with remedy-text added to the refusal (F156); and the D27 spot-check given a testable shape (a record/verdict disagreement escalates as a review failure, F163).
- **Changed in plan:** the Critical (F141) makes a defer or any continue-the-run blocker exit return the tree to the last clean committed baseline before the next item, restoring the D2 isolation invariant. A transient-state-durability cluster (F143) commits a received stop, a pending escalation, an accepted cross-slice escape, and a re-review record location immediately, and confirms the interrupted interview as the one state re-grounding still cannot reconstruct. Compaction handling was extended to mid-item and mid-preparation (F144, F145, with idempotent preparation re-entry); an errored/unusable dispatch return is classified as an environment problem (F146); interactive multi-commit and post-commit-fix cases review the cumulative diff and record a commit range (F147); a zero-overlap ledger gets a start-fresh-run option (F150); an abandon affordance clears the marker and the stopped-run hand-off names its forward actions (F152); and a band of confirm-gate, preview-skip-cascade, escalation-frame, HITL-menu, and resume-disclosure UX fixes landed (F153–F162). Decisions touched: D5, D6, D7, D8, D9, D10, D17, D18, D20, D22, D24, D25, D26, D27. A Deferred (YAGNI) entry was added for the operator-confirmed red-baseline path. No new decisions; the evidence/user-input decision counts are unchanged.
- **Stability:** even at 14 prior rounds the fresh five-lens team surfaced 23 real new findings (one Critical), concentrated in the seams *between* the well-reviewed clean-stop, compaction, re-grounding, and ledger mechanisms — evidence the spec's own panel-over-single-reviewer thesis still holds. The round closed seams rather than reopening structural decisions; the headline invariants (no commit without verify and review, the ledger drives resume, one gate-cleared commit per item, all history rewrites at completion only) hold, and the isolation invariant broken by the defer path (F141) was restored. No open items.
- **Next step:** the spec is ready for `plan-implementation`. Plan-implementation inputs now additionally include: hands-on verification that the bundled re-grounding hook installs and fires (F151), the marker/ledger idempotency and immediate-commit discipline for transient state (F143), and the folded-commit review-context and done-marker-annotation mechanics for repair-upstream (F148/F149).
