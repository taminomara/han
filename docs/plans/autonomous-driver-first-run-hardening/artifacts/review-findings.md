# Review Findings: implement-work-items First-Run Hardening

Findings from `han-planning:iterative-plan-review` passes on this feature specification. IDs continue the plan's global finding space (the `plan-a-feature` review recorded F1–F21 in [team-findings.md](team-findings.md)); this file starts at F22 so cross-references stay unambiguous. Spec-aware mode was engaged; `feature-technical-notes.md` does not exist, so `Changed in tech-notes:` is omitted.

## Major findings

### F22: The clean-tree allowance was wider than it needed to be

- **Agent:** self-review (operator-directed)
- **Category:** YAGNI candidate — simpler version available
- **Finding:** Draft D3 tolerated the entire plan folder as expected working-tree content and then relied on three sub-mechanisms to contain the blast radius (opening-commit staging that excludes a work item's own already-dirty paths, a preview enumeration, and a stale-run-artifact ask). The operator's note: the working tree should simply be clean before the first item, and anything other than the run's own just-produced planning outputs should be offered commit-or-stash.
- **Evidence considered:** The clean-tree gate's stated purpose (`SKILL.md` Step 1.8, "extra files might be folded into the first commit") and its current remedy already tells the operator to commit or stash first; source feedback improvement #2 (do not halt on the operator's own planning outputs). The simpler rule — clean tree, commit only the run's planning content, offer commit-or-stash for everything else — satisfies the same evidence as the multi-case toleration model and removes the three sub-mechanisms.
- **Resolution:** Replaced whole-folder toleration with: the working tree must be clean before the first item; the run's planning content (work-items file + linked artifacts) is committed as the opening; anything else (a stray draft, an unrelated edit, a work item's own already-dirty target, or a prior run's leftover artifacts) is offered commit-or-stash at startup. This subsumes the earlier F6 (own-path exclusion), F7 (preview enumerate), and F8 (stale-artifact ask) handling under one uniform rule.
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Outcome, Primary Flow (step 2), Edge Cases and Failure Modes (sub-agent-revert-adjacent rows: stale-artifact and own-expected-path), User Interactions (commit-or-stash affordance); decision-log D3 (Decision, Rationale, Rejected alternatives, Driven by findings)

### F23: The preserve-set was redundant under the new commit cadence

- **Agent:** self-review (operator-directed)
- **Category:** YAGNI candidate — simpler version available
- **Finding:** Draft D8 passed every dispatched sub-agent a preserve-set and verified after each dispatch that those paths still carried their pre-dispatch changes. The operator's note: with the new commit cadence (D10, every iteration committed), the working tree stays clean before every build, review, and fix, so there is no uncommitted in-flight work at dispatch time and the preserve-set guards an empty window.
- **Evidence considered:** D10 commits every iteration; the original incident (source feedback lines 54–57) was a sub-agent discarding *uncommitted* work by "restoring it to committed state." Once every iteration is committed before the next dispatch, restoring to committed state is a no-op, so the incident cannot recur. The preserve-set plus post-dispatch verification is machinery whose sole evidence (the W-7 incident) is now addressed structurally by the commit cadence.
- **Resolution:** Replaced the preserve-set plus post-dispatch verification with the clean-tree-at-dispatch invariant: the driver commits any in-flight work — its own, a sub-agent's output, or the operator's hand-edits — before dispatching the next sub-agent. Removed the preserve-set from the D11 role payloads and removed the "detected preserve-set revert" error state. Renamed D8. A sub-agent that rewrites already-committed history is noted as a separate, out-of-scope class. This structurally resolves the earlier F12 (preserve-set hardening / the on-call ship-blocker) more fundamentally than the post-dispatch check did.
- **Resolved by:** user input
- **Raised in round:** R1
- **Changed in plan:** Outcome, Primary Flow (steps 4, 5), Edge Cases and Failure Modes (sub-agent-revert row), User Interactions (error states); decision-log D8 (renamed and rewritten), D10 (clean-tree-at-dispatch consequence), D11 (preserve-set removed from payload)

## Minor edits

_None this session._
