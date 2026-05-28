# Why Solo and Small Teams, and Not Large Teams or Enterprise?

Han is built for solo product engineers and small teams. If you are on a 50-person engineering org, or evaluating tooling for a 500-person one, this page is the honest answer to the obvious question: does Han fit your situation? The short version is that Han gives a single engineer the specialist coverage of a team, but does not give a team the shared lift of an enterprise platform. Those are two different goods, and Han is built deliberately for the first.

> See also: [Plugin landing page](../README.md) · [Concepts](./concepts.md) · [Quickstart](./quickstart.md)

## Han acts as a full team on its own

On a solo or small team, you do not have a dedicated security engineer down the hall, a DevOps engineer to argue with about rollout safety, an on-call engineer to push back on a hot code path, a data engineer to scrutinize the schema, a UX designer to flag a confusing flow, an information architect to question the docs structure, a junior generalist to ask the dumb-but-important questions, or a project manager to keep the discussion honest. You have you. The work that a larger team would distribute across those roles still needs to get done, and on a small team it lands on whoever has the cycles.

Han's specialist sub-agents are built to fill those role gaps. When you run [`/code-review`](./skills/code-review.md), the skill dispatches the security analyst, the DevOps engineer, the on-call engineer, the data engineer, the test engineer, the edge-case explorer, and the structural, behavioral, and concurrency analysts at the size of your branch. Each one reads the changes from its own perspective and surfaces findings. When you run [`/plan-a-feature`](./skills/plan-a-feature.md), the project manager runs the discussion, the junior developer stress-tests the assumptions, and three to five specialists chosen by what the feature touches push back on the design. When you run [`/investigate`](./skills/investigate.md), the evidence-based investigator gathers the facts and the adversarial validator argues that the proposed fix will not actually fix the bug.

The value lands hardest where there is no one else in the room to push back. A senior engineer at a small startup writing the auth path does not have a security review pipeline waiting. A solo founder shipping a feature does not have a project manager interrupting to ask which decision is being deferred. Han puts those voices into the room.

Read [Concepts](./concepts.md) for the skill-and-agent model, and the [Quickstart](./quickstart.md) or the [how-to guides](./how-to/README.md) for what running these specialists actually looks like.

## There is intentionally no org-level lift on the output of Han

Han does not ship a server component, a shared knowledge base, a central prompt registry, a governance console, or any enterprise integration for sharing improvements across teams. The output of every skill lands in your working copy and, if you commit, in your repo's git history. That is the whole distribution surface.

This is a deliberate scope choice, not a missing feature. Enterprise AI tooling in 2025 and 2026 is built around several distinct kinds of org-level lift, and Han provides none of them out of the box. The categories worth naming, so you can recognize whether your organization is buying or building any of these:

- **Governance, compliance, and observability.** A centralized control plane for AI usage in the org: seat management, spend controls, policy enforcement, audit logs, and compliance APIs. This is the category that most cleanly distinguishes enterprise AI from individual-developer AI.
- **Shared prompt and instruction registries.** An admin writes behavioral instructions once, and developers across the org inherit them automatically in the surfaces the product covers.
- **Retrieval over shared knowledge and code.** A curated corpus of internal documentation, code, and runbooks that AI tools query at the moment of use, so the AI grounds its responses in what the org knows.
- **Model customization on org code.** Proprietary code is used to tailor model behavior so suggestions match org naming, idioms, and internal APIs.
- **MCP and shared context servers.** An org-hosted Model Context Protocol server exposes internal knowledge to any MCP-compatible AI client. Vendor-neutral, infrastructure-owned by the org.
- **AI-augmented code review at the pull request layer.** AI integrates at the version control workflow rather than the editor, providing cross-repo consistency and pattern enforcement at the merge gate.

Two concrete examples make the shape of org-level lift easier to see.

**GitHub Copilot Enterprise organization custom instructions.** Reached general availability in April 2026. An org admin writes behavioral instructions once in the GitHub admin panel, and every Copilot Chat conversation on github.com, every Copilot code review, and every Copilot cloud agent run inherits them automatically. The instructions cover github.com surfaces only as of GA, not the in-editor experience. The shape of the lift is one admin writing once, with the result propagating to all developers in the org without any developer action. (For the underlying research and citations, see [Enterprise AI tooling integration](./research/enterprise-ai-tooling-integration.md).)

**Anthropic Claude Enterprise governance and compliance.** Claude Enterprise bundles Claude Code and Claude Cowork under a single agreement with workforce-wide deployment, SSO and identity-provider integration, configurable data retention, audit infrastructure, policy enforcement covering tool permissions and MCP server configurations across all Claude Code users, and a Compliance API providing programmatic access to conversation content and activity event logs. The shape of the lift is IT and security having a control plane over AI usage that is visible, auditable, and policy-bounded across the org.

Han does not provide either of these. Han runs in your single Claude Code session, writes to your working copy, and stops there. The improvements you make to a Han skill on your machine do not propagate to anyone else's machine. The agents Han dispatches do not consult a shared knowledge base of your org's prior decisions. There is no audit log of Han runs you can hand to IT. There is no admin panel where someone in your security team approves which Han skills your developers may invoke.

You can integrate Han into something that does that lift. A larger team or an enterprise can wrap Han's output in their own review and distribution pipeline, fork the skills into an internal Claude Code plugin marketplace, or invest in a separate org-level layer that runs alongside Han. None of that comes with Han, and adding it is not on the roadmap.

This matters for your evaluation. If you are looking for tooling that provides centralized governance, shared prompts, indexed org knowledge, or audited AI usage across many developers, Han is not that product, and bolting those things on after the fact will be more work than starting with a product that includes them. The honest path is to look at the enterprise AI offerings that bundle the lift you need. If you are a solo engineer or a small team that needs specialist coverage you do not have headcount for, and you are content to keep the output in your own working copy and git history, Han is built for you.

## Where to go next

- **Read the model.** [Concepts](./concepts.md) walks through the skill-and-agent architecture that runs through the whole plugin.
- **Pick a starting skill.** [Quickstart](./quickstart.md) lists five common situations and the skill sequence that fits each.
- **Run a full workflow.** [How-to guides](./how-to/README.md) walks planning, bug triage, and research end to end.
- **See the enterprise landscape research.** [Enterprise AI tooling integration](./research/enterprise-ai-tooling-integration.md) is the underlying research that informed the org-level-lift discussion above, with citations, evidence status, and an adversarial-validator pass on the findings.
