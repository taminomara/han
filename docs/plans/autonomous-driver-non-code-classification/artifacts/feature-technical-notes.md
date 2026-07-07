# Feature Technical Notes: Non-code, meta, and non-deliverable work items

This file captures the one load-bearing mechanic this feature's behavior relies on that is not discoverable from the plugin repo alone. Behavioral statements live in [../feature-specification.md](../feature-specification.md).

## T1: general-purpose is a built-in, always-available agent type

- **Context:** The Outcome and the "Agent-drafted non-code build" flow commit that a non-code build classified as a general-purpose agent runs unattended without ever being a not-installed halt. That commitment is only correct because the general-purpose agent is always present.
- **Technical detail:** `general-purpose` is a built-in Claude Code agent type, not a han-provided agent that could be missing from an install. Two consequences follow. First, the driver's "every named implementation skill or sub-agent must be installed and invocable" validation treats it as always available, so an item whose build is `` `general-purpose` agent, AFK `` never fails the not-installed check the way an uninstalled han skill would. Second, because it is a built-in agent rather than an installed non-han skill, it sits outside the catalog's "never auto-`AFK` an unconfirmed non-han skill" guardrail, which is why the producer may set it to `AFK` without an operator declaration (D3). This is a platform fact, not visible in the han repo's own agent definitions.
- **Supports decisions:** D3, D13
- **Driven by findings:** F3, F6
- **Referenced in spec:** Outcome, Alternate Flows and States (Agent-drafted non-code build), Coordinations
