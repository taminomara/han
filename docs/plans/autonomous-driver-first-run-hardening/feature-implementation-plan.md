# Feature Implementation Plan: implement-work-items First-Run Hardening

Implement the settled behavioral spec by rewriting the driver's per-item loop around a commit-every-iteration cadence and collapsing its run record into a single committed, shell-parseable file — extracting new behavior into references and one script so `SKILL.md` stays under its size ceiling, and landing the record-and-commit model as one atomic keystone so resume never reconstructs from a half-changed contract.

## Source Specification

- **Feature specification:** [feature-specification.md](feature-specification.md)
- **Specification decision log:** [artifacts/decision-log.md](artifacts/decision-log.md)
- **Specification team findings:** [artifacts/team-findings.md](artifacts/team-findings.md)
- **Specification iterative-review record:** [artifacts/review-findings.md](artifacts/review-findings.md), [artifacts/review-iteration-history.md](artifacts/review-iteration-history.md)
- **Specification decisions this plan inherits:** D1–D12
- **Specification open items this plan must respect or resolve:** OI-1 (below-threshold discretion), OI-2 (correction-class criterion)

## Outcome

When this plan is executed, the `implement-work-items` skill will:

- Keep its run record as one committed, shell-parseable file with no `state.json` and no hard `jq`/`python3` dependency ([D-1](artifacts/implementation-decision-log.md#d-1-run-record-stays-a-shell-parseable-line-grammar-no-json-no-hard-jq-or-python-dependency), [D-2](artifacts/implementation-decision-log.md#d-2-delete-the-json-state-file-and-recover-scope-baseline-from-a-distinct-trailer)).
- Commit every build and fix iteration and every bookkeeping write, with a clean working tree at every dispatch boundary, via a rewritten per-item loop ([D-5](artifacts/implementation-decision-log.md#d-5-rewrite-the-per-item-loop-to-commit-before-every-dispatch-and-every-iteration)).
- Resume from the committed ledger `done` entry as the sole authority for completion ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- Store the run inside the plan folder, recommend the right base with ahead/behind evidence, offer commit-or-stash for stray tree content, accumulate operator corrections, and record below-threshold dispositions and coherence approvals durably — all through extensions to the existing scripts and one new reference, not new subsystems.

The changed files are: `SKILL.md` (loop rewrite, startup, dispatch), `references/durable-record-protocol.md` (absorbs the collapsed record) ([D-15](artifacts/implementation-decision-log.md#d-15-durable-record-protocol-absorbs-the-collapsed-record-commit-model-relocated-path-and-re-grounded-exclusion)), `references/review-verdict-contract.md` ([D-12](artifacts/implementation-decision-log.md#d-12-extend-the-review-verdict-contract-for-below-threshold-detail-prior-iteration-diff-and-approved-coherence-paths)), `references/re-grounding-routine.md` (loses its `state.json` section), `scripts/scan-run-history.sh` and `scripts/detect-driver-context.sh` (extended); plus two new files: `references/sub-agent-instructions.md` ([D-14](artifacts/implementation-decision-log.md#d-14-one-new-sub-agent-instructions-reference-that-also-carries-the-accumulated-corrections)) and `scripts/write-run-record.sh` ([D-4](artifacts/implementation-decision-log.md#d-4-one-mechanism-only-bookkeeping-writer-script)).

## Context

- **Driving constraint:** the skill's first full end-to-end run surfaced concrete friction (wrong base, spurious clean-tree halts, fix-cap fighting the operator, silently-reverted work, no diffable iteration history, a failed hand-maintained finalization). The skill is under active development on `feat/autonomous-driver-core-loop`, so the changes land into a moving target.
- **Stakeholders:** the solo operator running the driver (the primary user and the "on-call" for a run), and future maintainers of the skill who inherit the record grammar and the loop.
- **Future-state concern:** the `- <token>: <W-N>` ledger grammar is a two-party contract between the writer and `scan-run-history.sh`; a one-sided change silently reconstructs zero items on resume. `SKILL.md` sits at ~460 of a 500-line ceiling, so new behavior must extract to references/scripts. The pure-shell / `jq`-optional portability stance has no ADR guarding it and must be preserved as a de-facto contract.
- **Out-of-scope boundary:** containing the harness nested-agent limitation (a separate feature); changes to the work-items planning skill (deferred); and the driver ever rewriting git history — it tags commits so the operator *can* collapse or strip them, but never does so itself (spec Out of Scope).

## Team Composition and Participation

| Specialist | Status | Key Input |
|------------|--------|-----------|
| `project-manager` | Coordinator | Synthesized the final plan and decision log from the round-1 claim ledger. |
| `junior-developer` | Active | Surfaced the three invalidated implementation contracts (scanner read-contract, one-item-one-commit, clean-tree-equals-finished); dissented on the writer script as YAGNI ([D-4](artifacts/implementation-decision-log.md#d-4-one-mechanism-only-bookkeeping-writer-script)). |
| `devops-engineer` | Active | Owned the ledger-format/tooling decision (line-grammar, delete `state.json`, no hard `jq`/python), the trailer scheme, the `.gitignore` flip, and the D2 detector plumbing. |
| `on-call-engineer` | Active | Owned the loop's fail-closed semantics: pre-dispatch commit class, write-ordering invariant, resume done-authority, the re-verify-fails branch. |
| `software-architect` | Active | Owned the decomposition: one new reference, one new script, `durable-record-protocol.md` absorption, the two-wave build order and the four contract seams. |
| `test-engineer` | Stood down (errored) | Round-2 handoff for the testing strategy errored with no output; the strategy was folded from round-1 evidence ([D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)). |

## Implementation Approach

The record-and-commit model is the keystone: five spec decisions (D6, D7, D8, D9, D12) read or write through the committed record and the commit cadence, so it lands first and atomically ([D-16](artifacts/implementation-decision-log.md#d-16-two-wave-build-order-with-four-contract-seams-co-landing-atomically)). The guiding shape is *extract, don't inflate* (every format/contract/payload moves to a reference or script so `SKILL.md` stays under ceiling) and *deterministic edges, fuzzy center* (a writer script owns line formatting; the model owns token choice, gate decisions, and commit orchestration).

### Architecture and Integration Points

- **One new reference, `references/sub-agent-instructions.md`** holds the D11 shared baseline plus the role-scoped build and review payloads; D9's accumulated-corrections injection rules fold into it rather than a standalone `preference-memory.md` ([D-14](artifacts/implementation-decision-log.md#d-14-one-new-sub-agent-instructions-reference-that-also-carries-the-accumulated-corrections)). This is the outbound counterpart to the existing return contracts (`build-report-contract.md`, `review-verdict-contract.md`), and it net-reduces the restated dispatch prose in `SKILL.md` Step 3.3.
- **One new script, `scripts/write-run-record.sh`**, append-only and mechanism-only, following the existing pure-bash deterministic-detector precedent; it formats and appends record lines and never makes a proceed/discard judgment ([D-4](artifacts/implementation-decision-log.md#d-4-one-mechanism-only-bookkeeping-writer-script)).
- **`references/durable-record-protocol.md` absorbs** the collapsed record format, the commit model, the relocated path, and the re-grounded (path-based) exclusion; no new "collapsed-record" reference is created, and `re-grounding-routine.md` loses its now-dead `state.json` section ([D-15](artifacts/implementation-decision-log.md#d-15-durable-record-protocol-absorbs-the-collapsed-record-commit-model-relocated-path-and-re-grounded-exclusion)).
- **No new files or scripts for spec D2, D3, D5, D8** — each extends its existing home (`SKILL.md` prose or `detect-driver-context.sh`) ([D-18](artifacts/implementation-decision-log.md#trivial-decisions)).

### Data Model and Persistence

- **Record format:** the committed file stays the labeled config block plus one `- <token>: <W-N>` line per entry; no JSON, and neither `jq` nor `python3` becomes a hard dependency (only `git`+bash) ([D-1](artifacts/implementation-decision-log.md#d-1-run-record-stays-a-shell-parseable-line-grammar-no-json-no-hard-jq-or-python-dependency)).
- **`state.json` is deleted:** four of its five fields are re-established per session; the one durable field, `scope-baseline`, is recovered from committed history via a **distinct baseline trailer** on the start-of-item commit, never the item-id trailer ([D-2](artifacts/implementation-decision-log.md#d-2-delete-the-json-state-file-and-recover-scope-baseline-from-a-distinct-trailer)).
- **New durable state** (D6 dispositions, D7 approvals, D9 corrections) rides as its own labeled block appended **below** the byte-for-byte-preserved `Log:` block, each parsed additively so the shipped item-lifecycle regex is never touched ([D-3](artifacts/implementation-decision-log.md#d-3-new-durable-state-rides-in-separate-blocks-below-the-byte-preserved-log-block)).
- **Trailer scheme — four exact-key trailers:** `Implement-Work-Items-Item` on code commits only; `Implement-Work-Items-Run` on bookkeeping commits (never item-id); a distinct `Implement-Work-Items-Fixup` on review-addressing collapsible commits (a trailer, not native `fixup!`); and a distinct baseline trailer for scope-baseline recovery ([D-8](artifacts/implementation-decision-log.md#d-8-four-distinct-commit-trailers-for-item-id-run-fixup-and-baseline)).
- **`.gitignore` dropped:** with `state.json` gone and review records tracked, nothing under the artifact dir needs ignoring; the whole area is tracked, and the four path-based exclusion sites are re-verified to still hold ([D-9](artifacts/implementation-decision-log.md#d-9-drop-the-gitignore-hack-and-track-the-whole-artifact-area)).
- **Relocation:** the ledger path is derived from `dirname(NORM_PATH)` inside `scan-run-history.sh` (no new argument); every literal `.implement-work-items/` reference moves; and — highest risk — the scope-diff exclusion must match the directory **at any depth** once nested, or tracked review files leak as scope findings ([D-10](artifacts/implementation-decision-log.md#d-10-relocate-the-artifact-area-by-deriving-its-path-from-the-work-items-directory)).

### Runtime Behavior

- **The per-item loop is a rewrite of Steps 3.3/3.4**, not an extension: an explicit "commit in-flight work, then dispatch" step at every dispatch site (build, fix re-dispatch, review, recovery "Build further", foreground return), ordering pinned strictly commit → dispatch, and every iteration staged by path ([D-5](artifacts/implementation-decision-log.md#d-5-rewrite-the-per-item-loop-to-commit-before-every-dispatch-and-every-iteration)).
- **Write-ordering invariant:** the terminal ledger entry is the last write per item, committed after the code commit(s); the committed record stays append-only, mutable state stays session-local ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- **Resume** reads the committed `done` entry as the sole authority; the old "item-id commit + clean tree ⇒ cleared" shortcut is removed and folded into re-verify ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- **Base resolution** consumes new `detect-driver-context.sh` output — ahead/behind per candidate via `git rev-list --left-right --count <base>...HEAD`, and `fetch-status: ok|failed` — while the `git fetch` itself stays in `SKILL.md` so the detector remains read-only ([D-11](artifacts/implementation-decision-log.md#d-11-extend-the-context-detector-with-ahead-behind-counts-and-a-fetch-status-flag)).
- **Review** reads below-threshold detail from the durable record, diffs the latest committed iteration against a defined prior one, and receives already-approved-coherence paths so it does not re-raise them ([D-12](artifacts/implementation-decision-log.md#d-12-extend-the-review-verdict-contract-for-below-threshold-detail-prior-iteration-diff-and-approved-coherence-paths)).
- **The D6 re-verify-fails branch:** on a red re-verify of a post-gate below-threshold fix, do not commit; reset to the already-committed gate-cleared iteration or route into the fix loop; never carry the dirty tree into the next dispatch — reusing the existing loop and reset, no new machinery ([D-13](artifacts/implementation-decision-log.md#d-13-the-d6-re-verify-fails-branch-reuses-the-existing-fix-loop-and-committed-state-reset)).

### External Interfaces

- **git commit / hook boundary:** a rejected **pre-dispatch** commit joins the marker-write / resumable-stop class (never the fix loop); "clean tree, nothing to commit" (no-op → dispatch) is distinguished from "hook rejected, tree still dirty" (fail-closed stop) via `git status --porcelain` ([D-6](artifacts/implementation-decision-log.md#d-6-a-rejected-pre-dispatch-commit-is-a-marker-write-resumable-stop-not-a-fix-round)).
- **git trailer interface:** the four-trailer scheme above is the contract history and the resume scan read against ([D-8](artifacts/implementation-decision-log.md#d-8-four-distinct-commit-trailers-for-item-id-run-fixup-and-baseline)).

## Decomposition and Sequencing

Two waves plus an independent set; the four contract seams inside Wave 1 co-land atomically ([D-16](artifacts/implementation-decision-log.md#d-16-two-wave-build-order-with-four-contract-seams-co-landing-atomically)).

| # | Work Unit | Delivers | Depends On | Verification |
|---|-----------|----------|------------|--------------|
| 1 | **Record & commit model (keystone, atomic)** | Collapsed line-grammar record, `state.json` deleted, `.gitignore` dropped, relocated path, four-trailer scheme, `write-run-record.sh`, extended `scan-run-history.sh`, `durable-record-protocol.md` rewrite — the four seams (grammar↔scanner, trailers, path, exclusion) together | — | Round-trip harness (unit 1's writer↔reader), scanner classification tests, path-derivation + at-any-depth-exclusion tests ([D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)) |
| 2 | **Dispatch set** | `sub-agent-instructions.md` (baseline + role-scoped payloads), D9 corrections injection + storage block + capture step | — (parallel with 1) | Fixture briefs assert per-role payload contents |
| 3 | **Commit cadence & clean-tree-at-dispatch** | Loop rewrite (commit-before-dispatch, commit-every-iteration, stage-by-path), pre-dispatch commit class | 1 | Scenario: stopped mid-iteration resumes on the ledger, not commit-presence |
| 4 | **Resume done-authority** | Fold the forward-reconcile shortcut into re-verify; write-ordering invariant | 1, 3 | Scenario: unverified committed iteration is not marked done on resume |
| 5 | **Below-threshold & coherence** | D6 disposition record + re-verify-fails branch; D7 approval persistence + review threading; review-verdict contract edits | 1, 2 | Scenario against spec Edge Cases rows |
| 6 | **Base resolution (independent)** | `detect-driver-context.sh` ahead/behind + fetch-status; `SKILL.md` recommend-and-confirm, fresh-only | — | Detector tests across in-sync/ahead/diverged/detached/fetch-failure |
| 7 | **Clean-tree startup & fix-cap (independent)** | D3 commit-or-stash offer + stale-artifact ask; D5 fix-cap accounting | 1 (plan-folder anchor) | Scenario: stray tree content offered commit-or-stash |

## RAID Log

### Risks

| ID | Risk | Likelihood | Severity | Blast Radius | Reversibility | Owner | Mitigation |
|----|------|------------|----------|--------------|---------------|-------|------------|
| R1 | A contract seam lands one-sided (writer grammar, scanner regex, path, or exclusion), so resume reconstructs zero items and every run misclassifies as fresh | Medium | High | Every resume | Reversible (revert the landing) | software-architect | Co-land all four seams in Work Unit 1 atomically; the round-trip harness gates the landing ([D-16](artifacts/implementation-decision-log.md#d-16-two-wave-build-order-with-four-contract-seams-co-landing-atomically), [D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)) |
| R2 | The relocated exclusion stays root-anchored, so tracked review files leak into the next item's scope findings and stall the gate | Medium | Medium | Every item after relocation | Reversible | devops-engineer | Match `.implement-work-items/` at any depth; re-verify all four exclusion sites ([D-10](artifacts/implementation-decision-log.md#d-10-relocate-the-artifact-area-by-deriving-its-path-from-the-work-items-directory), [D-9](artifacts/implementation-decision-log.md#d-9-drop-the-gitignore-hack-and-track-the-whole-artifact-area)) |
| R3 | A host-repo commit hook rejects bookkeeping commits (now far more numerous), stopping the run repeatedly | Low | Medium | The whole run | Reversible | devops-engineer | Surface the bookkeeping-commit path at the Step 2.1 plan-preview so a hook conflict is caught before item 1; a rejected pre-dispatch commit is a resumable stop, not the fix loop ([D-6](artifacts/implementation-decision-log.md#d-6-a-rejected-pre-dispatch-commit-is-a-marker-write-resumable-stop-not-a-fix-round)) |

### Assumptions

| ID | Assumption | What Changes If Wrong | Verifier | Status |
|----|------------|-----------------------|----------|--------|
| A1 | `dirname(NORM_PATH)` is a reliable anchor for the plan folder | A work-items file at the repo root with no containing plan folder has no place for the artifact area | devops-engineer (D-10 revisit criterion) | Open — verify against a repo-root work-items path |
| A2 | Only `git`+bash can be assumed in a target user repo | A record or test that needs `jq`/python refuses to run where neither exists | devops-engineer | Confirmed (`.discovery-notes.md:9-11`) |

## Testing Strategy

Sourced from the round-1 evidence (the round-2 `test-engineer` handoff errored). The plan adds a minimal pure-bash test harness (throwaway git repos + fixture ledgers, assuming only `git`+bash) ([D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)).

- **Observable behaviors to test:**
  - **Writer↔reader grammar round-trip (highest value):** `write-run-record.sh` output reconstructs to the exact four-token lifecycle in `scan-run-history.sh`, and the new appended blocks do not perturb that reconstruction — the documented silent-failure mode (`scan-run-history.sh:138-144`, "a writer that changes it silently reconstructs zero items").
  - **Scanner classification:** fresh / resume / refuse / no-base and per-item state, including the D4 path-derivation and the D10 done-from-ledger-only change.
  - **Detector D2 output:** ahead/behind counts and fetch-status across in-sync / ahead / diverged / detached-HEAD / fetch-failure.
- **Test doubles posture:** throwaway git repositories as the integration fixture; fixture ledger files as the input to the scanner. No mocking of git — exercise real git in a scratch repo.
- **Edge cases requiring coverage:** empty ledger, foreign-run trailer, unresolved `done`, a work-items path with `..`/`./`, and the W-1-vs-W-10 substring trap.
- **Test levels:** script-level integration via scratch repos (deterministic scripts); model-judgment behaviors (token choice, gate decisions) stay scenario/manual against the spec's Edge Cases table — not script-testable and deliberately not tested ([D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)).

## Security Posture

No authentication, authorization, PII, or secrets surface. The one input-handling commitment: the new D2 base-resolution and path-derivation code preserves the scripts' existing git-injection defenses — `--end-of-options` operand-pinning (`scan-run-history.sh:94,106`) and exact-key trailer matching — so a branch name or path can never be parsed as a git option ([D-19](artifacts/implementation-decision-log.md#trivial-decisions)).

## Operational Readiness

- **Observability:** the run's per-iteration history and bookkeeping are now committed and diffable — the operator can inspect any iteration after the fact (spec D10). Below-threshold dispositions are recorded per item at decision time.
- **Rollout / rollback:** this is a skill-definition change; "rollback" is reverting the landing. The four-seam atomicity (R1) is what keeps a partial landing from leaving resume broken.
- **Portability:** the only hard runtime dependency remains `git`+bash; no `jq`/`python3` floor is introduced ([D-1](artifacts/implementation-decision-log.md#d-1-run-record-stays-a-shell-parseable-line-grammar-no-json-no-hard-jq-or-python-dependency)).
- **Hook conflicts:** the Step 2.1 plan-preview states that bookkeeping commits will be made under the artifact dir, so a host-repo hook that rejects them is discovered before item 1 (R3).
- **Cost:** committing every iteration produces a denser per-item history; this is the accepted cost of the diffable-history model (spec Out of Scope — the driver never rewrites history, but tags commits so the operator can collapse them) ([D-8](artifacts/implementation-decision-log.md#d-8-four-distinct-commit-trailers-for-item-id-run-fixup-and-baseline)).

## On-Call Resilience Posture

- **Commit-before-dispatch fail-closed:** never dispatch onto a dirty tree; a rejected pre-dispatch commit is a resumable stop, distinguished from a clean-tree no-op via `git status --porcelain` ([D-6](artifacts/implementation-decision-log.md#d-6-a-rejected-pre-dispatch-commit-is-a-marker-write-resumable-stop-not-a-fix-round)).
- **Partial-write safety:** the committed record is append-only and the terminal ledger entry is the last write per item, committed after the code commit — an interruption leaves a re-verifiable state, not a falsely-done item ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- **Resume done-authority:** only the committed `done` entry means done; commit-presence never implies cleared ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- **Re-verify-fails path:** a post-gate below-threshold fix that reddens re-verify is never committed and never carried dirty into the next dispatch ([D-13](artifacts/implementation-decision-log.md#d-13-the-d6-re-verify-fails-branch-reuses-the-existing-fix-loop-and-committed-state-reset)).
- **Data integrity:** the writer script fails loud (non-zero exit, no partial commit) so a partial write is never staged ([D-4](artifacts/implementation-decision-log.md#d-4-one-mechanism-only-bookkeeping-writer-script)).
- **Deliberately excluded:** no commit retry/backoff and no idempotency-key store — the side effects are additive git commits and replay is benign, so idempotency machinery would be YAGNI ([D-5](artifacts/implementation-decision-log.md#d-5-rewrite-the-per-item-loop-to-commit-before-every-dispatch-and-every-iteration)).

## Definition of Done

- [ ] The writer↔reader round-trip harness passes: `write-run-record.sh` output reconstructs to the exact four-token lifecycle and new blocks do not perturb it ([D-3](artifacts/implementation-decision-log.md#d-3-new-durable-state-rides-in-separate-blocks-below-the-byte-preserved-log-block), [D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)).
- [ ] `state.json` is deleted and no code path reads it; `scope-baseline` resolves from the baseline trailer on resume ([D-2](artifacts/implementation-decision-log.md#d-2-delete-the-json-state-file-and-recover-scope-baseline-from-a-distinct-trailer)).
- [ ] A stopped mid-iteration run resumes on the ledger `done` entry and re-verifies an uncommitted-gate item rather than marking it done ([D-7](artifacts/implementation-decision-log.md#d-7-the-committed-done-entry-is-the-sole-resume-authority)).
- [ ] The relocated artifact area is excluded from scope findings at its nested depth ([D-10](artifacts/implementation-decision-log.md#d-10-relocate-the-artifact-area-by-deriving-its-path-from-the-work-items-directory)).
- [ ] `detect-driver-context.sh` emits ahead/behind and `fetch-status`; base resolution recommends and confirms fresh-only ([D-11](artifacts/implementation-decision-log.md#d-11-extend-the-context-detector-with-ahead-behind-counts-and-a-fetch-status-flag)).
- [ ] `SKILL.md` remains under the 500-line ceiling after the changes ([D-14](artifacts/implementation-decision-log.md#d-14-one-new-sub-agent-instructions-reference-that-also-carries-the-accumulated-corrections)).
- [ ] No hard `jq`/`python3` dependency is introduced anywhere in the record or tests ([D-1](artifacts/implementation-decision-log.md#d-1-run-record-stays-a-shell-parseable-line-grammar-no-json-no-hard-jq-or-python-dependency)).

## Specialist Handoffs for Implementation

- **`test-engineer`** — dispatch when Work Unit 1 (the record & commit model) is built; needs the writer/scanner contract and the fixture ledgers to author the round-trip harness the round-1 handoff could not deliver ([D-17](artifacts/implementation-decision-log.md#d-17-verify-the-two-scripts-with-a-minimal-pure-bash-round-trip-harness)).

## Deferred (YAGNI)

### A standalone `preference-memory.md` reference for D9
- **Why deferred:** single-consumer file (simpler-version test) — D9's injection rules fold into `sub-agent-instructions.md`, its storage into a record block, and its capture into a `SKILL.md` step, so a separate reference would have one reader.
- **Reopen when:** OI-2's correction-class judgment rubric grows into substantial standalone content that a third independent consumer needs.
- **Source:** R1, software-architect (A3) → [D-14](artifacts/implementation-decision-log.md#d-14-one-new-sub-agent-instructions-reference-that-also-carries-the-accumulated-corrections).

## Open Items

- **OI-1 (inherited from spec):** how much discretion the driver has when it judges a below-threshold finding "genuinely matters."
  - **Resolves when:** real runs show whether the durable per-item disposition record is a sufficient bound.
  - **Blocks implementation:** No — the disposition record ([D-3](artifacts/implementation-decision-log.md#d-3-new-durable-state-rides-in-separate-blocks-below-the-byte-preserved-log-block)) plus re-verify ([D-13](artifacts/implementation-decision-log.md#d-13-the-d6-re-verify-fails-branch-reuses-the-existing-fix-loop-and-committed-state-reset)) implement the default now.
- **OI-2 (inherited from spec):** the criterion for naming a reusable "correction class."
  - **Resolves when:** real runs show whether accumulation is consistent under the "general corrections only" default.
  - **Blocks implementation:** No — the default rule is implementable now, and its home is fixed ([D-14](artifacts/implementation-decision-log.md#d-14-one-new-sub-agent-instructions-reference-that-also-carries-the-accumulated-corrections)).

## Summary

- **Outcome delivered:** a HOW-to-build plan for the hardening bundle, centered on the record-and-commit-model keystone, that keeps the skill pure-bash + git, rewrites the per-item loop around commit-every-iteration, and lands the four contract seams atomically so resume never breaks.
- **Team size:** 5 contributing specialists (+ PM) — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Rounds of facilitation:** 2 (round 2's handoff errored; strategy folded from round-1 evidence) — see [artifacts/implementation-iteration-history.md](artifacts/implementation-iteration-history.md)
- **Decisions committed:** 19 (17 full, 2 trivial) — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by evidence:** 19 — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Decisions settled by junior-developer reframing:** 0
- **Decisions settled by user input:** 0 (the operator's flagged ledger question was resolved by codebase evidence)
- **Rejected alternatives recorded:** ~30 across the 17 full decisions — see [artifacts/implementation-decision-log.md](artifacts/implementation-decision-log.md)
- **Open items remaining:** 2 (both inherited from the spec, both non-blocking)
- **Recommendation:** Ship as planned. One recorded dissent (junior-developer on the writer script, [D-4](artifacts/implementation-decision-log.md#d-4-one-mechanism-only-bookkeeping-writer-script)) resolved under disagree-and-commit; one assumption (A1, `dirname` anchor) to verify at build time.
