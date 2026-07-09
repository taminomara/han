# Team Findings: implement-work-items Driver Automation and Resumability Hardening

Records every finding raised by the review team for this feature, and how each was resolved. Behavioral outcomes live in [../feature-specification.md](../feature-specification.md); decisions the findings affected live in [decision-log.md](decision-log.md); load-bearing mechanics live in [feature-technical-notes.md](feature-technical-notes.md).

Review team: `han-core:junior-developer` (JD), `han-core:edge-case-explorer` (EC), `han-core:on-call-engineer` (OCE), `han-core:gap-analyzer` (GA).

## Major findings

### F1: Per-round commit ordering invariant is unstated

- **Agent:** edge-case-explorer (EC#1, root of EC#2/#3/#5/#11), on-call-engineer (OCE#3)
- **Finding:** Each item/round produces up to three independently-committed artifacts — the code commit (driver), the review record (tool), and the lifecycle/iteration marker (tool). The spec never pins their order, so it never says which partial states are reachable on a mid-step death or what resume does for each. This is the root gap under most resume-integrity findings.
- **Resolution:** Added a resume-integrity invariant: a durable marker is committed only after the artifact it attests, so a resume never sees a marker for work that is not present; the only reachable partial state is artifact-present-marker-absent, which is treated as in-progress and re-verified/re-reviewed. Reaffirmed the existing default-deny rule (commit presence never implies done/cleared) for the new state, and that a record-vs-history disagreement surfaces-and-asks rather than silently trusting either side. Recorded as new decision D14; woven into the Resume flow and Edge Cases.
- **Resolved by:** evidence
- **Affected decisions:** D14 (new), D11
- **Affected tech-notes:** T1
- **Changed in spec:** Alternate Flows and States (Resume), Edge Cases and Failure Modes

### F2: Resume-critical state could be read from the uncommitted working tree

- **Agent:** edge-case-explorer (EC#4)
- **Finding:** The current history scanner falls back to reading an uncommitted working-tree ledger. Once pre-work decisions and iteration markers share that file, an uncommitted decision could be read as durable, contradicting T1's premise that resume-critical state must come from committed artifacts.
- **Resolution:** T1 tightened to state that resume-critical state (decisions, fix-round count, in-progress-round findings) is reconstructable only from committed artifacts; the uncommitted-working-tree fallback must not be used for it. A decision/marker written but not committed before a stop is treated as not-yet-durable.
- **Resolved by:** evidence
- **Affected decisions:** D10, D11, D14
- **Affected tech-notes:** T1
- **Changed in spec:** Edge Cases and Failure Modes

### F3: "Agent commits only code" boundary omits branch setup, recovery resets, and the pre-run gate

- **Agent:** junior-developer (JD#10/#11/#12/#20), on-call-engineer (OCE#2/#4), edge-case-explorer (EC#9/#14)
- **Finding:** The absolute phrasing "the driver runs version control only to commit item code" is false as written: the current skill also creates/switches the branch, discards/resets the tree on skip and on a reddening below-threshold fix and on resume, reconciles an interactive skill's own commits, and — before the first item — offers to commit-or-stash stray content and confirms a green suite. The spec dropped all of these.
- **Resolution:** D5 re-scoped to the operator's own "under happy path" qualifier: on the happy path the item's code commit is the driver's only version-control action; branch creation/switching folds into the tool's opening/resume setup action; recovery-time tree resets (skip, reddening, resume discard) are enumerated exceptions performed under operator confirmation; foreground commit reconciliation is part of the code-commit responsibility, not bookkeeping. Restored the pre-run clean-tree commit-or-stash offer and the green-suite gate to the spec. Added torn-write atomicity spanning the tool's write+commit, narrow staging, and a general operator-takeover guarantee on any tool-step failure.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Actors and Triggers (Preconditions), Primary Flow, Alternate Flows (Resumable stop), Edge Cases and Failure Modes

### F4: Dropping expected-paths orphaned several current sites

- **Agent:** junior-developer (JD#1/#2/#3/#4/#5/#6), gap-analyzer (GAP-004)
- **Finding:** The current skill uses `Expected paths` at Step 1.5 validation (a required field), the no-output/Type guards, the coherence-spillover keying (identify by "outside expected paths", exclude a "predicted path"), the review-verdict scope section and the review payload placeholder, and the human-review-capture orientation. The spec's D7 said "tolerated and ignored" but did not trace these sites, so at least one startup refusal was silently lost.
- **Resolution:** D7 made explicit that the driver removes its own use of the predicted-path list at every site: it is dropped from the required-fields validation (neither required nor read; presence tolerated, absence not a refusal); no-output re-keys entirely on the item's type (D8); coherence spillover re-keys on the scope finding on an already-committed sibling, so the predicted-path exclusion branch is gone and every such finding is offered for approval; the review dispatch stops supplying a predicted-path list and the reviewer judges scope from the diff and item intent; the human-review path orients the human by the diff and intent, not a path list.
- **Resolved by:** evidence
- **Affected decisions:** D7, D8
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases and Failure Modes, Coordinations

### F5: Audit-report-in-artifact-area created a stray-vs-intended ambiguity

- **Agent:** junior-developer (JD#7/#8/#9), edge-case-explorer (EC#6/#10)
- **Finding:** Routing an audit's report into the bookkeeping area makes a broken/garbage write indistinguishable from an intended report (the clean-tree check allows any file under that area), leaves who-commits-it and under-what-path unspecified, and a failed report write recreates the empty-result ambiguity D8 explicitly rejected.
- **Resolution:** User decision: a `Type: audit` item produces no committed code, and its findings are captured in the per-round durable review/confirmation record the run already writes and commits — no separate report file, no new path convention, no stray-vs-intended ambiguity. The AFK-review-on-audit refusal survives, re-keyed on the item's type: an audit's review is always a human or agent confirmation, never an unattended auto-clear. Any file left outside the bookkeeping area by an audit is code output and halts.
- **Resolved by:** user input
- **Affected decisions:** D8
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (No-output audit), Edge Cases and Failure Modes

### F6: Self-fetch has no deadline and could run on resume

- **Agent:** on-call-engineer (OCE#1), edge-case-explorer (EC#7/#15/#17)
- **Finding:** Folding the base refresh into the detector puts an unbounded network call on the fresh-run critical path; an offline or slow-network run stalls silently. Separately, if the detect+refresh pass precedes classification, a resume would pay the fetch despite the rule that resume restores the base from the record.
- **Resolution:** D3 gained a deadline commitment (a slow refresh folds into the already-specified failed-refresh path: proceed on reported-stale counts, no recommendation) and an ordering commitment (the run recognizes an existing run record before refreshing, so no refresh runs on resume). Detector suppressibility stays OI-1.
- **Resolved by:** evidence
- **Affected decisions:** D3
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases and Failure Modes

### F7: State-reconstruction and reference-rename scope undershot the operator's asks

- **Agent:** gap-analyzer (GAP-002/GAP-003), junior-developer (JD#13)
- **Finding:** D4 bound the tool-produced reconstruction only to Resume, but the re-grounding routine is called from three sites (Resume, foreground hand-off, human-review capture). D6 named only 3 of 8 reference files for the rename, but the operator asked to rename references generally and make naming consistent. D1's enumerated automation list did not reach the task-list updates.
- **Resolution:** D4 broadened to all re-entry sites. D6 broadened so every reference file gets a consistent actor-prefixed name, not only the hand-off trio. D1 clarified: the automation targets are version-control, record/file, and state-discovery work; lightweight harness affordances (the task list) remain the driver's, so the "everything deterministic" principle has a stated boundary.
- **Resolved by:** evidence
- **Affected decisions:** D1, D4, D6
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Alternate Flows (Resume), Coordinations

### F8: Persisting every round's full findings exceeds the evidence

- **Agent:** on-call-engineer (OCE#5), junior-developer (JD#18)
- **Finding:** D11 justified persisting every round's full findings by "a resumed fix round needs the findings," but the run is serial and the fixer reads only the current round; the round count is the genuinely resume-critical part.
- **Resolution:** D11 scoped: the resume-critical state is the fix-round count plus the in-progress round's committed review record. Each round's record is still committed when it is written (answering the operator's "do we even commit review findings in between?" — yes), but the spec no longer claims prior rounds' findings are consumed on resume; retained records are audit history.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow

### F9: Decision persistence needs staleness handling

- **Agent:** edge-case-explorer (EC#8/#12/#13)
- **Finding:** A recorded pre-work decision is keyed to an item that may later be edited or renumbered, or whose `Requires pre-work decisions` field may flip to `no`; D10 is the first restored state that directly steers a build, raising the stakes. The compound "baseline committed, decision recorded, build not yet dispatched" is an unnamed resume state.
- **Resolution:** D10 gained: a recorded decision is restored only when its item is materially unchanged; a decision for an item whose text materially changed, was renumbered, or no longer requires a decision is surfaced-and-asked under the existing default-deny rule rather than silently steering the build. The decided-but-not-built state is named as a distinct resume phase.
- **Resolved by:** evidence
- **Affected decisions:** D10
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows (Resume), Edge Cases and Failure Modes

### F10: Mechanics leaking into the spec

- **Agent:** junior-developer (JD#14/#15)
- **Finding:** The spec named implementation literals in behavioral sentences — the item-type field value, the bookkeeping directory name, the predicted-path field name, and the commit-trailer markers ("run-identity marker", "baseline reference"). JD#14 further flagged a tension: the spec depended on the type field literal while declaring the producer's output out of scope.
- **Resolution:** Behavioral sentences generalized — "an audit item (declared to produce no committed code)", "the run's tracked bookkeeping area", "a predicted-path list", and "so the run is identifiable on resume" / "recording the item's baseline". The literals moved to the decision log. Clarified that the run depends on the item type field that the producer already emits today, so no producer change is required — resolving the out-of-scope tension.
- **Resolved by:** evidence
- **Affected decisions:** D8, D5, D11
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, Out of Scope, Coordinations

### F13: Broken cross-reference anchors and a residual spec-content literal (synthesis audit)

- **Agent:** project-manager (synthesis-mode cross-reference and spec-content audit)
- **Finding:** Three invariant violations surfaced when the cross-reference and spec-content invariants were enforced across all four files. (1) Both spec links to D9 pointed at `#d9-fix-routing-bounded-driver-substantive-sub-agent`, which does not match the D9 heading's actual slug `#d9-fix-routing-bounded-to-the-driver-substantive-to-a-sub-agent` (the link dropped the words "to the" and "to a"), so both links resolved to nothing. (2) D2 and D12 were bullets under "Trivial decisions", so they had no heading anchor, yet the spec linked to `#d2-bookkeeping-tool-creates-its-own-record-area` and `#d12-expanded-base-branch-candidates`; both links resolved to nothing, and neither decision carried the four required cross-reference sections the invariant requires of every `D#`. (3) The Edge Cases row about an older producer's block still named the implementation field literal `` `Expected paths` `` in a behavioral sentence, which the spec-content rule reserves for the decision-log evidence and tech-notes.
- **Resolution:** (1) Both D9 links were repointed to the heading's real slug. (2) D2 and D12 were promoted from bullets to `### ` headings under "Trivial decisions" (retaining the trivial framing and a condensed rationale), each gaining the four required cross-reference sections (`Linked technical notes:`, `Driven by findings:`, `Dependent decisions:`, `Referenced in spec:`), so their anchors now resolve and the every-`D#` invariant holds. (3) The `` `Expected paths` `` parenthetical was removed from the Edge Cases row, leaving the already-present behavioral phrasing "a predicted-path block from an older producer". No behavioral decision changed; these are structural and spec-content corrections only.
- **Resolved by:** evidence
- **Affected decisions:** D2, D9, D12
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow (D9 link), Gate-blocking fix round (D9 link), Edge Cases and Failure Modes (removed the `` `Expected paths` `` literal)

## Minor edits

- F11: Resume flow bundled already-durable state (accumulated corrections and coherence approvals) with the genuinely-new state, implying new persistence work; clarified the tool continues to surface already-durable state — junior-developer (JD#19) — Alternate Flows (Resume).
- F12: Open Items understated the actual openness; the resolved forks were promoted to decisions and only detector-suppressibility remains as OI-1 — junior-developer (JD#16) — Open Items.
