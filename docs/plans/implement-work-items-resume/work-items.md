# Work Items — Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

These work items break [feature-implementation-plan.md](feature-implementation-plan.md) into vertical slices for the `implement-work-items` skill. The deliverable is edits to a Claude Code skill — markdown instruction files plus one shell script — not application code; there is no service, database, or code test harness, so items are verified against the feature specification's Edge Cases table. Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

**Note on review markers.** Most items edit executable skill markdown, where a structurally-broken edit ships green because no automated gate catches it, so their review is a deliberate human read (`none, HITL`) per the deliverable-skill catalog — do not upgrade these to `AFK`. Only the script item (W-2) and the operator-doc item (W-10) carry `AFK` reviews.

**Note on shared-file order.** `SKILL.md` is edited by W-4 through W-7 and is chained in that order; `human-review-capture.md` is edited by W-3 and W-9 and is chained in that order. These `Depends on` edges keep the commit-by-path driver from building against a stale copy of a shared file — they are load-bearing, not soft preferences.

## Shared reference artifacts

- **Implementation plan** — [feature-implementation-plan.md](feature-implementation-plan.md). The how; per-item sections (Runtime Behavior, Data Model and Persistence) are cited in each item.
- **Feature specification** — [feature-specification.md](feature-specification.md). The behavioral ground truth; per-item spec anchors (Edge Cases rows, resume/halt flows) are cited in each item.
- **The skill under edit** — [han-coding/skills/implement-work-items/](../../../han-coding/skills/implement-work-items/). Every item's target file lives here (`SKILL.md`, `references/`, `scripts/`).
- **Progressive-disclosure guidance** — [progressive-disclosure.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md). The 500-line SKILL.md ceiling and the SKILL.md-points-to-references discipline that shapes every markdown edit.
- **Skill reference-file guidance** — [skill-reference-files.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-reference-files.md). How the two new `references/*.md` files should be structured.

## W-1 — Durable-record protocol reference

**Type.** `deliverable`

**Summary.** Create `references/durable-record-protocol.md`, the schema every downstream item reads: the ledger entry types with minimal fields, the run-identity and item-id commit trailers, the committed-ledger-file location, the default-deny integrity matrix, and the exclusion checklist. See plan: D-1 (committed ledger at `.implement-work-items/progress.md`), D-2 (`Implement-Work-Items-Run` trailer), D-8 (positional references), D-9 (`Implement-Work-Items-Item` trailer), D-11 (exclusion sites), D-13 (minimal fields), and [Data Model and Persistence](feature-implementation-plan.md#data-model-and-persistence).

**Description.**
1. Define the five ledger entry types and their minimal fields: opening entry (run configuration plus the work-items file's normalized repo-root-relative path); start-of-item entry (the changed-file-set baseline); done entry (a positional reference to the item's code commit, computed at report time, never a stored hash); no-commit-done entry (no `Type` field, distinguished by its entry token); skip entry (no dependency snapshot). See plan: D-13, D-8.
2. Specify the durable record as a committed markdown ledger at `.implement-work-items/progress.md`, made trackable by the setup step changing `.implement-work-items/.gitignore` from a single `*` to `*` then `!progress.md`, so the ledger is version-controlled while `state.json` and the review records stay ignored. See plan: D-1.
3. Specify the `Implement-Work-Items-Run:` commit trailer (value: the normalized repo-root-relative work-items path) carried by every ledger commit, and the `Implement-Work-Items-Item: W-N` trailer carried by each item's own code commit. Both matched exactly, never as a message substring. See plan: D-2, D-9.
4. State the D11 default-deny integrity matrix: the done-entry-commit-still-resolves check (output items only); the no-commit-done validity check (present, well-formed, clean tree at the item's baseline — a valid outcome, not a missing-commit divergence); and the rule that any state not positively classified as safe is surfaced-and-asked.
5. State the exclusion checklist naming the four sites (SKILL.md stage-by-path, the review scope diff, the human-review pointer, the no-output clean-tree assertion) that must keep `.implement-work-items/progress.md` out of an item's commit and scope. See plan: D-11.
6. Keep the file at reference altitude — schema and rules the SKILL.md steps consult, not a process to execute — following the skill reference-file guidance.

**References.**
- **Spec section** — [feature-specification.md#coordinations](feature-specification.md#coordinations) (the record travels with the branch, recorded separately from code, hook-conformant) and [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 2–5, the entry lifecycle).
- **Plan section** — [feature-implementation-plan.md#data-model-and-persistence](feature-implementation-plan.md#data-model-and-persistence).
- **Skill file** — [no-output-completion.md](../../../han-coding/skills/implement-work-items/references/no-output-completion.md) (the no-commit-done outcome this schema must express).
- **Authoring guidance** — [skill-reference-files.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-reference-files.md).

**Checks.**
- Read-the-file conformance: the schema names all five entry types and expresses a no-commit-done outcome; the two trailers and the `!progress.md` un-ignore line are stated exactly; the integrity matrix scopes the commit-resolves check to output items; the exclusion checklist names all four sites.

**Acceptance criteria.**
- [ ] The file defines the five entry types with minimal fields (no `Type` on no-commit-done, no dependency data in skip, no durable fix-counter/body-hash/pre-work-decision).
- [ ] The `Implement-Work-Items-Run` and `Implement-Work-Items-Item` trailers and the `!progress.md` un-ignore are specified.
- [ ] The default-deny integrity matrix and the four-site exclusion checklist are present.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/references/durable-record-protocol.md`

**Depends on.** None.

## W-2 — Run-history scan script

**Type.** `deliverable`

**Summary.** Create `scripts/scan-run-history.sh`, the deterministic detector that greps the resolved branch history for the `Implement-Work-Items-Run` trailer matched exactly against the normalized target path, classifies the invocation as fresh / resume / refuse, and reconstructs the run's entries from history. Deterministic work lives in the script; judgment stays in SKILL.md, per the hardening rule. See plan: D-2 (trailer match and path normalization), D-3 (a sibling script, not an extension of `detect-driver-context.sh`), and [Runtime Behavior](feature-implementation-plan.md#runtime-behavior).

**Description.**
1. Take the resolved work-items path as a parameter and normalize it (strip a leading `./`, resolve `..` segments, drop a trailing slash) before any comparison, so an equivalent-but-differently-spelled path classifies as the same run. See plan: D-2.
2. Scan the target branch history for the `Implement-Work-Items-Run:` trailer matched exactly against the normalized path, and classify: **fresh** when the branch is empty or carries no prior run commits; **resume** when a record for this file is present; **refuse** when the branch carries commits but no record for this file (a foreign base).
3. Reconstruct the per-item entry state (pending / started / done / done-no-commit / skipped) and the done-entry commit-resolution status from the scanned entries, emitting a structured `key: value` output in the style of `detect-driver-context.sh`.
4. Do not make judgment calls (whether to proceed, discard, or surface) — emit the facts and let SKILL.md interpret them. Invoke it from SKILL.md as numbered prose with a `${CLAUDE_SKILL_DIR}/scripts/...` path, per the script-execution guidance, and keep it out of `allowed-tools`.

**References.**
- **Spec section** — [feature-specification.md#actors-and-triggers](feature-specification.md#actors-and-triggers) (the fresh/resume/refuse trigger) and [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 1, classify the invocation).
- **Plan section** — [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (Invocation classification) and [feature-implementation-plan.md#testing-strategy](feature-implementation-plan.md#testing-strategy) (the four crafted-branch check cases).
- **Skill file** — [scripts/detect-driver-context.sh](../../../han-coding/skills/implement-work-items/scripts/detect-driver-context.sh) (the output-style and single-responsibility pattern to mirror).
- **Authoring guidance** — [hardening-fuzzy-vs-deterministic.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/hardening-fuzzy-vs-deterministic.md) and [script-execution-instructions.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/script-execution-instructions.md).

**Checks.**
- Behavioral check on crafted branches (there is no shell-test harness; these fixtures are the acceptance tests): (a) a branch carrying a matching run trailer → `resume`; (b) a branch with no trailer → `fresh`; (c) a branch with foreign commits and no trailer → `refuse`; (d) an equivalent-but-differently-spelled path against a matching record → `resume`.

**Acceptance criteria.**
- [ ] The script classifies resume / fresh / refuse correctly on the four crafted branches, including the path-normalization case.
- [ ] It reconstructs per-item states and done-entry commit-resolution status as structured output.
- [ ] It takes no judgment action; SKILL.md consumes its output.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `han-coding:tdd`, AFK. ``

**Suggested review.** `` `han-coding:code-review`, AFK. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/scripts/scan-run-history.sh`

**Depends on.** W-1.

## W-3 — Re-grounding routine and repointed references

**Type.** `deliverable`

**Summary.** Create `references/re-grounding-routine.md` holding the one core re-grounding routine, and repoint `foreground-handoff-protocol.md` and `human-review-capture.md` at it so all three in-session re-entry sites reuse the core without the cross-session go-ahead. See plan: D-4 (one core routine plus per-site wrapping; the go-ahead lives only at the cross-session site), D-3 (decomposition keeps SKILL.md under its ceiling), and [Runtime Behavior](feature-implementation-plan.md#runtime-behavior).

**Description.**
1. Define the core routine: reconstruct run state from the durable record; re-derive the dependency graph from the current work-items file; re-read the working tree; re-read the driver's own instructions, reloading if truncated (the extracted instruction-reload sub-step W-6 reuses at the commit boundary); and announce where the driver is before acting.
2. State that on a cross-session resume the core reconstructs `state.json` from the durable record and treats any surviving gitignored copy as untrusted; in-session the existing store is current.
3. Keep the cross-session go-ahead (D19) out of this core — it wraps only the cross-session site in SKILL.md (W-4), so the three in-session sites (foreground hand-off, human review, recovery-menu re-attempt) never spuriously pause. See plan: D-4.
4. Repoint `foreground-handoff-protocol.md` step 2 and `human-review-capture.md` step 6 from their inline/undefined re-ground text to a pointer at this routine, removing the partial inline definition.

**References.**
- **Spec section** — [feature-specification.md#resuming-a-partially-complete-run](feature-specification.md#resuming-a-partially-complete-run) (the re-grounding sequence), [feature-specification.md#resuming-an-interrupted-foreground-item](feature-specification.md#resuming-an-interrupted-foreground-item), and [feature-specification.md#coordinations](feature-specification.md#coordinations) (review records are ephemeral; resume re-reads fresh).
- **Plan section** — [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (Re-grounding).
- **Skill files** — [foreground-handoff-protocol.md](../../../han-coding/skills/implement-work-items/references/foreground-handoff-protocol.md) and [human-review-capture.md](../../../han-coding/skills/implement-work-items/references/human-review-capture.md) (the two consumers to repoint).
- **Authoring guidance** — [hardening-fuzzy-vs-deterministic.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/hardening-fuzzy-vs-deterministic.md) (the routine is judgment, so it stays prose).

**Checks.**
- Read-the-file conformance: the core routine is defined once; both consuming references point at it and carry no competing inline definition; the go-ahead appears nowhere in the shared core.

**Acceptance criteria.**
- [ ] `re-grounding-routine.md` defines the core routine including the instruction-reload sub-step and the reconstruct-from-record fork.
- [ ] `foreground-handoff-protocol.md` and `human-review-capture.md` point at the routine with no surviving partial inline definition.
- [ ] The cross-session go-ahead is not in the shared core.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/references/re-grounding-routine.md`
- `han-coding/skills/implement-work-items/references/foreground-handoff-protocol.md`
- `han-coding/skills/implement-work-items/references/human-review-capture.md`

**Depends on.** W-1.

## W-4 — SKILL.md Step 1: fresh/resume/refuse classification

**Type.** `deliverable`

**Summary.** Edit `SKILL.md` Step 1 so that, after branch resolution and before the clean-tree gate, the driver runs `scripts/scan-run-history.sh` and branches on its verdict: a present record resumes (via the cross-session re-grounding site, wrapped with the D19 go-ahead, resume summary, config restoration, and baseline re-establishment); an empty branch proceeds fresh; commits-but-no-record is refused as a foreign base, reworking today's blanket prior-run-branch refusal in Step 1.6. See plan: D-2, D-19, and [Runtime Behavior](feature-implementation-plan.md#runtime-behavior). First of the four chained SKILL.md edits.

**Description.**
1. Invoke `scripts/scan-run-history.sh` with the resolved work-items path (numbered prose, `${CLAUDE_SKILL_DIR}/scripts/...`), after branch resolution (Step 1.8) and before the clean-tree/green-suite gate (Step 1.5), so the classification runs before the gate that would otherwise refuse an in-progress item's expected dirty tree.
2. Branch on the verdict: **resume** enters the cross-session re-grounding site (W-3's core wrapped with the go-ahead, the resume summary, config restoration from the opening entry, and baseline re-establishment); **fresh** proceeds to setup (W-5); **refuse** halts with the foreign-base message, preserving today's guardrail against committing onto a foreign base.
3. Sequence the clean-tree gate to allow the single in-progress item's uncommitted work on a resume (the one allowed exception), and re-establish the verification baseline after inspecting/removing that work.
4. Keep the classification judgment in SKILL.md prose; the grep/scan is the script's job (hardening rule).

**References.**
- **Spec section** — [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (rows: re-invoke on a branch carrying the record → resume; branch carries commits but no record → refuse; record stripped by hand → fresh; recorded branch missing → surface-and-ask) and [feature-specification.md#resuming-a-partially-complete-run](feature-specification.md#resuming-a-partially-complete-run) (the go-ahead-before-mutate sequence).
- **Plan section** — [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (Invocation classification).
- **Skill file** — [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (Steps 1.5, 1.6, 1.8).
- **Authoring guidance** — [script-execution-instructions.md](../../../han-plugin-builder/skills/guidance/references/skill-building-guidance/script-execution-instructions.md).

**Checks.**
- Read-the-file conformance and scenario dry-run against the Edge Cases rows: a branch carrying this run's record resumes rather than refusing; a branch with foreign commits and no record refuses; a stripped record classifies fresh; a missing recorded branch surfaces-and-asks. The clean-tree gate no longer refuses the in-progress item's expected uncommitted work on a resume.

**Acceptance criteria.**
- [ ] The scan runs after branch resolution and before the clean-tree gate, and the invocation is numbered prose with a `${CLAUDE_SKILL_DIR}` path.
- [ ] Resume / fresh / refuse each route correctly, and the foreign-base refusal is preserved for the commits-but-no-record case.
- [ ] The clean-tree gate allows the in-progress item's uncommitted work on a resume.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-2.

## W-5 — SKILL.md Step 2.2: fresh/resume fork, un-ignore, atomic opening entry

**Type.** `deliverable`

**Summary.** Edit `SKILL.md` Step 2.2 so setup forks on the Step-1 verdict: a fresh run changes the `.implement-work-items/.gitignore` from `*` to `*` then `!progress.md` and records the atomic opening entry co-committed with the planning-artifacts commit; a resume skips fresh setup. The opening-entry commit exercises the repo's hook path at plan-confirmation. See plan: D-1, D-10, and [Data Model and Persistence](feature-implementation-plan.md#data-model-and-persistence). Second of the four chained SKILL.md edits.

**Description.**
1. Fork Step 2.2 on the Step-1 verdict: on **fresh**, run the full setup; on **resume**, switch to the existing branch and skip branch creation, the planning-artifacts commit, and the opening-entry write.
2. In fresh setup, change the `.implement-work-items/.gitignore` the step writes from a single line `*` to `*` followed by `!progress.md`, so `progress.md` is tracked while `state.json` and the review records stay ignored. See plan: D-1.
3. Record the opening entry (run configuration plus the normalized work-items path) into `progress.md` and stage it into the **same** commit as the planning artifacts, so a failed opening leaves an empty (fresh) branch rather than a foreign base. See plan: D-10.
4. Rely on that opening-entry commit as the de-facto hook probe: a strict-hook repo fails at plan-confirmation (the existing Step 2.2 "report exactly what failed and stop"), so no separate read-only probe is built (Deferred YAGNI).

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 2, set up a fresh run) and [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (row: opening run entry fails to record → run stops, re-invocation starts fresh).
- **Plan section** — [feature-implementation-plan.md#data-model-and-persistence](feature-implementation-plan.md#data-model-and-persistence) (the `!progress.md` un-ignore and the opening-entry co-commit).
- **Skill files** — [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (Step 2.2) and [durable-record-protocol.md](../../../han-coding/skills/implement-work-items/references/durable-record-protocol.md) (opening-entry schema).

**Checks.**
- Scenario dry-run: on a fresh run the gitignore carries `!progress.md` and the opening entry lands in the planning-artifacts commit; a simulated opening-entry rejection leaves an empty branch that re-invocation classifies fresh, not a foreign base; on a resume the fresh-setup steps are skipped.

**Acceptance criteria.**
- [ ] Step 2.2 forks fresh vs resume and skips fresh setup on a resume.
- [ ] The `.gitignore` becomes `*` + `!progress.md`, and the opening entry is co-committed atomically with the planning artifacts.
- [ ] A failed opening entry leaves a fresh-classifiable branch (no foreign-base dead end).

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-1, W-4.

## W-6 — SKILL.md Step 3: start-of-item entry, record-the-item-done routine, bookkeeping-failure path

**Type.** `deliverable`

**Summary.** Edit `SKILL.md` Step 3 to bracket each item durably (a start-of-item entry replacing today's in-session `scope-baseline`), run the shared record-the-item-done routine on the item clearing (an unconditional re-Read commit-boundary self-check, then an output/no-output fork with a positional reference, the `Implement-Work-Items-Item` trailer, and code-commit-before-done-entry ordering), and route every progress-record write through one shared bookkeeping-entry routine whose failure branch is the marker-write class, never the code fix loop. See plan: D-5, D-6, D-7, D-8, D-9, and [Runtime Behavior](feature-implementation-plan.md#runtime-behavior). Third of the four chained SKILL.md edits.

**Description.**
1. Record a start-of-item entry to `progress.md` before any build; use its commit as the item's changed-file-set baseline, replacing today's in-session `scope-baseline` reference.
2. On the item clearing its gate, run one shared record-the-item-done routine whose first line is an **unconditional** re-Read of the relevant step(s) — the commit-boundary self-check that bounds a compaction-truncated driver to the in-progress item (never a "reload if it seems truncated" judgment). See plan: D-7.
3. Fork inside that routine: an output item commits (the code commit strictly preceding the done entry, carrying the `Implement-Work-Items-Item: W-N` trailer) and records a positional done entry computed at report time; a no-output item delegates to `no-output-completion.md` (W-8). See plan: D-8, D-9.
4. Route every progress-record write (opening, start, done, no-commit-done, skip) through one shared bookkeeping-entry routine whose failure branch is the Halt Procedure marker-write class — surface-and-stop, resumable — never the Step 3.4 code fix loop. See plan: D-6.
5. Confirm Step 3.4's stage-by-path keeps `.implement-work-items/progress.md` out of the item's code commit (exclusion site #1 of four, verified in W-9).

**References.**
- **Spec section** — [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (rows: output committed but done entry did not → forward-reconcile; no-output audit's outcome did not record → re-run and re-confirm; a later progress entry fails to record → surface-and-stop resumably; hooks reject a bookkeeping commit → distinct class; mid-run compaction truncates instructions → commit-boundary self-check) and [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 3 and 5).
- **Plan section** — [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (Commit boundary, Bookkeeping failure).
- **Skill files** — [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (Steps 3.1, 3.3, 3.4), [re-grounding-routine.md](../../../han-coding/skills/implement-work-items/references/re-grounding-routine.md) (the instruction-reload sub-step reused here), and [durable-record-protocol.md](../../../han-coding/skills/implement-work-items/references/durable-record-protocol.md).

**Checks.**
- Scenario dry-run against the Edge Cases rows: a committed-but-unmarked item forward-reconciles rather than double-commits; a rejected bookkeeping commit surfaces-and-stops rather than entering the fix loop; the commit-boundary re-Read is unconditional and covers both the commit and no-commit-done paths.

**Acceptance criteria.**
- [ ] A start-of-item entry is recorded before the build and is the item's changed-file baseline.
- [ ] The shared record-the-item-done routine re-Reads unconditionally and forks output vs no-output, with the code commit preceding the done entry and carrying the item-id trailer.
- [ ] Bookkeeping-write failure is surface-and-stop, never the fix loop.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-1, W-3, W-5.

## W-7 — SKILL.md alternate flows, recovery menu, and AFK-only forward-reconcile

**Type.** `deliverable`

**Summary.** Edit `SKILL.md` to add the resume alternate-flow sections with forward-reconcile routed AFK-only (an interrupted foreground item goes to re-verify/re-review before forward-reconcile, and forward-reconcile is gated by a positive-classification test reusing the existing scope computation), and rework the Halt Procedure's fifth part from the "no resume" dead-end into the in-session recovery menu plus the ledger-and-history-disagree default-deny handling. See plan: D-5, and [Runtime Behavior](feature-implementation-plan.md#runtime-behavior). Fourth and final chained SKILL.md edit; carries the definitive 500-line-ceiling check.

**Description.**
1. Add the alternate-flow sections: resuming a partially complete run, resuming an in-progress item, and resuming an interrupted foreground item.
2. Route forward-reconcile **AFK-only**: an interrupted foreground item is sent to re-verify/re-review before forward-reconcile is reached, and forward-reconcile is gated by a positive-classification test that reuses the existing scope computation — the start-of-item-to-HEAD changed-file set must be within scope and the tree clean — so a foreground pre-gate commit or a foreign in-range commit is surfaced-and-asked, never silently marked done. See plan: D-5. This implements D11 default-deny on the forward-reconcile path and does not reopen the deferred dedicated range check.
3. Rework the Halt Procedure's fifth part into the in-session recovery menu: fix-in-place-and-re-attempt, run-more-fix-rounds, skip-this-item (naming the stranded dependents before the choice), and stop-the-run (resumable). Add the ledger-and-history-disagree default-deny handling with the uniform, consequence-labeled option set.
4. Keep the tree-state disclosure and completed-items references distinguishing committed completions from no-commit completions (a no-output audit is recorded, not in the commit range).

**References.**
- **Spec section** — [feature-specification.md#a-run-reaches-a-state-it-cannot-settle](feature-specification.md#a-run-reaches-a-state-it-cannot-settle), [feature-specification.md#operator-fixes-an-issue-and-re-attempts](feature-specification.md#operator-fixes-an-issue-and-re-attempts), [feature-specification.md#resuming-an-in-progress-item](feature-specification.md#resuming-an-in-progress-item), [feature-specification.md#resuming-an-interrupted-foreground-item](feature-specification.md#resuming-an-interrupted-foreground-item), [feature-specification.md#ledger-and-history-disagree-on-resume](feature-specification.md#ledger-and-history-disagree-on-resume), and the relevant [Edge Cases](feature-specification.md#edge-cases-and-failure-modes) rows (in-progress uncommitted work; cannot positively classify → surface; foreign in-range commit → scope finding; skip with uncommitted work; skip with dependents; red baseline; re-attempt after fix; stop the run).
- **Plan section** — [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (Forward-reconcile, Halt).
- **Skill files** — [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (Halt Procedure) and [re-grounding-routine.md](../../../han-coding/skills/implement-work-items/references/re-grounding-routine.md).

**Checks.**
- Highest-value scenario dry-run: an interrupted foreground item routes to re-review before forward-reconcile; an AFK item with a foreign in-range commit is surfaced rather than marked done; the halt shows the recovery menu (not "start a fresh branch"); the stop label names no-output completions separately. Full-file line count stays under the 500-line ceiling.

**Acceptance criteria.**
- [ ] Forward-reconcile applies only to AFK items, after the foreground branch, gated by the reused scope diff.
- [ ] The Halt Procedure's fifth part is the recovery menu, and ledger-disagreement uses the uniform default-deny option set.
- [ ] SKILL.md stays under the 500-line progressive-disclosure ceiling (push mechanics to a reference if needed, never trim behavior). See plan: D-3.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-3, W-6.

## W-8 — no-output-completion.md durable no-commit-done write

**Type.** `deliverable`

**Summary.** Edit `references/no-output-completion.md` so completing a no-output `audit` writes the durable no-commit-done outcome to the ledger, ordered durable-record-first then `state.json`, with the minimal entry fields. Preserve the existing clean-tree assertion as exclusion site #4 and the safe-to-re-run guarantee. See plan: D-12 (durable-record-first ordering), D-13 (minimal fields), and [Data Model and Persistence](feature-implementation-plan.md#data-model-and-persistence).

**Description.**
1. In the no-output completion step, add the durable no-commit-done write to `progress.md` before the `state.json` update, so the branch-durable record is authoritative and `state.json` is the reconstructable follower. See plan: D-12.
2. Record the no-commit-done entry with minimal fields (no `Type` field; distinguished by its entry token). See plan: D-13.
3. Apply the same durable-record-first write at the recovery re-attempt Exit for a no-output audit that clears (no spurious commit).
4. Preserve the existing clean-tree assertion (only `.implement-work-items/` allowed) as exclusion site #4, and restate the safe-to-re-run guarantee grounded in the catalog's side-effect-free-audit constraint rather than building an idempotency guard.

**References.**
- **Spec section** — [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (row: a no-output audit ran but its no-commit done outcome did not record → re-run the side-effect-free audit, re-ask, then record) and [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 5, the no-commit done outcome).
- **Plan section** — [feature-implementation-plan.md#data-model-and-persistence](feature-implementation-plan.md#data-model-and-persistence) (durable-record-first ordering).
- **Skill files** — [no-output-completion.md](../../../han-coding/skills/implement-work-items/references/no-output-completion.md) and [durable-record-protocol.md](../../../han-coding/skills/implement-work-items/references/durable-record-protocol.md) (the no-commit-done entry schema).

**Checks.**
- Read-the-file conformance and scenario dry-run: the durable write precedes the `state.json` write; the entry carries no `Type` field; the clean-tree assertion survives; a no-output audit whose outcome did not record re-runs and re-confirms rather than being rebuilt as partial or spuriously committed.

**Acceptance criteria.**
- [ ] Completing a no-output audit writes the durable no-commit-done outcome before `state.json`.
- [ ] The entry uses minimal fields, and the clean-tree assertion (exclusion site #4) is preserved.
- [ ] The safe-to-re-run guarantee is restated, with no idempotency guard added.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/references/no-output-completion.md`

**Depends on.** W-1.

## W-9 — Exclusion verification across the four sites

**Type.** `deliverable`

**Summary.** Add the exclusion to `references/human-review-capture.md` (the one site the plan flags to confirm) so the human-review pointer no longer surfaces the now-tracked `progress.md` as a scope finding, and verify `.implement-work-items/progress.md` is kept out of all four scope/stage/human-review/no-output computations. See plan: D-11 (the exclusion checklist), and [Data Model and Persistence](feature-implementation-plan.md#data-model-and-persistence).

**Description.**
1. Because W-5 makes `progress.md` tracked, edit `human-review-capture.md` where it points a human reviewer at "everything since scope-baseline, committed or not" to exclude `.implement-work-items/`, mirroring the exclusion `review-verdict-contract.md` already applies on the agent path, so the ledger commit is not misread as a scope finding.
2. Verify the other three sites keep `progress.md` out: SKILL.md 3.4 stage-by-path (W-6), the `review-verdict-contract.md` scope diff (already excludes `.implement-work-items/` — verify only), and the `no-output-completion.md` clean-tree assertion (W-8).

**Note on scope boundary with W-6 and W-8.** The SKILL.md staging exclusion is authored in W-6 and the no-output clean-tree assertion in W-8; this item verifies them and owns only the `human-review-capture.md` edit. If inspection finds the human-review pointer already excludes the record with no wording change needed, this item collapses to a checks-only `audit` (no file change).

**References.**
- **Spec section** — [feature-specification.md#coordinations](feature-specification.md#coordinations) (the record is never staged into an item's code commit and never counted as a scope finding).
- **Plan section** — [feature-implementation-plan.md#data-model-and-persistence](feature-implementation-plan.md#data-model-and-persistence) (the exclusion sites) and the Definition of Done exclusion criterion.
- **Skill files** — [human-review-capture.md](../../../han-coding/skills/implement-work-items/references/human-review-capture.md) (the edit), [review-verdict-contract.md](../../../han-coding/skills/implement-work-items/references/review-verdict-contract.md) (verify-only), [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (verify 3.4), [no-output-completion.md](../../../han-coding/skills/implement-work-items/references/no-output-completion.md) (verify clean-tree), and [durable-record-protocol.md](../../../han-coding/skills/implement-work-items/references/durable-record-protocol.md) (the checklist).

**Checks.**
- Named checks confirm `.implement-work-items/progress.md` appears in no scope diff, no stage set, no human-review scope pointer, and no no-output clean-tree consideration across the four sites.

**Acceptance criteria.**
- [ ] `human-review-capture.md` excludes `.implement-work-items/` from the human reviewer's change view.
- [ ] All four exclusion sites are verified to keep `progress.md` out.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `general-purpose` agent, AFK. ``

**Suggested review.** `` none, HITL. ``

**Expected paths.**
- `han-coding/skills/implement-work-items/references/human-review-capture.md`

**Depends on.** W-3, W-6, W-8.

## W-10 — Operator doc rewrite

**Type.** `deliverable`

**Summary.** Rewrite the three inverted passages in `docs/skills/han-coding/implement-work-items.md` (lines 20, 72, 83) to describe the shipped behavior — cross-session resume after a go-ahead, the in-session recovery menu, and re-grounding on every re-entry — and correct the YAGNI deferred list. See plan: D-3, D-4, D-5, and [Outcome](feature-implementation-plan.md#outcome).

**Description.**
1. Rewrite line 20 ("the driver has no interactive recovery menu" / "halt the whole run") to describe the in-session recovery menu at a halt.
2. Rewrite the "In more detail" region at lines 72 and 83 ("single-pass with no resume", "the halt posture is deliberately absolute") to describe cross-session resume from the first unfinished item after an operator go-ahead, and the durable branch ledger replacing the single-pass gitignored store.
3. Correct the YAGNI deferred list: cross-session resume and the recovery menu move out of "deferred"; compaction survival, concurrent drivers, edited-done-item detection, a richer menu, and history cleanup stay deferred.
4. Follow the writing voice (no em-dashes, direct second person) and keep the operator doc's structure.

**References.**
- **Spec section** — [feature-specification.md#outcome](feature-specification.md#outcome), [feature-specification.md#out-of-scope](feature-specification.md#out-of-scope), and [feature-specification.md#deferred-yagni](feature-specification.md#deferred-yagni) (what stays deferred).
- **Plan section** — [feature-implementation-plan.md#outcome](feature-implementation-plan.md#outcome).
- **Skill file** — the final [SKILL.md](../../../han-coding/skills/implement-work-items/SKILL.md) (the behavior the doc must describe).

**Note on subsystem capability.** `content-auditor` compares the rewrite against the prior version of the doc to confirm no fact was lost and no inverted passage survives; provide the prior version as its comparison reference in the dispatch.

**Checks.**
- Read against the spec and the final SKILL.md: no surviving "no resume" / "absolute halt" / "no interactive recovery menu" claim; the deferred list matches the spec's Out of Scope and Deferred sections; `content-auditor` confirms no important fact was dropped.

**Acceptance criteria.**
- [ ] The three inverted passages (lines 20/72/83) describe the shipped resume, recovery-menu, and re-grounding behavior.
- [ ] The YAGNI deferred list is corrected to the current deferred set.
- [ ] `content-auditor` finds no lost fact and no surviving inverted claim.

**Requires pre-work decisions.** `no`.

**Suggested implementation.** `` `han-core:project-documentation`, AFK. ``

**Suggested review.** `` `han-core:content-auditor` agent, AFK. ``

**Expected paths.**
- `docs/skills/han-coding/implement-work-items.md`

**Depends on.** W-1, W-2, W-3, W-4, W-5, W-6, W-7, W-8, W-9.
