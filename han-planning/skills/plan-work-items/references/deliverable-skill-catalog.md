# Deliverable-skill catalog

This map is used to choose each work item's **suggested implementation** and **suggested review** fields.

## How to classify one work item

Each work item consists of two parts: implementation and review. For each part, derive an appropriate skill, sub-agent, or action that can perform it. Additionally, classify part as `AFK` (can be completed without human input) or `HITL` (requires human participation). This will inform whether the part can run in a background sub-agent.

1. **Classify the deliverable nature and pick the implementation and review skill** from Table 1.
2. **Apply operator overrides** (see "Overrides").
3. **Handle the non-han and not-installed cases** (see those sections).
4. **Record the two fields** on the item. Separately set `Requires pre-work decisions` (`yes` when the item needs a human decision, an architectural decision or a design gate, before work can start).

## Table 1: deliverable nature to implementation and review

| Deliverable nature | Suggested implementation | Suggested review |
|---|---|---|
| New or changed testable code | `han-coding:tdd`, AFK | `han-coding:code-review`, AFK |
| Behavior-preserving restructuring of already-tested code | `han-coding:refactor`, HITL | `han-coding:code-review`, AFK |
| A new Claude Code skill | `han-plugin-builder:skill-builder`, HITL | `han-plugin-builder:guidance`, AFK |
| A new Claude Code agent | `han-plugin-builder:agent-builder`, HITL | `han-plugin-builder:guidance`, AFK |
| Other work related to Claude Code plugins | `han-plugin-builder:guidance`, AFK | `han-plugin-builder:guidance`, AFK |
| Authoring feature or system documentation | `han-core:project-documentation`, AFK | `han-core:information-architect` agent, AFK |
| Editing feature or system documentation | `han-core:project-documentation`, AFK | `han-core:content-auditor` agent, AFK |
| An architectural decision record | `han-core:architectural-decision-record`, HITL | manual read, HITL |
| A coding standard | `han-coding:coding-standard`, HITL | manual read, HITL |
| A runbook | `han-core:runbook`, HITL | manual read, HITL |
| No han skill fits | scan installed skills (see "Non-han skills"); if none fits, bare `none, HITL` |

### `han-coding:tdd`

Use `tdd` only for deliverables with tests to lead their development (code, or anything test-verifiable). Never default a non-testable deliverable (documentation, a vendoring step, an ADR) to `tdd`. When the nature is ambiguous, pick the best fit and flag it low-confidence in the breakdown rather than defaulting to `tdd`.

### Dual-nature items

A work item whose deliverable spans two natures (for example, code plus its runbook) is split into separate vertical-slice items, one per deliverable and skill. When it cannot be cleanly split, record the dominant skill and flag the uncovered nature in the breakdown rather than dropping it silently.

### For more complex scenarios

Table 1 lists common cases, but doesn't define strict pairings between implementation and review skills. If an item is best covered by a combination not listed in the table, you can use it, or add additional instructions for implementation and review stages.

### Non-han skills

When no han skill in Table 1 fits an item's nature, scan the installed skills. If a non-han skill plausibly fits, surface it in the breakdown as a **low-confidence suggestion**, never an auto-assignment: the producer cannot reliably tell whether an arbitrary installed skill is code-producing or interactive.

A non-han skill's `AFK`/`HITL` are **declared by the operator**, defaulting to `HITL` when undeclared. Never set an unconfirmed non-han skill to `AFK`.

### Installed-skill detection

User can be missing some skills or agents listed in table 1. Before committing to one, verify that it is installed. If not, fall back to an installed best-fit, and record uninstalled alternative next to it: ``none, HITL (or install and use `han-plugin-builder:skill-builder`, HITL)``.

## Overrides

The operator can override the implementation skill, the review, and a non-han skill's declared autonomy for a named item, two ways:

- **Invocation instruction.** A natural-language instruction in the invocation (for example, "use `skill-builder` for the new-skill item", or "my `deploy-notes` skill has an autonomous build"). Interpret it and apply.
- **Pre-written marker.** A recognizable single-line bracketed annotation left in the source plan near the relevant section, carrying a skill and an optional review and non-han autonomy declaration (for example, `[implementation: skill-builder; review: manual read]`). Read it read-only; never modify the source plan.

On an override:

- Re-derive the item's implementation and review classification: from Table 1 for a han skill, or from the operator's declaration for a non-han skill (defaulting to `HITL`). A required pre-work decision the item already needs is unaffected by a skill override.
- **Flag a mismatch** when the override's skill does not match the item's nature (for example, `tdd` on a non-testable deliverable, or any skill on a deliverable of a different kind). Honor it, because the operator has the final say, but flag it in the breakdown.
- **An override naming an uninstalled skill** is treated like a not-installed best-fit: the item becomes bare and the override is kept as a recommendation, a distinct outcome from an honored mismatch.
- **Report how each override resolved** (applied to which item, unmatched, or ambiguous across items). Never drop an override silently.
