# Feedback: plan-work-items classification and non-code / meta work

This report captures friction found while running `plan-work-items` (with the new per-item skill selection and `deliverable-skill-catalog.md`) on a real plan whose deliverable is **Han plugin authoring, not application code**: the implementation plan for `autonomous-driver-hitl-support`, which edits the `implement-work-items` driver `SKILL.md`, its reference contracts, and the `plan-work-items` catalog.

It is written as input for a later polishing feature, not as a plan itself. Findings are prioritized. Each names what happened in the run, why it matters, and a suggested direction (not a finished solution).

## Summary

The per-item model (an implementation skill, a review, and per-phase AFK/HITL signals plus a pre-work-decision flag) is a good shape and worked. The gaps cluster around one root cause: the catalog was extended to classify **non-code deliverables** (docs, ADRs, runbooks, skills, agents), but the rest of the model still assumes **application code**, and it has no clean home for **meta work** (editing an existing skill definition, a verification pass, a spike). On this plan, five of six work items had to override or strain the catalog, and the run depended on the orchestrator injecting classification judgment the catalog does not encode. Without that framing, the literal catalog would have mis-classified the core items.

## Findings

### F1 (High): No catalog home for editing an existing skill/plugin file; `guidance`-as-implementation is a mis-fit

The catalog has "A new Claude Code skill → `skill-builder`" and "A new Claude Code agent → `agent-builder`", then a catch-all "Other work related to Claude Code plugins → `han-plugin-builder:guidance`, AFK / `guidance`, AFK". Editing an existing skill's `SKILL.md` or a reference contract falls into that catch-all, and `guidance` is the wrong implementation skill for it: `guidance` serves authoring rules (guidance mode identifies and cites the applicable docs); it does not author or edit files. Every item that edits an existing skill definition on this plan (W-1 through W-4) had to override the catalog to `none`.

- **Why it matters:** the single most common Han-maintenance task, editing an existing skill or agent, has no correct row, and the row it lands in names a skill that cannot do the work.
- **Suggested direction:** add a row for "modify an existing skill / agent / plugin definition" distinct from creating a new one, and reconsider whether `guidance` should ever be an *implementation* skill at all (it is a reference server, not an editor). This is adjacent to what the `autonomous-driver-hitl-support` feature already corrects on the *review* side (the `guidance`-as-review rows become a human read).

### F2 (High): Agent-draftable non-code work cannot be marked AFK; `none` is hardwired to HITL

The model records AFK/HITL *per phase*, which should be able to express "an agent drafts this build, a human reviews it." But for non-code work that an agent can draft (a markdown edit, a config change), there is no AFK *implementation* option. A named han skill (like `tdd`) is the only AFK build path, and the no-skill fallback `none` is defined as HITL (the catalog says "Never set an unconfirmed non-han skill to `AFK`", and the spec defines a bare `none` as a HITL free-form build). So an agent-draftable non-code edit is forced to `none, HITL` even when the genuine human need is only at the review gate.

- **Why it matters:** W-1, W-2, and W-4 are markdown edits an agent can draft from a detailed plan. Recording them as `HITL`-build overstates the human role and, more importantly, gives a *future* HITL driver the wrong signal: it cannot sub-agent the build and route only the review to the operator, because the build is marked human-throughout.
- **Suggested direction:** provide a way to record an "AFK free-form / agent-drafted build" for non-code work (a general-purpose AFK implementer, or an operator-declared AFK on a `none` build), so the per-phase model can actually express "agent drafts, human reviews" for non-code deliverables, not only for code.

### F3 (Medium): No classification for non-deliverable work items (verification passes, spikes, proving runs)

The catalog is deliverable-shaped: every row is "build X, review X". Real plans produce items that are not deliverables. On this plan, W-6 is a verification/QA pass (run the read-the-file contract checks and the dry-run scenarios) and W-3 is a spike (prove whether the platform reliably reads a queued message, then record the outcome). Neither produces a reviewable artifact, so both fell to `none, HITL` with a strained notion of "review".

- **Why it matters:** verification passes and spikes are normal outputs of `plan-implementation` (this plan explicitly created both as work units WU-8 and WU-3), and the classifier has nothing to say about them.
- **Suggested direction:** add guidance (or item-type rows) for verification/QA and spike/investigation items, whose "review" is a second-reader confirmation of the result rather than a deliverable review.

### F4 (Medium): Atomic co-land constraints are not expressible; `Depends on` only encodes order

The source plan required three units (the driver `SKILL.md`, `build-report-contract.md`, and the producer catalog) to land as **one commit** so the driver, its contracts, and the producer are never mutually inconsistent. `plan-work-items` has `Depends on` for ordering but no way to say "these must ship together atomically." Downstream, `implement-work-items` commits one commit per item, so the three units had to be collapsed into one thick work item (W-4), against this skill's own "prefer many thin work items over few thick ones" directive.

- **Why it matters:** a real, common constraint (a set of files that must change together to stay consistent) forces a choice between violating one-commit-per-item and violating thin-slices, with no way to express the actual relationship.
- **Suggested direction:** a first-class "must co-land / atomic group" relationship between work items, or explicit guidance on representing an atomic multi-file change (one thick item is acceptable when atomicity is documented as the reason).

### F5 (Medium): The template and the vertical-slice framing are code-shaped, but the catalog now classifies non-code deliverables

The catalog was extended to docs, ADRs, runbooks, skills, and agents, but the surrounding model still speaks application code. The vertical-slice directive is "a narrow but complete path through the appropriate layers (schema, API, UI, tests)", and the template's `**Tests.**` field asks for "unit, integration, migration, visual". For a markdown-authoring change, "vertical slice through layers" does not apply, and `Tests` had to be repurposed to mean read-the-file conformance checks and manual dry-run scenarios.

- **Why it matters:** the classifier and the work-item shape disagree about what kind of work this is. The catalog says "this can be documentation or a skill"; the template then asks for unit tests and API layers.
- **Suggested direction:** make the vertical-slice language and the `Tests` field deliverable-type-aware, so a doc or skill item's "tests" are its conformance and dry-run checks rather than code test levels.

### F6 (Low): `Expected paths` is required, but a verification/analysis item produces no output

The template marks `**Expected paths.**` as required, and the driver's scope check diffs against it. W-6 (verification) legitimately creates or modifies nothing, so its Expected paths is "None", which is awkward against a required field and a scope check that expects a diff.

- **Suggested direction:** allow an explicit no-output declaration for verification and analysis items.

### F7 (Low): The reference-artifact include/exclude boundary is fuzzy for `feature-technical-notes.md`

The reference-artifact inventory excludes "anything under an `artifacts/` subfolder of the plan that is not a contract or design reference", but the load-bearing technical note T1 lives under `artifacts/` next to the excluded decision logs and findings. T1 is a genuine design/contract reference an implementer of the verdict-contract items needs, so it was included, but the boundary between "design reference" and "process artifact" under `artifacts/` is judgment-heavy.

- **Suggested direction:** name `feature-technical-notes.md` explicitly as an includable design reference, or have `plan-a-feature` emit tech notes outside `artifacts/` so the exclude rule stays simple.

### F8 (Low): The closing three-group sort and next-action are driver-centric

The closing summary sorts items into driver-ready, run-the-skill-yourself, and needs-a-human, and its guidance leans on offering to drive the set with `implement-work-items`. When no item is driver-ready (as here, an all-non-code plan where five of six items are `none, HITL`), that emphasis reads awkwardly; the useful next action is "start the first item yourself".

- **Suggested direction:** let the closing summary adapt when no items are driver-ready, leading with the hand-driven next action instead of the driver offer.

## Cross-cutting observation

`plan-work-items` leaned on the orchestrator to supply classification judgment the catalog does not encode. The Step-5 dispatch to the drafting sub-agent needed heavy framing (this is markdown authoring, not testable code; guidance does not author edits; verification and spikes are `none, HITL`; the atomic constraint merges three units) to avoid a naive mapping of the core items to `guidance, AFK` per the literal catalog row. The catalog's thin coverage of meta and non-code plugin-authoring work is the root most of these findings share.

## What worked

- The three per-item signals (implementation skill, review, and per-phase AFK/HITL plus the pre-work-decision flag) are the right shape and expressed the code-vs-non-code distinction cleanly where a catalog row fit (the docs item mapped straight to `project-documentation` + `content-auditor`).
- The override and low-confidence flagging behaviors gave a clean way to record "no row fits" without dropping the item.
- The one-file, incremental, dependency-ordered output structure was fine and needed no workarounds.

## Scope note for the polishing feature

The headline is F1 and F2 (the catalog has no correct home for editing an existing skill, and no AFK path for agent-draftable non-code work). F3 through F5 are the same code-shaped-model mismatch seen from other angles. F6 through F8 are small template and summary refinements. A polishing feature could reasonably take F1, F2, F3, and F4 as its core and fold the rest in as it touches the template.
