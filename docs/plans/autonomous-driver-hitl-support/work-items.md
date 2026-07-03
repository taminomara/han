# Work Items — Autonomous Driver HITL Support

These work items break down [feature-implementation-plan.md](feature-implementation-plan.md) (the plan for teaching the `implement-work-items` driver to drive needs-a-human items and gate every review through one normalized verdict). This is a markdown skill-authoring change: there is no test harness, so verification is read-the-file contract checks and manual dry-runs against the contracts.

> Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

## Shared reference artifacts

These apply to more than one work item. Each work item's own `**References.**` block points into the relevant entries.

- **Feature specification** — [feature-specification.md](feature-specification.md). The behavioral ground truth for every item.
- **Normalized verdict mechanic (T1)** — [feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping](artifacts/feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping). The committed severity mapping, per-source coverage, location rule, and reference-material requirement. Applies to W-1 and W-4.
- **Skill Composition guidance** — [skill-composition.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-composition.md). Why the foreground build is an operator hand-off, not a `Skill` call. Applies to W-2 and W-4.
- **Context Hygiene guidance** — [context-hygiene.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/context-hygiene.md). The post-compaction budget that forces new detail into reference files. Applies to W-1, W-2, W-4.
- **Agent Dispatch Namespacing guidance** — [agent-dispatch-namespacing.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/agent-dispatch-namespacing.md). Qualify `han-coding:code-review`, `han-core:content-auditor`, `han-core:information-architect`; skill-vs-agent dispatch shape. Applies to W-1, W-2, W-4.
- **Workflow Patterns + AskUserQuestion guidance** — [workflow-patterns.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/workflow-patterns.md), [allowed-tools-AskUserQuestion.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/allowed-tools-AskUserQuestion.md). Human-gate placement; `AskUserQuestion` must not be added to `allowed-tools`. Applies to W-3 and W-4.
- **Authoring conventions** — [CONTRIBUTING.md](../../../CONTRIBUTING.md), [writing-voice.md](../../../docs/writing-voice.md). The coverage rule and the no-em-dash / no-banned-words voice profile every edited file must pass. Applies to W-5 and the voice pass across all items.

## W-1 — Generalize the review-verdict contract

**Summary.** Rewrite `review-verdict-contract.md` so the single normalized verdict the driver already parses fail-closed for `code-review` is generalized to cover any review source (`code-review`, `information-architect`, `content-auditor`, a human read), carrying the T1 per-source severity mapping, per-source coverage attestation, code-or-document location rule, and reference-material requirement as data. The `code-review` path must read identically to today so the shipped core loop is unaffected. See plan: WU-1, [D-2](feature-implementation-plan.md#implementation-approach); spec D5; T1.

**Description.**
1. Restate the verdict shape generically off the code-review panel: recommendation line, per-source coverage attestation, findings at or above the gate threshold (each with tier, location, one-line claim), below-threshold counts, durable-record path.
2. Add the per-source severity mapping as data for all four sources per T1: `code-review` identity (YAGNI non-gating, `SEC-###` gate by own tier); `information-architect` (Blocks comprehension → Critical, Degrades → Warning, Friction → Suggestion, Polish → below-threshold); `content-auditor` (each Missing fact → Warning, no Critical escalation, Present / Correctly Removed not findings); human read (operator states tier directly, confirmed against the threshold).
3. Generalize the coverage attestation off the panel shape: a single agent attests it ran to completion; a human read attests the operator reviewed the change. The attestation-missing halt fires only on an absent attestation, not on missing panel-specific language.
4. Add the location rule: `file:line` for code, a document anchor (section/heading or "document-wide") for prose.
5. Add the reference-material requirement: the item and referenced spec sections for every source; the prior document version additionally for a content audit.
6. Keep the file within the context-hygiene budget: this file is the home for the T1 data so the driver body stays lean.

**References.**
- **Spec section** — [feature-specification.md#coordinations](feature-specification.md#coordinations) (Review sources), [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 3.4), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (unmappable-verdict rows).
- **Technical note** — T1 (see Shared reference artifacts).
- **Standard / repo doc** — Context Hygiene and Agent Dispatch Namespacing guidance (see Shared reference artifacts).

**Tests.**
- C1 (read-the-file): the one normalized verdict shape is defined, generalized off the panel.
- C2 (read-the-file): the severity mapping is present as data for all four sources, matching T1.
- C4 (read-the-file): the location rule and generalized per-source coverage attestation are present, so a single-agent or human review does not trip the panel-shaped halt.

**Acceptance criteria.**
- [ ] C1 passes: one normalized verdict shape defined generically.
- [ ] C2 passes: severity mapping present for `code-review`, `information-architect`, `content-auditor`, and a human read, matching T1.
- [ ] C4 passes: location rule and generalized per-source coverage attestation present.
- [ ] The `code-review` reading is unchanged (backward-compatible; the A1 regression confirms at W-6).
- [ ] No em-dashes, no banned words (`leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`).

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `none, HITL` (low-confidence: a skill-reference contract, not testable code; hand-edit guided by the plan and the Context Hygiene and Agent Dispatch Namespacing guidance).

**Suggested review.** `manual read, HITL` (verify against C1, C2, C4).

**Expected paths.**
- `han-coding/skills/implement-work-items/references/review-verdict-contract.md`.

**Depends on.** None.

## W-2 — Add the two protocol reference files

**Summary.** Create the two new, not-yet-wired reference files the atomic driver edit will point at: `foreground-handoff-protocol.md` (the operator hand-off, `none` free-form build, confirm-done, state catch-up, adopt-own-commits inspection, bounded unfinished-foreground prompt, foreground pause markers) and `human-review-capture.md` (capture into the normalized verdict, ask-missing-field, echo-back-with-threshold, confirm-finality, per-round overwrite, review pause markers). They land as a standalone commit before the SKILL.md edit relies on them. See plan: WU-2, [D-3](feature-implementation-plan.md#implementation-approach); spec D7, D8, D14.

**Description.**
1. Author `foreground-handoff-protocol.md`: the voiced hand-off ("you are steering; tell me when the build is done and I will verify it"), the manual-compaction recommendation before a foreground build, the `none` free-form build, confirm-done, marking control returned, in-session state catch-up, the adopt-own-commits cumulative-diff inspection, the bounded unfinished-foreground prompt (re-foreground or halt; no skip/defer), and the "you are steering" / "control returned" foreground pause markers.
2. Author `human-review-capture.md`: point the operator at the change and referenced spec sections; capture each finding (tier, location, one-line claim) into the normalized verdict; ask-missing-field rather than guess; echo captured findings back with each tier and whether it gates at the active threshold; restate the threshold; confirm-finality ("this closes review for this item"); always write a durable record ("none at or above the gate threshold" when clean); per-round overwrite so a retracted finding is not re-chased; review pause markers. The verdict shape it captures into references the generalized contract from W-1.
3. Keep both files within the context-hygiene budget; they exist to keep this detail out of the driver body.

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 3.2, 3.4), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (foreground build, human read), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (unchanged-tree, cap-on-foreground rows).
- **Standard / repo doc** — Skill Composition, Context Hygiene, Agent Dispatch Namespacing guidance (see Shared reference artifacts).

**Tests.**
- C3 (read-the-file): the dispatch/protocol content the parameterized dispatch and capture rely on is present.
- C4 (read-the-file): location/coverage generalization is consistent with the capture.
- A5 (dry-run): a human-read exercises `human-review-capture.md`.

**Acceptance criteria.**
- [ ] `foreground-handoff-protocol.md` exists and covers hand-off, `none` build, confirm-done, state catch-up, adopt-own-commits, the bounded unfinished-foreground prompt, and the foreground markers.
- [ ] `human-review-capture.md` exists and covers capture, ask-missing-field, echo-back-with-threshold, confirm-finality, per-round overwrite, review markers, and captures into the W-1 verdict shape.
- [ ] C3/C4 reading confirms the protocol content is consistent with the generalized contract.
- [ ] A5 dry-run of a human read passes against `human-review-capture.md`.
- [ ] No em-dashes, no banned words.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `none, HITL` (low-confidence: new skill-reference files, not testable code; hand-edit guided by the Skill Composition, Context Hygiene, and Agent Dispatch Namespacing guidance).

**Suggested review.** `manual read, HITL` (verify against C3/C4 reading and A5).

**Expected paths.**
- `han-coding/skills/implement-work-items/references/foreground-handoff-protocol.md`.
- `han-coding/skills/implement-work-items/references/human-review-capture.md`.

**Depends on.** W-1 (the capture references the normalized verdict).

## W-3 — Prove the opt-in-pause mechanism

**Summary.** Before the SKILL.md wiring relies on it, prove whether the driver can detect a pending "pause after this review" message the operator queued during a synchronous review sub-agent run (a no-yield read after the sub-agent returns), and record either the resolved detection approach or the documented standing/pre-item opt-in fallback in `human-review-capture.md`. This closes RAID risk R2 as a Definition-of-Done gate. See plan: WU-3, [D-8](feature-implementation-plan.md#implementation-approach); spec D8, F25.

**Description.**
1. Run the A7b proving dry-run: the operator sends a pause-after-review message while an unattended review runs; check whether the driver reliably detects the pending request after the sub-agent returns and merges the operator's findings with the agent's into the one normalized verdict.
2. If the no-yield read is reliable, record the working detection approach in `human-review-capture.md` (opt-in-pause merge sub-section).
3. If it is unreliable, record the documented standing/pre-item opt-in fallback instead (operator declares the pause intent before the review starts), so the W-4 wiring references a mechanism that works on the platform.
4. Confirm A7a is preserved: with no pending request, the run proceeds straight to the gate without pausing (walk-away behavior intact).

**References.**
- **Spec section** — [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (the operator opts in to a review pause), [feature-specification.md#user-interactions](feature-specification.md#user-interactions) (opt-in feedback).
- **Standard / repo doc** — Workflow Patterns + AskUserQuestion guidance (see Shared reference artifacts).

**Tests.**
- A7b (proving dry-run, Definition-of-Done gate).
- A7a (regression: an unattended review with no pending request does not pause).

**Acceptance criteria.**
- [ ] A7b run executed; the result (detection works, or fallback adopted) is recorded in `human-review-capture.md`.
- [ ] The recorded mechanism is one the W-4 SKILL.md wiring can reference without further platform assumptions.
- [ ] A7a confirms an unattended review with no pending request does not pause.
- [ ] No em-dashes, no banned words in the recorded section.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `none, HITL` (low-confidence: a proving dry-run plus a reference-file edit, not testable code; consult the Workflow Patterns and AskUserQuestion guidance).

**Suggested review.** `manual read, HITL` (verify the A7b result and the recorded mechanism/fallback).

**Expected paths.**
- `han-coding/skills/implement-work-items/references/human-review-capture.md` (opt-in-pause section).

**Depends on.** W-2.

## W-4 — Atomic driver, contract, and catalog edit (one commit)

**Summary.** The load-bearing atomic change: the driver `SKILL.md`, its `build-report-contract.md` cleanup, and the producer `deliverable-skill-catalog.md` correction land as **one commit** so the driver, its contracts, and the producer catalog are never mutually inconsistent. This edits Step 1.7 (loosen refusals plus the drivability check), Step 3 (HITL phase routing), the work-state schema, the phase-name vocabulary, the `description` frontmatter, the completion summary, and folds the decide-gate and signposting inline. See plan: WU-4 + WU-5 + WU-6 merged under [D-9](feature-implementation-plan.md#decomposition-and-sequencing); also D-1, D-4, D-5, D-6, D-7, D-11, D-12, D-13; spec D2, D3, D4, D6, D7, D9, D10, D11, D14, D15.

**Description.**
1. **Step 1.7 loosening plus drivability check (SKILL.md):** stop refusing an item because its build/review needs a human, its combination is not `tdd` + `code-review`, or it requires a pre-work decision. Replace those refusals with a drivability check that resolves each named implementation skill to an installed plugin's `skills/<name>/SKILL.md` or agent `.md` (via Glob/find), aborting the whole run at startup and naming offenders on an unresolvable named skill; a bare `none` does not abort. Keep the still-applicable refusals (empty file, missing fields, malformed graph, prior-run branch, red suite).
2. **Step 3 routing (SKILL.md):** route each phase by the recorded markers. Decide (pause before build when `Requires pre-work decisions` is `yes`; record where the item directs or ask when silent; commit the durable edit; set `scope-baseline` after that commit; carry the decision into build; a distinct halt frame stating no build started on a rejected pre-decision commit). Build (`AFK` dispatch as today / `HITL` foreground hand-off / `none` free-form, per `foreground-handoff-protocol.md`). Verify (unconditional and independent; build-report parse only for a sub-agent return). Review (`AFK` dispatch through the generalized contract / `HITL` human read per `human-review-capture.md` / `none` no gate; opt-in pause checked after the sub-agent returns per W-3). Fix (re-enter at build by signal, never re-decide; re-review by signal; `none`-review clears on verify alone, stated at both sites; `fix-round` bounds the loop across state catch-up). Commit (dirty stages by path; clean-with-new-commits adopts the range after a cumulative-diff inspection).
3. **Work-state fields (SKILL.md):** add `scope-baseline` (set at item start, or after the pre-work-decision commit) and `fix-round` (per-item counter, persisted; neither reset on a fix round).
4. **Phase names (SKILL.md):** add `awaiting-decision`, `building-in-foreground`, `awaiting-review-feedback` to the work-state vocabulary alongside the existing statuses.
5. **`description` frontmatter (SKILL.md):** reword off "fully-autonomous". Keep `allowed-tools` unchanged (no `Skill`, no `AskUserQuestion`).
6. **Completion summary plus signposting (SKILL.md):** name each item's execution mode alongside its outcome; add the plan-preview execution-mode marks (unattended / decision-then-unattended / foreground build / human review), the once-only no-mid-run-stop disclosure, and the inline decide-gate as the Step 3 decide sub-step.
7. **Cleanup — `build-report-contract.md`:** generalize the intro off `tdd`, correct the `AFK`-build framing, remove the drivable-run parentheticals so the touched files stay internally consistent.
8. **Catalog correction — `deliverable-skill-catalog.md`:** change the three `guidance`-as-review rows (new skill, new agent, other plugin work) to `manual read, HITL`; documentation stays `content-auditor` / `information-architect`.

**Note on atomicity.** These three files land as one commit. Splitting them violates plan D-9 and risks the driver, its contracts, and the producer catalog being mutually inconsistent.

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes), [feature-specification.md#user-interactions](feature-specification.md#user-interactions), [feature-specification.md#coordinations](feature-specification.md#coordinations).
- **Technical note** — T1 (review dispatch; see Shared reference artifacts).
- **Standard / repo doc** — Skill Composition (foreground hand-off), Context Hygiene (SKILL.md budget), Agent Dispatch Namespacing (verdict dispatch), Workflow Patterns + AskUserQuestion (gate/pause) guidance (see Shared reference artifacts).

**Tests.**
- C5, C6, C7, C8 (read-the-file): Step 1.7 refusals replaced by the drivability check; Step 3 routes each phase by marker; work-state has `scope-baseline` + `fix-round`, fix loop re-enters at build by signal, re-reviews by signal, never re-decides, none-review clear-on-verify at both sites; commit-step branch, three catalog rows changed, `allowed-tools` unchanged, `description` reworded, `build-report-contract.md` generalized off `tdd`, no em-dashes / banned words.
- A1-A10 (dry-run): all execution modes (confirmed at W-6).

**Acceptance criteria.**
- [ ] SKILL.md, `build-report-contract.md`, and `deliverable-skill-catalog.md` land as **one atomic commit**.
- [ ] C5, C6, C7, C8 pass.
- [ ] A1-A10 dry-runs pass (proving runs A3 and A7b confirmed at W-6).
- [ ] `allowed-tools` unchanged; `description` reworded off "fully-autonomous".
- [ ] `build-report-contract.md` generalized off `tdd`; the three catalog rows are `manual read, HITL`.
- [ ] No em-dashes, no banned words across all three edited files.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `none, HITL` (low-confidence: three coupled skill-definition/contract/catalog edits, not testable code; consult the Skill Composition, Context Hygiene, Agent Dispatch Namespacing, Workflow Patterns, and AskUserQuestion guidance).

**Suggested review.** `manual read, HITL` (verify against C5-C8 and the A1-A10 dry-runs).

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`.
- `han-coding/skills/implement-work-items/references/build-report-contract.md`.
- `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md`.

**Depends on.** W-1, W-2, W-3.

## W-5 — Long-form docs and writing-voice pass

**Summary.** Update the two operator-facing long-form docs to reflect the HITL routing and normalized review gate, and run a writing-voice pass across every file edited by this feature. This is editing feature/system documentation, so it takes the documentation implementation and review skills rather than a manual-read gate. See plan: WU-7, [D-14](feature-implementation-plan.md#definition-of-done); CONTRIBUTING coverage rule.

**Description.**
1. Update `docs/skills/han-coding/implement-work-items.md` to describe: driving needs-a-human items alongside autonomous ones, phase routing by recorded markers, the decide gate, foreground build (named skill or free-form `none`), human review, the normalized verdict gate, in-session state catch-up, and the preserved single-pass / one-commit / independent-verify / fail-closed model.
2. Update `docs/skills/han-planning/plan-work-items.md` to reflect the catalog correction (the three `guidance`-as-review rows now record a human read).
3. Run a writing-voice pass across all files edited by this feature (both docs plus the W-1 through W-4 skill files): no em-dashes, no banned words (`leverage`, `utilize`, `just`, `actually`, `robust`, `Importantly`), direct second person, plainspoken tone per the voice profile.
4. Confirm the CONTRIBUTING coverage rule is satisfied (every touched skill has its long-form doc updated).

**References.**
- **Standard / repo doc** — Authoring conventions: CONTRIBUTING coverage rule and the writing-voice profile (see Shared reference artifacts).
- **Spec section** — [feature-specification.md#outcome](feature-specification.md#outcome), [feature-specification.md#primary-flow](feature-specification.md#primary-flow), [feature-specification.md#coordinations](feature-specification.md#coordinations) for the doc content.

**Tests.**
- CONTRIBUTING coverage rule (both long-form docs updated for the changed skills).
- Voice pass (no em-dashes, no banned words across all edited files — the C8 voice clause applied doc-wide).

**Acceptance criteria.**
- [ ] `docs/skills/han-coding/implement-work-items.md` reflects HITL routing and the normalized review gate.
- [ ] `docs/skills/han-planning/plan-work-items.md` reflects the catalog correction.
- [ ] Voice pass complete across all files edited by this feature: no em-dashes, no banned words.
- [ ] CONTRIBUTING coverage rule satisfied.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `han-core:project-documentation`, AFK (editing feature/system documentation; also carries the writing-voice pass).

**Suggested review.** `han-core:content-auditor` agent, AFK.

**Expected paths.**
- `docs/skills/han-coding/implement-work-items.md`.
- `docs/skills/han-planning/plan-work-items.md`.

**Depends on.** W-4 (the docs describe the shipped behavior).

## W-6 — Verification pass

**Summary.** Run the full read-the-file contract checks (C1-C8) and the dry-run scenarios (A1-A10) against the edited driver and contracts, including the A3 foreground-resume and A7b opt-in-pause proving runs and the A1 fully-autonomous regression, and confirm the Definition of Done. This is manual HITL verification against the plan's Testing Strategy; it produces no source change. See plan: WU-8, [D-14](feature-implementation-plan.md#definition-of-done).

**Description.**
1. Run C1-C8 read-the-file contract checks against the final edited files.
2. Run A1-A10 dry-runs, one per execution mode: A1 fully-autonomous regression (and still-applicable Step 1.7 refusals), A2 decision-then-unattended, A3 foreground-build resume (proving gate), A4 free-form `none` build, A5 human read, A6 non-code AFK review, A7a unattended no-opt-in, A7b opt-in review pause (proving gate), A8 fix loop on a HITL item (bounded across state catch-up), A9 commit adoption (no empty commit), A10 startup drivability abort.
3. Confirm the edge cases the plan flags are covered: the infinite-loop hole (A8), the never-clearing none-review loop (A1/A8), the empty-or-duplicate commit (A9), the pre-decision commit-failure halt frame (A2).
4. Confirm every Definition-of-Done checkbox in the plan is satisfied; report any residual gap rather than passing silently.

**References.**
- **Repo doc** — [feature-implementation-plan.md#testing-strategy](feature-implementation-plan.md#testing-strategy), [feature-implementation-plan.md#definition-of-done](feature-implementation-plan.md#definition-of-done).
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes).

**Tests.**
- C1-C8; A1-A10 (including the A3 and A7b proving runs and the A1 regression); Definition of Done.

**Acceptance criteria.**
- [ ] C1-C8 pass.
- [ ] A1-A10 pass, including the A3 and A7b proving runs.
- [ ] A1 regression and the still-applicable Step 1.7 refusals behave unchanged.
- [ ] All Definition-of-Done items in the plan are confirmed.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `none, HITL` (low-confidence: manual dry-run verification, no test harness; the verifier works against the plan's Testing Strategy and the edited contracts).

**Suggested review.** `manual read, HITL` (the verification pass is itself the review instrument; a second reader confirms the C-check / A-scenario results).

**Expected paths.**
- None (verification only; exercises real or scratch `work-items.md` files, produces no committed source change).

**Depends on.** W-1, W-2, W-3, W-4, W-5.
