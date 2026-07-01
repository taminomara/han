# Feature Implementation Plan: Autonomous Driver — Core Loop (`implement-work-items`)

Ship a new markdown Han skill, `implement-work-items`, in the `han-coding` plugin that drives a trusted `work-items.md` through a serial build/verify/review/fix/commit loop, plus the companion field additions to `plan-work-items` the driver reads. The deliverable is authored SKILL.md and reference markdown and edits to existing skill files; there is no compiled code or runtime service.

<!--
CROSS-REFERENCING GUIDANCE
Decision records live in [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md);
round-by-round history lives in [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md).
Inline `([D-N](artifacts/implementation-decision-log.md#...))` links mark non-obvious claims only.
-->

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md)
- **Specification decisions this plan inherits:** D1 through D20
- **Specification open items this plan must respect or resolve:** None (the spec closed with zero open items; the skill name that spec D20 left to implementation is now settled at [D-17](artifacts/implementation-decision-log.md#trivial-decisions)).

## Outcome

When this plan is executed, the `han-coding` plugin gains a slash-command skill, `implement-work-items` ([D-17](artifacts/implementation-decision-log.md#trivial-decisions)), that an operator points at a trusted `work-items.md`. The skill validates the input read-only, previews the run, and after one confirmation drives each item unattended: it dispatches a build sub-agent, re-runs the project's own verification, dispatches a full-coverage review, runs a bounded fix loop, and commits each cleared item on a dedicated branch, halting the whole run on the first item it cannot finish cleanly. The `plan-work-items` producer gains the two per-item fields the driver reads, and the suite's docs and indexes register the new skill.

## Context

- **Driving constraint:** The operator has chosen to build the larger autonomous-implementation-driver iteratively and ship the core loop first (roughly 80% of the manual conducting work), under the source spec's simplifying assumptions of no interruption, no cancellation, no compaction, and no stalls. The core is the enabling slice the later interaction, durability, and resilience features build on.
- **Stakeholders:** The operator (a solo or small-team engineer) wants each trusted item built, verified, reviewed, and committed without hand-invoking `tdd` and `code-review` per item, and a legible halt when something cannot be finished. The suite maintainer wants the skill to follow CONTRIBUTING and the writing voice, keep `han-planning` free of a dependency on `han-coding`, and register cleanly in the docs and indexes.
- **Future-state concern:** The by-instruction dispatch contract is prompt-imposed with no schema validation ([D-4](artifacts/implementation-decision-log.md#d-4-compact-return-contract-and-fail-closed-parsing)), and the review fan-out depends on a minimum platform version ([D-3](artifacts/implementation-decision-log.md#d-3-minimum-claude-code-version-prerequisite)); both are watched after ship, since a change in either would move the driver toward the deferred native compact-output modes or a below-version halt. The skill is the suite's first skill-to-skill orchestrator, so its SKILL.md sets a precedent later orchestrators will copy.
- **Out-of-scope boundary:** Everything the source spec defers stays deferred: HITL and interactive-skill items, clean-stop, resume across sessions, compaction recovery, stall handling, and the interactive blocker menu. This plan does not re-open any behavioral decision from the source spec; it commits only the "how".

## Team Composition and Participation

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Facilitated R1's deterministic aggregation and synthesized this plan; the spec-maturity gate did not trip. |
| `software-architect` | Active | Dispatch mechanism, review fan-out topology and version prerequisite, fail-closed contract parsing, allowed-tools set, driver artifact paths ([D-1](artifacts/implementation-decision-log.md#d-1-sub-agent-dispatch-mechanism) through [D-6](artifacts/implementation-decision-log.md#d-6-driver-artifacts-and-explicit-commit-staging)). |
| `test-engineer` | Active | Verification strategy and the Definition-of-Done set ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy), [D-15](artifacts/implementation-decision-log.md#d-15-definition-of-done)); companion-change verification. |
| `junior-developer` | Reframer | Reframed the references-granularity question under the YAGNI simpler-version test ([D-13](artifacts/implementation-decision-log.md#d-13-skill-file-structure-and-references-granularity)); detection, marker, planning-artifact parsing, and valid-skill recognition ([D-7](artifacts/implementation-decision-log.md#d-7-verify-command-auto-detection) through [D-12](artifacts/implementation-decision-log.md#d-12-planning-artifact-identification)). |
| `devops-engineer` / `on-call-engineer` | Not needed | A markdown skill has no deploy, runtime, or infrastructure surface, so neither was engaged; the Operational Readiness and On-Call Resilience Posture sections are omitted for the same reason. |

## Implementation Approach

The driver is a single orchestration SKILL.md in `han-coding/skills/implement-work-items/` plus two contract reference files, and it dispatches existing skills rather than reimplementing them. It reuses `tdd` for building, `code-review` for reviewing, and the target project's own verification commands for the independent check. No new agent definitions are added; the panel comes from the existing `han-core` reviewer roster through `code-review`.

### Architecture and Integration Points

- **Dispatch through the Agent tool.** The driver dispatches build, fix, and review sub-agents through the Agent tool with a prompt that names the skill to run and passes a per-call `model`, rather than preloading worker-agent definitions ([D-1](artifacts/implementation-decision-log.md#d-1-sub-agent-dispatch-mechanism)). This keeps the per-run model override wired and adds no files under `han-core/agents/`.
- **Version prerequisite.** The review fan-out requires Claude Code v2.1.172 or later ([D-3](artifacts/implementation-decision-log.md#d-3-minimum-claude-code-version-prerequisite)); the SKILL.md Constraints and the long-form doc state it, and below that version the review verdict is untrustworthy and the run halts (no reduced-coverage fallback).
- **allowed-tools.** The SKILL.md declares `Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(find *)` plus the runner prefixes `tdd` already declares ([D-5](artifacts/implementation-decision-log.md#d-5-allowed-tools-set)). Because a per-prefix Bash grant cannot cover an arbitrary project's runner, a verification command that will not run under these grants is the tooling-unavailable halt; the Constraints state this coverage gap.
- **SKILL.md structure.** The file is authored at orchestration altitude (roughly 300 to 380 lines) following the Project Context / Constraints / Step 1 Prepare and Validate / Step 2 Confirm and Set Up / Step 3 per-item loop with an inline Halt Procedure / Step 4 Completion Summary outline; exactly two reference files are extracted up front, with validation rules and the halt frame kept inline until overflow ([D-13](artifacts/implementation-decision-log.md#d-13-skill-file-structure-and-references-granularity)).
- **Companion producer changes.** `plan-work-items` gains the `expected-paths` (required, a best-effort declaration the producer derives from the plan's named touch points and Step-3 codebase exploration, which the operator confirms; when the plan gives no file-level detail the producer flags the item's paths as low-confidence rather than inventing them) and `Type` AFK/HITL marker (required) fields in its template and file-format reference, with SKILL.md Step 5/7/8 edits; the Step 8 closing recommendation names `implement-work-items` and its `han-coding` plugin in prose only ([D-16](artifacts/implementation-decision-log.md#d-16-companion-changes-to-plan-work-items)), which keeps `han-planning` free of a dependency on `han-coding` ([D-19](artifacts/implementation-decision-log.md#trivial-decisions)).

### Data Model and Persistence

- **Driver artifacts.** The uncommitted work-state file (run configuration plus per-item status: pending, in-progress, done with commit reference and review-record path, or halted) and the per-item durable review records live at concrete git-excluded paths inside the plan folder, in markdown ([D-6](artifacts/implementation-decision-log.md#d-6-driver-artifacts-and-explicit-commit-staging)).
- **Explicit staging.** Every per-item commit stages the item's code changes explicitly by path and never runs `git add -A`; the work-state file and the review records are excluded from the scope check and from every commit ([D-6](artifacts/implementation-decision-log.md#d-6-driver-artifacts-and-explicit-commit-staging)).
- **Companion fields.** The two producer fields are data the driver reads at validation time; their format reads identically across the template, the file-format doc, and the driver's validation ([D-16](artifacts/implementation-decision-log.md#d-16-companion-changes-to-plan-work-items)).

### Runtime Behavior

- **Prepare and validate (read-only).** The driver detects the project's verification commands by mirroring `tdd`'s `scripts/detect-tdd-context.sh` resolution order, with a `--verify` override and a scope-check-only fallback ([D-7](artifacts/implementation-decision-log.md#d-7-verify-command-auto-detection)); identifies the planning artifacts by parsing the `work-items.md` preamble for local `.md` links plus the file itself ([D-12](artifacts/implementation-decision-log.md#d-12-planning-artifact-identification)); reads the `Type` marker on each item and refuses any `HITL`-typed item ([D-8](artifacts/implementation-decision-log.md#d-8-valid-skill-recognition-set)); and refuses to start on a branch whose planning-artifacts commit carries the prior-run marker, detected with `git log` ([D-9](artifacts/implementation-decision-log.md#d-9-prior-run-branch-marker)).
- **Confirm and set up.** After the operator confirms the preview, the driver creates the dedicated branch (a `driver/{feature-dir}` style default unless overridden, [D-10](artifacts/implementation-decision-log.md#trivial-decisions)), commits the planning artifacts with the marker, and initializes the work-state file. Commit messages follow the project's convention, defaulting to conventional commits ([D-11](artifacts/implementation-decision-log.md#trivial-decisions)).
- **Per-item loop and review topology.** The driver dispatches one review sub-agent at depth 1 that runs `code-review` and fans out its panel at depth 2, returning only the condensed verdict and persisting the durable full record ([D-2](artifacts/implementation-decision-log.md#d-2-review-fan-out-topology)). The build, fix, and review returns are prompt-instructed with named-section headers and parsed fail-closed; a malformed or incomplete report, or a `tdd` report missing the RED-to-GREEN evidence, is untrustworthy and halts the run ([D-4](artifacts/implementation-decision-log.md#d-4-compact-return-contract-and-fail-closed-parsing)).

### External Interfaces

The driver's only interfaces are the dispatch contracts it imposes by instruction. The build-report contract (status, files changed, final gate result, escalation, and the RED-to-GREEN evidence for a `tdd` build) and the review-verdict contract (the Review Recommendation, severity counts complete at and above the threshold, and a full-coverage attestation) are each extracted to a reference file and copied verbatim into the matching dispatch prompt ([D-4](artifacts/implementation-decision-log.md#d-4-compact-return-contract-and-fail-closed-parsing), [D-13](artifacts/implementation-decision-log.md#d-13-skill-file-structure-and-references-granularity)). Neither `tdd` nor `code-review` is changed; native compact-output modes on them are deferred.

## Decomposition and Sequencing

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | Companion fields on `plan-work-items` ([D-16](artifacts/implementation-decision-log.md#d-16-companion-changes-to-plan-work-items)) | `expected-paths` and `Type` AFK/HITL marker added to `work-item-template.md` and `work-items-file-format.md`; SKILL.md Step 5/7/8 edits; `plan-work-items` long-form doc updated; prose-only driver reference ([D-19](artifacts/implementation-decision-log.md#trivial-decisions)) | None | Field format reads identically across template, file-format doc, and driver validation; a fixture work-items file exercises both fields; CONTRIBUTING self-review |
| 2 | Driver SKILL.md and two contract references ([D-13](artifacts/implementation-decision-log.md#d-13-skill-file-structure-and-references-granularity)) | `han-coding/skills/implement-work-items/SKILL.md` at orchestration altitude plus `references/build-report-contract.md` and `references/review-verdict-contract.md`; the step outline and inline halt frame | 1 | `allowed-tools` covers the verify Bash prefixes and includes Agent ([D-5](artifacts/implementation-decision-log.md#d-5-allowed-tools-set)); description under 1024 characters; voice and em-dash scan |
| 3 | Driver validation and preparation logic (authored inline in SKILL.md) | Verify-command detection ([D-7](artifacts/implementation-decision-log.md#d-7-verify-command-auto-detection)), planning-artifact parsing ([D-12](artifacts/implementation-decision-log.md#d-12-planning-artifact-identification)), Type-marker validation and HITL refusal ([D-8](artifacts/implementation-decision-log.md#d-8-valid-skill-recognition-set)), prior-run marker check ([D-9](artifacts/implementation-decision-log.md#d-9-prior-run-branch-marker)), branch-name default ([D-10](artifacts/implementation-decision-log.md#trivial-decisions)), commit-convention detection ([D-11](artifacts/implementation-decision-log.md#trivial-decisions)), and explicit artifact staging ([D-6](artifacts/implementation-decision-log.md#d-6-driver-artifacts-and-explicit-commit-staging)) | 2 | Pre-run refusal checks; artifacts-never-staged via `git show --stat`; scope-check-only dogfood on Han |
| 4 | Docs, indexes, catalog ([D-18](artifacts/implementation-decision-log.md#trivial-decisions)) | Long-form doc at `docs/skills/han-coding/implement-work-items.md`; Skills Index entry under `## han-coding`; root CLAUDE.md catalog entry; `.claude-plugin/marketplace.json` confirmed unchanged | 2 | Docs, index, and CLAUDE.md completeness; links resolve; the per-plugin doc path is followed (see the CONTRIBUTING drift note below) |
| 5 | Dogfood verification ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy), [D-15](artifacts/implementation-decision-log.md#d-15-definition-of-done)) | Happy-path dogfood on a real-suite fixture; scope-check-only dogfood on Han; mid-run halt checks; halt-leaves-completed-items-committed; companion-change verification | 1, 2, 3, 4 | The Definition-of-Done set exercised end to end |

Note on a pre-existing doc drift: CONTRIBUTING's add-a-skill step 3 names `docs/skills/{name}.md`, but the actual layout is per-plugin, `docs/skills/han-coding/{name}.md`. Work Unit 4 follows the per-plugin path (the verified layout) and does not fix the CONTRIBUTING wording, which is out of this plan's scope.

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | The operator's environment runs Claude Code below v2.1.172, so the review stage cannot fan out its panel and its verdict is untrustworthy ([D-3](artifacts/implementation-decision-log.md#d-3-minimum-claude-code-version-prerequisite)) | Low to Medium | High (the review gate is the feature's headline value) | The whole run | High (operator upgrades) | software-architect | State the prerequisite in SKILL.md Constraints and the long-form doc; fail closed to a halt rather than a reduced-coverage run |
| R2 | The depth-1 review sub-agent's context grows unmanageable on a large item, degrading review quality | Unknown (Low expected) | Medium | The item's review | High (adjust the dispatch) | software-architect | Watch at authoring; dispatch a `behavioral-analyst` review-context-budget instruction if it manifests (see Specialist Handoffs) |
| R3 | The prompt-instructed contract, having no schema validation, yields malformed or incomplete returns often enough to cause frequent halts ([D-4](artifacts/implementation-decision-log.md#d-4-compact-return-contract-and-fail-closed-parsing)) | Medium | Medium | Per run | High (reopen native compact modes) | software-architect | Fail-closed parsing with named-section headers; reopen the deferred native compact-output modes if unreliable |
| R4 | A target project's verification runner falls outside the fixed Bash prefix set, so a legitimate command halts as tooling-unavailable ([D-5](artifacts/implementation-decision-log.md#d-5-allowed-tools-set)) | Medium | Low | The affected run | High (operator grant) | software-architect | State the coverage gap in Constraints; operator adds a CLAUDE.md Bash grant or routes the command through `make` |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | The operator's environment runs Claude Code v2.1.172 or later (nested sub-agents) ([D-3](artifacts/implementation-decision-log.md#d-3-minimum-claude-code-version-prerequisite)) | The review fan-out is impossible and the run halts; the feature is unusable below the version | software-architect at authoring; operator at run time | Documented prerequisite; not verifiable per operator environment from this repo |
| A2 | The operator runs the skill on a session model capable of the coordination role (spec D12) | Weak sequencing, report reading, and halt decisions | Operator | Operator-responsibility precondition, carried from the source spec |
| A3 | The by-instruction dispatch contract is reliable enough in practice to keep halts rare | Frequent untrustworthy-report halts; the native compact modes reopen | Dogfood (test-engineer, Work Unit 5) | To be validated by dogfood |

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| Dep1 | The `plan-work-items` companion fields must ship before or with the driver so the fields exist for it to read ([D-16](artifacts/implementation-decision-log.md#d-16-companion-changes-to-plan-work-items)) | Implementer (Work Unit 1) | Sequenced first in this plan |

## Testing Strategy

Verification is dogfooding plus the CONTRIBUTING self-review checklist; no automated harness is added, because the repo is markdown-only with no CI ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy)).

- **Observable behaviors to test:** a clean happy-path run committing each item on the branch; each pre-run refusal (malformed graph, missing `expected-paths`, missing `Type` marker, `HITL`-typed item, empty file, dirty tree, red suite, prior-run branch); each mid-run halt (no file changes, missing RED-to-GREEN evidence, verification fails to execute, out-of-path change, cap reached, untrustworthy verdict); the artifacts-never-staged invariant; and halt-leaves-completed-items-committed.
- **Test doubles posture:** none; the strategy is end-to-end dogfooding against real repositories, since the deliverable is a markdown skill that orchestrates real sub-agents and git.
- **Edge cases requiring coverage:** the scope-check-only path (exercised by dogfooding on Han, which defines no verification commands); independent verification and the fix loop (require an external fixture repo that has a real test suite, since Han cannot exercise them, [D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy)); a rename declared as both old and new paths; an excluded-only build treated as no change.
- **Test levels:** manual dogfood (happy path on a real-suite fixture; scope-check-only on Han); refusal and halt checks; the CONTRIBUTING self-review as the static gate ([D-15](artifacts/implementation-decision-log.md#d-15-definition-of-done)).

## Definition of Done

- [ ] CONTRIBUTING self-review passes all eight items, with the load-bearing checks confirmed: `allowed-tools` covers the verify Bash prefixes and includes Agent, the description is under 1024 characters, links resolve, the long-form doc exists, and the indexes are complete ([D-15](artifacts/implementation-decision-log.md#d-15-definition-of-done), [D-5](artifacts/implementation-decision-log.md#d-5-allowed-tools-set)).
- [ ] Happy-path dogfood on a real-suite fixture builds, verifies, reviews, fixes, and commits each item on the branch ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy)).
- [ ] Scope-check-only dogfood on Han confirms the no-verification-commands path ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy)).
- [ ] Pre-run refusal checks each produce a refusal naming reason and remedy.
- [ ] Mid-run halt checks each produce the five-part halt frame with the correct reason.
- [ ] Artifacts-never-staged confirmed via `git show --stat` on each per-item commit ([D-6](artifacts/implementation-decision-log.md#d-6-driver-artifacts-and-explicit-commit-staging)).
- [ ] Halt-leaves-completed-items-committed confirmed on a deliberately halted run.
- [ ] Companion-change verification: the producer emits both fields and the driver's validation reads them identically ([D-16](artifacts/implementation-decision-log.md#d-16-companion-changes-to-plan-work-items)).
- [ ] Docs, Skills Index, and root CLAUDE.md updated and complete; `.claude-plugin/marketplace.json` confirmed unchanged ([D-18](artifacts/implementation-decision-log.md#trivial-decisions)).
- [ ] Voice and em-dash scan clean across the new and edited files.

## Specialist Handoffs for Implementation

- **`behavioral-analyst`** — dispatch only if authoring shows the depth-1 review sub-agent's context grows unmanageable on large items (RAID R2); needs the review dispatch prompt and an example large-item review, and produces a review-context-budget instruction for the depth-1 sub-agent.
- **`test-engineer`** — dispatch at Work Unit 5 to run the dogfood matrix; needs a real-suite fixture repository and a fixture `work-items.md` exercising both companion fields.

## Deferred (YAGNI)

### Per-item implementation-skill selection
- **Why deferred:** `tdd` is the only non-interactive code-producing build skill in the core, so a per-item `implementation-skill` field would carry exactly one valid value (a premature schema hook). An interactive skill cannot be driven unattended regardless.
- **Reopen when:** a second non-interactive code-producing skill exists AND the design adds a skill-selection decision tree plus an affordance for the operator to allow non-han skills (for example, "use my skill X for this part").
- **Source:** W-1 implementation, operator direction; mirrors spec Deferred (YAGNI) entry.

### Native compact-output modes on `tdd` and `code-review`
- **Why deferred:** The driver imposes the return contract by dispatch instruction ([D-4](artifacts/implementation-decision-log.md#d-4-compact-return-contract-and-fail-closed-parsing)), so no change to `tdd` or `code-review` is needed for the core; a declared, schema-validated mode is not justified until the by-instruction contract proves unreliable.
- **Reopen when:** the by-instruction contract proves unreliable in dogfood (RAID R3), or the platform confirms schema-enforced structured output for this dispatch path.
- **Source:** R1 (software-architect A3; source spec Deferred section).

### CI or shell-script automation of the Definition of Done
- **Why deferred:** The repo has no CI to host a harness and the deliverable is markdown, so an automated harness has nothing to hook into ([D-14](artifacts/implementation-decision-log.md#d-14-verification-strategy)).
- **Reopen when:** the repo adds CI, or DoD regressions recur often enough to justify automation.
- **Source:** R1 (test-engineer).

### A dedicated fixture repo committed into Han
- **Why deferred:** Independent verification and the fix loop need a real test suite, which the operator's own project or a throwaway repo supplies; committing a fixture into Han is not justified until repeated dogfood needs a stable one.
- **Reopen when:** repeated dogfood needs a stable, versioned fixture.
- **Source:** R1 (test-engineer).

### Per-halt-trigger fixtures and a distinct fix-loop-re-review DoD item
- **Why deferred:** The DoD covers the halt triggers as observable checks ([D-15](artifacts/implementation-decision-log.md#d-15-definition-of-done)); a dedicated fixture per trigger and a separate re-review DoD item are opportunistic coverage, not required for the core.
- **Reopen when:** a halt trigger misfires in production use.
- **Source:** R1 (test-engineer).

### The SKILL.md-property-scan skill-recognition mechanism
- **Why deferred:** Valid-skill recognition uses the hard-coded set `{tdd}` ([D-8](artifacts/implementation-decision-log.md#d-8-valid-skill-recognition-set)); a scan that reads each skill's declared properties is a single-use abstraction while `tdd` is the only qualifying skill.
- **Reopen when:** a second non-interactive, code-producing implementation skill exists.
- **Source:** R1 (junior-developer IMPL-04).

### A `behavioral-analyst` review-context-budget instruction for the depth-1 review sub-agent
- **Why deferred:** The depth-1 review sub-agent returns only the condensed verdict, so its context is expected to stay bounded ([D-2](artifacts/implementation-decision-log.md#d-2-review-fan-out-topology)); a context-budget instruction is unjustified until authoring shows the context grows unmanageably.
- **Reopen when:** authoring shows the depth-1 context grows unmanageably (RAID R2; recorded as a Specialist Handoff).
- **Source:** R1 (software-architect).

## Open Items

None. The one open question the source spec left to implementation (the skill name, spec D20) is settled at [D-17](artifacts/implementation-decision-log.md#trivial-decisions); the v2.1.172 prerequisite is a documented constraint and a RAID assumption and risk (A1, R1), not an open item. The plan is shippable as written.

## Summary

- **Outcome delivered:** a `han-coding` skill, `implement-work-items`, that drives a trusted `work-items.md` through a serial build/verify/review/fix/commit loop on a dedicated branch, halting cleanly on the first unfinishable item, plus the `plan-work-items` companion fields it reads.
- **Team size:** 4 specialists (project-manager, software-architect, test-engineer, junior-developer) — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 1 — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 19 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 17 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 1 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by user input:** 1 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Rejected alternatives recorded:** 19 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 0
- **Recommendation:** Ship as planned.
