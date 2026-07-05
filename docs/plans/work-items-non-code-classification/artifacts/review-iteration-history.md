# Review Iteration History: Non-code, meta, and non-deliverable work items

Iterative-plan-review of the recent iteration delta. Spec-aware mode engaged.

## R1

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** `han-core:junior-developer`, `han-core:adversarial-validator`, `han-core:evidence-based-investigator`
- **Scope:** the iteration delta (D11 producer-side validation, D16 reword, D17 spike routing, D18 pre-work-decision boundary), plus a YAGNI sweep. Prior plan-a-feature review (team-findings F1–F13) treated as resolved and not re-raised.
- **Findings raised:** F1, F2, F3, F4 (major); F5, F6, F7, F8, F9 (minor). The evidence-based-investigator confirmed all nine underlying codebase claims (investigate/research scope and tooling, the pre-work-decision field's ephemeral capture, the driver/producer validation surfaces, the absent conformance gate) with no refutations.
- **Changed in plan:** Alternate Flows and States (Spike; Note on the boundary with pre-work decisions), Startup Validation and Refusals, Out of Scope, Deferred (YAGNI); decision-log D8, D11, D15, D16, D17, D18.
- **Changed in tech-notes:** — (no new load-bearing mechanic; T1 unchanged)
- **Stability:** the delta held on its factual claims (all confirmed) but had a load-bearing design gap — the spike routing assumed interactive skills were AFK-drivable. Resolved by making `investigate`/`research` spikes HITL.
- **Next step:** round 2 required (round 1 raised major findings); verify the HITL-spike reframing and the D18 trigger-narrowing did not introduce new contradictions.

## R2

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** `han-core:junior-developer`, `han-core:adversarial-validator`
- **Scope:** verification of the R1 resolutions on the changed sections (HITL spike routing, D18 trigger-narrowing and tiebreaker, D11 producer action, the new Deferred entry).
- **Findings raised:** F10, F11 (major); F12, F13, F14 (minor). The junior-developer confirmed all R1 resolutions are directionally correct and fit the driver's foreground-handoff protocol (a HITL spike commits cleanly because `research`/`investigate` carry no `git` tool, so the finding lands uncommitted and the driver commits it). The adversarial-validator found the two majors the first pass missed: D17's HITL rule was not a driver refusal (hand-edit hole), and "nearest valid classification" was destructive for `spike`+`None`.
- **Changed in plan:** Startup Validation and Refusals (fifth refusal, producer decline-don't-transform), Alternate Flows and States (Spike), Note on the boundary with pre-work decisions (ordered ladder); decision-log D11, D17, D18.
- **Changed in tech-notes:** —
- **Stability:** the core architecture held; round 2 tightened the enforcement (the HITL-spike rule is now a driver refusal, not just a producer default) and made two producer-side rules decidable. Round 2 raised 2 major findings, both resolved in-place.
- **Next step:** medium round cap (2) reached; stop. The two round-2 majors were resolved in-place without a verifying round 3 — an optional round 3 could confirm the fifth refusal and the decline-don't-transform rule. Three F13/F14 items are explicitly routed to `plan-implementation` (catalog second-home edits, spike handoff/review framing).

## R3

- **Mode:** team (second review session, requested after the D19 spike-autonomy reframe)
- **Spec-aware mode:** engaged
- **Specialists engaged:** `han-core:junior-developer`, `han-core:adversarial-validator`, `han-core:evidence-based-investigator`
- **Scope:** the delta since R2 — the D19 reframe (AFK-with-escalation, HITL-for-now), the removal of the round-2 fifth refusal, the rewritten Spike flow, and the never-verified F11 (decline-don't-transform).
- **Findings raised:** F15, F16 (major); F17, F18, F19 (minor); then **F20** (major, post-agent). The three agents converged that D19's "clean escalation today" claim was unspecified and deterministically failed for two of `research`'s gates, so the fifth refusal was first restored as a capability-gated guard. A follow-up operator question then prompted a re-read of the skills, which established that `research`/`investigate` produce their finding **AFK-clean** for a well-formed, correctly-routed question (`research` has no blocking approval; its blocking gates are avoidable edge cases) — so the refusal was removed and interactive-skill spikes became AFK-capable, producer-judged (F20). F11's Type-override wording was also fixed (F17).
- **Changed in plan:** Startup Validation and Refusals (fifth refusal restored then removed; F11 wording fixed), Alternate Flows and States (Spike), Out of Scope, Summary; decision-log D8, D11, D17, D19.
- **Changed in tech-notes:** —
- **Stability:** spike autonomy settled at its final position — AFK-capable, producer-judged (D19). The review moved this decision four times (HITL → producer default → capability-gated refusal → AFK-capable producer-judged); each move was evidence-driven, and F20 anchored it once the skills' actual "no blocking approval" behavior was read directly.
- **Next step:** the F20 correction and the R3 fixes were not re-verified by a further review round — an optional R4 could confirm them. Residual risk is low: F20 is grounded directly in the two skills' step text.
