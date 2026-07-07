# Implementation Decision Log: Per-Item Skill Selection for Work Items

<!--
This file records every implementation decision committed while planning Per-Item
Skill Selection. Behavioral and implementation statements live in
[../feature-implementation-plan.md](../feature-implementation-plan.md) — this file
captures the question, rationale, evidence, and rejected alternatives for each
decision. Round-by-round history lives in
[implementation-iteration-history.md](implementation-iteration-history.md).

Two-tier format: full decisions carry all fields; trivial decisions are one-line
bullets. The D-N counter is shared across both sections. Any time a full decision
is added or edited, keep the matching entries in implementation-iteration-history.md
and ../feature-implementation-plan.md in sync.
-->

## Trivial decisions

- D-9: Producer edit sites — the producer change lands in `references/work-item-template.md` plus `SKILL.md` Step 5 (the `project-manager` drafting brief records the five per-item fields, derives the han signals, applies overrides, and runs installed-skill detection), Step 7 (the breakdown print replaces `Type: HITL/AFK` with the five fields, the derived label, a driver-ready / needs-a-hand marker, and the flags), and Step 8 (the in-channel summary and the three-bucket closing recommendation, replacing the "count by type" summary and the "all-AFK" driver handoff). — Referenced in plan: Implementation Approach (Runtime Behavior); Decomposition and Sequencing.
- D-10: Long-form docs are mandatory — update `docs/skills/han-planning/plan-work-items.md` and `docs/skills/han-coding/implement-work-items.md` through `han-update-documentation`; the driver's long-form doc drops the stale "build skill is `/tdd`, and only `/tdd`; per-item selection is deferred" note and the "AFK-typed" prerequisites; the producer's `description` and `argument-hint` are unchanged (advertising overrides there is a YAGNI deferral). — Referenced in plan: Decomposition and Sequencing; Definition of Done.

## Full decisions

### D-1: Catalog lives in a new producer reference

- **Question:** Where does the deliverable-nature-to-implementation-skill map, the nature-to-review map, the han-skill interactivity enumeration (spec D4), the non-han declaration/default rule, and the not-installed fallback live?
- **Decision:** Create one new producer reference, `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`, loaded by Step 5, holding all five of those tables and rules. The catalog is producer-only.
- **Rationale:** The producer already extracts decision matrices into `references/`; keeping the always-loaded Step 5 body lean is the established pattern, and a decision matrix is exactly what the authoring guidance says belongs in a reference. One file also gives the interactivity enumeration a single home the producer maintains as skills change.
- **Evidence:** Existing reference-extraction pattern in `han-planning/skills/plan-work-items/references/` (`work-item-template.md`, `work-items-file-format.md`, `reference-artifact-inventory.md`); `han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md` ("decision matrices go in references"); spec [D2](decision-log.md#d2-deliverable-nature-decision-tree-and-skill-catalog) and [D4](decision-log.md#d4-recorded-autonomy-signals-replace-the-afkhitl-type); discovery Gaps (no capability manifest exists, so the enumeration must be authored as a producer reference).
- **Rejected alternatives:**
  - Inline the catalog in Step 5 of `SKILL.md` — rejected because it bloats the always-loaded skill body with a matrix that is only consulted while drafting.
  - A driver-side copy of the catalog — rejected as a drift surface with no consumer (see [D-2](#d-2-driver-reads-signals-not-the-catalog)); deferred under YAGNI.
- **Specialist owner:** `structural-analyst`
- **Revisit criterion:** A consumer other than the producer needs the interactivity enumeration at run time (for example, a future driver that must derive a non-han skill's interactivity itself).
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-2, D-9
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Decomposition and Sequencing

### D-2: Driver reads signals, not the catalog

- **Question:** Does the driver read the catalog to compute autonomy, or only the recorded signals on each item?
- **Decision:** The driver consumes the per-item recorded signals plus its own hardcoded supported combination, and does **not** read the catalog. The catalog stays producer-only, so there is no duplicated interactivity table across the two skills.
- **Rationale:** The producer records every signal on every item (spec D6), so the driver has all the autonomy inputs it needs without an interactivity source. A second copy of the enumeration would be a maintenance and drift surface with nothing to consume it, since the driver only ever computes "fully autonomous" and "supported combination."
- **Evidence:** Spec [D4](decision-log.md#d4-recorded-autonomy-signals-replace-the-afkhitl-type) and [D6](decision-log.md#d6-per-item-fields-implementation-skill-review-and-autonomy-signals) (signals recorded per item; driver computes autonomy from the signals); discovery Gaps ("Prior: driver reads recorded signals + its own supported combo; catalog is producer-only").
- **Rejected alternatives:**
  - Give the driver a copy of the catalog — rejected: no consumer for it, and a divergent copy would silently mis-classify items.
- **Specialist owner:** `structural-analyst`
- **Revisit criterion:** A future driver must derive interactivity for a skill whose signals are not recorded (for example, reading a non-han skill directly).
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-6
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Deferred (YAGNI)

### D-3: Template is the single field-name source

- **Question:** With no compiler and no CI, how are the per-item field names kept identical between the producer that writes them and the driver that validates them?
- **Decision:** Field names are defined once, in `references/work-item-template.md`. The driver's Step 1.7 quotes each field name verbatim (backtick-bold), so the two skills share exactly one vocabulary. "Implementation skill" is the single name for the build-skill field; there is no "build skill" alias.
- **Rationale:** The schema goes from one field (`Type`) to five, which multiplies the silent-mismatch surface fivefold. With nothing to mechanically catch a divergence, verbatim quoting from a single source is the only mitigation available; a paraphrase in the driver would silently refuse every file.
- **Evidence:** Discovery ("No automated test suite or CI"; verification is review-based); round claim C3 (structural S3/S5-Pin3, test Check 3a/R6); spec [D6](decision-log.md#d6-per-item-fields-implementation-skill-review-and-autonomy-signals) and finding F13 (one field, one name).
- **Rejected alternatives:**
  - Paraphrase the field names in the driver's validation prose — rejected: any drift silently trips the missing-field refusal on every file.
  - Extract a shared field-name reference read by both skills — rejected: the template already is the single source, so a second file is redundant indirection.
- **Specialist owner:** `structural-analyst`
- **Revisit criterion:** A machine-checkable schema or CI check is introduced that can enforce field-name parity mechanically.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-6
- **Referenced in plan:** Implementation Approach (Data Model and Persistence); Testing Strategy; Definition of Done; RAID Log

### D-4: Installed-skill detection from the session registry

- **Question:** How does the producer detect which catalog skills are installed, so it can apply the not-installed fallback?
- **Decision:** The producer detects installed skills from the session's available-skills registry — the same set that tells it which skills it can invoke — and names each han catalog skill's plugin origin, so it can report, for example, "`skill-builder` ships in `han-plugin-builder` — not detected." Detection is best-effort. No new capability manifest is built.
- **Rationale:** The spec fixes only the behavior ("detects rather than assumes") and defers the mechanism to this stage. Nothing machine-readable exists to read, so the session's own registry of invocable skills is the only trustworthy signal, and it is exactly the signal the producer needs.
- **Evidence:** Discovery Gaps (no existing skill-capability manifest); spec Preconditions and [D9](decision-log.md#d9-uninstalled-best-fit-falls-back-to-bare-hitl); round OQ-3.
- **Rejected alternatives:**
  - Build a capability manifest to read — rejected: none exists, and authoring one is over-scoped for a best-effort check.
  - Assume the catalog skills are installed — rejected: the spec forbids assuming, because `han-plugin-builder` skills are frequently absent.
- **Specialist owner:** `junior-developer` (raised OQ-3); `structural-analyst`
- **Revisit criterion:** Installed skills expose a machine-readable capability declaration the producer can trust (spec Deferred).
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-9
- **Referenced in plan:** Implementation Approach (Runtime Behavior)

### D-5: Override channels, invocation instruction and pre-written marker

- **Question:** What concrete form do the invocation override and the pre-written marker take?
- **Decision:** The invocation override is a natural-language instruction the producer interprets (a prompt skill parses this natively; no formal grammar is defined). The pre-written marker is a recognizable single-line annotation the producer scans for in the source plan — a bracketed directive near the relevant section — carrying the skill, an optional review, and an optional non-han autonomy declaration. Both are read-only against the source. Kept minimal.
- **Rationale:** The producer is a prompt skill, so a formal override grammar buys nothing over natural-language interpretation; a minimal single-line marker covers the repeatable-run case without a parser; and the read-only posture preserves the skill's rule that the source plan is never modified.
- **Evidence:** Spec [D7](decision-log.md#d7-overrides-by-invocation-instruction-and-pre-written-marker) (both channels; bind-by-description) and finding F12; `han-planning/skills/plan-work-items/SKILL.md` Rules ("read-only input"); round OQ-4.
- **Rejected alternatives:**
  - Define a formal override grammar — rejected: a prompt skill parses natural language natively, so a grammar is unneeded machinery.
  - Support only one channel — rejected: the spec committed to both (invocation for ad-hoc, marker for repeatable).
- **Specialist owner:** `junior-developer` (raised OQ-4); `structural-analyst`
- **Revisit criterion:** Operators need machine-validated markers (for example, an automated pipeline emits them).
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-9
- **Referenced in plan:** Implementation Approach (Runtime Behavior)

### D-6: Driver re-plumb from Type to signals

- **Question:** How does the driver change to consume the new fields instead of the removed `Type`?
- **Decision:** Step 1.7 becomes three checks — fields-present (the five new fields), all-fully-autonomous (computed from the signals), and supported-combination (`tdd` built, `code-review` reviewed) — surfacing **two distinct refusals**: needs-a-human, and fully-autonomous-but-unsupported-combination. A third, pre-feature-file refusal fires when items carry the old `Type` and omit the new fields, directing the operator to re-run `plan-work-items`. Steps 2.1, 3.1, 3.3, and 3.4 read the recorded implementation skill and review instead of hardcoding `tdd`/`code-review`, in both the initial build and every fix round, preserving each dispatched skill's contract. The frontmatter description changes "AFK-typed" to "fully-autonomous." The opening sentences of `build-report-contract.md` and `review-verdict-contract.md` are updated for accuracy only; there is no operative change, because the driver still drives only `tdd` + `code-review`.
- **Rationale:** The driver no longer reads `Type`, so it must both validate the new fields and compute autonomy from the signals. Two distinct refusals let the operator tell "an item needs a human" from "the combination is not supported yet," which have different remedies. The pre-feature-file refusal distinguishes an explicit `none` (a legitimately bare item) from an omitted field (an old file), per spec F2. Reading the recorded skill in the fix round as well closes the gap the spec called out in F9. The contract edits are accuracy-only because expanding the combo is out of scope here.
- **Evidence:** `han-coding/skills/implement-work-items/SKILL.md` hardcodes `han-coding:tdd` and `han-coding:code-review` and reads `**Type.**` at Steps 1.7, 2.1, 3.1, 3.3, 3.4; spec [D5](decision-log.md#d5-driver-drivability-is-computed-from-the-signals), [D6](decision-log.md#d6-per-item-fields-implementation-skill-review-and-autonomy-signals), findings F2 and F9; the two contract files' opening sentences name `tdd`/`code-review`; round claim C4 (structural S4, test R2/R3).
- **Rejected alternatives:**
  - Read a stored `Type` to gate the driver — rejected: the spec replaced `Type` with the three signals.
  - Collapse the failures into one refusal message — rejected: it loses the remediation legibility of naming the two distinct causes.
  - Rewrite the two contracts operatively for per-skill dispatch — rejected as over-scoped: the driver still drives only `tdd` + `code-review`, so an accuracy-only opening-sentence edit is the simpler version that satisfies the same need.
- **Specialist owner:** `structural-analyst`
- **Revisit criterion:** The driver's supported combination expands (see [D-7](#d-7-supported-combo-stated-inline-coupling-noted)), or the human-in-the-loop driver lands and consumes the signals per phase.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior); Decomposition and Sequencing; Testing Strategy; Definition of Done

### D-7: Supported combo stated inline, coupling noted

- **Question:** Where does the driver's supported combination (`tdd` + `code-review`) live, given that both the producer's closing recommendation and the driver's validation and dispatch encode it?
- **Decision:** The producer's closing recommendation names `tdd` + `code-review` inline; the driver hardcodes the same pairing in its validation and dispatch. There is no shared reference. A plan note records that expanding the driver's supported combination later requires a coordinated edit to the producer's closing recommendation.
- **Rationale:** A shared reference for a single consumer pair is over-abstraction (the Rule of Three is not met). The cross-plugin coupling is real but changes rarely; managing it editorially with a documented note is the simpler version that still makes the coupling discoverable.
- **Evidence:** Round claim C6 (structural S5-Pin2, junior JD-004); round OQ-2; spec Deferred (YAGNI) ("Expanding the driver's supported combinations").
- **Rejected alternatives:**
  - A shared supported-combo reference read by both skills — rejected: single consumer pair, so it is a single-implementation abstraction; deferred under YAGNI.
  - Silent duplication with no note — rejected: the coupling would be undiscoverable to whoever expands the combo later.
- **Specialist owner:** `structural-analyst`
- **Revisit criterion:** A second supported combination is added and drift between the two sites is observed.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-6, D-9
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Deferred (YAGNI)

### D-8: Atomic ship and in-branch sequencing

- **Question:** Do the producer, driver, template, catalog, and docs ship together or separately, and in what in-branch order?
- **Decision:** All of it lands in one merge: producer, driver, template, catalog reference, and long-form docs. In-branch build order: template + catalog, then producer Steps 5/7/8, then driver Steps 1.7/2.1/3.x, then long-form docs.
- **Rationale:** The driver no longer reads `Type`, so a producer-only merge would leave the driver refusing every current file, and a driver-only merge would leave it validating fields no producer writes. With no CI to catch a half-merge, atomic shipping is the only safe posture. The build order lets each stage rest on the field names and catalog it depends on.
- **Evidence:** Spec Coordinations ("the producer and driver companion changes ship together"); round claim C8 (structural S5-Pin1, junior JD-006); discovery (no CI, review-based verification).
- **Rejected alternatives:**
  - Incremental merges — rejected: any half-merge silently breaks both skills.
  - Driver-first — rejected: the driver would validate a vocabulary the producer does not yet write.
- **Specialist owner:** `project-manager`
- **Revisit criterion:** A CI or compile-time check is added that can catch cross-skill drift, making a staged merge safe.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Decomposition and Sequencing; RAID Log

### D-11: Work-item schema change

- **Question:** What is the exact per-item field set after this feature, and what concrete labels do the three autonomy signals take?
- **Decision:** The per-item field set becomes: **Implementation skill.** (a skill name, or `none` for a bare item); **Review.** (a review skill, a review agent, `human read`, or `none`); **Build unattended.** (`yes` or `no`); **Review unattended.** (`yes` or `no`); **Pre-work decision.** (`yes` or `no`, whether a human decision is required before work starts); plus the unchanged **Expected paths.** and **Depends on.**. The `**Type.**` field is removed. AFK/HITL becomes a derived label: an item is fully autonomous when `Build unattended = yes`, `Review unattended = yes`, and `Pre-work decision = no`, and needs a human otherwise. A bare item carries `Implementation skill = none`, distinct from a field the producer never wrote.
- **Rationale:** The spec fixes the field set and replaces `Type` with the three signals; the signals need concrete, consistent labels because the template is the single field-name source (D-3). Uniform `yes`/`no` domains keep the derived-label computation total and legible and make the driver's signal parsing simple. The explicit `none` keeps the "field present on every item" invariant true for bare items while letting the driver distinguish them from a pre-feature file (spec F2).
- **Evidence:** Spec [D4](decision-log.md#d4-recorded-autonomy-signals-replace-the-afkhitl-type) and [D6](decision-log.md#d6-per-item-fields-implementation-skill-review-and-autonomy-signals); `han-planning/skills/plan-work-items/references/work-item-template.md` (`**Type.** AFK or HITL. Required.` at line 36; `**Expected paths.**` at line 38); discovery ("This is where the field-set change lands").
- **Rejected alternatives:**
  - Keep `Type` as a stored derived rollup alongside the signals — rejected (spec D4/D6): a stored derived value drifts from the signals it summarizes.
  - Free-text signal values — rejected: not total or legible; the `yes`/`no` domain is the simpler version.
  - A "build skill" alias for the implementation-skill field — rejected (spec F13): one field, one name.
- **Specialist owner:** `structural-analyst`; `test-engineer`
- **Revisit criterion:** The human-in-the-loop driver is cancelled (revisit whether all three signals earn their storage — see plan Assumption A1), or a signal needs a value beyond `yes`/`no`.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-3, D-6, D-9
- **Referenced in plan:** Implementation Approach (Data Model and Persistence); Decomposition and Sequencing; Definition of Done
