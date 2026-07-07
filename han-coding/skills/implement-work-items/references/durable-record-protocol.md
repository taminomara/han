# Durable-record protocol

The driver records per-item progress as a committed ledger at
`.implement-work-items/progress.md` that travels with the run's branch.

## Protocol

`progress.md` is committed after every change: each entry is appended and committed as
its own bookkeeping commit.

- **Run trailer.** Every ledger commit carries `Implement-Work-Items-Run: <normalized
  work-items path>` — the work-items file's repo-root-relative path with a leading `./`
  stripped, `..` resolved, and any trailing slash dropped. This is the run identity the
  resume scan greps.
- **Item trailer.** Each item's own code commit carries `Implement-Work-Items-Item: <W-N>`.
- Both are git commit trailers, matched **exactly** by key, never as a message
  substring, so an ordinary commit that mentions the run is never misread.
- A done entry stores no hash: it references its code commit **positionally** at report
  time, via the item-id trailer within the item's start-of-item-to-done range.
- Entry fields stay minimal — a no-commit-done entry carries no `Type` (read from the
  work-items file on resume), a skip carries no dependency snapshot (the graph is
  re-derived on resume), and nothing stores a durable fix-counter, body-hash, or
  pre-work decision (all re-established within the session).

## Format

A `progress.md` is a labeled opening block followed by one line per ledger entry:

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
```

The opening block holds the run's effective configuration and the normalized
work-items path; the driver reads it on resume to recognize the run and restore its
config. Each entry is a single line following the grammar `- <token>: <W-N>`, with
`<token>` one of `start-of-item`, `done`, `no-commit-done`, or `skip` — the contract
the resume scan reconstructs each item's state from. A `start-of-item` always precedes
its item's terminal entry: `done` for an output item that cleared, `no-commit-done` for
a cleared no-output `audit`, or `skip` for a skipped item.

## Integrity

On resume the record is untrusted until each entry is positively classified as safe;
any state not so classified is **surfaced and asked**, never acted on.

| Entry / state | Positively safe when | Otherwise |
|---|---|---|
| output item's done entry | its referenced commit still resolves in the branch history (report-time positional lookup) | surface the unresolved reference with its plain-language cause and ask; never accept done on the entry alone |
| no-commit-done entry | present, well-formed, and its item's tree is clean at the item's baseline | valid as-is — it carries no commit by design, so this is not a missing-commit divergence (the resolve check above is output-items-only) |
| any other disagreement | — | missing branch or commits, an edited or renumbered file, a foreign-run record, a partially-stripped record: examples of the default-deny rule, not a closed list — surface and ask |

## Exclusion

`.implement-work-items/progress.md` must never enter an item's code commit or count as
a scope finding. Placing the ledger inside the already-ignored `.implement-work-items/`
directory makes the existing directory exclusion cover most sites; verify all four hold:

1. **SKILL.md Step 3.4 stage-by-path** — stages the item's changed files by path, never
   the driver's `.implement-work-items/` artifacts.
2. **`review-verdict-contract.md` scope diff** — the changed-file computation excludes
   `.implement-work-items/`.
3. **`human-review-capture.md` reviewer pointer** — points the human at the item's
   change since `scope-baseline`, not the ledger (the one prose site to confirm).
4. **`no-output-completion.md` clean-tree assertion** — allows only
   `.implement-work-items/`, so the ledger update never reads as stray output.
