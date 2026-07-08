# Work Items — implement-work-items First-Run Hardening

These work items break the [feature-implementation-plan.md](feature-implementation-plan.md) into vertical slices that harden the `implement-work-items` skill. Each item is a narrow, independently verifiable change to the skill's `SKILL.md`, one of its `references/*.md`, or one of its `scripts/*.sh`.

Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file.

## Shared reference artifacts

- **Behavioral spec** — [feature-specification.md](feature-specification.md): the ground truth for what each change must do. Each item cites the specific sections it realizes.
- **Plugin-authoring guidance** — `han-plugin-builder/skills/guidance/references/skill-building-guidance/`: reference material for every `SKILL.md` and `references/*.md` edit (progressive disclosure, the 500-line ceiling, the fuzzy-vs-deterministic boundary). It is reference material for the implementer, never the implementer itself.

---

## W-1 — Pin the collapsed record and four-trailer contract in durable-record-protocol.md

**Type.** `deliverable`

**Summary.** Rewrite `durable-record-protocol.md` as the single format authority so every consumer conforms to one contract: the shell-parseable line grammar with no JSON and no hard `jq`/`python3` (See plan: D-1); `state.json` deleted with `scope-baseline` recovered from a distinct baseline trailer (See plan: D-2); new durable-state blocks appended below a byte-for-byte-preserved `Log:` block (See plan: D-3); the four exact-key commit trailers (See plan: D-8); the `.gitignore` hack dropped and the whole artifact area tracked (See plan: D-9); the plan-folder-derived, relocated path with an exclusion that matches at any depth (See plan: D-10); this file absorbing the format, commit model, and re-grounded exclusion rather than a new reference (See plan: D-15).

**Description.**
1. Rewrite the Format section: the labeled config block plus one `- <token>: <W-N>` line per `Log:` entry (the four tokens `start-of-item`/`done`/`no-commit-done`/`skip` unchanged), then separate labeled blocks below it for D9 corrections, D7 coherence approvals, and D6 below-threshold dispositions — each append-only and parsed independently.
2. Specify the four exact-key trailers: `Implement-Work-Items-Item` on code commits only, `Implement-Work-Items-Run` on bookkeeping commits, `Implement-Work-Items-Fixup` on review-addressing collapsible commits, and a distinct baseline trailer (name it) on the start-of-item commit for `scope-baseline` recovery.
3. State that `state.json` is deleted: name which former fields are session-ephemeral and how `scope-baseline` is recovered from the baseline trailer.
4. Re-ground the Exclusion section on path-based exclusion — the area is committed bookkeeping, excluded from code commits and scope by path, matched at any depth — and record the relocated, `dirname`-derived path.
5. Remove the `.gitignore` two-line rule from the protocol's description.

**References.**
- Current `han-coding/skills/implement-work-items/references/durable-record-protocol.md` (the file being rewritten).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) step 3, [feature-specification.md#coordinations](feature-specification.md#coordinations) (the run-branch row).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Read-the-file conformance: the Format, trailer, and Exclusion sections match D-1/D-2/D-3/D-8/D-9/D-10 with no residual `state.json` or `.gitignore` language, and the four downstream consumers (W-2 writer, W-3 reader, W-6 exclusion sites, W-8 setup) can be built against it without inventing format details.

**Acceptance criteria.**
- [ ] The record format, the three new blocks, and the four trailers are specified concretely enough to build the writer and reader without inventing details.
- [ ] No `state.json` or `.gitignore`-hack language remains; the exclusion is path-based and matches at any depth.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/references/durable-record-protocol.md`

**Depends on.** None.

## W-2 — New write-run-record.sh bookkeeping writer script

**Type.** `deliverable`

**Summary.** Add the one append-only, mechanism-only writer that formats and appends record lines and blocks per the W-1 grammar and never makes a proceed/discard judgment; it fails loud (non-zero exit, no partial write) so a partial write is never staged (See plan: D-4, D-17).

**Description.**
1. Test-first: write pure-bash tests (assuming only `git`+bash) asserting that `init`, `append <token> <W-N>`, and `set-state`-style operations emit grammar-correct lines and blocks per W-1.
2. Implement `write-run-record.sh` following the existing deterministic-detector precedent: line-oriented, no judgment (the caller decides which token; the script decides only how it is spelled), and no `git commit` inside the script.
3. Make every write fail loud: a malformed argument or a partial write exits non-zero and leaves nothing staged.

**Note on scope boundary with W-3.** The writer↔reader round-trip harness lives in W-3 (it needs both scripts); W-2's own tests assert the writer's output shape in isolation.

**References.**
- The W-1 record grammar in `han-coding/skills/implement-work-items/references/durable-record-protocol.md`.
- Existing pure-bash precedent `han-coding/skills/implement-work-items/scripts/detect-driver-context.sh`.
- Plan: [feature-implementation-plan.md#testing-strategy](feature-implementation-plan.md#testing-strategy), On-Call Resilience Posture (data-integrity bullet).

**Checks.**
- Bash unit tests in a throwaway environment: each operation emits the exact grammar; a bad input exits non-zero with no partial write.

**Acceptance criteria.**
- [ ] `write-run-record.sh` emits grammar-correct lines/blocks for every operation, verified by tests.
- [ ] A malformed input fails loud (non-zero exit, nothing staged); no `jq`/`python3` is used.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `han-coding:tdd`, AFK

**Suggested review.** `han-coding:code-review`, AFK

**Expected paths.**
- `han-coding/skills/implement-work-items/scripts/write-run-record.sh`
- `han-coding/skills/implement-work-items/scripts/tests/write-run-record.test.sh` *(low-confidence path — the plan names the harness only as "e.g. `scripts/tests/`"; confirm the test location/naming)*

**Depends on.** W-1.

## W-3 — Extend scan-run-history.sh for derived path, new-block parse, done-from-ledger, and the round-trip harness

**Type.** `deliverable`

**Summary.** Derive the ledger path from `dirname(NORM_PATH)` with no new argument (See plan: D-10); parse the new appended blocks additively without touching the shipped four-token item-lifecycle regex (See plan: D-3); make the committed `done` entry the sole completion signal on the scan side (See plan: D-7, D-16); and add the pure-bash round-trip harness proving the writer's output reconstructs to the exact lifecycle. Preserve `--end-of-options` operand-pinning and exact-key trailer matching (See plan: D-19).

**Description.**
1. Test-first: add the writer↔reader round-trip harness — `write-run-record.sh` output parsed by `scan-run-history.sh` reconstructs the exact four-token lifecycle, and the new blocks do not perturb that reconstruction — plus classification tests (fresh/resume/refuse/no-base) and the boundary cases (empty ledger, foreign-run trailer, unresolved `done`, a `..`/`./` path, the W-1-vs-W-10 substring trap).
2. Derive the ledger path from `dirname(NORM_PATH)` inside the script; do not add an argument.
3. Add additive parsers for the new blocks; leave the four-token `Log:` regex byte-for-byte unchanged.
4. Ensure per-item `done` is reported from the ledger entry, never from commit presence, and keep the injection defenses (`--end-of-options`, exact-key trailers) intact.

**References.**
- Current `han-coding/skills/implement-work-items/scripts/scan-run-history.sh` (the file being extended).
- The W-1 grammar in `han-coding/skills/implement-work-items/references/durable-record-protocol.md`.
- Plan: [feature-implementation-plan.md#testing-strategy](feature-implementation-plan.md#testing-strategy), RAID R1/R2.

**Checks.**
- Bash tests in throwaway git repos: the round-trip passes; classification and boundary cases pass; the derived path resolves under a nested plan folder; `done` is read from the ledger only.

**Acceptance criteria.**
- [ ] The round-trip harness passes and the new blocks do not perturb the four-token reconstruction.
- [ ] The ledger path is derived from the work-items path; `done` comes from the ledger; the substring and `..`/`./` cases pass.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `han-coding:tdd`, AFK

**Suggested review.** `han-coding:code-review`, AFK

**Expected paths.**
- `han-coding/skills/implement-work-items/scripts/scan-run-history.sh`
- `han-coding/skills/implement-work-items/scripts/tests/scan-run-history.test.sh` *(low-confidence path — confirm the test location/naming)*

**Depends on.** W-1, W-2.

## W-4 — Extend detect-driver-context.sh with ahead/behind counts and a fetch-status flag

**Type.** `deliverable`

**Summary.** Emit per-candidate ahead/behind via `git rev-list --left-right --count <base>...HEAD` and a `fetch-status: ok|failed` line, keeping the detector read-only (the `git fetch` stays in `SKILL.md`); cover in-sync / ahead / diverged / detached-HEAD / fetch-failure (See plan: D-11). Preserve the existing git-injection defenses (See plan: D-19).

**Description.**
1. Test-first: pure-bash tests in throwaway git repos across in-sync, ahead, diverged (both), detached-HEAD, and fetch-failure, asserting the emitted `key: value` lines.
2. Add ahead/behind computation per candidate in the fixed candidate set via `git rev-list --left-right --count`, emitted as marker-block or `key: value` lines.
3. Emit `fetch-status: ok|failed` computed from already-fetched remote-tracking refs; do not run `git fetch` in the detector.
4. Keep the detector read-only and preserve `--end-of-options`/operand-pinning so a branch name or path cannot be parsed as a git option.

**References.**
- Current `han-coding/skills/implement-work-items/scripts/detect-driver-context.sh` (the file being extended).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) step 1, [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (the base-resolution rows).
- Plan: [feature-implementation-plan.md#runtime-behavior](feature-implementation-plan.md#runtime-behavior) (D-11), Testing Strategy.

**Checks.**
- Bash tests across the five base scenarios assert the emitted ahead/behind and `fetch-status` lines; the detector performs no network write.

**Acceptance criteria.**
- [ ] The detector emits correct ahead/behind and `fetch-status` for in-sync, ahead, diverged, detached, and fetch-failure.
- [ ] The detector stays read-only and preserves the injection defenses; no new tool dependency is added.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `han-coding:tdd`, AFK

**Suggested review.** `han-coding:code-review`, AFK

**Expected paths.**
- `han-coding/skills/implement-work-items/scripts/detect-driver-context.sh`
- `han-coding/skills/implement-work-items/scripts/tests/detect-driver-context.test.sh` *(low-confidence path — confirm the test location/naming)*

**Depends on.** None.

## W-5 — New sub-agent-instructions.md reference with role-scoped payloads and accumulated corrections

**Type.** `deliverable`

**Summary.** Add the one outbound-dispatch reference holding the shared baseline instruction set plus the role-scoped build and review payloads, with D9's accumulated-corrections injection rules folded in — general corrections accumulate, item-specific one-offs do not, and the item's own instruction wins on conflict — rather than a standalone `preference-memory.md` (See plan: D-14).

**Description.**
1. Write the shared baseline section common to every dispatch, then a build-payload subsection (follow the implementation-skill guidance, accumulated corrections, prior-round residual findings) and a review-payload subsection (follow the review-skill guidance, already-approved coherence paths; corrections passed only as judging context, not as review criteria).
2. Fold in D9's injection rules: general corrections accumulate within the run and inject into later build payloads; item-specific one-off corrections are not accumulated; an item's own instruction wins for that item.
3. Cross-reference the existing return contracts (`build-report-contract.md`, `review-verdict-contract.md`) as the inbound counterparts.

**References.**
- Existing sibling contracts `han-coding/skills/implement-work-items/references/build-report-contract.md` and `references/review-verdict-contract.md`.
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) steps 4-5, [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (accumulated-correction-vs-item-instruction row).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Read-the-file conformance: build and review payloads are distinct, the corrections precedence rules are unambiguous, and W-9 can wire dispatch to this file without restating the instructions inline.

**Acceptance criteria.**
- [ ] The reference specifies a shared baseline plus distinct build and review payloads and the D9 corrections precedence rules.
- [ ] No standalone `preference-memory.md` is created; the corrections storage points at the record block (W-1).

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/references/sub-agent-instructions.md`

**Depends on.** None.

## W-6 — Relocate the prose exclusion sites to match at any depth and drop the dead state.json section

**Type.** `deliverable`

**Summary.** Update the three prose exclusion sites so the relocated, nested artifact dir is excluded at any depth rather than root-anchored — the scope-diff exclusion in `review-verdict-contract.md`, the reviewer pointer in `human-review-capture.md`, and the clean-tree assertion in `no-output-completion.md` (See plan: D-9, D-10) — and delete the now-dead `state.json` "State store" section from `re-grounding-routine.md` so re-grounding reconstructs only from the committed ledger (See plan: D-15, D-2). The fourth exclusion site (SKILL.md Step 3.4 stage-by-path) lands in W-9.

**Description.**
1. In each of the three exclusion sites, change the `.implement-work-items/` match from root-anchored to at-any-depth so the nested artifact dir is still excluded from scope findings and code commits.
2. Delete the `state.json`/"treat as untrusted, rebuild it" section from `re-grounding-routine.md`; state that re-grounding reconstructs from the committed ledger alone.
3. Keep the changes consistent with the W-1 Exclusion contract.

**References.**
- Current `references/review-verdict-contract.md`, `references/human-review-capture.md`, `references/no-output-completion.md`, `references/re-grounding-routine.md` (all under `han-coding/skills/implement-work-items/`).
- The Exclusion section of `references/durable-record-protocol.md` as revised in W-1.
- Spec: [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states); Plan RAID R2.

**Checks.**
- Read-the-file conformance: all three exclusion patterns match the dir at any depth; no `state.json` language remains in `re-grounding-routine.md`.

**Acceptance criteria.**
- [ ] The three prose exclusion sites match `.implement-work-items/` at any nesting depth.
- [ ] The `state.json` section is gone from `re-grounding-routine.md`.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/references/review-verdict-contract.md`
- `han-coding/skills/implement-work-items/references/human-review-capture.md`
- `han-coding/skills/implement-work-items/references/no-output-completion.md`
- `han-coding/skills/implement-work-items/references/re-grounding-routine.md`

**Depends on.** W-1.

## W-7 — Extend review-verdict-contract.md for below-threshold detail, prior-iteration diff, and approved-coherence paths

**Type.** `deliverable`

**Summary.** Extend the review contract so the review reads below-threshold finding detail from the durable record (not counts alone), diffs the latest committed iteration against a defined prior iteration, and receives already-approved coherence paths so it does not re-raise them as fresh scope findings (See plan: D-12).

**Description.**
1. Add the below-threshold detail read: the review consults the durable record for the detail behind below-threshold counts.
2. Define the prior-iteration diff: name the "prior" reference (the previous committed iteration) the review compares the latest committed iteration against.
3. Add the already-approved-coherence-paths input so an approved sibling-file edit is not re-raised.

**Note on scope boundary with W-6.** W-6 changes this file's exclusion pattern; W-7 changes its review inputs/outputs. W-7 is chained after W-6 for shared-file safety.

**References.**
- Current `han-coding/skills/implement-work-items/references/review-verdict-contract.md` (as revised in W-6).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) steps 5 and 7, [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (approved-coherence-edit-in-a-later-round row).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Read-the-file conformance: the contract names the record read, the defined prior ref, and the approved-paths input unambiguously enough for W-9/W-12 to wire the dispatch.

**Acceptance criteria.**
- [ ] The contract reads below-threshold detail from the record, defines the prior-iteration diff ref, and accepts approved-coherence paths.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/references/review-verdict-contract.md`

**Depends on.** W-1, W-6.

## W-8 — SKILL.md setup rewrite: wire the collapsed record, delete state.json, drop the .gitignore step, use the relocated path

**Type.** `deliverable`

**Summary.** Rewrite Step 2.2 to write the opening entry via `write-run-record.sh` and commit it per the revised protocol; delete the `state.json` initialization and every `state.json` reference in Steps 2.2/3.1/3.2, replacing durable reads with session-local state plus the committed record; remove the `.gitignore`-writing sub-step so the whole artifact area is tracked (See plan: D-9); and point setup at the `dirname`-derived, relocated artifact path (See plan: D-1, D-2, D-10). Keep `SKILL.md` under its 500-line ceiling (See plan: D-14).

**Description.**
1. Rewrite Step 2.2 to create the artifact area inside the plan folder (derived path), write the opening entry via `write-run-record.sh`, and drop the `.gitignore`-writing sub-step.
2. Delete the `state.json` init and replace `state.json` reads/writes in Steps 2.2/3.1/3.2 with session-local state plus the committed record.
3. Keep the step prose lean (extract to references where needed) so `SKILL.md` stays under 500 lines.

**Note on scope boundary with W-9/W-10.** W-8 owns setup (Step 2.2) and the `state.json` removal in early steps; the per-item loop (3.3/3.4) is W-9 and resume (2.3) is W-10. W-8 is the first link in the SKILL.md chain.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Steps 2.2, 3.1, 3.2).
- Revised `references/durable-record-protocol.md` (W-1) and `scripts/write-run-record.sh` (W-2).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) step 3, [feature-specification.md#user-interactions](feature-specification.md#user-interactions).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Read-the-file conformance: setup writes via the script, no `state.json` reference remains, no `.gitignore` step remains, and the artifact path is the derived plan-folder location; `SKILL.md` line count is under 500.

**Acceptance criteria.**
- [ ] Step 2.2 uses `write-run-record.sh`, the derived path, and no `.gitignore` step; no `state.json` reference remains in Steps 2.2/3.1/3.2.
- [ ] `SKILL.md` remains under the 500-line ceiling.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-1, W-2, W-3.

## W-9 — SKILL.md per-item loop rewrite: commit cadence, pre-dispatch commit class, re-verify-fails, role-scoped dispatch

**Type.** `deliverable`

**Summary.** Rewrite Steps 3.3/3.4 as a commit-before-every-dispatch, commit-every-iteration loop that stages by path and keeps the terminal ledger entry the last write per item (See plan: D-5, D-7); classify a rejected pre-dispatch commit as a marker-write / resumable stop distinguished from a clean-tree no-op via `git status --porcelain`, never the fix loop (See plan: D-6); add the D6 re-verify-fails branch that resets to the committed gate-cleared iteration and never carries a dirty tree forward (See plan: D-13); land the Step 3.4 stage-by-path exclusion site; and wire the build/review dispatch and the D9 corrections-capture step to `sub-agent-instructions.md` (See plan: D-14).

**Description.**
1. Insert an explicit "commit any in-flight work, then dispatch" step at every dispatch site (build, fix re-dispatch, review, recovery "Build further", foreground return), pinned commit → dispatch, staging by path.
2. Commit every iteration; keep the terminal ledger entry the last write per item, committed after the code commit; classify a rejected pre-dispatch commit as a resumable marker-write stop, using `git status --porcelain` to tell a clean-tree no-op from a hook rejection.
3. Add the re-verify-fails branch (reset to the committed gate-cleared iteration or route to the fix loop; never carry a dirty tree forward).
4. Land the Step 3.4 stage-by-path exclusion site; wire build/review dispatch and the corrections-capture step to `sub-agent-instructions.md`; remove remaining `state.json` references.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Steps 3.3, 3.4, Halt Procedure).
- Revised `references/durable-record-protocol.md`, `references/sub-agent-instructions.md`, `references/review-verdict-contract.md`.
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) steps 4-8, [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (sub-agent-restores-to-committed-state row).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Read-the-file conformance plus a dry-run trace: every dispatch commits first; a rejected pre-dispatch commit stops resumably (not the fix loop); the terminal entry is last; dispatch reads from `sub-agent-instructions.md`.

**Acceptance criteria.**
- [ ] Every dispatch site commits in-flight work first; iterations are committed; the terminal ledger entry is the last write per item.
- [ ] A rejected pre-dispatch commit is a resumable stop; the re-verify-fails branch never carries a dirty tree forward; dispatch is wired to `sub-agent-instructions.md`.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-2, W-5, W-7, W-8.

## W-10 — SKILL.md resume done-authority

**Type.** `deliverable`

**Summary.** Make the committed `done` entry the sole resume completion authority: fold the old "item-id commit + clean tree ⇒ cleared" forward-reconcile shortcut into re-verify so an unverified committed iteration is re-verified rather than marked done, and reconstruct run state from the committed ledger only (See plan: D-7).

**Description.**
1. Remove the forward-reconcile shortcut in the resume path (Step 2.3, "Resuming an in-progress item") and fold it into re-verify-then-record.
2. State that only a committed `done` entry means done; commit presence never implies cleared.
3. Reconstruct run state from the committed ledger (Step 1.7 / re-grounding), consistent with the revised integrity rules.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Steps 1.7, 2.3, "Resuming an in-progress item", "Ledger and history disagree").
- Revised `references/re-grounding-routine.md` (W-6) and `references/durable-record-protocol.md` (Integrity table).
- Spec: [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Dry-run trace: a run stopped after a committed but un-cleared iteration resumes into re-verify, not into a `done` record.

**Acceptance criteria.**
- [ ] Resume treats only the committed `done` entry as authoritative; an unverified committed iteration is re-verified, not marked done.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-3, W-9.

## W-11 — SKILL.md base resolution consuming the extended detector

**Type.** `deliverable`

**Summary.** Consume the detector's ahead/behind + `fetch-status` output to recommend-and-confirm the base on fresh runs only: surface the current branch as an alternative when ahead, present counts without a recommendation when diverged or the fetch is incomplete, fall back to asking on detached/no-base, and read the base from the recorded opening on resume (See plan: D-11). The `git fetch` stays in `SKILL.md`; the detector stays read-only.

**Description.**
1. In Step 1.6/1.7, consume the detector's ahead/behind and `fetch-status` lines.
2. On a fresh run: recommend the current branch when it is ahead of the base; present both candidates with counts and ask (no recommendation) when diverged or the fetch failed; fall back to asking on detached-HEAD or no-base.
3. On resume, read the base from the recorded opening rather than re-resolving; keep the `git fetch` in `SKILL.md`.

**Note on scope boundary.** Logically independent of the record model; chained after W-10 only for SKILL.md merge-safety.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Steps 1.6, 1.7, 2.1 preview).
- Revised `scripts/detect-driver-context.sh` (W-4).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) step 1, [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (the five base-resolution rows), [feature-specification.md#user-interactions](feature-specification.md#user-interactions) (base-recommendation choice).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Dry-run trace across the five base scenarios: recommend-and-confirm fires fresh-only, with the correct recommendation/ask behavior per scenario.

**Acceptance criteria.**
- [ ] Base resolution recommends-and-confirms fresh-only, asks (no recommendation) when diverged or fetch-incomplete, falls back on detached/no-base, and reads the recorded base on resume.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-4, W-10.

## W-12 — SKILL.md below-threshold dispositions and coherence-spillover approval

**Type.** `deliverable`

**Summary.** On a green gate, let the driver address below-threshold findings it judges genuinely matter (or deliberately leave them), re-running available verification before committing any such fix and recording each fix/leave disposition durably at decision time, escalating through the recovery menu when a fix needs a scope/approach change (See plan: D-6). Surface fix edits that touch already-committed sibling files outside the item's expected paths as a coherence-approval choice, threading approvals to later review rounds and persisting them across resume so the gate can clear; on rejection route them through the normal fix loop (See plan: D-7).

**Description.**
1. In Step 3.3 Gate/Cleared: on a green gate, the driver may address genuinely-mattering below-threshold findings (reading their detail per W-7) or leave them, re-running available verification before committing any such fix and recording each fix/leave disposition in the record; escalate through the recovery menu when a fix needs a scope or approach change.
2. Surface sibling-file edits outside the item's expected paths as a coherence-approval choice; on approval, record it in the record and thread the approved paths to later review rounds (per W-7); on rejection, route through the normal fix loop.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Step 3.3 Review/Gate, Step 3.4).
- Revised `references/review-verdict-contract.md` (W-7) and `references/durable-record-protocol.md` (disposition/approval blocks).
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) steps 6-7, [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (coherence-spillover-rejected), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Dry-run trace: a below-threshold fix re-verifies before commit and records its disposition; an approved coherence edit is not re-raised in a later round and survives a resume.

**Acceptance criteria.**
- [ ] Below-threshold fixes re-verify before commit and record a durable disposition; unfixable ones escalate through the recovery menu.
- [ ] Coherence spillover is surfaced for approval, threaded to later rounds, persisted across resume, and routed to the fix loop on rejection.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-7, W-11.

## W-13 — SKILL.md clean-tree startup commit-or-stash and fix-cap accounting

**Type.** `deliverable`

**Summary.** Require a clean tree before the first item by staging the run's own planning outputs as the opening commit and offering commit-or-stash for anything else — a stray draft, an unrelated edit, a pre-existing dirty expected-path file, or a prior run's stale artifact area — with the plan-preview enumerating exactly what the opening commit stages (See plan: D-3 in the spec's clean-tree decision); and change fix-cap accounting so an operator-directed hand fix does not consume the automated fix budget and a fully hand-driven item is not gated by the cap at all (See plan: the spec's fix-cap decision).

**Description.**
1. In Steps 1.8/2.1: require a clean tree before the first item; stage the run's own just-produced planning outputs as the opening commit; offer commit-or-stash for anything else (stray drafts, unrelated edits, a pre-existing dirty expected-path file, a prior run's stale artifact area); enumerate the opening-commit contents in the plan-preview.
2. In Step 3.3 Gate / Halt Procedure: count only automated fix rounds against the `--fix-cap`; an operator-directed hand fix does not consume the budget, and a fully hand-driven item is not gated by the automated cap.

**Note on scope boundary.** Logically independent; chained after W-12 for SKILL.md merge-safety; relies transitively on the relocated plan-folder anchor from W-1/W-8.

**References.**
- Current `han-coding/skills/implement-work-items/SKILL.md` (Steps 1.8, 2.1, 3.3 Gate, Halt Procedure / "Re-attempting after a fix").
- Spec: [feature-specification.md#primary-flow](feature-specification.md#primary-flow) steps 2 and 6, [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (operator-directed fix), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (stale-artifact / dirty-expected-path / no-artifacts-subfolder rows), [feature-specification.md#user-interactions](feature-specification.md#user-interactions) (commit-or-stash offer).
- Plan: [feature-implementation-plan.md#raid-log](feature-implementation-plan.md#raid-log) (R3 hook-conflict preview).
- Plugin-authoring guidance (see Shared reference artifacts).

**Checks.**
- Dry-run trace: a stray uncommitted file triggers a commit-or-stash offer; the opening commit stages only the run's planning content and is enumerated in the preview; an operator-directed fix round does not decrement the automated cap.

**Acceptance criteria.**
- [ ] The clean-tree gate stages only the run's planning content and offers commit-or-stash for everything else, with the opening commit enumerated in the preview.
- [ ] Operator-directed hand fixes do not consume the automated fix-cap; a fully hand-driven item is not gated by it.

**Requires pre-work decisions.** `no`

**Suggested implementation.** `general-purpose`, AFK

**Suggested review.** `none`, HITL

**Expected paths.**
- `han-coding/skills/implement-work-items/SKILL.md`

**Depends on.** W-12.
