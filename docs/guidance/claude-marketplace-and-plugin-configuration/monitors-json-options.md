# monitors.json Schema Reference

The monitors configuration file defines persistent background processes that deliver notifications to Claude during a session. It is a JSON **array** of monitor entry objects.

## File Location

- Default: `monitors/monitors.json` in the plugin root
- Custom path: set the `monitors` field in `plugin.json` (e.g. `"monitors": "./config/monitors.json"`)
- Inline: declare the array directly in `plugin.json` under the `monitors` key

Requires Claude Code v2.1.105 or later.

## Monitor Entry Object

| Field         | Required | Type   | Description                                                                                                |
| ------------- | -------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| `name`        | Yes      | string | Unique identifier within the plugin. Prevents duplicate processes on plugin reload or skill re-invocation. |
| `command`     | Yes      | string | Shell command run as a persistent background process in the session working directory.                     |
| `description` | Yes      | string | Short summary of what is being watched. Shown in the task panel and in notification summaries.             |
| `when`        | No       | string | Controls when the monitor starts (see When Values below). Defaults to `"always"`.                          |

## `when` Values

| Value                            | Description                                                        |
| -------------------------------- | ------------------------------------------------------------------ |
| `"always"`                       | (default) Starts at session start and on plugin reload             |
| `"on-skill-invoke:<skill-name>"` | Starts the first time the named skill in this plugin is dispatched |

## Variable Substitution in `command`

The `command` field supports these substitution variables:

| Variable                | Description                                                   |
| ----------------------- | ------------------------------------------------------------- |
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to the plugin install directory                 |
| `${CLAUDE_PLUGIN_DATA}` | Persistent data directory at `~/.claude/plugins/data/{id}/`   |
| `${user_config.KEY}`    | User config values defined in the plugin's `userConfig` field |
| `${ENV_VAR}`            | Any environment variable                                      |

To run the command from the plugin's own directory, prefix with `cd "${CLAUDE_PLUGIN_ROOT}" && `.

## Behavior

- Each stdout line from the monitor is delivered to Claude as a notification
- Claude can react to log entries, status changes, or polled events automatically
- Monitors run only in interactive CLI sessions — skipped where the Monitor tool is unavailable
- Monitors run unsandboxed at the same trust level as hooks
- Disabling a plugin mid-session does not stop already-running monitors; they stop when the session ends

## Official Reference

https://code.claude.com/docs/en/plugins-reference.md#monitors

## JSON example

available at docs/templates/monitors-example.json
