# Implementation Iteration History: implement-work-items First-Run Hardening

Round-by-round record of the `plan-implementation` team. See [implementation-decision-log.md](implementation-decision-log.md) for committed decisions and [../feature-implementation-plan.md](../feature-implementation-plan.md) for the plan.

## R1

- **Specialists engaged:** `han-core:devops-engineer`, `han-core:on-call-engineer`, `han-core:software-architect`, `han-core:junior-developer` (parallel). PM not called (facilitation is deterministic; PM reserved for synthesis).
- **New input provided:** the feature spec + decision log, the discovery notes, and the current skill (`SKILL.md`, `references/`, `scripts/`). Domain briefs targeted: the ledger format/tooling decision (devops), bookkeeping/commit-cadence resilience (on-call), decomposition/sequencing/structure (software-architect), and generalist stress-test of implementation contracts (junior).
- **Spec-maturity tags:** every finding is `plan-level`. No `spec-level` findings (the spec is behaviorally complete; all findings are HOW-to-implement contracts). No `T#`-contradictions (no `feature-technical-notes.md` exists). **Spec-maturity gate: not tripped.**
- **Project-manager review (gate-trip pass):** n/a — gate not tripped.

### Claim ledger (consolidated)

**Run-record format (the operator's flagged decision) — Evidenced, unanimous**
- CL-1: Keep the shell-parseable line-grammar; do **not** adopt JSON; do **not** make `jq`/`python3` a hard requirement. Evidence: `.discovery-notes.md:9-11`, `SKILL.md:67-68` (git is the only hard dep), `scan-run-history.sh:143-158` (pure-bash reconstruction). Raised by devops(item 1), junior(JD-006); consistent with on-call. A hard `jq`/python dep is a **YAGNI/portability** rejection — it turns every jq-absent user repo from graceful hand-maintenance into a startup refusal.
- CL-2: **Delete `state.json`.** Four of its five fields (`state`, `fix-round`, `decision`, `commit-range`) are re-established per session; only `scope-baseline` is durable, and it is recoverable from committed history (a git pickaxe on the `start-of-item` ledger line, or a **distinct** baseline trailer — never reuse the item-id trailer, which the scanner uses to detect resolved code commits). Evidence: `durable-record-protocol.md:20-23`, `re-grounding-routine.md:22-25`, `scan-run-history.sh:132-136`. Raised by devops(1), junior(JD-005).
- CL-3: Carry the genuinely-new durable state — D6 dispositions, D7 approvals, D9 corrections — as **separate labeled blocks appended below the `Log:` block, whose 4-token grammar stays byte-for-byte untouched**, each new block parsed additively. Evidence: `scan-run-history.sh:138-144` (grammar is a two-party contract; a writer change silently reconstructs zero items). Raised by devops(1); software-architect(A1/A5) proposed new tokens in the alternation — resolved to the safer separate-blocks form so the shipped item-lifecycle regex is never touched.

**Bookkeeping script (D12) — Disputed → Resolved by evidence**
- CL-4: Add **one** append-only bookkeeping writer script (e.g. `write-run-record.sh`), mechanism-only (init / append `<token> <W-N>` / set-state), following the existing pure-bash deterministic-detector precedent; the model decides *which* token and owns the `git commit`, the script owns *how the line is spelled*. Raised by devops(2), on-call(F2), software-architect(A2). **Disputed** by junior(JD-006/JD-011) as YAGNI. **Resolved: include one script** — the documented first-run finalization failure (D12's own evidence) plus the writer/reader grammar-drift risk pass the evidence test; junior's concern is honored by capping at one script and keeping all judgment model-driven.

**Loop rewrite (D8/D10) — Evidenced, major**
- CL-5: "Commit before each dispatch" + "commit every iteration" is a **rewrite** of Steps 3.3/3.4, not an extension (today: one code commit per item, at 3.4). Add an explicit "commit in-flight work, then dispatch" step at every dispatch site (build, fix re-dispatch, review, recovery "Build further", foreground return); pin ordering strictly commit→dispatch. Evidence: `SKILL.md:304-393`. Raised by junior(JD-003), on-call(F1), software-architect(A4).
- CL-6: A **rejected pre-dispatch commit joins the marker-write / resumable-stop class**, never the code-fix loop; distinguish "clean tree, nothing to commit" (no-op → dispatch) from "hook rejected, tree still dirty" (fail-closed stop) via `git status --porcelain`. Evidence/gap: the spec classifies the two existing commit sites but not this new third one. Raised by on-call(F1).
- CL-7: Stage **every** iteration commit by path (`git add <path>`, never `git add -A`), covering new untracked files an iteration may create. Evidence: `SKILL.md:375`. Raised by devops(3a).

**Resume authority (D10) — Evidenced, major**
- CL-8: The committed terminal ledger `done` entry becomes the **sole authority for done**; remove the "item-id commit + clean tree ⇒ cleared" forward-reconcile shortcut (`SKILL.md:257-263`), which is unsound once every iteration is committed and the tree is always clean; fold it into re-verify-then-record. Evidence: `SKILL.md:257-263`, `durable-record-protocol.md:61-69`. Raised by junior(JD-004), on-call(F3).
- CL-9: Write-ordering invariant — the terminal ledger entry is the **last write per item, committed after the code commit(s)**; the committed record stays append-only, mutable state stays session-local. Keeps a partial write tail-safe and the interrupted-between-code-and-bookkeeping window recoverable. Evidence: `SKILL.md:382-383`. Raised by on-call(F2), devops(3), junior(JD-010).
- CL-10: `scan-run-history.sh` needs no change for done-authority (it already reports `done` from the ledger, not commit presence). Keep the detector judgment-free. Evidence: `scan-run-history.sh:143-172`. Raised by on-call(F3).

**Commit markers/trailers (D10) — Evidenced**
- CL-11: Concrete trailer scheme — item-id trailer on **code** commits only; run trailer on **bookkeeping** commits (never item-id, or the scanner misreads them as resolved code); a **distinct** fixup trailer (e.g. `Implement-Work-Items-Fixup: <W-N>`) for review-addressing collapsible commits, as a git **trailer** not native `fixup!` (native `fixup!` keys on the subject line and buys nothing the spec needs). Evidence: `durable-record-protocol.md:15-17`. Raised by devops(3d), junior(JD-008), software-architect(A5).

**`.gitignore` + exclusion + D4 relocation — Evidenced, major (silent-failure risk)**
- CL-12: Drop the `.implement-work-items/.gitignore` two-line hack — with `state.json` gone and review records tracked, there is nothing left to ignore; track the whole area. Re-verify all four **path-based** exclusion sites still hold (they are path-based, orthogonal to tracked/ignored). Evidence: `SKILL.md:196-197`, `durable-record-protocol.md:72-84`. Raised by devops(3c), junior(JD-007), software-architect(A5).
- CL-13: D4 relocation — derive the ledger path from `dirname(NORM_PATH)` in `scan-run-history.sh` (no new arg); move every literal `.implement-work-items/` reference; and (highest-risk) make the scope-diff exclusion match the dir **at any depth** once nested, not root-anchored, or tracked review files leak as scope findings. Evidence: `scan-run-history.sh:124`, `review-verdict-contract.md:80`. Raised by devops(5), junior(JD-002), software-architect(A5).

**D2 base detector — Evidenced**
- CL-14: Extend `detect-driver-context.sh` (pure git): ahead/behind via `git rev-list --left-right --count <base>...HEAD` per candidate in the fixed candidate set; `fetch-status: ok|failed` (keep `git fetch` in `SKILL.md`, detector stays read-only, computes from already-fetched remote-tracking refs); detached HEAD is already handled (`branch: none`). Evidence: devops verified the plumbing in-repo. Raised by devops(4), software-architect(A6).

**review-verdict-contract (D6/D7) — Evidenced**
- CL-15: `review-verdict-contract.md` gains: below-threshold detail read from the durable record (D6); an iteration-to-iteration diff with a **defined** "prior" ref (D10); a new already-approved-coherence-paths input (D7). Evidence: `review-verdict-contract.md:20-26,79-85`. Raised by junior(JD-009), software-architect(A1/A3).

**D6 re-verify-fails branch — Evidenced/gap**
- CL-16: Specify the re-verify-**fails** branch of a post-gate below-threshold fix: on red re-verify, do not commit the fix; reset to the already-committed gate-cleared iteration or route into the not-cleared fix loop; never carry the dirty reddening tree into the next dispatch (closes the D6×D8 seam). Reuse the existing loop + committed-state reset — no new rollback machinery. Raised by on-call(F4).

**Decomposition / structure — Evidenced**
- CL-17: One new reference `sub-agent-instructions.md` (D11 shared baseline + role-scoped build/review payloads); **fold D9** into it (injection rules) + the record (storage) + a `SKILL.md` capture step — no standalone `preference-memory.md`. Driver: `SKILL.md` at 460/500, operator feedback #2. Raised by software-architect(A3).
- CL-18: `durable-record-protocol.md` **absorbs** the collapsed record format + commit model (D10) + relocated path (D4) + re-grounded (path-based) exclusion; `re-grounding-routine.md` loses its `state.json` section. No new "collapsed-record" reference. Raised by software-architect(A1).
- CL-19: Build order — **Wave 1 (keystones):** the record & commit model (D12+D10+D4-location+`.gitignore`+writer+scanner, landed atomically) and the dispatch set (D11+D9+D7-payload); **Wave 2:** D8, D6, D7, D9; **Independent:** D2, D3, D5. Evidence: dependency edges in the decision log (D8→D10, D9→D10/D12). Raised by software-architect(A4).
- CL-20: Four shared-contract seams must co-land in the same unit: (1) ledger grammar ↔ scanner regex, (2) trailers/markers, (3) the relocated path, (4) `.gitignore`+exclusion decoupling. A one-sided change reconstructs zero items on resume. Raised by software-architect(A5), junior(JD-001), devops(5).
- CL-21: No new structure for D2/D3/D5/D8 — extend existing homes (`SKILL.md` prose or the detector script). Raised by software-architect(A6).

### Open Questions

- **OQ-1 (write-script scope):** include a bookkeeping writer script, or keep append-and-commit as prose? **Resolved in-round by evidence** (CL-4): include exactly one mechanism-only script.
- **OQ-2 (record shape / tooling):** JSON vs line-grammar; hard `jq`/python or not? **Resolved in-round by evidence** (CL-1/2/3): line-grammar, delete `state.json`, no hard `jq`/python. This is the operator's flagged decision.
- **OQ-3 (resume authority under commit-everything):** **Resolved in-round by evidence** (CL-8/9/10): ledger `done` entry is sole authority; fold forward-reconcile into re-verify; keep the detector dumb.
- All other findings resolved in-round by codebase evidence (cited above). **No Open Question requires user input.**

### Next-step recommendation

**Continue iterating (one named handoff).** All plan-level findings resolved by evidence, but `han-core:junior-developer` named a specialist handoff — `han-core:test-engineer` / `han-core:edge-case-explorer` — for the testing strategy of the new/changed scripts and the resume edge cases under the new commit cadence. Round 2 runs one focused handoff (`test-engineer`, covering both) to firm up the Testing Strategy section, then synthesis. The loop-rewrite/structural concern junior also flagged was already absorbed by software-architect (A4/A5) and on-call (F1/F3), so structural/behavioral handoffs are not separately engaged.

- **Decisions produced:** D-1, D-2, D-3, D-4, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12, D-13, D-14, D-15, D-16, D-18, D-19 (all evidence-settled from the round-1 claim ledger).
- **Changed in plan:** Implementation Approach (Architecture and Integration Points, Data Model and Persistence, Runtime Behavior, External Interfaces), Decomposition and Sequencing, RAID Log, Security Posture, Operational Readiness, On-Call Resilience Posture, Definition of Done.

## R2

- **Specialists engaged:** `han-core:test-engineer` (the Round-1 named handoff), briefed on the Testing Strategy for the pure-bash scripts and the writer↔reader grammar contract.
- **Outcome:** the agent **errored (connection closed mid-response) and returned no usable output.** Not retried, to avoid a second long hang.
- **Disposition:** the Testing Strategy is folded into synthesis, authored from the Round-1 evidence that already identified the testable surfaces — the writer↔reader grammar round-trip (CL-1/CL-3, `scan-run-history.sh:138-144`), resume reconstruction with `done` as sole authority (CL-8/CL-10), `detect-driver-context.sh` ahead/behind + fetch-status (CL-14), and the portability constraint that tests assume only `git`+bash (CL-1). No new findings; no unresolved Open Question.
- **Spec-maturity gate:** not tripped (unchanged).
- **Next-step recommendation:** **go to synthesis.** All plan-level findings resolved by evidence; the one named handoff was attempted and failed technically, with its scope recoverable from Round-1 evidence.
- **Decisions produced:** D-17 (the round-trip testing harness; folded from round-1 evidence after the R2 handoff errored).
- **Changed in plan:** Testing Strategy, Decomposition and Sequencing, Definition of Done, Specialist Handoffs for Implementation.
