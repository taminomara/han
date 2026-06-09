---
name: plan-a-feature-to-confluence
description: >
  Builds a feature specification from scratch with plan-a-feature and publishes it to a
  user-specified Confluence location, posting the spec as a parent page and each companion artifact
  (decision log, team findings, technical notes) as a child page beneath it. Use when the user wants
  a new feature planned, designed, scoped, or specified AND posted to a Confluence space or page.
  Requires a configured Atlassian MCP server. Does not plan to local files only — use plan-a-feature.
  Does not publish an arbitrary existing markdown file — use markdown-to-confluence. Does not refine
  or stress-test an existing plan — use iterative-plan-review. Does not document already-built
  features to Confluence — use project-documentation-to-confluence.
arguments: size
argument-hint: "[size: small | medium | large] [feature description] [confluence location: page URL or space + parent] [--mode draft|live (default draft)]"
allowed-tools: Read, Write, Edit, Glob, Grep, Skill, Agent, Bash(find *), Bash(mkdir *), mcp__claude_ai_Atlassian__getAccessibleAtlassianResources
---

# Plan a Feature to Confluence

This skill builds a feature specification with the core `han.core:plan-a-feature`
skill, lets the user review the result, and then publishes it to a Confluence
location that **the user must specify**. It is a thin orchestrator: the planning
work belongs to `han.core:plan-a-feature`, and the publishing work belongs to
`han.atlassian:markdown-to-confluence`. This skill only validates its inputs, runs the
planning skill to a temporary folder, gets the user's review and publish choice,
and hands each file to the publisher.

`han.core:plan-a-feature` produces a small **set** of files — the primary
`feature-specification.md` plus companion artifacts under `artifacts/` (the
decision log, the team findings, and a lazily-created technical-notes file). This
skill publishes the **spec as a parent page** and each companion artifact as a
**child page** beneath it, so the whole plan lands in Confluence as one small
page tree. Because the files cross-reference each other with relative links that
do not resolve once each file is its own Confluence page, the skill publishes in
two passes: first it creates the page tree to learn every page's URL, then it
rewrites the cross-file links to point at the right Confluence pages and updates
each page.

The seven steps below are the whole skill. It does not resolve Confluence pages or
call the Confluence MCP create/update tools itself; `han.atlassian:markdown-to-confluence`
owns all of that.

## Step 1: Validate Inputs

Confirm the skill has everything it needs before spending effort producing a
plan:

1. **Atlassian MCP reachable (hard requirement).** Call
   `mcp__claude_ai_Atlassian__getAccessibleAtlassianResources` to confirm the
   server is connected and retrieve the cloud ID(s). If the tool is not
   available, the call errors, or it returns no accessible resources (typically
   an authentication or configuration problem), **stop immediately**. Tell the
   user this skill requires the Atlassian MCP server to be installed, configured,
   and authenticated, and that they can re-run it once it is connected. Do not
   fall back to a local-only run; for local-only planning, point them at
   `han.core:plan-a-feature`. This preflight runs first so a missing server fails
   before any planning work begins.
2. **A feature to plan.** Confirm the request names a feature, capability, or
   system behavior to specify. This — together with the `size` argument and any
   relevant conversation context — is forwarded to `han.core:plan-a-feature`
   verbatim in Step 2. If the request is too thin to start, let
   `han.core:plan-a-feature` run its own interview; do not pre-empt it here.
3. **A Confluence destination.** Confirm the request provides a target location:
   a **Confluence page URL** (to update that page, or create the spec as a child
   under it), or a **space** (key or name) plus an optional **parent page**. If
   none was provided, ask for one with `AskUserQuestion`, explaining plainly that
   the skill needs an exact destination because it does not search Confluence. Do
   not resolve the page tree here — only confirm a location was given. Carry it
   through to Step 5; `han.atlassian:markdown-to-confluence` resolves it.

## Step 2: Produce the Plan to a Temporary Folder

Invoke the `han.core:plan-a-feature` skill with the **Skill** tool, **forwarding
all provided context** verbatim: the `size` argument (if the user passed
`small`, `medium`, or `large`), the feature description, any known constraints or
entry points, and the relevant conversation context. Do not summarize, trim, or
reinterpret the user's context; pass it through so `han.core:plan-a-feature` runs
exactly as it would on its own — interview, review team, finding resolution, and
project-manager synthesis included — **except** add one explicit instruction: it
must write its output folder under `/tmp/` (for example
`/tmp/<feature-slug>/`) rather than into the repo's docs directory, and it should
not prompt the user to choose or confirm an output location, because this skill
owns that decision. This keeps the working plan out of the repo until the user
decides to publish it.

Let `han.core:plan-a-feature` complete its full process. **Capture the exact
`/tmp/` paths of every file it wrote:**

- `/tmp/<feature-slug>/feature-specification.md` — the primary spec (always written).
- `/tmp/<feature-slug>/artifacts/decision-log.md` — the decision history (always written).
- `/tmp/<feature-slug>/artifacts/team-findings.md` — the review-team findings (always written).
- `/tmp/<feature-slug>/artifacts/feature-technical-notes.md` — load-bearing mechanics. **Lazily created — only present if at least one technical note qualified.** Confirm whether it exists before relying on it.

Proceed to Step 3 once it finishes.

## Step 3: Show the Files for Review

Tell the user the exact `/tmp/` paths of every generated file — the spec and each
companion artifact that was actually written (the technical-notes file only if it
exists) — so they can open and review them before deciding whether to publish.
State plainly that nothing has been published anywhere yet.

## Step 4: Confirm the Publish Choice

Publishing to Confluence puts the content where other people can see it, so
require an explicit choice before posting. Ask with `AskUserQuestion`, restating
the **`/tmp/` file paths** and the **Confluence destination** the user provided,
and making clear that publishing creates **one parent page (the spec) plus one
child page per companion artifact**. Offer three options, listing the draft
option first as the recommended default:

- **"Yes, save them as drafts to edit later (recommended)"** — every page is
  published as an unpublished Confluence draft for the user to review, edit, and
  publish themselves. This is the default. (Publish mode: **draft**.)
- **"Yes, publish them live now"** — the pages go live immediately. (Publish
  mode: **live**.)
- **"No, keep them local only"** — nothing is published.

If the user keeps it local only, **stop**. Report the `/tmp/` folder path and
state clearly that nothing was published to Confluence. Otherwise, record the
chosen publish mode (draft or live) for Step 5. The chosen mode applies to every
page in the tree.

## Step 5: Publish the Page Tree (Pass 1 — create)

Create every page so each one gets a Confluence URL. The links inside the files
still point at local paths in this pass; Step 6 fixes them once the URLs are
known. Publish the spec first so the companion artifacts can be created as its
children. Use the **Skill** tool for every call, and apply the publish mode the
user chose in Step 4 to all of them — state it explicitly so
`han.atlassian:markdown-to-confluence` does not re-ask.

1. **Publish the spec (the parent page).** Invoke `han.atlassian:markdown-to-confluence`,
   forwarding:
   - the **`/tmp/.../feature-specification.md`** path captured in Step 2,
   - the **Confluence destination** the user provided in Step 1 (the page URL, or
     the space plus optional parent page), passed through verbatim,
   - the **publish mode** the user chose in Step 4 (`draft` or `live`), and
   - a suggested **page title** taken from the feature name.

   **Capture the resulting spec page's URL (and its page ID).** This is the parent
   for the artifact pages.

2. **Publish each companion artifact as a child of the spec page.** For each
   artifact file that exists (`decision-log.md`, `team-findings.md`, and
   `feature-technical-notes.md` only if it was created), invoke
   `han.atlassian:markdown-to-confluence` again, forwarding:
   - the artifact's **`/tmp/.../artifacts/<file>.md`** path,
   - the **spec page's URL** from step 1 above as the destination, with the
     intent to **create a new child page under it** (state this explicitly so the
     publisher does not ask whether to update the spec page),
   - the same **publish mode**, and
   - a suggested **page title** that names the artifact under the feature, for
     example `<Feature Name> — Decision Log`, `<Feature Name> — Team Findings`,
     `<Feature Name> — Technical Notes`.

   Publish the artifacts one at a time so each create resolves against the same
   parent. `han.atlassian:markdown-to-confluence` owns location resolution, the
   create call, and Mermaid handling for each file.

**Record the published set:** a map from each `/tmp/` file to the Confluence page
URL it was published to (the spec and every artifact). Step 6 needs this map.

## Step 6: Rewrite Cross-Page Links and Update the Pages (Pass 2 — relink)

The files cross-reference each other with relative links — the spec links to its
artifacts (`([D4](artifacts/decision-log.md#d4-...))`), and each artifact links
back to the spec (`../feature-specification.md`) and sometimes to a sibling
artifact. Those relative paths do not resolve once each file is a separate
Confluence page. Now that every page has a URL (the map from Step 5), rewrite the
links so they point at the right Confluence pages.

1. **Produce a rewritten copy of each file, leaving the `/tmp/` originals
   intact.** Write the rewritten copies to a dedicated subfolder (for example
   `/tmp/<feature-slug>/.confluence-publish/`) so the originals the user reviewed
   in Step 3 keep their working local links. For each published file, read it and
   rewrite **only** the cross-file links:
   - Resolve each relative markdown link target against the directory of the file
     being rewritten. If it resolves to **another file in the published set**,
     replace the target with that file's Confluence page URL from the Step 5 map.
   - **Drop the `#fragment`** (the `#d4-...`, `#t3-...`, or section anchor).
     Confluence Cloud generates its own heading anchors with a scheme that does
     not match these slugs, so a rewritten link lands the reader at the **top of
     the correct page**, not the exact heading. Keep the link text unchanged.
   - Leave every other link, and all other content, exactly as written. Do not
     touch links that point outside the published set (external URLs, code
     references).

2. **Update each page from its rewritten copy.** For every page whose rewritten
   copy changed (the spec always changes; artifacts change when they link back to
   the spec or a sibling), invoke `han.atlassian:markdown-to-confluence` again,
   forwarding:
   - the **rewritten copy's path**,
   - that page's **own Confluence URL** from the Step 5 map as the destination,
     with the intent to **update that existing page** (state this explicitly so
     the publisher updates rather than creating a child),
   - the same **publish mode**, and
   - the page's existing **title** (do not rename).

   Skip the update for any file whose rewrite produced no changes.

**Mermaid still posts as source.** As `han.atlassian:markdown-to-confluence`
reports, Mermaid diagrams publish as fenced code blocks, not rendered diagrams,
unless the space has a Mermaid macro. This is unrelated to the link rewrite and
is not something to silently fix.

Relay the result to the user: the spec parent page's URL, every artifact child
page's URL, whether the tree went live or was saved as drafts, that cross-page
links now point at the right Confluence pages but land at the top of the target
page (the heading-level anchors could not be preserved), and the Mermaid note. If
any create or update fails, report which file failed and its error, note which
pages were already created or updated, and confirm the `/tmp/` originals are
unchanged and intact.

## Step 7: Verification

1. **Inputs validated:** the Atlassian server was reachable, a feature to plan
   was present, and a Confluence location was provided — or the skill stopped
   before doing any work.
2. **Plan produced to /tmp:** `han.core:plan-a-feature` ran with the full
   forwarded context and wrote its files under a `/tmp/` folder whose paths were
   captured, including whether the lazily-created technical-notes file exists.
3. **User reviewed:** the `/tmp/` paths were shown to the user before any publish.
4. **Explicit choice obtained:** the user chose draft, live, or local-only.
5. **Tree created (Pass 1):** when the user chose to publish, the spec was posted
   as the parent page and each existing companion artifact as a child page in the
   chosen mode, and every page's URL was captured into the Step 5 map.
6. **Links rewritten (Pass 2):** cross-file links were rewritten to the published
   pages' URLs (fragments dropped), the changed pages were updated from rewritten
   copies, and the `/tmp/` originals were left intact.
7. **Reported:** every page URL was relayed with the publish mode, the
   land-at-page-top link caveat, and the Mermaid note; when the user declined,
   only the `/tmp/` files exist.
