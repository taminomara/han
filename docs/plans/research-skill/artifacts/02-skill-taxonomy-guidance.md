# Skill Taxonomy Guidance: Separate Skill vs. Expansion of /investigate

Evidence angle: What Han's own authoring guidance and conventions say about when a capability should be a separate skill versus an expansion of an existing one.

---

## E1: The single-responsibility rule for skills

**Source:** `docs/guidance/skill-building-guidance/skill-decomposition.md:7-9`

```
### Rule: Single responsibility, one skill, one concern

A skill should address a single concern. If a skill does both analysis and
integration, or both gathering and posting, it's doing too much.
```

**Relevance:** This is the primary structural rule. If "research" (exploration of ideas and solutions) and "investigation" (root-cause analysis of a broken thing) are different concerns, the rule requires them to be separate skills. The relevant test is whether the two purposes are independent — not whether they share vocabulary.

---

## E2: The "only split when the parts can function independently" counter-rule

**Source:** `docs/guidance/skill-building-guidance/skill-decomposition.md:35-40`

```
Keep together when:

- The steps are sequential and tightly coupled.
- Splitting would create skills that can't function independently.
- The skill is short and focused even with multiple steps.
```

And the summary checklist at line 106:

```
5. Only split when the parts can function independently.
```

**Relevance:** This is the guard against over-splitting. The question it raises: can a `/research` skill function independently of `/investigate`? Evidence gathering for "what technology should I use?" or "how does this API work?" does not depend on having a broken symptom, a codebase trace, or an adversarial validator. The two would be independently invocable, satisfying this counter-rule.

---

## E3: The "when to split" criteria — independent concerns and bug isolation

**Source:** `docs/guidance/skill-building-guidance/skill-decomposition.md:29-33`

```
Split when:

- The skill has **independent concerns** (analysis vs. integration, gathering vs. posting).
- **A bug in one part** requires debugging unrelated parts.
- **One part is reusable** without the other (for example, code review without GitHub).
- The skill prompt is **so long** the LLM struggles to follow it consistently.
```

**Relevance:** Research (gathering information about options and ideas) and root-cause investigation (tracing a bug to its origin) are independent concerns. A change to the research workflow (e.g., adding a technology-comparison agent) would have no logical connection to changing the bug-diagnosis workflow. They are independently reusable: you want research without a broken thing to fix, and you want investigation without a technology question to answer. Both of the primary split criteria apply.

---

## E4: /investigate's description is locked to failure symptoms

**Source:** `plugin/skills/investigate/SKILL.md:3-12`

```yaml
description: >
  Evidence-based investigation of issues, bugs, API calls, integrations, and
  other aspects of software development that need a deep dive to find the root
  cause and solutions. Use when you need to debug, troubleshoot, diagnose, or
  figure out why something is broken — especially when in-depth analysis of the
  reasons and an adversarial validation of the proposed solution are needed. Does
  not review code for quality or style — use code-review for auditing changes or
  gh-pr-review for posting review feedback to GitHub. Does not assess
  architectural health or structural risk — use architectural-analysis for
  architectural concerns.
```

**Relevance:** Every trigger phrase in this description is failure-oriented: "debug," "troubleshoot," "diagnose," "why something is broken," "root cause." Adding "research a technology option" or "explore how an API works" to this description would make it overbroad: Claude would route open-ended information-gathering requests through a skill built around adversarial validation and fix planning. The existing description has no room for a non-failure trigger without violating the guidance rule that "an overbroad description means false triggers."

---

## E5: /investigate's internal workflow is structured around a broken symptom

**Source:** `plugin/skills/investigate/SKILL.md:23-46`

```
## Investigation Approach

- Trace backward from symptoms — don't guess, follow the code.
- Launch parallel `evidence-based-investigator` agents for different angles simultaneously — one for the error path, one for the data flow, one for recent changes.

## Step 1: Research and Investigation

### Conditional specialist dispatch

Classify the bug from the user's symptom description before launching. Skip any
specialist that does not apply.
```

And Step 3:

```
Resolve project config: read CLAUDE.md's ## Project Discovery section for
docs, ADR, and coding-standards directories... Design a fix that directly
addresses the root cause from Step 2 — fix the underlying problem, not
symptoms.
```

And Step 4:

```
Launch `adversarial-validator` agents and pass them the complete evidence
summary (all E1-EN items with full code snippets), the root cause analysis, and
the planned fix with all file changes.
```

**Relevance:** Every step of /investigate presupposes a thing that is broken and needs a fix plan. The skill dispatches adversarial validation against a proposed fix, writes a "Planned Fix" section, and ends with approval-to-implement. Research for ideas, options, or understanding does not produce a fix plan or require adversarial validation of a solution. Expanding /investigate to handle general research would require either (a) a completely parallel step tree that shares almost no logic, or (b) forcing research outputs into an investigation-shaped artifact they do not fit.

---

## E6: The frontmatter description-competition rule requires crisp boundaries

**Source:** `docs/guidance/skill-building-guidance/skill-description-frontmatter.md:3-13`

```
The `description` field in SKILL.md frontmatter is the primary mechanism Claude
uses to decide when to invoke a skill. Every installed skill's description is
always loaded into Claude's context, where descriptions compete against each
other for selection. A thin description means missed triggers — users ask for
something the skill handles, but Claude doesn't recognize the match. An
overbroad description means false triggers — Claude invokes the wrong skill
because descriptions overlap without clear boundaries.
```

And the four-component rule at lines 20-26:

```
A complete description answers four questions:

- **What** — What does this skill do?
- **When to use** — What user intents or situations should trigger it?
- **Boundary** — What should NOT trigger it? (When to use a different skill or no skill at all.)
- **Trigger breadth** — What alternative phrasings, synonyms, or related concepts should also match?

Minimum 3 sentences. Typically 3-5 sentences. Skills in crowded spaces
(multiple similar skills in the same plugin) may need more to disambiguate.
```

**Relevance:** If /investigate were expanded to include research, both its trigger breadth and its boundary would need rewriting. The boundary statement would need to explain when to use investigation vs. research, but both would be in the same skill — creating the exact internal confusion that boundary statements are designed to prevent between sibling skills. A separate skill solves this cleanly: each description can name the other in its boundary.

---

## E7: The two-direction disambiguation rule applies to closely related skills

**Source:** `docs/guidance/skill-building-guidance/skill-description-frontmatter.md:83-85`

```
### Rule: Define boundaries by naming sibling skills or scope limits

When sibling skills exist in the same plugin, name them explicitly in the
boundary statement. When no siblings exist, describe the scope limit so Claude
knows where the skill stops.

Disambiguation must work in **both directions**. If `code-review` says "use
`gh-pr-review` for GitHub posting," then `gh-pr-review` must also say "use
`code-review` for local review without GitHub." One-way disambiguation leaves
a gap that Claude can fall through.
```

**Relevance:** The guidance explicitly models peer skills (`code-review` / `gh-pr-review`) that do related but distinct things and handle disambiguation by pointing at each other in both directions. A `/research` skill and `/investigate` skill would follow exactly this pattern: each names the other in its boundary. The guidance has a ready-made mechanism for this case; it does not have a mechanism for "two concerns inside one skill that needs to say do not use me for X — but also, X is inside me."

---

## E8: /investigate's long-form doc scopes it to failure-only

**Source:** `docs/skills/investigate.md:9-11`

```
## TL;DR

- **What it does.** Evidence-based investigation of a bug, failure, or
  unexpected behavior, followed by adversarial validation of the proposed fix.
- **When to use it.** Something is broken and you want a root cause backed by
  file-level evidence, not a guess.
```

And the "Do not invoke for" list at lines 32-37:

```
**Do not invoke for:**

- **Code review.** Use `/code-review` for a correctness, testing, and
  compliance audit of a branch.
- **Architectural analysis.** Use `/architectural-analysis` for coupling, data
  flow, concurrency, and SOLID assessment of a module.
- **Test planning.** Use `/test-planning` when the gap is coverage, not a bug.
- **Plan review.** Use `/iterative-plan-review` for multi-pass review of an
  existing plan.
```

**Relevance:** The canonical long-form doc positions /investigate as strictly "something is broken." The CONTRIBUTING.md convention is that the long-form doc is the canonical source — adding research to /investigate would require rewriting this canonical definition, and the result would be a skill whose TL;DR can no longer be stated in one sentence.

---

## E9: Adding a skill requires specific bookkeeping — counts are tracked

**Source:** `CONTRIBUTING.md:31-32`

```
5. Update the skill counts and catalog so they stay accurate: the skill catalog
and "Counts to verify when editing indexes" line in Root CLAUDE.md, the count
in Concepts ("What does the plugin include?"), and the counts in the README.
If the skill belongs to a new category, add it to the category lists too.
```

And `CLAUDE.md` (project map), which records:

```
├── skills/         # 18 skill directories, each with SKILL.md + references/
```

And `docs/concepts.md:95`:

```
- **18 skills.** The skills index groups them by purpose...
```

**Relevance:** Adding a skill carries a defined, manageable cost: update counts in four places, add a long-form doc, add an index entry, possibly add a new category. The convention explicitly anticipates this cost ("Counts to verify when editing indexes"). The cost is not an argument against adding a skill — it is evidence that the project has normalized skill addition as a routine operation.

---

## E10: The "one canonical source per concept" convention

**Source:** `CONTRIBUTING.md:60`

```
**One canonical source per concept.** The long-form doc is canonical. The
Skills Index and Agents Index carry scent only. One sentence plus a link.
The README never duplicates long-form content.
```

**Relevance:** "Research" and "investigation" are distinct concepts that users would look up separately. Putting both in /investigate would require the long-form doc to carry both concepts, breaking the "one canonical source per concept" convention. A user looking for research guidance would need to know to look inside the investigation doc.

---

## E11: The "Does not X — use Y" pattern used across all existing SKILL.md descriptions

**Source:** Grep of `plugin/skills/*/SKILL.md` for "Does not"

The following are verbatim boundary statements from existing skill descriptions. Every case is a separate skill pointing at another separate skill:

- `plugin/skills/code-review/SKILL.md:3`: `Does not post comments to GitHub pull requests — use gh-pr-review for that. Does not analyze architectural structure or module boundaries — use architectural-analysis for that.`
- `plugin/skills/issue-triage/SKILL.md:9-10`: `Does not investigate root causes or trace code paths — use investigate for debugging, diagnosis, and root cause analysis.`
- `plugin/skills/plan-a-feature/SKILL.md:14-15`: `Does not investigate bugs or failures — use investigate.`
- `plugin/skills/plan-implementation/SKILL.md:19-20`: `Does not investigate bugs or failures — use investigate. Does not perform file-level code review — use code-review.`
- `plugin/skills/investigate/SKILL.md:9-12`: `Does not review code for quality or style — use code-review for auditing changes or gh-pr-review for posting review feedback to GitHub. Does not assess architectural health or structural risk — use architectural-analysis for architectural concerns.`

**Relevance:** In every case, "Does not X" points to a different skill. The pattern is structurally designed to route between separate skills, not between two modes of the same skill. If research were inside /investigate, /investigate could not use "Does not research ideas or explore options — use..." because there would be nowhere external to point. The pattern that all existing skills use would be broken.

---

## E12: The entity taxonomy test — can the process be flowcharted?

**Source:** `docs/guidance/plugin-entity-taxonomy.md:27-28, 48`

```
## Skills: Process Engine

Deterministic, repeatable processes with consistency and expertise. Can have
companion reference folders and external files for support and detail, and
scripts to execute. No personality, taste, or adaptive judgment. Just
disciplined execution.

Test: *"Can I flowchart every path?"* → Skill.
```

And the Decision Heuristic at line 48:

```
1. Deterministic, flowchartable, repeatable process? → **Skill**
```

**Relevance:** A research process — gather sources, synthesize findings, surface options, document tradeoffs — is a distinct flowchartable process from bug investigation. It starts from a question, not a symptom. It ends with a synthesis of options, not a fix plan. Both processes pass the "can I flowchart every path?" test independently, which means both independently qualify as skills.

---

## Implication for the Decision

Every applicable Han authoring rule points toward a separate skill.

The single-responsibility rule says one skill, one concern — and "research of ideas and information" is a different concern from "root-cause diagnosis of a broken thing." The split criteria are met: the two purposes are independently invocable, a change to one would not require debugging the other, and each is useful without the other. The independence counter-rule is also satisfied: a research skill can function without an investigation, and vice versa.

The description system makes the case structurally. /investigate's existing description is locked to failure-oriented triggers (debug, troubleshoot, diagnose, broken). Expanding it to cover research triggers would either produce false triggers — Claude routing "how should I approach this API integration?" through adversarial fix-plan machinery — or require a description so hedged it becomes unparseable. The two-direction disambiguation rule and the "Does not X — use Y" pattern both presuppose two separate skills pointing at each other.

The internal workflow of /investigate is built around a symptom, a fix plan, and adversarial validation of that fix. Research produces none of these artifacts. Adding a parallel step-tree for research inside /investigate would be two skills stapled together under one name — precisely what the single-responsibility rule prohibits.

Adding a skill is a normalized operation in this codebase. The CONTRIBUTING.md documents the exact checklist. The cost is a long-form doc, an index entry, and count updates in four files. The conventions have accommodated 18 skills already; a 19th follows the same path.
