# Research: What can the autonomous-implementation-driver borrow from superpowers (model derivation, scope gating, and more)?

How the superpowers plugin (obra/superpowers, v6.0.3) derives the model for sub-agents and gates the scope/completion of a unit of work, plus other patterns worth borrowing for Han's planned autonomous work-item implementation driver. **Evidence mode: strict.**

## Summary

Superpowers is close to a working reference implementation of the skill we are planning, and it answers both of our open questions. On **model selection**, its hard-won lesson is the opposite of our current provisional default: never let a sub-agent silently inherit the session model, because an unnamed model quietly resolves to the session's most expensive one (one real run put all 26 of its reviewers on the top tier). Instead it makes the model an explicit choice on every dispatch, picked from a simple complexity rubric (cheap for mechanical one-or-two-file work, mid-tier for integration, the most capable model for design and for the final review). For Han this means: give the build and review sub-agents explicit model tiers (following Han's existing "model in the agent definition" convention) with an operator override, keep the conductor itself on a capable model, and add a hard turn cap as a cost backstop. On **scope gating**, superpowers has no declared file-scope field at all; it polices scope through the reviewer (a "did this build exactly the task, nothing extra" check plus a diff-first review budget). That is a good, proven pattern to borrow, but it has a real blind spot: it cannot catch correct code written in the wrong files. If that risk matters, a lightweight "expected paths" field on each work item closes it. Several other patterns are worth taking: a structured sub-agent status protocol, file-externalized hand-offs, an on-disk progress ledger for resume, blocker-triage routing, a pre-flight plan review, and a final whole-branch review. Notably, most of these confirm decisions Han already reached independently from the operator's manual runs, which is strong corroboration rather than new borrowing.

One correction the validation surfaced: superpowers' "same sub-agent fixes review findings" line is stale text; the current flow dispatches a fresh fix sub-agent with curated context, which matches Han's own conclusion that no continue-agent primitive exists.

This rests on directly verifiable evidence in the cloned repo (re-read and confirmed during validation) plus official Anthropic documentation for the platform mechanisms; the cost-magnitude framing rests on weaker, interested-party sources and is not load-bearing.

- **Confidence:** Medium-High (patterns and mechanisms are codebase-verified and corroborated by official docs; cost magnitudes are not).

## Research Results

**Model selection (resolves OI-1).** Superpowers requires every dispatch to name its model and warns that an omitted model "silently inherits the session's most expensive one" (S2). This was a real, observed cost regression: one run "put all 26 of its reviewers on the top tier," which is why the templates were changed to make the model mandatory (S4) [single-source: the 26-reviewer anecdote is only in the release notes; a related but different reviewer-cost data point appears in the design spec]. The choice is guided by a three-tier complexity rubric: cheap for isolated 1-2 file tasks with a clear spec, a standard mid-tier for multi-file integration, and the most capable model for architecture/design and for the final review (S1, S18). A floor rule warns that "turn count beats token price" because cheap models often take 2-3x the turns on multi-step work (S3). Crucially, superpowers deliberately keeps the model-*selection judgment itself* with the controller and never delegates it to a cheaper model; its experiments showed a cheap-model controller collapses on implicit quality-versus-plan conflicts (S5). It has **no** adaptive auto-routing. The platform supports all of this directly: Claude Code sub-agents accept a `model` field (including `inherit`), a `CLAUDE_CODE_SUBAGENT_MODEL` override, and a `maxTurns` cap, with a defined resolution order (W1); Anthropic's own guidance maps Haiku to sub-agent tasks, Sonnet to code generation, and Opus to multi-hour autonomous coding, and offers an `effort` lever within a model (W2); Anthropic's own multi-agent system runs an Opus orchestrator over Sonnet sub-agents (W3). The broader ecosystem has converged on the same fixed-tier-per-role pattern (W4), while dynamic model routing remains research-stage with no adopted standard (W7).

**Scope gating (resolves OI-2).** Superpowers has no declared file-scope field and no changed-file allowlist (S10). It polices scope two ways through review: a spec-compliance verdict that explicitly flags "Extra: features that weren't requested, over-engineering, unneeded nice-to-haves" plus an implementer YAGNI self-check (S10), and a "scope budget" that tells the reviewer to read the diff first and inspect outside it only to evaluate a named risk, never crawling the codebase (S9). This catches over-building well. It does **not** catch correct behavior implemented in the wrong files: a spec-compliant diff in the wrong location is approved, because nothing tells the reviewer which files *should* have changed (validation V10). Han's own plan already flags this exact gap (the work-item format has no scope field).

**Completion gate and fix loop.** A unit of work is "done" only when both a spec-compliance verdict and a code-quality verdict pass, with a three-tier severity model (Critical/Important blocking, Minor collected but non-blocking) (S6, S7). The per-task fix loop is **unbounded** ("repeat until approved"), with no iteration cap anywhere in the skill (S8). Each fix is a **fresh** fix sub-agent dispatched with curated context (the report file and the diff), not a persistent long-lived implementer; the "same subagent fixes them" phrasing survives only in a stale Red-Flags note that the current process flow contradicts (S8, validation V1). Completion claims are gated by an "Iron Law": verification is re-run fresh on every claim, and for delegated work the controller checks the VCS diff and verifies independently rather than trusting the sub-agent's report (S11) — exactly Han's verify-before-trust decision. The web consensus is unanimous that unbounded loops are a cost/correctness risk and a hard turn cap is essential (W4, W8), which supports Han's bounded-cap choice over superpowers' unbounded one. (The often-quoted "final fix wave cost more than all its tasks combined" is about a different antipattern — one fixer dispatched *per finding* in the final review — not the per-task loop (S20, validation V4).)

**Other borrowable mechanisms.** A structured return/status protocol (DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT, under 15 lines, detail in a report file) with controller routing per status (S12, S13); blocker triage that routes context problems back with context, reasoning gaps to a more capable model, oversized tasks to a split, and a wrong plan to the human (S13); a durable on-disk progress ledger at `.superpowers/sdd/progress.md` that lets a run resume from the ledger plus `git log` rather than conversation memory (S14); file-externalized hand-offs via small scripts (task brief, review package) in a git-ignored workspace so the controller never pastes diffs into its own context (S15); a pre-flight plan review that batches plan conflicts into one question before execution (S16); fresh sub-agent per task with no pasted history (S17); a final whole-branch review on the most capable model (S18); one git worktree per run with parallel implementers forbidden because of working-tree conflicts (S19); and a continuous-execution rule that only stops on an unresolved blocker, genuine ambiguity, or completion (S20).

**Convergence, not just borrowing.** Most of these map onto decisions Han already made from the operator's manual-run feedback: the Iron Law equals Han's D8, the status protocol equals D12, the ledger equals D10/D20, blocker triage equals D7, and Han's bounded fix cap is the one place Han deliberately improves on superpowers (validation V6). The genuinely new contributions are the model-selection rubric, the pre-flight plan review, the file-externalized hand-off scripts, and the final whole-branch review.

**Cost context [single-source / interested-party].** Three sources report a June 15 2026 billing change making `claude -p` and Agent SDK calls bill at full API rates from a separate credit pool (W5); whether this applies to Han's in-session Task-tool dispatch (as opposed to `claude -p`) is unverified, so it is contextual, not load-bearing (validation V8). Numerous vendor blogs claim 12%–10x cost reductions from model tiering (W6), but all are interested parties with single-source numbers; discounting them entirely does not change the recommendation, which rests on the in-repo cost evidence (S2, S4).

## Options to Consider

### O1: Explicit per-dispatch model from a complexity rubric (Han-idiomatic)

- **What it is:** Define typed implementer and reviewer sub-agents with an explicit `model:` in their definitions (Han's existing convention), choose the tier per the cheap/standard/most-capable rubric, expose an operator-level override, keep the conductor on a capable model, and add a hard turn cap as a backstop.
- **Trade-offs:** Requires deciding default tiers per role and documenting that the conductor must not run on a cheap model. Per-task (not just per-role) tuning still needs a dispatch-time model override; Han already does this in other skills via the dispatch `model` parameter.
- **Rests on:** (S1, S2, S3, S5, S18, W1, W2, W3, W4)
- **Evidence status:** corroborated

### O2: Inherit the session model by default (Han's current provisional D14)

- **What it is:** Sub-agents default to the operator's session model unless overridden.
- **Trade-offs:** Simple, but superpowers' direct evidence is that silent inheritance resolves to the most expensive model and that a cheap session model degrades conductor judgment. Removes per-role cost control.
- **Rests on:** (S2, S4, S5, W1)
- **Evidence status:** corroborated (as the option to avoid as a blanket default)

### O3: Adaptive automatic model routing (router / cascade)

- **What it is:** A routing layer scores each task and assigns the cheapest adequate model at runtime.
- **Trade-offs:** Research-stage, no adopted standard, added infrastructure and latency; superpowers explicitly rejected automating the model choice.
- **Rests on:** (S5, W7)
- **Evidence status:** single-source / research-stage (caveated)

### O4: Review-level scope gate only (borrow superpowers as-is)

- **What it is:** Police scope purely through the reviewer: a spec-compliance "nothing extra" verdict plus a diff-first "scope budget."
- **Trade-offs:** Proven and cheap; catches over-building. Structural blind spot: cannot detect correct behavior implemented in the wrong files.
- **Rests on:** (S9, S10)
- **Evidence status:** corroborated (with a named gap)

### O5: Review-level gate plus a lightweight "expected paths" field on work items

- **What it is:** O4 plus a small declared field on each work item listing the paths it is expected to touch, checked against the diff (a companion change to the work-item producer, like the HITL marker).
- **Trade-offs:** Closes the wrong-files blind spot deterministically; costs a second small upstream companion change and still needs the generated/ignored-file exclusions Han already specified.
- **Rests on:** (S9, S10, validation V10)
- **Evidence status:** corroborated (gap-closing rationale is reasoned from the evidence)

## Recommendation

- **Recommendation:** For **OI-1**, adopt **O1** and retire the blanket inherit-the-session default (O2). Concretely: give the build and review sub-agents explicit model tiers via Han's normal "model in the agent definition" convention, using superpowers' cheap/standard/most-capable rubric as the guidance for those values; expose a single operator override (Han's D14 input) and allow a per-dispatch override for an unusually hard or trivial item; require the **conductor itself to run on a capable model** regardless of sub-agent tiers; and add a hard turn cap as a cost/stall backstop. Do not build adaptive auto-routing (O3). For **OI-2**, borrow the review-level gate (O4) as the baseline, but treat **O5** as the answer when correct-code-wrong-files is a real risk: the review-level gate alone has a structural blind spot, so either add a lightweight expected-paths field or explicitly accept and document the gap. Separately, borrow the structured status protocol, blocker-triage routing, the on-disk progress ledger, file-externalized hand-offs, the pre-flight plan review, and a final whole-branch review; and correct Han's D13 to "fresh fix sub-agent with curated context" (superpowers does not keep a long-lived implementer per item). Keep Han's bounded fix cap.
- **Evidence basis:** The OI-1 direction rests on directly verifiable in-repo evidence (S1, S2, S3, S5, S18), re-read and confirmed during validation, plus official Anthropic platform documentation for feasibility (W1, W2, W3). The OI-2 baseline (O4) rests on the superpowers reviewer templates (S9, S10); the O5 gap-closing rationale is reasoned from the validation finding (V10) that a review-only gate cannot catch wrong-file placement, not from a source claiming O5 outright. The borrowable mechanisms rest on directly-read superpowers files (S11–S20). The cost-magnitude framing (W5, W6) is interested-party / single-source and is explicitly **not** load-bearing: the recommendation holds on the in-repo cost evidence (S2, S4) alone.

## Validation

### V1: "Same sub-agent fixes review findings" supports a long-lived agent per item

- **Strategy:** Challenge the Evidence
- **Investigation:** Read the full `subagent-driven-development/SKILL.md`; grepped the fix-dispatch language.
- **Result:** Refuted. "Same subagent" appears only in a stale Red-Flags line (≈397); the current process flow and dispatch guidance (≈59, 75-76, 194, 208, 318) dispatch a **fresh** fix sub-agent with curated context.
- **Impact:** The borrow for Han D13 is a curated-context re-dispatch, not a persistent implementer. This actually matches Han's own conclusion that no continue-agent primitive exists. Recommendation corrected accordingly.

### V5: OI-1 should copy superpowers' per-prompt `[MODEL]` placeholder

- **Strategy:** Challenge the Assumptions
- **Investigation:** Read Han's agent definitions and dispatch convention (all han-core agents set `model:` in frontmatter; skills pass `model:` on dispatch).
- **Result:** Refuted as framed. Han uses named agents with model in their definition, not a prompt-template placeholder.
- **Impact:** OI-1 recast to Han's idiom (typed agents with explicit model + dispatch override + capable conductor). The rubric is borrowed as *guidance for choosing tier values*, not the mechanism.

### V10: OI-2 review-level gate fully resolves scope policing

- **Strategy:** Challenge the Recommendation
- **Investigation:** Read the superpowers reviewer templates and Han's D8/OI-2.
- **Result:** Confirmed gap. The "Extra"/scope-budget gate catches over-building but not correct code in the wrong files; nothing tells the reviewer which files should have changed.
- **Impact:** OI-2 stays open; O5 (lightweight expected-paths field) added as the gap-closing option. Recommendation no longer presents OI-2 as settled.

### V4 / V6: framing corrections

- **Strategy:** Challenge the Evidence / Framing
- **Result:** Partially refuted. The "final fix wave cost more than all tasks" quote is about per-finding fixer proliferation in the *final* review, not the per-task loop (V4). Most "borrowables" are independent convergence with decisions Han already made from operator feedback, not new borrowings (V6).
- **Impact:** Han's bounded-cap rationale re-grounded on operator feedback plus the web turn-cap consensus, not the misattributed quote. The report now frames shared patterns as corroboration of Han's existing decisions.

### V2 / V9 / V11: evidence-provenance corrections

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Result:** Partially refuted. The "most capable model for final review" claim is at SKILL.md ≈107-109, not the cited 80-81/203-207 (V2). Specific model versions ("Opus 4.8", "Sonnet 4.6") appear nowhere in superpowers, which uses generic tier names; the report avoids attributing versions to superpowers (V9). The "26 reviewers" anecdote is single-source (release notes), not dual-sourced (V11).
- **Impact:** Citations corrected; no change to recommendation direction.

### Adjustments Made

The recommendation was sharpened, not overturned: OI-1 recast for Han's named-agent architecture and given a "capable conductor" requirement; D13 borrow corrected to fresh-fix-sub-agent-with-curated-context; OI-2 kept open with O5 added; the cost framing demoted to non-load-bearing; and provenance citations corrected. The core direction (explicit tiered model selection over silent inherit; review-level scope gate with a named gap) survives.

### Confidence Assessment

- **Confidence:** Medium-High.
- **Remaining Risks:** (1) Whether `maxTurns` triggers graceful escalation or a hard abort is unverified, which matters for Han's stall-handling (D17). (2) The June-2026 billing claim's applicability to Han's in-session Task dispatch is unverified, so cost urgency is uncertain (but not load-bearing). (3) Vendor cost figures (W6) are interested-party single-source and are excluded from the basis. (4) OI-2 remains genuinely open: shipping with O4 alone leaves the wrong-files case to the operator's eyes at final review. (5) The conductor-on-a-capable-model point is critical: if an operator runs the driver on a cheap session model and the orchestration inherits it, superpowers' documented controller-collapse failure (S5) applies to Han too.

## Sources

| ID | Source | Link / location | Retrieved | Trust class | Summary (one line) | Evidence status |
|---|---|---|---|---|---|---|
| S1 | superpowers model rubric | `provided: /home/taminomara/p/superpowers/skills/subagent-driven-development/SKILL.md:99-131` | n/a | provided (verified) | Cheap/standard/most-capable tiers by task type | corroborated by W2, W4 |
| S2 | model required per dispatch | `provided: …/subagent-driven-development/implementer-prompt.md:8-9; task-reviewer-prompt.md:13-14` | n/a | provided (verified) | Omitted model silently inherits session's most expensive | corroborated by S4, W1 |
| S3 | turn count beats token price | `provided: …/subagent-driven-development/SKILL.md:119-125` | n/a | provided (verified) | Mid-tier floor; cheap models take more turns | corroborated by W8 |
| S4 | 26-reviewers cost regression | `provided: …/RELEASE-NOTES.md` (v6.0.0, ~line 51) | n/a | provided (verified) | One run put all 26 reviewers on top tier | single source (caveated) |
| S5 | judgment guardrail | `provided: …/docs/superpowers/specs/2026-06-10-strict-cost-sdd-design.md:25-52,119-158` | n/a | provided (verified) | Cheap-model controller collapses on quality-vs-plan conflicts | single source (caveated) |
| S6 | dual completion verdict | `provided: …/subagent-driven-development/task-reviewer-prompt.md:139-165` | n/a | provided (verified) | Spec-compliance + code-quality verdicts | corroborated by W3 |
| S7 | review severity tiers | `provided: …/requesting-code-review/code-reviewer.md:86-126` | n/a | provided (verified) | Critical/Important blocking, Minor not; template lacks a model field | corroborated by S6 |
| S8 | uncapped fresh-fix loop | `provided: …/subagent-driven-development/SKILL.md:59,75-76,194,208,318 (vs stale 397)` | n/a | provided (verified) | Loop uncapped; fix is a fresh sub-agent, "same subagent" text is stale | contradicted internally (see V1) |
| S9 | review scope budget | `provided: …/task-reviewer-prompt.md:36-50; specs/2026-06-09-…md:130` | n/a | provided (verified) | Diff-first; inspect outside only for a named risk | corroborated by S10 |
| S10 | "Extra"/YAGNI scope-creep check | `provided: …/task-reviewer-prompt.md:83-85; implementer-prompt.md:95-97` | n/a | provided (verified) | Flags over-building; no declared file-scope field exists | corroborated by S9 |
| S11 | verification Iron Law | `provided: …/verification-before-completion/SKILL.md:16-38` | n/a | provided (verified) | Fresh verification; check VCS diff, never trust agent report | corroborated by W4 |
| S12 | status protocol | `provided: …/subagent-driven-development/implementer-prompt.md:127-138` | n/a | provided (verified) | DONE/DONE_WITH_CONCERNS/BLOCKED/NEEDS_CONTEXT, <15 lines | corroborated by S13 |
| S13 | blocker triage routing | `provided: …/subagent-driven-development/SKILL.md:132-148` | n/a | provided (verified) | context/reasoning/split/plan→human routing | single source |
| S14 | durable progress ledger | `provided: …/subagent-driven-development/SKILL.md:246-264` | n/a | provided (verified) | Resume from `.superpowers/sdd/progress.md` + git log | single source |
| S15 | file-externalized hand-off | `provided: …/subagent-driven-development/scripts/{sdd-workspace,task-brief,review-package}` | n/a | provided (verified) | Briefs/reports/diffs passed by file path in git-ignored workspace | single source |
| S16 | pre-flight plan review | `provided: …/subagent-driven-development/SKILL.md:85-97` | n/a | provided (verified) | Batched plan-conflict scan before execution | single source |
| S17 | fresh sub-agent per task | `provided: …/subagent-driven-development/SKILL.md:188-193` | n/a | provided (verified) | No pasted prior-task history in dispatches | corroborated by S12 |
| S18 | final review on capable model | `provided: …/subagent-driven-development/SKILL.md:107-109` | n/a | provided (verified) | Final whole-branch review on most capable model | corroborated by S1 |
| S19 | one worktree per run | `provided: …/using-git-worktrees/SKILL.md; subagent-driven-development/SKILL.md:373,409` | n/a | provided (verified) | Parallel implementers forbidden (working-tree conflicts) | single source |
| S20 | continuous execution + final-fix antipattern | `provided: …/subagent-driven-development/SKILL.md:14-17,215-217` | n/a | provided (verified) | Don't pause between tasks; avoid per-finding fixers in final review | single source |
| W1 | Claude Code subagent docs | https://code.claude.com/docs/en/sub-agents | 2026-06-30 | web | `model` (incl `inherit`), `CLAUDE_CODE_SUBAGENT_MODEL`, `maxTurns`, resolution order | corroborated by W2, W3 |
| W2 | Anthropic choosing-a-model | https://platform.claude.com/docs/en/about-claude/models/choosing-a-model | 2026-06-30 | web | Haiku→subagents, Sonnet→codegen, Opus→autonomous coding; effort lever | corroborated by W1, W3 |
| W3 | Anthropic multi-agent system | https://www.anthropic.com/engineering/multi-agent-research-system | 2026-06-30 | web | Opus orchestrator + Sonnet sub-agents; LLM-judged gates | corroborated by W1, W2 |
| W4 | Ralph / SDD public writeups | https://github.com/ClaytonFarr/ralph-playbook ; https://blog.fsck.com/2025/10/09/superpowers/ | 2026-06-30 | web | Opus-coordinator+Sonnet-workers; test-then-commit; bounded vs unbounded; turn caps | corroborated across sources |
| W5 | June-2026 billing change | https://the-decoder.com/claude-subscriptions-get-separate-budgets-for-programmatic-use-billed-at-full-api-prices/ | 2026-06-30 | web | `claude -p`/SDK bill at API rates from a separate pool | corroborated (3 sources); applicability to in-session dispatch unverified |
| W6 | vendor cost-tiering blogs | CloudZero; Augment; MindStudio; Caylent; AgentField | 2026-06-30 | web | 12%–10x cost reductions from model tiering | single-source / interested-party (excluded from basis) |
| W7 | model-routing research | https://arxiv.org/html/2604.03527v1 ; https://tianpan.co/blog/2025-11-03-llm-routing-model-cascades | 2026-06-30 | web | Dynamic routing/cascades; research-stage, no standard | single-source / research-stage |
| W8 | turn-count cost driver | https://daviddaniel.tech/research/articles/token-multiplier/ ; MindStudio agentic-loop guide | 2026-06-30 | web | Turn count dominates agentic cost; maxTurns hard stop, 10-25 turns typical | corroborated by W4 |

### S2: model required per dispatch — recommendation-bearing

- **Link / location:** `provided: /home/taminomara/p/superpowers/skills/subagent-driven-development/implementer-prompt.md:8-9` and `task-reviewer-prompt.md:13-14`
- **Retrieved:** n/a
- **Trust class:** provided (operator-cloned third-party repo; re-read and confirmed by the validator)
- **Summary:** Both dispatch templates carry a REQUIRED `model:` field, with the explicit warning that an omitted model "silently inherits the session's most expensive one." This is the core evidence that Han should not default sub-agents to a blanket session-inherit, and should name tiers explicitly instead.
- **Evidence status:** corroborated by S4 (the observed regression) and W1 (the platform resolution order that makes inherit resolve upward)

### S5: judgment guardrail / cheap-controller collapse — recommendation-bearing

- **Link / location:** `provided: /home/taminomara/p/superpowers/docs/superpowers/specs/2026-06-10-strict-cost-sdd-design.md:25-52,119-158`
- **Retrieved:** n/a
- **Trust class:** provided (verified)
- **Summary:** Superpowers' cost experiments found that moving the controller to a cheaper model fails on implicit quality-versus-plan conflicts (a "planted-defect battery failed decisively" with cheaper controllers). Model-selection judgment, review verdicts, and blocker diagnosis stay at the highest tier or with the human. This is the basis for the "conductor must run on a capable model" part of the recommendation and the warning against Han inheriting a cheap session model for orchestration.
- **Evidence status:** single source (caveated — one project's experiment), but directly verified and internally detailed

### S9 / S10: review-level scope gating — recommendation-bearing

- **Link / location:** `provided: …/task-reviewer-prompt.md:36-50,83-85` and `implementer-prompt.md:95-97` and `specs/2026-06-09-sdd-task-scoped-review-dispatch-design.md:130`
- **Retrieved:** n/a
- **Trust class:** provided (verified)
- **Summary:** Scope is policed entirely at review time: a "scope budget" (read the diff first, inspect outside only for a named risk) plus a spec-compliance check that flags work beyond what the task requested, backed by an implementer YAGNI self-check. There is no declared file-scope field. This is the borrowable OI-2 baseline (O4); its blind spot for wrong-file placement is what motivates the optional expected-paths field (O5).
- **Evidence status:** corroborated (the two mechanisms reinforce each other); the wrong-files gap is a reasoned validation finding (V10), not a sourced claim
