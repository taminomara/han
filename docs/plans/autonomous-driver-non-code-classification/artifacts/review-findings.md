# Review Findings: Non-code, meta, and non-deliverable work items

Iterative-plan-review of the recent iteration delta (D11 producer-side validation, D16 reword, D17 spike routing, D18 pre-work-decision boundary). Spec-aware mode. This file's `F#` numbering is local to the iterative-plan-review sessions and is distinct from the plan-a-feature review record in [team-findings.md](team-findings.md). Cross-links: each finding's `Changed in plan:` names the spec sections and decision-log decisions it changed; `Raised in round:` names the `R#` in [review-iteration-history.md](review-iteration-history.md).

## Major findings

### F1: Spike builds routed to `investigate`/`research` cannot be dispatched AFK

- **Agent:** junior-developer (M1), adversarial-validator (V1, V2, V5)
- **Category:** missing coordination / unhandled failure mode
- **Finding:** D17 routed a spike's build to `han-coding:investigate` or `han-core:research` but never set the spike's `AFK`/`HITL` autonomy. Both skills are interactive: `research` pauses to clarify a vague question and refuses to guess, `research` prompts before overwriting an existing output file (which deterministically halts the driver on the documented cherry-pick-forward recovery path, V1), `research`'s own out-of-scope classifier can redirect a "does X hold" spike to `investigate` and return a non-build-report message (V2), and both end at an operator approval gate. Dispatched AFK through the build-report contract, none of these interactive points has an operator, so the sub-agent returns a non-conforming message and the driver halts.
- **Evidence considered:** `han-core/skills/research/SKILL.md` (clarify-or-abort in Steps 1–2, overwrite prompt in Step 1, out-of-scope redirect in Step 2, approval in Step 8); `han-coding/skills/investigate/SKILL.md` (approval gate in Step 5); the driver's AFK build dispatch and fail-closed build-report parse (`implement-work-items/SKILL.md` step 3.3); the halt procedure's cherry-pick-forward recovery.
- **Resolution:** A spike routed to `investigate` or `research` is a **HITL** build the operator runs in the foreground (the existing foreground-handoff path), where the operator answers the clarify/redirect/approval gates and places the finding at the item's Expected path. Only a quick-probe general-purpose spike is `AFK`, dispatched with the Expected path as its output target. Revised D17 and D8 set the autonomy; the spec's Spike flow states it.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows and States (Spike); decision-log D17, D8, D15

### F2: A spike-build skill owns its output path and shape; the item's Expected path and finding-shape are not guaranteed

- **Agent:** junior-developer (M2), adversarial-validator (remaining risk 3)
- **Category:** missing coordination
- **Finding:** `research` writes to its own default `docs/` location and `investigate` writes a root-cause-plus-fix-plan document to its own template path — neither honors the item's declared Expected path by default, and the driver does not pass Expected paths to the builder as an output target (only to the reviewer for the scope diff). A spike build would land the finding off-path and the scope review would flag it; `investigate`'s fix-plan shape is also an awkward "finding."
- **Evidence considered:** `research`/`investigate` output-path conventions in their SKILL.md; driver review dispatch passes Expected paths only to the reviewer (`implement-work-items/SKILL.md` step 3.3).
- **Resolution:** Folded into F1's HITL framing — the operator running the foreground spike places the finding at the item's Expected path, and a spike's finding is whatever the routed skill produces (a root-cause document is a valid finding). A quick-probe general-purpose AFK spike is dispatched with the Expected path as its finding target. Stated in the spec's Spike flow and D17.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows and States (Spike); decision-log D17

### F3: D18's routing note silently narrows the `Requires pre-work decisions` trigger, contradicting the template

- **Agent:** junior-developer (M3)
- **Category:** T#-free contradiction with an existing contract
- **Finding:** The template triggers the inline field on "an architectural decision or a design gate," but D18 routes architectural/record-worthy decisions to an ADR or spike and reserves the inline flag for a pure judgment call. D18 framed this as "keep the field" without stating that its producer-side trigger narrows, so an implementer following the template would still flag architectural decisions inline, contradicting the routing.
- **Evidence considered:** `work-item-template.md:36` ("an architectural decision or a design gate"); D18; D8 (a spike records a finding).
- **Resolution:** State that the field is kept but its producer-side trigger narrows — the inline flag is for a decision statable and actionable in a single sentence; architectural/record-worthy decisions route to an ADR, investigation-shaped ones to a spike. The template's field definition updates accordingly (a producer-side change). Revised D18 and the spec's pre-work-decision note.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows and States (Note on the boundary with pre-work decisions), Out of Scope; decision-log D18

### F4: D18's inline / spike / ADR routing has no rule-checkable tiebreaker

- **Agent:** adversarial-validator (V4), junior-developer (m1)
- **Category:** ambiguity in a coordination the producer must apply
- **Finding:** "A pure judgment call with nothing to investigate" is itself a judgment; the producer must choose among three homes (inline gate, spike, ADR) with no decidable rule, so producers will classify inconsistently.
- **Evidence considered:** D18; the producer classifies via a `han-core:project-manager` sub-agent (`plan-work-items/SKILL.md` step 5) with no such rule.
- **Resolution:** Add a concrete discriminator: use the inline gate when the decision can be stated and acted on in a single sentence; use a spike when answering requires reading files, running code, or gathering external evidence; use an ADR when the answer must be permanently recorded and referenced. Added to D18 and the spec note.
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows and States (Note on the boundary with pre-work decisions); decision-log D18

### F10: D17's HITL-for-interactive-skill-spike rule was a producer default, not a driver refusal

- **Agent:** adversarial-validator (R2 V1, V5)
- **Category:** unhandled failure mode reachable by hand-edit
- **Finding:** F1 made `investigate`/`research` spikes HITL, but expressed it only as a producer default in D17. A hand-edited `Type: spike` + `Suggested implementation: han-coding:investigate, AFK` passes all four D11 refusals and the drivable check, so the driver AFK-dispatches the interactive skill and recreates the F1 failure — while D11 claims it "re-checks the refusals as the last line, because a hand-edited file bypasses the producer." The claim overstated the guard.
- **Evidence considered:** D11's four refusals; driver step 1.7 drivable check (`implement-work-items/SKILL.md`); the F1 interactive-gate failure modes.
- **Resolution:** Add a fifth D11 refusal — an `AFK` marker on an interactive-skill spike is refused; such a spike is `HITL`. Briefly removed after round 2 (a D19 wording that made it a producer default on a clean-escalation theory), then **restored in round 3 as a capability-gated refusal** (see F15, F16): the clean escalation was unspecified and deterministically fails for two of `research`'s gates today, so the pre-mutation startup refusal is retained — now marked to lift once the driver gains the gate→`blocked` dispatch instruction and escalate-and-resume.
- **Resolved by:** evidence (round 2), refined via user input (D19), restored by evidence (round 3)
- **Raised in round:** R2 (restored R3)
- **Changed in plan:** Startup Validation and Refusals, Alternate Flows and States (Spike), Out of Scope; decision-log D8, D11, D17, D19

### F11: "Nearest valid classification" is destructive for an override with no semantics-preserving fix

- **Agent:** adversarial-validator (R2 V4), junior-developer (R2 F-R2-6)
- **Category:** ambiguity that silently changes an item's meaning
- **Finding:** F5's "producer resolves to the nearest valid classification" is undefined and destructive for `spike`+`Expected paths: None` (the only implementable fix — flip Type to `verification` — changes the item from a finding-producing spike to a no-commit verification) and undecidable for `deliverable`+`None` (flip Type, or drop `None`?).
- **Evidence considered:** the refusal set (`None` legal only for `verification`); D8 spike semantics; the override cases enumerated by both agents.
- **Resolution:** The producer does not transform a refused combination. When an operator override would produce one, the producer declines that override, keeps the item's otherwise-valid classification (never silently changing its Type or output contract), and names the declined override and the conflict in the breakdown for the operator to resolve. Revised D11 and the spec's producer-action paragraph.
- **Resolved by:** evidence
- **Raised in round:** R2
- **Changed in plan:** Startup Validation and Refusals; decision-log D11

### F15: D19's "clean escalation today" was unspecified and deterministically fails for two of research's gates

- **Agent:** evidence-based-investigator (R3 claim 5), junior-developer (R3 M1), adversarial-validator (R3 V1, V2)
- **Category:** unhandled failure mode / assumption assumed away
- **Finding:** The post-round-2 D19 wording removed the fifth refusal on the theory that an `AFK` interactive-skill spike escalates cleanly via `blocked`. But the build report's ESCALATION description covers build-level blockers only, and neither `research` nor `investigate` instructs a sub-agent to emit `blocked` at an interactive gate — `research` says "ask the user" (clarify) and "stop, produce no research report" (out-of-scope redirect), the latter producing a missing-sections return that the driver halts as *untrustworthy* (the exact F1 failure). So clean escalation is not specified behavior today; it depends on a build-dispatch instruction that does not exist. This is the reliance F1 already refuted, assumed away rather than resolved.
- **Evidence considered:** `build-report-contract.md` (ESCALATION lists build-level blockers; missing sections → untrustworthy halt); `research/SKILL.md` (clarify "ask the user"; out-of-scope "produce no research report"); `investigate/SKILL.md` (approval gate); no `blocked`-emitting instruction in either skill.
- **Resolution:** Restore the fifth refusal (F10) as a capability-gated guard — it holds until the driver gains (1) a dispatch instruction that maps a routed skill's operator-gates to `blocked` and (2) escalate-and-resume, then lifts. D19 rewritten to record AFK-with-escalation as the target and the two prerequisites; the "clean escalation today" claim removed. **Superseded by F20:** re-reading the skills showed they run AFK-clean for well-formed questions, so the refusal was removed — interactive-skill spikes are AFK-capable, producer-judged, and the dispatch instruction became an enhancement, not a gate.
- **Resolved by:** evidence
- **Raised in round:** R3
- **Changed in plan:** Startup Validation and Refusals, Alternate Flows and States (Spike), Out of Scope; decision-log D11, D19, D8

### F16: Removing a pre-mutation startup refusal for a mid-run halt is a recovery-cost regression against the spec's own invariant

- **Agent:** junior-developer (R3 M2), adversarial-validator (R3 V3)
- **Category:** T#-free contradiction with a stated design principle
- **Finding:** The D19 wording justified the `HITL` default by "escalate-then-halt loses progress," then dismissed the same cost as "graceful/recoverable" for the `AFK` hand-edit it permitted. On today's halt-only driver the round-2 startup refusal strictly dominates: it catches the hand-edit loudly, before any branch or commit, with nothing lost — the spec's own "refuse before mutating the repository" invariant — whereas a permitted `AFK` interactive-skill spike burns a full run and halts mid-stream, forcing cherry-pick-forward recovery. Removing the guard bought nothing today.
- **Evidence considered:** the spec's Startup Validation "refuse before mutating" principle; the Halt Procedure ("the run does not resume … cherry-picks the completed items forward"); step 1.7 pre-mutation refusal.
- **Resolution:** Same as F15 — restore the capability-gated fifth refusal, which reinstates the pre-mutation guard and removes the contradictory cost-weighing from D19's rationale. **Superseded by F20:** the refusal was removed once the skills were shown to run AFK-clean for well-formed questions; interactive-skill spikes are AFK-capable, producer-judged.
- **Resolved by:** evidence
- **Raised in round:** R3
- **Changed in plan:** Startup Validation and Refusals; decision-log D11, D19

### F20: Interactive-skill spikes run AFK-clean for well-formed questions — the R3 refusal was over-conservative

- **Agent:** operator question this session, resolved against the skill definitions
- **Category:** over-constraint from an over-read of the skills' behavior (supersedes F1/F10/F15/F16 HITL framing)
- **Finding:** R1–R3 concluded interactive-skill spikes must be HITL (then a capability-gated refusal) on the belief that `research`/`investigate` end at a blocking approval gate and hit their interactive gates deterministically. Re-reading the skills against an operator question showed otherwise: `research` Step 8 writes its report and presents it with **no blocking approval**, Step 4 says "proceed without a blocking confirmation," and its blocking gates (out-of-scope redirect, too-vague clarify, compound) fire only on a mis-routed, under-specified, or multi-thread question — all producer-avoidable; the one unavoidable gate (a re-run overwrite) is rare and recoverable. `investigate` writes its finding before its Step 5 gate, which is about triggering a *fix* a spike does not want. So a well-formed, correctly-routed, first-run, single-thread interactive-skill spike runs `AFK` and produces its finding; the R3 hard refusal foreground-ran well-formed spikes for no benefit.
- **Evidence considered:** `research/SKILL.md` Steps 1, 2, 4, 8 (clarify/overwrite/out-of-scope/compound gate triggers; "proceed without a blocking confirmation"; "write it to the output location and present it"); `investigate/SKILL.md` Step 5 (fix-approval, finding written first).
- **Resolution:** Interactive-skill spikes are AFK-capable, producer-judged (D19) — `AFK` when the question is well-formed and correctly routed, `HITL` when exploratory. The fifth refusal is removed; the AFK-with-escalation dispatch instruction + escalate-and-resume become an out-of-scope *enhancement* (upgrading recoverable edge-case halts into clean escalations), not a prerequisite. Supersedes the HITL/refusal resolutions of F1, F10, F15, F16.
- **Resolved by:** evidence + user input
- **Raised in round:** R3 (post-agent)
- **Changed in plan:** Startup Validation and Refusals, Alternate Flows and States (Spike), Out of Scope, Summary; decision-log D8, D11, D17, D19

## Minor edits

- F5: D11's producer action on a refused combination was undefined ("never reaches the file" needs a drop or substitute the spec never named), and the realistic trigger is an operator override, not the producer's own classification — junior-developer (m2), adversarial-validator (V3). Resolution: the producer resolves a refused combination to the nearest valid classification and names the correction in the breakdown (keeping the file drivable), with an operator override the realistic trigger; the driver re-checks as the last line. — decision-log D11, spec Startup Validation and Refusals.
- F6: the spike question-type buckets overlap ("whether an approach holds" appears in both the spike entry condition and the `research` route) with no producer default — junior-developer (m3). Resolution: add the producer default "`research` unless the question is a named symptom with a codebase root cause → `investigate`." — decision-log D17, spec Spike flow.
- F7 (YAGNI candidate): the `research` spike route rests on scope-symmetry and operator direction, not a specific spike that needed web reach — junior-developer (m4). Resolution: kept — the feature explicitly supports open-ended spikes (feedback F3 + operator direction this session), and the HITL framing (F1) bounds its risk to a foreground, operator-run skill; the simpler two-way fallback is recorded in D17's rejected alternatives. Surfaced to the operator. — decision-log D17.
- F8: the producer↔driver refusal vocabulary is one shared contract but has no sync governance — adversarial-validator (V7). Resolution: add a maintenance convention (a change to the refusal set is applied to both skills in one commit); no enforcement machinery (YAGNI). — spec Out of Scope, decision-log D11.
- F9: the deferred mechanical conformance gate (D16) lacked a formal `## Deferred (YAGNI)` entry with a `Reopen when` trigger, unlike F4/F7 — adversarial-validator (V8), junior-developer (m5). Resolution: add a Deferred entry with a reopen trigger (a structural breakage ships through the human-read gate, or a reusable plugin-lint check exists); D16 points to it and drops "planned." — spec Deferred (YAGNI), decision-log D16.
- F12: the D18 tiebreaker criteria (single-sentence / requires-evidence / must-be-recorded) can co-apply with no precedence — adversarial-validator (R2 V3), junior-developer (R2 F-R2-5). Resolution: state an ordered ladder — needs a durable record → ADR; else needs investigation → spike; else single-sentence judgment → inline; a decision needing both investigation and a record is a spike whose finding an ADR records. — decision-log D18, spec pre-work-decision note.
- F13: the narrowed pre-work trigger and the override refusal-set exception also live in the catalog's classification step and Overrides note, not only the template — junior-developer (R2 F-R2-3, F-R2-7). Resolution: name the catalog classification step and Overrides note as required (semantic, not optional-phrasing) `plan-implementation` updates. — spec pre-work-decision note and producer-action paragraph.
- F14: the HITL spike handoff does not communicate the item's Expected path, and a spike-with-output review has no finding-soundness framing branch (only change-review and no-output branches exist) — adversarial-validator (R2 V2, V6). Resolution: route both to `plan-implementation` as required additions — a spike-specific handoff step that names the Expected path, and a spike-finding-soundness review framing. — spec Spike flow.
- F17: F11's "declines the override … without silently changing its `Type`" is self-contradictory when the refused combination is created by a `Type` override (the producer must decline that very Type override) — adversarial-validator (R3 V4). Resolution: reword to "declines the specific override field(s) that create the refused combination and restores the item's catalog-derived classification … does not transform the item to a different Type or output contract to make the override fit." — decision-log D11, spec Startup Validation and Refusals.
- F18: "unattended-capable" collided with "unattended" (the concrete AFK marker word), risking an implementer writing `AFK` for an interactive-skill spike — junior-developer (R3 m3). Resolution: the Spike flow now reserves "unattended" for the AFK marker and states the interactive-skill spike is `HITL` (a refusal); the "unattended-capable" phrasing was removed. — spec Alternate Flows and States (Spike).
- F19: the future producer-default flip (interactive-skill spike `HITL`→`AFK` when the capabilities land) was untracked, and a blocked quick-probe's semantic recovery (re-route to `investigate`/`research`) was unstated — junior-developer (R3 m4), adversarial-validator (R3 V5). Resolution: the Out-of-Scope wiring entry now names the `HITL`→`AFK` flip as a coupling to apply when the capabilities ship, and the Spike flow notes a blocked quick-probe signals misclassification and is re-routed HITL. — spec Out of Scope, Alternate Flows and States (Spike).
