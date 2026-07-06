# Foreground hand-off protocol

For a `HITL` build (an interactive skill) or a bare `none` build, the driver hands
control to the user rather than dispatching a sub-agent. The driver never calls
the `Skill` tool; the user runs the skill in their own session.

## Hand-off

1. Mark the boundary: state that the user is steering and the run is paused.
   For a named skill, tell them to run it (for example `/skill-builder`); for
   `none`, build it free-form together. Instruct the user to say
   "Confirm done" when the item is built and you should resume your loop.
2. Build the item together with the user.

## On confirm-done

1. Suggest that the user either `/compact` current session or `/rewind` to the
   point where interactive build started, using the "summarize to here" option.
2. Re-ground: run [re-grounding-routine.md](./re-grounding-routine.md).
3. Continue at step **2. Verify** in the build/verify/review loop.

## Adopting the skill's own commits

An interactive skill may commit its own work, leaving the item as its commits plus,
sometimes, an uncommitted remainder. Review (step 3.3) already judged the full
changed-file set — committed and uncommitted — so the commit step just settles the
tree, with no second review dispatch:

1. Keep any commits the skill made since `scope-baseline`; never reset or squash them.
2. Commit any remaining uncommitted changes as one additional commit. If nothing
   remains uncommitted, do not force an empty commit.
3. Record the item's full commit range (`<scope-baseline>..HEAD`) in the work-state file.
