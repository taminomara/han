# Analysis: `/investigate` Skill Scope and Fit for a Research Capability

This document records concrete, file-backed evidence on the scope and framing of the existing `/investigate` skill, examined against the question of whether a new `/research` capability should be a separate skill or an expansion of `/investigate`.

---

## E1: Description frontmatter is unambiguously bug/failure-framed

**Source:** `plugin/skills/investigate/SKILL.md:2-13`

```
name: "investigate"
description: >
  Evidence-based investigation of issues, bugs, API calls, integrations, and
  other aspects of software development that need a deep dive to find the root
  cause and solutions. Use when you need to debug, troubleshoot, diagnose, or
  figure out why something is broken — especially when in-depth analysis of the
  reasons and an adversarial validation of the proposed solution are needed.
```

The trigger verbs in the `description` field — *debug, troubleshoot, diagnose, figure out why something is broken* — are exclusively failure-mode verbs. Claude Code reads this field to decide when to invoke the skill. Adding "research ideas and options" would require stuffing qualitatively different trigger language into the same sentence, diluting the signal for both use cases and making the skill harder to route accurately.

---

## E2: Investigation Approach block is symptom-and-trace-only

**Source:** `plugin/skills/investigate/SKILL.md:22-27`

```
## Investigation Approach

- Trace backward from symptoms — don't guess, follow the code.
- Launch parallel `evidence-based-investigator` agents for different angles
  simultaneously — one for the error path, one for the data flow, one for
  recent changes.
- Add one or more specialist analysts **in parallel with** the investigators
  when the bug type calls for it (concurrency, data flow across boundaries,
  database or query behavior).
```

Every heuristic here assumes a symptom exists: "trace backward from symptoms," "one for the error path," "when the bug type calls for it." Open-ended idea research has no symptom, no error path, no bug type. The approach block is not conditionally structured — it is a flat list of directives, all of which presuppose failure-mode work. Making it serve research would require rewriting or adding a parallel, conditional block that selects a completely different investigation posture.

---

## E3: Specialist dispatch is fully bug-classified

**Source:** `plugin/skills/investigate/SKILL.md:38-46`

```
Classify the bug from the user's symptom description before launching.
Skip any specialist that does not apply. Dispatch every applicable specialist
in parallel with the `evidence-based-investigator` agents in the same message.

1. **Launch concurrency-analyst** — when the symptom involves intermittent
   failures, race conditions, deadlocks ...
2. **Launch behavioral-analyst** — when the symptom involves data transformed
   wrong, values lost between modules, errors swallowed ...
3. **Launch data-engineer** — when the symptom involves wrong data in the
   database, slow queries, N+1 ...
```

The conditional dispatch logic for every specialist is gated on "symptom involves X." There is no branch for "topic is X" or "the question asks about X option vs. Y option." Research of ideas would need a completely different specialist roster — or no specialists at all — because the classification predicate ("classify the bug") does not apply.

---

## E4: The output template's first two sections are structurally bug-only

**Source:** `plugin/skills/investigate/references/template.md:1-57`

```
# Investigation: {Issue Title}

## Problem Statement

<!-- Describe the problem in concrete terms. Include: -->
<!-- - Symptoms: What is happening? (error messages, unexpected behavior,
       failed tests) -->
<!-- - Expected behavior: What should happen instead? -->
<!-- - Conditions: When does it occur? (specific inputs, environments, timing) -->
<!-- - Impact: Who/what is affected? (users, builds, deployments, other
       features) -->

## Evidence Summary

...

## Root Cause Analysis

### Summary
<!-- One sentence stating the root cause. -->

### Detailed Analysis
<!-- Explain the root cause in detail. Reference evidence items by number:
     (E1), (E2), etc. -->
<!-- Trace the causal chain from root cause to symptom, showing how each
     piece of evidence supports the conclusion. -->
```

"Problem Statement," "Symptoms," "Expected behavior," "Conditions," "Impact," and "Root Cause Analysis" are all structurally wrong headers for an idea-research output. Research of ideas and options produces a landscape (options, trade-offs, precedents, constraints) — not a causal chain from failure to root cause. Using this template for research would either leave most fields empty or require artificial reinterpretation of every field's purpose.

---

## E5: Steps 2-4 form a single linear pipeline oriented entirely toward a fix

**Source:** `plugin/skills/investigate/SKILL.md:48-71` (Steps 2, 3, and 4)

```
## Step 2: Document Root Cause
Write to the plan file using the template at references/template.md. Fill in
these sections:
1. Problem Statement
2. Evidence Summary
3. Root Cause Analysis

## Step 3: Plan the Fix
Design a fix that **directly addresses the root cause** from Step 2 ...
1. Coding Standards Reference
2. Planned Fix

## Step 4: Validation (CRITICAL)
Launch `adversarial-validator` agents and pass them the complete evidence
summary (all E1-EN items with full code snippets), the root cause analysis,
and the planned fix with all file changes. Do not summarize — the validator
needs verbatim detail to challenge effectively.
```

The pipeline is: gather evidence → name root cause → design fix → validate fix. Each step feeds the next and the terminus is "a fix." Research of ideas has a different terminus: "an informed recommendation" or "a landscape of options." To accommodate research, Step 2 would need a new section structure, Step 3 would need to become "Evaluate Options" or similar, and Step 4's `adversarial-validator` invocation would need entirely different input (no "planned fix" exists in open-ended research).

---

## E6: `adversarial-validator` is coupled to "investigation + fix" as a unit

**Source:** `plugin/agents/adversarial-validator.md:1-4` (frontmatter description)

```
description: "Assumes investigation evidence is WRONG and the proposed fix
will FAIL. Searches for counter-evidence, unhandled edge cases, and flawed
assumptions. Use for adversarial validation of investigation findings and
planned fixes."
```

**Source:** `plugin/agents/adversarial-validator.md:8`

```
You will receive an evidence summary, root cause analysis, and planned fix.
Attack all three.
```

The agent's identity — "assumes the proposed fix will FAIL" — is coupled to the existence of a "planned fix." In idea research, there may be no fix and no single root cause. The validator's three required strategies ("Challenge the Evidence," "Challenge the Fix," "Challenge the Assumptions") map cleanly onto bug investigation but would need one of their three legs replaced for research: there is no "fix" to challenge when the output is a comparative options landscape. The agent could still be used for adversarial review of research conclusions, but a different framing of the three strategies (and a different input contract) would be required, which means either modifying the agent or dispatching it with explicit framing gymnastics.

---

## E7: `evidence-based-investigator` is more reusable — but still symptom-vocabulary-heavy

**Source:** `plugin/agents/evidence-based-investigator.md:1-4` (frontmatter)

```
description: "Investigates codebase issues by gathering concrete evidence —
file paths, line numbers, code snippets, error messages, git history, and test
coverage. Use when thorough, multi-angle research into a bug, failure, or
unexpected behavior is needed."
```

**Source:** `plugin/agents/evidence-based-investigator.md:12-20` (Domain Vocabulary)

```
root cause, proximate cause, contributing factor, symptom vs. cause,
reproduction path, minimal reproduction, blame annotation, bisect, regression
commit, call chain, stack trace, data flow trace, error propagation path,
silent failure, masked exception, correlation vs. causation, temporal
correlation, test coverage gap, fixture drift
```

The agent's domain vocabulary is entirely bug-investigation vocabulary: "symptom," "regression commit," "stack trace," "error propagation path," "silent failure." The agent's evidence-gathering protocols (trace code paths, check git history, examine test coverage) are also codebase-failure oriented. For research of ideas outside the codebase — comparing libraries, evaluating design patterns, assessing API trade-offs — these protocols produce little or no useful output. The `evidence-based-investigator` is partially reusable for codebase-grounded research (e.g., "gather evidence on how this project currently handles X before recommending an approach") but is a poor fit for externally-oriented idea research.

---

## E8: The long-form docs define `/investigate`'s identity around failure and breaking things

**Source:** `docs/skills/investigate.md:9-11` (TL;DR)

```
- **What it does.** Evidence-based investigation of a bug, failure, or
  unexpected behavior, followed by adversarial validation of the proposed fix.
- **When to use it.** Something is broken and you want a root cause backed by
  file-level evidence, not a guess.
```

**Source:** `docs/skills/investigate.md:23-29` (When to use it — Invoke when)

```
- A bug, failure, or unexpected behavior needs a root cause backed by
  code-level evidence.
- An integration or API call is misbehaving and you want a trace from
  symptoms to data flow to recent changes.
- You suspect a regression and want the investigation to consider git history
  alongside the code.
- You want the proposed fix adversarially validated, not just designed, before
  writing any code.
```

Every "invoke when" trigger is a failure state. The docs would need new "invoke when" bullets that use entirely different framing (no "broken," "misbehaving," "regression," "fix") to accommodate research. Adding those bullets alongside the current failure-mode bullets creates reader confusion about when to use which mode.

---

## E9: The Final Summary section in the template has no analog in research output

**Source:** `plugin/skills/investigate/references/template.md:128-136`

```
## Final Summary

- **Root Cause:** <!-- What caused the problem -->
- **Fix:** <!-- What the planned changes will do -->
- **Why Correct:** <!-- Reference the strongest evidence supporting the fix -->
- **Validation Outcome:** <!-- What validation confirmed or changed -->
- **Remaining Risks:** <!-- See Confidence Assessment above -->
```

For a bug investigation, all five fields have clear answers. For research of ideas, "Root Cause" does not apply (there is no failure), "Fix" does not apply (there is no defect to fix), and "Why Correct" becomes ambiguous. A research summary would need fields like "Options Evaluated," "Recommended Approach," "Evidence Supporting Recommendation," and "Trade-offs and Open Questions." These are categorically different fields, not just renamed ones.

---

## E10: No evidence of any conditional or research-mode branching in the existing skill

Searched `plugin/skills/investigate/SKILL.md`, `plugin/skills/investigate/references/template.md`, and `docs/skills/investigate.md` for conditionals, mode-switches, or any language suggesting the skill handles non-bug use cases. None found. The skill is a single linear workflow with only one type of conditionality: which specialist analysts to add based on bug type. There is no provision for an alternate workflow path when no bug or symptom exists.

---

## Implication for the decision

Every layer of `/investigate` — description frontmatter, Investigation Approach, specialist dispatch conditionals, the five-step pipeline, the output template, and both agent definitions — is coupled tightly to the "something is broken, find the root cause, plan the fix, validate the fix" model. The coupling is not incidental phrasing; it is structural: each step feeds the next in a pipeline that terminates at "a validated fix plan." Research of ideas and options terminates at "an informed landscape of options and a recommendation," which is a categorically different terminus.

Expanding `/investigate` to cover research would require branching or rewriting: the description frontmatter (triggering accuracy), the investigation approach (symptom-trace vs. option-survey), the specialist roster (bug classifiers vs. research-appropriate agents), the output template (Problem Statement / Root Cause / Planned Fix vs. Research Question / Options / Recommendation), the adversarial-validator invocation contract (it requires a "planned fix" to attack), and all five "invoke when" bullets in the long-form doc. That volume of change is equivalent to writing a new skill. The skill's existing identity — evidence-based bug investigation — is well-defined and high-value; overloading it would degrade triggering accuracy and make it harder for users to match the right skill to their need. The evidence strongly supports a separate `/research` skill rather than expansion of `/investigate`.
