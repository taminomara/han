# Feature Implementation Plan: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

<!-- Ships as markdown driver instructions plus one shell script — edits to the `implement-work-items` Claude Code skill, not application code. Posture: one coherent slice, foundation files first, rolled back by a clean `git revert`. -->

## Source Specification

- **Feature specification:** [feature-specification.md](../feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](decision-log.md)
- **Specification team findings:** [artifacts/team-findings.md](team-findings.md)
- **Specification technical notes:** [artifacts/feature-technical-notes.md](feature-technical-notes.md)
- **Specification decisions this plan inherits:** D1–D21 (all committed spec behaviors).
- **Specification open items this plan resolves:** both. Open Item #1 (the exact durable-record form and its grep convention) resolves to a committed ledger file ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd)) located by a namespaced trailer ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)); Open Item #2 (conform-versus-bypass for bookkeeping commits) resolves to conform-via-conventional-message ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)).

## Outcome

The `implement-work-items` skill gains three behaviors, delivered as edits to `SKILL.md`, two new reference files, one new shell script, one touched reference (`no-output-completion.md`), a verified exclusion checklist across existing references, and a rewrite of the operator doc. After this plan runs: the driver records its per-item progress durably as a committed ledger file on the run's branch; re-invoking the driver on the same work-items file resumes the run from the first unfinished item (after an operator go-ahead) instead of refusing the branch or rebuilding committed work; a halt presents an in-session recovery menu instead of a dead-end; and every re-entry point runs one shared re-grounding routine. The change ships as markdown and one script, with no application runtime, service, or database, and is rolled back by a clean `git revert`.

## Context

- **Driving constraint:** The behavioral spec is settled and just cleared `iterative-plan-review`; the skill it extends is freshly reconciled around the `audit`/`spike`/no-output item types (commits `7d8d1a4`, `74980fc`, `71e085c`, last 90 days) and is the baseline to build on before that reconciliation drifts. The prior over-scoped attempt at `docs/plans/autonomous-implementation-driver/` is the rejected precedent this plan deliberately stays smaller than.
- **Stakeholders:** the operator (resumes a stopped run, steers a halt back onto its feet, and must never have committed work silently rebuilt or a foreign commit silently marked done); the skill maintainer (inherits SKILL.md that must stay under the 500-line ceiling and reuse the existing contracts without regressing them); future driver agents (copy whatever patterns this plan commits, so every added mechanic is maintenance and precedent).
- **Future-state concern:** the durable record travels in branch history and is greppable forever; the trailer convention and the ledger file are patterns future runs and future skills will imitate. Watch that SKILL.md stays under the ceiling and that the record's exclusion holds at every scope/stage site so the driver's bookkeeping never contaminates an item's commit.
- **Out-of-scope boundary:** unchanged from the spec — no automatic mid-run compaction survival ([D4](decision-log.md#d4-re-invocation-only-recovery)), no concurrent-driver arbitration ([D17](decision-log.md#d17-single-writer-per-checkout)), no detection of an edited already-done item ([D21](decision-log.md#d21-done-items-trusted-by-identifier)), no richer recovery menu ([D5](decision-log.md#d5-in-session-recovery-menu)), no end-of-run history cleanup ([D8](decision-log.md#d8-ledger-markers-left-in-history)), and no dedicated commit-range integrity pre-check (spec Deferred (YAGNI)).

## Team Composition and Participation

One round (R1) of four specialists ran and converged strongly; the spec-maturity gate did not trip. Full round detail lives in [artifacts/implementation-iteration-history.md](implementation-iteration-history.md).

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Facilitated R1 and synthesized this plan; resolved all four Open Questions by evidence in aggregation. |
| `junior-developer` | Active | Reframed the record form and decomposition; flagged the go-ahead-leak risk in a monolithic re-grounding block ([D-4](implementation-decision-log.md#d-4-re-grounding-is-one-core-routine-with-per-site-wrapping)) and the redundant hook-probe (Deferred YAGNI). |
| `on-call-engineer` | Active | Drove the resilience findings: non-atomic write ordering, bookkeeping-failure class ([D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)), commit-boundary self-check ([D-7](implementation-decision-log.md#d-7-commit-boundary-self-check-is-an-unconditional-re-read-via-a-shared-record-the-item-done-routine)), positional reference ([D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time)), forward-reconcile ordering ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)), collision-resistant marker ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)). |
| `structural-analyst` | Active | Owned the file decomposition ([D-3](implementation-decision-log.md#d-3-structural-decomposition-into-two-references-and-one-sibling-script)), the exclusion-site checklist ([D-11](implementation-decision-log.md#trivial-decisions)), and the durable-record-first write ordering ([D-12](implementation-decision-log.md#trivial-decisions)). |
| `behavioral-analyst` | Active | Owned path normalization ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)), the changed-file-set data flow in forward-reconcile ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)), and minimal entry fields ([D-13](implementation-decision-log.md#trivial-decisions)). |
| `test-engineer` | Not engaged | No code test harness exists for skill markdown; verification is scenario-based against the spec's Edge Cases table (see Testing Strategy). |

## Implementation Approach

The feature layers resume, halt-recovery, and re-grounding onto the existing per-item loop without rewriting it. It reuses the driver's existing scope computation, its per-item commit-by-path discipline, its contracts (`build-report-contract.md`, `review-verdict-contract.md`, `human-review-capture.md`), and its self-ignoring `.implement-work-items/` directory. It introduces one tracked ledger file, one namespaced commit trailer for run identity, an item-id trailer on code commits, one deterministic detection script, and two reference files that hold the mechanics too large for SKILL.md.

### Architecture and Integration Points

The change touches `SKILL.md` (Steps 1, 2.2, 3, Halt Procedure, Completion Summary), adds `references/durable-record-protocol.md` and `references/re-grounding-routine.md`, adds `scripts/scan-run-history.sh`, and edits `references/no-output-completion.md`; it repoints `references/foreground-handoff-protocol.md` and `references/human-review-capture.md` at the shared re-grounding routine ([D-3](implementation-decision-log.md#d-3-structural-decomposition-into-two-references-and-one-sibling-script), [D-4](implementation-decision-log.md#d-4-re-grounding-is-one-core-routine-with-per-site-wrapping)). The existing `scripts/detect-driver-context.sh` is left unchanged, because the record scan needs the resolved work-items path and a post-Step-1.2 invocation timing that detector cannot take ([D-3](implementation-decision-log.md#d-3-structural-decomposition-into-two-references-and-one-sibling-script)). Deterministic work (scan the branch log for the run trailer, classify fresh/resume/refuse, reconstruct entries) lives in the script; judgment (classify resume state, surface-and-ask, present the recovery menu) stays in SKILL.md, per the hardening rule.

### Data Model and Persistence

The durable record is a committed markdown ledger at `.implement-work-items/progress.md`, made trackable by changing the setup step's `.implement-work-items/.gitignore` from a single line `*` to `*` followed by `!progress.md`, so the ledger is version-controlled while `state.json` and the review records stay ignored ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd)). Each commit that appends an entry carries the run-identity trailer `Implement-Work-Items-Run:` whose value is the work-items file's normalized repo-root-relative path ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)). The driver's own per-item code commits carry an `Implement-Work-Items-Item:` trailer with value `W-N` ([D-9](implementation-decision-log.md#d-9-add-an-item-id-trailer-to-the-drivers-own-code-commits)). Entry types (opening, start-of-item, done, no-commit-done, skip) are lines in the ledger; entry fields are kept minimal — no `Type` on the no-commit-done entry, no dependency snapshot in the skip entry, no durable fix-counter, body-hash, or pre-work-decision ([D-13](implementation-decision-log.md#trivial-decisions)). Done-entry references are positional, computed at report time from history rather than stored as a hash, so a benign history-preserving rebase does not false-alarm ([D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time)). Where a durable write and a `state.json` write both occur, the durable record is written first and `state.json` follows as the reconstructable in-session copy ([D-12](implementation-decision-log.md#trivial-decisions)). `state.json` remains an in-session convenience, reconstructed on cross-session resume from the durable record and treated as untrusted if a gitignored copy survives ([D-4](implementation-decision-log.md#d-4-re-grounding-is-one-core-routine-with-per-site-wrapping)).

### Runtime Behavior

**Invocation classification.** At Step 1, after branch resolution and before the clean-tree gate, `scripts/scan-run-history.sh` greps the branch history for the run-identity trailer, matched exactly against the normalized target path: a present record is a resume, an empty branch is a fresh run, and a branch with commits but no record for this file is refused as a foreign base ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)).

**Re-grounding.** One core routine (reconstruct run state from the record, re-derive the dependency graph from the current file, re-read the tree, re-read own instructions, announce) runs at all four re-entry sites; the cross-session site wraps it with the D19 go-ahead, the resume summary, config restoration, and baseline re-establishment, while the three in-session sites omit the go-ahead ([D-4](implementation-decision-log.md#d-4-re-grounding-is-one-core-routine-with-per-site-wrapping)).

**Forward-reconcile (the single most behavior-adjacent mechanic).** On resuming an in-progress item, an interrupted foreground item is routed to re-verify/re-review (the existing "Resuming an interrupted foreground item" flow) **before** forward-reconcile is reached, so forward-reconcile applies only to AFK items; and forward-reconcile is gated by a positive-classification test that reuses the existing scope computation — the item's start-of-item-to-HEAD changed-file set must be within scope and the tree clean — so a foreground pre-gate commit or a foreign in-range commit cannot be silently marked done, and is surfaced-and-asked instead ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)). This implements D11 default-deny on the forward-reconcile path and does not reopen the deferred dedicated range check.

**Commit boundary.** One shared "record the item done" routine unconditionally re-Reads the relevant step(s), then forks output (commit plus done entry, code commit strictly preceding the done entry) versus no-output (no-commit done outcome) ([D-7](implementation-decision-log.md#d-7-commit-boundary-self-check-is-an-unconditional-re-read-via-a-shared-record-the-item-done-routine), [D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time)).

**Bookkeeping failure.** Every progress-record write goes through one shared "record a bookkeeping entry" routine whose failure branch is the Halt Procedure marker-write class, never the Step 3.4 code fix loop ([D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)).

**Halt.** The Halt Procedure's fifth part becomes the in-session recovery menu (fix-and-re-attempt, more fix rounds, skip, stop), replacing today's "the run does not resume" dead-end ([D5](decision-log.md#d5-in-session-recovery-menu)).

### External Interfaces

The only external systems are git history and the repo's commit hooks, per the spec's Coordinations. Bookkeeping commits conform to the repo's detected commit convention so hooks accept them; a rejection is surface-and-stop ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)). No API, event, queue, or third-party integration is added.

## Decomposition and Sequencing

Foundation files first, then the SKILL.md steps that consume them, then the exclusion verification and docs.

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | `references/durable-record-protocol.md` | Entry schema, D11 integrity matrix, the `Implement-Work-Items-Run` trailer convention, the exclusion checklist ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)) | — | Reads against T1's constraint list; schema expresses a no-commit done outcome |
| 2 | `scripts/scan-run-history.sh` | Deterministic fresh/resume/refuse detection and history scan, path-normalized ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path), [D-3](implementation-decision-log.md#d-3-structural-decomposition-into-two-references-and-one-sibling-script)) | 1 | Behavioral check on a crafted branch (see Testing Strategy) |
| 3 | `references/re-grounding-routine.md` + repoint `foreground-handoff-protocol.md` and `human-review-capture.md` | The one core re-grounding routine with the extracted instruction-reload sub-step ([D-4](implementation-decision-log.md#d-4-re-grounding-is-one-core-routine-with-per-site-wrapping)) | 1 | The three in-session sites reference the core without the go-ahead |
| 4 | SKILL.md Step 1 | Fresh/resume/refuse via the script, ordered before the clean-tree gate, with path normalization ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)) | 2 | Edge Cases rows for resume, foreign-base refusal, stripped record |
| 5 | SKILL.md Step 2.2 | Fresh/resume fork; the `!progress.md` un-ignore; the atomic opening entry ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-10](implementation-decision-log.md#trivial-decisions)) | 1 | Opening-entry-fails row leaves a fresh branch |
| 6 | SKILL.md Step 3 | Start-of-item entry; the shared "record the item done" routine (unconditional re-Read, output/no-output fork, positional reference, item-id trailer); the distinct bookkeeping-failure path ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test), [D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class), [D-7](implementation-decision-log.md#d-7-commit-boundary-self-check-is-an-unconditional-re-read-via-a-shared-record-the-item-done-routine), [D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time), [D-9](implementation-decision-log.md#d-9-add-an-item-id-trailer-to-the-drivers-own-code-commits)) | 1, 3 | Edge Cases rows for committed-but-unmarked, bookkeeping rejection, compaction truncation |
| 7 | SKILL.md alternate-flow sections + Halt Procedure → recovery menu; forward-reconcile AFK-only routing ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)) | 3 | Edge Cases rows for in-progress item, foreground interrupt, skip, stop |
| 8 | `references/no-output-completion.md` | Durable no-commit-done write, ordered durable-record-first then `state.json` ([D-12](implementation-decision-log.md#trivial-decisions), [D-13](implementation-decision-log.md#trivial-decisions)) | 1 | No-output-audit-not-recorded row re-runs and re-confirms |
| 9 | Exclusion verification across scope/stage/human-review/no-output ([D-11](implementation-decision-log.md#trivial-decisions)) | Verified checklist; the human-review pointer is the one site to confirm | 1, 4 | The `.implement-work-items/progress.md` path appears in no scope diff or stage set |
| 10 | Operator doc rewrite (`docs/skills/han-coding/implement-work-items.md`) | Three inverted passages (lines 20/72/83) rewritten; YAGNI deferred list corrected | all | Reads against the spec; no surviving "no resume"/"absolute halt" claim |

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | An exotic repo hook (trailer-stripping, or rejecting a conventionally-messaged file-update commit) breaks the run-identity trailer or the ledger commit | Low | Medium | One repo's runs | High (`git revert`) | on-call-engineer | Bookkeeping commits conform to convention; the opening-entry commit exercises the hook path at plan-confirmation ([D-10](implementation-decision-log.md#trivial-decisions)); a rejection is surface-and-stop ([D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)) |
| R2 | A below-threshold foreign commit in an AFK item's range rides into the item's commit after a rare mid-run history rewrite | Low | Low | One item's commit | High | on-call-engineer | Accepted residual of deferring the dedicated range check; a substantial reach still gates via the reused scope diff ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test); spec Deferred (YAGNI)) |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | A no-output `audit` is side-effect-free per the producer's catalog constraint, so re-running it on resume is safe | An in-progress audit that mutates state on re-run would double-apply; re-run would need an idempotency guard | behavioral-analyst | Committing to it — grounded in the skill's existing catalog constraint ([D6](decision-log.md#d6-in-progress-item-inspect-and-decide), review-sync F11) |
| A2 | One live driver per checkout (single writer) | Two drivers would interleave commits and scramble the item ranges | on-call-engineer | Committing to it — stated precondition, no lock built ([D17](decision-log.md#d17-single-writer-per-checkout)) |

## Testing Strategy

There is no code test harness for skill markdown, so verification is scenario-based, not code-coverage-based. No `test-engineer` was on the team; this section is the project-manager's synthesis of the spec's own acceptance surface.

- **Observable behaviors to test:** the spec's **13-row Edge Cases table is the acceptance checklist** — each row is a scenario the driver must exhibit on a crafted branch (resume recognized, foreign base refused, committed-but-unmarked forward-reconciled, no-output audit re-run and re-confirmed, dirty in-progress tree classified, unclassifiable state surfaced, foreign in-range commit scope-flagged, skip-with-uncommitted-work cleaned, red baseline surfaced, re-attempt paths non-destructive, edited done-item trusted, unresolved done-commit surfaced, opening-entry failure classified fresh).
- **Deterministic unit worth a behavioral check:** `scripts/scan-run-history.sh` is the one deterministic unit — exercise it on a crafted branch carrying (a) a matching run trailer, (b) no trailer, (c) foreign commits with no trailer, and (d) an equivalent-but-differently-spelled path, and confirm it classifies resume / fresh / refuse / resume respectively ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)).
- **Highest-value scenario:** the forward-reconcile ordering ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)) — verify an interrupted foreground item routes to re-review before forward-reconcile, and an AFK item with a foreign in-range commit is surfaced rather than marked done.
- **Test levels:** scenario/behavioral only; no unit-, integration-, or end-to-end code layers exist for a markdown skill.

## On-Call Resilience Posture

The on-call-engineer contributed the bulk of R1's findings; these are the resilience commitments this plan makes. "Resilience" here concerns the driver's git-history handling and its behavior under compaction and interruption, not infrastructure.

- **Non-atomic write ordering and idempotency:** the code commit strictly precedes the done entry; a session killed between them leaves a committed-but-unmarked item that resume forward-reconciles rather than double-commits ([D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time), [D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)). The opening entry is co-committed atomically with the planning-artifacts commit, so a failed opening leaves an empty (fresh) branch, not a foreign base ([D-10](implementation-decision-log.md#trivial-decisions)). Durable writes precede `state.json` writes ([D-12](implementation-decision-log.md#trivial-decisions)).
- **Bookkeeping-failure class:** a rejected bookkeeping commit is surface-and-stop through the Halt Procedure marker-write class, never the code fix loop, so a rejected marker cannot become a poison-pill fix loop on sound code ([D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)).
- **Commit-boundary self-check as failure-path observability:** an unconditional re-Read at the commit boundary bounds a compaction-truncated driver's blast radius to the in-progress item, which resume re-inspects, rather than a falsely-trusted done item no later step re-examines ([D-7](implementation-decision-log.md#d-7-commit-boundary-self-check-is-an-unconditional-re-read-via-a-shared-record-the-item-done-routine)).
- **Positional reference for data integrity:** done-entry references are computed at report time from history, so a benign history-preserving rebase does not false-alarm a missing commit ([D-8](implementation-decision-log.md#d-8-done-entry-reference-is-positional-computed-at-report-time)).
- **Collision-resistant marker:** run identity is a namespaced trailer matched exactly against the normalized path, not a subject substring, so an ordinary commit cannot be misread as a run record ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)).
- **Single-writer assumption:** one live driver per checkout is a stated precondition; no lock is built, and concurrent invocation is unsupported ([D17](decision-log.md#d17-single-writer-per-checkout); assumption A2).
- **Rollback:** because the change ships as markdown plus one script with no runtime state, rollback is a clean `git revert` of the skill edits. A reverted old skill correctly refuses a branch that carries ledger-artifact commits as prior-run commits (its foreign-base guardrail), so no half-migrated state is stranded.

<!-- Security Posture omitted: this change adds no authentication, authorization, PII, secret, or new trust boundary — it edits a skill that already runs on a trusted, operator-supplied work-items file, and no adversarial-security-analyst was engaged. Operational Readiness omitted: the change ships as markdown and one shell script with no infrastructure, observability sink, feature flag, SLO, or rollout surface; its rollback is the clean `git revert` noted above, and no devops-engineer was engaged. Both omissions record the judgment that there is genuinely no surface, not a skipped step. -->

## Definition of Done

- [ ] Each of the spec's 13 Edge Cases behaviors is verified on a crafted branch (Testing Strategy).
- [ ] `scripts/scan-run-history.sh` classifies resume / fresh / refuse correctly, including the path-normalization case ([D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)).
- [ ] Forward-reconcile routes an interrupted foreground item to re-review first and gates the AFK path with the reused scope diff ([D-5](implementation-decision-log.md#d-5-forward-reconcile-is-afk-only-ordered-after-the-foreground-branch-and-gated-by-a-positive-classification-test)).
- [ ] The operator doc's three inverted passages (lines 20/72/83) are rewritten and its YAGNI deferred list corrected (cross-session resume and the recovery menu now ship; compaction survival, concurrent drivers, edited-done-item detection, richer menu, and history cleanup remain deferred).
- [ ] SKILL.md stays under the 500-line progressive-disclosure ceiling ([D-3](implementation-decision-log.md#d-3-structural-decomposition-into-two-references-and-one-sibling-script)).
- [ ] Every exclusion site (SKILL.md 3.4 stage, `review-verdict-contract.md` scope diff, `human-review-capture.md` pointer, `no-output-completion.md` clean-tree assertion) is verified to keep `.implement-work-items/progress.md` out ([D-11](implementation-decision-log.md#trivial-decisions)).
- [ ] `git revert` rollback is clean: a reverted old skill refuses a branch carrying ledger artifacts as prior-run commits.
- [ ] Post-ship owner named: the skill maintainer owns the driver and the operator doc.

## Specialist Handoffs for Implementation

- **`on-call-engineer`** — dispatch when authoring `scripts/scan-run-history.sh` and the forward-reconcile ordering in SKILL.md Step 3/7; needs the durable-record-protocol schema (unit 1) and the reused scope computation in `review-verdict-contract.md`.
- **`structural-analyst`** — dispatch when the two new references and the SKILL.md edits are drafted, to confirm SKILL.md stays under the ceiling and the exclusion checklist holds; needs units 1, 3, 6, 9.
- **`content-auditor`** — dispatch for the operator-doc rewrite (unit 10) to confirm no inverted passage survives; needs the prior version of the doc and this plan.

## Deferred (YAGNI)

### Separate D20 run-start hook-probe

- **Why deferred:** simpler-version test — the opening-entry commit at setup ([D-10](implementation-decision-log.md#trivial-decisions)) already exercises the hook path and fails at plan-confirmation, so a dedicated read-only probe adds a code path for no additional coverage.
- **Reopen when:** a repo whose hooks reject the start-of-item entry but accept the opening entry.
- **Source:** R1 — on-call OCE-010, junior JD-009, structural S4.

### `Type` field on the no-commit-done entry

- **Why deferred:** simpler-version test — the entry-type token plus reading `Type` from the work-items file at resume suffices; a durable `Type` field duplicates readable data.
- **Reopen when:** the work-items file is not reliably readable at resume.
- **Source:** R1 — behavioral B4.

### Dependency snapshot in the skip entry

- **Why deferred:** simpler-version test — the dependency graph is re-derived from the current file on resume (the spec requires this), so a snapshot duplicates it.
- **Reopen when:** re-derivation from the current file proves unreliable across between-session edits.
- **Source:** R1 — behavioral B5.

### A second script for per-item changed-file derivation

- **Why deferred:** simpler-version test — the existing scope computation (`git diff --name-only <baseline>`) already derives the changed-file set, with the baseline re-sourced from the start-of-item entry; a second script duplicates it.
- **Reopen when:** the reused scope diff proves insufficient for the forward-reconcile positive test, forcing a dedicated derivation.
- **Source:** R1 — junior JD-004.

<!-- Confirmed NOT re-added (already spec-deferred, not reopened by R1): a durable state-machine/phase field, a state.json migration, an idempotency framework, a concurrency lock/run-active marker, a dedicated commit-range integrity pre-check, a lifetime fix-round cap, and per-item body-identity detection. Source: R1 junior JD-010 and on-call notes; spec Deferred (YAGNI). -->

## Open Items

This plan resolves both of the spec's Open Items (record form → committed ledger file; conform-versus-bypass → conform via a conventional message). No open item blocks implementation.

- **OI-1 (spec Open Item #1 — record form and grep convention):** resolved to a committed ledger at `.implement-work-items/progress.md` located by the `Implement-Work-Items-Run` trailer ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-2](implementation-decision-log.md#d-2-run-identity-and-entry-marker-is-a-namespaced-git-trailer-keyed-on-the-normalized-work-items-path)).
  - **Resolves when:** resolved.
  - **Blocks implementation:** No.
- **OI-2 (spec Open Item #2 — conform-versus-bypass for bookkeeping commits):** resolved to conform via a conventional message on the file-update commit ([D-1](implementation-decision-log.md#d-1-durable-record-form-is-a-committed-ledger-file-at-implement-work-itemsprogressmd), [D-6](implementation-decision-log.md#d-6-bookkeeping-commit-failure-is-a-distinct-surface-and-stop-class)).
  - **Resolves when:** resolved.
  - **Blocks implementation:** No.

## Summary

- **Outcome delivered:** the `implement-work-items` skill records per-item progress in a committed branch ledger, resumes a stopped run from the first unfinished item after an operator go-ahead, offers an in-session recovery menu at a halt, and re-grounds through one shared routine — shipped as markdown plus one script.
- **Team size:** 4 specialists (plus the project-manager coordinator) — see [artifacts/implementation-iteration-history.md](implementation-iteration-history.md)
- **Rounds of facilitation:** 1 — see [artifacts/implementation-iteration-history.md](implementation-iteration-history.md)
- **Decisions committed:** 13 (9 full, 4 trivial) — see [artifacts/implementation-decision-log.md](implementation-decision-log.md)
- **Decisions settled by evidence:** 13 — see [artifacts/implementation-decision-log.md](implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0 — see [artifacts/implementation-decision-log.md](implementation-decision-log.md)
- **Decisions settled by user input:** 0 — see [artifacts/implementation-decision-log.md](implementation-decision-log.md)
- **Rejected alternatives recorded:** 15 — see [artifacts/implementation-decision-log.md](implementation-decision-log.md)
- **Open items remaining:** 0 blocking
- **Recommendation:** Ship as planned.
