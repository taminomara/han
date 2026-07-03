# Human-review capture

For a `HITL` review (a human read), the driver captures the operator's findings
into the normalized verdict
([review-verdict-contract.md](./review-verdict-contract.md)) rather than
dispatching a review sub-agent.

## Capture

1. Point the operator at the item's change and the spec sections the item references.
2. Capture each finding as a tier (Critical | Warning | Suggestion), a location
   (`file:line` for code, a heading or "document-wide" for prose), and a one-line
   claim. If a field is missing, ask for it; do not guess.
3. Before the operator confirms, echo the captured findings back, each with its
   tier and whether it gates at the active threshold, and restate the threshold.
4. Take a confirm-all-feedback-given signal. State that confirming closes the
   review and evaluates the gate.
5. Write the durable record at `.implement-work-items/reviews/<W-N>.md`, even when
   clean ("none at or above the gate threshold").
6. Catch up on run state before continuing.

Each review round writes a fresh verdict and durable record. The fix agent reads
only the current round, so a retracted finding is not re-chased.

## Opt-in pause on an unattended review

An `AFK` review runs uninterrupted by default. The operator opts in by sending a
"pause after this review" message while the review runs; a message sent during a
tool step arrives once it finishes.

1. When the review begins, note the operator may send a pause request, then start
   the review sub-agent immediately, without waiting.
2. After the sub-agent returns, check for a pending pause request. If present,
   collect the operator's findings and merge them with the agent's into the one
   verdict, then gate. If absent, gate on the agent's verdict and continue.

This applies only to `AFK`-review items; a `HITL` review is already the operator's,
and a `none` review has no gate.
