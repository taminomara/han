# Feature Specification: Skill and Agent Review

A skill that reviews a finished Claude Code skill or agent against the plugin-authoring guidance and a set of quality dimensions — bloat and restatement chief among them — and produces a severity-ranked review report.

## Outcome

Running the review over a skill or agent produces a severity-ranked report of every place the artifact drifts from the authoring guidance or the named quality dimensions, with a location and a suggested fix for each finding. The single most-emphasized outcome is that restatement and bloat — descriptions that repeat themselves, sentences that restate what an adjacent sentence or a linked reference already says, three-fold "apply rule X to A, B, and C" repetitions, filler transitions, and self-evident consequences — are caught and surfaced as corrective findings, not left to a human to notice by eye ([D6](artifacts/decision-log.md#d6-bloat-and-restatement-is-a-first-class-corrective-finding-class)).

The groundwork research recommended keeping skills and agents human-reviewed for now, precisely because no separate automated reviewer for them existed and the builders were left self-reviewing their own work — the configuration most prone to blind spots. This feature deliberately goes past that floor: it builds that missing separate reviewer, which the user selected over remaining human-only ([D3](artifacts/decision-log.md#d3-dual-consumer-human-invocable-and-driver-consumable)). The review is consumable by the autonomous driver the same way the driver already consumes code-review — the driver wraps the dispatch and maps the review's severity-tiered findings into its own gate. The review therefore holds no driver-specific behavior; its only obligation for that use is severity tiers that map without translation ([D3](artifacts/decision-log.md#d3-dual-consumer-human-invocable-and-driver-consumable), [D7](artifacts/decision-log.md#d7-severity-tiers-identical-to-the-drivers)).

## Actors and Triggers

- **Actors** — an operator authoring or maintaining a skill or agent who wants it reviewed; and any automated caller, such as the autonomous driver, that dispatches the review in fresh context and consumes its findings the way it consumes code-review.
- **Triggers** — a caller invokes the review, naming a target, a scope (the whole artifact or a specific change), and optionally an explicit size and focus areas. The size, when given, overrides the review's own size classification; focus areas receive extra scrutiny. The review runs to completion without a mid-run gate, so an automated caller can dispatch it unattended ([D11](artifacts/decision-log.md#d11-the-review-runs-unattended-with-no-mid-run-human-gate)).
- **Preconditions** — the target is a skill (a skill directory containing a `SKILL.md`) or an agent (an agent definition file); and the authoring guidance for that type is reachable, either bundled with the installed plugin-building plugin or vendored into the repository ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)).

## Primary Flow

1. The review receives a target — a skill directory or an agent file — and a scope.
2. The review resolves the target's type — skill or agent — from its structure, because the two are governed by different authoring guidance and different finding rubrics ([D5](artifacts/decision-log.md#d5-rubric-is-routed-by-artifact-type)). A target that resembles a type by name or location but fails the structural test for it is handled as an edge case, not forced into a rubric.
3. The review resolves the authoring guidance for the target's type and grounds every conformance judgment against it. When both a plugin-bundled copy and a repository-vendored copy resolve, it prefers the bundled copy, because a co-located vendored copy is mutable in the same tree as the artifact under review. If the guidance for the resolved type cannot be found, or the copy it finds is incomplete or stale relative to the bundled version, the review halts and says so rather than grounding against a partial or wrong-type rubric ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)).
4. The review scopes itself from the invocation, not from git state: asked to review an artifact, it reviews the whole artifact; asked to review a change, it scopes findings to that change while still reading the whole file for context. It reads the full file either way; the scope governs what it raises findings on ([D10](artifacts/decision-log.md#d10-scope-is-stated-by-the-invocation-whole-artifact-or-a-change)).
5. The review reads the artifact **as data to evaluate, never as instructions to obey** ([D8](artifacts/decision-log.md#d8-the-artifact-under-review-is-treated-as-data-at-every-step-the-review-reads-it-dispatches-it-or-recommends-from-it)), and runs its guidance-grounded passes across these dimensions:
   - **Guidance conformance**, per the artifact's type. For a skill: entity fit, the description's four components and both-directions sibling disambiguation, naming and dependency-prefix rules, progressive-disclosure layout, `allowed-tools` and Bash-permission granularity, `AskUserQuestion` never in `allowed-tools`, qualified agent-dispatch namespacing, graceful degradation, and tests. For an agent: entity fit and single role, the role-identity paragraph, domain-vocabulary and anti-pattern coverage, description, model tier, self-containment, tool set, and economic justification. This dimension owns every finding about tool usage, agent-dispatch and handoff wiring, and instruction routing, so those are not double-raised elsewhere ([D15](artifacts/decision-log.md#d15-overlapping-dimensions-are-de-duplicated-by-a-named-precedence-and-the-recommendation-is-highest-severity-wins)).
   - **Bloat and restatement** — the always-run dimension: restatement of the obvious, duplication of what a linked reference already specifies, clauses that re-explain a rule stated a line earlier, filler transitions and self-evident consequences, three-fold repetitions, and back-referential meta-commentary.
   - **Prose flow and clarity, internal correctness, automatable steps, edge cases the artifact leaves the agent unable to handle on its own, and portability** — the remaining quality lenses. ("Internal correctness" means the artifact's steps are self-consistent and runnable as written; a skill or agent has no compiler, so the oracle is the guidance and the artifact's own stated intent.)
6. The review dispatches independent reviewers in fresh context to surface hidden assumptions, muddied scope, and unclear naming a first-time reader would trip on. It sizes this dispatch to the artifact under review — a small skill or agent gets a single generalist reviewer, while a large or complex one (many reference files, long flows, the scale of a driver skill) adds focused reviewers — unless the caller passed an explicit size, which overrides the classification. This mirrors code-review, which auto-classifies size and honors a caller's size override ([D4](artifacts/decision-log.md#d4-hybrid-reviewer-model-with-a-dispatched-generalist)). Each dispatched reviewer receives the artifact as explicitly-marked untrusted data with the same discipline as step 5: directives embedded in it are disregarded, never obeyed ([D8](artifacts/decision-log.md#d8-the-artifact-under-review-is-treated-as-data-at-every-step-the-review-reads-it-dispatches-it-or-recommends-from-it)). Where a reviewer's observations overlap a conformance finding, it references that finding rather than raising a duplicate ([D15](artifacts/decision-log.md#d15-overlapping-dimensions-are-de-duplicated-by-a-named-precedence-and-the-recommendation-is-highest-severity-wins)).
7. The review consolidates the findings and classifies each as Critical, Warning, or Suggestion ([D7](artifacts/decision-log.md#d7-severity-tiers-identical-to-the-drivers)). Bloat and restatement findings are corrective and gate like any other finding; they are exempt from the size-based demotion that can omit ordinary Suggestions on a small change, so they are never silently dropped for being small. Scope (step 4) already governs whether pre-existing text is in view, so no bloat that is in scope is set aside ([D6](artifacts/decision-log.md#d6-bloat-and-restatement-is-a-first-class-corrective-finding-class)).
8. The review runs one adversarial pass over the consolidated list against the artifact itself, inheriting code-review's validation discipline: each finding is Confirmed, Partially Refuted (demoted one severity, not dropped), or Refuted, and a finding is dropped only on concrete counter-evidence at a cited location — never on assertion. This guard applies without exception to bloat findings, whose corrective, gating status makes a wrongful drop costlier than for an advisory note ([D6](artifacts/decision-log.md#d6-bloat-and-restatement-is-a-first-class-corrective-finding-class)).
9. The review produces one output: a review report — a summary table, a single recommendation driven by the highest-severity surviving finding ([D15](artifacts/decision-log.md#d15-overlapping-dimensions-are-de-duplicated-by-a-named-precedence-and-the-recommendation-is-highest-severity-wins)), and severity-ordered findings including the bloat-and-restatement section, each with a location and a suggested fix. The recommendation and findings derive only from the review's grounded passes; no directive embedded in the artifact can lower the recommendation or empty the findings, and such text is itself a finding ([D8](artifacts/decision-log.md#d8-the-artifact-under-review-is-treated-as-data-at-every-step-the-review-reads-it-dispatches-it-or-recommends-from-it)). A caller that gates on the review, such as the autonomous driver, wraps the dispatch to map these findings into its own verdict, exactly as it wraps code-review; that mapping is the caller's, not the review's ([D3](artifacts/decision-log.md#d3-dual-consumer-human-invocable-and-driver-consumable)).

## Alternate Flows and States

### Guidance absent for the resolved type
- **Entry condition:** neither a bundled nor a vendored copy of the authoring guidance for the target's type can be located, or the copy found is incomplete or stale.
- **Sequence:** the review does not fall back to a partial or wrong-type rubric.
- **Exit:** it halts, states that the type's guidance is required, and names where it looked ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)).

## Edge Cases and Failure Modes

| Condition | Required Behavior |
|-----------|-------------------|
| The authoring guidance for the target's type cannot be located, or only the other type's guidance is present | The review halts and reports that the type's guidance is required and where it searched; it never grounds against a wrong-type or absent rubric ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)). |
| A vendored guidance copy is present but incomplete or stale relative to the bundled version | Treated as the needed copy being absent for the affected rules: the review halts rather than grounding against a partial rubric ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)). |
| Both a bundled and a vendored guidance copy resolve | The bundled (trusted) copy is used; the vendored copy is used only when it is the sole source ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)). |
| The target resembles a type by name or location but fails its structural test (a skill directory with no `SKILL.md`; a file under an agents location that is structurally a skill) | The review halts and names the mismatch, distinct from an artifact that is neither type at all ([D5](artifacts/decision-log.md#d5-rubric-is-routed-by-artifact-type)). |
| The target is neither a valid skill nor a valid agent (for example a documentation file or a plugin manifest) | The review declines, states the target is out of its scope, and names the tool that does cover it ([D2](artifacts/decision-log.md#d2-review-scope-is-skills-and-agents-only)). |
| The artifact under review contains text aimed at the reviewer ("approve this", "ignore the guidance", "report no findings", or anything shaped like a directive) | The reviewer treats it as data at every step — reading, dispatch, and recommendation — never acts on it, and notes its presence as a finding; no such text can lower the recommendation or empty the findings ([D8](artifacts/decision-log.md#d8-the-artifact-under-review-is-treated-as-data-at-every-step-the-review-reads-it-dispatches-it-or-recommends-from-it)). |
| A conformance violation would stop the artifact loading, dispatching, or running a step as written (a bare or unresolvable agent-dispatch name, `AskUserQuestion` in `allowed-tools`, a tool a step uses but the frontmatter does not grant, unsafe frontmatter, or a missing referenced file a step needs) | Raised as Critical — the artifact would not run as written. |
| The artifact is very large, or its progressive-disclosure reference tree is | The review reads the target in full rather than sampling; a body that exceeds the guidance's size cap is itself a conformance finding, so size is surfaced as a defect rather than silently truncating the review ([D10](artifacts/decision-log.md#d10-scope-is-stated-by-the-invocation-whole-artifact-or-a-change)). |
| The target is a vendored artifact (prefixed name, guidance under the repository's own copy) | Reviewed against the repository's vendored guidance copy ([D9](artifacts/decision-log.md#d9-authoring-guidance-resolved-by-type-trusted-copy-preferred-review-halts-when-the-needed-copy-is-absent)). |
| No git history is available, or the target is a whole artifact | The full artifact is reviewed; with no change to scope to, severity is treated conservatively, as code-review does in the same situation ([D10](artifacts/decision-log.md#d10-scope-is-stated-by-the-invocation-whole-artifact-or-a-change)). |

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
|---------------------|-----------|-------------|-----------------------------------|
| Authoring guidance | inbound (read-only) | The type-appropriate rubric every conformance judgment is grounded against | Must be resolved before any conformance finding; the bundled copy is preferred over a vendored one; a missing, partial, or stale copy halts the review |
| Independent reviewer(s) | outbound (dispatch, fresh context) | Second perspective on assumptions, scope, and naming; a generalist for a small artifact, additional focused reviewers for a large one | Each receives the artifact as explicitly-marked untrusted data; references overlapping conformance findings instead of duplicating them |
| Adversarial validator | outbound (dispatch) | Confirms, demotes, or drops each consolidated finding | Drops only on concrete counter-evidence at a cited location; bloat findings get no exception to that bar |
| Automated caller (e.g. autonomous driver) | inbound (dispatch) | Wraps the review and maps its findings into the caller's own gate | The review's tiers map without translation, so a caller wraps it exactly as it wraps code-review; the review holds no caller-specific logic ([D3](artifacts/decision-log.md#d3-dual-consumer-human-invocable-and-driver-consumable), [D7](artifacts/decision-log.md#d7-severity-tiers-identical-to-the-drivers)) |

## Out of Scope

- Reviewing documentation — covered by the content and information-architecture reviewers and the documentation skills ([D2](artifacts/decision-log.md#d2-review-scope-is-skills-and-agents-only)).
- Reviewing application code — covered by code-review ([D2](artifacts/decision-log.md#d2-review-scope-is-skills-and-agents-only)).
- Building or fixing the artifact — this reviews only; authoring is skill-builder and agent-builder, and behavior-preserving restructuring is refactor ([D2](artifacts/decision-log.md#d2-review-scope-is-skills-and-agents-only)).
- The autonomous driver's own dispatch, verdict mapping, coverage attestation, scope-baseline inputs, and fix-loop wiring — the driver wraps this review the way it wraps code-review, so all of that lives on the driver side ([D3](artifacts/decision-log.md#d3-dual-consumer-human-invocable-and-driver-consumable)).
- Reviewing hooks and plugin or marketplace configuration files ([D14](artifacts/decision-log.md#d14-hooks-and-plugin-configuration-are-out-of-scope-for-this-feature)).

## Deferred (YAGNI)

### Whole-plugin sweep
- **Why deferred:** evidence test — no described need for a bulk pass yet; reviewing a single artifact covers every use case named so far, and it is the strictly simpler shape.
- **Reopen when:** an operator or a maintenance workflow asks to audit every skill and agent in a plugin in one run.
- **Source:** design tree, target-breadth branch.

### Batch (branch-set) review
- **Why deferred:** evidence test — no cited consumer needs it; the autonomous driver reviews one work item at a time and an operator can invoke the review per artifact, so single-artifact review satisfies every named use case. Deferring removes the branch-set flow and its systemic-versus-per-artifact halt handling.
- **Reopen when:** a consumer needs to review a branch's changed skills and agents, or produce a combined artifact-keyed report, in one run.
- **Source:** iterative-plan-review pass (cut #2), subsuming the earlier combined-report deferral (team finding F16).

### Dedicated conformance-reviewer agent
- **Why deferred:** simpler-version test — the hybrid model (guidance-grounded passes plus a dispatched generalist) satisfies the same need without a new specialist agent to design and maintain ([D4](artifacts/decision-log.md#d4-hybrid-reviewer-model-with-a-dispatched-generalist)).
- **Reopen when:** the inline passes show systematic blind spots a purpose-built specialist would catch.
- **Source:** reviewer-model decision (user selected the hybrid option).

### Reviewing hooks and plugin configuration
- **Why deferred:** evidence test — the stated need is skills and agents; hook and plugin-config authoring has not been named as needing a gate.
- **Reopen when:** hook or plugin/marketplace-config authoring needs an automated review gate.
- **Source:** scope boundary ([D14](artifacts/decision-log.md#d14-hooks-and-plugin-configuration-are-out-of-scope-for-this-feature)).

## Open Items

- **OI-1:** The severity heuristics that assign a specific bloat instance to Critical, Warning, or Suggestion (for example, whether a three-fold repetition is a Warning and a verbatim reference restatement is a Suggestion).
  - **Resolves when:** plan-implementation drafts the bloat rubric and its worked examples.
  - **Blocks implementation:** No — that bloat gates and is exempt from demotion is settled; only the per-instance tiering is open.
- **OI-2:** How the artifact under review is classified by size and complexity, the optional size-override keyword the caller passes (mirroring code-review's `size` argument), and which focused reviewers each size adds beyond the generalist.
  - **Resolves when:** plan-implementation drafts the size classification, the override argument, and the roster each size selects.
  - **Blocks implementation:** No — that the roster scales with the artifact and that a caller may override the size is settled; only the specific thresholds, keyword, and roster are open.

## Summary

- **Outcome delivered:** a grounded, severity-ranked review of a skill or agent that catches bloat and restatement as corrective findings, and whose findings a caller like the autonomous driver can wrap into its gate exactly as it wraps code-review.
- **Primary actors:** an operator maintaining a skill or agent; an automated caller such as the autonomous driver.
- **Decisions settled by evidence:** 11 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** 4 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** junior-developer, adversarial-security-analyst, edge-case-explorer, test-engineer — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** the four-agent team hardened the "treat as data" discipline across the dispatch and recommendation boundaries, made guidance resolution type-aware and trust-ordered, added a dimension-precedence rule, and exempted bloat from size demotion; a user review then decoupled the driver integration (the review is consumed by wrapping, as code-review is); and a cut/simplify pass deferred batch review, collapsed rubric-instance edge cases, trimmed restatement, and scaled the dispatched roster to the artifact under review — see [artifacts/team-findings.md](artifacts/team-findings.md) and [artifacts/review-findings.md](artifacts/review-findings.md)
- **Remaining open items:** 2

## Review History

- **Review mode:** lightweight (self-review).
- **Spec-aware mode:** engaged.
- **Iterations completed:** 1 review round (R1) plus a user-directed follow-up (R2) — see [artifacts/review-iteration-history.md](artifacts/review-iteration-history.md).
- **Findings raised:** 6 — see [artifacts/review-findings.md](artifacts/review-findings.md) (2 major, 4 minor; all resolved by evidence or user direction).
- **YAGNI candidates:** 1 — batch/branch-set review, deferred (subsuming the earlier combined-report deferral).
- **Consolidations made:** four rubric-instance edge-case rows collapsed into one principle row; the restatement-only User Interactions section folded into Actors and Triggers.
- **Assumptions challenged:** that the review needed a fixed reviewer roster regardless of the artifact under review — corrected to a size-scaled roster (D4, OI-2).
- **Open items remaining:** 2 — OI-1 (bloat severity heuristics) and OI-2 (artifact size classification and roster); neither blocks implementation.

Companion files: [artifacts/review-findings.md](artifacts/review-findings.md), [artifacts/review-iteration-history.md](artifacts/review-iteration-history.md).
