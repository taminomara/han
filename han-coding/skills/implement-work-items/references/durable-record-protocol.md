# Durable-record protocol

The driver records per-item progress as a committed ledger that travels with the
run's branch. This file is the schema the setup, resume, forward-reconcile, and
completion steps consult — it defines the record's form, its entry types, the
trailer convention, the integrity rules, and the exclusion sites. It is not a
process to run.

## Record form

- The record is one committed markdown ledger at `.implement-work-items/progress.md`,
  appended to and re-committed as each entry is written.
- Setup (SKILL.md Step 2.2) makes it trackable by writing `.implement-work-items/.gitignore`
  as two lines — `*` then `!progress.md` — so the ledger is version-controlled while
  `state.json` and the review records under the directory stay ignored.
- Each ledger commit uses the repo's detected commit convention so the project's hooks
  accept it; a rejected bookkeeping commit is surface-and-stop, never the fix loop.

## Trailers

Both are git commit trailers, matched **exactly**, never as a commit-message
substring, so an ordinary commit that happens to mention the run is never misread.

- `Implement-Work-Items-Run: <path>` on **every** ledger commit — value is the
  work-items file's normalized repo-root-relative path (strip a leading `./`, resolve
  `..`, drop any trailing slash). This is the run-identity signal `scan-run-history.sh`
  greps to classify an invocation fresh / resume / refuse.
- `Implement-Work-Items-Item: W-N` on each item's **own code commit** — the positive
  identity forward-reconcile keys on and report-time reference derivation resolves.

## Entry types

Five entry types, each a line in the ledger, distinguished by its own entry token.
Fields are kept minimal:

| Entry | One per | Fields | Notes |
|---|---|---|---|
| opening | run | the run's effective configuration (gate threshold, fix-loop cap, build/fix model, branch, verification configuration) and the normalized work-items path it drives | co-committed with the planning artifacts; read on resume to recognize the run and restore its config |
| start-of-item | item | item id | marks the commit the item's changed-file set is measured against — the durable replacement for the in-session `scope-baseline` |
| done | output item that cleared | item id | references the item's code commit **positionally**, computed at report time (the item-id trailer plus the start-of-item-to-done bracket), never a stored hash; the code commit strictly precedes this entry |
| no-commit-done | no-output `audit` that cleared | item id | carries **no `Type` field** (read from the work-items file at resume) and no commit reference; distinguished from a done entry by its entry token; the durable analog of `no-output-completion.md`'s `done-no-commit` |
| skip | skipped item | item id | carries **no dependency snapshot**; the graph is re-derived from the current work-items file on resume |

Never recorded: a durable fix-counter (the fix-round budget is within-session), a
body-hash or per-item body-identity (done items are trusted by identifier), and a
captured pre-work decision (re-asked on resume).

## Default-deny integrity matrix

On resume the record is untrusted until each entry is positively classified as safe;
any state not so classified is **surfaced and asked**, never acted on.

| Entry / state | Positively safe when | Otherwise |
|---|---|---|
| output item's done entry | its referenced commit still resolves in the branch history (report-time positional lookup) | surface the unresolved reference with its plain-language cause and ask; never accept done on the entry alone |
| no-commit-done entry | present, well-formed, and its item's tree is clean at the item's baseline | valid as-is — it carries no commit by design, so this is not a missing-commit divergence (the resolve check above is output-items-only) |
| any other disagreement | — | missing branch or commits, an edited or renumbered file, a foreign-run record, a partially-stripped record: examples of the default-deny rule, not a closed list — surface and ask |

## Exclusion checklist

`.implement-work-items/progress.md` must never enter an item's code commit or count
as a scope finding. Placing the ledger inside the already-ignored
`.implement-work-items/` directory makes the existing directory exclusion cover most
sites; verify all four hold:

1. **SKILL.md Step 3.4 stage-by-path** — stages the item's changed files by path, never
   the driver's `.implement-work-items/` artifacts.
2. **`review-verdict-contract.md` scope diff** — the changed-file computation excludes
   `.implement-work-items/`.
3. **`human-review-capture.md` reviewer pointer** — points the human at the item's
   change since `scope-baseline`, not the ledger (the one prose site to confirm).
4. **`no-output-completion.md` clean-tree assertion** — allows only
   `.implement-work-items/`, so the ledger update never reads as stray output.
