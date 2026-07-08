# Durable-record protocol

The driver's run-artifact area lives inside the plan folder — the directory that holds
the work-items file. Derive it from that directory: `<plan-folder>/.implement-work-items/`,
where `<plan-folder>` is `dirname` of the normalized work-items path. The area holds one
committed record, `progress.md`, plus the per-round review records under `reviews/`. The
whole area is tracked and travels with the run's branch.

## The committed record

`progress.md` is a labeled config block, then a `Log:` block, then one labeled block per
class of accumulated durable state. Every block is append-only and parsed independently.

```
# implement-work-items progress

Run config:

- gate: warning
- fix-cap: 3
- model: inherit
- base: origin/main
- branch: feat/checkout
- verify: npm test; npm run lint
- work items: docs/plans/checkout/work-items.md

Log:

- start-of-item: W-1
- done: W-1
- start-of-item: W-2
- no-commit-done: W-2
- start-of-item: W-3
- skip: W-3

Corrections:

- W-1: prefer explicit return types on exported functions

Coherence approvals:

- W-4: src/shared/config.ts

Below-threshold dispositions:

- W-1: fixed SUG-2 (naming); left SUG-3 (comment style)
```

- **Config block.** The run's effective configuration and the normalized work-items path.
  Read on resume to recognize the run and restore its config.
- **`Log:` block.** One line per lifecycle entry, grammar `- <token>: <W-N>`, with
  `<token>` exactly one of `start-of-item`, `done`, `no-commit-done`, or `skip`. This
  grammar is a fixed contract the reader parses; it is byte-for-byte and never changes.
  A `start-of-item` always precedes its item's terminal entry: `done` for an output item
  that cleared, `no-commit-done` for a cleared no-output `audit`, or `skip` for a skipped
  item. Last terminal entry wins per item.
- **`Corrections:` block.** The general style corrections carried forward into later builds.
- **`Coherence approvals:` block.** The sibling-file paths approved as intended.
- **`Below-threshold dispositions:` block.** The per-item fixed/left records at decision time.

Each block below the `Log:` is append-only and parsed on its own label, so appending to one
never perturbs the Log reconstruction.

## Commit trailers

Four trailers carry the durable references. Each is a git commit trailer matched **by exact
key**, never as a message substring, so an ordinary commit that mentions the run is never
misread.

- `Implement-Work-Items-Item: <W-N>` — on **code commits only**. Marks the item a commit
  belongs to; the resume scan resolves a `done` entry's commit positionally through it.
- `Implement-Work-Items-Run: <normalized work-items path>` — on **bookkeeping commits only**,
  never on a code commit and never carrying the item trailer. This is the run identity the
  resume scan greps. The path is the work-items file's repo-root-relative path with a leading
  `./` stripped, `..` resolved, and any trailing slash dropped.
- `Implement-Work-Items-Fixup: <W-N>` — on a **review-addressing fix commit**, marking it
  collapsible into the item's initial commit. This is a trailer, not native `fixup!`.
- `Implement-Work-Items-Baseline: <W-N>` — on the item's **start-of-item commit**, marking it
  as the item's `scope-baseline` so the baseline is recoverable on resume. Distinct from the
  item trailer.

## Commit model

- Every build and every fix iteration is committed. Bookkeeping commits (the record and the
  review records) stay separate from code commits and are never mixed into one commit.
- The terminal `Log:` entry (`done`, `no-commit-done`, or `skip`) is the last write per item,
  committed after the item's code commit(s). The committed record is append-only.
- All commits are retained: the driver never rewrites history. The `Implement-Work-Items-Fixup`
  and `Implement-Work-Items-Run` trailers exist only so the operator can later collapse or
  filter commits; the driver performs no autosquash, strip, or rewrite itself.

## Exclusion (path-based)

The artifact area is tracked bookkeeping. It must never enter an item's code commit or count
as a scope finding. Exclusion is **by path**: because the area is nested under the plan folder
rather than at the repo root, every exclusion matches the `.implement-work-items/` directory
**at any depth**, not a root-anchored prefix. Verify all four sites hold this:

1. **SKILL.md Step 3.4 stage-by-path** — stages the item's changed files by path, never the
   driver's `.implement-work-items/` artifacts.
2. **`review-verdict-contract.md` scope diff** — the changed-file computation excludes
   `.implement-work-items/` at any depth.
3. **`human-review-capture.md` reviewer pointer** — points the human at the item's change
   since `scope-baseline`, not the artifact area.
4. **`no-output-completion.md` clean-tree assertion** — allows only `.implement-work-items/`,
   so a bookkeeping write never reads as stray output.

## Integrity

On resume the record is untrusted until each entry is positively classified as safe; any
state not so classified is **surfaced and asked**, never acted on (default-deny). The
committed terminal entry is the sole authority for completion — commit presence never implies
an item cleared.

| Entry / state | Positively safe when | Otherwise |
|---|---|---|
| output item's `done` entry | its item-trailer commit still resolves in the branch history | surface the unresolved reference with its plain-language cause and ask; never accept `done` on the entry alone |
| `no-commit-done` entry | present, well-formed, and the tree is clean since the item's baseline (only `.implement-work-items/` allowed) | valid as-is — it carries no commit by design, so this is not a missing-commit divergence |
| any other disagreement | — | a missing branch or commits, an edited or renumbered file, a foreign-run record, a partially-stripped record: examples of the default-deny rule, not a closed list — surface and ask |
