# Decision Log: implement-work-items Driver Automation and Resumability Hardening

Records every decision settled while specifying this feature. Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the rationale, evidence, and rejected alternatives.

Evidence sources cited below are, unless noted, the current skill under `han-coding/skills/implement-work-items/` (its `SKILL.md`, `scripts/`, and `references/`) and the operator's second-run retrospective feedback (trust class: provided, operator-authored).

## Trivial decisions

These two decisions are lighter-weight than the full decisions below (a small, low-risk change each), so they carry a condensed rationale. They keep their own headings and cross-reference sections so every `D#` the spec links to resolves to an anchor.

### D2: Bookkeeping tool creates its own record area

- **Decision:** The tool creates the run's record directory itself on the opening write, rather than the driver issuing a separate directory-creation step first.
- **Rationale:** A separate driver directory-creation step is one more deterministic step for the driver to remember and get right; folding it into the tool's opening write removes that step.
- **Evidence:** `SKILL.md` Step 2.2 (the current split where the driver makes the directory and the writer would fail if it is missing).
- **Rejected alternatives:**
  - Keep the current split — the driver makes the directory, the writer fails if it is missing — rejected because it leaves the extra deterministic driver step this decision removes.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow

### D12: Expanded base-branch candidates

- **Decision:** The detector's candidate set gains the common integration-branch names, ranked below the mainline names so a mainline still wins when one resolves.
- **Rationale:** The operator requested these integration-branch names, so a fresh run in a repository that uses one can resolve it as a base; ranking them below the mainline names keeps the existing mainline-first preference intact.
- **Evidence:** The operator explicitly requested these names (user-described need), which is accepted YAGNI evidence, so the item is kept rather than deferred.
- **Rejected alternatives:**
  - Leave the candidate set unchanged — rejected because it does not resolve the integration-branch names the operator named.
  - Rank the new names above or equal to the mainline names — rejected because a mainline must still win when one resolves.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow

## Full decisions

### D1: Automate every deterministic step

- **Question:** What is the governing rule for deciding whether a run step is the driver's job or the tooling's job?
- **Decision:** Any run step that is deterministic version-control, record-and-file, or state-discovery work — directory and branch creation, record writes and their commits, base-candidate enumeration, base refresh, run-state reconstruction, and working-tree state checks — is performed by run tooling. The driver's own judgment is reserved for building, reviewing, gating, deciding, and halting. Lightweight harness affordances the operator sees, such as the run's task list, remain the driver's to maintain; they are cheap UI, not the git/record/state toil this rule targets.
- **Rationale:** The retrospective's dominant friction was that "the driver's own bookkeeping was entirely manual prose, again": long repeated Bash blocks per item for state, commit, and record writes, felt verbose and error-prone. Moving that work into tooling removes both the toil and the class of transcription errors, and shrinks the instruction surface the driver must carry. Naming the target as git/record/state work (not literally "everything") keeps the principle honest: the task-list calls are deterministic too but are cheap harness UI, so they stay with the driver rather than being force-fit into tooling.
- **Evidence:** Operator feedback ("everything that can be automated should be automated"); retrospective "What failed or was awkward" (manual bookkeeping) and "What to improve" #1.
- **Rejected alternatives:**
  - Keep the deterministic steps as driver prose but tighten the wording — rejected because it does not remove the toil or the transcription-error surface, only restates it.
  - Read "everything" literally and move the task-list updates into tooling too — rejected because they are lightweight operator-facing UI, not the git/record/state toil; forcing them into tooling adds machinery for no toil reduction (F7).
- **Linked technical notes:** —
- **Driven by findings:** F7
- **Dependent decisions:** D2, D3, D4, D5, D11
- **Referenced in spec:** Outcome, Primary Flow

### D3: Detector refreshes and reports base freshness itself

- **Question:** Should the environment detector stay strictly read-only, with the skill running the base refresh and re-invoking the detector, or should the detector perform the refresh and report freshness in one pass?
- **Decision:** The detector performs the base refresh itself, within a bounded deadline, and reports whether it succeeded, so the driver reads current base counts from a single call instead of running a detect → refresh → re-detect sequence. The refresh runs only when a base must be resolved for a fresh run; a run recognized as a resume restores its base from the record and performs no refresh. A refresh that fails, is partial, or exceeds its deadline folds into one path: the driver surfaces stale counts and asks which base to use without a recommendation.
- **Rationale:** The current three-step dance (`SKILL.md` Step 1.3 detect, Step 1.6 fetch and re-detect) exists only to keep the detector free of side effects; the driver pays for that purity with orchestration it must sequence correctly. The refresh is a safe, idempotent operation the run already performs on every fresh run, so folding it into the detector removes orchestration without adding real risk. The deadline closes the gap the review found: an unbounded network call on the critical path stalls an offline or slow-network run silently, and folding a slow refresh into the already-specified failed-refresh path handles it with no new operator-facing behavior. Recognizing a resume before refreshing avoids paying the fetch on a resume that does not need it.
- **Evidence:** Operator feedback ("`detect-driver-context.sh` should fetch itself"); `scripts/detect-driver-context.sh` (deliberately read-only, defers the fetch to the skill); `SKILL.md` Step 1.6 (the fetch-then-re-detect sequence); on-call-engineer (unbounded fetch stall) and edge-case-explorer (refresh-on-resume ordering).
- **Rejected alternatives:**
  - Keep the detector read-only — rejected because the operator asked for the opposite and the read-only purity buys nothing the run values; the refresh already happens every fresh run.
  - Attempt the refresh with no deadline — rejected because a slow or captive-portal network stalls the run silently (F6).
- **Linked technical notes:** —
- **Driven by findings:** F6
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D4: State reconstruction is tool-produced

- **Question:** At re-entry points, should the driver compose its own git and file probes to reconstruct run state, or read a structured reconstruction from tooling?
- **Decision:** Run-state reconstruction is produced by the state-reconstruction tool from the committed record and branch history, at every re-entry point — a cold resume, a return from a foreground hand-off, and a return from a human review. The driver reads one structured result — items done/in-progress/skipped, the in-progress item's outstanding change, the fix-round count, the restored configuration and base, and the restored pre-work decisions — rather than improvising probes. The tool also continues to surface the already-durable accumulated corrections and coherence approvals from their committed blocks; those are not newly persisted, only re-read.
- **Rationale:** The re-grounding routine currently instructs the driver to run its own `git status`, diff, and dependency-graph probes; that is deterministic work stated as prose, so it drifts and is re-derived every time. A tool that queries the record and history deterministically is cheaper and less error-prone, and it is the same kind of scan the run already relies on for classification. Binding it to every re-entry site, not only a cold resume, honors the operator's "other state discovery routines" — the routine is invoked after a foreground hand-off and after a human review as well.
- **Evidence:** Operator feedback ("re-grounding procedure and other state discovery routines should use shell scripts to query git log and progress.md instead of instructing agent to come up with its own probes"); `references/re-grounding-routine.md` (agent-improvised probes, invoked from `foreground-handoff-protocol.md` and `human-review-capture.md` as well); `scripts/scan-run-history.sh` (already reconstructs per-item state deterministically); gap-analyzer GAP-002.
- **Rejected alternatives:**
  - Keep the prose routine but list exact commands — rejected because it still leaves the driver assembling and interpreting probe output every re-entry, the exact toil the operator flagged.
  - Convert only the cold-resume site — rejected because the same routine runs at two other re-entry points that would keep improvising (F7).
- **Linked technical notes:** —
- **Driven by findings:** F7
- **Dependent decisions:** D10, D11
- **Referenced in spec:** Resume

### D5: Tooling owns all bookkeeping version control and tree state

- **Question:** How much version-control work should move into the bookkeeping tool, and what stays with the driver?
- **Decision:** The bookkeeping tool owns every version-control side effect of run setup and the record: it creates the record area and the run's branch, writes each record entry, commits each bookkeeping write — treating the write and its commit as one atomic action that either lands both or leaves the record file unchanged, staging only the exact record file it wrote — with the markers that make the run resumable and each item's baseline recoverable, and snapshots and asserts the working-tree state it expects. On the happy path the driver runs version control itself only to commit an item's code (which in a foreground build includes adopting the interactive skill's own commits and committing the remainder). The enumerated non-happy-path exceptions are recovery-time tree resets — on skip, on a reddening below-threshold fix, and on a resume discard — which the driver performs only under the operator's confirmation. A failure of any tool-owned step halts through the recovery menu with completed work preserved, so the operator can always take over; a failed bookkeeping step is its own class and is never routed into the fix loop. Before the first item on a fresh run, the driver still surfaces stray uncommitted content with a commit-or-stash offer and confirms a green verification suite where one resolves.
- **Rationale:** The retrospective shows the driver hand-building every bookkeeping commit and its trailers and re-asserting the clean tree repeatedly, one set per item. Concentrating those side effects in the tool removes the per-item boilerplate, keeps the resume markers correct by construction, and spares the driver from re-verifying the tree every step. The operator's boundary ("under happy path agent should need git only for committing code") is honored precisely by scoping the claim to the happy path and enumerating the setup and recovery exceptions the review surfaced, rather than overclaiming an absolute. The atomic write-and-commit and narrow staging close the torn-write and concurrent-edit windows the review found; the commit-or-stash offer and green-suite gate are operator-facing pre-run behaviors that must not vanish into a silent tool assertion.
- **Evidence:** Operator feedback (point 5: "write-run-record.sh can perform commit maintenance itself … the same script can keep track of git worktree state … agent should need git only for committing code"); `SKILL.md` Steps 2.2, 3.1, 3.4, and the skip/reset paths (driver-composed commits, branch creation, tree resets, and clean-tree assertions), Step 1.8 (commit-or-stash offer, green-suite gate); `references/durable-record-protocol.md` (commit model and trailers); junior-developer, on-call-engineer, edge-case-explorer (boundary leaks and atomicity).
- **Rejected alternatives:**
  - Tool writes record text only; the driver still runs every commit — rejected because it leaves the commit-orchestration prose and the transcription-error surface intact; the operator asked for the tool to perform commit maintenance.
  - Tool also stages and commits the item's code — rejected because the operator explicitly reserves the code commit for the driver; the item's real work stays under direct control.
  - State the boundary as an absolute ("only to commit code, ever") — rejected because branch setup and recovery resets are real version-control actions the absolute would contradict; scoping to the happy path with enumerated exceptions is accurate (F3).
- **Linked technical notes:** —
- **Driven by findings:** F3
- **Dependent decisions:** D2, D11, D14
- **Referenced in spec:** Outcome, Actors and Triggers, Primary Flow, Resumable stop, Edge Cases and Failure Modes

### D6: Two actor-named hand-off references

- **Question:** How should the sub-agent hand-off references be structured, and how should the reference files be named?
- **Decision:** The sub-agent hand-off collapses to two references with names that state which actor each serves. The driver reads one **driver-facing** reference that specifies how to compose each dispatch (which run-scoped values to fill in) and how to judge the return trustworthy (the sections it parses and the halt conditions). The sub-agent's full working guidance and required return format live in one **sub-agent-facing** reference that the driver passes to the worker by path and never reads itself. Beyond the hand-off pair, every reference file in the skill is renamed to a consistent actor-labeled scheme (driver-facing versus sub-agent-facing), so the naming is uniform across the whole `references/` directory, not only the hand-off files.
- **Rationale:** Today the driver reads `sub-agent-instructions.md`, copies the shared baseline and a payload verbatim, and also copies a separate return-contract file into the prompt — reading several sub-agent-facing files and stitching them together. Splitting cleanly by actor lets the driver read only what it needs to dispatch and parse, and lets the worker read its own guidance, removing the copy-and-stitch step and the file sprawl. The operator asked to rename references generally and make naming consistent, so the scheme covers all reference files (the driver-facing `durable-record-protocol`, `no-output-completion`, `re-grounding`, `foreground-handoff`, and `human-review-capture` included), not just the hand-off trio.
- **Rationale (naming):** The skill's own prose already calls the orchestrator the "driver"; keeping that word (rather than switching to "orchestrator") avoids a second name for the same actor.
- **Evidence:** Operator feedback (point 6: "one reference for orchestrator that instructs how to write sub-agent's prompt and read its output, and another reference that contains all guidance for sub-agent … rename our reference files to clearly label which file is intended for which actor, and make naming consistent"); the current eight reference files; gap-analyzer GAP-003.
- **Rejected alternatives:**
  - One shared reference for both actors — rejected because it forces the driver to read sub-agent working guidance it does not need, the sprawl the operator flagged.
  - Rename only the three hand-off files — rejected because the operator asked for consistent naming across the references, and a half-renamed directory is the inconsistency being removed (F7).
  - Switch the actor's name to "orchestrator" — rejected because the skill's existing prose says "driver"; two names for one actor is the drift being removed.
- **Linked technical notes:** —
- **Driven by findings:** F7
- **Dependent decisions:** —
- **Referenced in spec:** Coordinations

### D7: Drop expected-paths; reviewer judges scope from the diff

- **Question:** How should the driver check that an item's change stayed in scope, given repeated struggles with the path-based check?
- **Decision:** The expected-paths mechanic is removed from the driver's own use at every site. The driver no longer requires the predicted-path block as a field (its absence is not a refusal), no longer reads it, and no longer passes it to a reviewer. Scope is judged by the reviewer from the change it actually sees against the item's stated intent: a change that reaches beyond the item's work is a scope finding tiered by how far it reaches. The coherence-approval affordance survives — it keys on a scope finding on an already-committed sibling, not on a path list — so the operator can still approve an intended sibling edit and have that approval persist across rounds and resume; because there is no longer a predicted-path exclusion, every scope finding on a committed sibling is offered for approval rather than some being auto-excluded. A file that still carries the block from an older producer is tolerated (ignored).
- **Rationale:** The filepath-based scope check has been a recurring source of friction across runs. A reviewer already reads the diff; asking it to judge scope from what it sees plus the item's intent is both simpler and more accurate than maintaining a predicted list that is "a hint, not a boundary" anyway. The review confirmed the mechanic touches several sites (the required-field validation, the no-output guards, the coherence keying, the review payload placeholder and scope section, and the human-review orientation), so "drop the entire mechanic" is applied to each: validation stops requiring it, no-output moves to the item type (D8), coherence re-keys on the finding, the dispatch stops supplying it, and the human-review path orients by the diff and intent. Existing files that still carry the block are tolerated, so the change is backward-compatible without a producer change.
- **Evidence:** Operator feedback (point 7: "drop the entire expected-paths mechanic, instead instruct review agent to judge scope itself based on diff that it sees"); `references/review-verdict-contract.md` §Scope ("Expected paths are a hint, not a boundary"); `SKILL.md` Steps 1.5, 3.3 Gate (coherence spillover); `references/sub-agent-instructions.md` (`{expected-paths}` placeholder), `references/human-review-capture.md` (human orientation by expected paths); junior-developer JD#1–6, gap-analyzer GAP-004.
- **Rejected alternatives:**
  - Keep expected-paths but relax enforcement — rejected because the mechanic itself is the friction; a hint that must still be produced, validated, and passed is cost without a boundary.
- **Linked technical notes:** —
- **Driven by findings:** F4
- **Dependent decisions:** D8
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes, Coordinations

### D8: No-output carried by the item type

- **Question:** With expected-paths gone, how does the driver detect a no-output item, given that `Expected paths: None` was the current signal, and where do an audit's findings go?
- **Decision:** No-output is carried by the item's existing type field: an audit item produces no committed code. Its findings are captured in the per-round durable review or confirmation record the run already writes and commits, so there is no separate report file to place, name, or police. The audit's review stays a human or agent confirmation that the audit ran and its result is sound, and is never an unattended auto-clearing review — that current refusal survives, re-keyed on the item type instead of on `Expected paths: None`. An audit that leaves any file outside the run's bookkeeping area produced code output and halts with the stray file named. Because that confirmation record is already committed, the audit completes with an ordinary done entry backed by its commit — there is no distinct no-commit terminal state, and none of the separate no-commit reconstructed-state, integrity row, or completion/halt special-casing the current skill carries for it.
- **Rationale:** The item type field already exists in the work-item format the producer emits and the driver validates today, so keying no-output on it needs no new field and no producer change — resolving the mechanics-leak tension the review raised (depending on a producer literal while declaring the producer out of scope). Capturing the audit's findings in the existing review/confirmation record (the operator's steer, refined) preserves durable findings with zero new machinery and sidesteps the stray-vs-intended, who-commits, and namespace ambiguities that a separate report file under the bookkeeping area would introduce (a broken write would be indistinguishable from an intended one). This decouples the two concerns the predicted-path block conflated: no-output (now the item type) and scope (now the reviewer's judgment, D7).
- **Evidence:** User input (audit-findings-capture question — "In the durable review/confirmation record"); operator's original steer ("Audit can write findings report to .implement-work-items, maybe?"); `references/no-output-completion.md`, `references/durable-record-protocol.md` §Exclusion and §Integrity, `SKILL.md` Step 1.5 (the `Expected paths: None` guards being replaced, including the AFK-review-on-audit refusal); junior-developer JD#2/#3/#7/#8/#9, edge-case-explorer EC#6/#10.
- **Rejected alternatives:**
  - A dedicated audit-report file under the bookkeeping area with an attestation — rejected (by the user) because a failed or garbage write is filesystem-indistinguishable from an intended report, and it adds a path convention to police; the review/confirmation record already carries the findings durably.
  - A dedicated explicit no-output field (e.g., `Produces output: no`) — rejected because the existing item type field is sufficient, so a second field is redundant.
  - Infer no-output from an empty diff — rejected because a broken audit that produced nothing would be indistinguishable from an intentional no-output audit.
  - Keep a distinct no-commit-done terminal marker for audits — rejected because committing each round's confirmation record (D11) already gives every audit a committed artifact, so a separate no-commit completion state is redundant; dropping it also retires the `done-no-commit`/`no-commit-done` reconstructed-state-versus-token naming split that repeatedly read as a possible bug (F14).
- **Linked technical notes:** T2
- **Driven by findings:** F5, F14
- **Dependent decisions:** —
- **Referenced in spec:** No-output audit, Edge Cases and Failure Modes, Coordinations

### D9: Fix routing — bounded to the driver, substantive to a sub-agent

- **Question:** When a gate does not clear, should the driver apply the fix itself or dispatch a sub-agent, given that dispatching for a one-line change is costly but having the driver make many changes is also costly?
- **Decision:** The driver applies the fix itself when the finding names a bounded, mechanical edit (a specific location, no design or logic change); it dispatches a fix sub-agent when the change is substantive (logic, structure, or new tests). Either path re-verifies and re-reviews, and either consumes one round of the fix-cap, so a small driver-applied fix cannot loop unbounded.
- **Rationale:** The current instructions leave it ambiguous — below-threshold fixes are driver-applied while gate-blocking fixes always dispatch — so a one-line gate-blocking fix pays full sub-agent cost. A size-and-precision rule matches cost to the work while keeping the sub-agent's skill-guided rigor for substantive changes. Counting both paths against the cap closes the escape hatch where driver-applied fixes would loop for free.
- **Evidence:** Operator feedback (point 8: "we don't have clear instructions about whether orchestrator handles findings itself or delegates to sub-agent"); `SKILL.md` Step 3.3 (below-threshold fixes driver-applied; the not-cleared branch dispatches) and the fix-cap counting "automated (AFK) fix rounds only".
- **Rejected alternatives:**
  - Always dispatch a sub-agent — rejected because it pays full dispatch cost for a one-line fix, the exact cost the operator flagged.
  - The driver applies every fix directly — rejected because substantive fixes lose the sub-agent's skill-guided rigor and load the driver's context with heavy edits.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Gate-blocking fix round

### D10: Persist pre-work decisions durably

- **Question:** Where is an operator's pre-work decision (for a `Requires pre-work decisions: yes` item) held?
- **Decision:** A pre-work decision is recorded durably in the committed run record when the operator gives it, before the build. A resumed run restores the recorded decision and shows it in the resume announcement it already makes, so the operator confirms or corrects it before the go-ahead — the driver does not adjudicate whether the item "materially changed". A recorded decision that no longer maps to a current item (renumbered or removed) surfaces as a reconstruction mismatch under the existing default-deny rule. The resume reconstruction names a distinct "baseline recorded, decision recorded, build not yet dispatched" phase.
- **Rationale:** Today the decision is "held in the running session," so a stop-and-resume loses it, making a clean resume impossible — the driver would either re-ask or, worse, proceed without it. Persisting it is the only way resume can restore the exact input the build depended on. Because D10 is the first restored state that directly steers a build (rather than merely suppressing a review finding), the review raised the staleness stakes: a decision keyed to an item that later changed must not silently drive a build. A later simplicity pass found the leanest way to hold that safety is not driver-side "material change" detection (which needs a fuzzy criterion and a new branch) but surfacing the restored decision in the resume announcement the driver already makes and waits on, so the operator catches a stale decision at the existing go-ahead gate (F15).
- **Evidence:** Operator feedback (point 9: "we don't durably save decisions user made before item (require decision: yes), which makes clean resume impossible"); `SKILL.md` Step 3.2 ("hold it in the running session and proceed"), Halt Procedure (already anticipates mid-run item-text edits), `references/durable-record-protocol.md` §Integrity (default-deny); edge-case-explorer EC#8/#12/#13.
- **Rejected alternatives:**
  - Re-ask the operator to re-decide on resume — rejected because it is not a clean resume; the operator must reconstruct a decision they already made, and any divergence silently changes the build.
  - Restore a recorded decision silently, without surfacing it — rejected because an item edited since the decision could be built on a stale decision unnoticed (F9).
  - Detect "material change" driver-side and surface-and-ask — rejected because it adds a fuzzy criterion and a detection branch; the existing announce-and-wait-for-go-ahead gate already lets the operator catch a stale decision once it is shown, so the detection is redundant complexity (F15).
- **Linked technical notes:** T1
- **Driven by findings:** F9, F15
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Resume, Edge Cases and Failure Modes

### D11: Durable iteration markers and committed review records

- **Question:** Should each build/fix iteration be marked in the ledger, and should each round's review record be committed between rounds?
- **Decision:** Each build and fix iteration is recorded durably in the run record, and each round's review findings are written to a durable record that is committed when it is written. The resume-critical state is the fix-round count plus the in-progress round's committed review record: a resumed run reads the fix-round count from the record rather than re-deriving it from commit trailers, and reads the in-progress round's findings from its committed record. Records from earlier rounds are retained as history, not consumed on resume (the fixer reads only the current round). A disagreement between the recorded count and commit history is surfaced-and-asked, not silently resolved in favor of either.
- **Rationale:** Today the fix-round counter lives only in the session and the per-round review records may sit uncommitted, so a resume must re-derive the round count from commit history and cannot see the current round's findings — the operator's "we don't mark iterations in ledger, making restart procedure harder than necessary. do we even commit review findings in between?" Recording iterations and committing each round's record answers that (yes, commit them) and makes the restart deterministic. The review scoped the claim: the run is serial and the fixer reads only the current round, so persisting the count and the in-progress round is what resume needs; keeping older rounds' records is a nearly-free byproduct of committing each when written, not a separately-justified requirement. A later review pass found this decision also unlocks a simplification: because every audit's confirmation record is now committed, an audit no longer needs a distinct no-commit terminal state (D8, F14).
- **Evidence:** Operator feedback (point 10); `SKILL.md` Step 3.3 (per-item loop state "lives in the running session"); `references/durable-record-protocol.md` §Commit model; `references/human-review-capture.md` ("The fix agent reads only the current round"); on-call-engineer OCE#5, junior-developer JD#18.
- **Rejected alternatives:**
  - Keep re-deriving the round count from `Fixup` trailers — rejected because it is exactly the harder-than-necessary restart the operator named, and it cannot recover the current round's findings.
  - Justify committing every round's findings by "a resumed fix round needs all of them" — rejected because the fixer reads only the current round; the resume-critical part is the count plus the in-progress round (F8).
- **Linked technical notes:** T1
- **Driven by findings:** F8
- **Dependent decisions:** D14, D8
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D13: Feature scope excludes review-quality items

- **Question:** Should this feature also include the review-quality process changes the retrospective proposed?
- **Decision:** No. This feature is the automation and resumability hardening — the plumbing. Tiered review by risk, scoping fix-round re-reviews to confirmation-only, an automated review pass before every human hand-off, and a standing compactness lens are a separate feature.
- **Rationale:** The operator scoped this pass to the automation/plumbing points. The review-quality items are coherent but independent, add behavioral surface, and would slow this change landing. Keeping them separate keeps this feature reviewable and shippable.
- **Evidence:** User input (scope question, "Stay focused on the 11 points"); retrospective "What to improve" #3–#6 (the review-quality cluster).
- **Rejected alternatives:**
  - Fold the review-quality items into this feature — rejected by the operator to keep this change landable.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Out of Scope

### D14: Durable markers committed last; resume default-deny extended

- **Question:** In what order are an item/round's several committed artifacts written, and how does resume behave for a mid-step death, now that the terminal write and the code commit come from different actors?
- **Decision:** A durable marker (a lifecycle entry, an iteration marker, or a terminal entry) is committed only after the artifact it attests is committed — the code commit and the review record land before the marker that records them, and the terminal entry is the last write for the item. Consequently a resume never sees a marker for work that is not present; the only reachable partial state is a committed artifact whose marker is absent, which is treated as in-progress and re-verified and re-reviewed before completion. The existing default-deny integrity rule — commit presence never implies an item cleared, and a record-versus-history disagreement is surfaced-and-asked — extends to the new durable state (fix-round markers and pre-work decisions), so the record is never silently trusted over history or vice versa. With an audit's done now backed by its confirmation-record commit (D8), the same "done is safe when its backing commit resolves" rule covers audits and code items alike, so there is no separate no-commit integrity case.
- **Rationale:** The review's root finding was that three independently-committed artifacts per round (code commit, review record, marker) with no stated order leave a combinatorial set of partial states on a mid-step death, several of which would let a resume proceed on a wrong assumption (re-review unchanged code, skip a known finding, or accept an unverified item). Pinning "marker last, after the artifact it attests" collapses that set to the single safe partial state and matches the existing rule that the terminal entry is the last write per item. Extending default-deny to the new state keeps the existing safety net (which today guards the `done` entry against a missing commit) from being defeated by the new markers.
- **Evidence:** `references/durable-record-protocol.md` §Commit model ("the terminal `Log:` entry … is the last write per item") and §Integrity (default-deny table); `SKILL.md` Step 2.3 "Ledger and history disagree"; edge-case-explorer EC#1/#2/#3/#5/#11, on-call-engineer OCE#3.
- **Rejected alternatives:**
  - Leave the order unspecified and enumerate every partial state's recovery — rejected because it is a larger, more error-prone spec surface than pinning the order once, which makes most partial states unreachable.
  - Trust the record's count over history on a disagreement — rejected because it defeats the existing default-deny net that protects against a missing or filtered commit.
- **Linked technical notes:** T1, T2
- **Driven by findings:** F1, F14
- **Dependent decisions:** —
- **Referenced in spec:** Resume, Edge Cases and Failure Modes
