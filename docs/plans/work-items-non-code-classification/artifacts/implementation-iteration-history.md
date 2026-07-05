# Implementation Iteration History: Non-code, meta, and non-deliverable work items

<!--
Records how the implementation plan evolved across discussion rounds. Committed
decisions live in [implementation-decision-log.md](implementation-decision-log.md);
the primary plan lives in [../feature-implementation-plan.md](../feature-implementation-plan.md).
Per-round facilitation is deterministic (no separate facilitation files). `Decisions
produced:` and `Changed in plan:` are backfilled during the project-manager's synthesis step.
-->

## R1: Parallel specialist review

- **Specialists engaged:** `han-core:structural-analyst`, `han-core:edge-case-explorer`, `han-core:on-call-engineer`, `han-core:junior-developer` (aggregation deterministic; the spec-maturity gate did not trip, so no `han-core:project-manager` facilitation pass was made).
- **New input provided:** the settled feature specification, its decision log / team-findings / technical notes, the discovery notes, and the predecessor `autonomous-driver-hitl-support` implementation plan for altitude.
- **Claim ledger:**

  | # | Claim | Supporting specialists | State |
  |---|-------|------------------------|-------|
  | 1 | Four startup refusals live **inline in Step 1.7**, not a new reference file (short single-condition rules; one call site; Step 1.7 already net-deleted the tdd-only refusal in the HITL feature) | structural R1; edge-case F-1/F-3 | Evidenced |
  | 2 | Refusal **check sub-order**: (1) `none, AFK` inside the "Drivable" bullet → (2) `Type` validity → (3) `None`-on-non-`verification` → (4) `AFK`-review-on-`verification`/`None`; one refusal reported per halted item (checks 3/4 depend on the resolved `Type` from check 2) | edge-case F-1 | Evidenced |
  | 3 | **No shared refusal file across plugins** — deliberate duplication + atomic co-land; a shared file is the lightest cross-skill enforcement machinery the spec's Out of Scope forbids, and crosses the `han-planning`→`han-coding` boundary the suite has no mechanism for | structural R2 | Evidenced (YAGNI-rejected) |
  | 4 | **Catalog** gains 3 new rows (edit-existing-plugin, verification, spike) + the row-5 reframe (`guidance`→`general-purpose` agent) + the `general-purpose`-exempt-from-never-auto-AFK note + the Overrides-note refusal rule | structural R3; edge-case F-10 | Evidenced |
  | 5 | Both contract files (`build-report-contract.md`, `human-review-capture.md`) are **generalized in place**, not new files (Step 3.3 pastes them verbatim; a second file forces new body-dispatch routing) | structural R4; edge-case F-8/F-9 | Evidenced |
  | 6 | **Template:** `Type` is the first routing field (before `Requires pre-work decisions`); `Verification` rename in place; D18 trigger narrowed in the template field definition **and** the catalog classification step | structural R5; edge-case F-2; junior OQ8 | Evidenced |
  | 7 | `Type` is **not** added to Step 1.7 "Fields present"; absent → `deliverable`; the driver never parses `Type`-as-required nor `Verification` (backward compat) | edge-case F-2/F-12 | Evidenced |
  | 8 | `general-purpose` is **exempt** from the Step 1.7 installed-skill/drivability check (T1: built-in, always available) — the plan step T1 requires | edge-case F-4; junior OQ5; structural R3 | Evidenced |
  | 9 | No-output completion needs a **distinct state.json marker** + a Step 3.4 no-output branch + a Step 4 no-commit bucket + a Halt-Procedure trace (a bare `commit-range: null` cannot distinguish "done, no commit" from "not yet done") | on-call F1/F4; edge-case F-5/F-7; junior OQ7 | Evidenced |
  | 10 | **Idempotency (D14)** must be wired to an authored constraint line in the catalog verification row and the template `Verification` guidance ("a no-output verification must be side-effect-free / safe to re-run") — the fresh-branch recovery is amnesiac and re-runs it | on-call F2; junior OQ7 | Evidenced |
  | 11 | **Clean-tree assertion:** primary at the no-output item's own completion (correct attribution of stray files), backstop at Step 3.1 before the `scope-baseline` snapshot | on-call F3; edge-case F-6 | Evidenced (on-call refines edge-case's placement) |
  | 12 | **Compaction budget:** this feature is *net growth* at ~5 body sites, so the predecessor's net-deletion offset does not apply — split short refusal *rules* inline (structural) from multi-step no-output *mechanics* to a reference file (on-call), and add a Definition-of-Done gate measuring the body against the ~5k cap | on-call F6 **vs** structural R1/R4; junior OQ4 | Disputed → resolved by the inline-rules / reference-mechanics split + a body-size DoD gate |
  | 13 | The **spike build dispatch must carry the Expected path to the builder** as the finding target (today `Expected paths` reaches only the reviewer) — the AFK half of F14 | junior OQ3 | Evidenced (single agent, cited review-findings F2) |
  | 14 | The **spike review defaults to a human soundness read** (`none, HITL`), independent of the AFK build marker, so an AFK reviewer cannot rubber-stamp a fabricated-but-plausible finding; coherent with D8's stated "second-reader human read" and the agent-drafts/human-reviews split; does **not** reopen D19 build autonomy | on-call F5 | Evidenced (D8 intent; F2 rubber-stamp analog) |
  | 15 | D19's "recoverable halt, not corruption" is a **Disputed prediction** of AFK-spike-gate sub-agent behavior: edge-case F-11 predicts non-contract output → fail-closed halt (recoverable); on-call F5 predicts a well-formed fabricated report → passes the parse → commits (corrupting). The HITL-review default (#14) covers both; a proving dry-run is the resolution instrument | on-call F5 **vs** edge-case F-11 | Disputed → proving dry-run DoD gate + HITL-review mitigation |
  | 16 | **Escalate-and-resume / AFK-with-escalation stays out of scope**; the build-report contract does **not** gain a `blocked`-from-skill-gate path this feature (guard against over-building past D1/D19) | edge-case F-11; junior (Review History) | Evidenced |
  | 17 | **Verification model:** read-the-file contract checks C-1..C-12 + dry-runs A-1..A-12; two proving dry-runs (D14 idempotency, D19 spike-gate) as DoD gates on the predecessor's A3/A7b pattern | edge-case F-1..F-12; on-call F5 follow-on; junior OQ6 | Evidenced (test-engineer named to consolidate/own) |
  | 18 | **No-ADR-store fallback:** the producer catalog note for D18's record-worthy routing must say what to record when the target repo has no ADR home | junior OQ1 | Anecdotal → resolve by evidence |
  | 19 | **Guidance-reachability** in a target repo is a surfaced assumption (D15) → record as a RAID Assumption with the human-read backstop (D16) | junior OQ2 | Evidenced |

- **Open Questions raised:**
  - **OQ-1** — When the target repo has no ADR store, what does the producer emit for a record-worthy pre-work decision (D18)? (plan-level)
  - **OQ-2** — state.json: a distinct terminal state (`done-no-commit`) vs a `no-commit` flag on the existing `done` state? (plan-level)
  - **OQ-3** — the spike's Expected path must reach the *builder* (dispatch-prompt change), not just the reviewer. (plan-level)
  - **OQ-4** — Disputed: does an AFK interactive-skill spike hitting an operator gate fabricate-and-commit (corrupting) or return non-contract output and fail-closed-halt (recoverable)? (plan-level; needs a proving dry-run)
  - **OQ-5** — Disputed: refusals inline vs pushed to a reference file, under the compaction budget. (plan-level; resolved by the split + a DoD body-size gate)
- **Spec-maturity tags:** plan-level — all 19 claims / 5 OQs. spec-level — 0 firm (on-call F5 challenges D19 but is plan-level-resolvable via the HITL-review mitigation, with a *conditional* escalation trigger if the proving dry-run falsifies D19). T#-contradiction — 0 (all four specialists affirmed T1). **Spec-maturity gate: did not trip** (needs ≥2 T#-contradictions by ≥2 specialists, or ≥5 spec-level by ≥3 specialists).
- **Resolution source:** OQ-1 → evidence (R2 aggregation); OQ-2 → evidence (R2 aggregation); OQ-3 → evidence (R2 aggregation); OQ-4 → test-engineer proving dry-run (R2) + HITL-review mitigation; OQ-5 → evidence (R2, the inline/reference split).
- **Decisions produced:** D-1 (compaction split, disputed this round, resolved R2), D-2, D-3, D-4, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12 (disputed this round, adjudicated R2), D-14, D-15 (established this round, DoD confirmed R2).
- **Changed in plan:** Implementation Approach (Architecture and Integration Points; Data Model and Persistence; Runtime Behavior; External Interfaces); Decomposition and Sequencing; RAID Log (Risks, Assumptions, Dependencies); On-Call Resilience Posture; Deferred (YAGNI); Open Items.
- **Project-manager next-step recommendation:** Continue facilitation — re-engage `han-core:test-engineer` (named by junior-developer and on-call-engineer) to consolidate the C-1..C-12 / A-1..A-12 verification set, design the two proving dry-runs as Definition-of-Done gates, and adjudicate the Disputed OQ-4 spike-gate prediction. One round remains under the medium cap.

## R2: Test-engineer consolidation and dispute adjudication

- **Specialists engaged:** `han-core:test-engineer` (the handoff named by junior-developer and on-call-engineer in R1; aggregation deterministic, gate did not trip).
- **New input provided:** the R1 claim ledger and the two Disputed claims (OQ-4 spike-gate behavior, OQ-5 refusal placement), with a directive to consolidate the C#/A# verification set, design the two proving dry-runs as DoD gates, and adjudicate OQ-4.
- **Claim ledger:**

  | # | Claim | Supporting specialist | State |
  |---|-------|-----------------------|-------|
  | 20 | Consolidated verification model: **C-1..C-12** read-the-file contract checks (each mapped to a driver step / reference file / catalog section) + **A-1..A-12** dry-runs (each mapped to an execution mode), with doubles posture "none — real skills against scratch work-items files" and levels "contract-conformance + end-to-end dry-run only" | test-engineer | Evidenced (predecessor Testing Strategy model) |
  | 21 | **PD-1 (idempotency, D14)** proving run as a DoD gate: a no-output verification re-executes safely on a fresh branch after a later-item halt; falsified only by a side-effecting check or cross-branch state bleed | test-engineer | Evidenced |
  | 22 | **PD-2 (spike-gate, D19) resolves OQ-4:** the realistic failure is a *bad/incomplete* finding passing the parse (not a fabrication from nothing); the edge-case "STATUS: blocked → recoverable halt" prediction is more likely for the vague/compound gates, a real-but-stale/incomplete finding for the mis-route/overwrite gates. The **HITL spike-review default (claim 14) covers both predictions** — under the halt path no commit and no dependent item runs; under the commit path the human soundness read fires before any dependent item consumes the finding. D19's "not corruption" holds *given* claim 14; PD-2 makes it observable. Only falsified if a committed finding bypasses the HITL review (→ escalate to spec owner) | test-engineer (adjudicating on-call F5 vs edge-case F-11) | Disputed → **resolved** (HITL-review mitigation + PD-2 DoD gate; no D19 reopening) |

- **Open Questions raised:** none new. The five R1 OQs resolved this round:
  - **OQ-1** → evidence: the producer catalog note records a record-worthy decision where the repo keeps decision records (an ADR store if present), else the plan's own decision log; the inline flag is retained for single-sentence judgment calls (D18). Non-blocking.
  - **OQ-2** → evidence: a distinct terminal state `done-no-commit` in state.json (a single field the Step 3.4 / Step 4 / Halt / in-session-re-ground read sites branch on, and which cannot be internally inconsistent the way `done` + a separate `no-commit` boolean could).
  - **OQ-3** → evidence: the AFK spike build dispatch carries the item's Expected path to the builder as the finding target (C-12).
  - **OQ-4** → test-engineer proving run PD-2 + the HITL-review mitigation (claim 14). Resolved without reopening D19.
  - **OQ-5** → evidence: short single-condition refusal *rules* stay inline in Step 1.7; the multi-step no-output *mechanics* (clean-tree assertion, no-commit recording, summary labeling) move to a reference file; a DoD gate measures the post-edit body against the ~5k compaction cap.
- **Spec-maturity tags:** plan-level — all. spec-level — 0. T#-contradiction — 0. **Gate did not trip.** OQ-4's only path to a spec-level escalation is a *conditional* one: if PD-2 during implementation shows a committed finding bypassing the HITL review, that falsifies D19's "not corruption" premise and is escalated to the spec owner then — it is not a spec-immaturity signal now.
- **Resolution source:** OQ-1, OQ-2, OQ-3, OQ-5 → evidence; OQ-4 → test-engineer proving-run design + evidence.
- **Decisions produced:** D-13 (verification model + PD-1/PD-2 proving runs, new this round); D-1 (resolved the OQ-5 inline-rules / reference-mechanics split and added the body-size DoD gate); D-12 (PD-2 adjudication confirming the `none, HITL` default covers both gate-behavior predictions); D-15 (atomic co-land confirmed as a DoD gate).
- **Changed in plan:** Testing Strategy; Definition of Done; On-Call Resilience Posture (spike-review soundness default and the PD-1/PD-2 gates); Decomposition and Sequencing (the verification-pass work unit); Deferred (YAGNI) (automated test scaffolding); Open Items (OI-2 D19 falsification trigger).
- **Project-manager next-step recommendation:** Go to synthesis. Medium round cap (2) reached; no new findings of consequence, no named handoffs outstanding, all Open Questions resolved by evidence or the proving-run design. The two Disputed claims are resolved (OQ-5 by the inline/reference split; OQ-4 by the HITL-review mitigation, with PD-2 as the observable DoD gate).
