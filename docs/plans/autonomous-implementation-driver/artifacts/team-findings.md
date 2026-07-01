# Team Findings: Autonomous Work-Item Implementation Driver

<!--
This file records every finding raised by the review team for the Autonomous Work-Item
Implementation Driver, and how each was resolved. Behavioral outcomes live in
[../feature-specification.md](../feature-specification.md); decisions the findings
affected live in [decision-log.md](decision-log.md). No feature-technical-notes.md
exists for this spec: no load-bearing mechanic qualified (the sub-agent-nesting
constraint is a documented convention cited as evidence on D11), so no finding cites
a T# ID.

Review team: junior-developer, on-call-engineer, edge-case-explorer, gap-analyzer (all sonnet).
Findings are classified major (full structured fields) or minor (one-line bullet)
before recording. The F# counter is shared across both classes.
-->

## Major findings

### F1: tdd returns prose, not the structured/escalation contract the spec assumes

- **Agent:** junior-developer (with gap-analyzer)
- **Finding:** `tdd`'s Step 5 output is a human narrative with no structured escalation field, yet the spec required each implementer sub-agent to return a compact structured report the skill decides from without reading the diff. There is no mechanism for `tdd` to emit machine-parseable output on its own. The author's prior art also found sub-agents had to be told explicitly which skill to invoke.
- **Resolution:** Made the driver own the dispatch contract: it names the skill to run and specifies the exact compact return format in every dispatch, rather than relying on `tdd`'s default output. Updated D12 and the Primary Flow Build step and Coordinations.
- **Resolved by:** evidence
- **Affected decisions:** D12
- **Changed in spec:** Primary Flow (Build); Coordinations

### F2: code-review has no compact-verdict mode

- **Agent:** junior-developer
- **Finding:** `code-review`'s only documented output is its full template report; the spec required a concise verdict but named no mechanism, and an undocumented prompt override could silently break.
- **Resolution:** Folded into the driver-owned dispatch contract (D12): the driver requests a concise findings-by-severity verdict in the dispatch; how that is produced is implementation. Updated Primary Flow (Review) and Coordinations.
- **Resolved by:** evidence
- **Affected decisions:** D12
- **Changed in spec:** Primary Flow (Review); Coordinations

### F3: full review fidelity had no feasible mechanism given the sub-agent nesting constraint

- **Agent:** junior-developer (with gap-analyzer)
- **Finding:** D11 committed to full specialist coverage, but `code-review` achieves coverage by dispatching a panel of sub-agents, and a sub-agent cannot dispatch further sub-agents, so review-inside-a-sub-agent collapses to a single reviewer. Running review in the main loop preserves the panel but reintroduces the context cost D12 exists to avoid.
- **Resolution:** Sharpened D11: the driver runs as a main-loop skill so review can be invoked as a skill that fans out its own panel, and only the concise verdict (D12) returns to the driver, so the panel's deliberation never enters the driver's context. The exact dispatch topology is an implementation concern for plan-implementation (no mechanic-specialist pulled in at the spec stage per the skill's roster rule).
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Changed in spec:** Primary Flow (Review); Coordinations

### F4: the changed-file scope check had no defined baseline

- **Agent:** junior-developer (with on-call-engineer)
- **Finding:** D8 checked that changed files "stay within the item's slice," but the work-item format has no scope field, so "the slice" was undefined and the gate had nothing to measure against.
- **Resolution:** Recorded the baseline definition (heuristic inference versus a declared scope field) as an open item (OI-2) pending the operator's research into the superpowers pack; kept the parts that hold regardless (the check exists and surfaces suspicious changes). Updated D8.
- **Resolved by:** user input (deferred to OI-2 pending research)
- **Affected decisions:** D8
- **Changed in spec:** Primary Flow (Verify); Edge Cases and Failure Modes; Open Items (OI-2)

### F5: code-generation, lock, and ignored files would trigger a scope escape on every item

- **Agent:** edge-case-explorer
- **Finding:** Independent verification runs any required code-generation/sync step, which changes generated output, lock files, etc. A strict scope check would flag these every item, making the skill unusable on generation-heavy projects; untracked temp files from tests have the same effect.
- **Resolution:** D8 now excludes files the project ignores and any generation/sync output the verification step itself produced from the scope check. Added an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Changed in spec:** Edge Cases and Failure Modes; Primary Flow (Verify)

### F7: the companion change to the work-item producer was stated as a present-tense precondition

- **Agent:** junior-developer
- **Finding:** The Preconditions said each item "declares" its human-involvement marker, but the work-item template has no such field: it depends on a companion change that must ship first. The spec described a future state as a current fact.
- **Resolution:** Reframed the precondition and the Coordinations row to state the marker depends on a companion change that must ship before the skill can rely on it. Updated D6.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Actors and Triggers (Preconditions); Coordinations

### F8: the clean-tree precondition contradicted the resume flow, and the commit ledger had no matching protocol

- **Agent:** on-call-engineer (with junior-developer, edge-case-explorer)
- **Finding:** D15 refused to start on a dirty tree, but a mid-item interruption leaves a dirty tree, so the most common resume case was impossible without an undocumented manual cleanup. Separately, "commit history is the completion ledger" had no defined item-to-commit match, so an out-of-band commit or an edit between runs silently corrupted resume.
- **Resolution:** Resume now discards the interrupted item's uncommitted partial work (with confirmation) and rebuilds from scratch (D10), and D15 notes the clean-tree precondition applies to a fresh start, not a resume. Each commit carries a machine-readable item reference and resume confirms on any mismatch (D20). User chose "Discard & rebuild."
- **Resolved by:** user input
- **Affected decisions:** D10, D15, D20
- **Changed in spec:** Actors and Triggers (Preconditions); Alternate Flows and States (Resuming); Edge Cases and Failure Modes

### F9: "re-runs that item" was ambiguous and risked a verify bypass

- **Agent:** on-call-engineer
- **Finding:** The mid-item interrupt behavior ("re-runs that item") did not say whether the existing tree state is reused; reusing verified-but-unreviewed work could commit work that skipped a stage, violating D8.
- **Resolution:** D10 commits to discarding partial work and rebuilding from scratch, removing the ambiguity and guaranteeing no item is committed having skipped a stage.
- **Resolved by:** user input
- **Affected decisions:** D10
- **Changed in spec:** Alternate Flows and States (Resuming); Edge Cases and Failure Modes

### F10: a legitimate cross-slice change had no accept-and-commit path

- **Agent:** edge-case-explorer
- **Finding:** When an item's correct implementation legitimately touches another item's files, every listed blocker-exit option failed, permanently wedging the run.
- **Resolution:** D8 now surfaces a cross-slice change for confirmation and offers "accept and commit" as intentional; added the option to the blocker-exit list in the Alternate Flow and an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Changed in spec:** Edge Cases and Failure Modes; Alternate Flows and States (A blocker is raised)

### F11: no behavior when the project has no verification commands

- **Agent:** edge-case-explorer
- **Finding:** If no test/lint/typecheck/build commands exist, independent verification trivially "passes" and the substantive gate has no substance; the spec would silently skip it.
- **Resolution:** D8 now surfaces this as a configuration problem and asks the operator to confirm before proceeding with a scope-check-only run. Added an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Changed in spec:** Edge Cases and Failure Modes

### F12: "resolve" versus "skip" for a human-required item was undefined

- **Agent:** edge-case-explorer (with junior-developer)
- **Finding:** The HITL flow said the operator "resolves the item" without defining whether the skill then builds it or treats it as operator-completed: opposite behaviors with different dependency consequences.
- **Resolution:** D6 and the Alternate Flow now distinguish **proceed** (operator supplied the input; the skill builds it normally) from **skip** (operator owns it entirely; the skill starts no dependent of it).
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Alternate Flows and States (Item needs a human)

### F13: the ~300-word report budget was evidence, not a committed constraint

- **Agent:** gap-analyzer
- **Finding:** D12 listed the report fields but did not commit to the length budget that made the manual flow context-cheap; an implementation could honor the fields and still balloon the reports.
- **Resolution:** D12 now states the ~300-word budget as a behavioral constraint, not just a citation.
- **Resolved by:** evidence
- **Affected decisions:** D12
- **Changed in spec:** Primary Flow (Build)

### F14: the fix-round actor was unspecified and D13 was internally inconsistent

- **Agent:** junior-developer (with gap-analyzer)
- **Finding:** "Dispatches a fix" did not name the actor class; D13 called the mechanism an "implementation choice" while its alternatives rejected a cold re-read, and the path the operator actually used (conductor edits directly) was unaddressed.
- **Resolution:** D13 now commits to a delegated, context-informed, re-verified fix; rejects a context-free fresh agent and the conductor-edits-directly path with reasons; and notes the platform has no continue-agent primitive, constraining the mechanism to a long-lived agent or a reconstructed context bundle.
- **Resolved by:** evidence
- **Affected decisions:** D13
- **Changed in spec:** Primary Flow (Fix to the gate)

### F15: "default to the session model" may not be programmatically accessible

- **Agent:** junior-developer
- **Finding:** No Han skill reads the session model dynamically; if the platform does not expose it, the default reduces to "no override → platform default," which may not match the operator's model.
- **Resolution:** D14 records that the platform's model-inheritance option makes "match the session model" feasible; OI-1 keeps the convention/cost question open with a provisional inherit default that does not block implementation.
- **Resolved by:** evidence
- **Affected decisions:** D14
- **Changed in spec:** Open Items (OI-1)

### F16: the superpowers research outcome was not recorded, and OI-1 lacked a provisional default

- **Agent:** gap-analyzer
- **Finding:** D14 cited "research the superpowers pack" but never said whether it was done, leaving the YAGNI deferral's evidence ambiguous; OI-1 claimed "blocks implementation: No" without a concrete fallback default.
- **Resolution:** D14 now records that superpowers was not researched during this spec and the deferral rests on the absence of a measured gap; OI-1 carries a provisional inherit-the-session-model default and points at the operator's planned research.
- **Resolved by:** evidence
- **Affected decisions:** D14
- **Changed in spec:** Open Items (OI-1); Deferred (YAGNI)

### F17: no recovery path when a dispatched sub-agent never returns

- **Agent:** on-call-engineer
- **Finding:** The spec named no behavior for a sub-agent that hangs (interactive test runner, network-bound step), stranding an unattended run indefinitely.
- **Resolution:** D17 commits the skill to surfacing the stall, describing the tree state, and offering retry/skip/stop, with no wall-clock value pinned. Added an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D17
- **Changed in spec:** Edge Cases and Failure Modes; User Interactions

### F18: no recovery path when a verification command never returns

- **Agent:** on-call-engineer
- **Finding:** The same hang risk applies to the skill-owned verification re-run (a deadlocked or network-bound test), and this is skill code, not a sub-agent boundary.
- **Resolution:** D17 covers a non-returning verification command with the same surface-and-decide behavior. Added an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D17
- **Changed in spec:** Edge Cases and Failure Modes

### F19: no clean-stop affordance outside a blocker escalation

- **Agent:** on-call-engineer
- **Finding:** The operator's only run-level stop was via a blocker escalation; a deliberate "finish this item, then stop" had no path, forcing a raw interruption into the mid-item resume case.
- **Resolution:** D18 adds a clean-stop affordance: the skill finishes the in-progress item to its gate, then halts. Added an Alternate Flow and a User Interactions affordance. This also bounds run cost (global cap deferred).
- **Resolved by:** evidence
- **Affected decisions:** D18
- **Changed in spec:** Alternate Flows and States (Operator stops the run cleanly); User Interactions; Deferred (YAGNI)

### F20: a flaky suite produces a misleading escalation

- **Agent:** edge-case-explorer
- **Finding:** An intermittently-flaky test could trip the fix-loop cap on otherwise-correct work and escalate with failure output unrelated to the item, misleading the operator and eroding trust.
- **Resolution:** D17 requires the escalation to carry the raw verification output and reports a cap-reached case as "gate not cleared," reserving "unsatisfiable" for the build-never-passes row. Added an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D17
- **Changed in spec:** Edge Cases and Failure Modes

### F21: malformed dependency graphs (cycle, duplicate IDs, dangling reference) were unhandled

- **Agent:** edge-case-explorer (with junior-developer)
- **Finding:** A dependency cycle, duplicate item identifiers, or a `Depends on` naming a missing item would wedge the run, corrupt the ledger, or silently skip items while reporting success.
- **Resolution:** D19 adds an up-front graph-validation precondition that refuses to start and names the offending items. Added a precondition and an Edge Cases row.
- **Resolved by:** evidence
- **Affected decisions:** D19
- **Changed in spec:** Actors and Triggers (Preconditions); Primary Flow; Edge Cases and Failure Modes

### F22: out-of-band commits, edits, and rebases corrupt the resume ledger silently

- **Agent:** on-call-engineer (with junior-developer, edge-case-explorer)
- **Finding:** Manual commits, edited or renumbered items, or a rebase between runs make a name-matched ledger skip or re-run items with no surfaced error.
- **Resolution:** D20 has each commit carry a machine-readable item reference and requires the skill to confirm with the operator on any unmatched commit or item rather than guessing. Added an Edge Cases row, a Coordinations note, and a resume-flow note.
- **Resolved by:** evidence
- **Affected decisions:** D20
- **Changed in spec:** Edge Cases and Failure Modes; Coordinations; Alternate Flows and States (Resuming)

### F26: the legacy marker-derivation fallback was an unbuilt behavior for a population that does not exist

- **Agent:** junior-developer (YAGNI candidate)
- **Finding:** D6's fallback to re-derive the human-involvement marker for files lacking it served pre-companion-change files, which are essentially none at ship time and regenerable, and its derivation criteria were unspecified.
- **Resolution:** Moved the fallback to Deferred (YAGNI) with a reopening trigger; D6's main path now relies on the persisted marker only.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Deferred (YAGNI); Actors and Triggers (Preconditions)

## Minor edits

- F23: Dependency-skip interaction underspecified: clarified that the skill emits a note naming the blocked item and skipped dependents and continues autonomously without waiting (junior-developer, Edge Cases and Failure Modes).
- F24: code-review size argument for per-item dispatch / Warning gate may be vacuous on a tiny slice: acknowledged via the existing size-calibration Edge Cases row; the gate evaluates the findings review surfaces at the size it assigns (junior-developer, Edge Cases and Failure Modes).
- F25: "Proposes options" in on-demand triage flagged as exceeding evidence: clarified that the baseline escalation presents evidence and asks the operator to decide, while the opt-in triage (which the operator explicitly requested) is where options are proposed (junior-developer, Alternate Flows and States, A blocker is raised).
