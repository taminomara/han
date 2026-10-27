# Research: How should the Mikado Method work as a new Han skill?

The question is how the Mikado Method works and how to build it into a new Han skill that runs the method on a real
codebase. The decision to build a new skill is taken as given; this report covers what the skill should do and where it
should sit. Evidence mode: strict.

## Summary

Build one skill that runs the whole Mikado loop, from trying the goal through to finishing it, and keep a person in charge
of the goal and of how the graph grows. The method is well described and stable: try the change the simple way, write
down what breaks, undo the attempt, fix the blockers first, and commit each one only when the tests pass. The skill
belongs in the coding plugin beside `refactor` and `tdd`, because it edits code and runs tests the way they do.

Two design choices carry most of the risk. The first is how the skill undoes an attempt without throwing away finished
work. The second is how it keeps an agent from patching forward instead of undoing. The loop itself is
well-corroborated. The agent-specific design advice comes from a handful of 2026 blog posts and skill listings, and
nothing measures whether any of it works.

- **Confidence:** Medium
- **Web search:** used

## Research Results

### How the Mikado Method works

The method is a loop for changes too big or too tangled to make in one step. Ola Ellnestam and Daniel Brolund presented
it from 2010 and published it as a book with Manning in 2014 (A1, A2, A6). Four independent sources describe the same
loop (A1, A2, A3, A5):

1. Write down the goal.
2. Try the goal the simple, direct way.
3. Let the compiler, the tests, and any other checks show what breaks.
4. Write each break down as a prerequisite under the goal.
5. Undo the attempt.
6. Treat each prerequisite as a new goal and repeat, until an attempt shows no new prerequisites.
7. Make the changes that have no prerequisites of their own, commit each one with the tests passing, and work back up
   toward the goal.

The authors call this a depth-first walk through the change's dependencies (A1). A prerequisite with nothing under it is
a "leaf," and leaves always go first (A2). New obstacles can still show up while working back up, and they become new
branches (A3).

### The graph is the method's one lasting artifact

The record of goal and prerequisites, called the Mikado graph, is what survives each undo. It is kept outside the code,
on paper, a whiteboard, plain text, or a diagram tool (A3, A7). Finished nodes are marked done, and the graph can be
attached to a pull request so a reviewer sees why the change took the shape it did (A4, A7). The sources define no
formal notation for it (A3).

### Where the sources disagree on the details

The loop's shape is settled, but its mechanics vary from source to source:

- **What counts as broken.** One source names compilers, tests, analysis, and common sense (A1). Others center on
  compile and test failures (A3, A5). A skill has to pick an explicit signal.
- **How to undo.** Sources use a hard git reset (A4), commit the attempt and then revert that commit (A5), or allow a
  stash for a promising partial attempt (A3). The original says only "version control or undo" (A1).
- **Timeboxing.** One practitioner caps each attempt at 10 minutes (A4) [single-source]. The others set no limit.
- **Stopping.** The method has no natural end, so a stop condition is needed (A3). One source fixes a completion check
  at the start, such as a code search that returns no matches (A4) [single-source].

### The method's limits

All of the evidence on limits comes from practitioners, and no study measures the method's results (A3, A4, A5).
Practitioners name these limits:

- Without automated tests, nothing can confirm a change is safe (A3).
- Slow builds and tests make every attempt expensive (A3).
- Throwing away an attempt feels wasteful, and the discipline to undo is the hardest part (A3, A4, A5).
- Early rounds produce no committed code (A4).
- Dependencies that do not show up as compile or test failures are hard to discover by trying (A5).

Uses beyond restructuring code are thin. One source shows removing a library dependency (A5). No source found applies it
to feature work or framework migrations [negative result].

### How agents have used it so far

Agent-driven Mikado exists as a cluster of 2026 practitioner posts and at least four community skills, and none of them
publishes measured results (A9, A10, A11, A12, A13, A14). Evidence here is thin. Two of the three posts share an author
(A9, A11).

The agent sources agree on four points:

- **Undo, then record.** Every source undoes the attempt and keeps only the graph (A9, A11, A13, A14).
- **The graph lives in a file.** Most keep it as a markdown checklist in the repository (A9, A11, A13). One keeps it in
  an uncommitted folder (A12), and one keeps it only in the agent's working memory (A14).
- **Small leaf commits.** Each finished leaf is one commit, made only when the tests pass (A10, A11, A13).
- **The compiler and tests are the signal** (A9, A10, A13, A14).

They name three agent-specific failure modes. Agents make sweeping edits across many files, lose track as context grows,
and edit tests to make them pass (A9) [single-source for the test-editing claim]. One author argues that deciding which
failures share a root cause cannot be handed to the agent (A10) [single-source]. A worked example kept a person
confirming the goal and approving each green commit (A11).

The sources do not settle several questions:

- No source compares reset, stash, and a separate working copy for the undo.
- No source sets a cap on discovery rounds or handles a graph that keeps growing. One adds a script that checks the
  graph for loops (A11) [single-source].
- No source reports how reliably an agent obeys "undo, don't patch forward."

### How the new skill fits Han today

`refactor` and `tdd` are the two Han skills that edit code in a test-gated loop, and both live in the coding plugin
(A17, A18, A19). `refactor` plans every step before its first edit, treats each step's list of files as a contract, and
stops when a step spreads beyond it or two steps in a row fail (A17, A18). Those three rules are the ones Mikado's
discovery half breaks on purpose, which is why an earlier Han report advised against a Mikado mode inside `refactor`
(A25).

`plan-a-change` already sequences a restructure so each unit leaves the code working, but it does so by reading code and
never by trying a change (A20). That is the real line between it and a Mikado skill: one predicts the dependencies, the
other discovers them by breaking the build. The earlier report flagged the overlap as the main cost of a separate skill
(A25).

`refactor`'s undo rule matters here. After a recent fix, it forbids restoring files from git, because a restore throws
away any earlier passing step that was not yet committed (A18). Mikado changes that picture. Every finished leaf is
committed, so the last commit always holds every passing step (A4, A5, A11). Restoring to the last commit is safe in
that case, provided the working tree was clean when the run began. That safety condition is drawn here from the two
sources, not stated by either.

Han already has the pieces a new skill would reuse:

- A script that detects the project's test command from its manifest (A21).
- A shared rule for how a skill hands control back during pairing (A22).
- A list of skills that `pairing` can drive, which a new skill would join (A23).
- A coverage rule requiring a long-form doc, a README line, and an index entry (A26).

The entity taxonomy calls a flowchartable process a skill (A24). The Mikado loop is flowchartable, with one exception:
grouping failures into prerequisites takes judgment.

## Options to Consider

### O1: One skill for the full loop, with a person gating the goal and the graph

- **What it is:** A coding-plugin skill that confirms the goal and a completion check, then runs discovery rounds. Each
  round tries the change, records new prerequisites in a committed markdown graph, and restores the code to the last
  commit. It stops for the person to review the new prerequisites, then works leaves one at a time, committing each
  only when the tests pass. It starts only from a clean tree with a passing suite.
- **Trade-offs:** It matches the method as described, and it gives the person the root-cause grouping the sources say an
  agent should not own. It costs a stop after every discovery round. It also adds a skill whose sequencing overlaps
  `plan-a-change`. It must commit as it goes, where `refactor` commits only when asked.
- **Rests on:** (A1), (A3), (A5), (A10), (A11), (A18), (A20), (A21)
- **Evidence status:** loop corroborated. The human gate rests on two independent practitioner sources. The safety of
  the undo is drawn from the codebase and the commit-per-leaf practice.

### O2: A discovery-only skill that builds the graph and hands leaves to `refactor` or `tdd`

- **What it is:** The skill runs only the discovery half: try, record, undo. It ends with a graph file. The person then
  runs each leaf through `refactor` (or `tdd` for leaves that change behavior).
- **Trade-offs:** Execution reuses existing, tested skills, and the new skill stays small. But a leaf can reveal new
  prerequisites while it is being built (A3), and `refactor` has no way to send them back into the graph. The person
  becomes the go-between for every leaf.
- **Rests on:** (A3), (A17), (A18), (A20)
- **Evidence status:** corroborated for the fit. No source runs the method split this way.

### O3: One autonomous skill for the full loop, with a time or attempt budget and no human gate

- **What it is:** O1's loop with no stops. A budget per attempt (10 minutes in the source) bounds each round, and fixed
  commit prefixes record discoveries.
- **Trade-offs:** It is the simplest to run and the least work to review. The budget comes from one source and was
  designed for people. Nothing in it guards against an agent editing tests, and no source caps the number of rounds.
- **Rests on:** (A4), (A9), (A13)
- **Evidence status:** single-source for the specifics.

### O4: Add Mikado to `refactor` instead of building a new skill

- **What it is:** The earlier report's recommendation. When `refactor` stops on a scope or repeated-failure rule, it
  records what blocked the step as prerequisites in its stop report (A25). One community skill does the same, using
  Mikado as a fallback inside a refactor loop (A14).
- **Trade-offs:** It is the smallest change, and it adds no overlapping skill. But it never runs discovery on purpose,
  so a deep chain of blockers takes several runs. It also does not deliver the new skill that was asked for.
- **Rests on:** (A14), (A18), (A25)
- **Evidence status:** codebase-corroborated for the fit. A14 is single-source.

## Recommendation

- **Recommendation:** O1, built with these specific choices.
  1. **Place it in `han-coding`**, beside `refactor` and `tdd`. Route between it and its neighbors in the description:
     `plan-a-change` predicts a restructure by reading code, and this skill discovers one by trying it.
  2. **Make the undo safe by construction.** Require a clean tree and a passing suite before the first attempt. Commit
     each finished leaf, and commit each graph update separately from the code. Undo an attempt by restoring the code to
     the last commit, which then holds every passing step. Never undo across uncommitted work the person made.
  3. **Define "broken" up front** as the resolved test command plus the type-check command where one exists, reusing
     the detection script `refactor` uses.
  4. **Keep the graph in a committed markdown file**, a nested checklist where each node carries an ID and what it
     requires. Mark a node done only after its green commit.
  5. **Stop for the person at two points:** to confirm the goal and its completion check, and after each discovery round
     to review how failures were grouped into prerequisites. Present each stop in the shape the collaborative-stop rule
     sets, and add the skill to `pairing`'s list.
  6. **Guard against patching forward.** A red attempt is always undone, never patched. A leaf commit that restructures
     code changes no tests.
  7. **Bound discovery with a round count, not a clock.** Treat the exact limit as open, because the only stated budget
     (10 minutes) was designed for people.
- **Evidence basis:** The loop, the graph as the lasting artifact, and commit-per-leaf are corroborated across several
  independent sources (A1, A2, A3, A4, A5, A11). The plugin placement, the test-detection reuse, and the undo hazard come
  from the codebase (A18, A19, A21). The human gate on root-cause grouping rests on two independent practitioner posts
  (A10, A11). The no-test-edits rule rests on one source each for the risk and the guard (A9, A14) [single-source]. The
  attempt budget in choice 7 is the one part with no evidence behind it, so it is left open rather than fixed.

## Validation

Validation has not run yet; this section is filled in after the adversarial pass.

## Sources

| ID  | Source                                                     | Link / location                                                                                           | Retrieved  | Trust class | Summary (one line)                                                                                                   | Evidence status                  |
| --- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ---------- | ----------- | -------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| A1  | Øredev 2010 speaker page, Ola Ellnestam                    | https://archive.oredev.org/oredev2010/2010/speakers/ola-ellnestam                                          | 2026-10-27 | web         | Co-author's 7-step "Naive Approach": goal, naive attempt, find breaks, record prerequisites, revert, recurse, leaves first. | corroborated by A2, A3, A5       |
| A2  | InfoQ, "Large scale refactoring" (2010)                    | https://www.infoq.com/news/2010/08/large-scale-refactoring                                                 | 2026-10-27 | web         | Graph built from the goal down; leaves have no prerequisites and go first; do not fear reverting.                    | corroborated by A1, A3           |
| A3  | heise, "Update legacy code step by step with the Mikado method" | https://www.heise.de/en/background/Update-legacy-code-step-by-step-with-the-Mikado-method-11119651.html?seite=all | 2026-10-27 | web | Six-step loop, flexible graph tooling, and limits: no natural end, needs tests and fast builds, unwinding finds new obstacles. | loop corroborated by A1, A2, A5; limits single source |
| A4  | Vinta Software, "The Mikado Method" (2025)                 | https://www.vintasoftware.com/blog/the-mikado-method                                                       | 2026-10-27 | web         | 10-minute timeboxed rounds, hard reset on failure, commit per green node, completion check fixed up front.            | commit-per-node corroborated by A5, A11; timebox single source |
| A5  | Matthias Noback, "Successful refactoring projects: the Mikado Method" (2021) | https://matthiasnoback.nl/2021/02/refactoring-the-mikado-method/                          | 2026-10-27 | web         | Worked dependency-removal example; finished prerequisites committed one at a time so every step leaves a working app. | corroborated by A1, A3, A4       |
| A6  | Manning / O'Reilly book pages, *The Mikado Method* (2014)   | https://livebook.manning.com/book/the-mikado-method/chapter-1                                             | 2026-10-27 | web         | Confirms authors, publisher, and year; body text was not readable.                                                   | single source                    |
| A7  | mikado.nvie.com                                            | https://mikado.nvie.com/                                                                                  | 2026-10-27 | web         | Graph is the main artifact, usually drawn on paper; tool shares graphs, for example on pull requests.               | corroborated by A3, A4           |
| A8  | Martin Fowler, "Parallel Change"                           | https://martinfowler.com/bliki/ParallelChange.html                                                         | 2026-10-27 | web         | Expand, migrate, contract keeps code shippable through a change that cannot land in one step.                        | single source; not a Mikado source |
| A9  | Chaabani, "Taming Agentic Refactoring with the Mikado Method" | https://anischaabani.com/en/blog/mikado-method-ai-agents/                                               | 2026-10-27 | web         | Agent failure modes: sweeping edits, scattered context, tests edited to pass; reverts with a hard reset; versioned graph file. | partly corroborated by A10; same author as A11 |
| A10 | WellAged.dev, "The Mikado Method in the Age of AI Agents"  | https://wellaged.dev/posts/mikado-method-ai-agents/                                                        | 2026-10-27 | web         | Graph is what survives each step; commit leaves only on green; grouping failures by root cause cannot be delegated to the agent. | corroborated by A9, A11 on revert and graph; root-cause claim single source |
| A11 | Chaabani, "Mikado Method in Action"                        | https://anischaabani.com/en/blog/mikado-method-example/                                                    | 2026-10-27 | web         | Worked agent example: committed checklist graph with IDs and `requires:`, graph commit then code revert, one commit per leaf, human approves each. | single source for format (same author as A9) |
| A12 | nvie/skills "mikado" (skills.sh listing)                   | https://skills.sh/nvie/skills/mikado                                                                       | 2026-10-27 | web         | Community skill keeps one graph per goal under an uncommitted `.mikado/` folder.                                     | single source; full skill not visible |
| A13 | nWave "nw-mikado-method" (OpenSkillIndex listing)          | https://openskillindex.com/skills/nwave-ai-nwave-nw-mikado-method-474589                                   | 2026-10-27 | web         | Community skill: committed checklist graph, revert after every attempt, 10-minute attempts, one leaf at a time, no human gate. | loop corroborated by A9, A11; specifics single source |
| A14 | Oma Refactor skill (TypingMind listing)                    | https://www.typingmind.com/skills/first-fluke-oma-refactor                                                 | 2026-10-27 | web         | Mikado as a fallback inside a test-gated refactor loop; refactor commits change no tests; graph held in memory.      | single source                    |
| A15 | Pre-agent Mikado tooling (clokado, mikado_graph_generator, mikado-app) | https://github.com/ahitrin/clokado                                                             | 2026-10-27 | web         | Pre-agent tooling is graph drawers and small web apps; no IDE plugin or CLI found.                                   | single search pass (snippets only) |
| A16 | Kent Beck, "make the change easy, then make the easy change" | https://tidyfirst.substack.com/p/hinge                                                                   | 2026-10-27 | web         | States the enabling-change-first rule; no source ties it to Mikado directly.                                         | corroborated across two Beck posts |
| A17 | `refactor` skill, plan step                                | `han-coding/skills/refactor/SKILL.md:110-124`                                                             | n/a        | codebase    | Plans every refactoring, with evidence and a file list, before the first edit.                                       | codebase anchor                  |
| A18 | `refactor` skill, execute, undo, and stop rules             | `han-coding/skills/refactor/SKILL.md:128-155`                                                             | n/a        | codebase    | One change then the full suite; undo only the step's own edits, never restore from git; stop on scope spread or two failures in a row. | codebase anchor                  |
| A19 | `refactor` skill description                               | `han-coding/skills/refactor/SKILL.md:3-12`                                                                | n/a        | codebase    | Test-gated loop in the coding plugin; routes multi-module restructure planning to `plan-a-change`.                   | codebase anchor                  |
| A20 | `plan-a-change` skill                                       | `han-planning/skills/plan-a-change/SKILL.md:3-10`, `:312-315`                                             | n/a        | codebase    | Sequences change units so each leaves the code working, by reading code, never by trying a change.                   | codebase anchor                  |
| A21 | Test-command detection script                              | `han-coding/skills/refactor/scripts/detect-refactor-context.sh:26-94`                                     | n/a        | codebase    | Infers the project's test command from its manifest (npm, pytest, go, cargo, and others).                            | codebase anchor                  |
| A22 | Collaborative-stop rule                                    | `han-core/references/collaborative-stop-rule.md`                                                          | n/a        | codebase    | Shared contract for how a skill detects the collaborative flag and what a stop presents.                             | codebase anchor                  |
| A23 | `pairing` skill, flagged skills                            | `han-core/skills/pairing/SKILL.md:87-89`                                                                  | n/a        | codebase    | Lists the skills `pairing` can drive collaboratively: tdd, refactor, design-an-api, iterative-plan-review, plan-implementation. | codebase anchor                  |
| A24 | Entity taxonomy                                            | `han-plugin-builder/skills/guidance/references/plugin-entity-taxonomy.md`                                 | n/a        | codebase    | A flowchartable, repeatable process is a skill; contextual judgment is an agent.                                     | codebase anchor                  |
| A25 | Earlier Han research on Mikado in `refactor`               | `docs/research/mikado-method-refactor.md` on branch `research/mikado-method-refactor`                     | n/a        | codebase    | Advised against a Mikado mode in `refactor` and a separate skill; recommended fixing the undo, then recording prerequisites at stops. | codebase anchor (prior research) |
| A26 | Coverage rule                                              | `docs/templates/coverage-rule.md`                                                                         | n/a        | codebase    | Every new skill needs a long-form doc, a plugin README line, and an index entry in the same change.                  | codebase anchor                  |
