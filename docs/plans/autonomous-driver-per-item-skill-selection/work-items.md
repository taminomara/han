# Work Items — Per-Item Skill Selection

Broken down from the parent plan: [feature-implementation-plan.md](feature-implementation-plan.md) (behavioral source: [feature-specification.md](feature-specification.md)).

Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

**This is one atomic PR, not eight independent releases.** Per `See plan: D-8`, the whole feature ships in a single merge in a fixed in-branch order (template + catalog → producer → driver → long-form docs → integration gate). No item is shippable on its own: the driver stops reading the old `Type` field, so a partial merge silently breaks both skills. The `Depends on` chains below encode the build order.

**This feature is not self-drivable.** These are prompt-authoring edits to two Claude Code skills (markdown), and Han's own deliverables are documentation-nature — `implement-work-items` would classify them to non-`tdd` skills and refuse to drive them. Build these by hand or by invoking skills directly; there is no compiler and no CI, so verification is review plus spot-run. `Type: AFK` here means "no human decision is needed to implement it," not "the current driver can run it."

## Shared reference artifacts

These apply to more than one work item; each item's `**References.**` block points here plus any item-specific spec section.

- **Feature specification** — [feature-specification.md](feature-specification.md). Behavioral source of truth for every item.
- **Contributor guide and PR checklist** — [../../../CONTRIBUTING.md](../../../CONTRIBUTING.md). Voice rules (no em-dashes, no voice violations), the PR checklist that gates the merge, and the long-form-doc coverage rule. Applies to every item.
- **Skill-authoring guidance** — [progressive-disclosure.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md) (decision matrices and domain knowledge belong in `references/`, not the always-loaded skill body) and [skill-reference-files.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-reference-files.md) (reference-file placement). Applies to the skill and reference-authoring items.
- **Long-form doc template** — [../../templates/skill-long-form-template.md](../../templates/skill-long-form-template.md). Structure the documentation items must follow.

## W-1 — Replace `Type` with the five per-item schema fields in the work-item template

**Summary.** Change the per-item schema in the producer's work-item template, replacing the single `**Type.** AFK or HITL` field with five fields, so that AFK/HITL becomes a derived label rather than a stored field (`See plan: D-11`). This file is the single source of the field names the driver later quotes verbatim (`See plan: D-3`).

**Description.**
1. Edit `han-planning/skills/plan-work-items/references/work-item-template.md`, replacing the `**Type.** AFK or HITL. Required.` field with five per-item fields, keeping `**Expected paths.**` and `**Depends on.**` exactly as they are (`See plan: D-11`):
   - `**Implementation skill.**` — a skill name, or `none` for a bare item.
   - `**Review.**` — a review skill, a review agent, `human read`, or `none`.
   - `**Build unattended.**` — `yes` or `no`.
   - `**Review unattended.**` — `yes` or `no`.
   - `**Pre-work decision.**` — `yes` or `no` (whether a human decision is required before work starts).
2. Note in the template that AFK/HITL is no longer stored — it is derived: fully autonomous iff `Build unattended = yes`, `Review unattended = yes`, and `Pre-work decision = no`.
3. Use `none` (an explicit value, never an omitted field) for a bare item's implementation skill, so a bare item stays distinguishable from a pre-feature file (`See plan: D-11`).
4. Use `Implementation skill` as the single name for the build-skill field — no `build skill` alias anywhere (`See plan: D-3`).

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (the fields and their values) and [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (the bare-item `none` and pre-feature-`Type` rows).
- **Standards** — see Shared reference artifacts (CONTRIBUTING voice).

**Tests.**
- Review: the five field labels are present, correctly named, and in a consistent order; `**Expected paths.**` and `**Depends on.**` are unchanged; `**Type.**` is removed.
- Review: `Implementation skill` is the single build-skill field name; no `build skill` alias.

**Acceptance criteria.**
- [ ] The template carries the five new fields plus unchanged `**Expected paths.**` and `**Depends on.**`; `**Type.**` is gone.
- [ ] The derived fully-autonomous rule (all three signals) is stated in the template.
- [ ] A bare item uses `Implementation skill = none`, not an omitted field.

**Type.** `AFK`

**Expected paths.**
- `han-planning/skills/plan-work-items/references/work-item-template.md`

**Depends on.** None.

## W-2 — Author the `deliverable-skill-catalog.md` producer reference

**Summary.** Create the new producer-only reference that drives skill and review selection, signal derivation, non-han handling, and the not-installed fallback (`See plan: D-1`). The driver never reads it, so the interactivity enumeration lives in exactly one place (`See plan: D-2`).

**Description.**
1. Create `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`, following the existing reference-extraction pattern in that folder (`work-item-template.md`, `work-items-file-format.md`, `reference-artifact-inventory.md`). A decision matrix belongs in a reference, not the always-loaded skill body (`See plan: D-1`).
2. Include the deliverable-nature → implementation-skill map: testable code → `tdd`; behavior-preserving restructuring of tested code → `refactor`; a new skill → `skill-builder`; a new agent → `agent-builder`; vendoring or refreshing plugin-building guidance → `guidance`; feature or system documentation → `project-documentation`; an ADR → `architectural-decision-record`; a coding standard → `coding-standard`; a runbook → `runbook`. Never select `tdd` for a non-testable deliverable.
3. Include the nature → review map: code → `code-review`; a new skill or agent → reviewed against the plugin-building guidance; documentation → a content audit (`content-auditor` or `information-architect`); an ADR, runbook, or standard → `human read`; a vendoring or `guidance` step → `none`.
4. Include the han-skill interactivity enumeration used to derive the `Build unattended` and `Review unattended` signals (which skills and reviews run unattended vs stop for a human).
5. Include the non-han declaration-and-default rule: a user-defined skill's autonomy is declared by the operator and defaults to not-unattended when undeclared (`See plan: D-5`).
6. Include the not-installed fallback: record a bare item with `Implementation skill = none`, keep the recommended skill as a note on the item, and print an install recommendation at the end of the run (`See plan: D-4`).

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 2, 3, 4, 6) and [feature-specification.md#coordinations](feature-specification.md#coordinations) (the candidate build/review skills row).
- **Standards** — see Shared reference artifacts (skill-authoring guidance: decision matrices go in `references/`; reference-file placement).

**Tests.**
- Review: the catalog covers every deliverable nature named in the spec and resolves each named skill and review.
- Review: it holds all five tables/rules; all internal links resolve; no driver-side copy of the catalog exists (`See plan: D-2`).

**Acceptance criteria.**
- [ ] `deliverable-skill-catalog.md` exists under the producer's `references/` and holds the nature→skill map, the nature→review map, the interactivity enumeration, the non-han declaration/default rule, and the not-installed fallback.
- [ ] Step 5 of the producer loads it (realized in W-3); the driver holds no copy.

**Type.** `AFK`

**Expected paths.**
- `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`

**Depends on.** W-1.

## W-3 — Re-plumb producer `plan-work-items` Steps 5, 7, and 8

**Summary.** Change the producer skill's three judgment steps so it selects the implementation skill and review, derives and records the three autonomy signals (with overrides and installed-skill detection), prints them in the breakdown, and closes with a three-bucket recommendation (`See plan: D-9`). These steps interlock in one SKILL.md and are not split.

**Description.**
1. Edit `han-planning/skills/plan-work-items/SKILL.md`.
2. **Step 5** (the `han-core:project-manager` drafting brief): load `deliverable-skill-catalog.md`; classify each item's deliverable nature; select the implementation skill and review; derive the three signals from the catalog's interactivity enumeration; declare non-han autonomy, defaulting to not-unattended; apply operator overrides — a natural-language invocation instruction, or a recognizable single-line bracketed marker scanned read-only in the source plan, carrying a skill, an optional review, and an optional non-han autonomy declaration (`See plan: D-5`); and run installed-skill detection from the session's available-skills registry, naming each catalog skill's plugin origin so an uninstalled best-fit can be reported (`See plan: D-4`). Replace the old directive to classify items as `HITL`/`AFK` and record a `Type` field.
3. **Step 7** (the breakdown print): print the five fields, the derived fully-autonomous / needs-a-human label, a driver-ready / needs-a-hand marker, and the flags (low-confidence, non-han suggestions, not-installed notes, mismatch flags, override-resolution notes), replacing the `Type: HITL/AFK` line.
4. **Step 8** (the closing summary): replace the "count by type" summary and the "all-AFK" driver handoff with the three-bucket closing recommendation — driver-ready (`tdd` + `code-review`, named inline per `See plan: D-7`), run-the-skill-yourself, and needs-a-human.

**Note on scope boundary with W-4.** The producer's closing recommendation and the driver both encode the supported combination `tdd` + `code-review`; this is a documented editorial coupling, not a shared reference, so expanding the combination later means a coordinated edit at both sites (`See plan: D-7`).

**Note on frontmatter.** Leave the producer's `description` and `argument-hint` unchanged; advertising the override affordance there is deliberately deferred (`See plan: D-10`).

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 1, 5–7), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (all three), and [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (override and non-han rows).
- **Standards** — see Shared reference artifacts (keep the always-loaded Step 5 body lean; the catalog stays in the reference).

**Tests.**
- Producer four-item fixture spot-run: a testable-code item → `tdd` + `code-review`, fully-autonomous, driver-ready; a documentation item → `project-documentation` + `content-auditor`, fully-autonomous, run-the-skill-yourself; an absent-best-fit new-skill item (with `han-plugin-builder` not detected) → `Implementation skill = none`, bare, with an end-of-run install note; a `guidance` item → `guidance` with review `none`, fully-autonomous, run-the-skill-yourself.
- Producer override/non-han spot-run: a `tdd` + `human read` override recomputes the item to needs-a-human; a non-han skill is recorded not-unattended unless the operator declares it autonomous.
- Review: Steps 5/7/8 record and print the five fields, the derived label, the driver-ready/needs-a-hand marker, override resolution, non-han suggestions, and the three-bucket closing recommendation naming `tdd` + `code-review` inline.

**Acceptance criteria.**
- [ ] Step 5 selects skill and review, derives the three signals (han-derived, non-han declared/defaulted), applies overrides, and runs installed-skill detection against the catalog.
- [ ] Step 7 prints the five fields, the derived label, the driver-ready/needs-a-hand marker, and the flags.
- [ ] Step 8 emits the three-bucket closing recommendation and drops the "count by type" summary and "all-AFK" handoff.
- [ ] The four-item fixture and the override/non-han cases classify as described.

**Type.** `AFK`

**Expected paths.**
- `han-planning/skills/plan-work-items/SKILL.md`

**Depends on.** W-1, W-2.

## W-4 — Re-plumb driver `implement-work-items` Steps 1.7, 2.1, 3.x, and frontmatter

**Summary.** Change the driver skill so it computes autonomy from the recorded signals instead of reading `Type`, dispatches the recorded implementation skill and review per item, and refuses the whole run at startup with two distinct refusals plus a pre-feature-file refusal (`See plan: D-6`). Step 1.7 quotes the template's field names verbatim (`See plan: D-3`).

**Description.**
1. Edit `han-coding/skills/implement-work-items/SKILL.md`.
2. **Step 1.7** (currently the `**Expected paths.**` + `**Type.**` presence check and the "All AFK" check): make it three checks — (a) fields-present for the five new fields, quoting the template's field labels from W-1 verbatim (`See plan: D-3`); (b) all-fully-autonomous, computed from `Build unattended` / `Review unattended` / `Pre-work decision`; (c) supported-combination (`tdd` built, `code-review` reviewed). Surface two distinct startup refusals — needs-a-human vs unsupported-combination — plus a third pre-feature-file refusal when items still carry the old `Type` and omit the new fields, directing the operator to re-run `plan-work-items`.
3. **Step 2.1** (the plan preview): name each item by its recorded implementation skill and review, replacing the hardcoded `han-coding:tdd`.
4. **Steps 3.1 / 3.3 / 3.4** (build, review, fix rounds): read and dispatch the recorded implementation skill and review, in both the initial build and every fix round, preserving each dispatched skill's contract (for `tdd`, the observed test-failure-then-pass evidence). Remove the hardcoded `han-coding:tdd` / `han-coding:code-review`.
5. **Frontmatter:** change "AFK-typed" to "fully-autonomous" in the `description`, keeping the supported-combination language accurate and the description under 1024 characters (`See plan: D-6`).

**Note on scope boundary with W-2.** The driver deliberately does not read `deliverable-skill-catalog.md`; it reads the recorded signals plus its own supported combination (`See plan: D-2`).

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 8), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (pre-feature-`Type`, not-fully-autonomous, and unsupported-combination rows), and [feature-specification.md#coordinations](feature-specification.md#coordinations) (autonomous-driver row).
- **Standards** — see Shared reference artifacts (CONTRIBUTING voice; frontmatter under 1024 characters).

**Tests.**
- Driver spot-run B: a mixed file (one driver-ready item, one needs-a-human item) refuses the whole run at startup before branching, names the offending item, and leaves the repository untouched.
- Driver spot-run C: a pre-feature `Type` file refuses, names the missing fields, and gives the re-run remedy.
- Review: Step 1.7 performs the three checks with two distinct refusals plus the pre-feature refusal; Steps 2.1/3.1/3.3/3.4 dispatch the recorded skill and review in build and fix rounds, preserving the `tdd` contract; the frontmatter change is accuracy-only.
- *(Spot-run A and the side-by-side field-name review need the producer and template assembled; they run in W-8.)*

**Acceptance criteria.**
- [ ] Step 1.7 checks the five new fields (quoting the template labels verbatim), computes fully-autonomous from the signals, and surfaces needs-a-human, unsupported-combination, and pre-feature-file refusals as distinct messages.
- [ ] Steps 2.1/3.1/3.3/3.4 name and dispatch the recorded implementation skill and review in both build and fix rounds.
- [ ] The frontmatter `description` says "fully-autonomous" (not "AFK-typed") and stays under 1024 characters.
- [ ] Spot-runs B and C behave as described.

**Type.** `AFK`

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-1, W-3.

## W-5 — Accuracy edits to the two driver contract references

**Summary.** Update the opening sentences of the driver's two contract references so they read accurately alongside per-item dispatch, with no operative change to their required-return formats (`See plan: D-6`).

**Description.**
1. Edit the opening sentence of `han-coding/skills/implement-work-items/references/build-report-contract.md` (currently frames the driver as dispatching `han-coding:tdd`) so it reads accurately against the per-item dispatch introduced in W-4.
2. Edit the opening sentence of `han-coding/skills/implement-work-items/references/review-verdict-contract.md` (currently frames the driver as dispatching `han-coding:code-review`) the same way.
3. Make no operative change — the required-return-format blocks stay byte-for-byte unchanged, because the driver still drives only `tdd` + `code-review` (`See plan: D-6`).

**References.**
- **Spec section** — [feature-specification.md#coordinations](feature-specification.md#coordinations) (the `tdd`/`code-review` contracts are preserved) and [feature-specification.md#out-of-scope](feature-specification.md#out-of-scope) (no expansion beyond `tdd` + `code-review`).
- **Standards** — see Shared reference artifacts (CONTRIBUTING voice).

**Tests.**
- Review: both opening sentences read accurately against W-4's dispatch behavior; each contract's required-return-format block is unchanged.

**Acceptance criteria.**
- [ ] Both contract opening sentences are updated for accuracy only.
- [ ] Neither contract's required-return-format block is changed.

**Type.** `AFK`

**Expected paths.**
- `han-coding/skills/implement-work-items/references/build-report-contract.md`
- `han-coding/skills/implement-work-items/references/review-verdict-contract.md`

**Depends on.** None.

## W-6 — Update the `plan-work-items` long-form documentation

**Summary.** Bring the producer's canonical long-form doc up to date with the new schema and behavior, run through the repo's documentation-maintenance skill (`See plan: D-10`).

**Description.**
1. Update `docs/skills/han-planning/plan-work-items.md` through the `han-update-documentation` skill, scoped to this branch's producer changes.
2. Document the five per-item fields, the derived fully-autonomous / needs-a-human label, skill and review selection, overrides, installed-skill detection, non-han suggestions, the not-installed fallback, and the three-bucket closing recommendation.
3. Remove any stale `Type`/AFK-only language (`See plan: D-10`). Follow the long-form doc structure and the coverage rule.

**References.**
- **Standards** — see Shared reference artifacts (long-form doc template; CONTRIBUTING coverage rule, voice, PR checklist).
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (the behavior being documented).

**Tests.**
- Review (CONTRIBUTING PR checklist for this doc): no em-dashes, no voice violations, internal links resolve.
- Review: the doc reflects the new schema and behavior and is free of stale `Type`/AFK-only language.

**Acceptance criteria.**
- [ ] `docs/skills/han-planning/plan-work-items.md` documents the new fields, derived label, selection/override/detection behavior, and the three-bucket closing recommendation.
- [ ] No stale `Type`/AFK-only language remains; the PR checklist passes for this doc.

**Type.** `AFK`

**Expected paths.**
- `docs/skills/han-planning/plan-work-items.md`

**Depends on.** W-3.

## W-7 — Update the `implement-work-items` long-form documentation

**Summary.** Bring the driver's canonical long-form doc up to date with per-item dispatch and the signals-based refusals, run through the documentation-maintenance skill (`See plan: D-10`).

**Description.**
1. Update `docs/skills/han-coding/implement-work-items.md` through the `han-update-documentation` skill, scoped to this branch's driver changes.
2. Document per-item skill and review dispatch, the three startup checks with two distinct refusals plus the pre-feature refusal, and the fully-autonomous framing.
3. Explicitly remove the stale "build skill is `/tdd`, and only `/tdd`; per-item selection is deferred" note and the "AFK-typed" prerequisites (`See plan: D-10`).

**References.**
- **Standards** — see Shared reference artifacts (long-form doc template; CONTRIBUTING coverage rule, voice, PR checklist).
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 8) and [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes).

**Tests.**
- Review (CONTRIBUTING PR checklist for this doc): no em-dashes, no voice violations, internal links resolve.
- Review: the stale "`/tdd` only; per-item selection deferred" note and the "AFK-typed" prerequisites are gone; per-item dispatch and the refusals are documented.

**Acceptance criteria.**
- [ ] `docs/skills/han-coding/implement-work-items.md` documents per-item dispatch, the three checks/refusals, and the fully-autonomous framing.
- [ ] The stale "`/tdd` only / per-item selection deferred" note and "AFK-typed" prerequisites are removed; the PR checklist passes for this doc.

**Type.** `AFK`

**Expected paths.**
- `docs/skills/han-coding/implement-work-items.md`

**Depends on.** W-4, W-5.

## W-8 — Integration verification and atomic-merge gate

**Summary.** With every authoring item on the branch, run the cross-cutting checks that need the full assembly — the load-bearing field-name parity review, the assembled spot-run, and the consumer pass-through spot-read — then merge the single PR atomically in the `See plan: D-8` in-branch order.

**Description.**
1. **Driver spot-run A** across producer + driver + template: produce a `work-items.md` with `plan-work-items`, then drive it with `implement-work-items` and confirm the preview names each item's recorded implementation skill and review.
2. **Side-by-side field-name review** (load-bearing, `See plan: D-3`): confirm the template's five field labels (W-1) equal the driver's Step 1.7 verbatim strings (W-4), and that `Implementation skill` is the single field name with no alias. Nothing catches a drift at runtime, so this manual review carries the Definition of Done.
3. **Consumer spot-read:** confirm `work-items-to-issues` (`han-github`), `work-items-to-jira` (`han-atlassian`), and `work-items-to-linear` (`han-linear`) parse only the `## <W-N>` heading and the `**Depends on.**` line, so the five new fields pass through untouched. Read-only verification of those three skills — no edits.
4. **CONTRIBUTING PR checklist** over the whole PR: frontmatter under 1024 characters, no em-dashes, no voice violations, all internal links resolve.
5. **Atomic merge** of the single PR in the `See plan: D-8` in-branch order (template + catalog → producer → driver → docs).

**Note on scope boundary.** This item authors no file of its own; it is a verification-and-merge gate over the paths from W-1 through W-7, plus read-only checks of the three consumer skills.

**References.**
- **Standards** — see Shared reference artifacts (the CONTRIBUTING PR checklist is the release gate).
- **Spec section** — [feature-specification.md#coordinations](feature-specification.md#coordinations) (downstream consumer pass-through) and [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (the driver spot-run scenarios).

**Tests.**
- Spot-run A behaves as described; the field-name parity review confirms template ↔ driver agreement; the consumer spot-read confirms pass-through; the CONTRIBUTING PR checklist passes; the branch merges as one atomic PR in the `See plan: D-8` order.

**Acceptance criteria.**
- [ ] Spot-run A: the assembled producer + driver name each item's skill and review in the preview.
- [ ] The side-by-side review confirms the template field names equal the driver's Step 1.7 strings; `Implementation skill` is the single name.
- [ ] The consumer spot-read confirms `work-items-to-issues`/`-jira`/`-linear` pass the schema change through untouched.
- [ ] The CONTRIBUTING PR checklist passes over the whole PR.
- [ ] All changes land in one atomic merge in the `See plan: D-8` in-branch order.

**Type.** `HITL`

**Expected paths.**
- None. Verification-and-merge gate over the files created or modified by W-1 through W-7; read-only verification of `han-github/skills/work-items-to-issues/`, `han-atlassian/skills/work-items-to-jira/`, and `han-linear/skills/work-items-to-linear/`.

**Depends on.** W-1, W-2, W-3, W-4, W-5, W-6, W-7.
