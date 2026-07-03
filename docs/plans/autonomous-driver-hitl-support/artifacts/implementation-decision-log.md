# Implementation Decision Log: Autonomous Driver HITL Support

<!--
This file records every implementation decision committed while planning the
HITL support and normalized review gate for `implement-work-items`. Behavioral
and implementation statements live in [../feature-implementation-plan.md](../feature-implementation-plan.md);
this file captures the question, rationale, evidence, and rejected alternatives
for each decision. Round-by-round history lives in [implementation-iteration-history.md](implementation-iteration-history.md).

Every decision here is settled from the R1 deterministic aggregation and its
claim ledger CL-1..CL-15. The spec-level decisions D1..D15 the plan inherits
live in [decision-log.md](decision-log.md); this log records the implementation
decisions those spec commitments still leave open.
-->

## Trivial decisions

- D-13: Apply the companion catalog correction with the driver change — the three `guidance`-as-review rows in `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md` (new skill, new agent, other plugin work) become `manual read, HITL`, shipping in the same change as the driver edit, per spec [D6](decision-log.md#d6-companion-catalog-correction-plus-driver-fallback). — Referenced in plan: Decomposition and Sequencing, RAID Log (Dependencies).

## Full decisions

### D-1: Foreground build is an operator hand-off, not a Skill call

- **Question:** How does the driver run an item whose build does not run unattended, by calling the interactive skill through the `Skill` tool or by handing off to the operator?
- **Decision:** The driver runs a foreground build as an operator hand-off. It marks the foreground boundary, tells the operator to run the recorded interactive skill in their own session (or build free-form for a bare `none` item), and waits for a confirm-done message. `allowed-tools` stays unchanged; no `Skill` grant is added. The SKILL.md hand-off step carries explicit continuation discipline so the driver resumes its own verify/review/commit loop after control returns.
- **Rationale:** The driver is a heavy orchestrator: it owns verify, review, fix, and commit after any build. `skill-composition.md` names a mid-workflow `Skill` call as the moment the calling model is most likely to stop and treat the sub-skill's output as its own final answer, and warns that the more logic the orchestrator carries across the call, the more likely it loses its workflow. A hand-off keeps the driver's existing Agent-only dispatch discipline, needs no new tool grant, and matches the spec's "the operator steers" posture. Spec D9 state catch-up covers the context the pause erodes.
- **Evidence:** CL-1; software-architect A1; junior-developer JD-003 (the spec word "invokes" must be pinned to a hand-off in the SKILL.md build step); `han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-composition.md` (heavy-orchestrator early-exit; a `Skill` caller must add `Skill` to `allowed-tools`); current `han-coding/skills/implement-work-items/SKILL.md` `allowed-tools` (Agent-only, no `Skill`); spec [D7](decision-log.md#d7-hitl-build-runs-in-the-foreground).
- **Rejected alternatives:**
  - Driver calls the interactive skill through the `Skill` tool — rejected because it is the exact heavy-orchestrator early-exit case in `skill-composition.md` and needs a `Skill` grant the driver deliberately does not carry.
  - Trust the operator's confirm-done in place of independent verification — rejected as out of this decision's scope; verification stays unconditional per spec [D3](decision-log.md#d3-independent-verification-is-unconditional).
- **Specialist owner:** software-architect
- **Revisit criterion:** if the proving dry-run A3 shows the hand-off resume is unreliable even with the continuation discipline and the manual-compaction recommendation, reopen and reconsider the deferred compaction-survival mechanism.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-3, D-4, D-5
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Decomposition and Sequencing, RAID Log (Risks), Testing Strategy

### D-2: Generalize the review-verdict contract in place

- **Question:** How does the driver turn a non-code review agent's output and a human read into the same gate it applies to a code review, a second verdict file, a translating adapter agent, or a generalization of the existing contract?
- **Decision:** Generalize `review-verdict-contract.md` in place into one normalized verdict. The per-source severity mapping, per-source coverage attestation, code-or-document location rule, and reference-material requirement live as data inside the one dispatch-instruction contract, honoring [T1](feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping). One parameterized depth-1 Review dispatch covers the `han-coding:code-review` SKILL (which fans out its panel at depth 2) and the `han-core:content-auditor` and `han-core:information-architect` AGENTS; the depth-1 sub-agent runs the skill or embodies the agent, then maps its output to the normalized verdict. The generalized contract is written before any non-code dispatch is wired.
- **Rationale:** T1 already committed the normalized shape, the severity mapping, the per-source coverage, the location rule, and the reference-material contract as load-bearing; the implementation choice left open is where they live. One contract generalized in place keeps a single fail-closed parser and a single gate, scales to a new reviewer, and absorbs the human read. The dispatch generalizes cleanly over a SKILL and an AGENT because both are run by one depth-1 general-purpose sub-agent, per `agent-dispatch-namespacing.md`.
- **Evidence:** CL-3; [T1](feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping); software-architect A2; junior-developer JD-008; test-engineer C1-C3/C6; edge-case C4; current `han-coding/skills/implement-work-items/references/review-verdict-contract.md`; `agent-dispatch-namespacing.md`; spec [D5](decision-log.md#d5-one-normalized-review-gate).
- **Rejected alternatives:**
  - A second verdict file for non-code reviews — rejected because spec [D5](decision-log.md#d5-one-normalized-review-gate) already rejected per-reviewer contracts as more surface to maintain than one normalized shape.
  - A translating adapter agent that converts each source into the verdict — rejected as a single-implementation abstraction before three concrete uses; the dispatch-instruction contract carries the mapping as copied data instead (see Deferred (YAGNI) in the plan).
- **Specialist owner:** software-architect
- **Revisit criterion:** if the per-source mapping grows too complex to carry as a copied table in the dispatch prompt, reopen the translating-adapter-agent option.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-3, D-5, D-13
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points, Runtime Behavior), Decomposition and Sequencing, Testing Strategy

### D-3: Two new reference files, decide-gate and signposting stay inline

- **Question:** Which HITL machinery goes into new reference files, and which stays inline in SKILL.md?
- **Decision:** Add two new reference files. `foreground-handoff-protocol.md` carries the hand-off, the `none` free-form build, confirm-done, the D9 state-catch-up mechanism, the D14 adopt-own-commits inspection, the D7 unfinished-foreground bounded {re-foreground, halt} prompt, and the foreground pause markers. `human-review-capture.md` carries the D8 capture, ask-missing-field, echo-back-with-threshold, confirm-finality, per-round overwrite, the F25 opt-in-pause merge, and the review pause markers. Generalize the verdict contract in place (D-2). Keep the D11 decide-gate and the D12 signposting inline in SKILL.md.
- **Rationale:** The driver body is already at the post-compaction budget (`context-hygiene.md`, roughly 5k per skill), so new detail is pushed to references while the routing constraint is front-loaded inline. A consumer analysis found the hand-off protocol and the human-review capture each carry enough self-contained detail to earn a file, while the decide-gate (one call site) and the signposting (short marker, preview, and summary lists) do not clear the bar and stay inline. The Step 1.7 loosening is a net deletion, which buys back inline budget.
- **Evidence:** CL-4; CL-5; software-architect A3 (consumer analysis); junior-developer JD-006, JD-009; `context-hygiene.md`.
- **Rejected alternatives:**
  - `pre-work-decision-gate.md` as its own file — rejected; one call site, kept inline as the decide sub-step (see Deferred (YAGNI) in the plan).
  - `pause-signposting.md` as its own file — rejected; the markers fold into the two protocol files and the preview and summary lists stay inline (see Deferred (YAGNI) in the plan).
- **Specialist owner:** software-architect
- **Revisit criterion:** if a third protocol needs the pause vocabulary, or the decide-gate grows a second call site or past a screen, reopen the deferred files.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Decomposition and Sequencing, RAID Log (Risks)

### D-4: Work-state file gains scope-baseline and fix-round fields

- **Question:** What new state does the work-state file carry per item so the HITL loop is legible and bounded across a foreground pause?
- **Decision:** The work-state file gains a per-item `scope-baseline` field (the commit the item's scope check diffs against, set after any pre-work-decision commit) and a per-item `fix-round` counter. The fix-round counter is load-bearing: state catch-up after a foreground fix round re-reads the work-state, so a counter kept only in the driver's context would reset and turn the bounded fix loop into an unbounded foreground loop. Both fields persist in the work-state file and are not reset on a fix round. The D13 phases (awaiting-decision, building-in-foreground, awaiting-review-feedback) are added alongside the current statuses.
- **Rationale:** The counter closes the infinite-loop hole (edge-case M10): without a persisted counter, a foreground fix round that triggers state catch-up loses the round count and re-enters the loop with a fresh cap. Setting the scope-baseline after the pre-decision commit keeps the decision edit out of the item's scope diff and out of the item commit, so it is neither flagged as a scope escape nor double-committed.
- **Evidence:** CL-6; CL-12; edge-case M10 (infinite-loop risk), H7/M9; spec [D11](decision-log.md#d11-pre-work-decision-gate), [D13](decision-log.md#trivial-decisions); current `han-coding/skills/implement-work-items/SKILL.md` Step 2.2 (work-state file) and Step 3.2 (scope check against the item's base commit).
- **Rejected alternatives:**
  - Keep the fix-round counter in the driver's working context only — rejected because state catch-up re-reads persisted state and would reset an in-context counter, uncapping the foreground fix loop (edge-case M10).
  - Set the scope-baseline at item start — rejected because the pre-decision edit would then register as a scope escape (spec [D11](decision-log.md#d11-pre-work-decision-gate)).
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if the work-state schema is redesigned, or the fix loop stops re-entering through state catch-up.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-5, D-11
- **Referenced in plan:** Implementation Approach (Data Model and Persistence, Runtime Behavior), Decomposition and Sequencing, RAID Log

### D-5: Fix loop routing and none-review clear-on-verify

- **Question:** How does the fix loop behave for HITL items, and where does the none-review clear-on-verify rule appear?
- **Decision:** Each fix round re-enters at the BUILD phase routed by the item's build signal (AFK dispatches a fresh sub-agent, HITL fixes in the foreground through the hand-off, `none` fixes free-form inline), and never re-runs the Decide gate. Re-review runs through the same review path routed by the review signal (AFK dispatches the review, HITL foregrounds the human read again, `none` skips). The none-review clear-on-verification-alone rule is stated at both the initial gate and inside the fix loop. The fix-round counter (D-4) bounds the loop across foreground state catch-up.
- **Rationale:** Treating a fix as another build, routed by the same signal, keeps the loop consistent with the initial build and avoids a separate fix mechanism per mode. Stating the none-review clear rule at both sites closes the hole where a none-review item that failed verification enters the fix loop with no clear condition and can never exit.
- **Evidence:** CL-6, CL-7; edge-case C1/C2/H8/M10; spec [D2](decision-log.md#d2-route-each-phase-by-the-recorded-signals), [D10](decision-log.md#d10-the-fix-loop-routes-back-through-the-same-signals); spec finding F2; current `han-coding/skills/implement-work-items/SKILL.md` Step 3.4 (the "as in 3.3" re-review line at SKILL.md:319).
- **Rejected alternatives:**
  - Re-run the Decide gate on each fix round — rejected; a pre-work decision is resolved once before work starts (spec [D11](decision-log.md#d11-pre-work-decision-gate)), so re-deciding would re-pause and re-commit.
  - State the none-review clear rule only at the initial gate — rejected; a none-review item that failed verification and entered the fix loop would then have no clear condition inside the loop and could never exit (edge-case C2, spec F2).
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if the fix loop's re-entry point changes away from the build phase.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Decomposition and Sequencing, Testing Strategy

### D-6: Commit step adopts a foreground skill's own commits

- **Question:** What does the commit step do when a foreground skill has already committed the item's work and the tree is clean?
- **Decision:** Step 3.5 branches. A dirty tree stages and commits the item's work by path as today. A clean tree with new commits since the item's scope-baseline (`git log baseline..HEAD`) triggers the driver's own inspection of the cumulative diff (`git diff baseline HEAD`), not a second review dispatch, then adopts the commit range as the item's commit(s) and records the range in the work-state file. No empty commit is forced.
- **Rationale:** The driver owns the commit but must not lose or duplicate the operator's work. Inspecting the cumulative diff keeps the driver's per-item done record honest against everything the item shipped, and adopting the commit range preserves that record without an empty or duplicate commit. The inspection is the driver's own read, not another review dispatch, because the change already passed the item's review path.
- **Evidence:** CL-8; edge-case C3; spec [D14](decision-log.md#d14-adopt-a-foreground-skills-own-commits); current `han-coding/skills/implement-work-items/SKILL.md` Step 3.5.
- **Rejected alternatives:**
  - Force a "one clean commit by path" that turns out empty — rejected; it produces an empty or duplicate commit and a broken done record (spec [D14](decision-log.md#d14-adopt-a-foreground-skills-own-commits)).
  - Re-dispatch a review over the adopted commits — rejected; the change was already reviewed through the item's review path, so the commit-step cumulative-diff inspection is the driver's own check, not another review.
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if the one-commit-per-item model is replaced.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Decomposition and Sequencing, Testing Strategy

### D-7: Drivability resolves the named skill to an installed path

- **Question:** How does the startup drivability check verify a named implementation skill is installed and invocable in its recorded mode?
- **Decision:** The check resolves each item's named implementation skill to an installed plugin's `skills/<name>/SKILL.md` (for a skill) or the agent `.md` (for an agent) via Glob or find under the installed plugin paths. A resolvable skill is treated as drivable in its recorded mode; a HITL skill's in-session invocability is proxied by installed-and-resolvable. An unresolved named skill aborts the whole run at startup, naming the offender. A bare `none` needs no skill and is always drivable.
- **Rationale:** "Dispatchable" as written in spec D4 reads as sub-agent-only and would mis-test a HITL skill that is never dispatched (spec D15). Resolving the skill's on-disk definition is the check that covers both modes, is available during a read-only preflight, and lets the all-or-nothing startup abort fire before anything is branched.
- **Evidence:** CL-10; edge-case M11; spec [D4](decision-log.md#d4-startup-drivability-abort-only-on-an-undispatchable-named-skill), [D15](decision-log.md#d15-drivability-means-installed-and-invocable); OQ-C resolution in [implementation-iteration-history.md](implementation-iteration-history.md).
- **Rejected alternatives:**
  - Leave the check as an undefined "dispatchable/invocable" — rejected; not deferrable, an undefined check cannot abort correctly (edge-case M11).
  - Actually invoke each HITL skill at startup to test invocability — rejected; it would run an interactive skill during a read-only preflight, so installed-and-resolvable is the available proxy.
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if a resolvable-but-not-invocable skill passes startup and fails at the hand-off often enough to warrant a deeper check (see plan RAID Assumption A1).
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points, Runtime Behavior), Decomposition and Sequencing, RAID Log (Assumptions)

### D-8: Opt-in review pause is checked after the sub-agent returns

- **Question:** How and when does the driver detect an operator's opt-in request to pause an unattended review?
- **Decision:** The opt-in check runs after the review sub-agent returns its verdict, scoped to AFK-review items only; the driver never waits before starting the review. It detects a pending request (an operator message queued during the synchronous sub-agent run) and, when one is present, pauses to collect and merge the operator's findings into the one normalized verdict before gating; absent a request it does not stop. The pending-request-detection mechanism is pinned with a proving dry-run (A7b). If the no-yield read proves unreliable on the platform, the documented fallback is a standing or pre-item opt-in the operator sets before the review runs.
- **Rationale:** F25 made the pause opt-in so a fully-autonomous run is uninterrupted. The check must sit after the return because the operator cannot inject while a blocking sub-agent runs (spec F3). The detection mechanism is a Claude Code harness behavior, not codebase data flow, so a dry-run is the right instrument, and a fallback is documented because the mechanism is unproven.
- **Evidence:** CL-11; edge-case H6/M13; junior-developer JD-005; test-engineer A7b; spec [D8](decision-log.md#d8-hitl-review-collects-human-findings-into-the-normalized-verdict), spec findings F25 and F3; OQ-A resolution in [implementation-iteration-history.md](implementation-iteration-history.md).
- **Rejected alternatives:**
  - Offer feedback after every unattended review — rejected; it interrupts walk-away operation (spec F25).
  - Check for the request before dispatching the review — rejected; the operator decides while the review runs, so the driver must not wait before starting it (spec F25 timing refinement).
  - Rely on the no-yield read with no fallback — rejected; the mechanism is unproven on the platform, so a standing/pre-item fallback is documented.
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if A7b shows the no-yield read is unreliable, switch the wiring to the standing/pre-item opt-in fallback.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Decomposition and Sequencing, RAID Log (Risks), Testing Strategy, Open Items

### D-9: Ship the validation loosening and phase routing as one atomic edit

- **Question:** Can the Step 1.7 validation loosening and the Step 3 HITL routing ship as separate edits?
- **Decision:** No. Removing the "all fully autonomous" and "supported combination" refusals and adding the drivability check (Step 1.7), together with adding the Step 3 HITL routing, ship as one atomic edit to SKILL.md. Staging them separately leaves a transient state that either admits HITL items it cannot yet route, or routes phases it still refuses at validation.
- **Rationale:** The two edits are two halves of one behavior change; either half alone is internally inconsistent. Landing them together is the only state that is coherent at every commit.
- **Evidence:** CL-9; edge-case H5.
- **Rejected alternatives:**
  - Land the Step 1.7 loosening first, then the routing — rejected; between the two commits the driver would admit items it cannot drive (edge-case H5).
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if the SKILL.md steps are restructured so the two edits no longer overlap.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Decomposition and Sequencing

### D-10: The critical gate does not block content-audited items

- **Question:** How should `--gate critical` interact with content-auditor's Warning-only output?
- **Decision:** Document it as the expected consequence. Under `--gate critical`, content-auditor emits only Warning, so content-audited items never block (effectively un-gated at that threshold); the default `warning` gate is what gates doc facts. information-architect still gates under critical (Blocks maps to Critical). Do not reopen spec finding F9's drop of the Critical escalation. Record it as a documented behavior and a non-blocking Open Item flagged for operator awareness.
- **Rationale:** content-auditor produces no field to derive a Critical from, and at the default `warning` gate every Missing fact already blocks (T1), so the critical-gate interaction is a natural consequence of the severity mapping, not a defect to fix now. Surfacing it keeps the operator from assuming `--gate critical` gates doc facts.
- **Evidence:** CL-14; junior-developer JD-007; [T1](feature-technical-notes.md#t1-normalized-review-verdict-and-per-source-severity-mapping) (content-auditor Present/Correctly-Removed/Missing, no Critical field); spec finding F9; OQ-B resolution in [implementation-iteration-history.md](implementation-iteration-history.md).
- **Rejected alternatives:**
  - Reopen F9 and add a Critical escalation to content-auditor — rejected; content-auditor produces no field to derive a Critical from, and at the default `warning` gate every Missing already blocks (T1).
  - Let the critical gate un-gate content items silently — rejected; the consequence is surfaced to the operator as an FYI, not hidden.
- **Specialist owner:** junior-developer
- **Revisit criterion:** if an operator relies on `--gate critical` to gate a content-audited item, reconsider F9.
- **Dissent (if any):** none. This is the one spec-level claim (CL-14, one finding, one specialist); the spec-maturity gate did not trip, so it is recorded as a documented behavior plus a non-blocking open item rather than a spec change.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Open Items

### D-11: Pre-work-decision gate mechanics

- **Question:** What is the exact sequence of the pre-work-decision gate, and how does a pre-decision commit failure halt?
- **Decision:** The decide sub-step records the operator's decision (asking where to record it when the item is silent, defaulting to the referenced spec or the item), commits the durable edit, sets the item's scope-baseline (D-4) after that commit, and carries the decision into the build as context. A pre-decision commit failure gets a distinct halt frame that states no build has started and only the decision edit sits in the tree. The Decide sub-step never re-runs inside the fix loop (D-5).
- **Rationale:** A pre-work decision is a gate resolved once before work starts. Committing the durable edit before the build keeps it visible to a build sub-agent (which reads committed files) and out of the item's scope check; setting the baseline after the commit is what excludes the edit from the scope diff. The distinct halt frame tells the operator exactly what is in the tree when the pre-decision commit is the thing that failed.
- **Evidence:** CL-12; edge-case H7/M9; spec [D11](decision-log.md#d11-pre-work-decision-gate), spec findings F10 and F12; current `han-coding/skills/implement-work-items/SKILL.md` Halt Procedure and Step 2.2 commit-failure handling.
- **Rejected alternatives:**
  - Only pass the decision as prompt context, never commit it — rejected; a build sub-agent reads committed files, so an uncommitted edit is either invisible to it or flagged out-of-scope (spec [D11](decision-log.md#d11-pre-work-decision-gate)).
  - Reuse the generic commit-failure halt frame — rejected; the operator needs to know no build ran and only the decision edit is uncommitted (edge-case M9).
- **Specialist owner:** edge-case-explorer
- **Revisit criterion:** if the scope-check baseline model changes.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Runtime Behavior), Decomposition and Sequencing

### D-12: Cleanup edits carried with the change

- **Question:** What incidental corrections must ride along with this change so the touched files stay internally consistent?
- **Decision:** Generalize the `build-report-contract.md` intro off `han-coding:tdd` (it applies to any AFK build skill); remove the "(for a drivable run, tdd/code-review)" parentheticals in SKILL.md Step 3; define the D13 phase names in SKILL.md; and pin the unfinished-foreground path to a bounded {re-foreground, halt} prompt.
- **Rationale:** These are consistency fixes the routing generalization makes necessary. Leaving the tdd-specific framing, the drivable-run parentheticals, or an undefined phase vocabulary in place would contradict the new behavior the same run introduces.
- **Evidence:** CL-15; junior-developer JD-010; spec [D7](decision-log.md#d7-hitl-build-runs-in-the-foreground), spec finding F16; spec [D13](decision-log.md#trivial-decisions); current `han-coding/skills/implement-work-items/references/build-report-contract.md` (intro at L14, parentheticals at L15) and SKILL.md.
- **Rejected alternatives:**
  - Leave the tdd-specific framing in `build-report-contract.md` — rejected; the contract now serves any AFK build skill, so a tdd-specific intro is inaccurate.
  - Leave the unfinished-foreground path open-ended — rejected; an open-ended "follow the operator's direction" leaks the deferred blocker menu (spec F16), so it is bounded to {re-foreground, halt}.
- **Specialist owner:** junior-developer
- **Revisit criterion:** if a later chunk adds the deferred blocker menu, which would revisit the unfinished-foreground path.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points), Decomposition and Sequencing

### D-14: Verification is manual dry-run plus read-the-file contract checks

- **Question:** How is this change verified, given no automated test harness exists for skill behavior?
- **Decision:** Verification is read-the-file contract checks (C1-C8) plus manual dry-run scenarios (A1-A10) per execution mode, plus regression (A1 and the still-applicable Step 1.7 refusals). The proving dry-runs A3 (foreground resume) and A7b (opt-in pause) are Definition-of-Done gates. No automated test scaffolding or golden-file snapshots are built.
- **Rationale:** The repo has no compiler, test runner, or service for skill behavior (discovery notes), so verification is dry-running the skills and checking behavior against the contracts. The two proving dry-runs are promoted to DoD gates because they test the two unproven platform behaviors (hand-off resume, opt-in-pause message read).
- **Evidence:** CL-13; test-engineer full plan; `docs/plans/autonomous-driver-hitl-support/artifacts/.discovery-notes.md` (no automated test harness); CONTRIBUTING coverage rule.
- **Rejected alternatives:**
  - Build automated test scaffolding or golden-file snapshots for the skill — rejected; no skill test framework exists to host them, and golden files over free-form agent returns are non-deterministic noise (see Deferred (YAGNI) in the plan).
  - A separate information-architect end-to-end dry-run — rejected; the C3 reading covers the same mapping mechanics as content-auditor (see Deferred (YAGNI) in the plan).
- **Specialist owner:** test-engineer
- **Revisit criterion:** if a skill test framework is added to the repo, reopen the automated-scaffolding option.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Testing Strategy, Definition of Done, Deferred (YAGNI)
