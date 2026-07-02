# Review Findings: Per-Item Skill Selection for Work Items

<!--
Findings from iterative-plan-review sessions (spec-aware mode). F# continues the
plan's global finding sequence (the plan-a-feature team review used F1–F20 in
../team-findings.md), so this file starts at F21 to keep IDs globally unique.
Cross-links: Raised in round → review-iteration-history.md (R#); Changed in plan →
../feature-specification.md sections; decisions touched → ../decision-log.md (D#).
-->

## Major findings

### F21: `Type` derivation ignored review interactivity and conflated a pre-work gate with a human review

- **Agent:** junior-developer (JD-001), evidence-based-investigator (Claim 3), edge-case-explorer (F1)
- **Category:** behavioral-commitment / mis-classification
- **Finding:** D4 derived `Type` from the implementation skill's interactivity plus "independently needs a human," but never read the review field. An item with an autonomous build skill (`tdd`, `project-documentation`, `guidance`) and a `human read` review — reachable by overriding the review, and the operator's exact "AFK build + HITL review" case — was typed `AFK`, contradicting `AFK`'s own definition ("mergeable without a human sync"). The driver's D5 combination check still refused it (no safety hole), but the human-facing closing recommendation (D10) then sorted it into "run the skill yourself, no human decision needed" — false, because a human review is required. D4 also bundled two operationally different things under one clause: a *gate before work starts* (an architectural decision, resolved once) and a *design review* (a human review of the result), which need different handling in a future HITL driver.
- **Evidence considered:** spec Primary Flow step 4 and D4 list only implementation-skill interactivity + pre-work need; the review field's domain includes `human read` (step 3, D6); D5 refuses non-`code-review` combinations regardless of `Type`; the core loop defines `AFK` as "mergeable without a human sync."
- **Resolution:** `Type` is now `AFK` only when all three hold — the build runs without a human decision, the review runs without a human, and no human decision is needed before work starts; any failure makes it `HITL`. A `human read` review therefore forces `HITL`. The pre-work gate is named as a distinct `HITL` cause from an interactive skill and from a human review. The closing recommendation's "no human decision needed" bucket now holds only items whose review is autonomous or not applicable.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 4, step 7); Edge Cases and Failure Modes
- **Decisions touched:** D4, D10

### F22: The proposed three-signal decomposition is unnecessary — the signals are already recorded or reconstructable

- **Agent:** adversarial-validator (V1–V6), junior-developer (JD-005)
- **Category:** YAGNI candidate
- **Finding:** The operator proposed decomposing `Type` into three recorded signals (pre-work decision, build autonomy, review autonomy) so a future orchestrator can sub-agent an autonomous phase while foregrounding a human phase. But build autonomy is a deterministic function of the already-recorded implementation-skill field, review autonomy of the already-recorded review field, and the pre-work decision is reconstructable in exactly the case where it operationally matters: an item that is `HITL` while its build and review are both autonomous can only be `HITL` because of a pre-work gate. The full decomposition's only consumer is the core loop's *deferred* human-in-the-loop driver; recording redundant interactivity fields would add a consistency-failure surface (a field disagreeing with the skill it mirrors) for no live consumer, and the mixed-execution behavior itself (sub-agent the build, foreground the review, gate on the decision) is explicitly out of scope here and deferred by the core loop.
- **Evidence considered:** D4's closed interactivity enumeration; the review field's closed value set (D6); the driver dispatches build and review to sub-agents and refuses all `HITL` at startup with no foreground path (`implement-work-items` SKILL 1.7, 3.1, 3.3); the core loop's Deferred "Human-in-the-loop items and interactive-skill items."
- **Resolution:** Decomposition deferred; no new field added. The spec's `Type` step now notes that the two skill fields plus a correctly-derived `Type` let a future HITL driver reconstruct which phase is autonomous, and a Deferred (YAGNI) entry records the decomposition with its reopen trigger (the HITL follow-on is planned). Surfaced to the operator for a conscious call.
- **Resolved by:** evidence (surfaced to user)
- **Raised in round:** R1
- **Changed in plan:** Deferred (YAGNI); Primary Flow (step 4)
- **Decisions touched:** D4

### F23: `guidance` had no auto-selected review, leaving the review-selection tree non-total

- **Agent:** edge-case-explorer (F3)
- **Category:** coverage gap
- **Finding:** Step 3's review-selection tree named reviews for code, new-skill/agent, documentation, and ADR/runbook/standard, but a `guidance` (vendoring) item matched none — it is not code, not a new skill/agent, and not conventional documentation. Its review field was undefined; a fallback to `human read` would have silently produced the F21 mis-bucket without any override.
- **Evidence considered:** step 3 names four review mappings; the catalog (D2) includes `guidance`; `guidance` vendors skills and has no test/content review that fits.
- **Resolution:** A vendoring/guidance step is recorded with review `none` (no applicable automated review; verified by re-running), so the tree is total. With the F21 fix, such an item is `AFK` with an autonomous-or-no review and correctly lands in the "run the skill yourself" bucket.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 3); Edge Cases and Failure Modes
- **Decisions touched:** D2, D6

### F25: F22's defer reversed — the three signals are recorded, replacing `Type`

- **Agent:** operator (round R2, counter-evidence to F22)
- **Category:** behavioral-commitment / schema
- **Finding:** F22 deferred the decomposition on two grounds, both of which the operator refuted. (1) "Build/review autonomy is derivable from the skill fields" holds only for *han* skills — the derivation is D4's closed han enumeration. For a user-defined (non-han) skill, interactivity is not inferable (D8's own premise), so the signals are not reconstructable once non-han skills are in play, which is precisely the case this feature's non-han affordance introduces. (2) "No live consumer" fails because the operator named the human-in-the-loop driver as the next feature — this spec is its groundwork, so the consumer is a named upcoming dependency (accepted YAGNI evidence), not speculation.
- **Evidence considered:** D8 ("the producer cannot reliably tell whether an arbitrary skill is code-producing or interactive"); the operator's stated intent to build the HITL driver next; the reconstruction argument in F22 relied on the han enumeration.
- **Resolution:** The single `Type` (AFK/HITL) field is replaced by three recorded per-item signals — build autonomy, review autonomy, and whether a human decision is required before work starts. For han skills the producer derives build/review autonomy from the interactivity enumeration; for a non-han skill the operator declares it (default: not autonomous), so a user-defined AFK skill can be marked drivable (superseding D8's blanket non-han→HITL). AFK/HITL survives as a *derived* label (fully autonomous iff build-autonomous and review-autonomous and no pre-work decision), computed by the producer, the current core driver (which now computes autonomy from the signals instead of reading a `Type` field), and the future HITL driver (which reads the signals per phase to gate, sub-agent, or foreground). The mixed-execution orchestration itself remains deferred to the HITL follow-on; this feature only records the signals.
- **Resolved by:** user input
- **Raised in round:** R2
- **Changed in plan:** Outcome; Actors and Triggers; Primary Flow (steps 4, 5, 7, 8); Edge Cases and Failure Modes; User Interactions; Coordinations; Deferred (YAGNI)
- **Decisions touched:** D1, D4, D5, D6, D8, D10

## Minor edits

- F24: Closing-recommendation bucket 2 ("run the skill yourself") reworded so "no human judgment needed" holds only for items whose review is autonomous or not applicable — resolved within F21. — edge-case-explorer — Primary Flow (step 7).
