# Review Iteration History: Per-Item Skill Selection for Work Items

<!--
One entry per iterative-plan-review round. Cross-links: Findings raised → review-findings.md (F#).
-->

## R1: Decompose the AFK/HITL classification (build vs review)?

- **Mode:** team
- **Spec-aware mode:** engaged
- **Prompt / focus:** the operator's question — should the per-item `Type` be split so build and review interactivity are handled separately, given "AFK build + HITL review" and the "human decision needed before work starts" case?
- **Specialists engaged:** han-core:junior-developer, han-core:adversarial-validator, han-core:evidence-based-investigator, han-core:edge-case-explorer
- **Findings raised:** F21, F22, F23, F24
- **Outcome:** The decomposition itself is unnecessary (F22) — build and review autonomy are already recorded in the two skill fields, and the pre-work decision is reconstructable — so no new field is added. But the question exposed a real latent defect (F21): `Type` derivation ignored the review field, so an autonomous-build item with a human review was mis-typed `AFK` and mis-bucketed. Fixed by making `Type` a three-input conjunction (build autonomy, review autonomy, no pre-work gate) and by separating the pre-work gate from a human review as distinct `HITL` causes. A catalog coverage gap for `guidance`'s review was closed (F23). The mixed-execution behavior the operator described (sub-agent the autonomous phase, foreground the human phase) remains the core loop's deferred HITL-driver work; this round ensures the data that driver needs is recorded and the classification is honest.
- **Changed in plan:** Primary Flow (steps 3, 4, 7); Edge Cases and Failure Modes; Deferred (YAGNI); (decision log D2, D4, D10).
- **Stability / next step:** The core question is resolved by evidence with a clear recommendation; the only open judgment is whether the operator wants an explicit pre-work-decision field recorded now (not required — reconstructable) rather than deferred. Surfaced to the operator — see R2.

## R2: Operator reverses the decomposition defer

- **Mode:** user-directed (no new team; operator counter-evidence to R1's F22)
- **Spec-aware mode:** engaged
- **Prompt / focus:** the operator refuted F22's two grounds — (1) autonomy is not derivable for non-han/user-defined skills, only for han skills; (2) the human-in-the-loop driver is named upcoming work, so this is its groundwork, not speculation.
- **Findings raised:** F25
- **Outcome:** F22 reversed. The single `Type` field is replaced by three recorded signals (build autonomy, review autonomy, pre-work decision); AFK/HITL becomes a derived label. Han-skill autonomy is derived from the enumeration; non-han autonomy is declared by the operator (a user-defined AFK skill can now be drivable, superseding D8's blanket rule). The current core driver computes autonomy from the signals rather than reading `Type`; the future HITL driver reads the signals per phase. The mixed-execution orchestration stays deferred; only the recording is done here.
- **Changed in plan:** Outcome; Actors and Triggers; Primary Flow (steps 4, 5, 7, 8); Edge Cases and Failure Modes; User Interactions; Coordinations; Deferred (YAGNI); Summary; Review History (decision log D1, D4, D5, D6, D8, D10).
- **Stability / next step:** Two rounds complete. The classification model is now settled; the driver companion change grows to replace the `Type` gate. Ready for the operator's confirmation and then plan-implementation.
