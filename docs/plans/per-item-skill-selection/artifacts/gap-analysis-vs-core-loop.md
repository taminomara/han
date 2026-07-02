# Gap Analysis: Per-Item Skill Selection Spec vs. Core Loop Deferred Requirements

## Comparison Direction

Current state: `/home/taminomara/p/han/docs/plans/per-item-skill-selection/feature-specification.md` and its `/home/taminomara/p/han/docs/plans/per-item-skill-selection/artifacts/decision-log.md`. The artifact under review.

Desired state: `/home/taminomara/p/han/docs/plans/autonomous-driver-core-loop/feature-specification.md` (Deferred (YAGNI) sections "Per-item implementation-skill selection" and "Human-in-the-loop items and interactive-skill items," and its Coordinations); `/home/taminomara/p/han/docs/plans/autonomous-driver-core-loop/artifacts/decision-log.md` decisions D6, D7, D9, D13, D16, D19; and the current implementations `/home/taminomara/p/han/han-planning/skills/plan-work-items/SKILL.md`, `/home/taminomara/p/han/han-coding/skills/implement-work-items/SKILL.md`, and `/home/taminomara/p/han/han-planning/skills/plan-work-items/references/work-item-template.md`.

The question is whether the new feature spec fully addresses what the core loop deferred, preserves the core loop's committed invariants, and is internally consistent across the two systems it touches.

## Scope

Four comparison areas, drawn from the user's questions:

1. Reopen-trigger justification — whether the new spec honestly satisfies D16's reopen condition.
2. Invariant preservation — whether the driver companion change is consistent with the core loop's committed behaviors: fail-closed startup validation (D13), one-commit-per-item (D8), dispatch-contract-by-instruction (D10), HITL refusal at startup (D13), and the `tdd` build-report contract (D10).
3. Field-set consistency — whether the two new fields follow the D19 pattern and whether backward-compatibility is addressed.
4. Coverage of the core loop's coordination requirements — whether anything assumed in D16/D19 Coordinations is left unaddressed.

Excluded: implementation-level details (how specific SKILL.md steps would be rewritten), code structure, and anything outside the four behavioral areas above.

## Actors and Modes Observed

The desired state names or implies these actors and modes:

- **Operator** — the engineer invoking `plan-work-items` and later `implement-work-items`.
- **Work-item producer (`plan-work-items`)** — the AFK skill that classifies items and records fields.
- **Autonomous driver (`implement-work-items`)** — the AFK-only orchestration skill, single-pass, with one-time confirmation.
- **Implementer sub-agents** — disposable single-use sub-agents that run the build skill per item.
- **Reviewer sub-agents** — the self-contained review stage that fans out `code-review`'s specialist panel.
- **Interactive modes:** none for the driver core — the desired state is AFK-only. HITL items are refused.
- **Batch/automated mode:** the driver runs fully unattended after a single plan-preview confirmation.

## Summary

This analysis compares the new per-item-skill-selection feature spec (current state) against the core loop plan's deferred requirements, committed invariants, and the current implementations (desired state), to find where the spec overclaims, leaves invariants implicit, or creates ambiguity. The comparison runs in one direction: new spec toward the core loop's requirements.

| Category | Count | Description |
|----------|-------|-------------|
| Missing | 0 | Elements in desired state with no current state correspondence |
| Partial | 1 | Elements present in both but incompletely covered |
| Divergent | 0 | Elements addressing same concern in incompatible ways |
| Implicit | 4 | Assumed capabilities neither confirmed nor denied |

Full analysis written to: `/home/taminomara/p/han/docs/plans/per-item-skill-selection/artifacts/gap-analysis-vs-core-loop.md`

## Findings

---

**GAP-001: Reopen trigger first conjunct not met — spec claims full satisfaction**

- **Category:** Partial
- **Feature/Behavior:** Whether the new spec honestly satisfies the condition under which the core loop deferred "Per-item implementation-skill selection."
- **Current State:** `per-item-skill-selection/feature-specification.md` line 3 states "This reopens the core loop's deferred 'Per-item implementation-skill selection'" without qualification. `per-item-skill-selection/artifacts/decision-log.md` D1 (Evidence field) quotes the trigger in full — "a second non-interactive code-producing skill exists AND the design adds a skill-selection decision tree plus an affordance for the operator to allow non-han skills" — then states "User input chose 'producer + minimal driver read'" as the actual decision basis. D4 (Evidence field) confirms "`refactor` stops and waits" and that the user confirmed "`refactor` is interactive." D5 of the new spec's Deferred section states "`tdd` is the only build skill that is both autonomous and test-verifiable... Failed the evidence test (no second drivable skill exists yet)."
- **Desired State:** `autonomous-driver-core-loop/feature-specification.md`, "Per-item implementation-skill selection" under Deferred (YAGNI): "Reopen when: a second non-interactive code-producing skill exists AND the design adds a skill-selection decision tree plus an affordance for the operator to allow non-han skills." `autonomous-driver-core-loop/artifacts/decision-log.md` D16: "The per-item `implementation-skill` field is DEFERRED because `tdd` is the only non-interactive code-producing build skill in the core today... per-item skill selection reopens when a second non-interactive code-producing skill exists."

**Analysis:** The trigger is a conjunction. The new spec satisfies the second conjunct: D2 adds a deliverable-nature decision tree, and D7/D8 together add a non-han affordance (invocation-override + low-confidence suggestion). The first conjunct — "a second non-interactive code-producing skill exists" — is not satisfied: D4 confirms `refactor` is interactive, and D5 of the new spec itself states `tdd` remains the only autonomous and test-verifiable build skill. The actual basis for reopening is user direction ("user input chose 'producer + minimal driver read'"), not the trigger being fully met. The spec states "This reopens..." as a settled fact without disclosing that the first conjunct is unmet. The D5 deferred section's acknowledgment ("failed the evidence test — no second drivable skill exists yet") appears in a different context (explaining why expanding driver combinations is deferred) and is never connected back to the reopen trigger. This is an overclaim: the spec should either acknowledge that the trigger was only partially satisfied and that user direction bridges the gap, or it should restate the reopen condition for this feature using evidence that actually exists (e.g., "the decision tree and non-han affordance are themselves sufficient motivation independent of the first conjunct").

---

**GAP-002: Validation ordering for bare HITL items with no build-skill field**

- **Category:** Implicit
- **Feature/Behavior:** Whether the driver's startup validation correctly handles bare HITL items — items the new spec's D9 explicitly produces without a build-skill field — when the new "build-skill field required" check is added.
- **Current State:** `per-item-skill-selection/artifacts/decision-log.md` D6: "The driver reads both, names them in its preview, dispatches the recorded build skill and review per item, and validates their presence at startup — refusing a file whose items lack them." This applies the requirement to all items. D9: "The item falls back to a bare HITL item with no build skill recorded." The edge cases in `per-item-skill-selection/feature-specification.md` (edge cases row for legacy files) confirm the driver refuses items whose build-skill or review field is missing. No statement addresses the interaction between the "build-skill field missing" check and the "HITL type" check for bare HITL items that legitimately lack a build-skill field.
- **Desired State:** `autonomous-driver-core-loop/artifacts/decision-log.md` D13 specifies the validation order in the current implementation: fields-present (expected-paths, Type) is check #2, and the HITL-type check is check #3. `han-coding/skills/implement-work-items/SKILL.md` Step 1.7 follows this order: "Fields present" (Expected paths + Type) runs before "All AFK" (no HITL items). If the new "build-skill and review fields present" validation is placed at the same position as the existing fields-present check (Step 1.7 #2), a bare HITL item from D9 would be refused for a missing build-skill field rather than for being HITL-typed. The desired state (D13, SKILL.md Step 1.7) does not address how the new field checks interact with the HITL-type check when bare HITL items are present.

**Analysis:** The new spec creates a tension between two of its own decisions: D6 requires a build-skill field on every item, and D9 produces items without one. The existing validation order (D13, SKILL.md Step 1.7) places field-presence checks before the HITL-type check. The new spec does not specify whether the build-skill field check is scoped to AFK items only (resolving the tension cleanly) or applies to all items (which would cause bare HITL items to fail for the wrong reason). This ordering question is entirely absent from the spec's edge cases, validation description, and Coordinations.

---

**GAP-003: tdd build-report contract not explicitly confirmed under per-item dispatch**

- **Category:** Implicit
- **Feature/Behavior:** Whether the `tdd`-specific build-report contract — requiring observed test-failure-then-pass evidence, with a missing-evidence report treated as untrustworthy and halting the run — continues to apply when the driver reads `tdd` from the item's build-skill field rather than hardcoding it.
- **Current State:** `per-item-skill-selection/feature-specification.md` Out of Scope: "No companion changes to `tdd`, `code-review`, `skill-builder`, and so on; the producer records fields and the driver dispatches by instruction, mirroring how the core loop imposed its dispatch contract." Coordinations table: "The driver companion change preserves the core loop's fail-closed startup validation and one-commit-per-item model" (citing D1). `per-item-skill-selection/artifacts/decision-log.md` D1 Rationale: "Making the driver read the fields keeps the choice honest end to end." No statement confirms that the `tdd`-specific evidence requirement (test-failure-then-pass) still applies when `tdd` is dispatched via the recorded field rather than hardcoded.
- **Desired State:** `autonomous-driver-core-loop/artifacts/decision-log.md` D10: "The observed failure-then-pass evidence is required for a `tdd` build (a `tdd` report missing it is untrustworthy and halts the run)." `autonomous-driver-core-loop/feature-specification.md` Edge Cases: "A `tdd` build report is missing the required test-failure-then-pass evidence: The skill treats the report as untrustworthy and halts the run rather than committing an item that may not have been built test-first." `han-coding/skills/implement-work-items/SKILL.md` Step 3.1: "Parse the report fail-closed against the contract" referencing the build-report-contract file.

**Analysis:** The core loop's D10 establishes the `tdd` build-report contract as a critical halt condition tied to the identity of the build skill being `tdd`. The new spec says the driver will now dispatch the skill by reading the recorded field rather than hardcoding it, and that it "mirrors how the core loop imposed its dispatch contract." "Mirrors how" describes the method (by instruction, not by changing the skills), not the content of the contract. The new spec never explicitly states that the `tdd`-specific test-failure-then-pass evidence requirement still applies when `tdd` is dispatched via the recorded field. For the sole supported combination (`tdd` + `code-review`), the contract is effectively unchanged, but the spec leaves this implicit behind the "mirroring" language and the Coordinations' reference to "fail-closed startup validation" — which covers validation, not the build-report contract.

---

**GAP-004: Fix-loop dispatch not addressed for the per-item skill dispatch model**

- **Category:** Implicit
- **Feature/Behavior:** Whether the fix sub-agent dispatched during the bounded fix loop also uses the item's recorded build skill, or continues to hardcode `tdd`.
- **Current State:** `per-item-skill-selection/feature-specification.md` Primary Flow Step 8: "the driver reads each item's build skill and review, names them per item in its preview, and dispatches the recorded build skill to build the item and the recorded review to review it." The "dispatches the recorded build skill" language describes the initial build dispatch. The fix loop is not mentioned in this step or in the Coordinations table. No statement addresses what the fix sub-agent is instructed to run.
- **Desired State:** `autonomous-driver-core-loop/artifacts/decision-log.md` D10: the driver defines the contract "in every dispatch it makes" — meaning both the initial build dispatch and each fix-round dispatch. `han-coding/skills/implement-work-items/SKILL.md` Step 3.4.1 (fix loop): "Dispatch a fresh fix sub-agent... instructing it to run `han-coding:tdd`." D11 (fresh fix sub-agent with curated context): each fix round dispatches a fresh sub-agent given the original build context, the review's durable record, and the current cumulative diff — this dispatch carries the same skill instruction as the initial build.

**Analysis:** The core loop's D10 and D11 establish that the driver defines the dispatch contract in every dispatch, including fix rounds, and the SKILL.md hardcodes `han-coding:tdd` for both the initial build and each fix round. Under the new spec, the driver reads the build skill from the item's field for the initial dispatch. Logical consistency requires the fix dispatch to read the same field for the same item — otherwise a fix agent would always run `tdd` even if the item's recorded build skill is something else. The new spec never states this. Primary Flow Step 8 is scoped to the initial dispatch; the fix loop is addressed only in D1's general principle ("reads both fields and dispatches them per item") and in D5/D6, which describe what the driver supports and refuses, not how the fix loop dispatches. For today's sole supported combination (`tdd` + `code-review`), the practical behavior is unchanged, but the behavioral description has a gap.

---

**GAP-005: Plan-preview timing relative to unsupported-combination startup refusal**

- **Category:** Implicit
- **Feature/Behavior:** Whether the startup refusal for an unsupported AFK build-and-review combination occurs before the plan preview is shown (so the operator never sees the preview), or whether the preview is shown with the unsupported items named and then the run is refused before the operator can confirm.
- **Current State:** `per-item-skill-selection/feature-specification.md` Primary Flow Step 8: "the driver reads each item's build skill and review, names them per item in its plan preview." Edge cases: "An `AFK` item's recorded build-and-review combination is not one the driver supports: The driver refuses that item at startup (fail-fast, before any branch or commit), naming the item and its combination and telling the operator to run it by hand or wait for a follow-on, rather than branching and halting mid-run." Edge cases: "The plan mixes driver-drivable and non-drivable `AFK` items: if the driver is then run, it refuses at startup on the unsupported items rather than driving a partial set." `per-item-skill-selection/artifacts/decision-log.md` D5 Rationale: "adding a startup refusal for unsupported combinations fails fast (before any branch or commit), consistent with the driver's existing all-`AFK` and missing-field refusals."
- **Desired State:** `autonomous-driver-core-loop/artifacts/decision-log.md` D13: all startup refusals (malformed graph, HITL items, missing fields) are performed in Step 1 (read-only, before the plan preview). D17: the plan preview is shown after Step 1 validation, before any repository mutation. The plan preview shows the items that will be driven. `han-coding/skills/implement-work-items/SKILL.md` Step 1.7 (validate, Step 1) runs before Step 2.1 (plan preview), so items refused in Step 1 validation never appear in the plan preview.

**Analysis:** The core loop's D13 places all startup refusals in Step 1, before the plan preview (Step 2.1). D17 shows the preview only after validation passes. The new spec says the driver "names them per item in its plan preview" (suggesting unsupported items appear in the preview), and also says the refusal happens "at startup (fail-fast, before any branch or commit)." "Before any branch or commit" is consistent with either Step 1 (before preview) or Step 2.1 (after preview but before Step 2.2 setup). If the unsupported-combination check is placed in Step 1 alongside the existing HITL/missing-field checks, the preview would never show unsupported items because the run would be refused before reaching the preview. If it is placed in Step 2.1 (the preview itself names the items and then refuses), the operator sees what is being declined. The new spec uses both framings without reconciling them, and the Coordinations table does not clarify which step the new refusal belongs to.

---

## Areas Needing Separate Analysis

**Internal D6/D9 tension (field required vs. bare HITL has no field):** GAP-002 surfaces a tension between D6 (all items must carry build-skill and review) and D9 (bare HITL items have no build-skill recorded). Resolving this requires deciding whether "required on every item" means "required on every item the driver will attempt to drive" (AFK items only) or "required on all items including HITL." That scoping decision has downstream effects on the validation step, the template, and the producer's behavior for bare HITL items. The current spec does not address this, and a focused review of that decision would be warranted before implementation.

**tdd build-report contract for future supported combinations:** GAP-003 is low-stakes today (only `tdd` + `code-review` is supported, so the contract is effectively unchanged). But the new spec's architecture explicitly anticipates future supported combinations. When a second drivable combination is added, the build-report contract for the new skill would need explicit specification. GAP-003 identifies where the current spec's "mirrors" language is insufficient as a template for that extension; a separate analysis at the time of that addition is warranted.
