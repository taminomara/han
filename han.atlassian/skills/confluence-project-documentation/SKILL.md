---
name: confluence-project-documentation
description: >
  Creates or updates project documentation for a feature, system, or component
  and publishes it to a user-specified Confluence location. Runs the core
  project-documentation skill to produce the documentation locally, then, after
  explicit confirmation, publishes it to Confluence through the Atlassian MCP
  server. Use when the user wants feature or system documentation written to
  Confluence, posted to a Confluence space or page, or synced to a Confluence
  location. Requires a configured Atlassian MCP server and requires the user to
  provide the target Confluence location — it does not search Confluence for the
  right place. Does not document to local files only — use project-documentation
  for that. Does not create architectural decision records — use
  architectural-decision-record. Does not create coding standards — use
  coding-standard. Does not produce runbooks — use runbook.
argument-hint: [feature-name or doc-path] [confluence location: page URL or space + parent]
allowed-tools: Read, Glob, Grep, Skill, Agent, Bash(date *), Bash(git config *), Bash(whoami), Bash(mkdir *), Bash(find *), mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian__getConfluenceSpaces, mcp__claude_ai_Atlassian__getConfluencePage, mcp__claude_ai_Atlassian__getPagesInConfluenceSpace, mcp__claude_ai_Atlassian__getConfluencePageDescendants, mcp__claude_ai_Atlassian__createConfluencePage, mcp__claude_ai_Atlassian__updateConfluencePage
---

# Confluence Project Documentation

This skill produces project documentation with the core `/project-documentation`
skill and then publishes it to a Confluence location that **the user must
specify**. It is a thin wrapper: the documentation work belongs to
`/project-documentation`; this skill adds the Atlassian MCP requirement, the
location requirement, and a confirmed publish step.

## Step 0: Atlassian MCP Preflight (hard requirement)

This skill cannot run without a configured and connected Atlassian MCP server.

Confirm the server is reachable by calling
`mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to retrieve the
cloud ID(s). If the tool is not available, the call errors, or it returns no
accessible resources (typically an authentication or configuration problem),
**stop immediately**. Tell the user this skill requires the Atlassian MCP server
to be installed, configured, and authenticated, and that they can re-run the
skill once it is connected. Do not fall back to a local-only run; for local-only
documentation, point them at `/project-documentation`.

If more than one cloud / site is accessible, note which sites are available;
you will confirm the correct one while resolving the location in Step 1.

## Step 1: Resolve the Target Confluence Location (required)

**This skill does not search Confluence for the right place.** A typical
Confluence instance is large and full of duplicate or similarly-named pages, so
guessing the destination is unreliable. The user must name the exact location.

1. **Find a location in the request.** Check the arguments and conversation for
   either of:
   - a **Confluence page URL** (to update that page, or to create a child page
     under it), or
   - a **space** (key or name) plus an optional **parent page** (title, ID, or
     URL).
2. **If no location was provided, ask for one.** Use `AskUserQuestion` to
   request it, and explain plainly that the skill needs an exact destination
   because it does not search Confluence. Offer both accepted forms (a page URL,
   or a space plus parent page). This is required: do not proceed without a
   location.
3. **Resolve the location concretely now, so failures surface early.** Use the
   cloud ID from Step 0 for every call.
   - **From a page URL:** extract the page ID from the `/pages/<id>/` segment and
     call `mcp__claude_ai_Atlassian__getConfluencePage` to confirm it exists and
     to read its space and title. Then determine the intent: **update that page**,
     or **create a new child page under it**. If the user did not already say,
     ask with `AskUserQuestion`.
   - **From a space (+ parent):** call
     `mcp__claude_ai_Atlassian__getConfluenceSpaces` to resolve the space ID from
     the key or name. If a parent page was named, find it with
     `mcp__claude_ai_Atlassian__getPagesInConfluenceSpace` or
     `mcp__claude_ai_Atlassian__getConfluencePageDescendants` (or by page ID/URL)
     to get the parent page ID. With no parent, the new page is created at the
     space root.
4. **Record the resolved target:** cloud ID, space (ID + human name), parent
   page ID (if any), existing page ID (if updating), the **mode**
   (`create` a new page, or `update` an existing one), and the intended page
   **title**. If updating, default the title to the existing page's title unless
   the user asked to rename it.

## Step 2: Produce the Documentation Locally

Invoke the `/project-documentation` skill with the **Skill** tool, **forwarding
all provided context** verbatim: the feature name or document path argument, the
scope, any known entry points, and the relevant conversation context. Do not
summarize, trim, or reinterpret the user's context; pass it through so
`/project-documentation` runs exactly as it would on its own.

Let `/project-documentation` complete its full process (codebase exploration,
writing or updating the doc, content audit, information-architecture review, and
verification). It writes or updates a local markdown file under the project's
docs directory; **capture that file's path**. That markdown file is the source
content for Confluence. Proceed immediately to Step 3 once it finishes.

## Step 3: Confirm Publication to the Specified Location

Publishing to Confluence puts the content where other people can see it, so
require explicit confirmation before posting.

Present a clear summary and ask with `AskUserQuestion`:

- the **local doc path** produced in Step 2,
- the **destination**: the Confluence site, the space (human name), the parent
  page (if any), and the exact action — *create a new page titled "X" under
  "Parent"*, or *update existing page "Y"* with its URL,
- the question: **"Publish this documentation to that Confluence location?"**
  with options "Yes, publish to Confluence" and "No, keep it local only".

If the user declines, stop. Report the local doc path and state clearly that
nothing was published to Confluence.

## Step 4: Publish to Confluence

Read the markdown file from Step 2 and publish it with the Atlassian MCP server.
The Confluence MCP tools accept Markdown directly via `contentFormat: "markdown"`,
so post the document body as-is — no manual conversion to storage/XHTML is
needed.

- **Create mode:** call `mcp__claude_ai_Atlassian__createConfluencePage` with the
  cloud ID, space ID, `title`, the markdown `body`, `contentFormat: "markdown"`,
  and the parent page ID when one was resolved.
- **Update mode:** call `mcp__claude_ai_Atlassian__getConfluencePage` first to
  read the current page (for its version and existing content), then call
  `mcp__claude_ai_Atlassian__updateConfluencePage` with the cloud ID, page ID,
  `title`, the markdown `body`, and `contentFormat: "markdown"`.

**Diagram note:** `/project-documentation` emits Mermaid diagrams in fenced
```mermaid``` code blocks. Confluence does not render Mermaid natively without a
Mermaid macro, so these blocks publish as code, not rendered diagrams. Leave them
intact — do not silently strip them — and tell the user the diagrams posted as
Mermaid source, in case their space has a macro that renders them or they want to
convert them by hand.

On success, report the created or updated page's URL. On failure, report the
error and confirm the local markdown doc from Step 2 is unchanged and intact.

## Step 5: Verification

1. **MCP preflight passed:** the Atlassian server was reachable, or the skill
   stopped before doing any work.
2. **Location was user-specified:** the destination came from the user, never
   from an automated Confluence search.
3. **Local doc produced:** `/project-documentation` ran with the full forwarded
   context and wrote or updated a local markdown file.
4. **Explicit confirmation obtained:** the user approved the specific destination
   before anything was published.
5. **Publish reported:** the page was created or updated and its URL was returned,
   or the user declined and only the local doc exists.
