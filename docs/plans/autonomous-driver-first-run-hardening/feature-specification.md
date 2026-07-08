# Feature Specification: implement-work-items First-Run Hardening

The driver survives realistic active-branch development state and operator-in-the-loop refinement without spurious halts or lost work, applying a bundle of behavioral improvements drawn from its first full end-to-end run.

## Outcome

After this feature, a run of the driver on a real feature branch does the right thing under conditions that tripped it before:

- It branches from the base that actually carries the plan's dependencies, not a stale default that is missing them ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)).
- It requires a clean working tree before the first item, committing the run's own just-produced planning outputs as its opening and offering to commit or stash anything else, instead of either halting outright or silently absorbing it ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)).
- It spends its automated fix budget only on automated churn, so operator-directed refinement does not force a mid-collaboration halt ([D5](artifacts/decision-log.md#d5-operator-directed-fixes-do-not-consume-the-automated-fix-cap)).
- It lets the operator address findings below the gate threshold that genuinely matter, re-verifying before it commits any such fix, and lets an approved fix touch already-committed sibling files for coherence, without either being treated as a hard failure ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement), [D7](artifacts/decision-log.md#d7-coherence-spillover-is-surfaced-for-approval-not-flagged)).
- It commits any in-flight work before dispatching the next sub-agent, so the working tree is clean at every dispatch boundary and a sub-agent that restores files to their committed state cannot silently discard an unsaved fix ([D8](artifacts/decision-log.md#d8-a-clean-tree-at-every-dispatch-removes-the-preserve-set-need)).
- It carries the style corrections the operator raised on earlier items forward into every later build, so the same class of correction is not re-made item after item ([D9](artifacts/decision-log.md#d9-operator-corrections-accumulate-within-the-run)).
- It commits every build and fix iteration and its own bookkeeping to the branch, keeping code commits and bookkeeping commits separate, so the full run history is durable and diffable and a reviewer can confirm a fix by comparing iterations ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed), [D12](artifacts/decision-log.md#d12-the-run-record-is-a-single-committed-file)).

## Actors and Triggers

- **Actors** — the **operator** running the driver; the **driver** itself (the orchestrator); the **build sub-agents** and **review sub-agents** the driver dispatches.
- **Triggers** — the operator invokes the driver on a work-items file, either as a fresh run or as a resume of a prior run on the same file. No trigger changes in this feature.
- **Preconditions** — a git repository; a validated work-items file. The driver treats the folder that holds the work-items file as the plan folder and does not require a specific artifacts subfolder to be present ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)). The review step still runs on the existing review dispatch: this bundle does not change how the review fan-out is dispatched and accepts the known nested-dispatch limitation the same first-run feedback documented, which is deferred to its own feature (see Out of Scope).

## Primary Flow

This traces one run through the loop, calling out where the hardened behavior differs from the pre-feature driver. Steps not listed here are unchanged.

1. **Resolve the base (fresh runs).** On a fresh run the driver fetches and resolves the base it will branch from. When the current branch is ahead of the resolved default base — the base is missing commits the current branch already carries — the driver surfaces the current branch as an alternative base, shows how far ahead and behind each candidate is, recommends branching from the current branch, and asks the operator to confirm before creating anything ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)). On a resume the base is read from the run's own recorded opening, not re-resolved or re-confirmed, so an active-branch resume is not re-prompted ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)).
2. **Confirm a clean tree.** The working tree must be clean before the first item starts. The run's own just-produced planning outputs — the work-items file and the artifacts it links — are the allowed exception: the driver stages exactly that planning content as its opening commit, and the plan-preview enumerates what that commit will contain. Anything else uncommitted in the tree, including a stray draft or an unrelated edit, the driver offers to commit or stash before starting, rather than halting outright or silently folding it in ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)).
3. **Set up run artifacts.** The driver keeps its run-artifact area inside the plan folder ([D4](artifacts/decision-log.md#d4-run-artifacts-live-inside-the-plan-folder)). The run record is a single file that both records progress and holds the machine state; the driver commits it, and every review and fix record, to the branch in bookkeeping commits kept separate from code commits ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed), [D12](artifacts/decision-log.md#d12-the-run-record-is-a-single-committed-file)).
4. **Build an item.** For each item, the driver dispatches a build sub-agent (or hands off to the operator for an interactive build) from a clean working tree — any in-flight work is committed before the dispatch, so the sub-agent cannot silently discard it ([D8](artifacts/decision-log.md#d8-a-clean-tree-at-every-dispatch-removes-the-preserve-set-need)). A build sub-agent receives a consistent baseline instruction set, the directive to follow the guidance of the item's implementation skill, and the set of style corrections accumulated from earlier items this run ([D9](artifacts/decision-log.md#d9-operator-corrections-accumulate-within-the-run), [D11](artifacts/decision-log.md#d11-sub-agents-receive-a-role-scoped-instruction-set)). The build iteration is committed ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed)).
5. **Verify, then review.** The driver runs verification, then dispatches the review step. A review sub-agent receives the baseline instruction set, the directive to follow the guidance of the item's review skill, and the paths of any coherence edits already approved for this item so it does not re-raise them; it compares the latest committed iteration against the prior one to confirm what changed, working from a clean tree. When the gate is green but below-threshold findings remain, the driver reads the durable review record for their detail rather than acting on counts alone ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement), [D11](artifacts/decision-log.md#d11-sub-agents-receive-a-role-scoped-instruction-set)).
6. **Gate and fix.** A fix round driven by automated churn spends one slot of the automated fix budget; a round the operator directs by hand does not, and an item the operator drives entirely by hand is not gated by the automated cap at all ([D5](artifacts/decision-log.md#d5-operator-directed-fixes-do-not-consume-the-automated-fix-cap)). Each fix iteration is committed as a review-addressing commit carrying a marker that lets the operator later collapse it into the item's initial commit; the driver itself never rewrites history ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed)). When the gate is green, the driver runs no further review, but may still address below-threshold findings that genuinely matter — or deliberately leave them — by its own judgement; it re-runs available verification before committing any such fix, and records which findings it addressed and which it left ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement)).
7. **Approve coherence spillover.** When a fix legitimately edits already-committed sibling files that are outside the item's own expected paths, the scope check surfaces those edits to the operator as a coherence-approval choice rather than a hard finding; an already-committed file the item's own expected paths predicted is ordinary expected work, not spillover. On approval the edits are recorded as intended, threaded to this item's later review rounds so they are not re-raised, and do not block the gate; on rejection they remain a scope finding routed through the normal fix loop ([D7](artifacts/decision-log.md#d7-coherence-spillover-is-surfaced-for-approval-not-flagged)).
8. **Commit and carry forward.** The item's commits — its initial build and any review-addressing fix commits — remain on the branch; the driver records the correction classes the operator raised into the run's committed preference record so later builds inherit them, and advances to the next item ([D9](artifacts/decision-log.md#d9-operator-corrections-accumulate-within-the-run), [D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed)).

## Alternate Flows and States

### Resume reads the committed history as the authoritative record

- **Entry condition:** the operator resumes a prior run on the same work-items file.
- **Sequence:** the re-grounding step reconstructs run state, accumulated corrections, coherence approvals, and iteration history from the committed run record and branch history, which are the authoritative store; a disagreement between that record and the working tree default-denies to a stop rather than proceeding on a guess ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed), [D12](artifacts/decision-log.md#d12-the-run-record-is-a-single-committed-file)).
- **Exit:** the resumed run continues without re-making the corrections the operator already raised or re-litigating an approval already granted in the earlier session.

### Operator-directed fix during the loop

- **Entry condition:** the gate does not clear and the operator steers the fix by hand, or the item is one the operator drives interactively.
- **Sequence:** the driver applies or accepts the operator's hand-directed change, commits the iteration, and re-verifies and re-reviews, without incrementing the automated fix budget ([D5](artifacts/decision-log.md#d5-operator-directed-fixes-do-not-consume-the-automated-fix-cap)).
- **Exit:** on clear, the item is recorded done; if it does not clear, the driver returns to the same choice rather than silently consuming the cap.

### Coherence spillover rejected

- **Entry condition:** the scope check finds sibling-file edits outside the item's expected paths and the operator declines to approve them.
- **Sequence:** the edits remain a scope finding; the driver routes it through the normal not-cleared fix path ([D7](artifacts/decision-log.md#d7-coherence-spillover-is-surfaced-for-approval-not-flagged)).
- **Exit:** the item clears only once the sibling-file edits are reverted or approved.

## Edge Cases and Failure Modes

| Condition | Required Behavior |
|-----------|-------------------|
| Current branch in sync with the resolved base (neither ahead nor behind) | No recommendation change: the driver resolves the base as it does today and does not surface the current branch as an alternative ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)). |
| Current branch diverged from the base (both ahead and behind) | The driver surfaces both candidates with their ahead/behind counts and asks the operator to choose, without computing a recommended base — the ahead/behind evidence is shown, the choice is the operator's ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)). |
| The fetch fails or completes only partially | The driver states the fetch did not complete, marks the ahead/behind counts as possibly stale, and asks the operator rather than presenting stale counts as authoritative ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)). |
| No current branch to name (detached working state) | The driver does not offer a current-branch alternative; it falls back to asking the operator which base to branch from ([D2](artifacts/decision-log.md#d2-base-resolution-when-the-current-branch-is-ahead)). |
| No base resolves at all | Unchanged: the driver surfaces the condition and asks the operator which base to branch from rather than proceeding. |
| A dispatched sub-agent restores files to their committed state (the class that caused the first-run data loss) | No uncommitted driver or operator work is at risk: the driver commits any in-flight work before each dispatch, so restoring to committed state is a no-op. A sub-agent that rewrites already-committed history is a separate, more severe class outside this feature's scope ([D8](artifacts/decision-log.md#d8-a-clean-tree-at-every-dispatch-removes-the-preserve-set-need)). |
| An accumulated correction contradicts a later item's own explicit instruction | The item's own instruction wins for that item, and an item-specific one-off correction is not itself accumulated into later builds; only general corrections accumulate ([D9](artifacts/decision-log.md#d9-operator-corrections-accumulate-within-the-run)). |
| The accumulated preference set grows large over a long run | Accepted: the set is run-scoped and advisory; consolidation or de-duplication is not attempted at the observed run lengths (see Deferred). |
| An approved coherence edit is still present in a later review round of the same item | The approval is threaded to the item's later review dispatches so the edit is not re-raised as a fresh scope finding, avoiding a gate that can never clear ([D7](artifacts/decision-log.md#d7-coherence-spillover-is-surfaced-for-approval-not-flagged)). |
| A below-threshold fix on a green gate introduces a new above-threshold defect | The driver re-runs available verification before committing any post-gate fix; in scope-check-only mode, where no suite exists, the scope check still runs and a fix the driver judges risky is re-reviewed rather than committed unchecked ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement)). |
| A below-threshold finding the driver judges must-fix needs a scope or approach change a fix cannot make | The driver escalates it through the recovery menu rather than silently fixing or silently dropping it ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement)). |
| A fresh run finds a stale run-artifact area from an earlier stopped or aborted run under the plan folder | It is not the run's planning content, so the driver surfaces it and offers to commit, stash, or clean it rather than silently folding it into the new run ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder), [D4](artifacts/decision-log.md#d4-run-artifacts-live-inside-the-plan-folder)). |
| A work item's own expected path is a file inside the plan folder that is already dirty at run start | It is not the run's planning content, so the driver offers to commit or stash it before starting rather than folding the pre-existing edit into the opening commit and misattributing it ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)). |
| The work-items file is not inside a folder that has an artifacts subfolder | The driver degrades gracefully: it treats the work-items file's own folder as the plan folder and places its run-artifact area there, rather than refusing ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder), [D4](artifacts/decision-log.md#d4-run-artifacts-live-inside-the-plan-folder)). |
| A bookkeeping commit is rejected (a hook rejects the run-record commit) | Unchanged in kind: this is a marker-write failure, surfaced as a resumable stop, never routed through the code-fix loop ([D12](artifacts/decision-log.md#d12-the-run-record-is-a-single-committed-file)). |

## User Interactions

- **Affordances:**
  - A **base-recommendation choice** at the start of a fresh run when the current branch is ahead of the resolved base: both candidates, their ahead/behind counts, the recommended base, and confirm-or-redirect. When the branch has diverged or the fetch was incomplete, the same surface presents the counts and asks without a recommendation.
  - A **coherence-approval choice** at the gate when a fix touched sibling files outside the item's expected paths: which files, and approve-as-intended or reject-as-scope-finding.
  - A **commit-or-stash offer** at startup for any uncommitted content that is not the run's planning content — a stray draft, an unrelated edit, or a prior run's leftover artifact area — so the working tree is clean before the first item ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)).
- **Feedback:**
  - The plan-preview enumerates exactly what the opening commit will stage ([D3](artifacts/decision-log.md#d3-clean-tree-allowance-covers-the-plan-folder)).
  - Each below-threshold fix/leave disposition is recorded in the item's committed record at decision time and named in the run summary, so it survives a non-terminal halt and is auditable ([D6](artifacts/decision-log.md#d6-below-threshold-findings-may-be-addressed-by-judgement)).
  - The run summary notes the correction classes carried forward into later builds ([D9](artifacts/decision-log.md#d9-operator-corrections-accumulate-within-the-run)); the committed per-iteration history is browsable after the run ([D10](artifacts/decision-log.md#d10-every-iteration-and-the-bookkeeping-are-committed)).
- **Error states:** a below-threshold finding that cannot be fixed, and a rejected coherence spillover that is not reverted, both surface through the recovery menu rather than as silent outcomes.

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
|---------------------|-----------|-------------|-----------------------------------|
| The planning skill that produces the work-items file and plan folder | inbound | The base-resolution, clean-tree, and artifact-placement behaviors depend on the folder that holds the work-items file and on the work-items file's linked-artifact list. | The plan folder must exist before the run; an artifacts subfolder is used if present but is not required. |
| The planning skill that breaks a plan into work items | inbound | Two threads from the source feedback — pinning shared cross-item contracts concretely in the foundation item, and emitting an explicit instruction that sub-agents follow the named skill's guidance — require changes in that skill and are out of this feature's scope (see Deferred and Out of Scope). | None imposed by this feature; noted so the coordination is not lost. |
| The run branch | outbound | The driver commits per item to the run branch: initial build and review-addressing fix commits as code commits, and the run record, review records, and preferences as bookkeeping commits kept separate from code commits and marked so they are identifiable. | Committed history is the authoritative run record; the item's completion is marked by its committed record, and code and bookkeeping commits are never mixed. |

## Out of Scope

- **Containing the harness nested-agent limitation (flat review dispatch and bounded, self-terminating agents).** Surfaced by the same first-run feedback, but large enough to plan and build as its own feature; excluded here so this bundle stays shippable. This bundle's review dispatch stays on the existing nested path and accepts the documented residual until that feature ships.
- **Modifying git history after the run.** The driver tags review-addressing and bookkeeping commits so the operator (or a later tool) can collapse or filter them, but the driver never performs an autosquash, strip, or any post-run history rewrite itself.
- **Changing what the work-items planning skill emits.** Concretely pinning shared contracts in the foundation item and emitting a follow-the-skill-guidance instruction are cross-skill changes deferred to that skill (see Deferred).
- **Cross-run or project-global preference memory.** The accumulated corrections are scoped to a single run.

## Deferred (YAGNI)

### Cross-run / project-global preference memory
- **Why deferred:** the operator chose run-scoped accumulation; there is no evidence yet of a need to reuse corrections across unrelated runs, and a shared mutable store introduces staleness risk. Simpler-version test: within-run accumulation satisfies the stated need.
- **Reopen when:** multiple runs are observed re-correcting the same style classes a prior run already learned.
- **Source:** interview Q3 (preference-memory persistence).

### Pre-declared coherence-companion paths
- **Why deferred:** the operator chose surface-and-approve at the gate; declaring companion paths up front requires foresight the run rarely has, and the simpler ad-hoc approval satisfies the same evidence.
- **Reopen when:** a recurring, foreseeable spillover pattern makes up-front declaration clearly worth the planning cost.
- **Source:** interview Q2 (coherence-spillover approval model).

### Consolidating or de-duplicating the accumulated preference set
- **Why deferred:** at the run lengths observed so far the set stays small and advisory; consolidation is machinery for a scale not yet seen.
- **Reopen when:** a run accumulates enough near-duplicate corrections that later build briefs are measurably diluted.
- **Source:** review finding F11 (edge-case-explorer).

### Concretely pinning shared contracts in the foundation item
- **Why deferred:** this is a change to the work-items planning skill, outside the chosen implement-work-items-only scope. Captured as an inbound coordination.
- **Reopen when:** the work-items planning skill is taken up for hardening.
- **Source:** source feedback, improvement #4 (contracts).

### Emitting an explicit follow-the-skill-guidance instruction from the planning skill
- **Why deferred:** this is a change to the work-items planning skill, outside the chosen scope. The implement-work-items side (its sub-agents receive the follow-the-guidance directive in their baseline instructions) is in scope as [D11](artifacts/decision-log.md#d11-sub-agents-receive-a-role-scoped-instruction-set); the planning-skill side is deferred.
- **Reopen when:** the work-items planning skill is taken up for hardening.
- **Source:** source feedback, operator feedback #5.

## Open Items

- **OI-1:** How much discretion the driver should have when it judges a below-threshold finding "genuinely matters" on a green gate. The default is the operator-visible, per-item durable disposition record (what was fixed, what was left) plus mandatory re-verification before commit; the open question is whether an explicit guardrail on *what* it may fix is also needed.
  - **Resolves when:** enough real runs show whether the durable disposition record is a sufficient bound.
  - **Blocks implementation:** No — the durable-record default is implementable now; a guardrail can be added without reshaping the flow.
- **OI-2:** The criterion by which the driver names a reusable "correction class" from ad-hoc operator feedback (D9) is the same open-ended judgement as OI-1. The default is to accumulate only general style corrections and to leave item-specific one-offs un-accumulated; the open question is whether the class boundary needs an explicit definition for consistent behavior across runs.
  - **Resolves when:** real runs show whether accumulation is consistent under the default.
  - **Blocks implementation:** No — the default rule is implementable now.

## Summary

- **Outcome delivered:** the driver runs cleanly on realistic active-branch state and operator-in-the-loop refinement, applying a bundle of first-run-feedback fixes across base resolution, the clean-tree gate, fix-cap accounting, below-threshold and coherence handling, sub-agent coordination, within-run preference memory, and committed per-iteration run history.
- **Primary actors:** the operator and the driver, plus the build and review sub-agents the driver dispatches.
- **Decisions settled by evidence:** 7 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** 5 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** junior-developer, on-call-engineer, edge-case-explorer, devops-engineer — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** base resolution made fresh-only and its diverged-case heuristic dropped for a plain operator choice; the clean-tree gate narrowed to commit-or-stash anything that is not the run's planning content; coherence approval made persistent across rounds and resume; below-threshold fixes re-verified and durably recorded; the durable-store integrity concerns and the sub-agent preserve-set both dissolved by committing everything — git history is the authoritative store, and a clean tree at every dispatch removes the preserve-set need. See [artifacts/team-findings.md](artifacts/team-findings.md) and the iterative pass in [artifacts/review-findings.md](artifacts/review-findings.md).
- **Remaining open items:** 2

## Review History

- **Review mode:** lightweight (self-review).
- **Spec-aware mode:** engaged.
- **Iterations completed:** 1 — see [artifacts/review-iteration-history.md](artifacts/review-iteration-history.md).
- **Findings raised:** 2 (both major, both resolved by user input) — see [artifacts/review-findings.md](artifacts/review-findings.md).
- **YAGNI candidates:** 2 — both replaced with a strictly simpler version: the D3 clean-tree handling (F22) and the D8 preserve-set collapsed into the D10 commit cadence (F23).
- **Assumptions challenged across all passes:** confirmed the commit-before-each-dispatch cadence guarantees a clean tree at every dispatch boundary — including the recovery "Build further" path, where operator hand-edits are committed as an iteration before the dispatch — so the preserve-set guarded no remaining window.
- **Consolidations made:** D3 collapsed three sub-mechanisms (opening-commit own-path exclusion, preview enumeration, stale-artifact ask) into one commit-or-stash rule; D8's preserve-set plus post-dispatch verification collapsed into the D10 clean-tree-at-dispatch guarantee.
- **Ambiguities resolved, and how:** two operator notes directed both simplifications; applied directly.
- **Open items remaining:** 2 (OI-1, OI-2 in Open Items above; both non-blocking, unchanged by this review).
