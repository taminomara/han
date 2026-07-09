# Decision Log: Skill and Agent Review

This file records every decision settled while specifying Skill and Agent Review. Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the history, rationale, evidence, and rejected alternatives.

## Trivial decisions

- D1: Entity is a skill — the review is a fixed pipeline (resolve target, ground against guidance, run passes, dispatch, classify, output), which the entity taxonomy classifies as a skill under "can I flowchart every path?" (considered an agent; rejected because the review has no open-ended judgment loop, and its base, code-review, is itself a skill). — Referenced in spec: Outcome.
- D11: The review runs unattended with no mid-run human gate — findings are surfaced only at the end, so the same run serves an operator and an automated caller (considered pausing to ask the operator to clarify ambiguous findings; rejected because a mid-run gate would make the review undispatchable by an automated caller, and code-review sets the precedent of no `AskUserQuestion`). — Referenced in spec: User Interactions.
- D12: The report structure mirrors code-review's — a summary table, a single recommendation, and severity-ordered finding sections. — Referenced in spec: Outcome, User Interactions.
- D13: The skill is homed in the plugin-building plugin, alongside skill-builder, agent-builder, and guidance (considered homing it near code-review in the coding plugin; rejected because the rubric it grounds against and its nearest siblings both live in the plugin-building plugin). — Referenced in spec: Outcome.
- D14: Hooks and plugin/marketplace configuration are out of scope for this feature — the stated need is skills and agents. — Referenced in spec: Out of Scope, Deferred (YAGNI).

## Full decisions

### D2: Review scope is skills and agents only

- **Question:** What artifact types does this review cover, and what does it deliberately leave to other tools?
- **Decision:** The review covers skills and agents. Documentation, application code, hooks, and plugin configuration are out of scope.
- **Rationale:** The user framed the feature as "reviewing other skills and agents." Documentation already has capable reviewers, and application code has code-review, so covering them would duplicate existing tools and blur the boundary a reader routes on.
- **Evidence:** User request; the groundwork research names `han-core:content-auditor` and `han-core:information-architect` as documentation reviewers and `han-coding:code-review` as the code reviewer (`docs/plans/autonomous-driver-per-item-skill-selection/research/reviewing-non-code-work-items.md`, sources A3–A4, A8–A9); code-review's own description draws the same boundaries.
- **Rejected alternatives:**
  - Include documentation review — rejected because content and IA reviewers plus the documentation skills already cover it, and the driver already routes documentation to them.
  - Include application-code review — rejected because that is code-review's job.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D5, D14
- **Referenced in spec:** Edge Cases and Failure Modes, Out of Scope

### D3: Dual consumer, human-invocable and driver-consumable

- **Question:** Is this review only for an operator to run, or also for the autonomous driver to use as the separate reviewer for skill and agent work items — and if the latter, how much must the review know about the driver?
- **Decision:** The review is human-invocable and produces a severity-ranked report. It is consumable by the autonomous driver the same way the driver already consumes code-review: the driver wraps the dispatch, injecting its verdict format and any scope-reference inputs, and maps the review's findings into its own gate. The review holds no driver-specific mode, verdict contract, coverage attestation, or scope-baseline handling; its only obligation for driver use is severity tiers that map without translation (D7). Everything driver-specific is driver-side wiring, out of scope.
- **Rationale:** The groundwork research names the gap — no separate automated reviewer for skills and agents, so the builders self-review, the configuration most prone to blind spots — and this skill fills it. But the driver already consumes its sources by *wrapping* them: the verdict contract states the driver copies its required-format block and the source's severity-mapping row into the dispatch prompt, and code-review itself carries no verdict-contract knowledge. Making this review emit the driver's verdict would invert that dependency and couple the review to a caller that already knows how to wrap it. So driver-consumability reduces to D7 (identity tiers) plus D11 (unattended), and nothing else. (The research's own recommendation was to keep skills and agents human-reviewed until such a reviewer existed; this feature builds that reviewer and goes past the human floor — see F15.)
- **Evidence:** User input (selected "Both: human-invocable + driver-consumable", then directed that the review carry no driver knowledge); the verdict contract states the driver injects the format and mapping at dispatch and lists code-review as a wrapped source (`han-coding/skills/implement-work-items/references/review-verdict-contract.md`, lines 3–18); code-review's `SKILL.md` contains no verdict-contract references.
- **Rejected alternatives:**
  - Human-invocable only — rejected because it forgoes the feature's biggest payoff for the branch that motivated it, and driver-consumability costs nothing beyond D7.
  - Emit the driver's verdict contract from the review (a "driver mode") — rejected because it couples the review to the driver, duplicates the wrapping the driver already performs for every source, and inverts the dependency direction (F5, F6, F7, F8).
- **Linked technical notes:** —
- **Driven by findings:** F5, F6, F7, F8
- **Dependent decisions:** D7, D11
- **Referenced in spec:** Outcome, Primary Flow, Coordinations, Out of Scope

### D4: Hybrid reviewer model with a dispatched generalist

- **Question:** How is the review performed — inline passes done by the skill, dispatched agents, a new purpose-built reviewer agent, or a combination?
- **Decision:** A hybrid. The skill runs the guidance-conformance and bloat-and-restatement passes itself, grounded against the authoring guidance, and dispatches an independent generalist reviewer (`han-core:junior-developer`) in fresh context for a first-time-reader pass on assumptions, scope, and naming. The dispatched roster scales with the size and complexity of the artifact under review: a small skill or agent gets the generalist alone, while a large or complex one (many references, long flows, the scale of a driver skill) adds focused reviewers, mirroring code-review's size-driven roster. The size is classified from the artifact by default, and a caller may pass an explicit size that overrides the classification, exactly as code-review accepts a size override. The generalist is the floor; the specific size classification, the override keyword, and the roster each size selects are settled in implementation (OI-2). No new specialist agent is built now.
- **Rationale:** code-review, the stated base, is itself a hybrid of inline passes and dispatched agents. Grounding the conformance and bloat passes against the guidance keeps them reference-anchored; a fresh-context generalist adds an independent perspective without the cost of designing and maintaining a new specialist. Running the review separately from whoever built the artifact preserves the reviewer-not-builder separation the research identifies as the single most important property of an honest automated review. The user selected this option. Because a small agent and a large multi-reference skill warrant different review depth, the dispatched roster scales with the artifact's size the way code-review scales by change size, rather than being fixed.
- **Evidence:** User input (selected the hybrid option); code-review's Step 3 dispatch plus Steps 4–6 inline passes (`han-coding/skills/code-review/SKILL.md`); `han-core:junior-developer`'s description covers artifact review of plans, ADRs, and standards; multi-agent-economics guidance sets the bar for creating a new agent (`.../guidance/references/agent-building-guidelines/multi-agent-economics.md`); research on self-bias and reviewer separation (`.../research/reviewing-non-code-work-items.md`, sources A6–A7, A27).
- **Rejected alternatives:**
  - Build a dedicated conformance-reviewer agent — a reasonable choice for maximum specialization, rejected now under YAGNI: the hybrid satisfies the same need without a new agent to maintain (deferred, with a reopen trigger).
  - Inline-only with no dispatch — rejected because a single reviewer's blind spots go unchecked; a fresh-context second reader is cheap insurance.
  - A fixed reviewer roster regardless of the artifact's size — rejected because a small agent and a large skill warrant different depth; code-review already scales its roster by size (raised in the iterative-plan-review pass).
- **Linked technical notes:** —
- **Driven by findings:** F1
- **Dependent decisions:** D15
- **Referenced in spec:** Primary Flow, Coordinations, Deferred (YAGNI)

### D5: Rubric is routed by artifact type

- **Question:** Does the review apply one rubric to everything, or a different rubric per artifact type?
- **Decision:** The review resolves whether the target is a skill or an agent from its structure and applies the type-specific guidance and finding rubric — skill-building guidance for skills, agent-building guidance for agents. A target that resembles a type by name or location but fails its structural test is halted with the mismatch named, distinct from a target that is neither type at all.
- **Rationale:** Skills and agents have materially different rules: a skill has progressive disclosure across a directory, `allowed-tools`, and agent-dispatch namespacing; an agent is a single self-contained file with a role-identity paragraph, domain vocabulary, anti-patterns, and a model tier. A single generic rubric would miss the rules unique to each. The builders already split this way. Because type drives which guidance body must be present, type-resolution failures (a skill directory missing its `SKILL.md`, a mislocated file) are a real state the review must name rather than force into a rubric.
- **Evidence:** skill-builder's Step 6 and agent-builder's Step 6 check against distinct governing documents (`han-plugin-builder/skills/skill-builder/SKILL.md`, `.../agent-builder/SKILL.md`); the guidance is physically split into `skill-building-guidance/` and `agent-building-guidelines/`.
- **Rejected alternatives:**
  - One generic authoring rubric for both — rejected because it cannot carry the type-specific rules (self-containment for agents, progressive disclosure for skills) that are the most common conformance failures.
- **Linked technical notes:** —
- **Driven by findings:** F13
- **Dependent decisions:** D9
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D6: Bloat and restatement is a first-class corrective finding class

- **Question:** How does the review treat bloat and restatement — advisory or corrective — and how does that interact with size-based severity calibration?
- **Decision:** Bloat and restatement is an always-run, first-class corrective finding class. Its findings are classified by severity and gate like any other finding; they are not advisory the way code-review's YAGNI findings are. They are exempt from the size-based demotion that can omit ordinary Suggestions on a small change, so a bloat finding is never silently dropped for being small. The validator's drop-on-counter-evidence bar applies to bloat findings without exception. What text is in view is governed by the invocation's scope (D10), not by this class.
- **Rationale:** The user reports this as the single most prevalent issue in the branch that motivated the feature, and wants it fixed, not merely flagged; making it corrective is what feeds a gating caller's fix loop. But D7 reuses code-review's size calibration, which omits Suggestions on small changes; left unresolved, that would silently drop bloat on exactly the small edits that are most common. Exempting bloat from demotion — the treatment code-review gives its own YAGNI class — reconciles the two. Because bloat here gates, a wrongful validator drop is costlier than for advisory YAGNI, so the drop bar is stated to apply without exception.
- **Evidence:** User input (the feature request and its detailed anti-bloat instructions); the rules are codified in `.../guidance/references/skill-building-guidance/writing-effective-instructions.md` ("Say it once", the verbose/buried/ambiguous anti-pattern table) and `context-hygiene.md`; code-review exempts its YAGNI class from size demotion (`han-coding/skills/code-review/SKILL.md`, Step 3.3) and guards its validation pass against over-dropping (Step 7.4).
- **Rejected alternatives:**
  - Advisory-only, like code-review's YAGNI class — rejected because the user's goal is correction, and advisory would not gate a caller's fix loop.
  - Corrective but subject to size demotion — rejected because it would silently omit bloat on small changes, undercutting the flagship outcome (F10).
- **Linked technical notes:** —
- **Driven by findings:** F10, F11
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow

### D7: Severity tiers identical to the driver's

- **Question:** What severity tiers does the review use, and how do they reach a gating caller?
- **Decision:** The review uses Critical, Warning, and Suggestion, calibrated to the change the way code-review does. These are the same three tiers code-review emits, so a gating caller (the autonomous driver) maps them into its verdict by identity, with no translation — which is the review's entire driver-facing obligation (D3).
- **Rationale:** The driver's verdict contract maps each source's native findings into three tiers and parses them fail-closed; code-review's mapping is already identity, while a documentation reviewer's needs translation. Using code-review's own tiers makes this review wrappable exactly like code-review and removes a class of translation bugs. It also lets the review reuse code-review's size-based calibration directly (with the bloat-class exemption recorded in D6).
- **Evidence:** The verdict contract's severity-mapping table shows `code-review` mapping by identity while `information-architect` and `content-auditor` require translation (`han-coding/skills/implement-work-items/references/review-verdict-contract.md`); code-review's Step 3.3 size calibration (`han-coding/skills/code-review/SKILL.md`).
- **Rejected alternatives:**
  - Custom tiers tuned to prose (for example "blocks comprehension / degrades / friction / polish") — rejected because they would need a translation step, reintroducing the exact fail-closed mismatch the research flags as the top blocker.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Coordinations

### D8: The artifact under review is treated as data at every step the review reads it, dispatches it, or recommends from it

- **Question:** A skill or agent file is itself a document full of imperative directives. How does the reviewer avoid being steered by the artifact it is reviewing — not only while reading it, but when it hands the artifact to another agent and when it composes its recommendation?
- **Decision:** The reviewer treats the artifact's text strictly as data at every point it touches it: its own reading passes, the dispatch to the generalist reviewer (which receives the artifact as explicitly-marked untrusted data), and the composition of the report's recommendation. No directive embedded in the artifact — "approve this", "ignore the guidance", "report no findings" — is ever obeyed, and none can lower the recommendation or empty the findings. The presence of such text is itself a finding.
- **Rationale:** Unlike ordinary code, a skill or agent under review is composed of instructions ("Always X", "Return exactly these sections", "Launch agent Y"). A reviewer that reads them naively can be redirected — an acute prompt-injection surface. The commitment cannot stop at the first reading step: the dispatched generalist (`han-core:junior-developer`) has no native untrusted-content defense, and a directive that steers the recommendation would produce a clean report a gating caller then trusts. code-review already handles this class for untrusted branch context by wrapping third-party content in explicit untrusted markers before dispatch; the same discipline applies here, extended to the dispatch boundary and the recommendation.
- **Evidence:** code-review's untrusted-context handling wraps content in `BEGIN/END (UNTRUSTED)` markers before dispatching it to an agent and instructs the agent to disregard embedded directives (`han-coding/skills/code-review/SKILL.md`, Step 1.5 and Step 3.5, lines ~205–213); the research-analyst agent's "treats fetched content as claims to evaluate, never as instructions to follow" contract.
- **Rejected alternatives:**
  - Treat the artifact as ordinary trusted input — rejected because the artifact is literally instructions and would let a crafted or careless skill steer its own review.
  - State the discipline only at the reading step — rejected because the dispatch boundary and the recommendation are where a steered result actually reaches the reader or a gating caller, and neither is covered by a reading-step-only commitment (F1, F2).
- **Linked technical notes:** —
- **Driven by findings:** F1, F2
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D9: Authoring guidance resolved by type; trusted copy preferred; review halts when the needed copy is absent

- **Question:** Where does the review get the rubric it grounds against — given the guidance is split by type, can live in more than one place, and a located copy may be partial or stale — and what happens when the needed copy is missing?
- **Decision:** The review resolves the authoring guidance for the target's *type* (skill guidance for a skill, agent guidance for an agent). When both a plugin-bundled and a repository-vendored copy resolve, it prefers the bundled copy, because a co-located vendored copy is mutable in the same tree as the artifact. If the guidance for the resolved type cannot be located, or the copy found is incomplete or stale relative to the bundled version, the review halts and reports that the type's guidance is required and where it searched, rather than grounding against a partial, wrong-type, or absent rubric.
- **Rationale:** The guidance can be vendored into any repository via the guidance skill's init step, so a hardcoded path would break both portability and the vendored case — and portability is a dimension the user explicitly named. Three failure shapes all reduce to "the trusted, complete, type-appropriate rubric is not what we grounded against," and each produces the same danger a grounded-against-nothing review does — a false "approve": (a) only the other type's guidance is present; (b) a vendored copy is partial or stale (the guidance skill's own update mode exists precisely because vendored copies drift); (c) a co-located vendored copy could be weakened in the working tree. Halting, and preferring the bundled copy when both resolve, is the safe failure for all three.
- **Evidence:** The guidance skill's Initialization Mode vendors the guidance into `.claude/skills/plugin-guidance/references/`, and its Update Mode exists to refresh drifted vendored copies (`han-plugin-builder/skills/guidance/SKILL.md`); the guidance is split into `skill-building-guidance/` and `agent-building-guidelines/`; the research names reference-grounding as the reliability lever for non-code review (`.../research/reviewing-non-code-work-items.md`, source A39); user named portability as a review dimension.
- **Rejected alternatives:**
  - Hardcode the plugin-building plugin's guidance path — rejected because it breaks when the guidance is vendored or the plugin is installed under a different root, and defeats the portability the feature is meant to check for.
  - Fall back to reviewing from general knowledge when the guidance is absent — rejected because an ungrounded pass produces false approvals.
  - Treat "any guidance located" as sufficient — rejected because the wrong-type, partial, or stale copy each produces the same false-approve the decision exists to prevent (F4).
  - Trust a located vendored copy equally with the bundled one — rejected because the vendored copy is mutable in the same tree as the artifact, so a weakened copy would silently degrade the rubric (F3).
- **Linked technical notes:** —
- **Driven by findings:** F3, F4
- **Dependent decisions:** —
- **Referenced in spec:** Actors and Triggers, Primary Flow, Alternate Flows and States, Edge Cases and Failure Modes, Coordinations

### D10: Scope is stated by the invocation: whole artifact or a change

- **Question:** Does the review inspect the whole artifact or only what changed, and how is that chosen?
- **Decision:** The scope is chosen by the invocation, not inferred from git state. "Review this skill/agent" reviews the whole artifact; "review this change" scopes findings to the change while still reading the whole file for context. The full file is read either way. There is no size-based sampling: a body that exceeds the guidance's own size cap is raised as a conformance finding rather than a reason to truncate the read.
- **Rationale:** Restatement and bloat span the whole file, so a whole-artifact review must read everything; but which findings to raise is a matter of intent the caller states, not something to guess from whether a diff happens to exist. Stating scope in the request is predictable and keeps the review free of environment-sensing behavior. code-review already models both a change-scoped read (reads full files, raises on the diff) and a whole-file read; this decision selects between them by the request rather than by git detection. code-review's large-file sampling fallback is deliberately not adopted, because it would blind the whole-artifact bloat scan; an oversize body is instead itself a finding, which the guidance already bounds (skill bodies are capped well under a thousand lines).
- **Evidence:** User direction (scope stated by the prompt: "review this skill" → whole artifact; "review this change" → the change); code-review's Mode A change-scoped read, Mode C whole-file read, and its large-file sampling fallback (`han-coding/skills/code-review/SKILL.md`, Step 1 and Step 4); the progressive-disclosure guidance caps skill bodies (`.../guidance/references/skill-building-guidance/progressive-disclosure.md`).
- **Rejected alternatives:**
  - Infer scope from whether a branch diff exists — rejected per user direction, because it makes the review's behavior depend on environment state rather than the caller's stated intent.
  - Adopt code-review's large-file sampling — rejected because it reintroduces a blind spot in the whole-artifact bloat scan; an oversize body is instead a conformance finding (F18).
- **Linked technical notes:** —
- **Driven by findings:** F18
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D15: Overlapping dimensions are de-duplicated by a named precedence, and the recommendation is highest-severity-wins

- **Question:** The review's dimensions and its dispatched generalist can each surface a routing, tool, or dispatch finding, and a mixed-quality artifact produces findings at several severities. How are duplicates reconciled, and what drives the single recommendation?
- **Decision:** The guidance-conformance pass owns every finding about tool usage, agent-dispatch and handoff wiring, and instruction routing; the other lenses and the dispatched generalist reference a conformance finding on overlap rather than raising a duplicate. The single recommendation is driven by the highest-severity surviving finding.
- **Rationale:** The dimensions the user named overlap (bullet-level "tool usage", "handoff protocols", and "ambiguous routing" all restate checks the conformance pass already owns), and the generalist's charter overlaps the same routing space. Without a precedence rule the report double-counts, and — because tiers feed a caller's gate identically (D7) — a duplicated or averaged recommendation would corrupt the gate decision, not merely confuse a human. code-review already solves both problems: overlap-reference instead of duplicate, and highest-severity-wins for the recommendation.
- **Evidence:** code-review's overlap-reference rule (`han-coding/skills/code-review/SKILL.md`, Step 9.1 rule 10), its self-consistency check (Step 9.0), and its highest-severity-wins recommendation (Step 9.1 rule 9); the overlapping dimension list is in the user's own feature request.
- **Rejected alternatives:**
  - Let every dimension raise its own finding — rejected because it double-counts and inflates the finding list a caller gates on.
  - Leave the recommendation rule implicit — rejected because an ambiguous recommendation feeds a wrong gate decision under D7's identity mapping.
- **Linked technical notes:** —
- **Driven by findings:** F9, F14
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow

### D17: Batch review — deferred

Batch (branch-set) review and its systemic-versus-per-artifact halt handling were deferred under YAGNI in the iterative-plan-review pass (no cited consumer; the driver reviews one item at a time and an operator can invoke per artifact). See the spec's `## Deferred (YAGNI)` → "Batch (branch-set) review". Retained here as a tombstone so the D-number is not reused; the driving finding was team finding F12.
