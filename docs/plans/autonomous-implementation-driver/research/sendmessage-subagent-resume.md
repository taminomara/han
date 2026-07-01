# Research: Can a sub-agent be resumed with context intact via `SendMessage`?

Whether Claude Code's `SendMessage` tool — the mechanism the `Agent`/Task tool result points at for "continue this agent" — is a real, usable primitive for resuming a previously-spawned sub-agent without losing its context, and what it takes to enable it. Relevant to the autonomous-implementation-driver because the conductor would lean on exactly this primitive to hand findings back to a build sub-agent instead of dispatching a fresh one each time.

## Summary

`SendMessage` is **real and officially documented, but gated behind an experimental flag that is off by default**, which is why it does not appear in a normal session and `ToolSearch` cannot find it. It belongs to the **Agent Teams** feature, enabled by setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `settings.json` (`env` block) or the shell environment. Without that variable, no team is set up, no team directories are written, and the tool is not loaded.

There is a genuine **documentation/implementation gap**: the `Agent` tool's output tells you to "use SendMessage with to: '<id>' to continue this agent," and `SendMessage` is documented as the replacement for the removed `resume` parameter — but that instruction only works when the flag is on. Multiple open GitHub issues track this exact mismatch. Even with the flag enabled, there are reports that resuming a plain **sub-agent** (as opposed to a named **teammate**) is still flaky, and the docs list "no session resumption with in-process teammates" as a known limitation.

**Implication for the driver:** do not design the conductor around a reliable "resume the same build sub-agent with its context intact" primitive. As of now that primitive is experimental, flag-gated, and partially broken for the sub-agent case. The safer design — which also matches what the superpowers research already concluded (`superpowers-patterns.md`, S8/S17: dispatch a *fresh* fix sub-agent with curated context) — is to assume no durable continue-agent primitive exists and pass context by file/diff instead.

## What was confirmed (official docs)

From the official Agent Teams page (https://code.claude.com/docs/en/agent-teams, page states "as of v2.1.178"):

- **Gated and off by default:** "Agent teams are experimental and disabled by default. Enable them by adding `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to your settings.json or environment. Without that variable, no team is set up at session start, no team directories are written, and Claude does not spawn or propose teammates."
- **Exact enable mechanism** (verbatim from docs):
  ```json
  {
    "env": {
      "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
    }
  }
  ```
  Set in `~/.claude/settings.json` or the shell environment, then restart the session (env-gated tools load at startup).
- **`SendMessage` is a team coordination tool:** "Team coordination tools such as `SendMessage` and the task management tools are always available to a teammate even when `tools` restricts other tools." It is the mailbox/messaging primitive between agents; a delivered message is injected into the recipient's conversation as a new user message.
- **Known limitation relevant to resume:** "No session resumption with in-process teammates: `/resume` and `/rewind` do not restore in-process teammates."

## The documentation/implementation gap (GitHub issues)

The `Agent` result's "use SendMessage to continue this agent" hint, and `SendMessage` being the documented replacement for the removed `resume` parameter, only function with the flag on. Tracked by:

- [#35240](https://github.com/anthropics/claude-code/issues/35240) — Agent tool docs reference SendMessage for subagent resumption, but it's gated behind the Agent Teams flag.
- [#42737](https://github.com/anthropics/claude-code/issues/42737) — SendMessage unavailable without agent teams, breaking agent resume.
- [#37051](https://github.com/anthropics/claude-code/issues/37051) — SendMessage not available despite being documented as the replacement for `Agent.resume`.
- [#48160](https://github.com/anthropics/claude-code/issues/48160) — Spawned sub-agents can't *originate* SendMessage even with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set.

## How to enable (if we want to test it)

1. Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to the `env` block of `settings.json` (or export it in the shell).
2. Restart the Claude Code session.
3. To actually exercise resumption, spawn a **named teammate**, not a plain sub-agent — per #48160 the plain-sub-agent resume path is the broken one.

## Caveats / not verified

- This was not tested first-hand with the flag enabled in this environment.
- The behavior difference between "teammate" and "sub-agent" resumption rests on issue reports, not on a primary doc statement or a reproduction.
- An earlier research pass cited issue **#47021** and specific changelog dates (e.g. "June 15, 2026"); neither could be independently confirmed and they are excluded here. The corroborated issue is #35240 (plus #42737, #37051, #48160).

## Sources

- [Orchestrate teams of Claude Code sessions — official docs](https://code.claude.com/docs/en/agent-teams) (web, 2026-06-30)
- [Sub-agents — official docs](https://code.claude.com/docs/en/sub-agents) (web, 2026-06-30)
- GitHub issues [#35240](https://github.com/anthropics/claude-code/issues/35240), [#42737](https://github.com/anthropics/claude-code/issues/42737), [#37051](https://github.com/anthropics/claude-code/issues/37051), [#48160](https://github.com/anthropics/claude-code/issues/48160) (web, 2026-06-30)
