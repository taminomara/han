# Implementation Decision Log: implement-work-items First-Run Hardening

This file records every implementation decision committed while planning the
first-run hardening bundle for the `implement-work-items` skill. Behavioral and
implementation statements live in
[../feature-implementation-plan.md](../feature-implementation-plan.md); this file
captures the question, rationale, evidence, and rejected alternatives for each
decision. Round-by-round history lives in
[implementation-iteration-history.md](implementation-iteration-history.md). The
behavioral spec these decisions implement is
[../feature-specification.md](../feature-specification.md) and its companion
[decision-log.md](decision-log.md) (spec decisions D1–D12).

Every decision below was settled by codebase evidence in Round 1; none required
user escalation, and none was settled by junior-developer reframing. The
per-round claim ledger (CL-1..CL-21) that these decisions consolidate lives on
the R1 entry in [implementation-iteration-history.md](implementation-iteration-history.md).

## Trivial decisions

- D-18: No new reference file or script for D2, D3, D5, or D8 — each is implemented by extending its existing home (`SKILL.md` prose or `detect-driver-context.sh`), following the YAGNI default of not adding structure the change does not force (consolidates CL-21; software-architect A6). — Referenced in plan: Implementation Approach → Architecture and Integration Points, Decomposition and Sequencing.
- D-19: The new detector and scanner code preserves the scripts' existing git-injection defenses — `--end-of-options` operand-pinning (`scan-run-history.sh:94,106`) and exact-key trailer matching — so a branch name or path can never be parsed as a git option. — Referenced in plan: Security Posture.

## Full decisions

### D-1: Run record stays a shell-parseable line-grammar, no JSON, no hard jq or python dependency

- **Question:** Should the collapsed single run record adopt a structured format (JSON) and a parser (`jq`/`python3`), or keep the current pure-bash line-grammar?
- **Decision:** Keep the shell-parseable line grammar. The record stays the labeled config block plus one `- <token>: <W-N>` line per entry; no JSON is introduced anywhere in the record, and neither `jq` nor `python3` becomes a hard dependency. The only hard runtime dependency remains `git` plus bash.
- **Rationale:** The skill runs in arbitrary user repositories that may be Go, Ruby, or JS with no `jq` or Python on the machine. Making a parser a hard requirement turns every `jq`-absent repo from graceful hand-maintenance into a startup refusal — a portability regression. The existing reconstruction is already pure bash, so no new tooling is needed to read or write the record. This is the operator's explicitly flagged decision.
- **Evidence:** `.discovery-notes.md:9-11` (no Python anywhere; only git+bash guaranteed); `SKILL.md` Project Context (`which jq || echo "not installed"` — jq is probed, not required); `scan-run-history.sh:143-158` (pure-bash regex reconstruction, no jq); consolidates CL-1 (devops item 1, junior JD-006, consistent with on-call).
- **Rejected alternatives:**
  - Adopt a JSON run record — rejected because it forces a structured parser the pure-bash reader does not have and does not need.
  - Make `jq`/`python3` a hard dependency — rejected on portability: a `jq`-absent user repo would refuse to start rather than degrade to hand-maintenance (`.discovery-notes.md:10-11`).
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a future minimum-supported environment guarantees `jq` or `python3` as a hard floor, or a new durable block needs a genuinely structured field the line grammar cannot express.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-3, D-4 (both rest on the line grammar being the record format).
- **Referenced in plan:** Implementation Approach, Data Model and Persistence, Testing Strategy, Operational Readiness.

### D-2: Delete the JSON state file and recover scope-baseline from a distinct trailer

- **Question:** The old record split a tracked `progress.md` ledger from a gitignored `state.json`. With the record collapsing to one committed file (spec D12), what happens to `state.json` and its five per-item fields?
- **Decision:** Delete `state.json`. Four of its five fields (`state`, `fix-round`, `decision`, `commit-range`) are re-established per session and need no durable store. The one durable field, `scope-baseline`, is recovered from committed history via a **distinct baseline trailer** on the start-of-item bookkeeping commit — never by reusing the item-id trailer, which the scanner reads to detect resolved code commits.
- **Rationale:** `state.json` was the parallel untrusted store that already failed once at finalization (spec D12). Once every iteration is committed, git history is the durable authority, so the ephemeral fields do not need serializing and the one durable field is recoverable from the commit that established it. A distinct trailer keeps the baseline lookup from colliding with the item-id trailer's resolved-code-commit semantics in `scan-run-history.sh`.
- **Evidence:** `durable-record-protocol.md:20-23` (nothing stores a durable fix-counter, body-hash, or pre-work decision — all re-established in session); `re-grounding-routine.md:22-25` (state.json is untrusted, rebuild it); `scan-run-history.sh:132-136` (item-id trailer drives resolved/unresolved classification); consolidates CL-2 (devops item 1, junior JD-005).
- **Rejected alternatives:**
  - Serialize the four session-ephemeral fields into the committed record — rejected because they are reconstructed per session; storing them adds durable state the session already rebuilds.
  - Recover the scope-baseline by reusing the item-id (`Implement-Work-Items-Item`) trailer — rejected because the scanner reads that trailer to classify resolved code commits; a baseline lookup on the same key would be misread (`scan-run-history.sh:132-136`).
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a field currently treated as session-ephemeral proves non-reconstructable on resume under the new commit cadence.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-8 (the baseline trailer is part of the trailer scheme), D-7 (mutable per-item state stays session-local), D-15 (re-grounding drops its state.json section).
- **Referenced in plan:** Implementation Approach, Data Model and Persistence, Runtime Behavior.

### D-3: New durable state rides in separate blocks below the byte-preserved Log block

- **Question:** The genuinely-new durable state — D6 below-threshold dispositions, D7 coherence approvals, D9 accumulated corrections — has to live in the committed record. How is it carried without breaking the resume scan?
- **Decision:** Carry each new state class as its own labeled block appended **below** the existing `Log:` block, whose four-token grammar (`start-of-item`, `done`, `no-commit-done`, `skip`) stays byte-for-byte untouched. Each new block is parsed additively and independently; the item-lifecycle regex the scanner already ships is never changed.
- **Rationale:** The `- <token>: <W-N>` line grammar is a two-party contract between the writer and `scan-run-history.sh`; a one-sided change to that alternation silently reconstructs zero items on resume. Adding new tokens into the same alternation risks exactly that. Separate labeled blocks let the new state grow without touching the shipped lifecycle regex.
- **Evidence:** `scan-run-history.sh:138-144` (the grammar is a shared contract; a writer that changes it silently reconstructs zero items); consolidates CL-3 (devops item 1; software-architect A1/A5 proposed new tokens in the alternation, resolved to the safer separate-blocks form).
- **Rejected alternatives:**
  - Add new tokens into the existing `Log:` alternation — rejected because the shipped item-lifecycle regex must never be perturbed; a mismatched writer reconstructs zero items (`scan-run-history.sh:138-144`). Raised by software-architect (A1/A5) and resolved to separate blocks.
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a new durable block's data cannot be expressed as append-only labeled lines and genuinely needs to interleave with the Log block.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-12 (below-threshold detail is read from these blocks), D-14 (accumulated corrections are stored as one of these blocks).
- **Referenced in plan:** Data Model and Persistence, Testing Strategy.

### D-4: One mechanism-only bookkeeping writer script

- **Question:** Should the collapsed record be maintained by a new writer script, or by the model appending lines and committing as prose?
- **Decision:** Add exactly **one** append-only bookkeeping writer script (`write-run-record.sh`), pure bash, following the existing deterministic-detector precedent. It is mechanism only — init the record, append a `<token> <W-N>` line, set per-item state — and makes no proceed/discard judgment. The model decides *which* token to write and owns the `git commit`; the script owns only *how the line is spelled*.
- **Rationale:** The documented first-run finalization failure (spec D12's own evidence) and the writer/reader grammar-drift risk both pass the evidence test: a hand-spelled line that drifts from the scanner regex reconstructs zero items. A single mechanism-only writer removes the hand-spelling drift while keeping all judgment model-driven, which is where the junior-developer's YAGNI concern is honored — the cap is one script, no judgment moves into it.
- **Evidence:** spec D12 (a finalization turn did not complete cleanly, needing a manual retry — `decision-log.md` D12); `scan-run-history.sh:138-144` (grammar-drift silently reconstructs zero items); the pure-bash deterministic-detector precedent in `detect-driver-context.sh` and `scan-run-history.sh` (`.discovery-notes.md:25`); consolidates CL-4 (devops item 2, on-call F2, software-architect A2).
- **Rejected alternatives:**
  - No script — keep append-and-commit as model prose — rejected because the documented finalization failure and the grammar-drift risk are real, evidenced failure modes hand-prose already hit once.
  - A second state-manager script alongside the writer — rejected because the scanner's existing regex already reconstructs per-item state; a second script duplicates it. Extend the scanner instead.
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a second finalization-class failure appears that one mechanism-only writer cannot cover, or the writer starts accreting judgment (then re-scope, do not add judgment to the script).
- **Dissent (if any):** junior-developer (CL-4, JD-006/JD-011) argued the writer script is YAGNI — the model can append and commit as prose. Recorded under disagree-and-commit: the finalization-failure evidence and grammar-drift risk carried the decision; the dissent is honored by capping at one script and keeping all token/commit judgment with the model. Revisit if the writer proves to add no coverage over prose in practice.
- **Driven by rounds:** R1
- **Dependent decisions:** D-16 (the writer co-lands in Wave 1 with the scanner it shares a grammar with).
- **Referenced in plan:** Implementation Approach, Architecture and Integration Points, Decomposition and Sequencing, Testing Strategy.

### D-5: Rewrite the per-item loop to commit before every dispatch and every iteration

- **Question:** Spec D8/D10 require a clean tree at every dispatch and a commit per iteration. Is that an extension of Steps 3.3/3.4 (today: one code commit per item at 3.4) or a rewrite?
- **Decision:** Treat it as a **rewrite** of Steps 3.3/3.4. Add an explicit "commit in-flight work, then dispatch" step at every dispatch site — build, fix re-dispatch, review, the recovery-menu "Build further" path, and the foreground return — with ordering pinned strictly commit → dispatch. Every iteration commit is staged **by path** (`git add <path>`, which also covers new untracked files an iteration creates), never `git add -A`, and never `.implement-work-items/`.
- **Rationale:** Today the loop commits once per item at 3.4; "commit before each dispatch" and "commit every iteration" change the loop's commit cadence at multiple sites, which is structural, not a local edit. Pinning commit → dispatch is what makes the clean tree a structural guarantee (spec D8) rather than a soft instruction. Staging by path keeps the driver's own bookkeeping artifacts out of an item's code commit while still capturing new untracked source files.
- **Evidence:** `SKILL.md:304-393` (the current single-commit-per-item loop the rewrite replaces); `SKILL.md:375` (existing stage-by-path, never `git add -A` discipline the rewrite extends to every iteration); consolidates CL-5 (junior JD-003, on-call F1, software-architect A4) and CL-7 (devops item 3a).
- **Rejected alternatives:**
  - Extend Steps 3.3/3.4 in place rather than rewriting — rejected because the commit cadence changes at every dispatch site, not one; a local edit would miss the fix-re-dispatch, review, and recovery paths.
  - `git add -A` for iteration commits — rejected because it would sweep the driver's `.implement-work-items/` bookkeeping into a code commit; stage by path covers new untracked files without that (`SKILL.md:375`).
  - A commit-retry/backoff or idempotency-key store around the new commits — rejected (on-call): the side effects are additive git commits and replay is benign, so no idempotency machinery is warranted.
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** committing before every dispatch measurably degrades run throughput at observed run lengths, or a dispatch site is found that cannot commit first.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-6 (the new pre-dispatch commit's rejection class), D-7 (write-ordering invariant), D-13 (the re-verify-fails branch reuses this loop and its reset).
- **Referenced in plan:** Runtime Behavior, On-Call Resilience Posture, Decomposition and Sequencing.

### D-6: A rejected pre-dispatch commit is a marker-write resumable stop, not a fix round

- **Question:** The rewrite (D-5) adds a new commit site — the pre-dispatch commit of in-flight work. When that commit is rejected by a hook, which failure class does it join?
- **Decision:** A rejected pre-dispatch commit joins the marker-write / resumable-stop class (the same class as a rejected bookkeeping commit), never the code-fix loop. Distinguish "clean tree, nothing to commit" (a no-op → proceed to dispatch) from "hook rejected, tree still dirty" (fail-closed resumable stop) via `git status --porcelain`.
- **Rationale:** The spec already classifies the two existing commit sites (code-commit rejection → fix loop; bookkeeping rejection → resumable stop) but is silent on this new third site the rewrite introduces. Routing a rejected pre-dispatch commit into the fix loop would turn a hook problem into churn on sound code; the fail-closed stop preserves the never-dispatch-onto-a-dirty-tree guarantee. `git status --porcelain` is the deterministic test that separates a benign clean tree from a genuine rejection.
- **Evidence:** spec Edge Cases row "A bookkeeping commit is rejected … surfaced as a resumable stop, never routed through the code-fix loop" (`feature-specification.md`, Edge Cases; `decision-log.md` D12); the gap that the spec classifies the two existing commit sites but not the new pre-dispatch one; consolidates CL-6 (on-call F1).
- **Rejected alternatives:**
  - Route a rejected pre-dispatch commit through the code-fix loop — rejected because it is a marker/hook failure, not a code defect; looping churns sound code (spec D12 keeps the two classes separate).
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** a repo is observed whose hook rejects a pre-dispatch commit but accepts other bookkeeping commits, exposing a sub-class the single stop path does not cover.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, External Interfaces, On-Call Resilience Posture, RAID Log.

### D-7: The committed done entry is the sole resume authority

- **Question:** Once every iteration is committed and the tree is always clean at dispatch, the old resume shortcut ("item-id commit present + clean tree ⇒ item cleared") no longer discriminates. What is the authority for "done" on resume, and how are the multiple per-item writes ordered?
- **Decision:** The committed terminal ledger `done` entry becomes the **sole authority for done**. Remove the "item-id commit + clean tree ⇒ cleared" forward-reconcile shortcut and fold it into re-verify-then-record. Pin the write-ordering invariant: the terminal ledger entry is the **last write per item**, committed after the item's code commit(s); the committed record stays append-only and mutable per-item state stays session-local. `scan-run-history.sh` needs no change for done-authority — it already reports `done` from the ledger, not from commit presence.
- **Rationale:** With every iteration committed, an item-id commit plus a clean tree is now the normal state of *every* in-progress item, so the old shortcut would mark not-yet-cleared items done. The ledger `done` entry, written last and after the code commit, keeps a partial write tail-safe: an interruption between the code commit and the done entry leaves a recoverable, re-verifiable state rather than a falsely-done item. The scanner already keys done on the ledger, so it stays judgment-free.
- **Evidence:** `SKILL.md:257-263` (the forward-reconcile shortcut being removed); `durable-record-protocol.md:61-69` (the integrity matrix — done is authoritative only when its referenced commit resolves); `SKILL.md:382-383` (done entry committed after the code commit); `scan-run-history.sh:143-172` (scanner reports done from the ledger, not commit presence); consolidates CL-8 (junior JD-004, on-call F3), CL-9 (on-call F2, devops item 3, junior JD-010), CL-10 (on-call F3).
- **Rejected alternatives:**
  - Keep the "item-id commit + clean tree ⇒ cleared" forward-reconcile shortcut — rejected because under commit-everything the tree is always clean and every in-progress item carries an item-id commit, so the shortcut is unsound; fold it into re-verify (`SKILL.md:257-263`).
  - Have the scanner infer done from commit presence — rejected because the scanner must stay judgment-free and the ledger already carries the authoritative done signal (`scan-run-history.sh:143-172`).
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** a done entry is observed surviving while its referenced code commit is provably gone in a way the integrity default-deny does not already catch.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, On-Call Resilience Posture, Testing Strategy.

### D-8: Four distinct commit trailers for item-id run fixup and baseline

- **Question:** With code commits, bookkeeping commits, review-addressing collapsible commits, and the scope-baseline all needing to be identifiable in history, what is the concrete trailer scheme?
- **Decision:** Four distinct git trailers, each matched by exact key: the **item-id** trailer (`Implement-Work-Items-Item: <W-N>`) on **code** commits only; the **run** trailer (`Implement-Work-Items-Run: <normalized path>`) on **bookkeeping** commits (never item-id, or the scanner misreads them as resolved code); a **distinct fixup** trailer (`Implement-Work-Items-Fixup: <W-N>`) for review-addressing collapsible commits, as a git trailer rather than native `fixup!`; and a **distinct baseline** trailer for the scope-baseline recovery (D-2), never reusing the item-id trailer.
- **Rationale:** The scanner classifies a commit as resolved code by the item-id trailer, so bookkeeping commits must never carry it. A collapsible review-addressing commit needs its own marker so the operator (or a later tool) can collapse it; a git trailer is greppable and keyed exactly, whereas native `fixup!` keys on the subject line and buys nothing the spec needs. A distinct baseline trailer keeps the scope-baseline lookup from colliding with resolved-code detection.
- **Evidence:** `durable-record-protocol.md:15-17` (item and run trailers, exact-key match, positional done reference); `scan-run-history.sh:132-136` (item-id trailer drives resolved/unresolved); consolidates CL-11 (devops item 3d, junior JD-008, software-architect A5).
- **Rejected alternatives:**
  - Use native `fixup!` for review-addressing commits — rejected because it keys on the subject line, not a greppable trailer, and buys nothing the collapsible-marker requirement needs (`durable-record-protocol.md:15-17`).
  - Reuse the item-id trailer for bookkeeping or baseline commits — rejected because the scanner reads that key to detect resolved code commits; overloading it misclassifies bookkeeping as code (`scan-run-history.sh:132-136`).
- **Specialist owner:** devops-engineer
- **Revisit criterion:** native `fixup!` gains a capability the trailer scheme lacks, or a fifth commit class appears that the four trailers cannot distinguish.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-7 (done authority reads the item-id trailer positionally), D-10 (trailers travel with the relocated path).
- **Referenced in plan:** Data Model and Persistence, External Interfaces.

### D-9: Drop the .gitignore hack and track the whole artifact area

- **Question:** The setup step writes `.implement-work-items/.gitignore` as two lines (`*` then `!progress.md`) so only the ledger is tracked. With `state.json` gone (D-2) and review records now committed (spec D10), is anything left to ignore?
- **Decision:** Drop the two-line `.gitignore` hack entirely — with `state.json` deleted and review records tracked, nothing under `.implement-work-items/` needs ignoring. Track the whole area. Re-verify that all four **path-based** exclusion sites still hold, since they are path-based and orthogonal to the tracked/ignored axis.
- **Rationale:** The `.gitignore` existed only to keep `state.json` and the review records out of history while tracking `progress.md`. Deleting `state.json` and committing the review records removes both reasons, so the file has nothing left to do. The exclusion sites that keep bookkeeping out of an item's code commit are path-based (they match the `.implement-work-items/` directory), not ignore-based, so they must be independently re-verified after the ignore rule is removed.
- **Evidence:** `SKILL.md:196-197` (the two-line `.gitignore` setup); `durable-record-protocol.md:72-84` (the four path-based exclusion sites and the note that placing artifacts in the directory makes the exclusion path-based); consolidates CL-12 (devops item 3c, junior JD-007, software-architect A5).
- **Rejected alternatives:**
  - Keep the `.gitignore` hack — rejected because with `state.json` gone and review records tracked there is nothing left to ignore; the file becomes dead machinery.
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a new artifact under `.implement-work-items/` must be ignored rather than tracked.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-10 (the relocated path must keep the exclusion covering the area at its new depth), D-15 (the exclusion re-grounding is documented in `durable-record-protocol.md`).
- **Referenced in plan:** Data Model and Persistence, Operational Readiness, RAID Log.

### D-10: Relocate the artifact area by deriving its path from the work-items directory

- **Question:** Spec D4 moves the run-artifact area from the repo root into the plan folder. How does the scanner and every literal path reference follow the move without a new argument, and what breaks if the exclusion stays root-anchored?
- **Decision:** Derive the ledger path from `dirname(NORM_PATH)` inside `scan-run-history.sh` (no new argument — the work-items path the scanner already receives determines the plan folder). Move every literal `.implement-work-items/` reference to the derived location. Highest-risk: make the scope-diff exclusion match the `.implement-work-items/` directory **at any depth** once it is nested under the plan folder, not root-anchored, or the now-tracked review files leak into scope findings.
- **Rationale:** The scanner already receives the normalized work-items path, so the plan folder is `dirname` of it — no new config knob is needed. Once the artifact area is nested rather than at the repo root, a root-anchored exclusion pattern no longer matches it, so tracked review records would surface as scope findings and stall the gate. Matching the directory at any depth is the lockstep change that keeps the exclusion holding after the move.
- **Evidence:** `scan-run-history.sh:124` (the hard-coded `HEAD:.implement-work-items/progress.md` read that must become derived); `review-verdict-contract.md:80` (the scope-diff exclusion `excluding .implement-work-items/` that must match at any depth); consolidates CL-13 (devops item 5, junior JD-002, software-architect A5).
- **Rejected alternatives:**
  - Add an `--artifact-dir` (or `--base`-style) config argument to locate the area — rejected because `dirname(NORM_PATH)` already determines it from the path the scanner receives; a knob no caller sets is speculative configuration.
  - Keep the exclusion root-anchored — rejected because once the area is nested it no longer matches, and tracked review files leak as scope findings (`review-verdict-contract.md:80`).
- **Specialist owner:** devops-engineer
- **Revisit criterion:** `dirname(NORM_PATH)` proves an unreliable anchor (for example a work-items file placed at the repo root with no containing plan folder).
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-15 (the relocated path is documented in `durable-record-protocol.md`).
- **Referenced in plan:** Data Model and Persistence, Testing Strategy, Security Posture, RAID Log.

### D-11: Extend the context detector with ahead-behind counts and a fetch-status flag

- **Question:** Spec D2 needs ahead/behind counts per base candidate and a fetch-freshness signal. Where does that computation live, and does the read-only detector run `git fetch`?
- **Decision:** Extend `detect-driver-context.sh` (pure git, read-only). Compute ahead/behind per candidate in the fixed candidate set via `git rev-list --left-right --count <base>...HEAD`. Emit `fetch-status: ok|failed` computed from already-fetched remote-tracking refs. Keep the `git fetch` itself in `SKILL.md` so the detector stays read-only. Detached HEAD is already handled (`branch: none`).
- **Rationale:** The ahead/behind signal is the direct detector of the real first-run failure (a base missing a dependency the branch already carried), and it is pure git plumbing that belongs with the other detector output. Keeping the fetch in `SKILL.md` preserves the detector's read-only contract. A binary `fetch-status` is enough to mark counts as possibly stale; per-remote partial-fetch detail is not needed to make the operator ask.
- **Evidence:** the existing detector already emits `branch` and `default-branch` (`detect-driver-context.sh:19-21`) and handles the git-absent and detached cases; devops verified the `git rev-list --left-right --count` plumbing in-repo; consolidates CL-14 (devops item 4, software-architect A6).
- **Rejected alternatives:**
  - Per-remote partial-fetch parsing — rejected because a binary `fetch-status: ok|failed` suffices to mark counts stale and ask; per-remote detail is unobserved-case machinery.
  - Run `git fetch` inside the detector — rejected because it would break the detector's read-only contract; the fetch stays in `SKILL.md`.
- **Specialist owner:** devops-engineer
- **Revisit criterion:** a per-remote or partial-fetch signal proves necessary beyond the binary `fetch-status`.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Testing Strategy, Security Posture.

### D-12: Extend the review-verdict contract for below-threshold detail, prior-iteration diff, and approved coherence paths

- **Question:** Spec D6/D7/D10 add three review-time needs: reading below-threshold detail, diffing iteration-to-iteration, and not re-raising approved coherence edits. What does `review-verdict-contract.md` gain?
- **Decision:** `review-verdict-contract.md` gains three inputs/outputs: below-threshold detail read from the durable record (D6) rather than acted on as counts alone; an iteration-to-iteration diff with a **defined "prior" reference** (the latest committed iteration compared against the prior committed one, D10); and an already-approved-coherence-paths input so a review does not re-raise approved sibling-file edits (D7).
- **Rationale:** The verdict already returns below-threshold findings as counts only, with detail in the durable record, so acting on D6 requires an explicit record read the contract must name. Confirming a fix by diff (D10) requires a defined "prior" ref, which the commit-every-iteration cadence now supplies. Threading approved coherence paths into the review dispatch is what stops a fresh per-round reviewer from re-raising an approved edit and stalling the gate.
- **Evidence:** `review-verdict-contract.md:20-26` (reference material the dispatch supplies, and the scope-baseline input); `review-verdict-contract.md:79-85` (the per-dispatch full-diff scope computation that re-raises approved edits without a threaded approval); consolidates CL-15 (junior JD-009, software-architect A1/A3).
- **Rejected alternatives:**
  - Act on below-threshold counts alone without the record read — rejected because the detail needed to judge which below-threshold findings matter lives only in the durable record (`review-verdict-contract.md:20-26`).
  - Leave "prior" iteration undefined — rejected because a fix-confirmation diff needs an unambiguous prior ref; the commit-every-iteration cadence defines it.
- **Specialist owner:** software-architect
- **Revisit criterion:** the review verdict must carry structured below-threshold detail inline rather than by a record read.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Testing Strategy.

### D-13: The D6 re-verify-fails branch reuses the existing fix loop and committed-state reset

- **Question:** Spec D6 requires re-verifying before committing a post-gate below-threshold fix. The spec covers the pass case; what happens when that re-verify comes back **red**?
- **Decision:** On a red re-verify of a post-gate below-threshold fix, do not commit the fix. Reset to the already-committed gate-cleared iteration, or route into the not-cleared fix loop; never carry the dirty reddening tree into the next dispatch. Reuse the existing loop and committed-state reset — add no new rollback machinery.
- **Rationale:** This closes the D6×D8 seam: a post-gate fix that reddens re-verify must not become the tree a later dispatch inherits, or the clean-tree-at-dispatch guarantee (spec D8) breaks. Because every gate-cleared iteration is already committed (D-5/D-7), resetting to it is a plain checkout of committed state — the existing reset the recovery menu already uses — so no new rollback code is warranted.
- **Evidence:** the spec's Edge Cases row "A below-threshold fix on a green gate introduces a new above-threshold defect" requires re-verification before commit but is silent on the red branch (`feature-specification.md`, Edge Cases; `decision-log.md` D6); the existing committed-state reset in the recovery menu (`SKILL.md:430-435`, skip returns the tree to the last clean committed baseline); consolidates CL-16 (on-call F4).
- **Rejected alternatives:**
  - Add dedicated rollback machinery for the red-re-verify branch — rejected because the gate-cleared iteration is already committed, so the existing reset covers it; new machinery is unjustified.
- **Specialist owner:** on-call-engineer
- **Revisit criterion:** reusing the existing reset proves insufficient and a dedicated rollback is forced.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, On-Call Resilience Posture.

### D-14: One new sub-agent-instructions reference that also carries the accumulated corrections

- **Question:** Spec D11 (role-scoped instruction set) and D9 (accumulated corrections) both need a home, and `SKILL.md` is near its progressive-disclosure ceiling. How many new references, and where does D9 live?
- **Decision:** Add **one** new reference, `sub-agent-instructions.md`, holding the D11 shared baseline plus the role-scoped build and review payloads. **Fold D9 into it** — the injection rules for accumulated corrections live in that reference, their storage is a durable block in the record (D-3), and a `SKILL.md` capture step records them. Do **not** create a standalone `preference-memory.md`.
- **Rationale:** D9's mechanics are small — inject accumulated corrections into the build payload, store them as a record block, capture them at the right step. A standalone reference for that would be a single-consumer file. Folding the injection rules into the sub-agent-instructions reference (which already owns the build payload), the storage into the record, and the capture into `SKILL.md` keeps `SKILL.md` under its ceiling without adding a file that has one reader.
- **Evidence:** `SKILL.md` at ~460 of a 500-line ceiling (`.discovery-notes.md:14`); operator feedback #2 (a file of common sub-agent instructions); consolidates CL-17 (software-architect A3).
- **Rejected alternatives:**
  - A standalone `preference-memory.md` reference for D9 — rejected as a single-consumer file; its injection rules fold into `sub-agent-instructions.md`, its storage into the record block, its capture into `SKILL.md`. Deferred under YAGNI with a reopen trigger (see the plan's Deferred (YAGNI) section).
- **Specialist owner:** software-architect
- **Revisit criterion:** OI-2's correction-class judgment rubric grows into substantial standalone content that needs a third independent consumer, justifying splitting `preference-memory.md` back out.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-3 (corrections are stored as a durable record block).
- **Referenced in plan:** Architecture and Integration Points, Runtime Behavior, Deferred (YAGNI).

### D-15: durable-record-protocol absorbs the collapsed record, commit model, relocated path, and re-grounded exclusion

- **Question:** The collapsed record format, the commit model (D10), the relocated path (D4), and the path-based exclusion all need documenting. New reference, or extend an existing one? And what happens to `re-grounding-routine.md`'s `state.json` section?
- **Decision:** `durable-record-protocol.md` **absorbs** the collapsed record format, the commit model (D10), the relocated path (D4), and the re-grounded (path-based) exclusion — no new "collapsed-record" reference is created. `re-grounding-routine.md` loses its `state.json` section, since `state.json` is deleted (D-2).
- **Rationale:** `durable-record-protocol.md` already owns the record format, the trailer scheme, and the exclusion checklist, so the collapse, commit model, path move, and exclusion re-grounding are edits to the file that already governs them, not a new file. Deleting `state.json` makes the re-grounding routine's state.json section dead prose that must be removed so a future reader does not rebuild a store that no longer exists.
- **Evidence:** `durable-record-protocol.md` (already owns the format, trailers, integrity matrix, and four-site exclusion checklist); `re-grounding-routine.md:22-25` (the state.json section being removed); consolidates CL-18 (software-architect A1).
- **Rejected alternatives:**
  - Create a new "collapsed-record" reference — rejected because `durable-record-protocol.md` already governs the record format and exclusion; a second file would split one contract across two homes.
- **Specialist owner:** software-architect
- **Revisit criterion:** `durable-record-protocol.md` exceeds a readable size after absorbing the additions and must split.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach, Architecture and Integration Points.

### D-16: Two-wave build order with four contract seams co-landing atomically

- **Question:** In what order do the pieces land, and which changes cannot be split across separate landings without breaking resume?
- **Decision:** Build in two waves plus an independent set. **Wave 1 (keystones, land atomically):** the record & commit model (spec D12+D10+the D4 location+the `.gitignore` drop+the writer+the scanner) and the dispatch set (spec D11+D9+the D7 review payload). **Wave 2:** spec D8, D6, D7, D9. **Independent:** spec D2, D3, D5. Four shared-contract seams **must co-land in the same unit**: (1) the ledger grammar ↔ scanner regex, (2) the trailers/markers, (3) the relocated path, (4) the `.gitignore` + exclusion decoupling. A one-sided change to any seam reconstructs zero items on resume.
- **Rationale:** The record and commit model is the keystone every other change reads or writes through, so it lands first and atomically. The four seams are two-party contracts (a writer and a reader, or a path and its exclusion); splitting either side across landings leaves an intermediate state where resume reconstructs nothing. Spec D2/D3/D5 touch no shared record contract, so they land independently.
- **Evidence:** the dependency edges in the spec decision log (spec D8→D10, D9→D10/D12 — `decision-log.md` D8, D9, D10, D12 dependent-decisions fields); `scan-run-history.sh:138-144` (the grammar is a two-party contract a one-sided change breaks); consolidates CL-19 (software-architect A4) and CL-20 (software-architect A5, junior JD-001, devops item 5).
- **Rejected alternatives:**
  - Land the writer, scanner, path, or exclusion changes independently of their paired side — rejected because each is one half of a two-party contract; a one-sided landing reconstructs zero items on resume (`scan-run-history.sh:138-144`).
- **Specialist owner:** software-architect
- **Revisit criterion:** a dependency edge is discovered that reorders the waves, or a seam is found that can safely land one-sided.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Decomposition and Sequencing, RAID Log.

### D-17: Verify the two scripts with a minimal pure-bash round-trip harness

- **Question:** The repo has no test suite. The Round-1 handoff to `test-engineer` errored with no output. How are the new/changed pure-bash scripts verified, and at what level?
- **Decision:** Add a minimal pure-bash test harness (throwaway git repos + fixture ledgers, assuming only `git`+bash) covering the highest-value surfaces: the `write-run-record.sh` ↔ `scan-run-history.sh` grammar **round-trip** (writer output reconstructs to the exact four-token lifecycle, and the new appended blocks do not perturb that reconstruction), the scanner's fresh/resume/refuse/no-base classification with the D4 path-derivation and the D10 done-from-ledger-only change, and `detect-driver-context.sh`'s D2 ahead/behind + fetch-status across in-sync / ahead / diverged / detached-HEAD / fetch-failure. Model-judgment behaviors stay scenario/manual against the spec's Edge Cases table.
- **Rationale:** `scan-run-history.sh:138-144` documents a silent-failure mode — a writer change "silently reconstructs zero items" — and D-4 adds exactly the writer that must round-trip with that reader, so a round-trip test is justified by a real, documented break, not speculation. A minimal harness on the deterministic scripts catches the one silent-failure class; model judgment (token choice, gate decisions) is not script-testable and stays scenario-based. The harness assumes only `git`+bash to match the portability floor (D-1).
- **Evidence:** `scan-run-history.sh:138-144` (the documented grammar-drift silent-failure mode); the R1 next-step handoff naming `test-engineer` for the scripts' testing strategy, and the R2 record that the handoff errored and the strategy folds from R1 evidence (`implementation-iteration-history.md` R1/R2); consolidates the folded R1 testing evidence.
- **Rejected alternatives:**
  - Manual/scenario-only verification, as the sibling resume plan used — rejected here because the added writer creates a documented silent grammar-drift failure a round-trip test catches deterministically; manual reads do not (`scan-run-history.sh:138-144`).
  - A full combinatorial classification matrix across every token × path × trailer combination — rejected as YAGNI; the round-trip plus the boundary cases (empty ledger, foreign-run trailer, unresolved done, `..`/`./` path, the W-1-vs-W-10 substring trap) cover the realistic failure modes.
- **Specialist owner:** test-engineer (dispatched at implementation; strategy PM-authored in synthesis after the R2 handoff errored)
- **Revisit criterion:** a code test harness is later standardized for the wider suite, or the round-trip test proves insufficient to catch a grammar-drift regression.
- **Dissent (if any):** —
- **Driven by rounds:** R1, R2
- **Dependent decisions:** —
- **Referenced in plan:** Testing Strategy, Decomposition and Sequencing, Definition of Done.
