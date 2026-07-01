# Team Findings: Autonomous Driver — Core Loop

<!--
This file records every finding raised by the review team for the Autonomous Driver
Core Loop, and how each was resolved. Behavioral outcomes live in
[../feature-specification.md](../feature-specification.md); decisions the findings
affected live in [decision-log.md](decision-log.md). No feature-technical-notes.md
exists for this feature (no load-bearing mechanic qualified), so no finding cites a T#.

Major findings carry the full structured fields; minor edits are one-line bullets.
The F# counter is shared across both classes.
-->

## Review configuration

- **Feature size:** Medium — the core touches two skills (the new driver and the `plan-work-items` companion changes), coordinates four systems (`tdd`, `code-review`, the work-item producer, and version control), and has a multi-state per-item loop with several failure modes, but is deliberately descoped (no HITL, no resume, no compaction, no stall handling, no interactive blocker menu) and has no security or data-migration surface.
- **Team cap:** 3 to 4 (medium).
- **Team:** `han-core:junior-developer`, `han-core:edge-case-explorer`, `han-core:on-call-engineer`, `han-core:user-experience-designer` (all run on sonnet).
- **Round:** R1 (single team round). Reviewers were briefed that the deferred surface (HITL, clean-stop, resume, compaction, stall handling, interactive blocker menu) is intentional and out of scope; none re-raised it. The findings clustered instead in the seams the descoping created — the fix loop's failure dispositions, the scope check, and the operator-facing halt.

## Major findings

### F1: Verification-failure disposition and fix-loop entry were contradictory

- **Agent:** junior-developer (F-001), with edge-case-explorer (F1) and on-call-engineer (R3) on adjacent points
- **Finding:** The primary flow described the fix loop as entered only by a gate-blocking review finding, but the edge-case table said a failed initial verification "treats the failure as a fix-loop round" — a state where no review has run, so the loop as described could not be entered. It was unclear whether a failed verification enters the fix loop or halts.
- **Resolution:** Clarified (matching reference plan D8/D5) that the per-item fix loop is entered either by a verification command that reports failures (fix → re-verify, no review until verify passes) or by a gate-blocking review finding; only a verification command that reports failures is a not-cleared round, and the loop halts the run only when the cap is reached. Rewrote Primary Flow steps 3.2 and 3.4 to spell out the re-verify and re-review outcome sets.
- **Resolved by:** evidence
- **Affected decisions:** D5, D6
- **Changed in spec:** Primary Flow (Verify, Fix to the gate); Edge Cases and Failure Modes; Alternate Flows and States

### F2: A verification command that fails to execute was conflated with one that reports failures

- **Agent:** on-call-engineer (R3)
- **Finding:** The core dropped the reference plan's distinction between a verification command that runs and reports test failures (code's fault → fix loop) and one that fails to execute (broken environment → not the code's fault). Feeding an execution failure into the fix loop would burn the cap and halt with a misleading "gate not cleared".
- **Resolution:** Restored the distinction: a command that fails to execute (missing/removed tool, service down, full disk) is surfaced as a tooling or environment problem and halts the run immediately, rather than entering the fix loop. Re-added the corresponding edge-case row.
- **Resolved by:** evidence
- **Affected decisions:** D6, D7
- **Changed in spec:** Primary Flow (Verify); Edge Cases and Failure Modes

### F3: The scope-check semantics were undefined for renames, deletions, and generated files

- **Agent:** edge-case-explorer (F2, F3, F8)
- **Finding:** The scope check compares changed files against expected paths, but the spec never said how renames (a delete plus an add), deletions, or build-step code generation are treated, so the guard's behavior was undefined and would false-positive-halt on a legitimate rename.
- **Resolution:** Specified that the inspection treats each added, modified, or deleted path against the declared paths, so a rename must declare both the old and new paths (a deleted declared path counts as in-scope); extended the exclusion to code-generation or sync output produced by any step in the per-item loop (build or verify), not only the verify step. The exact expected-paths syntax is left to `plan-implementation` as a companion-field data-format detail.
- **Resolved by:** evidence
- **Affected decisions:** D7
- **Changed in spec:** Primary Flow (Verify); Edge Cases and Failure Modes; Actors and Triggers (Preconditions)

### F4: "No file changes" and commit scope were undefined relative to excluded files

- **Agent:** edge-case-explorer (F4), on-call-engineer (R1)
- **Finding:** Two gaps. (1) A build whose only changes are to excluded files (ignored, generated, or the driver's own artifacts) could be read as "changes present" and proceed to a semantically empty commit. (2) The commit step never said what is staged, so an `add-all` would fold verification-produced files (lock files), the durable review record, and the work-state file into the item's code commit, polluting the clean-history invariant.
- **Resolution:** Specified that the "no file changes" halt is evaluated after exclusions (an excluded-only build halts), and that the per-item commit stages only the item's own code changes (and any project-tracked generation output), never the driver's own artifacts (the work-state file and the durable review record).
- **Resolved by:** evidence
- **Affected decisions:** D6, D8, D18
- **Changed in spec:** Primary Flow (Build, Commit); Edge Cases and Failure Modes

### F5: The durable review record had no defined location or lifetime

- **Agent:** junior-developer (F-005)
- **Finding:** The durable review record is load-bearing (the fix agent reads it; a halt points the operator to it), but the spec never said where it lives, whether it is committed, or how long it persists — so neither the fix nor the operator-inspection behavior could be specified.
- **Resolution:** Specified the record behaviorally as a driver artifact kept out of commits (like the work-state file), readable by any sub-agent the driver dispatches during the run and retained after a halt so the operator can read the full findings; exact location and format are left to `plan-implementation`.
- **Resolved by:** evidence
- **Affected decisions:** D9, D18
- **Changed in spec:** Primary Flow (Review); Coordinations

### F6: Fail-closed handling was not applied uniformly across the fix loop

- **Agent:** edge-case-explorer (F1, F5, F6)
- **Finding:** The initial review's untrustworthy-verdict halt and the out-of-path halt were specified for the first pass, but the fix loop's re-verify and re-review were not: an untrustworthy re-review verdict or an out-of-path change during a fix round could be mis-counted as a not-cleared round (burning the cap, wrong halt reason), and a `tdd` build report missing the required failure-then-pass evidence had no halt rule at all (silent skip of the test-first gate).
- **Resolution:** Applied the fail-closed rule uniformly: an untrustworthy re-review verdict and an out-of-path change during re-verify each halt the run immediately (not a not-cleared round), and a `tdd` report missing the required failure-then-pass evidence is treated as untrustworthy and halts. Only a verification command that reports failures counts as a not-cleared round.
- **Resolved by:** evidence
- **Affected decisions:** D5, D6, D9, D10
- **Changed in spec:** Primary Flow (Build, Fix to the gate); Edge Cases and Failure Modes

### F7: No mechanism was defined for judging a declared skill "non-interactive and code-producing"

- **Agent:** junior-developer (F-003)
- **Finding:** The driver must refuse an item whose declared implementation skill is not a non-interactive, code-producing skill, but the spec defined no way to determine that property of an arbitrarily-named skill.
- **Resolution:** Stated the behavioral criterion — the driver recognizes valid skills against a known set of non-interactive, code-producing implementation skills, `tdd` the default and canonical member — and left the recognition mechanism (a fixed set, or a property read from each skill's own definition) to `plan-implementation`.
- **Resolved by:** evidence
- **Affected decisions:** D13, D16
- **Changed in spec:** Actors and Triggers (Preconditions); Edge Cases and Failure Modes

### F8: The review fan-out rests on an unverified platform capability with no stated contingency

- **Agent:** junior-developer (F-006)
- **Finding:** The full-coverage self-contained review depends on a platform capability (a dispatched stage fanning out its own panel) that D9 defers to `plan-implementation` verification, with no stated outcome if that verification fails.
- **Resolution:** Stated the posture explicitly (matching reference plan D11): the core carries no reduced-coverage single-reviewer fallback; review fails closed, so if the platform cannot support full-coverage self-contained review, that is resolved at implementation rather than by degrading the gate. Recorded as a rejected alternative on D9.
- **Resolved by:** evidence
- **Affected decisions:** D9
- **Changed in spec:** — (decision-log posture; the spec already defers the topology to `plan-implementation`)

### F9: A fresh re-run on a branch carrying a prior run's commits would duplicate work

- **Agent:** on-call-engineer (R2), junior-developer (F-009)
- **Finding:** With single-pass, no-resume semantics, re-invoking after a halt (especially a clean-tree halt such as "no file changes") on a branch that already carries the prior run's commits would rebuild already-committed items, creating duplicate commits, and no existing check caught it.
- **Resolution:** Added a start-time refusal: the skill refuses to start on a branch that already carries a prior run's planning-artifacts commit and directs the operator to a fresh branch.
- **Resolved by:** evidence
- **Affected decisions:** D14, D18
- **Changed in spec:** Primary Flow (step 1); Edge Cases and Failure Modes; Alternate Flows and States (what-to-do-next)

### F10: The clean-tree "planning artifacts" exception had no identification criterion

- **Agent:** junior-developer (F-004)
- **Finding:** The clean-tree check exempts "the run's own planning artifacts", but the spec never said how the skill distinguishes those from unrelated uncommitted changes — so the check could block a legitimate start or silently fold in unrelated work.
- **Resolution:** Defined the criterion: planning artifacts are the work-items file the operator passed plus the spec, research, and plan files that file names as its context; source files the items target do not qualify. The set is shown at the plan preview so the operator sees what will be committed first.
- **Resolved by:** evidence
- **Affected decisions:** D14, D15
- **Changed in spec:** Primary Flow (step 1); Actors and Triggers (Preconditions)

### F11: The halt report omitted tree state and a "what to do next", and did not warn that re-invocation is a fresh run

- **Agent:** user-experience-designer (F-03, F-04), junior-developer (F-013)
- **Finding:** The halt report's defined structure gave a status line, a reason, and evidence, but omitted the working-tree state (forcing an external `git status`), listed the durable-record pointer only as a prose aside, and had no "what to do next". Critically, it never warned that re-invocation starts a fresh run from item 1 (not a resume), so an operator fixing the cause and re-invoking would re-process completed items on a new branch.
- **Resolution:** Defined a five-part halt frame: status line, one-sentence reason, tree-state disclosure (halting item's uncommitted files + a statement that completed items remain committed), evidence with a named durable-review-record pointer when review-gated, and what-to-do-next (a halt-kind-appropriate resolution; the fresh-run-not-resume warning; the instruction to commit or stash the halting work and use a fresh branch; and the branch and commit range of completed work).
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Alternate Flows and States (halt); User Interactions (Error states)

### F12: Five refusal messages named the reason but not the remedy

- **Agent:** user-experience-designer (F-05)
- **Finding:** Only the red-suite refusal named a remedy; the malformed-graph, human-required/interactive-item, empty-file, missing-expected-paths, and tooling-unavailable refusals named the reason alone, so the operator often could not tell what to fix.
- **Resolution:** Added a remedy to each refusal (break the cycle / de-duplicate / repair the reference / replace the invalid skill; remove or replace the flagged items; the file must contain at least one buildable item; re-run the producer or add the field; install the listed commands), and recorded in D13 that every refusal names both reason and remedy.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Changed in spec:** Edge Cases and Failure Modes

### F13: The verification-command configuration created a second touchpoint that contradicted the "one confirmation" model

- **Agent:** user-experience-designer (F-06, F-07, F-09), edge-case-explorer (F10), junior-developer (F-002, F-007)
- **Finding:** The spec claimed the plan preview was the only operator touchpoint, but the verification-command confirm/override and the scope-check-only confirmation were described "during preparation" (before the preview) and were absent from the preview's effective configuration — a direct contradiction, and an operator could confirm a plan without seeing what verification would run.
- **Resolution:** Folded the verification configuration into the plan preview: the resolved verification commands (or scope-check-only mode) are shown in the preview's effective configuration and confirmed there; the verification-command override is an invocation input. This makes the preview the single confirmation touchpoint and removes the separate scope-check-only prompt.
- **Resolved by:** evidence
- **Affected decisions:** D7, D17
- **Changed in spec:** Outcome; Primary Flow (steps 1, 2); Alternate Flows and States (no verification commands); User Interactions; Actors and Triggers

### F14: The plan-preview reorder affordance was under-specified and thin on evidence

- **Agent:** user-experience-designer (F-01, F-02), junior-developer (F-011, YAGNI candidate)
- **Finding:** The reorder option needed an input protocol, a dependency display, and constraint-violation feedback the core did not have; the "rejects or re-sorts" behavior was ambiguous; and the evidence behind the preview was "let the operator see and confirm the run's shape", which a simpler confirm-or-decline preview satisfies.
- **Resolution:** Deferred item reorder at the plan preview. The core preview is confirm-or-decline only; a single-pass operator who wants a different order edits the work-items file and re-invokes. Recorded in the spec's Deferred (YAGNI) section with a reopen trigger.
- **Resolved by:** user input (operator chose to defer)
- **Affected decisions:** D17
- **Changed in spec:** Primary Flow (step 2); User Interactions; Deferred (YAGNI)

### F15: A later item's failure caused by an earlier committed item would be misdiagnosed

- **Agent:** on-call-engineer (R6)
- **Finding:** Serial building verifies each item against the committed tree of earlier items, so a regression from an interaction between an earlier committed item and the current one surfaces during the current item's verify and is misdiagnosed as the current item's fault, halting with a misleading reason. Automatic culprit attribution and repair-upstream recovery are deferred, but the operator gets no hint.
- **Resolution:** Added an operator-facing note to the halt's what-to-do-next and an Edge Cases row: when the halt names an item whose own changes look correct, the cause may be an earlier committed item interacting with this one, which the operator can confirm by inspecting the branch without this item's changes. The recovery machinery stays deferred.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Alternate Flows and States (halt); Edge Cases and Failure Modes

## Minor edits

- F16: cap=0 surfaced as its own row in the Edge Cases table and the fix-loop text made consistent with D5 (the loop is not entered; halt on the first gate-blocking finding) — edge-case-explorer (F7) — Primary Flow (Fix to the gate), Edge Cases and Failure Modes.
- F17: D13's "every item filtered out" wording corrected to the all-or-nothing refusal ("every item invalid; a single invalid item causes a total refusal") to match the spec — junior-developer (F-012) — decision-log.md D13.
- F18: "the diff" the fix agent receives disambiguated to the current cumulative working-tree diff against the item's base commit, so a later fix round does not get a stale original-build diff — edge-case-explorer (F-008), on-call-engineer (R4) — Primary Flow (Fix to the gate), decision-log.md D11.
- F19: scope-check-only mode's fix-loop re-verify clarified — it can only pass or find an out-of-path change (halting), never a verification-failure not-cleared round, and the verify-step generation exclusion is noted as inapplicable — on-call-engineer (R5), edge-case-explorer (F9) — Alternate Flows and States (no verification commands).
- F20: Feedback strengthened — the skill emits the verification commands it runs and a one-line pass/fail result (verification is not a sub-agent dispatch), and labels each fix round with its number and the cap — user-experience-designer (F-08) — User Interactions (Feedback).
- F21: Decline response content specified — a decline is acknowledged with a confirmation that no branch was created and nothing was committed, plus the suggested next step — user-experience-designer (F-10) — User Interactions (Error states), decision-log.md D17.
