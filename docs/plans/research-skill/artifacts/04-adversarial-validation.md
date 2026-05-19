# Adversarial Validation: Separate `/research` Skill vs. Expansion of `/investigate`

Adversarial validator tasked with building the strongest possible case *against* the "separate skill" recommendation. Every claim below is backed by direct file inspection. The investigation attempts genuine falsification — not ceremonial pushback.

---

## V1: The "API calls and integrations" language in the existing description is broader than the investigators claimed

**Strategy:** Challenge the Evidence

**Hypothesis:** Evidence items E1 (Angle 1) and E4 (Angle 2) assert that `/investigate`'s description is "unambiguously bug/failure-framed." This may be overstated — the actual frontmatter contains language that does not require a failure state.

**Investigation:** Read `plugin/skills/investigate/SKILL.md:2-13` verbatim.

```
name: "investigate"
description: >
  Evidence-based investigation of issues, bugs, API calls, integrations, and
  other aspects of software development that need a deep dive to find the root
  cause and solutions.
```

"Issues," "API calls," "integrations," and "other aspects of software development that need a deep dive" are not exclusively failure-mode concepts. An engineer researching how a third-party API works, how to integrate a new service, or what "other aspects" of a system do before building anything — all of these can be described as "API calls or integrations that need a deep dive." The phrase "find the root cause and solutions" arguably frames it, but "solutions" does not require a pre-existing failure; it can mean "what solution to adopt."

The trigger verbs that follow — "debug, troubleshoot, diagnose, figure out why something is broken" — are failure-oriented, but the prior noun list is genuinely ambiguous. The investigators cited only the verb section as evidence of failure-framing and soft-pedaled the noun section. A user asking "how should I integrate this API?" could match the description as written.

**Result:** Partially Refuted. The description is failure-*leaning* but not failure-*locked* as the investigators claimed. The noun list creates genuine ambiguity that the verb list only partially resolves. This weakens E1 from "unambiguously" to "predominantly."

**Impact:** The case for a separate skill is somewhat weakened at the evidence level: the existing description already has a foothold for non-failure research under "API calls, integrations, and other aspects of software development." This means the separation argument cannot rest on "zero overlap in the current description" — the overlap already exists. It does, however, strengthen the case for clarifying the description regardless of which choice is made.

---

## V2: E14 — "Step 1 is already called Research and Investigation" — argues FOR expansion, not against it

**Strategy:** Challenge the Evidence

**Hypothesis:** The investigators cite E14 as a "label collision risk" arguing against expansion. This is a strained interpretation. The presence of the word "research" inside `/investigate`'s Step 1 is evidence that the skill's authors already conceived of research as part of investigation — not evidence that the two are incompatible.

**Investigation:** Read `plugin/skills/investigate/SKILL.md:30-34`.

```
## Step 1: Research and Investigation

### Always dispatch

Launch at least 2 `evidence-based-investigator` agents in parallel, each
investigating from a different angle — for example, one tracing the error
path and another following the data flow.
```

The step title "Research and Investigation" uses "research" as the first word. The body narrows it to bug-tracing, but the choice of title reflects that the skill's authors perceived the initial evidence-gathering phase as research. An expansion argument could use this as evidence: the existing skill already has a research phase (Step 1), and extending that phase's scope to cover non-failure evidence-gathering is a natural evolution, not a violation. A user who says "I want to research how this API works before building anything" is asking for exactly what Step 1 does — multi-angle evidence gathering — with a different starting point.

The investigators attempt to neutralize E14 by calling it a "label collision risk." But a label collision is a maintenance concern, not a capability argument. It could be resolved by renaming Step 1 to "Investigation" or "Evidence Gathering" rather than writing a new skill. The investigators used this evidence to support the conclusion it nominally challenges, which is a symptom of confirmation bias.

**Result:** Refuted as stated. E14 can be read as supporting expansion just as plausibly as it supports separation. The investigators' framing of E14 as evidence against expansion is one interpretation; the equally valid reading is that the skill already labels its first phase "research" because that is what it does.

**Impact:** E14 should be removed from the evidence list supporting separation, or reformulated neutrally. As stated it is not evidence against expansion; it is a cosmetic concern resolvable by a one-word rename.

---

## V3: The gh-pr-review precedent (Angle 3, E3) is undermined by a current guidance contradiction

**Strategy:** Challenge the Evidence

**Hypothesis:** Angle 3, E3 cites `gh-pr-review` calling `/code-review` via the `Skill` tool as the canonical "separate skill even when implementation overlaps" precedent. This precedent is directly contradicted by `skill-composition.md`, which now prohibits sub-skill composition.

**Investigation:** Read `docs/guidance/skill-building-guidance/skill-composition.md` in full.

```
# Skill Composition

Skills should not call other skills via the Skill tool. Sub-skill calls have
proven too inconsistent and unreliable to use in practice.

These issues stem from fundamental limitations in how sub-skill context is
handled, not from how individual skills are written. No amount of instruction
tuning or `context: fork` configuration has reliably resolved them.
```

And from `plugin/skills/gh-pr-review/SKILL.md:35`:

```
Invoke the `/code-review` skill to perform the full code review.
```

The `gh-pr-review` skill still uses `Skill` in its `allowed-tools` (`allowed-tools: ..., Skill, Agent`) and explicitly invokes `/code-review` at Step 2. But the current guidance at `skill-composition.md` says skills should *not* call other skills. This means `gh-pr-review` is a **deprecated pattern** — not a current best-practice precedent. The investigators cited it as "Han's precedent for splitting on trigger even when implementation overlaps heavily" without checking whether that precedent is still current guidance.

Furthermore, `skill-decomposition.md:67` still refers to `gh-pr-review → code-review` as an example of orchestration composition — but this is directly in tension with `skill-composition.md`'s prohibition. The decomposition doc has not been updated to reflect the composition doc's ruling. This is a live contradiction in the guidance itself.

A `/research` skill built as a peer to `/investigate` (not calling into it) would not have the `gh-pr-review` composition problem. But the precedent the investigators cited to support separation is itself a guideline violation the project has not yet resolved. The argument that "Han gave it its own skill anyway" may be a description of a mistake that is being preserved for backward compatibility, not a design principle to replicate.

**Result:** Partially Refuted. The `gh-pr-review` precedent is structurally suspect: it relies on sub-skill composition that current guidance explicitly discourages. The "separate skill" argument from E3 is weakened because the model it cites is no longer recommended. This does not, by itself, argue against a separate `/research` skill — but it removes one of the three angles' strongest pieces of evidence from the usable pool.

**Impact:** The separation recommendation cannot lean on `gh-pr-review` as a precedent. A separate `/research` skill would be built differently (standalone, not calling `/investigate`), which means its implementation needs a fresh rationale, not an appeal to `gh-pr-review`'s structure.

---

## V4: A third option — reframe `/investigate` as `/deep-dive` with two modes — was never evaluated

**Strategy:** Challenge the Assumptions

**Hypothesis:** The investigation was framed as a binary: separate skill or expand `/investigate`. No investigator examined whether a rename-and-reframe of `/investigate` to a broader concept (e.g., "deep-dive," "analyze," "explore") with explicit mode routing could satisfy both use cases under one entry point.

**Investigation:** No artifact among the three angles contains any analysis of a third option. Searched `01-investigate-skill-analysis.md`, `02-skill-taxonomy-guidance.md`, and `03-precedent-and-cost.md` for: "third option," "rename," "reframe," "deep-dive," "mode," "modes," "two-mode," "expand and rename." None found.

The existing description already contains language compatible with a broader framing: "other aspects of software development that need a deep dive to find the root cause and solutions." If the skill were renamed or redescribed as a "deep exploration" skill with explicit routing — "Use for: (1) bug and failure investigation, (2) research of ideas, options, and information" — the disambiguation rule (`skill-description-frontmatter.md`) could still be satisfied through explicit trigger language for each mode.

This option was not examined. The investigation did not apply the YAGNI rule to its own process: no evidence was cited that a third option was considered and rejected. The summary at the bottom of each artifact leaps to the binary choice without establishing that the third option was evaluated.

The cost of a rename-and-reframe is lower than creating a new skill: no new `plugin/skills/{name}/` directory, no new long-form doc, no count bumps in four files. The trade-off is a more complex description and potentially a two-branch step structure inside the skill. Whether that complexity crosses the "too long for the LLM to follow consistently" threshold (the fourth split criterion in `skill-decomposition.md:34`) was never tested.

**Result:** Refuted — the assumption that the decision is binary was not examined. The third option (rename-and-reframe) has plausible merit and zero cost analysis against it. The investigation team's mandate appears to have closed around the binary before exploring the space.

**Impact:** The recommendation is incomplete. Before adopting "separate skill," the team should evaluate the rename-and-reframe option with the same rigor applied to the other two options. If it fails the single-responsibility rule, say so with evidence. As of the three artifacts, it was not examined.

---

## V5: The "independent concerns" split criterion is applied without testing the shared evidence-gathering engine

**Strategy:** Challenge the Assumptions

**Hypothesis:** Angle 2, E3 argues that "research (gathering information about options and ideas) and root-cause investigation (tracing a bug to its origin) are independent concerns" and therefore must be separate skills. This assertion is applied without checking what both workflows would share, which the decomposition rule (`skill-decomposition.md:35-40`) requires.

**Investigation:** Read `skill-decomposition.md:35-40`:

```
Keep together when:

- The steps are sequential and tightly coupled.
- Splitting would create skills that can't function independently.
- The skill is short and focused even with multiple steps.
```

Now compare the actual processes. Both "research a technology option" and "investigate a bug" share:

1. An initial evidence-gathering phase using `evidence-based-investigator` or `codebase-explorer` agents.
2. A synthesis step producing a numbered evidence list.
3. An adversarial validation phase (even research benefits from challenging whether the evidence supports the recommendation).
4. A final summary with a recommendation.

The workflows diverge at: (a) what triggers them (symptom vs. question), and (b) what they output (fix plan vs. options landscape). But the underlying engine — gather evidence, synthesize, validate adversarially, summarize — is shared. Under the "keep together when steps are sequential and tightly coupled" criterion, if the shared engine constitutes the majority of the workflow, the criterion cuts *against* splitting.

The investigators did not compute what fraction of the workflow is shared vs. distinct. They asserted independence without measuring the overlap. A more rigorous application of the split criteria would require showing that the distinct parts — "classify the bug" and "design a fix" — dominate the workflow, not just that they exist. If 60% of both workflows is identical evidence-gathering and adversarial validation, and only 40% differs, the "keep together" criterion becomes competitive with the "split when independent concerns" criterion.

**Result:** Partially Refuted. The split criteria were applied selectively (the "split when" criteria were cited and the "keep together" criteria were not seriously tested against the shared engine). The investigators cited all four "split when" criteria as applying, but did not test the three "keep together" criteria with the same rigor.

**Impact:** The recommendation is not clearly wrong, but the analysis is one-sided. A thorough analysis would measure the shared fraction of both workflows and apply both sets of criteria. If research and investigation share roughly half their workflow steps, the "keep together when steps are sequential and tightly coupled" criterion has a real claim.

---

## V6: The "no slot is unoccupied" argument for a new skill is weakened by plan-a-feature's exploration mode

**Strategy:** Challenge the Evidence

**Hypothesis:** Angle 3, E6 and E7 argue that no current skill covers "research of ideas, possible solutions, and information" — that the slot is "genuinely empty." This is too strong: `/plan-a-feature` performs extensive research before and during its interview loop, and `/coding-standard` explicitly advertises research-backed rationale for new standards.

**Investigation:** Read `plugin/skills/plan-a-feature/SKILL.md:60-71` (Step 2: Discover Before Asking):

```
Before asking the user anything beyond the initial framing, explore the
codebase and project documentation to gather context that will answer as many
design-tree questions as possible. Use Glob and Grep to find:
- CLAUDE.md, AGENTS.md, and any project-discovery.md
- ADRs in docs/adr/ ...
- Coding standards ...
- Existing feature specifications or PRDs ...
- Code adjacent to what the feature touches
```

And from `docs/skills/coding-standard.md:29`:

```
A new standard needs research-backed rationale (testing boundaries, error
handling, transaction patterns). The skill grounds the standard in evidence
from the codebase and surfaces Correct and Avoid examples.
```

The investigators correctly note (Angle 3, E7 and E10) that these are "downstream research" bounded by a specific output type. But the "slot is empty" claim overstates the gap. A user who wants to research "how should I handle errors in this project?" before choosing an approach does have a current entry point: `/coding-standard` already covers research of that question. A user who wants to research "what are the options for this feature?" has `/plan-a-feature`.

The genuinely empty slot is narrow: *open-ended, output-agnostic research of ideas and information that does not terminate in a fixed artifact type*. That is a real gap, but the investigators painted it broader than the evidence supports. The "no current skill matches this trigger" claim is true for the *most general* version of research; it is false for several bounded versions.

**Result:** Partially Refuted. The "slot is empty" argument overstates the gap. The gap is real but narrower: it is specifically *output-agnostic, open-ended research* that lacks a home, not all research. This narrower gap still supports a separate skill, but the scope of the new skill is more constrained than the investigators implied — it should be scoped precisely to the open-ended, output-agnostic case, and its "does not" boundaries need to explicitly route to `/plan-a-feature` and `/coding-standard` for the bounded research they already cover.

**Impact:** If a `/research` skill is built, its description must carefully distinguish it from `/plan-a-feature`'s exploration mode and `/coding-standard`'s research-backed rationale mode, or it will create the trigger collision the investigators were arguing against.

---

## V7: A new /research skill would itself face triggering collisions — the investigators' own concern, unexamined for the recommendation

**Strategy:** Challenge the Fix

**Hypothesis:** The investigators argued that expanding `/investigate` would cause false triggers and description overlap. They did not apply the same scrutiny to whether a new `/research` skill would face the same problem against `/plan-a-feature`, `/gap-analysis`, `/architectural-analysis`, and `/coding-standard`.

**Investigation:** Read the descriptions of the four adjacent skills:

`plugin/skills/plan-a-feature/SKILL.md:3-9`: "Builds a feature specification from scratch through a relentless, evidence-based interview that walks the design tree... Explores the codebase, project documentation, coding standards, and ADRs to resolve questions before asking the user."

`plugin/skills/gap-analysis/SKILL.md` (line 3-9): "Performs a gap analysis between two artifacts... Use when the user wants to compare, evaluate, audit, or reconcile one artifact against another."

`plugin/skills/architectural-analysis/SKILL.md:2-6`: "Performs deep architectural analysis of a specified module... Use when the user wants to assess, evaluate, or review the architecture, design quality, dependency structure."

`plugin/skills/coding-standard/SKILL.md:3-10`: "Creates and updates coding standards, conventions, rules, and guidelines."

A `/research` skill with a description broad enough to cover "research of ideas, possible solutions, and information" would have trigger overlap with all four of these skills:

- "Research what approach to take for this feature" → `/plan-a-feature` or `/research`?
- "Research the architecture options for this module" → `/architectural-analysis` or `/research`?
- "Research what's missing from this implementation against the spec" → `/gap-analysis` or `/research`?
- "Research best practices for error handling" → `/coding-standard` or `/research`?

The investigators' core argument against expansion — that overbroad descriptions cause false triggers — applies with equal force to a new `/research` skill. A `/research` skill that is narrow enough to avoid these collisions is narrow enough that its "trigger slot" looks suspiciously like a single use case, not a general capability. The investigators never scoped what the research skill would *not* cover, which means they never tested whether its description could be disambiguated in four directions simultaneously.

The `skill-description-frontmatter.md` guidance requires that disambiguation work in both directions. A `/research` skill would need to say "does not plan features — use plan-a-feature; does not assess architecture — use architectural-analysis; does not create coding standards — use coding-standard; does not compare artifacts — use gap-analysis; does not investigate bugs — use investigate." That is five negative routing lines — already at the upper limit of what fits in 3-5 sentences.

**Result:** Refuted in part. The investigators identified a trigger-collision problem with expansion but did not apply the same analysis to the recommendation. A `/research` skill faces at least four trigger-collision risks that the investigators did not examine. This does not mean the recommendation is wrong, but it means the recommendation's implementation is substantially harder than the artifacts suggest.

**Impact:** The description of any `/research` skill must be scoped aggressively — probably to something like "open-ended, output-agnostic research that does not produce a feature spec, ADR, coding standard, gap report, or investigation plan." That tight scoping may leave the trigger breadth too thin to reliably activate, which is the opposite failure mode from the one the investigators were worried about.

---

## V8: The maintenance cost of two overlapping skills with reciprocal routing is understated

**Strategy:** Challenge the Fix

**Hypothesis:** Angle 3, E11 and E12 frame the cost of adding a new skill as "bounded" at six file changes. The investigators do not account for the ongoing maintenance cost of two overlapping skills with reciprocal routing that must stay in sync.

**Investigation:** Count the reciprocal routing additions required by a new `/research` skill, using the "does not X — use Y" pattern the investigators cite as the canonical pattern (Angle 3, E1-E5):

1. `/investigate` SKILL.md description: add "Does not research ideas, options, or technology choices — use research."
2. `/investigate` long-form doc `When to use it / Do not invoke for`: add "Research. Use /research for open-ended exploration of ideas, options, and information not tied to a specific failure."
3. `/plan-a-feature` SKILL.md description: add "Does not research ideas outside feature planning — use research."
4. `/plan-a-feature` long-form doc: add parallel entry.
5. `/coding-standard` SKILL.md description: add "Does not research general ideas or options — use research."
6. `/coding-standard` long-form doc: add parallel entry.
7. `/architectural-analysis` SKILL.md description: add "Does not research options not tied to a specific module — use research."
8. `/architectural-analysis` long-form doc: add parallel entry.

That is eight reciprocal routing lines (or more, depending on how tight the boundaries are) across four existing skills, each of which then requires its long-form doc to be updated. The investigators counted only the new skill's artifacts (six files) and mentioned "reciprocal routing lines" in a single sentence at the end of Angle 3's summary. They did not count the changes required in existing skills.

Adding these up: six new files plus eight or more updates to existing files across four skills, each of which must stay in sync whenever the research skill's scope evolves. The investigators called this cost "real but bounded." It is bounded — but the bound is closer to 14+ file changes than 6.

**Result:** Partially Refuted. The maintenance cost is real and larger than stated. This does not make the recommendation wrong, but it removes the "low cost" argument from the supporting evidence. The cost comparison between "expand `/investigate`" (complex rewrite of one skill) vs. "separate skill" (6+ new files plus 8+ reciprocal routing updates across four skills) is closer to parity than the investigators suggested.

**Impact:** The recommendation survives but the "bounded cost" framing needs adjustment. The correct framing is: the cost of a separate skill is larger than the artifacts suggest, but still justified by the single-responsibility and disambiguation gains. Calling it "low cost" is inaccurate.

---

## V9: The adversarial-validator coupling argument (E6, Angle 1) is overstated — the agent is already being used non-standardly

**Strategy:** Challenge the Evidence

**Hypothesis:** E6 (Angle 1) argues that `adversarial-validator` is tightly coupled to "investigation + fix" and cannot be used for research validation. But the investigator prompt for this very validation task (the system prompt that dispatched this agent) uses the `adversarial-validator` for something explicitly not a bug fix — it is validating a *design recommendation*.

**Investigation:** The `adversarial-validator` system prompt description states:

```
description: "Assumes investigation evidence is WRONG and the proposed fix
will FAIL. Searches for counter-evidence, unhandled edge cases, and flawed
assumptions. Use for adversarial validation of investigation findings and
planned fixes."
```

But the prompt actually dispatching this agent reads: "You are adversarially validating a DESIGN RECOMMENDATION for the Han Claude Code plugin... THE RECOMMENDATION UNDER ATTACK: Create a SEPARATE `/research` skill..." — this is neither a bug investigation nor a planned fix. The agent is being used outside its stated description *by the investigation that produced these artifacts*, without any description modification.

This proves that `adversarial-validator` is already being stretched beyond its formal description in current practice. If the agent can be repurposed for design recommendation validation without modifying its description, the same agent could be used for research output validation. The investigators' claim that the agent "requires a planned fix to attack" is disproven by the very context in which their artifacts were produced.

**Result:** Refuted. The adversarial-validator coupling argument is incorrect. The agent's *description* requires a "planned fix," but the agent's *actual instructions* — challenge evidence, challenge the fix/recommendation, challenge assumptions — are general enough to apply to any claim-and-recommendation structure. The agent is already being used this way. This evidence weakens E6 significantly.

**Impact:** E6 (Angle 1) should be removed from the evidence supporting separation. The adversarial-validator is not tightly coupled to bug investigation; it is a general adversarial review mechanism that its description undersells. This neither proves nor disproves that `/investigate` should be expanded, but it removes one structural argument from the separation case.

---

## Confidence Assessment

**Level:** Medium

**Rationale:** The "separate skill" recommendation survives adversarial pressure on its core claims. The single-responsibility rule, the description disambiguation rule, and the structural pipeline mismatch (symptom-trace vs. option-survey) are all real. However, five findings above genuinely weaken the evidence base:

- V1 shows the existing description is less failure-locked than claimed.
- V2 shows E14 was misread — it supports expansion as much as separation.
- V3 shows the gh-pr-review precedent cites a pattern current guidance discourages.
- V4 shows the third option (rename-and-reframe) was never examined.
- V9 shows the adversarial-validator coupling argument is empirically false.

None of these individually defeats the recommendation, but together they reveal that the investigators' evidence base was not as solid as presented. The recommendation likely remains correct, but the correct framing is: "the description disambiguation and single-responsibility rules point toward a separate skill; the evidence of total structural incompatibility between the two workflows is weaker than the investigators suggested."

---

## Remaining Risks

1. **The third option (rename-and-reframe) was not evaluated.** If the project's next investigation finds that a two-mode `/investigate` (or a renamed `/explore`) can be described with clean trigger disambiguation, the separate-skill recommendation may not be necessary.

2. **A separate `/research` skill faces four trigger-collision risks (V7) that were not scoped.** Before committing to the recommendation, the research skill's description must be drafted and tested against `/plan-a-feature`, `/coding-standard`, `/gap-analysis`, and `/architectural-analysis`. If disambiguation requires more than five sentences, the skill may not fit the description model.

3. **The maintenance cost is larger than stated (V8).** Roughly 14+ file changes are required, not 6. Any cost-benefit framing in the final recommendation should use the corrected figure.

4. **The shared evidence-gathering engine (V5) was not measured.** If research and investigation share more than half their workflow steps, the "keep together" criterion has a real claim that was never fully answered.

5. **The guidance contradiction between `skill-decomposition.md` and `skill-composition.md` (V3) is unresolved.** The decomposition doc still presents `gh-pr-review → code-review` as a composition pattern while the composition doc prohibits it. This contradiction affects any skill that might compose with `/investigate` or call into another skill. It should be resolved before using either doc as authoritative precedent.
