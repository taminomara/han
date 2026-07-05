# Work Items — Non-code, meta, and non-deliverable work items

These work items break down the implementation plan [feature-implementation-plan.md](feature-implementation-plan.md), which extends the producer `plan-work-items` and the driver `implement-work-items` so a plan whose deliverables are non-code, meta, or non-deliverable classifies and drives end to end with the no-output relaxations guarded. This is a markdown skill-authoring change with no application code and no automated test harness; verification is read-the-file contract checks plus manual dry-runs.

Classifications use **today's** `deliverable-skill-catalog.md` — the verification, spike, and edit-existing rows this feature adds do not exist yet — which is why three of the four items are low-confidence catalog misfits driven as foreground human work. Plan decisions are restated inline with a plain-text `See plan: D-N` breadcrumb (the plan's decision IDs and Work Units); the decision log and other `artifacts/` process files are deliberately never linked.

> Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

## Shared reference artifacts

These artifacts span more than one work item. Each work item's own `**References.**` block points into the relevant section.

- **Behavioral ground truth** — [feature-specification.md](feature-specification.md): [Primary Flow](feature-specification.md#primary-flow), [Startup Validation and Refusals](feature-specification.md#startup-validation-and-refusals), [Alternate Flows and States](feature-specification.md#alternate-flows-and-states) (agent-drafted non-code build, editing an existing definition, verification pass, spike), [Edge Cases and Failure Modes](feature-specification.md#edge-cases-and-failure-modes), [Coordinations](feature-specification.md#coordinations), [Outcome](feature-specification.md#outcome).
- **Editing skill definitions correctly** — the plugin-authoring guidance at `han-plugin-builder/skills/guidance/references/skill-building-guidance/` (in particular `progressive-disclosure.md`, `skill-reference-files.md`, `writing-effective-instructions.md`, `context-hygiene.md`).
- **Docs voice and coverage** — [docs/writing-voice.md](../../writing-voice.md) (no em-dashes; banned words `leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`); [CONTRIBUTING.md](../../../CONTRIBUTING.md) (the long-form-doc coverage rule).

## W-1 — Generalize the two build and review contracts in place

**Summary.** Generalize `build-report-contract.md` and `human-review-capture.md` so they accept the shapes the extended driver will later route: a skill-less general-purpose build (no skill-gate claim), a declared-no-output build (empty FILES is the expected success), and a no-output human-review branch that confirms a result rather than pointing at an absent change. These generalizations are backward-compatible and inert until the driver body uses them, so this item commits first, ahead of the atomic change. See plan: D-5, Work Unit 1.

**Description.**
1. In `han-coding/skills/implement-work-items/references/build-report-contract.md`, make the empty-FILES halt conditional: it still fires for a declared-output item, but a declared-no-output build may report `built` with an empty FILES set.
2. In the same contract, add a skill-less build shape: a general-purpose build reports without a skill-gate claim (it runs no skill) and declares itself untestable rather than carrying test evidence.
3. In `han-coding/skills/implement-work-items/references/human-review-capture.md`, add a no-output review branch that confirms the result (and, if a no-output item unexpectedly left files, surfaces them as a scope finding) instead of pointing the reviewer at a change; the coverage attestation is "operator confirmed result".
4. Preserve every existing declared-output path unchanged so the current fully-autonomous deliverable flow is untouched.

**Note on classification.** Today's catalog has no clean unattended home for editing an executable plugin reference contract — the "Other work related to Claude Code plugins" row names `han-plugin-builder:guidance`, which serves authoring rules and cannot edit files, and a broken edit ships green because there is no test harness. This item is therefore a foreground human edit with a human read. Once this feature ships, it would reclassify to a `` `general-purpose` agent, AFK `` build with a human read (the feature's own value), but that path is not safe under today's driver.

**References.**
- **Spec** — [Coordinations](feature-specification.md#coordinations) (the Driver→build-report/review-verdict contracts row: skill-less build, no-output build, no-output review), [Alternate Flows and States](feature-specification.md#alternate-flows-and-states) (agent-drafted non-code build → skill-less shape; verification pass → no-output), [Edge Cases and Failure Modes](feature-specification.md#edge-cases-and-failure-modes) (a no-output item that unexpectedly leaves files).
- **Authoring guidance** — `han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-reference-files.md`, `writing-effective-instructions.md`.

**Tests.**
- C-6: `build-report-contract.md` expresses the skill-less shape and the no-output carve-out (empty FILES valid only for a declared-`Expected paths: None` build; the halt still fires for a declared-output build).
- C-9: `human-review-capture.md` has a no-output branch with the "operator confirmed result" attestation, distinct from the diff-review branch.
- A-2 (run in W-4) must confirm the declared-output regression path is unchanged.

**Acceptance criteria.**
- [ ] The empty-FILES halt still fires for a declared-output build and no longer fires for a declared-no-output build.
- [ ] The build-report contract expresses a skill-less general-purpose build with no skill-gate claim and an untestable declaration.
- [ ] The human-review capture has a no-output branch that confirms a result and flags stray files as a scope finding.
- [ ] No existing declared-output build or review path changed behavior (backward-compatible).
- [ ] No new writing-voice violations introduced (the full pass runs in W-3).

**Requires pre-work decisions.** No.

**Suggested implementation.** `none`, HITL.

**Suggested review.** `none`, HITL.

**Expected paths.**
- `han-coding/skills/implement-work-items/references/build-report-contract.md`
- `han-coding/skills/implement-work-items/references/human-review-capture.md`

**Depends on.** None.

## W-2 — Atomic driver and producer change

**Summary.** Land, as a single atomic commit, the new no-output-mechanics reference file, the driver `SKILL.md` edits, the producer catalog edits, and the template edits. The producer emits marker vocabulary the driver validates, so a commit where one side's vocabulary changed and the other did not silently drops items — these units cannot be separate driver-committed work items. See plan: D-1, D-3, D-4, D-6, D-7, D-8, D-9, D-10, D-11, D-15, Work Units 2, 3, and 4.

**Description.**
1. Create `han-coding/skills/implement-work-items/references/no-output-completion.md` holding the multi-step no-output mechanics: the clean-tree assertion at completion, the no-commit recording, and the completion/halt summary labeling that Step 3.4, Step 4, and the Halt Procedure point to (the compaction split — See plan: D-1).
2. `SKILL.md` Step 1.7: parse `Type` (missing defaults silently to `deliverable`); add the four refusals checked in sub-order with one refusal reported per halted item — (a) `` `none`, AFK `` build, inside the "Drivable" bullet; (b) `Type` outside `deliverable`/`verification`/`spike`; (c) `Expected paths: None` on a non-`verification` item; (d) `AFK` review on a `verification` item or any `Expected paths: None` item. Carve `general-purpose` out of the drivability check as a built-in, always-available agent so an agent-drafted build is never a not-installed halt. See plan: D-1, D-3, D-7.
3. `SKILL.md` Step 3.3: carry the item's Expected path into the spike build dispatch as the finding target; add the no-output build and review routing — an agent-drafted skill-less build, a no-output verification build dispatched knowing zero files is the expected result, and a spike review that is a `` none, HITL `` human soundness read independent of the build marker. See plan: D-11, D-12.
4. `SKILL.md` Step 3.4: add the no-output branch — a `verification` item that declared `Expected paths: None` and produced no diff since `scope-baseline` skips the commit and records `done-no-commit`, with a primary clean-tree assertion at its own completion and a Step 3.1 backstop assertion before the `scope-baseline` snapshot. See plan: D-8, D-10.
5. `SKILL.md` `state.json` schema: add the distinct terminal state value `done-no-commit`; branch Step 4, the Halt Procedure, and the in-session re-grounding on it. See plan: D-8.
6. `SKILL.md` Step 4 and Halt Procedure: name no-commit completions as their own outcome bucket (item, `Type`, `Expected paths: None`, count); the Halt trace names them distinctly (no commit, not in the cherry-pick range). See plan: D-8.
7. `deliverable-skill-catalog.md`: add the edit-existing-plugin-definition row, the verification row (with the authored side-effect-free idempotency constraint line), and the spike row before the catch-all; reframe the "Other work related to Claude Code plugins" row from `` `han-plugin-builder:guidance`, AFK `` to `` `general-purpose` agent, AFK ``; add the `general-purpose`-exempt parenthetical to the never-auto-`AFK` guardrail; add the decline-the-field refusal rule to the Overrides note. See plan: D-4, D-9, D-14.
8. `work-item-template.md`: add `Type` as the first routing field before `Requires pre-work decisions`; rename `Tests` to a type-aware `Verification` field in place (carrying the idempotency guidance for a no-output verification); narrow the `Requires pre-work decisions` trigger to the ordered ladder (record-worthy → an ADR the dependent item depends on; needs investigation → a spike; single-sentence judgment → the inline flag). See plan: D-6, D-9.
9. Measure the post-edit `SKILL.md` body against the ~5k post-compaction cap; if over, push more mechanics to the reference file (the short refusal rules stay inline). See plan: D-1.
10. Commit steps 1 through 8 as one commit; confirm `allowed-tools` is unchanged (no `Skill`, no `AskUserQuestion`).

**Note on atomic co-land.** This item is deliberately thick because plan decision D-15 requires the driver `SKILL.md`, the new reference file, the producer catalog, and the template to land as one atomic commit: the producer emits markers the driver validates, so a half-landed vocabulary silently drops items. The driver commits per work item, so these units cannot be split into separate committing items. Do not decompose this further.

**Note on classification.** Editing these executable plugin definitions (the driver body, the catalog, the template) has no clean unattended home in today's catalog, a broken edit ships green with no test harness, and the cross-file vocabulary reconciliation itself wants a human driving it. It is therefore a foreground human edit with a human read. Once this feature ships, an edit like this reclassifies to a `` `general-purpose` agent, AFK `` build with a human read, but that path is not safe under today's driver.

**References.**
- **Spec** — [Startup Validation and Refusals](feature-specification.md#startup-validation-and-refusals) (the four refusals and the two-point enforcement), [Alternate Flows and States](feature-specification.md#alternate-flows-and-states) (all four subsections), [Edge Cases and Failure Modes](feature-specification.md#edge-cases-and-failure-modes) (the full table), [Primary Flow](feature-specification.md#primary-flow), [Coordinations](feature-specification.md#coordinations) (producer→driver marker vocabulary; producer→agents general-purpose availability; driver→contracts).
- **Prerequisite** — the generalized `build-report-contract.md` and `human-review-capture.md` from W-1.
- **Authoring guidance** — `han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md`, `skill-reference-files.md`, `context-hygiene.md`, `writing-effective-instructions.md`.

**Tests.**
- C-1 through C-5: Step 1.7 refusal placement and sub-order; `Type` parsing and backward compatibility; `Expected paths: None` gating; the `AFK`-review and `none, AFK` refusals; the `general-purpose` drivability exemption.
- C-7: the Step 3.4 no-output branch and the clean-tree assertion at completion.
- C-8: `state.json` `done-no-commit`, the Step 4 no-commit bucket, the Halt trace.
- C-10: catalog rows, reframe, exempt note, Overrides refusal rule.
- C-11: template `Type` field, `Verification` rename, pre-work-decisions narrowing.
- C-12: the spike Expected-path dispatch and the `` none, HITL `` spike review.
- Dry-runs A-1 through A-12 (run in W-4): backward-compat old file; deliverable regression; the refusal set A-3..A-7; no-output clean no-commit A-8; stray-files scope finding A-9; general-purpose skill-less report A-10; producer declines a refused override A-11; human-review no-output branch A-12.

**Acceptance criteria.**
- [ ] The four refusals fire singly and compound in the correct sub-order before any mutation; a compound case reports one offender per halted item.
- [ ] A missing `Type` defaults to `deliverable` and drives an old file identically; `Verification` (renamed from `Tests`) is not driver-parsed.
- [ ] `general-purpose` is exempt from the drivability not-installed halt.
- [ ] A no-output `verification` completes as `done-no-commit` with a labeled outcome bucket and a clean-tree assertion at completion; stray files surface as a scope finding.
- [ ] The spike build dispatch carries the Expected path as the finding target; the spike review is `` none, HITL `` regardless of the build marker.
- [ ] The catalog gains three rows, the reframe, the exempt parenthetical, the idempotency line, and the Overrides refusal rule; the producer declines a refused override and restores the catalog base without transforming `Type`.
- [ ] The template puts `Type` first, renames `Tests` to `Verification`, and narrows the pre-work-decisions trigger to the ordered ladder.
- [ ] All of the above land in one commit; the post-edit `SKILL.md` body measures against ~5k and is split further if over; `allowed-tools` is unchanged.

**Requires pre-work decisions.** No.

**Suggested implementation.** `none`, HITL.

**Suggested review.** `none`, HITL.

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`
- `han-coding/skills/implement-work-items/references/no-output-completion.md`
- `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`
- `han-planning/skills/plan-work-items/references/work-item-template.md`

**Depends on.** W-1.

## W-3 — Long-form docs update and writing-voice pass

**Summary.** Update the two canonical long-form docs to reflect the extended behavior, and run a writing-voice pass across every file edited in W-1 and W-2. This is the one unattended item: an agent drafts the doc edits from the shipped behavior and `content-auditor` reviews them unattended. See plan: D-15 (coverage requirement), Definition of Done (docs and voice), Work Unit 5.

**Description.**
1. Update `docs/skills/han-coding/implement-work-items.md` to document the four Step 1.7 refusals, the no-output branch and `done-no-commit` terminal state, the no-commit outcome bucket, the spike Expected-path dispatch, and the `` none, HITL `` spike-soundness review.
2. Update `docs/skills/han-planning/plan-work-items.md` to document the three new catalog homes, the reframed catch-all, the `Type`-first template field, the `Tests`→`Verification` rename, the idempotency constraint, and the pre-work-decisions narrowing.
3. Run a writing-voice pass across every file edited in W-1 and W-2 as well (the two contracts, the new reference file, the driver `SKILL.md`, the catalog, the template): no em-dashes; no banned words (`leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`).
4. Verify both long-form docs satisfy the CONTRIBUTING coverage rule (every skill has a long-form doc and an index entry; the first Related Documentation bullet points to the repo README).

**Note on scope boundary with W-1 and W-2.** The voice pass in step 3 touches the skill, contract, catalog, and template files that W-1 and W-2 already committed; those are edited in place here for voice only, so any change stays confined to prose. The `Expected paths` below list only the two doc files this item creates content in.

**References.**
- **Standards** — [docs/writing-voice.md](../../writing-voice.md) (voice profile and banned words), [CONTRIBUTING.md](../../../CONTRIBUTING.md) (the long-form-doc coverage rule).
- **Spec** — [Outcome](feature-specification.md#outcome), [Alternate Flows and States](feature-specification.md#alternate-flows-and-states), [Startup Validation and Refusals](feature-specification.md#startup-validation-and-refusals) (the behavior to describe).
- The files edited in W-1 and W-2 are the source of truth for what the docs must now say.

**Tests.**
- CONTRIBUTING coverage rule satisfied for both long-form docs.
- Writing-voice pass clean across all edited files (no em-dashes, no banned words). Confirmed in W-4's Definition-of-Done checklist.

**Acceptance criteria.**
- [ ] Both long-form docs describe the shipped behavior accurately and completely (refusals, no-output and `done-no-commit`, spike dispatch and review, catalog homes, template `Type`/`Verification`/pre-work-decisions).
- [ ] The writing-voice pass is clean across all files edited in W-1, W-2, and W-3.
- [ ] Both docs meet the CONTRIBUTING coverage rule and link up to the README.

**Requires pre-work decisions.** No.

**Suggested implementation.** `han-core:project-documentation`, AFK.

**Suggested review.** `han-core:content-auditor` agent, AFK.

**Expected paths.**
- `docs/skills/han-coding/implement-work-items.md`
- `docs/skills/han-planning/plan-work-items.md`

**Depends on.** W-1, W-2.

## W-4 — Verification pass

**Summary.** Run the C-1 through C-12 read-the-file contract checks, the A-1 through A-12 dry-runs, and the PD-1 (idempotency) and PD-2 (spike-gate) proving runs as a foreground human gate that certifies the whole change against the plan's Definition of Done. Under today's driver there is no `verification` `Type`, so this is a human-run checklist, not a committing driver item. See plan: D-13, OI-1, OI-2, Work Unit 6.

**Description.**
1. Run C-1 through C-12 read-the-file contract checks against the edited `SKILL.md`, both contracts, the new reference file, the catalog, and the template.
2. Script and run A-1 through A-12 dry-runs against scratch work-items files: backward-compat old file (A-1); fully-autonomous deliverable regression (A-2); the refusal set singly and compound (A-3..A-7); no-output clean no-commit (A-8); stray-files scope finding (A-9); general-purpose skill-less report (A-10); producer declines a refused override (A-11); human-review no-output branch (A-12).
3. Run PD-1 (idempotency): a no-output verification completes `done-no-commit` on branch A, then re-executes safely on a fresh branch B after a later-item halt, producing no artifact outside the gitignored `.implement-work-items/`. See plan: D-9, D-13.
4. Run PD-2 (spike-gate): an interactive-skill spike dispatched into each of the four gates (mis-route, too-vague clarify, compound multi-thread, re-run overwrite) either halts before any commit, or commits a finding and the `` none, HITL `` review fires before any dependent item consumes it. See plan: D-12, D-13.
5. Confirm the body-size gate: the post-edit `SKILL.md` body measures against ~5k, with the split applied further if over.
6. Record OI-2's outcome: if PD-2 shows a committed spike finding that bypasses the `` none, HITL `` review, escalate to the spec owner rather than plan around it. Note that OI-1 (the hand-edited AFK-spike-review residual) stays open and non-blocking.

**Note on classification.** No `verification` `Type` exists in today's model, so this is a foreground human gate rather than a committing driver item: the operator runs the checks (build `none, HITL`) and the checks are the verification (review `none`). Its `Expected paths` are `None` — exactly the no-output pattern this feature introduces and guards; under today's driver that pattern would be a refusal, so this item is run as a foreground checklist, not driven. Once this feature ships, it would classify as a `verification` item with `Expected paths: None` driving to `done-no-commit`.

**References.**
- **Spec** — [Startup Validation and Refusals](feature-specification.md#startup-validation-and-refusals) (predicts A-3..A-7), [Edge Cases and Failure Modes](feature-specification.md#edge-cases-and-failure-modes) (predicts A-1, A-8, A-9, A-11), [Alternate Flows and States](feature-specification.md#alternate-flows-and-states) (the spike flow → PD-2 gates), [Outcome](feature-specification.md#outcome) (the end-to-end behavior being certified).

**Tests.** The full suite is the item: C-1 through C-12, A-1 through A-12, PD-1, PD-2, and the body-size gate. There is no separate review stage — the checks are the verification.

**Acceptance criteria.**
- [ ] C-1 through C-12 all pass.
- [ ] A-1 through A-12 all pass, including the regression pair (A-1 old file, A-2 fully-autonomous deliverable) driving unchanged with the still-applicable Step 1.7 refusals firing.
- [ ] PD-1 shows the no-output verification re-executes safely on a fresh branch with no artifact outside `.implement-work-items/`.
- [ ] PD-2 shows the `` none, HITL `` spike review fires before any dependent item in every committed-finding path, with no gate bypass (OI-2 resolved or escalated).
- [ ] The `SKILL.md` body measures against ~5k; `allowed-tools` is confirmed unchanged.

**Requires pre-work decisions.** No.

**Suggested implementation.** `none`, HITL.

**Suggested review.** `none`.

**Expected paths.**
- None (verification only).

**Depends on.** W-1, W-2, W-3.
