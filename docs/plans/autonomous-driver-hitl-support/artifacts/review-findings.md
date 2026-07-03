# Review Findings: Autonomous Driver Human-in-the-Loop Support (iterative-plan-review)

<!--
Findings from iterative-plan-review sessions on feature-specification.md.
F# continues from the plan-a-feature team-findings.md counter (which ended at
F24) so finding IDs stay globally unique across the plan's whole review history.
Round IDs (R#) are local to this iterative-review history (review-iteration-history.md).
Spec-aware mode: engaged.
-->

## Major findings

### F25: Unattended reviews must not interrupt a fully-autonomous run; operator feedback is opt-in

- **Agent:** self-review (operator-directed)
- **Category:** behavioral correction (alternate flow)
- **Finding:** The "The operator adds feedback to an unattended review" alternate flow (and the D8 decision) had the driver, after every unattended review returned, offer the operator the chance to add findings before the gate. That interrupts exactly the fully-autonomous operation the AFK path exists for: the operator wants to start the run, leave it in the background (for example in a separate terminal), and do other work while the loop runs. An always-on post-review offer defeats walk-away operation.
- **Evidence considered:** Operator direction: fully-AFK items should run without interruption; an operator who wants to contribute must opt in *before* the automatic review starts by sending a message asking to pause after the automated review finishes, and absent that message the driver does not stop. Consistent with the spec's existing default-uninterrupted posture for AFK items (`feature-specification.md#primary-flow` step 3.iv) and with keeping general mid-run stop deferred (`#out-of-scope`) — this is a narrow, review-specific opt-in, not a general clean-stop.
- **Resolution:** Reworked the alternate flow to "The operator opts in to a review pause on an unattended item": by default the driver runs an unattended review and proceeds to the gate without pausing; the driver announces the pause-after-review option and starts the review immediately without waiting; the operator opts in by sending a pause-after-review message *while that review runs*; the driver honors a request that has arrived by the time the sub-agent returns by pausing to collect and merge the operator's findings, then gating; absent such a request it does not stop. The plan preview also discloses how to opt in. Updated D8 (decision text, rationale, rejected alternatives, `Driven by findings`) and the User Interactions Affordances and Feedback bullets to match. No mechanic leaked into the spec (the pending-request detection is left to `plan-implementation`), so no `T#` was created. (Timing refined by a follow-up on the same finding: the opt-in window is *during* the running review, not before it starts — the driver never waits before starting the review.)
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Alternate Flows and States (the renamed "operator opts in to a review pause" flow), User Interactions (Affordances, Feedback)
- **Changed in tech-notes:** —

## Minor edits

_None._
