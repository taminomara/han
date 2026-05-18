---
name: implementation-plan-to-issues
description: >
  Break an implementation plan into independently-grabbable issues. Use when
  user wants to convert a plan to issues, create implementation tickets, or
  break down the plan into work items. Do not use when there isn't an
  implementation plan yet, or when the plan isn't yet trusted. Pair with
  `/plan-implementation` or `/iterative-plan-review` upstream to create or
  harden the plan before breaking it into issues.
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(find *), Bash(gh *)
---

## Pre-requisites

- gh CLI: !`which gh`

If `gh CLI` is not found and the user has provided a `github.com` URL as the plan source, inform the user that the gh CLI must be installed and configured to fetch issue content, and ask them to provide the plan as a file path instead. If the plan is a file path, proceed regardless of gh CLI availability.

## Project Context

- CLAUDE.md: !`find . -maxdepth 1 -name "CLAUDE.md" -type f`
- project-discovery.md: !`find . -maxdepth 3 -name "project-discovery.md" -type f`
- feature-implementation-plan.md: !`find . -maxdepth 5 -name "feature-implementation-plan.md" -type f`

# Implementation Plan to Issues

Break an implementation plan into vertical slices (tracer bullets), write a work-item file per repo.

This skill (Steps 1–7) largely coordinates: locating the plan, getting confirmation, writing the work-items file. Step 4 is where the judgement comes into play, in dividing up the plan.

## Rules

- Do NOT close, edit, or comment on the parent implementation plan issue.
- Each slice lives in exactly one repo. Cross-repo integration is documented in the preamble integration table, never as a native blocker.
- Native `blocked_by` relationships are **within-repo only**. Cross-repo dependencies stay in the preamble integration table.
- Every slice issue body MUST link the reference artifacts an implementer needs: API/event contracts, design frames, schema docs, runbooks, ADRs, coding standards. Issues that consume an HTTP endpoint or event payload MUST link the contract section that defines it.
- UI slices, when the plan folder has a `ui-designs/` subfolder, MUST embed the relevant screenshots inline using same-target-repo raw URLs. See [references/screenshot-embed-rules.md](references/screenshot-embed-rules.md).
- NEVER include process artifacts in issue bodies or the work-items preamble. Excluded categories: iteration histories, decision logs, review findings, team findings, facilitation summaries, gap analyses, and anything under an `artifacts/` subfolder of the plan that is not a contract or design reference. Restate plan-level decisions inline in the slice with `See plan: D-N` as the breadcrumb. Full include/exclude list in [references/reference-artifact-inventory.md](references/reference-artifact-inventory.md).

## Process

### 1. Locate the implementation plan

If the plan is not provided, check to see if there are any existing features with plans, e.g., `docs/features/<feature-name>/feature-implementation-plan.md`. If there is only one, use that as the plan. If there are multiple, use the most recently-updated file as the plan. If there are none, ask for the plan file path or an issue URL. If the plan is a file and not already in context, read it. If the plan is a `github.com` URL, use the `gh` CLI tool to fetch the issue. Otherwise, try to use WebFetch to retrieve the issue body and all comments. If the issue body references a file, read that file too. The plan content is the union of all these sources. If WebFetch fails, e.g., due to authentication errors, ask the user to paste the content directly.

### 2. Explore the codebase when needed

If the plan references existing code or repo boundaries that aren't in your context, explore the affected repos. Skip exploration if the plan is self-contained and the boundaries are already clear.

### 3. Inventory reference artifacts

Before drafting slices, list every artifact an implementer of those slices will need. See [references/reference-artifact-inventory.md](references/reference-artifact-inventory.md) for the include list, exclude list, and screenshot-to-slice mapping rules.

If an expected artifact is missing (e.g., the plan touches an HTTP boundary but no contract file exists), surface it to the user before Step 4. Slices that consume an undefined contract are not draftable.

### 4. Draft vertical slices

Launch `project-manager` (`subagent_type: "han:project-manager"`, `model: "sonnet"`) with:

- The full plan content from Step 1.
- The artifact inventory from Step 3.
- The Rules section of this skill verbatim.
- A directive to draft vertical slices: each slice is a narrow but complete path through the appropriate layers (schema, API, UI, tests) for a single repo, demoable or verifiable on its own. Classify each slice as **HITL** (requires human interaction: architectural decision, design review) or **AFK** (can be implemented and merged without sync). Prefer AFK over HITL. Prefer many thin slices over few thick ones.
- A directive to return the proposed slice breakdown as a numbered list. Do not write any files.

Return the project-manager's output verbatim. Proceed to Step 5.

### 5. Assign symbolic IDs and titles

Give each slice a per-repo symbolic ID: a short prefix + sequential number within that file.

Propose a 1–3 letter prefix based on the repo name and surface it to the user in Step 6 for confirmation before writing files.

Issue title format: `<SYM-N> — <short descriptive name>` (em-dash separator).

### 6. Show the breakdown and get confirmation

Present a numbered list. For each slice show:

- **Title**: `<SYM-N> — <short descriptive name>`
- **Type**: HITL or AFK
- **Depends on**: other slices in the **same repo** that must complete first, or `None`
- **Work items addressed**: user stories or work-unit numbers from the parent plan that this slice satisfies
- **Reference artifacts**: contract sections, design frame IDs, ADRs, and other references from Step 3
- **Screenshots**: when `ui-designs/` exists and the slice is UI-bearing, list the screenshot filenames that will be embedded in the issue body

Wait for the user's confirmation before writing files or creating issues.

### 7. Write work-item files

**Plan is a file:** write one `<repo-name>.work-items.md` file per affected repo, in the same folder as the plan file. File layout (title line, intro, preamble structure) is specified in [references/work-items-file-format.md](references/work-items-file-format.md). Slice template is [references/issue-template.md](references/issue-template.md).
