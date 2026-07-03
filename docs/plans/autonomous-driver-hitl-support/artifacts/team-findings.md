# Team Findings: Autonomous Driver Human-in-the-Loop Support

<!--
Behavioral outcomes live in ../feature-specification.md; decisions live in
decision-log.md; load-bearing mechanics live in feature-technical-notes.md.
F# is a single counter shared across major findings and minor edits.
Review team: han-core:junior-developer (JD), han-core:edge-case-explorer (EC),
han-core:user-experience-designer (UX), han-core:gap-analyzer (GAP).
Full gap-analysis report: gap-analysis.md.
-->

## Major findings

### F1: Interactive skill that commits its own work breaks the commit step

- **Agent:** edge-case-explorer (EC2, Critical); junior-developer (JD-001)
- **Finding:** The driver instructs AFK sub-agents not to commit, but never constrains a foreground interactive skill. Several interactive skills (`skill-builder`, `architectural-decision-record`, `runbook`, `coding-standard`) commit their own work. The commit step ("one clean commit staged by path") would then find a clean tree and either fail or make an empty commit. This also breaks the "one commit per item" invariant.
- **Resolution:** Added D14. When a foreground build leaves the item's work already committed, the driver reviews the **cumulative diff of the item's commits** (not just the last), treats them as the item's commit(s), records the commit range in the work-state file, and does not force an empty commit. When the interactive skill leaves the work uncommitted, the driver commits it by path as today. The "one commit per item" language is restated as "one item commit (or the interactive skill's own commit range), plus an optional pre-work-decision commit."
- **Resolved by:** evidence (over-scoped reference plan D9 precedent; the driver's commit-ownership principle)
- **Affected decisions:** D14 (new), D7
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, Alternate Flows, Edge Cases, Coordinations

### F2: A `none`-review item cannot clear the fix loop

- **Agent:** edge-case-explorer (EC1, Critical)
- **Finding:** Primary Flow says a `none`-review item "runs no review and no gate," but the gate-clear rule requires "verification passed AND the verdict reports no finding." A `none`-review item that enters the fix loop on a verification failure never produces a verdict, so it can never clear — it runs to cap and halts even after a successful fix.
- **Resolution:** Stated explicitly that a `none`-review item has no review gate: verification pass alone clears it, on the initial pass and in every fix round. The fix loop for a `none`-review item re-verifies only; there is no re-review.
- **Resolved by:** evidence
- **Affected decisions:** D2, D10
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases

### F3: "Inject feedback while the sub-agent runs" is mechanically impossible concurrency

- **Agent:** edge-case-explorer (EC3, High); junior-developer (JD-006); user-experience-designer (UX-008)
- **Finding:** The dispatched review call is synchronous — the driver blocks until the sub-agent returns, so the operator cannot inject findings "while the sub-agent runs." The affordance is also invisible (no signifier, no stated window).
- **Resolution:** Made the flow sequential: the review sub-agent runs and returns its verdict; the driver then offers the operator the chance to add their own findings before the gate is evaluated, and merges both into the one normalized verdict. The driver narrates the option and its window (until the gate is evaluated) once when the unattended review starts.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows, User Interactions

### F4: Non-code review dispatch does not specify the reference material each reviewer needs

- **Agent:** gap-analyzer (GAP-001, Partial, high priority)
- **Finding:** T1 maps severities but says nothing about the reference material the dispatch wrapper must supply. `content-auditor` requires the original/prior source document to extract and compare facts; without it, the wrapper produces a structurally valid but unreliable verdict. Reference-grounding is the research's top reliability lever.
- **Resolution:** Stated that the driver supplies every review source the reference material it needs: the item and the spec sections it references for all sources; and, for a content audit, the prior version of the document being edited. Captured the reference-grounding requirement in T1 and as a coordination.
- **Resolved by:** evidence (`reviewing-non-code-work-items.md` A8, A39, O5)
- **Affected decisions:** D5
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Coordinations

### F5: The verdict's coverage attestation is undefined for non-code and human reviews

- **Agent:** edge-case-explorer (EC7, Medium)
- **Finding:** The existing verdict contract halts when the coverage section is missing or names a partially-covered panel — phrased for `code-review`'s specialist panel. A single non-code agent or a human read has no panel, so a valid clean review could trigger a false untrustworthy-verdict halt.
- **Resolution:** Generalized the coverage attestation per source: a single review agent attests it ran to completion; a human read attests the operator reviewed it. The halt fires only when the attestation is absent, not when it omits panel-specific language.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** T1
- **Changed in spec:** Primary Flow, Edge Cases

### F6: A clean human review must still produce a durable record

- **Agent:** edge-case-explorer (EC9, Medium)
- **Finding:** A human read that finds no issues could record nothing, and the "durable record missing" halt would then fire on a genuinely clean review.
- **Resolution:** Stated the driver always writes a durable record for a human read, recording "none at or above the gate threshold" explicitly when the operator reports no findings, so a clean human review never trips the missing-record halt.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Affected tech-notes:** T1
- **Changed in spec:** Alternate Flows

### F7: Human-review capture must confirm the normalized findings, with the gate threshold visible

- **Agent:** edge-case-explorer (EC6, Medium); user-experience-designer (UX-004, UX-005, Degrades)
- **Finding:** The operator states findings in natural language; the driver normalizes them into severity/location/claim, and that severity silently decides whether the finding gates — but the operator never sees the active gate threshold, is never shown the captured normalized result, and there is no rule for ambiguous input (missing severity/location).
- **Resolution:** Before the operator confirms all feedback is given, the driver echoes the captured findings back — each with its normalized tier and whether it gates at the run's active threshold — restates the threshold, and asks the operator to confirm that list. When a finding is missing a required field the driver asks the operator to supply it rather than guessing.
- **Resolved by:** evidence
- **Affected decisions:** D8
- **Affected tech-notes:** T1
- **Changed in spec:** Alternate Flows, User Interactions

### F8: The normalized location must accept a document anchor for non-code reviews

- **Agent:** user-experience-designer (UX-007, Friction)
- **Finding:** T1 anchors a finding's location to `code-review`'s `file:line` form, but the human-read and content/IA paths exist for prose deliverables where a finding may be a whole-document or missing-section concern with no line number.
- **Resolution:** The normalized location accepts a document anchor (a section or heading, or "document-wide") when the reviewed artifact is not code; `file:line` is used only where the artifact is code.
- **Resolved by:** evidence
- **Affected decisions:** D5
- **Affected tech-notes:** T1
- **Changed in spec:** —

### F9: Drop the content-auditor "load-bearing → Critical" severity escalation

- **Agent:** junior-developer (JD-008); edge-case-explorer (YAGNI-1)
- **Finding:** `content-auditor` emits no severity tier and no load-bearing flag, so raising a Missing fact to Critical injects a judgment the source does not produce, and at the default `warning` gate the bump is inert. It is a speculative configuration with no cited need.
- **Resolution:** Every Missing fact maps to Warning (gate-blocking at the default threshold); the Critical escalation is dropped. Simplified T1 accordingly.
- **Resolved by:** evidence (YAGNI simpler-version)
- **Affected decisions:** D5
- **Affected tech-notes:** T1
- **Changed in spec:** —

### F10: The pre-work-decision scope-check baseline must be set after the decision commit

- **Agent:** edge-case-explorer (EC4, High)
- **Finding:** D11 commits the decision edit "before the build so it is not flagged as a scope escape," but the item's scope-check baseline is the item's base commit. If the baseline is set before the decision commit and the decision edits a file outside the item's `Expected paths`, the scope check halts with a false scope escape.
- **Resolution:** Stated that the item's scope-check baseline is set after the pre-decision commit, so the decision edit appears in neither the item's scope diff nor its item commit.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows

### F11: Where the operator records a decision is undefined when the item is silent

- **Agent:** junior-developer (JD-013)
- **Finding:** D11 says "where the item or spec directs," but the work-item template does not require a `Requires pre-work decisions: yes` item to name a recording location, leaving the driver without a target and making the "commit the durable edit" step conditional on an undefined location.
- **Resolution:** The driver records the decision where the item names; when the item is silent, it asks the operator where to record it (defaulting to the referenced spec or the work item itself) and always carries the decision into the build as context regardless of whether a durable edit was made.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows

### F12: A pre-work-decision commit failure mid-run has no defined halt path

- **Agent:** edge-case-explorer (EC10, Medium)
- **Finding:** The decide phase is new; a rejected pre-decision commit (hook, lock, git error) mid-run is not routed to the Halt Procedure, leaving the driver unable to build (the edit is uncommitted) with no defined exit.
- **Resolution:** A pre-decision commit failure routes to the existing Halt Procedure with the five-part frame, naming the rejection and disclosing that no build has started — the same class as the existing commit-rejection halt.
- **Resolved by:** evidence
- **Affected decisions:** D11
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases

### F13: Contradictory operator findings across HITL review rounds

- **Agent:** edge-case-explorer (EC5, High)
- **Finding:** In a HITL-review fix loop the operator re-reviews each round and may give different or retracted findings. The spec does not say whether the durable record accumulates or is overwritten, risking a fix agent chasing contradictory instructions across rounds.
- **Resolution:** Each review round (agent or human) produces a fresh normalized verdict that overwrites the durable record; the fix agent for the next round reads only the current round's findings, so a retracted or changed finding is reflected and not re-chased.
- **Resolved by:** evidence
- **Affected decisions:** D8, D10
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow

### F14: Always re-ground after inline work; drop the unmeasurable "ran long enough" trigger

- **Agent:** junior-developer (JD-007); edge-case-explorer (EC12, YAGNI-2); user-experience-designer (UX-010); gap-analyzer (GAP-002)
- **Finding:** "Soft re-ground only if the review ran long enough to erode context" has no measurable trigger. Re-grounding is also an internal mechanic surfaced in the operator-facing flow. And the fix-loop section does not restate that a foreground fix round re-grounds.
- **Resolution:** The driver re-grounds after every foreground interaction — a foreground build (heavier) and a human review (lighter) — with no conditional; the fix-loop section states that a foreground fix round re-grounds the same way. The behavioral flow describes re-grounding by its operator-perceived outcome ("the driver catches up on run state, then continues"); the mechanism stays in the decision log / technical notes.
- **Resolved by:** evidence (YAGNI simpler-version)
- **Affected decisions:** D9
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Alternate Flows

### F15: "Verified exactly like a sub-agent's build" overstates equivalence for hand-built work

- **Agent:** junior-developer (JD-002)
- **Finding:** A sub-agent build is trusted by two mechanisms — a fail-closed build-report parse and independent re-run. A foreground/free-form build produces no build report, so the report parse, the FILES cross-check, and the red-to-green evidence requirement do not exist; only the independent re-run and scope check transfer.
- **Resolution:** Reworded to state that the driver independently verifies every build with the same project verification commands and scope check, and that the build-report parse applies only to sub-agent builds; a foreground build is trusted through independent verification and review, not a report.
- **Resolved by:** evidence
- **Affected decisions:** D3
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, Alternate Flows

### F16: An unfinishable foreground build leaks the deferred blocker menu

- **Agent:** junior-developer (JD-004); edge-case-explorer (EC11, Low)
- **Finding:** "Keeps the item paused and follows the operator's direction" is an ad-hoc version of the deferred skip/defer/blocker menu.
- **Resolution:** Constrained the two permitted paths for an unfinishable or unchanged-tree foreground build: re-foreground the skill so the operator can finish, or halt the run through the existing Halt Procedure. No skip/defer.
- **Resolved by:** evidence
- **Affected decisions:** D7
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows, Edge Cases

### F17: A long foreground build can trigger the deferred auto-compaction condition on the happy path

- **Agent:** junior-developer (JD-003, Blocks decision)
- **Finding:** A long interactive build (a full `skill-builder` interview, a lengthy `refactor`) can consume enough context to fire an auto-compaction that truncates the driver's own instructions — precisely the compaction-survival condition this chunk deferred — inside an in-scope path, after which the driver could resume verify/review/commit on truncated instructions.
- **Resolution:** The driver recommends the operator run a manual compaction before a foreground build so the inline work does not crowd its context, and discloses that surviving an auto-compaction that truncates its instructions is out of scope; if the driver detects it cannot re-establish its instructions and run state, it halts fail-closed rather than continuing on partial state. Full compaction-survival stays deferred to its own chunk.
- **Resolved by:** evidence (fail-closed principle; over-scoped reference plan's manual-compaction-around-human-items recommendation)
- **Affected decisions:** D9
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Out of Scope, Edge Cases

### F18: HITL-built cap exhaustion — the halt guidance ignores the operator's hand-built effort

- **Agent:** edge-case-explorer (EC8, Medium)
- **Finding:** The cap-exhaustion halt reuses the existing "discard and rebuild" guidance, which suits a cheap sub-agent build but not multiple rounds of the operator's own hand-built work.
- **Resolution:** The halt for a foreground-built item names a preserve-the-effort path — the operator may commit the work-in-progress on a separate branch before a fresh run — rather than implying the hand-built work is discardable.
- **Resolved by:** evidence
- **Affected decisions:** D10
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases

### F19: Mixed-run pause boundaries lack attention, mode, consequence, and position signals

- **Agent:** user-experience-designer (UX-001, UX-002, UX-003, UX-006, UX-009)
- **Finding:** Every new pause is under-signposted: no salient "action needed" cue after an unattended stretch (UX-001); the foreground build shares one text stream with an ambiguous, unspecified handback trigger (UX-002); the confirm points do not disclose that they are irreversible and gate-determining (UX-003); the return from a pause is unsignaled and pauses carry no position/status line (UX-006); and the absence of a mid-run stop is never disclosed to a now-present operator (UX-009).
- **Resolution:** Promoted D12 to a full decision covering mixed-run legibility. The driver: emits a salient action-needed prompt as the last line at each pause, carrying the same status line (item, position, phase, awaiting-you) halts use; marks the foreground boundary on both sides and voices the handback prompt in its own voice rather than waiting on an unstated phrase; states each confirm's consequence and finality inline; emits a resumption cue on handback saying whether the operator is free to step away; and discloses once (at the preview and first pause) that the run has no mid-run stop. All are disclosure/signposting — no deferred feature is built.
- **Resolved by:** evidence
- **Affected decisions:** D12
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, User Interactions

### F20: Drivability must be defined as "installed and invocable," covering both dispatch and in-session invocation

- **Agent:** junior-developer (JD-009)
- **Finding:** The startup drivability check is phrased as "dispatchable," but a HITL skill is invoked in-session, not dispatched to a sub-agent, so the check must cover both execution modes.
- **Resolution:** Reworded the startup check to "installed and invocable," covering both a sub-agent dispatch (AFK) and an in-session invocation (HITL); an item aborts the run only when its named skill is neither.
- **Resolved by:** evidence
- **Affected decisions:** D15 (new), D4
- **Affected tech-notes:** —
- **Changed in spec:** Preconditions, Primary Flow

## Minor edits

- F21: "Open Items: None" was premature while the review team had not run; populated and then re-closed after Step 7/8 resolution — junior-developer (JD-005) — feature-specification.md#open-items
- F22: Tie the catalog's literal `manual read` value to the spec's "human read" term so an implementer connects them; note that only the `guidance`-as-review rows (new skill, new agent, other plugin work) actually change in the catalog, and that "other plugin work" is the one whose needs-a-human status flips — junior-developer (JD-010, JD-011) — feature-specification.md#coordinations, D6
- F23: State that `--model` governs only sub-agent (AFK) build and fix; it does not apply to a foreground build or an inline fix — junior-developer (JD-014) — feature-specification.md#user-interactions
- F24: Collapse the preview's "interactive build" and "free-form build" into one operator-facing foreground mode (optionally annotating whether a named skill drives it), since both impose the identical operator obligation — user-experience-designer (UX-011) — feature-specification.md#primary-flow, D12
