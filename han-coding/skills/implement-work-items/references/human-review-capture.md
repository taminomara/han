# Human-review capture

For a `HITL` or `none` review (a human read), the driver captures the user's findings
into the normalized verdict
([review-verdict-contract.md](./review-verdict-contract.md)) rather than
dispatching a review sub-agent.

## Capture

1. Point the user at the item's change — everything since `scope-baseline`, committed
   or not, excluding the driver's `.implement-work-items/` — the spec sections it
   references, and the files outside `Expected paths`, so
   they judge scope as well as quality. A change beyond the item's work is a scope
   finding. For a no-output item (`Expected paths: None`) there is no change to read:
   ask the user to confirm the checks ran and the result is sound (the coverage
   attestation is "operator confirmed result"), and treat any file left despite `None`
   as a scope finding.
2. Capture each finding as a tier (Critical | Warning | Suggestion), a location
   (`file:line` for code, a heading or "document-wide" for prose), and a one-line
   claim. If a field is missing, ask for it; do not guess. If the user raises an
   issue a fix round cannot resolve — the scope or approach must change for the
   feature to work or be secure, an architectural problem, or an unresolvable RAID
   item — capture it as the verdict's ESCALATION so the run halts for the decision;
   otherwise ESCALATION is none.
3. Before the user confirms, echo the captured findings back, each with its
   tier and whether it gates at the active threshold, and restate the threshold.
4. Take a **Confirm done** signal. State that confirming closes the
   review and evaluates the gate.
5. Write the durable record at `.implement-work-items/reviews/<W-N>-iter<fix-round>.md`,
   even when clean ("none at or above the gate threshold").
6. Re-ground: run [re-grounding-routine.md](./re-grounding-routine.md) before continuing.

Each review round writes a fresh verdict and durable record. The fix agent reads
only the current round, so a retracted finding is not re-chased.

## Opt-in pause on an unattended review

An `AFK` review runs uninterrupted by default. The user opts in by sending a
"pause after this review" message while the review runs; a message sent during a
tool step arrives once it finishes.

1. When the review begins, note the user may send a pause request, then start
   the review sub-agent immediately, without waiting.
2. After the sub-agent returns, check for a pending pause request. If present,
   collect the user's findings and merge them with the agent's into the one
   verdict, then gate. If absent, gate on the agent's verdict and continue.

This applies only to `AFK`-review items; a `HITL` or `none` review is already the user's.
