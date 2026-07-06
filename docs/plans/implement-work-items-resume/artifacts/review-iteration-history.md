# Review Iteration History: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

Rounds of `iterative-plan-review` over [../feature-specification.md](../feature-specification.md).
Findings detailed in [review-findings.md](review-findings.md); mechanics in
[feature-technical-notes.md](feature-technical-notes.md).

Review commission: **sync the spec with the current skill implementation.** The spec was
frozen at `92fd266`; the `implement-work-items` skill gained item `Type` classification,
no-output completion, skill-less `none` builds, and human-confirmation reviews in the
commits that followed (`74980fc`, `7d8d1a4`, `71e085c`).

## R1 — Team review (round 1 of up to 2)

- **Mode:** team
- **Spec-aware mode:** engaged (feature-specification.md; T# routing active, `feature-technical-notes.md` present)
- **Size:** medium (team mode, 4-agent roster, 2-round cap) — one spec file, single system (the driver), but the "code commit per item" assumption threads through Primary Flow, three alternate flows, Edge Cases, Coordinations, and the technical notes.
- **Specialists engaged:** `han-core:junior-developer` (required), `han-core:adversarial-validator` (required), `han-core:evidence-based-investigator` (mandatory — spec rests on codebase claims about the skill's contracts and the review verifies against the current skill), `han-core:gap-analyzer` (the task is a gap analysis between the frozen spec and the evolved skill). Structural/behavioral/concurrency/architect/data specialists excluded by the spec-aware roster rule.
- **Findings raised:** F1, F2, F3, F4, F5, F6, F7 (major); F8, F9, F10 (minor). All four agents converged on one root assumption — every item produces a code commit and is classified on resume by verification plus a non-empty changed-file set — which the no-output `audit` item class refutes. Adversarial-validator identified F1 (Primary Flow step 5's unconditional commit) as **corrupting**, not cosmetic. Agents independently confirmed the not-gapped cases: `spike` commits its finding and fits the model unchanged; the AFK-review-on-audit refusal is enforced at startup validation, so no in-progress AFK-review audit can reach the resume path (F10 records the deliberate non-change).
- **Changed in plan:** Primary Flow (steps 5, 7); Alternate Flows (Resuming a partially complete run; Resuming an in-progress item; Resuming an interrupted foreground item; A run reaches a state it cannot settle; Ledger and history disagree on resume); Edge Cases (committed-but-unmarked row split into output-item and no-output-audit rows; commit-resolution row qualified to output items; stop-the-run row); Coordinations (done-entry description; review-records row); User Interactions (Feedback resume summary).
- **Changed in tech-notes:** T1 (entry list gains the no-commit done outcome; resolution check scoped to output items; `plan-implementation` delegation notes the no-commit form; provenance); T2 (foreground wording generalized to cover skill-less `none` builds; provenance).
- **YAGNI:** the sync was carried entirely by behavioral clauses and one done-entry variant, not new machinery. Four YAGNI guardrails from junior-developer were honored during resolution: no durable persistence of audit confirmations (D13 already keeps review records ephemeral); no runtime idempotency/side-effect guard (the existing catalog constraint that no-output audits are side-effect-free is cited in one clause instead); no separate audit-ledger subsystem (the no-commit done outcome is a variant of the existing done entry); `spike` gets terminology-only change, no new resume behavior.
- **Mechanics leaking into spec:** one candidate (F8, "the item's code commit"). Resolved as terminology precision ("code commit" → "commit") — the start-of-item-to-HEAD range mechanic it sits beside is already owned and accepted by T1, so no new T# was extracted.
- **Stability assessment:** not stable after R1 — R1 produced 7 major findings, so the deterministic stop rule does not fire. Round 1 was discovery-and-resolution; a focused R2 verification is warranted to confirm the edits are complete, internally consistent, and introduce no new contradictions.
- **Next step:** run R2 as a focused verification pass (adversarial-validator re-attacking the edited spec for residual no-output holes; gap-analyzer re-sweeping for any remaining `Type`-coverage gap), then apply the stop rule.

## R2 — Team verification (round 2 of 2, size cap)

- **Mode:** team
- **Spec-aware mode:** engaged
- **Specialists engaged:** `han-core:gap-analyzer` (verify each R1 fix closed its gap and is internally consistent), `han-core:adversarial-validator` (re-attack the edited spec for residual no-output holes and self-introduced contradictions). Focused two-agent pass — the two required generalists most suited to verifying a just-edited artifact.
- **Findings raised:** F11, F12 (major); F13, F14, F15, F16 (minor). Gap-analyzer verified F1–F10 all correctly closed and consistent, surfacing only wording residues (step-4 "code commit", T1 metadata, one naming-drift row, a D18-scope clarity point). Adversarial-validator surfaced two substantive residuals: **F11** — the R1 F3/F7 edit was internally contradictory (a clean tree cannot prove a no-output audit's *ephemeral* human confirmation, so it cannot forward-reconcile; corrected to re-run-and-re-confirm), and **F12** — a second unconditional-commit path in the re-attempt Exit that F1 did not cover (a no-output audit would be spuriously committed). Both were self-introduced or missed in R1 and are now fixed.
- **Changed in plan:** Primary Flow (steps 4, 5); Alternate Flows (Resuming a partially complete run; Resuming an in-progress item; Operator fixes an issue and re-attempts; A run reaches a state it cannot settle); Edge Cases (no-output-audit row; commit-resolution row naming); Coordinations (review-records row).
- **Changed in tech-notes:** T1 (`Referenced in spec` metadata gains Alternate Flows).
- **Adversarial over-reach adjudicated:** none material — V1/V2/V7 correctly exposed that the R1 F3 fix over-reached; the correction (re-run + re-confirm) is simpler and more correct. V5/V6 were minor and taken as light tightenings. The agent's noted "already-complete early-exit for all-done-or-skipped" is a pre-existing spec condition unrelated to this sync and out of scope for the commission.
- **Post-edit self-verification:** re-read the edited resume flows and grepped the spec for residual unconditional-commit phrasing — remaining "code commit" references are all correct contrasts (bookkeeping entries vs. the code commits output items produce), not per-item assertions. No contradiction remains.
- **Stability assessment:** the R2 findings were corrections to R1 edits, now resolved; a post-edit self-verification found the spec internally consistent and synced. The medium size cap (2 rounds) is reached; the review stops here.
- **Next step:** none — the sync is complete. Two `plan-implementation` delegations remain (pre-existing Open Items), neither blocking.
