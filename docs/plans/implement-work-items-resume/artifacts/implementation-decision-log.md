# Implementation Decision Log: Resume, Halt Recovery, and Re-Grounding for the Work-Item Driver

<!--
This file records every implementation decision committed while planning HOW to
build resume, halt-recovery, and re-grounding into the `implement-work-items` skill.
Behavioral and implementation statements live in
[../feature-implementation-plan.md](../feature-implementation-plan.md) — this file
captures the question, rationale, evidence, and rejected alternatives for each
decision. Round-by-round history lives in
[implementation-iteration-history.md](implementation-iteration-history.md).

The claim ledger (CL-1..CL-17) these decisions synthesize lives on R1 in
implementation-iteration-history.md. Every decision here was settled by evidence —
specialist findings corroborated against the current skill, the feature spec's
committed decisions (D1–D21), and the technical notes (T1, T2). None required user
input; the spec-maturity gate did not trip.
-->

## Trivial decisions

- D-10: Opening entry co-committed atomically with the planning-artifacts commit — the driver writes the opening progress entry into the same commit that lands the planning artifacts, so a rejected or interrupted opening leaves an empty branch (classified fresh) rather than a foreign base (refused) ([CL-5]; on-call OCE-001). — Referenced in plan: Decomposition and Sequencing, On-Call Resilience Posture.
- D-11: Record-path exclusion is a verified checklist, not one edit — the `.implement-work-items/progress.md` path must stay out of the item-staging step (SKILL.md 3.4), the review scope diff (`review-verdict-contract.md`), the human-review scope pointer (`human-review-capture.md`), and the no-output clean-tree assertion (`no-output-completion.md`); placing the ledger inside `.implement-work-items/` (D-1) makes the existing directory exclusion cover most sites, and the human-review pointer prose is the one site to verify ([CL-12]; on-call OCE-007, structural S6, behavioral B10). — Referenced in plan: Decomposition and Sequencing, Definition of Done, On-Call Resilience Posture.
- D-12: No-output durable write ordered durable-record-first — `no-output-completion.md` step 2 and the recovery re-attempt Exit each gain the durable no-commit-done write, ordered durable record first then `state.json`, so the branch-durable record is authoritative and `state.json` is the reconstructable follower ([CL-13]; structural S5/S9, review-sync F12). — Referenced in plan: Decomposition and Sequencing, Data Model and Persistence.
- D-13: Entry fields kept minimal — the no-commit-done entry carries no `Type` field (read from the work-items file at resume), the skip entry carries no dependency snapshot (the graph is re-derived from the current file), and no durable fix-counter, body-hash, or pre-work-decision is recorded (all spec-deferred) ([CL-16]; behavioral B1/B4/B5). — Referenced in plan: Data Model and Persistence, Deferred (YAGNI).

## Full decisions

### D-1: Durable record form is a committed ledger file at `.implement-work-items/progress.md`

- **Question:** What concrete form does the durable progress record take, given it must travel with the branch, pass the repo's commit hooks, and be located on resume without a stored reference? (Spec Open Item #1.)
- **Decision:** Record run progress as a committed markdown ledger file at `.implement-work-items/progress.md`, appended to and re-committed as each entry is written. Make the file trackable by changing the setup step's `.implement-work-items/.gitignore` from a single line `*` to two lines — `*` then `!progress.md` — so the one ledger file is version-controlled while `state.json`, the review records, and everything else in the directory stay ignored. The opening, start-of-item, done, no-commit-done, and skip entries are lines in this file; the commit that lands each update carries the run-identity trailer (D-2). This resolves spec Open Item #1 (the exact record form) and, together with D-2, the conform-versus-bypass mechanism (bookkeeping commits conform to the repo convention rather than bypassing hooks).
- **Rationale:** An empty marker commit is rejected by a no-empty-commit hook and needs an explicit allowance; a commit-message-substring marker is mutated by a message-rewriting commit-msg hook, which breaks a greppable message marker. A committed file updated with a conventional message survives both hook classes and is greppable via its own trailer. Placing it inside the existing `.implement-work-items/` directory means the driver's current path exclusions already cover it (T1 line 9), so the record does not leak into an item's code commit or its scope diff.
- **Evidence:** [CL-1], [CL-4] (implementation-iteration-history.md#r1-parallel-specialist-review); junior JD-002/003, behavioral B9/B10/B12, on-call OCE-009 (hook-conformance); spec [T1](feature-technical-notes.md#t1-greppable-per-item-ledger-markers-in-commit-history) line 10 (hook-conformant constraint), [D2](decision-log.md#d2-committed-greppable-per-item-ledger), [D20](decision-log.md#d20-marker-commits-conform-to-convention-and-fail-as-a-distinct-class); current setup writes `.implement-work-items/.gitignore` as a single `*` (`han-coding/skills/implement-work-items/SKILL.md` Step 2.2). Trust class: codebase and provided.
- **Rejected alternatives:**
  - Empty marker commit — rejected because a no-empty-commit hook rejects it and it needs an explicit allowance (on-call OCE-009, spec T1 line 10).
  - Commit-message-substring marker — rejected because a message-mutating commit-msg hook rewrites the subject and breaks the greppable message marker (behavioral B9).
  - A new top-level tracked path outside `.implement-work-items/` — rejected because it would require adding exclusions at every scope/stage site; the inside-directory placement reuses the existing exclusion (behavioral B10 vs. on-call OCE-007/structural S6, resolved toward inside-placement by evidence).
- **Specialist owner:** structural-analyst (record structure and exclusion surface).
- **Revisit criterion:** a target repo whose hooks reject a conventionally-messaged file-update commit, or whose policy forbids a tracked file under an otherwise-ignored directory.
- **Dissent (if any):** none. CL-4 was a location dispute (behavioral B10 assumed inside, on-call OCE-007/structural S6 assumed an outside path); resolved by evidence toward inside-placement, with the OCE-007 exclusion-site checklist retained as D-11.
- **Driven by rounds:** R1
- **Dependent decisions:** D-2, D-8, D-10, D-11, D-12, D-13
- **Referenced in plan:** Data Model and Persistence, Architecture and Integration Points, Decomposition and Sequencing, Definition of Done

### D-2: Run identity and entry marker is a namespaced git trailer keyed on the normalized work-items path

- **Question:** What signal does the driver grep to classify an invocation as fresh, resume, or refuse, and to bracket its own bookkeeping commits, without colliding with ordinary commits?
- **Decision:** Key run identity on a namespaced git commit trailer, `Implement-Work-Items-Run:`, whose value is the work-items file's repo-root-relative path. Every bookkeeping commit that updates `progress.md` (D-1) carries this trailer; `scripts/scan-run-history.sh` (D-3) greps the branch history for the trailer, matched exactly against the normalized target path, to decide fresh-versus-resume-versus-refuse. Detection normalizes the path — strip a leading `./`, resolve `..`, drop any trailing slash — before comparison, so a valid resume expressed with a differently-spelled-but-equivalent path is not silently refused as a foreign base. A trailer keyed on the exact path is matched, not a commit-message substring that could appear in an ordinary commit.
- **Rationale:** The entire D10 fresh/resume/refuse safety and the D11 default-deny posture rest on this match being exact and collision-resistant. A subject-line substring risks a false positive against an ordinary commit that happens to mention the run; a namespaced trailer keyed on the path does not. Path normalization is required because the same file can be named several equivalent ways at invocation, and D10 keys identity on the repo-root-relative path.
- **Evidence:** [CL-10], [CL-17] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-008, behavioral B12 (collision-resistance), behavioral B8 (path normalization); spec [D10](decision-log.md#d10-fresh-vs-resume-detection) (identity keyed on repo-root-relative path), [T1](feature-technical-notes.md#t1-greppable-per-item-ledger-markers-in-commit-history) (located by scanning the branch log via a commit trailer, not a stored hash). Trust class: provided and codebase. This resolves the grep-convention half of spec Open Item #1.
- **Rejected alternatives:**
  - A commit-message subject substring marker — rejected because it risks collision with an ordinary commit that mentions the run, and a message-rewriting hook can mutate it (on-call OCE-008, behavioral B12).
  - Matching the raw supplied path without normalization — rejected because an equivalent path spelled with `./` or a trailing slash would fail the exact match and a valid resume would be refused as a foreign base (behavioral B8).
- **Specialist owner:** behavioral-analyst (detection correctness and path normalization).
- **Revisit criterion:** a repo whose hooks strip or rewrite commit trailers, or a run identity that must survive a work-items file move (which today reads as a different run).
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-5, D-8, D-9
- **Referenced in plan:** Runtime Behavior, Data Model and Persistence, Decomposition and Sequencing

### D-3: Structural decomposition into two references and one sibling script

- **Question:** Where does the new mechanic live — inline in SKILL.md, extended onto the existing detector script, or in new files — given the 500-line progressive-disclosure ceiling and the hardening split between deterministic and fuzzy work?
- **Decision:** Add three files and leave the existing detector untouched: `references/durable-record-protocol.md` (the entry schema, the D11 integrity matrix, the trailer convention from D-2, and the exclusion checklist from D-11); `references/re-grounding-routine.md` (the single re-grounding routine from D-4); and `scripts/scan-run-history.sh` (the deterministic fresh/resume/refuse detection and history scan). Leave `scripts/detect-driver-context.sh` unchanged. SKILL.md gains only the prose that invokes these and the per-site judgment.
- **Rationale:** Inlining everything breaches the 500-line SKILL.md ceiling, and the driver's own instructions are exactly what a mid-run compaction drops — the failure D18's commit-boundary self-check exists to bound — so bloating SKILL.md worsens the problem the feature is guarding against. The deterministic detection (scan the branch log for the trailer, classify the invocation) belongs in a script per the hardening rule, while the judgment (classify resume state, surface-and-ask, present the recovery menu) stays in SKILL.md. The existing detector cannot host detection: it runs at Step 1.3 with no work-items-path parameter, and the record scan needs the resolved path and must run after Step 1.2 branch resolution.
- **Evidence:** [CL-2] (implementation-iteration-history.md#r1-parallel-specialist-review); structural S1/S2/S3/S7, junior JD-001; skill-authoring guidance `han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md` (500-line ceiling), `hardening-fuzzy-vs-deterministic.md` (deterministic-to-scripts split); current `scripts/detect-driver-context.sh` runs at SKILL.md Step 1.3 without a path parameter; spec [D18](decision-log.md#d18-commit-boundary-self-check). Trust class: codebase and provided.
- **Rejected alternatives:**
  - Inline the whole mechanic in SKILL.md — rejected because it breaches the 500-line ceiling and enlarges the driver's own instruction body, the thing compaction drops (structural S7).
  - Extend `detect-driver-context.sh` — rejected because it needs a work-items-path parameter it does not take and a post-Step-1.2 invocation timing it cannot occupy (structural S3).
- **Specialist owner:** structural-analyst (module boundaries and file decomposition).
- **Revisit criterion:** the new references push a consuming SKILL.md step back over the ceiling, or a second script would duplicate `scan-run-history.sh`'s history scan.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-4
- **Referenced in plan:** Architecture and Integration Points, Decomposition and Sequencing

### D-4: Re-grounding is one core routine with per-site wrapping

- **Question:** How is re-grounding defined so its four re-entry sites (foreground hand-off, human review, cross-session resume, recovery-menu re-attempt) share one routine without leaking the cross-session go-ahead into the in-session sites?
- **Decision:** Define one core re-grounding routine in `references/re-grounding-routine.md` (D-3): reconstruct run state from the durable record, re-derive the dependency graph from the current work-items file, re-read the working tree, re-read the driver's own instructions, and announce where it is. The cross-session resume site wraps the core with the D19 go-ahead, the resume summary, config restoration from the opening entry, and verification-baseline re-establishment. The three in-session sites run the core without imposing the go-ahead. On cross-session entry, `state.json` is reconstructed from the durable record; any surviving gitignored `state.json` copy is treated as untrusted. Extract the "re-read own instructions" sub-step so the D18 commit-boundary self-check reuses it.
- **Rationale:** A single monolithic block would carry the cross-session go-ahead into the in-session sites, where D19 explicitly does not require it (the operator is already present). Leaving re-grounding scattered inline is the exact inconsistency D9 flags. Reconstructing `state.json` from the durable record rather than trusting a surviving gitignored copy honors D13's "the durable record supersedes the in-session store."
- **Evidence:** [CL-3] (implementation-iteration-history.md#r1-parallel-specialist-review); junior JD-005/006, structural S1, on-call OCE-004; spec [D9](decision-log.md#d9-re-grounding-as-one-shared-routine) (one shared routine), [D13](decision-log.md#d13-durable-ledger-content-vs-ephemeral-state) (durable record supersedes), [D18](decision-log.md#d18-commit-boundary-self-check) (reuses the instruction-reload sub-step), [D19](decision-log.md#d19-cross-session-resume-go-ahead) (go-ahead is cross-session only); current partial definition in `han-coding/skills/implement-work-items/references/foreground-handoff-protocol.md` lines 17-22 and the re-ground references in SKILL.md and `human-review-capture.md`. Trust class: provided and codebase.
- **Rejected alternatives:**
  - One monolithic re-grounding block reused verbatim at all four sites — rejected because it leaks the cross-session go-ahead into the in-session sites where D19 forbids it (junior JD-005).
  - Leave re-grounding scattered inline as today — rejected because it is undefined and inconsistent, the condition D9 was written to fix.
- **Specialist owner:** structural-analyst (routine boundary and reuse).
- **Revisit criterion:** a fifth re-entry site emerges whose needs the core-plus-wrapping split cannot express, or the go-ahead is needed at an in-session site.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-7
- **Referenced in plan:** Runtime Behavior, Architecture and Integration Points, Decomposition and Sequencing

### D-5: Forward-reconcile is AFK-only, ordered after the foreground branch, and gated by a positive-classification test

- **Question:** In the resume-an-in-progress-item flow, in what order does the driver reach forward-reconcile, and what stops it from silently marking foreground work or a foreign in-range commit as done?
- **Decision:** Route an interrupted foreground item to re-verify/re-review (the existing "Resuming an interrupted foreground item" flow) **before** the forward-reconcile check, so forward-reconcile applies only to AFK items. Gate forward-reconcile with a positive-classification test that reuses the existing scope computation: the item's start-of-item-to-HEAD changed-file set must fall within the item's scope and the tree must be clean before the driver records the missing done entry and advances. A foreground pre-gate commit, or a foreign commit landing in the range, fails the positive test and is surfaced-and-asked rather than silently marked done. This is the single most behavior-adjacent mechanic in the plan.
- **Rationale:** The spec's line-49 ordering reaches forward-reconcile before the AFK/foreground branch, so an interrupted foreground item (whose interactive skill commits pre-gate) or a foreign commit in the item's range would be marked done and advanced past without re-review — the D11 default-deny posture forbids that. Reordering so the foreground branch runs first, and gating the AFK path with a positive test, implements default-deny on the forward-reconcile path. Reusing the existing scope diff (`git diff --name-only <baseline>`, already computed by the review) means this does **not** reopen the deferred dedicated commit-range integrity pre-check; it leans on machinery the driver already runs.
- **Evidence:** [CL-6], [CL-11] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-002, behavioral B6; spec [D16](decision-log.md#d16-committed-but-unmarked-forward-reconcile) reasoning "an unattended build never commits" (feature-specification.md line 170), [D11](decision-log.md#d11-ledger-and-history-integrity-safety) default-deny, spec Deferred (YAGNI) (the dedicated range check stays deferred); the existing scope computation in `han-coding/skills/implement-work-items/references/review-verdict-contract.md` lines 78-86; the existing "Resuming an interrupted foreground item" flow (feature-specification.md lines 52-56). Trust class: provided and codebase.
- **Rejected alternatives:**
  - The spec's line-49 ordering (forward-reconcile before the AFK/foreground branch) — rejected because it marks un-gated foreground work and foreign in-range commits done without re-review (on-call OCE-002, corroborated by behavioral B6).
  - Add a dedicated commit-range integrity pre-check to gate forward-reconcile — rejected because it reopens the spec-deferred range check; the existing scope diff plus the recovery menu already surface a polluted range (spec Deferred (YAGNI)).
- **Specialist owner:** on-call-engineer (resume-path correctness) with behavioral-analyst (data-flow of the changed-file set).
- **Revisit criterion:** the reused scope diff proves insufficient to distinguish a foreground pre-gate commit from the item's own AFK work, forcing the deferred dedicated range check back open.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Decomposition and Sequencing, Testing Strategy, On-Call Resilience Posture, Definition of Done

### D-6: Bookkeeping-commit failure is a distinct surface-and-stop class

- **Question:** When a bookkeeping (progress-record) commit is rejected by a hook, does it enter the Step 3.4 code fix loop, or a separate path?
- **Decision:** Treat a bookkeeping-commit failure as its own surface-and-stop class, never routed into the Step 3.4 code fix loop. Implement it via one shared "record a bookkeeping entry" routine whose failure branch is the Halt Procedure's marker-write failure class. Every progress-record write (opening, start-of-item, done, no-commit-done, skip) goes through this one routine, so the distinct failure handling is defined once.
- **Rationale:** SKILL.md Step 3.4 routes a rejected commit into the fix loop, which re-dispatches a build to fix the code. A rejected bookkeeping commit has no code to fix, so routing it into that loop is a poison pill: the driver would loop uselessly on an item whose code is already sound. Surfacing-and-stopping (D20) is the correct handling, and centralizing the write routine keeps every entry type on that handling.
- **Evidence:** [CL-7] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-003; spec [D20](decision-log.md#d20-marker-commits-conform-to-convention-and-fail-as-a-distinct-class); current fix-loop routing of commit-hook failures in `han-coding/skills/implement-work-items/SKILL.md` Step 3.4 lines 282-291. Trust class: provided and codebase.
- **Rejected alternatives:**
  - Reuse the Step 3.4 commit-hook fix-loop handler for bookkeeping commits — rejected because a rejected marker becomes a poison-pill fix loop on an item whose code is fine (on-call OCE-003, spec D20).
- **Specialist owner:** on-call-engineer (failure-class routing).
- **Revisit criterion:** a hook class emerges that can reject a bookkeeping commit for a reason an automated retry could fix.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Decomposition and Sequencing, On-Call Resilience Posture

### D-7: Commit-boundary self-check is an unconditional re-Read via a shared "record the item done" routine

- **Question:** How does the driver guarantee it re-reads its own instructions before marking an item done, given a compacted driver cannot reliably judge whether its instructions were truncated?
- **Decision:** Make the commit-boundary self-check an unconditional re-Read of the relevant step(s), implemented through one shared "record the item done" routine that re-Reads, then forks the output — an output-producing item commits and writes a done entry; a no-output `audit` writes a no-commit done outcome with no commit. The re-Read is not conditional on any truncation judgment.
- **Rationale:** "Reload if it seems truncated" asks a compacted driver to make exactly the judgment its compaction has impaired — it is a no-op precisely when it is needed. An unconditional re-Read (reusing the re-grounding routine's instruction-reload sub-step from D-4) removes the judgment. Centralizing both done paths through one routine ensures the self-check cannot be skipped on either fork, including the no-commit done outcome, which spans two files (SKILL.md and `no-output-completion.md`) in the review-sync.
- **Evidence:** [CL-8] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-005; spec [D18](decision-log.md#d18-commit-boundary-self-check), review-sync F15; skill-authoring hardening rule (`han-plugin-builder/skills/guidance/references/skill-building-guidance/context-hygiene.md`); the instruction-reload sub-step extracted in D-4. Trust class: provided and codebase.
- **Rejected alternatives:**
  - "Reload if it seems truncated" — rejected because it is a judgment a compacted driver cannot make, a no-op exactly when needed (on-call OCE-005, spec D18).
- **Specialist owner:** on-call-engineer (compaction resilience).
- **Revisit criterion:** the unconditional re-Read measurably dominates per-item cost, warranting a cheaper guard.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Decomposition and Sequencing, On-Call Resilience Posture, Definition of Done

### D-8: Done-entry reference is positional, computed at report time

- **Question:** How does a done entry reference the item's code commit — a stored hash written into the entry, or something a benign rebase cannot invalidate?
- **Decision:** The done entry is positional, storing no commit hash. The code commit strictly precedes the done entry, and the per-item display reference (the commit or range shown in the summary and resume view) is computed at report time from the current branch history — the item-id trailer (D-9) plus the start-of-item-to-done bracket identify the item's commit. No hash is persisted.
- **Rationale:** A stored hash false-alarms on a benign history-preserving rebase: the recorded hash no longer resolves even though the item's work is intact, and the driver would surface a spurious divergence. Deriving the reference positionally at report time means a rebase that preserves the item's commit still resolves it. This matches T1's "real commits rather than stored hashes" and D2's rejection of stored hashes.
- **Evidence:** [CL-9] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-006, behavioral B2/B3; spec [T1](feature-technical-notes.md#t1-greppable-per-item-ledger-markers-in-commit-history) line 11 ("real commits rather than stored hashes"), [D2](decision-log.md#d2-committed-greppable-per-item-ledger) (rejects stored hashes). Trust class: provided. The item-id trailer that makes positional derivation possible is D-9.
- **Rejected alternatives:**
  - Store the commit hash in the done entry — rejected because it false-alarms on a benign history-preserving rebase and contradicts T1/D2 (on-call OCE-006).
- **Specialist owner:** behavioral-analyst (report-time derivation).
- **Revisit criterion:** report-time derivation proves ambiguous when multiple commits in an item's bracket carry the same item-id trailer.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Data Model and Persistence, Runtime Behavior

### D-9: Add an item-id trailer to the driver's own code commits

- **Question:** How does forward-reconcile positively identify that the commit in an item's range is that item's own work, and how does report-time reference derivation (D-8) find it?
- **Decision:** Add the item id as a git commit trailer, `Implement-Work-Items-Item:` with value `W-N`, to the driver's own per-item code commits. This gives forward-reconcile (D-5) a positive identity signal and enables the positional report-time reference (D-8). Confirmed absent on the driver's commits today.
- **Rationale:** Without an id on the code commit, forward-reconcile cannot distinguish the item's own commit from a foreign one that landed in the range, and report-time reference derivation has nothing to key on. A namespaced item-id trailer is the minimal positive signal that closes both.
- **Evidence:** [CL-11] (implementation-iteration-history.md#r1-parallel-specialist-review); on-call OCE-002/OQ2; verified via git that the driver's code commits carry no such trailer today (`git log -- han-coding/skills/implement-work-items/` shows no `Implement-Work-Items-Item` trailer); enables D-5's positive-classification test and D-8's report-time reference. Trust class: codebase and provided.
- **Rejected alternatives:**
  - Leave code commits id-less — rejected because forward-reconcile cannot distinguish the item's commit from a foreign one in range, and report-time reference derivation has nothing to key on (on-call OCE-002/OQ2).
- **Specialist owner:** on-call-engineer (forward-reconcile identity).
- **Revisit criterion:** a repo whose hooks strip commit trailers from code commits, defeating the identity signal.
- **Dissent (if any):** none.
- **Driven by rounds:** R1
- **Dependent decisions:** D-5
- **Referenced in plan:** Data Model and Persistence, Runtime Behavior, Decomposition and Sequencing
