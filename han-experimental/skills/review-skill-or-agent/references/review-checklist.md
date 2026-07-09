# Guidance-Conformance Checklist

Applied by the conformance & quality reviewer (Step 4) against the resolved `target-type`. Apply the section matching the type. Each item names the guidance rule it checks; ground findings against the resolved guidance copy, and cite the rule when raising one. Severity per [finding-classification.md](finding-classification.md).

## Skill target

- **Entity fit** — the artifact is a flowchartable process, not a judgment layer that should be an agent (`plugin-entity-taxonomy.md`).
- **Description** — third person; covers what, when, boundary, and trigger breadth; weaves trigger words into prose, not a keyword list; names sibling skills in boundary clauses and disambiguates in both directions; within 1024 characters (`skill-description-frontmatter.md`, `skill-description-length.md`).
- **Naming** — directory name matches frontmatter `name`; a process/gerund name when the output is a plan or doc; a dependency prefix when an external tool is required; `SKILL.md` cased exactly; no `README.md` in the skill folder (`naming-conventions.md`).
- **Progressive disclosure** — the body is process only and under 500 lines; domain knowledge (rubrics, templates, matrices) lives in `references/`; nothing the toolchain already enforces is restated (`progressive-disclosure.md`, `skill-reference-files.md`).
- **Instruction quality** — steps are specific and actionable; constraints embed reasoning (`Always/Never X BECAUSE Y`); error handling is present on tool-dependent steps; critical instructions sit at the top of a step, not buried (`writing-effective-instructions.md`, `workflow-patterns.md`).
- **Tools and safety** — `allowed-tools` is the minimal set the steps use, with separate Bash entries at the right granularity; `AskUserQuestion` is absent from `allowed-tools`; no angle brackets or non-standard YAML in frontmatter; scripts are not listed in `allowed-tools` (`allowed-tools-bash-permissions.md`, `allowed-tools-AskUserQuestion.md`, `security-restrictions.md`, `script-execution-instructions.md`).
- **Agent dispatch** — every dispatch uses the qualified `defining-plugin:agent-name`, never a bare name or a meta-plugin prefix, and the agent exists in a declared dependency (`agent-dispatch-namespacing.md`).
- **Discovery and degradation** — the skill discovers project specifics dynamically rather than hardcoding them, and degrades gracefully when a tool or git is absent (`dynamic-project-discovery.md`, `graceful-degradation.md`, `optional-git-repositories.md`).
- **Scripts and their invocation** — script invocations use `${CLAUDE_SKILL_DIR}/scripts/...` prose steps, not fenced code blocks or bare relative paths; each skill owns its own scripts; and every script the skill tells an agent or the operator to run carries its full invocation contract — the arguments in order and the outputs to capture — with the skill branching only on keys or exit codes the script actually emits (`script-execution-instructions.md`). A script invoked without its syntax is the canonical miss here.
- **Tests** — each use case maps to a triggering and a functional test (`success-criteria-and-testing.md`).

## Agent target

- **Entity fit and single role** — the artifact is a judgment layer, targets one narrow domain, and only generates or only evaluates, never both (`plugin-entity-taxonomy.md`, `agent-domain-focus.md`).
- **Role identity** — the opening paragraph is under 50 tokens and states domain, task, and perspective, with no flattery or motivational filler (`agent-domain-focus.md`).
- **Domain vocabulary and anti-patterns** — 15–30 precise terms that pass the 15-year-practitioner test, and 5–10 named anti-patterns each with a detection signal, both inlined in the body (`agent-domain-focus.md`).
- **Description** — covers what, when, boundary, and trigger breadth; names near-sibling agents in boundary clauses and disambiguates in both directions; within 1024 characters; vocabulary and anti-patterns stay in the body, not the description (`agent-description-length.md`).
- **Model selection** — `model` is set explicitly and matches the cognitive load, chosen on capability not cost (`agent-model-selection.md`).
- **Self-containment** — no `references/` or `scripts/` folder and no context injection; all protocol and reference content is inlined; frontmatter uses `tools` (not `allowed-tools`); the file relies on no field plugins ignore (`agent-external-files.md`).
- **Tool set** — the `tools` allowlist is the minimum the work needs, each tool used in the body; no `Agent` tool unless the agent's own protocol dispatches sub-agents (`agent-external-files.md`, `agent-dispatch-namespacing.md`).
- **Graceful degradation** — every tool-dependent step checks availability inline and notes the limitation when the tool is absent (`graceful-degradation.md`).
- **Economic justification** — the agent clears the bar for existing: a single well-prompted agent or an instruction tweak to an existing one would not do the job as well (`multi-agent-economics.md`).
