# Implementation Iteration History: Per-Item Skill Selection

<!--
Round-by-round record. Deterministic aggregation (this skill), not per-round PM.
Cross-links: Decisions produced → implementation-decision-log.md (D-#); Changed in
plan → ../feature-implementation-plan.md sections. Both backfilled by PM in synthesis.
-->

## R1: Parallel specialist review (structural, test, junior-developer)

- **Specialists engaged:** han-core:structural-analyst, han-core:test-engineer, han-core:junior-developer
- **New input provided:** the feature specification + decision log; `.discovery-notes.md`; the live SKILL.md/reference/template files for both skills.

### Claim ledger

| # | Finding | Category | State | Spec-maturity | Raised by |
|---|---------|----------|-------|---------------|-----------|
| C1 | Skill/review/interactivity catalog belongs in a **new producer `references/` file** (`deliverable-skill-catalog.md`), following the established reference-extraction pattern and progressive-disclosure guidance; inlining in Step 5 bloats the always-loaded body. | overlap/structure | Evidenced | plan-level | structural (S1), junior (JD-003) |
| C2 | Driver needs only the **recorded signals + its own supported combo**, not the catalog → catalog is producer-only, no duplication. A driver-side copy is a YAGNI candidate (drift surface). | coupling | Evidenced | plan-level | structural (S2), junior (JD-003) |
| C3 | **Template is the single source of field names**; driver Step 1.7 must quote each field verbatim. Moving from 1 field (`Type`) to 5 new fields multiplies the silent-mismatch surface 5×; verbatim quoting is the only mitigation (no CI). | coupling/coordination | Evidenced | plan-level | structural (S3/S5-Pin3), test (Check 3a/R6) |
| C4 | **Driver `Type`→signals re-plumb**: Step 1.7 becomes three checks — fields-present (5 new), all-fully-autonomous (computed from signals), supported-combination (`tdd`+`code-review`) — as **two distinct refusal messages** (needs-a-human vs unsupported-combo) plus a pre-feature-file refusal (old `Type`, missing new fields). Steps 2.1/3.1/3.3/3.4 read recorded skill/review; frontmatter "AFK-typed"→"fully-autonomous"; contract opening sentences updated for accuracy (no operative change). | assumption/coupling | Evidenced | plan-level | structural (S4), test (R2/R3) |
| C5 | **Producer edit sites = template + SKILL.md Steps 5, 7, 8** (not just template + Step 5): Step 7 prints "Type: HITL/AFK"; Step 8 in-channel summary counts "by type" and offers the "all-AFK" driver handoff — both hard-code the vocabulary being replaced. | scope | Evidenced | plan-level | junior (JD-002) |
| C6 | Producer closing recommendation **encodes the driver's supported combo** (`tdd`+`code-review`), a fact the driver also hard-codes — cross-plugin coupling. No shared source; manage editorially (a shared reference for one consumer pair is YAGNI). Expanding the combo later requires a coordinated producer edit. | coupling | Evidenced | plan-level | structural (S5-Pin2), junior (JD-004) |
| C7 | **`.implement-work-items/state.md` should NOT record per-item skill/review** — every driven item is `tdd`+`code-review`, so the field is constant today. YAGNI candidate; defer. | YAGNI-candidate | Evidenced | plan-level | junior (JD-005) |
| C8 | **Atomic ship**: producer + driver + template + catalog reference + docs land in one merge; no CI means a half-merge silently breaks both skills. In-branch order: template+catalog → producer Steps 5/7/8 → driver 1.7/2.1/3.x → docs. | coordination | Evidenced | plan-level | structural (S5-Pin1), junior (JD-006) |
| C9 | **Long-form docs are mandatory DoD** (CONTRIBUTING coverage rule): `docs/skills/han-planning/plan-work-items.md`, `docs/skills/han-coding/implement-work-items.md`, via `han-update-documentation`; plus the driver frontmatter description ("AFK-typed"→"fully-autonomous"). Producer description/argument-hint need no change; advertising overrides there is YAGNI. | scope/standards | Evidenced | plan-level | test (§4), junior (JD-009/JD-010) |
| C10 | **Consumers safe**: `work-items-to-issues`/`-jira`/`-linear` parse heading + `Depends on` only; new fields pass through the body verbatim. Spot-check, not a rewrite. RAID note. | overlap | Evidenced | plan-level | structural (summary), test (Check 3d) |
| C11 | Verification is **review + spot-run** (no test harness): a 4-item representative fixture for the producer; three driver spot-runs (drivable / mixed-refusal / pre-feature-refusal); side-by-side field-name review. | test-strategy | Evidenced | plan-level | test (full report) |
| C12 | **Three mechanisms the spec deferred to plan-implementation** — installed-skill detection, override grammar, non-han autonomy-declaration syntax — must be **designed in this run** (else unbuildable). junior tagged "Blocks decision"; resolved below as OQ-3/OQ-4. | ambiguity | Evidenced | plan-level | junior (JD-001/JD-008) |

**Spec-maturity gate:** NOT tripped. Zero T#-contradictions (no tech-notes exist). Spec-level findings: 0 — the deferred mechanisms (C12) were intentionally delegated to plan-implementation by the spec, so they are plan-level HOW questions this run answers, not spec gaps. No PM gate-trip facilitation call made.

### Open Questions and resolutions (evidence/decision, this run)

- **OQ-1 — Where does the catalog live?** → **Resolved (evidence).** New producer reference `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`, per the existing reference pattern and `progressive-disclosure.md` ("decision matrices go in references"). Driver does not get a copy (C2). → D-1.
- **OQ-2 — Single source for the supported combo?** → **Resolved (evidence).** No shared reference (YAGNI for one consumer pair, C6). The producer's closing recommendation names `tdd`+`code-review` inline; the driver hard-codes it in dispatch/validation; a plan note records that expanding the combo requires a coordinated producer edit. → D-7.
- **OQ-3 — Installed-skill detection mechanism?** → **Resolved (decision).** The producer detects installed skills from the session's available-skills registry (the same set that tells it which skills it can invoke), naming each han catalog skill's plugin origin so it can report, e.g., "`skill-builder` ships in `han-plugin-builder` — not detected." Best-effort, consistent with the spec's "detects rather than assumes." No new manifest is built (none exists to read). → D-4.
- **OQ-4 — Override grammar + non-han autonomy declaration syntax?** → **Resolved (decision).** The invocation channel is natural-language instruction the producer interprets (a prompt-skill parses this natively — no formal grammar). The pre-written marker channel is a recognizable single-line annotation the producer scans for in the source plan (a bracketed directive near the relevant section), carrying the skill, optional review, and optional non-han autonomy declaration. Kept minimal. → D-5.
- **OQ-5 — Record per-item skill/review in `state.md`?** → **Resolved (YAGNI).** No — constant across driven items today; deferred (C7). → Deferred (YAGNI).

### Next-step recommendation

**Go to synthesis.** All Open Questions resolved by evidence or implementation decision; no user escalation required; no specialist handoff outstanding (structural-analyst, the only requested handoff, ran this round); gate not tripped; round cap (2) not needed.

- **Decisions produced:** D-1, D-2, D-3, D-4, D-5, D-6, D-7, D-8, D-9, D-10, D-11 (9 full, 2 trivial). Mapping: C1→D-1; C2→D-2; C3→D-3; OQ-3→D-4; OQ-4→D-5; C4→D-6; C6/OQ-2→D-7; C8→D-8; C5→D-9 (trivial); C9→D-10 (trivial); the spec D4/D6 schema realized as D-11. C7/OQ-5 and C10 fed the plan's Deferred (YAGNI) and RAID R4 rather than a standalone decision.
- **Changed in plan:** Source Specification; Outcome; Context; Team Composition and Participation; Implementation Approach (Architecture and Integration Points, Data Model and Persistence, Runtime Behavior, External Interfaces); Decomposition and Sequencing; RAID Log; Testing Strategy; Definition of Done; Specialist Handoffs for Implementation; Deferred (YAGNI); Open Items; Summary — the plan was authored in full this round.
