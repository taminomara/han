# Research: A durable, conditional re-ground trigger that survives compaction

How a long-running orchestrator skill can reliably re-establish its context ("re-ground") after an event that may have erased its own instructions, an automatic compaction or a long pause/resume, and do so **only when one of its runs is actually in progress** (no irrelevant injection otherwise). Targets both Claude Code and OpenAI Codex, since the suite ships to both.

## Summary

There is **no compaction-surviving "session-local memory"** on either platform. The reliable, portable, conditional trigger is assembled from three durable pieces the platforms already provide: a **run-active marker stored in git config** (durable on disk, outside the working tree and commit history, branch-scoped), a **conditional lifecycle hook** that reads the marker and injects a short re-ground pointer only when it is set, and the **committed ledger** as the state of record. The skill body holds the full re-ground procedure but cannot be trusted to carry the *trigger*, because compaction re-injects skills only truncated.

**Design adopted (D26):** ledger = state; git-config branch marker = "run active" flag; conditional `SessionStart`/`PostCompact` hook = the compaction-surviving trigger; skill = the reload-able procedure.

## What was confirmed

### Session-local memory
- Neither Claude Code nor Codex has a session-scoped memory store that survives compaction. The only thing re-injected in full after compaction is the project instruction file (Claude Code: `CLAUDE.md`; Codex: `AGENTS.md`), which is project-wide and always-on, not session-scoped or conditional.

### Skill re-injection is unreliable for this purpose
- After auto-compaction, Claude Code re-injects only the most-recent invocation of each used skill, truncated to roughly the first 5,000 tokens, within a shared ~25,000-token budget across all invoked skills; older skills can be dropped entirely.
- Consequence: front-loading the re-ground instruction at the top of the SKILL.md is **not** reliable, the skill can be dropped from the budget. The trigger must live outside the skill body.

### Lifecycle hooks exist on both targets and are generally available
- `SessionStart`, `PreCompact`, `PostCompact`, `UserPromptSubmit` exist and are GA on **both** Claude Code and Codex (this retired the portability worry: hooks port).
- A `command`-type hook can run a shell script and return `additionalContext`. There is no built-in "only if a file/marker exists" matcher, so the condition is implemented in the hook script (test the marker, inject only when present, otherwise no-op).

### Git config as the marker store (the operator's idea, refined)
- `git config` stores branch-scoped values in `.git/config`: durable on disk (survives sessions and compaction), **not** in the working tree (never a scope escape, never discarded with partial work), and **not** in commit history (no noise, no cleanup commit).
- Use a **custom key** rather than `branch.<name>.description`; `description` has a conventional use (`format-patch --cover-letter`, some PR tooling) and would collide. A custom key under the branch namespace carries the same properties without overloading a field.
- The marker value can carry the ledger path as payload, so the hook's injected sentence points at the right ledger.
- Portable: plain git, identical on both targets.

## Caveats / not verified
- Whether a `PreCompact` hook can influence what survives the compaction *summary* (vs only injecting after) was not confirmed; the design relies on `SessionStart`/`PostCompact` injecting *after* the event, which is sufficient.
- Codex's `AGENTS.md` has no documented "Compact Instructions"-style prioritized section equivalent to Claude Code's; not relied on.
- The git-config marker is local to the checkout: it does not travel to a fresh clone or another machine. The committed ledger does travel, so cross-machine resume degrades to the operator re-invoking the skill (which reads the ledger). Acceptable, not engineered around.

## Sources
- Claude Code memory and compaction behavior; hooks reference (web, 2026-06-30).
- OpenAI Codex AGENTS.md guide and hooks overview (web, 2026-06-30).
- Operator's branch-config-marker proposal (R13 design conversation).
