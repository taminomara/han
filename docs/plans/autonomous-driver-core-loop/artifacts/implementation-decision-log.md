# Implementation Decision Log: Autonomous Driver — Core Loop (`implement-work-items`)

<!--
This file records every implementation decision committed while planning the
`implement-work-items` skill. Behavioral and implementation statements live in
[../feature-implementation-plan.md](../feature-implementation-plan.md) — this file
captures the question, rationale, evidence, and rejected alternatives for each decision.
Round-by-round history lives in [implementation-iteration-history.md](implementation-iteration-history.md).

The source spec's own decisions are cited as "spec D-N" and live in
[decision-log.md](decision-log.md). The resolved platform-capability findings are
cited as "discovery finding N" and live in [.discovery-notes.md](.discovery-notes.md).
No feature-technical-notes.md exists for the source spec, so no decision cites a T#.
-->

## Trivial decisions

- D-10: Branch-name default — the run's dedicated branch defaults to a feature-derived name in a `driver/{feature-dir}` style, unless the operator names one or the project convention dictates otherwise. Settled by convention from spec D15. — Referenced in plan: Implementation Approach (Runtime Behavior); Decomposition and Sequencing.
- D-11: Commit-convention detection — the driver reads CLAUDE.md or project-discovery for a stated commit convention and defaults to conventional commits when none is found. Settled by convention from spec D8. — Referenced in plan: Implementation Approach (Runtime Behavior).
- D-17: Skill name — the driver ships as `implement-work-items` (settled by user input, answering spec D20/OQ-1); skill directory `han-coding/skills/implement-work-items/`. — Referenced in plan: Outcome; Implementation Approach (Architecture and Integration Points).
- D-18: Plugin home and docs registration — the skill lives in the `han-coding` plugin beside `tdd` and `code-review`; its long-form doc is `docs/skills/han-coding/implement-work-items.md`, with a Skills Index entry under `## han-coding` in `docs/skills/README.md` and a catalog entry in root `CLAUDE.md`; `.claude-plugin/marketplace.json` is unchanged because the skill joins an existing plugin's `skills/` directory. — Referenced in plan: Decomposition and Sequencing.
- D-19: Cross-plugin prose-reference clearance — the `plan-work-items` Step 8 closing recommendation names `implement-work-items` and its `han-coding` plugin in prose only; this is a pointer, not a plugin dependency, so it does not require `han-planning` to depend on `han-coding` and does not violate CONTRIBUTING's dependency-direction rule. — Referenced in plan: Implementation Approach (Architecture and Integration Points); Decomposition and Sequencing.

## Full decisions

### D-1: Sub-agent dispatch mechanism

- **Question:** How does the driver invoke the build, fix, and review sub-agents so each runs a named skill on a per-run-selected model?
- **Decision:** The driver dispatches build, fix, and review sub-agents through the Agent tool, with a prompt that explicitly names the skill the sub-agent must run (`tdd` for building and fixing; `code-review` for reviewing) and passes a per-call `model`. The driver does not preload worker-agent definitions with a `skills:` frontmatter list.
- **Rationale:** The manual runs found sub-agents had to be told which skill to invoke or they would not run `tdd`/`code-review` (spec D10). The per-call model on the Agent tool is what wires the operator's build/fix model override (spec D12); a preloaded worker-agent definition bakes the model at definition time and would have to live in `han-core/agents/` per CONTRIBUTING, adding files for no gain. The Agent-tool-with-prompt path needs no new agent definitions and supports the per-call model directly.
- **Evidence:** spec D10 (driver-defined dispatch contract) and spec D12 (model selection policy) in [decision-log.md](decision-log.md); discovery finding 2 (three dispatch mechanisms; the Agent tool accepts a per-call `model`) and finding 4 (`skills:` preload bakes full content at startup) in [.discovery-notes.md](.discovery-notes.md); `han-coding` has no `agents/` directory (discovery Touch points).
- **Rejected alternatives:**
  - Preload worker-agent definitions with `skills:` frontmatter — rejected because it bakes the model at definition time (defeating the per-run override in spec D12), and the definitions would have to be added under `han-core/agents/`, a heavier surface than a dispatch prompt (discovery finding 4, Touch points).
- **Specialist owner:** software-architect (A1)
- **Revisit criterion:** the platform adds a per-call model override to the preload path, or the by-prompt skill-naming proves unreliable in dogfood.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-2, D-4, D-5
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points; Runtime Behavior)

### D-2: Review fan-out topology

- **Question:** Where does the review panel run so it fans out at full specialist coverage without entering the driver's context?
- **Decision:** The driver (running in the operator's main session) dispatches one review sub-agent at depth 1, which runs `code-review` and lets that skill fan out its specialist panel at depth 2. The review sub-agent must retain the Agent tool so it can spawn the panel: a deliberate exception to Han's default-no-`Agent`-tool convention (a coordinator dispatching a self-contained review worker that fans out its own panel, keeping the reviewers' context fresh and the panel's deliberation out of the coordinator's window). Han's agent guidance describes this same default-exception pattern, having been updated in light of this design work, so it is an alignment reference here, not independent evidence that the topology is sound. It returns only the condensed verdict (the `code-review` Review Recommendation, the severity counts complete at and above the gate threshold, and a full-coverage attestation) and persists the durable full record to a driver artifact; the panel's deliberation never enters the driver's context.
- **Rationale:** Running `code-review` from the driver's main loop would pull the panel into the driver's context (losing the context economy the skill exists for) and expose the review to the driver's builder-output bias (spec D9). A single reduced reviewer would discard the panel coverage that made review worth gating on (spec F8). Nesting is supported, so the review can run one level down and fan out one level further.
- **Evidence:** spec D9 (self-contained full-coverage review with a condensed verdict gate) in [decision-log.md](decision-log.md); discovery finding 1 (a sub-agent can spawn its own sub-agents as of Claude Code v2.1.172, hard 5-level depth cap; the review at depth 1 fans out the panel at depth 2; the Agent tool must be present for a sub-agent to fan out) in [.discovery-notes.md](.discovery-notes.md); team finding F8. (Han's agent guidance now describes the same default-exception pattern, but it was updated in light of this design work, so it is an alignment reference in the Decision above, not independent corroborating evidence.)
- **Rejected alternatives:**
  - Run `code-review` from the driver's main loop — rejected because it loads the panel into the driver's context and carries the driver's builder-output bias into the review (spec D9).
  - Run review as a single reduced reviewer inside one sub-agent — rejected because it discards the panel coverage that is the review's headline value (spec F8, spec D9).
- **Specialist owner:** software-architect (A2)
- **Revisit criterion:** the platform's depth cap changes, or authoring shows the depth-1 review sub-agent cannot reliably fan out the panel.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-3, D-4
- **Referenced in plan:** Implementation Approach (Runtime Behavior)

### D-3: Minimum Claude Code version prerequisite

- **Question:** What platform version must the operator's environment meet for the review fan-out to be trustworthy, and what happens below it?
- **Decision:** Claude Code v2.1.172 or later (nested sub-agents) is a required prerequisite for the review fan-out. The prerequisite is stated in the SKILL.md Constraints and in the long-form doc prerequisites, and is carried as a RAID assumption and risk. Below that version the review stage cannot fan out its panel, so its verdict cannot be trusted as a full-coverage pass; the core carries no reduced-coverage single-reviewer fallback, so this halts the run (spec F8) rather than degrading the gate.
- **Rationale:** The self-contained full-coverage review depends on nesting, which arrived at v2.1.172 (discovery finding 1). The source spec already rejected a reduced-coverage fallback and requires review to fail closed (spec D9, F8), so a below-version environment is a halt condition, not a degraded run.
- **Evidence:** discovery finding 1 (nesting supported as of v2.1.172) in [.discovery-notes.md](.discovery-notes.md); spec D9 and F8 (no reduced-coverage fallback; review fails closed) in [decision-log.md](decision-log.md) and [team-findings.md](team-findings.md).
- **Rejected alternatives:**
  - Carry a reduced-coverage single-reviewer fallback for below-version environments — rejected because it degrades the gate that is the feature's headline value; review fails closed instead (spec D9, F8).
- **Specialist owner:** software-architect (A2)
- **Revisit criterion:** the platform changes how nested sub-agents are gated, or a supported single-agent full-coverage review path appears.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); RAID Log (Assumptions A1, Risks R1)

### D-4: Compact-return contract and fail-closed parsing

- **Question:** How does the driver get a trustworthy structured return from each dispatched sub-agent, given no schema validation exists on the Agent path?
- **Decision:** The driver imposes the build-report and review-verdict return contract by dispatch instruction, using named-section headers in the prompt (no schema validation is available on this path). It parses the return defensively and treats a malformed or incomplete report as untrustworthy, which halts the run immediately. A `tdd` build report missing the required RED-to-GREEN observed-failure evidence is untrustworthy and halts; RED-to-GREEN evidence is not required on fix rounds that add no new behavior. The build-report contract and the review-verdict contract are each extracted to a reference file and copied verbatim into the matching dispatch prompt.
- **Rationale:** The Agent path returns free-form text with no schema enforcement (discovery finding 3), so the contract can only be requested, not validated by the platform; the driver must supply the enforcement by parsing fail-closed. A single "does this look complete?" judgment would reintroduce the silent-cap-burn the source spec closed in F6. Extracting the two contracts to reference files keeps the dispatch prompts and the operator-readable contract in one canonical place.
- **Evidence:** spec D10 (driver-defined dispatch contract), spec D6 (halt on any unresolvable item), spec F6 (uniform fail-closed handling) in [decision-log.md](decision-log.md) and [team-findings.md](team-findings.md); discovery finding 3 (no schema-validated return on the Agent path) in [.discovery-notes.md](.discovery-notes.md).
- **Rejected alternatives:**
  - Gate on a single "looks complete?" judgment of the return — rejected because it reintroduces the F6 silent-cap-burn, where a mechanism failure is mis-counted as a not-cleared fix round and surfaces later as a misleading "gate not cleared".
  - Rely on a schema-validated structured return — rejected because none exists on the Agent dispatch path (discovery finding 3); native compact-output modes on `tdd`/`code-review` are deferred.
- **Specialist owner:** software-architect (A3)
- **Revisit criterion:** the platform adds schema-enforced structured output for the Agent path, or the by-instruction contract proves unreliable in dogfood (reopening the deferred native compact modes).
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-13
- **Referenced in plan:** Implementation Approach (External Interfaces; Runtime Behavior)

### D-5: allowed-tools set

- **Question:** What `allowed-tools` set does the driver's SKILL.md declare, given it runs a target project's verification commands it cannot know in advance?
- **Decision:** The driver declares `Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(find *)` plus the runner prefixes `tdd` already declares (`Bash(npm *), Bash(npx *), Bash(pnpm *), Bash(yarn *), Bash(pytest *), Bash(python3 *), Bash(go *), Bash(cargo *), Bash(make *), Bash(bundle *), Bash(rake *)`). Because a per-prefix Bash grant cannot cover an arbitrary project's runner, a verification command that cannot be run under these grants is the "tooling unavailable" halt (spec D15), and the operator resolves it by adding a CLAUDE.md Bash grant or routing the command through `make`. This coverage gap is stated in the SKILL.md Constraints.
- **Rationale:** CONTRIBUTING forbids a `Bash(*)` wildcard, so the driver must enumerate prefixes; mirroring `tdd`'s list covers the common runners and keeps the two skills consistent. An un-runnable command surfaces as the existing tooling-unavailable halt rather than a silent skip, matching the spec's fail-closed posture.
- **Evidence:** spec D7 (independent verification) and spec D15 (tooling-unavailable halt) in [decision-log.md](decision-log.md); `tdd` SKILL.md `allowed-tools` frontmatter (`han-coding/skills/tdd/SKILL.md`, verified verbatim); CONTRIBUTING per-prefix Bash rule (discovery Standards).
- **Rejected alternatives:**
  - Declare a `Bash(*)` wildcard so any project runner works — rejected because it violates the CONTRIBUTING per-prefix rule (discovery Standards).
- **Specialist owner:** software-architect (A5)
- **Revisit criterion:** the platform adds a scoped dynamic-grant mechanism, or dogfood shows the fixed prefix list blocks common project runners often enough to warrant a different approach.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points)

### D-6: Driver artifacts and explicit commit staging

- **Question:** Where do the uncommitted work-state file and the per-item durable review records live, in what format, and how are commits staged so those artifacts never enter history?
- **Decision:** The uncommitted work-state file (run configuration plus per-item status: pending, in-progress, done with commit reference and review-record path, or halted) and the per-item durable review records live at concrete git-excluded paths inside the plan folder, in markdown (the suite's format convention). Every per-item commit stages the item's own code changes explicitly by path and never runs `git add -A`; the work-state file and the review records are excluded from the changed-file scope check and from every commit.
- **Rationale:** The source spec requires both artifacts to be uncommitted, readable by dispatched sub-agents during the run, and retained after a halt (spec D18, D9), and requires commits to carry only the item's code (spec F4). Explicit path staging is the mechanism that guarantees a stray add-all never folds bookkeeping into a code commit. Markdown matches the rest of the suite and stays operator-readable after a halt.
- **Evidence:** spec D18 (uncommitted single-pass work-state), spec D9 (durable review record as an out-of-commit artifact), spec F4 (commit staging scoped to the item's code), spec F5 (durable record location and lifetime) in [decision-log.md](decision-log.md) and [team-findings.md](team-findings.md).
- **Rejected alternatives:**
  - Stage with `git add -A` and rely on ignore rules — rejected because a mis-scoped ignore folds the work-state file or a review record into the item's commit, breaking the clean-history invariant (spec F4).
  - Store the artifacts in YAML — rejected in favor of markdown for consistency with the suite's artifact convention (R1 resolution of the format sub-dispute).
- **Specialist owner:** software-architect (A6); junior-developer (IMPL-01)
- **Revisit criterion:** a later resume or compaction-recovery feature needs a committed ledger, which would move the work-state file into history.
- **Dissent (if any):** None (the markdown-vs-YAML sub-dispute was resolved by suite convention, not carried as dissent).
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Data Model and Persistence)

### D-7: Verify-command auto-detection

- **Question:** How does the driver determine the target project's verification commands, and what does it do when the project defines none?
- **Decision:** The driver mirrors `tdd`'s `scripts/detect-tdd-context.sh` resolution order to detect the target project's verification commands from that project's own configuration. It surfaces the resolved set (or scope-check-only mode where none is found) in the plan preview for the operator to confirm or override, accepts an operator `--verify` override, and falls back to scope-check-only when no commands are detected.
- **Rationale:** Reusing the `tdd` detection order keeps the two skills consistent and grounds the heuristic in an existing, exercised precedent rather than a fresh guess. Surfacing the resolved set at the preview folds verification into the single confirmation touchpoint (spec D17) instead of a separate prompt.
- **Evidence:** spec D7 (independent verification, operator override, no-commands path) and spec D17 (single plan-preview confirmation) in [decision-log.md](decision-log.md); `han-coding/skills/tdd/scripts/detect-tdd-context.sh` (verified present); spec Primary Flow step 1.
- **Rejected alternatives:**
  - Invent a new detection heuristic for the driver — rejected because `tdd` already resolves project verification context and reusing its order keeps behavior consistent (junior IMPL-03 resolved from anecdotal to evidence by adopting the `tdd` precedent).
- **Specialist owner:** software-architect; junior-developer (IMPL-03)
- **Revisit criterion:** `tdd`'s detection order changes, or dogfood shows it misses verification commands common in target projects.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Runtime Behavior); Decomposition and Sequencing
### D-8: Valid-skill recognition set

- **Question:** How does the driver determine which build skill to use per item, and how does it detect and refuse `HITL` items?
- **Decision:** The driver hardcodes `tdd` as the build skill for every item; there is no per-item `implementation-skill` field in the core (the field is deferred, see the spec's Deferred (YAGNI) section). `HITL` items are refused at startup via the persisted `Type` marker (spec D13). `refactor` would be interactive-ineligible even if a selection mechanism existed, and analysis or documentation skills do not produce code; `tdd` is the only qualifying skill. The SKILL.md-property-scan mechanism that would read each skill's own declared properties is deferred. Revised during W-1 implementation (operator direction).
- **Rationale:** The source spec requires the driver to refuse `HITL` items and to offload building to a non-interactive code-producing skill (spec D13, D16). `tdd` is the only qualifying skill; a per-item selection field would carry exactly one valid value (a premature schema hook). The `Type` marker is the startup gate, and the driver simply dispatches `tdd` for every item.
- **Evidence:** spec D13 (input-validation preconditions) and spec D16 (per-item implementation skill; `refactor` interactivity; field deferred) in [decision-log.md](decision-log.md); team finding F7; W-1 implementation, operator direction.
- **Rejected alternatives:**
  - Read each skill's own declared properties (a property-scan) now — rejected under YAGNI because the core has exactly one qualifying skill, so the scan has no second use to justify it; deferred until a second non-interactive code-producer exists.
- **Specialist owner:** junior-developer (IMPL-04)
- **Revisit criterion:** a second non-interactive, code-producing implementation skill is added to the suite.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Runtime Behavior); Decomposition and Sequencing

### D-9: Prior-run branch marker

- **Question:** How does the startup check detect that the target branch already carries a prior run's commits, so a fresh re-invocation does not rebuild committed items?
- **Decision:** The planning-artifacts commit carries a recognizable marker (a commit-message convention or a git trailer) that the startup check detects with `git log`. A match refuses the run and directs the operator to a fresh branch.
- **Rationale:** The run is single-pass with no resume (spec D18), so re-invoking on a branch that already carries the prior run's commits would duplicate work (spec D14, F9). A marker on the first commit is a cheap, git-native signal the startup check can read without a separate state file.
- **Evidence:** spec D14 (start-time refusal on a branch carrying a prior run's commit) and spec D18 (single-pass, no resume) in [decision-log.md](decision-log.md); team finding F9.
- **Rejected alternatives:**
  - Detect a prior run only from the uncommitted work-state file — rejected because a clean-tree halt (for example "no file changes") can leave no work-state file while the committed items remain, so the check must read git history (spec F9).
- **Specialist owner:** junior-developer (IMPL-02); software-architect (A6)
- **Revisit criterion:** a resume feature lands that makes re-invocation on the same branch a supported path.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Runtime Behavior); Decomposition and Sequencing

### D-12: Planning-artifact identification

- **Question:** How does the driver identify the planning artifacts it commits first and exempts from the clean-tree check?
- **Decision:** The driver parses the `work-items.md` preamble for local `.md` links (the spec, plan, and research files it names) and adds the work-items file itself; that set is the planning artifacts. Source files the items target do not qualify. The resolved set is shown at the plan preview so the operator sees exactly what will be committed first.
- **Rationale:** The source spec defines planning artifacts as the work-items file plus the spec/research/plan it names as context (spec F10), and the work-items file format links its parent plan in the preamble, so the preamble links are the reliable signal. Showing the set at the preview keeps the operator's confirmation informed.
- **Evidence:** spec D14 and D15 (planning-artifact exception and the first commit), spec F10 (identification criterion) in [decision-log.md](decision-log.md) and [team-findings.md](team-findings.md); `han-planning/skills/plan-work-items/references/work-items-file-format.md` (the preamble links the parent plan).
- **Rejected alternatives:**
  - Treat every uncommitted `.md` file as a planning artifact — rejected because it would fold unrelated documentation edits into the first commit; the preamble link set is the bounded, declared signal (spec F10).
- **Specialist owner:** junior-developer (IMPL-05)
- **Revisit criterion:** the work-items file format stops linking its context in the preamble.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Runtime Behavior); Decomposition and Sequencing

### D-13: Skill-file structure and references granularity

- **Question:** How is the driver's SKILL.md structured, and how many reference files are extracted up front?
- **Decision:** SKILL.md is authored at orchestration altitude (roughly 300 to 380 lines, matching the `tdd`/`code-review`/`plan-implementation` precedent) following the step outline: Project Context; Constraints; Step 1 Prepare and Validate (read-only); Step 2 Confirm and Set Up; Step 3 per-item Build / Verify / Review / Fix / Commit with an inline Halt Procedure; Step 4 Completion Summary. Exactly two reference files are extracted up front, `references/build-report-contract.md` and `references/review-verdict-contract.md` (D-13 depends on D-4). The validation rules and the halt-frame format stay inline in SKILL.md and are extracted only if the first draft overflows the orchestration-altitude precedent.
- **Rationale:** The two contracts are copied verbatim into dispatch prompts, so extracting them keeps one canonical source; the validation rules and halt frame have no such second consumer, so under the YAGNI simpler-version test they stay inline until length forces extraction. Four to six reference files up front would create single-use files before the draft shows they are needed.
- **Evidence:** junior-developer reframing under the YAGNI simpler-version test (IMPL-07); SKILL.md size precedent (plan-implementation 287, tdd 277, code-review 398 lines) in [.discovery-notes.md](.discovery-notes.md); the software-architect step outline (A4).
- **Rejected alternatives:**
  - Extract four to six reference files up front (the two contracts plus `validation-rules.md`, `halt-frame-format.md`, `per-item-loop.md`, and `work-state-schema.md`) — rejected under the YAGNI simpler-version test because only the two contracts have a second consumer (the dispatch prompts); the rest are single-use until the draft overflows (software-architect A4 preferred four; resolved in junior's favor).
- **Specialist owner:** junior-developer (IMPL-07)
- **Revisit criterion:** the first SKILL.md draft overflows the orchestration-altitude precedent, at which point the inline validation rules and halt frame are extracted to references.
- **Dissent (if any):** software-architect (A4) preferred extracting four reference files up front (the two contracts plus `validation-rules.md` and `halt-frame-format.md`); resolved against under the YAGNI simpler-version test and committed disagree-and-commit, with the overflow revisit criterion as the reopen path.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Decomposition and Sequencing

### D-14: Verification strategy

- **Question:** How is the finished skill verified, given the Han repo has no build, test, lint, or CI configuration?
- **Decision:** Verification is dogfooding plus the CONTRIBUTING self-review checklist; no automated harness is added, because the repo is markdown-only with no CI. Dogfooding the driver on Han itself exercises only the scope-check-only path (Han defines no verification commands), so a separate fixture repo that has a real test suite is needed to exercise independent verification and the fix loop.
- **Rationale:** The repo has no test/lint/build config and no CI (discovery Tech stack), so an automated harness has nothing to hook into; the established suite practice is dogfood plus the CONTRIBUTING checklist. Because Han has no verification commands, only an external real-suite fixture can drive the independent-verification and fix-loop behavior.
- **Evidence:** test-engineer input (R1); discovery Tech stack (no root build/test/lint config, no CI) in [.discovery-notes.md](.discovery-notes.md).
- **Rejected alternatives:**
  - Add a CI or shell-script harness to automate the checks — rejected because the repo has no CI to host it and the deliverable is markdown; deferred with a reopen trigger.
  - Verify only by dogfooding on Han — rejected because Han's scope-check-only path never exercises independent verification or the fix loop, so a real-suite fixture is required.
- **Specialist owner:** test-engineer
- **Revisit criterion:** the repo adds CI, or dogfood regressions recur often enough to justify an automated harness.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** D-15
- **Referenced in plan:** Testing Strategy

### D-15: Definition of Done

- **Question:** What testable criteria mark the skill complete?
- **Decision:** The Definition of Done is the test-engineer set: the CONTRIBUTING self-review (all eight items, load-bearing being that `allowed-tools` covers the verify Bash prefixes and includes Agent, the description is under 1024 characters, links resolve, the long-form doc exists, and the indexes are complete); a happy-path dogfood on a real-suite fixture; a scope-check-only dogfood on Han; the pre-run refusal checks; the mid-run halt checks; artifacts-never-staged verified with `git show --stat`; halt-leaves-completed-items-committed; companion-change verification; docs, index, and root CLAUDE.md completeness; and a voice and em-dash scan.
- **Rationale:** These criteria map directly onto the behaviors the source spec commits to and the CONTRIBUTING add-a-skill requirements, and they are each observable (a refusal, a commit, a `git show --stat`, a completed dogfood), so completion is checkable without an automated harness.
- **Evidence:** test-engineer input (R1); CONTRIBUTING add-a-skill checklist and self-review (discovery Standards); the source spec's refusal and halt behaviors (spec D6, D13, D14) in [decision-log.md](decision-log.md).
- **Rejected alternatives:**
  - A thinner DoD (self-review plus a single happy-path dogfood) — rejected because it would not exercise the refusal paths, the halt paths, or the artifacts-never-staged invariant that are the feature's safety guarantees.
- **Specialist owner:** test-engineer
- **Revisit criterion:** a new halt trigger or refusal path is added that the DoD does not cover.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Definition of Done

### D-16: Companion changes to `plan-work-items`

- **Question:** What exactly changes in `plan-work-items` so the driver can read the fields it depends on, and how are those changes kept consistent and dependency-legal?
- **Decision:** Add two per-item fields, `expected-paths` (required) and a `Type` AFK/HITL marker (required), to `references/work-item-template.md` and `references/work-items-file-format.md`, and edit `plan-work-items` SKILL.md Step 5 (produce the fields), Step 7 (print them), and Step 8 (a closing recommendation naming `implement-work-items` and its `han-coding` plugin in prose only). The field format must read identically across the template, the file-format doc, and the driver's validation. The `implementation-skill` field is deferred (Decision B); the `Type` marker ships because the producer already classifies items as AFK or HITL, and persisting that classification lets the driver refuse `HITL` items at startup. Revised during W-1 implementation (operator direction).
- **Rationale:** The scope check and HITL detection both depend on data that only the producer can record, and a data field cannot be imposed by a dispatch instruction the way the return contract can (spec D19). Naming the driver in prose keeps `han-planning` free of a dependency on `han-coding`, which CONTRIBUTING's dependency direction forbids. Format consistency across the three consumers is what keeps the driver's validation aligned with what the producer emits.
- **Evidence:** spec D19 (companion changes to the work-item producer) in [decision-log.md](decision-log.md); CONTRIBUTING dependency-direction rule (discovery Standards); junior-developer IMPL-06 (prose reference is not a dependency); the current `work-item-template.md` has no `Type`, `expected-paths`, or `implementation-skill` field (discovery Touch points); W-1 implementation, operator direction.
- **Rejected alternatives:**
  - Also ship the `implementation-skill` field — rejected because `tdd` is the only valid value in the core, making it a premature schema hook (Decision B); the field is deferred.
  - Make `plan-work-items` depend on `han-coding` so it can link the driver as a component — rejected because CONTRIBUTING forbids that dependency direction; a prose pointer covers the need (junior IMPL-06).
- **Specialist owner:** junior-developer (IMPL-06)
- **Revisit criterion:** the HITL handling feature lands, or a second non-interactive code-producing skill is added (reopening the `implementation-skill` field), or the field format needs to diverge across consumers.
- **Dissent (if any):** None.
- **Driven by rounds:** R1
- **Dependent decisions:** None
- **Referenced in plan:** Implementation Approach (Architecture and Integration Points); Decomposition and Sequencing
