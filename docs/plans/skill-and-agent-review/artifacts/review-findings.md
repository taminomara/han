# Review Findings: Skill and Agent Review (iterative-plan-review)

This file records the `iterative-plan-review` pass (lightweight, spec-aware) over `../feature-specification.md`. It is separate from the `plan-a-feature` team review recorded in [team-findings.md](team-findings.md); F# numbering continues from that file's highest ID (F24) so IDs stay globally unique for this plan. Iterations are in [review-iteration-history.md](review-iteration-history.md).

Pass theme (user prompt): "anything else we can cut or simplify?" — a YAGNI/simplification sweep. Net result: one decision and one section removed, four edge rows collapsed, and one gap fixed (reviewer roster now scales with the artifact under review).

## Major findings

### F26: Batch (branch-set) review has no cited consumer

- **Agent:** self-review
- **Category:** YAGNI candidate
- **Finding:** The spec let a caller target "the set of skills and agents changed on the branch," which forced an alternate flow and D17 (systemic-versus-per-artifact halt handling). No consumer needs it: the autonomous driver reviews one work item at a time, and an operator can invoke the review per artifact. Batch is a convenience with no user-described need — a YAGNI candidate whose simpler version (single-artifact review) satisfies every named use case.
- **Evidence considered:** The driver dispatches one review per work item (`han-coding/skills/implement-work-items/references/review-verdict-contract.md`); no operator batch need is stated anywhere in the spec or decision log.
- **Resolution:** Deferred under YAGNI (user selected the cut). Removed the branch-set target option from Primary Flow step 1, removed the "Reviewing a branch's changed skills and agents" alternate flow, tombstoned D17, and added a "Batch (branch-set) review" entry to `## Deferred (YAGNI)` (subsuming the earlier combined-report deferral, team finding F16).
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 1), Alternate Flows and States (flow removed), Deferred (YAGNI). Companion: decision-log D17 tombstoned; team-findings F12 marked superseded.
- **Changed in tech-notes:** —

### F29: The reviewer roster was fixed regardless of the artifact under review

- **Agent:** self-review (surfaced by the user while declining cut #4)
- **Category:** gap
- **Finding:** The spec pinned the dispatched roster at one generalist reviewer regardless of the artifact's size and complexity. A 40-line agent and a 500-line multi-reference skill (the scale of `implement-work-items`) warrant different review depth. code-review, the stated base, already classifies size and scales its dispatched roster accordingly; this review inherited the hybrid model but not the scaling.
- **Evidence considered:** code-review classifies change size and selects its agent roster from it (`han-coding/skills/code-review/SKILL.md`, Steps 3.1–3.2); a concrete large artifact (`implement-work-items`) exists as a review target.
- **Resolution:** Extended D4 so the dispatched roster scales with the size and complexity of the artifact under review — the generalist as the floor for a small artifact, additional focused reviewers for a large or complex one — mirroring code-review's size-driven roster. Added OI-2 for the specific size classification and the roster it selects (deferred to plan-implementation, non-blocking).
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 6), Coordinations (independent-reviewer row), Open Items (OI-2 added). Companion: decision-log D4 extended.
- **Changed in tech-notes:** —

## Minor edits

- F25: Removed the dead "plus scope findings" clause from D7 — a leftover from the driver decoupling; a decoupled review has no driver-supplied baseline to judge scope against, so the tier was meaningless — self-review — decision-log D7 (spec unchanged).
- F27: Collapsed four rubric-instance edge-case rows (bare agent dispatch, missing reference file, `AskUserQuestion` in `allowed-tools`, unsafe frontmatter) into one principle row, since the specific severity assignments are implementation-level rubric detail rather than behavioral commitments — self-review — Edge Cases and Failure Modes.
- F28: Folded the restatement-only User Interactions section into Actors and Triggers; its Feedback and Error-states bullets duplicated the Outcome, Primary Flow step 9, and the guidance-absent edge case — self-review — Actors and Triggers, User Interactions (section removed).
- F30: Added an optional caller-supplied size override on top of the review's auto-classification (mirroring code-review's `size` argument), so a caller can force the reviewer roster when it knows the artifact's complexity better than the heuristic does — same "state intent rather than infer it" principle as D10's scope; user-directed follow-up after R1 — self-review (user-directed) — Actors and Triggers, Primary Flow (step 6), Open Items (OI-2); decision-log D4.
