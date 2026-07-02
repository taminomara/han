# Feature Implementation Plan: Per-Item Skill Selection for Work Items

<!-- Two-skill prompt-authoring change: the producer (`plan-work-items`) records a per-item implementation skill, review, and three autonomy signals in place of the single `Type` field, and the driver (`implement-work-items`) computes autonomy from those signals and dispatches the recorded skill and review per item, refusing the whole run at startup when any item is not fully autonomous or is of an unsupported combination. No compiler, no CI; verification is review plus spot-run; everything ships in one atomic merge. -->

<!--
CROSS-REFERENCING GUIDANCE
This file is the primary implementation plan. Decision records live in
[artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md);
round-by-round history lives in
[artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md).
Non-obvious claims carry an inline ([D-N](artifacts/implementation-decision-log.md#...)) link.
Rationale and rejected alternatives live in the decision log, not here.
-->

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md)
- **Specification review findings:** [artifacts/review-findings.md](artifacts/review-findings.md)
- **Specification decisions this plan inherits:** D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11 (spec IDs)
- **Specification open items this plan must respect or resolve:** None — the spec records 0 open items.

## Outcome

When this plan is executed, `plan-work-items` records five fields on every work item — an implementation skill, a review, and the three autonomy signals `Build unattended`, `Review unattended`, and `Pre-work decision` — replacing the old `Type` field, and derives the AFK/HITL label from the signals ([D-11](artifacts/implementation-decision-log.md#d-11-work-item-schema-change)). A new producer reference, `deliverable-skill-catalog.md`, drives the nature-to-skill and nature-to-review mapping, the han interactivity enumeration, the non-han declaration rule, and the not-installed fallback ([D-1](artifacts/implementation-decision-log.md#d-1-catalog-lives-in-a-new-producer-reference)). `implement-work-items` computes each item's autonomy from the recorded signals, dispatches the recorded implementation skill and review per item, and refuses the whole run at startup — with two distinct refusals plus a pre-feature-file refusal — when any item is not fully autonomous or is of a combination it does not support ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)). Both skills, the template, the catalog, and the long-form docs land in a single merge ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)).

## Context

- **Driving constraint:** This is the direct follow-on to the core-loop build (W-1…W-5) that shipped `Type`/`expected-paths`, reopening that plan's deferred "Per-item implementation-skill selection" and recording the per-phase signals the named upcoming human-in-the-loop driver will read (spec D1, D4). Both target skills are under active churn, so the change lands while the surrounding code is fresh.
- **Stakeholders:** The operator breaking a trusted plan into work items (gets a correctly-typed skill and review per item, plus an honest driver-ready / needs-a-hand grouping); the autonomous driver (dispatches the recorded skill and review instead of assuming `tdd`/`code-review`); the future human-in-the-loop driver (reads the three signals per phase); contributors maintaining the two skills (a single field-name vocabulary and one catalog to keep current).
- **Future-state concern:** The producer's closing recommendation and the driver both encode the supported combination `tdd` + `code-review`; expanding that combination later requires a coordinated edit at both sites, tracked as a documented coupling rather than a shared abstraction ([D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)). The template-to-driver field-name coupling is the standing operability risk, mitigated only by verbatim quoting and a review check (R1).
- **Out-of-scope boundary:** No human-in-the-loop driver, no expansion of the supported combination beyond `tdd` + `code-review`, no changes to the build/review skills themselves, no auto-install of missing plugins, and no machine-readable classification of non-han skills (spec Out of Scope). No compiler and no CI are introduced; verification stays review-based.
- **Build-mode note (this feature is not self-drivable):** Han's own deliverables here are documentation-nature (skill and reference prose), so `implement-work-items` would classify this feature's own work items to `project-documentation` / `guidance` / `none` and refuse to drive them as a non-`tdd`+`code-review` set. Build this feature by hand or by invoking the skills directly; judge success by correct classification and correct refusal behavior, not by an autonomous driven run.

## Team Composition and Participation

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Facilitated R1 and synthesized this plan; owns the atomic-ship posture ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)). |
| `junior-developer` | Active | Surfaced the three mechanisms the spec deferred to plan-implementation (installed-skill detection, override channels, non-han declaration) and the full producer edit-site set (Steps 5/7/8); reframed OQ-3/OQ-4 ([D-4](artifacts/implementation-decision-log.md#d-4-installed-skill-detection-from-the-session-registry), [D-5](artifacts/implementation-decision-log.md#d-5-override-channels-invocation-instruction-and-pre-written-marker), [D-9](artifacts/implementation-decision-log.md#trivial-decisions)). |
| `structural-analyst` | Active | Catalog placement and producer-only scope; template as the single field-name source; the driver `Type`-to-signals re-plumb; supported-combo coupling; atomic ship ([D-1](artifacts/implementation-decision-log.md#d-1-catalog-lives-in-a-new-producer-reference), [D-2](artifacts/implementation-decision-log.md#d-2-driver-reads-signals-not-the-catalog), [D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source), [D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals), [D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)). |
| `test-engineer` | Active | Review-plus-spot-run strategy: the four-item producer fixture, the three driver spot-runs, and the side-by-side field-name review that carries the Definition of Done. |

## Implementation Approach

This is a two-skill prompt-authoring change across `han-planning/skills/plan-work-items/` (the producer) and `han-coding/skills/implement-work-items/` (the driver), plus a new producer reference, the shared work-item template, the two driver contract references, the two long-form docs, and the CONTRIBUTING PR checklist as the release gate. There is no application code, no compiler, and no CI; the artifacts are markdown skill definitions and their references.

### Architecture and Integration Points

- **New producer reference.** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md` holds the deliverable-nature-to-implementation-skill map, the nature-to-review map, the han-skill interactivity enumeration (from spec D4), the non-han declaration-and-default rule, and the not-installed fallback. Step 5 loads it. It follows the existing reference-extraction pattern in that folder ([D-1](artifacts/implementation-decision-log.md#d-1-catalog-lives-in-a-new-producer-reference)).
- **Producer-to-driver contract.** The `work-items.md` file is the only interface between the two skills. The producer writes the five fields; the driver reads the signals and its own supported combination and does **not** read the catalog, so the interactivity enumeration lives in exactly one place ([D-2](artifacts/implementation-decision-log.md#d-2-driver-reads-signals-not-the-catalog)).
- **Supported-combination coupling.** Both the producer's closing recommendation and the driver's validation/dispatch encode `tdd` + `code-review`. This is managed editorially with a plan note rather than a shared reference, because a single consumer pair does not justify the abstraction; expanding the combination requires a coordinated producer edit ([D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)).
- **Downstream consumers pass through.** `work-items-to-issues` (`han-github`), `work-items-to-jira` (`han-atlassian`), and `work-items-to-linear` (`han-linear`) parse only the `## <W-N>` heading and the `**Depends on.**` line and copy slice bodies verbatim, so the schema change flows through them untouched (RAID R4).
- **Atomic ship.** The producer, driver, template, catalog, and docs land in one merge, in the in-branch order recorded in Decomposition and Sequencing ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)).

### Data Model and Persistence

The per-item schema in `references/work-item-template.md` changes from the single `**Type.** AFK or HITL` (line 36) to five fields, keeping `**Expected paths.**` and `**Depends on.**` unchanged ([D-11](artifacts/implementation-decision-log.md#d-11-work-item-schema-change)):

- **Implementation skill.** A skill name, or `none` for a bare item.
- **Review.** A review skill, a review agent, `human read`, or `none`.
- **Build unattended.** `yes` or `no`.
- **Review unattended.** `yes` or `no`.
- **Pre-work decision.** `yes` or `no` (whether a human decision is required before work starts).

AFK/HITL is no longer stored; it is derived (fully autonomous iff `Build unattended = yes`, `Review unattended = yes`, and `Pre-work decision = no`). A bare item carries `Implementation skill = none`, distinct from a field the producer never wrote, so the driver can tell a bare item from a pre-feature file. The template is the single source of these field names; the driver quotes them verbatim rather than paraphrasing ([D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source)).

### Runtime Behavior

- **Producer (`plan-work-items` Steps 5, 7, 8).** Step 5's `project-manager` drafting brief classifies each item's deliverable nature against the catalog, selects the implementation skill and review, derives the han signals (declaring non-han autonomy, defaulting to not-unattended), applies operator overrides, and runs installed-skill detection. Step 7's breakdown prints the five fields, the derived label, a driver-ready / needs-a-hand marker, and the flags. Step 8's in-channel summary and three-bucket closing recommendation (driver-ready `tdd`+`code-review`; run-the-skill-yourself; needs-a-human) replace the old "count by type" summary and "all-AFK" driver handoff ([D-9](artifacts/implementation-decision-log.md#trivial-decisions)).
- **Installed-skill detection.** The producer reads the session's available-skills registry — the set it can invoke — and names each catalog skill's plugin origin so it can report an uninstalled best-fit; it builds no capability manifest ([D-4](artifacts/implementation-decision-log.md#d-4-installed-skill-detection-from-the-session-registry)).
- **Override channels.** An invocation override is a natural-language instruction the producer interprets; a pre-written marker is a recognizable single-line bracketed annotation the producer scans for in the read-only source, carrying a skill, an optional review, and an optional non-han autonomy declaration ([D-5](artifacts/implementation-decision-log.md#d-5-override-channels-invocation-instruction-and-pre-written-marker)).
- **Driver (`implement-work-items` Steps 1.7, 2.1, 3.1/3.3/3.4).** Step 1.7 becomes three checks — fields-present, all-fully-autonomous (computed from the signals), and supported-combination — surfacing two distinct startup refusals (needs-a-human vs unsupported-combination) plus a pre-feature-file refusal when items still carry `Type`. Steps 2.1/3.1/3.3/3.4 name and dispatch the recorded implementation skill and review in both the initial build and every fix round, preserving each dispatched skill's contract (for `tdd`, the observed test-failure-then-pass evidence). The frontmatter description changes "AFK-typed" to "fully-autonomous," and the opening sentences of `build-report-contract.md` and `review-verdict-contract.md` are updated for accuracy only, with no operative change ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)).

### External Interfaces

The only cross-skill interface is the `work-items.md` schema above. The two driver contract references (`build-report-contract.md`, `review-verdict-contract.md`) get accuracy-only opening-sentence edits; their required-return formats are unchanged because the driver still drives only `tdd` + `code-review` ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)). No external service, API, or event contract is touched.

## Decomposition and Sequencing

Four work units, built in the in-branch order below and merged atomically ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)). No unit is a shippable slice on its own — a partial merge silently breaks both skills — so the units are a build order, not independent releases.

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | Template + catalog | The five-field schema replacing `Type` in `work-item-template.md`; the new `deliverable-skill-catalog.md` reference ([D-11](artifacts/implementation-decision-log.md#d-11-work-item-schema-change), [D-1](artifacts/implementation-decision-log.md#d-1-catalog-lives-in-a-new-producer-reference)) | — | Review: field labels present and consistent; `Expected paths`/`Depends on` unchanged; catalog covers every nature and resolves its links |
| 2 | Producer Steps 5/7/8 | Classification, skill/review selection, signal derivation, overrides, installed-skill detection, breakdown print, three-bucket closing recommendation ([D-9](artifacts/implementation-decision-log.md#trivial-decisions), [D-4](artifacts/implementation-decision-log.md#d-4-installed-skill-detection-from-the-session-registry), [D-5](artifacts/implementation-decision-log.md#d-5-override-channels-invocation-instruction-and-pre-written-marker), [D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)) | 1 | Producer four-item fixture spot-run plus the override and non-han cases (Testing Strategy) |
| 3 | Driver 1.7/2.1/3.x re-plumb | Three startup checks with two distinct refusals plus a pre-feature refusal; per-item dispatch of the recorded skill/review; frontmatter and contract accuracy edits ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)) | 1 | Three driver spot-runs (drivable / mixed-refusal / pre-feature-refusal) plus the side-by-side field-name review ([D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source)) |
| 4 | Long-form docs | Updated `plan-work-items.md` and `implement-work-items.md`, stale `Type`/AFK-only language removed ([D-10](artifacts/implementation-decision-log.md#trivial-decisions)) | 2, 3 | CONTRIBUTING PR checklist |

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | The template and the driver's Step 1.7 field names drift, so the driver silently refuses every file with a missing-field error | Medium | High | Both skills, every file | High (edit) | `structural-analyst` | Template is the single field-name source; driver quotes verbatim ([D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source)); side-by-side field-name review check (Testing Strategy) |
| R2 | A partial or non-atomic merge lands the producer without the driver, or vice versa, breaking both skills | Low | High | Both skills | High (edit) | `project-manager` | Single atomic merge in the fixed in-branch order ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)) |
| R3 | The human-in-the-loop driver is cancelled, leaving two of the three recorded signals without a live consumer | Low | Low (accepted, disclosed) | Producer schema | Medium | `project-manager` / operator | Accepted and disclosed; reopen tracked in A1 and the kept-item note under Deferred (YAGNI) |
| R4 | A downstream work-item consumer (`work-items-to-issues`/`-jira`/`-linear`) breaks on the schema change | Low | Medium | Three opt-in skills | High | implementer | They parse only heading + `Depends on`; new fields pass through verbatim (discovery: zero matches); spot-read confirms (Testing Strategy) |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | The human-in-the-loop driver is genuinely upcoming and will consume all three per-phase signals | Two of three signals become speculative; revisit whether they earn their storage (R3) | operator / `project-manager` | Accepted (user input; spec D4/F25) |
| A2 | The producer, driver, template, catalog, and docs land in one atomic merge | A half-merge breaks both skills (R2) | implementer | Committed ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)) |

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| Dep1 | `han-update-documentation` to scope the long-form doc pass to the branch-touched entities | implementer | Available (repo maintenance skill; discovery) |

## Testing Strategy

Verification is review plus spot-run; there is no test harness (discovery). The strategy below is sourced from `test-engineer` (round claim C11).

- **Observable behaviors to test.**
  - **Producer, four-item representative fixture:** a testable-code item classifies to `tdd` + `code-review`, fully-autonomous, driver-ready; a documentation item classifies to `project-documentation` + `content-auditor`, fully-autonomous, run-the-skill-yourself; an absent-best-fit new-skill item (with `han-plugin-builder` not detected) classifies to implementation skill `none`, bare, with an end-of-run install note; a `guidance` item classifies to `guidance` with review `none`, fully-autonomous, run-the-skill-yourself.
  - **Producer, override and non-han cases:** a `tdd` + `human read` override recomputes the item to needs-a-human; a non-han skill is recorded not-unattended unless the operator declares it autonomous.
  - **Driver spot-runs:** (A) an all-`tdd` + `code-review` file drives to the preview naming each item's skill and review; (B) a mixed file refuses the whole run at startup before branching, names the offending item, and leaves the repository untouched; (C) a pre-feature `Type` file refuses, names the missing fields, and gives the re-run remedy ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)).
- **Review checks (no runtime safeguard exists for these).**
  - The template field names equal the driver's Step 1.7 verbatim strings — load-bearing, since nothing catches a mismatch at run time ([D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source)).
  - "Implementation skill" is the single field name; `Expected paths` and `Depends on` are unchanged.
  - The consumer skills spot-read (heading + `Depends on` only) confirms the schema passes through.
  - All references resolve; the docs are free of stale `Type` / AFK-only language.
  - CONTRIBUTING PR checklist: frontmatter under 1024 characters, no em-dashes, no voice violations, internal links resolve.
- **Test doubles posture:** Not applicable — no code under test; verification is fixture-based spot-run plus prose review.
- **Test levels:** Producer fixture spot-run and driver spot-runs stand in for integration/end-to-end; the field-name and prose review checks stand in for static verification.

## Definition of Done

- [ ] `work-item-template.md` carries the five per-item fields (Implementation skill, Review, Build unattended, Review unattended, Pre-work decision) plus unchanged `Expected paths` and `Depends on`; `Type` is removed ([D-11](artifacts/implementation-decision-log.md#d-11-work-item-schema-change)).
- [ ] `deliverable-skill-catalog.md` exists and holds the nature-to-skill map, the nature-to-review map, the han interactivity enumeration, the non-han declaration/default rule, and the not-installed fallback; Step 5 loads it; the driver holds no copy ([D-1](artifacts/implementation-decision-log.md#d-1-catalog-lives-in-a-new-producer-reference), [D-2](artifacts/implementation-decision-log.md#d-2-driver-reads-signals-not-the-catalog)).
- [ ] Producer Steps 5/7/8 record and print the five fields, the derived label, the driver-ready / needs-a-hand marker, override resolution, non-han suggestions, and a three-bucket closing recommendation that names `tdd` + `code-review` inline ([D-9](artifacts/implementation-decision-log.md#trivial-decisions), [D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)).
- [ ] The producer four-item fixture, the `tdd` + `human read` override, and the non-han case all classify as described in Testing Strategy.
- [ ] Driver Step 1.7 performs the three checks and surfaces two distinct refusals plus a pre-feature-file refusal; Steps 2.1/3.1/3.3/3.4 dispatch the recorded implementation skill and review in both build and fix rounds, preserving the `tdd` contract ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)).
- [ ] Driver spot-runs A, B, and C behave as described in Testing Strategy.
- [ ] The side-by-side review confirms the template field names equal the driver's Step 1.7 strings; "implementation skill" is the single name ([D-3](artifacts/implementation-decision-log.md#d-3-template-is-the-single-field-name-source)).
- [ ] Driver frontmatter and both contract opening sentences are updated for accuracy (AFK-typed to fully-autonomous), with no operative change ([D-6](artifacts/implementation-decision-log.md#d-6-driver-re-plumb-from-type-to-signals)).
- [ ] `docs/skills/han-planning/plan-work-items.md` and `docs/skills/han-coding/implement-work-items.md` are updated through `han-update-documentation`; the driver doc's stale "`/tdd` only; per-item selection deferred" note and "AFK-typed" prerequisites are removed ([D-10](artifacts/implementation-decision-log.md#trivial-decisions)).
- [ ] A consumer spot-read confirms `work-items-to-issues`/`-jira`/`-linear` pass the schema change through untouched (R4).
- [ ] The CONTRIBUTING PR checklist passes.
- [ ] All changes land in one atomic merge in the D-8 in-branch order ([D-8](artifacts/implementation-decision-log.md#d-8-atomic-ship-and-in-branch-sequencing)).

## Specialist Handoffs for Implementation

None outstanding. The only requested handoff, `structural-analyst`, ran in R1, and `test-engineer` supplied the full verification strategy; implementation is prompt-authoring the operator or agent performs directly, using `han-update-documentation` for the doc pass (Dep1).

## Deferred (YAGNI)

*Kept under YAGNI (tracked, not deferred): the three-signal decomposition itself is retained, because its consumer — the human-in-the-loop driver — is named upcoming work, which is accepted evidence (spec D4/F25). Its reopen risk is tracked in Assumption A1 and Risk R3, not here.*

### Driver-side copy of the catalog
- **Why deferred:** No consumer — the driver reads the recorded signals plus its own supported combination, not the interactivity enumeration ([D-2](artifacts/implementation-decision-log.md#d-2-driver-reads-signals-not-the-catalog)). A copy would be a single-source duplication and drift surface.
- **Reopen when:** A future driver must derive a skill's interactivity itself (for example, reading a non-han skill whose signals are not recorded).
- **Source:** R1, `structural-analyst` (claim C2).

### Per-item skill/review fields in `.implement-work-items/state.md`
- **Why deferred:** Constant across every driven item today — every driven item is `tdd` + `code-review` — so recording the fields is the symmetry/completeness anti-pattern.
- **Reopen when:** The driver supports a second combination.
- **Source:** R1, `junior-developer` (claim C7 / OQ-5).

### A shared supported-combo reference read by both skills
- **Why deferred:** Single consumer pair, so it is a single-implementation abstraction (the Rule of Three is not met). The coupling is managed editorially instead ([D-7](artifacts/implementation-decision-log.md#d-7-supported-combo-stated-inline-coupling-noted)).
- **Reopen when:** A second supported combination is added and drift between the two sites is observed.
- **Source:** R1, `structural-analyst` (claim C6 / OQ-2).

### Advertising overrides / skill-selection in the producer description and argument-hint
- **Why deferred:** No trigger-accuracy evidence that operators miss the override affordance; speculative discoverability work ([D-10](artifacts/implementation-decision-log.md#trivial-decisions)).
- **Reopen when:** Measured invocation misses show operators are not finding the override affordance.
- **Source:** R1, `junior-developer` / `test-engineer` (claim C9).

## Open Items

None blocking. The three mechanisms the spec deferred to plan-implementation — installed-skill detection, the override grammar, and the non-han autonomy-declaration syntax — were resolved this run as [D-4](artifacts/implementation-decision-log.md#d-4-installed-skill-detection-from-the-session-registry) and [D-5](artifacts/implementation-decision-log.md#d-5-override-channels-invocation-instruction-and-pre-written-marker) (round OQ-3, OQ-4), so nothing remains to block implementation.

## Summary

- **Outcome delivered:** The producer records a per-item implementation skill, review, and three autonomy signals in place of `Type`, and the driver computes autonomy from the signals and dispatches the recorded skill and review per item, refusing the whole run at startup when any item is not fully autonomous or is of an unsupported combination.
- **Team size:** 4 specialists — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 1 — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 11 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 9 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by user input:** 0 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Rejected alternatives recorded:** 19 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 0
- **Recommendation:** Ship as planned — build by hand or by invoking the skills directly (this feature is not self-drivable), verify by review plus spot-run, and merge atomically.
