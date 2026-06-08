# Feature Specification: Leaner Code-Review Output Document

The code-review skill produces a review document that records every finding once and grows only sections that have content, so a small change yields a small document and the same review information survives at a fraction of the prose.

## Outcome

Running a code review produces a review document in which every finding's prose appears exactly once, no section is rendered empty, and the generic and duplicated commentary that does not change the merge decision is gone. Nothing that drives a decision is lost: every finding keeps its severity, its task ID, its `file:line` reference, every proven security exploit path, and its YAGNI advisory class. A review of a change with few findings produces a correspondingly short document; a review of a large, problem-heavy change still records everything, just without the repetition ([D2](artifacts/decision-log.md#d2-success-criterion), [D8](artifacts/decision-log.md#d8-lazy-section-creation)).

## Actors and Triggers

- **Actors** — a solo or small-team product engineer running the code-review skill on a branch, on uncommitted work, or on a set of named files; and the pull-request-posting skill that consumes the review document to build a PR review body.
- **Triggers** — the engineer invokes the code-review skill; on completion the skill emits the review document.
- **Preconditions** — the review has completed its analysis and holds a set of findings (possibly empty), each with a severity, task ID, location, and category, plus any proven security findings and YAGNI advisories.

## Primary Flow

1. The review assembles a **Review Summary table** that indexes every corrective finding as one row carrying its task ID, category, `file:line`, and a brief description. The table is the single at-a-glance index and the only place a finding's category is shown ([D7](artifacts/decision-log.md#d7-finding-block-condensing)).
2. The review states a one-line **Review Recommendation** chosen from the highest severity present. The recommendation accounts for the severity of security findings even though those findings are presented in their own dedicated section rather than in the critical-severity list ([D4](artifacts/decision-log.md#d4-merge-recommendation-covers-security)).
3. For each severity that has at least one finding, the review renders that severity's section (🔴 Critical, 🟡 Warnings, 🔵 Suggestions). Each finding block carries its task ID, `file:line` location, the issue, and — for corrective findings — a suggested fix. The block does not repeat the category, which already appears in the summary table ([D7](artifacts/decision-log.md#d7-finding-block-condensing)). A severity with no findings produces no section at all ([D8](artifacts/decision-log.md#d8-lazy-section-creation)).
4. If the review found proven security vulnerabilities, it renders one **full security block per finding** carrying that finding's OWASP category, location, evidence, step-by-step exploit path, and severity. This block is the single home for each security finding's prose ([D3](artifacts/decision-log.md#d3-security-finding-de-duplication)).
5. If the review found proven security vulnerabilities, it appends a **single short security-improvement paragraph** that names what was found and the actionable remediation, referencing the security finding IDs. It does not restate each finding at length and does not carry a separate generic prevention narrative ([D3](artifacts/decision-log.md#d3-security-finding-de-duplication)).
6. If the review found YAGNI advisories, it renders the **YAGNI section**, opening with its verbatim advisory statement. Each YAGNI finding is one line carrying its task ID, anti-pattern class, location, and description, plus a single reopen-trigger clause naming when the code should be kept or revisited ([D7](artifacts/decision-log.md#d7-finding-block-condensing)).
7. If — and only if — the reviewer has a specific, substantive positive worth recording, the review renders a **What's Good** section naming it. When there is nothing substantive to say, the section is omitted entirely rather than filled with generic praise ([D5](artifacts/decision-log.md#d5-whats-good-optional)).
8. If the change introduced no findings at all, the review states that no issues were found and recommends approval, with no empty finding sections ([D8](artifacts/decision-log.md#d8-lazy-section-creation)).

## Alternate Flows and States

### Clean review (no findings)

- **Entry condition:** the review completed and found no corrective findings, no security vulnerabilities, and no YAGNI advisories.
- **Sequence:** the Review Summary table shows its no-issues row; the Review Recommendation states the code can be approved; no severity sections, no security sections, no YAGNI section are rendered. A What's Good section appears only if a substantive positive exists.
- **Exit:** a short document recording a clean result.

### Security findings present

- **Entry condition:** the review found one or more proven security vulnerabilities.
- **Sequence:** each security finding appears as one summary-table row and one full security block with its exploit path; a single short security-improvement paragraph follows; no per-finding cross-reference is created in the critical-severity list. The Review Recommendation reflects the highest security severity ([D3](artifacts/decision-log.md#d3-security-finding-de-duplication), [D4](artifacts/decision-log.md#d4-merge-recommendation-covers-security)).
- **Exit:** each security finding's prose has appeared exactly once (the table row is an index, not prose).

## Edge Cases and Failure Modes

| Condition | Required Behavior |
|-----------|-------------------|
| A finding is both a security vulnerability and critical severity | It appears as a summary-table row and a full security block; it is **not** also duplicated in the 🔴 Critical section. The Review Recommendation still treats it as a merge-blocking critical issue ([D4](artifacts/decision-log.md#d4-merge-recommendation-covers-security)). |
| A severity tier has no findings | No section is rendered for that tier — no heading, no empty-state placeholder line ([D8](artifacts/decision-log.md#d8-lazy-section-creation)). |
| There are no security findings | Neither the security-vulnerabilities section nor the security-improvement paragraph is rendered ([D8](artifacts/decision-log.md#d8-lazy-section-creation)). |
| There are no YAGNI advisories | The YAGNI section is omitted entirely ([D8](artifacts/decision-log.md#d8-lazy-section-creation)). |
| The reviewer has no substantive positive to record | The What's Good section is omitted entirely ([D5](artifacts/decision-log.md#d5-whats-good-optional)). |
| A self-consistency tension is detected between two findings | The existing tension-annotation behavior is preserved; the tension note still appears on both members of the contradictory pair. |
| The PR-posting consumer builds a review body from a document with no What's Good section | The consumer treats What's Good as optional and omits it from the posted body without error ([D6](artifacts/decision-log.md#d6-consumer-treats-whats-good-as-optional)). |

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
|---------------------|-----------|-------------|-----------------------------------|
| Pull-request-posting skill | outbound (consumes the review document) | Builds a PR review body from the Review Summary table, Review Recommendation, the optional What's Good section, and all findings by severity | Must treat the What's Good section as optional and not assume it is always present ([D6](artifacts/decision-log.md#d6-consumer-treats-whats-good-as-optional)) |
| Code-review long-form documentation | outbound (describes the output) | The operator-facing description of the review document's structure | Stays consistent with the new structure (security de-duplication, optional What's Good, lazy sections, condensed finding blocks) — updated for accuracy, not trimmed for its own size ([D10](artifacts/decision-log.md#d10-long-form-doc-consistency)) |

## Out of Scope

- Trimming the code-review skill's own source files — the skill definition, its reference files, or the long-form documentation — for their own size. That is the territory of a separate effort (issue #51). This feature changes only what the generated review document contains and how it is structured ([D1](artifacts/decision-log.md#d1-scope-output-document-only)).
- Changing what the review analyzes, which agents it dispatches, the severity rubric, or the self-consistency tension check. Only the shape and redundancy of the emitted document change.
- A fixed word or line ceiling for a review. Size is governed structurally (prose once, no empty sections), not by a numeric target ([D2](artifacts/decision-log.md#d2-success-criterion)).

## Open Items

<!-- populated by the project-manager in synthesis -->

## Summary

- **Outcome delivered:** the code-review document records every finding once and grows only sections that have content, shrinking the artifact without losing any finding, severity, location, exploit path, or YAGNI class.
- **Primary actors:** an engineer running the code-review skill; the PR-posting skill that consumes the document.
- **Decisions settled by evidence:** N — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** N — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** junior-developer, information-architect — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** TBD after review — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Remaining open items:** TBD
