# Gap Analysis: Feature Specification vs. Desired State (Flowchart + Research)

## Comparison Direction

Current state: feature specification at `docs/plans/autonomous-driver-hitl-support/feature-specification.md` with its artifacts `artifacts/decision-log.md` and `artifacts/feature-technical-notes.md`. Desired state: (a) the happy-path flowchart provided in the prompt, and (b) the research report `docs/plans/per-item-skill-selection/research/reviewing-non-code-work-items.md`.

Default comparison direction used: current state toward desired state.

## Scope

The comparison covers every node in the flowchart and every load-bearing recommendation in the research report, checked against the feature specification and its two artifacts. Ground truth for the current skill is `han-coding/skills/implement-work-items/SKILL.md`, `references/review-verdict-contract.md`, `references/build-report-contract.md`, and `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`.

The following areas are explicitly excluded per the scope note in the prompt and the spec's own Out of Scope and Deferred sections: cross-session resume, mid-run clean-stop, compaction-survival re-grounding, the rich blocker menu, skip/defer, repair-upstream, and async parking of gated items (the research's "park gated items asynchronously rather than blocking the batch" maps directly to skip/defer and is explicitly deferred). No gaps are reported for these areas.

## Actors and Modes Observed

The desired state names or implies these actor types and modes:

- **Operator (human):** present throughout; makes pre-work decisions, steers HITL builds, provides human review findings, optionally injects findings into an unattended review.
- **Build sub-agents (AFK):** autonomous sub-agents dispatched to run a named implementation skill on the item's behalf.
- **HITL build (foreground interactive skill):** the operator steers a named interactive skill in-session (skill-builder, agent-builder, refactor, runbook, coding-standard, architectural-decision-record) or performs a free-form build with no named skill (`none`).
- **Review sub-agents (AFK):** automated review agents dispatched to evaluate the built artifact (`code-review`, `content-auditor`, `information-architect`), each expected to return a normalized verdict.
- **Human reviewer:** the operator, when the review marker is HITL; they inspect the change and supply findings in the normalized verdict shape.
- **Driver (orchestrator):** the `implement-work-items` skill itself; routes phases by recorded markers, runs verification independently, owns commits, re-grounds after inline work.

Modes: interactive / in-session (HITL build and HITL review), fully automated (AFK build and AFK review), pre-task decision gate (pre-work decision), post-task sign-off (human review after independent verify).

## Summary

Comparison direction: feature specification (current state) toward flowchart and research report (desired state). The spec covers all flowchart nodes and most research recommendations well. Two Partial gaps survive adversarial self-disproof: the spec describes the non-code review dispatch outcome (normalized verdict) but does not specify what reference materials the dispatch wrapper provides to each non-code review agent, which the research identifies as the key reliability lever; and the fix-loop text does not explicitly extend the re-grounding requirement to HITL fix-round builds, even though D7 and D9 establish it as mandatory for all foreground builds and the flowchart implies it by returning to the full Build path.

| Category | Count | Description |
|----------|-------|-------------|
| Missing  | 0     | Elements in desired state with no current state correspondence |
| Partial  | 2     | Elements present in both but incompletely covered |
| Divergent| 0     | Elements addressing same concern in incompatible ways |
| Implicit | 0     | Assumed capabilities neither confirmed nor denied |

Full analysis written to: `/home/taminomara/p/han/docs/plans/autonomous-driver-hitl-support/artifacts/gap-analysis.md`

## Findings

**GAP-001: Non-code review dispatch does not specify reference material inputs**

- **Category:** Partial
- **Feature/Behavior:** The research identifies reference-grounding as "the reliability lever for non-code review" (Summary, A39). `content-auditor` is specifically described as reference-grounded fact-preservation: it "extracts atomic facts from the original source, classifies each as Present / Correctly Removed / Missing in the new document" (A8). For that to work, the dispatch wrapper must supply the original source document. `information-architect` similarly needs the document under review to apply its rubric. The research frames reference material provision as a behavioral requirement — without it, non-code review reliability collapses — not as an implementation detail of the wrapper.
- **Desired State:** Research Summary ("reference-grounding as the reliability lever for non-code review"); research A8 (content-auditor "extracts atomic facts from the original source"); research A39 ("judge accuracy collapses without a reference; grounding recovers it" — recommendation-bearing, corroborated by A36); research O5 Recommendation ("using Han's `content-auditor` + `information-architect` for documentation" — both are reference-grounded reviewers by design and need reference material provided at dispatch).
- **Current State:** Spec Primary Flow step 3 item iv ("the driver dispatches the item's recorded review — `code-review` at full specialist coverage, or a non-code review agent — and requires it to return the normalized verdict and persist a durable record") — silent on what inputs the dispatch provides to non-code review agents. T1 (`artifacts/feature-technical-notes.md`, section T1) specifies per-source severity mapping in detail (four sources, four mapping rows) but says nothing about what reference materials the wrapper provides; it explicitly defers "the exact wrapper mechanism... to `plan-implementation`" without naming reference provision as a behavioral requirement the wrapper must satisfy.

  Compare to the current skill's code-review dispatch (`han-coding/skills/implement-work-items/SKILL.md`, Step 3.3): "giving it the item and the spec sections the item references so it judges the change against what the item asked for" — an explicit input specification. The spec has no equivalent statement for non-code review agents.

- **Adversarial self-check:** Could the wrapper mechanism deferral to plan-implementation cover this? Partially — the wrapper implementation would have to provide reference materials to function, so an implementer would discover the need. But the research calls reference-grounding a *reliability lever*, not just a nice-to-have wiring detail. A spec that specifies severity mapping per source (T1) but is silent on input requirements for the same sources is incomplete in a load-bearing way: without knowing the requirement, plan-implementation might return a wrapper that produces structurally valid normalized verdicts (correct output format) while running content-auditor without an original source, producing low-quality or incorrect verdicts that pass the parser but fail the user. The gap survives.

---

**GAP-002: Fix-loop HITL builds — re-grounding requirement not stated in the fix loop section**

- **Category:** Partial
- **Feature/Behavior:** D7 and D9 establish that re-grounding is mandatory after any foreground build: "On confirm, the driver re-grounds, then verifies the item independently like any build" (D7); "It is mandatory after a foreground build (which erodes context heavily)" (D9). The flowchart makes re-grounding part of the Build node itself ("run inline → confirm done → re-ground"), so every pass through the Build HITL path — including fix rounds — triggers re-grounding before verify. D10 says fix rounds "re-enter at the build phase routed by the item's build signal," which logically includes the re-ground that is part of that phase. However, the fix loop text (Primary Flow step 3 item v and D10) does not state this explicitly: it describes a HITL fix round as "fixed by the operator inline again. The round then re-verifies and, on a pass, re-reviews through the same review path" — jumping directly from inline fix to re-verify with no re-ground step named.
- **Desired State:** Flowchart Build path (HITL branch): "run inline → confirm done → re-ground"; then to Review. Flowchart gate-fail path: "back to Build" — which returns to the full Build path, making re-ground part of every fix-round HITL build. The flowchart does not distinguish initial build from fix-round build; both pass through the same re-ground node.
- **Current State:** Primary Flow step 3 item v (spec, p. 35): "an interactive or free-form build is fixed by the operator inline again ([D10]). The round then re-verifies and, on a pass, re-reviews through the same review path (dispatched agent, or the human again)." — no re-ground mentioned between inline fix and re-verify. Decision D10 (`artifacts/decision-log.md`, D10): "an interactive or free-form build is fixed by the operator inline again. The round then re-verifies and, on a pass, re-reviews through the same review path." — same omission. D7 and D9 establish the requirement for initial foreground builds but are not cross-referenced in the fix loop section.

  By contrast, re-grounding is mentioned in every other HITL phase of the spec: the initial foreground build (Primary Flow 3 item ii, Alternate Flow "An item's build runs in the foreground"), the human review (Primary Flow 3 item iv, Alternate Flow "An item's review is a human read"), and the Coordinations table entry for interactive build skills.

- **Adversarial self-check:** Does D10's "re-enters at the build phase" implicitly carry D7's re-ground requirement? D7 describes the foreground build phase as including re-grounding ("the driver re-grounds" on confirm). D10 says fix rounds re-enter that phase. An implementer reading D7 + D10 together could infer the re-ground. However, D7 and D9 are referenced nowhere in the fix loop section of either the spec or D10. An implementer reading the fix loop section in isolation — which is the natural unit when implementing the fix loop — sees: operator inline fix → re-verify, with no re-ground step. The gap is real even if the implication is there by transitivity. The flowchart's explicit re-ground on the Build path (making it a named node, not an inference) provides the desired-state citation the current state lacks in the fix loop section.

## Areas Needing Separate Analysis

**Wrapper mechanism and per-source input contracts for non-code review agents.** T1 defers the exact wrapper mechanism to `plan-implementation`. That deferral is appropriate for a feature spec, but plan-implementation will need to resolve the input contracts (what reference documents each non-code agent receives), the COVERAGE-section semantics for non-code sources (the current `review-verdict-contract.md` defines COVERAGE in code-review terms — "panel members that ran" — which does not apply to `content-auditor` or `information-architect` or a human read), and the RECOMMENDATION-line vocabulary for non-code sources. These are design questions within plan-implementation's scope, not gaps in this spec, but they should be treated as first-class design items rather than incidental wiring. The research's V3 verification ("no overlap with the required contract") established that the incompatibility is complete, not partial, so all three contract sections need specification for each non-code source, not only FINDINGS.

**Catalog companion change row-level specification.** The spec (D6, Coordinations) describes the companion `plan-work-items` change at category level: "skills, agents, plugin-work, ADR, standard, runbook → a human read; documentation → `content-auditor` / `information-architect`; code → `code-review`." The current catalog (`han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`) still has `han-plugin-builder:guidance, AFK` as the review for the "New Claude Code skill," "New Claude Code agent," and "Other work related to Claude Code plugins" rows. The spec does not show the corrected row text. This is within implementation scope — the category-level guidance is clear and sufficient to write the rows — but authoring the corrected catalog is a distinct deliverable that plan-implementation or the build step should treat explicitly, rather than discovering it as a side effect of wiring the driver.
