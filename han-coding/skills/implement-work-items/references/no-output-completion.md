# No-output completion

An `audit` item that declared `Expected paths: None` and changed no files
completes without a code commit. This file holds the mechanics the driver's Step 3.4,
Step 4, and Halt Procedure point to.

## Completing a no-output item

1. Assert the tree is clean since `scope-baseline` (only paths with a
   `.implement-work-items/` segment at any depth allowed). If a file was left despite
   `Expected paths: None`, the item did produce
   output: do not record it no-commit. Halt through the Halt Procedure with the stray
   file named, so it is never silently dropped or carried to the next item.
2. Make no code commit. Record the `no-commit-done` entry to `progress.md` and commit it
   per [durable-record-protocol.md](./durable-record-protocol.md). That entry is the item's
   distinct terminal marker, so re-grounding never mistakes it for `pending`.

## Reporting

- **Completion summary (Step 4).** List no-output completions as their own outcome:
  the item, its `Type`, `Expected paths: None`, and a count, kept distinct from
  committed items so a legitimate empty audit is not read as a silent no-op.
- **Halt Procedure.** A `done-no-commit` item carries no commit and is not in the
  completed-items commit range; name it separately so a cherry-pick-forward does not
  drop it. It re-executes on a fresh run, which is safe because the catalog constrains
  a no-output audit to side-effect-free checks.
