# implement-work-items: second end-to-end run feedback

Feedback from the second full end-to-end run of the `implement-work-items` driver. The
run drove the 13-item `work-items.md` that builds the first-run-hardening feature (base
resolution, the collapsed committed record, commit-every-iteration, resume done-authority,
below-threshold and coherence handling, and the pure-bash bookkeeping scripts) into the
`implement-work-items` skill itself. So, like the first run, this was a dogfood of the
driver editing its own definition, one layer removed: the run executed the *current*
(pre-hardening) skill logic while committing the hardened replacement.

Verification ran in **scope-check-only** mode (the repo defines no project test suite);
the three script items carried their own `*.test.sh` harnesses, which the `tdd` builds
and the driver ran directly. All 13 items built, reviewed, and committed; none halted,
none went unreached. Ten items took a human (HITL) review, three ran fully unattended,
and the last two were switched to AFK-review-only mid-run to finish faster.

This first section is the driver's (Claude's) retrospective. The operator will add their
own feedback below.

## What worked

- **The review gate caught real, serious bugs.** This is the strongest signal of the run.
  The `code-review` panel plus its adversarial-validator found genuine defects before they
  landed: W-2's `write-run-record.sh` had a newline-injection into the sole-authority
  record (a `\n` in an argument forged a grammar-valid `- skip: W-9` Log entry, silently
  dropping a real work item on resume), a silent-truncation path (masked pipe exit status
  under `set -u`), and a two-`Log:`-header reorder; W-3's `scan-run-history.sh` had a
  path-traversal disclosure (a `../`-bearing arg read a `.implement-work-items/progress.md`
  outside the repo). Every one was reproduced against the code, not asserted. The fix loop
  closed them with reproducing tests. Without the gate these ship.
- **The per-item loop and clean commit history held across all 13 items.** Start-of-item
  entry, build, verify, review, fix, commit, done, for each item, with one clean code
  commit per item carrying `Implement-Work-Items-Item: <W-N>` and bookkeeping commits kept
  separate. The tree was clean at every item boundary; the scope check never let stray work
  fold in. The whole run reverts item-by-item.
- **The decomposition and run order were right.** Foundation-contract-first (W-1 pinned the
  record + trailer contract before any consumer), the writer→reader dependency (W-2→W-3
  with a round-trip test proving they agree), and the shared-file linearization of `SKILL.md`
  (W-8→W-13 chained) all held with zero conflicts. The marker classification
  (`general-purpose`/`none`-HITL for skill-markdown, `tdd`/`code-review`-AFK for scripts)
  matched the work.
- **The AFK-self-review-before-HITL pattern (operator-directed) earned its keep.** Running a
  `general-purpose` review (checking against the plugin-building guidance and the operator's
  style rules) before every HITL hand-off caught real must-fixes the human would otherwise
  have had to catch: W-8's bare script path (`${CLAUDE_SKILL_DIR}` missing), W-9's no-output-
  audit iteration-commit gap and the foreground-vs-AFK commit-failure ambiguity, W-11's
  strictly-behind base gap, W-13's backward-reference leak. The HITL then spent its attention
  on higher-order judgment (W-1's contract shape, W-5's copy-vs-read design question) rather
  than mechanical defects.
- **The "well, duh!" compactness heuristic (introduced mid-run) worked and generalized.**
  Framed as "if a sentence makes you go 'well, duh!', it is probably an unnecessary
  restatement," it cut genuine bloat (the clean-tree invariant stated three times in W-9's
  loop) while a well-instructed reviewer correctly left load-bearing sentences alone
  (the no-output-audit carve-out, the `Never [X] BECAUSE [Y]` rationale). Folded into every
  later skill-prose review with no trouble.
- **The upstream planning chain paid off.** Each build agent got the committed spec, plan,
  and work item as context; the work items were mostly well-scoped, so most builds landed
  correct on the first pass and needed only review polish.

## What failed or was awkward

- **The driver's own bookkeeping was entirely manual prose, again.** The run hand-maintained
  `state.json` (per-item `jq` state transitions) and hand-appended every `progress.md` entry
  and hand-built every commit and its trailers, in long repeated Bash blocks, one set per
  item. This is exactly the "bookkeeping is all manual prose" friction the first run flagged
  and that D12 scripts. The irony is sharp: this run *built* `write-run-record.sh` to do this
  deterministically, but drove with the old logic and never used it for its own record. The
  boilerplate was verbose and felt error-prone (state file, code commit, progress append,
  state file, per item).
- **The nested-agent review bug bit exactly as the deferred harness feature predicted.** The
  `code-review` adversarial-validator (a sub-sub-agent from the driver's view) hung on W-3,
  leaving the review agent stalled until the operator killed it (the panel had already
  persisted its verdict record, so no work was lost, but it needed an interruption and a
  manual read of the durable record to recover). A hardened poll-loop-plus-persist-record
  workaround let W-4's validator return cleanly, but the bug is real and unfixed. This is the
  harness limitation this feature deliberately scoped out to its own feature; the run is a
  live argument for building it.
- **Reviews were the dominant wall-clock cost, and slow.** The full `code-review` fan-out
  panel ran 8-17 minutes per pass. W-2 alone took three review passes (iter0, iter1, iter2)
  across two fix rounds, so its review time dwarfed its build time. A full adversarial panel
  on a 120-line pure-bash script is heavy for the risk.
- **Fix-round re-reviews re-ran the whole panel and surfaced fresh (sometimes stale) noise.**
  Each W-2 re-review found new issues rather than just confirming the prior fixes: iter1
  raised two genuinely new findings, and iter1 also filed three *false* Criticals from stale
  reads that the validator had to refute. A fix-round re-review really only needs to confirm
  the named findings are resolved and check for regressions; the fresh full panel added cost
  and noise. The targeted driver re-review I did for W-3's fix round (verify the three
  findings landed, inspect the code, run the tests) was far faster and sufficient.
- **A cross-cutting cleanup fell through the decomposition.** `state.json` removal was split
  across W-6 (references), W-8 (SKILL.md setup), and W-9 (SKILL.md loop), and one site
  (`no-output-completion.md`'s `state.json` line) was owned by no item. I folded it into W-6
  as an approved coherence fix, but a cross-cutting "remove X everywhere" concern shouldn't
  rely on catching an orphan. Similarly, the re-verify-fails branch (D-13) was listed under
  W-9 but is tightly coupled to W-12's below-threshold flow, so I deferred it to W-12; the
  decomposition seam did not match the coherence unit.
- **`SKILL.md` grew past its own 500-line ceiling (460 to 532).** The loop, gate, and
  base-resolution prose all had to live in the skill body because of an architectural
  constraint (nothing yet lets this logic move out), so the skill now violates the very
  progressive-disclosure limit it is reviewed against. De-bloating is deferred to a separate
  feature, but the skill shipped over its stated limit.
- **`SKILL.md` kept getting touched between read and edit.** Several edits failed with "file
  modified since read" (a formatter-on-save or the operator editing directly), forcing
  re-reads mid-edit. Minor, but it interrupted the edit flow repeatedly.
- **Dogfood artifact: the run's record location is now inconsistent with the skill it built.**
  This run created `.implement-work-items/` at the repo root (old behavior), but W-3/W-8/W-10
  relocated the record to the plan folder and made the scanner derive that path. Had the run
  needed to resume, the new scanner would not have found the root-level record and would have
  misclassified the run as fresh. Acceptable for a single live session, but an inherent hazard
  of editing the resume machinery while relying on it.
- **The operator's style rules were hand-threaded into every build brief, and some still
  slipped.** "No meta-commentary, no backward-references, no decision-IDs, compact" went into
  every dispatch by hand, yet W-13 still shipped a backward-reference ("rather than only
  instructing the user and halting") and W-8 shipped a redundant restatement, both caught only
  in review. This is the exact style-drift the D9 preference-memory targets; the run showed
  both the value of that feature and that even careful hand-threading is leaky.
- **The `done-no-commit` (reconstructed-state name) vs `no-commit-done` (Log token) split kept
  reading as a possible bug.** It is intentional (the scanner maps one to the other), but it
  surfaced as a "wait, is this inconsistent?" question in more than one review.

## What to improve

1. **Have the driver use its own bookkeeping script.** The single biggest toil this run
   re-lived. Once the hardened skill is live, `write-run-record.sh` should do every record
   write; the manual `jq`/`git` per-item boilerplate should not exist.
2. **Build the flat-review-dispatch / harness-workaround feature.** The review step is both
   the slowest part of the run and the one that hangs. Dispatching the review fan-out flat
   from the driver (the deferred feature) is the fix; this run is the second strong argument
   for it.
3. **Offer a tiered review.** A full adversarial panel is right for a security-sensitive
   script like the record writer, but overkill for a small markdown edit or a 120-line
   script. A lighter default with escalation to the full panel would cut most of the
   wall-clock.
4. **Scope fix-round re-reviews to "did the named findings land, and any regressions?"**
   rather than re-running a fresh full panel. The targeted driver re-review pattern (confirm
   each finding, inspect, run tests) was faster and adequate; make it the default for a fix
   round.
5. **Make the AFK-self-review-before-HITL pattern part of the driver.** It measurably improved
   the quality of what reached the human. A HITL-review item should get an automated pass
   first by default.
6. **Make the compactness lens a standing part of skill-prose review.** The "well, duh!" test
   found real bloat and cost nothing; it should be default for skill-editing items, not an
   opt-in the operator has to request.
7. **`plan-work-items` should co-locate cross-cutting cleanups.** A "remove `state.json`
   everywhere" concern should be one item that enumerates every site, or the plan should list
   every touch point so no orphan survives. Coherence units (like re-verify-fails + the
   below-threshold flow) should not be split across items whose file scopes force a deferral.
8. **The architectural constraint that forces everything into `SKILL.md` needs the de-bloating
   feature.** The skill is now over its own ceiling; the constraint (no clean way to move
   loop/gate logic into references without losing the driver's inline control flow) is the
   real blocker.

## The meta-point

Like the first run, this one is a strong argument for the feature it produced, and for one it
did not: nearly every friction above is something the hardening this run built (or the harness
feature it deferred) directly addresses, but which was not active because the run drove the old
logic. Manual bookkeeping is what D12 scripts. Style drift across items is what D9 remembers.
The record-location hazard on resume is what D4 and the reader's derived path fix. The slow,
hanging reviews are what the deferred flat-dispatch feature contains. The driver spent the run
re-experiencing the exact problems it was committing the fix for. What is genuinely new this
time is the positive: the review gate demonstrably caught real security bugs, and two process
moves (an automated review pass before the human, and a plain-language compactness test) proved
worth institutionalizing.

## Operator feedback

`write-run-record.sh init` should create directory itself

`detect-driver-context.sh` should fetch itself

everything that can be automated should be automated

re-grounding procedure and other state discovery routines should use shell scripts
to query git log and progress.md instead of instructing agent to come up with its own probes

write-run-record.sh can perform commit maintenance itself; this will also allow removing
a bunch of instructions and protocols that orchestrator has to remember. the same script
can keep track of git worktree state so that agent doesn't have to re-verify it every time.
overall, under happy path agent should need git only for committing code

sub-agent hand-off protocols and references are over-complicated; we need one reference
for orchestrator that instructs how to write sub-agent's prompt and read its output,
and another reference that contains all guidance for sub-agent. Orchestrator doesn't read
sub-agent-specific references, just passes a path to them. Plus, we need to rename
our reference files to clearly label which file is intended for which actor, and make naming
consistent

we still struggle with filepath-based scope checks. proposal: drop the entire expected-paths
mechanic, instead instruct review agent to judge scope itself based on diff that it sees

we don't have clear instructions about whether orchestrator handles findings itself
or delegates to sub-agent. spawning a sub-agent to make a one-line change is costly,
but having orchestrator to make lots of changes is costly as well

we don't durably save decisions user made before item (require decision: yes), which makes
clean resume impossible

we don't mark iterations in ledger, making restart procedure harder than necessary.
do we even commit review findings in between?

add to base candidates: dev, develop, development, trunk
