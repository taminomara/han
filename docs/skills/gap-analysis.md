# /gap-analysis

Operator documentation for the `/gap-analysis` skill in the han plugin. This document helps humans decide *when* and *how* to use the skill. For what the skill does internally, read the skill definition at [`plugins/han/skills/gap-analysis/SKILL.md`](../../skills/gap-analysis/SKILL.md).

> See also: [Plugin landing page — han](../../README.md) · [All skills](./README.md) · [All agents](../agents/README.md)

## TL;DR

- **What it does:** Compares two artifacts (a current state and a desired state) and produces a plain-language, stakeholder-readable report indexed by stable gap IDs.
- **When to use it:** You have a spec, PRD, design, or requirements doc and want to know how an implementation (or another artifact) measures up — and you want a report a non-engineer can read.
- **What you get back:** `gap-analysis-report.md` (four-section progressive-disclosure structure) plus the underlying `gap-analysis-source.md` written by the `gap-analyzer` agent.
- **Size-aware:** The skill classifies the analysis as small / medium / large, defaults to small (no swarm), and recommends a swarm composition proportional to the gap count and domain spread. Pass the size as the first positional argument to override (`/gap-analysis large`). See [Sizing](#sizing).

## Key Concepts

- **Plain language by default.** Sections 1 and 2 of the report contain no file paths, line numbers, function names, or library mechanics. Technical fidelity is quarantined to Section 3 and is only added when the user explicitly opts in.
- **Stable `G-NNN` gap IDs.** Every gap gets a citable ID assigned in discovery order. Tickets, threads, and follow-up reports reference the IDs; Sections 3 and 4 cross-reference them without restating the plain-language explanation.
- **The swarm is opt-in.** By default the report rests on `gap-analyzer` alone. The skill recommends a swarm composition sized to the analysis (small / medium / large) but never runs one without the user's explicit opt-in.
- **Four sections, progressively disclosed.** Executive Summary → Indexed Gaps → optional Technical Details → optional Swarm Findings. Reading stops anywhere; what came before stands on its own. Optional sections are physically omitted when not requested, not collapsed.
- **IA-designed template.** The report template was designed by `information-architect` against Rosenfeld & Morville's four IA systems, DITA topic typing, LATCH, Mark Baker's "Every Page is Page One", John Carroll's minimalism, JoAnn Hackos's audience-task mapping, and Dan Brown's 8 Principles of IA. The template lives at [`gap-analysis-report-template.md`](../../skills/gap-analysis/references/gap-analysis-report-template.md).

## When to Use It

**Invoke when:**

- You have a spec, PRD, requirements doc, or design and want to compare it against an implementation, a shipped feature, or another artifact — "what's missing from X compared to Y," "does the auth module satisfy the auth spec," "did the v3 launch ship everything in the PRD."
- The audience is mixed — product managers, engineering leads, designers, auditors, stakeholders — and the deliverable needs to be a plain-language report rather than raw analyst output with file paths and code identifiers.
- You want a stable, citable index of gaps. Each gap gets a `G-NNN` ID you can reference in tickets, threads, and follow-up work; the IDs are append-only across sections of the same report.
- You want optional adversarial validation and domain augmentation of the gap list before it goes to stakeholders — opt in to the swarm and the skill recommends a team sized to the analysis.
- The user only named one artifact and a comparison target is implied (e.g., "is the auth implementation complete," "what's missing from this feature"). The skill resolves the implied artifact from the project's documentation root, codebase, and prior context.
- The user explicitly asks for a *bidirectional* analysis (current ↔ desired) rather than the default unidirectional pass (current → desired).

**Do not invoke for:**

- **Investigating runtime bugs or failures.** Use [`/investigate`](./investigate.md) for evidence-based root-cause work on a bug. This skill compares artifacts; it does not trace data flow or error paths to a defect.
- **Reviewing code correctness, style, or security.** Use [`/code-review`](./code-review.md) for a comprehensive code review of a branch or files, or [`/gh-pr-review`](./gh-pr-review.md) to post the review to a GitHub PR. This skill does not assess correctness of implementation independent of a desired-state artifact.
- **Architectural assessment of an existing module.** Use [`/architectural-analysis`](./architectural-analysis.md) for coupling, data flow, concurrency, risk, and SOLID alignment of a module. This skill compares a module against a target spec; it does not assess the module on its own architectural merits.
- **Iterating on a plan that already exists.** Use [`/iterative-plan-review`](./iterative-plan-review.md) for multi-pass review of a plan you already drafted. This skill compares two artifacts; it does not refine a single plan in place.
- **Auditing whether documentation updates preserved important content.** Use the [`content-auditor`](../agents/README.md#gap--content) agent directly when the question is "did the rewrite drop facts the original carried." This skill compares two distinct artifacts; `content-auditor` validates a single artifact across a before-and-after.
- **Single-artifact analysis with no comparison target, even implied.** If there is genuinely no second artifact and no implied target, the work is documentation, investigation, or architectural — pick the matching skill instead.

## How to Invoke It

Run `/gap-analysis` in Claude Code. Point it at the two artifacts in the same message, or describe them — paths, URLs, or inline text all work.

Give it:

1. **The current state.** What exists today: a code directory, a file, a URL, or inline text. Examples: `src/auth/`, `docs/features/bulk-export/feature-implementation-plan.md`, `https://staging.example.com/api/users`. The skill defaults to treating the first input as the current state.
2. **The desired state.** What is expected: a spec, a PRD, a design doc, a requirements file, a URL, or inline text. Examples: `docs/specs/auth.md`, `https://wiki.example.com/PRD-v3`, `docs/features/bulk-export/feature-specification.md`. The skill defaults to treating the second input as the desired state.
3. **Scope, optional.** A bounded region to compare (a specific subsystem, feature, section, or capability). Without a scope, the `gap-analyzer` agent identifies the comparison areas itself by reading both inputs.
4. **Mode overrides, optional.** By default the skill runs no swarm and no technical details. If you already know you want the swarm or the technical-details section, say so up front: "run a medium swarm" or "include technical details" — the skill skips the confirmation step. If you want a specific swarm size or specific specialists named, say so.
5. **Direction override, optional.** The default direction is current → desired (what does the implementation lack relative to the spec). If you want the analysis reversed (what does the spec lack relative to the implementation — scope creep, undocumented capabilities) or fully bidirectional, say so.

Example prompts that work well:

- `/gap-analysis docs/specs/auth.md src/auth/` — Compare the auth spec to the auth implementation. Default modes: no swarm, plain language only.
- `/gap-analysis` — "Compare what we shipped in the bulk-export feature to what the PRD called for. Run a medium swarm; the result is going to the steering committee on Friday."
- `/gap-analysis docs/features/checkout/feature-specification.md src/checkout/` — "Plain-language report only. We just need to know the shape of the gap before we plan remediation."
- `/gap-analysis` — "Compare the v2 PRD at `docs/prd-v2.md` against the v3 PRD at `docs/prd-v3.md`. Bidirectional — we need to see what was added *and* what was dropped."
- `/gap-analysis docs/specs/billing.md src/billing/ --include-technical` — "Run the swarm and include technical details; engineers need to act on this."

The skill states the resolved comparison direction, the chosen size class, the recommended swarm composition, and the chosen modes in a short message before launching `gap-analyzer`. If you want to correct any of those, say so and the skill adjusts before proceeding.

## What You Get Back

Two files on disk plus an in-channel summary:

- The **`gap-analysis-report.md`** — the stakeholder-readable artifact. Four sections, progressively disclosed:
  - **Section 1 — Executive Summary.** Plain-language verdict on overall alignment, a magnitude-at-a-glance table broken down by category (Missing / Partial / Divergent / Implicit), 3-5 bullets describing the *shape* of the gap thematically, a "what this means for the work ahead" paragraph, and a pointer to subsequent sections.
  - **Section 2 — Indexed Gaps.** A scan-view index table mapping gap IDs to plain-language titles and categories, followed by one self-contained entry per gap. Each entry has plain-language `Expected` and `Current` descriptions, a `Why it matters` paragraph, and a `Confidence` field (High / Medium / Low) with a one-sentence reason.
  - **Section 3 — Technical Details** *(included only when requested).* Per-gap technical fidelity: `Locations` (file paths, anchors), `Relevant identifiers` (function, class, module names), `Specifics of the divergence`, `Remediation direction`, `Effort signal` (Trivial / Small / Medium / Large / Unknown), `Risks / dependencies`. Cross-references to Section 2 by `G-NNN` ID.
  - **Section 4 — Swarm Findings** *(included only when a swarm ran).* Confirmations, Contradictions, and Augmentations from the swarm, grouped by signal type and cross-referenced by `G-NNN` ID. Confidence summary table grouping gaps as High / Medium / Low based on swarm corroboration.
- The **`gap-analysis-source.md`** — the `gap-analyzer` agent's full structured output, written alongside the report. Contains `GAP-NNN` entries with evidence pairs (file paths and line numbers, document section headings, URL excerpts) and the analyzer's category classifications. The skill maps `GAP-NNN` to `G-NNN` in the report; the source file is preserved for engineers who need the raw evidence to act on a gap.
- An **in-channel summary** with the report path, the source file path, the size class, the modes used, the gap count broken down by category, and any open recommendations (e.g., "the swarm contradicted three gaps — adjudicate before remediation," or "two `proposed_new_gap` entries were surfaced by the swarm and added to the report").

The two files interlock through shared IDs. Every `G-NNN` in the report maps back to a `GAP-NNN` in the source file; every cross-reference in Sections 3 and 4 of the report names a `G-NNN` from Section 2.

The default report (no swarm, plain language only) is the smallest viable artifact: Sections 1 and 2 alone, with the front-matter `sections_included` field listing only those two. Adding Section 3 or 4 augments the report; it never changes the meaning of Sections 1 and 2.

## How to Get the Most Out of It

- **Be explicit about which is current and which is desired.** The default direction is current → desired (what's missing from the implementation relative to the spec). Reversing the direction yields a different finding shape — scope creep, undocumented capabilities, drift in the desired-state artifact. Name the direction up front when it matters.
- **Trust the lightweight default for first-pass scoping.** Default modes (no swarm, plain language only) produce a stakeholder-readable report quickly and cheaply. Run that first; opt in to the swarm and technical details once you know the gap list will drive remediation work.
- **Opt in to the swarm when stakeholders need confidence signals.** A bare `gap-analyzer` pass produces gaps with `Medium` confidence by default — confidence rests on the analyzer alone. The swarm produces `High` (multi-agent corroborated) and `Low` (contradicted) confidence signals that change how stakeholders prioritize. If the report is going to a steering committee or driving a multi-week remediation, the swarm cost is worth it.
- **Match swarm size to the analysis, not the calendar.** The skill recommends small (lightweight, no swarm), medium (3-4 agents), or large (4-5 agents) based on gap count, distribution across categories, and the domains the gaps touch. Override the recommendation only when you have a specific reason (e.g., the analysis touches auth even though only two gaps were found — promote to medium and include `adversarial-security-analyst`).
- **Name specialists you know you want.** If gaps cluster in a single domain — auth, data, UX, deployment, architecture — naming the matching specialist (`adversarial-security-analyst`, `data-engineer`, `user-experience-designer`, `devops-engineer`, `software-architect`, `system-architect`) ensures they are included regardless of what the heuristic would have picked. The two required swarm roles (`adversarial-validator`, `evidence-based-investigator`) are always there.
- **Pair with `/plan-implementation` downstream.** Once a gap analysis identifies the gaps, `/plan-implementation` produces a committable plan to close them. The pairing is natural — the gap report's Section 2 IDs become work items in the implementation plan; Section 3 (when present) feeds the technical detail straight into the plan's Implementation Approach section.
- **Pair with `/iterative-plan-review` upstream.** When the desired-state artifact is itself a plan you don't yet trust, run `/iterative-plan-review` on it first. A gap analysis against a flawed desired-state produces flawed gaps. Hardening the desired-state before comparing pays for itself.
- **Re-run after the spec or implementation changes.** A gap analysis is a point-in-time artifact; it does not auto-refresh. After the implementation closes gaps (or after the spec changes), re-run the skill — the new report's `G-NNN` IDs are independent of the prior run's. The prior report stays valid as a snapshot.
- **Use bidirectional mode when the desired-state artifact is itself drifting.** Bidirectional analysis catches the *current state has capabilities the desired state never specified* failure mode — scope creep, undocumented behavior, capabilities that were shipped without an explicit spec. The default unidirectional pass misses this entirely.
- **Read Section 1 even if you wrote it.** The IA-designed template is structured so a stakeholder reading only Section 1 has a complete (low-resolution) understanding of the gap. Use it as a sanity check on your own framing — if Section 1 doesn't read well to a non-technical audience, the executive-summary translation step in the skill needs adjusting and you should re-run with a sharper prompt.

## Sizing

Size determines the swarm-recommendation the skill presents to the user. The skill defaults to small (no swarm) and only recommends a larger swarm when concrete signals require it.

| Size | Gap count | Domain signals | Recommended swarm |
|---|---|---|---|
| **Small** *(default)* | 0–3 total gaps | Single domain (one feature, one module, one document section); no security / data / cross-service / architectural signals in any gap. | None (lightweight). The bare `gap-analyzer` pass stands on its own. |
| **Medium** | 4–10 total gaps | Two or three adjacent domains; may touch one cross-cutting concern (a single auth surface, a single integration boundary, a single data-contract change). | 3–4 agents — `adversarial-validator` and `evidence-based-investigator` always, plus 1–2 domain specialists. |
| **Large** | 11+ total gaps | Cross-cutting concerns across multiple domains (security + data + architecture, or cross-service integration), or the user explicitly requested a full swarm. | 4–5 agents — required two plus 2–3 domain specialists matched to what the gaps touch. |

How the size is chosen:

- **Default to small.** Unless the gap count or domain signals push the analysis higher, the skill stays at small and proceeds with no swarm by default.
- **Domain-driven specialist selection.** When a swarm is recommended, augmenters are drawn from `adversarial-security-analyst`, `data-engineer`, `user-experience-designer`, `devops-engineer`, `system-architect`, `software-architect`, `content-auditor`, `codebase-explorer`, `junior-developer` based on which domains the gaps actually touch.
- **The swarm is opt-in.** No swarm runs by default at any size. The skill states the recommendation; the user opts in (or doesn't).

How to override the size:

- Pass `small`, `medium`, or `large` as the first positional argument: `/gap-analysis medium`, `/gap-analysis large docs/specs/auth.md src/auth/`.
- When the size is overridden via `$size`, the skill announces the override (`Medium: passed via $size`) and uses the chosen band for the swarm-composition recommendation.
- Conversational overrides ("run a medium swarm anyway") still work and are equivalent.

For the cross-skill sizing model and design principles, see [Sizing](../sizing.md).

## Cost and Latency

The skill is structured for low-cost first-pass and opt-in deepening. The default run is the cheapest artifact the skill can produce; every additional mode is a deliberate, named cost.

- **Default mode (no swarm, plain language only).** A single `gap-analyzer` dispatch (opus) plus the skill's in-process rendering of Sections 1 and 2 from the analyzer's source file. No additional sub-agents. Lowest-cost configuration; appropriate for first-pass scoping and stakeholder reports where confidence signals are not yet needed.
- **Technical details mode (Section 3 added).** No additional sub-agents. Section 3 is rendered by the skill from the `gap-analyzer`'s existing structured output — file paths, identifiers, and divergence specifics already in the source file. Cost equals the default mode plus a marginal rendering pass.
- **Swarm mode (Section 4 added).** A single fan-out of three to five sub-agents in parallel, each running on its own default model (most han analysis agents default to `sonnet`; specialists like `adversarial-validator` and `evidence-based-investigator` follow their definitions). The swarm is one round, not iterative — the skill does not loop the swarm against itself. Expect three to five concurrent sub-agent dispatches plus the `gap-analyzer` and the skill-side consolidation. For a medium-size analysis with the recommended team, this typically lands in the four-to-six total sub-agent dispatch range.
- **Both modes together (Sections 3 and 4 added).** The combined cost is the swarm mode cost plus the marginal Section-3 rendering pass — the skill does not re-dispatch `gap-analyzer` when adding either or both optional sections.

The skill is built for periodic, decision-point analysis (before a steering committee, before a remediation plan, after a release) — not for tight-loop iteration on the same comparison within a single session. Re-running the skill is appropriate after a spec or implementation has materially changed; running it repeatedly against the same inputs in the same session does not produce new insight.

## In more detail

The skill's input is two artifacts and its output is a stakeholder-readable report. The judgment-heavy work — identifying comparison areas, mapping correspondences, classifying gaps into the Missing / Partial / Divergent / Implicit taxonomy, gathering evidence pairs from both inputs — happens inside the `gap-analyzer` agent. The skill orchestrates that agent, optionally adds a validator/augmenter swarm, then translates the analyzer's structured output into the IA-designed template.

**Default-no-swarm posture.** The swarm is opt-in for two reasons. First, the bare `gap-analyzer` pass is high-quality and self-contained — every gap finding requires an evidence pair from both inputs, and the agent runs an adversarial self-check in Step 5 of its own protocol before reporting any gap. Second, the swarm exists to produce *confidence signals* (High / Medium / Low) that change how stakeholders prioritize, not to produce new gaps. If the analysis is for first-pass scoping and confidence is not yet a decision input, the swarm is an avoidable cost. The skill states the recommended team for the analysis size so the user can make the call with the recommendation in front of them, but the default is always "proceed without."

**Sizing rule.** Small analyses (0-3 gaps, single domain, no security / data / cross-service signals) run lightweight by default — no swarm. Medium analyses (4-10 gaps, two or three adjacent domains, may touch one cross-cutting concern) recommend a 3-4 agent swarm. Large analyses (11+ gaps, multi-domain cross-cutting concerns, security or data implications, or explicit user request) recommend a 4-5 agent swarm. The required swarm roles when one runs are `adversarial-validator` (attacks gap-analyzer's findings with counter-evidence) and `evidence-based-investigator` (verifies each gap against the actual current state). Augmenters are drawn from the standard han specialist roster based on what the gaps actually touch.

**Plain-language translation.** The `gap-analyzer` agent produces structured output rich in technical detail — file paths, line numbers, document anchors, code identifiers. The skill's render step translates each gap's `Expected`, `Current`, and `Why it matters` content into plain language for Sections 1 and 2 by stripping every code or document-mechanic reference and replacing it with a capability-or-behavior description. Technical fidelity is preserved in `gap-analysis-source.md` and, when the user opts in, surfaces in Section 3 with full evidence pairs intact.

**Append-only `G-NNN` IDs.** Gap IDs are assigned in the order the analyzer surfaced the gaps, including any `proposed_new_gap` entries the swarm added. IDs are stable for the life of the report and not renumbered if a re-run produces a different gap set — re-running creates a new report, with its own ID space, rather than editing the prior report in place.

**Optional sections are physically omitted.** When Section 3 or Section 4 is not requested or generated, the skill removes the section from the rendered output entirely (and removes the corresponding `sections_included` entry from the front matter). The "How to Read This Report" frame at the top of the template is rewritten to reflect what was included so a reader is never promised a section that does not exist.

## Sources

The skill draws on two distinct provenance lines: the gap-analysis vocabulary itself, and the IA frameworks the report template was designed against.

### Gap-analysis taxonomy and protocol

The four-category taxonomy (Missing / Partial / Divergent / Implicit) and the evidence-pair requirement come from the `gap-analyzer` agent's protocol, which is itself grounded in software-engineering specification practice. The taxonomy is the agent's own vocabulary; the skill renders gap entries using that taxonomy verbatim because translating "Missing" or "Partial" into looser language would degrade the precision a stakeholder needs to decide what kind of remediation each gap requires.

URL: see [`gap-analyzer` agent definition](../../agents/gap-analyzer.md)

### Rosenfeld & Morville — *Information Architecture* (4th edition)

The four IA systems — organization, labeling, navigation, search — are the foundation of the report's structure. The four-section progressive-disclosure design is an *organization system*; the gap categories and severity vocabulary are a *labeling system*; the index table at the top of Section 2 plus the `G-NNN` cross-references throughout Sections 3 and 4 form the *navigation system*; the stable, append-only IDs make `Cmd-F` search durable across the report's lifetime.

URL: https://www.oreilly.com/library/view/information-architecture-4th/9781491913529/

### JoAnn Hackos — Audience-Task Mapping and DITA Topic Typing

Hackos's audience-and-task mapping informs the section split. Section 1 serves stakeholders doing a triage task; Section 2 serves PMs and leads doing a discuss-and-prioritize task; Section 3 serves engineers doing an implement task; Section 4 serves anyone doing a trust-and-adjudicate task. DITA's concept / task / reference distinction informs the topic-type discipline within sections — Section 1 is concept, Section 2 is a reference list of concept entries, Section 3 is reference + task, Section 4 is reference.

URL: https://www.xmlpress.net/publications/dita-third-edition/

### Mark Baker — *Every Page is Page One* (EPPO)

Baker's EPPO discipline shapes the per-gap entry format in Section 2. Each entry is self-contained — a reader landing on a single gap via search or a deep link gets oriented (what it is, what was expected vs. current, why it matters, how confident we are) without needing to read the rest of the report. The "How to Read This Report" frame at the top of the template is the EPPO orientation for cold arrivals to the report itself.

URL: https://everypageispageone.com/

### Richard Saul Wurman — LATCH

Wurman's LATCH (Location, Alphabet, Time, Category, Hierarchy) framework drove the choice of indexing scheme for gaps. The IDs use the *Location* / sequence dimension (assigned in discovery order, append-only, stable for the report's life) rather than *Category* (Missing/Partial/Divergent/Implicit) because grouping by category fragments the index and prevents a single citable list. Category appears as a *facet* on each entry, not as the grouping axis.

URL: https://www.wurman.com/books/

### John Carroll — Minimalism

Carroll's minimalism principles inform the template's "no throat-clearing" stance. There is no meta-introduction; the "How to Read" frame replaces it. Tables replace prose where lookup is the task. Optional sections are physically omitted (not collapsed) when they are not generated, so a reader scanning the report never reads "Section 3 was not included" when they could read nothing instead.

URL: https://mitpress.mit.edu/9780262531313/the-nurnberg-funnel/

### Dan Brown — *Eight Principles of Information Architecture*

Brown's principle of Disclosure underpins the section ordering and the optional-section placement. Sections 1 and 2 are load-bearing; Sections 3 and 4 sit *below* them so removing the optional sections never breaks the sections above. The principle of Multiple Classification supports the indexing decision — each gap is *classified* by category but *located* by sequence ID, so readers who want to scan by category use the index table, and readers who want to cite a gap use the ID.

URL: https://eightprinciples.com/

### Adversarial Review and Devil's Advocate Practice

The opt-in swarm's role mirrors the same red-team / devil's-advocate practice that powers `/code-review` and `/iterative-plan-review` team mode. `adversarial-validator` attacks each `gap-analyzer` finding with counter-evidence; `evidence-based-investigator` verifies each gap against the actual current state. Augmenters add domain context the generalist gap-analyzer may have missed. The pattern is documented in Klein's pre-mortem literature and the broader red-teaming tradition.

URLs: https://hbr.org/2007/09/performing-a-project-premortem and https://en.wikipedia.org/wiki/Red_team

## Related Documentation

- [Plugin landing page — han](../../README.md) — The front door. Start here if you arrived from outside the docs tree.
- [Skills Index](./README.md) — All 15 skills, grouped by purpose.
- [Sizing](../sizing.md) — The cross-skill sizing model. Explains the small / medium / large bands, the default-to-small rule, and the `$size` override.
- [`gap-analyzer`](../../agents/gap-analyzer.md) — The agent that performs the underlying gap analysis. The skill always dispatches it once and reads its full output.
- [`adversarial-validator`](../../agents/adversarial-validator.md) — Required swarm role when the swarm runs. Attacks each gap with counter-evidence to produce per-gap `confirmed` / `contradicted` / `inconclusive` verdicts.
- [`evidence-based-investigator`](../../agents/evidence-based-investigator.md) — Required swarm role when the swarm runs. Verifies each gap against the actual current state with file-level evidence.
- [`information-architect`](../agents/information-architect.md) — The agent that designed the report template. The template is a one-time IA design output; the agent is not dispatched at runtime.
- [`/iterative-plan-review`](./iterative-plan-review.md) — Pair upstream when the desired-state artifact is itself a plan you do not yet trust. Hardening the desired state before comparing produces sharper gaps.
- [`/plan-implementation`](./plan-implementation.md) — Pair downstream when the gap report will drive remediation work. The gap report's Section 2 IDs become work items; Section 3 (when present) feeds the implementation plan's Implementation Approach.
- [`/investigate`](./investigate.md) — The sibling skill for runtime bug investigation. Use `/investigate` when the question is "why is this broken;" use `/gap-analysis` when the question is "how does this compare to what was specified."
- [`/code-review`](./code-review.md) — The sibling skill for code-level quality review. Use `/code-review` when the question is about correctness, style, or security; use `/gap-analysis` when the question requires a comparison against a specification.
- [Report template](../../skills/gap-analysis/references/gap-analysis-report-template.md) — The IA-designed template the skill renders. The template's front matter, "How to Read This Report" frame, and section structure are the canonical reference for the report's shape.
- [coverage-rule.md](../templates/coverage-rule.md) — The criteria that decide which skills get a long-form doc. `/gap-analysis` qualifies on multiple modes (lightweight / swarm), multiple artifacts (report + source file), dispatches other agents, named pairings, user-reachable, and non-trivial provenance.
