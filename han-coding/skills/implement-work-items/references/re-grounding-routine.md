# Re-grounding routine

## Core routine

Run these at every re-entry site, re-reading only what you do not already have in
context or that may be stale:

1. **Reconstruct run state** from the durable record — read the committed
   `.implement-work-items/progress.md` ledger
   ([durable-record-protocol.md](./durable-record-protocol.md)) to reconstruct which
   items are done (each committed or, for a no-output `audit`, completed without a
   commit), which is in progress, and which were skipped.
2. **Re-derive the dependency graph** from the current work-items file, so a dependent
   of a skipped item is not picked up.
3. **Re-read the working tree** (`git status`, and the diff since the in-progress
   item's `scope-baseline` where one is in flight).
4. **Reload-instructions**: re-read the driver's own instructions — this SKILL.md and
   any reference in flight — reloading any that read as truncated.

## State store

- **Cross-session entry.** `state.json` is gitignored and does not travel with the
  branch, so reconstruct it from the durable record. Treat any surviving `state.json`
  as untrusted: rebuild it, never read it as authority.
- **In-session entry.** The store is current; re-read it as-is.
