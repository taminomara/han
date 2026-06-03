---
name: work-items-to-jira
description: >
  Break a work-items.md file (produced by /plan-work-items) into independently-grabbable
  Jira tickets, one per slice, in a single Jira project. Use when you want to turn a
  work-items file into Jira tickets, publish work items as Jira issues, or create
  implementation tickets that can be worked on and tracked in Jira. Requires a configured
  Atlassian MCP server and a target Jira project (or board). Defaults to creating each
  slice as a Story, unassigned, in the backlog; an epic, a different issue type, an
  assignee, and a target column are all optional overrides. Does not produce the
  work-items file itself — use plan-work-items to break a plan into work items first.
  Does not post to GitHub — use work-items-to-issues for GitHub issues.
argument-hint: [path to work-items.md] [--project <KEY> or --board <name>] [--epic <KEY> (optional)] [--type <issue type, default Story>] [--assignee <accountId/email> (optional)] [--column <name, default Backlog>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find *), mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian__getVisibleJiraProjects, mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata, mcp__claude_ai_Atlassian__lookupJiraAccountId, mcp__claude_ai_Atlassian__createJiraIssue, mcp__claude_ai_Atlassian__editJiraIssue, mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__getTransitionsForJiraIssue, mcp__claude_ai_Atlassian__transitionJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql
---

# Work Items to Jira Tickets

Take an already-broken-down `work-items.md` file (produced by `/plan-work-items`) and publish each slice as a Jira ticket in a single target project.

The breakdown work — drafting slices, assigning symbolic IDs, specifying dependencies, inventorying references — has already been done upstream. This skill's job is to validate the format, confirm the target, create one ticket per slice through the Atlassian MCP server, link the within-file dependencies, and place the tickets in the chosen column.

## Rules

- **Every slice posts into one Jira project.** This skill does not split work across repos or projects. A `work-items.md` that names multiple code repos still produces tickets in the single project you name; the repo prose is informational only.
- **Dependencies are within-file only.** Every SYM named in a `Depends on` line must resolve to another slice in the same file. A `Depends on` that names an unknown SYM is a format error to surface for repair.
- **Symbolic-ID prefixes:** accept whatever the input uses. Any uppercase prefix shape is valid (`W-N`, `V2-N`, `EV-N`, …); the prefix has no effect on Jira placement.
- **Defaults:** issue type `Story`, no assignee, reporter taken from the Atlassian MCP identity, and the project's initial status (Backlog). Each is overridable per run; nothing is assigned or moved unless asked.
- **Every slice ticket MUST carry the reference artifacts an implementer needs** — API/event contracts, design references, schema docs, runbooks, ADRs, coding standards. Tickets that consume an HTTP endpoint or event payload MUST reference the contract section that defines it. Full include/exclude list in [references/reference-artifact-inventory.md](references/reference-artifact-inventory.md).
- **NEVER include process artifacts in ticket descriptions.** Excluded: iteration histories, decision logs, review findings, team findings, facilitation summaries, gap analyses, and anything under an `artifacts/` subfolder of the plan that is not a contract or design reference.
- **No screenshot upload or image embedding.** Design references are carried as links, not uploaded into Jira. See [references/jira-ticket-template.md](references/jira-ticket-template.md).

## Process

### 0. Atlassian MCP preflight (hard requirement)

This skill cannot run without a configured and connected Atlassian MCP server. Confirm it is reachable by calling `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to retrieve the cloud ID(s). If the tool is unavailable, the call errors, or it returns no accessible resources, **stop immediately** and tell the user the skill requires the Atlassian MCP server to be installed, configured, and authenticated. Do not fall back to any other publishing target.

If more than one site is accessible, note which are available; you will confirm the right one while resolving the project in Step 3.

### 1. Locate the work-items file

If the path is not provided, ask for it. The input is a single `work-items.md` produced by `/plan-work-items`. Read it. Its format is described in [references/work-items-file-format.md](references/work-items-file-format.md).

### 2. Gather the run options

Read these from the arguments and conversation; do not guess defaults the user did not ask for:

- **Target project or board** — `--project <KEY>` (e.g., `ACME`) or `--board <name/URL>`. **Required.** If absent, ask for it in Step 3.
- **Epic** — `--epic <KEY>` (e.g., `ACME-12`) or an epic URL. Optional. When present, every created ticket is parented to this epic.
- **Issue type** — `--type <name>`. Optional; defaults to `Story`.
- **Assignee** — `--assignee <accountId or email>`. Optional; defaults to unassigned.
- **Column** — `--column <name>`. Optional; defaults to the project's initial status (Backlog).

### 3. Resolve the target against Jira

Using the cloud ID from Step 0, resolve everything concretely now so failures surface before any ticket is created:

- **Project (required).** If given a project key, confirm it with `mcp__claude_ai_Atlassian__getVisibleJiraProjects`. If given a board, resolve it to its underlying project (list projects and match; if a board maps to more than one project or is ambiguous, ask the user which project to use). If no project or board was provided, ask for one — do not proceed without a project key.
- **Issue type.** Call `mcp__claude_ai_Atlassian__getJiraProjectIssueTypesMetadata` for the project and confirm the chosen type (default `Story`) exists. If `Story` is not an available type in this project, surface the available types and ask the user to pick one.
- **Epic (optional).** If an epic was named, fetch it with `mcp__claude_ai_Atlassian__getJiraIssue` to confirm it exists, is in the target project, and is an epic. Record its key as the parent for every ticket.
- **Assignee (optional).** If an assignee was named, resolve it to an account ID with `mcp__claude_ai_Atlassian__lookupJiraAccountId`. If unset, leave tickets unassigned.
- **Column (optional).** If a column was named, hold it for Step 8. Resolve the matching status when you transition (Step 8), since transitions are per-issue.

### 4. Validate the format with evidence-based repair

Check the work-items file against the invariants in [references/jira-ticket-template.md](references/jira-ticket-template.md) and [references/work-items-file-format.md](references/work-items-file-format.md):

- **Heading shape.** Every slice heading matches `## <SYM-N> — <title>` with an em-dash separator (already-published headings annotated as `## <SYM-N> (<KEY>) — <title>` are valid too).
- **`Depends on` line.** Literal bold marker `**Depends on.**`, trailing period, `None.` or comma-separated SYMs.
- **Within-file blockers.** Every SYM named in a `Depends on` line resolves to another slice in this file.
- **References block.** Present whenever the slice consumes an HTTP endpoint, event payload, design frame, ADR, coding standard, or other named artifact.
- **No process artifacts.** No links to iteration histories, decision logs, review findings, team findings, facilitation summaries, gap analyses, or anything under an `artifacts/` subfolder that is not a contract or design reference.

When a check fails, attempt evidence-based repair. Pull evidence from the source `work-items.md`, the parent plan referenced in its intro, the feature spec in the same folder, sibling files in the plan folder, and the relevant repo's ADRs / coding standards / docs:

- **Malformed heading** — propose the corrected shape based on the surrounding text. Cite the line number.
- **Missing `Depends on` line** — propose `None.` if no blockers are evident in the slice's prose. Cite the absence.
- **Unknown-SYM `Depends on`** — propose either the correct in-file SYM (if a typo is evident) or `None.`. Cite the SYM list this file actually defines.
- **Missing References bullet for an HTTP-consuming slice** — propose the contract section link from the parent plan's External Interfaces / API Contracts section. Cite the anchor.
- **Missing References bullet for a UI slice** — propose the design frame and document path from the feature spec's Visual Reference table. Cite the spec section.
- **Process-artifact link found** — propose removing the link and (if the slice still needs the context) restating the decision inline with `See plan: D-N`. Cite the include/exclude list.

After validation, report findings in plain language. For each finding name: (1) what is wrong — slice SYM, line reference, failing invariant; (2) the proposed fill — corrected line, new bullet, removed link; (3) the evidence — file path with line number, document section, or named source.

Then give the user three actions: **Continue with fills** (apply the repairs to the source `work-items.md` and proceed), **Correct the fills** (user provides the right values; apply those and proceed), or **Stop** (exit without creating tickets). If validation passes with no findings, proceed to Step 5.

### 5. Show the plan for confirmation

Creating Jira tickets writes to a shared system, so confirm before doing it. Present a summary and wait for an explicit yes:

- **Destination:** the Jira site, the target project (key and name), the epic (if any), the issue type, the assignee (or "unassigned"), and the target column (or "Backlog (default)").
- **The tickets to create:** a table of every slice that does not already carry a `(<KEY>)` annotation.

| SYM | Summary (ticket title) | Depends on |
| --- | --- | --- |
| W-1 | Backend per-list validator generalization | None |
| W-2 | … | W-1 |

State the total count and that reporter will be the authenticated Atlassian user. Do not create anything until the user confirms.

### 6. Create one ticket per slice

Walk the slices in file order (blocker-first, as authored). Skip any slice whose heading already carries a `(<KEY>)` annotation so a re-run resumes cleanly. For each remaining slice, call `mcp__claude_ai_Atlassian__createJiraIssue` with:

- the cloud ID and target **project key**,
- **issue type** = the resolved type (default `Story`),
- **summary** = the slice title (the text after `— ` in the heading),
- **description** = the rendered slice body (everything below the heading: Summary, Description, any notes, References, Tests, Acceptance criteria). Pass it as Markdown; if the create tool requires ADF, convert it. Confirm the expected format against the tool's input schema.
- **parent** = the epic key, when an epic was resolved (Step 3). Use the field the project's create metadata exposes for epic membership; if `parent` is rejected, surface the legacy "Epic Link" field requirement rather than dropping the epic silently.
- **assignee** = the resolved account ID only when the user provided one; otherwise omit it (unassigned).
- **reporter:** never set it. Jira records the authenticated MCP user as reporter.

After each successful create, capture the returned Jira key and rewrite that slice's heading in place from `## <SYM-N> — <title>` to `## <SYM-N> (<KEY>) — <title>` using Edit, so dependencies resolve and re-runs skip it. Report each creation as `created: <SYM-N> -> <KEY>`.

### 7. Link dependencies

Once every slice has a Jira key, build the SYM→key map from the annotated headings and walk each slice's `**Depends on.**` line. For each blocker (skip `None.`):

- **Record it durably in the dependent ticket.** Rewrite the dependent ticket's `Depends on` line in its description from symbolic IDs to the blockers' Jira keys (linked), via `mcp__claude_ai_Atlassian__editJiraIssue`. This survives regardless of native-link support.
- **Create a native link when available.** If the configured Atlassian MCP exposes an issue-link capability, also create an "is blocked by" relationship from the dependent ticket to each blocker. If no issue-link tool is available, say so once in the final report rather than implying native links were made.

Report each as `linked: <SYM-A>(<KEY-A>) blocked_by <SYM-B>(<KEY-B>)`.

### 8. Place tickets in the target column

By default, leave every ticket in the project's initial status (Backlog) and do nothing here.

When the user named a `--column`, transition each created ticket toward the matching status: call `mcp__claude_ai_Atlassian__getTransitionsForJiraIssue` for the ticket, find the transition whose target status matches the requested column, and apply it with `mcp__claude_ai_Atlassian__transitionJiraIssue`. If no transition leads to the requested column for a ticket, do not force it — report that ticket as left in Backlog and name the column it could not reach, so the user can move it by hand.

### 9. Report

Summarize: the project and epic (if any), the issue type used, the assignee (or unassigned), and the column. List every created ticket as `<SYM-N> — <KEY>` with its URL, the count of dependency links made (and whether they are native Jira links or description references), and any slices skipped because they already carried a key. If any step failed, report the error and confirm the source `work-items.md` annotations reflect exactly which tickets were created.
