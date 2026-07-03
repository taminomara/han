# Foreground hand-off protocol

For a `HITL` build (an interactive skill) or a bare `none` build, the driver hands
control to the operator rather than dispatching a sub-agent. The driver never calls
the `Skill` tool; the operator runs the skill in their own session.

## Hand-off

1. Recommend the operator run a manual compaction first, so the inline work does
   not crowd the driver's context.
2. Mark the boundary: state that the operator is steering and the run is paused.
   For a named skill, tell them to run it (for example `/skill-builder`); for
   `none`, build it free-form together.
3. Emit an action-needed prompt as the last line and wait for a confirm-done message.

## On confirm-done

1. Mark control returned.
2. Catch up on run state: re-read `.implement-work-items/state.md` and reload this
   skill's own instructions. If you cannot re-establish them, halt fail-closed.
3. Continue to Verify. There is no build report to parse; the item is trusted
   through independent verification and review.

## Unfinished or unchanged tree

If the operator reports the item is not done, or the tree is unchanged after
confirm-done, do not commit nothing. Offer two options only: re-foreground the
skill so they can finish, or halt through the Halt Procedure. There is no skip or
defer.

## Adopting the skill's own commits

An interactive skill may commit its own work. At the commit step, if the tree is
clean but new commits exist since the item's `scope-baseline`
(`git log <scope-baseline>..HEAD`):

1. Review the cumulative diff (`git diff <scope-baseline> HEAD`) yourself. This is
   the driver's own inspection, not a second review dispatch.
2. Adopt those commits as the item's and record the commit range in the work-state
   file. Do not force an empty commit.
