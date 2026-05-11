# IA Analysis: han plugin documentation set

## Scope

- `/Users/mxriverlynn/dev/testdouble/skills-internal/plugins/han/README.md` (288 lines) — the plugin landing page
- `/Users/mxriverlynn/dev/testdouble/skills-internal/plugins/han/docs/agents/*.md` — 6 long-form agent docs:
  - `data-engineer.md` (196 lines)
  - `devops-engineer.md` (172 lines)
  - `information-architect.md` (136 lines)
  - `junior-developer.md` (146 lines)
  - `project-manager.md` (164 lines)
  - `user-experience-designer.md` (126 lines)
- `/Users/mxriverlynn/dev/testdouble/skills-internal/plugins/han/docs/skills/*.md` — 3 long-form skill docs:
  - `iterative-plan-review.md` (144 lines)
  - `plan-a-feature.md` (137 lines)
  - `plan-implementation.md` (158 lines)
- Manifest files walked for inventory: `plugins/han/.claude-plugin/plugin.json`, `plugins/han/skills/*/SKILL.md` frontmatter, `plugins/han/agents/*.md` frontmatter

Sampling approach: the three long-form skill docs and six long-form agent docs are a complete census (not a sample). The README was read end-to-end. The 14 agents and 10 skills that do not yet have long-form docs were enumerated via directory listing and their short frontmatter descriptions read; their internal bodies were not read because they are outside the audit focus area.

Branch: `han/documentation-updates`

## Reader Context

- **Primary reader goal (JTBD):** When I've just installed the han plugin and don't know where to start, I want to understand what it does and pick the right skill for my current problem, so I can get something useful done in the first ten minutes.
- **Audience segments:**
  - **A1 — Solo/small-team product engineer, first contact.** Has never run a han skill. Arrives at the GitHub README from the marketplace listing or a "see also" link. Needs: what is this, who is it for, what do I run first.
  - **A2 — Returning user in reference-lookup mode.** Knows one or two skills. Evaluating whether a new skill or agent fits a current problem.
  - **A3 — Contributor / plugin author.** Understands the plugin's shape in order to add or edit a skill, agent, or long-form doc.
- **Tasks covered (mapped per audience):**
  - A1: orient → pick a first skill → run it → read its output → decide whether to keep the plugin
  - A2: look up one skill by capability → check "when to use" and "when NOT to use" → compare with neighbors → invoke correctly
  - A3: learn the plugin layout → find the template / pattern for a new skill or agent → follow a documentation convention that already exists
- **Arrival paths considered:** GitHub README at `plugins/han/README.md`; search hits landing on an individual agent or skill long-form doc; a sibling skill's "Related Documentation" link pointing across the docs tree; a marketplace listing (content unknown but treated as a cold arrival).

## Content Inventory Summary

| Path | Topic Type | Audience(s) | Inbound (discovered) | Outbound | Last Changed |
|---|---|---|---|---|---|
| `README.md` | Mixed (concept + tutorial + reference) | A1, A2, A3 | Marketplace listing; GitHub repo root; 6 agent long-forms via "Operator documentation for..." header (implied parent) | 6 agent long-form docs (via `docs/agents/X.md`); 3 skill long-form docs (via `docs/skills/X.md`) | 2026-04-23 |
| `docs/agents/devops-engineer.md` | Reference (operator-facing) | A2 (primary), A3 | README line 98 | `agents/devops-engineer.md`; `docs/agent-building-guidelines/*`; 14 external URLs (sources) | 2026-04-23 |
| `docs/agents/data-engineer.md` | Reference | A2, A3 | README line 100 | `agents/data-engineer.md`; agent-building docs; many external URLs | 2026-04-23 |
| `docs/agents/information-architect.md` | Reference | A2, A3 | README line 104 | `agents/information-architect.md`; agent-building docs; external URLs | 2026-04-23 |
| `docs/agents/junior-developer.md` | Reference | A2, A3 | README line 105 | `agents/junior-developer.md`; agent-building docs; external URLs | 2026-04-23 |
| `docs/agents/project-manager.md` | Reference | A2, A3 | README line 106 | `agents/project-manager.md`; agent-building docs; external URLs | 2026-04-23 |
| `docs/agents/user-experience-designer.md` | Reference | A2, A3 | README line 112 | `agents/user-experience-designer.md`; agent-building docs; external URLs | 2026-04-23 |
| `docs/skills/iterative-plan-review.md` | Reference + partial concept | A2, A3 | README line 217 | `skills/iterative-plan-review/SKILL.md`; `/plan-a-feature`, `/plan-implementation`, several agents | 2026-04-23 |
| `docs/skills/plan-a-feature.md` | Reference + partial concept | A2, A3 | README line 230; `docs/skills/plan-implementation.md` | `skills/plan-a-feature/SKILL.md`; `project-manager`, `junior-developer`, `/plan-implementation`, `/iterative-plan-review` | 2026-04-23 |
| `docs/skills/plan-implementation.md` | Reference + partial concept | A2, A3 | README line 243; `docs/skills/plan-a-feature.md` | `skills/plan-implementation/SKILL.md`; many agents; `/plan-a-feature`; `/iterative-plan-review` | 2026-04-23 |

Not-yet-documented, counted by enumeration:

- **Agents without long-form docs (14 of 20):** `adversarial-security-analyst`, `adversarial-validator`, `behavioral-analyst`, `codebase-explorer`, `concurrency-analyst`, `content-auditor`, `edge-case-explorer`, `evidence-based-investigator`, `gap-analyzer`, `project-scanner`, `risk-analyst`, `structural-analyst`, `system-architect`, `test-engineer`. All are referenced only by a one-line entry under README.md §"Custom Agents".
- **Skills without long-form docs (10 of 13):** `/architectural-analysis`, `/code-review`, `/coding-standard`, `/architectural-decision-record`, `/update-pr-description`, `/gh-pr-review`, `/investigate`, `/project-discovery`, `/project-documentation`, `/test-planning`. All are referenced by a one-line entry under README.md §"Skills" (lines 75-89) *and* a longer reference block under §"Skills Reference" (lines 123-288).

Observed inventory facts:

- README.md is 288 lines and carries 22 headings; the "Skills Reference" section alone is 166 lines (lines 123-288), ~58% of the file.
- Each skill currently appears in as many as **three** separate places in README.md: the Getting Started narrative (first 3 skills only), the brief bullet list (§"Skills", lines 75-89), and the detailed "Skills Reference" (lines 123-288).
- Orphan entry-point check: no `docs/README.md` or `docs/index.md` exists. A reader arriving cold at `docs/agents/devops-engineer.md` via search finds a reference page with no link "up" to the plugin landing page. Inbound link text for every agent long-form doc is always the README bullet containing `See [X documentation](docs/agents/X.md) for when and how to use it.` — the only path "in" is from the README; no sibling long-form doc links to it.
- Recency: every file in the focus area was last touched in a single commit (`8dc7c5e`, 2026-04-23) — the plugin rename and information-architect add. This is new material landing in one push; the IA has not yet been stress-tested by reader use.

## Question Log

**Arrival Path**

- **Q1 [Answered]:** How does the primary reader arrive at the plugin? — From the brief: marketplace listing, GitHub README, or a "see also" link from another skill's doc. All three land at `plugins/han/README.md` as the intended front door.
- **Q2 [Assumed]:** Do readers arrive at individual agent/skill long-form docs via external search (Google) or only via the README? — Assumed both, because the files are committed to a public GitHub repo and will index. This assumption underlies IA-006 (EPPO check).
- **Q3 [Answered]:** Can a reader leave a long-form doc and return to the plugin landing page? — Partially. The long-form docs link *down* to agent definitions and build-guidelines docs, but never *up* to `plugins/han/README.md`. Verified: `docs/agents/devops-engineer.md:3` references `../../agents/devops-engineer.md`, and §"Related Documentation" (lines 167-172) points to `docs/agent-building-guidelines/*` — never back to the plugin landing page. Same for every other long-form doc inspected.

**Audience Segmentation**

- **Q4 [Answered]:** How many audiences does the documentation address? — Three (A1, A2, A3), named in the brief.
- **Q5 [Answered]:** Does the structure serve each audience? — No. The README places A1 (first-contact, needs orientation) and A2 (reference lookup, needs a specific skill's behavior) on the same page, at the same visual weight, with A1 content (Getting Started, lines 21-74) sitting above A2 content (Skills Reference, lines 123-288) that repeats material A1 already read. Contributor (A3) has no documented entry point at all.

**Reader Task (JTBD)**

- **Q6 [Answered]:** What is the primary first-contact task? — Pick a first skill and run it within ten minutes. Evidence: explicit statement in the brief.
- **Q7 [Answered]:** Does the current README satisfy that task? — Only for a narrow slice. Getting Started (lines 21-74) names three skills (`/project-discovery`, `/project-documentation`, `/coding-standard`) as the starting sequence. None of the three planning skills (`/plan-a-feature`, `/plan-implementation`, `/iterative-plan-review`) — which have the deepest long-form docs and are the most "headline" capabilities — appear in Getting Started. A reader who arrives wanting to plan a feature sees "start with project discovery" and has to infer, from the later Skills Reference, that a planning path exists.

**Usage Pattern**

- **Q8 [Answered]:** Is the reading order linear or random-access? — Both, depending on audience. A1 reads top-down; A2 jumps to a specific heading; A3 goes digging. The README is structured as linear narrative (Getting Started → Skills → Agents → Installation → Skills Reference), so random-access readers have to scroll past an introductory tutorial and two one-line-per-item lists to reach the reference content.

**Prior Knowledge**

- **Q9 [Answered]:** What does the README assume the reader already knows? — Line 3 calls han a "suite of custom AI skills and agents" and never defines *skill* vs *agent* anywhere in the doc set. A first-time reader is assumed to know what those words mean in Claude Code's plugin system. The README never links to a glossary or to the plugin-entity taxonomy at `docs/plugin-entity-taxonomy.md` (which exists at the repo root but is not referenced from this plugin's docs).
- **Q10 [Answered]:** Do the long-form docs assume prior plugin knowledge? — Yes. `docs/agents/devops-engineer.md:30` says "Dispatch via the `Agent` tool with `subagent_type: han:devops-engineer`" without explaining what the `Agent` tool is, where the reader would invoke it, or how `subagent_type` prefixing works. This is defensible for A2 (returning user) but a hard wall for A1 who arrived via search.

**Context of Reading**

- **Q11 [Assumed]:** Most readers are on desktop, with the repo cloned or the GitHub viewer open. — Assumed from the "product engineer" audience statement in the brief. Mobile reading is not a primary consideration.

**Orientation**

- **Q12 [Answered]:** Can a reader dropped onto `docs/agents/devops-engineer.md` (line 1) tell where they are? — Partially. Line 1 says "devops-engineer"; line 2 says "Operator documentation for the `devops-engineer` agent in the han plugin." That is an explicit orientation frame and is one of the strongest design choices in the set. But the line does not link back to the plugin landing page, so a reader who arrives here cold has no path to "what is the han plugin, what else is in it, where else should I look."
- **Q13 [Answered]:** Can a reader dropped onto `docs/skills/plan-a-feature.md` tell where they are? — Same as Q12 — self-orienting at the top, but no path back up to the README or sideways to the other planning skills in a single visual index.

**Entry-Point Density**

- **Q14 [Answered]:** How many front doors exist? — One and only one: `plugins/han/README.md`. There is no `docs/README.md`, no `docs/index.md`, no `docs/agents/README.md`, no `docs/skills/README.md`. A search-arriving reader landing on a long-form doc has no local landing page to fall back to.

**Cross-Channel Consistency**

- **Q15 [Answered]:** Is this documentation the canonical source, or do README, SKILL.md, and inline agent definitions tell different stories? — Three channels exist: (1) the SKILL.md body inside each skill directory, which Claude reads to execute the skill; (2) the README Skills Reference prose; (3) the long-form `docs/skills/X.md`. For the three skills with long-form docs, the README Skills Reference entries are near-copies of the long-form Summary paragraphs (compare README lines 217, 230, 243 with the long-form Summary sections). Content drift risk is high — two sources of truth with no pointer between them.

**Decision and Action**

- **Q16 [Answered]:** What decision is the landing page trying to drive? — Purportedly "pick which skill to run first." Getting Started (lines 21-74) makes a specific recommendation (project-discovery → project-documentation → coding-standard), but the §"Skills" list (lines 75-89) and §"Skills Reference" (lines 123-288) then present all 13 skills at the same visual weight without calibrating the reader back to the recommended starting path. A reader scrolling past Getting Started loses the recommendation.

**Exit and Completion**

- **Q17 [Answered]:** How does a first-contact reader know they are done with orientation and ready to run? — They do not. The README never says "by the end of Getting Started, you should have run project-discovery and you are ready to do X." There is no completion signal. The reader keeps scrolling into reference content.
- **Q18 [Answered]:** Where does a reader go when they want to see the full team of specialists the planning skills invoke? — Nowhere cohesive. The README §"Custom Agents" (lines 93-112) lists 20 agents with paragraph-length one-liners, but the ones linked to long-form docs (6) are visually identical to the ones without (14). There is no grouping by role ("planning coordinators," "adversarial reviewers," "codebase scanners," etc.) or by which skill dispatches which.

**Measurement and Validation**

- **Q19 [Open]:** What support questions or repeat confusions are readers actually having? — No analytics, issue-tracker, or support-ticket review was available for the audit. Findings must assume defensible reader-task friction from structure alone.
- **Q20 [Open]:** Which skills are used most often in practice? — Unknown. Used implicitly in IA-010 (coverage rule for long-form docs) where the current 6/20 agents and 3/13 skills with long-form docs appear to reflect author convenience rather than a usage-based prioritization.

## Assumptions

- The primary audience is A1 (solo/small-team product engineer, first contact) and the structure must serve them first, without excluding A2 and A3.
- A long-form doc per agent or per skill is valuable when the agent/skill has enough behavioral nuance (modes, decision logic, multiple outputs, named pairings) to need more than a README bullet. Not every entry needs one.
- Readers arrive at individual long-form docs from external search as well as from the README; EPPO (every-page-is-page-one) applies.
- README content that duplicates long-form content will drift unless there is exactly one source of truth.
- Progressive disclosure is the primary lens for this audit — the brief names it — and structural recommendations that flatten content onto one surface will be rejected.

## Open Questions

**OQ1: What concrete analytics or support data exists on reader confusion?**
- **Why it matters:** Without usage data, severity on "Getting Started recommends the wrong first skill" findings is inferred from audience-task structure, not from measured confusion.
- **Findings affected:** IA-002, IA-004
- **How to resolve:** Pull support-ticket history for the last 90 days, review recurring "how do I start" / "which skill does X" questions, and — if possible — instrument long-form docs with a simple "was this useful" signal before/after the rewrite.

**OQ2: Which skills and agents see the most real-world use?**
- **Why it matters:** The long-form-doc coverage rule proposed in IA-010 is framed around "enough behavioral nuance to need more than a bullet." A usage-weighted view might change priority — a high-traffic skill that is behaviorally simple (e.g., `/update-pr-description`) still benefits from a long-form doc because many readers land on it.
- **Findings affected:** IA-010
- **How to resolve:** Add telemetry or review skill invocation logs if available. Otherwise, let the maintainers apply the proposed coverage rule against their own sense of traffic as a second filter.

**OQ3: Is the three-channel content model (inline SKILL.md, README reference entry, long-form doc) intentional?**
- **Why it matters:** If the README Skills Reference is meant to be the canonical "when to use" text (and the long-form `docs/skills/X.md` is an expanded version for power users), say so explicitly; if the long-form doc is canonical and the README is an index, say that. Today, both read as canonical and neither is labeled as a summary of the other.
- **Findings affected:** IA-001, IA-003, IA-009
- **How to resolve:** Product decision on which surface is canonical for each topic type. The recommended target (below) moves the canonical reference into the long-form doc and turns README entries into scent-only pointers.

**OQ4: Is there an intended reading order beyond Getting Started?**
- **Why it matters:** IA-005 recommends introducing a concept-type page that explains skill-vs-agent and the planning-skill chain. If the team intends readers to learn concepts linearly, the ordering of that page matters. If the team intends random-access, the page should be an index with scent-rich links.
- **Findings affected:** IA-005, IA-007
- **How to resolve:** Maintainer product decision once the new concept page(s) are drafted.

## Summary

The han plugin's documentation is high-quality prose on a structure that has not yet learned to carry it: one README tries to be a landing page, a tutorial, a skills index, and a full reference at once (288 lines, 22 headings, 58% of the file is reference content), and 14 of 20 agents and 10 of 13 skills have no long-form doc while the 9 that do exist are orphaned from everything but a single README bullet. A first-contact reader (A1) is asked to scroll past a narrative Getting Started, a flat 20-agent list, and then a second flat 13-skill reference to find material they already scanned once — with no concept page defining *skill* vs *agent*, no grouping of agents by role, and the headline planning-skill chain absent from Getting Started entirely.

| Severity               | Count |
|------------------------|-------|
| Blocks comprehension   | 3     |
| Degrades comprehension | 5     |
| Friction               | 4     |
| Polish                 | 2     |

Open Questions: 4 (must be answered before findings are fully actionable)

Full analysis written to: /Users/mxriverlynn/dev/testdouble/skills-internal/plugins/han/docs/ia-analysis.md

## Findings

### Protocol 1 — Critical Inquiry and Reader Context

See the Question Log and Open Questions sections above. Twenty questions logged: 14 Answered from the docs themselves, 2 Assumed, 4 Open.

### Protocol 2 — Content Inventory

**IA-001: README tries to be four topic types in one document.**
- **Principle:** DITA topic-type boundary (concept / task / reference / tutorial mixed); Dan Brown Principle 3 (Disclosure); anti-pattern "Reference-As-Tutorial (and vice versa)" and "Everything-at-Once Intro".
- **Location:** `plugins/han/README.md:1-288`.
- **Evidence:** Line 1-19 is concept/overview ("Han is a suite of custom AI skills and agents..."). Lines 21-74 are tutorial ("Getting Started" with numbered steps). Lines 75-89 are a reference index ("Skills"). Lines 91-112 are another reference index ("Custom Agents"). Lines 114-121 are a task (installation). Lines 123-288 are a full reference (166 lines — 58% of the file — of per-skill detail). Five distinct topic types are interleaved.
- **Reader Impact:** A1 (first-contact engineer, JTBD: pick a first skill) sees a three-step Getting Started, then is asked to evaluate a 13-item skill list and a 20-item agent list at the same visual weight *before* any of them have been introduced conceptually. A2 (reference-lookup) has to scroll past 122 lines of tutorial and index to reach the reference detail. The topic types fight each other for the same page real estate.
- **Related questions:** Q6 (answered), Q7 (answered), Q8 (answered), Q16 (answered), OQ3 (open).
- **Severity:** Blocks comprehension.
- **Remediation:** Split README into four pages with defined topic types. Landing page (README.md): concept + signposting only (~80 lines). Quickstart page (`docs/quickstart.md`): the tutorial currently at lines 21-74. Skills index page (`docs/skills/README.md`): the bullet list + short scent. Agents index page (`docs/agents/README.md`): grouped agent overview. The existing §"Skills Reference" (lines 123-288) is deleted from README.md — each entry moves into a long-form `docs/skills/X.md` as per IA-010.

**IA-002: Getting Started contradicts the plugin's own headline capability.**
- **Principle:** Dan Brown Principle 6 (Multiple Classification — the paths shown in the navigation must match real reader intents); Hackos audience-to-task mapping.
- **Location:** `plugins/han/README.md:21-74` (Getting Started) vs. `plugins/han/README.md:8-19` (Features list) and lines 215-251 (planning skills Skills Reference).
- **Evidence:** README lines 8-19 list features including "evidence-based planning." The three planning skills (`/plan-a-feature`, `/plan-implementation`, `/iterative-plan-review`) have the longest Skills Reference entries in the document (lines 217, 230, 243 — roughly 10 lines each) and are the only skills with dedicated long-form docs in `docs/skills/`. But Getting Started names `/project-discovery` → `/project-documentation` → `/coding-standard` as the recommended first sequence. The most-invested-in skills of the plugin do not appear in the recommended first path.
- **Reader Impact:** A1 arriving from the marketplace listing ("I want to plan a feature") completes Getting Started and has learned nothing about the planning skills the plugin invests its deepest documentation in. They may run `/project-discovery` three times, conclude the plugin is a codebase-scanner tool, and leave.
- **Related questions:** Q6 (answered), Q7 (answered), Q16 (answered), OQ1 (open).
- **Severity:** Blocks comprehension.
- **Remediation:** Replace the single-sequence Getting Started with a **"Which path are you on?"** signposting page offering (at minimum) three named paths: "I want to plan a new feature," "I want to investigate or review existing code," "I want to set up my project for all han skills." Each path is three to five lines pointing at the first skill to run and a one-line justification; detail lives in the long-form skill docs.

**IA-003: Skills listed in three places inside the same file.**
- **Principle:** Rosenfeld/Morville labeling system (one concept, one canonical location); Carroll minimalism (cut meta-content and restatement); anti-pattern "TOC-As-Architecture".
- **Location:** `plugins/han/README.md:25-56` (Getting Started narrative for 3 skills), `plugins/han/README.md:75-89` (brief "Skills" list of all 13), and `plugins/han/README.md:123-288` (full "Skills Reference" of all 13).
- **Evidence:** `/project-documentation` appears at line 39 (in Getting Started, with 3 example prompts), at line 88 (one-line reference), and at lines 266-276 (full reference block with prompts). Same pattern for every other skill. Each skill has between two and three separate entries within README.md, with prose duplicated or near-duplicated.
- **Reader Impact:** A1 scans the first mention and assumes they have seen it all; scrolls down, finds a second list, scrolls again, finds a third; confusion mounts about whether the three are different entities or the same. A2 hunting for one skill's behavior has to guess which of the three entries is the canonical one. A3 editing a skill description has three places to keep in sync and no linter catching drift.
- **Related questions:** Q15 (answered), OQ3 (open).
- **Severity:** Blocks comprehension.
- **Remediation:** The Skills Index page has **one** bullet per skill with a one-sentence scent line and a link to `docs/skills/X.md`. The long-form doc is canonical. The Getting Started / Quickstart page mentions skills by name only, always with a link to the long-form doc, never with a restated description.

### Protocol 3 — Audience and Task Analysis

**IA-004: A3 (contributor) audience has no entry point in the plugin docs.**
- **Principle:** Hackos audience-task mapping (an unaddressed audience); Dan Brown Principle 5 (Front Doors — multiple audiences deserve scent-appropriate front doors).
- **Location:** `plugins/han/README.md:1-288` — no heading, no link, no paragraph addresses contributors. Repo-root files `docs/plugin-entity-taxonomy.md` and `docs/skill-building-guidance/*` exist (per CLAUDE.md) but are never linked from this plugin's docs.
- **Evidence:** A full grep of README.md for "contribut", "author", "edit", "add a skill", or "add an agent" returns no matches. The only hint the plugin has contributor-facing docs is the `docs/agents/<name>.md` §"Related Documentation" sections (e.g., `docs/agents/devops-engineer.md:167-172`), which link four build-guideline docs — but only an A3 who has already landed on a long-form doc will see them.
- **Reader Impact:** A3 who clones the plugin to extend it has to discover the build-guideline docs by file browsing or by reading an unrelated agent's footer. There is no "Contributing to han" entry point.
- **Related questions:** Q4 (answered), Q5 (answered).
- **Severity:** Degrades comprehension.
- **Remediation:** Add a short `docs/contributing.md` (or a "Contributing" section on the landing page under progressive disclosure) that links to `docs/plugin-entity-taxonomy.md`, `docs/skill-building-guidance/`, and `docs/agent-building-guidelines/` with one-line scent for each. This is index-weight content, not prose — four to six lines.

### Protocol 4 — Topic Typing and Information Model

**IA-005: Skill-vs-agent concept is assumed, never explained.**
- **Principle:** Carroll minimalism (cut assumed vocabulary); anti-pattern "Curse-of-Knowledge Prose"; Dan Brown Principle 1 (Objects — content has a life of its own that has to be named before it can be navigated).
- **Location:** `plugins/han/README.md:3` ("suite of custom AI skills and agents"), `plugins/han/README.md:75` (§"Skills" heading), `plugins/han/README.md:91` (§"Custom Agents" heading).
- **Evidence:** README line 3 names "skills and agents" as the building blocks. The doc never defines what either is or how they relate. The reader is expected to know that skills are invoked with `/slash-commands`, that agents are dispatched from within skills via the `Agent` tool, and that some skills dispatch multiple agents. This relationship is the load-bearing mental model of the plugin, and it is nowhere on the page.
- **Reader Impact:** A1 cannot build a ground-up mental model of the plugin. They will experiment, map intent-to-command, and eventually infer the relationship. Until then, the §"Skills" list and §"Custom Agents" list appear to be two flat catalogs with no relationship between them — even though, e.g., `/plan-a-feature` dispatches `junior-developer`, `project-manager`, and three to five additional specialists. That relationship is invisible from the landing page.
- **Related questions:** Q9 (answered), Q10 (answered), OQ4 (open).
- **Severity:** Blocks comprehension.
- **Remediation:** Add a **Concepts** page at `docs/concepts.md` (linked from the landing page above the quickstart) with: (a) a 100-word definition of skill and agent as used in han, (b) a simple diagram or ASCII sketch showing a skill dispatching agents, (c) two or three example pairings ("`/plan-a-feature` dispatches `junior-developer` + `project-manager` + 3-5 specialists"), (d) a one-sentence pointer to `docs/plugin-entity-taxonomy.md` for the general Claude Code taxonomy. Referenced once from the landing page as "Start here if you are new to the skill/agent model."

**IA-006: Long-form skill docs mix reference and concept on one page with no disclosure ramp.**
- **Principle:** DITA topic-type boundary; progressive disclosure; anti-pattern "Wall of Text" (at a sub-page scale).
- **Location:** `docs/skills/iterative-plan-review.md:5-7` (Summary: one 480-word paragraph); `docs/skills/plan-a-feature.md:5-7` (Summary: one 450-word paragraph); `docs/skills/plan-implementation.md:5-7` (same pattern).
- **Evidence:** Each skill long-form begins with a Summary section whose body is a single paragraph of 400-500 words, immediately followed by "When to Use It" lists and "How to Invoke It" steps. A reader who needs to decide "is this the right skill" has to consume 400 words of dense prose before reaching the scannable When/Do-not-use lists. The Summary duplicates material that appears later in When-to-use / What-you-get-back form.
- **Reader Impact:** A2 in reference-lookup mode cannot scan for "does this apply to my situation" without reading paragraph prose. A1 choosing between sibling planning skills has to read three 400-word paragraphs and hold them in working memory. The Summary section is doing concept-work and reference-work simultaneously.
- **Related questions:** Q8 (answered), Q13 (answered).
- **Severity:** Degrades comprehension.
- **Remediation:** Replace the long Summary paragraph with a **three-line TL;DR** (what it does, when to use it, what you get back — one line each) followed by a scannable bullet list of the top three concepts the skill uses (e.g., "decision tree," "team mode vs lightweight mode," "cross-referenced artifacts folder"). The existing 400-word paragraph becomes an "In more detail" section lower on the page, after When-to-use.

### Protocol 5 — Hierarchy and Progressive Disclosure

**IA-007: Agents list at landing-page level reveals all 20 at equal weight.**
- **Principle:** Nielsen progressive disclosure; Dan Brown Principle 3 (Disclosure); LATCH (no organizing dimension chosen — it is alphabetical by accident, not by design); anti-pattern "Progressive-Disclosure Failure".
- **Location:** `plugins/han/README.md:91-112`.
- **Evidence:** §"Custom Agents" lists 20 agents, each as a bullet with a paragraph of description (ranging from 30 to 230 words per bullet). No grouping, no role separation, no "agents you will meet first" vs "agents you only see when a skill dispatches them." The heavy-duty agents (`data-engineer` at line 100, 230 words; `devops-engineer` at line 98, 220 words; `information-architect` at line 104, 180 words) sit next to lightweight ones (`project-scanner` at line 107, 30 words) with identical visual weight.
- **Reader Impact:** A1 sees a 20-bullet list where each entry is a dense paragraph. The cognitive load to pick one is high, and the reader will not realize that most agents are dispatched automatically by skills (so A1 will not typically invoke them directly). A2 looking for a specific specialist has to linear-scan the list with no alphabet or role signpost.
- **Related questions:** Q18 (answered), OQ4 (open).
- **Severity:** Degrades comprehension.
- **Remediation:** Introduce a grouped Agents Index at `docs/agents/README.md`. Proposed groups: (1) **Planning & Facilitation** — `project-manager`, `junior-developer`; (2) **Adversarial Reviewers** — `adversarial-validator`, `adversarial-security-analyst`, `devops-engineer`, `data-engineer`, `information-architect`, `user-experience-designer`; (3) **Investigation & Evidence** — `evidence-based-investigator`, `codebase-explorer`, `project-scanner`; (4) **Architecture & Risk** — `structural-analyst`, `behavioral-analyst`, `concurrency-analyst`, `risk-analyst`, `system-architect`; (5) **Testing** — `test-engineer`, `edge-case-explorer`; (6) **Gap & Content** — `gap-analyzer`, `content-auditor`. Each agent carries a one-line scent + link to its long-form doc (if one exists) or directly to the agent definition.

**IA-008: Getting Started forces a linear narrative past the reader's true entry point.**
- **Principle:** Every Page is Page One (Baker) — content designed for linear reading fails random-access readers; Dan Brown Principle 5 (Front Doors).
- **Location:** `plugins/han/README.md:21-74`.
- **Evidence:** §"Getting Started" is structured as numbered sections 1-4, with the clear implication that readers proceed in order. Section 1 is `/project-discovery` (narrow use case — reference file generation), section 2 is `/project-documentation`, section 3 is `/coding-standard`, section 4 is "Combining skills in prompts." A reader whose problem is "plan a feature" has no signpost in the first 74 lines that their path is different.
- **Reader Impact:** A1 scrolls past the linear onboarding, reaches §"Skills" at line 75, and has to re-orient. The 74 lines of Getting Started read as instruction but are in fact a specific path that does not apply to most readers.
- **Related questions:** Q7 (answered), Q16 (answered).
- **Severity:** Degrades comprehension.
- **Remediation:** See IA-002. Replace the numbered "Start here in order" frame with a **"Pick a path"** frame that names the reader situation first and points to the right starting skill for each — no more linearity than the problems actually have.

### Protocol 6 — Labeling and Navigation Systems

**IA-009: Identical scent prose in README and in long-form Summary.**
- **Principle:** Rosenfeld/Morville labeling system (each concept at one canonical location); anti-pattern "Category Fiction" (two surfaces claiming to be canonical).
- **Location:** Compare `plugins/han/README.md:217` (§"Skills Reference" entry for `/iterative-plan-review`, ~210 words) with `docs/skills/iterative-plan-review.md:5-7` (§"Summary" paragraph, ~480 words). Similar overlap at README.md:230 vs `docs/skills/plan-a-feature.md:5-7`, and README.md:243 vs `docs/skills/plan-implementation.md:5-7`.
- **Evidence:** The README entry begins "Sharpens and stress-tests an existing plan file through multiple codebase-grounded review passes..." and the long-form Summary begins "A skill that sharpens and stress-tests an *already-written* plan file through multiple codebase-grounded review passes..." — same opening, same structure, same vocabulary. Two source-of-truth surfaces for a description that should live in exactly one place. Drift will happen; the linter cannot catch it.
- **Reader Impact:** A3 maintaining these docs has to keep README and long-form in sync manually. A2 reading README reference and long-form Summary consecutively feels the repetition and loses trust in the docs.
- **Related questions:** Q15 (answered), OQ3 (open).
- **Severity:** Degrades comprehension.
- **Remediation:** Pick one canonical surface per skill — recommendation: the long-form `docs/skills/X.md` is canonical. The README / Skills Index carries only **scent** (a one-sentence "when to use this" line) and a link. Delete `plugins/han/README.md:123-288` once each skill has a long-form doc meeting the template in IA-011.

**IA-010: Coverage asymmetry — most skills and agents are undocumented beyond a bullet, but those that are documented are heavily documented.**
- **Principle:** Hackos audience-task mapping (reader lands where the depth is, not where the traffic is); Dan Brown Principle 8 (Growth — content set assumes continued additions, so a consistent depth-floor is required); anti-pattern "Orphan Topic" (inverse — pages that exist are not consistently authored).
- **Location:** `plugins/han/agents/` (20 agent definitions) vs `plugins/han/docs/agents/` (6 long-form docs); `plugins/han/skills/` (13 skill directories) vs `plugins/han/docs/skills/` (3 long-form docs).
- **Evidence:** 14 of 20 agents have no long-form doc — notably `adversarial-security-analyst` (10.2 KB definition), `edge-case-explorer` (17 KB definition), `test-engineer` (12 KB definition), `system-architect`, `codebase-explorer`, and all three architectural analysts. These are dispatched by `/code-review`, `/test-planning`, `/architectural-analysis`, and the planning skills — they are the *working force* of the plugin. They have zero operator-facing documentation beyond the README bullet. Meanwhile, `user-experience-designer` (only dispatched via specific user request) has a 126-line long-form. 10 of 13 skills have no long-form doc, including `/code-review` — almost certainly one of the most-invoked skills in the plugin.
- **Reader Impact:** A2 (reference-lookup) trying to understand "what will `/code-review` actually do" or "when should I dispatch `test-engineer` directly vs. let `/test-planning` do it" finds only the README bullet. The inconsistency tells the reader the docs are partial, which undermines trust in the 9 long-form docs that do exist.
- **Related questions:** OQ2 (open).
- **Severity:** Degrades comprehension.
- **Remediation:** Apply a **coverage rule** (proposed below in IA-011). Audit each agent and each skill against the rule; close the long-form-doc gap with a sequenced backlog rather than in one push. Suggested priority order: `/code-review` (user-facing, likely highest-traffic), `/investigate`, `/architectural-analysis`, `/test-planning`, `/architectural-decision-record`, `/coding-standard`, `/project-documentation`, `/project-discovery`, `/gh-pr-review`, `/update-pr-description`. Agent priority: `adversarial-security-analyst`, `test-engineer`, `edge-case-explorer`, `evidence-based-investigator`, `structural-analyst`+`behavioral-analyst`+`concurrency-analyst`+`risk-analyst`+`system-architect` (possibly one shared "architectural analysts" long-form covering the five as a team), then the rest.

**IA-011: No template for long-form agent or skill docs is documented.**
- **Principle:** Rosenfeld/Morville organization system (consistent structure across peers); anti-pattern "TOC-As-Architecture" (the TOC is the only structural artifact).
- **Location:** `docs/agents/*.md` (6 files) and `docs/skills/*.md` (3 files).
- **Evidence:** All 9 long-form docs share a near-identical outer shape — Summary, When to Use It, How to Invoke It, What You Get Back, How to Get the Most Out of It, Cost and Latency, Sources, Related Documentation. This is clearly an intentional convention. But the convention is nowhere documented. A contributor adding a tenth long-form doc has to reverse-engineer it from the existing six. Minor drift already exists: `docs/agents/junior-developer.md` adds sub-modes ("Artifact-review mode," "Conversational mode") to the When/How sections; `docs/agents/information-architect.md` adds a "Boundary with user-experience-designer" section that no other agent has. These may be intentional exceptions — but without a documented template, they cannot be distinguished from drift.
- **Reader Impact:** A3 cannot write a consistent new long-form doc without reading all 9 existing ones first. Inconsistency across long-forms taxes A2 who develops a scanning habit on one and then has to re-learn the shape on another.
- **Related questions:** OQ4 (open).
- **Severity:** Friction.
- **Remediation:** Formalize a long-form template at `docs/templates/agent-long-form-template.md` and `docs/templates/skill-long-form-template.md` with the exact section order and what each section must contain. Proposed section order for both:
  1. **TL;DR** (new; three lines — what / when / what-you-get-back)
  2. **Summary** (the existing paragraph, but moved below TL;DR and shortened; concept prose only, no task steps)
  3. **When to Use It** (`Invoke when:` list; `Do not invoke it for:` list with sibling-skill pointers)
  4. **How to Invoke It** (task content; numbered input requirements; example prompts)
  5. **What You Get Back** (reference content; output structure)
  6. **How to Get the Most Out of It** (task content; "Levers you control")
  7. **Cost and Latency** (reference content; model tier and dispatch cost)
  8. **Sources** (reference content; provenance of principles)
  9. **Related Documentation** (reference content; sibling docs and agents it pairs with — **must include a link back to the plugin landing page**).

**IA-012: Long-form docs have no upward link to the plugin landing page.**
- **Principle:** Dan Brown Principle 7 (Focused Navigation — every page should surface its parent context); EPPO (a page entered via search must offer paths onward).
- **Location:** `docs/agents/devops-engineer.md:167-172` (§"Related Documentation") and the equivalent section in every other long-form doc.
- **Evidence:** Spot-check of `docs/agents/devops-engineer.md` §"Related Documentation" links only to repo-wide build-guideline docs, never to `plugins/han/README.md` or to any plugin-local index. Same in all 9 long-form docs inspected. A reader who arrived cold via Google has no "up" link.
- **Reader Impact:** A1 arriving via external search at `docs/agents/devops-engineer.md` reads 170 lines of reference content and has no way to orient themselves in the wider plugin — they can only scroll back up to line 1 and read "Operator documentation for the devops-engineer agent in the han plugin" with no link on the word "han plugin."
- **Related questions:** Q3 (answered), Q12 (answered), Q14 (answered).
- **Severity:** Friction.
- **Remediation:** Every long-form doc must end with a "Related Documentation" section that starts with a link to `plugins/han/README.md` ("Plugin landing page — han"), followed by links to sibling long-form docs that are commonly paired, followed by the external reference material that currently occupies this section.

### Protocol 7 — Every-Page-Is-Page-One Check

**IA-013: Agent long-form docs self-orient at the top; skill long-form docs are comparable.**
- **Principle:** EPPO.
- **Location:** All 9 long-form docs open with a 2-3 line orientation frame (e.g., `docs/agents/devops-engineer.md:1-3`).
- **Evidence:** Every long-form starts with the pattern "# {name}\n\nOperator documentation for the `{name}` agent/skill in the han plugin. This document exists to help humans decide *when* and *how* to use the {agent/skill}. For what the {agent/skill} does internally, read the {agent/skill} definition at [...]." This is a strong EPPO design — a reader dropped cold knows what the page is, who it is for, and where the internal-behavior source lives. This is one of the docs' strongest existing properties and should be preserved.
- **Reader Impact:** Positive.
- **Related questions:** Q12 (answered), Q13 (answered).
- **Severity:** — (this is a positive design finding, not a problem).
- **Remediation:** Preserve this pattern in the template (IA-011). Make the "For what the {thing} does internally, read the {thing} definition at..." pointer mandatory in the template's orientation frame.

**IA-014: README.md has no equivalent front-door orientation frame.**
- **Principle:** Dan Brown Principle 5 (Front Doors); anti-pattern "Front-Door Absence" and "Everything-at-Once Intro".
- **Location:** `plugins/han/README.md:1-20`.
- **Evidence:** Lines 1-2 say "# Han: For the 'Solo' Product Engineer" and "Han is a suite of custom AI skills and agents, purpose-built for solo (or limited team size) product engineer." Lines 3-19 then jump to a marketing-style feature bullet list. There is no answer to "who is this for, what do I read first, how is this page organized." A reader cannot tell, from the landing page, whether they should read top-to-bottom, skip to a specific section, or jump to a sibling page. No "Start here if you are new / Start here if you are returning / Start here if you want to contribute" scent.
- **Reader Impact:** A1 has no reading-order signal and defaults to top-down, which leads through Getting Started's linear narrative (see IA-008). A2 scrolls past the intro to find a reference. A3 has no signal at all.
- **Related questions:** Q1 (answered), Q11 (assumed), Q14 (answered).
- **Severity:** Degrades comprehension.
- **Remediation:** Replace the feature bullet list (lines 8-19) with a **"Which path are you on?"** block (3-4 audience-tagged paths, each linking to the right next page: new user → quickstart; returning user → skills index; contributor → contributing page). The feature list, if kept at all, moves below the path-chooser as supporting detail.

### Protocol 8 — Minimalism Sweep (Carroll)

**IA-015: Features list is throat-clearing.**
- **Principle:** Carroll minimalism (cut meta-content and restatement of the obvious).
- **Location:** `plugins/han/README.md:8-19`.
- **Evidence:** Twelve bullet points ("Deep-dive investigations with root cause analysis," "Architectural analysis," "... and so much more!") restate, in a less specific form, content that appears in more actionable form 70 lines later in the Skills list. The bullet list does not help a reader decide what to do.
- **Reader Impact:** A1 reads 11 generic bullets, gains no directional signal, and scrolls on. The space is spent but no task is advanced.
- **Related questions:** Q6 (answered), Q16 (answered).
- **Severity:** Friction.
- **Remediation:** Delete the feature bullet list. Replace with the path-chooser from IA-014. If a one-line marketing summary is needed (for marketplace metadata), keep a single sentence, not 12.

**IA-016: Long-form doc Summary paragraphs embed too much in narrative prose.**
- **Principle:** Carroll minimalism (task-oriented chunking — sections structured around reader tasks, not author narrative).
- **Location:** `docs/skills/iterative-plan-review.md:5-7` (single paragraph, 480 words); `docs/skills/plan-a-feature.md:5-7` (single paragraph, 450 words); `docs/skills/plan-implementation.md:5-7` (similar); `docs/agents/data-engineer.md:5-7` (single paragraph, 430 words).
- **Evidence:** The Summary sections read as dense, comma-spliced expert prose. They contain, in running text, the information a reader would pull from a TL;DR, a key-concepts list, an inputs/outputs table, and a positioning statement. A reader scanning for "does this apply?" has to decode the paragraph.
- **Reader Impact:** A2 in reference-lookup mode cannot skim; A1 trying to build a mental model gets flooded with nuance that is defensible later but premature up front.
- **Related questions:** Q6 (answered), Q13 (answered).
- **Severity:** Friction.
- **Remediation:** Per the template (IA-011), move the existing Summary paragraph to a "Summary — in more detail" section below the When/How sections, and introduce a new TL;DR (three lines) and Key Concepts (3-5 bullets) at the top of each long-form doc.

### Protocol 9 — Recency and Cross-Reference Integrity

**IA-017: All documentation files landed in a single recent commit; IA regressions are newly introduced and have not been tested by reader use.**
- **Principle:** Pace layering (fast-moving surface content has not stabilized against slower audience research).
- **Location:** git log `8dc7c5e 2026-04-23 han: rename from r-and-d, add information-architect agent (#138)` is the only commit in the last 180 days touching `plugins/han/README.md` or `plugins/han/docs/`.
- **Evidence:** Every file in the focus area was last modified in one push. The rename from "r-and-d" to "han" is recent; the information-architect long-form doc is brand-new. The IA problems found in this audit are almost certainly fresh — no reader has yet had time to surface them via support questions or feedback.
- **Reader Impact:** Positive for the remediation plan — these problems are cheap to fix now, before readers build workarounds. Negative for validation — no reader-use data exists yet to confirm priority (OQ1).
- **Related questions:** Q19 (open), Q20 (open).
- **Severity:** Polish (it is a context note for the team, not a finding to fix).
- **Remediation:** Treat the rewrite as a one-shot structural landing. Instrument whatever light signal is available ("was this helpful" at the bottom of each long-form doc, or issue-template prompts) and revisit the IA in 60-90 days once the docs have seen real use.

**IA-018: Cross-reference integrity is intact across the 9 long-form docs and the README.**
- **Principle:** Rosenfeld/Morville navigation system (link integrity).
- **Location:** All internal `docs/agents/X.md` and `docs/skills/X.md` references in the README resolve to real files; the long-form docs' references to `../../agents/X.md`, `../../skills/X/SKILL.md`, and sibling long-form docs all resolve. External source URLs were not checked (out of scope; requires network).
- **Evidence:** Manual resolution of every `docs/agents/X.md` and `docs/skills/X.md` link in README.md lines 98-112 and 217-243 succeeded; same for every `../../agents/X.md` link in the 9 long-form docs. No broken internal cross-references were found.
- **Reader Impact:** Positive. No dead links to remove.
- **Related questions:** Q3 (answered).
- **Severity:** Polish (no action needed; positive baseline to preserve in rewrite).
- **Remediation:** Preserve link discipline through the rewrite. Consider adding a `markdown-link-check` or equivalent pre-commit hook so the next structural change cannot regress this.

## IA Improvement Summary

### What Was Found

The han plugin docs have landed with high-quality prose on a structure that cannot yet carry it. The README is doing the work of four pages at once — landing, tutorial, skills index, and full reference — and the 9 long-form docs are orphaned from everything except a single README bullet. Ground-up learning is blocked: the skill-vs-agent concept is never defined (IA-005), the headline capability (the planning-skill chain) is absent from Getting Started (IA-002), and the 20-agent list at landing-page weight (IA-007) hides which agents a first-time reader will ever need to invoke directly vs. which are dispatched for them.

Progressive disclosure is missing at two levels. At the plugin level, one document carries all the weight (IA-001, IA-003). At the per-page level, long-form Summary sections are 400-500-word paragraphs that do TL;DR work, concept work, and reference work in the same run-on prose (IA-006, IA-016). The 9 long-form docs that do exist share an implicit template that is not formalized (IA-011), and 14 agents plus 10 skills have no long-form doc at all (IA-010) — so the depth-floor is uneven.

The docs get some important things right: every long-form doc has a strong "what this page is, who it is for, where the canonical source lives" orientation frame at the top (IA-013), internal cross-references all resolve (IA-018), and content is recent enough that fixing the structure is cheap (IA-017). The remediation plan preserves these.

### How to Improve

**Target shape.** The plugin's docs tree should look like this after the rewrite:

```
plugins/han/
  README.md                     (~90 lines: landing page only — concept + signposting)
  docs/
    README.md                   (docs index — optional; see IA-012)
    concepts.md                 (NEW: skill vs agent, how they compose — IA-005)
    quickstart.md               (NEW: "Which path are you on?" — IA-002, IA-008)
    contributing.md             (NEW: links to build-guidelines — IA-004)
    skills/
      README.md                 (NEW: Skills index — grouped — IA-001, IA-003)
      architectural-analysis.md (NEW long-form — IA-010)
      code-review.md            (NEW long-form — IA-010)
      coding-standard.md        (NEW long-form — IA-010)
      architectural-decision-record.md             (NEW long-form — IA-010)
      update-pr-description.md      (NEW long-form — IA-010)
      gh-pr-review.md           (NEW long-form — IA-010)
      investigate.md            (NEW long-form — IA-010)
      iterative-plan-review.md  (existing; apply template — IA-011, IA-016)
      plan-a-feature.md         (existing; apply template — IA-011, IA-016)
      plan-implementation.md    (existing; apply template — IA-011, IA-016)
      project-discovery.md      (NEW long-form — IA-010)
      project-documentation.md  (NEW long-form — IA-010)
      test-planning.md          (NEW long-form — IA-010)
    agents/
      README.md                 (NEW: Agents index — grouped by role — IA-007)
      data-engineer.md          (existing; apply template — IA-011)
      devops-engineer.md        (existing; apply template — IA-011)
      information-architect.md  (existing; apply template — IA-011)
      junior-developer.md       (existing; apply template — IA-011)
      project-manager.md        (existing; apply template — IA-011)
      user-experience-designer.md (existing; apply template — IA-011)
      {plus 14 more long-form docs, sequenced per IA-010 priority}
```

**Proposed new landing page outline** (`plugins/han/README.md`, target ~90 lines):

1. **Title + one-sentence purpose** (lines 1-3)
2. **Which path are you on?** (lines 5-25) — three or four audience paths:
   - *New to han?* → `docs/concepts.md` then `docs/quickstart.md`
   - *Looking for a specific skill?* → `docs/skills/README.md`
   - *Looking for a specific agent?* → `docs/agents/README.md`
   - *Contributing?* → `docs/contributing.md`
3. **What this plugin does** (lines 27-40) — two paragraphs replacing the 12-bullet feature list (IA-015). No skill list here.
4. **Installation** (lines 42-50)
5. **Quick links** (lines 52-70) — the three to five most-used skills (headed "You probably want..."), each a one-sentence description + link to long-form doc. Based on team judgment about traffic (OQ2).
6. **Related documentation** (lines 72-85) — links to concepts, quickstart, skills index, agents index, contributing.

**Proposed new long-form template** (referenced in IA-011):

1. Orientation frame (mandatory, preserves IA-013)
2. **TL;DR** — three lines (what / when / what-you-get-back)
3. **Key Concepts** — 3-5 bullets with links into the doc
4. **When to Use It** — Invoke-when list; Do-not-invoke-for list with explicit pointers to sibling skills
5. **How to Invoke It** — numbered input requirements + example prompts
6. **What You Get Back** — output structure, file names if relevant
7. **How to Get the Most Out of It** — "levers you control"
8. **Cost and Latency** — model tier, dispatch fan-out
9. **In more detail** (optional) — the existing 400-word Summary paragraph moves here if preserved
10. **Sources** — provenance of principles
11. **Related Documentation** — **first link is up to the plugin landing page**, then sibling long-form docs, then build-guidelines

**Proposed coverage rule for when a long-form doc is needed** (referenced in IA-010):

A skill or agent gets its own long-form `docs/` page when any **two** of the following are true:

- It has more than one operating mode (e.g., `junior-developer` artifact-review vs conversational; `/iterative-plan-review` lightweight vs team).
- It produces more than a single artifact, or writes to more than one file.
- It dispatches or orchestrates other agents (any planning skill; `/code-review`; `/test-planning`; `/architectural-analysis`).
- It pairs with another specialist in a named, recommended way (`devops-engineer` + `adversarial-security-analyst`; `data-engineer` + `devops-engineer`).
- It is directly reachable by the user (all slash-command skills meet this; agents do so only when invoked manually).
- It has non-trivial provenance (named frameworks, research sources, or vocabulary the reader must learn to read the output).

Skills and agents that meet **only one** of the above are well-served by a scent-rich entry in the Skills Index or Agents Index (a paragraph at most). An agent like `project-scanner` (read config files, write a static reference) does not need a long-form doc; the README/Index bullet suffices.

**Ordered remediation plan** (severity-first):

1. **Blocks comprehension — fix in this rewrite:**
   - IA-001: Split README into landing + quickstart + skills index + agents index.
   - IA-002: Replace Getting Started single-path with "Which path are you on?" signposting; surface the planning-skill chain as a first-class path.
   - IA-003: Eliminate duplicate skill entries; one canonical surface per skill.
   - IA-005: Add `docs/concepts.md` defining skill vs agent.

2. **Degrades comprehension — fix in this rewrite or immediately after:**
   - IA-004: Add `docs/contributing.md`.
   - IA-006: Apply new TL;DR + Key Concepts top-of-page to the 9 existing long-form docs.
   - IA-007: Introduce grouped Agents Index.
   - IA-008: Remove linear Getting Started numbering.
   - IA-009: Move canonical skill/agent reference into `docs/skills/X.md` and `docs/agents/X.md`; README carries scent only.
   - IA-010: Apply coverage rule; add long-form docs for top-priority missing skills and agents over a sequenced backlog. `/code-review` and `/investigate` are day-one priorities because they are the likely high-traffic skills.
   - IA-014: Add a "Which path are you on?" orientation frame at the top of README.

3. **Friction — fix as part of the rewrite if cheap, otherwise track:**
   - IA-011: Formalize the template at `docs/templates/agent-long-form-template.md` and `docs/templates/skill-long-form-template.md`.
   - IA-012: Add an "up to plugin landing page" link in the Related Documentation section of every long-form doc.
   - IA-015: Delete the 12-bullet feature list.
   - IA-016: Apply the template's section reordering to existing long-form docs.

4. **Polish — track for a later pass:**
   - IA-017: Revisit the IA 60-90 days after the rewrite ships.
   - IA-018: Add a link-check hook to protect the current clean cross-reference state.

### How to Prevent This Going Forward

- **Formalize the long-form template** (IA-011) at `docs/templates/` and reference it from the contributing doc. Any new agent or skill docs use it.
- **One canonical surface per concept.** The Skills Index and Agents Index carry a one-sentence scent line and a link; the long-form doc carries the canonical reference. The README never duplicates long-form content.
- **Coverage rule documented** (IA-010). When a new skill or agent ships, the coverage rule is applied in the PR that lands it; missing long-form docs for qualifying entries block merge (or at least get a tracked issue before merge).
- **Link-check pre-commit hook.** Protect the current clean cross-reference state from future structural changes.
- **Content inventory at release time.** Before each plugin release, run a quick content inventory pass against the rule: has anything drifted, is any skill/agent new and missing a long-form, is any section in the README still duplicating long-form content.
- **Re-audit in 60-90 days.** Once real reader usage has accumulated (support questions, issues, feedback), re-dispatch the `information-architect` agent against the new structure. Open Questions OQ1, OQ2, and OQ4 will become Answered.

### Balancing Shipping vs Improving

**Must fix in the rewrite** (these are blocks to the audit's primary reader task):
- IA-001, IA-002, IA-003, IA-005 — the top-of-funnel decisions. Without these the reader cannot orient, pick a first skill, or build the skill-vs-agent mental model.

**Should fix in the rewrite** (degrades but does not block):
- IA-004, IA-007, IA-008, IA-009, IA-014 — reader has a harder time than they should, but can still complete the task.
- IA-006 and IA-016 can be applied only to the 3 existing long-form skill docs now; the 6 long-form agent docs can follow immediately after; the 14 new agent long-forms will inherit the template naturally.

**Can be sequenced over multiple sprints:**
- IA-010 — filling out the 14 missing agent long-forms and 10 missing skill long-forms is a real body of work. Do the top-three highest-traffic skills in the rewrite (`/code-review`, `/investigate`, `/architectural-analysis`) and queue the rest. Do not block the structural rewrite on complete long-form coverage.
- IA-011 — the template can be formalized as part of the rewrite or immediately after.

**Track and don't block:**
- IA-015, IA-017, IA-018 — polish and future validation.

The rewrite's success criterion is that a first-contact reader (A1) can, within ten minutes of landing on the README, identify which of three named paths they are on, follow that path to a single recommended starting skill, and reach the long-form doc for that skill with a clean orientation frame. Everything else is secondary to that criterion.
