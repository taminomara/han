# Research: Strategy and Han Tools for Reviewing Skills, Agents, and Documentation in an Autonomous Implementation Loop

*Open-ended question: what is the best strategy, and which Han tools, for the **review-and-fix** phase of an autonomous build → review → fix → commit loop when the work item's deliverable is a Claude Code skill, an agent, or documentation — as groundwork for extending `implement-work-items` to support human-in-the-loop (HITL) items and non-code tasks?*

*Evidence mode: **strict** (evidence required; every claim carries a source and an evidence status).*

## Summary

The strongest and best-evidenced strategy is the one Han already runs for code: a loop where a separate agent reviews the builder's work, findings feed a bounded fix loop, and the item either passes a gate or escalates. The single most important property — the reviewer is never the same agent that built the artifact — is already true in Han's loop across every fix round, and it is what keeps an automated review honest. That pattern should be preserved, not redesigned, when extending to non-code work.

For **documentation**, Han already has two capable unattended reviewers (a fact-preservation auditor and an information-architecture auditor), so documentation is the most promising non-code deliverable to automate. But there is a real plumbing gap: those reviewers speak a different "findings" format than the driver's review loop expects, so they cannot simply be plugged in — an adapter or a second, non-code review contract has to be built first. For **new skills, new agents, ADRs, coding standards, and runbooks**, Han has no separate automated reviewer that produces actionable pass/fail findings, and the builders for those deliverables already need a person during the build, so the honest recommendation is to keep them human-reviewed for now rather than pretend an automated gate exists.

Two concrete errors in the plan's own draft artifacts must be fixed before any of this is built: the skill-selection catalog marks several interactive skills (ADR, coding standard, runbook) as fully unattended when they stop for a human mid-run, and it names a documentation-serving skill as an automated reviewer for skills and agents when it produces no reviewable findings.

This is a solid direction rather than a certainty: the load-bearing conclusions survive even if every unverifiable recent web source is discarded, but the recommendation cannot be acted on as first drafted because of the format-mismatch gap and the catalog errors. Well-corroborated on the core pattern; qualified by real, verified prerequisites.

- **Confidence:** Medium

## Research Results

**Han's current loop already embodies the pattern the prior art endorses most strongly: a separated critic.** The driver dispatches a build sub-agent running `tdd` and a *distinct* review sub-agent running `code-review`, and inside a fix round it re-runs the build with `tdd` and then re-reviews with a fresh `code-review` sub-agent — builder and reviewer stay separate in every round, and the fix agent reads the prior review as input, never as its own author (A1, A5; confirmed by validation V5). This matters because the most consistent finding across the loop literature is that when the *same* model both generates and critiques, self-bias is amplified: the model inflates its own quality scores and optimizes for cosmetic "false-positive corrections" while task quality plateaus or regresses (A27, A28, A29). The mitigation is exactly what Han does — the critic must not be the generator (A27, A31, A32). So the extension's first job is to *preserve* this invariant for non-code items, not to invent something new.

**For non-code deliverables the automated "done" signal is weaker, because there is no compiler or test suite as an objective oracle.** LLM review is reliable for structural and clarity dimensions but weak on factual accuracy unless it is *reference-grounded* — given the authoritative source, spec, or prior version to check against (A39, A46, A47, A52). The best-evidenced configuration for a review that can gate a revision loop is a structured rubric plus a reference document, with findings that carry a location, a severity, and a suggested fix so a downstream agent can act on them (A39, A40, A41, A43). The claim that LLM-only review is too unreliable to be the *sole* gate for high-stakes non-code artifacts is corroborated by the judge-reliability literature (A36, A39, A49) — though note (see Validation V8) that several of the most on-point sources here are recent, unverifiable preprints.

**Han already has reference-grounded and rubric-style reviewers for documentation, and they produce location-anchored, severity-marked findings and run unattended** (A8, A9, A12, A13):
- `content-auditor` is *reference-grounded* fact-preservation: it extracts atomic facts from the original source, classifies each as Present / Correctly Removed / Missing in the new document, and validates removals against the codebase with Grep — the closest match in Han to the "check every claim against a trusted reference" pattern the prior art rewards (A8).
- `information-architect` is a *rubric* reviewer: it audits a document against named IA principles and returns numbered `IA-###` findings, each with a principle, a location, evidence, reader impact, severity, and a remediation (A9).
- `gap-analyzer` compares any artifact against a desired-state reference and returns `GAP-###` findings (Missing / Partial / Divergent / Implicit) with an evidence pair, and it runs its own adversarial self-disproof pass over its findings (A10).

**But those reviewers cannot be dropped into the current fix loop as-is — this is the sharpest, verified gap.** The driver's review sub-agent must return a specific verdict contract: `RECOMMENDATION`, `COVERAGE`, `FINDINGS (at and above the gate threshold: critical|warning)`, `BELOW THRESHOLD`, `DURABLE RECORD`, and the parser is fail-closed — a missing or malformed section triggers an untrustworthy-verdict halt (A2). `content-auditor` emits Present/Correctly-Removed/Missing with no severity tiers; `information-architect` emits `Blocks comprehension / Degrades / Friction / Polish` severities, not Critical/Warning/Suggestion; neither emits a `RECOMMENDATION` line (A8, A9). Fed to the current loop, every documentation item would halt immediately (validation V3). So "documentation already has unattended reviewers" is true, but "documentation can run in the loop today" is not — a non-code verdict contract or a translation-wrapper is a prerequisite.

**Reviewing skills and agents is the weakest part of the proposed mapping.** The builders' guidance-conformance review is a *self-review inside the builder* — the same agent that wrote the skill checks it against the guidance and applies fixes (A6, A7), which is precisely the self-bias configuration to avoid for an automated gate. The catalog's proposed alternative — "review with `guidance`" — is not a reviewer at all: `guidance` in Guidance Mode only serves documents, with no findings format and no verdict (A22, validation V4). And the builds themselves are interview-driven and stop for a human at every decision (A17). So there is no separate agent that reviews a finished skill or agent against the guidance and returns actionable findings, and the builds need a human regardless — which points to keeping these items human-reviewed rather than automated.

**HITL has three well-attested gate positions, and the plan's three per-item signals map onto them cleanly.** The positions are: a pre-task decision gate (approve the approach before building), an in-line checkpoint (interrupt mid-run and resume from saved state), and a post-task sign-off (human reviews the finished artifact, e.g. a PR, before commit) (A54, A55, A56, A61, A62). The plan records exactly the signals needed to route these: "human decision before work starts" → pre-task gate; "build phase unattended? no" → interactive/interview build; "review phase unattended? no" → post-task sign-off (A15, A16). Production practice favors checkpoint-serialize-resume with *async parking* of gated items over blocking the whole batch, and classifying items by consequence/reversibility rather than by model confidence (A55, A56, A59). Bounded-retry-then-escalate — already the driver's design via `--fix-cap` and halt-on-cap (A5) — is the corroborated termination strategy (A25, A26, A30, A60); convergence/no-new-findings detection is a reasonable addition for non-code (A33, A34, single-source-cluster; see V8).

**Conflict surfaced by the codebase evidence (do not read past this):** the plan's two new, untracked artifacts contradict each other. The skill-selection catalog marks ADR, coding-standard, and runbook builds as `AFK` (unattended) (A14), while the feature specification lists those same three as skills that "stop for a human mid-run" (A16). Direct inspection of the skills confirms the feature spec: all three call `AskUserQuestion` mid-run, not only in an upfront preflight (validation V1, V2). The catalog is wrong on those rows, and on the "review skills/agents with `guidance`" rows (V4). This must be resolved before a driver consumes the catalog, or the driver will classify interactive items as drivable and hang on a prompt it cannot answer.

## Options to Consider

### O1: Reuse `code-review` as the universal reviewer for every deliverable type

- **What it is:** Point the existing review sub-agent at all items regardless of what they produce.
- **Trade-offs:** `code-review` dispatches a code-specific roster (security, concurrency, data-engineering, edge cases) and applies a code rubric; it has no lens for prose accuracy, information architecture, or skill/agent authoring conventions. It would produce mostly empty or irrelevant findings on non-code and give a false "approve" (A3, A4).
- **Rests on:** A3, A4.
- **Evidence status:** corroborated (that `code-review` is code-scoped).

### O2: Per-deliverable-type reviewer routing using Han's existing agents

- **What it is:** The driver dispatches the reviewer recorded for each item's deliverable nature — documentation → `content-auditor` and/or `information-architect`; code → `code-review` — mirroring the plan's catalog.
- **Trade-offs:** Uses reviewers that are already reference-grounded/rubric-based and run unattended for docs (A8, A9). But it requires a routing table to be maintained, and — critically — the doc reviewers' output is incompatible with the driver's verdict contract, so it needs an adapter before it works (A2, validation V3). Leaves skills/agents/ADR/standard/runbook without a usable automated reviewer (A22, V4).
- **Rests on:** A8, A9, A12, A13, A2, A14.
- **Evidence status:** corroborated on reviewer capability; the loop-compatibility gap is a verified blocker.

### O3: A single generic rubric LLM-as-judge for all non-code items

- **What it is:** One reviewer with a generic quality rubric, no per-type reference document.
- **Trade-offs:** Cheapest to wire, but a generic rubric with no reference grounding has the highest false-positive rate and cannot check factual accuracy; different models converge on different "evaluation dialects," so it is internally consistent but not trustworthy as a sole gate (A39, A46, A47, A48). Throws away Han's existing reference-grounded reviewers.
- **Rests on:** A39, A46, A47, A48.
- **Evidence status:** corroborated directionally (rubric-only is weak); several supporting sources are unverifiable 2026 preprints (see V8).

### O4: Human sign-off gate for all non-code items (LLM review advisory only)

- **What it is:** Any automated review is advisory; a human accepts/rejects before commit for every non-code item.
- **Trade-offs:** Safest and correct where no trustworthy automated reviewer exists (skills, agents, ADR, standard, runbook), but defeats the autonomy goal for deliverables (documentation) where Han *does* have capable unattended reviewers, leaving throughput on the table.
- **Rests on:** A17, A22, A36, A39.
- **Evidence status:** corroborated as the right floor for un-reviewable types.

### O5: Hybrid tiered routing (recommended direction)

- **What it is:** Route by deliverable type: send documentation and code to Han's unattended reviewers; human-gate the deliverables with no usable automated reviewer (skills, agents, ADR, standard, runbook); preserve builder≠reviewer separation; keep bounded fix-cap + escalate; classify each item's HITL position from the three recorded signals and park gated items asynchronously rather than blocking the batch.
- **Trade-offs:** Matches oversight cost to risk and reuses what Han has, but is only actionable after (a) the non-code verdict-contract gap is closed and (b) the catalog errors are corrected. Adds a routing table to maintain.
- **Rests on:** A1, A5, A8, A9, A2, A14, A16, A27, A54, A55, A59, A61.
- **Evidence status:** corroborated on the core pattern; conditional on two verified prerequisites (V2, V3, V4).

### O6: `gap-analyzer` against the work-item's acceptance criteria as a unified non-code gate

- **What it is:** Instead of a per-type routing table, use one domain-agnostic reviewer — `gap-analyzer` — comparing the delivered artifact (current state) against the work item's own acceptance criteria (desired state), for every non-code type.
- **Trade-offs:** Simpler routing (one reviewer, spec-anchored), inherently reference-grounded, and it already runs an adversarial self-disproof pass over its findings (A10). But it needs the same verdict-contract adapter as O2 (V3), it checks *conformance to the stated spec* rather than domain-specific quality (it will not catch an IA problem or a lost fact the way `information-architect`/`content-auditor` do), and its fit for arbitrary non-code deliverables is reasoned from the agent's contract, not demonstrated.
- **Rests on:** A10.
- **Evidence status:** corroborated that the agent exists and is spec-anchored; its suitability as a *universal* non-code gate is a design hypothesis, not tested (surfaced by validation V7).

## Recommendation

- **Recommendation:** Adopt **O5 (hybrid tiered routing)** as the strategy, keeping `code-review` for code, using Han's `content-auditor` + `information-architect` for documentation, and **keeping skills, agents, ADRs, coding standards, and runbooks human-reviewed** — but treat two verified prerequisites as blocking, and evaluate **O6** for the non-code path before committing to a per-type routing table:
  1. **Close the verdict-contract gap first (hard prerequisite).** `content-auditor` and `information-architect` do not emit the driver's `RECOMMENDATION/COVERAGE/FINDINGS` contract and will halt the loop as-is (A2, A8, A9; V3). Define a non-code review contract (or a thin adapter agent that maps their findings into it) before wiring any documentation item into the fix loop. This is the single most important build-order finding.
  2. **Correct the plan's catalog before a driver consumes it.** Resolve the A14↔A16 contradiction in favor of the feature spec and the actual skill behavior: mark ADR, coding-standard, and runbook builds **HITL**, not AFK (A16; V1, V2), and replace "review skills/agents with `guidance`, AFK" with "manual read, HITL," since `guidance` emits no findings (A22; V4).
  3. **Preserve builder≠reviewer for non-code, as the loop already does for code** (A1, A5, A27; confirmed V5). Do **not** count a builder's own Step-6 self-review (skill-builder/agent-builder) as the item's review (A6, A7) — that is the self-bias configuration to avoid.
  4. **Weigh O6 against O2 for the non-code path.** A single spec-anchored `gap-analyzer` gate may be simpler to maintain than a per-type routing table, at the cost of domain-specific depth. Both need the same adapter (V3, V7); decide deliberately rather than defaulting to per-type routing.
  5. **For HITL orchestration, use checkpoint-serialize-resume with async parking of gated items** and classify by consequence/reversibility, not model confidence (A54, A55, A56, A59); keep bounded fix-cap + escalate-on-exhaust (A5) and consider convergence detection for non-code (A33, A34, caveated).

- **Evidence basis:**
  - *Corroborated (survives discarding all unverifiable 2026 preprints — see V8):* the separated-critic invariant and its self-bias justification (A1, A5, A27, A28, A29; V5); bounded-retry-then-escalate as the termination model (A5, A25, A26); the three HITL gate positions and checkpoint/resume + async parking (A54, A55, A56, A61, A62); reference-grounding as the reliability lever for non-code review (A39); and every codebase current-state claim about Han's reviewers, the verdict contract, the catalog, and the skills' interactivity (A1–A24, directly verified in Validation).
  - *Single-source / caveated:* that "post-task human sign-off is *more* load-bearing for non-code than for code" — after discarding the 2026 preprints (A47, A52) this rests on inference plus general judge-reliability literature, so it is carried as a **design judgment**, not a prior-art-corroborated finding (V8). Specific figures (loop-convergence rates, rubric ROC-AUC) are single-source and advisory (A33, A34, A48).
  - *Not decided by evidence:* whether `gap-analyzer` is a good *universal* non-code gate (O6) is a hypothesis to test, not a settled result (V7); and there is no sourced answer to fail-fast-vs-partial-run when gated items appear at batch start, though production guidance leans toward async partial-run (A54, A59; V8).

The recommendation **stands with caveats**: the direction is sound and robust to the weakest evidence, but it is not actionable as first drafted until the verdict-contract gap and the catalog errors are fixed.

## Validation

### V1: ADR, coding-standard, and runbook builds are unattended (AFK) after a one-time preflight

- **Strategy:** Challenge the Evidence.
- **Investigation:** Grepped the three skills for `AskUserQuestion`. Found mid-run calls *outside* any preflight: `architectural-decision-record/SKILL.md:57`, `runbook/SKILL.md:69,90,104`, `coding-standard/SKILL.md:89,132` (the last gates the scope-index step, not a preflight).
- **Result:** Refuted.
- **Impact:** The catalog's `AFK` build label for these three is wrong; their builds are HITL. The recommendation's conclusion (these need a human) is right, but the reason is broader than "review is human" — the *build* is human too. Folded into recommendation item 2.

### V2: The catalog (A14) and feature spec (A16) are internally consistent

- **Strategy:** Challenge the Evidence.
- **Investigation:** Read both untracked files. Catalog: ADR/coding-standard/runbook builds = `AFK`. Feature spec: those three "stop for a human mid-run."
- **Result:** Refuted (direct contradiction).
- **Impact:** The two artifacts the research treated as jointly authoritative disagree on a load-bearing point. Recommendation now calls to resolve this in favor of the spec + verified skill behavior before a driver consumes the catalog.

### V3: `content-auditor` + `information-architect` "suffice unattended" for the fix loop

- **Strategy:** Challenge the Fix.
- **Investigation:** Compared the driver's fail-closed verdict parser (`review-verdict-contract.md`, halts on missing `RECOMMENDATION`) against the two agents' actual output (Present/Correctly-Removed/Missing; Blocks/Degrades/Friction/Polish). No overlap with the required contract.
- **Result:** Refuted.
- **Impact:** The largest actionable finding. "Documentation has unattended reviewers" is true, but they cannot drive the current loop without a new non-code verdict contract or adapter. Elevated to the top prerequisite in the recommendation.

### V4: `guidance` is a valid AFK reviewer for new skills/agents

- **Strategy:** Challenge the Assumptions.
- **Investigation:** Read Guidance Mode (`guidance/SKILL.md:26-50`): it identifies applicable docs and applies them; no findings format, no severity, no verdict.
- **Result:** Refuted.
- **Impact:** The catalog's skill/agent review rows are unusable; they must become "manual read, HITL." Reinforces keeping skills/agents human-reviewed.

### V5: The fix loop reintroduces self-bias by re-reviewing with the same skill

- **Strategy:** Challenge the Assumptions.
- **Investigation:** Read Step 3.4 fix rounds: each round dispatches a fresh `tdd` fix agent and a fresh `code-review` sub-agent; builder and reviewer stay distinct; the fix agent consumes the durable review record as input.
- **Result:** Confirmed (the concern does *not* hold; separation is preserved).
- **Impact:** Strengthens the recommendation's premise — extend the existing pattern to non-code rather than redesign it.

### V6: `refactor` is HITL because it binds its target through user interaction

- **Strategy:** Challenge the Evidence.
- **Investigation:** `refactor/SKILL.md` frontmatter has no `AskUserQuestion`; the target is the invocation argument. The HITL behavior is a *conditional* halt on scope-spread (lines ~50-51), not a mandatory interactive step.
- **Result:** Partially Refuted (conclusion right, mechanism mischaracterized).
- **Impact:** Minor. A well-scoped `refactor` run may complete without halting; a future driver author should model it as conditionally-HITL, not always-HITL.

### V7: O1–O5 exhaust the meaningful option space for non-code review routing

- **Strategy:** Challenge the Options Framing.
- **Investigation:** Read `gap-analyzer.md` fully: domain-agnostic current-vs-desired comparison with an adversarial self-disproof pass — a distinct routing strategy (one spec-anchored gate for all non-code) that had been demoted to a supporting tool.
- **Result:** Partially Refuted.
- **Impact:** Added as **O6** and folded into the recommendation as an alternative to weigh against per-type routing.

### V8: The 2026 arXiv sources are real and accurately summarized; the recommendation depends on them

- **Strategy:** Challenge the Evidence-Gathering Integrity.
- **Investigation:** ~18 web artifacts are arXiv IDs in the 2601–2606 range, unverifiable at the validator's cutoff and suspiciously clustered around the exact sub-questions (e.g. A33 "Semantic Early-Stopping," A47 "Can LLM-as-judge verify rubrics in agentic scenarios"). Ran the discount test: remove all 2026 arXiv sources and keep only pre-2025 papers (A25–A29, A36, A37, A39, A51), production framework docs (A54, A55, A56, A61), and codebase evidence.
- **Result:** Partially Refuted.
- **Impact:** The core recommendation (O5, separated critic, per-type routing, HITL for skills/agents, reference grounding) **survives the discount**. The one claim that does not survive — "post-task sign-off is *more* load-bearing for non-code" — is downgraded to a design judgment. Also flagged a provenance gap: an earlier draft cited "Angle-A finding 7," which is not a registry entry; it has been removed from the evidence basis.

### Adjustments Made

- Added **O6** (gap-analyzer as a universal non-code gate) after V7.
- Rewrote the recommendation to make the **verdict-contract gap (V3)** and the **catalog corrections (V1, V2, V4)** blocking prerequisites rather than incidental notes.
- Downgraded "post-task sign-off more load-bearing for non-code" from a corroborated finding to a **design judgment**, and removed the unlisted "Angle-A finding 7" citation (V8).
- Reclassified ADR/coding-standard/runbook builds as **HITL** throughout, overriding the catalog's AFK label (V1, V2).
- The recommendation was **not** rewritten to "no clear winner": the core direction survived validation and the discount test.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  1. The catalog is the source of truth a future driver reads; it has at least two wrong rows (V1/V2 build-autonomy; V4 skill/agent review). No driver-side logic corrects a wrong catalog.
  2. The verdict-contract incompatibility (V3) is an unmade architectural decision, not a small wiring task — nothing non-code runs in the loop until it is resolved.
  3. Both plan artifacts are untracked and mutually contradictory (V2); neither can be treated as final ground truth yet.
  4. A meaningful share of the external evidence is unverifiable 2026 preprints (V8); conclusions that lean on them (convergence heuristics, the non-code sign-off emphasis) are held as advisory/design judgment.
  5. O6's suitability as a universal non-code gate is untested (V7); choosing it over per-type routing without a trial is a risk.

## Sources

| ID | Source | Link / location | Retrieved | Trust class | Summary (one line) | Evidence status |
|---|---|---|---|---|---|---|
| A1 | implement-work-items build/review dispatch | `han-coding/skills/implement-work-items/SKILL.md:~228-237` | n/a | codebase | Driver dispatches a `tdd` build sub-agent and a distinct `code-review` review sub-agent | corroborated (verified V5) |
| A2 | Review verdict contract | `han-coding/skills/implement-work-items/references/review-verdict-contract.md:~24-89` | n/a | codebase | Fail-closed parser requires RECOMMENDATION/COVERAGE/FINDINGS/BELOW-THRESHOLD/DURABLE-RECORD | corroborated (verified V3) |
| A3 | code-review agent fan-out | `han-coding/skills/code-review/SKILL.md:~125-152` | n/a | codebase | Always junior-developer + security; conditional specialists by file signal | corroborated |
| A4 | Severity calibration by size | `han-coding/skills/code-review/SKILL.md:~170-176` | n/a | codebase | Small→Critical only; Medium→+Warning; Large→all | corroborated |
| A5 | Bounded fix loop | `han-coding/skills/implement-work-items/SKILL.md:~282-329` | n/a | codebase | Up to `--fix-cap` (default 3) Fix→Re-verify→Re-review; halt on cap | corroborated (verified V5) |
| A6 | skill-builder self-review | `han-plugin-builder/skills/skill-builder/SKILL.md:~180-220` | n/a | codebase | Step 6 conformance review is inside the builder (self-review) | corroborated |
| A7 | agent-builder self-review | `han-plugin-builder/skills/agent-builder/SKILL.md:~180-220` | n/a | codebase | Same self-review pattern for agents | corroborated |
| A8 | content-auditor | `han-core/agents/content-auditor.md:~43-102` | n/a | codebase | Reference-grounded fact audit (Present/Correctly-Removed/Missing) validated via Grep | corroborated (format gap V3) |
| A9 | information-architect | `han-core/agents/information-architect.md:~179-282` | n/a | codebase | Rubric IA audit; `IA-###` findings with location/severity/remediation | corroborated (format gap V3) |
| A10 | gap-analyzer | `han-core/agents/gap-analyzer.md:~128-161` | n/a | codebase | Current-vs-desired `GAP-###` findings + adversarial self-disproof pass | corroborated (basis for O6, V7) |
| A11 | junior-developer | `han-core/agents/junior-developer.md` | n/a | codebase | Artifact-review over plans/ADRs/standards; flags assumptions + standards conflicts | corroborated |
| A12 | project-documentation content audit | `han-core/skills/project-documentation/SKILL.md:~82-90` | n/a | codebase | Step 6 dispatches content-auditor, restores Missing facts | corroborated |
| A13 | project-documentation IA review | `han-core/skills/project-documentation/SKILL.md:~92-98` | n/a | codebase | Step 7 dispatches information-architect, applies edits | corroborated |
| A14 | Deliverable-skill catalog | `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:~14-28` | n/a | codebase | Proposed deliverable→(impl, review) mapping with AFK/HITL | contradicted by A16 (V1, V2, V4) |
| A15 | Feature spec: three signals | `docs/plans/autonomous-driver-per-item-skill-selection/feature-specification.md:~1-8` | n/a | codebase | Three per-item autonomy signals replace the single Type marker | corroborated |
| A16 | Feature spec: autonomy derivation | `docs/plans/autonomous-driver-per-item-skill-selection/feature-specification.md:~26` | n/a | codebase | ADR/coding-standard/runbook/refactor/builders "stop for a human mid-run" | corroborated (verified V1); contradicts A14 |
| A17 | skill-builder interview | `han-plugin-builder/skills/skill-builder/SKILL.md:~68-85` | n/a | codebase | Interview-driven, one question at a time (HITL build) | corroborated |
| A18 | Driver description | `han-coding/skills/implement-work-items/SKILL.md:~3-8` | n/a | codebase | Unattended `tdd` + `code-review` loop | corroborated |
| A19 | refactor is HITL | `han-coding/skills/refactor/SKILL.md:~26-56` | n/a | codebase | HITL via conditional scope-spread halt (not target-binding) | partially refuted (V6) |
| A20 | project-documentation unattended | `han-core/skills/project-documentation/SKILL.md:~21-45` | n/a | codebase | Procedural steps 2-7 run unattended | corroborated |
| A21 | ADR skill | `han-core/skills/architectural-decision-record/SKILL.md:~25-57` | n/a | codebase | Mid-run `AskUserQuestion` at line 57 → build is HITL | refuted as AFK (V1) |
| A22 | guidance modes | `han-plugin-builder/skills/guidance/SKILL.md:~26-50` | n/a | codebase | Guidance Mode only serves docs; no findings/verdict | corroborated (V4) |
| A23 | coding-standard skill | `han-coding/skills/coding-standard/SKILL.md:~21-132` | n/a | codebase | Mid-run `AskUserQuestion` at 89, 132 → build is HITL | refuted as AFK (V1) |
| A24 | runbook skill | `han-core/skills/runbook/SKILL.md:~17-104` | n/a | codebase | Mid-run `AskUserQuestion` at 69, 90, 104 → build is HITL | refuted as AFK (V1) |
| A25 | Self-Refine | https://arxiv.org/abs/2303.17651 | 2026-07-02 | web | Generate→critique→revise loop; gains concentrate in early rounds | corroborated by A26 |
| A26 | Reflexion | https://arxiv.org/html/2303.11366 | 2026-07-02 | web | Verbal self-reflection + max-trial/consecutive-failure stop conditions | corroborated by A25 |
| A27 | Pride & Prejudice (self-bias) | https://arxiv.org/html/2402.11436v2 | 2026-07-02 | web | Same-model self-refinement amplifies self-bias; external critic mitigates | corroborated by A28, A29 |
| A28 | LLM evaluators favor own generations | https://proceedings.neurips.cc/paper_files/paper/2024/file/7f1f0218e45f5414c79c0679633e47bc-Paper-Conference.pdf | 2026-07-02 | web | Judges recognize and prefer their own outputs (NeurIPS 2024) | corroborated by A27 |
| A29 | Self-Preference Bias | https://arxiv.org/pdf/2410.21819 | 2026-07-02 | web | Self-preference correlates with self-recognition, incl. frontier models | corroborated by A27, A28 |
| A30 | Practical Limits of Autonomous Test Repair | https://arxiv.org/abs/2605.01471 | 2026-07-02 | web | Autonomous repair unstable; needs constraints + oversight | single source (caveated; 2026, V8) |
| A31 | 17x Error Trap (multi-agent) | https://towardsdatascience.com/why-your-multi-agent-system-is-failing-escaping-the-17x-error-trap-of-the-bag-of-agents/ | 2026-07-02 | web | Dedicated Evaluator/Critic cuts error amplification 17.2x→4.4x | corroborated by A27 |
| A32 | Steer, Don't Solve (small critic) | https://arxiv.org/abs/2606.21811 | 2026-07-02 | web | Separate small critic steers + shortens trajectories | single source (caveated; 2026, V8) |
| A33 | Semantic Early-Stopping | https://arxiv.org/pdf/2606.27009 | 2026-07-02 | web | Stop on semantic convergence rather than iteration count | single source (caveated; 2026, V8) |
| A34 | Iterative Review-Fix Loops | https://dev.to/yannick555/iterative-review-fix-loops-remove-llm-hallucinations-and-there-is-a-formula-for-it-4ee8 | 2026-07-02 | web | First 2 rounds ~75% of gains; hard cap ~5-6 rounds | single source (caveated) |
| A35 | AWS Evaluator Reflect-Refine | https://docs.aws.amazon.com/prescriptive-guidance/latest/agentic-ai-patterns/evaluator-reflect-refine-loop-patterns.html | 2026-07-02 | web | Generator→Evaluator→Refiner pattern with threshold convergence | corroborated by A25 |
| A36 | CALM: 12 judge biases | https://arxiv.org/abs/2410.02736 | 2026-07-02 | web | Catalogs verbosity/position/self-preference/authority biases in LLM judges | corroborated by A37, A29 |
| A37 | Position bias systematic study | https://aclanthology.org/2025.ijcnlp-long.18.pdf | 2026-07-02 | web | Order-swaps shift pairwise accuracy >10 points | corroborated by A36 |
| A38 | Pointwise/pairwise position bias | https://arxiv.org/pdf/2602.02219 | 2026-07-02 | web | Rubrics reduce but don't eliminate position bias | single source (caveated; 2026, V8) |
| A39 | No Free Labels | https://arxiv.org/html/2503.05061v1 | 2026-07-02 | web | Judge accuracy collapses without a reference; grounding recovers it | corroborated by A36 |
| A40 | Holistic→Structured rubrics survey | https://arxiv.org/html/2606.08625v1 | 2026-07-02 | web | Structured analytic rubrics beat holistic scoring | single source (caveated; 2026, V8) |
| A41 | Autorubric | https://arxiv.org/html/2603.00077v2 | 2026-07-02 | web | Per-criterion binary rubric + multi-judge voting improves agreement | single source (caveated; 2026, V8) |
| A42 | Rubric eval + biases (practitioner) | https://medium.com/@adnanmasood/rubric-based-evals-llm-as-a-judge-methodologies-and-empirical-validation-in-domain-context-71936b989e80 | 2026-07-02 | web | Swap-and-average, cross-family judges, panels to cancel bias | corroborated by A36, A37 |
| A43 | iRULER (actionable findings) | https://arxiv.org/html/2602.12779 | 2026-07-02 | web | Findings must be Specific/Actionable/Scaffolded to drive revision | single source (caveated; 2026, V8) |
| A44 | ReviewGrounder | https://arxiv.org/pdf/2604.14261 | 2026-07-02 | web | Rubric + tool-grounded evidence yields substantive reviews | single source (caveated; 2026, V8) |
| A45 | RubricRAG | https://arxiv.org/html/2603.20882v1 | 2026-07-02 | web | Retrieve domain knowledge to generate query-specific rubrics | single source (caveated; 2026, V8) |
| A46 | Learning to Judge (rubrics) | https://arxiv.org/html/2602.08672v1 | 2026-07-02 | web | LLM rubrics degrade on knowledge-intensive tasks; "evaluation dialects" | single source (caveated; 2026, V8) |
| A47 | LLM-as-judge verify rubrics (agentic) | https://arxiv.org/abs/2606.29920 | 2026-07-02 | web | Frontier judges still noisy; majority voting has diminishing returns | single source (caveated; 2026, V8) |
| A48 | Agentic rubrics as verifiers (SWE) | https://arxiv.org/html/2601.04171v1 | 2026-07-02 | web | Repo-grounded rubrics gate well; 22% low-utility failures | single source (caveated; 2026, V8) |
| A49 | Stability Trap (instruction adherence) | https://arxiv.org/pdf/2601.11783 | 2026-07-02 | web | LLM judges miss violations on complex multi-constraint specs | single source (caveated; 2026, V8) |
| A50 | LLM-as-judge guide | https://www.evidentlyai.com/llm-guide/llm-as-a-judge | 2026-07-02 | web | Detailed rubric + CoT-before-score improves evaluation quality | corroborated by A42 |
| A51 | Qraft fact-checking writing | https://arxiv.org/html/2503.17684v2 | 2026-07-02 | web | Agentic evidence→draft→editorial-review; context preservation is hard | corroborated by A39 |
| A52 | LLMs in Requirements Engineering | https://www.emergentmind.com/topics/large-language-models-llms-in-requirements-engineering | 2026-07-02 | web | LLMs give per-characteristic binary QA on structured text; expert review still needed | corroborated by A40 |
| A53 | Prompt Evaluation Frameworks | https://www.getmaxim.ai/articles/prompt-evaluation-frameworks-measuring-quality-consistency-and-cost-at-scale/ | 2026-07-02 | web | Prompt-quality dimensions + rubric auto-improvement | single source (caveated) |
| A54 | Redis HITL oversight patterns | https://redis.io/blog/ai-human-in-the-loop/ | 2026-07-02 | web | HITL/HOTL/out-of-loop; approval gates, checkpoints, risk tiers | corroborated by A55, A59 (vendor) |
| A55 | LangGraph interrupt()/resume | https://www.langchain.com/blog/making-it-easier-to-build-human-in-the-loop-agents-with-interrupt | 2026-07-02 | web | Pause mid-node, serialize state, resume on human response | corroborated by A56 |
| A56 | Microsoft Agent Framework HITL | https://learn.microsoft.com/en-us/agent-framework/workflows/human-in-the-loop | 2026-07-02 | web | RequestPort checkpoint/resume + tool-approval | corroborated by A55 |
| A57 | Alibaba HITL field experiment | https://arxiv.org/abs/2605.14830 | 2026-07-02 | web | AI-eligible/ineligible classification at intake; parallel human supervision | single source (caveated; 2026, V8) |
| A58 | Decoupled HITL system | https://arxiv.org/abs/2604.23049 | 2026-07-02 | web | Treat HITL oversight as an independent, reusable component | single source (caveated; 2026, V8) |
| A59 | Escalation design / risk tiers | https://www.digitalapplied.com/blog/human-in-the-loop-escalation-design-ai-agents-2026 | 2026-07-02 | web | Classify by consequence not confidence; prefer async escalation | corroborated by A54 |
| A60 | Self-improving coding agents | https://addyosmani.com/blog/self-improving-agents/ | 2026-07-02 | web | Max-iteration/time/idle caps; PR-before-merge human gate | corroborated by A61 |
| A61 | GitHub Copilot coding agent | https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/ | 2026-07-02 | web | Plan-inspect then PR; human approval before CI/CD | corroborated by A60, A62 |
| A62 | Professionals "don't vibe, they control" | https://arxiv.org/abs/2512.14012 | 2026-07-02 | web | Devs review plans, intervene mid-run, hold architectural calls | corroborated by A61 |

### A1: implement-work-items build/review dispatch — recommendation-bearing

- **Link / location:** `han-coding/skills/implement-work-items/SKILL.md:~228-237`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** The driver dispatches a build sub-agent (general-purpose running `tdd`) at Step 3.1 and a distinct review sub-agent (running `code-review`) at Step 3.3, both via the Agent tool. This is the separated-critic architecture the recommendation says to preserve for non-code items.
- **Evidence status:** corroborated; separation across all fix rounds verified in Validation V5.

### A2: Review verdict contract — recommendation-bearing

- **Link / location:** `han-coding/skills/implement-work-items/references/review-verdict-contract.md:~24-89`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** The review sub-agent must return exactly `RECOMMENDATION`, `COVERAGE`, `FINDINGS (at and above the gate threshold: critical|warning)`, `BELOW THRESHOLD`, `DURABLE RECORD`; the parser is fail-closed and halts on a missing/empty section. Because Han's documentation reviewers do not emit this shape, closing this gap is the top prerequisite in the recommendation.
- **Evidence status:** corroborated; incompatibility with A8/A9 verified in Validation V3.

### A5: Bounded fix loop — recommendation-bearing

- **Link / location:** `han-coding/skills/implement-work-items/SKILL.md:~282-329`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** The loop runs up to `--fix-cap` (default 3) rounds of Fix → Re-verify → Re-review, gate default `warning`, halting when the cap is reached with the gate uncleared. This bounded-retry-then-escalate design is what the prior art endorses and what the recommendation keeps for non-code.
- **Evidence status:** corroborated by A25, A26; separation preserved per V5.

### A8: content-auditor — recommendation-bearing

- **Link / location:** `han-core/agents/content-auditor.md:~43-102`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Extracts atomic facts from the original source, classifies each as Present / Correctly Removed / Missing in the new document, validates removals against the codebase with Glob/Grep, and returns numbered audit items. It is Han's reference-grounded documentation reviewer — the strongest available match to the "check claims against a trusted reference" pattern — but its output format does not match the driver's verdict contract (see A2, V3).
- **Evidence status:** corroborated on capability; loop-format gap verified in V3.

### A9: information-architect — recommendation-bearing

- **Link / location:** `han-core/agents/information-architect.md:~179-282`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Audits a document against named IA principles and returns numbered `IA-###` findings with principle, location, evidence, reader impact, severity (Blocks/Degrades/Friction/Polish), and remediation. Han's rubric-style documentation reviewer, running unattended; also format-incompatible with the driver's contract (A2, V3).
- **Evidence status:** corroborated on capability; loop-format gap verified in V3.

### A10: gap-analyzer — recommendation-bearing

- **Link / location:** `han-core/agents/gap-analyzer.md:~128-161`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Compares a current state against a desired state and returns `GAP-###` findings (Missing/Partial/Divergent/Implicit) with an evidence pair, running its own adversarial self-disproof pass. Applied with the work item's acceptance criteria as the desired state, it is the basis for O6 — a single, domain-agnostic, spec-anchored non-code gate.
- **Evidence status:** corroborated that the agent exists and is spec-anchored; universal-gate suitability untested (V7).

### A14: Deliverable-skill catalog — recommendation-bearing

- **Link / location:** `han-planning/skills/plan-work-items/references/deliverable-skill-catalog.md:~14-28`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** The proposed mapping from deliverable nature to a (implementation, review) pair with AFK/HITL markers. The research must interrogate rather than trust it: it marks ADR/coding-standard/runbook builds AFK (contradicted by A16 and the skills themselves) and names `guidance` as an AFK reviewer for skills/agents (contradicted by A22). These rows must be corrected before a driver consumes the catalog.
- **Evidence status:** contradicted by A16 and A22; corrections specified in Validation V1, V2, V4.

### A16: Feature spec autonomy derivation — recommendation-bearing

- **Link / location:** `docs/plans/autonomous-driver-per-item-skill-selection/feature-specification.md:~26`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** States that `tdd`, `project-documentation`, and `guidance` run unattended while `refactor`, `skill-builder`, `agent-builder`, `architectural-decision-record`, `runbook`, and `coding-standard` "stop for a human mid-run," and that review autonomy is derived per reviewer. Direct inspection of the skills confirms this over the catalog's AFK labels.
- **Evidence status:** corroborated (verified V1); contradicts A14.

### A22: guidance modes — recommendation-bearing

- **Link / location:** `han-plugin-builder/skills/guidance/SKILL.md:~26-50`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Guidance Mode identifies and applies the relevant authoring docs and cites them; it produces no numbered findings, no severity, and no verdict. It therefore cannot serve as the automated reviewer the catalog assigns for new skills and agents — those items have no separate findings-emitting reviewer and should stay human-reviewed.
- **Evidence status:** corroborated (verified V4).

### A27: Pride & Prejudice — self-bias in self-refinement — recommendation-bearing

- **Link / location:** https://arxiv.org/html/2402.11436v2
- **Retrieved:** 2026-07-02
- **Trust class:** web (outside the trust boundary)
- **Summary:** Same-model self-refinement amplifies self-bias: models inflate scores for their own outputs and optimize for false-positive corrections while task quality stalls; an external evaluator or a different model mitigates it. This is the core justification for the builder≠reviewer invariant and survives the discard of unverifiable 2026 sources (dated Feb 2024).
- **Evidence status:** corroborated by A28, A29.

### A39: No Free Labels — recommendation-bearing

- **Link / location:** https://arxiv.org/html/2503.05061v1
- **Retrieved:** 2026-07-02
- **Trust class:** web (outside the trust boundary)
- **Summary:** LLM-judge alignment with humans collapses on questions the judge cannot itself answer (one study: 0.78→0.14) and is largely recovered by providing a verified reference; reference correctness matters more than authorship. This underpins the recommendation to prefer reference-grounded review for non-code; dated Mar 2025, it survives the 2026-source discount.
- **Evidence status:** corroborated by A36.

### A55: LangGraph interrupt()/resume — recommendation-bearing

- **Link / location:** https://www.langchain.com/blog/making-it-easier-to-build-human-in-the-loop-agents-with-interrupt
- **Retrieved:** 2026-07-02
- **Trust class:** web (outside the trust boundary)
- **Summary:** Documents the pause-serialize-resume HITL primitive: a workflow interrupts at a node, saves full state, waits for a human (approve/modify/reject), and resumes from the checkpoint, consuming no compute while idle. This is the mechanism behind the recommendation's async-parking of gated items; a stable production-framework source unaffected by the 2026-preprint concern.
- **Evidence status:** corroborated by A56.

### A61: GitHub Copilot coding agent — recommendation-bearing

- **Link / location:** https://github.blog/news-insights/product-news/github-copilot-meet-the-new-coding-agent/
- **Retrieved:** 2026-07-02
- **Trust class:** web (outside the trust boundary)
- **Summary:** A production agent plans, implements on a branch, and opens a draft PR; a human must approve before CI/CD runs. This is the post-task sign-off gate the recommendation applies to items with no trustworthy automated reviewer; a stable, verifiable source.
- **Evidence status:** corroborated by A60, A62.
