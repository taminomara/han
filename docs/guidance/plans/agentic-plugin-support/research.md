# Agentic Coding Tools — Plugin Support Research

**Date:** 2026-04-21
**Scope:** Survey how the major agentic coding tools (Claude Code, Cursor, GitHub Copilot, Google Gemini CLI / Code Assist, OpenAI Codex) support plugin-like extensibility, so this repository can decide how to publish its skills and agents across all of them.

---

## Executive Summary

**All five tools surveyed now support a bundled plugin concept** — a single installable unit that packages multiple primitives (skills, agents, MCP servers, hooks, commands, rules) under one manifest. GitHub Copilot's bundling lives in Copilot CLI, where `copilot plugin install` treats plugins as directory bundles in the same shape as Claude Code plugins — Copilot CLI even reads `.claude-plugin/plugin.json` as a valid manifest location, making existing Claude Code plugins potentially installable verbatim.

The `SKILL.md` file format has emerged as a **de facto cross-tool standard**. Claude Code, Cursor, Gemini CLI, GitHub Copilot, and OpenAI Codex all recognize the same frontmatter-driven Markdown format, often reading from shared directories like `.agents/skills/` or `.claude/skills/`. This means skills are largely portable today without per-tool duplication.

### Plugin Support Matrix

| Tool | Bundled Plugin | Marketplace | Skills (`SKILL.md`) | Custom Agents | MCP | Hooks | Slash Commands | Rules / Memory |
|---|---|---|---|---|---|---|---|---|
| **Claude Code** | ✅ `.claude-plugin/plugin.json` | ✅ Official (`/plugin marketplace add`) | ✅ Markdown + YAML | ✅ `agents/*.md` (model, tools) | ✅ | ✅ 9 events | ⚠️ Merged into skills | ✅ `CLAUDE.md` |
| **Cursor** (2.5+) | ✅ Full bundle (Feb 2026) | ✅ `cursor.com/marketplace` + team marketplaces | ✅ (in plugin bundle) | ✅ `.cursor/agents/*.md` (also reads `.claude/agents/`) | ✅ `.cursor/mcp.json` | ✅ 20+ events | ✅ `.cursor/commands/*.md` | ✅ `.cursor/rules/*.mdc` + `AGENTS.md` |
| **GitHub Copilot (CLI)** | ✅ `plugin.json` in `.plugin/`, `.github/plugin/`, `.claude-plugin/`, or root | ✅ `copilot-plugins`, `awesome-copilot` pre-registered + custom marketplaces | ✅ `skills/<name>/SKILL.md` | ✅ `agents/*.agent.md` | ✅ `.mcp.json` in plugin | ✅ `hooks.json` in plugin | ✅ `.github/prompts/*.prompt.md` | ✅ `.github/copilot-instructions.md` + path-scoped |
| **Gemini CLI** | ✅ Extensions (`gemini-extension.json`) | ⚠️ Uncurated gallery (`geminicli.com/extensions`) | ✅ `skills/<name>/SKILL.md` (agentskills.io) | ⚠️ Preview: `agents/*.md` in extension | ✅ First-class | ✅ 11 events | ✅ TOML in `commands/` | ✅ `GEMINI.md` (configurable to `AGENTS.md`) |
| **OpenAI Codex** | ✅ `.codex-plugin/plugin.json` | ✅ Plugin Directory in app + marketplace | ✅ `skills/<name>/SKILL.md` | ⚠️ Separate — `.codex/agents/*.toml` (TOML, not bundled in plugin) | ✅ `~/.codex/config.toml` (shared CLI + IDE) | ⚠️ Docs sparse (404) | ✅ Built-ins + custom | ✅ `AGENTS.md` |
| **Copilot (non-CLI surfaces)** | ❌ No bundled artifact | ⚠️ GitHub Marketplace (hosted GitHub Apps only) | ✅ `.github/skills/` (cross-compat with `.claude/skills/`) | ✅ `.github/agents/*.agent.md` | ✅ `.vscode/mcp.json` + cloud agent UI | ❌ Not documented | ✅ `.github/prompts/*.prompt.md` | ✅ `.github/copilot-instructions.md` |
| **Gemini Code Assist** (IDE) | ❌ Inherits CLI extensions | — | Via bundled CLI | Via bundled CLI | ✅ | — | ✅ | ✅ Markdown context files |

**Legend:** ✅ = officially supported, ⚠️ = partial / preview / caveats, ❌ = not supported.

### Key Takeaways

1. **All five tools support true plugin bundles through their CLI surface.** A single manifest can ship skills + MCP at minimum, and usually more. The formats are structurally parallel (kebab-case manifest + entity subdirectories).
2. **Copilot CLI explicitly supports `.claude-plugin/` as a manifest location** — this repo's existing Claude Code plugins are candidates for direct install via `copilot plugin install testdouble/skills-internal`, pending validation that entity paths resolve identically.
3. **Copilot IDE / cloud agent surfaces still require per-primitive publishing** to the well-known `.github/...` paths. The bundled plugin story is CLI-first.
4. **Skill-level portability is broad.** Cursor, Gemini CLI, Copilot, and Codex all explicitly read from `.claude/skills/` or `.agents/skills/` in addition to their native paths. Same `SKILL.md` content works everywhere.
5. **Custom-agent portability is weaker.** Claude Code, Cursor, and Copilot use Markdown+YAML; Codex uses TOML; Gemini CLI's custom-agent support is preview. Cross-tool agents need format shims.
6. **Memory/instructions are converging on `AGENTS.md`.** The cross-tool [`AGENTS.md`](https://agents.md/) standard is recognized by Codex and Gemini CLI natively and by Cursor as an alternative. Copilot still mandates `.github/copilot-instructions.md`; Claude Code still uses `CLAUDE.md`.

---

## Detailed Findings

### 1. Claude Code (Anthropic)

#### C1 — Marketplace exists and is slash-command driven

Users add a marketplace and install plugins by name:

```
/plugin marketplace add testdouble/skills-internal
/plugin install han@testdouble-skills-internal
/plugin marketplace update
```

Primary evidence: this repository's `README.md` (lines 19–32) and its working `marketplace.json`.

Source: <https://code.claude.com/docs/en/plugins-reference>

#### C2 — Marketplace registry: `.claude-plugin/marketplace.json`

The marketplace root is a git repo (or local path) with `.claude-plugin/marketplace.json` containing `name`, `owner`, `metadata.description`, and a `plugins[]` array where each entry has `name`, `source`, `description`, and `version`.

Evidence: `/Users/mxriverlynn/dev/testdouble/skills-internal/.claude-plugin/marketplace.json`.

#### C3 — Plugin on-disk structure

A plugin directory contains:

- `.claude-plugin/plugin.json` — required metadata; optional pointers like `"skills": "./skills"`, `"hooks": "./hooks"`, `"agents": "./agents"`.
- `skills/<name>/SKILL.md`
- `agents/<name>.md`
- `hooks/hooks.json` + scripts

Evidence: `plugins/han/.claude-plugin/plugin.json` and `plugins/hook-logger/.claude-plugin/plugin.json`.

#### C4 — Skills: Markdown + YAML frontmatter

```yaml
---
name: "investigate"
description: >
  Evidence-based investigation of issues, bugs, ...
allowed-tools: Read, Glob, Grep, Agent
---
```

Required frontmatter: `name`, `description`. Optional: `argument-hint`, `allowed-tools`. Body supports runtime context injection via `` !`command` `` syntax. Source: <https://code.claude.com/docs/en/skills>.

#### C5 — `allowed-tools` per-skill allowlist

Each Bash prefix is its own entry: `Bash(git *), Bash(find *)`. Known footgun: listing `AskUserQuestion` silently breaks interactive prompts (upstream bug `anthropics/claude-code#29547`).

#### C6 — Custom agents (subagents) as `.md`

```yaml
---
name: project-manager
description: "Seasoned, facilitative project manager..."
tools: Read, Glob, Grep, Bash(git *), Bash(find *), Write
model: opus
---
```

Frontmatter: `name`, `description`, `tools`, `model` (`opus` | `sonnet` | `haiku` | `inherit`). Agents are single self-contained `.md` files — no `references/` or `scripts/` subfolders. Source: <https://code.claude.com/docs/en/sub-agents>.

#### C7 — Hooks via `hooks/hooks.json`

Events observed: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `SessionStart`, `SessionEnd`, `PreCompact`, `Notification`. `$CLAUDE_PLUGIN_ROOT` is injected so hook scripts can locate themselves. Source: <https://code.claude.com/docs/en/hooks>.

#### C8 — Slash commands deprecated, merged into skills

Per `docs/plugin-entity-taxonomy.md`: "Commands have been merged into skills in Claude Code. They should no longer be created as separate entities."

#### C9 — MCP servers

Plugins can ship MCP server configs. Observed at runtime: `mcp__plugin_slack_slack__*`, `mcp__pencil__*`, `mcp__claude-in-chrome__*`. Source: <https://code.claude.com/docs/en/mcp>.

#### C10 — Four discovery paths + multi-channel distribution

Build system discovers plugins from `plugins/`, `skills/` (auto-wrapped), `gists/{username}/plugins/{name}/`, and any root dir with `plugin.json` or `SKILL.md`. Distribution: git-backed marketplace, ZIP archives via GitHub Releases (Claude Desktop), per-skill ZIPs for Claude Cowork, local dev paths.

#### C11 — Three-tier config

Global `~/.claude/settings.json`, project `.claude/settings.json`, user-local `.claude/settings.local.json`. Memory: `CLAUDE.md` at project root and `~/.claude/CLAUDE.md`.

#### Sources

- Plugin reference: <https://code.claude.com/docs/en/plugins-reference>
- Skills: <https://code.claude.com/docs/en/skills>
- Subagents: <https://code.claude.com/docs/en/sub-agents>
- Agent Teams: <https://code.claude.com/docs/en/agent-teams>
- Hooks: <https://code.claude.com/docs/en/hooks>
- MCP: <https://code.claude.com/docs/en/mcp>
- Primary in-repo evidence: this repository itself

---

### 2. Cursor (Anysphere)

#### CU1 — Extension marketplace via Open VSX

Cursor's in-app extension library is backed by Open VSX (not Microsoft's VS Code Marketplace). Cursor publishes "Anysphere"-authored forks of popular extensions for compatibility.

- <https://forum.cursor.com/t/extension-marketplace-changes-transition-to-openvsx/109138>
- <https://devclass.com/2025/04/08/vs-code-extension-marketplace-wars-cursor-users-hit-roadblocks/>

#### CU2 — Rules: `.cursor/rules/*.mdc` (MDC format)

Rules are the closest analog to Claude Code skills *for project guidance*. Locations:

- Project: `.cursor/rules/`
- User: global dashboard
- Team: Team/Enterprise dashboard

MDC uses YAML frontmatter with `description`, `globs`, `alwaysApply`. Cursor also honors a lightweight `AGENTS.md` as an alternative. Source: <https://cursor.com/docs/context/rules>.

#### CU3 — Legacy `.cursorrules`

Root-level `.cursorrules` still supported but community-reported as deprecated; docs steer users to `.cursor/rules/` or `AGENTS.md`.

#### CU4 — Subagents (custom agents)

Introduced Cursor 2.4 (Jan 2026). Custom Modes (the earlier primitive) were **removed in 2.1**.

- Project: `.cursor/agents/`
- User: `~/.cursor/agents/`
- Cross-tool: also reads `.claude/agents/` and `.codex/agents/`

Frontmatter: `name`, `description`, `model` (`inherit` | `fast` | specific ID), `readonly`, `is_background`. Project agents take precedence on name conflicts.

- <https://cursor.com/docs/subagents>
- <https://cursor.com/changelog/2-4>

#### CU5 — MCP

Config at `.cursor/mcp.json` (project) or `~/.cursor/mcp.json` (global). JSON with `mcpServers` object. One-click deep-links, Settings UI, or hand-edited JSON. Gotcha: servers only load at startup — restart required. Source: <https://cursor.com/docs/mcp>.

#### CU6 — Slash commands (Cursor 1.6, Sept 2025)

`.cursor/commands/*.md` (project) and global user-level commands. Trigger via `/` in Agent input. Built-ins include `/summarize`, `/add-plugin`.

- <https://cursor.com/changelog/1-6>
- <https://cursor.com/docs/cli/reference/slash-commands>

#### CU7 — Hooks (Cursor 1.7, Oct 2025 — beta)

Config at `.cursor/hooks.json` (project) or `~/.cursor/hooks.json`. Rich event set:

`sessionStart`, `sessionEnd`, `preToolUse`, `postToolUse`, `postToolUseFailure`, `subagentStart`, `subagentStop`, `beforeShellExecution`, `afterShellExecution`, `beforeMCPExecution`, `afterMCPExecution`, `beforeReadFile`, `afterFileEdit`, `beforeSubmitPrompt`, `preCompact`, `stop`, `afterAgentResponse`, `afterAgentThought`, `beforeTabFileRead`, `afterTabFileEdit`.

Command-based (stdin/stdout JSON) or LLM-evaluated prompt-based. Sources: <https://cursor.com/docs/hooks>, <https://www.infoq.com/news/2025/10/cursor-hooks/>.

#### CU8 — Plugin marketplace (Cursor 2.5, Feb 17 2026) — full bundle

**This is the direct analog to Claude Code plugins.** Plugins bundle skills + subagents + MCP servers + hooks + rules as a single installable unit.

- Install: `/add-plugin` slash command, or browse <https://cursor.com/marketplace>
- Publish: <https://cursor.com/marketplace/publish>
- Spec repo: <https://github.com/cursor/plugins>
- Launch partners: Amplitude, AWS, Figma, Linear, Stripe, Cloudflare, Vercel, Databricks, Snowflake, Hex
- Announcement: <https://cursor.com/blog/marketplace>
- Docs: <https://cursor.com/docs/plugins>

#### CU9 — Team marketplaces (Cursor 2.6)

Private team marketplaces for Team/Enterprise plans with central governance. Source: <https://forum.cursor.com/t/cursor-2-6-team-marketplaces-for-plugins/153484>.

#### CU10 — Skills marketplace (Cursor 2.4)

Separate from full plugins, 2.4 shipped a skills-only marketplace. Preceded the full plugin marketplace in 2.5.

#### CU11 — Community hub: cursor.directory

Unofficial community site hosting rules, MCP servers, and plugins organized by language/framework.

- <https://cursor.directory/>
- <https://github.com/sanjeed5/awesome-cursor-rules-mdc>
- <https://github.com/spencerpauly/awesome-cursor-skills>

#### CU12 — Differences vs Claude Code

- Subagents natively read `.claude/agents/` and `.codex/agents/` — cross-tool portability by design.
- `readonly` and `is_background` booleans in agent frontmatter have no Claude Code equivalent.
- Hook taxonomy is richer (Tab-completion hooks have no Claude Code analog).
- Open feature request (Dec 2025): "Agent Plugins: Isolated packaging + lifecycle management" — suggests bundle isolation not yet as strong as Claude Code's. Source: <https://forum.cursor.com/t/agent-plugins-isolated-packaging-lifecycle-management-for-sub-agents-skills-hooks-rules-incl-agent-md-across-cursor-ide-cli/151250>.

---

### 3. GitHub Copilot

Copilot's extensibility story spans three distinct surfaces: **Copilot CLI** (which has a full bundled plugin system directly comparable to Claude Code), **Copilot Chat in IDEs** (per-primitive files under `.github/`), and **Copilot Extensions as GitHub Apps** (hosted services on GitHub Marketplace). The CLI surface is the primary "plugin" story; the IDE and GitHub-App surfaces are treated separately.

#### CP1 — Copilot CLI plugins: a full bundled plugin system

Source: <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-finding-installing>

*"Plugins are packages that extend the functionality of Copilot CLI."* Plugins must contain a `plugin.json` in one of these locations:

- `.plugin/`
- `.github/plugin/`
- **`.claude-plugin/`** — the same location Claude Code uses
- Repository root

**This means a Claude Code plugin's `.claude-plugin/plugin.json` is a valid Copilot CLI plugin manifest location.** This is an explicit cross-compatibility signal from GitHub.

Installation methods:

```
copilot plugin install PLUGIN-NAME@MARKETPLACE-NAME
copilot plugin install OWNER/REPO
copilot plugin install URL-OF-GIT-REPO
copilot plugin install ./PATH/TO/PLUGIN
copilot plugin install OWNER/REPO:PATH/TO/PLUGIN
```

Management: `copilot plugin list | update | uninstall`.

Storage on disk:
- Marketplace plugins: `~/.copilot/installed-plugins/MARKETPLACE/PLUGIN-NAME/`
- Direct installs: `~/.copilot/installed-plugins/_direct/SOURCE-ID/`

#### CP2 — Pre-registered marketplaces

Two marketplaces come pre-registered: `copilot-plugins` and `awesome-copilot`. The primary community marketplace is <https://github.com/github/awesome-copilot> — a GitHub-hosted repo containing `agents/`, `instructions/`, `skills/`, `plugins/`, `hooks/`, `workflows/`, `cookbook/` directories. It operates as a marketplace without using a `.claude-plugin/marketplace.json`; discovery is via a companion site (`awesome-copilot.github.com`) and a machine-readable `llms.txt` file.

#### CP3 — `plugin.json` manifest schema

Source: <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating>

Fields:
- `name` (required)
- `description`
- `version` — semver
- `author` — `{name, email}`
- `license`
- `keywords` — array
- `agents` — directory path for custom agents
- `skills` — directory path(s) for skill definitions
- `hooks` — path to hooks config file
- `mcpServers` — path to MCP server config

Bundled entities:

| Entity | Format | Location |
|---|---|---|
| Agents | `NAME.agent.md` (Markdown + frontmatter) | `agents/` |
| Skills | `skills/NAME/SKILL.md` | `skills/` |
| Hooks | `hooks.json` | plugin root |
| MCP servers | `.mcp.json` | plugin root |

This is a near-direct structural parallel to Claude Code's plugin layout — same kebab-case manifest, same `skills/NAME/SKILL.md` path, same agent Markdown format, same `hooks.json` conceptually.

#### CP4 — Repository custom instructions (IDE + cloud agent)

VS Code auto-detects `.github/copilot-instructions.md`. Plain Markdown, no frontmatter required.

- <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions>
- <https://code.visualstudio.com/docs/copilot/customization/custom-instructions>

#### CP5 — Path-scoped instructions

`.github/instructions/NAME.instructions.md` with YAML frontmatter:

```yaml
---
applyTo: "**/*.ts"
excludeAgent: "code-review"
---
```

Glob patterns; comma-separate multiple.

#### CP6 — Prompt files (`.prompt.md`)

Stored in `.github/prompts/` (workspace) or user profile. Frontmatter: `description`, `name`, `argument-hint`, `agent`, `model`, `tools`. Invoked by `/<name>` or "Chat: Run Prompt".

Source: <https://code.visualstudio.com/docs/copilot/customization/prompt-files>

#### CP7 — Custom agents (formerly chat modes) — `.agent.md`

Renamed from `.chatmode.md`. Stored in `.github/agents/` (workspace) or `~/.copilot/agents/` (profile). Frontmatter: `description`, `tools`, `model` (single or prioritized array).

Source: <https://code.visualstudio.com/docs/copilot/customization/custom-chat-modes>

#### CP8 — Agent Skills (Dec 18, 2025)

Released 2025-12-18. Works across Copilot cloud agent, Copilot CLI, and VS Code agent mode.

Storage:
- Project: `.github/skills/`, `.claude/skills/`, or `.agents/skills/`
- Personal: `~/.copilot/skills/`, `~/.claude/skills/`, or `~/.agents/skills/`
- Configurable via `chat.agentSkillsLocations`

SKILL.md frontmatter: `name` (lowercase/hyphens), `description`, `argument-hint`, `user-invocable`, `disable-model-invocation`. Three-stage progressive loading. **Explicitly an open standard** — cross-compatible with Claude Code's `.claude/skills` directories.

- <https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/>
- <https://docs.github.com/en/copilot/concepts/agents/about-agent-skills>
- <https://code.visualstudio.com/docs/copilot/customization/agent-skills>

#### CP9 — MCP (IDE + CLI + cloud agent)

**VS Code:** `.vscode/mcp.json` or user profile `mcp.json`. Example: `{"servers": {"github": {"type": "http", "url": "https://api.githubcopilot.com/mcp"}}}`.

**Cloud agent:** MCP JSON in repo Settings → Copilot → Cloud agent → MCP configuration. Tools only (no resources/prompts). Allowlisted tools run autonomously.

**CLI plugin:** `.mcp.json` bundled in the plugin, referenced by `mcpServers` in `plugin.json`.

- <https://code.visualstudio.com/docs/copilot/customization/mcp-servers>
- <https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp>

#### CP10 — Copilot coding agent (async cloud) environment

Env customized via `.github/workflows/copilot-setup-steps.yml` — single `copilot-setup-steps` job in GitHub Actions before Copilot starts. Extended by custom instructions (CP4/CP5), MCP config (CP9), Agent Skills (CP8).

Source: <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/customize-the-agent-environment>

#### CP11 — Copilot Extensions (GitHub Apps) — separate concept

These are the older "Copilot Extensions" that are hosted services, not file bundles, and should not be confused with Copilot CLI plugins. Built as GitHub Apps with two flavors:

- **Skillsets** — lightweight; Copilot handles routing, prompt crafting, function evaluation.
- **Agents** — full flexibility; custom logic, other LLMs, own Copilot API use.

Distributed via GitHub Marketplace: <https://github.com/marketplace?type=apps&copilot_app=true>. Require hosted infrastructure.

- <https://docs.github.com/en/copilot/building-copilot-extensions/setting-up-copilot-extensions>
- <https://docs.github.com/en/copilot/concepts/extensions/skillsets>

#### CP3 — Repository custom instructions

VS Code auto-detects `.github/copilot-instructions.md`. Plain Markdown, no frontmatter required.

- <https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions>
- <https://code.visualstudio.com/docs/copilot/customization/custom-instructions>

#### CP4 — Path-scoped instructions

`.github/instructions/NAME.instructions.md` with YAML frontmatter:

```yaml
---
applyTo: "**/*.ts"
excludeAgent: "code-review"
---
```

Glob patterns; comma-separate multiple. Source: same as CP3.

#### CP5 — Prompt files (`.prompt.md`)

Stored in `.github/prompts/` (workspace) or user profile. Frontmatter: `description`, `name`, `argument-hint`, `agent`, `model`, `tools`. Invoked by `/<name>` or "Chat: Run Prompt".

Source: <https://code.visualstudio.com/docs/copilot/customization/prompt-files>.

#### CP6 — Custom agents (formerly chat modes) — `.agent.md`

Renamed from `.chatmode.md`. Stored in `.github/agents/` (workspace) or `~/.copilot/agents/` (profile). Frontmatter: `description`, `tools`, `model` (single or prioritized array). Source: <https://code.visualstudio.com/docs/copilot/customization/custom-chat-modes>.

#### CP7 — Agent Skills (Dec 18, 2025)

Released 2025-12-18. Works across Copilot cloud agent, Copilot CLI, and VS Code agent mode.

Storage:
- Project: `.github/skills/`, `.claude/skills/`, or `.agents/skills/`
- Personal: `~/.copilot/skills/`, `~/.claude/skills/`, or `~/.agents/skills/`
- Configurable via `chat.agentSkillsLocations`

SKILL.md frontmatter: `name` (lowercase/hyphens), `description`, `argument-hint`, `user-invocable`, `disable-model-invocation`. Three-stage progressive loading. **Explicitly an open standard** — cross-compatible with Claude Code's `.claude/skills` directories.

- <https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/>
- <https://docs.github.com/en/copilot/concepts/agents/about-agent-skills>
- <https://code.visualstudio.com/docs/copilot/customization/agent-skills>

#### CP8 — MCP support (IDE + CLI + cloud agent)

**VS Code:** `.vscode/mcp.json` or user profile `mcp.json`. Example: `{"servers": {"github": {"type": "http", "url": "https://api.githubcopilot.com/mcp"}}}`.

**Cloud agent:** MCP JSON in repo Settings → Copilot → Cloud agent → MCP configuration. Tools only (no resources/prompts). Allowlisted tools run autonomously.

JetBrains / Visual Studio / Xcode Copilot each support MCP through their own config surfaces.

- <https://code.visualstudio.com/docs/copilot/customization/mcp-servers>
- <https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp>

#### CP9 — Copilot coding agent (async cloud) environment

Env customized via `.github/workflows/copilot-setup-steps.yml` — single `copilot-setup-steps` job executed in GitHub Actions before Copilot starts. Use cases: preinstall deps, larger runners, Windows, Git LFS, secrets in a dedicated `copilot` environment. Extended by custom instructions (CP3/CP4), MCP config (CP8), Agent Skills (CP7).

Source: <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/customize-the-agent-environment>.

#### CP12 — VS Code settings.json customization

`chat.agentSkillsLocations`, `chat.promptFiles`, `chat.promptFilesLocations`, `chat.instructionsFilesLocations`, `github.copilot.chat.codeGeneration.useInstructionFiles`, `chat.tools.autoApprove`, MCP toggles.

#### CP13 — Comparison vs Claude Code plugins

**Copilot CLI plugins are the direct analog to Claude Code plugins** and share a remarkable amount of structure:

| Concern | Claude Code | Copilot CLI plugin |
|---|---|---|
| Manifest location | `.claude-plugin/plugin.json` | **`.claude-plugin/plugin.json`** (also `.plugin/`, `.github/plugin/`, root) |
| Skills | `skills/<name>/SKILL.md` | `skills/<name>/SKILL.md` |
| Agents | `agents/<name>.md` | `agents/<name>.agent.md` |
| Hooks | `hooks/hooks.json` | `hooks.json` |
| MCP servers | plugin-level config | `.mcp.json` |
| Marketplace | `/plugin marketplace add OWNER/REPO` | `copilot plugin install OWNER/REPO` |

The remaining Copilot surfaces (IDE chat, cloud coding agent) still consume per-primitive `.github/...` files rather than a bundle — but Agent Skills (CP8) explicitly reads from `.claude/skills/` paths, so skills travel across surfaces without duplication.

**Convergence:** Agent Skills is explicitly an open standard, and Copilot CLI's acceptance of `.claude-plugin/plugin.json` as a manifest location is an explicit interop gesture. Claude Code's plugins are, in most cases, directly installable as Copilot CLI plugins.

---

### 4. Google Gemini CLI / Gemini Code Assist

#### Gemini CLI (open source `@google/gemini-cli`)

##### G1 — Extensions are the bundled plugin unit

Quote from official docs: *"Gemini CLI extensions package prompts, MCP servers, custom commands, themes, hooks, sub-agents, and agent skills into a familiar and user-friendly format."*

Extension layout: `gemini-extension.json` manifest + optional `commands/` (TOML), `skills/` (`SKILL.md`), `agents/` (`.md`), `hooks/hooks.json`, `policies/` (`.toml`), `GEMINI.md`. Manifest supports `name`, `version`, `description`, `mcpServers`, `contextFileName`, `excludeTools`, `settings`, `plan.directory`, `themes`.

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/extensions/index.md>

##### G2 — Install commands and gallery

CLI subcommands: `gemini extensions install <source> [--ref --auto-update --pre-release --consent --skip-settings]`, `uninstall`, `disable`, `enable`, `update [--all]`, `new <path> [template]` (templates: `mcp-server`, `context`, `custom-commands`), `link <path>`.

Gallery: <https://geminicli.com/extensions> (~871 extensions, **explicitly uncurated** — "Google does not vet, endorse, or guarantee the functionality or security of these extensions").

##### G3 — `GEMINI.md` context files

Hierarchical loading: global `~/.gemini/GEMINI.md`, workspace `GEMINI.md` files (walking up), just-in-time files when tools access a directory. Supports `@file.md` imports and `/memory show|reload|add`. Filename configurable via `context.fileName` (can be set to `["AGENTS.md", "CONTEXT.md", "GEMINI.md"]`).

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/gemini-md.md>

##### G4 — Custom slash commands (TOML)

`~/.gemini/commands/` (user) or `.gemini/commands/` (project, higher precedence). Subdirectories namespace via colon: `git/commit.toml` → `/git:commit`. Fields: required `prompt`, optional `description`. Supports `{{args}}` injection and `!{shell_command}` with confirmation. Reload via `/commands reload`.

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md>

##### G5 — Agent skills (agentskills.io open standard)

Same `SKILL.md` format Anthropic released. Three tiers (Workspace > User > Extension):

- Workspace: `.gemini/skills/` or `.agents/skills/`
- User: `~/.gemini/skills/` or `~/.agents/skills/`
- Extension: bundled

Activation via `activate_skill` tool with consent prompt. Progressive disclosure (name+description loaded first). Management: `gemini skills list|link|install|uninstall|enable|disable` and `/skills`. Installable from Git repo, local dir, or `.skill` zip.

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md>

##### G6 — Subagents (custom in preview)

Built-ins shipped by default: `codebase_investigator`, `cli_help`, `generalist`, `browser_agent` (experimental). Invoked automatically or explicitly via `@subagent_name prompt`. Overrides in `settings.json` (`model`, `maxTurns`, etc.).

**Custom subagents via extensions exist but are flagged preview:** *"Sub-agents are a preview feature currently under active development"*. Custom definitions in extension `agents/*.md`.

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md>

##### G7 — MCP (first-class)

Configurable in `settings.json` or extension manifests (`mcpServers`). All options supported except `trust`. `${extensionPath}` variable for portability. Settings-level servers override extension-level on name conflict.

##### G8 — Custom tools via MCP only

No separate native tool API. `mcp-server` template scaffolds `@modelcontextprotocol/sdk` Node servers. `excludeTools` manifest field blocklists built-ins or restricts shell commands (e.g. `"run_shell_command(rm -rf)"`).

##### G9 — Hooks (11 lifecycle events)

`SessionStart`, `SessionEnd`, `BeforeAgent`, `AfterAgent`, `BeforeModel`, `AfterModel`, `BeforeToolSelection`, `BeforeTool`, `AfterTool`, `PreCompress`, `Notification`. stdin/stdout JSON; exit 2 = block. Regex matchers for tool events, exact strings for lifecycle. Configured in `settings.json` or via extension `hooks/hooks.json` (**not in the extension manifest itself**).

Source: <https://github.com/google-gemini/gemini-cli/blob/main/docs/hooks/index.md>

##### G10 — Policy engine

Extensions may ship `policies/*.toml` for tool-authorization rules (tier 2: above defaults, below user/admin). *"Gemini CLI ignores any `allow` decisions or `yolo` mode configurations in extension policies"* — extensions cannot self-authorize dangerous ops.

#### Gemini Code Assist (IDE product)

##### G11 — Narrower IDE extensibility

VS Code and JetBrains extensions support:

- **Agent mode** powered by an embedded Gemini CLI. VS Code: "all of the Gemini CLI built-in tools available." JetBrains: reduced set.
- **MCP servers**: "Configure MCP servers to extend the agent's abilities."
- **Context files in Markdown**
- **Smart/slash commands** on the quick pick bar

No dedicated IDE-specific marketplace, custom-agent UI, or skills registry. Extensibility largely inherited from the embedded CLI.

Source: <https://docs.cloud.google.com/gemini/docs/codeassist/agent-mode>

##### G12 — Gap vs Claude Code

Near-complete parity for Gemini CLI: `gemini-extension.json` is a direct structural peer to `.claude-plugin/plugin.json`. Main gaps: hooks live in a separate `hooks/hooks.json` rather than being declared in the extension manifest, and custom subagents are preview. Gemini Code Assist (IDE) has no bundled-plugin story of its own.

---

### 5. OpenAI Codex

*NB: This concerns the 2025+ agentic Codex product family — Codex CLI, ChatGPT Codex web agent, Codex IDE extension — not the legacy 2021 Codex model.*

#### CX1 — Codex plugins are a first-class bundling concept

From <https://developers.openai.com/codex/plugins>: *"Plugins bundle skills, app integrations, and MCP servers into reusable workflows for Codex."* Installed via Plugin Directory in the Codex app, the CLI `/plugins` command, or marketplace sources. *"More plugin capabilities are coming soon."*

#### CX2 — Plugin structure

```
my-plugin/
├── .codex-plugin/plugin.json   (required)
├── skills/my-skill/SKILL.md    (optional)
├── .app.json                   (optional)
├── .mcp.json                   (optional)
└── assets/                     (optional)
```

Manifest: kebab-case `name`, `version`, `description`, `skills` path. Structural parallel to Claude Code's `.claude-plugin/plugin.json`.

Source: <https://developers.openai.com/codex/plugins/build>

#### CX3 — Skills use SKILL.md with YAML frontmatter

*"A skill is a directory with a `SKILL.md` file plus optional scripts and references. The `SKILL.md` file must include `name` and `description`."*

Discovery order: repo `.agents/skills` (any depth), user `$HOME/.agents/skills`, admin `/etc/codex/skills`, plus OpenAI-bundled. Explicit invocation or implicit description matching — same pattern as Claude Code.

Source: <https://developers.openai.com/codex/skills>

#### CX4 — AGENTS.md is the cross-tool standard

Standard Markdown. Promoted at <https://agents.md/> as a shared convention across Codex, Google Jules, Aider, goose, Devin, Copilot, Cursor, Zed, JetBrains Junie, Warp, Windsurf, Gemini CLI. Codex merge order: `~/.codex/AGENTS.override.md` → `~/.codex/AGENTS.md` → git root walking down, with `AGENTS.override.md` at each directory. Closer files override. Byte limit `project_doc_max_bytes` default 32 KiB.

Sources: <https://agents.md/>, <https://developers.openai.com/codex/guides/agents-md>

#### CX5 — Subagents are TOML-defined (not bundled in plugin)

From <https://developers.openai.com/codex/subagents>: *"Codex can run subagent workflows by spawning specialized agents in parallel and then collecting their results in one response."*

TOML files requiring `name`, `description`, `developer_instructions`. Optional: `model`, `sandbox_mode`, `mcp_servers`. Located at `~/.codex/agents/` (user) or `.codex/agents/` (project). Built-ins: default, worker, explorer.

**Differs from Claude Code:** TOML format vs Markdown+frontmatter, and agents are **not** packaged inside the plugin bundle.

#### CX6 — MCP (mature, shared CLI + IDE)

Configured in `~/.codex/config.toml` (global) or `.codex/config.toml` (project, trusted only). *"The CLI and the IDE extension share this configuration."* Setup: `codex mcp add <server-name> -- <command>` or direct TOML. STDIO (`command`/`args`/`env_vars`) and HTTP (`url`/`bearer_token_env_var`) supported. Per-server/per-tool `approval_mode` and `supports_parallel_tool_calls`.

Source: <https://developers.openai.com/codex/mcp>

#### CX7 — Slash commands

30+ built-ins: `/model`, `/plan`, `/clear`, `/compact`, `/diff`, `/review`, `/permissions`, `/status`, `/agent`, `/resume`, `/fork`, `/new`, `/apps`, `/plugins`, …

The CLI features page confirms users can "create custom ones for team-specific tasks or personal shortcuts" — but the dedicated custom-prompts doc page (`/codex/config/prompts`) returned 404 during research, so exact storage/format is unverified here.

Sources: <https://developers.openai.com/codex/cli/slash-commands>, <https://developers.openai.com/codex/cli/features>

#### CX8 — Codex Cloud environments

Setup scripts run in a separate Bash session with internet access to install deps. Maintenance scripts run on cached resume. Env vars persist across setup + agent phase; secrets only available to setup scripts. Agent-phase internet off by default with configurable limited/unrestricted modes, all via HTTP/HTTPS proxy. Auto-installs for npm/yarn/pnpm/pip/pipenv/poetry.

Source: <https://developers.openai.com/codex/cloud/environments>

#### CX9 — IDE extension shares CLI config

VS Code / Cursor / Windsurf extension supports Plugins, Subagents, Skills, MCP, slash commands. MCP config shared: *"Once you configure your MCP servers, you can switch between the two Codex clients without redoing setup."*

Source: <https://developers.openai.com/codex/ide>

#### CX10 — Hooks exist but documentation is sparse

Nav lists Rules and Hooks. MCP config page mentions *"Notifications: Configurable hooks when agent turns complete."* The dedicated hooks page (`/codex/config/hooks`) returned 404 during research — specific event types and format unverified. Appears less mature than Claude Code.

#### CX11 — Gaps vs Claude Code plugins

- **Subagents are NOT bundled in plugins.** Live separately in `~/.codex/agents/` or `.codex/agents/` as TOML.
- **Hooks are NOT clearly part of plugin bundles.**
- **Custom slash commands**: confirmed to exist but bundling-in-plugins story unclear from accessible docs.
- **Agent format differs**: TOML vs Markdown-with-frontmatter.
- **Skills path differs**: `.agents/skills` cross-tool convention rather than `.claude/` scope.

#### CX12 — Customization concept overlap

OpenAI explicitly lists 5 complementary layers at <https://developers.openai.com/codex/concepts/customization>: AGENTS.md, Memories (Chronicle), Skills, MCP, Subagents. *"Complementary, not competing."* Plugins are the bundling layer packaging Skills + Apps + MCP.

#### Sources

- Plugins: <https://developers.openai.com/codex/plugins>, <https://developers.openai.com/codex/plugins/build>
- Skills: <https://developers.openai.com/codex/skills>
- Subagents: <https://developers.openai.com/codex/subagents>
- MCP: <https://developers.openai.com/codex/mcp>
- AGENTS.md: <https://agents.md/>, <https://developers.openai.com/codex/guides/agents-md>
- Slash commands: <https://developers.openai.com/codex/cli/slash-commands>
- Cloud environments: <https://developers.openai.com/codex/cloud/environments>
- IDE: <https://developers.openai.com/codex/ide>
- Customization concept overview: <https://developers.openai.com/codex/concepts/customization>

**Known doc gaps (404 during research):** `/codex/config/hooks`, `/codex/config/prompts`, `/codex/web/environments` (moved to `/codex/cloud/environments`).

---

## Implications for This Repository

1. **Skills are already broadly portable.** The existing `SKILL.md` files in `plugins/*/skills/` and `skills/` should work as-is in Claude Code, Cursor, Gemini CLI, GitHub Copilot, and OpenAI Codex given the shared `.agents/skills` / `.claude/skills` discovery conventions.
2. **Claude Code plugins may install directly in Copilot CLI.** Because Copilot CLI reads `.claude-plugin/plugin.json` as a valid manifest location, plugins in `plugins/` may be usable via `copilot plugin install testdouble/skills-internal:plugins/han` (or similar). Worth validating with a single plugin end-to-end; the agent filename convention is `*.agent.md` for Copilot vs `*.md` for Claude Code, so that rename (or dual-filename) is the likely gap.
3. **Cursor 2.5+ is a new distribution target.** Cursor's plugin marketplace launched Feb 2026; the same skills + agents + MCP + hooks bundle structure this repo already produces maps closely to Cursor's spec (<https://github.com/cursor/plugins>).
4. **Codex needs format adaptation for custom agents.** This repo's Markdown+frontmatter agents in `plugins/han/agents/*.md` would need TOML wrappers to work as Codex subagents.
5. **Gemini CLI is a near-drop-in target** once a `gemini-extension.json` manifest is generated — skill and hook formats are already compatible, custom agents are preview but otherwise shape-aligned.
6. **A per-tool build step is feasible.** The existing `scripts/build.sh` already stages content into `plugin-marketplace-dist/` for Claude Code. Analogous staging targets for Cursor, Gemini CLI, Codex, and Copilot CLI are tractable because the primitive formats (especially `SKILL.md`) overlap so heavily.

## Open Questions

- Codex custom slash command storage/format — the relevant docs page returned 404.
- Codex hook event taxonomy and config format — docs page returned 404.
- Whether Copilot CLI accepts an existing `.claude-plugin/plugin.json` verbatim, or requires Copilot-specific fields (e.g., `agents` directory, `mcpServers` path) to be added. Needs a concrete install test.
- Whether Copilot CLI agent files require the `.agent.md` suffix, or whether `.md` alone works when the `agents` manifest field points at the directory.
- Whether Gemini CLI's "preview" custom subagents are stable enough to publish against, or whether this should wait for GA.
- Whether Cursor plugins can be published directly from this marketplace-style repo, or whether the cursor.com/marketplace publishing flow requires per-plugin submission.
- Whether this repo's top-level `.claude-plugin/marketplace.json` can itself be registered as a Copilot CLI marketplace, or whether Copilot requires a different marketplace format (the `github/awesome-copilot` marketplace does not use `marketplace.json`).
