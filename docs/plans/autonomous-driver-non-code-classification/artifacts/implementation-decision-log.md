# Implementation Decision Log: Non-code, meta, and non-deliverable work items

<!--
This file records every implementation decision committed while planning this feature.
Behavioral and implementation statements live in [../feature-implementation-plan.md](../feature-implementation-plan.md);
this file captures the question, rationale, evidence, and rejected alternatives for each decision.
Round-by-round history lives in [implementation-iteration-history.md](implementation-iteration-history.md).
The D-N counter is shared across the trivial and full sections.
-->

## Trivial decisions

- D-7: `general-purpose` is exempt from the Step 1.7 installed-skill check — the driver's "every named implementation skill or sub-agent must be installed and invocable" bullet gains a carve-out reading `general-purpose` as a built-in, always-available agent type, so an agent-drafted build is never a not-installed halt; this is the placement the spec's T1 mechanic requires and there is no counterfactual (without it every `` `general-purpose` agent, AFK `` build aborts at startup). — Referenced in plan: Implementation Approach (Architecture and Integration Points), Testing Strategy.

## Full decisions

### D-1: Four refusals inline in Step 1.7, no-output mechanics to a reference file

- **Question:** Given the driver body is already at the post-compaction context cap (~5k), where do the four new `Type`-coupled refusals and the multi-step no-output completion mechanics live — inline in `SKILL.md`, or pushed to a reference file?
- **Decision:** Split by shape. The four short single-condition refusal *rules* (spec [D11](../feature-specification.md), driver [D11 startup refusals](decision-log.md#d11-the-type-marker-is-driver-validated-with-startup-refusals)) stay inline in Step 1.7, extending the existing four validation bullets. The multi-step no-output *mechanics* — the clean-tree assertion, the no-commit recording, and the completion/halt summary labeling — move to a new reference file that Step 3.4, Step 4, and the Halt Procedure point to. A Definition-of-Done gate measures the post-edit driver body against the ~5k compaction cap and applies the split further if the body is over.
- **Rationale:** A single-condition halt rule with one call site fails the reference-file simpler-version test (structural-analyst): Step 1.7 already net-deleted the old tdd-only refusal in the HITL feature, so four short bullets replace rather than grow the block. But the no-output mechanics are net additions at ~5 body sites with no offsetting deletion, so leaving them inline risks a mid-run compaction dropping the very guards this feature adds (on-call-engineer). Splitting rules-inline from mechanics-to-reference keeps body growth minimal while keeping the guards durable.
- **Evidence:** `han-coding/skills/implement-work-items/SKILL.md` Step 1.7 (four existing validation bullets; the tdd-only refusal was net-deleted by the HITL feature); the ~5k post-compaction cap carried from the predecessor (`docs/plans/autonomous-driver-hitl-support/feature-implementation-plan.md` R3, `.discovery-notes.md`); R1 structural-analyst (iteration-history claim 1) vs R1 on-call-engineer Finding 6 (iteration-history claim 12), resolved in R2 by the inline-rules / reference-mechanics split (OQ-5).
- **Rejected alternatives:**
  - A dedicated refusal reference file for the four `Type` checks — rejected because each refusal is a single condition with one call site and the block is shrinking, not growing (structural-analyst R1); a reference file here is a helper before a shared or large need.
  - Keep the no-output mechanics inline as well — rejected because this feature is net growth at ~5 sites, so a compaction can revert the body to pre-feature behavior with the guards gone (on-call-engineer Finding 6).
- **Specialist owner:** structural-analyst (body-shape split); on-call-engineer (compaction durability)
- **Revisit criterion:** the post-edit driver body measures over the ~5k cap even after the split, or a second driver entry point emerges that also needs the refusal rules.
- **Dissent (if any):** None standing — the structural-analyst (refusals inline) and on-call-engineer (mechanics to a reference) positions were Disputed in R1 and reconciled in R2 by the split; both committed.
- **Driven by rounds:** R1, R2
- **Dependent decisions:** D-8, D-10, D-13, D-15
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Decomposition and Sequencing, On-Call Resilience Posture, Definition of Done

### D-2: No shared cross-plugin refusal file; deliberate duplication with atomic co-land

- **Question:** The refusal set lives in both the producer (declines overrides) and the driver (re-checks at startup). Does it become one shared source-of-truth file, or is it stated in full in each skill?
- **Decision:** State the four refusals in full in each skill — the producer's catalog classification step and Overrides note, and the driver's Step 1.7 — and keep them reconciled by co-landing both edits in one commit as a maintenance convention. No shared refusal file.
- **Rationale:** A shared file is the lightest cross-skill enforcement machinery, which the spec's Out of Scope explicitly forbids. It also crosses the `han-planning`→`han-coding` plugin boundary the suite has no cross-plugin reference mechanism for, and would have to live in `han-core` although the vocabulary is a producer↔driver contract detail, not core vocabulary. The predecessor handled the identical producer/driver reconciliation by co-landing the catalog correction with the driver edit, no shared file.
- **Evidence:** spec Out of Scope "Machinery to keep the producer and driver refusal vocabularies in sync … adds no cross-skill enforcement machinery" ([spec D11](decision-log.md#d11-the-type-marker-is-driver-validated-with-startup-refusals)); the plugin split (`han-planning/skills/plan-work-items/` vs `han-coding/skills/implement-work-items/`, `.discovery-notes.md`); predecessor atomic co-land of driver + `deliverable-skill-catalog.md` (`docs/plans/autonomous-driver-hitl-support/feature-implementation-plan.md` D-9/Dep1); R1 structural-analyst R2 (iteration-history claim 3).
- **Rejected alternatives:**
  - A shared refusal file in `han-core` — rejected because it is exactly the cross-skill sync machinery the spec forbids and it crosses a plugin boundary with no reference mechanism (structural-analyst R2).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** a third skill, or a cross-suite enforcement mechanism, needs the refusal vocabulary — at which point the shared file (deferred YAGNI) reopens.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-15
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Decomposition and Sequencing, Deferred (YAGNI)

### D-3: Refusal check sub-order, one refusal per halted item

- **Question:** When an item violates more than one refusal, what does the driver report, and in what order are the four refusals checked?
- **Decision:** Report exactly one refusal per halted item — the first in check order — and check in this sub-order: (1) a `` `none`, AFK `` build marker, inside the existing "Drivable" bullet; (2) `Type` validity (present and outside `deliverable`/`verification`/`spike` refuses; absent defaults silently to `deliverable`); (3) `Expected paths: None` on any non-`verification` item; (4) an `AFK` review on any `verification` item or any item declaring `Expected paths: None`. Checks 3 and 4 read the `Type` resolved by check 2, so the order is load-bearing.
- **Rationale:** Checks 3 and 4 cannot evaluate until check 2 has resolved a valid `Type`, so `Type` validity must fire before the `Type`-dependent refusals. Reporting one refusal per halted item keeps the startup halt message actionable rather than flooding the operator with every violation an ill-formed item carries. The `none, AFK` check needs only the build-marker field, so it sits with the structural drivability rules, ahead of the semantic `Type` layer.
- **Evidence:** driver Step 1.7 existing bullets (not-empty, fields-present, Drivable, well-formed-graph) in `han-coding/skills/implement-work-items/SKILL.md`; the compound examples (`Type: sprint` + `None` surfaces only "unrecognized Type"; `verification` + `None` + AFK-review surfaces the AFK-review refusal) from R1 edge-case-explorer F-1 (iteration-history claim 2).
- **Rejected alternatives:**
  - Report every refusal an item violates — rejected because a single ill-formed item can trip several refusals at once, and a flood of simultaneous halt reasons is harder to act on than the first blocking one (edge-case-explorer F-1).
  - Check the `Type`-dependent refusals before `Type` validity — rejected because a refused item could have an unrecognized `Type`, leaving checks 3 and 4 with no `Type` to branch on.
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** a fifth refusal is added whose evaluation depends on a different resolved field, changing the dependency order.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Testing Strategy

### D-4: Catalog gains three rows, a row reframe, an exempt note, and an Overrides refusal rule

- **Question:** What edits does `deliverable-skill-catalog.md` need so the producer can classify an edit-existing-plugin item, a verification, and a spike, and so it declines rather than writes a refused override?
- **Decision:** Make five in-place catalog changes: (A) a new **edit-existing-plugin-definition** row after the new-skill/new-agent rows, mapping `` `general-purpose` agent, AFK `` / `` none, HITL ``; (B) reframe the existing "Other work related to Claude Code plugins" row from `` `han-plugin-builder:guidance`, AFK `` to `` `general-purpose` agent, AFK `` / `` none, HITL `` (implementation cell only, position unchanged); (C) new **verification** and **spike** rows as a non-deliverable cluster placed after the doc/records rows and before the catch-all — verification = named-checks build (AFK when automatable, HITL when manual dry-runs), review `` none, HITL ``; spike = routed by question type (spec D17: investigate / research / general-purpose), review `` none, HITL ``; (D) a `general-purpose`-exempt parenthetical on the existing never-auto-`AFK` guardrail; (E) the Overrides note gains the producer-side refusal rule (decline the offending field, restore the catalog base, name the declined override — never transform `Type` or the output contract).
- **Rationale:** The classification step is a table lookup, so verification and spike need first-class rows, not `Type`-conditional prose, or a codebase spike meant for `han-coding:investigate` falls to the "no han skill fits" catch-all and is classed human-throughout (contradicting spec D8). The guidance row cannot stay named as an implementer because guidance serves authoring rules and cannot edit files (spec D5). The exempt note keeps the producer from reading `` `general-purpose` agent, AFK `` as a guardrail violation (spec T1). The Overrides refusal rule is where the producer applies the same four refusals it authors from, declining the field rather than writing a refused combination.
- **Evidence:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md` Table 1 (new-skill/new-agent rows at `none, HITL`; the "Other work related to Claude Code plugins → `han-plugin-builder:guidance`, AFK" row; the "No han skill fits" catch-all; the never-auto-`AFK` guardrail and the Overrides note); spec [D4](decision-log.md#d4-editing-an-existing-plugin-definition-is-its-own-classification), [D5](decision-log.md#d5-guidance-is-reference-only-never-the-implementer), [D15](decision-log.md#d15-the-catalog-gains-classification-homes-for-verification-and-spike-and-links-guidance), [T1](feature-technical-notes.md#t1-general-purpose-is-a-built-in-always-available-agent-type); R1 structural-analyst R3 and R1 edge-case-explorer F-10 (iteration-history claim 4).
- **Rejected alternatives:**
  - `Type`-conditional guidance instead of new rows — rejected because the classification step is a table lookup, so verification and spike need selectable rows (structural-analyst R3).
  - Merge the edit-existing case into the catch-all — rejected because editing an existing definition is the most common plugin-maintenance task and deserves an explicit, findable row (spec D4/D5).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** a plugin-maintenance task emerges that fits none of the new rows and is being forced through the catch-all again.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-6, D-9, D-15
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Data Model and Persistence, Decomposition and Sequencing

### D-5: Both contract files are generalized in place

- **Question:** Do the build-report contract (a skill-less build, a declared-no-output build) and the human-review capture (a no-output review) get new files, or in-place generalizations?
- **Decision:** Generalize both in place. In `build-report-contract.md`, make the empty-FILES halt conditional (it still applies to any item that declared paths, but a declared-`Expected paths: None` build may report `built` with empty FILES as a clean completion) and let a skill-less general-purpose build report `built` without a skill-gate claim. In `human-review-capture.md`, add a no-output branch at the top of the Capture step: when the item declared `Expected paths: None`, the operator confirms the checks ran and the result is sound rather than being pointed at an absent change, and the coverage attestation is "operator confirmed result."
- **Rationale:** Step 3.3 pastes each contract verbatim into the dispatch, so a second file would force new routing logic in the already-capped driver body. Both changes are conditional clauses on existing sections, matching how the predecessor generalized its verdict contract in place. A new file would be a single-implementation abstraction before a second consumer.
- **Evidence:** `han-coding/skills/implement-work-items/references/build-report-contract.md` (the STATUS/FILES semantics and the "STATUS is `built` but FILES lists no path" halt); `han-coding/skills/implement-work-items/references/human-review-capture.md` (the Capture step "Point the user at the item's change"); driver Step 3.3 pastes the contract verbatim; spec [D12](decision-log.md#d12-a-no-output-item-is-reviewed-by-a-human-confirmation), [D13](decision-log.md#d13-the-build-report-contract-gains-a-skill-less-and-no-output-shape); R1 structural-analyst R4 and R1 edge-case-explorer F-8/F-9 (iteration-history claim 5).
- **Rejected alternatives:**
  - New contract files for the skill-less and no-output shapes — rejected because Step 3.3 pastes contracts verbatim, so a second file forces body-side routing and is a single-implementation abstraction (structural-analyst R4).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** a third build or review shape appears whose contract cannot be expressed as a conditional clause on the existing sections.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-15
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Decomposition and Sequencing

### D-6: Template puts Type first and renames Tests to Verification with the D18 narrowing

- **Question:** Where does the new `Type` field sit in `work-item-template.md`, what happens to `Tests`, and where does the D18 ordered trigger land?
- **Decision:** Add `Type` as the first field in the routing-field group, immediately before `Requires pre-work decisions`. Rename `Tests` to `Verification` at its existing position (after References) with type-aware content (code test levels for code, read-the-file conformance and dry-run checks for docs and skills, result confirmation for a verification). Update the `Requires pre-work decisions` field definition to the narrowed ordered trigger (record-worthy → ADR the dependent item depends on; else requires-evidence → spike; else single-sentence → inline flag), and land the same narrowing in the catalog's classification step.
- **Rationale:** `Type` is a driver-validated marker that conditions the acceptable values of the other routing fields (`None`-only-on-`verification`, catalog-row selection, AFK-review refusal), so a producer filling top-to-bottom should resolve it first, and its position matches the driver's validation order. `Verification` is producer- and documentation-facing only (the driver never parses it), so its rename is a vocabulary change at its existing position. The D18 trigger narrows in two sites because "keep the field" would otherwise silently contradict the template's current "architectural decision" trigger.
- **Evidence:** `han-planning/skills/plan-work-items/references/work-item-template.md` (`**Tests.**`, `**Requires pre-work decisions.**`, `**Suggested implementation.**`, `**Suggested review.**`, `**Expected paths.**`; no `Type` field today); the driver never parses `Tests`/`Verification` ([spec D10](decision-log.md#d10-the-extended-format-is-backward-compatible)); spec [D6](decision-log.md#d6-a-type-marker-distinguishes-deliverable-verification-and-spike-items), [D7](decision-log.md#d7-the-templates-tests-field-becomes-a-type-aware-verification-field), [D18](decision-log.md#d18-the-pre-work-decisions-field-is-kept-with-a-producer-routing-note); R1 structural-analyst R5, edge-case-explorer F-2, junior-developer OQ8 (iteration-history claim 6); OQ-8 resolution.
- **Rejected alternatives:**
  - Keep the `Tests` field name with type-aware guidance — rejected because the name stays code-flavored even when the content is conformance checks (spec D7, user input).
  - Place `Type` lower among the documentation-facing fields — rejected because it is driver-validated and conditions the other routing fields' acceptable values, so it belongs first in the routing group (structural-analyst R5).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** the driver begins parsing `Verification`, making its position driver-facing rather than documentation-facing.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-9, D-15
- **Referenced in plan:** Implementation Approach (Data Model and Persistence), Decomposition and Sequencing

### D-8: No-output completion is the distinct terminal state done-no-commit

- **Question:** How does the driver record a `verification` item that declared `Expected paths: None` and changed no files, so it is distinguishable from a not-yet-done item and survives the fresh-branch recovery?
- **Decision:** Record a no-output completion as a distinct terminal state `done-no-commit` in `state.json` — one field the Step 3.4 no-output branch, the Step 4 completion summary, the Halt Procedure, and the in-session re-grounding all branch on. Step 3.4 gains a no-output branch (verification + `Expected paths: None` + no diff since `scope-baseline`) that skips the commit and sets `done-no-commit`; Step 4 names no-commit completions as their own outcome bucket (item ID, `Type`, `Expected paths: None`, count); the Halt Procedure names them distinctly (they carry no commit and are not in the cherry-pick range).
- **Rationale:** The current schema inits `commit-range: null` and sets `done` on commit, so a no-output item ending `{state: done, commit-range: null}` is indistinguishable from an item whose range is not yet written — and the in-session re-ground can re-drive it. A single distinct terminal state cannot be internally inconsistent the way `done` plus a separate `no-commit` boolean could (the two could disagree), and it is the single field every read site branches on. Removing the empty-FILES halt removes the operator's only no-op signal, so the labeled, counted outcome must ship with it.
- **Evidence:** `han-coding/skills/implement-work-items/SKILL.md` Step 2.2 (state.json init `{state, fix-round, scope-baseline, decision, commit-range}`), Step 3.4 (stages by path, sets `done`; no zero-file branch), Step 4 (completion summary), Halt Procedure (commit-range-based cherry-pick recovery); spec [D9](decision-log.md#d9-a-verification-item-may-declare-no-output-and-is-then-driven-without-a-commit), [D14](decision-log.md#d14-a-no-commit-completion-is-labeled-tracked-and-idempotent); R1 on-call-engineer Findings 1 and 4, edge-case-explorer F-5/F-7 (iteration-history claim 9); OQ-2 resolution.
- **Rejected alternatives:**
  - `state: done` plus a separate `no-commit: true` boolean — rejected because two fields can fall out of sync (a `done` with a stale or absent boolean), where one distinct terminal state cannot be internally inconsistent (on-call-engineer OQ2; edge-case-explorer F-7 noted either satisfies distinguishability, on-call refined to the single field).
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** a second no-output completion shape appears that the single terminal state cannot distinguish (for example a no-output item that must also record a partial artifact).
- **Dissent (if any):** None standing — edge-case-explorer offered a boolean-or-state choice; on-call-engineer's single-terminal-state refinement was adopted; both committed.
- **Driven by rounds:** R1
- **Dependent decisions:** D-10
- **Referenced in plan:** Implementation Approach (Data Model and Persistence, Runtime Behavior), On-Call Resilience Posture, Testing Strategy

### D-9: Idempotency is wired as an authored constraint line in the catalog and template

- **Question:** Spec D14 commits that a no-output verification's execution is idempotent, but the fresh-branch recovery re-runs it unconditionally. Where is that commitment wired so the classifier or operator actually reads it?
- **Decision:** Author one constraint line in the catalog's verification row and the template's `Verification` guidance: a no-output verification must be side-effect-free and safe to re-run, because on re-invocation the driver re-runs it from the first item and it leaves no commit to skip it.
- **Rationale:** The fresh-branch recovery is amnesiac — a no-output item leaves no commit for cherry-pick-forward to skip and the fresh `state.json` re-executes it from scratch, so "safe to repeat" concretely requires the checks be read-only. The in-repo case is naturally read-only, but the driver ships to arbitrary repos where a "verification pass" could hit a database or staging API, so the commitment must be recorded where the producer authors the item, not left as an unwired spec assertion.
- **Evidence:** driver Halt Procedure re-runs from the first item on re-invocation and the fresh-branch `state.json` is empty (`han-coding/skills/implement-work-items/SKILL.md`); spec [D14](decision-log.md#d14-a-no-commit-completion-is-labeled-tracked-and-idempotent); R1 on-call-engineer Finding 2, junior-developer OQ7 (iteration-history claim 10).
- **Rejected alternatives:**
  - Leave idempotency as a spec commitment with nothing authored — rejected because D14 is asserted but wired to nothing the classifier or operator ever reads, so the amnesiac recovery re-runs a side-effecting check with no warning (on-call-engineer Finding 2).
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** a target repo reports a no-output verification whose re-run caused a side effect despite the constraint line, indicating the authored guidance is insufficient and a mechanical guard is needed.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Data Model and Persistence), On-Call Resilience Posture, Testing Strategy

### D-10: Clean-tree assertion at no-output completion with a Step 3.1 backstop

- **Question:** A no-output item that unexpectedly leaves files breaks the inductive "tree was clean at item start" that the next item's scope check relies on. Where does the driver assert a clean tree so stray files are attributed to the item that produced them?
- **Decision:** Place the primary clean-tree assertion in the Step 3.4 no-output branch, at the no-output item's own completion, so stray files are attributed to and gated on the item that produced them (they surface as a scope finding in that item's review). Keep a lightweight assertion at Step 3.1, before recording `scope-baseline`, as a backstop against a prior item's stray files, and update Step 3.4's inductive comment.
- **Rationale:** `scope-baseline` is a commit hash that captures nothing about uncommitted stray files, and the "tree was clean at item start" induction holds only because every deliverable commits — a no-output item breaks it for the next item. Asserting only at the next item's Step 3.1 fires after the no-output item is recorded done, so a halt there mis-attributes the stray files to the next item (the Halt Procedure would disclose them as belonging to the wrong item). Asserting at the no-output item's own completion attributes correctly; the Step 3.1 backstop covers the general case.
- **Evidence:** driver Step 3.1 (records `scope-baseline` as the per-item HEAD), Step 3.4 (stages files changed since `scope-baseline`), the review sweep of untracked files, and the Halt Procedure tree-state disclosure (`han-coding/skills/implement-work-items/SKILL.md`); spec [D9](decision-log.md#d9-a-verification-item-may-declare-no-output-and-is-then-driven-without-a-commit), [D14](decision-log.md#d14-a-no-commit-completion-is-labeled-tracked-and-idempotent); R1 on-call-engineer Finding 3 refining edge-case-explorer F-6 (iteration-history claim 11).
- **Rejected alternatives:**
  - Assert a clean tree only at the next item's Step 3.1 — rejected because it fires after the no-output item is recorded done, mis-attributing that item's stray files to the next item in any halt disclosure (on-call-engineer Finding 3).
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** the driver adopts per-item branches or a non-HEAD scope baseline, changing how stray files are attributed.
- **Dissent (if any):** None standing — on-call-engineer refined edge-case-explorer's single Step 3.1 placement to primary-at-completion-plus-backstop; both committed.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), On-Call Resilience Posture, Testing Strategy

### D-11: The spike build dispatch carries the Expected path to the builder

- **Question:** For an AFK spike to land its finding on-path, the build dispatch must tell the builder where to write. The driver passes `Expected paths` only to the reviewer today — what changes?
- **Decision:** The Step 3.3 build dispatch for a spike carries the item's `Expected path` to the builder as the finding target, so the routed skill (`investigate` / `research` / general-purpose) writes its finding where the scope review expects it.
- **Rationale:** Today `Expected paths` reaches only the reviewer, so an AFK spike's builder would write to a default location and the scope review would flag every spike as off-path. Carrying the Expected path into the build dispatch is the smallest change that lands the finding on-path; it is the AFK half of the spec's F14 handoff.
- **Evidence:** driver Step 3.3 passes reference material and the `scope-baseline` commit hash to the build agent, and passes `Expected paths` to the reviewer (`han-coding/skills/implement-work-items/SKILL.md`); spec [D17](decision-log.md#d17-a-spikes-build-routes-by-question-type) and its F14 plan-implementation handoff; R1 junior-developer OQ3 (iteration-history claim 13); OQ-3 resolution.
- **Rejected alternatives:**
  - Pass the Expected path to the reviewer only, as today — rejected because the AFK spike's builder then writes to a default location and every spike is flagged off-path at review (junior-developer OQ3).
- **Specialist owner:** structural-analyst (dispatch shape); test-engineer (verified by C-12/PD-2)
- **Revisit criterion:** the spike build gains a distinct output-location mechanism separate from `Expected paths`.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-12
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Testing Strategy

### D-12: The spike review defaults to a human soundness read independent of the build marker

- **Question:** An AFK interactive-skill spike that hits an operator gate can return a well-formed but bad or incomplete finding that passes the fail-closed build parse and commits, propagating to a dependent item. What is the smallest guard, without reopening spec D19's AFK build autonomy?
- **Decision:** A spike's review defaults to a human soundness read (`` none, HITL ``) in the catalog, independent of the AFK build marker (build and review autonomy are separate markers). No new driver refusal is added — the guard is the catalog default plus the PD-2 proving run, not a fifth Step 1.7 refusal. A human soundness reviewer reads the finding against the spike's question before the driver advances to any dependent item; a bad, empty, or misdirected finding fails the soundness check and the driver fix-loops or halts.
- **Rationale:** The fail-closed build parse guarantees a recoverable halt only for a malformed return; a capable sub-agent hitting a vague-clarify or mis-route gate can proceed on a fabricated interpretation and return a well-formed report that passes the parse and commits. Spec D8/F10 got the spike review only to "recorded, non-empty," which is mechanically checkable and an AFK reviewer would rubber-stamp over a plausible-but-wrong finding. A human soundness read is the smallest gate that catches a finding that answers a question the spike invented, and it holds under both R1 predictions of the gate behavior: under the halt prediction no commit and no dependent item runs; under the commit prediction the human read fires before any dependent item consumes the finding. A fifth driver refusal would expand the spec's bounded four-refusal contract for no added safety and cost inline compaction budget.
- **Evidence:** the fail-closed build parse halt conditions in `han-coding/skills/implement-work-items/references/build-report-contract.md`; a spike finding steers a dependent item ([spec D18](decision-log.md#d18-the-pre-work-decisions-field-is-kept-with-a-producer-routing-note)); spec [D8](decision-log.md#d8-verification-and-spike-items-carry-result-confirming-reviews), [D19](decision-log.md#d19-spike-autonomy-is-afk-capable-producer-judged-per-item), and the F2 rubber-stamp analog ([spec D12](decision-log.md#d12-a-no-output-item-is-reviewed-by-a-human-confirmation)); R1 on-call-engineer Finding 5 vs edge-case-explorer F-11, adjudicated in R2 by test-engineer PD-2 (iteration-history claims 14, 15, 22); OQ-4 resolution.
- **Rejected alternatives:**
  - A fifth driver refusal on an `AFK` spike review — rejected because the catalog `none, HITL` default plus PD-2 satisfy spec D8's intent without expanding the spec's bounded four-refusal contract, and the compaction budget argues against another inline refusal (on-call-engineer recommended catalog-default-only; this is a YAGNI deferral). The residual is that a hand-edited AFK-spike-review is not refused by the driver — a non-blocking Open Item.
  - Reopen spec D19 and route all interactive-skill spikes to HITL builds — rejected because `research`/`investigate` run AFK-clean for well-formed, correctly-routed questions, so a blanket build-side HITL foreground-runs them for no benefit (spec D19).
- **Specialist owner:** on-call-engineer (the HITL-review default); test-engineer (PD-2 observability)
- **Revisit criterion:** PD-2 during implementation shows a committed spike finding that bypasses the HITL review (the driver advancing a dependent item without the human read) — which falsifies spec D19's "not corruption" premise and escalates to the spec owner; or a hand-edited AFK-spike-review is observed to rubber-stamp a bad finding (reopening the fifth-refusal YAGNI).
- **Dissent (if any):** None standing — on-call-engineer (fabricated-finding risk) and edge-case-explorer (recoverable-halt) offered opposing predictions of the gate behavior; test-engineer adjudicated that the `none, HITL` default covers both and PD-2 makes it observable; all committed.
- **Driven by rounds:** R1, R2
- **Dependent decisions:** D-13
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Testing Strategy, On-Call Resilience Posture, Deferred (YAGNI), Open Items

### D-13: Verification is read-the-file checks plus dry-runs, with two proving runs as gates

- **Question:** There is no automated test harness for skill behavior. What is the verification set, and which behaviors need a proving dry-run gate?
- **Decision:** Verify with read-the-file contract checks C-1..C-12 (each mapped to a driver step, reference file, or catalog/template section) and end-to-end dry-runs A-1..A-12 (one per execution mode), with test-double posture "none" (real skills against scratch work-items files) and levels contract-conformance and end-to-end only. Add two proving dry-runs as Definition-of-Done gates: PD-1 (idempotency, spec D14) — a no-output verification re-executes safely on a fresh branch after a later-item halt; PD-2 (spike-gate, spec D19 / OQ-4) — an AFK interactive-skill spike dispatched into each gate either halts before any commit, or commits a finding and the `none, HITL` review fires before any dependent item consumes it.
- **Rationale:** The predecessor established the read-the-file + dry-run model for the same class of markdown skill-authoring change with no harness; golden-file snapshots over free-form agent returns are non-deterministic noise. The two asserted-but-unproven commitments (idempotency, and "an AFK spike gate halts recoverably") are exactly the class the predecessor proved with dedicated dry-runs, so each becomes an observable DoD gate rather than an assumption.
- **Evidence:** no automated harness for skill behavior (`.discovery-notes.md`); predecessor Testing Strategy and its A3/A7b proving-run pattern (`docs/plans/autonomous-driver-hitl-support/feature-implementation-plan.md`); spec [D14](decision-log.md#d14-a-no-commit-completion-is-labeled-tracked-and-idempotent), [D19](decision-log.md#d19-spike-autonomy-is-afk-capable-producer-judged-per-item); R2 test-engineer consolidation (iteration-history claims 17, 20, 21, 22).
- **Rejected alternatives:**
  - Automated test scaffolding or golden-file snapshots over agent returns — rejected because there is no harness to run them and golden files over non-deterministic returns are noise (test-engineer; a YAGNI deferral).
  - A unit or integration layer for the markdown skill behavior — rejected because there is no runtime to unit-test; contract-conformance and end-to-end dry-run are the only applicable levels (test-engineer).
- **Specialist owner:** test-engineer
- **Revisit criterion:** a skill-test framework is added to the repo, at which point automated scaffolding reopens.
- **Dissent (if any):** None.
- **Driven by rounds:** R2
- **Dependent decisions:** —
- **Referenced in plan:** Testing Strategy, Definition of Done, Decomposition and Sequencing, Deferred (YAGNI)

### D-14: A record-worthy pre-work decision routes to the repo decision-record home or the plan decision log

- **Question:** Spec D18 routes a record-worthy pre-work decision to an ADR the dependent item depends on, but a target repo may have no ADR store (this repo has none). What does the producer emit so the narrowing does not produce a dangling ADR reference?
- **Decision:** The producer's catalog note records a record-worthy decision where the target repo keeps its decision records — an ADR store if one is present, otherwise the plan's own decision log. The inline `Requires pre-work decisions` flag is retained for single-sentence judgment calls, so the fallback never forces a manufactured record for a pure judgment call.
- **Rationale:** Without a fallback the producer emits a dangling ADR reference or silently drops to the inline flag, defeating the D18 narrowing. Routing to wherever the repo actually keeps decision records (this repo keeps them in the per-feature decision logs under `docs/plans/`) keeps the record-worthy decision recorded without assuming an ADR store exists, and keeping the inline flag for single-sentence calls preserves the lighter path D18 depends on.
- **Evidence:** no `docs/adr/` or `docs/architecture/` in this repo; decisions live in per-feature decision logs under `docs/plans/` (`.discovery-notes.md` enumerated gaps); spec [D18](decision-log.md#d18-the-pre-work-decisions-field-is-kept-with-a-producer-routing-note); R1 junior-developer OQ1, resolved by evidence in R2 (iteration-history claim 18); OQ-1 resolution.
- **Rejected alternatives:**
  - Emit an ADR reference unconditionally — rejected because a target repo without an ADR store gets a dangling reference (junior-developer OQ1).
  - Silently fall back to the inline flag for a record-worthy decision — rejected because it defeats the D18 narrowing (the record-worthy decision loses its durable home).
- **Specialist owner:** junior-developer (surfaced); resolved by evidence
- **Revisit criterion:** an implementer is misled on a real run by the decision-record-home fallback, or a target repo's decision-record convention is neither an ADR store nor a plan decision log.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Data Model and Persistence), RAID Log

### D-15: Driver, contracts, catalog, and template co-land as one atomic change

- **Question:** The producer-side markers and the driver-side validation are one shared vocabulary contract. How are the edits sequenced so the two skills are never mutually inconsistent?
- **Decision:** Land the driver `SKILL.md` edit, the two contract-file generalizations, the producer catalog edits, and the template edits as one atomic change (contracts same commit or sequenced before the driver body; catalog and template in the same commit as the driver). The refusal set, the marker vocabulary, and the `Type` values are reconciled across both skills in that one commit.
- **Rationale:** The producer emits the markers the driver validates and routes on, so a version where one side's vocabulary has changed and the other has not silently drops items. Co-landing inherits the predecessor's atomic co-land discipline for the same producer↔driver contract, and is the maintenance convention the spec relies on in place of cross-skill enforcement machinery (D-2).
- **Evidence:** the producer→driver marker vocabulary is a shared contract reconciled in one commit ([spec D11](decision-log.md#d11-the-type-marker-is-driver-validated-with-startup-refusals), spec Coordinations); predecessor atomic co-land of driver + catalog (`docs/plans/autonomous-driver-hitl-support/feature-implementation-plan.md` D-9); R1 edge-case-explorer atomic-edit boundary and R2 test-engineer atomic-co-land DoD (iteration-history claims 4, 5, 6, 9).
- **Rejected alternatives:**
  - Sequence the catalog and template edits in a later commit than the driver — rejected because a driver that validates a `Type` the producer does not yet emit (or vice versa) drops items silently between commits (edge-case-explorer atomic-edit boundary).
- **Specialist owner:** structural-analyst
- **Revisit criterion:** a cross-skill enforcement mechanism is added that keeps the vocabularies in sync without a manual co-land.
- **Dissent (if any):** None.
- **Driven by rounds:** R1, R2
- **Dependent decisions:** —
- **Referenced in plan:** Decomposition and Sequencing, RAID Log, Definition of Done
