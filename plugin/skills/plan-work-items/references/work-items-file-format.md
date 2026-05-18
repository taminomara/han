# Work-items file format

One file per affected repo, in the same folder as the plan, named `<repo-name>.work-items.md` (e.g., `my-repo.work-items.md`).

## Title and intro

```
# <repo-name> Work Items — <feature-name>
```

Followed by one intro paragraph linking the parent plan and noting:

> Issues are numbered `<SYM>-N` for cross-reference only; actual issue numbers come from the issue tracker on creation. Dependencies listed are within this repo only.

Link the parent plan once here. Do not relink it inside every slice.

## Preamble (only when the plan touches more than one repo)

In order:

1. **Prerequisites** *(required when this repo depends on external PRs or other-repo deliverables)* — external PRs or cross-repo deliverables whose state must be verified before picking up any slice in this file.
2. **Cross-repo integration points** *(required)* — a table of what this repo emits/exposes, which other-repo component consumes it, and the downstream slice that does the consuming. Immediately after the table, include a one-paragraph **Precedence rule**:
   > If a per-ticket `Depends on` line conflicts with this table, this table wins for upstream-vs-downstream ownership. Per-ticket `Depends on` is a within-repo ordering hint only.
3. **Shared reference artifacts** *(required when any artifact applies to more than one slice in this file)* — API response envelopes, event payload shapes, shared-stylesheet notices, design-frame-to-component mappings (Pencil document path + frame IDs), ADR pointers. Each entry is a relative link plus the anchor an implementer should jump to.

## Slices

Every slice uses the template at [issue-template.md](issue-template.md).

The preamble (Prerequisites, Cross-repo integration points + Precedence rule, Shared reference artifacts) stays in the work-items file and is **not** duplicated into each issue body. Each issue body still carries its own `**References.**` block — slice references can point into the preamble's shared-artifacts entries by anchor when the artifact is shared, but the bullets in the slice itself are what the implementer reads on the issue.
