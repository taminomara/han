# Long-form Doc Coverage Rule

Not every skill or agent needs a long-form doc. This rule decides which do.

## The Rule

A skill or agent gets its own long-form `docs/skills/{name}.md` or `docs/agents/{name}.md` page when **any two** of the following are true:

1. **Multiple modes.** The skill or agent has more than one operating mode — e.g., `/iterative-plan-review` runs in lightweight or team mode; `junior-developer` has artifact-review and conversational modes.
2. **Multiple artifacts.** It produces more than one output file, or writes across more than one location on disk.
3. **Dispatches other agents.** It orchestrates sub-agents or is itself an orchestrator — any planning skill; `/code-review`; `/test-planning`; `/architectural-analysis`.
4. **Named pairings.** It has explicit, recommended pairings with other skills or agents — e.g., `devops-engineer` + `adversarial-security-analyst`; `/plan-a-feature` → `/plan-implementation`.
5. **User-reachable.** It is directly invocable by the user. Every slash-command skill meets this; agents meet it only when users dispatch them manually rather than through a skill.
6. **Non-trivial provenance.** It is grounded in named frameworks, research sources, or vocabulary the reader must learn to read the output — e.g., Rosenfeld/Morville, DITA, Nielsen heuristics, WCAG, DORA.

A skill or agent that meets **only one** of the criteria is well-served by a rich entry in the [Skills Index](../skills/README.md) or [Agents Index](../agents/README.md) — a paragraph at most, with a link to its definition file. No long-form doc needed.

## Examples

| Skill or agent | Criteria met | Long-form? |
| --- | --- | --- |
| `/plan-a-feature` | Modes, artifacts, dispatches, pairings, user-reachable, provenance | Yes |
| `/code-review` | Modes (branch vs files), dispatches, user-reachable, provenance | Yes |
| `information-architect` | Modes (text-only vs sample), artifacts, pairings, provenance | Yes |
| `project-scanner` | User-reachable only | No |
| `structural-analyst` | Non-trivial provenance, pairings | Yes (shared with sibling analysts is acceptable) |

## When to Apply It

- **When a new skill or agent lands.** The PR that introduces it applies the rule; if two criteria are met, a long-form doc lands in the same PR (or a tracked follow-up issue is opened).
- **When a skill or agent grows.** If a skill gains a second mode or starts dispatching sub-agents, re-apply the rule.
- **At plugin-release time.** Quick inventory pass — any skill or agent that crossed the threshold without a long-form doc gets one scheduled.

## The Goal

A consistent depth-floor. Every reader who finds a long-form doc knows what to expect; every reader who reads an index entry knows they have the canonical reference there.
