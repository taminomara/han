# Test Plan: implement-work-items Driver Automation — bash-harness coverage for D3/D5/D7/D8/D10/D11/D12/D14

## Scope

Analyzed: `han-coding/skills/implement-work-items/scripts/write-run-record.sh`,
`detect-driver-context.sh`, `scan-run-history.sh`, and their `*.test.sh` harnesses
(ground truth for today's behavior and today's test conventions), against the behavior
the feature specification and decision log commit the changed scripts to. Read in full:
`docs/plans/implement-work-items-automation/artifacts/.discovery-notes.md`,
`feature-specification.md`, `artifacts/feature-technical-notes.md` (T1, T2),
`artifacts/decision-log.md` (D1–D14), `SKILL.md` (Steps 1–4, Halt Procedure),
`references/durable-record-protocol.md`, and
`docs/research/implement-work-items-second-run-feedback.md` (the dogfooding hazard
example). No project-wide test suite or CI exists; the three `*.test.sh` harnesses are
the only automated gate for this change. No branch name was supplied.

## Summary

Examined the three-script bash harness suite for `implement-work-items` against the six
behavior changes the spec/decision-log commit to (D3, D5, D7/D8, D10/D11, D12, D14/T1/T2).
Today's 61 harness cases cover only the pre-change contract (writer touches a bare file with
no git; scanner reads a working-tree-fallback ledger; `no-commit-done` is a first-class
token) — every changed behavior is currently untested because the code it targets does not
exist yet. D7 (reviewer-judges-scope-from-diff) is a sub-agent-prompt behavior with no
script entry point, so it is out of the script harness's reach entirely.

| Priority | Count |
|----------|-------|
| High     | 9     |
| Medium   | 6     |
| Low      | 2     |
| Skipped  | 5     |

Full analysis written to: /home/taminomara/p/han/docs/plans/implement-work-items-automation/artifacts/test-plan.md

## Coverage Assessment

The existing suite is thorough for what it covers: `write-run-record.test.sh` (20 cases)
exhaustively guards the append-only grammar, atomicity (temp-then-mv, mid-stream-failure,
unwritable-dir), and injection defenses (newline/control-char in every free-text arg).
`scan-run-history.test.sh` (26 cases) exhaustively guards classification, block-aware Log
parsing, path normalization/traversal-confinement, and a writer-reader round-trip.
`detect-driver-context.test.sh` (14 cases) exhaustively guards the candidate-behind/ahead
matrix and the read-only fetch-status contract. All three follow one convention: pure bash,
`ok()`/`fail()` counters, a `mktemp -d` sandbox with a `trap ... EXIT` cleanup, and (for the
two git-touching scripts) a shared `mkrepo`/`cempty` fixture pair duplicated verbatim in
each file.

That coverage is now the pre-change baseline, not the post-change contract. Every one of
the six behavior changes moves work into these scripts that the current harnesses were
explicitly built to assume away — most visibly, `write-run-record.test.sh`'s own header:
"The writer touches a plain file, so the sandbox is a tmp dir with no repo." D5 makes that
sentence false. The harnesses will need real rewrites (not additive-only extension) for
the writer, and substantial additions for the detector and the scanner. D7 has zero
script-level entry point — it is exclusively prompt/sub-agent behavior — so no bash harness
can cover it; that gap is inherent to the design, not a coverage lapse.

## Findings

**T1: Writer creates its own record area, branch, and commits the opening write atomically**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` `init` subcommand (spec D2, D5; decision-log D5 "creates the record area and the run's branch ... writes the opening record, and commits it ... as one tool action")
- **Gap type:** Untested (the behavior does not exist in the current script; today's `init` only writes a plain file, never touches git — `write-run-record.test.sh:1-5` states this explicitly)
- **Test approach:**
  - **Behavior:** Given a git repo with a resolved base ref, `init` creates the run's branch off that base (or switches to it if it already exists, per SKILL.md 2.2 step 1), creates the record directory, writes the opening `progress.md`, and commits the record together with any already-staged planning artifacts as a single commit — with no separate directory-creation or branch-creation command from the caller.
  - **Stubs:** None (a query stub isn't meaningful here — the collaborator is a real git repo, which is the fixture, per the `mkrepo`/`cempty` convention in `detect-driver-context.test.sh:29-30` and `scan-run-history.test.sh:30-31`).
  - **Input/Action:** `mkrepo` a base branch with one commit; call `init` with the new branch name and base; also cover "branch already exists" (call `init` again pointed at the same branch/record path scenario the resume path would hit).
  - **Expected output:** the record file exists with the exact opening content (same assertion style as the current case 1); `git branch --show-current` (or `git rev-parse --abbrev-ref HEAD`) reports the new branch; `git log` shows exactly one new commit on top of base whose tree contains the record (and, when planning artifacts were pre-staged, contains those too).
  - **Expected commands:** the commit exists (an outgoing command from the script) — assert its existence and tree content, not its exact call sequence internally.
- **Brittleness assessment:** Durable — asserts observable git state (branch exists, one commit, correct tree contents), not internal call order. Watch for over-specification: do not assert the exact sequence of `git checkout -b` vs `git switch -c` the script uses internally; only assert the resulting branch/commit state, matching how `detect-driver-context.test.sh` asserts final `behind/ahead` counts rather than which rev-list invocation produced them.

**T2: Writer's atomic write-and-commit — a failed commit leaves the record file unchanged**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` (all subcommands now touching git per D5; decision-log D5 "treating the write and its commit as one atomic action that either lands both or leaves the record file unchanged"; spec Resumable stop: "the bookkeeping tool fails loudly and leaves its record file unchanged on a write it cannot commit")
- **Gap type:** Untested (today's atomicity tests, cases 8/8b/14/20 in `write-run-record.test.sh`, only guard the temp-file-then-mv write; none exercise a failing commit, because today's writer never commits)
- **Test approach:**
  - **Behavior:** When the git commit step fails (e.g., a `pre-commit` hook rejects it), the record file on disk is unchanged from before the call, and the command exits non-zero — the write and its commit are one atomic unit, not sequential steps that can partially land.
  - **Stubs:** A hook-shim is the natural test double here — a real `.git/hooks/pre-commit` (or `commit-msg`) script that exits non-zero, exactly the "sabotaged PATH binary" pattern already used in `detect-driver-context.test.sh:184-191` ("a fake `git` on PATH that fails on any `fetch` invocation") — this is not a mock-the-mock risk because the assertion is on the resulting file/git state, not on whether the hook was invoked with particular args.
  - **Input/Action:** Install a rejecting hook in the sandbox repo; call `log` (or `block`) to append an entry.
  - **Expected output:** exit non-zero; `cat` the record file and diff against its pre-call content (byte-identical, same pattern as case 8b's `eq "original record intact..."`); no stray commit was created (`git log` commit count unchanged); no stray temp artifact (reuse the `find ... -name '.write-run-record.*'` check from case 8/20).
  - **Expected commands:** none to verify as a positive outcome — the point of the test is the *absence* of a landed commit.
- **Brittleness assessment:** Durable. This is the single highest-value new writer test: it is the concrete mechanism behind the Resumable-stop spec clause and directly protects against a torn write/commit, the exact hazard D5's rationale names. No mock-count risk since nothing is mocked — a real hook is exercised and only the resulting repo/file state is asserted.

**T3: Writer stages only the record file it wrote, never a concurrent unrelated edit**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` commit step (spec Edge Cases: "A formatter-on-save or other process dirties the tree inside the tool's assert-then-commit window ... The tool stages only the exact record file it wrote (never the whole tree)"; decision-log D5)
- **Gap type:** Untested (new behavior; no current test touches staging scope because no current commit exists)
- **Test approach:**
  - **Behavior:** If an unrelated file in the working tree is dirty (or is created) at call time, a subsequent write-and-commit call commits only the record file's own change — the concurrent unrelated file stays uncommitted and untouched afterward.
  - **Stubs:** None — real repo fixture.
  - **Input/Action:** In the sandbox repo, after an `init`, dirty an unrelated tracked file (or add a new untracked one) in the working tree, then call `log` to append an entry.
  - **Expected output:** the new commit's tree/diff contains only the record file's change (`git show --stat` or `git diff --name-only HEAD~1 HEAD` lists exactly the record path); the unrelated file remains uncommitted (`git status --porcelain` still reports it dirty/untracked) after the call succeeds.
  - **Expected commands:** the commit itself, scoped to the one path — assert via `git diff --name-only`, not by asserting a `git add <path>` call was made with specific args (that would be mock-the-mock; the observable outcome is the committed tree).
- **Brittleness assessment:** Durable — asserts the committed tree's file list, a stable observable outcome regardless of whether the implementation uses `git add <path>` or `git commit -- <path>` internally.

**T4: Writer records and returns the item's baseline ref on the start-of-item commit**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` `log start-of-item` path (spec Primary Flow 5.1: "recording the item's baseline so the driver can scope the item's later changes against it"; `durable-record-protocol.md:78-80`, the `Implement-Work-Items-Baseline: <W-N>` trailer)
- **Gap type:** Untested (new trailer/return value; no current test asserts any commit trailer since the writer commits nothing today)
- **Test approach:**
  - **Behavior:** Logging a `start-of-item` entry commits the record with an `Implement-Work-Items-Baseline: <W-N>` trailer on that commit, and the script's output (or exit communication channel — whatever plan-implementation designs, e.g. printing the ref to stdout) lets the caller recover that commit as the item's `scope-baseline`.
  - **Stubs:** None — real repo fixture.
  - **Input/Action:** `init`, then `log start-of-item W-1`.
  - **Expected output:** `git log --format='%(trailers:key=Implement-Work-Items-Baseline,valueonly)' -1` on the new commit equals `W-1`; whatever the script emits as "the baseline ref" resolves via `git rev-parse` to that same commit.
  - **Expected commands:** the commit with the correct trailer — assert trailer content, not the exact `git commit -m ... -m ...` invocation shape.
- **Brittleness assessment:** Durable — trailers are the committed, documented contract (`durable-record-protocol.md` Commit trailers section) that `scan-run-history.sh` already parses by exact key; testing trailer presence/value is testing the load-bearing interface, not an implementation detail.

**T5: Writer commits the terminal (`done`) entry as the last write, distinct from the code commit**
- **Priority:** Medium
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` `log done` path (spec Primary Flow 5.7; D14 "the terminal entry is the last write for the item")
- **Gap type:** Untested (new; today's `log done` test, case 2, only asserts file content, not commit ordering)
- **Test approach:**
  - **Behavior:** After a prior commit exists on the branch representing the item's code (simulated by the test committing a dummy file with `Implement-Work-Items-Item: W-1`), calling `log done W-1` produces a *separate* bookkeeping commit (never mixed into the code commit) that is chronologically after it.
  - **Stubs:** None — real repo fixture; the "code commit" is simulated directly with a plain `git commit` in the test, since the code-commit itself is the driver's job (D5), not the writer's — this correctly keeps the writer test from mocking away the writer's own behavior.
  - **Input/Action:** `init`; commit a fake code change with the item trailer; call `log done W-1`.
  - **Expected output:** two distinct commits exist after `init`; the later one's tree changes only the record file; `git log --format='%(trailers:key=Implement-Work-Items-Run,valueonly)'` on that later commit is non-empty and its item-trailer is absent (bookkeeping commits never carry the item trailer, per `durable-record-protocol.md:72-73`).
- **Brittleness assessment:** Durable, but keep the assertion to "record commit strictly follows the code commit and touches only the record path" — do not assert exact trailer message wording beyond the documented trailer keys.

**T6: Audit completion (`done`) resolves via its confirmation-record commit — round-trip proves parity with a code item (D8/T2)**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox; extends `scan-run-history.test.sh`'s existing round-trip pattern, case 22)
- **Entry point:** `scripts/scan-run-history.sh` items reconstruction (spec No-output audit exit; T2 "the confirmation-record commit is made the audit's resolving commit ... carries the same item-resolution marker a code item's commit carries"); `scripts/write-run-record.sh` (writes the confirmation-record commit and the terminal entry)
- **Gap type:** Untested (new resolution path; today's scanner resolves `done` only via the code-item trailer, and the "no-commit-done ... valid as-is, carries no commit by design" rule in `durable-record-protocol.md:118` is exactly what T2 retires)
- **Test approach:**
  - **Behavior:** For an audit item, write the confirmation record and commit it carrying the item-resolution trailer (whatever marker plan-implementation chooses per T2 — "the exact marker or trailer reused is plan-implementation's to choose"), then write and commit the `done` terminal entry. The scanner then reports that item as `done resolved` — the identical resolution path and identical output shape a code item's `done resolved` produces, using the same reconstruction rule (`ITEM_RESOLVED` keyed off the trailer, `scan-run-history.sh:154-158,203-208`), not a separate no-commit code path.
  - **Stubs:** None — real repo fixture; drive both the writer and reader together (round-trip), the same pattern as `scan-run-history.test.sh` case 22.
  - **Input/Action:** Commit an audit's confirmation record with the resolving trailer; `log start-of-item`/`log done` via the writer; run the scanner.
  - **Expected output:** items block shows `W-<n> done resolved` (not a distinct `done-no-commit` state) — assert this against the *same* code path/output shape as a deliverable item's resolved `done`, i.e. a single shared assertion helper, not two divergent ones.
  - **Expected commands:** none beyond the commits already asserted as outputs.
- **Brittleness assessment:** Durable and high-value — this is the one test the prompt specifically asks for ("round-trip tests prove a completed audit resolves the same way a code item does"). Low brittleness because it asserts final reconstructed state (`done resolved`), which is exactly what today's case 19 already asserts for code items — extending the same assertion to the audit path, rather than inventing new internal-shape assertions.

**T7: `no-commit-done` token and `done-no-commit` state no longer appear anywhere in writer, scanner, or a produced record (D8/F14 removal)**
- **Priority:** High
- **Test level:** Unit (bash harness, both scripts)
- **Entry point:** `scripts/write-run-record.sh` `cmd_log` token validation (`write-run-record.sh:97-100`); `scripts/scan-run-history.sh` token-to-state mapping (`scan-run-history.sh:184-198`)
- **Gap type:** Untested as a negative assertion (today's tests, e.g. `write-run-record.test.sh` case 2, case 9, and `scan-run-history.test.sh` cases 12/13/22, *positively* exercise `no-commit-done`/`done-no-commit` as valid — every one of those assertions must invert)
- **Test approach:**
  - **Behavior:** The writer's `log` subcommand accepts exactly `start-of-item|done|skip` (three tokens, not four) and rejects `no-commit-done` the same way it rejects any other bogus token (fail loud, record unchanged) — same assertion shape as the current bogus-token case 3. The scanner's token-to-state case statement recognizes only the three tokens; a ledger line using `no-commit-done` is either unrecognized (falls through, contributing no item) or the scanner treats it as any other malformed lifecycle line, consistent with block-gate tests like case 25.
  - **Stubs:** None — real repo fixture for the scanner half; tmp-dir for the writer half (writer still needs no git for pure grammar-rejection checks... except D5 now means `log` runs inside a repo; adjust the fixture accordingly, see T9 below on harness-wide sandbox migration).
  - **Input/Action:** Writer: call `log <rec> no-commit-done W-2`. Scanner: commit a ledger whose `Log:` block contains a `- no-commit-done: W-2` line, run the scanner.
  - **Expected output:** writer exits non-zero, record unchanged (mirror case 3's assertion exactly, token substituted). Scanner: `W-2` does not appear as `done-no-commit` in the items block (either absent entirely or surfaced however the updated grammar treats an unrecognized token — pin to whatever plan-implementation specifies, but the *removed* state string must never appear).
  - **Expected commands:** none.
- **Brittleness assessment:** Durable — this is a straightforward token-set narrowing, mirroring the exact test shape (case 3 / case 12) already in the suite. Low risk of over-specification since it reuses existing assertion patterns verbatim with the token swapped.

**T8: Pre-work decision commits before the item's build begins and survives a simulated stop/resume (D10)**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox; writer + scanner round-trip)
- **Entry point:** `scripts/write-run-record.sh` new `block`/`log` grammar for a decision entry (spec Primary Flow 5.2, D10; T1 "a pre-work decision is committed before the item's build begins"); `scripts/scan-run-history.sh` reconstruction extension (spec Resume: "the restored pre-work decisions")
- **Gap type:** Untested (wholly new record entity; no current grammar, writer subcommand, or scanner field exists for a decision)
- **Test approach:**
  - **Behavior:** Recording a pre-work decision for an item writes and commits a durable entry (whatever block/grammar plan-implementation designs) before any code commit for that item exists. A second, independent invocation of the scanner (simulating a fresh process after a stop) reads that committed entry back and reports the same decision value for that item — proving the record round-trips across process boundaries, not merely within one script's memory.
  - **Stubs:** None — the "new process" is simulated exactly as the writer/reader round-trip already is in `scan-run-history.test.sh` case 22: invoke the writer script, then invoke the scanner script as a separate `bash` process reading only the committed git state — no shared shell state between the two invocations proves durability, not merely correctness within one process.
  - **Input/Action:** `init`; write a decision entry for W-1 via the writer, commit; (no code commit yet, matching the "baseline recorded, decision recorded, build not yet dispatched" phase D10 names); run the scanner in a fresh `bash` subshell.
  - **Expected output:** the scanner reports the decision value/text for W-1 exactly as recorded, and reports the item's phase as the distinct "decision recorded, build not yet dispatched" state the spec names (Resume section), not conflated with "started" or "in-progress-with-code".
  - **Expected commands:** the decision commit itself, asserted by content, matching the writer's other block-entry test style (case 5 in `write-run-record.test.sh`).
- **Brittleness assessment:** Durable — this is exactly the scenario T1 (technical notes) requires be provable, and it uses the existing round-trip idiom already proven durable by case 22. Watch for one brittleness risk: do not assert the exact commit count or commit message text beyond the trailer/marker contract — assert only the reconstructed decision value and phase.

**T9: Uncommitted decision/iteration write is NOT treated as durable on resume (T1 negative case)**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/scan-run-history.sh` reconstruction, specifically whatever narrows or removes the working-tree ledger fallback (`scan-run-history.sh:146-152`, currently exercised by case 17 "Working-tree fallback: uncommitted ledger... populates items"); T1 "that fallback must not be used to satisfy resume-critical state, or an uncommitted decision would be read as durable"
- **Gap type:** Untested as a negative case; **directly contradicts today's passing test**. Case 17 in `scan-run-history.test.sh` currently asserts the opposite of what T1 requires: it proves the working-tree fallback *does* populate items from an uncommitted ledger. T1 says this must not happen for resume-critical state. This is a genuine T#-contradiction to flag, not silently resolve.
- **Test approach:**
  - **Behavior:** Write a decision (or a fix-round marker) to the record file's working-tree copy only (never committed), then run the scanner. The scanner must not report that decision/marker as present/durable — it must reconstruct state as if that write never happened (i.e., resume proceeds as though the decision was never given, which per D10/T1 is the only sound reading — an uncommitted write is indistinguishable from a stop before the write started).
  - **Stubs:** None — real repo fixture.
  - **Input/Action:** `init` and commit; write a decision entry to the working copy of the record file directly (bypass the writer, or use the writer but do not commit — whichever the implementation makes possible) without committing; run the scanner.
  - **Expected output:** the scanner's reconstructed state for that item shows no decision recorded (or, if the scanner still falls back to a working-tree ledger for the *general* items block per case 17's existing behavior, the **decision/iteration-count fields specifically** must not be sourced from that fallback — pin the assertion to the resume-critical fields T1 names, not the whole items block).
- **Brittleness assessment:** Durable and necessary — this is the single test that would have caught the dogfooding hazard the second-run retrospective flagged (an uncommitted/misplaced record silently misread as valid state). Flag as **T#-contradiction**: raise this against decision-log D5/T1's authors before implementation, since it requires either narrowing case 17's existing working-tree-fallback test or explicitly scoping it away from the newly-durable fields. Do not silently drop case 17 — either it is retargeted to a narrower claim ("the general items block still tolerates a working-tree ledger for [reason X]") or it is removed with a plan-implementation note explaining why the fallback itself is retired for resume-critical fields.

**T10: Mid-step death — artifact committed, terminal marker absent — reconstructs as in-progress (D14 ordering invariant)**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/scan-run-history.sh` reconstruction (spec Resume: "the reachable partial state is a committed artifact whose terminal marker is absent, which is treated as in-progress and re-verified and re-reviewed before completion"; D14)
- **Gap type:** Partially tested. Today's case 3 pattern ("Resuming an in-progress item" logic actually lives in SKILL.md prose, not the scanner) and the scanner's existing `started` state (no test currently simulates a code commit landing with no terminal entry and asserts the *specific* in-progress classification for the new markers — fix-round iterations, review-record commits).
- **Test approach:**
  - **Behavior:** Simulate a mid-step death by committing an item's code (with its item trailer) and a review-record commit, but never writing the round's iteration marker or the terminal entry. The scanner reconstructs this item's state as in-progress with the round count derivable from what *is* committed, not from a marker that was never written.
  - **Stubs:** None — real repo fixture.
  - **Input/Action:** `init`; `log start-of-item`; commit a fake code change with the item trailer; commit a fake review-record file (no iteration marker logged); run the scanner.
  - **Expected output:** the item's reconstructed state is `started`/in-progress (never `done`), and — since D11 extends reconstruction to the fix-round count — the reported round count matches what the committed review records actually show, not a stale or absent count that silently reads as zero.
  - **Expected commands:** none.
- **Brittleness assessment:** Durable — mirrors the existing "done without item-trailer is unresolved" idiom (case 20) applied to the new marker-ordering invariant. Keep the assertion on the final classification string and round count, not on which specific commit the scanner inspected first.

**T11: Detector performs self-fetch with a deadline; a slow/failed fetch is reported, never silently swallowed (D3)**
- **Priority:** High
- **Test level:** Unit (bash harness, real git sandbox with a local bare "remote")
- **Entry point:** `scripts/detect-driver-context.sh` (spec Primary Flow 1: "The driver validates the plan and detects the environment in a single tooling pass that also refreshes base-branch information within a bounded deadline"; D3)
- **Gap type:** Untested (inverse of today's tests — case 12 in `detect-driver-context.test.sh` currently asserts the detector "runs no git fetch"; this assertion must invert for a fresh run, while the read-only behavior on resume, per D3's "a run recognized as a resume performs no refresh", still needs its own coverage)
- **Test approach:**
  - **Behavior:** On a fresh-run invocation, the detector runs its own fetch (replacing the driver's `git fetch --all` from `SKILL.md` Step 1.6) against a real remote, within a bounded deadline, and reports success/failure/timeout as a status the caller reads (extending or replacing today's `IWI_FETCH_STATUS`-passthrough field, which becomes self-produced instead of caller-supplied).
  - **Stubs:** A local bare git repo as the "remote" (`git init --bare`) is the deterministic double for "network," avoiding real-network flakiness, exactly as OI-1/D3's own text implies and as `detect-driver-context.test.sh` case 6 already fakes a remote via `update-ref refs/remotes/origin/main` — extend that pattern to a real `git remote add` + real `git fetch` against a bare local repo so the fetch call is real but the network is not.
  - **Input/Action:** Set up a working repo with `origin` pointed at a local bare repo; advance the bare repo's `main` a few commits; run the detector fresh (no prior fetch); separately, simulate a slow/hanging remote (e.g., a `git-upload-pack` wrapper that sleeps past the deadline, or a bare repo made unreachable via a bogus `file://` path substituted after setup) to exercise the deadline-exceeded path.
  - **Expected output:** after a successful fetch, `origin/main`'s candidate line reflects the *post-fetch* ahead/behind counts (proving the fetch actually ran, not just that a flag was echoed); the fetch-status field reports success. For the slow/unreachable case, the status field reports failure/timeout and the command still returns promptly (bounded by the deadline) rather than hanging the test.
  - **Expected commands:** the fetch itself is the outgoing command; assert its *effect* (updated remote-tracking refs) rather than mocking `git fetch` and asserting it was called — this is the correct level per "unit test that mocks away the very behavior being tested" caution: do not fake `git fetch` here (unlike case 12's read-only-guard test, which correctly fakes it to prove *absence*), because for this test the fetch actually running is the behavior under test.
  - **Resume-awareness sub-case:** on a resume invocation (however the detector learns it is a resume — a flag, or reuse of the scanner's classification), no fetch occurs at all; reuse the same fake-`git`-on-PATH trap from case 12 to prove the fetch is skipped.
- **Brittleness assessment:** Medium brittleness risk on the deadline-exceeded sub-case specifically — a real sleep-based timeout test can be slow or flaky in CI-less local runs. Prefer a fast, deterministic hang simulation (a wrapper script that blocks on a pipe/FIFO the test controls, or a very short configured deadline against a script that never returns) over a real multi-second sleep, so the test stays fast and deterministic. The success-path and resume-skip sub-cases are fully durable (real local fetch, real ref-state assertion).

**T12: Expanded base-branch candidates rank correctly (D12)**
- **Priority:** Medium
- **Test level:** Unit (bash harness, real git sandbox — extends the existing candidate-matrix pattern)
- **Entry point:** `scripts/detect-driver-context.sh` candidate loop (`detect-driver-context.sh:39`, currently `main master origin/main origin/master upstream/main upstream/master`; D12 "gains the common integration-branch names, ranked below the mainline names")
- **Gap type:** Untested (today's candidate tests, cases 1-7, only cover the current six names; none exist for `dev`/`develop`/`development`/`trunk`, and none prove the ranking — mainline wins when both resolve)
- **Test approach:**
  - **Behavior:** When a repo has both a `main` and a `develop` branch, the detector still emits both candidate lines (so the driver can compute counts for each), but SKILL.md's candidate-preference resolution (Step 1.6, "Pick the default base from the first candidate: line that resolves, in this order of freshness") continues to prefer `main` — this is a script-level concern only insofar as the emission *order* of candidate lines matters for "first that resolves"; if the driver's preference is order-dependent on emission order, the new names must be appended after the mainline set, never interleaved or prepended.
  - **Stubs:** None — real repo fixture, same `mkrepo`/`cempty` pattern as cases 1-7.
  - **Input/Action:** Create a repo with both `main` and `develop` branches (as local refs or faked remotes per case 6's `update-ref` pattern); run the detector; separately, create a repo with only `develop` (no mainline) to prove `develop` alone still resolves and is emitted.
  - **Expected output:** candidate lines exist for all of `dev`/`develop`/`development`/`trunk` when they resolve (mirroring case 5's "unresolved candidates skipped" — the new names must be skipped too when absent); when both a mainline and an integration-branch candidate resolve, the mainline candidate line appears at or before the integration-branch line in the output (whatever ordering the driver's "first that resolves" logic depends on).
  - **Expected commands:** none.
- **Brittleness assessment:** Durable for the "candidate resolves/is emitted" half (mirrors existing, low-risk pattern exactly). Slight brittleness risk on asserting emission *order* if the eventual implementation makes ranking a driver-side (SKILL.md) concern rather than a detector-output-order concern — confirm with plan-implementation which side owns the ranking before writing an order-dependent assertion; if ranking is resolved entirely in SKILL.md prose reading candidate lines by name (not position), drop the order assertion and keep only the resolves/emitted half.

**T13: Assert an unwritable git repo (branch/commit creation failure) fails loud and leaves the record file unwritten (D5 failure mode)**
- **Priority:** Medium
- **Test level:** Unit (bash harness, real git sandbox)
- **Entry point:** `scripts/write-run-record.sh` `init` (spec Resumable stop: "a failure of any tool-owned step — record-area or branch creation, a bookkeeping write or its commit")
- **Gap type:** Untested (new failure mode; today's unwritable-dir tests, case 8, guard the plain-file write, not a git operation failure like a branch that cannot be created because it already exists and points elsewhere, or a commit rejected by a hook on the opening commit)
- **Test approach:**
  - **Behavior:** If the run's branch name already exists and points at unrelated history (not a resumable run), or a `pre-commit`/`commit-msg` hook rejects the opening commit, `init` fails loud, leaves no record file behind (or leaves the record file's prior state — if any — unchanged), and does not leave the repo on a half-created branch with no commit.
  - **Stubs:** A rejecting git hook (real, same double as T2) for the commit-rejection sub-case; a pre-existing conflicting branch for the branch-creation sub-case.
  - **Input/Action:** Create a branch with the target name pointing at unrelated history; call `init` targeting that same branch name; separately, install a rejecting hook and call `init` on a fresh branch name.
  - **Expected output:** non-zero exit in both cases; no record file created (or unchanged, matching the missing-record convention in case 7: "log/block against a non-existent record must fail loud and not create it"); repo state otherwise unchanged (no stray branch left checked out mid-creation, no stray commit).
- **Brittleness assessment:** Durable — mirrors existing "fail loud, no partial state" idiom (cases 7, 8, 17, 19) applied to the new git-touching failure surface.

**T14: Coherence-approval persistence still round-trips unchanged by the D5/D8 grammar changes**
- **Priority:** Low
- **Test level:** Unit (bash harness — regression check on existing behavior, not new behavior)
- **Entry point:** `scripts/write-run-record.sh` `cmd_block` (`write-run-record.sh:134-152`), unaffected by D5/D8/D10/D11's grammar additions
- **Gap type:** Tested today (cases 4, 5, 6 already cover this) — listed here only as a regression-safety flag, not a new behavior.
- **Test approach:** No new test needed. Flag for whoever migrates the harness to the new git-sandboxed convention (T15 below): confirm cases 4-6's block-append assertions still pass unmodified once the surrounding sandbox changes from a bare tmp dir to a real repo — this is a migration-safety note, not an independent behavioral gap.
- **Brittleness assessment:** N/A — not a new test; a migration checklist item.

**T15: Harness-wide sandbox migration — every `write-run-record.test.sh` case must run inside a real repo post-D5**
- **Priority:** Medium
- **Test level:** Unit (harness infrastructure, not a single behavior)
- **Entry point:** `scripts/write-run-record.test.sh:1-19` (the file header explicitly states "The writer touches a plain file, so the sandbox is a tmp dir with no repo" — this sentence becomes false under D5)
- **Gap type:** Untested / harness infrastructure gap. Every existing case (1-20) currently runs the writer against a bare tmp file. Once `init` creates a branch and commits, and `log`/`block` commit on every call, all 20 existing cases need their fixture changed to a real repo (adopting the `mkrepo`/`cempty` helpers already duplicated in the other two harnesses) — otherwise every existing case fails outright, not just the new ones.
- **Test approach:**
  - **Behavior:** Not a new behavior — a fixture/infrastructure change. Every existing assertion (init writes exact content, log appends tokens, injection defenses, atomicity) must be re-verified against the new git-backed writer, with the same expected *content* assertions but inside a repo.
  - **Stubs:** Adopt the `mkrepo`/`cempty` pair verbatim (already duplicated identically in `detect-driver-context.test.sh:29-30` and `scan-run-history.test.sh:30-31` — a third copy in `write-run-record.test.sh` continues the existing convention rather than introducing a shared-library abstraction the project's pure-bash style doesn't use elsewhere).
  - **Input/Action:** For each of cases 1-20, wrap the record path inside a fresh `mkrepo` sandbox instead of a bare `mktemp -d` subdir; add commit-count/content assertions alongside the existing file-content assertions where D5 now implies a commit should exist after a successful call.
  - **Expected output:** all 20 existing assertions still hold (file content is unchanged in shape); additionally, where relevant, a commit now exists with the expected trailer.
- **Brittleness assessment:** This is necessary migration work, not optional — without it the entire existing suite fails to compile/run against the changed script. Low risk once done, since it reuses the proven `mkrepo`/`cempty` idiom from the other two harnesses rather than inventing new infrastructure.

## Deferred / Skipped Tests

**S1: D7 reviewer-judges-scope-from-diff — no script entry point exists**
- **Entry point:** None in `scripts/`. The behavior lives entirely in the review sub-agent's prompt construction (`SKILL.md` Step 3.3 "3. Review", `references/sub-agent-instructions.md`, `references/review-verdict-contract.md`) and the review sub-agent's own judgment.
- **Reason:** Not testable by a pure-bash harness at all — there is no deterministic script to invoke, no input/output contract a bash test can assert against, and the "judgment" itself is the sub-agent's job, not a script's. Per the prompt's own framing, this is prompt-level behavior "only exercisable by an end-to-end dogfood run" (see Coverage Estimate below). Recommending a unit test here would either mock the sub-agent's verdict (Test-the-Mock — asserting a canned verdict came back proves nothing about whether the reviewer judges scope correctly) or be an Assertion-Free smoke test that calls a prompt template with no observable pass/fail criterion. Correctly out of script-harness scope; covered instead by dogfooding (see below).

**S2: Exhaustive matrix of every new base-candidate name × every ahead/behind/diverged/detached permutation**
- **Entry point:** `scripts/detect-driver-context.sh:39` (candidate loop)
- **Reason:** T12 already covers "new candidate resolves and is emitted" and "mainline still wins when both resolve" — the two behaviors D12 actually commits to. Testing all four new names (`dev`/`develop`/`development`/`trunk`) against the full ahead/behind/diverged/detached-HEAD matrix that cases 1-4 and case 8 already prove once for the mainline names would be YAGNI: the candidate-counting logic itself (`git rev-list --left-right --count`) is name-agnostic and already proven correct by cases 1-4; repeating that proof once per new name tests the same code path four more times for no new information. Trigger to revisit: if the counting logic itself becomes name-dependent (e.g., a name-specific special case is added), a targeted test for that one name is then justified.

**S3: Detector self-fetch against a genuinely slow/real network for realism**
- **Entry point:** `scripts/detect-driver-context.sh` (D3 self-fetch)
- **Reason:** A test that waits out a real multi-second-or-longer deadline is a flaky/slow test for a bash harness the prompt explicitly says must stay pure-bash and fast. T11 already recommends the deterministic hang-simulation approach (a controllable blocking wrapper); an additional "real slow network" variant adds runtime and flakiness risk for no additional behavioral proof beyond what the controlled-hang test already gives. Trigger to revisit: if a real production incident traces to the deadline logic itself misbehaving in a way the controlled-hang test didn't catch.

**S4: Symmetry test — "we test decision persistence, so also test a symmetric currently-undecided-item persistence"**
- **Entry point:** would be `scripts/write-run-record.sh` decision-block writer (same as T8)
- **Reason:** The spec/decision-log commit only to a *recorded* decision surviving resume (D10). There is no committed behavior around persisting the *absence* of a decision (an item with `Requires pre-work decisions: no` has nothing to record — SKILL.md 3.2 already gates that a decision step is skipped entirely for such an item). A test asserting "an item with no decision has no decision entry" would test that the writer wasn't called, not a behavior the writer owns — Coverage-Metric-Chasing. Trigger to revisit: only if a future edge case shows a no-decision item's absence being misread as a *stale* recorded decision on resume, which is not a case named anywhere in the spec.

**S5: Every SKILL.md prose-level halt/recovery-menu path re-implemented as a bash-harness test**
- **Entry point:** `SKILL.md` Halt Procedure and recovery menu (all of Step 3.4/Halt Procedure prose)
- **Reason:** These are driver-prose behaviors (what the orchestrating agent says and offers), not script entry points — same category as S1/D7. The scripts' job ends at reporting facts (classification, reconstructed state, commit/file outcomes); the halt menu, its wording, and the operator-facing offer set are agent behavior with no bash-testable surface. This is squarely the "prompt-level, dogfood-only" bucket, not a script gap.

## Coverage Estimate

After T1-T13 and T15 (T14 is a no-op regression flag), the six changed behaviors reach the
following state:

- **D5 (writer owns git)** — fully covered at the script level by T1 (setup), T2 (atomic
  write+commit), T3 (narrow staging), T4 (baseline trailer/ref), T5 (terminal-last ordering),
  T13 (git-specific failure modes), and the T15 harness migration that makes the existing
  20 cases valid again under the new sandbox. This is the single largest and highest-value
  block of new coverage; script-level tests reach everything except the actual orchestration
  prose in SKILL.md (which is driver behavior, inherently dogfood-only).
- **D8/T2 (no-commit-done removed, audit resolves via confirmation commit)** — fully covered
  by T6 (round-trip parity) and T7 (negative removal check across both scripts).
- **D10/D11/T1 (decision + iteration persistence, uncommitted-state exclusion)** — covered by
  T8 (positive durability round-trip) and T9 (negative uncommitted-is-not-durable case). T9
  is flagged as a **T#-contradiction** against the current passing case 17 in
  `scan-run-history.test.sh` and needs plan-implementation's explicit resolution before
  either test is finalized — this is the most important open question this plan surfaces.
- **D14 (resume-integrity ordering)** — covered by T10 (mid-step-death reconstruction) and
  reinforced by T9's negative case; the full disagreement/default-deny surface-and-ask
  behavior (SKILL.md's "Ledger and history disagree" prose) stays driver-level and is not
  independently re-tested at the script level beyond what the scanner's output enables.
- **D3/D12 (self-fetch, expanded candidates)** — covered by T11 (fetch with deadline, resume
  skip) and T12 (new candidate names, ranking). The deadline-exceeded sub-case is the one
  softer spot: T11 flags it as the harness's own risk of flakiness and recommends a
  controlled-hang double over a real timed sleep.
- **D7 (reviewer judges scope from diff)** — **zero script-level coverage is possible or
  appropriate.** This is the hard coverage ceiling: no bash harness reaches into a
  sub-agent's judgment. It is inherently exercised only by an end-to-end dogfood run, where
  a human or the driver's own retrospective (as with the second-run feedback document already
  read for this analysis) observes whether the reviewer actually raises and the operator
  actually resolves a scope finding on an unpredicted sibling file. The recovery-menu prose
  (S5) and the halt-procedure wording sit in the same ceiling.

**On the dogfooding-safe verification problem** (the run edits its own resume machinery):
the recommended approach, given the evidence in
`docs/research/implement-work-items-second-run-feedback.md` ("the run's record location is
now inconsistent with the skill it built... an inherent hazard of editing the resume
machinery while relying on it"), is a two-phase verification, not a single dogfood run:

1. **Phase 1 — script-level harness coverage first (T1-T13/T15 above), run to green before
   any dogfood run begins.** This is the only way to validate D5/D8/D10/D11/D14/D3/D12
   without relying on a live run that depends on the very machinery being changed. All of
   these behaviors are provable by a script invoked directly against a crafted repo — no
   live `implement-work-items` invocation is needed to prove them, which is exactly why the
   harnesses exist and why this plan front-loads them as High priority.
2. **Phase 2 — the dogfood run itself is scoped to a single continuous session with no
   interrupt-and-resume across the migration boundary**, precisely to avoid the concrete
   hazard already observed once: a run that stops mid-migration and resumes against a
   scanner that now looks in a different place (or expects a different grammar) than where
   the still-old writer left its record. Concretely: run the implementation work-items batch
   for *this* feature start-to-finish without a cold stop/resume; if a stop is unavoidable,
   resume only after confirming (by hand, via the scanner's own output) that the record on
   disk matches the grammar the *current* code on that branch expects — the same check T9
   automates for the negative case, applied manually as a pre-resume sanity check for this
   one bootstrapping run only. This reduces but does not eliminate the risk (it is
   structurally the same hazard the retrospective named), which is acceptable because the
   full harness suite from Phase 1 is what carries the actual correctness burden; the dogfood
   run's job is to prove the driver-level (prompt/SKILL.md) integration, D7's scope-judgment
   behavior, and the operator-facing UX — the things Phase 1 cannot reach.

Remaining permanently untested at the script level after this plan: D7 (S1) and the halt/
recovery-menu prose (S5) — both intentionally deferred to end-to-end dogfooding as the
practical coverage ceiling for a pure-bash-harness strategy, not a gap in this plan.
