# Review Findings: Autonomous Work-Item Implementation Driver

<!--
Iterative-plan-review findings for feature-specification.md. Spec-aware mode engaged.
This file's F# counter is independent of team-findings.md (the plan-a-feature review).
No feature-technical-notes.md exists; no finding cites a T# ID.
Rounds are recorded in review-iteration-history.md.
-->

## Major findings

### F1: Model-selection default should be explicit tiering, not session-model inheritance

- **Agent:** research-integration (superpowers research + its adversarial validation)
- **Category:** behavioral commitment change
- **Finding:** The spec's provisional default (D14, OI-1) was to inherit the operator's session model. The superpowers research showed an unnamed sub-agent model silently resolves to the session's most expensive model (one real run put all 26 reviewers on the top tier), and that a cheap-model controller collapses on quality-versus-plan conflicts.
- **Evidence considered:** `research/superpowers-patterns.md` (S1, S2, S4, S5; Anthropic tiered-orchestration guidance W2/W3), adversarially validated (recast for Han's named-agent architecture per V5).
- **Resolution:** Recast D14 to "explicit per-item model tier by complexity, operator override, conductor on a capable model," superseding the inherit default; removed OI-1; updated the User Interactions affordance and the Deferred adaptive-router item.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D14 (renamed to "Model selection policy"); User Interactions; Deferred (YAGNI); Open Items (OI-1 removed)

### F2: Fix-round mechanism should be a fresh fix sub-agent with curated context, not a long-lived agent

- **Agent:** research-integration (superpowers research, validation V1)
- **Category:** mechanic correction (behavioral commitment unchanged)
- **Finding:** D13 presented "long-lived agent per item" and "reconstructed context bundle to a fresh agent" as equal implementation options. The research found a working implementation re-dispatches a fresh fix sub-agent with curated context (report + diff), and that no continue-agent primitive exists, so the long-lived-agent path is not realistically available.
- **Evidence considered:** `research/superpowers-patterns.md` (S8; validation V1 corrected the explorer's "same subagent" misread).
- **Resolution:** Sharpened D13 to lead with the curated-context fresh-agent mechanism and added the long-lived-agent path as a rejected alternative the platform does not support. The behavioral requirement (context-informed, re-verified fixes) is unchanged.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D13

### F3: Scope policing has a review-level baseline with a named wrong-files blind spot

- **Agent:** research-integration (superpowers research, validation V10)
- **Category:** coordination / edge-case rule
- **Finding:** OI-2 framed the scope-check baseline as undecided. The research showed a working implementation polices scope purely at review time (a diff-first review budget plus a "nothing extra" spec-compliance check) with no declared file-scope field, and that this has a structural blind spot: it cannot catch correct behavior written in the wrong files.
- **Evidence considered:** `research/superpowers-patterns.md` (S9, S10; validation V10).
- **Resolution:** Extended D8 to add the review-level "nothing extra" check as the baseline scope-policing mechanism and named the wrong-files blind spot; reframed OI-2 to the concrete fork (review-level gate alone, or add a declared expected-paths field to close the gap at the cost of a second companion change). OI-2 remains open pending the operator's choice.
- **Resolved by:** evidence (fork surfaced to the operator)
- **Raised in round:** R1
- **Changed in plan:** Decision D8; Open Items (OI-2)

### F4: D14's per-item cost tiering violated Han's standard, rested on an undefined signal, and overshot YAGNI

- **Agent:** junior-developer, adversarial-validator, on-call-engineer (convergent)
- **Category:** behavioral commitment change
- **Finding:** The F1 recast set the model per item from "complexity." Three problems: (1) the "cheaper tier" framing violates Han's own standard ("Cost is not a factor in model selection; choose based on what the task demands, not price"); (2) the per-item complexity signal is undefined and circular (the work-item format has no complexity field, and complexity is not known before the item is built); (3) per-item tiering is YAGNI versus Han's existing per-role convention, which achieves the same lesson (no silent inheritance) more simply.
- **Evidence considered:** `han-plugin-builder/.../agent-model-selection.md` (cost-not-a-factor rule); the work-item template (no complexity field); Han agents are tiered per role; research W4 (ecosystem converges on fixed-tier-per-role).
- **Resolution:** Recast D14 to per-role, capability-matched, explicit (not inherited) model selection for the build and fix sub-agents, with an operator override per run or per item; review models are the `code-review` skill's concern; cost framing removed. This also dissolved the "heaviest review" and fix-tier ambiguities (review is code-review's; fix uses the build dispatch).
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D14 (recast); User Interactions; Deferred (YAGNI)

### F5: "Conductor runs on a capable model" was an unenforceable behavioral commitment

- **Agent:** junior-developer, adversarial-validator, on-call-engineer (convergent)
- **Category:** failure mode / unstated dependency
- **Finding:** The skill runs in the operator's session (D11), so the conductor's model is the session model; the skill cannot set or enforce it. The F1 recast asserted "conductor on a capable model regardless," which is a phantom fix: it fails silently if the operator runs on a weak session model, the exact controller-collapse failure the research warned about (S5).
- **Evidence considered:** D11 (driver runs as a main-loop skill); `agent-model-selection.md` (skills have no model field); research Remaining Risk 5.
- **Resolution:** Reframed the conductor-capability requirement as an operator precondition (D15-class) in Actors and Triggers and in D14, rather than a behavior the skill guarantees.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Actors and Triggers (Preconditions); Decision D14

### F6: Review-level scope policing was invisible in the Primary Flow, and the review dispatch context was unstated

- **Agent:** junior-developer
- **Category:** coordination
- **Finding:** D8 added a review-level "nothing extra" scope check, but the Primary Flow Review step described only quality review, and neither it nor the Coordinations row said the review dispatch includes the work item (which the scope check requires).
- **Evidence considered:** D8 (scope check added); Primary Flow step 2.iii; D12 (build dispatch context is explicit, review's was not).
- **Resolution:** Updated the Primary Flow Review step to state the review receives the work item and the spec sections it references and checks both code quality and that the change does not exceed what the item asked for.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (Review)

### F7: The fix dispatch was missing from the Coordinations table

- **Agent:** junior-developer
- **Category:** coordination
- **Finding:** Primary Flow dispatches a fix sub-agent (D13), but the Coordinations table listed only the build and review dispatches.
- **Evidence considered:** Primary Flow step 2.iv; D13; Coordinations table.
- **Resolution:** Extended the `tdd` Coordinations row to note that each fix round reuses the build dispatch with the original build context.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Coordinations

### F8: OI-2 understated the wrong-files failure and the D8 extension cost

- **Agent:** adversarial-validator
- **Category:** edge-case rule
- **Finding:** OI-2 framed the scope baseline as a neutral fork, but the wrong-files failure (correct behavior in the wrong module, passing tests and review, committed undetected) is a real blind spot in every item, and adding an expected-paths field later requires a new check direction in D8 that an implementation could foreclose.
- **Evidence considered:** D8 exclusion logic; research V10; the work-item format.
- **Resolution:** Strengthened OI-2 to name the concrete worst case and to add the caveat that the changed-file inspection should leave a hook for an expected-paths check direction.
- **Resolved by:** evidence (the fork itself surfaced to the operator, see F13)
- **Raised in round:** R1
- **Changed in plan:** Open Items (OI-2)

### F9: The mid-fix stall tree-state was undefined

- **Agent:** on-call-engineer
- **Category:** failure mode
- **Finding:** D10's discard-and-rebuild covered "mid-build" interruptions; a stall during a fix round leaves the original build plus a partial fix in the tree, and the spec did not say to discard that mixed state, risking a commit from a corrupted tree.
- **Evidence considered:** D10 (mid-build only); D17 (retry the item); D5 (fix loop).
- **Resolution:** Extended D10 and the "Operator interrupts mid-item" edge case to treat a mid-fix stall the same as a mid-build interruption (discard all uncommitted work, rebuild).
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D10; Edge Cases and Failure Modes

### F10: Stall handling did not distinguish a turn-cap exhaustion from an operational hang

- **Agent:** on-call-engineer, adversarial-validator
- **Category:** failure mode
- **Finding:** D17 offered the same retry/skip/stop options for every non-return; an operator retrying a turn-cap-exhausted sub-agent at the same model hits the same failure.
- **Evidence considered:** D17; research Remaining Risk 1 (maxTurns behavior unverified).
- **Resolution:** D17 now names the stall cause where identifiable and offers a retry on a stronger model. The platform's turn-cap abort behavior is left to implementation.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D17

### F11: The fix-round curated context could be insufficient for cross-cutting findings

- **Agent:** adversarial-validator
- **Category:** failure mode
- **Finding:** D13 framed the fix context as the build report plus the diff, which cannot address review findings about cross-cutting patterns; such a finding would churn the fix loop to its cap for lack of context, not because it is unfixable.
- **Evidence considered:** D13; D7 escalation.
- **Resolution:** Broadened D13 so the fix sub-agent can also read the codebase for findings that reach beyond the change, and noted that a finding it cannot resolve within the cap escalates like any other.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Decision D13; Primary Flow (Fix to the gate)

### F12: Two research borrowables had no recorded disposition

- **Agent:** junior-developer
- **Category:** YAGNI candidate
- **Finding:** The research recommended a pre-flight conflict scan and a final whole-run review; neither was integrated nor recorded, leaving a paper-trail gap. On-call flagged the final review as a likely YAGNI candidate.
- **Evidence considered:** research S16, S18; existing D19 (graph validation), D7 (run-time escalation), and the per-item review.
- **Resolution:** Added both to the Deferred (YAGNI) section with reasoning (existing mechanisms cover the need; no measured gap) and reopening triggers.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Deferred (YAGNI)

### F13: OI-2 fork needs the operator's decision

- **Agent:** adversarial-validator (escalation)
- **Category:** coordination / open item
- **Finding:** Whether to close the wrong-files gap with a declared expected-paths field (a second companion change to the work-item producer) or accept the gap with the review-level gate is a judgment only the operator can make.
- **Evidence considered:** F8; research V10.
- **Resolution:** Surfaced to the operator. The operator chose to add a declared expected-paths field to each work item (a second companion change to the work-item producer), closing the wrong-files gap deterministically. D8, the Preconditions, the Primary Flow Verify step, the Coordinations row, and the Open Items section were updated; OI-2 is closed.
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Decision D8; Actors and Triggers (Preconditions); Primary Flow (Verify); Coordinations; Open Items (OI-2 closed)

### F14: A Deferred (YAGNI) item still carried pre-recast per-item-complexity and cost language

- **Agent:** adversarial-validator
- **Category:** behavioral commitment consistency
- **Finding:** The verification pass found the "Adaptive, automatically-routed per-task model-selection policy" Deferred item still said the skill "picks a model tier per item by complexity," referenced the "cheapest adequate model," and reopened on "per-item tiering," all contradicting the recast D14 (per-role, capability-matched, no cost framing).
- **Evidence considered:** the recast D14; Han's cost-not-a-factor standard.
- **Resolution:** Rewrote the Deferred item to describe per-role explicit selection with an operator override and a deferred automatic router, removing the per-item-complexity and cost language.
- **Resolved by:** evidence
- **Raised in round:** R2
- **Changed in plan:** Deferred (YAGNI)

### F16: The driver should support more than one implementation skill, with interactivity determining the autonomous path

- **Agent:** design conversation (operator)
- **Category:** behavioral commitment
- **Finding:** The spec assumed every item builds with `tdd`. Real features have items that restructure code (`refactor`) or author a skill/agent (`skill-builder`, `agent-builder`). A disposable sub-agent cannot run an interactive skill, so an item whose skill interviews or asks as it goes cannot be driven autonomously.
- **Evidence considered:** `tdd` is AFK; `refactor` is gated/interactive; `skill-builder`/`agent-builder` are interview-driven; the sub-agent dispatch model (returns once, no interaction).
- **Resolution:** Added D21: an optional per-item implementation skill (default `tdd`); the driver auto-drives only non-interactive skills in a sub-agent and treats an interactive-skill item as human-required (the D6 pause flow). Wired into D6, D12, and the Build and human-needed flows.
- **Resolved by:** user input
- **Raised in round:** R3
- **Changed in plan:** Decision D21 (new); Decisions D6, D12; Primary Flow (Build); Alternate Flows (Item needs a human); Coordinations

### F17: The skill needs minimum workspace preparation before the loop

- **Agent:** design conversation (operator)
- **Category:** behavioral commitment
- **Finding:** The spec assumed an already-prepared working tree. A run needs a branch to commit onto and working tooling to verify against, and it should not refuse over the operator's uncommitted planning artifacts. Full worktree provisioning is a heavier, reusable concern.
- **Evidence considered:** operator direction (do branch, tooling check, spec commit; defer full worktree to a separate reusable skill); superpowers factors isolation into a separate `using-git-worktrees` skill; D15.
- **Resolution:** Added D22 (minimum preparation: branch, tooling check, planning-artifact first commit) and deferred full workspace isolation to a candidate separate skill. Relaxed D15 so the run's planning artifacts do not block. Added a preparation step to the Primary Flow, an Edge Cases row, and a Deferred (YAGNI) item.
- **Resolved by:** user input
- **Raised in round:** R3
- **Changed in plan:** Decision D22 (new); Decision D15; Primary Flow; Actors and Triggers (Preconditions); Edge Cases and Failure Modes; Coordinations; Deferred (YAGNI)

### F18: The work-item producer should recommend the driver as the next step

- **Agent:** design conversation (operator)
- **Category:** coordination
- **Finding:** `plan-work-items` closes with "review the breakdown, then start the first AFK work item," with no pointer to an autonomous driver. When the driver ships, that recommendation should offer it.
- **Evidence considered:** `plan-work-items` SKILL.md closing message; the planning-to-coding handoff chain.
- **Resolution:** Added D23 (trivial): the work-item producer's closing recommendation offers the driver, a companion change alongside the marker (D6) and expected-paths (D8) changes. Recorded in the Coordinations table.
- **Resolved by:** user input
- **Raised in round:** R3
- **Changed in plan:** Decision D23 (new, trivial); Coordinations

### F19: The HITL "proceed" path has no working build or fix-context route

- **Agent:** junior-developer, adversarial-validator, edge-case-explorer, user-experience-designer (convergent, R4)
- **Category:** behavioral commitment / failure mode
- **Finding:** "Proceed continues like any other item" is wrong for two cases: a decision-needed item with a non-interactive skill has no build yet (nothing to verify), and an interactive-skill item has no implementer build report to feed the fix loop's "original build context" (D13). The pre-proceed step (where the operator records the decision) was also undefined.
- **Resolution:** Split the proceed exit: a decision-needed AFK item runs the full per-item loop (build with the operator's decision as context); an interactive-skill item continues from the operator's committed changes (no build dispatch), and its fix rounds work from the work item, diff, and codebase. Named the pre-proceed expectation and the unchanged-tree flag. Updated D6, D13, the alternate flow, and an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D6; Decision D13; Alternate Flows (Item needs a human); Edge Cases and Failure Modes

### F20: Skip and defer decisions are lost across a session boundary

- **Agent:** adversarial-validator, junior-developer (R4)
- **Category:** failure mode
- **Finding:** The resume ledger (D20) is commit-based; a skipped or deferred item never gets a commit, so on resume it looks identical to an item never started and would be re-attempted, contradicting D6.
- **Resolution:** Added D24: skip and defer choices are recorded durably and honored on resume (re-surfaced when the blocking reason may have changed), not silently re-built or silently skipped forever. Updated the resume and HITL flows.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D24 (new); Decision D20; Alternate Flows (Item needs a human; Resuming)

### F21: Planning-artifact identification is undefined and ordered after the clean-tree check

- **Agent:** adversarial-validator, edge-case-explorer, junior-developer (convergent, R4)
- **Category:** inconsistency
- **Finding:** D15/D22 commit "the run's planning artifacts" without defining which files, and the Primary Flow committed them before checking for unrelated uncommitted changes, so unrelated work would be folded into the first commit.
- **Resolution:** Defined the planning artifacts as the files the work items reference plus the work-items file; reordered preparation so the unrelated-change check precedes the planning-artifact commit. Updated D15, D22, the Primary Flow, Preconditions, and the dirty-tree edge case.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D15; Decision D22; Primary Flow; Actors and Triggers (Preconditions); Edge Cases and Failure Modes

### F22: A non-implementation AFK skill commits nothing silently

- **Agent:** edge-case-explorer (R4)
- **Category:** risk / data loss
- **Finding:** An item declaring an AFK-but-non-implementation skill (e.g. `code-review`) passes D21's interactive filter, produces no code, and the gate clears on an empty diff, marking the item "done" with no work.
- **Resolution:** D21 now requires the declared skill to be a code-producing implementation skill; D19 rejects an invalid skill up front, and a build producing zero file changes is escalated, not committed. Updated D21, D19, the Build step, and edge-case rows.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D21; Decision D19; Primary Flow (Build); Edge Cases and Failure Modes

### F23: A review-call stall is not covered by the stall handling

- **Agent:** on-call-engineer (R4)
- **Category:** failure mode
- **Finding:** D17 covered sub-agent and verification-command stalls, but the review runs as a main-loop skill call (D11) that fans out its own panel, a third and heaviest category, with no recovery path if it hangs.
- **Resolution:** D17 now names the review skill call as a covered stall category. Updated D17 and the stall edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D17; Edge Cases and Failure Modes

### F24: A committed earlier item breaking a later item has no recovery path

- **Agent:** adversarial-validator, on-call-engineer (R4)
- **Category:** failure mode
- **Finding:** The green-suite check is only at start; a later item's verification can fail because of a regression in an already-committed earlier item, which no fix to the current item can resolve, and the blocker options had no "repair the earlier item" path.
- **Resolution:** Added a cross-item-regression edge-case row (escalation evidence distinguishes which tests were green at the earlier commit) and a "repair an already-committed earlier item and resume" blocker-exit option routed through D20's mismatch path. Updated D7 and the edge cases.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D7; Alternate Flows (A blocker is raised); Edge Cases and Failure Modes

### F25: The clean-stop affordance has no signal mechanism

- **Agent:** junior-developer, user-experience-designer (R4; UX's top day-one gap)
- **Category:** under-specified / usability
- **Finding:** D18 defined what happens after a stop signal but never how the operator sends one, leaving a hard interrupt (which lands in discard-and-rebuild) as the only real option.
- **Resolution:** D18 now commits to a behavioral mechanism: the operator can send a stop request at any time; the skill checks for a pending request at each item boundary and finishes the current item to its gate before halting. Updated D18, the alternate flow, and User Interactions.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D18; Alternate Flows (Operator stops the run cleanly); User Interactions

### F26: The compact report contract is tdd-specific

- **Agent:** adversarial-validator, edge-case-explorer (R4)
- **Category:** inconsistency
- **Finding:** D12 required "test-failure-then-pass evidence," which is meaningless for the non-tdd implementation skills D21 now allows.
- **Resolution:** D12 now treats status, files changed, final gate result, and escalation as common to all skills, with the failure-then-pass evidence required for `tdd` and N/A otherwise. Updated D12 and the Build step.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D12; Primary Flow (Build)

### F27: The expected-paths value format and rename handling are undefined

- **Agent:** edge-case-explorer (R4)
- **Category:** under-specified
- **Finding:** The expected-paths match (exact path vs directory vs glob) and the handling of renames/deletes were undefined; a strict reading would flag every directory member or every rename.
- **Resolution:** D8 now commits that a file or any file under a declared directory matches, that a deleted declared path is in-scope, and that a created path outside the declared set is surfaced with rename context. Updated D8, the Verify step, and the rename edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D8; Primary Flow (Verify); Edge Cases and Failure Modes

### F28: Missing required fields and invalid skills are not validated up front

- **Agent:** junior-developer, edge-case-explorer (R4)
- **Category:** under-specified / risk
- **Finding:** D19 validated the graph but not the presence of the HITL marker and expected-paths fields or the validity of the declared skill, so missing fields would surface mid-run as undefined behavior.
- **Resolution:** D19 now validates field presence and skill validity up front, with defined fallbacks (missing marker assumes AFK with a warning; missing expected-paths asks before a review-level-only scope check). Updated D19, D8, Preconditions, and edge cases.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D19; Decision D8; Actors and Triggers (Preconditions); Edge Cases and Failure Modes

### F29: Branch conditionality risked committing to a shared mainline

- **Agent:** edge-case-explorer (R4)
- **Category:** inconsistency / risk
- **Finding:** The Primary Flow allowed running on the current branch while Coordinations said "the run works on a branch," so per-item commits could land on `main`.
- **Resolution:** D22 now commits the run to a dedicated branch (created if needed); per-item commits never land on a shared mainline by default. Updated D22, the Primary Flow, and the Coordinations row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D22; Primary Flow; Coordinations

### F30: "Tooling unavailable" and "no verification commands" conflated; partial tooling undefined

- **Agent:** junior-developer, edge-case-explorer (R4)
- **Category:** inconsistency
- **Finding:** Two edge-case behaviors (stop vs ask-and-continue) described overlapping conditions, and partial tooling availability had no defined behavior.
- **Resolution:** Distinguished "tooling unavailable" (configured commands cannot run, including any one missing tool: stop and name them) from "no verification commands configured" (ask before a scope-check-only run). Updated D22, D8, and the edge-case rows.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D22; Decision D8; Edge Cases and Failure Modes

### F31: Run-status visibility is insufficient for an unattended run

- **Agent:** user-experience-designer (R4)
- **Category:** usability
- **Finding:** The Feedback spec listed per-item phase labels but no progress counter, dispatch notification, commit reference, or preparation narration, leaving an operator who steps away unable to tell progress from a stall.
- **Resolution:** Extended the Feedback spec: preparation narration, a per-item status header with run position, a dispatch notification per sub-agent, the commit short-reference at commit time, and a one-line run summary at each item boundary.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** User Interactions (Feedback)

### F32: No plan preview before the run, and no proactive skip

- **Agent:** user-experience-designer (R4)
- **Category:** usability / missing functionality
- **Finding:** The run started immediately after validation, so the operator could not see which items are human-required before committing attention, nor skip an item they already knew was problematic.
- **Resolution:** Added D25: a plan preview after validation that lists items in order (marking human-required ones and skips) and waits for the operator to confirm, reorder, or mark items to skip. User chose "Add preview + confirm." Updated the Primary Flow and User Interactions.
- **Resolved by:** user input
- **Raised in round:** R4
- **Changed in plan:** Decision D25 (new); Primary Flow; User Interactions

### F33: Escalations have no consistent frame and the blocker options are a flat six

- **Agent:** user-experience-designer (R4)
- **Category:** usability
- **Finding:** Eight pause types used inconsistent framing and the blocker presented six flat options, increasing re-orientation cost and decision fatigue.
- **Resolution:** Added a required escalation frame (status line, one-sentence reason, explicit labeled options) and grouped the blocker options by consequence (continue / modify and retry / repair upstream / stop). Updated User Interactions and the blocker flow.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** User Interactions; Alternate Flows (A blocker is raised)

### F34: The completion state is not actionable, and an all-blocked run ends silently

- **Agent:** user-experience-designer, on-call-engineer, junior-developer (R4)
- **Category:** usability
- **Finding:** The summary was undefined (no branch name, commit refs, or next step), and a run where every remaining item is blocked would complete with no items committed and no explanation.
- **Resolution:** Specified the completion summary (branch name, per-item outcome with commit reference, next action) and committed an all-blocked run to report itself as partially complete with counts and reasons. Updated the Primary Flow, User Interactions, and an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Primary Flow; User Interactions; Edge Cases and Failure Modes

### F35: The resume-mismatch interaction is a binary confirm with no options

- **Agent:** user-experience-designer (R4)
- **Category:** usability
- **Finding:** D20's mismatch handling asked the operator to "confirm" with no real option set, insufficient for a rebase or squash.
- **Resolution:** D20 now offers proceed-from-first-unmatched, restart-from-the-beginning, or abort-to-reconcile. Updated D20 and the mismatch edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D20; Edge Cases and Failure Modes

### F36: The per-item model override was advertised but unreachable

- **Agent:** user-experience-designer (R4)
- **Category:** inconsistency
- **Finding:** D14 named a per-item model override with no mechanism.
- **Resolution:** Descoped the proactive per-item override (kept the whole-run override; the stall retry-on-a-stronger-model covers the reactive case) and moved it to Deferred. User chose "Descope to deferred." Updated D14, User Interactions, and Deferred.
- **Resolved by:** user input
- **Raised in round:** R4
- **Changed in plan:** Decision D14; User Interactions; Deferred (YAGNI)

### F37: Cross-slice acceptance is re-asked each fix round, and two accept-and-commit paths conflict

- **Agent:** adversarial-validator, junior-developer (R4)
- **Category:** under-specified
- **Finding:** A legitimate cross-slice change would be re-surfaced for acceptance on every fix round, and the "accept and commit" blocker path versus the verify-step surface were inconsistent.
- **Resolution:** D8 now holds an acceptance for the rest of the item's loop so the operator is not re-asked each round. Updated D8 and the Verify step.
- **Resolved by:** evidence
- **Raised in round:** R4
- **Changed in plan:** Decision D8; Primary Flow (Verify)

### F43: The proceed/skip decision came after the operator did the work

- **Agent:** design conversation (operator, R5)
- **Category:** behavioral commitment
- **Finding:** For an interactive-skill item, the R4 flow had the operator run the skill and only then asked proceed-or-skip, so a skip wasted the work already done; the operator might also run a manual compaction before or after, making the late skip even more awkward.
- **Resolution:** Moved the proceed-or-skip decision before any work (a decision gate at the start of the item). Skip is now meaningful and wastes nothing. Updated D6 and the alternate flow.
- **Resolved by:** user input
- **Raised in round:** R5
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human)

### F44: There was no confirmation that an interactive item's manual work was complete

- **Agent:** design conversation (operator, R5)
- **Category:** behavioral commitment
- **Finding:** After the operator ran an interactive skill, the skill resumed verify/review/commit with no explicit checkpoint that the operator considered the work done.
- **Resolution:** Added a confirm-the-work-is-complete gate after the interactive skill, before the automated verify/review/fix/commit resumes; if the operator reports the work is not done, the item stays paused or is skipped. Updated D6 and the alternate flow.
- **Resolved by:** user input
- **Raised in round:** R5
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human)

### F45: Inline HITL work erodes orchestrator context with no re-grounding guard

- **Agent:** design conversation (operator, R5)
- **Category:** behavioral commitment / risk
- **Finding:** Handling a human-required item inline (a recorded decision or an interactive skill the operator runs in-session) consumes the orchestrator's context window; without re-grounding, the orchestrator can mis-conduct the rest of the run with eroded instructions.
- **Resolution:** Added D26: the skill treats each HITL item as a context boundary, records the handling in its durable progress ledger, re-grounds from the ledger plus its own instructions and the spec, and recommends a manual compaction before and after a HITL item. Refined during R5 so the re-ground happens **at the resume point, before the orchestrator conducts the item's own verify/review/fix/commit stages** (not only at the next-item boundary), since those stages run right after the inline work erodes context. Updated D24 (the ledger is also the re-grounding anchor). This serves the feature's original context-erosion motivation.
- **Resolved by:** user input
- **Raised in round:** R5
- **Changed in plan:** Decision D26 (new); Decision D24; Alternate Flows (Item needs a human); User Interactions

### F46: The skill-to-sub-agent dispatch mechanism was unspecified, and D11 rested on a now-stale platform constraint

- **Agent:** design conversation (operator) + claude-code-guide doc verification (R6)
- **Category:** behavioral commitment / platform-constraint update
- **Finding:** How an existing skill (`tdd`, `code-review`) reaches a dispatched sub-agent was unspecified, and D11's rationale rested on "a sub-agent cannot dispatch another sub-agent." Live Claude Code docs show that constraint was lifted: as of v2.1.172 a sub-agent can spawn its own sub-agents (nested, ~5 levels). Two handoff mechanisms exist: preloading skills into a worker-agent definition (`skills:` list, dispatch-controllable, does not modify the skill) versus `context: fork` on the skill's own SKILL.md (would modify the shared skill and force every invocation to fork).
- **Evidence considered:** Claude Code sub-agents and skills documentation (fetched live); the operator's "fork on tdd is not the right choice" framing; the now-stale repo guidance (`agent-external-files.md`).
- **Resolution:** Updated D11: review runs inside a dispatched review-worker that fans out `code-review`'s panel as nested sub-agents, with only the verdict returning (cleaner than main-loop review; that remains the pre-v2.1.172 fallback). Recommended the preload-skills mechanism (lightweight worker agent types preloading `tdd` / `code-review`) over `context: fork`. The dispatch topology and the v2.1.172 version floor are recorded as `plan-implementation` inputs. The behavioral commitment (full coverage, only the verdict returns) is unchanged and better supported.
- **Resolved by:** evidence
- **Raised in round:** R6
- **Changed in plan:** Decision D11

### F47: The commit gate trusted a verdict with no completeness guarantee

- **Agent:** adversarial-validator, edge-case-explorer, junior-developer (convergent, R7)
- **Category:** behavioral commitment / risk (data integrity)
- **Finding:** The commit gate (D4) is evaluated on a verdict the review compacts twice (the panel reconciles, then the result is condensed to roughly 300 words), and nothing required that verdict to be complete at and above the threshold. On a heavy slice the budget cannot enumerate every finding, so a dropped or down-severitied Critical or Warning lets a defective item commit through a gate that reports "clear."
- **Resolution:** Added D27: the review persists a durable full record and returns a condensed verdict that is complete at and above the threshold (the budget bounds prose, not the blocking-finding count) and references the record. Completeness lives on disk, out of the driver's context, so it no longer competes with the verdict's brevity. Borrowed the documentation-track and ledger model from an internal precedent (a skill that persists a full per-item review document and threads only its path and an open-gate status through a durable state file). Updated D4, D11, D12; Primary Flow (Review); Coordinations.
- **Resolved by:** user input (the durable-record approach, with a working precedent) and evidence (convergent findings)
- **Raised in round:** R7
- **Changed in plan:** Decision D27 (new); Decision D4; Decision D11; Decision D12; Primary Flow (Review); Coordinations

### F48: An empty, partial, or non-evaluable verdict was indistinguishable from a clean pass

- **Agent:** edge-case-explorer, on-call-engineer (convergent, R7)
- **Category:** failure mode / risk (data integrity)
- **Finding:** A verdict that is empty (the panel never ran), built from a partially-failed panel, or not evaluable against the Critical/Warning/Suggestion vocabulary is structurally identical to a clean pass; the gate clears and the item commits on absent or degraded review. This is the review-side analogue of D8's verify-before-trust: a "clean" claim must be backed.
- **Resolution:** D27 requires the verdict to attest full specialist coverage; a verdict that is empty without that attestation, reports a partial panel, or cannot be evaluated against the threshold is treated as a review failure and escalated like a stall (retry, skip, or stop), never as a clean gate (fail closed). Added edge-case rows and tied the failure path into D17.
- **Resolved by:** evidence
- **Raised in round:** R7
- **Changed in plan:** Decision D27 (new); Decision D17; Edge Cases and Failure Modes

### F49: The build-distrusted / review-trusted asymmetry was unstated

- **Agent:** junior-developer, adversarial-validator (convergent, R7)
- **Category:** inconsistency / risk
- **Finding:** The spec loudly distrusts the build's "all green" and re-verifies it (D8) but silently accepts the review's "no findings," so the asymmetry reads as an omission rather than a deliberate, bounded trust boundary, and the same over-claim failure D8 was built to catch now applies to the review verdict one dispatch hop further away.
- **Resolution:** Stated the trust boundary explicitly (review is a judgment the skill cannot re-run, unlike the re-verified build; trusted as returned, bounded by the completeness requirement, the coverage attestation, the spot-check, and the per-fix re-review). Added an orchestrator spot-check of the durable record as a partial cross-check (operator's request: not a full guarantee, lowers the chance of issues). Distinguished the two actors in the Actors list. Recorded in D27.
- **Resolved by:** user input (the spot-check) and evidence
- **Raised in round:** R7
- **Changed in plan:** Decision D27 (new); Actors and Triggers; Primary Flow (Review)

### F50: The Feedback contract overpromised per-sub-agent visibility for the now-hidden panel

- **Agent:** user-experience-designer, on-call-engineer (R7)
- **Category:** usability
- **Finding:** The Feedback spec promised "a dispatch notification when each sub-agent starts" and "streams each sub-agent's compact report," which cannot hold for the review panel now nested inside the self-contained review stage; the review phase becomes a long opaque block where progressing is indistinguishable from stalled, and a liveness signal was proposed.
- **Resolution:** Operator deprioritized the legibility concern: the platform surfaces sub-agent activity to anyone who looks, and keeping review self-contained is intentional because it isolates the review from the builder-output bias the driver's context carries (added as a second rationale in D11). Scoped the Feedback promise to the sub-agents the skill itself dispatches (the review stage surfaces as its dispatch plus its returned verdict, not panel by panel); did not add a separate liveness signal.
- **Resolved by:** user input
- **Raised in round:** R7
- **Changed in plan:** Decision D11 (bias-isolation rationale); User Interactions (Feedback)

### F51: The fix sub-agent was not given the review's findings under the new topology

- **Agent:** adversarial-validator (R7)
- **Category:** under-specified
- **Finding:** D13 defined the fix context as the build report and the diff, which predate review. Previously the full review report sat in the driver's context and naturally informed the fix dispatch; now only the condensed verdict returns, so the fix agent has nothing telling it which findings to address unless they are forwarded explicitly.
- **Resolution:** The fix dispatch now carries a reference to the review's durable record (D27) alongside the build context, so the fix targets the specific blocking findings rather than re-deriving them. Updated D13 and the Primary Flow Fix step.
- **Resolved by:** user input (a link to the review document) and evidence
- **Raised in round:** R7
- **Changed in plan:** Decision D13; Decision D27 (new); Primary Flow (Fix to the gate)

### F52: The review stage's own model was an unowned gap in D14

- **Agent:** on-call-engineer, junior-developer (convergent, R7)
- **Category:** failure mode / inconsistency
- **Finding:** D14 sets the build and fix models explicitly because an unnamed dispatched sub-agent silently resolves to the most-expensive tier, but exempts "models used inside review" wholesale. The agent that hosts the self-contained review stage is a new driver-dispatched sub-agent that is neither a build/fix agent nor a panel reviewer, so it falls in the gap and would silently inherit the top tier on every item.
- **Resolution:** Extended D14's explicit-model rule to cover every sub-agent the driver itself dispatches, including the review stage's host; only the in-panel specialist reviewer models stay the `code-review` skill's concern.
- **Resolved by:** evidence
- **Raised in round:** R7
- **Changed in plan:** Decision D14

### F53: D17's stall recovery levers map poorly onto a review-domain stall

- **Agent:** on-call-engineer, junior-developer (R7)
- **Category:** failure mode
- **Finding:** D17's recovery was written for build and verify: "describes the working-tree state" is meaningless for a review stall (review writes nothing), "retry on a stronger model" cannot reach the panel (its models are `code-review`'s), and the cause is opaque two stages down. The taxonomy also double-listed "the review skill call" as distinct from "a dispatched sub-agent." On-call additionally floated a commit-with-review-deferred degrade mode.
- **Resolution:** Folded the review stage into the dispatched-sub-agent stall class; replaced the tree-state clause with what the review stage can report and acknowledged the cause may be only "review did not return"; scoped the stronger-model retry to the build and fix path; routed an untrustworthy verdict onto the same escalation path (fail closed). Rejected the degrade-in-place mode (committing unreviewed code defeats the gate that is the feature's headline value). Non-convergence detection (diffing persisted review-iteration records) was noted as an available future sharpening, not adopted now.
- **Resolved by:** user input (reject degrade-in-place; a review outage escalates) and evidence
- **Raised in round:** R7
- **Changed in plan:** Decision D17; Edge Cases and Failure Modes

### F54: D11 overclaimed the fallback and asserted a single-sourced platform state

- **Agent:** adversarial-validator (R7)
- **Category:** inconsistency / evidence quality
- **Finding:** D11 claimed the pre-nesting main-loop fallback preserved both full coverage and "only the verdict returns" (it cannot, because the panel's full output enters the driver's context there), and asserted the v2.1.172 nesting capability as settled from a single source while the in-repo guidance said the opposite.
- **Resolution:** Removed the fallback entirely (operator: target current Claude Code; the old-version population is negligible on an aggressively auto-updating platform); reframed the platform capability as an implementation-stage verification against the live documentation rather than a settled version fact, and dropped the "supersedes the now-stale guidance" framing (that reconciliation is handled separately). Keeps D11 consistent with the parallel guidance fix.
- **Resolved by:** user input
- **Raised in round:** R7
- **Changed in plan:** Decision D11

### F57: The resume ledger is simpler as a committed file than a machine-readable per-commit reference

- **Agent:** design conversation (operator, R8)
- **Category:** behavioral commitment / simplification
- **Finding:** D20 matched completed items by parsing a machine-readable reference out of each commit message and reconciling mismatches, which is fragile (commit conventions do not encode a parseable id, and a squash or rebase that rewrites messages corrupts the parse). A simpler, more robust mechanism is to commit updates to a resume ledger file that marks items done.
- **Resolution:** Recast D20 to a committed resume ledger: the same commit that lands an item's changes marks the item done in the ledger (with its commit and review-record location), skips and defers go in the same ledger, and resume reads the ledger directly. The ledger's content survives a rebase or squash, so resume no longer reconstructs completion from commit messages. The ledger file is excluded from the per-item scope check (D8). Unified D24's durable record into the same committed ledger. Updated the Primary Flow Commit step, the Resume flow, the mismatch edge case, and the Coordinations version-control row.
- **Resolved by:** user input
- **Raised in round:** R8
- **Changed in plan:** Decision D20; Decision D24; Primary Flow (Commit); Alternate Flows (Resuming); Edge Cases and Failure Modes; Coordinations

### F58: Stall tracking, in-progress-on-retry, and explicit command timeouts were under-specified

- **Agent:** design conversation (operator, R8) + claude-code-guide capability verification
- **Category:** failure mode / feasibility
- **Finding:** D17 committed to surfacing a stall and offering recovery but did not establish that the orchestrator can actually track a non-return, did not say what becomes of the item's in-progress state on a retry, and did not address the operator's idea of running sub-agent commands under explicit timeouts.
- **Resolution:** Verified against current Claude Code that bounded and background-monitored dispatch, command timeouts (Bash up to ten minutes), and scheduled wake-ups are generally available, so the stall-tracking commitment is implementable (the mechanism stays plan-implementation). Made explicit that a retry of a stalled item discards the in-progress partial work and rebuilds it (D10). Recorded the explicit-command-timeout idea as a complementary guard and a companion change to the implementation skills (so a hung command aborts inside the sub-agent rather than hanging it). Updated D17.
- **Resolved by:** user input and evidence (platform capability verified)
- **Raised in round:** R8
- **Changed in plan:** Decision D17

### F59: The fix-round mechanism can now continue the original builder

- **Agent:** design conversation (operator question, R8) + claude-code-guide capability verification
- **Category:** mechanic correction (behavioral commitment unchanged)
- **Finding:** The operator asked whether D13's fix round passes messages to the original builder sub-agent (and if so, whether that is out of beta) or works from some other context. D13 specified a fresh fix sub-agent with curated context, chosen because the research-era platform had no continue-a-subagent primitive.
- **Resolution:** Verified that continuing an already-returned sub-agent with full context retention is generally available in current Claude Code (custom agents only). Flipped D13 to prefer continuing the original builder for the fix round (it holds the build context and can read the codebase), handing it the review record's findings, with the fresh-agent-with-curated-context path kept as the fallback. The behavioral requirement (context-informed, test-backed fixes) is unchanged; the stale "no continue-agent primitive" rejected alternative was corrected. Made the Primary Flow Fix step mechanism-neutral (fresh-vs-continued is implementation).
- **Resolved by:** user input and evidence (platform capability verified)
- **Raised in round:** R8
- **Changed in plan:** Decision D13; Primary Flow (Fix to the gate); Coordinations

### F60: Structured output could make the return contract robust, if available for skill-dispatched sub-agents

- **Agent:** design conversation (operator, R8) + claude-code-guide capability verification
- **Category:** implementation option (behavioral commitment unchanged)
- **Finding:** D12 has the driver impose the compact-return contract by a prose dispatch instruction, which relies on the sub-agent obeying. The operator suggested adjusting the building-block skills to allow structured output.
- **Resolution:** Verified that schema-enforced structured output is generally available for the main session and workflows but unconfirmed for skill-dispatched sub-agents as of R8. Recorded in D12 that giving the building-block skills a declared structured-output mode is an implementation-planning option to verify, not a behavioral change; the prose-instruction contract remains the baseline.
- **Resolved by:** evidence (platform capability verified, partial)
- **Raised in round:** R8
- **Changed in plan:** Decision D12

### F61: Non-convergence detection across review iterations is deferred under YAGNI

- **Agent:** design conversation (operator, R8)
- **Category:** YAGNI candidate
- **Finding:** The `cls-grafana-server-alert` precedent diffs consecutive review-iteration records to escalate a finding that survives a claimed fix, but it needs that detector because it has no cap on its review loop. This driver's fix loop is already bounded by a configurable cap (D5) that terminates and escalates, so the detector would only escalate a few rounds earlier.
- **Resolution:** Added a Deferred (YAGNI) item with the reasoning (the cap already terminates the loop; the detector is cheap to add later now that iteration records are persisted, but no measured need justifies it) and a reopening trigger. The R7 "available future sharpening" note is now formally deferred.
- **Resolved by:** user input
- **Raised in round:** R8
- **Changed in plan:** Deferred (YAGNI)

### F62: The HITL confirm-complete gate should let the operator choose how to proceed

- **Agent:** design conversation (operator, R8)
- **Category:** behavioral commitment
- **Finding:** The verify/review/fix/commit loop is autonomous, but a human-required item by definition needs human steering. After an interactive-skill item, the skill resumed the loop fully autonomously; the operator who just did the manual work had no way to stay in the loop or to skip review on work they trust.
- **Resolution:** The confirm-the-work-is-complete gate now also asks how to proceed: finish the item autonomously, pause after each review (so the operator can steer before fix and commit), or continue without review (verify and commit on the operator's explicit say-so, skipping review for this hand-built item, an informed operator override distinct from the autonomous path, which never skips review). Updated D6, the alternate flow, and the User Interactions affordances.
- **Resolved by:** user input
- **Raised in round:** R8
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human); User Interactions

### F63: An interactive-skill item runs in the foreground, invoked by the orchestrator

- **Agent:** design conversation (operator, R8)
- **Category:** precision / under-specified
- **Finding:** The spec said "the operator runs that skill themselves," which understated the mechanism: the orchestrator invokes the interactive skill in the foreground in the operator's session, and the operator steers the interview through it. This is exactly why an interactive-skill item erodes the orchestrator's context (D26).
- **Resolution:** Reworded D6, D21, D26, and the alternate flow so the orchestrator invokes the interactive skill in the foreground and the operator steers it, rather than running it separately.
- **Resolved by:** user input
- **Raised in round:** R8
- **Changed in plan:** Decision D6; Decision D21; Decision D26; Alternate Flows (Item needs a human)

### F64: "Continue without review" broke the headline review promise and left unreviewed commits unmarked

- **Agent:** junior-developer, adversarial-validator, user-experience-designer (convergent, R9)
- **Category:** behavioral commitment / contradiction
- **Finding:** The R8 "continue without review" proceed-mode let a hand-built item commit while skipping the gate, but the Outcome, Summary, and Actors promise *every* item is reviewed at full coverage, the edge-case row says the skill "never commits unreviewed work," and D27 says committing unreviewed code "does not lower the bar." Nothing marked the unreviewed commit (the completion summary, per-item status, and ledger showed it identically to a reviewed one), and the label read like "without me watching" rather than "without the quality gate."
- **Resolution:** The operator chose to **remove** the mode rather than guardrail it. The HITL confirm-complete gate now offers two modes (finish autonomously, or pause after each review); review always runs. This keeps the Outcome/Summary/Actors "reviewed at full coverage" promise honestly true and needs no carve-out in D27, no unreviewed marker, and no new completion-summary category.
- **Resolved by:** user input
- **Raised in round:** R9
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human); User Interactions

### F65: "Continue the builder" was hollow for the long-run compaction case the feature targets

- **Agent:** adversarial-validator, on-call-engineer, junior-developer, edge-case-explorer (convergent, R9)
- **Category:** behavioral commitment / mechanic correction
- **Finding:** R8 made continuing the original builder the *preferred* fix mechanism, but the feature exists for long runs that cross compaction and session boundaries (D1, D26), and a sub-agent handle does not survive a compaction or resume (confirmed by the R9 compaction-behavior verification: skills re-injected only truncated, read-file contents and sub-agent IDs not preserved verbatim). So continuing the builder is unavailable for the common case, the fresh-agent path is the de facto primary one, and attempting to continue an unreachable builder would surface as a stall whose retry discards verified work. The fallback trigger and the custom-agent precondition were also unstated.
- **Resolution:** Reframed D13: the **fresh fix sub-agent with curated context (build report, diff, review record) is the standard, boundary-proof path**; continuing the builder is an **optional within-session optimization** taken only when the builder is still reachable, with a **silent, non-escalating fallback** whenever it is not (compaction, resume, a non-continuable agent, or a failed continuation). The builder is released once its item commits. The context-informed-fix invariant holds either way. Made the Primary Flow Fix step mechanism-neutral.
- **Resolved by:** user input and evidence (platform compaction behavior verified)
- **Raised in round:** R9
- **Changed in plan:** Decision D13; Primary Flow (Fix to the gate); Coordinations

### F66: A per-item or ledger-only commit failure had no recovery path and could discard verified work

- **Agent:** edge-case-explorer, on-call-engineer, junior-developer (convergent, R9)
- **Category:** failure mode
- **Finding:** The committed-ledger model moved a commit into every item, but only the *preparation* commit's rejection (a hook) was handled (D22). A per-item commit (or a ledger-only skip/defer commit) rejected mid-run would leave verified, reviewed work uncommitted; resume (D10) would then discard it as interrupted work, or the run would wedge or advance into a mixed tree.
- **Resolution:** D20 now treats a rejected or failed per-item or ledger-only commit as a fail-closed halt in the same class as a rejected preparation commit: surface the failure and remedy, leave the verified work in the tree, do not advance and do not discard. Added an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D20; Edge Cases and Failure Modes

### F67: Skip/defer ledger writes had undefined commit timing, and the ledger was never initialized

- **Agent:** edge-case-explorer, junior-developer (convergent, R9)
- **Category:** under-specified / failure mode
- **Finding:** A skip or defer has no code change, so the "same commit that lands the item's changes marks it done" pattern does not apply; the spec never said when the ledger edit is committed. If left uncommitted until the next item, the clean-tree check (D15) wedges; if the run stops first, the skip is lost on resume, contradicting D24. The ledger's creation point was also unstated (lazy creation at the first item's commit fails if the first reached item is skipped).
- **Resolution:** A skip or defer is committed immediately as a ledger-only commit (D20, D24); D9 names this as the ledger-only-commit exception to "one commit per completed item"; the ledger is initialized as part of the D22 planning-artifact first commit so it exists before any item.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D20; Decision D24; Decision D9; Decision D22

### F68: The ledger's scope-check exclusion was stated only in D20 and was unconditional

- **Agent:** junior-developer, edge-case-explorer (R9)
- **Category:** inconsistency / blind spot
- **Finding:** D20 excludes the ledger from the per-item scope check, but the Verify step and the generated-files edge-case row, which enumerate the exclusions, omit it (so a reader concludes the ledger is in scope). The exclusion was also unconditional, so a builder sub-agent mis-writing the ledger would pass the scope check silently.
- **Resolution:** Added the ledger to the exclusion list in the Verify step and the edge-case row; scoped the exclusion in D8 and D20 to the skill's *own* writes, so a builder writing the ledger is surfaced as a scope escape. Added an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D8; Decision D20; Primary Flow (Verify); Edge Cases and Failure Modes

### F69: An unparseable ledger on resume had no defined recovery

- **Agent:** edge-case-explorer (R9)
- **Category:** failure mode
- **Finding:** D20 handled a ledger that *disagrees with the work-items file at the item level*, but not a ledger that cannot be parsed at all (merge-conflict markers, truncation, corruption). On resume the skill could silently treat it as empty and rebuild committed work, or fail unpredictably.
- **Resolution:** D20 now treats an unparseable ledger as a fatal resume error: surface the raw content and offer abort-to-reconcile rather than guessing, because committed items may already exist on the branch. Added an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D20; Edge Cases and Failure Modes

### F71: The committed ledger was the re-ground authority on resume and around HITL items, but not after a bare mid-run auto-compaction

- **Agent:** on-call-engineer (R9), with claude-code-guide compaction verification
- **Category:** failure mode
- **Finding:** The feature exists to span compaction boundaries, but an auto-compaction that fires between items continues the same session without triggering the resume flow, and nothing required re-reading the ledger before the next dispatch. The R9 verification confirmed the platform re-injects the orchestrator's own skill instructions only truncated and does not preserve a previously-read file's contents or a sub-agent's handle verbatim, so a post-compaction orchestrator could rebuild a committed item or skip an unbuilt one, the exact failure the ledger exists to prevent.
- **Resolution:** Extended D26 so the committed ledger is the source of truth across *any* context-erosion boundary: after any compaction the orchestrator re-reads the ledger (and re-establishes its instructions) before the next item dispatch, not only on resume or around HITL items.
- **Resolved by:** evidence (platform compaction behavior verified)
- **Raised in round:** R9
- **Changed in plan:** Decision D26

### F72: D17 contradicted itself on a review stall, prescribing discard of a verified build

- **Agent:** edge-case-explorer (R9)
- **Category:** inconsistency
- **Finding:** The R8 addition to D17 ("a retry of a stalled item discards the in-progress work and rebuilds") conflicted with D17's own review-stall handling: a review stall has no tree work (the build is complete and verified, review writes nothing), so discarding would throw away a verified build.
- **Resolution:** Scoped discard-and-rebuild to build, verify, and fix stalls; a review stall re-runs the review stage only and keeps the verified build. Updated D17 and the interrupt/stall edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D17; Edge Cases and Failure Modes

### F73: "Pause after each review" had undefined semantics across a multi-round fix loop

- **Agent:** edge-case-explorer, user-experience-designer (convergent, R9)
- **Category:** under-specified / usability
- **Finding:** D6's "pause after each review" did not say whether it pauses after every round's re-review in the fix loop or only once, and set no expectation of how many pauses to anticipate or how to let the item run from there. An implementation pausing only once would silently remove the operator from later fix decisions.
- **Resolution:** D6 now states the mode pauses after every fix round's re-review until the gate clears or the cap is reached, sets that expectation, and offers at each pause to keep steering, finish autonomously, or stop.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human)

### F74: The proceed-mode choice was made in eroded context and not recorded before re-grounding

- **Agent:** adversarial-validator (R9)
- **Category:** failure mode
- **Finding:** The operator's proceed-mode choice is confirmed while the orchestrator's context is eroded by the inline interactive work (the exact state D26 mandates re-grounding from), but the choice was not recorded in the ledger, so a re-grounded orchestrator would lose it and default to a mode the operator did not pick.
- **Resolution:** D6 and D26 now record the chosen proceed-mode in the durable ledger before re-grounding, so the re-grounded orchestrator reads the mode rather than defaulting.
- **Resolved by:** evidence
- **Raised in round:** R9
- **Changed in plan:** Decision D6; Decision D26

### F77: "Independently verified" overclaims relative to the scope-check-only run

- **Agent:** independent single-sub-agent review (R10)
- **Category:** behavioral commitment / contradiction
- **Finding:** The Outcome and Summary promise every item is "independently verified," but the operator-confirmed scope-check-only run (a project with no verification commands, D8) commits items with no independent verification and marks them no differently, the same false-promise pattern F64 corrected for review's "reviewed at full coverage" claim.
- **Resolution:** Scoped the headline: items are independently verified against the project's own checks where they exist, and scope-checked with the operator's confirmation where a project has none. Updated the Outcome and Summary.
- **Resolved by:** evidence
- **Raised in round:** R10
- **Changed in plan:** Outcome; Summary

### F78: The plan-preview reorder can produce an order that violates the dependency graph

- **Agent:** independent single-sub-agent review (R10)
- **Category:** under-specified / failure mode
- **Finding:** The preview (D25) lets the operator reorder items after D19 validates the dependency graph, but nothing constrained the reorder to a valid order or re-validated it, so an operator could move a dependent ahead of its dependency and the skill's behavior was undefined.
- **Resolution:** D25 now requires a reorder to preserve the dependency order; the skill rejects, or re-sorts and re-presents, an order that would run a dependent before something it depends on. Updated D25 and the Primary Flow preview step.
- **Resolved by:** evidence
- **Raised in round:** R10
- **Changed in plan:** Decision D25; Primary Flow (Confirm the plan)

### F79: Missing-required-field handling was described as both "apply a fallback" and "refuse to start"

- **Agent:** independent single-sub-agent review (R10)
- **Category:** inconsistency
- **Finding:** The Preconditions said the driver "applies a defined fallback when one is missing" (proceed), while the edge-case row and D19 said it "refuses to start ... with the defined fallback offered" (stop); the two framings point an implementer in opposite directions.
- **Resolution:** Reconciled to apply-the-fallback: D19 refuses only on a structural error (graph malformation, invalid skill); a missing marker or expected-paths field applies the defined fallback and proceeds with a warning. Split the edge-case row into a refuse row and a fallback row.
- **Resolved by:** evidence
- **Raised in round:** R10
- **Changed in plan:** Decision D19; Edge Cases and Failure Modes

### F80: Mid-run operator edits to committed planning artifacts were unhandled, with a data-loss path

- **Agent:** independent single-sub-agent review (R10)
- **Category:** failure mode / data loss
- **Finding:** The HITL and blocker flows tell the operator to record a decision in the committed spec or work-items file, or amend the spec, mid-run, but the spec never committed or protected that edit, so it could be flagged as a scope escape, folded into the wrong item commit, or discarded by D10's resume-rebuild, silently losing the recorded decision.
- **Resolution:** The skill now commits the operator's mid-run edit as a marked planning commit before proceeding, so it is durable (a resume will not discard it) and is excluded from the item's scope check. Updated D6, the decision-needed alternate flow, and added an edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R10
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human); Edge Cases and Failure Modes

### F81: The repair-upstream exit was under-specified and mis-referenced D20's mismatch path

- **Agent:** independent single-sub-agent review (R10)
- **Category:** under-specified / inconsistency
- **Finding:** The blocker exit routed "repair an already-committed earlier item" through D20's mismatch path, but that path triggers only on a ledger-versus-work-items-file disagreement, which a code repair does not cause; the actual repair lifecycle (re-commit, ledger re-marking, downstream re-verification) was unspecified.
- **Resolution:** D7 now specifies the repair-upstream lifecycle (re-open the earlier item, re-run it through the per-item loop producing a new commit and done marker, then re-verify the items built on top of it) and drops the wrong D20-mismatch cross-reference. Updated the blocker flow and the cross-item-regression edge-case row.
- **Resolved by:** evidence
- **Raised in round:** R10
- **Changed in plan:** Decision D7; Alternate Flows (A blocker is raised); Edge Cases and Failure Modes

### F82: Run configuration and branch were not persisted across resume; the ledger commit shape was recast

- **Agent:** independent single-sub-agent review (R10) + operator direction
- **Category:** failure mode / behavioral commitment
- **Finding:** The ledger recorded item progress but not the configured threshold, cap, model, or branch, so a resume could gate remaining items differently than committed ones and the branch-creation step could fork a new branch where no ledger was found. The operator also judged the fold-the-ledger-into-each-item-commit model too complex and a barrier to a clean code history.
- **Resolution:** Recast the ledger commit discipline (D20): all run bookkeeping lands as separate commits carrying a specific marker, interleaved with clean per-item code commits, and the operator can drop the marked commits with a rebase to leave a clean history. In-progress and done markers bracket each item so resume is unambiguous (a code commit without its done marker is reconciled as done, never rebuilt). The ledger now carries the run configuration and branch, restored on resume. Separating the commits also dissolved the self-referential-hash concern (the done marker, a later commit, records the real reference of the code commit). Updated D20, D24, D9, D22, and the spec's Primary Flow (branch, commit, completion), Resume flow, and Coordinations.
- **Resolved by:** user input and evidence
- **Raised in round:** R10
- **Changed in plan:** Decision D20; Decision D24; Decision D9; Decision D22; Primary Flow (Prepare, Commit, completion); Alternate Flows (Resuming); Coordinations

### F86: Continue-the-builder rests on an experimental, broken platform primitive; deferred

- **Agent:** operator hands-on verification (R11)
- **Category:** behavioral commitment / evidence correction
- **Finding:** R8 treated continuing the original build sub-agent for fix rounds as generally available (from doc-research), and R9 demoted it to an optional within-session optimization. A hands-on R11 check found the primitive it relies on, `SendMessage`-based sub-agent resume, is experimental: it belongs to the off-by-default Agent Teams feature (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) and is reported broken for plain sub-agents (GitHub #35240, #42737, #37051, #48160). The R8 "generally available" claim, from single-source doc-research, was wrong.
- **Resolution:** Deferred continuing the builder entirely. The fix mechanism is now solely a fresh fix sub-agent given curated context (the build report, the diff, and the review record), which works on the default platform. Recast D13, corrected its evidence, and added a Deferred (YAGNI) item with the reopen trigger (resume GA and reliable). Updated the Coordinations implementation-skill row and the compaction edge case (fresh agent only).
- **Resolved by:** user input (hands-on verification)
- **Raised in round:** R11
- **Changed in plan:** Decision D13; Deferred (YAGNI); Coordinations; Edge Cases and Failure Modes

### F87: Repair-upstream's rebuild lifecycle was unsound and overcomplex; reframed to an in-context fix

- **Agent:** review-worker nested panel (R12; P1, P2, P3)
- **Category:** failure mode / simplification
- **Finding:** The R10 repair-upstream lifecycle (re-open the earlier item, re-run it through the loop, new commit and done marker, re-verify downstream) had three holes the panel found: it would rebuild into the current item's dirty tree (P1), wrote no in-progress marker so an interrupted repair looked done (P2), and its downstream re-verification had no failure branch and was not resumable (P3).
- **Resolution:** Dropped the rebuild dance. The earlier item is fixed in the current working context and committed (separately if it cleanly stands alone, else folded into a bulkier commit), with the whole-suite verify still gating it so a downstream regression surfaces before commit; an optional `commit --fixup` plus `rebase --autosquash` attributes the fix to the earlier item in history. The operator judged the rebuild-and-reapply approach not worth its complexity. Updated D7, the blocker flow, and the cross-item-regression edge case.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D7; Alternate Flows (A blocker is raised); Edge Cases and Failure Modes

### F88: Resume's reconcile-as-done rule trusted any commit in the in-progress window

- **Agent:** review-worker nested panel (R12; P4)
- **Category:** failure mode (soundness)
- **Finding:** The R10 rule "in-progress marker plus a code commit after it equals reconcile as done" assumed the commit was the skill's own gated one; a foreign or out-of-band commit (or a contract-violating builder commit) in that window followed by a run death would mark an unbuilt, unverified item done, and dependents would build on a missing foundation.
- **Resolution:** Made resume reconciliation a judgment, not a rule: the skill inspects the actual in-progress commits and tree changes, decides whether they are the item's complete gate-passed work, and asks the operator when the call is not clean; a foreign commit in the window is never blindly accepted. Updated D20.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D20; Alternate Flows (Resuming)

### F89: One-commit-per-item was treated as an invariant, and resume discarded partial work blindly

- **Agent:** review-worker nested panel (R12; P6, P16)
- **Category:** behavioral commitment / failure mode
- **Finding:** The spec assumed one code commit per item, leaving the interactive-skill commit-ownership case undefined (P6: if the interactive skill self-commits, the single-commit step and D9 break; if not, an interruption puts hand-built work on D10's discard path where "loses nothing trustworthy" is false). The resume discard was also a bare confirm that did not show what it would discard (P16).
- **Resolution:** Reframed one-commit-per-item as the normal target, not an invariant (abnormal cases produce other mappings, which the skill accepts). Reframed D10 from blind discard to inspect-decide-ask: the skill inspects partial work, decides resume-or-drop, confirms while surfacing what it found, and never discards an interactive item's hand-built work without explicit agreement. Updated D9, D10, the resume flow, and the interrupt edge case.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D9; Decision D10; Alternate Flows (Resuming); Edge Cases and Failure Modes

### F91: The clean-stop's "at item boundary" check made its mid-fix-loop behavior unreachable

- **Agent:** review-worker nested panel (R12; P5)
- **Category:** inconsistency
- **Finding:** D18 said the stop is checked "at each item boundary" yet also that a stop arriving mid-fix-loop completes the current round and stops; a fix round is within an item, not a boundary, so the mid-fix behavior could never fire and "takes effect at the next item boundary" overclaimed.
- **Resolution:** D18 now checks for a pending stop before each sub-agent dispatch (build, each fix round, review), finishing the in-flight stage to the gate, so the stop takes effect at the next safe point rather than waiting out a whole item.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D18; User Interactions

### F92: Mid-run planning commits could be dropped by the end-of-run cleanup rebase

- **Agent:** review-worker nested panel (R12; P8)
- **Category:** data loss
- **Finding:** The cleanup rebase drops the marked bookkeeping commits, but the spec never said whether a mid-run planning commit (an operator's recorded decision, F80) shares that marker; if it did, the cleanup would delete the decision and its rationale.
- **Resolution:** The planning-commit marker is now distinct from the droppable bookkeeping marker, so the cleanup keeps planning commits. Updated D6 and D20.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D6; Decision D20

### F93: The end-of-run cleanup deleted the resume ledger and was offered on partial runs

- **Agent:** review-worker nested panel (R12; P9)
- **Category:** failure mode
- **Finding:** The cleanup rebase drops the bookkeeping commits and the ledger disappears with them, but the ledger is the sole resume anchor; offering the cleanup on a partial run would silently foreclose resume, so a re-invoke rebuilds already-committed work.
- **Resolution:** D20 now offers the cleanup only when the run is fully complete, never on a partial run. Updated the completion summary.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D20; Primary Flow (completion)

### F94: Resume never re-established the mandatory green-suite baseline

- **Agent:** review-worker nested panel (R12; P10)
- **Category:** failure mode
- **Finding:** The feature spans sessions where the baseline can drift red, but resume restored config/branch and handled partial work without re-checking that the suite is green, so a pre-existing red would be misattributed to the resumed item, the exact failure D15 exists to prevent.
- **Resolution:** Resume now re-establishes the green-suite baseline by re-running the suite before continuing, the same precondition as a fresh start. Updated D10 and the resume flow.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D10; Alternate Flows (Resuming)

### F95: Preparation mutated the repository before the validation and confirm gates

- **Agent:** review-worker nested panel (R12; P11)
- **Category:** inconsistency / failure mode
- **Finding:** The branch, planning commit, and ledger-init landed before the green-suite and field validations could refuse and before the operator's plan confirmation, and the preview had no decline, so a refusal or a "not now" left a stray new branch and commits.
- **Resolution:** Reordered preparation so the read-only checks and the operator's confirmation precede any repository mutation, and added an explicit decline to the preview; a refusal or a declined plan now leaves the repo untouched. Updated D22, D25, and the Primary Flow.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D22; Decision D25; Primary Flow (Prepare, Confirm)

### F96: A mid-run command that fails to execute was misclassified as a code defect

- **Agent:** review-worker nested panel (R12; P13)
- **Category:** failure mode
- **Finding:** The tooling check ran only at start; a mid-run verification command that fails to execute (tool removed, service down, disk full) was routed into the fix loop like a failing assertion, burning the cap on sound code and potentially mistriggering the cross-item-regression path.
- **Resolution:** D8 now distinguishes a command that fails to execute (surfaced as a tooling/environment problem, like the start-time check) from one that runs and reports failures (a code defect for the fix loop). Added an edge-case row.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D8; Edge Cases and Failure Modes

### F97: A stop request was never acknowledged on receipt

- **Agent:** review-worker nested panel (R12; P15)
- **Category:** usability
- **Finding:** The stop's effect was deferred to the next safe point with no on-receipt acknowledgment, so an operator who sees the run keep streaming concludes it did not register and falls back to a raw interrupt, the discard-and-rebuild path the clean stop exists to avoid.
- **Resolution:** D18 now acknowledges the stop on receipt while applying it at the next safe point. Updated D18 and User Interactions.
- **Resolved by:** user input
- **Raised in round:** R12
- **Changed in plan:** Decision D18; User Interactions

### F106: The re-grounding routine needed a durable trigger that survives skill-truncating compaction

- **Agent:** design conversation (operator, R13) with claude-code-guide capability verification
- **Category:** behavioral commitment / failure mode
- **Finding:** D26 committed the orchestrator to re-ground after compaction, but the reminder to do so lived only in the skill body, which a compaction re-injects only truncated (and may drop), so the instruction to recover could be lost by the very event it must survive. Two further gaps: a resume after a pause or time gap was not named as a re-grounding trigger (the orchestrator could misread the new message as a cold start), and any always-on trigger would inject irrelevant content when no run is active.
- **Resolution:** Generalized D26 into a single named **re-grounding** routine with three triggers (compaction, resume-after-pause, inline human-required work) and a defined procedure (re-read the ledger, reload the skill, re-establish state, announce position, then interpret the operator's message in context). Committed that the durable trigger lives outside the skill body and stays conditional: a run-active marker in version-control config (durable, outside the tree and history, branch-scoped) plus a conditional lifecycle hook that fires only when the marker is set. Verified (R13 research) that neither target has session-local memory, skills re-inject only truncated, lifecycle hooks are GA on both Claude Code and Codex, and git config holds a branch-scoped value durably outside the tree and history. The marker/hook mechanics are plan-implementation inputs; the bundled hook is a companion.
- **Resolved by:** user input and evidence (platform capability verified)
- **Raised in round:** R13
- **Changed in plan:** Decision D26 (renamed and generalized); Alternate Flows (Item needs a human); Edge Cases and Failure Modes

### F107: A mid-run repair-upstream autosquash invalidates the commit references the resume ledger records

- **Agent:** R14 review-worker panel (edge-case-explorer, adversarial-validator)
- **Category:** ledger integrity / unsound robustness claim (Critical)
- **Finding:** The repair-upstream exit offered a mid-run `git commit --fixup` plus `rebase --autosquash`, which rewrites the earlier item's code-commit hash. But the done marker still records that item's old hash, and D20's "content preserved even when history is rewritten" claim covers the ledger file's text, not the commit references inside it. After a mid-run autosquash, the recorded reference dangles, so resume reconciliation and the cross-item-regression evidence follow a commit that no longer exists.
- **Resolution:** Deferred the `--fixup`/`--autosquash` attribution to the end-of-run cleanup, the same place D20 already gates the bookkeeping-commit drop, because both are history rewrites that invalidate the ledger's recorded references; mid-run the repair stays a normal commit (D7, D20). This unifies all history rewrites under one completion-only rule.
- **Resolved by:** user input (completion-time history rewrites)
- **Raised in round:** R14
- **Changed in plan:** Decisions D7, D20; Alternate Flows (A blocker is raised); Primary Flow (Commit / completion summary)

### F108: The clean-stop alternate flow contradicted D18's before-each-dispatch granularity

- **Agent:** R14 review-worker panel (junior-developer, adversarial-validator)
- **Category:** internal contradiction (Major)
- **Finding:** The "Operator stops the run cleanly" flow said the stop is checked "at each item boundary," the granularity D18 explicitly rejected in R12 ("before each sub-agent dispatch ... not only at item boundaries"). The contradiction made the flow's own mid-fix-loop handling look unreachable.
- **Resolution:** Reworded the flow to "before each sub-agent dispatch (the next build, fix round, or review), not only at item boundaries," matching D18.
- **Resolved by:** evidence (D18 cross-reference)
- **Raised in round:** R14
- **Changed in plan:** Alternate Flows (Operator stops the run cleanly); Decision D18 (driven-by)

### F109: Resume did not handle a done-marker reference that no longer resolves

- **Agent:** R14 review-worker panel (edge-case-explorer)
- **Category:** resume reconciliation gap (Major)
- **Finding:** Resume handled an unparseable ledger and a missing branch, but not a valid ledger whose done-marker commit reference no longer resolves (after a hard reset, cherry-pick, or the F107 autosquash). Resume would read the marker, skip the item as done, and report it complete while its commit is gone.
- **Resolution:** Extended the resume reconciliation so an unresolvable done-marker reference is surfaced and the operator is asked, the same class as a missing branch or a checkout lacking the run's prior commits, rather than accepting done on the marker alone.
- **Resolved by:** evidence (resume soundness)
- **Raised in round:** R14
- **Changed in plan:** Decision D20; Alternate Flows (Resuming); Edge Cases and Failure Modes

### F110: The interactive-self-commit case had no defined commit-step behavior

- **Agent:** R14 review-worker panel (edge-case-explorer)
- **Category:** HITL boundary / undefined behavior (Major)
- **Finding:** D9 recognized an interactive skill may commit its own work, but no commit-step behavior was prescribed: the driver has no staged changes, review would run against an empty diff, and the done marker must record a commit the driver did not make.
- **Resolution:** Specified that when an interactive skill has already committed, the driver treats that commit as the item's code commit, reviews that commit's diff, and records its reference in the done marker rather than producing an empty commit (D9).
- **Resolved by:** evidence (HITL completeness)
- **Raised in round:** R14
- **Changed in plan:** Decision D9; Alternate Flows (Item needs a human, interactive proceed)

### F111: Re-grounding did not cover a compaction during a foreground interactive interview

- **Agent:** R14 review-worker panel (edge-case-explorer)
- **Category:** re-grounding / HITL boundary (Major)
- **Finding:** D26's triggers did not cover an auto-compaction firing while an interactive skill runs in the foreground. The ledger holds no interview state, the manual-compaction tip cannot prevent an auto-compaction, and the interrupted interview is lost with no described recovery.
- **Resolution:** Named the interrupted-interview state as the one run state re-grounding cannot reconstruct; the skill surfaces the interrupted interactive item and offers to re-invoke the skill or, on the operator's confirmation that the hand-built work is complete, resume at verify, keeping the item in progress (D26, D21, D10).
- **Resolved by:** evidence (HITL completeness)
- **Raised in round:** R14
- **Changed in plan:** Decisions D26, D21; Edge Cases and Failure Modes

### F112: Mid-run structural edit of the work-items file caught only at next resume

- **Agent:** R14 review-worker panel (edge-case-explorer)
- **Category:** concurrent operator action (Major, declined)
- **Finding:** The edge cases covered a content edit to the work-items file mid-run but not a structural one (adding, removing, or reordering items); the in-flight run would conclude against the stale plan it built at start, with the divergence caught only on the next resume.
- **Resolution:** Declined. The platform's file-write tooling forces a re-read of a file before writing it, so the skill re-reads the work-items file on its next write and catches a structural change there; the next-resume reconciliation (D20) is the backstop. Recording the consideration rather than adding a per-item re-validation cost.
- **Resolved by:** user input (platform re-read covers it)
- **Raised in round:** R14
- **Changed in plan:** none

### F113: The run-active marker lifecycle was underspecified

- **Agent:** R14 review-worker panel (edge-case-explorer, on-call-engineer)
- **Category:** marker lifecycle / orphan recovery (Major)
- **Finding:** The version-control run-active marker (D26) was underspecified in three ways: its set timing relative to ledger-init (a preparation failure could leave a marker with no ledger), no staleness or clear path after an abnormal termination (the hook re-grounds into a dead run forever), and ambiguity over whether a clean stop clears it.
- **Resolution:** Specified the lifecycle: the marker is set last in the preparation sequence (after ledger-init), cleared only at full completion, left set on a clean stop so a later resume still re-grounds, and recoverable when re-entry finds the marker but the ledger shows no run in progress (D26, D22).
- **Resolved by:** evidence (re-grounding soundness)
- **Raised in round:** R14
- **Changed in plan:** Decisions D26, D22; Primary Flow (set up; completion summary); Alternate Flows (Operator stops the run cleanly)

### F114: A mid-run re-grounding that cannot re-read or reload had no fail-closed commitment

- **Agent:** R14 review-worker panel (on-call-engineer)
- **Category:** fail-open path (Major)
- **Finding:** D20's abort-to-reconcile was written for a fresh resume, but re-grounding also fires mid-run after a compaction. If the ledger read or skill reload fails there, the orchestrator has no trustworthy source of truth yet no fail-closed was committed, so it could skip a gate or commit unverified work.
- **Resolution:** Committed that a re-grounding which cannot re-read the ledger or reload its instructions halts fail-closed and surfaces the state, the same handling as an unparseable ledger on resume, since the trigger can fire mid-run and not only at a fresh resume (D26, D20).
- **Resolved by:** evidence (fail-closed invariant)
- **Raised in round:** R14
- **Changed in plan:** Decision D26; Edge Cases and Failure Modes

### F115: Extending the non-return bound to the orchestrator's own blocking operations

- **Agent:** R14 review-worker panel (on-call-engineer)
- **Category:** stall-coverage (Major, declined)
- **Finding:** D17's non-return bound covers dispatched and verification operations, not the orchestrator's own commit, marker write, or ledger read; a hanging pre-commit hook or git lock could strand the run.
- **Resolution:** Declined as over-guarding. A hanging git operation borders on the edge of reasonable, and the existing fail-closed handling of a rejected or failed commit (D20) already covers the realistic case; guarding every blocking call the orchestrator makes is not worth the added spec surface. Recording the consideration.
- **Resolved by:** user input (do not over-guard)
- **Raised in round:** R14
- **Changed in plan:** none

### F116: Bounding a no-progress re-grounding / compaction loop within one item

- **Agent:** R14 review-worker panel (on-call-engineer)
- **Category:** unguarded runaway (Major, declined)
- **Finding:** A compaction-to-re-ground-to-reload-to-re-compact loop within one item is neither a fix round (the cap never counts it) nor a dispatch (the clean-stop check is never reached), so neither mechanism the cost-cap deferral relies on would bound it.
- **Resolution:** Declined as not a realistic failure mode. A re-grounding either restores enough working context to make forward progress or it does not; there is no plausible no-progress oscillation to bound, since re-grounding reads a small ledger and reloads the skill and then proceeds. Recording the consideration.
- **Resolved by:** user input (not a realistic oscillation)
- **Raised in round:** R14
- **Changed in plan:** none

### F117: An accepted cross-slice change lived only in memory and was lost on a mid-item compaction

- **Agent:** R14 review-worker panel (on-call-engineer)
- **Category:** work-loss window (Major)
- **Finding:** An accepted cross-slice change (D8) held only in memory for the rest of the item's loop, unlike the durably-recorded proceed-mode; a mid-item compaction would erase it, so re-grounding would resurface the already-approved change as a fresh scope escape and halt the unattended run.
- **Resolution:** Recorded per-item accepted scope escapes in the durable ledger so a re-grounding restores them rather than resurfacing the approved change (D8, D20, D24).
- **Resolved by:** evidence (durable-state invariant)
- **Raised in round:** R14
- **Changed in plan:** Decisions D8, D20, D24; Primary Flow (Verify)

### F118: Resume had no branch for a planning-commit-landed-but-build-not-started item

- **Agent:** R14 review-worker panel (on-call-engineer, adversarial-validator)
- **Category:** resume reconciliation gap (Major)
- **Finding:** Resume's complete-or-drop classification had no slot for a decision-needed HITL item whose recorded-decision planning commit landed but whose build never started; it fit neither "done" nor "partial build to discard," so the build could be skipped or the decision dropped.
- **Resolution:** Added a resume branch: an item whose planning commit landed but whose build never started is resumed at build with the recorded decision kept, not mistaken for partial work (the decision is committed before build, D6, D10, D20).
- **Resolved by:** evidence (resume completeness)
- **Raised in round:** R14
- **Changed in plan:** Decision D10; Alternate Flows (Resuming)

### F119: The source of the project's verification commands was unstated

- **Agent:** R14 review-worker panel (junior-developer)
- **Category:** hidden assumption / underspecified discovery (Major)
- **Finding:** The verify-before-trust gate hinges on running the project's verification commands, but the spec never said how the skill learns which they are, and the optional inputs did not include them.
- **Resolution:** Named the source: the skill determines the verification commands from the project's own configuration, with the operator able to confirm or override the set (D8).
- **Resolved by:** evidence (han project-discovery convention)
- **Raised in round:** R14
- **Changed in plan:** Decision D8; Primary Flow (Prepare and validate)

### F120: The green-suite precondition contradicted the no-verification-commands case

- **Agent:** R14 review-worker panel (junior-developer)
- **Category:** internal contradiction (Major)
- **Finding:** The start sequence made a green suite a hard refusal gate (D15), but a no-commands project has no suite; the spec never said whether that is vacuously green or unconfirmable, two opposite outcomes, and the no-commands edge case already routed to a scope-check-only confirmation.
- **Resolution:** Scoped the green-suite gate to projects that define verification commands; a project with none takes the scope-check-only path rather than being treated as vacuously green or refused (D15, D8).
- **Resolved by:** evidence (reconciles D15 and the no-commands edge case)
- **Raised in round:** R14
- **Changed in plan:** Decisions D15, D8; Primary Flow (Prepare and validate); Actors and Triggers (Preconditions)

### F121: The proceed path assumed a recordable edit for every human-required item

- **Agent:** R14 review-worker panel (junior-developer)
- **Category:** coverage gap / hidden assumption (Major)
- **Finding:** The only non-interactive proceed path required the operator to record a decision, but the HITL classification includes a design review or external setup that produces nothing to commit, leaving the proceed path undefined for such an item.
- **Resolution:** Generalized the proceed path: a decision-needed or external-prerequisite item has the operator do the human step and signal done; if there is something to record it is committed as a marked planning commit, and if there is nothing to record the skill proceeds straight to build (D6).
- **Resolved by:** evidence (HITL completeness)
- **Raised in round:** R14
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human)

### F122: A healthy sub-agent's silence made working, hung, and awaiting-input indistinguishable

- **Agent:** R14 review-worker panel (user-experience-designer, on-call-engineer)
- **Category:** missing system-status feedback (Major)
- **Finding:** Between a dispatch notification and the compact report a healthy sub-agent emits nothing, so working, hung, and halted-awaiting-input looked identical until the stall bound tripped; there was no active attention signal and no legible awaiting-operator state, defeating the step-away value.
- **Resolution:** Committed to keeping the run's current state legible at a glance (working, or awaiting the operator) and emitting an active attention signal at the transition to awaiting operator input, so a stepped-away operator is drawn back at a decision point; the mechanism is plan-implementation.
- **Resolved by:** evidence (unattended-run UX)
- **Raised in round:** R14
- **Changed in plan:** User Interactions (Feedback)

### F123: The proceed/skip prompt did not show the dependents a skip would strand

- **Agent:** R14 review-worker panel (user-experience-designer)
- **Category:** error prevention / recognition over recall (Major)
- **Finding:** The proceed/skip prompt for a human-required item did not show that skipping it also strands every dependent item; the cascade was surfaced only after the choice, so the operator learned the downstream cost too late.
- **Resolution:** The proceed/skip prompt now names the dependent items a skip would also strand, before the operator confirms (D6).
- **Resolved by:** evidence (informed-consent UX)
- **Raised in round:** R14
- **Changed in plan:** Alternate Flows (Item needs a human, decision gate)

### F124: A gate-overridden commit was recorded and summarized identically to a clean one

- **Agent:** R14 review-worker panel (user-experience-designer)
- **Category:** high-stakes action under-surfaced (Major)
- **Finding:** A gate-overridden commit (the heavy choice) was recorded and summarized identically to a clean one; nothing flagged which commits carried known unresolved findings, so an operator pushing the branch could not tell which items shipped with overrides without opening each review record.
- **Resolution:** The done marker flags an override-committed item and points at its review record, and the completion summary distinguishes it as committed over residual findings (D7, D9, D20, D24).
- **Resolved by:** evidence (auditability)
- **Raised in round:** R14
- **Changed in plan:** Decisions D7, D9, D20, D24; Primary Flow (completion summary); Alternate Flows (A blocker is raised)

### F125: The preview conflated a brief decision pause with a full interactive interview, and hid defaulted classifications

- **Agent:** R14 review-worker panel (user-experience-designer)
- **Category:** insufficient information scent (Major)
- **Finding:** The plan preview marked items only "unattended or human-required," conflating a brief record-a-decision pause with a full foreground interactive interview, and telling them apart required recalling which skills are interactive. A classification defaulted from a missing marker was also not flagged (the fail-open angle from the missing-marker fallback).
- **Resolution:** The preview now distinguishes three classes (unattended; needs a decision then runs unattended; needs you to drive an interactive skill in the foreground) and flags any item whose classification was defaulted because its marker was missing (D25, D6).
- **Resolved by:** evidence (attention-planning UX); folds W23 (missing-marker fail-open angle)
- **Raised in round:** R14
- **Changed in plan:** Primary Flow (Confirm the plan); Decision D25 (preview content)

### F126: Finish-autonomously did not disclose that a sub-agent may rewrite hand-built work

- **Agent:** R14 review-worker panel (user-experience-designer)
- **Category:** error prevention / informed consent (Major)
- **Finding:** Choosing finish-autonomously after hand-building an interactive item hands fix authority to a sub-agent that may rewrite that hand-built work to clear the gate, but the label read as "wrap it up" rather than "let a sub-agent modify my work."
- **Resolution:** The finish-autonomously option now states that a gate-blocking finding is fixed by a sub-agent that may alter the hand-built work to clear the gate, making the choice informed (D6); this is the explicit, informed agreement D10 requires before hand-built work is touched.
- **Resolved by:** evidence (informed-consent UX)
- **Raised in round:** R14
- **Changed in plan:** Decision D6; Alternate Flows (Item needs a human, interactive proceed)

### F141: Deferring a blocked item (and other continue-the-run exits) leaves its uncommitted work in the tree, breaking between-item isolation

- **Agent:** R15 team (on-call-engineer)
- **Category:** soundness hole / broken invariant (Critical)
- **Finding:** Several blocker triggers fire with uncommitted work already in the tree (a fix-loop-cap escalation carries the build plus partial fixes; a suspected scope escape carries the build; an unbuildable-as-written item carries partial changes). The blocker Exit lets the operator *defer this item* so "the run continues to the next independent item," recording a defer marker (D24) but never committing or discarding the deferred item's changes. The next item's build sub-agent is then dispatched into a tree that still holds the deferred item's work, and that work is folded into the next item's whole-suite verify, scope check, and commit. On a later re-attempt the deferred item's original work has already been committed under another item, so the rebuild double-applies or conflicts. This breaks D2's stated isolation invariant ("a commit between items keeps each item's changes isolated and the tree clean"); the resume flow's discard (D10) only runs on a re-invoke, not on a same-session defer-and-continue.
- **Evidence considered:** Alternate Flows (A blocker is raised, Exit); D2 isolation rationale; D10 (discard is gated on re-invoke); D24 (defer records a marker only). F9/F72/F129 cover stall/interrupt/resume tree discards, none the defer-and-continue path.
- **Resolution:** A defer (and any blocker exit that continues the run without committing the current item) returns the working tree to the last clean committed baseline before the next independent item is dispatched, using D10's inspect-surface-confirm discipline (never silently discarding an interactive item's hand-built work); the deferred item, when re-surfaced, is rebuilt from scratch.
- **Resolved by:** evidence (restores the D2 isolation invariant)
- **Raised in round:** R15
- **Changed in plan:** Decision D7; Decision D24; Alternate Flows (A blocker is raised); Edge Cases and Failure Modes

### F142: The end-of-run cleanup erases the gate-override audit trail F124 added

- **Agent:** R15 team (junior-developer, on-call-engineer)
- **Category:** internal contradiction / auditability regression (Major)
- **Finding:** F124 made a gate-overridden commit auditable by flagging it in the done marker and pointing at its review record, specifically so an operator pushing the branch can tell which items shipped over residual findings without opening each review record. But the offered end-of-run cleanup drops the marked bookkeeping commits (D20) to leave a "clean per-item code history" for sharing, and the override flag and review-record pointer live in those bookkeeping commits; the retained code commits follow the project's commit convention and carry no override signal. After the cleanup a shared branch reintroduces exactly the blind spot F124 closed, in the sharing scenario F124 cared about most. The two decisions were hardened in the same round (R14) but never checked against each other.
- **Evidence considered:** Primary Flow step 4 (cleanup); Coordinations (version-control row); F124; F92/F93/F139 (cleanup scoped to completion, resume/planning-commit warnings) none noticed the override-audit erasure.
- **Resolution:** The completion summary warns that running the cleanup drops the override flags and review-record pointers riding on the bookkeeping commits, erasing the on-branch record of which items shipped over residual findings, so the operator preserves what they need before sharing; the durable review records themselves survive the cleanup, kept independently of the dropped commits, so the pointer's target does not vanish. (Folding the override flag into the retained code commit's message is left to plan-implementation as an option.)
- **Resolved by:** evidence (auditability retention across a history-rewriting step)
- **Raised in round:** R15
- **Changed in plan:** Primary Flow (completion summary)

### F143: Transient run state established mid-item is not durable across a compaction, and the spec overclaims that only the interview is unreconstructable

- **Agent:** R15 team (junior-developer, on-call-engineer, adversarial-validator)
- **Category:** soundness hole / compaction-durability gap (Major)
- **Finding:** F74 and F117 recorded the HITL proceed-mode and accepted cross-slice escapes durably before re-grounding precisely because in-memory state does not survive a compaction. Four other pieces of state established mid-item were left transient, each with a compaction window between when it is established and when it reaches the committed ledger: (1) **a received-but-unapplied clean-stop request** (JD1) — acknowledged on receipt, applied at the next dispatch, but a compaction in the drain window loses it and the run continues past the stop; (2) **a pending, undecided escalation and its option set** (OCE-B) — re-grounding rebuilds only decided facts from the ledger, so an operator returning after a compaction sends an answer whose question the orchestrator has lost; this falsifies the spec's claim (F111) that the interrupted interview is "the one run state re-grounding cannot reconstruct"; (3) **a just-accepted cross-slice scope escape** (V3) — F117 says it is "recorded durably in the ledger" but, unlike skips/defers, never says "committed immediately," so a compaction before the done marker re-surfaces the already-approved change as a fresh escape, the exact failure F117 meant to prevent; (4) **the review-record location during the verified-but-not-reviewed re-review window** (V5, arising from F134) — the location returned by the re-review lives only in memory until the done marker, so a compaction before the fix dispatch leaves D13's fix sub-agent without the findings it must address, and D26's fail-closed does not trigger because the ledger itself is still readable.
- **Evidence considered:** D18, D26 (re-grounding reads only the committed ledger); D24/D20 (ledger content); F74, F111, F117, F134; the explicit "committed immediately" discipline D20 gives skips and defers.
- **Resolution:** Any decision or acceptance the orchestrator makes that governs the rest of an item's handling — a received stop request, a pending escalation with its evidence pointer and option set, an accepted cross-slice escape, and a completed re-review's record location — is committed immediately as a marked bookkeeping commit (matching D20's skip/defer discipline), so a mid-item compaction's re-grounding restores or re-presents it rather than losing or re-deriving it. Correct D26/F111 to state that pending escalations are also brought under durable reconstruction rather than left as an exception.
- **Resolved by:** evidence (consistency with the F74/F117 durability pattern)
- **Raised in round:** R15
- **Changed in plan:** Decision D18; Decision D20; Decision D24; Decision D26; Primary Flow (Verify); Alternate Flows (Operator stops the run cleanly; Resuming); Edge Cases and Failure Modes

### F144: Auto-compaction is framed as a between-items event, but it fires mid-item where no re-grounding handling is specified

- **Agent:** R15 team (junior-developer)
- **Category:** coverage gap / edge case (Major)
- **Finding:** The only autonomous-run compaction edge-case row and D26 both say compaction "can fire mid-run **between items**," and the stated guarantee is item-boundary correctness ("never rebuilds a committed item or skips an unbuilt one"). But auto-compaction is triggered by context pressure, so it fires during the heaviest phase — a long fix loop on a big item — i.e. mid-item, leaving an uncommitted build plus a partial fix and a lost in-context phase/round count. Re-grounding describes re-reading the ledger, reloading instructions, and announcing position; it does not say it routes that mid-item uncommitted work through D10's inspect-decide-ask, and D10 is gated on "the operator re-invokes the skill." The mid-autonomous-item compaction falls between the two mechanisms; the likely failure is committing a mixed build+partial-fix tree or wedging on the clean-tree check.
- **Evidence considered:** Edge Cases (auto-compaction row); D26 (between-items framing); D10 (entry condition is re-invoke); F71 (re-ground-after-any-compaction, but at the item-dispatch boundary); F111 (interactive-interview case only).
- **Resolution:** Re-grounding, when it finds uncommitted in-progress work for the current item (not only at an item boundary), routes that work through the same inspect-decide-ask / discard-and-rebuild handling D10 defines for resume; the "between items" framing is replaced with "at any point, including mid-item." (Recording the current phase in the ledger so re-grounding need not re-derive it from the tree is a plan-implementation option.)
- **Resolved by:** evidence (unifies the compaction and resume partial-work handling)
- **Raised in round:** R15
- **Changed in plan:** Decision D26; Decision D10; Edge Cases and Failure Modes

### F145: Preparation is not idempotent, so a compaction mid-preparation strands re-entry on "nothing to commit," and D26's reliability claim excludes the pre-marker window

- **Agent:** R15 team (edge-case-explorer, junior-developer)
- **Category:** coverage gap / edge case (Major)
- **Finding:** The preparation mutation sequence is create branch → commit planning artifacts → initialize ledger → set marker (marker last, F113). If an auto-compaction fires after the planning-artifact commit but before the ledger/marker, there is no marker, so the hook never fires and re-grounding cannot trigger (D26's "reliable through any compaction" claim therefore does not hold in this pre-marker window). On re-invoke the skill re-enters preparation, finds a clean tree (artifacts already committed), and attempts the planning-artifact commit against a clean tree; git returns "nothing to commit," which D22 lists as a preparation failure, so the skill halts on a self-inflicted error with no path forward.
- **Evidence considered:** Primary Flow step 2 (set up); D22 (mutation order, "commit rejected" is a preparation failure); D26 (marker set last, reliability claim); F113.
- **Resolution:** D22's preparation steps are idempotent on re-entry: an already-created branch and an already-committed planning-artifact set are treated as already-complete rather than as failures, so a re-invoke after a mid-preparation compaction proceeds to ledger-init and marker-set on the already-prepared branch. D26's reliability claim is scoped to "once the run is active (marker set)," with a compaction during preparation handled by preparation's idempotent re-entry.
- **Resolved by:** evidence (idempotent preparation)
- **Raised in round:** R15
- **Changed in plan:** Decision D22; Decision D26; Edge Cases and Failure Modes

### F146: A dispatch that fails outright (model/API outage, rate-limit, network partition) has no environment-vs-code classification

- **Agent:** R15 team (on-call-engineer)
- **Category:** unhandled failure mode (Major)
- **Finding:** The spec maps a dispatched operation that does not return (D17 stall → retry/skip/stop) and a verification command that fails to execute (F96 → tooling/environment, not fed to the fix loop), but not a dispatch that returns an error or an unusable non-report — a model-API 5xx/429, a rate-limit, or a network partition that errors fast rather than hanging. On the build/fix path such a failure produces no compact report and no file changes, so it can be misclassified as "a build that produces no file changes is escalated" (D21), labeling an infrastructure outage as a code blocker, or churned into an ad-hoc retry that consumes the fix budget. For an unattended run a transient model outage hits this on the next dispatch.
- **Evidence considered:** Edge Cases (stall row; "verification command fails to execute mid-run" row); D17; D21 (zero-change escalation); F58/F76/F96 cover no-return and command-execution failure, not an errored dispatch.
- **Resolution:** A dispatch that fails to produce a usable report (errored, refused, or empty non-return, as distinct from a hang and from a report saying "no changes") is classified as a tooling/environment problem on the same footing as F96 — surfaced with retry/skip/stop, never fed into the fix loop and never treated as "build produced nothing." A row names the errored-dispatch case alongside the no-return case.
- **Resolved by:** evidence (integration-point failure classification)
- **Raised in round:** R15
- **Changed in plan:** Decision D17; Edge Cases and Failure Modes

### F147: Interactive-skill items assume a single self-commit; multi-commit and post-commit fix rounds leave code unreviewed or the done marker mis-recorded

- **Agent:** R15 team (adversarial-validator, edge-case-explorer)
- **Category:** soundness hole / partial-review path (Major)
- **Finding:** F110 resolved the interactive-self-commit case by "treats that commit as the item's code commit, reviews that commit's diff… records its reference in the done marker" — singular throughout. Two realistic shapes break it: (1) **multiple self-commits** (the operator commits a skeleton, an implementation, and a cleanup during the interview) — "that commit's diff" reviews only the last commit, so earlier commits' changes escape review entirely, violating the no-commit-without-full-coverage-review invariant, and the done marker records only one of several code commits; (2) **fix rounds after a self-commit** — the interactive commit is X, a gate-blocking finding is fixed as commit Y, but the done marker still records X, so the ledger and completion summary point at the pre-fix commit and the review record covers X's diff, not the item's final X+Y state.
- **Evidence considered:** Alternate Flows (interactive proceed); D9; F110; D20 (done marker records the code commit reference).
- **Resolution:** When an interactive item produces more than one commit, the review receives the cumulative diff from the branch base (or the item's start point) to HEAD, not the last commit's diff alone, and the done marker records the commit range (or the final commit produced for the item after any fix rounds), not a single original hash. The single-commit path remains the simple case.
- **Resolved by:** evidence (restores the full-coverage-review invariant for interactive items)
- **Raised in round:** R15
- **Changed in plan:** Decision D9; Alternate Flows (Item needs a human, interactive proceed)

### F148: A folded repair-upstream commit is reviewed against only the current item's spec context

- **Agent:** R15 team (adversarial-validator)
- **Category:** partial-review path (Major)
- **Finding:** D7's repair-upstream fold path commits the upstream fix together with the current item's work, asserting "the gate invariant still holds, the skill only commits when verification and review are green." But the Review step dispatches with "the work item and the spec sections **the item references**" — the current item's context only. Reviewers see the upstream fix as out-of-scope for the current item (surfaced as a scope escape under D8, which the operator accepts) and never evaluate it against the upstream item's own acceptance criteria, which are absent from the review context. A scope-escape acceptance substitutes operator acknowledgment for specialist review, so the upstream portion of a folded commit receives no full-coverage review against its own requirements.
- **Evidence considered:** Alternate Flows (repair-upstream exit); D7; D8 (scope-escape acceptance); Primary Flow (Review dispatch context); F87 (fold structural correctness only).
- **Resolution:** Operator chose the middle path: when a repair-upstream fix is folded into the current item's commit, the review of that commit is given both the current item's and the repaired item's work-item and spec context, so the upstream fix is reviewed against its own acceptance criteria and not only the current item's scope. No full attribution machinery; the marker annotation is F149.
- **Resolved by:** user input (R15 question)
- **Raised in round:** R15
- **Changed in plan:** Decision D7; Alternate Flows (A blocker is raised)

### F149: After a repair-upstream fold, the upstream item's done marker still records its pre-fix commit

- **Agent:** R15 team (adversarial-validator)
- **Category:** ledger-integrity gap (Major)
- **Finding:** After item N's fix is folded into item M's commit Y, item N's done marker still records its original commit X, which does not contain the fix. The ledger's "single source of truth" now has a factually misleading entry for item N (the completion summary shows it as a clean commit X), and resume reconciliation does not catch it because X still resolves in history. The only history-attribution path (`--fixup`/`--autosquash` at cleanup) would rewrite X's hash and dangle the done marker's reference — the very problem F107 addressed — so the fold and the end-of-run cleanup were never reconciled.
- **Evidence considered:** Alternate Flows (repair-upstream exit); D7; D20 (done marker records the real commit reference); D9; F107 (mid-run rewrite deferred to cleanup); F87.
- **Resolution:** Operator chose the middle path: at fold time the repaired item's done marker is annotated to note its fix landed in the current item's commit, so the ledger does not misrepresent the upstream item as untouched; the full done-marker-update-plus-cleanup-refresh machinery is not built.
- **Resolved by:** user input (R15 question)
- **Raised in round:** R15
- **Changed in plan:** Decision D7; Alternate Flows (A blocker is raised)

### F150: A zero-overlap ledger (a different work-items file on the same branch) misfires the mismatch handler

- **Agent:** R15 team (edge-case-explorer)
- **Category:** coverage gap / resume edge case (Major)
- **Finding:** The D20 ledger/work-items mismatch handler was designed for "same file, items edited or renumbered." When the operator points the driver at a different work-items file on a branch that already carries a prior run's ledger (zero shared identifiers), all three offered options misfire: *proceed from the first unmatched item* builds the new file's items on top of the old file's unrelated commits and reports the old items as done; *restart from the beginning* is ambiguous (rebuild the old items or start fresh with the new ones?); *abort* is safe but leaves no guided path to "start a new run on this branch." There is no "start a fresh run on this branch, initializing a new ledger" option.
- **Evidence considered:** Alternate Flows (Resuming); Edge Cases (ledger-vs-work-items mismatch row); D20; F35, F101.
- **Resolution:** The mismatch handler detects a zero-overlap (or below-threshold) mismatch and surfaces it as a distinct case with an explicit "start a fresh run on this branch (initializing a new ledger)" option alongside switch-branch and abort, rather than routing it through the edited-items option set.
- **Resolved by:** evidence (distinct resume state)
- **Raised in round:** R15
- **Changed in plan:** Decision D20; Alternate Flows (Resuming); Edge Cases and Failure Modes

### F151: Re-grounding's durable trigger (a bundled lifecycle hook) rests on a single-source platform-distribution inference

- **Agent:** R15 team (junior-developer)
- **Category:** evidence quality / load-bearing single-source claim (Major)
- **Finding:** D26 makes re-grounding's reliability turn on a bundled conditional startup hook, "portable across the suite's targets, which share the same lifecycle-hook model." The cited R13 evidence verifies the *platform* supports lifecycle hooks; it does not verify that installing the han-coding plugin registers a conditional hook that fires in an arbitrary operator project. This is the load-bearing claim the whole compaction-survival story depends on, resting on one doc-sourced platform fact plus an inference (platform-supports-hooks ⟹ our-bundled-hook-installs-and-fires). R11 is the precedent: a single-source doc claim about a platform primitive was overturned only by hands-on verification, and R11 itself flagged that the same method backed other claims — a lesson never applied to the newer, only-doc-verified hook. A bundled lifecycle hook is also a new artifact type for the suite (which ships skills/agents/references/scripts), so "it just installs and fires" is worth the evidence flag.
- **Evidence considered:** D26 (durable trigger); R13 research (lifecycle hooks GA on both targets); R11 precedent (F86) and its open-risk flag; Han's evidence rule (load-bearing single-source claims must be marked).
- **Resolution:** Operator chose to accept the existing plan-implementation deferral: D26 already defers the marker/hook mechanics to plan-implementation, and the aggressively-auto-updating-platform reasoning that dropped the R7 pre-nesting fallback applies here too, so no fallback is added and the spec is unchanged. The evidence flag is recorded so plan-implementation verifies the bundled hook installs and fires (the R11 hands-on standard) rather than assuming it.
- **Resolved by:** user input (R15 question)
- **Raised in round:** R15
- **Changed in plan:** — (no spec change; recorded as a plan-implementation verification input)

### F152: There is no abandon-the-run affordance; a permanent stop leaves the marker armed and names no positive next action

- **Agent:** R15 team (junior-developer, user-experience-designer)
- **Category:** missing affordance / marker-lifecycle gap (Major)
- **Finding:** The run-active marker "stays set on a clean stop… only a fully complete run clears it," and orphan recovery only clears it when the ledger shows no run in progress. An operator who stops a run for good (direction changed, feature abandoned) has no modeled way to quiet the trigger: skipping all remaining items ends as "partially complete" (still in progress), so the marker is never cleared and every later session on that branch re-grounds into the dead run and announces "resuming at item N," including messages meant for unrelated work. The only escapes are completing the run or hand-editing git config, neither offered nor documented. Relatedly, the stopped/partial-run hand-off is entirely a prohibition ("warns against dropping those commits by hand") and never states the two forward actions — resume by re-invoking, or abandon by discarding the branch — while the complete-run summary does give a concrete next action.
- **Evidence considered:** Alternate Flows (Operator stops the run cleanly, Exit); Primary Flow step 4; D26 (marker lifecycle); F113; F34/F139.
- **Resolution:** Add an explicit end/abandon choice (distinct from clean stop and defer) that clears the run-active marker and records the run as abandoned in the ledger, and have the stopped/partial-run summary state the two available next actions (resume by re-invoking on the same work-items file; abandon by discarding the branch) alongside the existing don't-drop-by-hand warning.
- **Resolved by:** evidence (marker-lifecycle completeness; user-control-and-freedom)
- **Raised in round:** R15
- **Changed in plan:** Decision D26; Decision D18; Alternate Flows (Operator stops the run cleanly); Primary Flow (completion summary); User Interactions

### F153: The confirm-the-plan gate never shows the effective run configuration or the branch the commits land on

- **Agent:** R15 team (user-experience-designer)
- **Category:** missing system-status feedback (Major)
- **Finding:** At the one deliberate decision point of the whole flow, the operator is shown the item list but not the effective run configuration governing the unattended run: the gate threshold, the fix-loop cap, the build/fix model, and — most concretely — the branch the per-item commits will land on (the branch name is only reported in the completion summary, after every commit is made). The resume summary likewise omits the config it silently "restores from the ledger." This is visibility-of-system-status and recognition-over-recall at exactly the moment the operator commits attention to a long AFK run.
- **Evidence considered:** Primary Flow step 2 (Confirm); Alternate Flows (Resuming, resume summary); User Interactions (Affordances); D25; D14; D20/F82 (config persisted but not surfaced).
- **Resolution:** The confirm-the-plan preview and the resume summary display the effective run configuration (gate threshold, fix-loop cap, build/fix model, and the branch the run commits onto, including an auto-derived one) alongside the item list; exact layout is plan-implementation. (Editing config at the preview is a separate, unevidenced affordance and is not added.)
- **Resolved by:** evidence (informed confirmation)
- **Raised in round:** R15
- **Changed in plan:** Decision D25; Primary Flow (Confirm the plan); Alternate Flows (Resuming); User Interactions

### F154: A skip marked at the preview does not show the dependents it will strand before the operator confirms

- **Agent:** R15 team (user-experience-designer)
- **Category:** error prevention / informed consent (Major)
- **Finding:** At the preview the operator can mark items to skip, but the "items that will be skipped because a dependency is blocked" list is computed from the initial state, before the operator's own skips. When the operator marks item 4 to skip, the items that depend on it are newly stranded, yet nothing states the preview re-renders to show that cascade before the operator confirms. The operator learns the downstream cost only when the run reaches (or fails to reach) those items — the same gap F123 closed for the in-run human-required decision gate, which the preview-time skip is a distinct interaction F123 never touched.
- **Evidence considered:** Primary Flow step 2 (Confirm); D25; F123 (in-run gate cascade); F32/F85 (preview-skip existence and durability).
- **Resolution:** When the operator marks an item to skip at the preview, the skill re-renders the plan showing the dependents the skip now strands and returns to a fresh confirm before any work begins — the "show the cascade before the choice" contract F123 gives the in-run gate.
- **Resolved by:** evidence (informed-consent UX; mirrors F123)
- **Raised in round:** R15
- **Changed in plan:** Decision D25; Primary Flow (Confirm the plan)

### F155: The human-required menus lack a defer option, and the interactive pause's bare "stop" is ambiguous

- **Agent:** R15 team (user-experience-designer)
- **Category:** missing affordance / cross-menu inconsistency (Major)
- **Finding:** "Defer this item (the run continues)" is a first-class blocker exit but is absent from both human-required menus. The start-of-item decision gate offers only proceed or skip: for an external-prerequisite item whose prerequisite is not ready when the run reaches it, neither fits (proceed is impossible, skip means permanent operator ownership); the natural "not now, come back and keep the run moving" has no affordance. Inside pause-after-each-review the menu is keep-steering / finish-autonomously / stop, with no defer/skip-this-item, and the bare "stop" carries the defer-vs-stop-run ambiguity F136 resolved for the blocker menu but left untouched here, so the operator cannot tell whether stop abandons the item or halts the whole run.
- **Evidence considered:** Alternate Flows (Item needs a human — decision gate; interactive proceed / pause-after-each-review); D6; F136 (blocker defer/stop split); F62/F64/F73.
- **Resolution:** Offer "defer this item" at the human-required decision gate (routing through D24 defer-persistence), and in the interactive pause-after-each-review menu replace the bare "stop" with the F136 split — defer/skip this item (the run continues) versus stop the run.
- **Resolved by:** evidence (affordance completeness; cross-menu consistency)
- **Raised in round:** R15
- **Changed in plan:** Decision D6; Decision D24; Alternate Flows (Item needs a human)

### F156: The already-red-suite refusal names no remedy and dead-ends a legitimately-red-baseline project

- **Agent:** R15 team (user-experience-designer)
- **Category:** error recovery / equitable use (Major)
- **Finding:** Error states requires every refusal to name reason and remedy (F42), but the "test suite is already red at start" row gives only the reason and no remedy. More seriously, a project with a legitimately red baseline (known-failing or environment-dependent tests, a common real state) hits a hard wall: the no-verification-commands case has a documented escape (operator-confirmed scope-check-only run), but a project that has commands and a red baseline has no path, only a rationale. F42 (general remedy requirement) did not reach this row and F120 (green gate scoped to command-defining projects) did not consider the red-baseline-with-commands case.
- **Evidence considered:** Edge Cases ("test suite is already red at start" row); User Interactions (Error states); D15; F42; F120.
- **Resolution:** Operator chose remedy-text-only: the already-red-suite refusal now names a remedy (get the suite green, or narrow the configured verification command to exclude the known-failing tests, then re-invoke). A dedicated operator-confirmed red-baseline path is deferred under YAGNI with a reopen trigger rather than built now.
- **Resolved by:** user input (R15 question)
- **Raised in round:** R15
- **Changed in plan:** Edge Cases and Failure Modes (test suite already red row); Deferred (YAGNI, operator-confirmed red-baseline path)

## Minor edits

- F15: "D15-class" label on the capable-session precondition could imply the skill enforces it the way it enforces the clean-tree check; reworded to an operator-responsibility precondition the skill may not be able to check (adversarial-validator; Decision D14).
- F38: "Finishes to its gate" on a clean stop mid-fix was ambiguous; clarified that it completes the current fix round, evaluates the gate once, then commits or escalates (junior-developer; Decision D18).
- F39: The triage offer gave no preview of what triage produces; the blocker escalation now names what triage does so the operator can give informed consent (user-experience-designer; Alternate Flows, A blocker is raised).
- F40: No mid-run adjustment for a too-strict gate; the fix-loop-cap escalation now offers running more fix rounds as an option (user-experience-designer; Edge Cases and Failure Modes; Alternate Flows).
- F41: Summary decision counts were stale after R3/R4; updated (junior-developer; Summary).
- F42: Precondition refusals named the reason but not always the remedy; User Interactions now requires both in every refusal (user-experience-designer; User Interactions, Error states).
- F55: The review-level "nothing extra" scope check depends on the work-item scope context reaching the reviewing judgment, which now runs a stage removed from the driver; D8 now states the scope context must reach that judgment however the review stage is dispatched (junior-developer; Decision D8).
- F56: D12's "the driver defines the contract in every dispatch" over-claimed under the panel fan-out (the driver does not make the panel's dispatches), and the Coordinations `code-review` row omitted the per-fix-round re-review; scoped the contract to "every dispatch the driver makes" and added "and again per fix round" (junior-developer; Decision D12; Coordinations).
- F70: D20's "recording... its commit" in the same commit is circular (a commit's hash cannot contain itself); reworded to "a stable reference to its commit," with the exact reference form left to implementation (adversarial-validator, R9; Decision D20).
- F75: the foreground hand-off's *start* was not signaled the way its end (the confirm gate) is; the compaction recommendation landed at the item's end where an operator who chose to finish autonomously had already left; and the three (now two) modes were terse at a depleted moment. D26 now signals the hand-off start, surfaces the compaction tip at the choice point, and the alternate flow states each mode's sequence (user-experience-designer, R9; Decision D26; Alternate Flows).
- F76: the explicit-command-timeout companion (D17) could be mistaken for the primary non-return guard; D17 now states the orchestrator's outer stall bound is the load-bearing guard and the per-command timeout is a latency optimization, so the run never depends on the companion having shipped (on-call-engineer, R9; Decision D17).
- F83: "Built test-first" overclaimed in the Outcome and Summary now that D21 allows non-`tdd` code-producing skills; scoped to "built with its declared implementation skill (test-first by default)" (independent sub-agent review, R10; Outcome; Summary).
- F84: D27's orchestrator spot-check had no trigger, action, or consequence, so it made no testable commitment and could not be relied on as a safeguard; reframed as an optional best-effort aid, with the bounded trust resting on the verdict's completeness, the coverage attestation, and the per-fix re-review (independent sub-agent review, R10; Decision D27; Primary Flow Review step).
- F85: preview-time skips were not connected to D24's durable immediate-commit mechanism, and the resume flow did not say whether the preview gate replays; D25 now records a preview skip durably at once and the resume flow shows a resume summary rather than replaying the full preview (independent sub-agent review, R10; Decision D25; Alternate Flows, Resuming).
- F90: the per-item-commit-failure edge case said a failed commit "leaves the work in the tree," false when the code commit succeeded but its done marker failed (the code is already in git); reworded to distinguish a code-commit failure (work in the tree) from a done-marker failure (code committed, the missing marker reconciled on resume by inspection) (review-worker nested panel, R12 P7; Edge Cases; Decision D20).
- F98: the Outcome and D1 overclaimed that the design "removes" the per-item context cost "that forces session compaction" while D26 guards against mid-run compaction still firing; scoped to "sharply reduces," the same overclaim-scoping pattern as F64/F77/F83 (review-worker nested panel, R12 P17; Outcome; Decision D1).
- F99: D12's "failure-then-pass evidence required for tdd" was unsatisfiable for a tdd fix round that addresses a review finding without adding new behavior; scoped the red-to-green field to a tdd build, not every fix round (review-worker nested panel, R12 P18; Decision D12).
- F100: the interactive-item "tree unexpectedly unchanged" trigger mapped to two different responses (a light pause/skip in the alternate flow, a full blocker escalation in the edge case); reconciled to one operator-directed behavior (re-run the skill, skip, or treat as a blocker) (review-worker nested panel, R12 P19; Edge Cases; Decision D21).
- F101: the resume cases covered ledger/file mismatch, unparseable ledger, and compaction, but not a recorded branch that was deleted or a resume from a checkout lacking the prior commits; D20 now surfaces that and asks rather than continuing on the wrong base (review-worker nested panel, R12 P20; Decision D20; Alternate Flows, Resuming).
- F102: the blocker "continue" option lumped overriding the quality gate (committing past Critical/Warning findings) with a benign accept-and-commit; split by consequence so the gate-override is surfaced as the weighty choice it is (review-worker nested panel, R12 P21; Decision D7; Alternate Flows).
- F103: the single re-surface rule (re-surface when the blocking reason may change) did not fit a self-owned HITL skip, which has no blocking reason; D24 now honors a self-owned skip without re-surfacing every resume while still re-surfacing a blocked-defer (review-worker nested panel, R12 P22; Decision D24).
- F104: a guard against a concurrent second invocation on the same working tree (the in-progress marker cannot distinguish a live run from a crashed one) was deferred under YAGNI, since concurrent runs on one tree are unusual and the resume inspect-and-ask flow already confirms before any discard (review-worker nested panel, R12 P12; Deferred (YAGNI)).
- F105: an aggregate "systematic review-stage failure" diagnosis (versus N individual escalations) was deferred under YAGNI, since the per-item escalations already surface each failure with evidence and no measured run has produced the misleading aggregate (review-worker nested panel, R12 P14; Deferred (YAGNI)).
- F127: a stop detected before the initial review was ambiguous between "finish to the gate" (review runs) and "escalate with no review record"; the clean-stop flow now states a stop pending before review does not skip it, review runs and the gate is evaluated before the stop takes effect (R14 review-worker panel, adversarial-validator; Alternate Flows; Decision D18).
- F128: the stop acknowledgement did not tell the operator the stop takes effect only after the in-flight stage drains to its gate, so continued output could be misread as the stop not registering; the acknowledgement now states the in-flight stage finishes to the item's gate first (R14 review-worker panel, user-experience-designer, junior-developer; User Interactions; Decision D18).
- F129: resume re-ran the suite for a green baseline and inspected/discarded interrupted partial work without ordering them, so leftover partial work could redden the baseline; the inspection and any discard now complete before the green-baseline re-run (R14 review-worker panel, junior-developer; Alternate Flows, Resuming; Decision D10).
- F130: the clean-tree refusal and the first commit both depend on separating planning artifacts from unrelated dirty files, but how that set is computed was unstated; the skill now derives the planning-artifact set from the items' references plus the work-items file and confirms it with the operator before committing (R14 review-worker panel, junior-developer; Primary Flow; Decision D22).
- F131: listing the optional-with-fallback marker and expected-paths fields under Preconditions as "fields the driver depends on" read as required-to-start, conflicting with the proceed-with-fallback handling; reworded as preferred-but-optional fields the driver uses when present, reserving the hard gates (clean tree, green suite, well-formed graph) for the blocking preconditions (R14 review-worker panel, junior-developer; Actors and Triggers, Preconditions).
- F132: an empty work-items file or one with no buildable items vacuously passed start-time validation, producing an empty preview, an empty ledger, and a "zero items done" report; it is now a startup error reported before any mutation (R14 review-worker panel, edge-case-explorer; Primary Flow; Edge Cases; Decision D19).
- F133: a fix-loop cap of zero was ambiguous between "escalate on the first finding" and an operator's intent of "no hard cap"; D5 now names cap zero explicitly (escalate on the first gate-blocking finding with no fix attempt) and states an unbounded, never-escalate loop is not a supported value (R14 review-worker panel, edge-case-explorer; Decision D5).
- F134: D17 keeps a verified build on a review stall, but the crash-then-resume analogue conflated verified-but-not-reviewed with unverified work; resume now adds a branch that keeps a complete, verified build whose review had not run and re-runs review, mirroring the review-stall handling (R14 review-worker panel, edge-case-explorer; Alternate Flows, Resuming; Decision D10).
- F135: several blocker types shared one Exit menu though options like repair-upstream, accept-flagged, and run-more-fix-rounds are blocker-specific; the escalation now surfaces only the options applicable to the blocker that fired (R14 review-worker panel, user-experience-designer; Alternate Flows; Decision D7).
- F136: the blocker Exit grouped defer-this-item (the run continues) with stop-the-run (everything halts) under one "stop" label; split into defer-this-item (the run continues to the next independent item) and stop-the-run (R14 review-worker panel, user-experience-designer; Alternate Flows; Decision D7).
- F137: the uniform escalation frame gave a routine, preview-anticipated pause the same visual weight as an unexpected one (a regression or a stall); added an expectedness marker to the frame while keeping the shared shape (R14 review-worker panel, user-experience-designer; User Interactions, Escalation frame).
- F138: markers were not committed to be idempotent or keyed by item, so a retried stage (a rebuild, a double re-grounding, a hung-but-landed commit) could append duplicates that the resume reconciliation must tolerate; the behavioral invariant (duplicate markers must not corrupt resume) is already implied by D20's judgment-based reconciliation, and the keying mechanism (keyed by item and run, last-write-wins) is deferred to plan-implementation as an implementation detail rather than a spec behavior (R14 review-worker panel, on-call-engineer; deferred to plan-implementation).
- F139: the end-of-run cleanup was not committed to explain it rewrites history and ends resume, and a partial run showed the same droppable-looking bookkeeping commits with no warning; the completion summary now states the cleanup rewrites history and ends resume, and a partial-run summary warns against dropping the bookkeeping commits by hand (R14 review-worker panel, user-experience-designer; Primary Flow, completion summary; Decision D20).
- F140: in pause-after-each-review, "keep steering" named no signal that re-runs the next verify-review cycle after the operator's manual changes; defined the re-trigger as an operator message that runs the next verify-and-review cycle (R14 review-worker panel, adversarial-validator; Alternate Flows, Item needs a human).
- F157: the blocker escalation places the raw evidence dump (raw verification output or residual findings) between the one-sentence reason and the actionable option list, burying the choice the returning operator must make below a wall of output; the frame's scannable core (reason + labeled options) should precede the raw evidence, with the raw output placed after the options or behind the durable review-record pointer (R15 team, user-experience-designer; User Interactions, Escalation frame; Alternate Flows, A blocker is raised).
- F158: the cross-item-regression exit presents "which earlier item regressed" as evidence already in hand, but the whole-suite verify only establishes the suite is green-then-red, not which earlier item is the culprit; state that identifying the specific earlier item is a triage/operator step rather than an autonomous claim, so the repair-upstream exit does not assume a fact the skill has not established (R15 team, junior-developer; Alternate Flows, A blocker is raised; Decision D7).
- F159: an item both marked human-required and declaring an interactive skill fits neither proceed path cleanly, and the interactive path omits the record-a-decision-as-a-planning-commit step, so a decision made during an interactive item could go unrecorded and be lost on resume (the gap F80/F118 closed for the non-interactive path); state the precedence rule — an interactive item that also carries a decision runs the foreground interview but still commits any recorded decision as a planning commit before proceeding (R15 team, junior-developer; Decision D6; Alternate Flows, Item needs a human).
- F160: the fix loop says "re-verifies, and re-reviews" without stating whether re-review runs when re-verification fails within a round; specify that re-review runs only when re-verification passes (a re-verification failure alone counts as a not-cleared round and loops to the next fix), so the panel does not review known-broken code and the round's durable record reflects that verification did not pass and no review ran (R15 team, edge-case-explorer; Primary Flow, Fix to the gate; Decision D5, D8).
- F161: the escalation frame's status line is defined as "which item and phase," dropping the run position (item N of M, done/remaining/blocked) the normal per-item header carries (F31), so a returning operator offered a run-wide choice cannot weigh it without scrolling back; the frame's status line carries the same run position the header already computes (R15 team, user-experience-designer; User Interactions, Escalation frame).
- F162: the resume-mismatch "restart from the beginning" option does not disclose its consequence for already-committed work (re-process and duplicate commits? reset the branch? ignore the ledger?), a high-stakes choice on a branch that already carries committed items; state what restart does to the committed items and ledger at the prompt so the operator chooses with the consequence visible (R15 team, user-experience-designer; Alternate Flows, Resuming; Edge Cases, ledger-vs-work-items mismatch row).
- F163: the D27 orchestrator spot-check, after F84 hollowed it to "best-effort, not load-bearing," made no testable behavioral commitment (no trigger, no action, no consequence) yet read as a safeguard; operator chose to give it a testable shape — the spot-check stays optional, but when it runs and finds the record and the verdict disagree (a finding at or above the threshold present in the record but missing from the verdict) it escalates as a review failure, so it makes a defined commitment when exercised rather than being a no-op (R15 team, junior-developer; Category: YAGNI candidate, resolved by user input; Primary Flow, Review step; Decision D27).
