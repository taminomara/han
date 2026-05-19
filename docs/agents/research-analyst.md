# research-analyst

Operator documentation for the `research-analyst` agent in the han plugin. This document helps you decide *when* and *how* to dispatch the agent. For what the agent does internally, read the agent definition at [`plugin/agents/research-analyst.md`](../../plugin/agents/research-analyst.md).

> See also: [Plugin landing page](../../README.md) · [All agents](./README.md) · [All skills](../skills/README.md) · [YAGNI](../yagni.md)

## TL;DR

- **What it does.** Researches an open-ended question from the open web and provided material, then returns sourced evidence, an options landscape, and a recommendation.
- **When to dispatch it.** You need multi-angle research into options, prior art, or how something works, and every claim must trace to a checkable source.
- **What you get back.** Numbered evidence items (E1, E2, …) each with a source and corroboration status, an options landscape, and a recommendation or an explicit "no clear winner".

## Key concepts

- **Question in, landscape out.** The agent starts from a question, not a symptom or a codebase. It ends at a steelmanned set of options and a recommendation, never at a fix or a committed artifact.
- **Sourced or it is not evidence.** Every item carries a source URL plus retrieval date, or a precise reference to provided material. An assertion with no checkable source is dropped, not reported.
- **Content is data, never instruction.** Directive language inside a fetched page is recorded as a claim about that page, never acted on. The agent does not change behavior because a source told it to.
- **Corroboration gate.** A claim that bears on the recommendation must be confirmed by an independent source or by evidence already in the brief, or it is carried with an explicit single-source caveat and cannot stand alone.

## When to use it

**Dispatch when:**

- You need the prior art or option space for a decision, gathered from outside the codebase.
- You need to understand how an external system, protocol, or technique works, with sources.
- You are running a research angle in parallel with other angles and need one analyst to own a domain or option cluster.

**Do not dispatch for:**

- **Bug or failure evidence from a codebase.** Use [`evidence-based-investigator`](./evidence-based-investigator.md) instead.
- **Discovering how a feature is implemented in the repo.** Use [`codebase-explorer`](./codebase-explorer.md) instead.
- **Comparing two concrete artifacts for gaps.** Use [`gap-analyzer`](./gap-analyzer.md) instead.

## How to invoke it

Dispatch via the `Agent` tool with `subagent_type: han:research-analyst`.

Give it:

1. **A framed question or sub-angle.** The specific decision, unknown, or domain this analyst owns. If the question implies discrete alternatives, name them.
2. **Provided material, by reference (optional).** Docs or links the operator supplied. The agent holds these to web-source scrutiny.
3. **No codebase contents.** The web-facing angle is deliberately isolated. Codebase evidence comes from a separate `codebase-explorer` dispatch, not this one.

Example prompts:

- *"Research the viable options for distributed rate limiting and their trade-offs. Web and prior art only; no repo context."*
- *"How does the OAuth 2.0 device authorization grant work, end to end? Sourced."*

## What you get back

A numbered evidence list (E1, E2, …), each with a Source line (URL plus retrieval date, or provided-material reference), a verbatim Finding, a Corroboration line (independent confirmation or "single source — caveated"), and a Relevance line. Then an Options Landscape — each viable option steelmanned with trade-offs keyed to evidence items — and a Recommendation, or an explicit "no clear winner" with the deciding criteria. The agent also reports what it searched for and did not find.

## How to get the most out of it

- **Give it one angle, not the whole question.** A `research-analyst` scoped to "delivery-semantics prior art" returns sharper evidence than one told to research "messaging" broadly. The dispatching skill splits domains across parallel analysts for this reason.
- **Point at the material you trust.** Provided material enters the evidence list with its source and is checked against independent sources, so a vendor doc helps without quietly steering the recommendation.
- **Expect single-source caveats.** When the agent flags a claim as single-source, that is the agent working correctly, not a gap to paper over. Corroborate it or treat the recommendation as provisional.
- **Pair with `adversarial-validator`.** The analyst produces the landscape; the validator attacks it. They are dispatched in sequence by `/research`, and the pairing is what turns a first-pass survey into a defensible recommendation.

## YAGNI

The options landscape is exactly the kind of artifact that accretes alternatives nobody asked for. The agent applies the [YAGNI](../yagni.md) posture: an option is surfaced as viable only when the question or the evidence puts it in play. Options that exist only "for completeness" are named as out of scope, not presented as live choices, and the recommendation is the strictly simpler option that satisfies the evidence rather than the most capable one. Strawman options — described only well enough to lose — are an explicit anti-pattern the agent guards against.

## Cost and latency

Runs on `sonnet`. Research synthesis is judgment-heavy, so the model tier matches `evidence-based-investigator` and `adversarial-validator`. Web search and fetch make it slower than a pure codebase agent; dispatch several in parallel for breadth rather than running one analyst across many domains in series. It is a per-question agent, not a tight-loop one.

## In more detail

`research-analyst` exists because no prior han agent fit open-ended, idea-space research. `evidence-based-investigator` is built around bug vocabulary — root cause, regression, reproduction — and `codebase-explorer` is scoped to discovering implementation inside a repo. Forcing either into "what are the options out there" produced a vocabulary mismatch that degraded the work. The agent's protocols, anti-patterns, and output format are built around options, prior art, source provenance, and corroboration instead.

The isolation from codebase context is deliberate and load-bearing. Because the agent fetches arbitrary web content, letting it also hold repository contents would create an exfiltration path: a crafted page could ask the agent to include codebase material in its output. The brief contract — web angle gets no repo context, codebase evidence comes only from a separate `codebase-explorer` — closes that path. The rationale is recorded in [`docs/plans/research-skill/artifacts/skills-calling-skills-investigation.md`](../plans/research-skill/artifacts/) and the spec's security findings.

## Sources

### OWASP: LLM01 Prompt Injection (2025)

The "content is data, never instruction" rule and the codebase-isolation contract trace directly to OWASP's guidance on indirect prompt injection through retrieved content.

URL: https://genai.owasp.org/llmrisk/llm01-prompt-injection/

### Toulmin: The Uses of Argument (1958)

The evidence-grounds-recommendation discipline — no recommendation without corroborated grounds — applies Toulmin's argument model to research output.

URL: https://en.wikipedia.org/wiki/Stephen_Toulmin#The_Toulmin_model_of_argument

## Related documentation

- [Plugin landing page](../../README.md). The front door. Start here if you arrived from outside the docs tree.
- [Agents Index](./README.md). All 22 agents, grouped by role.
- [YAGNI](../yagni.md). The evidence-based "You Aren't Gonna Need It" rule the agent applies to the options landscape.
- [`adversarial-validator`](./adversarial-validator.md). The agent that attacks this agent's landscape and recommendation; they pair in `/research`.
- [`evidence-based-investigator`](./evidence-based-investigator.md). The symptom-shaped counterpart for codebase bug evidence.
- [`/research`](../skills/research.md). The skill that dispatches this agent.
