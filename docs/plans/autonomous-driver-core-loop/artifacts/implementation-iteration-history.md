# Implementation Iteration History: Autonomous Driver — Core Loop

<!--
Round-by-round record of the plan-implementation facilitation. Committed decisions live
in [implementation-decision-log.md](implementation-decision-log.md); the primary plan lives
in [../feature-implementation-plan.md](../feature-implementation-plan.md). No separate
facilitation files are written — the claim ledger, Open Questions, and spec-maturity tags
live on each round entry. `Decisions produced:` and `Changed in plan:` are backfilled during
the project-manager synthesis step. No feature-technical-notes.md exists for the source spec,
so the T#-contradiction classification does not apply this run.
-->

## R1: Parallel specialist review + deterministic aggregation

- **Specialists engaged:** `software-architect`, `test-engineer`, `junior-developer` (all sonnet). `project-manager` not called in R1 (deterministic aggregation; the spec-maturity gate did not trip, so no facilitation pass). Team size Medium (cap 4-5, round cap 2); `devops-engineer`/`on-call-engineer` deliberately omitted — a markdown skill has no deploy/runtime/infra surface.
- **New input provided:** the source `feature-specification.md`, its `artifacts/decision-log.md` and `artifacts/team-findings.md`, and `artifacts/.discovery-notes.md` (which carries the RESOLVED platform-capability findings: sub-agent nesting supported v2.1.172, free-form sub-agent returns, `skills:` preload, per-call model on the Agent tool).
- **Claim ledger:**
  - *Dispatch mechanism = Agent tool + prompt naming the skill + per-call `model` (not preload worker-agent defs).* **Evidenced** (software-architect A1: D10, D12, discovery-notes platform findings). No dispute. → D-1.
  - *Review fan-out topology: driver (main session) → one review sub-agent (depth 1) → `code-review` panel (depth 2); the review sub-agent retains the Agent tool; **Claude Code v2.1.172 is a hard prerequisite**.* **Evidenced** (software-architect A2: D9, discovery finding 1). No dispute. → D-2, D-3 (prerequisite).
  - *Compact-return contract imposed by prompt (no schema validation exists), parsed by named-section headers, malformed/incomplete report → immediate halt (fail-closed).* **Evidenced** (software-architect A3: D10, D6, spec F6, discovery finding 3). No dispute. → D-4.
  - *`allowed-tools` mirrors `tdd`'s per-prefix runner list + Agent + git + find; per-prefix Bash cannot cover an unknown project's command, so an un-runnable verify command is the "tooling unavailable" halt.* **Evidenced** (software-architect A5: D7, `tdd` SKILL.md frontmatter). No dispute. → D-5.
  - *Driver artifacts (work-state file + per-item durable review records) live at concrete git-excluded paths; commits stage explicitly (never `git add -A`).* **Evidenced** (software-architect A6 + junior IMPL-01: D18, D9, spec F4/F5). Overlap; minor format sub-dispute (markdown vs YAML) — resolvable by convention. → D-6.
  - *Verification-command auto-detection heuristic (which config files, priority, `--verify` override, scope-check-only fallback).* **Anecdotal→resolved** (junior IMPL-03: real work, no Han precedent; resolved by evidence — mirror `tdd`'s `scripts/detect-tdd-context.sh` resolution order). → D-7.
  - *Valid-implementation-skill recognition = hard-coded set; `tdd` is the only core member (`refactor` "can ask as it goes" → interactive-ineligible).* **Evidenced** (junior IMPL-04: spec D13/D16; `refactor` interactivity per spec D16 evidence). → D-8.
  - *Prior-run branch detection marker convention (commit-message pattern or git trailer on the planning-artifacts commit).* **Evidenced** (junior IMPL-02, software-architect A6: spec D14). Minor convention choice — resolvable. → D-9.
  - *Branch-name default derivation (feature-dir based).* **Disputed(minor)** (software-architect `feature/{stem}` vs junior `driver/{dir}-{date}`) — resolvable by convention. → D-10.
  - *Commit-convention detection (read CLAUDE.md/project-discovery; default conventional commits).* **Evidenced** (junior IMPL-09: spec D8). → D-11.
  - *Planning-artifact identification = parse the work-items.md preamble for local `.md` links; show the set at the preview.* **Evidenced** (junior IMPL-05: spec Primary Flow step 1, F10). → D-12.
  - *References-file granularity.* **Disputed** (software-architect A4 = 4 files: 2 contracts + validation-rules + halt-frame; junior IMPL-07 = extract the 2 contracts, keep validation + halt inline until the draft overflows the ~400-line precedent). Resolved by the YAGNI simpler-version test in junior's favor. → D-13.
  - *Testing/verification is dogfood + the CONTRIBUTING self-review checklist; Han itself exercises only the scope-check-only path (no verify commands), so a fixture repo with a real test suite is needed for independent verification.* **Evidenced** (test-engineer). No dispute. → D-14, D-15 (DoD).
  - *Companion-change verification: a fixture work-items file exercising both new fields; the producer emits them; format consistency across the template, the file-format doc, and the driver's validation.* **Evidenced** (test-engineer, spec D19). → D-16.
  - *Cross-plugin prose reference (plan-work-items Step 8 naming the han-coding driver) is a prose pointer, not a dependency violation; name the plugin so an operator without it is not surprised.* **Evidenced** (junior IMPL-06, test-engineer, CONTRIBUTING). → trivial decision / Team Composition note.
- **Open Questions raised:**
  - OQ-1: the slash-command name (spec D20 deferred it). → **user input**: `implement-work-items`.
  - OQ-2: references-file granularity (4 vs 2). → **junior-developer reframing** (YAGNI simpler-version): extract the 2 contracts; validation + halt inline until overflow.
  - Minor: work-state file format (md vs YAML), prior-run marker convention, branch-name default — all resolved by **evidence/convention** during the resolution pass.
- **Spec-maturity tags:** plan-level: all findings (IMPL-01..IMPL-10, A1..A6, the test-engineer set). spec-level: 0. T#-contradiction: 0 (no T# notes). **Spec-maturity gate: NOT tripped.**
- **Resolution source:** OQ-1 → user input; OQ-2 → junior-developer reframing (IMPL-07); verify-detection, valid-skill set, marker, branch default, commit convention, planning-artifact parsing, artifact paths → evidence (spec deferrals + `tdd`/`code-review` precedent). Remaining items → PM synthesis (Step 8 evidence) where noted.
- **Decisions produced:** D-1, D-2, D-3, D-4, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12, D-13, D-14, D-15, D-16, D-17, D-18, D-19 (D-1 through D-9, D-12 through D-16 full; D-10, D-11, D-17, D-18, D-19 trivial). See [implementation-decision-log.md](implementation-decision-log.md).
- **Changed in plan:** the whole plan was authored from this single round — Source Specification; Outcome; Context; Team Composition and Participation; Implementation Approach (Architecture and Integration Points, Data Model and Persistence, Runtime Behavior, External Interfaces); Decomposition and Sequencing; RAID Log (Risks, Assumptions, Dependencies); Testing Strategy; Definition of Done; Specialist Handoffs for Implementation; Deferred (YAGNI); Open Items; Summary. See [../feature-implementation-plan.md](../feature-implementation-plan.md).
- **Project-manager next-step recommendation:** Go to synthesis. One specialist round plus a resolution pass converged: the architecture is Evidenced and un-disputed, the single dispute (refs granularity) resolved by the YAGNI rule, and the single user Open Question (skill name) answered. No spec-maturity gate trip, no required specialist handoff for a round 2 (the `behavioral-analyst` review-context-budget concern is conditional-on-authoring, recorded as a RAID risk and a specialist handoff, not a round-2 trigger).
