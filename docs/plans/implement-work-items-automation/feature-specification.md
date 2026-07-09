# Feature Specification: implement-work-items Driver Automation and Resumability Hardening

Shifts the deterministic clerical work of an `implement-work-items` run — creating the record area, writing and committing every bookkeeping entry with the markers that make the run resumable, refreshing base-branch information, and reconstructing run state at every re-entry — out of the orchestrating agent and into the run's own tooling, so that on the happy path the agent uses version control only to commit an item's code, and so a resumed run restores exactly where it left off.

## Outcome

Successful use produces an `implement-work-items` run in which the orchestrating agent (the "driver") no longer hand-composes the run's clerical steps. The run's tooling creates its own record area and branch, writes and commits every bookkeeping entry (with the markers that make the run identifiable on resume and each item's baseline recoverable), refreshes and reports base-branch freshness in one bounded pass, and reconstructs run state at every re-entry as a single structured read. On the happy path the driver runs version control only to commit an item's code; the enumerated exceptions are one-time branch setup (performed by the tooling) and recovery-time tree resets (performed under the operator's confirmation).

Three kinds of run state that were previously held only in the live session — the operator's pre-work decisions, the per-item fix-round count, and the in-progress review round's findings — are recorded durably in committed artifacts ([T1](artifacts/feature-technical-notes.md#t1-resume-critical-state-lives-in-committed-artifacts)), so a resumed run restores them instead of re-asking the operator or re-deriving them from commit history. Scope is judged by the reviewer from the diff it sees and the item's stated intent, with no predicted-path list. A gate-blocking fix is applied by the driver when it is a bounded, review-named mechanical edit and dispatched to a sub-agent when it is substantive.

The automation targets the run's version-control, record-and-file, and state-discovery work. Lightweight harness affordances the operator sees, such as the run's task list, remain the driver's to maintain ([D1](artifacts/decision-log.md#d1-automate-every-deterministic-step)).

## Actors and Triggers

- **Actors**
  - **Operator** — invokes the skill, confirms the plan, supplies pre-work decisions, performs foreground builds and human reviews, and confirms any recovery-time tree reset.
  - **Driver** — the orchestrating agent running the skill's loop.
  - **Build and review sub-agents** — unattended workers the driver dispatches for a build, a fix, or a review.
  - **Run tooling** — the run's deterministic helpers: the environment detector (which refreshes base-branch information), the state-reconstruction reader, and the bookkeeping writer that also owns the run's setup and record version-control side effects.
- **Triggers** — the operator invokes `implement-work-items` on a trusted `work-items.md`, either fresh or to resume a prior run on the same file.
- **Preconditions**
  - A git repository, a validated `work-items.md`, and a Claude Code version that supports the review fan-out.
  - Before the first item on a fresh run, the working tree is clean apart from the run's own planning artifacts; stray uncommitted content is surfaced with a commit-or-stash offer so the operator resolves it, and where verification commands resolve, the suite is confirmed green so newly introduced breakage stays distinguishable from pre-existing breakage ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).

## Primary Flow

The fresh-run happy path, with the automation woven in:

1. The operator invokes the driver on a work-items file. The driver validates the plan and detects the environment in a single tooling pass that also refreshes base-branch information within a bounded deadline and reports whether the refresh succeeded, rather than detecting, then separately refreshing, then re-detecting ([D1](artifacts/decision-log.md#d1-automate-every-deterministic-step), [D3](artifacts/decision-log.md#d3-detector-refreshes-and-reports-base-freshness-itself)). The refresh is attempted only when a base must be resolved for a fresh run; a run recognized as a resume restores its base from the record and performs no refresh.
2. The driver resolves the base to branch from out of an expanded candidate set — the mainline names plus the common integration-branch names — preferring a mainline when one resolves ([D12](artifacts/decision-log.md#d12-expanded-base-branch-candidates)).
3. Before the first item, the driver confirms the pre-run preconditions stated above — the clean-tree commit-or-stash offer and the green-suite check ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).
4. On the operator's confirmation, the bookkeeping tool creates the record area, creates the run's branch, writes the opening record, and commits it together with the run's planning artifacts so the run is identifiable on resume — as one tool action, with the driver composing no directory-creation, branch-creation, or commit command ([D2](artifacts/decision-log.md#d2-bookkeeping-tool-creates-its-own-record-area), [D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).
5. For each item in run order:
   1. The bookkeeping tool records the item's start and commits that baseline, recording the item's baseline so the driver can scope the item's later changes against it ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).
   2. If the item requires a pre-work decision, the driver asks the operator once and records the decision durably before building ([D10](artifacts/decision-log.md#d10-persist-pre-work-decisions-durably)).
   3. The driver builds the item — dispatching a build sub-agent for an unattended item, or steering a foreground build with the operator — then commits the item's code itself. This code commit is the only version-control action left to the driver on the happy path; in a foreground build it includes adopting any commits the interactive skill made and committing the remainder ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).
   4. The driver verifies the committed work, then reviews it. The reviewer judges scope from the change it sees against the item's stated intent, with no predicted-path list supplied ([D7](artifacts/decision-log.md#d7-drop-expected-paths-reviewer-judges-scope-from-the-diff)).
   5. The round's review findings are written to a durable record that is committed when it is written, and the round is marked in the run record, so the fix-round count and the in-progress round's findings survive a resume ([D11](artifacts/decision-log.md#d11-durable-iteration-markers-and-committed-review-records), [D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended), [T1](artifacts/feature-technical-notes.md#t1-resume-critical-state-lives-in-committed-artifacts)).
   6. If the gate does not clear, the driver applies the fix itself when the finding names a bounded, mechanical edit, or dispatches a sub-agent when the change is substantive; either path consumes one round of the fix-cap ([D9](artifacts/decision-log.md#d9-fix-routing-bounded-to-the-driver-substantive-to-a-sub-agent)).
   7. On a clear, the bookkeeping tool records the item done and commits that entry as the last write for the item ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state), [D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended)).
6. When every item is done, the driver reports the completion summary.

## Alternate Flows and States

### Resume

- **Entry condition:** the driver is invoked on a file whose branch already carries this run's record.
- **Sequence:** the driver reconstructs run state from a single tooling pass over the committed record and branch history — which items are done, in progress, or skipped; the in-progress item's outstanding change; the fix-round count; the restored run configuration and base; and the restored pre-work decisions — rather than composing its own git and file probes ([D4](artifacts/decision-log.md#d4-state-reconstruction-is-tool-produced)). The same tool-produced reconstruction is used at every re-entry point, not only a cold resume — after a foreground hand-off and after a human review as well ([D4](artifacts/decision-log.md#d4-state-reconstruction-is-tool-produced)). The already-durable accumulated corrections and coherence approvals continue to be surfaced from their committed blocks; this reconstruction adds the pre-work decisions and the fix-round count as newly-durable state. A pre-work decision recorded for an item is restored and shown in the resume announcement the driver already makes, so the operator confirms or corrects it before the go-ahead rather than the driver judging whether the item changed; a recorded decision that no longer maps to a current item is surfaced as a reconstruction mismatch ([D10](artifacts/decision-log.md#d10-persist-pre-work-decisions-durably)). The driver announces the concrete next action and waits for the operator's go-ahead.
- **Resume integrity:** a committed terminal or lifecycle marker never precedes the artifact it attests, so a resume never sees a marker for work that is not present; the reachable partial state is a committed artifact whose terminal marker is absent, which is treated as in-progress and re-verified and re-reviewed before completion — commit presence never implies an item cleared. Any disagreement between the record and branch history is surfaced-and-asked under the default-deny rule, never silently resolved in favor of either side ([D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended)).
- **Exit:** the driver resumes at the first item that is neither done nor skipped, from the phase the record shows it left off, including the distinct "baseline recorded, decision recorded, build not yet dispatched" phase.

### No-output audit

- **Entry condition:** the next item is an audit item (declared to produce no committed code).
- **Sequence:** the item produces no committed code. Its findings are captured in the per-round durable review or confirmation record the run already writes and commits, so there is no separate report file to place or police. The item's review is a human or agent confirmation that the audit ran and its result is sound — never an unattended auto-clearing review ([D8](artifacts/decision-log.md#d8-no-output-carried-by-the-item-type)).
- **Exit:** the audit completes with an ordinary done entry, backed by the commit of the confirmation record it already produced, so a resume verifies a completed audit by the same rule it uses for any item — the backing commit resolves. There is no distinct no-commit completion state ([D8](artifacts/decision-log.md#d8-no-output-carried-by-the-item-type), [D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended), [T2](artifacts/feature-technical-notes.md#t2-audit-completion-resolves-against-its-confirmation-record-commit)).

### Gate-blocking fix round

- **Entry condition:** verification failed or the review returned a finding at or above the gate.
- **Sequence:** for a bounded edit the review named precisely (a specific location, no design or logic change), the driver applies the fix directly; for a substantive change (logic, structure, new tests) the driver dispatches a fix sub-agent. Either path re-verifies and re-reviews, and either consumes one round of the fix-cap ([D9](artifacts/decision-log.md#d9-fix-routing-bounded-to-the-driver-substantive-to-a-sub-agent)).
- **Exit:** the gate clears, or the fix-cap is exceeded and the run halts.

### Resumable stop

- **Entry condition:** the run hits a state it cannot resolve unattended, including a failure of any tool-owned step — record-area or branch creation, a bookkeeping write or its commit, a tree snapshot or assertion, the base refresh, or state reconstruction.
- **Sequence:** completed items stay committed; the bookkeeping tool fails loudly and leaves its record file unchanged on a write it cannot commit, treating the write and its commit as one atomic action; the driver surfaces the halt with its recovery menu so the operator can always take over by hand. A failed bookkeeping step is surfaced as its own class, never routed into the fix loop ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)).
- **Exit:** the run resumes on a later invocation on the same file.

## Edge Cases and Failure Modes

| Condition | Required Behavior |
|-----------|-------------------|
| Base-branch refresh fails, is partial, or exceeds its deadline | The driver surfaces that base counts may be stale and asks which base to use without a recommendation; a slow refresh folds into the same failed-refresh path as a hard failure ([D3](artifacts/decision-log.md#d3-detector-refreshes-and-reports-base-freshness-itself)). |
| The run is a resume, where the base is already fixed by the record | The base is restored from the record and no refresh is performed ([D3](artifacts/decision-log.md#d3-detector-refreshes-and-reports-base-freshness-itself)). |
| A pre-work decision was recorded, then the run is resumed | The recorded decision is restored and shown in the resume announcement for the operator to confirm or correct before the go-ahead; one that no longer maps to a current item surfaces as a reconstruction mismatch ([D10](artifacts/decision-log.md#d10-persist-pre-work-decisions-durably)). |
| Resume finds fix rounds already run for the in-progress item | The fix-round count is read from the record; a disagreement with commit history is surfaced-and-asked, not silently resolved ([D11](artifacts/decision-log.md#d11-durable-iteration-markers-and-committed-review-records), [D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended)). |
| A durable marker was written to the record file but not committed before a stop | The uncommitted write is not durable; resume reconstructs only from committed artifacts and treats the un-committed state as not-yet-recorded ([T1](artifacts/feature-technical-notes.md#t1-resume-critical-state-lives-in-committed-artifacts)). |
| A tool bookkeeping commit lands, then the tool fails before recording the baseline for the driver | Treated as a resumable stop; on re-entry the tool recognizes the already-recorded start rather than appending a duplicate baseline ([D14](artifacts/decision-log.md#d14-durable-markers-committed-last-resume-default-deny-extended)). |
| A formatter-on-save or other process dirties the tree inside the tool's assert-then-commit window | The tool stages only the exact record file it wrote (never the whole tree), so a concurrent edit elsewhere is neither swept into a bookkeeping commit nor mistaken for a failed assertion ([D5](artifacts/decision-log.md#d5-tooling-owns-all-bookkeeping-version-control-and-tree-state)). |
| The reviewer sees a change on an already-committed sibling file it judges unrelated | It raises a scope finding from the diff and intent; the operator may approve it as intended, and that approval persists across later rounds and resume. With no predicted-path list, every scope finding on a committed sibling is offered for approval rather than some being auto-excluded ([D7](artifacts/decision-log.md#d7-drop-expected-paths-reviewer-judges-scope-from-the-diff)). |
| An audit item leaves any file outside the bookkeeping area | It produced code output; the run halts with the stray file named rather than recording a no-output completion ([D8](artifacts/decision-log.md#d8-no-output-carried-by-the-item-type)). |
| Resume finds a completed audit | It is verified by the same rule as any completed item — its backing confirmation-record commit resolves — with no distinct no-commit terminal state to special-case ([D8](artifacts/decision-log.md#d8-no-output-carried-by-the-item-type), [T2](artifacts/feature-technical-notes.md#t2-audit-completion-resolves-against-its-confirmation-record-commit)). |
| A work-items file still carries a predicted-path block from an older producer | The driver neither requires nor reads it; its presence is tolerated and its absence is not a refusal ([D7](artifacts/decision-log.md#d7-drop-expected-paths-reviewer-judges-scope-from-the-diff)). |

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
|---------------------|-----------|-------------|-----------------------------------|
| Work-items producer (`plan-work-items`) | inbound | The driver consumes items; it stops requiring or reading a predicted-path block and reads no-output from the item's existing type field | The driver depends only on the item type field the producer already emits today, so this change needs no lockstep producer change; a file that still carries a predicted-path block is accepted by ignoring the block ([D7](artifacts/decision-log.md#d7-drop-expected-paths-reviewer-judges-scope-from-the-diff), [D8](artifacts/decision-log.md#d8-no-output-carried-by-the-item-type)) |
| Sub-agents | outbound | The driver hands a build or review sub-agent the path to its guidance rather than copying that guidance into the prompt | The driver reads only the driver-facing hand-off reference; the sub-agent's working guidance and required return format live in one sub-agent-facing reference passed by path ([D6](artifacts/decision-log.md#d6-two-actor-named-hand-off-references)) |
| Skill's own references and documentation | outbound | Every reference file is renamed to a consistent actor-labeled scheme, and reworking the scripts and references requires the skill's long-form documentation and cross-links to be updated in the same change | All reference files carry a consistent actor prefix, not only the sub-agent hand-off ones; doc and definition stay in sync per the repository's documentation-coverage rule ([D6](artifacts/decision-log.md#d6-two-actor-named-hand-off-references)) |

## Out of Scope

- **Review-quality process changes** — tiered review by risk, scoping fix-round re-reviews to "did the named findings land?", an automated review pass before every human hand-off, and a standing compactness lens. Coherent, but a separate feature so this one stays landable ([D13](artifacts/decision-log.md#d13-feature-scope-excludes-review-quality-items)).
- **The flat review-dispatch / nested-agent-hang harness workaround** — already a separately scoped, deferred feature.
- **De-bloating `SKILL.md` below its own line ceiling** — a separate deferred feature; whatever prose this change removes is a welcome side effect, not the goal.
- **Changing the work-items producer's output** — this feature depends only on the item type field the producer already emits and does not require the producer to stop emitting a predicted-path block; whether `plan-work-items` keeps emitting it is out of scope.
- **Style-rule / preference memory across items** — a separate feature.

## Open Items

- **OI-1:** Whether the detector's base refresh should be suppressible for an offline or slow-network fresh run, or always attempted within its deadline and reported.
  - **Resolves when:** the team weighs the operator cost of an always-attempted, deadline-bounded refresh against a suppression flag.
  - **Blocks implementation:** No — the recommended default (always attempt within a deadline, fold a slow or failed refresh into the no-recommendation base prompt) is implementable as-is; a suppression affordance can be added later.

## Summary

- **Outcome delivered:** The driver's deterministic clerical work moves into run tooling, the agent runs version control only to commit code on the happy path (with enumerated setup and recovery exceptions), and resume-critical state is recorded durably in committed artifacts.
- **Primary actors:** Operator and driver, with build/review sub-agents and the run tooling.
- **Decisions settled by evidence:** 13 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** 1 (D8 audit-findings capture) — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** junior-developer, edge-case-explorer, on-call-engineer, gap-analyzer — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** Pinned a resume-integrity ordering invariant (D14), traced the expected-paths removal to every current site, re-scoped the "agent commits only code" boundary to the happy path with enumerated exceptions, added a self-fetch deadline, and scoped resume-critical findings to the round count plus the in-progress round — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Remaining open items:** 1
- **Technical notes:** 2 — see [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md)

## Review History

- **Review mode:** lightweight (self-review).
- **Spec-aware mode:** engaged.
- **Iterations completed:** 2 (R1, R2) — see [artifacts/review-iteration-history.md](artifacts/review-iteration-history.md).
- **Findings raised:** 3 — F14 (major, R1), F15 (major, R2), F16 (minor, R2); all resolved by evidence — see [artifacts/review-findings.md](artifacts/review-findings.md).
- **YAGNI candidates:** 2, both replaced with the simpler version — R1 dropped the now-redundant no-commit audit terminal state; R2 dropped D10's driver-side "material change" detection in favor of the existing announce-and-wait-for-go-ahead gate.
- **Assumptions challenged:** R1 confirmed the no-commit marker exists only to suppress absent-commit flags on resume (now redundant given D8 + D11); R2 confirmed the resume flow already provides a human gate that makes decision-staleness detection redundant.
- **Consolidations made:** R1 unified the audit terminal state into the ordinary `done` state (two integrity rules → one); R2 merged two decision-staleness edge-case rows into one and trimmed a duplicated pre-run precondition statement.
- **Ambiguities resolved:** an audit's completion resolves against the confirmation-record commit it already produces (D8 + D11), not a new separate commit; a stale pre-work decision is caught at the operator go-ahead gate, not by a "material change" criterion.
- **Technical notes added/edited:** 1 (T2) — see [artifacts/feature-technical-notes.md](artifacts/feature-technical-notes.md).
- **Open items remaining:** 0 new (the spec's own OI-1 remains, non-blocking).
