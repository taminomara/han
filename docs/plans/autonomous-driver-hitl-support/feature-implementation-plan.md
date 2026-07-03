# Feature Implementation Plan: Autonomous Driver HITL Support

This plan edits two skill definitions and their reference files so the `implement-work-items` driver drives needs-a-human work items (a pre-work decision, a foreground interactive or free-form build, a human review) alongside the fully-autonomous items it already drives, and gates every review through one normalized verdict. It is a markdown skill-authoring change with no application code, no infrastructure, and no automated test harness; verification is dry-running the skills against their contracts.

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md)
- **Specification technical notes:** [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md) (T1 is a committed mechanic this plan honors)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md) (F1-F24)
- **Specification review findings:** [artifacts/review-findings.md](artifacts/review-findings.md) (F25)
- **Discovery notes:** [artifacts/.discovery-notes.md](artifacts/.discovery-notes.md)
- **Specification decisions this plan inherits:** D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15
- **Specification open items this plan must respect or resolve:** none (the spec's Open Items list is empty)

## Outcome

When this plan is executed, the `implement-work-items` driver reads each work item's `Suggested implementation`, `Suggested review`, and `Requires pre-work decisions` markers and routes each phase by them, rather than refusing any item that is not `tdd` plus `code-review`. A run can mix unattended items with items that need a human: an item can pause for a pre-work decision, run its build in the foreground with the operator steering (a named interactive skill or a free-form `none` build), or take a human read as its review. Every review path, a `code-review` sub-agent, a non-code review agent, or a human read, returns one normalized verdict the driver gates on identically. The driver still verifies every build itself, still owns every commit, still processes one item at a time, and still halts the whole run on the first item it cannot finish cleanly. What changes is that "cannot finish cleanly" no longer includes "this item needs a human."

The change touches these files:

- `han-coding/skills/implement-work-items/SKILL.md` (the driver body: Step 1.7 validation, Step 3 routing, work-state file, phase names, completion summary, `description` frontmatter).
- `han-coding/skills/implement-work-items/references/review-verdict-contract.md` (generalized in place into the one normalized verdict).
- `han-coding/skills/implement-work-items/references/build-report-contract.md` (intro and parentheticals generalized off `tdd`).
- Two new files under `han-coding/skills/implement-work-items/references/`: `foreground-handoff-protocol.md` and `human-review-capture.md`.
- `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md` (the companion catalog correction).
- The two long-form docs `docs/skills/han-coding/implement-work-items.md` and `docs/skills/han-planning/plan-work-items.md`.

## Context

- **Driving constraint:** The operator is moving the larger autonomous-driver design in small, buildable chunks. The shipped core loop refuses needs-a-human items; this chunk adds the operator's flowchart (decide, foreground build, human review) plus the one hard problem the operator wanted planned now, review-output consistency across code and non-code reviews ([D1](artifacts/decision-log.md#d1-scope-hitl-support-and-a-normalized-review-gate)).
- **Stakeholders:** The operator, who runs mixed work-items files and wants a mostly-unattended run that pauses only where a human is genuinely needed. Future skill authors, who inherit the driver body as a pattern and pay the maintenance cost of anything added to it.
- **Future-state concern:** The driver body is already at the post-compaction context budget (`context-hygiene.md`, roughly 5k per skill). Adding HITL detail inline risks the body being dropped after a compaction during a long run, so new detail is pushed to reference files and the routing constraint is front-loaded ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline), [D-4](artifacts/implementation-decision-log.md#d-4-work-state-file-gains-scope-baseline-and-fix-round-fields)).
- **Out-of-scope boundary:** Cross-session resume, mid-run clean-stop, compaction-survival re-grounding, the rich blocker menu, skip/defer, repair-upstream, and parallel execution stay deferred, unchanged from the spec ([D1](artifacts/decision-log.md#d1-scope-hitl-support-and-a-normalized-review-gate)). No changes are made to the build or review skills and agents themselves (`tdd`, `code-review`, `content-auditor`, `information-architect`, `skill-builder`, and so on); only the driver and the producer catalog change.

## Team Composition and Participation

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Aggregated the R1 claim ledger and synthesized this plan (no facilitation pass; the spec-maturity gate did not trip). |
| `software-architect` | Active | The operator hand-off over a `Skill` call (A1); one verdict contract generalized in place over a translating adapter agent (A2); the two-file consumer analysis (A3). |
| `test-engineer` | Active | The read-the-file contract checks C1-C8 and the dry-run scenarios A1-A10, including the proving dry-runs A3 and A7b. |
| `edge-case-explorer` | Active | The fix-round-counter infinite-loop hole (M10); the atomic Step 1.7 plus Step 3 edit (H5); the commit-adoption branch (C3); the drivability mechanism (M11); the pre-decision halt frame (M9). |
| `junior-developer` | Active | Pinning the spec word "invokes" to a hand-off (JD-003); the YAGNI agreement on the dispatch-instruction contract (JD-008); the `--gate critical` consequence (JD-007); the unfinished-foreground bounded prompt (JD-010). |
| `behavioral-analyst` | Stood down | Named as a possible handoff for the resume-reliability question; not applicable because that is Claude Code harness behavior, not codebase data flow, so a proving dry-run is the right instrument. |

## Implementation Approach

The change consumes signals the producer already records and generalizes contracts the driver already parses. It adds no new tool grant and no new agent. The driver keeps its Agent-only dispatch discipline: build and review sub-work still runs through the `Agent` tool, and the one new interaction pattern, the foreground build, is an operator hand-off rather than a `Skill` call ([D-1](artifacts/implementation-decision-log.md#d-1-foreground-build-is-an-operator-hand-off-not-a-skill-call)).

### Architecture and Integration Points

The driver is `han-coding/skills/implement-work-items/SKILL.md` with its `references/` contracts. The integration points this plan touches:

- **The review dispatch.** The existing depth-1 review dispatch, which runs `han-coding:code-review` and lets it fan out its panel at depth 2, is generalized into one parameterized dispatch that also runs the `han-core:content-auditor` and `han-core:information-architect` AGENTS. One depth-1 general-purpose sub-agent runs the skill or embodies the agent, then maps its output to the normalized verdict, so the driver keeps one fail-closed parser and one gate ([D-2](artifacts/implementation-decision-log.md#d-2-generalize-the-review-verdict-contract-in-place)). The severity mapping, per-source coverage attestation, code-or-document location rule, and reference-material requirement committed in [T1](artifacts/feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping) live as data in `review-verdict-contract.md`, generalized in place rather than in a second file or a translating adapter agent.
- **The foreground boundary.** A new consumer of the driver's control flow: for a HITL or `none` build the driver hands control to the operator and waits for a confirm-done message. The hand-off protocol, the `none` free-form build, confirm-done, the state-catch-up mechanism, the adopt-own-commits inspection, the bounded unfinished-foreground prompt, and the foreground pause markers live in the new `foreground-handoff-protocol.md` ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)).
- **The human-review capture.** A second new consumer: for a HITL review the driver captures the operator's findings into the normalized verdict. The capture, ask-missing-field, echo-back-with-threshold, confirm-finality, per-round overwrite, opt-in-pause merge, and review pause markers live in the new `human-review-capture.md` ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)).
- **The drivability check.** Step 1.7 gains a check that resolves each item's named implementation skill to an installed plugin's `skills/<name>/SKILL.md` or agent `.md` via Glob or find, aborting the whole run at startup on an unresolved named skill ([D-7](artifacts/implementation-decision-log.md#d-7-drivability-resolves-the-named-skill-to-an-installed-path)).
- **The producer catalog.** `deliverable-skill-catalog.md` in `plan-work-items` is corrected so every drivable item's review is one the driver can normalize; the three `guidance`-as-review rows become `manual read, HITL` ([D-13](artifacts/implementation-decision-log.md#trivial-decisions), spec [D6](artifacts/decision-log.md#d6-companion-catalog-correction-plus-driver-fallback)).

The decide-gate (spec D11) and the mixed-run signposting (spec D12) stay inline in SKILL.md rather than becoming their own files: the decide-gate has one call site and the signposting is short marker, preview, and summary lists ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)). The cleanup edits (generalizing `build-report-contract.md` off `tdd`, removing the drivable-run parentheticals, defining the D13 phase names, bounding the unfinished-foreground prompt) ride along so the touched files stay internally consistent ([D-12](artifacts/implementation-decision-log.md#d-12-cleanup-edits-carried-with-the-change)).

### Data Model and Persistence

The persisted state is the work-state file `.implement-work-items/state.md` and the durable review records under `.implement-work-items/reviews/`. This plan adds two per-item fields to the work-state file ([D-4](artifacts/implementation-decision-log.md#d-4-work-state-file-gains-scope-baseline-and-fix-round-fields)):

- `scope-baseline`: the commit the item's scope check diffs against. It is set at item start, or after the pre-work-decision commit when the item has one, so the decision edit is in neither the item's scope diff nor its item commit.
- `fix-round`: the per-item fix-round counter. It is load-bearing: state catch-up after a foreground fix round re-reads the work-state, so a counter kept only in the driver's context would reset and turn the bounded fix loop into an unbounded foreground loop. Neither field is reset on a fix round.

The D13 phase names (awaiting-decision, building-in-foreground, awaiting-review-feedback) are added to the work-state vocabulary alongside the current statuses so a HITL item's position is legible in the same place as an unattended item's.

### Runtime Behavior

The per-item loop gains the routing the spec's Primary Flow describes, all keyed off the item's recorded markers ([D-2 spec](artifacts/decision-log.md#d2-route-each-phase-by-the-recorded-signals)):

- **Decide.** When `Requires pre-work decisions` is `yes`, the driver pauses before any build, the operator records the decision where the item directs (or where the driver asks when the item is silent), the driver commits the durable edit, sets the item's `scope-baseline` after that commit, and carries the decision into the build. A rejected pre-decision commit halts with a distinct frame that states no build has started ([D-11](artifacts/implementation-decision-log.md#d-11-pre-work-decision-gate-mechanics)).
- **Build.** An `AFK` build dispatches a sub-agent as today. A `HITL` build hands off to the operator, with the driver recommending a manual compaction first, then waiting for confirm-done; a `none` build is free-form. On confirm the driver marks control returned and catches up on run state ([D-1](artifacts/implementation-decision-log.md#d-1-foreground-build-is-an-operator-hand-off-not-a-skill-call)).
- **Verify.** Unconditional and independent, whoever built the item, exactly as today; the build-report parse applies only to a sub-agent's return (spec [D3](artifacts/decision-log.md#d3-independent-verification-is-unconditional)).
- **Review.** An `AFK` review dispatches through the generalized contract and returns the normalized verdict; a `HITL` review foregrounds the human read and captures findings into the same verdict; a `none` review runs no gate. For an `AFK` review the driver checks after the sub-agent returns whether the operator opted in to a pause, and merges the operator's findings when a request is pending ([D-8](artifacts/implementation-decision-log.md#d-8-opt-in-review-pause-is-checked-after-the-sub-agent-returns)).
- **Fix.** Each round re-enters at BUILD routed by the build signal, never re-running Decide, and re-reviews through the same review path; a `none`-review item clears on a verification pass alone, stated at both the initial gate and inside the loop ([D-5](artifacts/implementation-decision-log.md#d-5-fix-loop-routing-and-none-review-clear-on-verify)). The persisted `fix-round` counter bounds the loop across foreground state catch-up.
- **Commit.** A dirty tree stages and commits by path as today; a clean tree with new commits since the `scope-baseline` triggers the driver's own cumulative-diff inspection and adopts the commit range instead of forcing an empty commit ([D-6](artifacts/implementation-decision-log.md#d-6-commit-step-adopts-a-foreground-skills-own-commits)).

One gate consequence is documented rather than fixed: under `--gate critical`, content-auditor (which emits only Warning) does not block, so content-audited items are effectively un-gated at that threshold, while the default `warning` gate is what gates doc facts and information-architect still gates under critical ([D-10](artifacts/implementation-decision-log.md#d-10-the-critical-gate-does-not-block-content-audited-items)). This is surfaced to the operator as an FYI (see Open Items).

### External Interfaces

None. The change adds no API, event, queue, or third-party integration, and no new tool grant. `allowed-tools` stays exactly as it is today (no `Skill`, no `AskUserQuestion`); the foreground hand-off and the async opt-in pause are message-based, not tool calls ([D-1](artifacts/implementation-decision-log.md#d-1-foreground-build-is-an-operator-hand-off-not-a-skill-call)).

## Decomposition and Sequencing

The order respects four gates: generalize the verdict contract before wiring non-code dispatch; keep the Step 1.7 loosening and the Step 3 routing as one atomic edit; prove the opt-in-pause mechanism before the SKILL.md wiring relies on it; and ship the companion catalog correction with the driver change.

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | Generalize the verdict contract | `review-verdict-contract.md` rewritten in place into the one normalized verdict, with the T1 severity mapping, per-source coverage, location rule, and reference-material requirement as data ([D-2](artifacts/implementation-decision-log.md#d-2-generalize-the-review-verdict-contract-in-place)) | none | C1, C2, C4 |
| 2 | Add the two protocol reference files | `foreground-handoff-protocol.md` and `human-review-capture.md` ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)) | 1 (capture references the normalized verdict) | C3, C4 reading; A5 |
| 3 | Prove the opt-in-pause mechanism | A resolved pending-request-detection approach, or the documented standing/pre-item fallback, recorded in `human-review-capture.md` ([D-8](artifacts/implementation-decision-log.md#d-8-opt-in-review-pause-is-checked-after-the-sub-agent-returns)) | 2 | A7b (proving dry-run) |
| 4 | Atomic SKILL.md edit | Step 1.7 loosening plus drivability check, Step 3 HITL routing (decide, foreground build, verify, normalized review, fix routing, commit branch), work-state fields, D13 phase names, `description` reworded off "fully-autonomous", completion-summary execution modes, D11 decide-gate and D12 signposting inline ([D-1](artifacts/implementation-decision-log.md#d-1-foreground-build-is-an-operator-hand-off-not-a-skill-call), [D-4](artifacts/implementation-decision-log.md#d-4-work-state-file-gains-scope-baseline-and-fix-round-fields), [D-5](artifacts/implementation-decision-log.md#d-5-fix-loop-routing-and-none-review-clear-on-verify), [D-6](artifacts/implementation-decision-log.md#d-6-commit-step-adopts-a-foreground-skills-own-commits), [D-7](artifacts/implementation-decision-log.md#d-7-drivability-resolves-the-named-skill-to-an-installed-path), [D-9](artifacts/implementation-decision-log.md#d-9-ship-the-validation-loosening-and-phase-routing-as-one-atomic-edit), [D-11](artifacts/implementation-decision-log.md#d-11-pre-work-decision-gate-mechanics)) | 1, 2, 3 | C5, C6, C7, C8; A1-A10 |
| 5 | Cleanup edits | `build-report-contract.md` intro generalized off `tdd` and its `AFK`-build framing corrected ([D-12](artifacts/implementation-decision-log.md#d-12-cleanup-edits-carried-with-the-change)) | co-lands with 4 | C8 reading |
| 6 | Companion catalog correction | The three `guidance`-as-review rows in `deliverable-skill-catalog.md` become `manual read, HITL`; ships in the same change as unit 4 ([D-13](artifacts/implementation-decision-log.md#trivial-decisions)) | co-lands with 4 | C8 reading |
| 7 | Long-form docs and voice pass | `docs/skills/han-coding/implement-work-items.md` and `docs/skills/han-planning/plan-work-items.md` updated; writing-voice pass across all edited files ([D-14](artifacts/implementation-decision-log.md#d-14-verification-is-manual-dry-run-plus-read-the-file-contract-checks)) | 4, 5, 6 | CONTRIBUTING coverage rule; voice pass |
| 8 | Verification pass | C1-C8 read-the-file checks; A1-A10 dry-runs including the A3 and A7b proving runs and the A1 regression | 1-7 | Definition of Done |

Units 4, 5, and 6 land as one atomic change so the driver, its contracts, and the producer catalog are never mutually inconsistent ([D-9](artifacts/implementation-decision-log.md#d-9-ship-the-validation-loosening-and-phase-routing-as-one-atomic-edit)).

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | Hand-off resume reliability: after a foreground hand-off the driver may drop its own workflow (heavy-orchestrator early-exit) and act on stale state or fail to resume | Medium | High | The active item and the remainder of the run | High (re-invoke fresh on a clean branch) | implementer | Explicit continuation discipline in the SKILL.md hand-off step; mandatory manual-compaction recommendation before a foreground build (spec [D9](artifacts/decision-log.md#d9-in-session-state-catch-up-not-compaction-survival)); unconditional state catch-up; proving dry-run A3 as a Definition-of-Done gate ([D-1](artifacts/implementation-decision-log.md#d-1-foreground-build-is-an-operator-hand-off-not-a-skill-call)) |
| R2 | Opt-in-pause message read: the pending-request detection (a no-yield read of a message queued during a synchronous sub-agent run) may be unreliable on the platform | Medium | Medium | One item's review (a requested pause missed; the run still completes on the agent verdict) | High | implementer | Proving dry-run A7b as a Definition-of-Done gate; documented standing/pre-item opt-in fallback if the no-yield read is unreliable ([D-8](artifacts/implementation-decision-log.md#d-8-opt-in-review-pause-is-checked-after-the-sub-agent-returns)) |
| R3 | SKILL.md compaction budget: the driver body is already at the post-compaction cap, so added inline detail risks the body being dropped after a compaction during a long run | Medium | Medium | Any run long enough to compact | High | implementer | Push new detail to the two reference files and the in-place verdict generalization; front-load the routing constraint; rely on the Step 1.7 loosening being a net deletion ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)) |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | A HITL skill's in-session invocability is adequately proxied by installed-and-resolvable at startup | A skill that resolves on disk but cannot be invoked in session passes startup and fails at the hand-off, degrading to a mid-run halt (not a silent bad commit) | The foreground hand-off and dry-run A3 | Accepted; installed-and-resolvable is the only signal available in a read-only preflight ([D-7](artifacts/implementation-decision-log.md#d-7-drivability-resolves-the-named-skill-to-an-installed-path)) |

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| Dep1 | The companion `plan-work-items` catalog correction (`deliverable-skill-catalog.md`, the three `guidance`-as-review rows to `manual read, HITL`) ships in the same change as the driver edit | implementer | Committed ([D-13](artifacts/implementation-decision-log.md#trivial-decisions), spec [D6](artifacts/decision-log.md#d6-companion-catalog-correction-plus-driver-fallback)) |

## Testing Strategy

No automated harness exists for skill behavior (discovery notes), so verification is read-the-file contract checks plus manual dry-runs against the contracts, sourced from test-engineer ([D-14](artifacts/implementation-decision-log.md#d-14-verification-is-manual-dry-run-plus-read-the-file-contract-checks)).

- **Observable behaviors to test:** each execution mode routes and gates correctly (unattended, decision-then-unattended, foreground build, free-form `none`, human review, non-code AFK review); the fix loop stays bounded across a foreground round; a foreground skill's own commits are adopted, not duplicated; a startup drivability abort fires on an unresolvable named skill.
- **Read-the-file contract checks (C1-C8):**
  - **C1**: `review-verdict-contract.md` defines the one normalized verdict shape (recommendation, per-source coverage attestation, findings with tier/location/claim, below-threshold counts, durable record) generalized off the code-review panel.
  - **C2**: the severity mapping is present as data for `code-review`, `information-architect`, `content-auditor`, and a human read, matching T1.
  - **C3**: one parameterized depth-1 dispatch covers the `code-review` SKILL and the `content-auditor` and `information-architect` AGENTS, with reference material supplied per source (the item and referenced spec sections for every source, the prior document version for a content audit). This reading also covers the information-architect mapping, which is why a separate IA dry-run is deferred.
  - **C4**: the location rule (file:line for code, document anchor for prose) and the per-source coverage attestation (single-agent and human-read generalization) are present, so a single-agent or human review does not trip the panel-shaped halt.
  - **C5**: Step 1.7 no longer refuses a HITL, a non-`tdd`-plus-`code-review`, or a pre-work-decision item; the drivability check replaces those refusals and defines how it resolves a named skill.
  - **C6**: Step 3 routes each phase by the recorded marker (build: AFK dispatch / HITL hand-off / `none` free-form; review: AFK dispatch / HITL human read / `none` no gate).
  - **C7**: the work-state file schema includes `scope-baseline` and `fix-round` per item; the fix loop re-enters at build by signal, re-reviews by signal, never re-decides, and the none-review clear-on-verify rule appears at both sites.
  - **C8**: the commit step branches (dirty stages by path; clean-with-new-commits adopts the range after a cumulative-diff inspection); the three catalog rows changed; `allowed-tools` unchanged; `description` reworded off "fully-autonomous"; `build-report-contract.md` generalized off `tdd`; no em-dashes and no banned words across the edited files.
- **Dry-run scenarios (A1-A10), one per execution mode:**
  - **A1**: fully-autonomous run (regression): behaves exactly as the shipped core loop, and the still-applicable Step 1.7 refusals (empty file, missing fields, malformed graph, prior-run branch, red suite) still fire.
  - **A2**: decision-then-unattended: the decide gate records, commits the durable edit, sets the baseline after it, and carries the decision into the build.
  - **A3**: foreground build resume (proving dry-run, Definition-of-Done gate): hand-off, confirm-done, state catch-up, and independent verify all resume the driver's loop cleanly.
  - **A4**: free-form `none` build: no named skill, independently verified and reviewed like any item.
  - **A5**: human read: capture into the normalized verdict, ask-missing-field, echo-back-with-threshold, confirm-finality, and a durable record written even when clean.
  - **A6**: non-code AFK review (`content-auditor` or `information-architect`): dispatched through the generalized contract, mapped to the normalized verdict, gated identically.
  - **A7a**: unattended review, no opt-in: the run proceeds to the gate without pausing (walk-away preserved).
  - **A7b**: opt-in review pause (proving dry-run, Definition-of-Done gate): the operator sends a pause-after-review message while the review runs; the driver detects the pending request after the sub-agent returns and merges the findings, or falls back to the standing/pre-item opt-in if the no-yield read is unreliable.
  - **A8**: fix loop on a HITL item: re-enters at build by signal (foreground fix inline), re-verifies, re-reviews by signal, and the `fix-round` counter persists across state catch-up so the loop stays bounded.
  - **A9**: commit adoption: a foreground skill committed its own work; the driver inspects the cumulative diff, adopts the range, and records it (no empty commit).
  - **A10**: startup drivability abort: an unresolvable named skill aborts the whole run at startup naming the offender; a bare `none` does not abort.
- **Test doubles posture:** none; the dry-runs exercise the real skills against real (or scratch) work-items files.
- **Edge cases requiring coverage:** the infinite-loop hole (A8, edge-case M10); the never-clearing none-review fix loop (A1/A8, edge-case C2); the empty-or-duplicate commit (A9, edge-case C3); the pre-decision commit-failure halt frame (A2, edge-case M9).
- **Test levels:** contract conformance (C1-C8) and end-to-end dry-run (A1-A10); there is no unit or integration layer for markdown skill behavior.

## Definition of Done

- [ ] C1-C8 read-the-file contract checks pass.
- [ ] A1-A10 dry-runs pass, including the A3 (foreground resume) and A7b (opt-in pause) proving runs as gates ([D-14](artifacts/implementation-decision-log.md#d-14-verification-is-manual-dry-run-plus-read-the-file-contract-checks)).
- [ ] Regression confirmed: A1 and the still-applicable Step 1.7 refusals behave unchanged.
- [ ] The verdict contract is generalized in place; the two new reference files exist; the decide-gate and signposting stay inline ([D-2](artifacts/implementation-decision-log.md#d-2-generalize-the-review-verdict-contract-in-place), [D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)).
- [ ] The Step 1.7 loosening plus drivability check and the Step 3 routing land as one atomic change ([D-9](artifacts/implementation-decision-log.md#d-9-ship-the-validation-loosening-and-phase-routing-as-one-atomic-edit)).
- [ ] The companion catalog correction ships in the same change ([D-13](artifacts/implementation-decision-log.md#trivial-decisions)).
- [ ] The two long-form docs are updated per the CONTRIBUTING coverage rule.
- [ ] The driver `description` frontmatter is reworded off "fully-autonomous".
- [ ] A writing-voice pass across all edited files: no em-dashes, no banned words (`leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`).
- [ ] `allowed-tools` is unchanged: no `Skill`, no `AskUserQuestion`.

## Specialist Handoffs for Implementation

- **`test-engineer`**: dispatch when the atomic SKILL.md edit (unit 4) is drafted; needs the edited SKILL.md and its contracts to run the C1-C8 conformance reading and script the A1-A10 dry-runs, including the A3 and A7b proving runs.
- **`edge-case-explorer`**: dispatch to validate the A8 fix-loop-boundary and A9 commit-adoption dry-runs against the M10 and C3 findings; needs the edited fix-loop and commit steps.

## Deferred (YAGNI)

### Translating adapter agent for non-code verdicts

- **Why deferred:** single-implementation interface or abstraction before three concrete uses. The dispatch-instruction contract carries the per-source mapping as copied data, which satisfies the same need without a new agent ([D-2](artifacts/implementation-decision-log.md#d-2-generalize-the-review-verdict-contract-in-place)).
- **Reopen when:** a per-source mapping becomes too complex to carry as a copied table in the dispatch prompt.
- **Source:** R1, software-architect A2 and junior-developer JD-008.

### `pre-work-decision-gate.md` reference file

- **Why deferred:** helper file before a shared or large need. The decide-gate has one call site and stays inline as the Step 3 decide sub-step ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)).
- **Reopen when:** a second call site appears or the decide-gate grows past a screen.
- **Source:** R1, software-architect A3.

### `pause-signposting.md` reference file

- **Why deferred:** symmetry or completeness with the other two protocol files, without the detail to earn one. The pause markers fold into the two protocol files and the preview and summary lists stay inline ([D-3](artifacts/implementation-decision-log.md#d-3-two-new-reference-files-decide-gate-and-signposting-stay-inline)).
- **Reopen when:** a third protocol needs the pause vocabulary.
- **Source:** R1, software-architect A3.

### Automated test scaffolding and golden-file snapshots

- **Why deferred:** tests for a harness that does not exist; golden-file snapshots over free-form agent returns are non-deterministic noise. Verification is human dry-run plus read-the-file checks ([D-14](artifacts/implementation-decision-log.md#d-14-verification-is-manual-dry-run-plus-read-the-file-contract-checks)).
- **Reopen when:** a skill test framework is added to the repo.
- **Source:** R1, test-engineer.

### Separate information-architect end-to-end dry-run

- **Why deferred:** the C3 reading covers the same mapping mechanics as content-auditor, so a separate IA dry-run is redundant now.
- **Reopen when:** C3 finds the IA mapping absent or divergent from content-auditor's.
- **Source:** R1, test-engineer.

## Open Items

- **OI-1 (confirmed, closed):** Under `--gate critical`, content-audited items do not block, because content-auditor emits only Warning ([D-10](artifacts/implementation-decision-log.md#d-10-the-critical-gate-does-not-block-content-audited-items)). The operator reviewed this and confirmed it is correct behavior: the default `warning` gate is what gates doc facts, information-architect still gates under critical, and F9's drop of the Critical escalation stands.
  - **Resolves when:** confirmed correct by the operator; no change required. Reopen only if a future need arises to gate content-audited items under `--gate critical`.
  - **Blocks implementation:** No.

## Summary

- **Outcome delivered:** the `implement-work-items` driver drives needs-a-human items (pre-work decision, foreground interactive or free-form build, human review) alongside fully-autonomous ones, routing each phase by the item's recorded markers and gating every review through one normalized verdict.
- **Team size:** 5 specialists (plus the coordinator). See [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 1. See [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 14. See [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 13. See [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0. See [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by user input:** 1 (D-13, inherited from spec D6). See [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Rejected alternatives recorded:** 26. See [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 0 (OI-1 reviewed and confirmed correct by the operator)
- **Recommendation:** Ship as planned.
