# Feature Implementation Plan: Skill and Agent Review

Build `review-skill-or-agent`, a new Claude Code skill modeled on `han-coding/skills/code-review`, that reviews a finished skill or agent against the plugin-authoring guidance and a set of quality dimensions (bloat and restatement first-class) and emits a severity-ranked report. The skill is homed in a new opt-in `han-experimental` plugin, dispatches `han-core` agents, and grounds against `han-plugin-builder` guidance resolved at runtime. This plan feeds `skill-builder` directly.

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md)
- **Specification review findings (iterative-plan-review):** [artifacts/review-findings.md](artifacts/review-findings.md)
- **Implementation discovery notes:** [artifacts/.discovery-notes.md](artifacts/.discovery-notes.md)
- **Specification decisions this plan inherits:** D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D14, D15 (spec-log IDs). D13 (home = han-plugin-builder) is **superseded** by [D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder); D16 was deleted and D17 tombstoned at spec time.
- **Specification open items this plan resolves:** OI-1 (closed by [D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories)), OI-2 (closed by [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)).

## Outcome

When this plan is executed, the repository contains a new opt-in plugin `han-experimental` whose single skill, `review-skill-or-agent`, reviews a finished skill or agent. Running the skill over a target produces a severity-ranked report (Critical / Warning / Suggestion) of every place the artifact drifts from the type-appropriate authoring guidance or the named quality dimensions, with a location and a suggested fix per finding, and with bloat and restatement caught as first-class corrective findings that are never silently dropped for being small. The report's tiers map by identity into a gating caller's verdict (the autonomous driver wraps the dispatch exactly as it wraps code-review). The skill resolves `han-plugin-builder`'s guidance at runtime and halts distinctly when it is absent, so a gating caller never reads a halt as a pass ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder), [D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)).

## Context

- **Driving constraint:** The groundwork research left skill and agent builders self-reviewing their own work — the configuration most prone to blind spots — because no separate automated reviewer existed. This skill fills that gap so the autonomous driver can gate skill and agent work items the way it already gates code (spec Outcome, spec D3). Shipping it as an experimental plugin lets it land now, with the dependencies it needs, without waiting on a permanent-home decision.
- **Stakeholders:** an operator authoring or maintaining a skill or agent who wants it reviewed; the autonomous driver (and any automated caller) that dispatches the review in fresh context and wraps its findings into a gate; the `han-plugin-builder` maintainers, whose "depends on nothing" identity is deliberately preserved ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)).
- **Future-state concern:** the skill's permanent home and distribution shape are deferred. If maintainers later bless it into `han-plugin-builder` or ask for it to be vendored, the guidance-resolution path ([D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification)) and the reciprocal sibling-description edits ([D-15](artifacts/implementation-decision-log.md#d-15-reciprocal-sibling-description-edits-to-skill-builder--agent-builder-are-deferred-until-the-skill-is-blessed)) reopen. The runtime guidance resolution across install layouts is the piece most worth watching.
- **Out-of-scope boundary:** reviewing documentation (content/IA reviewers), application code (code-review), and hooks / plugin-or-marketplace configuration (spec D14); building or fixing the artifact (skill-builder, agent-builder, refactor); the driver's own verdict mapping, coverage attestation, and fix-loop wiring (driver-side, spec D3); vendoring the skill and reciprocal sibling edits (deferred — see Deferred (YAGNI)).

## Team Composition and Participation

Round 1 ran four specialists in parallel; deterministic aggregation found all findings Evidenced and plan-level, so the spec-maturity gate did not trip and one round sufficed. The user then handed back an authoritative pivot that resolved the escalated home/vendoring/guidance-resolution questions. Full round detail: [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md).

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Aggregated the parallel round deterministically and synthesized this plan; recorded the user pivot ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder), [D-7](artifacts/implementation-decision-log.md#d-7-the-skill-is-not-vendored-vendoring-deferred-until-maintainers-state-a-preference), [D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification)). |
| `test-engineer` | Active | Closed OI-1 (bloat rubric, [D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories)) and OI-2 (size + roster, [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)); authored the functional + triggering test set. |
| `adversarial-security-analyst` | Active | Untrusted-marker mechanism across four touch points, address-and-ask rule, false-clean guards ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)). |
| `edge-case-explorer` | Active | Detection-script contract, path-shape-first type routing with two distinct halts, oversize handling, no-git scope fallback ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages), [D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)). |
| `junior-developer` | Reframer | SKILL.md step skeleton ([D-5](artifacts/implementation-decision-log.md#trivial-decisions)), minimal `allowed-tools` ([D-12](artifacts/implementation-decision-log.md#d-12-allowed-tools-is-the-minimal-set-read-grep-glob-bashfind--agent)), de-dup mechanics ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)), name/description and deferred sibling edits ([D-2](artifacts/implementation-decision-log.md#trivial-decisions), [D-15](artifacts/implementation-decision-log.md#d-15-reciprocal-sibling-description-edits-to-skill-builder--agent-builder-are-deferred-until-the-skill-is-blessed)). |

## Implementation Approach

The skill mirrors `han-coding/skills/code-review`'s layout and mechanisms ([D-1](artifacts/implementation-decision-log.md#trivial-decisions)): a `SKILL.md` of numbered prose steps, a `references/` set of rubrics, and a `scripts/` detector. It reuses code-review's untrusted-marker shape, its size-override argument, and its adversarial-validator discipline, adapting each to the fact that the artifact under review is itself a document of imperative instructions (the acute injection surface spec D8 exists for).

The one structural departure from the base is the home plugin. The skill needs both `han-core` (it dispatches `han-core:junior-developer` and any focused reviewers) and `han-plugin-builder` (it grounds against the guidance references). Rather than add those dependencies to `han-plugin-builder` and break its "depends on nothing" identity, the skill is homed in a new opt-in plugin `han-experimental` that declares both dependencies ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)). This supersedes the spec's trivial D13 (home = `han-plugin-builder`); the feature spec is left unedited.

### Architecture and Integration Points

- **New plugin `han-experimental`.** `han-experimental/.claude-plugin/plugin.json` declares name `han-experimental`, an experimental-framing description, version `0.1.0`, and `"dependencies": ["han-core", "han-plugin-builder"]`. It is opt-in and NOT bundled by the `han` meta-plugin ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)). A `han-experimental` entry is added to `.claude-plugin/marketplace.json`, mirroring an existing entry's shape (`name`, `source: ./han-experimental`, `description`, `version`).
- **Skill layout** (mirrors code-review): `han-experimental/skills/review-skill-or-agent/` with `SKILL.md`, `references/` (a bloat-classification rubric, a finding/severity classification, a report template, and a review checklist), and `scripts/` (the guidance-and-type-context detector).
- **Skill name and description** ([D-2](artifacts/implementation-decision-log.md#trivial-decisions)): name `review-skill-or-agent`; a four-component description that disambiguates against the siblings — "Does not BUILD a skill/agent — use skill-builder/agent-builder; does not review documentation — use content/IA reviewers; does not review application code — use code-review."
- **`allowed-tools`** ([D-12](artifacts/implementation-decision-log.md#d-12-allowed-tools-is-the-minimal-set-read-grep-glob-bashfind--agent)): `Read, Grep, Glob, Bash(find *), Agent` — code-review's git/gh/make/npm grants are dropped (unused; least-privilege / self-conformance); `Bash(find *)` is justified by the guidance search. `AskUserQuestion` is deliberately absent (unattended run, spec D11).
- **Dispatch namespacing:** dispatched agents live in `han-core`, so dispatch uses the qualified `han-core:junior-developer` (the agent-dispatch-namespacing rule the skill itself enforces). The `han-core` dependency on `han-experimental` is what makes that dispatch resolve.
- **Documentation and index integration** (CLAUDE.md coverage rule): add `han-experimental` and the skill to the CLAUDE.md plugin map, add a skills-index entry, and add a long-form doc at `docs/skills/han-experimental/review-skill-or-agent.md`. These are plan steps (see Decomposition and Sequencing), not content authored in this plan.

### Runtime Behavior

The SKILL.md follows code-review's numbered-step skeleton ([D-5](artifacts/implementation-decision-log.md#trivial-decisions)):

1. **Receive target + scope.** Scope is parsed from the invocation intent in prose, not sniffed from git ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics), spec D10).
2. **Resolve + halt-check guidance.** The `detect-guidance` step probes for the type-appropriate guidance subtree in order — the installed `han-plugin-builder` references at the sibling-plugin path relative to the plugins root, then repo-local `.claude/skills/plugin-guidance/references/` — preferring the installed (trusted) copy, and halts on an absent-or-incomplete-for-the-resolved-type copy ([D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification)). A static per-type manifest of expected guidance filenames drives the completeness check ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages)).
3. **Resolve type.** Path-shape first (directory + `SKILL.md` → skill; `.md` under an agents location → agent), then frontmatter confirmation (`allowed-tools` vs `tools`+`model`, mutually exclusive in the corpus). Two distinct halts: structural-misfire vs neither-type ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages), spec D5).
4. **Classify size + select roster.** Size classified from the artifact against the measured-distribution thresholds; a caller `size` override (`arguments: size`) affects roster only, never the passes ([D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)).
5. **Inline conformance + bloat passes** over the full artifact read as data. The conformance pass owns tool / dispatch / routing findings ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics), spec D15); bloat runs always, exempt from size demotion (spec D6), tiered per `references/bloat-classification.md` ([D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories)). An oversize skill body (>500 lines) is itself a Warning conformance finding; agents have no body cap ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)).
6. **Dispatch reviewer(s)** with the artifact wrapped in `----- BEGIN/END ARTIFACT UNDER REVIEW (UNTRUSTED) -----` markers and a disregard-embedded-directives instruction ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)). The generalist references overlapping conformance findings rather than duplicating them (spec D15).
7. **Consolidate + de-dup + classify** into Critical / Warning / Suggestion; de-dup happens here, inheriting code-review's Step 9.0 self-consistency and Step 9.1 rule-10 overlap-reference ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)).
8. **Adversarial-validator pass** — the validator dispatch receives the same untrusted markers ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)); it inherits code-review's three verdicts, demote-don't-drop, and drop-only-on-concrete-counter-evidence-at-file:line overcorrection guard (spec D6, D8; the bloat carve-out applies without exception).
9. **Render report** ([D-3](artifacts/implementation-decision-log.md#trivial-decisions)): a summary table, a single recommendation driven by the highest-severity surviving finding (spec D15), and severity-ordered findings including the bloat section. HALT is a dedicated, distinct output block — never the "no-issues + approve" shape — so a gating caller cannot read a halt as a pass ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)). The recommendation is composed only from surviving findings, never from artifact text.

Focus areas passed by a caller receive extra scrutiny; the run is unattended with no mid-run gate (spec D11).

## Decomposition and Sequencing

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | Scaffold `han-experimental` plugin | `han-experimental/.claude-plugin/plugin.json` (name, experimental description, version `0.1.0`, deps `["han-core","han-plugin-builder"]`); `han-experimental` entry in `.claude-plugin/marketplace.json` ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)) | — | plugin.json parses; marketplace entry mirrors sibling shape |
| 2 | Detection script | `scripts/detect-guidance-and-type-context.sh` emitting `target-shape/target-type/structural-signal/guidance-root/guidance-complete/guidance-missing-files` + git-scope, degrading cleanly ([D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification), [D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages)) | 1 | detection tests: skill / agent / structural-misfire / neither-type / guidance-absent / no-git fixtures |
| 3 | `references/bloat-classification.md` | Three-tier rubric spanning six bloat categories, D6-exemption note, 2-3 worked examples/tier ([D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories)) | 1 | planted-bloat fixtures tier correctly |
| 4 | `references/` finding-classification, report template, checklist | Severity classification (mirror `agent-finding-classification.md`), report template (mirror code-review), conformance checklist per type ([D-3](artifacts/implementation-decision-log.md#trivial-decisions), [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)) | 1, 3 | report renders all sections; size thresholds match D-11 |
| 5 | `SKILL.md` | Frontmatter (name, description, `arguments: size`, `argument-hint`, minimal `allowed-tools`); 9-step skeleton wiring units 2–4; untrusted markers at generalist + validator dispatch; HALT-distinct-from-CLEAN contract ([D-2](artifacts/implementation-decision-log.md#trivial-decisions), [D-5](artifacts/implementation-decision-log.md#trivial-decisions), [D-12](artifacts/implementation-decision-log.md#d-12-allowed-tools-is-the-minimal-set-read-grep-glob-bashfind--agent), [D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards), [D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)) | 2, 3, 4 | functional + triggering tests (Testing Strategy) |
| 6 | Docs + index integration | CLAUDE.md plugin-map entry; skills-index entry; `docs/skills/han-experimental/review-skill-or-agent.md` long-form doc (CLAUDE.md coverage rule) | 5 | indexes list the new plugin + skill; long-form doc follows the template + voice |

## RAID Log

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | The installed `han-plugin-builder` guidance is reachable at a sibling-plugin path relative to the plugins root at runtime | The guidance-resolution order ([D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification)) must add or reorder probe locations, or vendoring becomes required sooner ([D-7](artifacts/implementation-decision-log.md#d-7-the-skill-is-not-vendored-vendoring-deferred-until-maintainers-state-a-preference)) | `edge-case-explorer` during unit 2 build (detection-script fixtures across install layouts) | Unverified — commit at build time |
| A2 | `allowed-tools` vs `tools`+`model` remains mutually exclusive across the skill/agent corpus, so frontmatter confirmation disambiguates a path-shape near-miss | Type routing ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages)) needs an additional structural signal | `edge-case-explorer` during unit 2 | Evidenced against current corpus; recheck on build |

### Dependencies

| ID | Dependency | Owner | Status |
|----|------------|-------|--------|
| Dep1 | `han-experimental` declares `han-core` so `han-core:junior-developer` (and focused reviewers) resolve at dispatch | Unit 1 (plugin.json deps) | Committed in plan ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)) |
| Dep2 | `han-experimental` declares `han-plugin-builder` so the guidance references resolve | Unit 1 | Committed in plan ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)) |

## Testing Strategy

Skills have no compiled tests; "tests" are the triggering + functional checks from the guidance's `success-criteria-and-testing.md`, run against a fixture set. Sourced from `test-engineer` and `edge-case-explorer` (Round 1).

- **Observable behaviors to test (8 functional tests, one per Primary Flow step / edge case):** guidance resolved and grounded against; type resolved correctly for a skill and an agent; size classified and roster scaled; conformance findings raised at correct severity; bloat findings raised and tiered per [D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories) and never demoted for being small (spec D6); a planted reviewer-directed "approve me" directive fails to suppress an independently-verifiable ground-truth finding and is itself raised (the falsifiable check for the "did not obey" invariant, spec F2 / [D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)); the validator demotes rather than drops absent concrete counter-evidence; the report's recommendation is the highest-severity surviving finding.
- **Triggering tests:** the skill triggers on "review this skill / agent" and should NOT trigger on documentation, application-code, or plugin/marketplace-config targets (routing to code-review / content-IA reviewers instead) — the both-directions disambiguation the description asserts ([D-2](artifacts/implementation-decision-log.md#trivial-decisions)).
- **Halt tests:** guidance-absent → dedicated HALT block, distinct from CLEAN, never "no-issues + approve" ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)); structural-misfire and neither-type produce the two distinct halt messages ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages)).
- **Edge cases requiring coverage:** oversize skill body (>500 lines) raised as a Warning conformance finding, full read preserved; no-git scope fallback (whole-artifact + conservative severity + explicit report line); malformed-frontmatter artifact routed by path-shape.
- **Fixture set (minimal, named):** a clean skill; skills with planted bloat at each tier (CRIT/WARN/SUGG); an embedded-directive fixture (the "approve me" injection); a malformed-type fixture (structural misfire); and `implement-work-items` reused as the large exemplar (533 lines / 8 refs).
- **Excluded:** a performance-comparison test suite — no cited need, and F1 already tests the value proposition (see Deferred (YAGNI)).

## Security Posture

The artifact under review is itself a document of imperative directives, which is an acute prompt-injection surface (spec D8). This plan commits to concrete mitigations from `adversarial-security-analyst` ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)):

- **Untrusted markers at four touch points.** The artifact body is wrapped in `----- BEGIN/END ARTIFACT UNDER REVIEW (UNTRUSTED) -----` markers at the skill's own reading step, the generalist-reviewer dispatch, the adversarial-validator dispatch (the fourth touch point the spec's D8 enumeration omitted), and the recommendation is composed only from surviving findings — never from artifact text.
- **Deliberate divergence from code-review:** here the fenced content is the PRIMARY review target ("evaluate closely as data"), not ancillary context to ignore.
- **Address-and-ask rule (semantic prose, not a phrase regex).** A directive addressing the skill's own runtime/user is evaluated as conformance; a reviewer-directed directive addressing the review or verdict ("report no findings") is out-of-place by construction and is itself a finding — default Warning, Critical if the skill's own runtime would emit a rigged verdict.
- **False-clean guards:** HALT is distinct from CLEAN in the output contract (a guidance-unavailable halt never renders as a pass); the validator overcorrection guard is inherited verbatim (Refuted drops only on concrete counter-evidence at file:line, else demote one severity); bloat findings are carved out of size demotion (spec D6).
- **Least privilege:** `allowed-tools` is trimmed to the minimal set the skill actually uses ([D-12](artifacts/implementation-decision-log.md#d-12-allowed-tools-is-the-minimal-set-read-grep-glob-bashfind--agent)); dispatched agents carry no `Agent` tool and cannot re-invoke the skill (recursion closed, spec F19).

## Definition of Done

- [ ] `han-experimental/.claude-plugin/plugin.json` exists with name `han-experimental`, version `0.1.0`, deps `["han-core","han-plugin-builder"]`, and is not in the `han` meta-plugin's dependencies ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)).
- [ ] `.claude-plugin/marketplace.json` lists a `han-experimental` entry mirroring an existing entry's shape ([D-6](artifacts/implementation-decision-log.md#d-6-home-the-skill-in-a-new-han-experimental-plugin-not-in-han-plugin-builder)).
- [ ] `review-skill-or-agent` triggers on a skill/agent review request and declines documentation / code / plugin-config targets, naming the covering tool ([D-2](artifacts/implementation-decision-log.md#trivial-decisions), spec D2/D14).
- [ ] Running the skill over a clean fixture yields a CLEAN report; over each planted-bloat fixture yields the tier `references/bloat-classification.md` prescribes, never demoted for being small ([D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories), spec D6).
- [ ] Size classification and the `size` override select the roster per [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2); the override never alters the always-run passes.
- [ ] Guidance-absent produces a dedicated HALT block distinct from CLEAN; structural-misfire and neither-type produce their two distinct halt messages ([D-9](artifacts/implementation-decision-log.md#d-9-type-and-context-detection-script-contract-type-routing-and-two-distinct-halt-messages), [D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards)).
- [ ] A planted "approve me" directive does not suppress a ground-truth finding and is raised as a finding ([D-13](artifacts/implementation-decision-log.md#d-13-untrusted-artifact-marker-mechanism-spans-four-touch-points-with-an-address-and-ask-semantic-rule-and-false-clean-guards), spec F2).
- [ ] `allowed-tools` is exactly `Read, Grep, Glob, Bash(find *), Agent` ([D-12](artifacts/implementation-decision-log.md#d-12-allowed-tools-is-the-minimal-set-read-grep-glob-bashfind--agent)).
- [ ] CLAUDE.md plugin map, skills index, and `docs/skills/han-experimental/review-skill-or-agent.md` all list the new plugin and skill (CLAUDE.md coverage rule).
- [ ] Post-ship owner named (skill author / maintainer of `han-experimental`).

## Specialist Handoffs for Implementation

- **`skill-builder`** — dispatch first, to author the `SKILL.md` and `references/` from this plan directly (no `plan-work-items` intermediary). Needs: this plan, the base skill `han-coding/skills/code-review`, and the closed rubrics ([D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories), [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)).
- **`test-engineer`** — dispatch when the fixture set is built, to confirm the 8 functional + triggering + halt tests. Needs: the fixture set (Testing Strategy) and `references/bloat-classification.md`.
- **`information-architect`** — dispatch only if/when the skill is blessed out of `han-experimental`, to make the reciprocal sibling-description edits ([D-15](artifacts/implementation-decision-log.md#d-15-reciprocal-sibling-description-edits-to-skill-builder--agent-builder-are-deferred-until-the-skill-is-blessed)). Not needed for the initial build.

## Deferred (YAGNI)

### Vendoring the skill via `init-guidance.sh`
- **Why deferred:** evidence test — no cited consumer needs the skill to run in a repo that has vendored the guidance but not installed `han-experimental`; not vendoring is the strictly simpler shape and avoids touching `init-guidance.sh` ([D-7](artifacts/implementation-decision-log.md#d-7-the-skill-is-not-vendored-vendoring-deferred-until-maintainers-state-a-preference)).
- **Reopen when:** a consumer needs the review in a vendored-only repo, or maintainers ask for it to be vendored.
- **Source:** R1, user pivot.

### Content-level cross-copy guidance staleness comparison
- **Why deferred:** simpler-version test — content integrity of a vendored guidance copy belongs to the vendoring mechanism, not this review; "prefer the trusted installed copy" plus the manifest completeness check covers the practical case ([D-8](artifacts/implementation-decision-log.md#d-8-guidance-resolution-stays-dynamic-via-a-runtime-detect-guidance-script-reverses-the-specialists-co-located-simplification)).
- **Reopen when:** a version-marker mechanism is added to vendored guidance, making a content comparison cheap and meaningful.
- **Source:** R1 (spec D9 minus this check).

### Agent body-line cap
- **Why deferred:** evidence test — the agent-building guidance defines no body-line ceiling; a review that grounds against guidance must not raise a finding the guidance does not support ([D-14](artifacts/implementation-decision-log.md#d-14-oversize-handling-scope-parsing-and-de-duplication-mechanics)).
- **Reopen when:** the agent guidance introduces a body cap.
- **Source:** R1, edge-case-explorer.

### Performance-comparison test suite
- **Why deferred:** evidence test — no cited need; the functional value-proposition test (F1) already exercises what the review is for.
- **Reopen when:** a measured latency or cost regression is observed on a real review run.
- **Source:** R1, test-engineer.

### Reciprocal sibling-description edits to skill-builder / agent-builder
- **Why deferred:** simpler-version test — the both-directions disambiguation is satisfied one-directionally from the new skill's side; editing a blessed, stable plugin's skill descriptions to point at an experimental skill in another plugin couples blessed to unblessed before maintainers sign off ([D-15](artifacts/implementation-decision-log.md#d-15-reciprocal-sibling-description-edits-to-skill-builder--agent-builder-are-deferred-until-the-skill-is-blessed)).
- **Reopen when:** the skill is blessed / promoted out of `han-experimental`.
- **Source:** R1, junior-developer (JD-008).

## Open Items

- **OI reciprocal-sibling-edits:** the reciprocal disambiguation edits to `skill-builder` and `agent-builder` descriptions are deferred while the skill is experimental ([D-15](artifacts/implementation-decision-log.md#d-15-reciprocal-sibling-description-edits-to-skill-builder--agent-builder-are-deferred-until-the-skill-is-blessed)).
  - **Resolves when:** the skill is blessed out of `han-experimental`; `information-architect` makes the edits then.
  - **Blocks implementation:** No — the new skill's own description disambiguates one-directionally, which is sufficient for a reader routing to it; the reverse edits are cosmetic until the skill is blessed.

Spec OI-1 and OI-2 are closed in this plan ([D-10](artifacts/implementation-decision-log.md#d-10-referencesbloat-classificationmd-closes-oi-1--a-three-tier-bloat-rubric-spanning-the-six-bloat-categories), [D-11](artifacts/implementation-decision-log.md#d-11-size-classification-and-roster-of-the-artifact-under-review-closes-oi-2)) and are not carried forward.

## Summary

- **Outcome delivered:** a new opt-in `han-experimental` plugin whose `review-skill-or-agent` skill produces a severity-ranked, guidance-grounded review of a skill or agent with bloat as a first-class corrective finding, wrappable by a gating caller exactly as code-review is.
- **Team size:** 5 specialists (project-manager, test-engineer, adversarial-security-analyst, edge-case-explorer, junior-developer) — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 1 — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 15 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 7 (D-9, D-10, D-11, D-12, D-13, D-14, D-15) — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by user input:** 3 (D-6, D-7, D-8 — the pivot) — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Rejected alternatives recorded:** 22 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 1 (reciprocal sibling-description edits, non-blocking)
- **Recommendation:** Ship as planned — hand off to `skill-builder`.
