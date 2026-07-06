# Investigation: Spike-item AFK/HITL handling and AFK→HITL escalation feasibility

Investigation report. Read the Summary, then the Feasibility Assessment; the Evidence Summary and Validation Results back every claim.

## Summary

- **Question answered:** Whether a `spike` work item routed to `research`/`investigate` can be driven unattended (`AFK`), where it must fall back to a human (`HITL`), and how hard an `AFK`→`HITL` mid-run promotion would be on the driver's current escalation mechanism.
- **Answer (AFK) — corrected by validation:** `research` is confirmed AFK-clean on the happy path — zero unconditional human gates for a well-formed, single-thread, correctly-routed question with no pre-existing finding file (E6; V1). `investigate` is the *weaker* AFK route, not the stronger: it writes its finding to disk before its gate, but it *always* reaches an **unconditional** "present the plan file for approval" gate at Step 5 (E8; V2, V3), where a sub-agent's clean return is undefined without a gate→`blocked` mapping. Either way the spike's *review* is always `none, HITL` (E4, E5), so a spike is never unattended end-to-end.
- **Answer (HITL cases):** `research`'s human gates are conditional and mostly producer-avoidable — a vague question, a re-run overwrite, a compound multi-thread question, and a mis-route out of scope (E7). `investigate`'s single gate is **unconditional** and fires on every run (E8; V2). There is no `Type: spike` awareness in either skill to suppress a gate (V2).
- **Answer (promotion effort):** Low-to-**moderate** and localized, *given the branch's assumed resume-after-halt/resume-in-new-context* (E20). The escalation channel already exists and parses fail-closed (E10, E11), so the shape of the fix is right — but validation refuted the "one instruction paragraph" framing: the gate→`blocked` mapping must be **gate-type-aware** (the out-of-scope gate is a categorical "produce no report" conflict, V7), and folding the operator's answer back is a **genuine new recovery-menu interaction**, not a wire-up of existing plumbing, with the answer not persisted across sessions (V5, V6). Net: roughly three bounded artifacts, not one.
- **Validation Outcome:** The `research` half of the AFK claim is fully confirmed; the `investigate` reliability ordering was corrected (it is the weaker AFK route) and the "finding-only run" framing was dropped as unsupported by skill text (V2, V3). The "promotion is cheap" conclusion survives in shape — the channel is real and Option A stays the recommendation — but its effort estimate was raised and three under-counted costs were named (V5, V6, V7, V8). All evidence citations verified accurate on-branch except E17's interpretation, now corrected (V9).
- **Remaining Risks:** Medium confidence; see Confidence Assessment. The load-bearing residuals are the gate-type-aware re-dispatch construction, the un-owned recovery-menu answer-capture interaction, and the categorical out-of-scope override.

## Problem Statement

- **What is being investigated.** `plan-work-items` classifies some work as a `spike` (an investigation that records a finding) and routes its build by the question's shape to `han-coding:investigate`, `han-core:research`, or a `general-purpose` probe (E1, E2). `implement-work-items` drives that item. The open questions:
  1. Can `research`/`investigate` be driven fully unattended (`AFK`) under the happy path?
  2. In which cases do they require a human (`HITL`)?
  3. How hard is it to implement an `AFK`→`HITL` promotion (escalate to a human mid-run, then continue) on the *current* escalation mechanism?
- **Why it matters.** The producer marks a spike's build `AFK` or `HITL` per item (E4), but neither skill *prescribes* which, and the driver dispatches an `AFK` spike into a sub-agent that runs an interactive skill with no human attached. If a gate fires, today's behavior is undefined and can halt the whole run messily. Knowing exactly where the gates are, and how cheaply an escalate-and-resume path closes them, decides whether the "AFK-with-escalation" enhancement that decision **D19** deferred is worth doing on this branch.
- **Stated assumptions (from the requester, treated as given).** Resume-after-halt/compaction and resume-in-new-context will be implemented before this branch merges. The analysis below is conditioned on those two capabilities landing.
- **Scope.** This is a design/feasibility investigation of the Han skills themselves, not a runtime bug. "Findings" are skill-text citations, not stack traces.

## Root Cause Analysis

### Root Cause

There is no defect to fix; the finding is that **`AFK`→`HITL` promotion for spikes is a small, well-bounded addition, not a rebuild** — the escalation channel and fail-closed parse already exist (E10, E11), the only structural gap is that the spike build-dispatch never tells the sub-agent to convert an interactive gate into a `STATUS: blocked` escalation (E9), and the only load-bearing dependency (turning a halt into a resumable escalation) is exactly the resume capability the requester says is already being built (E12, E14).

### Detailed Analysis

**1. `research` produces a finding cleanly `AFK`; `investigate` produces the finding to disk but always reaches an unconditional gate (corrected by validation).**
`research`'s Step 4 says "proceed without a blocking confirmation" and Step 8 presents the report without an approval gate (E6); a specific, single-thread, first-run, correctly-routed research question runs start-to-finish with zero unconditional gates (V1). `investigate` writes its root cause and planned fix in Steps 2–3 and its Summary at the top of Step 5 (line 76), so the finding *file* lands complete before the approval gate at line 78 — but the sub-agent still *reaches* that gate, which is **unconditional**: nothing in the skill has `Type: spike` awareness to suppress it, and the driver's spike dispatch adds no instruction to neutralize it (E8; V2). Its wording, "present the plan file **for approval** (triggering implementation)," reads as a blocking hand-off, not a bare presentation (V3). So validation reversed my first framing: `research` is the *more* reliable AFK route (no gate to reach), and `investigate` is the *weaker* one (always reaches a gate, undefined return there). D19 (E14) is right that the finding lands on disk regardless, but it slightly over-reads that as a clean AFK *return* for `investigate` — the file is written, the clean return is not guaranteed without the gate→`blocked` mapping.

**2. The HITL cases are enumerable; `research`'s are conditional, `investigate`'s is unconditional.**
`research`'s four gates (E7): a too-vague question (Step 1), a re-run overwrite of an existing finding file (Step 1), a compound multi-thread question (Step 2), and a request that belongs to a sibling skill — an out-of-scope redirect that "produce[s] no research report" (Step 2). The first, third, and fourth are avoided by the producer writing a specific, single-thread, correctly-routed question — which is precisely why D19 makes the `AFK`/`HITL` call the *producer's* judgment (E4, E14). Only the overwrite gate is not fully producer-controlled, and it fires only on a re-run over an existing finding file. `investigate` adds one **unconditional** gate at Step 5 that fires on every run regardless of the question's quality (E8; V2) — so an AFK `investigate` spike depends on the gate→`blocked` mapping (or the sub-agent's undefined behavior there) even on the happy path. This is why `investigate` spikes benefit from the escalation enhancement *more* than `research` spikes, not less.

**3. When a gate fires today, behavior is undefined and stops the run.**
The driver dispatches an `AFK` spike by having a `general-purpose` agent run the routed skill, passing the item's `Expected paths` as the finding target and copying the build-report contract verbatim (E9). It does **not** add any instruction mapping the routed skill's "ask the user"/"present for approval"/"redirect" points to `STATUS: blocked`. So if a gate fires, the sub-agent has conflicting instructions — its own skill says "ask the user," the contract says "return one of these sections." It may invent an answer (silent wrong finding), or return prose missing the `STATUS` header (which the fail-closed parser treats as untrustworthy and halts on), or happen to emit `STATUS: blocked`. All three paths stop the run; none corrupt committed state (D19's "recoverable halt, not corruption"), but none resume either.

**4. The current escalation mechanism is halt-only, but the channel is already the right shape.**
There are two escalation surfaces: the build sub-agent's `STATUS: blocked` + `ESCALATION` (E10) and the review sub-agent's `ESCALATION` field (E11). Both are explicitly "clean escalations" that the driver surfaces through the Halt Procedure — which today is a *total stop*: "The run does not resume, so a re-invocation starts a fresh run from the first item" (E12). There is no `AFK`→`HITL` transition anywhere in the driver: a repo-wide search for *promote / demote / switch to HITL / downgrade* returns nothing, and the foreground-handoff protocol only serves items already marked `HITL`/`none`, with no path in from an `AFK` item (E12, E13).

**5. The promotion tracks the two pieces D19 named — but validation split piece (a) into gate-type-aware authoring plus a recovery-menu interaction.**
D19's "AFK-with-escalation enhancement" is (a) "a build-dispatch instruction that maps a routed skill's operator-gates to a `blocked` escalation" and (b) "escalate-and-resume so the driver hands off at the escalation and continues rather than halting" (E14). Piece (b) is the requester's stated assumption (resume-after-halt, E20). Piece (a) is the genuinely new authoring, and validation showed it is not a single paragraph: the gate→`blocked` mapping is gate-type-aware (the out-of-scope gate is a categorical "produce no report" conflict, V7), and re-injecting the operator's answer on resume is a new recovery-menu interaction, not a wire-up of existing plumbing (V5, V6). The effort stays low-to-moderate and localized because the channel (E10), the fail-closed parse (E10), and the human-facing halt frame (E12) are all already built and already carry the `ESCALATION` payload a human needs to act — but "one paragraph" undersold it. See the Planned Fix for the ~three-artifact breakdown.

## Planned Fix

This is a feasibility investigation, so "the fix" is the smallest change set that turns today's halt-on-gate behavior into an `AFK`-that-escalates-on-need path, plus an effort read on each piece. It presumes resume-after-halt/resume-in-new-context (the requester's given). Nothing here should be built without an owning plan; this section scopes it.

### Approach

Convert a routed spike skill's interactive gates into an escalation, and wire the resumed build to re-dispatch the routed skill with the operator's answer folded in — reusing the existing `ESCALATION` channel rather than adding a new driver state. The shape is right and the channel already exists (E10), but validation showed this is roughly **three** bounded artifacts, not one paragraph: (a) a *gate-type-aware* dispatch instruction (the out-of-scope gate is a categorical "produce no report" conflict that needs its own named exception, V7; the overwrite gate needs suppression rather than answer-injection on re-dispatch, V5); (b) a small broadening of the build-report `ESCALATION` guidance (E10); and (c) a genuinely new recovery-menu interaction that captures the operator's answer and injects it into the re-dispatch — the resume spec's "build further toward the item" path is built for code edits and does not carry a question-answer today (V6). Still localized and authoring-level; just not trivial.

There are two viable signalling shapes for the escalation; both are cheap, and the choice is a vocabulary-vs-flow trade:

- **Option A — reuse `STATUS: blocked` + resume (recommended).** The gate maps to the existing `blocked` value with the question in `ESCALATION`; the (assumed) resume-after-halt path turns the halt into a resumable escalation and re-dispatches the routed skill with the operator's answer folded in. No new `STATUS` vocabulary, no new driver state; it composes directly with the resume work already planned. "Resume" is re-dispatch-with-answer, not mid-step continuation.
- **Option B — a distinct `needs-human` signal that promotes in-session.** Add a third build-report signal meaning "cannot complete unattended, switch me to foreground" that routes the *current* item into the foreground-handoff protocol without halting the run. Validation corrected E17's insertion points: the real ones are (1) a new `STATUS` value in the build-report contract, (2) a `promote` state in `state.json`, (3) **a new branch in the Step 3.3 *Build* parse** — not the Gate's "Needs a human decision" path, which fires on the *review verdict*, not a build status (V8) — plus (4) an extension of the foreground-handoff protocol, which today assumes the sub-agent was never dispatched (E13, V8). So Option B is ~4 touch points, not 3. This is the more literal `AFK`→`HITL` promotion and needs no cross-context resume when the operator is present, but it adds vocabulary and a new mid-loop transition the driver does not have today (E12, E13).

Recommend **Option A**: it reuses the exact channel that already parses (E10) and rides the resume machinery the requester says is landing, avoiding Option B's new build-parse branch and foreground-handoff extension (V8). Its marginal cost is the gate-type-aware dispatch instruction plus the recovery-menu answer-capture — bounded, but not a single paragraph. Option B is preferable only if runs are expected to be attended and restarting context is unwanted.

### Changes

#### `han-coding/skills/implement-work-items/SKILL.md` (spike branch of the `AFK` build dispatch, ~lines 207–218)

- **Change:** Add an instruction, on the `spike` path only, telling the sub-agent that it is running an interactive skill unattended: if the routed skill reaches a point where it would ask the user, present for approval, request clarification, or redirect out of scope, it must **not** attempt to; it returns `STATUS: blocked` with the exact question/decision (and, for a compound question, the thread list; for a redirect, the named sibling) in `ESCALATION`. Name the concrete gates so the mapping is deterministic: `research` Steps 1–2 (vague, overwrite, compound, out-of-scope) and `investigate`'s unconditional Step 5 approval gate (map "present for approval" to a clean return of the already-written finding, since a spike wants no fix).
- **Evidence:** (E9) is the exact gap — the dispatch copies the contract but never maps the gates. (E7) enumerates the gates to name. (E6, E8) confirm the happy path needs no such handling. (E14) is the design mandate.
- **Standards:** Producer↔driver marker vocabulary must stay reconciled (the shared-contract convention in the spec's Coordinations); writing-voice (no em-dashes, second person).
- **Details:** No new parse, because `STATUS: blocked` + `ESCALATION` already parse (E10) — but the instruction is **gate-type-aware**, not a generic "don't ask the user" catch-all (V5, V7). Three of `research`'s gates (vague, compound, overwrite) and `investigate`'s Step 5 are interactive-prompt overrides ("instead of asking, emit `STATUS: blocked` with the question in `ESCALATION`"). The fourth, `research`'s out-of-scope redirect, is a **categorical conflict**: the skill says "stop. Produce no research report," which directly contradicts "return this report format," so it needs its own named exception ("name the sibling in `ESCALATION` and emit `STATUS: blocked`") or a mis-routed spike silently produces a wrong finding (V7). The routed skill's own "ask/present" text competes with the wrapper inside the sub-agent, so the wrapper must be authoritative and enumerate each gate (Remaining Risks R1, R3).

#### `han-coding/skills/implement-work-items/references/build-report-contract.md` (ESCALATION section, lines 51–57 and 77–81)

- **Change:** Broaden the `ESCALATION` guidance so "needs a human decision" explicitly includes "the routed skill reached an operator gate (a clarification, a thread choice, an overwrite confirmation, or a scope redirect) that cannot be answered unattended." Optionally tag such an escalation as *resumable* (the run can continue once the operator answers) versus *terminal* (the item must be redesigned), so the resume path knows whether to re-dispatch or stop.
- **Evidence:** (E10) is the section being broadened; (E7) supplies the gate vocabulary; (E12) is the halt frame that will consume the tag.
- **Standards:** Same shared-contract reconciliation; keep the fixed `STATUS` vocabulary (`built`/`blocked`) unchanged so older parses still hold.
- **Details:** If the resumable/terminal tag is added, it rides inside `ESCALATION` prose (no new section) to avoid breaking the five-section parse.

#### Recovery-menu answer capture + gate-type-aware re-dispatch (a genuine third artifact — flagged, not owned here)

- **Change:** When a resumable spike escalation is answered by the operator, resume by **re-dispatching the routed skill for that item with the operator's answer folded in** (not by resuming the terminated sub-agent mid-step). Validation showed this is not a wire-up of the resume spec's existing "build further toward the item" path — that path carries a changed item and residual review findings, not a question-answer (V6). It needs a new recovery-menu interaction: surface the `research` question from `ESCALATION`, capture the operator's free-text answer, and inject it **gate-type-aware** — inject clarified question text for the vague gate (self-clears), inject the chosen thread for the compound gate, but **suppress** the overwrite gate (the file still exists, so a naive re-dispatch re-fires it — V5).
- **Evidence:** (E12) today's halt says "does not resume"; the assumption (E20) replaces that. (E13) confirms no existing in-from-AFK path to reuse. (V5) the overwrite gate needs suppression, not answer-injection. (V6) the resume spec's re-attempt is built for code edits and does not persist the answer, so a cross-session resume re-asks the operator.
- **Standards:** Re-grounding discipline already in the foreground-handoff/resume protocols; the producer↔driver reconciliation convention.
- **Details:** "Resume" is re-dispatch-with-answer, not mid-step continuation (R2). The operator's answer is not durably recorded (consistent with how pre-work decisions are treated), so "escalate-and-resume" degrades to "escalate-and-re-ask" across sessions — a UX caveat worth stating to the owner (R5). Do not repurpose the `decision` state.json field, which is scoped to pre-work decisions and would conflate the two (V6).

### What this does *not* change (and why the spike stays partly HITL)

The spike's **review** is always `none, HITL` — a human soundness read, by producer convention (E4) and reinforced by the driver refusing an `AFK` review on `audit`/no-output items (E5). Making the *build* escalate-and-resume does not make a spike unattended end-to-end; it only removes the mid-build halts. That is by design (a finding's soundness wants a human), and the report should say so plainly so the requester does not expect a fully-`AFK` spike.

## Evidence Summary

### E1: A spike is defined and detected by the `Type` marker

- **Source:** `han-planning/skills/plan-work-items/references/work-item-template.md:8`
- **Finding:**
  ```
  **Type.** `deliverable` (default; builds and commits an artifact), `audit` (a
  checks-only pass), or `spike` (an investigation that records a finding). Required.
  ```
- **Relevance:** The `Type` field is the classifier; a spike is distinguished by outcome (records a finding). There is no content heuristic — the producer decides.

### E2: A spike's build routes by the shape of the question

- **Source:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:52-54`
- **Finding:**
  ```
  A `spike` records a finding. Route its build by the question: `han-coding:investigate`
  for a named symptom with a codebase root cause, `han-core:research` for an open-ended
  question (the default), a `general-purpose` agent for a quick single-read probe.
  ```
- **Relevance:** Confirms the three routes and the `research` default; matches decision D17.

### E3: `AFK`/`HITL` is a suffix on two fields, not a standalone marker

- **Source:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:7`; `han-planning/skills/plan-work-items/references/work-item-template.md:6-47`
- **Finding:**
  ```
  ... classify part as `AFK` (can be completed without human input) or `HITL`
  (requires human participation). This will inform whether the part can run in a
  background sub-agent.
  ```
- **Relevance:** The only two values; carried inside `Suggested implementation` and `Suggested review`, never a separate field.

### E4: A spike's build `AFK`/`HITL` is producer-judged; its review is always `none, HITL`

- **Source:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:29,54`
- **Finding:**
  ```
  | A spike (an investigation that records a finding) | route by question (see "Spikes") | none, HITL |
  ...
  Its review is a human soundness read (recorded, non-empty, answers the question),
  independent of the build's `AFK`/`HITL`.
  ```
- **Relevance:** The build carries a per-item `AFK`/`HITL` the catalog leaves unspecified; the review is fixed `none, HITL`. This is why a spike is never fully unattended.

### E5: The driver treats an item as unattended only when *both* parts are `AFK`

- **Source:** `han-planning/skills/plan-work-items/SKILL.md:121`
- **Finding:**
  ```
  ... a count of how many items run unattended (both `Suggested implementation` and
  `Suggested review` are `AFK`, with no required pre-work decision) versus how many
  pause for a human ...
  ```
- **Relevance:** Because a spike's review is always `HITL`, a spike always pauses at review regardless of its build marker.

### E6: `research` runs `AFK` on the happy path — no blocking confirmation, non-blocking presentation

- **Source:** `han-core/skills/research/SKILL.md:89,128`
- **Finding:**
  ```
  Proceed without a blocking confirmation; research is read-only and re-runnable. ...
  ... The user can accept the report, ask for specific revisions, or redirect the question.
  ```
- **Relevance:** Step 4 waives the roster confirmation; Step 8 presents without a blocking approval. A clean, single-thread question runs start-to-finish unattended.

### E7: `research`'s conditional HITL gates (all producer-avoidable except overwrite)

- **Source:** `han-core/skills/research/SKILL.md:36,42,48,50`
- **Finding:**
  ```
  (l.36) If the user supplied an output path and a report already exists there, ask
         whether to overwrite it or write elsewhere before doing any work.
  (l.42) If the question is too vague to research ... ask the user for the specific
         decision or unknown they need resolved before dispatching anything.
  (l.48) If the request is a bug to diagnose, a feature to specify, ... name the
         correct sibling skill ... and stop.
  (l.50) If the question bundles more than one independent research thread ... ask
         the user which to run first, and defer the rest.
  ```
- **Relevance:** The complete list of mid-build human gates. Vague / compound / out-of-scope are avoided by a well-formed, single-thread, correctly-routed question (producer-controlled); overwrite fires only on a re-run.

### E8: `investigate` writes its finding `AFK`; its only gate is an unrelated fix approval

- **Source:** `han-coding/skills/investigate/SKILL.md:78` (and Steps 1–4, lines 31–73)
- **Finding:**
  ```
  Present the plan file to the user for approval. The user can approve the plan
  (triggering implementation) or provide feedback for revisions.
  ```
- **Relevance:** Steps 1–4 (investigate, document root cause, plan fix, validate) have no human gate; the finding is written before Step 5, whose approval triggers a *fix* a spike does not want. So a finding-only run has no mid-build HITL gate.

### E9: The spike `AFK` dispatch copies the contract but never maps operator-gates to `blocked`

- **Source:** `han-coding/skills/implement-work-items/SKILL.md:207-218`
- **Finding:**
  ```
  - **AFK build.** Dispatch a build sub-agent through `Agent` ... when the item's
    implementation is a skill, dispatch `general-purpose` and instruct it to run
    that skill on this item ... For a `spike` ... give it the item's `Expected paths`
    as the output target: a `spike` writes its finding there ... Copy the
    [build-report contract] verbatim; parse the return fail-closed and apply the
    Halt Procedure on its halt conditions.
  ```
- **Relevance:** This is the structural gap. Nothing tells the sub-agent to convert the routed skill's "ask the user" points into `STATUS: blocked`; on a gate, behavior is undefined and stops the run.

### E10: Escalation channel #1 — build `STATUS: blocked` + `ESCALATION`, parsed fail-closed

- **Source:** `han-coding/skills/implement-work-items/references/build-report-contract.md:22-57,77-81`
- **Finding:**
  ```
  STATUS: <"built" = ... "blocked" = the item cannot be completed and you are
  escalating it in ESCALATION. No other value is valid.>
  ...
  A STATUS of `blocked` is a clean escalation, not a malformed report: the driver
  halts and surfaces the ESCALATION content as the halt's supporting evidence.
  ```
- **Relevance:** The escalation payload channel already exists and is already the target format a gate→blocked mapping would emit into.

### E11: Escalation channel #2 — review-verdict `ESCALATION` halts immediately

- **Source:** `han-coding/skills/implement-work-items/references/review-verdict-contract.md:57-62,117-119`
- **Finding:**
  ```
  A non-`none` ESCALATION is a clean escalation, not an untrustworthy verdict: the
  driver halts for the human decision it names rather than opening a fix round ...
  ```
- **Relevance:** The review side has the same escalation shape; a spike's `none, HITL` review already routes through the human capture path, so the review side needs no new escalation plumbing.

### E12: Today escalation → total-stop Halt Procedure; no resume, no promotion

- **Source:** `han-coding/skills/implement-work-items/SKILL.md:259-267,306-331`
- **Finding:**
  ```
  5. **What to do next.** The run does not resume, so a re-invocation starts a
     fresh run from the first item. ...
  ```
- **Relevance:** The halt is a hard stop today. A repo-wide search for *promote/demote/switch to HITL/downgrade* found nothing — there is no `AFK`→`HITL` transition to reuse; the requester's resume assumption is what replaces the "does not resume" clause.

### E13: The foreground-handoff path only serves already-`HITL`/`none` items

- **Source:** `han-coding/skills/implement-work-items/references/foreground-handoff-protocol.md:3-5`
- **Finding:**
  ```
  For a `HITL` build (an interactive skill) or a bare `none` build, the driver hands
  control to the user rather than dispatching a sub-agent.
  ```
- **Relevance:** There is no entry into this path from an `AFK` item, confirming the promotion is net-new (and would live in the resume path as a re-dispatch, not a hand-in to this protocol mid-sub-agent).

### E14: Design intent already names both promotion pieces and defers them (D19 / spec Out of Scope)

- **Source:** `docs/plans/work-items-non-code-classification/artifacts/decision-log.md` (D19); `docs/plans/work-items-non-code-classification/feature-specification.md:104`
- **Finding:**
  ```
  A build-dispatch instruction that maps a routed skill's operator-gates to a
  `blocked` escalation ... together with escalate-and-resume, upgrades those
  edge-case gates into clean mid-run escalations ...; neither is required for AFK
  to work on the common case today.
  ```
- **Relevance:** The branch already scoped exactly the two pieces this report costs; piece (b) is the requester's assumption, leaving piece (a) as the marginal work.

### E15: Terminology note — design `verification` shipped as `audit`

- **Source:** `han-coding/skills/implement-work-items/SKILL.md:123-128`; `han-planning/skills/plan-work-items/references/work-item-template.md:8`
- **Finding:**
  ```
  ... a present value outside `deliverable`, `audit`, `spike` is a refusal.
  ```
- **Relevance:** The decision log (D6) discusses a `verification` type; on disk the third type is `audit`. Same concept, renamed — noted so cross-references between the plan docs and the shipped skills read consistently.

### E16: A spike with an `AFK` review is not refused by the driver (latent contract gap)

- **Source:** `han-coding/skills/implement-work-items/SKILL.md:123-128`
- **Finding:**
  ```
  ... an `AFK` review on an `audit` item or any item declaring `Expected paths: None`
  is a refusal ...
  ```
- **Relevance:** The driver enforces `HITL` review only for `audit`/no-output items. A `spike` has `Expected paths` set and `Type: spike`, so a hand-edited or mis-emitted `AFK` review on a spike passes validation and would dispatch an unattended review — the "spike review always HITL" invariant is a producer convention, not a driver guard. Orthogonal to the escalation question but worth flagging.

### E17: Least-disruptive insertion points for a promotion channel

- **Source:** `han-coding/skills/implement-work-items/references/build-report-contract.md:22-23`; `han-coding/skills/implement-work-items/SKILL.md:261-264` (Gate "Needs a human decision")
- **Finding:**
  ```
  STATUS: <"built" = the item was implemented. "blocked" = the item cannot be
  completed and you are escalating it in ESCALATION. No other value is valid.>
  ```
- **Relevance:** If Option B is chosen, the insertion points are (1) a third `STATUS` value (e.g. `needs-human`) in the build-report contract; (2) a `promote` state alongside `build`/`verify` in `state.json`; (3) **a new branch in the Step 3.3 *Build* parse** that routes to foreground handoff. Validation corrected an earlier version of this item (V8): the Gate's "Needs a human decision" branch (`SKILL.md:261-264`) fires on the *review verdict*, not a build status, so it is **not** the right insertion point for a build-side promotion; and the foreground-handoff protocol (E13) assumes the sub-agent was never dispatched, so it needs extending for a post-dispatch hand-off — making Option B ~4 touch points. Option A needs none of these — it reuses `blocked`.

### E18: Producer marks `Type` Required, but the driver defaults it silently (validation asymmetry)

- **Source:** `han-planning/skills/plan-work-items/references/work-item-template.md:8`; `han-coding/skills/implement-work-items/SKILL.md:113-116,123-124`
- **Finding:**
  ```
  (producer) **Type.** `deliverable` ... or `spike` ... Required.
  (driver "Fields present" check lists only) `**Requires pre-work decisions.**`,
  `**Suggested implementation.**`, and `**Suggested review.**`
  (driver Type guard) Read each item's `Type` (absent means `deliverable`, so older
  files drive unchanged) ...
  ```
- **Relevance:** `Type` is not in the driver's presence check; a hand-edited item missing `Type` silently runs as `deliverable`, and a spike/audit intended item can misfail (or misrun) with a message pointing at re-running `plan-work-items` rather than fixing the field. Orthogonal to the escalation question, but a real producer↔driver contract gap surfaced while tracing the boundary.

### E19: The spike build token is the only unspecified routing token in the catalog

- **Source:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:28-29,52-55`
- **Finding:**
  ```
  | An audit pass (checks, no new deliverable) | named checks, AFK if automatable else HITL | none, HITL |
  | A spike (an investigation that records a finding) | route by question (see "Spikes") | none, HITL |
  ```
- **Relevance:** Every other catalog row prescribes an `AFK`/`HITL` token on the build; the spike row prescribes only the *route* and leaves the token to the project-manager's judgment ("independent of the build's `AFK`/`HITL`"). So the "runs unattended" intent for a spike build is implicit in whatever token the producer chose — two runs on the same plan could differ and both be driver-valid. This is what makes the producer-judged `AFK` of D19 a convention rather than a contract, and is exactly the token the escalation enhancement would let the producer set `AFK` more confidently.

### E20: The resume assumption is a real scoped follow-on, and this surface is explicitly deferred

- **Source:** `docs/plans/autonomous-driver-core-loop/feature-specification.md:103,127-130`; `docs/plans/implement-work-items-resume/` (plan folder exists)
- **Finding:**
  ```
  (l.103) The human-in-the-loop item path, interactive-skill items, the clean-stop
  affordance, resume across sessions, compaction recovery and re-grounding, ...
  and the operator-interactive blocker menu (triage, accept-a-flagged-change, gate
  override, repair-upstream, defer, skip) are all deferred to follow-on features ...
  (l.127) ### Resume across sessions and committed-ledger integrity
  (l.130) Reopen when: the follow-on feature that adds cross-session resume is planned ...
  ```
- **Relevance:** Confirms the requester's "resume will land before merge" is a planned follow-on (there is already an `implement-work-items-resume` plan folder), so conditioning the effort estimate on it is grounded, not hypothetical. It also confirms that interactive-skill items and the blocker menu — the exact surface an `AFK`→`HITL` promotion belongs to — are a deliberately deferred follow-on, consistent with D19 (E14). The open question the validator probes is whether that resume design preserves a *mid-build* item position (so a resumed run re-dispatches the escalated spike rather than restarting from item 1).

## Validation Results

Two adversarial validators ran in parallel: one attacking the "happy-path AFK" claim (V1–V4), one attacking the "promotion is cheap" claim (V5–V9). Both rated Medium confidence; the core structure held, but the AFK reliability ordering was reversed and the effort estimate was raised.

### Counter-Evidence Investigated

#### V1: `research` has no unconditional gate; its gate enumeration is complete — CONFIRMED

- **Hypothesis:** `research` hides a mandatory human gate the report missed (roster selection, validation wait, or closing).
- **Investigation:** Every interaction hit in `research/SKILL.md` re-checked. Lines 104 and 120 are agent-wave waits, not human gates; line 89 explicitly waives the block; lines 36/42/48/50 are the four conditional gates already in E7; line 126 is a non-blocking completion write.
- **Result:** Confirmed. `research` traverses all eight steps on a well-formed, single-thread, first-run question with zero human gates (also V7 of that validator: the report-writing step is reachable AFK end-to-end).
- **Impact:** E6/E7 stand; `research` is the clean AFK route.

#### V2: `investigate`'s Step 5 approval gate is unconditional; there is no "finding-only run" — REFUTED (my framing)

- **Hypothesis:** `investigate` writes its finding before Step 5, so a finding-only run has no mid-build gate.
- **Investigation:** `investigate/SKILL.md` has no `Type: spike` awareness and no conditional guarding Step 5; the spike dispatch (E9) adds no instruction to skip or neutralize it. "Present the plan file to the user for approval" (line 78) fires on every run.
- **Result:** Refuted. The "finding-only run" is my own inference, not skill text.
- **Impact:** Reframed Detailed Analysis point 1 and the Summary: the finding *file* lands before the gate, but the sub-agent still reaches an unconditional gate where its clean return is undefined.

#### V3: `research` "present" and `investigate` "present for approval" are not equivalent — PARTIALLY REFUTED

- **Hypothesis:** The report treats both closings as non-blocking presentations.
- **Investigation:** `research/SKILL.md:126` "write it to the output location and present it" (no approval); `investigate/SKILL.md:78` "present ... for approval ... (triggering implementation)" (approval-requesting).
- **Result:** Partially refuted. The two are not parallel; `investigate`'s wording reads as a blocking hand-off.
- **Impact:** Corrected the claim that `investigate` is "more reliably AFK"; it is the weaker route.

#### V4: `investigate` is *less* reliably AFK than `research`, not more — REFUTED (my claim)

- **Hypothesis:** `investigate` is more reliably AFK because it has no conditional clarify gate.
- **Investigation:** `research` = zero unconditional gates on the happy path; `investigate` = one unconditional gate (Step 5) on every run.
- **Result:** Refuted. The reliability ordering is reversed.
- **Impact:** Rewrote the routing guidance: `research` is the safe AFK route; `investigate` spikes benefit *more* from the gate→`blocked` mapping precisely because they always hit a gate.

#### V5: Re-dispatch is gate-type-aware, not a uniform "fold the answer in" — PARTIALLY REFUTED

- **Hypothesis:** Re-dispatching the routed skill with the operator's answer is a single clean restart.
- **Investigation:** The vague gate self-clears when the clarified question is folded in (the gate condition changes). The overwrite gate does **not**: the finding file still exists, so a naive re-dispatch re-fires it; clearing it needs an explicit permission/suppression, not an answer. Gates fire before any agents run, so no partial finding is in flight — that half holds.
- **Result:** Partially refuted.
- **Impact:** The dispatch instruction and the re-dispatch must be gate-type-specific; reflected in the Approach and the third Changes entry.

#### V6: Folding the answer back is a new recovery-menu interaction, not a wire-up; the answer is not persisted — PARTIALLY REFUTED

- **Hypothesis:** Piece (b) lands in the resume path's existing plumbing.
- **Investigation:** `implement-work-items-resume/feature-specification.md`'s "build further toward the item" carries a changed item and residual review findings — designed for code edits, not a question-answer. The `decision` state.json field is scoped to pre-work decisions; repurposing it would conflate. Per the resume spec's own treatment of within-session decisions, the answer is not durably recorded, so a cross-session resume re-asks.
- **Result:** Partially refuted.
- **Impact:** Upgraded the resume-path change from "flagged, not owned" wire-up to a named third artifact; added the cross-session "re-ask" caveat (R5).

#### V7: The out-of-scope gate is a categorical instruction conflict, not a reliability nuance — PARTIALLY REFUTED

- **Hypothesis:** The four `research` gates are similar enough that one authoritative wrapper handles them.
- **Investigation:** Gates 1–3 and `investigate` Step 5 are interactive-prompt overrides. Gate 4 (`research/SKILL.md:48`) says "stop. Produce no research report," which directly contradicts the build-report contract's "return this report format." It needs its own named exception, or a mis-routed spike silently produces a wrong finding.
- **Result:** Partially refuted.
- **Impact:** Named the out-of-scope exception explicitly in the dispatch-instruction Details and in R3.

#### V8: Option B's third insertion point is at the wrong loop phase; blast radius is ~4, not 3 — REFUTED (for that point)

- **Hypothesis:** E17's three insertion points (STATUS enum, `promote` state, Gate branch) are all correct and localized.
- **Investigation:** The Gate's "Needs a human decision" branch (`SKILL.md:261-264`) fires on the *review verdict*, not a build status. A build-side `needs-human` must branch in the Step 3.3 Build parse; and the foreground-handoff protocol assumes the sub-agent was never dispatched, so it needs extending for a post-dispatch hand-off.
- **Result:** Refuted for the third insertion point.
- **Impact:** Corrected E17 and Option B (now ~4 touch points), reinforcing the Option A recommendation.

#### V9: All evidence citations accurate and current on-branch — CONFIRMED

- **Hypothesis:** Cited line numbers are stale or misquoted.
- **Investigation:** Every E-series citation verified verbatim against the current files (E6, E7, E8, E9, E10, E12, E13, E14, E17).
- **Result:** Confirmed. The only accuracy issue was E17's *interpretation* (a claim-from-evidence error, not a stale citation), fixed under V8.
- **Impact:** The evidence base is solid; the refutations are analysis-level, not citation-level.

### Adjustments Made

- **Summary + Detailed Analysis (V2, V3, V4):** Reversed the AFK reliability ordering — `research` is the clean AFK route; `investigate` always reaches an unconditional Step 5 gate. Dropped the "finding-only run" framing.
- **Approach + Changes (V5, V6, V7):** Reframed the effort from "one instruction paragraph" to ~three bounded artifacts; made the dispatch instruction gate-type-aware; named the out-of-scope categorical exception; upgraded the resume-path change to a named third artifact with the cross-session re-ask caveat.
- **E17 + Option B (V8):** Corrected the third insertion point to the Build parse branch and added the foreground-handoff extension; Option B is ~4 touch points.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  - **R1 — wrapper reliability.** The gate→`blocked` mapping lives in a dispatch prompt that competes with the routed skill's own "ask/present" instructions inside the sub-agent; a gate the wrapper does not enumerate can slip through (silent wrong finding, or a malformed report that halts messily).
  - **R2 — resume = re-dispatch, not continuation.** The routed skill re-runs from its start with the answer folded in; safe because gates fire early, but not a true mid-step resume.
  - **R3 — out-of-scope categorical conflict.** `research`'s "produce no research report" must be overridden by a named exception, not a generic "don't ask" rule (V7).
  - **R4 — output-path honoring.** `research` writes to a `docs/` default unless "the user supplied an output path"; the dispatch must make the spike's `Expected paths` count as that supplied path, or the finding lands in the wrong place. Not resolvable from skill text alone.
  - **R5 — cross-session answer loss.** The operator's escalation answer is not durably recorded, so a cross-session resume re-asks; "escalate-and-resume" is really "escalate-and-re-ask" across sessions (V6).
  - **R6 — E16 latent gap.** The driver does not refuse an `AFK` review on a `spike` (only on `audit`/no-output items), so the "spike review always HITL" invariant is a producer convention, not a driver guard; higher operator confidence in AFK spike builds slightly raises the chance of an accidental `AFK` review slipping through.

## Coding Standards Reference

| Standard | Source | Applies To |
|----------|--------|------------|
| Producer↔driver marker vocabulary stays reconciled — every value the producer emits, the driver validates and routes the same way | `docs/plans/work-items-non-code-classification/feature-specification.md` (Coordinations) | The spike-dispatch instruction and any `ESCALATION` vocabulary change |
| Writing voice — no em-dashes, direct second person, plainspoken | `docs/writing-voice.md` | All skill-text edits proposed above |
| YAGNI applies to skill text and docs | `CLAUDE.md` (Conventions) | Keep the gate→blocked instruction to the gates that exist; do not pre-build terminal/resumable tagging unless the resume path consumes it |
