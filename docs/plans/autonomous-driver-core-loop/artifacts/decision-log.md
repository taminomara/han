# Decision Log: Autonomous Driver — Core Loop

<!--
This file records every decision settled while specifying the Autonomous Driver
Core Loop. Behavioral statements live in
[../feature-specification.md](../feature-specification.md); this file captures the
history, rationale, evidence, and rejected alternatives for each decision.

This core loop is a deliberately narrow slice of the larger design in
../../autonomous-implementation-driver/. Where a decision here is the descoped
counterpart of a reference-plan decision, the Evidence field cites that reference
decision (e.g. "reference plan D3").
-->

## Trivial decisions

- D20: Plugin placement and invocation — the driver ships as a coding-time skill in the `han-coding` plugin, alongside `tdd` and `code-review`, since the unit of work it drives is coding; the exact slash-command name is left to implementation (considered an orchestration skill in the planning plugin; rejected because the work it runs is coding, not planning). — Referenced in spec: none (placement is not a behavior).

## Full decisions

### D1: Core scope and outcome

- **Question:** What does this first slice of the driver do, for whom, and what does a successful run produce?
- **Decision:** The skill takes a trusted `work-items.md` plus the committed spec or plan its items reference, and drives implementation end to end for **unattended, non-interactive items only** (building each item test-first, verifying it, reviewing it, fixing it to a gate, and committing it), offloading the build and the review to sub-agents. It runs fully unattended after a one-time plan confirmation and halts the whole run on any item it cannot complete on its own. The human-in-the-loop path, clean-stop, resume, compaction recovery, stall handling, and the operator-interactive blocker menu are out of scope for this core and are deferred to follow-on features.
- **Rationale:** The full autonomous-implementation-driver design proved too broad to deliver as one feature. The operator has chosen an iterative build: ship the core loop first (the per-item build → verify → review → fix → commit cycle that is roughly 80% of the manual conducting work) under simplifying assumptions (no interruptions, no cancellation, no compaction, no stalls, and a trusted uncommitted work-state file), then layer the interaction, durability, and resilience surfaces in later features.
- **Evidence:** Reference plan D1 (full scope and outcome) and its motivation (issue #96; the operator's manual-run feedback, a 7-item feature driven in 6 commits); operator direction in this planning session to plan only the core loop under the stated assumptions. `tdd` builds and tests but does not commit (`han-coding/skills/tdd/SKILL.md`); `code-review` audits changes (`han-coding/skills/code-review/SKILL.md`); `plan-work-items` produces the items (`han-planning/skills/plan-work-items/SKILL.md`).
- **Rejected alternatives:**
  - Plan the full driver as one feature, rejected because it accumulated major findings across ~20 revisions and cannot be delivered as a single feature.
  - Ship a how-to doc pointing at an external loop runner, rejected because the operator wants a first-party Han skill (reference plan D1).
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** D2, D3, D6, D8, D9, D16
- **Referenced in spec:** Outcome; Actors and Triggers; Coordinations

### D2: Serial, one-item-at-a-time processing

- **Question:** Does the skill build items one at a time or several in parallel?
- **Decision:** Items are processed serially in dependency order, one at a time; the run order is built from each item's `Depends on` field.
- **Rationale:** The work items share a single working tree and the build skill does not commit its changes, so two items built concurrently would overwrite each other's uncommitted work. Serial processing with a commit between items keeps each item's changes isolated and the tree clean. Because this core halts the whole run on any unresolvable item ([D6](#d6-halt-the-whole-run-on-any-unresolvable-item)), the reference plan's "skip the dependents of a blocked item and continue" behavior does not apply here; dependency order governs only sequencing.
- **Evidence:** `tdd` leaves changes uncommitted in the working tree (`han-coding/skills/tdd/SKILL.md`); `work-items.md` orders items by a `Depends on` field and is single-file, single-repository (`han-planning/skills/plan-work-items/references/work-items-file-format.md`); reference plan D2.
- **Rejected alternatives:**
  - Parallel execution across independent items, rejected because the shared working tree makes it unsafe without per-item isolation, which does not exist (deferred in the reference plan under YAGNI).
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** D8
- **Referenced in spec:** Primary Flow

### D3: Per-item loop shape

- **Question:** What is the fixed sequence the skill runs for each item?
- **Decision:** Build (test-first via `tdd` by default) → independently verify → review (via `code-review`) → bounded fix loop until the gate clears → commit.
- **Rationale:** The operator's manual runs converged on exactly this loop and identified it as roughly 80% of the conducting work the two building-block skills do not provide. Encoding it as the skill's core makes the conductor first-party. This is the heart of the core slice.
- **Evidence:** Operator feedback: "for each slice: tdd → review → (while findings ≥ Warning and rounds < 3) fix → re-review → verify green → commit"; `tdd` and `code-review` skill contracts; reference plan D3.
- **Rejected alternatives:**
  - Build-then-commit with review as an optional afterthought, rejected because keeping review in the gate is the operator's whole motivation; review caught real latent bugs in the manual runs.
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** D4, D5, D7, D8, D9, D10, D11
- **Referenced in spec:** Primary Flow

### D4: Completion gate severity threshold

- **Question:** What review result lets an item be considered done, given `code-review`'s severity scale?
- **Decision:** An item clears the review gate when the review reports no finding at or above a configurable severity threshold; the default threshold is Warning, so any Critical or Warning finding blocks the commit and Suggestions do not. The gate reads the condensed verdict the review returns, whose completeness at and above the threshold and full-coverage attestation are secured by [D9](#d9-self-contained-full-coverage-review-with-a-condensed-verdict-gate).
- **Rationale:** `code-review`'s levels are Critical, Warning, Suggestion, with no "medium". Warning is the natural mapping of "medium-and-above", and a configurable threshold lets a project gate more strictly (Critical only) or more loosely (include Suggestions). The gate is evaluated against whatever findings the review surfaces at the size it assigns the slice.
- **Evidence:** `han-coding/skills/code-review/SKILL.md` severity levels (Critical / Warning / Suggestion) and size-calibration rules; issue #96 ("severity threshold should probably be configurable"); reference plan D4 (user input selecting "Warning+, configurable").
- **Rejected alternatives:**
  - Block on Critical only, rejected because it would silently ship Warning-level bugs the operator wanted a gate on.
  - Block on Critical or Warning with no knob, rejected because projects legitimately want a stricter or looser bar.
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** D5, D9
- **Referenced in spec:** Primary Flow; Edge Cases and Failure Modes

### D5: Bounded fix-loop cap, then halt

- **Question:** What happens when a review keeps finding gate-blocking issues?
- **Decision:** The skill runs a bounded fix loop (fix, re-verify, re-review) up to a configurable cap (default 3 rounds). The loop is entered either when verify's commands report failures or when the review reports a gate-blocking finding. Only a verification command that **reports failures** makes a not-cleared round that loops to the next fix without a review (so the panel never reviews known-broken code); a verification command that **fails to execute**, an **out-of-path change**, or an **untrustworthy re-review verdict** halts the run immediately ([D6](#d6-halt-the-whole-run-on-any-unresolvable-item)) rather than being counted as a not-cleared round, so a mechanism failure never silently burns the cap and surfaces later as "gate not cleared". If the gate has not cleared at the cap, the skill halts the whole run with the residual findings listed. A cap of zero is valid and means halt on the first gate-blocking finding with no fix attempt; an unbounded, never-halt loop is not a supported value.
- **Rationale:** An unbounded loop can thrash forever on an item the sub-agents cannot resolve. A small cap bounds the cost; when it is exhausted, the core has no operator-interactive recovery to fall back on (that is deferred), so it halts the run with evidence rather than looping or committing over the findings.
- **Evidence:** Operator feedback ("rounds < 3", "iteration cap"); issue #96 failure-handling direction ("a hard cap on the iteration count"); reference plan D5.
- **Rejected alternatives:**
  - Escalate to an interactive operator menu at the cap, rejected for the core because operator interaction is deferred; the core halts the run instead (reference plan D7, deferred).
  - Unbounded retry, rejected because it can spin indefinitely and burn cost on an unsatisfiable item.
- **Linked technical notes:** (none)
- **Driven by findings:** fix-loop entry from a failed verification clarified, the not-cleared-round path scoped to verification-reported-failures only, and cap-zero surfaced in the edge cases in R1 (team-findings.md F1, F6, F16)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; Edge Cases and Failure Modes

### D6: Halt the whole run on any unresolvable item

- **Question:** With no operator interaction in scope, what does the core do when it reaches a state it cannot resolve unattended?
- **Decision:** The skill halts the **whole run** on the first item it cannot complete cleanly: a sub-agent-escalated blocker; a build that produces no file changes (or only changes to excluded files), or whose `tdd` report is missing the required test-failure-then-pass evidence; a verification command that fails to execute (as distinct from one that reports failures); a changed file outside the item's declared expected paths (including during a fix round); a fix loop that reaches its cap without clearing the gate; an untrustworthy review verdict (including on a fix round's re-review); or a rejected commit. Items completed before the halt remain committed on the branch; the halting item's uncommitted work is left in the tree for the operator to inspect. The skill emits a completion summary naming the run as partially complete (items committed, the halting item and why, items not reached) using the five-part halt frame (status line, one-sentence reason, tree-state disclosure, evidence with a durable-review-record pointer when review-gated, and what-to-do-next including that re-invocation starts a fresh run rather than a resume) and stops. It does not offer any recovery menu, does not skip the item and continue, and does not commit over the problem.
- **Rationale:** The operator chose to build the driver iteratively and keep the core free of any mid-run operator interaction. That rules out the reference plan's rich escalation surface (triage, accept-a-flagged-change, gate override, repair-upstream, defer, skip). Between the two interaction-free dispositions — halt the whole run, or mark the item failed and continue with independent items — the operator chose to halt the whole run: it is the simpler, more predictable disposition, it never leaves a run limping past a real problem, and it keeps the failure obvious rather than buried in an end-of-run failure list. Completed items stay committed because one commit per item ([D8](#d8-one-commit-per-completed-item)) already made them durable.
- **Evidence:** Operator direction in this planning session (halt the whole run; no operator interaction in the core); reference plan D7 (the full interactive blocker machinery, deferred here).
- **Rejected alternatives:**
  - Mark the item failed, skip its dependents, and continue with independent items, rejected by the operator in favor of halting the whole run.
  - Offer the operator a recovery menu at the halt, rejected because operator interaction is deferred from the core (reference plan D7).
  - Commit over the problem (skip verify/review, or override the gate), rejected because it defeats the gate that is the feature's headline value.
- **Linked technical notes:** (none)
- **Driven by findings:** halt triggers extended (verification-fails-to-execute, excluded-only build, missing `tdd` evidence, out-of-path-during-fix, untrustworthy re-review), the five-part halt frame added, and the inter-item-regression operator note added in R1 (team-findings.md F1, F2, F4, F6, F11, F15)
- **Dependent decisions:** (none)
- **Referenced in spec:** Outcome; Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes

### D7: Independent verification and scope check before commit

- **Question:** Can the skill trust a sub-agent's "all gates green" before it commits, and what does the changed-file check measure against?
- **Decision:** The skill verifies independently, in two checks. First, it re-runs the project's own verification commands (tests, type-checking, any required code-generation or sync step, lint, and build), determined from the project's own configuration with the operator able to override the set, and trusts those results over the sub-agent's self-report or raw editor diagnostics. A command that **reports failures** is handled by the fix loop; a command that **fails to execute** (a tool missing or removed, a service down, a full disk) is distinguished from that and halts the run as an environment problem rather than being fed into the fix loop as if the code were at fault. Where the project defines no verification commands, the skill surfaces the **scope-check-only** mode in the plan preview so the operator's plan confirmation is its conscious confirmation ([D17](#d17-plan-preview-and-confirmation-before-the-run)), rather than treating an empty check as a pass. Second, it inspects the changed-file set against an **expected-paths declaration** the producer derives from the plan's named touch points and Step-3 codebase exploration, which the operator confirms (when the plan gives no file-level detail the producer flags the item's paths as low-confidence rather than inventing them) ([D19](#d19-companion-changes-to-the-work-item-producer)), treating each added, modified, or deleted path against those paths (so a rename — a delete plus an add — must declare both the old and new paths, and a deleted declared path counts as in-scope) and excluding files the project ignores, any code-generation or sync output produced by any step in the per-item loop (build or verify), and the driver's own artifacts (the work-state file and the durable review record). A change to a file outside the item's declared paths halts the run ([D6](#d6-halt-the-whole-run-on-any-unresolvable-item)); the accept-as-intentional and cross-slice paths the reference plan offers are deferred. The exact expected-paths syntax is a data-format detail of the companion field, settled at `plan-implementation`, not here.
- **Rationale:** In the manual runs, sub-agents repeatedly over-claimed green while real issues remained, and raw editor diagnostics were stale until a code-generation/sync step ran, so only an independent re-run of the project's own checks could tell stale-diagnostic from real-breakage. Sub-agents also occasionally reached past their slice, so the changed-file set is worth inspecting; the expected-paths declaration catches correct behavior written in the wrong files, the gap a review-only gate cannot close. In the core, a detected out-of-slice change halts the run rather than surfacing an accept/reject choice, because operator interaction is deferred.
- **Evidence:** Operator feedback ("Sub-agents over-claimed 'all gates green'... verify-before-trust was mandatory"; stale pre-sync diagnostics; "verify the changed-file set matches the slice"); `tdd` runs the project's test/lint/build and shows output (`han-coding/skills/tdd/SKILL.md`); reference plan D8 (independent verification, the expected-paths field, and the no-verification-commands path); this session's decision to ship the expected-paths companion field ([D19](#d19-companion-changes-to-the-work-item-producer)).
- **Rejected alternatives:**
  - Trust the sub-agent's reported gate result, rejected because it demonstrably shipped false greens and stale-diagnostic confusion in the manual runs.
  - Police scope through review alone with no declared expected-paths field, rejected because it has a structural blind spot for correct-code-in-the-wrong-file (reference plan D8).
  - Surface an out-of-slice change for the operator to accept or reject, rejected for the core because operator interaction is deferred; the core halts instead.
- **Linked technical notes:** (none)
- **Driven by findings:** the execute-failure-vs-reports-failure distinction restored, rename handling specified, the exclusion extended to any per-item-loop step and to the driver's own artifacts, the scope-check-only confirmation folded into the plan preview, and the scope-check-only fix-loop path noted, in R1 (team-findings.md F2, F3, F13, F19)
- **Dependent decisions:** D13
- **Referenced in spec:** Actors and Triggers (Preconditions); Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes; Coordinations

### D8: One commit per completed item

- **Question:** When and how does the skill commit, given the build skill does not commit?
- **Decision:** The skill commits each completed item as a single commit, following the project's commit convention, once verification is green and the review gate has cleared. The commit stages only the item's own code changes (and any project-tracked generation output) and never the driver's own artifacts: the uncommitted work-state file and the durable review record are kept out of every code commit, so a stray `add-all` does not pollute the item's commit with bookkeeping. The per-item code commits are the only run bookkeeping in commit history; run progress and configuration live in the uncommitted work-state file, not in commits ([D18](#d18-uncommitted-single-pass-work-state)). One commit per item is the normal target: the interactive-skill and folded-in-repair cases that the reference plan allows to deviate from it are deferred, so in this core each completed item maps to exactly one code commit.
- **Rationale:** `tdd` deliberately leaves changes in the working tree and does not commit, so the conductor owns the commit. One commit per item gives a clean, revertible history and makes completed items durable, so a run that halts leaves the finished items safely committed.
- **Evidence:** `tdd` does no commits (`han-coding/skills/tdd/SKILL.md`); operator's manual run produced "7 work items in 6 commits, each built test-first, panel-reviewed, fixed where needed, and committed green"; reference plan D9.
- **Rejected alternatives:**
  - Make all changes and commit once at the end, rejected because it loses per-item revertibility and would lose all work if the run halts.
  - Leave committing to the operator, rejected because per-item commits are what make completed work durable across a halt.
  - Interleave marked bookkeeping commits for run state, rejected for the core because the work-state file is uncommitted ([D18](#d18-uncommitted-single-pass-work-state)); the committed-ledger model is deferred (reference plan D20).
- **Linked technical notes:** (none)
- **Driven by findings:** commit staging scoped to the item's code only, with the driver's own artifacts kept out of every commit, in R1 (team-findings.md F4)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; Coordinations

### D9: Self-contained, full-coverage review with a condensed verdict gate

- **Question:** Does autonomous review run at the same specialist coverage as a manual `code-review`, and how does the driver gate on it without the return either dropping a gate-blocking finding or flooding the driver's context?
- **Decision:** Autonomous review applies the same specialist coverage a manual `code-review` would and runs as a **self-contained stage** rather than from the driver's main loop, so the panel's deliberation stays out of the driver's context and the review is isolated from the builder-output bias the driver's context carries. The stage produces a **durable, complete record** of its reconciled findings and returns only a **condensed verdict** to the driver: findings by severity, complete at and above the configured threshold, and attesting full specialist coverage. The verdict is the gate input ([D4](#d4-completion-gate-severity-threshold)). A verdict that cannot be evaluated against the threshold, reports incomplete coverage, or is empty with no positive coverage attestation is treated as a review failure and **halts the run** ([D6](#d6-halt-the-whole-run-on-any-unresolvable-item)): review fails closed, never open. The full record is the input the fix stage reads ([D11](#d11-fresh-fix-sub-agent-with-curated-context)) and the artifact a halt points the operator to; it is a driver artifact kept out of commits like the work-state file ([D18](#d18-uncommitted-single-pass-work-state)), readable by any sub-agent the driver dispatches during the run and retained after a halt so the operator can read the full findings (its exact location and format are settled at `plan-implementation`). The exact dispatch topology that lets the review stage fan out its panel, and any platform capability or depth constraint, is confirmed against the live Claude Code documentation at `plan-implementation` rather than asserted here; the core carries **no reduced-coverage single-reviewer fallback** (matching the reference plan's rejection of a pre-nesting fallback), so if the platform cannot support full-coverage self-contained review, that is resolved at implementation rather than by degrading the gate — review fails closed, never open.
- **Rationale:** `code-review`'s value in the manual runs came specifically from its specialist panel out-performing a single reviewer and reconciling competing claims; a driver that dropped that coverage would lose the thing that made review worth gating on. Running review in a self-contained stage that fans out the panel and returns only a condensed verdict keeps that deliberation out of the driver (context economy) and judges the change on its merits (bias isolation). If the condensed return were the only place findings existed, brevity would compete with the completeness the gate depends on; splitting the return into a durable full record plus a condensed verdict dissolves that competition. Build output is distrusted and independently re-verified ([D7](#d7-independent-verification-and-scope-check-before-commit)) because tests can be re-run; a review verdict is a judgment that cannot be re-run, so it is trusted as returned, bounded by the completeness-at-threshold requirement, the full-coverage attestation, the per-fix re-review, and fail-closed handling of an untrustworthy verdict.
- **Evidence:** Operator feedback ("code-review's specialist panel repeatedly out-performed a single reviewer... that self-reconciliation is the headline value"); `code-review` dispatches a specialist panel via sub-agents (`han-coding/skills/code-review/SKILL.md`); the sub-agent-nesting constraint (a sub-agent cannot itself fan out a panel) that forces review to run where it can fan out (discovery notes in the reference plan's implementation-planning folder); reference plan D11 and D27.
- **Rejected alternatives:**
  - Run review as a single reduced reviewer inside one sub-agent, rejected because it discards the panel coverage that made review valuable.
  - Load the full review report into the driver's context to keep the panel, rejected because it reintroduces the per-item context cost the skill exists to avoid; only the condensed verdict returns.
  - Cram completeness into the condensed verdict by requiring every finding, rejected because it collides with the brevity budget on a heavy slice; the durable record holds completeness instead.
  - Treat an empty or non-evaluable verdict as a clean pass, rejected because it lets an item commit on a review that never ran or never completed; the verdict fails closed to a halt.
  - Carry a reduced-coverage single-reviewer fallback for a platform that cannot fan out the panel, rejected because it degrades the gate that is the feature's headline value; review fails closed and the topology is resolved at implementation instead (matching reference plan D11).
- **Linked technical notes:** (none)
- **Driven by findings:** the durable record given an out-of-commit behavioral location, the fail-closed re-review during fix rounds specified, and the no-reduced-coverage-fallback posture stated in R1 (team-findings.md F5, F6, F8)
- **Dependent decisions:** D10, D11
- **Referenced in spec:** Outcome; Actors and Triggers; Primary Flow; Edge Cases and Failure Modes; User Interactions; Coordinations

### D10: Driver-defined dispatch contract

- **Question:** What do the sub-agents return to the skill, and how does the skill get a structured return and the right skill invoked, given `tdd` emits prose and `code-review` emits a long report by default?
- **Decision:** The **driver defines the contract in every dispatch it makes**, by dispatch instruction, without changing `tdd` or `code-review`: it explicitly names the skill the sub-agent must run (`tdd` for building; `code-review` for reviewing) and specifies the exact compact report the sub-agent must return, short enough for the skill to decide accept/fix/commit/halt from the report alone without reading the diff. The build report's common fields are status, files changed, the final gate result, and any escalation; the observed failure-then-pass evidence is required for a `tdd` build (a `tdd` report missing it is untrustworthy and halts the run, [D6](#d6-halt-the-whole-run-on-any-unresolvable-item)) and is not applicable for a fix round that adds no new behavior. The review returns a condensed verdict referencing its durable record ([D9](#d9-self-contained-full-coverage-review-with-a-condensed-verdict-gate)). Giving `tdd` and `code-review` their own declared structured-output modes is deferred (see the spec's Deferred (YAGNI) section); the driver imposes the contract by instruction for the core.
- **Rationale:** The manual runs found the sub-agents had to be told explicitly which skill to invoke or they would not run `tdd`/`code-review`, and each had to return a short structured report so the orchestrator could conduct many items in one context without reading diffs. `tdd`'s default output is a human narrative and `code-review`'s is a long report, so neither yields a machine-consumable return on its own. The driver imposing the contract in the dispatch is what made the manual flow work, and it requires no companion change to those skills — matching the operator's choice to limit companion changes to the work-item producer's data fields.
- **Evidence:** Operator feedback ("I had to explicitly pass the skill names to the sub-agents"; "Structured, machine-consumed return contracts made the orchestration context-cheap"); `tdd` Step 5 emits a narrative (`han-coding/skills/tdd/SKILL.md`); `code-review` emits a full markdown report by default (`han-coding/skills/code-review/references/template.md`); reference plan D12; this session's decision to impose the contract by instruction rather than by changing `tdd`/`code-review`.
- **Rejected alternatives:**
  - Rely on `tdd`/`code-review` default output and parse it, rejected because the defaults are prose and a long report with no structured escalation field.
  - Add a structured-output mode to `tdd` and `code-review` now, rejected for the core in favor of imposing the contract by instruction; deferred (reference plan D12).
- **Linked technical notes:** (none)
- **Driven by findings:** a `tdd` report missing the required failure-then-pass evidence made an untrustworthy-report halt in R1 (team-findings.md F6)
- **Dependent decisions:** D16
- **Referenced in spec:** Primary Flow; Coordinations

### D11: Fresh fix sub-agent with curated context

- **Question:** When the review finds issues, how is the fix applied so it does not lose the original build context?
- **Decision:** A fix round is delegated to a **fresh fix sub-agent given curated context** — the build report, the review's durable record, and the current cumulative diff (the working tree against the item's base commit at the start of the item, so a later fix round sees all prior rounds' changes rather than a stale original-build diff) — rather than a cold, context-free re-read of the files; the fixed item is re-verified and re-reviewed through the full gate. The fix carries the findings from the durable record so it targets the specific findings that blocked the gate. Continuing the original build sub-agent with its context intact is deferred (the platform's sub-agent-resume primitive is experimental and reported broken for plain sub-agents); the fresh-agent path passes the same context by file and diff and works on the default platform.
- **Rationale:** In the manual runs there was no reliable way to continue a finished sub-agent, so a fix either fell back to the conductor editing directly (loading file context into the strained conductor and bypassing the build skill's discipline) or spawned a cold agent that lost the implementer's context. A fresh fix agent given curated context avoids both: it keeps the build context without depending on an experimental resume primitive.
- **Evidence:** Operator feedback ("No way to continue a finished sub-agent... the original implementer's context was lost"); reference plan D13 and its R11 hands-on verification that sub-agent resume via `SendMessage` is experimental and reported broken for plain sub-agents.
- **Rejected alternatives:**
  - Spawn a fresh, context-free agent for each fix, rejected because it loses the build context and risks regressing prior decisions.
  - Have the conductor make the edits itself, rejected because it loads editing judgment and file context into the conductor's already-strained context and bypasses the build skill's discipline.
  - Continue the original build sub-agent, rejected for now because the resume primitive is experimental and reported broken for plain sub-agents (reference plan D13, deferred).
- **Linked technical notes:** (none)
- **Driven by findings:** "the diff" the fix agent receives disambiguated to the current cumulative diff against the item's base commit in R1 (team-findings.md F18)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; Coordinations

### D12: Model selection policy

- **Question:** How does the skill choose the model for the sub-agents it dispatches, and what model does its own coordination run on?
- **Decision:** The skill dispatches its build and fix sub-agents on an explicit model chosen for what those sub-agents do (structured, test-first code implementation), following Han's convention of choosing a sub-agent's model by what the task demands, not by price, rather than letting them inherit the operator's session model. The operator can override this model for the whole run. The explicit-model rule covers every sub-agent the driver itself dispatches, including the agent that hosts the self-contained review stage ([D9](#d9-self-contained-full-coverage-review-with-a-condensed-verdict-gate)); only the models of the specialist reviewers inside `code-review`'s own panel are governed by the `code-review` skill. Because the skill's own coordination runs in the operator's session, it requires the operator to run it on a session model capable of the coordination role, recorded as an operator-responsibility precondition. Per-item and adaptive automatic model routing remain deferred (reference plan D14).
- **Rationale:** An unnamed sub-agent model silently resolves to the session's most expensive tier, so the model must be set explicitly. Han's standard requires choosing by what the task demands, not cost. The work-item format carries no complexity signal, so a per-item guess would be circular; per-role selection with an operator override is simpler and matches Han's convention. The conductor is the operator's session, so "capable conductor" cannot be a value the skill sets; it is an operator precondition.
- **Evidence:** Reference plan D14 (the explicit-model lesson, the 26-reviewer cost regression, the cheap-controller-collapse finding); Han's model-selection standard "choose based on what the task demands, not price" (`han-plugin-builder/skills/guidance/references/agent-building-guidelines/agent-model-selection.md`); the work-item template has no complexity field (`han-planning/skills/plan-work-items/references/work-item-template.md`).
- **Rejected alternatives:**
  - Default sub-agents to inherit the operator's session model, rejected because an unnamed model silently resolves to the most expensive tier.
  - Choose the sub-agent model per item from a guessed complexity, rejected because the work-item format has no complexity signal and complexity is not reliably known before building.
  - Assert "the conductor runs on a capable model" as a skill behavior, rejected because the conductor is the operator's session and the skill cannot set the session model; it is an operator precondition instead.
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** (none)
- **Referenced in spec:** Actors and Triggers (Preconditions); User Interactions

### D13: Input-validation preconditions

- **Question:** What input does the skill validate up front, and what does it do when validation fails?
- **Decision:** Before starting the first item, the skill validates the work-item input and **refuses to start** (naming the offending items) on any of: a dependency-graph malformation (a cycle, a self-dependency, duplicate item identifiers, or a `Depends on` reference to an item not present in the file); a file with no buildable items at all (empty, or every item invalid — a single invalid item causes a total refusal, since the run is all-or-nothing); a missing `expected-paths` field on any item; a missing `Type` marker on any item; or any item typed `HITL`. All of these are start-time refusals in this core, in the same class as a dirty tree or a red suite, and each refusal names both the reason and the remedy. Unlike the reference plan, the core does not apply a proceed-with-fallback for a missing field: both `expected-paths` and `Type` ship with this core so they must be present, and `HITL`-typed items are outside the core and are refused rather than handled. Revised during W-1 implementation (operator direction): HITL detection now keys off the persisted `Type` marker rather than an unshipped human-required marker, and there is no implementation-skill field to validate.
- **Rationale:** The skill builds a serial run order from the dependency graph; a cycle has no valid order, duplicate identifiers make resolution ambiguous, and a dangling reference can never be satisfied. Each fails silently or wedges if not caught. The core additionally refuses `HITL`-typed items because it has no path to drive them (that path is deferred), so surfacing them up front via the `Type` marker is safer than discovering them mid-run.
- **Evidence:** Reference plan D19 (dependency-graph and field validation) and the edge-case-explorer findings behind it (cycle, duplicate IDs, dangling reference, all High); `Depends on` is the sole ordering field and items are single-file (`han-planning/skills/plan-work-items/references/work-items-file-format.md`); this session's scope (`AFK`-only items; `expected-paths` and `Type` fields shipped with this core).
- **Rejected alternatives:**
  - Discover the malformation mid-run, rejected because by then items may be partly built and the failure is harder to diagnose; up-front validation is cheap and clear.
  - Apply a proceed-with-fallback for a missing `expected-paths` or `Type` field (the reference plan's behavior), rejected for the core because both fields ship here and the HITL path does not exist yet.
- **Linked technical notes:** (none)
- **Driven by findings:** the valid-implementation-skill recognition criterion named (with the mechanism left to `plan-implementation`), remedies added to every refusal, and the "filtered out" wording corrected to the all-or-nothing refusal in R1 (team-findings.md F7, F12, F17)
- **Dependent decisions:** D16
- **Referenced in spec:** Actors and Triggers (Preconditions); Primary Flow; Edge Cases and Failure Modes

### D14: Start preconditions: clean tree and green suite

- **Question:** What must be true before the skill begins a run?
- **Decision:** The skill refuses to start unless the working tree is clean and, where the project defines verification commands, the test suite is green; otherwise it reports the reason and the remedy and stops. A project with no verification commands takes the scope-check-only path ([D7](#d7-independent-verification-and-scope-check-before-commit)) rather than being refused on the green-suite gate. The one exception to "clean" is the run's own uncommitted planning artifacts (the work-items file the operator passed, plus the spec, research, and plan files it names as context; source files the items target are not planning artifacts), which the preparation step commits first ([D15](#d15-minimum-workspace-preparation)); unrelated uncommitted changes still block. The skill also refuses to start on a branch that already carries a prior run's planning-artifacts commit (detectable by that commit's marker), directing the operator to a fresh branch, because the run is single-pass with no resume ([D18](#d18-uncommitted-single-pass-work-state)) and re-running on the existing branch would rebuild already-committed items.
- **Rationale:** Per-item commits must not fold in unrelated uncommitted work, and the skill cannot tell newly introduced breakage from pre-existing breakage if the suite is already red. Both are cheap to check up front and prevent corrupt commits and false failures. Because this core is single-pass with no resume ([D18](#d18-uncommitted-single-pass-work-state)), the reference plan's resume-time exception for an interrupted item's partial work does not apply.
- **Evidence:** Operator feedback (manual `git status` after every item; verify-before-trust depends on a known-green baseline); reference plan D15; D8 (one clean commit per item).
- **Rejected alternatives:**
  - Auto-stash a dirty tree and proceed, rejected because it silently hides the operator's in-flight work and risks losing or mixing it.
  - Start on a red suite, rejected because new breakage becomes indistinguishable from pre-existing breakage.
  - Reuse a branch that already carries a prior run's commits as "suitable", rejected because the single-pass model would rebuild already-committed items and create duplicate commits; the skill refuses and directs to a fresh branch instead.
- **Linked technical notes:** (none)
- **Driven by findings:** a start-time refusal on a branch already carrying a prior run's planning-artifacts commit, and the planning-artifact identification criterion, added in R1 (team-findings.md F9, F10)
- **Dependent decisions:** D15
- **Referenced in spec:** Actors and Triggers (Preconditions); Edge Cases and Failure Modes

### D15: Minimum workspace preparation

- **Question:** What does the skill set up before the per-item loop begins?
- **Decision:** The skill does a minimal preparation and orders it so the **read-only checks and the operator's plan confirmation precede any repository mutation**, so a refusal or a declined plan leaves the repo untouched. First, read-only: it checks the required tooling is available (any one missing required command is "tooling unavailable" and stops), confirms the working tree is clean apart from the run's own planning artifacts (the work-items file the operator passed plus the spec, research, and plan files it names as context; source files the items target do not qualify), shown at the plan preview so the operator sees the exact set that will be committed first, confirms the suite is green where verification commands exist, and validates the items ([D13](#d13-input-validation-preconditions)). Then, only after the operator confirms the plan ([D17](#d17-plan-preview-and-confirmation-before-the-run)), it mutates the repository: it creates the **dedicated branch** (named by the operator, the project's convention, or a feature-derived default, unless already on a suitable one), commits the planning artifacts as the first commit, and initializes the uncommitted work-state file ([D18](#d18-uncommitted-single-pass-work-state)). A preparation failure (the branch cannot be created, a required command will not run, or the planning-artifact commit is rejected) is reported and stops the run; because the mutations come last, a failure or a declined plan leaves no stray branch or commits. Full workspace isolation (worktrees, dependency install, service bringup) is not built into this skill and is deferred to a separate reusable workspace-preparation skill (reference plan D22).
- **Rationale:** The run needs a branch to commit onto and working tooling to verify against, and it should not refuse over the planning documents the operator just produced. The core drops the reference plan's committed-ledger initialization and run-active marker: the work-state file is uncommitted ([D18](#d18-uncommitted-single-pass-work-state)) and the re-grounding marker belongs to the deferred compaction-recovery feature.
- **Evidence:** Reference plan D22 (minimum preparation, ordering, dedicated branch, tooling distinction); operator direction (branch, tooling check, and spec commit as the minimum; full worktree resolution deferred to a separate skill); D9/D8 (per-item commits need a branch).
- **Rejected alternatives:**
  - Build the full setup phase (worktree, dependency install, service bringup) into this skill, rejected because it couples a reusable isolation concern into the driver (reference plan D22, deferred).
  - Do no preparation and run in the existing checkout as-is, rejected because the run needs a branch and working tooling and must not block on the operator's uncommitted planning artifacts.
  - Initialize a committed ledger and a run-active marker during preparation, rejected for the core because the work-state file is uncommitted and compaction recovery is deferred.
- **Linked technical notes:** (none)
- **Driven by findings:** the planning-artifact set given an identification criterion and shown at the plan preview in R1 (team-findings.md F10)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; Actors and Triggers (Preconditions); Edge Cases and Failure Modes

### D16: Per-item implementation skill

- **Question:** Does every item build with `tdd`, or can a work item name a different implementation skill?
- **Decision:** The core builds every item with `tdd`, the sole non-interactive code-producing build skill. The per-item `implementation-skill` field is DEFERRED (see the spec's Deferred (YAGNI) section). A build that produces no file changes halts the run ([D6](#d6-halt-the-whole-run-on-any-unresolvable-item)) rather than being committed. A disposable sub-agent runs once and cannot conduct an interview, so an interactive skill genuinely cannot be driven unattended; `HITL`-typed items are refused at startup via the `Type` marker ([D13](#d13-input-validation-preconditions)), and the interactive-skill-as-foreground-HITL path the reference plan supports is deferred. Revised during W-1 implementation (operator direction): the field was deferred because `tdd` is the only valid value in the core.
- **Rationale:** A disposable sub-agent runs once and cannot conduct an interview, so an interactive skill genuinely cannot be driven unattended; in this core `HITL`-typed items are refused at startup via the `Type` marker rather than run in the foreground (that path is deferred). The per-item `implementation-skill` field is not shipped because `tdd` is the only non-interactive code-producing build skill in the core; a field with exactly one valid value is a premature schema hook.
- **Evidence:** `tdd` runs autonomously with no gate (`han-coding/skills/tdd/SKILL.md`); `skill-builder` and `agent-builder` are interview-driven (`han-plugin-builder/skills/`); reference plan D21 (per-item skill and the interactive-item deferral); W-1 implementation, operator direction to defer the `implementation-skill` field.
- **Rejected alternatives:**
  - Keep the driver `tdd`-only: adopted for the core (the `implementation-skill` field is deferred); per-item skill selection reopens when a second non-interactive code-producing skill exists.
  - Run interactive skills in the foreground as HITL items, rejected for the core because the HITL path is deferred; `HITL`-typed items are refused at startup instead (reference plan D21).
- **Linked technical notes:** (none)
- **Driven by findings:** the valid-skill recognition criterion named, with the recognition mechanism left to `plan-implementation`, in R1 (team-findings.md F7)
- **Dependent decisions:** (none)
- **Referenced in spec:** Actors and Triggers (Preconditions); Primary Flow; Edge Cases and Failure Modes; Coordinations

### D17: Plan preview and confirmation before the run

- **Question:** Does the run start immediately after preconditions, or does the operator see and confirm the plan first?
- **Decision:** After preparation's read-only checks and validation, the skill shows the operator the run plan (the effective run configuration — the gate threshold, the fix-loop cap, the build/fix model, the branch, the verification configuration (the resolved verification commands, or scope-check-only mode where the project defines none), and the planning-artifact set that will be committed first — followed by the items in dependency order, each named with its build skill (`tdd`)) and waits for the operator to **confirm** or **decline** (which stops the run before any repository mutation, [D15](#d15-minimum-workspace-preparation)) before the first item is dispatched. Folding the verification configuration into this preview keeps it the single confirmation touchpoint, with no separate scope-check-only prompt; a decline is acknowledged with a confirmation that nothing was mutated. This is the one-time confirmation and the only planned operator touchpoint after invocation; there is no mid-run re-prompt because the run is single-pass and unattended. Item reorder at the preview is deferred; an operator who wants a different order edits the work-items file and re-invokes.
- **Rationale:** The run is unattended and can be long; without a preview the operator cannot see the run's shape or its configuration before committing to it. A one-time confirmation at the start surfaces that shape (including the verification gate and the planning-artifact set) and gives the operator a place to decline, without breaking the autonomous-after-start model. The reference plan's per-item skip affordance and resume summary are tied to the deferred skip/defer and resume surfaces, and item reorder was descoped as a YAGNI candidate (the simpler confirm-or-decline preview satisfies the "see and confirm the run's shape" evidence, and a single-pass operator can reorder by editing the file), so the core keeps confirm / decline only.
- **Evidence:** Reference plan D25 (plan preview, the decline option, the dependency-preserving reorder, and surfacing the effective configuration); user-experience-designer finding behind it (no plan preview before the run).
- **Rejected alternatives:**
  - Start immediately with no preview, rejected because the operator cannot see the run's shape or configuration before it mutates the repository.
  - Show a preview but auto-proceed without confirmation, rejected by the operator in the reference plan in favor of an explicit confirmation.
  - Keep item reorder at the preview, rejected as a YAGNI candidate for the core (it needs an input protocol, a dependency display, and constraint feedback); deferred, with the edit-the-file-and-re-invoke path covering the need on a single-pass run.
  - Confirm the scope-check-only run as a separate prompt, rejected because it contradicts the single-touchpoint model; the verification configuration is folded into the plan preview instead.
- **Linked technical notes:** (none)
- **Driven by findings:** verification configuration folded into the plan preview (resolving the single-touchpoint contradiction), item reorder deferred as a YAGNI candidate, and the decline response specified in R1 (team-findings.md F13, F14, F21)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; User Interactions; Alternate Flows and States; Edge Cases and Failure Modes

### D18: Uncommitted, single-pass work-state

- **Question:** How does the skill track run progress and configuration, and does a re-invocation resume a partially-done run?
- **Decision:** The skill maintains a single **uncommitted work-state file** recording the run configuration (gate threshold, fix-loop cap, model, branch) and each item's status (in progress, done with its code-commit reference and review-record location). The file is **assumed always up to date** and is **not committed**; the skill's own writes to it are excluded from the per-item changed-file and scope checks ([D7](#d7-independent-verification-and-scope-check-before-commit)) and kept out of every code commit ([D8](#d8-one-commit-per-completed-item)). The durable review record ([D9](#d9-self-contained-full-coverage-review-with-a-condensed-verdict-gate)) is likewise an uncommitted driver artifact — excluded from the scope check, kept out of every code commit, readable by dispatched sub-agents during the run, and retained after a halt for the operator. The run is **single-pass**: re-invoking the skill starts a fresh run rather than resuming. Cross-session resume, committed-ledger integrity, item-to-commit reconciliation, and skip/defer persistence are all deferred.
- **Rationale:** The operator's stated assumptions — no compaction, no interruption, no cancellation — mean a run completes in one session, so the elaborate committed-ledger-with-reconciliation model the reference plan needs for resume and compaction survival is unnecessary here. A plain uncommitted work-state file that the skill trusts is the simplest thing that keeps the loop's own bookkeeping and drives the completion summary, and it establishes the seam a later resume feature will build on. Keeping it out of commits keeps the commit history to just the planning-artifacts commit plus one clean code commit per item ([D8](#d8-one-commit-per-completed-item)).
- **Evidence:** Operator direction in this planning session (ledger and work state stay out of commits, assumed always up to date; single-pass, no resume); reference plan D20 and D24 (the committed-ledger and skip/defer-persistence model, deferred here); reference plan D26 (compaction recovery, deferred here).
- **Rejected alternatives:**
  - Commit the work-state as marked bookkeeping commits (the reference plan's model), rejected for the core because resume and compaction recovery are deferred, so the integrity machinery those commits secure is not needed.
  - Support naive resume from the uncommitted file, rejected by the operator in favor of a single-pass run; resume is a follow-on feature.
  - Keep no work-state file at all, rejected because the skill still needs an in-session progress record for the completion summary and to establish the seam a later resume feature builds on.
- **Linked technical notes:** (none)
- **Driven by findings:** the durable review record classified as an uncommitted driver artifact alongside the work-state file, both kept out of every code commit, in R1 (team-findings.md F4, F5)
- **Dependent decisions:** (none)
- **Referenced in spec:** Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes; Coordinations

### D19: Companion changes to the work-item producer

- **Question:** Which changes to `plan-work-items` ship with this core, given the driver relies on per-item fields the producer does not record today?
- **Decision:** Two per-item fields are added to the work-item producer (`plan-work-items`, its template, and its file-format reference) and ship with this core: an **`expected-paths` declaration** (which the scope check reads, [D7](#d7-independent-verification-and-scope-check-before-commit)) and a **`Type` AFK/HITL marker** (which the driver reads to refuse any `HITL`-typed item, [D13](#d13-input-validation-preconditions)). The producer already classifies each item as AFK or HITL; persisting that classification as the `Type` field lets the driver enforce the boundary at startup. The producer's Step 5 brief produces both fields, Step 7 breakdown prints them, and its closing recommendation offers this driver as the autonomous next step. The `implementation-skill` field is deferred (Decision B); the driver's return contract is imposed by dispatch instruction, so `tdd` and `code-review` need no companion change ([D10](#d10-driver-defined-dispatch-contract)). These producer changes must ship before or with the driver so the fields exist for it to read. Revised during W-1 implementation (operator direction).
- **Rationale:** The driver's scope check and HITL detection both depend on data that lives on each work item, and a data field cannot be imposed by a dispatch instruction the way the return contract can — it has to be recorded by the producer. Shipping only the two fields the core actually consumes keeps the companion surface minimal. The `Type` marker ships because the producer already classifies items as AFK or HITL, so persisting that classification costs nothing while enabling the startup refusal; the `implementation-skill` field is not shipped because `tdd` is the only valid value in the core.
- **Evidence:** `plan-work-items` classifies AFK/HITL in Step 5 and prints it in Step 7 but the `work-item-template.md` has no `Type`, `expected-paths`, or `implementation-skill` field (`han-planning/skills/plan-work-items/`); reference plan D6, D8, D21, D23 (the producer companion changes) and its implementation discovery notes (the exact producer files to edit); W-1 implementation, operator direction to ship `expected-paths` + `Type` (not `implementation-skill`).
- **Rejected alternatives:**
  - Also ship the `implementation-skill` field, rejected because `tdd` is the only valid value in the core, making it a premature schema hook (Decision B); the field is deferred.
  - Add compact structured-output modes to `tdd` and `code-review`, rejected in favor of imposing the return contract by dispatch instruction ([D10](#d10-driver-defined-dispatch-contract)); deferred.
  - Have the driver infer expected paths or the `Type` at run time instead of recording them on the item, rejected because a fresh guess is unreliable and the producer already has the context to record them.
- **Linked technical notes:** (none)
- **Driven by findings:** (none)
- **Dependent decisions:** D7, D16
- **Referenced in spec:** Actors and Triggers (Preconditions); Coordinations
