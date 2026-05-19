# Precedent, Overlap, and Cost: Evidence for the `/research` Decision

Investigation angle: Should a new `/research` capability be a separate skill or an expansion of `/investigate`?

---

## E1: How Han delineates `plan-a-feature` from its siblings

**Source:** `plugin/skills/plan-a-feature/SKILL.md:14–17`

```
Does not refine or stress-test an existing plan — use iterative-plan-review. Does not
investigate bugs or failures — use investigate. Does not analyze existing architecture — use
architectural-analysis. Does not document already-built features — use project-documentation.
Does not record architectural decisions — use architectural-decision-record.
```

**Relevance:** Han's house style for splitting adjacent capabilities is explicit negative routing in the `description` frontmatter. Every skill names the siblings it does NOT replace. This is the canonical pattern: the boundary is stated in the skill's own description, not inferred from the body. A new `/research` skill would require its own negative routing ("does not investigate bugs or failures — use investigate") and would require every sibling that abuts it to add a reciprocal line.

---

## E2: How Han delineates `plan-implementation` from its siblings

**Source:** `plugin/skills/plan-implementation/SKILL.md:18–22`

```
Does not specify what the feature should do — use plan-a-feature to produce the
behavioral specification first. Does not refine or stress-test an already-written plan —
use iterative-plan-review. Does not investigate bugs or failures — use investigate.
Does not perform file-level code review — use code-review. Does not record architectural
decisions — use architectural-decision-record.
```

**Relevance:** The explicit "does not" boundary from E1 is not an outlier — it is applied consistently across the planning cluster. Both `plan-a-feature` and `plan-implementation` already name `investigate` as the sibling for bug/failure work. A `/research` skill that sits between "investigate a bug" and "plan a feature" would create a new adjacency that both skills' descriptions would need to acknowledge.

---

## E3: How `gh-pr-review` delineates itself from `code-review`

**Source:** `plugin/skills/gh-pr-review/SKILL.md:6–9`

```
Run a full pull request review and post review comments directly to the current
branch's GitHub PR. [...] For local code review without posting to GitHub, use
code-review instead. Does not write or update PR descriptions — use
update-pr-description for that.
```

**Source:** `plugin/skills/code-review/SKILL.md:3–4` (frontmatter description excerpt)

```
Does not post comments to GitHub pull requests — use gh-pr-review for that.
Does not analyze architectural structure or module boundaries — use architectural-analysis for that.
```

**Relevance:** `gh-pr-review` is a thin delivery-channel wrapper around `code-review` — it literally invokes `/code-review` at Step 2. Han gave it its own skill anyway because the delivery channel (posting to GitHub vs. local output) is a distinct user decision, not a mode flag. This is Han's precedent for a skill that adds one new capability on top of an existing one rather than adding a mode to that skill. The precedent argues for a separate skill when the trigger condition (what brings you to the slash command) differs meaningfully from the parent skill's trigger.

---

## E4: How `investigate` delineates itself from `architectural-analysis`

**Source:** `plugin/skills/investigate/SKILL.md:1–6` (frontmatter description)

```
Evidence-based investigation of issues, bugs, API calls, integrations, and
other aspects of software development that need a deep dive to find the root
cause and solutions. Use when you need to debug, troubleshoot, diagnose, or
figure out why something is broken [...] Does not assess
architectural health or structural risk — use architectural-analysis for
architectural concerns.
```

**Source:** `plugin/skills/architectural-analysis/SKILL.md:4` (frontmatter description excerpt)

```
Not for investigating specific bugs, runtime errors, or failures — use investigate.
```

**Relevance:** `investigate` is explicitly scoped to "why something is broken." Its trigger vocabulary — "debug, troubleshoot, diagnose" — is failure-oriented. `architectural-analysis` is scoped to "assess, evaluate, or review" an existing part of the codebase. These two skills share the `evidence-based-investigator` and `behavioral-analyst` agents but serve distinct entry points. A `/research` skill aimed at "ideas, possible solutions, and information" sits in neither of these domains. `investigate`'s description would need revision to encompass that use case without a clear trigger boundary for users.

---

## E5: How `coding-standard` delineates itself from `architectural-decision-record`

**Source:** `plugin/skills/coding-standard/SKILL.md:7–10` (frontmatter description)

```
Does not create architectural decision records — use architectural-decision-record for ADRs.
Does not write feature or system documentation — use project-documentation for that.
```

**Source:** `plugin/skills/architectural-decision-record/SKILL.md:7–10` (frontmatter description)

```
Does not create or update enforceable coding standards or conventions — use coding-standard for
that. Does not write feature or system documentation — use
project-documentation instead.
```

**Relevance:** Two skills that both work with decision documentation, both use `codebase-explorer` agents, and both produce durable written artifacts are kept strictly separate by output type and forcing function. The separation is not about what they do internally — it is about what the user is trying to produce and why. This is Han's third example of the split-on-trigger-not-implementation pattern.

---

## E6: `investigate`'s scope is explicitly failure-bounded

**Source:** `plugin/skills/investigate/SKILL.md:1–6`

```
Evidence-based investigation of issues, bugs, API calls, integrations, and
other aspects of software development that need a deep dive to find the root
cause and solutions. Use when you need to debug, troubleshoot, diagnose, or
figure out why something is broken
```

**Source:** `docs/skills/investigate.md:32–36`

```
Do not invoke for:
- Code review. Use /code-review ...
- Architectural analysis. Use /architectural-analysis ...
- Test planning. Use /test-planning ...
- Plan review. Use /iterative-plan-review ...
```

**Relevance:** The long-form doc's "Do not invoke for" section has no entry for "researching ideas, technology options, or possible solutions." That absence is significant: the skill does not name research of ideas or options as a use case, and it does not route those requests to a different skill either. The slot is unoccupied. Expanding `investigate` to cover research of ideas would require either broadening its description past the failure-bounded vocabulary ("debug, troubleshoot, diagnose, figure out why something is broken") or adding a second-trigger mode — both of which conflict with Han's single-trigger-per-skill pattern established in E1 through E5.

---

## E7: `plan-a-feature` does research, but only within spec-building

**Source:** `plugin/skills/plan-a-feature/SKILL.md:29–36` (Step 2 and Operating Principles)

```
Before asking the user anything beyond the initial framing, explore the codebase and project
documentation to gather context [...] Use Glob and Grep to find: CLAUDE.md, AGENTS.md,
and any project-discovery.md [...] ADRs [...] Coding standards [...] Existing feature
specifications or PRDs [...] Code adjacent to what the feature touches
```

**Relevance:** `plan-a-feature` does conduct research — but its research is strictly downstream of a feature-speccing intent. It researches to resolve design-tree questions, not to explore ideas freely. Its output is always `feature-specification.md`. A user who wants to research technology options, compare libraries, explore architectural approaches, or survey prior art before committing to any particular feature or plan has no current entry point that matches their intent. `plan-a-feature` would produce a feature spec they did not ask for.

---

## E8: `architectural-analysis` does not research options; it assesses existing code

**Source:** `plugin/skills/architectural-analysis/SKILL.md:2–6` (frontmatter description)

```
Performs deep architectural analysis of a specified module, directory, or feature area by
examining structural coupling, data flow, concurrency patterns, risk, and SOLID alignment.
Use when the user wants to assess, evaluate, or review the architecture, design quality,
dependency structure [...] of an existing part of the codebase. Requires a specific focus
area (module, directory, or component) to analyze.
```

**Relevance:** `architectural-analysis` requires a focus area that resolves to real files in the codebase. It analyzes what exists, not what could exist. Researching options or ideas — especially for new approaches or external patterns — falls outside its scope. No existing skill covers free-form research of possible solutions or ideas.

---

## E9: `gap-analysis` does not cover option research

**Source:** `plugin/skills/gap-analysis/SKILL.md:3–9` (frontmatter description)

```
Performs a gap analysis between two artifacts (a current state and a desired state) and
produces a plain-language, stakeholder-readable report indexed by stable gap IDs. Use when
the user wants to compare, evaluate, audit, or reconcile one artifact against another
```

**Relevance:** `gap-analysis` requires two artifacts to compare. It produces a gap report. It does not explore possible solutions or research ideas. Negative evidence: no existing skill description matches the research-of-ideas trigger.

---

## E10: `coding-standard` mentions "evidence-based research" but scopes it to standard-writing

**Source:** `docs/skills/README.md:56`

```
/coding-standard. Create and update coding standards from existing patterns or evidence-based research.
```

**Source:** `docs/skills/coding-standard.md:29`

```
A new standard needs research-backed rationale (testing boundaries, error handling,
transaction patterns). The skill grounds the standard in evidence from the codebase and
surfaces Correct and Avoid examples.
```

**Relevance:** "Evidence-based research" in the `coding-standard` context means researching what the codebase already does to produce grounded examples for a standard — not free-form research of ideas or technology options. The `codebase-explorer` agents it dispatches are the mechanism, and the output is always a coding standard document. This is the closest existing overlap with a research capability, and it still requires a specific topic and the intent to produce a standard. It does not cover open-ended exploration.

---

## E11: The full cost of adding a new skill — artifacts required

**Source:** `CONTRIBUTING.md:26–33` ("Adding a skill")

```
1. Scaffold the folder under plugin/skills/{name}/ and add a SKILL.md.
2. Write the SKILL.md: Frontmatter with name, description, allowed-tools [...] Body: numbered steps [...]
3. Copy the skill template into docs/skills/{name}.md and fill it in. Every skill gets a long-form doc.
4. Add the skill to the Skills Index (docs/skills/README.md) with a one-sentence scent line and a link.
5. Update the skill counts [...] the skill catalog and "Counts to verify when editing indexes" line in
   Root CLAUDE.md, the count in Concepts (docs/concepts.md) [...] and the counts in the README.
6. Update the marketplace registry at .claude-plugin/marketplace.json if needed.
```

**Source:** `docs/templates/coverage-rule.md:1–10`

```
Every skill and agent in the han plugin gets a long-form doc. No exceptions.
[...]
The long-form doc lands in the same pull request as the skill or agent definition.
Not as a follow-up. Not "when there's time."
```

**Relevance:** Adding a skill to Han requires at minimum six distinct file changes: `plugin/skills/{name}/SKILL.md` (new), `docs/skills/{name}.md` (new), `docs/skills/README.md` (entry + count update), `CLAUDE.md` (count update), `docs/concepts.md` (count update), `README.md` (count update). The `marketplace.json` and `plugin.json` may also need updating. The coverage rule enforces that the long-form doc ships in the same PR. Each of these files is a future-maintenance surface: every time the skill changes, its long-form doc, the index, and any callers' "does not do X — use this instead" routing lines must be kept in sync.

---

## E12: Count constraint — current totals

**Source:** `CLAUDE.md` (root, "Counts to verify when editing indexes")

```
21 agents in plugin/agents/; 18 skills in plugin/skills/; 21 long-form agent docs in
docs/agents/; 18 long-form skill docs in docs/skills/.
```

**Source:** `docs/concepts.md:95`

```
18 skills. The skills index groups them by purpose (planning, building, investigation,
review, discovery, conventions, reporting).
```

**Source:** `README.md:37`

```
Skills Index (docs/skills/README.md). All 18 skills, grouped by purpose.
```

**Relevance:** All three files carry the hard count "18." Adding a new skill requires updating CLAUDE.md, concepts.md, and README.md to read "19." These count references are not cosmetic — CLAUDE.md states they are "counts to verify when editing indexes," meaning contributors are expected to keep them accurate. Each file is a maintenance synchronization point.

---

## E13: Agents a `/research` skill could reuse without new creation

**Source:** `plugin/agents/evidence-based-investigator.md` (frontmatter description)

```
Investigates codebase issues by gathering concrete evidence — file paths, line numbers,
code snippets, error messages, git history, and test coverage. Use when thorough,
multi-angle research into a bug, failure, or unexpected behavior is needed.
```

**Source:** `plugin/agents/codebase-explorer.md` (frontmatter description)

```
Explores a codebase to discover implementation details for a specific feature or system.
Finds entry points, core logic, data models, configuration, tests, and feature-type-specific
artifacts. Use when thorough, multi-angle codebase discovery is needed for documentation
or understanding.
```

**Source:** `plugin/agents/gap-analyzer.md` (frontmatter description)

```
Performs gap analysis between two artifacts — finds what's missing, incomplete, conflicting,
or assumed when comparing a current state against a desired state.
```

**Relevance:** The `evidence-based-investigator` agent's description says "codebase issues" and "bug, failure, or unexpected behavior" — its vocabulary is failure-oriented, matching `investigate`'s scope. Re-using it for idea research would require either accepting the vocabulary mismatch or rewriting its description, which would affect how every dispatching skill briefs it. The `codebase-explorer` agent is scoped to "discover implementation details for a specific feature" — closer to research, but output-oriented toward documentation. A genuine free-form research skill might need `codebase-explorer` for codebase angles plus something like `adversarial-validator` for challenging options. No existing agent is described as "researches external ideas, technology options, or possible solutions" — that posture does not currently exist in the agent catalog. A new `/research` skill could likely reuse `codebase-explorer` and `gap-analyzer` for codebase-grounded analysis, but would require either a new agent or a significantly reframed brief for external/idea-space research.

---

## E14: `investigate`'s Step 1 is already named "Research and Investigation"

**Source:** `plugin/skills/investigate/SKILL.md:31`

```
## Step 1: Research and Investigation
```

**Relevance:** The first step of `/investigate` uses the word "research" internally, but the section body makes clear this means launching `evidence-based-investigator` agents to gather evidence about a failure. The label "Research and Investigation" does not signal that the skill accepts free-form research requests — it is an internal process label describing the evidence-gathering phase. Expanding `/investigate` to serve general research requests would create a label collision: the word "research" would mean two different things inside the same skill's step.

---

## Implication for the decision

Han separates adjacent capabilities when the entry point — the user's trigger and intent — differs, even when the internal mechanics overlap. This is demonstrated consistently across five pairs: `plan-a-feature`/`plan-implementation`/`plan-a-phased-build`, `code-review`/`gh-pr-review`, `investigate`/`architectural-analysis`, and `coding-standard`/`architectural-decision-record`. In every case, the boundary is stated explicitly in the `description` frontmatter using "does not — use X instead" routing.

`/investigate` is explicitly scoped to failure — "debug, troubleshoot, diagnose, figure out why something is broken." General research of ideas, possible solutions, and information outside the bug/issue domain has no current home in Han: no skill description matches that trigger, and `investigate`'s long-form doc's "Do not invoke" list does not even name it as an out-of-scope case (it simply does not exist). The slot is genuinely empty.

The cost of adding a new skill is real but bounded: six file changes minimum (SKILL.md, long-form doc, skills index, CLAUDE.md count, concepts.md count, README.md count), all in one PR per the coverage rule, with reciprocal "does not — use X" routing lines added to the skills that abut it (at minimum `investigate` and `plan-a-feature`). The cost of expanding `/investigate` is lower in artifact count but carries a different risk: broadening the skill's trigger vocabulary past "failure" would conflict with Han's established single-trigger pattern, and the Step 1 label collision ("Research and Investigation" would mean two different things) would reduce the skill's internal coherence. The precedent evidence argues for a separate skill.
