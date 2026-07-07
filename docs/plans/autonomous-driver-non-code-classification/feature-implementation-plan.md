# Feature Implementation Plan: Non-code, meta, and non-deliverable work items

This plan edits two coordinating Claude Code skills — the producer `plan-work-items` and the driver `implement-work-items` — plus their reference contracts, one classification catalog, and one work-item template, so a plan whose deliverables are non-code, meta, or non-deliverable classifies and drives end-to-end with the no-output relaxations guarded rather than silent. It is a markdown skill-authoring change with no application code, no infrastructure, and no automated test harness; verification is read-the-file contract checks plus manual dry-runs.

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md) (spec decisions D1–D19)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md) (F1–F13)
- **Specification technical notes:** [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md) (T1 is a committed mechanic this plan honors)
- **Discovery notes:** [artifacts/.discovery-notes.md](artifacts/.discovery-notes.md)
- **Specification decisions this plan inherits:** D1, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19 (D2 is the medium-sizing rationale).
- **Specification open items this plan must respect or resolve:** none (the spec's Open Items list is empty). The spec's named `plan-implementation` handoffs — F13 (catalog second-home edits) and F14 (spike Expected-path handoff and finding-soundness review) — are resolved here by [D-4](artifacts/implementation-decision-log.md#d-4-catalog-gains-three-rows-a-row-reframe-an-exempt-note-and-an-overrides-refusal-rule), [D-6](artifacts/implementation-decision-log.md#d-6-template-puts-type-first-and-renames-tests-to-verification-with-the-d18-narrowing), [D-11](artifacts/implementation-decision-log.md#d-11-the-spike-build-dispatch-carries-the-expected-path-to-the-builder), and [D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker); the AFK-with-escalation enhancement (spec D19) stays deferred.

## Outcome

When this plan is executed, the producer `plan-work-items` classifies non-code, meta, and non-deliverable work against three new catalog homes and records the markers the driver reads; the driver `implement-work-items` validates those markers with four startup refusals, drives an agent-drafted non-code build unattended, drives a no-output verification to a distinct no-commit completion, and drives a spike to a committed finding under a human soundness review — all with no catalog override and no repurposed template field.

Concretely, in the codebase:

- The driver body gains a `Type` parse and four `Type`-coupled startup refusals in Step 1.7 ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file), [D-3](artifacts/implementation-decision-log.md#d-3-refusal-check-sub-order-one-refusal-per-halted-item)), a no-output branch in Step 3.4, a distinct `done-no-commit` terminal state in `state.json`, and a no-commit outcome bucket in Step 4 and the Halt Procedure ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit)).
- The two build/review contracts gain a skill-less shape, a no-output shape, and a no-output review branch, generalized in place ([D-5](artifacts/implementation-decision-log.md#d-5-both-contract-files-are-generalized-in-place)).
- The producer catalog gains an edit-existing-plugin row, verification and spike rows, a reframed catch-all, a `general-purpose`-exempt note, an idempotency constraint line, and an Overrides refusal rule ([D-4](artifacts/implementation-decision-log.md#d-4-catalog-gains-three-rows-a-row-reframe-an-exempt-note-and-an-overrides-refusal-rule), [D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template)); the template gains a `Type`-first routing field, a `Tests`→`Verification` rename, and the D18 ordered-trigger narrowing ([D-6](artifacts/implementation-decision-log.md#d-6-template-puts-type-first-and-renames-tests-to-verification-with-the-d18-narrowing)).

The change touches these files:

- `han-coding/skills/implement-work-items/SKILL.md` (Step 1.7 refusals, Step 3.3 spike dispatch and no-output routing, Step 3.4 no-output branch, `state.json` schema, Step 4 and Halt Procedure).
- `han-coding/skills/implement-work-items/references/build-report-contract.md` and `references/human-review-capture.md` (generalized in place).
- A new no-output-mechanics reference file under `han-coding/skills/implement-work-items/references/` (the compaction split).
- `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md` and `references/work-item-template.md`.
- The two long-form docs `docs/skills/han-coding/implement-work-items.md` and `docs/skills/han-planning/plan-work-items.md`.

## Context

- **Driving constraint:** The operator is moving the larger autonomous-driver design in small, buildable chunks. The shipped HITL chunk drives needs-a-human items but has no home for non-code, meta, or non-deliverable work; this chunk adds the classification model and guards the no-output relaxations so they cannot pass a broken or no-op build green.
- **Stakeholders:** The operator, who wants a mixed plan (application code plus docs, skills, verification passes, spikes) to classify and drive with no manual override. Future skill authors, who inherit the driver body as a pattern and pay the maintenance cost of anything added to it.
- **Future-state concern:** The driver body is already at the ~5k post-compaction context cap. This feature is net growth at ~5 body sites with no offsetting deletion, so a mid-run compaction could drop the very guards it adds; new mechanics are pushed to a reference file and the body is gated against the cap ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)).
- **Out-of-scope boundary:** The AFK-with-escalation dispatch instruction and escalate-and-resume stay deferred (spec D19); the build-report contract does not gain a `blocked`-from-skill-gate path this feature. Atomic co-land as a first-class inter-item relationship (spec F4) and the tech-notes reference boundary (spec F7) stay deferred. No shared cross-plugin refusal file is built ([D-2](artifacts/implementation-decision-log.md#d-2-no-shared-cross-plugin-refusal-file-deliberate-duplication-with-atomic-co-land)). The build and review skills and agents themselves are unchanged; only the driver, the producer, and their contracts change.

## Team Composition and Participation

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `han-core:project-manager` | Coordinator | Aggregated the R1 and R2 claim ledgers and synthesized this plan; aggregation was deterministic and the spec-maturity gate did not trip (0 T#-contradictions, 0 spec-level findings). |
| `han-core:junior-developer` | Active (R1) | Surfaced the Open-Question map (no-ADR-store fallback, guidance link, spike Expected-path to builder, compaction budget, general-purpose exemption, verification set, idempotency audit, `Type` placement); the resolutions came from evidence and specialist design, not reframing. |
| `han-core:structural-analyst` | Active (R1) | Refusals inline ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)); no shared refusal file ([D-2](artifacts/implementation-decision-log.md#d-2-no-shared-cross-plugin-refusal-file-deliberate-duplication-with-atomic-co-land)); catalog three-rows-plus-reframe ([D-4](artifacts/implementation-decision-log.md#d-4-catalog-gains-three-rows-a-row-reframe-an-exempt-note-and-an-overrides-refusal-rule)); contracts generalized in place ([D-5](artifacts/implementation-decision-log.md#d-5-both-contract-files-are-generalized-in-place)); `Type`-first template ([D-6](artifacts/implementation-decision-log.md#d-6-template-puts-type-first-and-renames-tests-to-verification-with-the-d18-narrowing)). |
| `han-core:edge-case-explorer` | Active (R1) | Refusal sub-order ([D-3](artifacts/implementation-decision-log.md#d-3-refusal-check-sub-order-one-refusal-per-halted-item)); the general-purpose exemption ([D-7](artifacts/implementation-decision-log.md#trivial-decisions)); the no-output quadrant and clean-tree assertion; producer override-refusal decision points; the AFK-spike gate enumeration; backward-compat read paths. |
| `han-core:on-call-engineer` | Active (R1) | The distinct no-output state marker and Step 3.4 branch ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit)); the idempotency wiring ([D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template)); the clean-tree attribution placement ([D-10](artifacts/implementation-decision-log.md#d-10-clean-tree-assertion-at-no-output-completion-with-a-step-31-backstop)); the no-commit trace; the spike-review soundness default ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)); the compaction body-size gate. |
| `han-core:test-engineer` | Active (R2) | Consolidated the C-1..C-12 and A-1..A-12 verification set; designed PD-1 and PD-2 as Definition-of-Done gates; adjudicated OQ-4, confirming the `none, HITL` spike-review default covers both gate-behavior predictions ([D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)). |

## Implementation Approach

The change extends signals the producer already records and generalizes contracts the driver already parses. It adds no new tool grant and no new agent; `allowed-tools` stays exactly as it is today (no `Skill`, no `AskUserQuestion`). The producer and driver share one marker vocabulary, so the two edits reconcile in one atomic commit ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)), with the refusal set stated in full in each skill rather than a shared file ([D-2](artifacts/implementation-decision-log.md#d-2-no-shared-cross-plugin-refusal-file-deliberate-duplication-with-atomic-co-land)).

### Architecture and Integration Points

The producer is `han-planning/skills/plan-work-items/` and the driver is `han-coding/skills/implement-work-items/`. The integration points this plan touches:

- **Startup validation (driver Step 1.7).** The four `Type`-coupled refusals extend the existing validation bullets inline: the `` `none`, AFK `` refusal joins the "Drivable" bullet, and a new semantic bullet carries `Type` validity, `Expected paths: None`-on-non-`verification`, and `AFK`-review-on-`verification`-or-`None`, checked in that sub-order with one refusal reported per halted item ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file), [D-3](artifacts/implementation-decision-log.md#d-3-refusal-check-sub-order-one-refusal-per-halted-item)). The "Drivable" bullet also carves out `general-purpose` as a built-in, always-available agent so an agent-drafted build is never a not-installed halt ([D-7](artifacts/implementation-decision-log.md#trivial-decisions), spec [T1](artifacts/feature-technical-notes.md#t1-general-purpose-is-a-built-in-always-available-agent-type)).
- **The build and review contracts.** `build-report-contract.md` and `human-review-capture.md` are generalized in place: the empty-FILES halt becomes conditional (still fires for a declared-output item, but a declared-no-output build may report `built` with empty FILES), a skill-less general-purpose build reports without a skill-gate claim, and the human-review capture gains a no-output branch that confirms the result rather than pointing at an absent change ([D-5](artifacts/implementation-decision-log.md#d-5-both-contract-files-are-generalized-in-place)). A new reference file holds the multi-step no-output mechanics (clean-tree assertion, no-commit recording, summary labeling) that Step 3.4, Step 4, and the Halt Procedure point to ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)).
- **The producer catalog.** `deliverable-skill-catalog.md` gains an edit-existing-plugin-definition row, a non-deliverable cluster of verification and spike rows before the catch-all, and a reframe of the "Other work related to Claude Code plugins" row from `` `han-plugin-builder:guidance`, AFK `` to `` `general-purpose` agent, AFK ``; the never-auto-`AFK` guardrail gains the `general-purpose`-exempt parenthetical, and the Overrides note gains the decline-the-field refusal rule ([D-4](artifacts/implementation-decision-log.md#d-4-catalog-gains-three-rows-a-row-reframe-an-exempt-note-and-an-overrides-refusal-rule)).
- **The template.** `work-item-template.md` gains `Type` as the first routing field before `Requires pre-work decisions`, renames `Tests` to a type-aware `Verification` field in place, and narrows the `Requires pre-work decisions` trigger to the D18 ordered ladder ([D-6](artifacts/implementation-decision-log.md#d-6-template-puts-type-first-and-renames-tests-to-verification-with-the-d18-narrowing)).

### Data Model and Persistence

The persisted state is the work-state file `.implement-work-items/state.json`, whose per-item record is `{state, fix-round, scope-baseline, decision, commit-range}`. This plan adds one terminal state value, `done-no-commit`, that the Step 3.4 no-output branch sets, and that Step 4, the Halt Procedure, and the in-session re-grounding all branch on ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit)). A single distinct terminal state is chosen over `done` plus a separate `no-commit` boolean because it cannot fall internally inconsistent.

Two producer-side authored fields carry data, not driver-parsed markers: the `Type` field (`deliverable`, `verification`, `spike`; absent defaults to `deliverable`) and the renamed `Verification` field. The catalog's verification row and the template's `Verification` guidance carry an authored idempotency constraint line — a no-output verification must be side-effect-free and safe to re-run, because the amnesiac fresh-branch recovery re-runs it from the first item with no commit to skip it ([D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template)). A record-worthy pre-work decision routes to the target repo's decision-record home (an ADR store if present, else the plan's own decision log), with the inline flag retained for single-sentence judgment calls ([D-14](artifacts/implementation-decision-log.md#d-14-a-record-worthy-pre-work-decision-routes-to-the-repo-decision-record-home-or-the-plan-decision-log)).

### Runtime Behavior

The per-item loop gains the routing the spec's Primary Flow describes, keyed off the item's recorded markers:

- **Validate.** Step 1.7 reads `Type` and applies the four refusals in sub-order before any mutation; a missing `Type` defaults silently to `deliverable`, preserving backward compatibility with files that predate the field ([D-3](artifacts/implementation-decision-log.md#d-3-refusal-check-sub-order-one-refusal-per-halted-item)).
- **Build.** An agent-drafted non-code build dispatches a `general-purpose` agent that reports through the skill-less contract shape. A spike build dispatches the routed skill (`investigate` / `research` / general-purpose) with the item's Expected path carried in the dispatch as the finding target, so the finding lands on-path ([D-11](artifacts/implementation-decision-log.md#d-11-the-spike-build-dispatch-carries-the-expected-path-to-the-builder)). A declared-no-output verification build is dispatched knowing zero files is the expected result.
- **Review.** A spike's review is a human soundness read (`` none, HITL ``) independent of the build marker, so an AFK reviewer cannot rubber-stamp a well-formed but bad or incomplete finding, and the read fires before the driver advances to any dependent item ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)). A no-output item's review is a human result-confirmation; if such an item unexpectedly left files, the reviewer surfaces them as a scope finding.
- **Commit.** Step 3.4 gains a no-output branch: a `verification` item that declared `Expected paths: None` and produced no diff since `scope-baseline` skips the commit and is recorded `done-no-commit`, with a primary clean-tree assertion at its own completion so any stray files are attributed to it; a Step 3.1 backstop assertion covers the general case ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit), [D-10](artifacts/implementation-decision-log.md#d-10-clean-tree-assertion-at-no-output-completion-with-a-step-31-backstop)).
- **Summarize.** Step 4 names no-commit completions as their own outcome bucket (item, `Type`, `Expected paths: None`, count), and the Halt Procedure names them distinctly (they carry no commit and are not in the cherry-pick range) ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit)).

### External Interfaces

None. The change adds no API, event, queue, or third-party integration, and no new tool grant. The producer→driver marker vocabulary is an internal shared contract, reconciled by co-landing both edits ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)).

## Decomposition and Sequencing

The order respects three gates: generalize the contracts before the driver body relies on their new shapes; keep the Step 1.7 refusals, the Step 3 routing, and the `state.json` change as one atomic driver edit; and co-land the producer catalog and template with the driver change so the shared vocabulary is never inconsistent ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)).

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | Generalize the two contracts in place | `build-report-contract.md` skill-less and no-output shapes; `human-review-capture.md` no-output branch ([D-5](artifacts/implementation-decision-log.md#d-5-both-contract-files-are-generalized-in-place)) | none | C-6, C-9 |
| 2 | Author the no-output-mechanics reference file | The clean-tree assertion, no-commit recording, and summary labeling, as a reference Step 3.4 / Step 4 / Halt point to ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)) | none | C-7, C-8 |
| 3 | Atomic driver `SKILL.md` edit | Step 1.7 four refusals and sub-order, general-purpose exemption; Step 3.3 spike Expected-path dispatch and no-output build/review routing; Step 3.4 no-output branch; `state.json` `done-no-commit`; Step 4 no-commit bucket; Halt trace ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file), [D-3](artifacts/implementation-decision-log.md#d-3-refusal-check-sub-order-one-refusal-per-halted-item), [D-7](artifacts/implementation-decision-log.md#trivial-decisions), [D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit), [D-10](artifacts/implementation-decision-log.md#d-10-clean-tree-assertion-at-no-output-completion-with-a-step-31-backstop), [D-11](artifacts/implementation-decision-log.md#d-11-the-spike-build-dispatch-carries-the-expected-path-to-the-builder)) | 1, 2 | C-1..C-5, C-7, C-8, C-12; A-1..A-10, A-12 |
| 4 | Producer catalog and template edits | Three catalog rows, the reframe, the exempt note, the idempotency line, the Overrides refusal rule; template `Type`-first, `Tests`→`Verification`, D18 narrowing ([D-4](artifacts/implementation-decision-log.md#d-4-catalog-gains-three-rows-a-row-reframe-an-exempt-note-and-an-overrides-refusal-rule), [D-6](artifacts/implementation-decision-log.md#d-6-template-puts-type-first-and-renames-tests-to-verification-with-the-d18-narrowing), [D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template), [D-14](artifacts/implementation-decision-log.md#d-14-a-record-worthy-pre-work-decision-routes-to-the-repo-decision-record-home-or-the-plan-decision-log)) | co-lands with 3 | C-10, C-11; A-11 |
| 5 | Long-form docs and voice pass | `docs/skills/han-coding/implement-work-items.md` and `docs/skills/han-planning/plan-work-items.md` updated; writing-voice pass across edited files | 1–4 | CONTRIBUTING coverage rule; voice pass |
| 6 | Verification pass | C-1..C-12 read-the-file checks; A-1..A-12 dry-runs; PD-1 (idempotency) and PD-2 (spike-gate) proving runs ([D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)) | 1–5 | Definition of Done |

Units 3 and 4 land as one atomic change so the driver, its contracts, and the producer catalog and template are never mutually inconsistent; units 1 and 2 land in the same commit or sequenced before unit 3 ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)).

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | A mid-run compaction truncates the net-added guards (clean-tree assertion, no-output branch, no-commit trace), reverting the body to pre-feature behavior with the guards gone | Medium | Medium | Any run long enough to compact | High (re-invoke fresh on a clean branch) | implementer | Push the no-output mechanics to a reference file; keep only short refusal rules inline; add a body-size Definition-of-Done gate measuring the body against ~5k ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)) |
| R2 | An AFK interactive-skill spike hitting an operator gate returns a well-formed but bad or incomplete finding that passes the fail-closed parse and commits, propagating to a dependent item | Medium | High | The spike finding and any dependent item that consumes it | High | The spike review defaults to `` none, HITL `` independent of the build marker, so the human soundness read fires before any dependent item; PD-2 makes it observable ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker), [D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)) |
| R3 | A no-output verification in a target repo runs a side-effecting check (a database or staging API), so the amnesiac fresh-branch re-run is not safe to repeat | Low | Medium | The re-run's side effect in the target repo | Medium | Author the side-effect-free constraint line in the catalog verification row and template `Verification` guidance; PD-1 proves the in-repo read-only case ([D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template)) |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | The plugin-authoring guidance the edit-existing and catch-all classifications link is reachable (installed or vendored) in the target repo | The build agent drafts with none of the authoring rules, and the required human read on an executable plugin artifact is the only backstop | A real run in a target repo; the human read ([spec D16](artifacts/decision-log.md#d16-an-edit-to-an-executable-plugin-artifact-requires-a-human-read)) | Accepted; the spec surfaces the reachability assumption ([spec D15](artifacts/decision-log.md#d15-the-catalog-gains-classification-homes-for-verification-and-spike-and-links-guidance)) and D16's human read is the committed backstop ([spec D16](artifacts/decision-log.md#d16-an-edit-to-an-executable-plugin-artifact-requires-a-human-read)) |

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| Dep1 | The producer catalog and template edits (`plan-work-items`) ship in the same change as the driver `SKILL.md` and contract edits (`implement-work-items`), so the shared marker vocabulary is never inconsistent | implementer | Committed ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)) |

## Testing Strategy

No automated harness exists for skill behavior (discovery notes), so verification is read-the-file contract checks plus manual dry-runs against the contracts, consolidated by test-engineer ([D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)).

- **Observable behaviors to test:** the four refusals fire singly and compound in the correct sub-order before any mutation; a missing `Type` defaults to `deliverable` and `Type` is not required; `general-purpose` is exempt from the drivability check; a no-output verification completes as a distinct `done-no-commit` outcome; stray files surface as a scope finding with a clean-tree assertion at completion; the build report accepts skill-less and no-output shapes while the empty-FILES halt still fires for a declared-output item; the human-review capture presents a result-confirmation for a no-output item; the catalog gains three rows, the reframe, the exempt note, and the Overrides refusal rule; the template puts `Type` first, renames `Tests` to `Verification`, and narrows D18 in template and catalog; the spike build carries the Expected path to the builder and the spike review is `` none, HITL `` regardless of the build marker; the producer declines a refused override and restores the catalog base without transforming `Type`; an old file drives identically.
- **Read-the-file contract checks (C-1..C-12):** C-1 refusal placement and sub-order (Step 1.7); C-2 `Type` parsing and backward compatibility (Step 1.7); C-3 `Expected paths: None` gating (Step 1.7); C-4 the `AFK`-review and `none, AFK` build refusals (Step 1.7); C-5 `general-purpose` exempt from drivability (Step 1.7); C-6 the build-report skill-less and no-output shapes (`build-report-contract.md`); C-7 the Step 3.4 no-output branch and clean-tree assertion at completion; C-8 `state.json` distinct terminal state, Step 4 no-commit bucket, Halt trace; C-9 the human-review no-output branch (`human-review-capture.md`); C-10 catalog rows, reframe, exempt note, Overrides refusal rule (`deliverable-skill-catalog.md`); C-11 template `Type` field, `Verification` rename, D18 narrowing (`work-item-template.md` plus the catalog classification step); C-12 the spike dispatch carries the Expected path and the spike review is `` none, HITL `` (Step 3.3).
- **Dry-run scenarios (A-1..A-12):** A-1 backward-compat old file; A-2 fully-autonomous deliverable regression; A-3 `none, AFK` refusal; A-4 invalid `Type` refusal; A-5 deliverable/spike + `None` refusal; A-6 verification + `AFK`-review refusal; A-7 compound refusal naming all offenders; A-8 no-output verification clean no-commit with labeled summary and `done-no-commit`; A-9 no-output verification stray files to a scope finding and clean-tree assertion; A-10 general-purpose non-code build skill-less report; A-11 producer declines a refused override; A-12 human-review no-output branch.
- **Proving runs (Definition-of-Done gates):** PD-1 (idempotency, spec D14) — a no-output verification completes `done-no-commit` on branch A, then re-executes safely on a fresh branch B after a later-item halt, producing no artifact outside the gitignored `.implement-work-items/`; falsified by a side-effecting check or cross-branch state bleed. PD-2 (spike-gate, spec D19 / OQ-4) — an AFK interactive-skill spike dispatched into each of the four gates (mis-route, too-vague clarify, compound multi-thread, re-run overwrite) either halts before any commit, or commits a finding and the `` none, HITL `` review fires before any dependent item consumes it; falsified only by a committed finding that bypasses the human review, which escalates to the spec owner ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker), [D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)).
- **Test doubles posture:** none; the dry-runs exercise the real skills against scratch work-items files. Golden-file snapshots over free-form agent returns are non-deterministic noise and are deferred.
- **Edge cases requiring coverage:** compound refusals reporting one offender (A-7); a no-output item that unexpectedly leaves files (A-9); a fabricated-but-plausible spike finding reaching commit (PD-2); a side-effecting no-output check on re-run (PD-1).
- **Test levels:** contract conformance (C-1..C-12) and end-to-end dry-run (A-1..A-12); there is no unit or integration layer for markdown skill behavior.

## On-Call Resilience Posture

This is a single-threaded, one-item-at-a-time, local-git markdown driver: no concurrency, no network, no queue, so timeouts, retries, bulkheads, backpressure, and kill switches have no surface and none are added (on-call-engineer). The application-source resilience commitments this plan makes:

- **Idempotency:** a no-output verification must be side-effect-free and safe to re-run, because the amnesiac fresh-branch recovery re-runs it from the first item with no commit to skip it; the commitment is authored as a constraint line in the catalog verification row and the template `Verification` guidance, and proved by PD-1 ([D-9](artifacts/implementation-decision-log.md#d-9-idempotency-is-wired-as-an-authored-constraint-line-in-the-catalog-and-template)).
- **Data integrity:** the primary clean-tree assertion at a no-output item's own completion attributes any stray files to the item that produced them and gates them as a scope finding, with a Step 3.1 backstop before the `scope-baseline` snapshot so stray files cannot contaminate the next item's scope window ([D-10](artifacts/implementation-decision-log.md#d-10-clean-tree-assertion-at-no-output-completion-with-a-step-31-backstop)).
- **Observability of failure paths:** a no-output completion is recorded as the distinct terminal state `done-no-commit` and named as its own outcome bucket in the completion summary and the Halt Procedure, so a legitimately-empty verification is never indistinguishable from a silently-slipped no-op ([D-8](artifacts/implementation-decision-log.md#d-8-no-output-completion-is-the-distinct-terminal-state-done-no-commit)).
- **Graceful degradation:** an AFK interactive-skill spike that hits an operator gate fails recoverably (the fail-closed parse halts, committed items stay, the tree is clean, the run re-invokes fresh); a well-formed bad finding that reaches commit is caught by the `` none, HITL `` soundness review before any dependent item consumes it ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)). A mid-run compaction is contained by pushing the no-output mechanics to a reference file and gating the body size ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)).

## Definition of Done

- [ ] C-1..C-12 read-the-file contract checks pass.
- [ ] A-1..A-12 dry-runs pass, including PD-1 (idempotency) and PD-2 (spike-gate) as gates ([D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)).
- [ ] PD-2 shows the `` none, HITL `` spike review fires before any dependent item in every committed-finding path; no gate bypasses it ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)).
- [ ] Regression confirmed: A-1 (old file) and A-2 (fully-autonomous deliverable) drive unchanged, and the still-applicable Step 1.7 refusals still fire.
- [ ] The four refusals stay inline in Step 1.7 and the no-output mechanics live in a reference file; a body-size gate measures the post-edit body against ~5k and applies the split further if over ([D-1](artifacts/implementation-decision-log.md#d-1-four-refusals-inline-in-step-17-no-output-mechanics-to-a-reference-file)).
- [ ] The Step 1.7 refusals, Step 3 routing, Step 3.4 no-output branch, `state.json` `done-no-commit`, Step 4 no-commit bucket, and Halt trace land as one atomic `SKILL.md` edit; the producer catalog and template ship in the same change ([D-15](artifacts/implementation-decision-log.md#d-15-driver-contracts-catalog-and-template-co-land-as-one-atomic-change)).
- [ ] The two long-form docs are updated per the CONTRIBUTING coverage rule.
- [ ] A writing-voice pass across all edited files: no em-dashes, no banned words (`leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`).
- [ ] `allowed-tools` is unchanged: no `Skill`, no `AskUserQuestion`.

## Specialist Handoffs for Implementation

- **`han-core:test-engineer`** — dispatch when the atomic driver `SKILL.md` edit, the two contracts, the no-output-mechanics reference file, and the catalog and template edits are drafted; needs the edited files to run the C-1..C-12 conformance reading and to script and execute the A-1..A-12 dry-runs and the PD-1 and PD-2 proving runs.
- **`han-core:edge-case-explorer`** — dispatch to validate the PD-2 spike-gate dry-run against the four gates and the A-9 stray-files scope-finding; needs the edited Step 3.3 spike dispatch and the Step 3.4 no-output branch.
- **`han-core:on-call-engineer`** — dispatch to validate the PD-1 idempotency run and the clean-tree, no-commit-trace, and `done-no-commit` commitments; needs the edited Step 3.4, Step 4, Halt Procedure, and `state.json` schema.

## Deferred (YAGNI)

### Shared cross-plugin refusal reference file

- **Why deferred:** simpler-version and single-implementation-abstraction test — the refusal set has two consumers today, and a shared file is the lightest cross-skill enforcement machinery the spec's Out of Scope forbids; it also crosses the `han-planning`→`han-coding` boundary the suite has no cross-plugin reference mechanism for. Deliberate duplication with an atomic co-land satisfies the same need ([D-2](artifacts/implementation-decision-log.md#d-2-no-shared-cross-plugin-refusal-file-deliberate-duplication-with-atomic-co-land)).
- **Reopen when:** a third skill, or a cross-suite enforcement mechanism, needs the refusal vocabulary.
- **Source:** R1, structural-analyst.

### A driver refusal on an AFK spike review (a fifth refusal)

- **Why deferred:** simpler-version test — the catalog `` none, HITL `` default plus the PD-2 proving run satisfy spec D8's intent without expanding the spec's bounded four-refusal contract, and the compaction budget argues against another inline refusal ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)). The residual is that a hand-edited AFK-spike-review is not refused by the driver, carried as OI-1.
- **Reopen when:** a hand-edited AFK-spike-review is observed to rubber-stamp a bad finding.
- **Source:** R1, on-call-engineer (recommended the catalog-default-only guard).

### AFK-with-escalation dispatch instruction and escalate-and-resume

- **Why deferred:** out of scope per spec D19 — an enhancement, not a prerequisite; the build-report contract does not gain a `blocked`-from-skill-gate path this feature, so an AFK spike gate halts recoverably rather than escalating cleanly.
- **Reopen when:** the driver gains escalate-and-resume (the separate `autonomous-driver-resume` feature).
- **Source:** spec D19; R1, edge-case-explorer.

### Automated test scaffolding and golden-file snapshots

- **Why deferred:** tests for a harness that does not exist; golden-file snapshots over free-form agent returns are non-deterministic noise. Verification is read-the-file checks plus manual dry-runs ([D-13](artifacts/implementation-decision-log.md#d-13-verification-is-read-the-file-checks-plus-dry-runs-with-two-proving-runs-as-gates)).
- **Reopen when:** a skill-test framework is added to the repo.
- **Source:** R2, test-engineer (predecessor precedent).

### Compaction-survival re-grounding for AFK loops

- **Why deferred:** resilience machinery for a failure mode with no demonstrated incident; `state.json` already gives compaction-durable position, and the reference-file split plus body-size gate contain the known risk.
- **Reopen when:** a compaction during a long AFK run is observed to drop the guards.
- **Source:** R1, on-call-engineer (predecessor precedent).

## Open Items

- **OI-1 (hand-edit residual):** A hand-edited `spike` item carrying an `AFK` review is not refused by the driver — the catalog never emits that combination, so the produced case is covered by PD-2, but a hand-edit bypasses the producer and there is no fifth driver refusal.
  - **Resolves when:** a hand-edited AFK-spike-review is observed to rubber-stamp a bad finding, at which point the fifth-refusal YAGNI reopens ([D-12](artifacts/implementation-decision-log.md#d-12-the-spike-review-defaults-to-a-human-soundness-read-independent-of-the-build-marker)).
  - **Blocks implementation:** No — the produced path is guarded by the `` none, HITL `` default and PD-2; only the hand-edited path is uncovered, and the spec's four-refusal contract is deliberately bounded.
- **OI-2 (D19 falsification trigger):** If PD-2 during implementation shows a committed spike finding that bypasses the `` none, HITL `` review (the driver advancing a dependent item without the human read), that falsifies spec D19's "not corruption" premise.
  - **Resolves when:** PD-2 confirms the review always gates before any dependent item; if it does not, escalate to the spec owner rather than plan around it.
  - **Blocks implementation:** No — this is a Definition-of-Done gate observed during the verification pass, not a pre-build blocker.

## Summary

- **Outcome delivered:** non-code, meta-editing, and non-deliverable work items classify and drive end-to-end with no catalog override or template strain, and the no-output relaxations are guarded by startup validation, a distinct no-commit state, and a human spike-soundness review rather than passed silently.
- **Team size:** 5 specialists (plus the coordinator) — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 2 — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 15 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 15 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by user input:** 0 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Rejected alternatives recorded:** 21 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 2 (OI-1 hand-edit residual, OI-2 D19 falsification trigger) — both non-blocking
- **Recommendation:** Ship as planned.
