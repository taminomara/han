# Sizing

Sizing is a foundational mechanic of the han plugin. Every skill that dispatches a swarm of specialist agents — `/code-review`, `/gap-analysis`, `/iterative-plan-review`, `/plan-a-feature`, and `/plan-implementation` — first classifies the work as **small**, **medium**, or **large**, then uses that classification to decide how many agents to dispatch, which agents to dispatch, how many rounds to iterate, and how aggressively to calibrate findings.

> See also: [Plugin landing page — han](../README.md) · [Concepts](./concepts.md) · [YAGNI](./yagni.md) · [All skills](./skills/README.md) · [All agents](./agents/README.md)

## TL;DR

- **Three bands.** Small / medium / large. Each band caps the team or swarm size and the iteration depth.
- **Default is small.** Every sizing-aware skill starts the classification at **small** and only escalates to medium or large when concrete signals clearly require it. When a signal is borderline, the skill stays at the smaller band.
- **Auto-classified.** When the user does not pass `$size`, the skill reads concrete signals — file count, subsystems touched, security/data/infra surface, cross-cutting concerns — and announces the chosen size with a one-line justification before dispatching agents.
- **Always overridable.** Pass the size as the first positional argument when invoking the skill (`/code-review medium`, `/plan-a-feature small "describe the feature"`, etc.). The skill honors the override and still scales the team and round caps to the chosen size.
- **Conservative by design.** Fewer agents producing higher-signal findings is the goal; quantity is not the metric. The skill prefers under-dispatching that the user can re-run at a larger size to over-dispatching that drowns the user in low-signal findings.

## Why sizing matters

Specialist agents are expensive — in tokens, in latency, and in user attention to reconcile their findings. Without sizing:

- A two-line README fix would dispatch the full security, structural, behavioral, concurrency, data, devops, test, and edge-case roster, drown the user in low-signal findings, and burn tokens for nothing.
- A genuinely cross-service change would get the same default roster as a single-file rename, miss specialists whose domain it actually touches, and arrive at the user under-reviewed.
- Findings would not calibrate to scope: a `Suggestion` about a hypothetical scaling concern would land alongside a `Critical` about a real exploit, and the team would have to triage the false-equivalence themselves.

Sizing fixes all three: it picks a roster proportional to the actual change, calibrates each agent's brief to the size, and tells the user up front what was chosen and why.

## The three bands

The exact cutoffs vary per skill (a "medium" code review is not a "medium" feature plan), but the bands carry the same meaning across the plugin:

| Band | Meaning | Typical signals | Team / swarm posture |
|---|---|---|---|
| **Small** | Single subsystem, no cross-cutting concerns, contained surface area. | A handful of files, one module, no auth/PII, no schema or migration, no integration boundary. | Minimum roster — the cheapest specialists that still cover correctness and security. Iteration cap is at its lowest (often a single round). |
| **Medium** | Two or three adjacent subsystems, may touch one cross-cutting concern. | Up to a dozen files, a single API contract, schema migration, new permission check, or new index. | A modest team — required roles plus two to three domain specialists chosen by signal. Iteration cap is moderate. |
| **Large** | Cross-service, security-sensitive, multiple new coordinations, data ownership shifts, or the user explicitly requested it. | More than a dozen files, multiple subsystems, architectural changes, security or data implications. | A larger team — required roles plus four to six domain specialists. Iteration cap is at its highest. |

Each sizing-aware skill restates these bands with skill-specific signals and caps; see the **Sizing** section in each skill's long-form doc.

## How auto-classification works

Each sizing-aware skill performs classification before dispatching agents. The skill:

1. Reads the available context — for code, the changed file list and diff; for plans and specs, the document body; for gap analyses, the structured `gap-analyzer` output.
2. Starts the classification at **small**.
3. Maps signals to a band — file count, subsystem count, presence of security/PII/auth/data/integration concerns, cross-cutting surface area.
4. Escalates from small to medium only when at least one medium-band signal is clearly present, and from medium to large only when at least one large-band signal is clearly present. Borderline signals do not escalate.
5. States the chosen band to the user in one line with a justification (e.g., `Medium: 6 files touched, adds one index and a query for it`).
6. Caps the team or swarm size and the iteration depth based on the band.

## Overriding the size with `$size`

Every sizing-aware skill declares a `$size` positional argument in its frontmatter. The argument is optional — if present, it bypasses the skill's signal-based classification and forces the chosen band; if absent, the skill auto-classifies as above.

Pass the size as the first positional argument when invoking the skill:

```
/code-review medium
/code-review large "focus on the new auth endpoints"
/gap-analysis large
/iterative-plan-review small docs/plans/refactor-cache.md
/plan-a-feature medium "describe the feature here"
/plan-implementation large docs/features/checkout/feature-specification.md
```

Accepted values: `small`, `medium`, `large`. Anything else is treated as part of the trailing context, not as a size, and the skill falls back to auto-classification.

When the size is overridden via `$size`:

- The skill announces the override (`Medium: passed via $size`) instead of an auto-classification justification.
- The team or swarm still scales to the chosen band — overriding to `large` does not also bypass the team cap.
- Specialists are still selected by signal — the size sets the upper bound, but agents whose domain is not actually touched are still skipped.
- Conversational overrides ("actually run this as a large review") still work; `$size` and conversational override are equivalent inputs.

## Sizing across skills at a glance

| Skill | What gets sized | Small | Medium | Large |
|---|---|---|---|---|
| [`/code-review`](./skills/code-review.md) | Agent roster + finding calibration | 1–3 files, single subsystem | 3–10 files, one cross-cutting concern | More than 10 files, multiple subsystems |
| [`/gap-analysis`](./skills/gap-analysis.md) | Optional swarm size | 0–3 gaps, single domain (no swarm by default) | 4–10 gaps, two or three domains (3–4 agents) | 11+ gaps or cross-cutting domains (4–5 agents) |
| [`/iterative-plan-review`](./skills/iterative-plan-review.md) | Lightweight vs team mode + team size + round cap | 2–3 files, single system (lightweight, 1 round) | 3–5 files, one cross-cutting concern (team, 3–4, 2 rounds) | More than 5 files, multiple systems (team, 4–5, 3 rounds) |
| [`/plan-a-feature`](./skills/plan-a-feature.md) | Review-team size cap | Single subsystem (team cap 2) | Two to three subsystems (team cap 3–4) | Cross-service or security-sensitive (team cap 4–5) |
| [`/plan-implementation`](./skills/plan-implementation.md) | Implementation-team size + round cap | Single subsystem (team cap 3, 1 round) | Two to three subsystems (team cap 4–5, 2 rounds) | Cross-service or security-sensitive (team cap 6–8, 3 rounds) |

Read each skill's **Sizing** section for the full per-skill rules.

## Design principles

- **Sizing is transparent.** The skill always announces the chosen band before dispatching agents. The user can override and the skill states the override explicitly.
- **Sizing is conservative.** Borderline signals drop to the smaller band. Over-dispatching is more expensive than under-dispatching when the user can re-run a skill with a larger size.
- **Sizing is signal-driven.** The bands are defined by what the work actually touches, not by who asked for the review. The auto-classification is the same for everyone.
- **Sizing scales the team and the brief.** A larger size dispatches more agents *and* tells each agent that more severity bands are in scope and more findings are acceptable. A smaller size narrows both the roster and what each agent escalates.
- **Sizing is overridable, not configurable.** There is no project-level "always run as medium" setting. The user opts in to the override on each invocation when the auto-classification is wrong.

## Related reading

- [Concepts](./concepts.md) — The skill / agent split. Sizing is a property of skills that dispatch agent swarms.
- [YAGNI](./yagni.md) — The other foundational mechanic. Sizing decides *how much review* an artifact gets; YAGNI decides *what survives* the review.
- [`docs/agent-building-guidelines/multi-agent-economics.md`](../../../docs/agent-building-guidelines/multi-agent-economics.md) — Why dispatching the right number of agents matters more than dispatching the most agents.
- The **Sizing** section in each sizing-aware skill's long-form doc — [`/code-review`](./skills/code-review.md), [`/gap-analysis`](./skills/gap-analysis.md), [`/iterative-plan-review`](./skills/iterative-plan-review.md), [`/plan-a-feature`](./skills/plan-a-feature.md), [`/plan-implementation`](./skills/plan-implementation.md).
