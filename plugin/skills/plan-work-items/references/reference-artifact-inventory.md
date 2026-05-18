# Reference artifact inventory

Before drafting slices, list every artifact an implementer of those slices will need to reach for. Pull from the same folder as the plan, the plan's links, and the cross-repo rule in `.claude/rules/cross-repository-work.md`.

## Include (link these from slices and/or the preamble)

- **HTTP API contract files** (e.g., `api-contracts.md`) and the specific endpoint sections that slices in this breakdown produce or consume.
- **Event payload contract files** and the specific event sections.
- **Feature specification** (`feature-specification.md`) — sections that define behavior the slice must realize.
- **Design assets** — Pencil document file paths plus specific frame IDs (when the plan or a sibling doc maps frames to UI), screenshot files, Figma URLs, mockup PDFs.
- **Screenshots from `ui-designs/`**, when present. Inventory every PNG in that folder and map each one to the slices that realize the behavior it depicts. Use the feature spec as the mapping source: the spec's "Visual Reference" table (or equivalent) lists every screenshot, and the spec's inline `![…](ui-designs/…png)` embeds appear next to the prose that describes the depicted state — that prose tells you which slice owns the screenshot. A single slice may need multiple screenshots when it implements multiple states (e.g., a list-page slice may embed both the manager and viewer states); a single screenshot may apply to multiple slices when distinct slices share a screen — in that case the file is copied once into each owning slice's `.github/issue-assets/<SYM-N>/` folder by the upload script. The planning-repo location is the *source*; it is never the URL embedded in the issue. See [screenshot-embed-rules.md](screenshot-embed-rules.md) for the full URL rule.
- **Schema/migration references** in the target repo when a slice depends on a not-yet-shipped schema.
- **ADRs** (`docs/adr/...` in target repos), coding standards, and feature documentation that constrain the slice's implementation.
- **Runbook skeletons or observability notes** only when a slice's acceptance criteria require them.

## Exclude (these never belong in tickets)

- Iteration histories (`*-iteration-history.md`, `.evidence-roundN.md`, `.junior-developer-roundN.md`, `.adversarial-roundN.md`, etc.)
- Decision logs (`decision-log.md`, `implementation-decision-log.md`)
- Review findings (`review-findings.md`, `implementation-review-findings.md`)
- Team findings, facilitation summaries, gap analyses, security/UX round notes
- Anything under an `artifacts/` subfolder of the plan **unless** it is a contract or design reference (e.g., a `design-frame-verification.md` may be cited; a `team-findings.md` may not).

These exist to record how the plan was reached, not what the implementer needs to build. Plan-level decisions that survive into the slice are restated inline in the slice description, with `See plan: D-N` as the breadcrumb — never a link to the decision log itself.

## Where to cite each artifact

- When a single artifact applies to **many slices in one repo**, cite it once in that repo's preamble (under "Shared reference artifacts" or equivalent) and let slices reference the section by anchor.
- When an artifact applies to a **single slice**, cite it inline in that slice's `**References.**` block.

## Missing-artifact handling

If an expected artifact is missing — for example, the plan touches an HTTP boundary but no contract file exists — surface it to the user **before drafting slices**. Slices that consume an undefined contract are not draftable.
