# Decision Log: Autonomous Driver Human-in-the-Loop Support

## Trivial decisions

- D13: Work-state phases — the existing work-state file gains the new per-item phases (awaiting-decision, building-in-foreground, awaiting-review-feedback) alongside the current ones, so an item's position through the HITL loop is legible in the same place as an unattended item's. — Referenced in spec: Primary Flow.

## Full decisions

### D1: Scope: HITL support and a normalized review gate

- **Question:** Which of the larger driver design's deferred concerns does this chunk add to `implement-work-items`, and which stay deferred?
- **Decision:** This chunk adds exactly the operator's flowchart plus review normalization: the pre-work-decision gate, the foreground interactive/free-form build, the human review, non-code AFK build-and-review support, in-session state catch-up after inline work, and the bounded fix loop that halts on exhaustion. Cross-session resume, mid-run clean-stop, compaction-survival re-grounding, the rich blocker menu, skip/defer, and repair-upstream stay deferred.
- **Rationale:** The original `autonomous-implementation-driver` spec tried to scope all of these at once and became too complex and inconsistent; the operator is deliberately moving in small chunks. Keeping this chunk to the happy path plus the one hard problem (review-output consistency) is what keeps it buildable.
- **Evidence:** user input; the shipped core loop (`han-coding/skills/implement-work-items/SKILL.md`) and its deferred list; the over-scoped reference plan (`docs/plans/autonomous-implementation-driver/feature-specification.md`).
- **Rejected alternatives:**
  - Pull resume and clean-stop into this chunk too — rejected because it re-creates the over-scoping that made the original plan unwieldy.
  - Defer review normalization to a later chunk — rejected because the operator explicitly wants the review-output inconsistency planned now.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D2, D5, D9
- **Referenced in spec:** Outcome, Alternate Flows, Coordinations, Out of Scope

### D2: Route each phase by the recorded signals

- **Question:** How does the driver decide, per item, whether to run the build and review in a sub-agent or in the foreground?
- **Decision:** The driver reads each item's `Suggested implementation` (+ `AFK`/`HITL`), `Suggested review` (+ `AFK`/`HITL`), and `Requires pre-work decisions` markers and routes each phase by them: an `AFK` build dispatches a sub-agent, a `HITL` build runs in the foreground, a `none` build is free-form foreground; an `AFK` review dispatches the review agent, a `HITL` review foregrounds the human, a `none` review runs no gate and clears on a verification pass alone. This replaces the core loop's validation that refused every combination except `tdd` + `code-review`.
- **Rationale:** The producer already records these three signals on every item (verified in the current skill files); the driver only needs to consume them. Routing by the recorded marker is the minimal change that lets one run mix unattended and needs-a-human items.
- **Evidence:** user input; current `plan-work-items` and `deliverable-skill-catalog.md`; current `implement-work-items` Step 1.7 and Step 3 (already parameterized to read the recorded skill, restricted only by validation).
- **Rejected alternatives:**
  - Infer interactivity at run time instead of reading the marker — rejected because a non-han skill's interactivity is not inferable; the producer's declared marker is the trusted source.
- **Linked technical notes:** —
- **Driven by findings:** F2
- **Dependent decisions:** D3, D7, D8, D10
- **Referenced in spec:** Outcome, Primary Flow, Edge Cases

### D3: Independent verification is unconditional

- **Question:** Does the driver independently verify a hand-built (interactive or free-form) item before reviewing and committing it, or does the operator's confirm-done stand in for verification?
- **Decision:** The driver runs the project's verification commands and the scope check itself for every build, whoever produced it — a sub-agent's, an interactive skill's, or a free-form collaboration's. The operator's "it's done" never substitutes for a green suite or an in-scope diff. The additional build-report parse (the fail-closed check of the sub-agent's returned report — its FILES cross-check and red-to-green evidence) applies only to a sub-agent build; a foreground build produces no report and is trusted through independent verification and review instead.
- **Rationale:** The core loop's central invariant is "do not trust the build report; verify independently." A hand-built item is exactly as capable of a failing suite or an out-of-scope change as a sub-agent's, and the driver owns the commit, so it must verify. The flowchart omitted the Verify node on the HITL branch for brevity; the operator confirmed it should stay. The report-parse distinction was drawn out by review (F15): it is not equivalent across the two build paths.
- **Evidence:** user input (Q-A); current `implement-work-items` Step 3.2 ("Do not trust the report's FINAL GATE"); `build-report-contract.md` (the report parse that only a sub-agent produces).
- **Rejected alternatives:**
  - Trust confirm-done and skip verify for HITL builds — rejected because a hand-built commit could carry a failing suite or an out-of-scope change the review might miss, breaking the driver's verify-before-commit guarantee.
  - Claim a foreground build is "verified exactly like a sub-agent's" — rejected as overstated; only the independent re-run and scope check transfer, not the report parse.
- **Linked technical notes:** —
- **Driven by findings:** F15
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows, Coordinations, Edge Cases

### D4: Startup drivability: abort only on an undispatchable named skill

- **Question:** When a run mixes drivable items with items the driver still cannot handle, does it refuse the whole run, drive a partial set, or something in between?
- **Decision:** The driver validates all items at startup and aborts the whole run — naming the offenders — only when a named implementation skill (han or non-han) cannot be run in its recorded mode (see D15). A bare `none` implementation is **not** an abort: it is driven as a free-form foreground build. The posture stays all-or-nothing: no partial run and no skip.
- **Rationale:** The operator clarified that `none` means "collaboration between operator and agent not guided by any particular skill" — a free-form variant of the HITL build, not an undrivable item. The only genuinely undrivable case is a named skill the driver cannot run, which must fail fast before branching. All-or-nothing matches the core loop and keeps skip/defer out of scope.
- **Evidence:** user input (Q-C); current `implement-work-items` Step 1 startup-refusal posture.
- **Rejected alternatives:**
  - Refuse a bare `none` item — rejected because `none` is a valid free-form HITL build, not a gap.
  - Drive the drivable and flag the rest — rejected because it pulls partial-run and skip semantics into a chunk that deferred them.
- **Linked technical notes:** —
- **Driven by findings:** F20
- **Dependent decisions:** D7, D15
- **Referenced in spec:** Primary Flow, Preconditions, Edge Cases

### D5: One normalized review gate

- **Question:** How does the driver gate reviews whose output is not the `code-review` verdict contract — non-code review agents and a human read?
- **Decision:** Define one driver-side normalized verdict vocabulary (recommendation, coverage attestation, findings at or above the threshold each with a normalized tier / location / claim, below-threshold counts, and a durable record). Every review path maps into it: `code-review` via its existing contract (already this shape), each non-code agent via a translating dispatch wrapper, and a human read entered by the operator in the same shape. The driver supplies every source the reference material it needs to judge the change; the coverage attestation is generalized per source (a single agent attests it ran to completion, a human read attests the operator reviewed it); a finding's location is a `file:line` for code or a document anchor for prose. The driver evaluates one gate against one shape, and an output it cannot map is an untrustworthy verdict that halts.
- **Rationale:** The research's sharpest verified gap is that the driver's fail-closed verdict parser rejects every non-`code-review` output as-is; a single normalized gate closes that gap once and scales to new reviewers, and it naturally absorbs the human-read path. Review found the normalization was incomplete: without reference material a non-code verdict is structurally valid but unreliable (F4); the panel-shaped coverage check would falsely halt a single-agent or human review (F5); and `file:line` does not fit prose (F8). The normalized record also feeds the fix agent, so a human-reviewed item can be fixed unattended.
- **Evidence:** user input (Q3); `reviewing-non-code-work-items.md` (V3, A8, A39, recommendation O5); current `review-verdict-contract.md`; the reviewer severity vocabularies (`code-review` Critical/Warning/Suggestion; `information-architect` Blocks/Degrades/Friction/Polish; `content-auditor` Present/Correctly-Removed/Missing).
- **Rejected alternatives:**
  - Human sign-off for all non-code (keep `code-review`'s contract as the only automated gate) — rejected because it leaves documentation unautomated and only avoids the inconsistency rather than solving it.
  - One spec-anchored `gap-analyzer` gate for all non-code — rejected for this chunk because it trades domain depth for routing simplicity; kept as a deferred alternative.
  - Per-reviewer contracts with a parser each — rejected as more surface to maintain than one normalized shape.
- **Linked technical notes:** T1
- **Driven by findings:** F4, F5, F8, F9
- **Dependent decisions:** D6, D8, D10
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, Coordinations, Edge Cases

### D6: Companion catalog correction plus driver fallback

- **Question:** The current producer catalog assigns some reviews the driver cannot turn into a verdict (`guidance` as the review for new skills and agents emits no findings). How is that handled?
- **Decision:** Ship a companion `plan-work-items` / catalog change so every drivable item's review is one the driver can normalize. The rows that actually change are the `guidance`-as-review rows — new skill, new agent, and other plugin work — which become a human read; documentation stays `content-auditor` / `information-architect`; ADR, coding standard, and runbook already record the literal `manual read` value (a human read). The driver additionally falls back to treating any still-un-normalizable review as a human read, so a stale item degrades rather than halts. The one item whose needs-a-human status flips is "other plugin work" (both its parts were AFK).
- **Rationale:** The research explicitly recommended correcting the catalog's `guidance`-as-reviewer rows to a human read; the core loop already established the pattern of shipping a companion producer change with a driver change. The driver-side fallback makes the driver robust to any catalog row the producer change misses or a future one introduces. Review clarified that only three rows change and only one status flips (F22).
- **Evidence:** user input (Q-B); `reviewing-non-code-work-items.md` (V4, recommendation item 2); current `deliverable-skill-catalog.md` (still lists `guidance` as the review for new skills/agents, and `manual read` for ADR/standard/runbook).
- **Rejected alternatives:**
  - Driver copes only, no catalog change — rejected because leaving `guidance`-as-review in the catalog means the producer keeps recording a review the driver has to reinterpret every run.
  - Refuse un-normalizable reviews — rejected as needless friction when a human-read fallback lets the run continue.
- **Linked technical notes:** T1
- **Driven by findings:** F22
- **Dependent decisions:** —
- **Referenced in spec:** Coordinations, Edge Cases

### D7: HITL build runs in the foreground

- **Question:** How does the driver build an item whose build phase does not run unattended?
- **Decision:** The driver marks the foreground boundary, invokes the recorded interactive skill in the operator's own session with a voiced hand-off, and waits for the operator to confirm the work is done; a bare `none` item is built free-form by the operator and the driver together with no named skill. On confirm, the driver marks control returned, catches up on run state, then verifies the item independently like any build. If the operator reports the item is not done or the tree is unchanged, the driver re-foregrounds the skill or halts through the Halt Procedure — it never skips or defers, and never commits nothing.
- **Rationale:** An interactive skill interviews the operator as it runs and cannot be dispatched to an unattended sub-agent; running it in the operator's session is the only way to drive it. The confirm-done checkpoint gives the driver a defined resume point. Review constrained the unfinished-item paths so they do not become an ad-hoc version of the deferred skip/defer menu (F16).
- **Evidence:** user input; the operator's flowchart; the over-scoped reference plan's foreground interactive-item path (D21).
- **Rejected alternatives:**
  - Dispatch interactive skills to sub-agents anyway — rejected because they would hang on a prompt the sub-agent cannot answer.
  - "Follow the operator's direction" open-endedly on an unfinishable item — rejected as leaking the deferred blocker menu; constrained to re-foreground or halt.
- **Linked technical notes:** —
- **Driven by findings:** F1, F16
- **Dependent decisions:** D14
- **Referenced in spec:** Actors and Triggers, Primary Flow, Alternate Flows, Coordinations, Edge Cases

### D8: HITL review collects human findings into the normalized verdict

- **Question:** How does a human read gate the loop, can the operator add feedback to an unattended review, and how are contradictory findings across fix rounds handled?
- **Decision:** For a human-read review the driver foregrounds the operator's inspection, captures each finding into the normalized verdict (tier, location, claim), asks the operator to supply any missing field rather than guessing, and — before the operator confirms all feedback is given — echoes the captured findings back with each one's tier and whether it gates at the active threshold, restating that threshold. It always writes a durable record, recording "none at or above the gate threshold" when there are no findings. For an unattended review the driver does not pause by default — a fully-autonomous run is uninterrupted so the operator can leave it running — and the operator opts in to contributing by sending a pause-after-review message while that item's automatic review runs — the driver announces the option and starts the review immediately without waiting; the driver honors a request that has arrived by the time the sub-agent returns by pausing to collect and merge the operator's findings, then gating, and absent such a request it does not stop. Each review round produces a fresh verdict that overwrites the durable record, so the fix agent reads only the current round's findings.
- **Rationale:** The flowchart's review branch collects human feedback, confirms it is complete, then gates; its note also lets the operator read the work during an unattended review. Review corrected the impossible concurrency (the operator cannot inject while a blocking sub-agent runs — F3), added the echo-back so a silently mis-tiered finding cannot decide the gate unseen (F7), guaranteed a durable record for a clean human review (F6), and defined the record's per-round overwrite so contradictory findings are not accumulated (F13). A follow-up review corrected the unattended-review feedback path: an always-on post-review offer would interrupt a fully-autonomous run and defeat walk-away operation, so the pause is opt-in via a pre-review message and the driver otherwise never stops after an unattended review (F25).
- **Evidence:** user input; the operator's flowchart and its review-branch note; D5; `SKILL.md` Step 3.3 (the dispatched review is awaited).
- **Rejected alternatives:**
  - Free-form human review the driver interprets ad hoc — rejected because the fix loop and the gate need findings in the one normalized shape to act on them.
  - Operator injects findings concurrently while the sub-agent runs — rejected as mechanically impossible; made sequential.
  - Offer feedback after every unattended review (always pause) — rejected because it interrupts a fully-autonomous run and defeats leaving it to run unattended; the pause is opt-in via a pre-review message instead.
  - Accumulate findings across fix rounds — rejected because it makes the fix agent chase contradictory instructions.
- **Linked technical notes:** T1
- **Driven by findings:** F3, F6, F7, F13, F25
- **Dependent decisions:** D10
- **Referenced in spec:** Actors and Triggers, Primary Flow, Alternate Flows, Edge Cases

### D9: In-session state catch-up, not compaction-survival

- **Question:** What is the "re-ground" step in the flowchart, how far does it go, and what happens if a long foreground interaction triggers an auto-compaction?
- **Decision:** After conducting any inline human work — a foreground build or a human review — the driver catches up on run state (re-reads the work-state and reloads its own instructions) before continuing to verify/review/commit; this is unconditional, with no "ran long enough" trigger, and the fix loop's foreground rounds catch up the same way. The behavioral flow describes this by its operator-perceived outcome; the mechanism lives here and in the technical notes. Surviving an auto-compaction that truncates the driver's own instructions is out of scope: the driver recommends a manual compaction before a foreground build, and if it detects it cannot re-establish its instructions and run state it halts fail-closed rather than continuing on partial state.
- **Rationale:** Conducting an interactive build or a human review inline pushes the driver's own state out of easy reach, so it must re-establish that state before it acts as the orchestrator again. Review removed the unmeasurable "soft if it ran long enough" conditional (F14) and surfaced that a long foreground build can itself trigger the deferred compaction condition on the happy path (F17); the resolution recommends a manual compaction and fail-closes on detected truncation without building the deferred compaction-survival machinery.
- **Evidence:** user input; the operator's flowchart (re-ground after build, soft after review); the reference plan's re-grounding routine (D26) and its manual-compaction-around-human-items recommendation, scoped down.
- **Rejected alternatives:**
  - Conditional "soft" re-ground after a human review — rejected as unmeasurable; made unconditional.
  - Build the full compaction-survival routine now — rejected as out of this chunk's scope; it belongs with cross-session resume.
  - Ignore the compaction-during-foreground-build risk — rejected; disclosed and fail-closed instead.
- **Linked technical notes:** —
- **Driven by findings:** F14, F17
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Preconditions, Primary Flow, Alternate Flows, Out of Scope, Edge Cases

### D10: The fix loop routes back through the same signals

- **Question:** When a gate-blocking finding fires, how does the fix loop behave for HITL items?
- **Decision:** Each fix round re-enters at the build phase routed by the item's build signal: an unattended build is fixed by a fresh sub-agent handed the current durable record; an interactive or free-form build is fixed by the operator inline again, with the same foreground boundary markers and state catch-up. The round then re-verifies and, on a pass, re-reviews through the same review path; a `none`-review item re-verifies only and clears on a verification pass. The fix agent for an unattended build reads the durable record whether the findings came from an agent or the human. On cap exhaustion the run halts through the existing Halt Procedure; for a foreground-built item the halt names a preserve-the-effort path rather than implying the operator's hand-built work is discardable.
- **Rationale:** Treating a fix as just another build, routed by the same signal, keeps the loop consistent with the initial build and avoids a separate fix mechanism per mode. Feeding the durable record to the fix agent is what lets a sub-agent-built, human-reviewed item be fixed without the operator hand-fixing it. Review added the `none`-review clear-on-verify path (F2) and the HITL-cap preservation guidance (F18).
- **Evidence:** user input; the operator's flowchart (gate-fail loops back to BuildStart); current `implement-work-items` Step 3.4 bounded fix loop and Halt Procedure.
- **Rejected alternatives:**
  - A separate fix path that always asks the operator for HITL items — rejected because a sub-agent-built, human-reviewed item can be fixed unattended from the normalized findings.
  - Reuse the sub-agent "discard and rebuild" halt guidance for a foreground-built item — rejected because it ignores the operator's own multi-round effort.
- **Linked technical notes:** —
- **Driven by findings:** F2, F13, F18
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases

### D11: Pre-work-decision gate

- **Question:** What does the driver do for an item whose `Requires pre-work decisions` marker is `yes`?
- **Decision:** The driver pauses before any build, presents what the item says must be decided, and waits for the operator to make and record the decision where the item directs; when the item names no location, the driver asks the operator where (defaulting to the referenced spec or the item). It always carries the decision into the build as context, and when the recording produced a durable edit to a committed file it commits that edit and sets the item's scope-check baseline **after** that commit, so the edit is in neither the item's scope diff nor its item commit. A rejected pre-decision commit routes to the Halt Procedure like any commit failure.
- **Rationale:** A pre-work decision is a gate resolved once before work starts, distinct from a build that needs a human throughout. Committing a durable decision edit before the build keeps it visible to a build sub-agent (which reads committed files) and out of the item's scope check. Review pinned down the scope-check baseline ordering (F10), a default recording location when the item is silent (F11), and the mid-run commit-failure halt path (F12).
- **Evidence:** user input; the operator's flowchart (first node); the reference plan's decision-gate path (D6); `SKILL.md` Step 3.2 (scope check against the item's base commit) and Step 2.2 (commit-failure handling).
- **Rejected alternatives:**
  - Only pass the decision as prompt context, never commit it — rejected because a build sub-agent reads committed files, and an uncommitted decision edit would either be invisible to it or flagged as an out-of-scope change.
  - Set the scope-check baseline at item start — rejected because the pre-decision edit would then falsely register as a scope escape.
- **Linked technical notes:** —
- **Driven by findings:** F10, F11, F12
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Alternate Flows, Edge Cases

### D12: Mixed-run legibility and pause signposting

- **Question:** A mixed run pauses in-session for decisions, foreground builds, and human reviews. How does the driver keep those pause boundaries legible so the operator is never lost about who holds control and what a confirm commits them to?
- **Decision:** The plan preview marks each item's execution mode (unattended / decision-then-unattended / foreground build / human review) and discloses once that the run has no mid-run stop. Each pause emits a salient action-needed prompt as the last line, carrying the same status line (item, position in the run order, phase, awaiting-you) the Halt Procedure uses. The driver bounds foreground work with explicit "you are steering" / "control returned" markers and voices the handback prompt in its own voice rather than waiting on an unstated phrase. Each confirm prompt states its consequence and finality inline. On handback the driver emits a resumption cue saying whether the operator is free to step away. The completion summary names each item's execution mode alongside its outcome. The two foreground labels collapse into one operator-facing "foreground build" mode.
- **Rationale:** The mixed run introduces new pause boundaries on the least-settled part of the driver, and the value of a mostly-unattended run is undermined if the operator cannot tell when they are needed, what confirming commits them to, or where they are. All of this is disclosure and signposting — no deferred feature (clean-stop, skip/defer) is built. Promoted from a trivial decision to a full one after the UX review made the pause-boundary gaps the dominant cluster of findings (F19), and after the two foreground labels were found to impose one obligation (F24).
- **Evidence:** user input; UX review (F19, F24); `SKILL.md` (existing plan preview, per-item narration, five-part Halt, completion summary this stays consistent with).
- **Rejected alternatives:**
  - Leave the pauses as ordinary narration lines — rejected because a pause after an unattended stretch is easily missed and the operator loses wall-clock time.
  - Keep "interactive build" and "free-form build" as distinct preview labels — rejected because both impose the identical operator obligation (steer this build).
  - Build a mid-run stop so the operator has an exit — rejected as out of scope; the constraint is disclosed instead.
- **Linked technical notes:** —
- **Driven by findings:** F19, F24
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, User Interactions

### D14: Adopt a foreground skill's own commits

- **Question:** Some interactive skills (`skill-builder`, `architectural-decision-record`, `runbook`, `coding-standard`) commit their own work when run in the foreground. What does the driver do at the commit step, given it otherwise stages "one clean commit by path" and would find a clean tree?
- **Decision:** When a foreground build leaves the item's work already committed, the driver does not force an empty commit: it reviews the cumulative diff of the item's commits (not only the last), treats them as the item's commit(s), and records the commit range in the work-state file. When the interactive skill leaves the work uncommitted, the driver commits it by path as today. The "one commit per item" model generalizes to "one item commit, or the adopted commit range, plus an optional pre-work-decision commit."
- **Rationale:** The driver owns the commit but must not lose the operator's work or duplicate it; reviewing the cumulative diff keeps the review honest against everything the item shipped, and adopting the commit range preserves the driver's per-item done record without an empty or duplicate commit. Surfaced by the edge-case review (F1, EC2 Critical); the over-scoped reference plan handled the same case, and this is that handling scoped down (no resume ledger).
- **Evidence:** edge-case review (F1); the over-scoped reference plan (D9, "if the interactive skill committed its own work ... reviews the cumulative diff ... records the commit range").
- **Rejected alternatives:**
  - Instruct every foreground skill not to commit — rejected as unreliable; several interactive skills commit as part of their own flow and the driver cannot prevent it.
  - Force a "one clean commit by path" and let it be empty — rejected because it produces an empty or duplicate commit and a broken done record.
- **Linked technical notes:** —
- **Driven by findings:** F1
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Edge Cases, Coordinations

### D15: Drivability means installed and invocable

- **Question:** The startup drivability check (D4) was phrased as "dispatchable," but a HITL skill is invoked in the operator's session, not dispatched to a sub-agent. What exactly is the check?
- **Decision:** Drivability of an item's named implementation skill means it is installed and invocable in its recorded mode — dispatchable to a sub-agent for an `AFK` skill, or invocable in the operator's session for a `HITL` skill. An item aborts the run at startup only when its named skill is neither. A bare `none` implementation needs no skill and is always drivable (free-form foreground).
- **Rationale:** "Dispatchable" reads as sub-agent-only and would mis-test a HITL skill that is never dispatched. Covering both execution modes makes the all-or-nothing startup check correct for the mixed set. A clarification of D4 drawn out by review (F20).
- **Evidence:** junior-developer review (F20); D4; D7 (HITL foreground invocation).
- **Rejected alternatives:**
  - Keep "dispatchable" as the sole test — rejected because it does not describe how a HITL skill is run.
- **Linked technical notes:** —
- **Driven by findings:** F20
- **Dependent decisions:** —
- **Referenced in spec:** Preconditions, Primary Flow, Edge Cases
