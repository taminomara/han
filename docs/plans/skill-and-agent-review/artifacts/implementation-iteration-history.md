# Implementation Iteration History: Skill and Agent Review

<!--
This file records how the implementation plan for Skill and Agent Review evolved across
discussion rounds. Committed decisions live in [implementation-decision-log.md](implementation-decision-log.md)
and the primary plan lives in [../feature-implementation-plan.md](../feature-implementation-plan.md).

Cross-referencing invariants:
- `Decisions produced:` — D# IDs from implementation-decision-log.md that this round added or changed. `—` if none.
- `Changed in plan:` — sections of ../feature-implementation-plan.md that this round updated. `—` if nothing changed.
-->

## R1: Parallel specialist review + user pivot

- **Specialists engaged:** `junior-developer`, `test-engineer`, `adversarial-security-analyst`, `edge-case-explorer` (dispatched in parallel); `project-manager` (deterministic aggregation and synthesis, did not facilitate per round). Feature size: Medium.
- **New input provided:** The feature specification (`../feature-specification.md`) and its companion artifacts (`decision-log.md`, `team-findings.md`, `review-findings.md`), plus the implementation discovery notes (`.discovery-notes.md`). Downstream consumer is `skill-builder` directly (no `plan-work-items`), so the plan had to be concrete and had to close OI-1 and OI-2. Mid-round, the user handed back an authoritative pivot (below) that overrode the home-plugin assumption the discovery notes carried and reversed one specialist simplification.
- **Claim ledger:**

  | # | Claim | State | Citation / resolving note | Source |
  |---|-------|-------|---------------------------|--------|
  | 1 | OI-1 bloat rubric can be closed now against code-review's classification structure and the six spec bloat categories | Evidenced | `han-coding/skills/code-review/references/agent-finding-classification.md`; spec Outcome + Primary Flow step 5; spec D6 | test-engineer |
  | 2 | OI-2 size thresholds are grounded in the repo's measured skill/agent distribution; `implement-work-items` (533 lines / 8 refs) is the named large exemplar | Evidenced | measured repo distribution; `han-coding/skills/code-review/SKILL.md` Steps 3.1–3.2 | test-engineer |
  | 3 | The adversarial-validator dispatch is a fourth untrusted-artifact touch point the spec's D8 enumeration omitted | Evidenced | spec D8/F1/F2 enumerate three; `code-review` Step 7.4 dispatches the validator over the artifact | adversarial-security-analyst |
  | 4 | A guidance-unavailable HALT that renders as the clean "no-issues + approve" shape would be read by a gating caller as a pass (false clean) | Evidenced | spec D9 (halt behavior) states the halt but the CLEAN-vs-HALT output distinction was only implied | adversarial-security-analyst |
  | 5 | The address-and-ask distinction (skill-runtime-directed vs reviewer-directed directive) must be semantic prose, not a phrase regex | Evidenced | spec D8 (embedded directive is itself a finding); a fixed phrase list is evaded by rewording | adversarial-security-analyst |
  | 6 | Type routing must be path-shape-first then frontmatter-confirmation, with two DISTINCT halts (structural-misfire vs neither-type) | Evidenced | spec D5 requires the halts distinct; `allowed-tools` vs `tools`+`model` mutually exclusive in the corpus | edge-case-explorer |
  | 7 | Oversize: skill body >500 lines is a Warning conformance finding; agents have no body cap because the guidance defines none | Evidenced | `.../skill-building-guidance/progressive-disclosure.md` ceiling; agent guidance has no cap | edge-case-explorer |
  | 8 | `allowed-tools` should drop code-review's git/gh/make/npm grants to the minimal `Read, Grep, Glob, Bash(find *), Agent` | Evidenced | `code-review` frontmatter (the grants dropped); the skill runs no build/package/GitHub commands; `Bash(find *)` justified by the guidance search | junior-developer |
  | 9 | Reciprocal sibling-description edits to skill-builder/agent-builder should be deferred while the skill is experimental | Evidenced | both-directions disambiguation rule (`.../skill-description-frontmatter.md`); skill lives in a separate experimental plugin | junior-developer |
  | 10 | (Discovery-notes aggregation) guidance resolution could reduce to a co-located existence check, dropping dynamic resolution | Disputed → reversed by the user pivot | discovery notes' guidance-location reasoning held only while the skill was co-located in `han-plugin-builder`; the pivot moves it to `han-experimental`, so `${CLAUDE_PLUGIN_ROOT}` no longer points at the guidance | project-manager aggregation, overridden by user |
  | 11 | (Discovery-notes assumption) the skill is homed in `han-plugin-builder`, resolving the han-core dependency gap by adding the dependency there | Anecdotal → superseded by the user pivot | discovery notes state the home assumption and flag the dependency gap; the pivot chose a new `han-experimental` home instead of changing `han-plugin-builder`'s "depends on nothing" identity | discovery notes, overridden by user |

- **Open Questions raised:**
  - OQ-1: Which plugin homes the skill, given it needs both `han-core` (dispatched agents) and `han-plugin-builder` (guidance), neither declared by `han-plugin-builder`? → resolved by user pivot → D-6.
  - OQ-2: Is the skill vendored via `init-guidance.sh`, or install-only? → resolved by user pivot → D-7.
  - OQ-3: Given the home, does guidance resolution stay dynamic or collapse to a co-located check? → resolved by user pivot (stays dynamic) → D-8.
  - OQ-4 (OI-1): per-instance bloat severity tiering → resolved by evidence → D-10.
  - OQ-5 (OI-2): size classification, override keyword, roster → resolved by evidence → D-11.
- **Spec-maturity tags:** All specialist findings were plan-level (resolvable in the plan stage) and Evidenced; the deterministic aggregation found no spec-level findings and no T#-contradictions (no `feature-technical-notes.md` exists). **The spec-maturity gate did NOT trip.** One round was sufficient.
- **Resolution source:** OQ-1, OQ-2, OQ-3 — user input (the pivot). OQ-4 (OI-1), OQ-5 (OI-2) — evidence (code-review classification structure + measured repo distribution). Claims 10 and 11 — user input (the pivot reversed/superseded the discovery-notes aggregation).
- **Decisions produced:** D-1 through D-15 (D-1–D-5 trivial; D-6–D-15 full). D-6, D-7, D-8 encode the user pivot; D-10 closes OI-1; D-11 closes OI-2.
- **Changed in plan:** Entire plan authored this round — Source Specification, Outcome, Context, Team Composition and Participation, Implementation Approach (all sub-sections), Decomposition and Sequencing, RAID Log, Testing Strategy, Security Posture, Definition of Done, Specialist Handoffs, Deferred (YAGNI), Open Items, Summary.
- **Project-manager next-step recommendation:** Go to synthesis (done). One remaining open item (reciprocal sibling-description edits, deferred) does not block implementation; hand off to `skill-builder`.
