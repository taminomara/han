# Sub-agent instructions

The common instructions the driver gives its build and review sub-agents. For a build or
fix dispatch the driver copies the **Shared baseline** plus the **Build payload** into the
dispatch prompt; for a review dispatch, the baseline plus the **Review payload**. Copy the
blocks verbatim, substituting each `{…}` with its run-scoped value (see Driver assembly).
The **Driver assembly** section is the driver's own logic and is never copied into a
dispatch.

## Shared baseline (copy verbatim)

- **Ground truth.** Build or review against this work item, the paths it lists under
  `References`, and the committed spec or plan those references cite.
- **Run the named skill.** Follow the guidance of `{skill}`, running it as its own skill
  (for example, run `han-coding:tdd`), not an approximation of it.
- **Do not commit.** Leave your changes in the working tree. Never run `git commit`,
  `git reset`, or `git rebase` — the driver owns every commit.
- **Bounded wait on any nested worker.** A skill you run may fan out its own nested agent.
  Never end a turn waiting on one, and never rely on its completion notification. Spawn it
  in the background; have it write its result atomically to an agreed path
  (`<output> > RESULT.tmp && mv RESULT.tmp RESULT`); then block on a single bounded
  foreground poll (`for i in $(seq 1 60); do [ -f RESULT ] && break; sleep 3; done`) and
  read the file. On timeout, continue without that result rather than hanging.

## Build payload (copy verbatim)

- **Implementation-skill guidance.** Follow the guidance of the item's implementation
  skill, `{implementation-skill}`.
- **Accumulated corrections.** Apply these as build directives: `{corrections}`.
- **Residual findings.** On a fix round, also address the findings still open from the
  previous iteration: `{residual-findings}`.
- **Return** per [build-report-contract.md](./build-report-contract.md).

## Review payload (copy verbatim)

- **Review-skill guidance.** Follow the guidance of the item's review skill, `{review-skill}`.
- **Scope.** Judge scope against baseline commit `{scope-baseline}` and the item's
  `Expected paths`: `{expected-paths}`.
- **Approved coherence edits.** These paths are already approved for this item — do not
  re-raise them as scope findings: `{approved-paths}`.
- **Corrections as context.** These accumulated corrections are context for judging that
  the build honored them, never new review criteria: `{corrections}`.
- **Return** per [review-verdict-contract.md](./review-verdict-contract.md).

## Driver assembly (not copied into a dispatch)

How the driver fills the payload placeholders and maintains the corrections it injects:

- `{corrections}` is the record's `Corrections:` block; `{approved-paths}` is its
  `Coherence approvals:` block ([durable-record-protocol.md](./durable-record-protocol.md)).
  `{scope-baseline}` and `{expected-paths}` come from the item's state and its work-item entry.
- **Corrections accumulation:**
  - A **general style correction** accumulates: append it to the `Corrections:` block and
    inject it into every later build payload this run.
  - An **item-specific one-off** does not accumulate: apply it to its item and stop.
  - An **item's own explicit instruction wins** for that item, over any accumulated
    correction that would contradict it.
