# Work Items — Autonomous Driver Core Loop

These work items break down [feature-implementation-plan.md](feature-implementation-plan.md) (the implementation plan for the `implement-work-items` skill and its companion `plan-work-items` changes). Work items are numbered `W-N` for cross-reference only. `Depends on` lines refer to other work items in this file. Plan decisions are cited inline as `See plan: D-N` breadcrumbs.

All six items are AFK (implementable and mergeable without a sync). The deliverable is markdown authoring; there is no automated test suite in this repo, so verification is dogfood plus the CONTRIBUTING self-review checklist.

## Shared reference artifacts

These artifacts apply to more than one work item; each work item's `**References.**` block points here by name and adds its own specifics.

- **Feature specification** — [feature-specification.md](feature-specification.md). The behavior every work item realizes. Relevant sections are cited per work item.
- **Contributor guide** — [CONTRIBUTING.md](../../../CONTRIBUTING.md). The "Adding a skill" checklist (frontmatter, `allowed-tools` per-prefix rule, description under 1024 chars, docs, index, marketplace) and the "Reviewing your own changes" self-review checklist. Note: CONTRIBUTING's add-a-skill step 3 shorthand `docs/skills/{name}.md` is stale; the actual layout is per-plugin `docs/skills/han-coding/{name}.md`.
- **Writing voice** — [docs/writing-voice.md](../../writing-voice.md). No em-dashes in prose; direct second person; no `leverage`/`utilize`/`showcase`/`robust`(vague)/`actually`/`just`/`It's worth noting`/`Importantly`. Applies to every edited file.
- **`tdd` skill** — [han-coding/skills/tdd/SKILL.md](../../../han-coding/skills/tdd/SKILL.md). Its frontmatter `allowed-tools` runner-prefix list is mirrored by the driver (W-2), and its Step 1 verify-command resolution order (CLAUDE.md → project-discovery.md → `${CLAUDE_SKILL_DIR}/scripts/detect-tdd-context.sh` → manifest inference) is the precedent for the driver's detection (W-3).

## W-1 — Companion fields on the work-item producer

**Summary.** Add the two per-item fields the driver consumes to the `plan-work-items` producer, so a produced `work-items.md` carries an `expected-paths` declaration (required) and a `Type` (AFK/HITL) marker (required). Per-item implementation-skill selection is deferred; the driver hardcodes `tdd`. See plan: D-16, D-19, and Work Unit 1. This ships first because the driver's Step 1 validation reads these fields.

**Description.**
1. Add `**Expected paths.**` (required, a best-effort list the producer derives from the plan's named touch points and Step-3 codebase exploration, which the operator confirms; when the plan gives no file-level detail the producer flags the item's paths as low-confidence rather than inventing them) and `**Type.**` (`AFK` or `HITL`, required) to the work item template, in the field order the template already defines, with a one-line description of each. The `expected-paths` field lists the files the item is expected to touch (the format is settled here as the driver's scope check reads it; keep it simple and lexically unambiguous — a list of repo-root-relative paths, one per entry, with a rename declaring both its old and new path).
2. Document both fields in the work-items file-format reference, in the same syntactic form as the template.
3. Edit `plan-work-items/SKILL.md`: Step 5 directive produces both fields; Step 7 breakdown print shows both fields per item; Step 8 closing recommendation adds a prose-only line offering `implement-work-items` (naming its `han-coding` plugin) as the autonomous next step for AFK items.
4. Update the `plan-work-items` long-form doc to describe both new fields in its "What you get back" and "In more detail" sections.

**Note on scope boundary with the driver.** The `expected-paths` field format defined here is the exact string the driver's Step 1 validation (W-3) checks for presence and the scope check compares against. The `Type` field is the string the driver reads to refuse `HITL` items. Keep both field names and syntax identical across the template, the file-format doc, and the field description a reader consults, so the driver can validate presence without ambiguity. The `implementation-skill` field (another field in the larger design) is deliberately NOT added: per-item skill selection is deferred; the driver hardcodes `tdd` for the core.

**Note on cross-plugin dependency direction.** The Step 8 recommendation names `implement-work-items` and its `han-coding` plugin in prose only. It is a pointer, not an invocation, so it does not make `han-planning` depend on `han-coding` and does not touch `han-planning/.claude-plugin/plugin.json`. See plan: D-19.

**References.**
- **Spec section** — [feature-specification.md#actors-and-triggers](feature-specification.md#actors-and-triggers) (each item carries an `expected-paths` declaration and a `Type` marker), [feature-specification.md#coordinations](feature-specification.md#coordinations) (Work-item producer row).
- **Files to edit** — `han-planning/skills/plan-work-items/references/work-item-template.md`, `han-planning/skills/plan-work-items/references/work-items-file-format.md`, `han-planning/skills/plan-work-items/SKILL.md` (Steps 5, 7, 8), `docs/skills/han-planning/plan-work-items.md`.
- **Standard** — CONTRIBUTING.md self-review checklist and docs/writing-voice.md (see Shared reference artifacts).

**Tests.**
- Doc/format check: both fields appear in `work-item-template.md` and `work-items-file-format.md` with identical names and syntax; required/optional status matches.
- Producer check: run `plan-work-items` against a small plan and confirm the output `work-items.md` emits `expected-paths` on every item and a `Type` marker (`AFK` or `HITL`) on every item.
- Consistency check: the field name and syntax are lexically identical across the template, the file-format doc, and the long-form doc.
- Voice/em-dash scan clean on all edited files.

**Acceptance criteria.**
- [ ] `expected-paths` (required) and `Type` (`AFK` or `HITL`, required) exist in the template and file-format reference in one consistent syntax.
- [ ] `plan-work-items/SKILL.md` Step 5 produces both fields, Step 7 prints both, Step 8 adds the prose-only `implement-work-items` recommendation naming the `han-coding` plugin.
- [ ] `han-planning/.claude-plugin/plugin.json` is unchanged (no new dependency).
- [ ] `docs/skills/han-planning/plan-work-items.md` reflects both new fields.
- [ ] No em-dash or voice violations in any edited file.

**Depends on.** None.

## W-2 — Driver skill scaffold and the two dispatch-contract references

**Summary.** Author the `implement-work-items` skill's `SKILL.md` shell (frontmatter, Project Context, Constraints, the Step 1-4 outline, and the inline Halt Procedure frame) plus its two reference files that define the compact returns the dispatched sub-agents must produce. See plan: D-1, D-3, D-4, D-5, D-6, D-13, and Work Unit 2. This is static content only; the skill is not invoked until W-3 fills in the loop logic.

**Description.**
1. Create `han-coding/skills/implement-work-items/SKILL.md` frontmatter: `name: implement-work-items`; a `description` under 1024 chars (a trusted `work-items.md`, an unattended build→verify→review→fix→commit loop on a branch); an `argument-hint` naming the work-items file and the optional inputs (gate threshold, fix-loop cap, build/fix model, branch, `--verify` override); and `allowed-tools` mirroring `tdd`'s runner-prefix list verbatim plus `Agent`, `Bash(git *)`, and `Bash(find *)` (See plan: D-5).
2. Write the Constraints section: the **minimum Claude Code v2.1.172** prerequisite (nested sub-agents are required for the review fan-out, and there is no reduced-coverage fallback, See plan: D-3); the Bash-prefix **coverage gap** (a verify command outside the fixed prefix set is treated as a tooling-unavailable halt, and the operator must grant the prefix in CLAUDE.md or route via `make`, See plan: D-5); the never-`git add -A` rule and the git-excluded driver-artifact paths (See plan: D-6); and the fail-closed posture (a malformed or incomplete sub-agent return halts the run, See plan: D-4).
3. Write step-outline paragraphs for Steps 1-4 (prepare+validate; confirm+setup; per-item loop; completion summary) and embed the five-part Halt Procedure frame definition in Step 3 (status line; one-sentence reason; tree-state disclosure; supporting evidence with a durable-review-record pointer when review-gated; what-to-do-next including the fresh-run-not-resume warning). The loop bodies themselves are filled in W-3 and W-4.
4. Author `references/build-report-contract.md` in full: the compact build report format the build/fix sub-agents must return (status, files changed, final gate result, escalation, and the observed test-failure-then-pass evidence required for a `tdd` build and not required on a fix round), with the named-section headers the driver parses and the malformed-report conditions that trigger a halt (See plan: D-4).
5. Author `references/review-verdict-contract.md` in full: the condensed verdict format the review sub-agent must return (the recommendation, findings by severity complete at and above the gate threshold, and a full-coverage attestation), the durable-record-path field, and the untrustworthy-verdict conditions that trigger a halt (See plan: D-2, D-4).

**Note on the dispatch mechanism.** Both contracts are written so their full text can be copied verbatim into the Agent-tool dispatch prompts authored in W-3 and W-4; the driver imposes the contract by dispatch instruction (returns are free-form; there is no schema validation). See plan: D-1, D-4.

**References.**
- **Spec section** — [feature-specification.md#actors-and-triggers](feature-specification.md#actors-and-triggers) (optional inputs), [feature-specification.md#coordinations](feature-specification.md#coordinations) (the build-skill (`tdd`) and code-review rows: what each dispatched skill returns).
- **`tdd` skill** — its frontmatter `allowed-tools` list to mirror (see Shared reference artifacts).
- **Standard** — CONTRIBUTING.md "Adding a skill" (frontmatter, `allowed-tools` per-prefix rule, description limit) and `han-plugin-builder/skills/guidance/references/skill-building-guidance/` (SKILL.md structure, progressive disclosure); docs/writing-voice.md.

**Tests.**
- Frontmatter check: `allowed-tools` equals `tdd`'s runner prefixes plus `Agent`, `Bash(git *)`, `Bash(find *)`, with nothing else added or dropped; `description` under 1024 chars.
- Constraints check: the section states the v2.1.172 prerequisite, the coverage-gap tooling-unavailable wording, the no-`git add -A` rule, and the git-excluded artifact paths.
- Contract check: both reference files exist with every required field, and their trustworthiness triggers align with the Halt Procedure frame (missing RED→GREEN evidence → untrustworthy build report; missing coverage attestation → untrustworthy verdict).
- Voice/em-dash scan clean.

**Acceptance criteria.**
- [ ] `han-coding/skills/implement-work-items/SKILL.md` exists with valid frontmatter; `allowed-tools` mirrors `tdd`'s list plus `Agent`/`Bash(git *)`/`Bash(find *)`; description under 1024 chars.
- [ ] Constraints name the v2.1.172 prerequisite, the coverage-gap halt, the no-`git add -A` rule, and the git-excluded artifact paths.
- [ ] The Step 1-4 outline is present and the five-part Halt Procedure frame is defined inline in Step 3.
- [ ] `references/build-report-contract.md` and `references/review-verdict-contract.md` exist with all required fields and their halt-trigger conditions.
- [ ] Internal links from SKILL.md to both reference files resolve; no em-dash or voice violations.

**Depends on.** None.

## W-3 — Happy-path loop: validation, per-item build-verify-review-commit, and pre-fix halts

**Summary.** Fill in the driver's Steps 1-4 with the complete happy-path logic and every halt that does not involve the fix loop, so a full run can prepare, validate, preview, build→verify→review→commit each item on a dedicated branch, and halt cleanly on any pre-fix failure. See plan: D-1, D-2, D-4, D-5, D-6, D-7, D-8, D-9, D-10, D-11, D-12, and Work Unit 3 (validation, setup, and the basic loop). A driver at this stage halts on any gate-blocking review finding rather than fixing it (equivalent to a fix-cap of zero), which is safe but limited; W-4 adds the fix loop.

**Description.**
1. **Step 1 prepare + validate (read-only).** Detect the project's verification commands by mirroring `tdd`'s resolution order (CLAUDE.md → project-discovery.md → `detect-tdd-context.sh` → manifest inference), with a `--verify` override and a scope-check-only fallback when none are found (See plan: D-7). Check tooling availability (any missing required command is a refusal naming all missing). Confirm the working tree is clean apart from the planning artifacts, identified by parsing the work-items preamble for local `.md` links plus the work-items file itself (source files the items target do not qualify, See plan: D-12). Refuse if the target branch already carries a prior run's planning-artifacts commit, detected by its marker (See plan: D-9). Validate the dependency graph (no cycles, no self-dependency, no duplicate IDs, no `Depends on` to an absent item), the presence of `expected-paths` and `Type` on every item, and that no item is typed `HITL` (See plan: D-8). Every refusal names the condition, the reason, and the remedy.
2. **Step 2 confirm + setup.** Show the plan preview (effective gate threshold, fix-loop cap, build/fix model, branch defaulting to a `driver/{feature-dir}` name, the verification configuration or scope-check-only mode in plain language, and the planning-artifact set), and wait for confirm or decline. On decline, stop and confirm nothing was mutated. On confirm, create the branch, commit the planning artifacts (carrying the prior-run marker), detect the commit convention (read CLAUDE.md/project-discovery, default conventional commits, See plan: D-11), and initialize the uncommitted work-state file. See plan: D-10, D-12.
3. **Step 3 per-item loop (build → verify → review → commit).** For each item in dependency order: dispatch a build sub-agent via the Agent tool with a per-call model, naming `tdd` as the build skill and copying the build-report contract verbatim into the prompt (See plan: D-1). Run independent verify by executing the project's own verification commands directly (not via the sub-agent), distinguishing a command that reports failures from one that fails to execute (the latter is a tooling-unavailable halt) (See plan: D-7). Run the scope check comparing changed files against the item's `expected-paths`, excluding project-ignored files, generation/sync output produced by the build or verify steps, and the driver's own artifacts. Dispatch the review sub-agent at depth 1 via the Agent tool, copying the review-verdict contract verbatim and directing it to persist the durable record at a git-excluded path (See plan: D-2). If verify passes and the verdict clears the gate, stage the item's code changes explicitly by path (never `git add -A`) and commit; then update the work-state file (See plan: D-6, D-9). Pre-fix halts handled here: no file changes (or only excluded files); a `tdd` report missing RED→GREEN evidence; a verify command that fails to execute; a changed file outside `expected-paths`; an untrustworthy review verdict; a rejected commit. All use the five-part Halt Procedure frame from W-2.
4. **Step 4 completion summary.** Report the branch, each item's outcome, the items not reached, and the operator's next action.
5. Add the driver-artifact paths (the work-state file and the per-item durable review records) to a gitignore entry so they are never staged by any git command.

**Note on scope boundary with W-4.** This item stops at the point a review returns a gate-blocking finding: it halts rather than fixing. It does not author the fix loop, cap-zero handling, or the fix-round-specific halts (out-of-path during re-verify, untrustworthy re-review) — those are W-4.

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (steps 1 through 3.v and step 4), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (the no-verification-commands flow), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (all rows except the fix-loop-specific ones).
- **`tdd` skill** — its Step 1 verify-command resolution order (see Shared reference artifacts).
- **`code-review` skill** — [han-coding/skills/code-review/SKILL.md](../../../han-coding/skills/code-review/SKILL.md) (panel dispatch and the Review Recommendation/Summary verdict surface the review sub-agent returns).
- **Producer field** — `han-planning/skills/plan-work-items/references/work-item-template.md` (the `expected-paths` and `Type` fields authored in W-1; `expected-paths` is read by the scope check and `Type` is read by startup validation).
- **Standard** — docs/writing-voice.md.

**Tests.**
- Scope-check-only dogfood on Han: driver detects no verification commands, surfaces scope-check-only mode in the preview, and (on confirm) processes items with the scope check only.
- Pre-run refusals each fire naming reason and remedy: dirty tree, red suite, malformed graph (cycle, duplicate ID, dangling reference, each separately), missing `expected-paths`, missing `Type` marker, `HITL`-typed item, prior-run branch, empty or no-buildable-items file.
- Pre-fix halts each fire with the five-part frame: no file changes; missing RED→GREEN evidence; verify-execution failure (tooling-unavailable, not a fix round); out-of-path change (naming the file); untrustworthy verdict; rejected commit (work left in tree).
- Artifacts-never-staged: `git show --stat` on the planning-artifact commit shows no work-state or review-record files; `git check-ignore` confirms both artifact paths are excluded.

**Acceptance criteria.**
- [ ] Step 1 detects verify commands (with `--verify` override and scope-check-only fallback), validates the graph and fields, identifies planning artifacts, and refuses on a prior-run branch — each refusal naming reason and remedy.
- [ ] Step 2 previews the full effective configuration and planning-artifact set, and mutates the repo only after confirm; decline leaves the repo untouched.
- [ ] Step 3 dispatches build and review via the Agent tool with the verbatim contracts, verifies independently, scope-checks against `expected-paths`, and commits one item per commit with explicit staging.
- [ ] Every pre-fix halt uses the five-part frame with the correct reason; completed items stay committed and the halted item's work stays in the tree.
- [ ] Driver artifacts are gitignored and never appear in a commit; no em-dash or voice violations.

**Depends on.** W-1, W-2.

## W-4 — Bounded fix loop and fix-loop halt coverage

**Summary.** Extend Step 3 with the bounded fix loop and its fix-round-specific halts, so a gate-blocking finding or a verify failure is fixed by a fresh sub-agent, re-verified, and re-reviewed until the gate clears or the configured cap is reached. See plan: D-2, D-4, D-5, D-6, D-7, D-9, D-11, and Work Unit 3 (the fix loop).

**Description.**
1. After verify reports failures (a command ran and reported failures, not a failure to execute) or the review returns a finding at or above the configured threshold, dispatch a fresh fix sub-agent via the Agent tool with the original build context, the review's durable record, and the current cumulative diff (the working tree against the item's base commit) (See plan: D-2).
2. Re-verify: a pass advances to re-review; a command that fails to execute halts as a tooling/environment problem (not a not-cleared round); an out-of-path change halts immediately naming the file (not a not-cleared round).
3. Re-review: a clean verdict commits the item; gate-blocking findings make it a not-cleared round; an untrustworthy re-review verdict halts immediately (not a not-cleared round).
4. Label each round in the operator-visible narration (`fix round N of cap`). Repeat until the gate clears or the cap is reached. A cap of zero skips the loop and halts on the first gate-blocking finding. A cap-reached halt reports residual findings as "gate not cleared" (reserve "unsatisfiable" for the build-never-passes case). See plan: D-5.
5. For scope-check-only runs (no verification commands), the fix-round re-verify can only pass (advance to re-review) or detect an out-of-path change (halt) — there is no verification-failure not-cleared round.

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow) (step 3.iv "Fix to the gate"), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (cap=0; cap reached; out-of-path or untrustworthy verdict during a fix round; verify-command-fails-to-execute), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states) (the scope-check-only fix-loop note).
- **Standard** — docs/writing-voice.md.

**Tests.**
- Verify-failure entry: a fixture item whose verify initially reports failures shows a labeled fix round, re-verify pass, re-review, and commit.
- Gate-finding entry: a fixture item with a review finding shows a fix round carrying the durable record, re-verify, re-review, and commit on a clean verdict.
- cap=0 halts on the first gate-blocking finding with no fix dispatched; cap reached halts with "gate not cleared" (never "unsatisfiable").
- Out-of-path change and untrustworthy re-review during a fix round each halt immediately with the five-part frame and are not counted against the cap; a verify-execution failure during a fix round halts as tooling/environment.
- Scope-check-only re-verify only passes or halts on out-of-path, never a not-cleared round.

**Acceptance criteria.**
- [ ] The fix loop dispatches a fresh sub-agent with the build context, durable record, and cumulative diff; re-verifies then re-reviews only on a verify pass.
- [ ] cap=0 and cap-reached behave per spec, with correct "gate not cleared" language.
- [ ] Fix-round out-of-path, untrustworthy re-review, and verify-execution failures each halt immediately (not not-cleared rounds) with the five-part frame.
- [ ] Scope-check-only fix rounds never produce a verification-failure not-cleared round.
- [ ] No em-dash or voice violations in the updated SKILL.md.

**Depends on.** W-3.

## W-5 — Long-form doc, Skills Index, and root catalog entry

**Summary.** Register the new skill per the documentation coverage rule: author its long-form doc, add its Skills Index scent entry, and add its root `CLAUDE.md` catalog entry. See plan: D-3, D-5, D-15 (DoD-9), D-18, and Work Unit 4.

**Description.**
1. Create `docs/skills/han-coding/implement-work-items.md` (the per-plugin path, not CONTRIBUTING's stale `docs/skills/{name}.md` shorthand) following the long-form skill template. Cover: TL;DR; Key concepts (the loop, the halt, the scope check, the planning-artifact commit, scope-check-only mode); When to use it; How to invoke it (the work-items file argument plus the optional inputs); What you get back (the branch, per-item commits, the completion summary, the durable review records, the halt frame); How to get the most out of it (pairs upstream with `plan-work-items`, per-item skill defaults to `tdd`, the fixture-repo requirement for real verification, the v2.1.172 prerequisite and the Bash-grant coverage gap); YAGNI; Cost and latency (the driver-session model overhead; one depth-1 review sub-agent and one depth-2 panel per item); In more detail (single-pass model, scope-check-only path, halt posture); Sources; Related documentation (first bullet links the README).
2. Add a one-sentence scent entry for `implement-work-items` under `## han-coding` in `docs/skills/README.md`.
3. Add a catalog entry for `implement-work-items` in the root `CLAUDE.md` `han-coding` plugin description, matching the pattern used for the other skills.
4. Confirm `.claude-plugin/marketplace.json` is unchanged (the skill joins the existing `han-coding` plugin's `skills/` directory, which is already listed).

**References.**
- **Templates** — `docs/templates/skill-long-form-template.md` (section shape), `docs/templates/coverage-rule.md` (the every-skill-gets-a-doc rule).
- **Doc precedent** — `docs/skills/han-coding/tdd.md` (a peer long-form doc to align with).
- **Files to edit** — `docs/skills/README.md` (`## han-coding` section), root `CLAUDE.md` (han-coding catalog line).
- **Standard** — CONTRIBUTING.md "Adding a skill" steps 3-6 and docs/writing-voice.md (see Shared reference artifacts).

**Tests.**
- The long-form doc exists at the per-plugin path with every template section filled (no placeholder text) and states the v2.1.172 prerequisite and the Bash-grant coverage gap.
- The Skills Index has an `implement-work-items` entry under `## han-coding`; root `CLAUDE.md` has a catalog entry; `.claude-plugin/marketplace.json` is unchanged.
- All links in the long-form doc resolve (the SKILL.md, the sibling `plan-work-items`/`tdd`/`code-review` docs, the template links, the README up-link).

**Acceptance criteria.**
- [ ] `docs/skills/han-coding/implement-work-items.md` exists, follows the template, and names both platform constraints.
- [ ] Skills Index and root `CLAUDE.md` both carry the new skill; `.claude-plugin/marketplace.json` unchanged.
- [ ] Every internal link in the doc resolves; no em-dash or voice violations.

**Depends on.** W-4.

## W-6 — End-to-end dogfood verification

**Summary.** Exercise the full Definition of Done end to end: the CONTRIBUTING self-review checklist, a happy-path-plus-fix-loop dogfood on a fixture repo with a real test suite, and a scope-check-only dogfood on Han, including the producer→driver companion-field integration. See plan: D-14, D-15, and Work Unit 5. This is the primary quality gate because the repo has no automated test suite.

**Description.**
1. Run the full CONTRIBUTING self-review checklist across every new and edited file, confirming the four load-bearing checks: `allowed-tools` covers the verify Bash prefixes and includes `Agent`; description under 1024 chars; internal links resolve; the long-form doc exists and the indexes are complete.
2. Happy-path dogfood on an external fixture repo that has a real test suite (required because Han defines no verification commands and so cannot exercise independent verification or the fix loop): drive a `work-items.md` produced by the updated `plan-work-items` (exercising both new fields), and confirm each item builds with `tdd`, is independently verified against the project's own commands, is reviewed, enters at least one fix round, and is committed on the dedicated branch, with a correct completion summary.
3. Scope-check-only dogfood on Han: confirm the driver detects no verification commands, surfaces scope-check-only mode in the preview, and processes items with the scope check only (or halts cleanly when there are none).
4. Companion-change integration: confirm `plan-work-items` emits `expected-paths` and `Type`, the driver reads both without error, the missing-`expected-paths` refusal fires on a hand-crafted item that omits the field, and the `HITL`-typed-item refusal fires on a hand-crafted item typed `HITL`.
5. Invariant checks: artifacts-never-staged (`git show --stat` on each per-item commit) and halt-leaves-completed-items-committed (after a deliberate late-item halt, `git log` shows pre-halt items committed and `git status` shows the halted item's work uncommitted).

**Note on fixture repo.** The fixture is an existing external project with a green test suite (the operator's issue-#96 project or a small throwaway with a trivial `pytest`/`npm test` suite). A dedicated fixture committed into Han is deferred (plan Deferred (YAGNI)); do not add one.

**References.**
- **Spec section** — [feature-specification.md#primary-flow](feature-specification.md#primary-flow), [feature-specification.md#alternate-flows-and-states](feature-specification.md#alternate-flows-and-states), [feature-specification.md#edge-cases-and-failure-modes](feature-specification.md#edge-cases-and-failure-modes) (the behaviors exercised end to end).
- **Standard** — CONTRIBUTING.md self-review checklist, all eight items (see Shared reference artifacts).
- **Producer field** — `han-planning/skills/plan-work-items/references/work-item-template.md` (the fields the integration check exercises).

**Tests.**
- CONTRIBUTING self-review passes all eight items with the four load-bearing checks explicitly confirmed.
- Happy-path dogfood commits every fixture item on the branch, exercises at least one fix round, and produces a correct completion summary.
- Scope-check-only dogfood narrates the mode, invokes no verification commands, and completes or halts cleanly (no mutation on decline).
- Each pre-run refusal and each mid-run halt produces the correct message/frame.
- `git show --stat` shows no driver artifacts in any per-item commit; a deliberate halt leaves pre-halt items committed and the halted item's work in the tree.
- Producer→driver integration: the driver reads both new fields; the missing-`expected-paths` refusal and the `HITL`-typed-item refusal each fire on hand-crafted items that trigger them.

**Acceptance criteria.**
- [ ] The full DoD (CONTRIBUTING checklist, happy-path-plus-fix-loop dogfood on a real-suite fixture, scope-check-only dogfood on Han, refusal and halt checks, artifacts-never-staged, halt-leaves-committed, companion-change integration) passes.
- [ ] Findings from the dogfood are folded back into W-2/W-3/W-4/W-5 before this item closes.

**Depends on.** W-4, W-5.
