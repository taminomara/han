# Review Findings: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

Findings from `iterative-plan-review` of `feature-specification.md`. This review was
commissioned to **sync the spec with the current skill implementation**: the spec was
frozen at commit `92fd266`, before the `implement-work-items` skill gained item `Type`
classification (`deliverable`/`audit`/`spike`), no-output completion (`done-no-commit`,
no code commit, an empty changed-file set as the expected complete result), skill-less
`none` builds, and human-confirmation reviews for audits. Those landed in `74980fc`,
`7d8d1a4`, and `71e085c`.

The spec's load-bearing assumption — **every item produces a code commit, and a resumed
item is classified by verification plus a non-empty changed-file set** — is refuted by the
no-output `audit` item class, which is the root of every major finding below.

Cross-references: iteration history in [review-iteration-history.md](review-iteration-history.md);
plan under review is [../feature-specification.md](../feature-specification.md); mechanics in
[feature-technical-notes.md](feature-technical-notes.md).

## Major findings

### F1: Primary Flow step 5 mandates a code commit for every clearing item

- **Agent:** self-review (consolidating gap-analyzer GAP-001, evidence-based-investigator E2, junior-developer JD-001, adversarial-validator V3)
- **Category:** assumption refuted (spec-vs-implementation conflict)
- **Finding:** Primary Flow step 5 reads "When the item clears its gate and the driver commits the item's code as today, it then records a done entry to the branch referencing the item's code commit." The completion path is unconditional. A no-output `audit` (`Expected paths: None`) must **not** commit — the current skill (`SKILL.md` Step 3.4, `references/no-output-completion.md`) forks before the commit, sets `done-no-commit`, asserts a clean tree, and advances. A driver following the spec literally would attempt a commit with an empty staging area: either a no-empty-commit hook rejects it and the driver burns fix rounds and halts on a legitimately completed item, or it injects a spurious empty commit that poisons the item's commit range and the D11 integrity check. Adversarial-validator classed this **corrupting**, not cosmetic.
- **Evidence considered:** `han-coding/skills/implement-work-items/SKILL.md:271-273` (the no-output fork before the commit path); `references/no-output-completion.md:11-14` (skip the commit, set `done-no-commit`); spec Primary Flow step 5. Trust class: codebase (running skill definition). Corroborated by all four agents.
- **Resolution:** Primary Flow step 5 rewritten to fork before the commit: an output item commits and records a done entry referencing its code commit; a no-output `audit` skips the commit and records a **no-commit done outcome** instead, then advances.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 5)
- **Changed in tech-notes:** —

### F2: The durable done-entry invariant has no no-commit variant

- **Agent:** self-review (consolidating gap-analyzer GAP-001, evidence-based-investigator E1/E2, adversarial-validator V4)
- **Category:** missing behavior
- **Finding:** The spec states three times — Coordinations ("done entries referencing each item's code commit"), D13, and technical note T1 ("a done entry per item referencing that item's code commit") — that a done entry carries a code-commit reference. A no-output audit completes with `done-no-commit` and no commit. The durable-record schema therefore has no legal form for a completed no-output audit, and T1's enumerated entry list (opening, start-of-item, done, skip) omits the no-commit done outcome. This is the record-format facet of F1 and propagates to F3 (forward-reconcile), F4 (integrity check), and F5 (summaries).
- **Evidence considered:** spec Coordinations table, `feature-technical-notes.md:8` (T1 entry list); `references/no-output-completion.md:11-14` (`done-no-commit` is a distinct terminal state). Trust class: codebase. Note: the spec's Open Items already delegate the *exact record form* to `plan-implementation`; this finding fixes the *behavioral invariant* the form must satisfy, not the form.
- **Resolution:** Coordinations reworded so a done entry references the code commit for an output item **or** records a no-output audit's completion without a commit. T1's entry list extended to include the no-commit done variant, with a note that `plan-implementation`'s record form must be able to express a done outcome that carries no commit reference. Per the YAGNI guardrail this is a **variant of the existing done entry**, not a new record stream.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Coordinations
- **Changed in tech-notes:** T1

### F3: Resume rebuilds a correctly completed no-output audit (empty-tree rule + D16 blindness)

- **Agent:** self-review (consolidating gap-analyzer GAP-002/GAP-003, evidence-based-investigator E3/E5, junior-developer JD-002/JD-003, adversarial-validator V1/V2)
- **Category:** edge case / assumption refuted
- **Finding:** In "Resuming an in-progress item," the spec's forward-reconcile (D16) fires only when "a code commit exists in the item's start-of-item-to-HEAD range." A no-output audit never commits, so D16 is structurally blind to it and always misses. The item then falls through to "an empty or partial tree ... is treated as partial and rebuilt from the start-of-item entry." But for a no-output audit an empty tree is the **expected complete result** (`no-output-completion.md`, `build-report-contract.md`: an empty FILES list clears). So a completed no-output audit whose `done-no-commit` entry failed to land (a killed session or rejected bookkeeping commit — a case the spec's own Edge Cases already plans for) is rebuilt on every resume. Re-running is *safe* (the catalog constrains a no-output audit to side-effect-free checks) but the spec violates its own "done and skipped items are not rebuilt" guarantee and cannot distinguish "no-output audit done" from "deliverable not started" without reading the item's `Type`.
- **Evidence considered:** spec "Resuming an in-progress item"; `references/no-output-completion.md:3-4,22-25` (empty tree is the completion; re-execution is safe because side-effect-free); `references/build-report-contract.md:28-29` (empty FILES clears when `Expected paths: None`); `SKILL.md:122-128` (Type/no-output guards). Trust class: codebase. Four-agent corroboration.
- **Resolution:** "Resuming an in-progress item" gains a `Type`-branch ahead of the empty-tree rule, scoping the empty-tree-means-partial rule to output-producing items. **Superseded in round 2 by F11:** the R1 framing ("a clean tree *is* the completed signal → record the no-commit done outcome and advance") was found internally contradictory in R2 — a clean tree does not prove the audit's *ephemeral* human confirmation ever happened (D13), so it cannot forward-reconcile. The corrected behavior (F11) re-runs the side-effect-free audit and re-asks the operator to confirm, then records the no-commit done outcome; it still does not treat the expected empty tree as leftover partial work to discard. See F11 for the corrected plan text.
- **Resolved by:** evidence (corrected in R2, see F11)
- **Raised in round:** R1 (corrected in R2)
- **Changed in plan:** Alternate Flows (Resuming an in-progress item); Edge Cases
- **Changed in tech-notes:** —

### F4: The done-entry integrity check false-alarms on a no-commit done entry

- **Agent:** self-review (consolidating gap-analyzer GAP-004, adversarial-validator V4/V6)
- **Category:** failure mode / edge case
- **Finding:** D11's only commit-level integrity check for done entries is "a done entry's referenced commit no longer resolves → surface as a divergence and ask." A no-commit done entry has no commit to resolve. Under the spec's default-deny posture ("any resume state it cannot positively classify as safe is surfaced-and-asked"), the driver could treat a well-formed no-commit done entry as unclassifiable and surface a legitimately completed no-output audit as a ledger divergence, offering the operator abort/restart/proceed for a run that is actually fine.
- **Evidence considered:** spec "Ledger and history disagree on resume" and the matching Edge Cases row; `references/no-output-completion.md:13-14` (`done-no-commit` is a distinct, legitimate terminal state). Trust class: codebase. This is the resume-integrity mirror of F2.
- **Resolution:** The commit-resolves check is qualified to done entries that carry a commit (output items). A well-formed no-commit done outcome for a no-output audit is defined as **valid, not a divergence** — its integrity check is that the entry is present, well-formed, and its item's tree is clean at that item's baseline. The "Ledger and history disagree on resume" divergence list and the Edge Cases row are qualified accordingly.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows (Ledger and history disagree on resume); Edge Cases
- **Changed in tech-notes:** —

### F5: The resume and completion summaries lack a no-commit outcome bucket

- **Agent:** self-review (consolidating gap-analyzer GAP-005, junior-developer JD-004, adversarial-validator V5/V6)
- **Category:** missing behavior / coordination
- **Finding:** The resume summary's inventory is done / skipped / in progress / remaining, and Primary Flow step 7 reports "the completion summary as today." Both are stale: the current completion summary (`SKILL.md` Step 4, `no-output-completion.md` Reporting) keeps no-output completions "distinct from committed items so a legitimate empty audit is not read as a silent no-op." "As today" no longer means what it meant at `92fd266`. A no-output-done item has no commit, so folding it into "done" misreports it (implying a commit that does not exist and, per F4, tripping the integrity check) and folding it into "halted" is wrong. The all-no-output run is a corner of this: "every item done → already-complete" must not then run a commit-resolves check on items that have no commit.
- **Evidence considered:** spec "Resuming a partially complete run," User Interactions (Feedback), Primary Flow step 7; `SKILL.md:297-302` (completion summary now names `done-no-commit` outcomes with a count); `references/no-output-completion.md:18-20`. Trust class: codebase; git diff `92fd266..HEAD` confirms "as today" went stale at `74980fc`/`7d8d1a4`.
- **Resolution:** Both summaries gain a no-commit completion outcome distinct from committed-done, skipped, in progress, and remaining. Primary Flow step 7's "as today" is replaced with an explicit outcome enumeration that names the no-output completion. The already-complete exit is qualified so a done-but-no-commit item is not run through a commit-resolves check.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Primary Flow (step 7); Alternate Flows (Resuming a partially complete run); User Interactions
- **Changed in tech-notes:** —

### F6: The recovery menu's "stop" label and the halt frame's commit-range drop the no-output caveat

- **Agent:** self-review (consolidating evidence-based-investigator E6, gap-analyzer GAP-006, adversarial-validator V7)
- **Category:** edge case / user-facing failure
- **Finding:** The spec's recovery menu (D5) rewrites the halt frame's fifth part, and labels "Stop the run (resumable)" as "leaving completed items committed." The current skill's Halt Procedure part 5 (amended after the spec froze) names the caveat the spec's replacement drops: "a no-output `audit` recorded `done-no-commit` carries no commit and is not in that range ... name it separately so a cherry-pick-forward does not drop it." For a run containing no-output audits the spec's "leaving completed items committed" label is factually wrong, and an operator cherry-picking the named commit range forward would silently lose the completed audits. The consequence-stated label is the only information the operator has at that moment.
- **Evidence considered:** spec "A run reaches a state it cannot settle" (recovery menu), Primary Flow step 6; `SKILL.md:325-331` (part 5 with the no-output caveat, added in `7d8d1a4`); `references/no-output-completion.md:21-24`. Trust class: codebase.
- **Resolution:** The "stop" option's consequence label and the halt frame's completed-items reference are reworded to name two categories of preserved work: output items committed (the commit range) and no-output audits recorded without a commit (listed by identifier, not in the range). This keeps the recovery menu's promise honest for runs that mix item types.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows (A run reaches a state it cannot settle); User Interactions
- **Changed in tech-notes:** —

### F7: Resume "re-review" is undefined for a no-output audit / human-confirmation review

- **Agent:** self-review (consolidating evidence-based-investigator E4, junior-developer JD-007)
- **Category:** behavioral commitment
- **Finding:** The spec leans on "re-run verification as the completeness signal" (D6) and "a resume re-reviews the item" (Coordinations, D13). For a no-output audit there is no changed file to verify and no artifact to re-read: the review is a human confirmation ("operator confirmed result"), and an `AFK` review on an audit is refused at validation. On resume, "re-review" collapses to "re-run the (side-effect-free) audit and re-ask the operator to confirm," a human step that cannot be dispatched unattended. The spec's re-review model assumes a diff and an optionally-unattended reviewer; neither holds for this item class.
- **Evidence considered:** spec Coordinations ("Review durable records"), D6, D13; `SKILL.md:122-128` (AFK review on an audit is a refusal); `references/human-review-capture.md:13-16` ("no change to read ... operator confirmed result"). Trust class: codebase.
- **Resolution:** The relevant flow notes that for a no-output audit the resume re-confirmation is a human step over a re-run result rather than a diff re-read, and cannot run unattended. Per the YAGNI guardrail, the confirmation is **not** persisted durably (D13 already keeps review records ephemeral); the resume re-asks.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows (Resuming an in-progress item); Coordinations
- **Changed in tech-notes:** —

### F11: The F3/F7 resolution was internally contradictory for a cross-session resume

- **Agent:** self-review (round-2 adversarial-validator V1/V2/V7)
- **Category:** edge case (self-introduced contradiction in a round-1 edit)
- **Finding:** The round-1 edit to "Resuming an in-progress item" said both "a clean tree with no stray files **is** the completed signal → record the no-commit done outcome and advance" (F3) **and** "if the human confirmation was never captured, re-run and re-ask" (F7). But a no-output audit's human confirmation is ephemeral (D13 keeps review records local and not durable), so "confirmation was never captured" is **always** true on a cross-session resume — the two clauses demand opposite actions for the exact killed-session case F3 was written to handle. Root cause: unlike an output item (whose code commit is durable proof it cleared its gate), a no-output audit that is in-progress by definition has **no durable proof of gate-clearance** — its only proof would be the no-commit done outcome, which is absent in the in-progress branch. A clean tree proves "no output was produced," not "a human confirmed the result." So there is no valid forward-reconcile for a no-output audit; the honest, safe move is to re-run (side-effect-free) and re-confirm. The round-1 edit to the Coordinations "re-reviews the item" row also read as a universal that contradicted the output-item forward-reconcile's advance-without-re-review (V2).
- **Evidence considered:** spec "Resuming an in-progress item" and Coordinations (post-R1 text); decision log D13 (confirmations/review records ephemeral); `references/human-review-capture.md` (local record under gitignored `.implement-work-items/`, does not survive a session). Trust class: codebase + the spec's own decision log. Corroborated by both round-2 agents (adversarial V1/V2/V7; gap-analyzer confirmed the fix on re-read).
- **Resolution:** "Resuming an in-progress item" rewritten: an in-progress no-output audit cannot be forward-reconciled from history (a clean tree does not prove the human confirmation happened); the driver re-runs the side-effect-free audit and re-asks for confirmation, then records the no-commit done outcome, and does not treat the expected empty tree as leftover partial work to discard. The Edge Cases row and the Coordinations "re-reviews" wording were reconciled to match (the latter softened to "a resume that must review an item does so fresh," with the forward-reconcile-advances-without-re-review case named explicitly).
- **Resolved by:** evidence
- **Raised in round:** R2
- **Changed in plan:** Alternate Flows (Resuming an in-progress item); Edge Cases; Coordinations
- **Changed in tech-notes:** —

### F12: The re-attempt Exit commits unconditionally — a no-output audit would be spuriously committed

- **Agent:** self-review (round-2 adversarial-validator V3)
- **Category:** assumption refuted (missed sibling of F1)
- **Finding:** F1 forked Primary Flow step 5's completion path, but "Operator fixes an issue and re-attempts" has a structurally identical unconditional commit in its Exit: "the re-attempted item re-enters the gate. If it clears, the driver commits it and records it done." A no-output audit can reach the recovery menu (it halts on stray files left despite `Expected paths: None`, or on a review escalation), the operator fixes the issue and re-attempts, the re-check clears the human confirmation, and this Exit commits it — the same spurious empty commit F1 was raised to prevent, on a second path.
- **Evidence considered:** spec "Operator fixes an issue and re-attempts" (Exit); `references/no-output-completion.md:9-14` (stray files on a no-output audit halt through the Halt Procedure); `SKILL.md` Step 3.4 (the skill's own no-output fork prevents the commit — an implementation built from the spec alone would not). Trust class: codebase.
- **Resolution:** The re-attempt Exit forked to match step 5: on clear, the driver commits an output item and records it done, or records the no-commit done outcome without a commit for a no-output `audit`.
- **Resolved by:** evidence
- **Raised in round:** R2
- **Changed in plan:** Alternate Flows (Operator fixes an issue and re-attempts)
- **Changed in tech-notes:** —

## Minor edits

- F8: "the item's code commit" / "the item's code already landed" is code-only wording — a `spike` commits a finding, not code, and the phrasing is imprecise for any non-`deliverable` item; softened to "the item's commit" where it is terminology (the start-of-item-to-HEAD range mechanic is already owned by T1, so this is precision, not a new mechanic leak) — self-review (evidence-based-investigator, junior-developer JD-008, adversarial-validator V4) — Primary Flow; Alternate Flows (Resuming an in-progress item); Edge Cases; Coordinations
- F9: the foreground-resume flow and technical note T2 say "that skill's own commits," which is skill-centric and does not cleanly cover a skill-less `none` build whose foreground work may be entirely uncommitted; generalized to "the foreground item's own commits and/or uncommitted work" — self-review (junior-developer JD-006; evidence-based-investigator E7) — Alternate Flows (Resuming an interrupted foreground item); T2
- F10: the current Step 1.7 "Type and no-output guards" and the AFK-review-on-audit refusal are net-new validation added after the spec froze; confirmed **not a gap the spec must fix** — the spec inherits startup validation unchanged ("stages inside the loop are unchanged except where noted") and does not restate Step 1.7, so it does not contradict the new guards; a resume re-invokes and re-validates, so no in-progress AFK-review audit can reach the resume path (matches gap-analyzer's and adversarial-validator's not-gapped analysis) — self-review — no change (documented so the non-change is not silently made)
- F13: the halt frame's tree-state disclosure (part 3) inherited "items completed before the halt stay committed," which is incomplete for a mixed run once the stop option was reworded (F6); it now names any no-output audits as completed-without-a-commit, matching the stop option so an operator reading part 3 before choosing is not misled — self-review (round-2 adversarial-validator V4) — Alternate Flows (A run reaches a state it cannot settle)
- F14: the cross-session go-ahead gated "the first build or any discard," which does not cover recording a done outcome (a durable-record write) on the resumed item, and "the phase it will resume at" had no value for a forward-reconcile-past item; the go-ahead now gates "the first build, discard, or write to the durable record on the resumed item," and the announce-next-action wording covers the record-done-and-advance-past case — self-review (round-2 adversarial-validator V5/V6) — Alternate Flows (Resuming a partially complete run)
- F15: Primary Flow step 4 still said "only the item's own **code commit** ... reach history" (F8 residual, flagged by round-2 gap-analyzer RG-1), and step 5's D18 self-check said "before it commits," which did not clearly cover the no-output fork that never commits (NI-3); step 4 reworded to "the item's own commit, when it produces one," and the D18 clause reframed around "before it records the item done — whether by committing it or by recording a no-commit done outcome" — self-review (round-2 gap-analyzer RG-1/NI-3) — Primary Flow (steps 4, 5)
- F16: T1's `Referenced in spec` metadata omitted Alternate Flows even though "Resuming an in-progress item" now cross-references T1 (round-2 gap-analyzer NI-1), and one Edge Cases row used the abbreviated "done outcome"/"no-commit outcome" instead of the established "no-commit done outcome" (NI-2); both aligned — self-review (round-2 gap-analyzer NI-1/NI-2) — Edge Cases; T1
