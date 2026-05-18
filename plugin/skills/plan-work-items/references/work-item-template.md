# Slice issue template

Each slice in a `<repo-name>.work-items.md` file uses this template. Required fields appear in the order shown. The `**References.**` block is required whenever the slice consumes any artifact identified in Step 3 of the skill — omit it only when no external artifact applies. Additional `**Bold paragraph.**` context blocks are allowed between required fields when a slice needs them — common ones: `**Note on scope boundary with <other effort>.**` for ticket-boundary clarifications, `**Note on <subsystem> capability.**` for SDK or platform caveats that affect acceptance.

```
## <SYM-N> — <short descriptive name>

**Summary.** One paragraph describing what this slice delivers. Include a plan reference inline (e.g., `See plan: [D-6](feature-implementation-plan.md#d-6-...)` or `See plan: D-3, D-7, and Work Unit 2`). The plan reference replaces a standalone "Work items addressed" field — do not add one.

**Description.**
1. Numbered steps describing the full behavior to build.
2. Reference implementation details by file path where helpful (`db/ent/schema/jot.go`), but do not prescribe implementation code.
3. Duplicate content from the parent plan into this description when clarity requires it.

*(Insert additional `**Bold paragraph.**` blocks here when needed — e.g., `**Note on scope boundary.**`.)*

**Screenshots.** *(Required for UI-bearing slices when the plan folder contains a `ui-designs/` subfolder. Embed each screenshot inline using a same-target-repo raw URL of the form `https://github.com/<organization>/<target-repo>/raw/<branch>/.github/issue-assets/<SYM-N>/<file>.png`. Cross-repo URLs are forbidden — the automated implementation tooling cannot resolve them. Wrap each embed in a link to the same URL so readers can open the full-size image in a new tab. One image per bullet, with a short caption naming the depicted state. Omit the entire block when the slice has no UI surface or no `ui-designs/` folder exists.)*

- *<state-or-scenario name>* — `[![<alt text>](https://github.com/<organization>/<target-repo>/raw/<branch>/.github/issue-assets/<SYM-N>/<file>.png)](https://github.com/<organization>/<target-repo>/raw/<branch>/.github/issue-assets/<SYM-N>/<file>.png)`

**References.**
- **API contract** — `[<file>#<anchor>](<relative-path>)` (e.g., `[api-contracts.md#post-v1-parent_kind-id-comments-create](api-contracts.md#post-v1parent_kindidcomments--create)`). Required when the slice produces or consumes an HTTP endpoint.
- **Event contract** — `[<file>#<event-section>](<relative-path>)`. Required when the slice produces or consumes an event payload.
- **Design (Pencil)** — `<pen-file-path>`, frames `<frameId>` (purpose), `<frameId>` (purpose). Required for UI slices.
- **Spec section** — `[feature-specification.md#<anchor>](feature-specification.md#<anchor>)` for the behavior this slice realizes.
- **ADR / standard / repo doc** — link any architectural decision, coding standard, or feature doc the implementer must honor.
- Omit any bullet that does not apply. Do not link iteration histories, decision logs, review findings, team findings, facilitation summaries, or any other process artifact.

**Tests.**
- Bullet list of tests required for the behavior above. Be concrete: name the test type (unit, integration, migration, visual, etc.) and the assertion.

**Acceptance criteria.**
- [ ] Criterion 1
- [ ] Criterion 2

**Depends on.** `<SYM-N>` (within this repo), comma-separated for multiple, or `None.`
```

## Format invariants the scripts depend on

- Heading line begins with `## ` followed by `<SYM-N>` (uppercase letters, dash, digits), then ` — ` (em-dash with surrounding spaces), then the title.
- After issue creation, the heading is rewritten in place to `## <SYM-N> (#NNN) — <title>`. The `(#NNN)` annotation is how `link-blockers.sh` resolves symbolic IDs to GitHub issue numbers, and how `create-issues.sh` knows to skip already-created slices on re-run.
- A slice body ends at the next `## ` heading or end of file.
- Screenshot URLs use the exact path scheme `.github/issue-assets/<SYM-N>/<file>.png`. The upload script extracts this path verbatim from the work-items file.
- The `**Depends on.**` line uses the literal bold marker, comma-separates blockers, and ends with `.` (the trailing period is part of the format, not a sentence terminator).
