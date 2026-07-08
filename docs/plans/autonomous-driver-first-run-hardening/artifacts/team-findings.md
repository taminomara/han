# Team Findings: implement-work-items First-Run Hardening

This file records every finding raised by the review team for the first-run hardening bundle, and how each was resolved. Behavioral outcomes live in [../feature-specification.md](../feature-specification.md); decisions the findings affected live in [decision-log.md](decision-log.md). This feature has no `feature-technical-notes.md` (no load-bearing mechanic qualified after the harness nested-agent item was scoped out to a separate feature), so `Affected tech-notes:` is omitted from findings.

Review team: `han-core:junior-developer`, `han-core:on-call-engineer`, `han-core:edge-case-explorer`, `han-core:devops-engineer` (Medium size, 4 agents). Raw finding IDs from each agent are cited in-line (JD#, OCE#, EC#, DOR#).

## Major findings

### F1: Base-recommendation prompt fires before fresh/resume classification

- **Agent:** edge-case-explorer (EC1)
- **Finding:** D2's interactive base recommendation attaches to base resolution, which runs before the run is classified fresh vs resume; on an active-branch resume — the common case — the current branch is ahead of the base, so the prompt re-fires on nearly every resume and could reclassify the run against a base different from the one the branch was built from.
- **Resolution:** The recommend-and-confirm step is fresh-only; on resume the base is read from the run's recorded opening and not re-resolved or re-confirmed.
- **Resolved by:** evidence
- **Affected decisions:** D2
- **Changed in spec:** Primary Flow (step 1), Edge Cases and Failure Modes

### F2: Diverged-base "contains the target paths" heuristic does not detect the real failure and is YAGNI

- **Agent:** edge-case-explorer (EC3), devops-engineer (DOR-002), junior-developer (JD-002, JD-009)
- **Finding:** The recommended diverged-case base "that contains the paths the work items target" conflates outputs with dependencies: expected paths are often newly created (absent from both candidates, no signal) or long-lived (present in both), and the real first-run failure was a missing dependency, not a missing output. The heuristic is undefined for the both/neither cases and builds path-set machinery for an unobserved case.
- **Resolution:** Dropped the computed diverged-case recommendation; the diverged case surfaces both candidates with ahead/behind counts and asks the operator to choose. The ahead case (the real incident) keeps its recommendation, now anchored on the ahead-of-base signal rather than output paths.
- **Resolved by:** evidence (simpler-version test satisfied)
- **Affected decisions:** D2
- **Changed in spec:** Edge Cases and Failure Modes, User Interactions

### F3: Base resolution does not commit to fetch-failure or stale-remote behavior

- **Agent:** devops-engineer (DOR-001)
- **Finding:** The ahead/behind counts and recommendation are only as fresh as the fetch; a failed or partial fetch still resolves a base from cached refs, so stale counts are presented as authoritative — reproducing the wrong-base failure with added false confidence.
- **Resolution:** When the fetch fails or is partial, the driver states the fetch did not complete, marks the counts as possibly stale, and asks rather than presenting stale counts as authoritative.
- **Resolved by:** evidence
- **Affected decisions:** D2
- **Changed in spec:** Edge Cases and Failure Modes

### F4: Detached working state breaks the "surface the current branch" mechanism

- **Agent:** edge-case-explorer (EC2)
- **Finding:** D2 is phrased entirely in terms of "the current branch"; in a detached state (mid-rebase, a checked-out commit/tag) there is no branch to name or recommend.
- **Resolution:** With no current branch, the driver does not offer a current-branch alternative and falls back to asking the operator which base to branch from.
- **Resolved by:** evidence
- **Affected decisions:** D2
- **Changed in spec:** Edge Cases and Failure Modes

### F5: Clean-tree widening left the opening-commit staging and per-item assertion unresolved

- **Agent:** devops-engineer (DOR-003), junior-developer (JD-007)
- **Finding:** Widening the startup clean-tree allowance to the whole plan folder without pinning what the opening commit stages either strands tolerated files (a spurious per-item halt) or folds them into the first commit (the blast-radius risk the gate exists to prevent).
- **Resolution:** Toleration is decoupled from commit scope: the opening commit stages only the run's planning content, the per-item assertion tolerates the same plan-folder content for the run, and the plan-preview enumerates exactly what the opening commit will contain.
- **Resolved by:** evidence
- **Affected decisions:** D3
- **Changed in spec:** Primary Flow (step 2), Edge Cases and Failure Modes, User Interactions

### F6: A work item's own expected path in the plan folder could be folded into the opening commit

- **Agent:** edge-case-explorer (EC9)
- **Finding:** If a work item's expected path is a file inside the plan folder that is already dirty at run start, D3's allowance folds it into the opening commit before the item's own baseline is taken, misattributing the edit and corrupting the scope-baseline invariant.
- **Resolution:** A work item's own expected paths are excluded from the opening-commit staging.
- **Resolved by:** evidence
- **Affected decisions:** D3
- **Changed in spec:** Edge Cases and Failure Modes

### F7: The whole-folder allowance does not distinguish just-produced outputs from stale cruft

- **Agent:** edge-case-explorer (EC10)
- **Finding:** D3 was evidenced by the operator's own just-produced outputs tripping the gate, but "the entire plan folder as expected" also silently allows any leftover draft or scratch file, reintroducing the commit-pollution the gate prevents.
- **Resolution:** The plan-preview enumerates exactly what the opening commit will stage so the operator can catch stale or unrelated content before confirming.
- **Resolved by:** evidence
- **Affected decisions:** D3
- **Changed in spec:** Primary Flow (step 2), User Interactions

### F8: Relocation plus whole-folder allowance can sweep in stale run-artifact remnants

- **Agent:** edge-case-explorer (EC11), on-call-engineer (OCE-004)
- **Finding:** Moving the run-artifact area into the plan folder (D4) while making the whole plan folder exempt (D3) means a leftover artifact area from an earlier stopped or aborted run silently qualifies as expected content and can enter the new run.
- **Resolution:** A fresh run that finds a stale run-artifact area under the plan folder surfaces it and asks rather than silently adopting or committing it.
- **Resolved by:** evidence
- **Affected decisions:** D3, D4
- **Changed in spec:** Edge Cases and Failure Modes

### F9: The plan-folder-plus-artifacts prerequisite is not met by the current arbitrary-path input

- **Agent:** junior-developer (JD-006)
- **Finding:** D3/D4 anchor on a plan folder with an artifacts subfolder, but the current skill accepts an arbitrary work-items path; the spec added a hard prerequisite without stating refuse-vs-degrade.
- **Resolution:** The driver degrades: it treats the folder holding the work-items file as the plan folder and places its run-artifact area there; an artifacts subfolder is used if present but not required.
- **Resolved by:** evidence
- **Affected decisions:** D3, D4
- **Changed in spec:** Actors and Triggers (Preconditions), Edge Cases and Failure Modes

### F10: The new durable stores inherited no integrity, tracked/ignored, write-ordering, or fate-at-push contract

- **Agent:** on-call-engineer (OCE-002, OCE-003), edge-case-explorer (EC4, EC15, EC16), devops-engineer (DOR-004)
- **Finding:** The preference set and iteration history were added as new durable stores with no integrity or graceful-degradation contract on resume, no placement on the tracked/ignored axis, no write-ordering across the now-multiple per-item durable writes, and no boundary for what rides to merged history.
- **Resolution:** Resolved structurally by the D10/D12 redirect: git history is the durable, authoritative store (durable by construction), the run record collapses to a single committed file, bookkeeping commits are kept separate from and identifiable against code commits, the item's committed record is the completion signal, and resume default-denies on any disagreement between the committed record and the tree.
- **Resolved by:** user input (the commit-everything redirect) reconciled with evidence
- **Affected decisions:** D10, D12
- **Changed in spec:** Primary Flow (steps 3, 8), Alternate Flows and States, Coordinations

### F11: The accumulated preference set has no de-duplication or growth bound

- **Agent:** edge-case-explorer (EC14)
- **Finding:** Near-duplicate corrections raised on different items could accumulate as separate entries and dilute later build briefs over a long run.
- **Resolution:** Accepted at the observed run lengths (the first run was 10 items); consolidation is deferred under YAGNI with a reopening trigger.
- **Resolved by:** evidence (YAGNI defer)
- **Affected decisions:** D9
- **Changed in spec:** Edge Cases and Failure Modes, Deferred (YAGNI)

### F12: The preserve-set was a soft instruction with no verification and did not cover all in-flight paths

- **Agent:** on-call-engineer (OCE-001), edge-case-explorer (EC7)
- **Finding:** D8 committed only to *sending* the preserve instruction, never to detecting a violation, so a sub-agent that ignores it silently reverts unrecoverable in-flight work — the exact first-run incident; and the preserve-set as scoped ("the driver's in-flight work") did not obviously include operator-directed edits or approved-but-uncommitted coherence edits.
- **Resolution:** The driver verifies after each dispatch that the preserve-set paths still carry their pre-dispatch changes and surfaces a detected revert as a named failure; the preserve-set is widened to include operator-directed uncommitted edits and approved coherence edits. Committing each iteration (D10) further narrows the exposure window.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Changed in spec:** Outcome, Primary Flow (step 4), Edge Cases and Failure Modes

### F13: Coherence approval was not persisted across rounds and did not exclude the item's own expected paths

- **Agent:** edge-case-explorer (EC5, EC6, EC13)
- **Finding:** A fresh per-round reviewer recomputes the full diff, so an approved sibling-file edit is re-raised every round (a gate that never clears) unless the approval persists; and the trigger "already-committed sibling files" would fire on the validated chained shared-file pattern unless the item's own expected paths are excluded; and the approval had no stated durability across stop/resume.
- **Resolution:** An approved coherence edit is threaded to the item's later review dispatches so it is not re-raised, is durable across resume because it is committed, and applies only to files outside the item's own expected paths (a predicted committed sibling is ordinary expected work).
- **Resolved by:** evidence
- **Affected decisions:** D7
- **Changed in spec:** Primary Flow (step 7), Alternate Flows and States, Edge Cases and Failure Modes

### F14: A below-threshold fix on a green gate ran no re-verification, risking an undetected regression

- **Agent:** edge-case-explorer (EC8)
- **Finding:** A standalone below-threshold judgement fix on a cleared gate ran neither re-review nor re-verification, so it could commit a new above-threshold defect undetected — most dangerously in scope-check-only mode, the mode the source-feedback run used.
- **Resolution:** The driver re-runs available verification before committing any post-gate fix; in scope-check-only mode the scope check still runs and a fix the driver judges risky is re-reviewed rather than committed unchecked.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Outcome, Primary Flow (step 6), Edge Cases and Failure Modes

### F15: Below-threshold detail is counts-only on a green gate, and dispositions were only in the terminal summary

- **Agent:** devops-engineer (DOR-005), junior-developer (JD-001)
- **Finding:** On a green gate the driver holds only below-threshold counts (full detail lives in the durable record), so acting on D6 requires an unstated record read; and the fix/leave dispositions surfaced only in the terminal summary, invisible on a non-terminal halt and unauditable at decision time on an autonomous run.
- **Resolution:** The driver reads the durable review record for below-threshold detail, and records each fix/leave disposition in the item's committed record at decision time as well as in the run summary. This gives OI-1 an implementable default.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Primary Flow (steps 5, 6), User Interactions, Open Items (OI-1)

### F16: The per-role dispatch payload (build vs review) was unspecified

- **Agent:** junior-developer (JD-003)
- **Finding:** D9 said corrections inject into "every build's baseline" while D11 said the baseline goes to "every dispatched sub-agent" with corrections and preserve-set on top, and an item names both an implementation and a review skill — so a builder could not tell whether reviewers get style corrections or a preserve-set, or which skill's guidance a reviewer follows.
- **Resolution:** D11 now states a role-scoped payload: build sub-agents get baseline + implementation-skill guidance + corrections + preserve-set; review sub-agents get baseline + review-skill guidance + preserve-set + already-approved coherence paths, with corrections only as judging context.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Changed in spec:** Actors and Triggers, Primary Flow (steps 4, 5)

### F17: D9's correction-class extraction is open-ended and the one-off-vs-general conflict was unresolved

- **Agent:** edge-case-explorer (EC12), junior-developer (JD-004)
- **Finding:** Naming a reusable "correction class" from ad-hoc feedback is the same open-ended judgement as D6 but carried no open item; and a one-off item-specific instruction that reverses a general accumulated correction had no resolution, risking silent propagation as a new general rule or being outweighed by the growing set.
- **Resolution:** Item-specific one-off corrections are not accumulated (only general corrections are), and an item's own instruction wins for that item; the class-extraction criterion is promoted to open item OI-2 with that default.
- **Resolved by:** evidence
- **Affected decisions:** D9
- **Changed in spec:** Edge Cases and Failure Modes, Open Items (OI-2)

### F18: D5's operator-directed in-loop fix implied a pause the autonomous loop lacks, and the HITL cap consequence was unstated

- **Agent:** junior-developer (JD-008)
- **Finding:** The current loop auto-re-dispatches automated rounds with no operator-choice branch, so D5's "operator steers the fix inside the loop" assumes a pause the flow never introduces; and if per-round classification holds, a HITL item's rounds never count, making the automated cap inert for HITL items — unstated.
- **Resolution:** D5 states the operator can intervene to steer a fix at any point, and that an item driven entirely by hand is not gated by the automated cap at all (by design).
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Changed in spec:** Primary Flow (step 6), Alternate Flows and States

### F19: The "review fan-out" precondition implied a safety the same feedback contradicts

- **Agent:** junior-developer (JD-005), devops-engineer (DOR-006)
- **Finding:** The precondition reads as "meet the version floor and the fan-out works," but the same first-run feedback documents the nested fan-out as harness-broken above the floor, and this bundle defers the flat-dispatch fix — so the precondition silently promises safety that does not yet hold.
- **Resolution:** The Preconditions and Out of Scope now state that this bundle's review dispatch stays on the existing nested path and accepts the documented residual until the deferred harness feature ships.
- **Resolved by:** evidence
- **Affected decisions:** —
- **Changed in spec:** Actors and Triggers (Preconditions), Out of Scope

## Minor edits

- F20: "tracked"/"ignored" git vocabulary in the spec restated behaviorally as "committed to the branch" — junior-developer (JD-011) — Primary Flow (step 3)
- F21: Open-item count was understated as 1; promoted the genuine second open item (D9 correction-class criterion) so the count is 2 — junior-developer (JD-010) — Open Items, Summary
