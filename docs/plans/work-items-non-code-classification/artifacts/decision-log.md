# Decision Log: Non-code, meta, and non-deliverable work items

This file records every decision settled while specifying this feature. Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the history, rationale, evidence, and rejected alternatives.

## Trivial decisions

- D2: Feature spans two coordinating subsystems — sized medium — because the producer (`plan-work-items`) emits the per-item markers and the driver (`implement-work-items`) validates and routes on them, a vocabulary contract the two must keep reconciled. — Referenced in spec: Actors and Triggers, Coordinations.

## Full decisions

### D1: Scope is Roots A+B+C; F4 and F7 are deferred

- **Question:** Which of the eight feedback findings does this feature take on?
- **Decision:** Take Roots A (agent-drafted non-code build), B (editing an existing plugin definition), and C (non-deliverable item types plus a type-aware template). Defer F4 (atomic co-land) and F7 (tech-notes reference boundary). F8 and the review-side catalog normalization are already shipped and out of scope.
- **Rationale:** A+B+C share one root — the classification model assumes application code and has no home for non-code, meta, or non-deliverable work — so they cohere as one change. F4 needs a new inter-item relationship and a driver per-item-commit change; F7 is an unrelated one-line inventory clarification. Neither shares the A+B+C root.
- **Evidence:** user input this session; feedback.md scope note; the review-side normalization and F8 confirmed already landed in commits e6c218f–e7431d7.
- **Rejected alternatives:**
  - Fold F4 into this feature — rejected because its driving evidence is a single plan with a working fallback, and it forces a driver-commit-model change unrelated to classification.
  - Fold F7 into this feature — rejected because it is independent of the classification model and would widen the feature for no shared benefit.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D3, D4, D6
- **Referenced in spec:** Out of Scope, Deferred (YAGNI)

### D3: Agent-drafted non-code build runs through the general-purpose agent

- **Question:** How does a non-code change an agent can draft (a markdown or config edit) get marked as an unattended build, given the current model forces a no-skill build to human-in-the-loop?
- **Decision:** Classify such a build as run by a **general-purpose agent, unattended**, using the canonical marker `` `general-purpose` agent, AFK `` — naming a real built-in agent with an `AFK` marker — rather than inventing a new bare `none, AFK` marker. A bare `none` build stays human-in-the-loop. The driver's existing dispatch already handles "when it names an agent, dispatch that agent directly," so the dispatch shape is reused; but this is the first catalog classification to name an agent as a *build* (agents appear only as reviews today), so the agent-as-build path is newly exercised, and the build-report contract needs a skill-less shape for it (D13). The general-purpose agent is exempt from the catalog's "never auto-`AFK` an unconfirmed non-han skill" guardrail because it is a built-in agent, not an installed non-han skill.
- **Rationale:** Naming a real agent reuses the driver's named-agent dispatch and the build-report contract's untestable-change clause, so far less new machinery is needed than a fresh marker would take; a `none, AFK` marker would be a second, awkward way to say "an agent drafts this." The review-team pass corrected the initial "almost no new machinery" framing: the dispatch shape is reused, but the report shape and the not-installed/guardrail exemptions are genuinely new.
- **Evidence:** user direction this session ("`none`, AFK reads strange, better `general-purpose` agent, AFK"); driver dispatches a named agent for an AFK build (`han-coding/skills/implement-work-items/SKILL.md` step 3.3); the build-report contract's "not applicable (untestable: …)" clause (`references/build-report-contract.md`); the catalog's never-auto-`AFK` guardrail and its scope to non-han installed skills (`deliverable-skill-catalog.md` lines 44–46).
- **Rejected alternatives:**
  - A new `none, AFK` marker — rejected because it duplicates "an agent drafts this unattended" and reads awkwardly against the named-agent markers.
  - Keep forcing agent-draftable non-code work to a human-throughout build — rejected because it overstates the human role and denies the driver the "agent drafts, human reviews" split (feedback F2).
- **Linked technical notes:** T1
- **Driven by findings:** F3, F7
- **Dependent decisions:** D4, D11, D13, D16
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States (Agent-drafted non-code build), Edge Cases and Failure Modes

### D4: Editing an existing plugin definition is its own classification

- **Question:** Where does editing an existing skill, agent, or plugin file land in the catalog, given the only rows are "a new skill", "a new agent", and a catch-all that names the reference-only guidance skill?
- **Decision:** Add a distinct classification for modifying an existing skill, agent, or plugin definition: an agent-drafted unattended build (per D3) with the plugin-authoring guidance linked in the item's references (per D15), reviewed by a human read (per D16). It is separate from the new-skill and new-agent rows.
- **Rationale:** Editing an existing definition is the single most common plugin-maintenance task and had no correct row; the row it fell to named a skill that serves authoring rules but cannot edit files. A human read matches the review the new-skill and new-agent rows already use after the HITL normalization, and is required here because the edited artifact is one the tooling loads (D16).
- **Evidence:** feedback F1; catalog new-skill/new-agent review rows are `none, HITL` after commits e6c218f–e7431d7 (`deliverable-skill-catalog.md`).
- **Rejected alternatives:**
  - Leave edits in the "other plugin work" catch-all — rejected because that row's implementation could not perform the edit (D5).
  - Reuse the new-skill/new-agent builder skills for edits — rejected because those skills author from scratch, not edit an existing definition.
- **Linked technical notes:** —
- **Driven by findings:** F6, F7
- **Dependent decisions:** D5, D16
- **Referenced in spec:** Outcome, Alternate Flows and States (Editing an existing skill, agent, or plugin definition)

### D5: Guidance is reference-only, never the implementer

- **Question:** What becomes of the catalog's use of the guidance skill as an implementation for plugin work?
- **Decision:** Reframe guidance as reference material an agent consults for the applicable authoring rules, never the implementation that performs a change. The "other plugin work" catch-all's implementation becomes a general-purpose agent build informed by guidance; the edit-existing row (D4) does the same. Because the driver passes only the item's references and the plan to the build agent, the applicable guidance must be linked as a reference on the item (D15), not merely named in prose. The edit-existing row and the reframed catch-all coexist — the row is the common specific case, the catch-all covers other plugin work (hooks, marketplace manifest, plugin metadata).
- **Rationale:** Guidance serves and cites authoring rules; it does not author or edit files, so naming it as an implementer misdirects the build. A general-purpose agent that reads the linked guidance is the honest implementation.
- **Evidence:** feedback F1; the guidance skill's own description (serves authoring rules; `init`/`update` vendor the skills) in `han-plugin-builder/skills/guidance/SKILL.md`; the driver passes the item's references and plan to the build agent (`implement-work-items/SKILL.md` step 3.3).
- **Rejected alternatives:**
  - Keep guidance named as the implementation but clarify its role in prose — rejected because the driver would still dispatch a reference-only skill as a builder.
  - Merge the edit-existing row and the catch-all into one row — rejected because the common edit-existing case deserves an explicit, findable row.
- **Linked technical notes:** —
- **Driven by findings:** F6
- **Dependent decisions:** D15
- **Referenced in spec:** Outcome, Alternate Flows and States (Editing an existing skill, agent, or plugin definition)

### D6: A Type marker distinguishes deliverable, verification, and spike items

- **Question:** How does the model classify work that is not a deliverable — a verification pass or a spike — when every catalog row is deliverable-shaped ("build X, review X")?
- **Decision:** Add a per-item **Type** marker with three values: `deliverable` (the default), `verification`, and `spike`. It is a marker the driver validates (D11), not merely a producer note; a missing marker means `deliverable`.
- **Rationale:** A three-value marker keeps verification and spike distinct, which matters because their reviews confirm different things and their outputs differ (a verification may produce nothing; a spike records a finding). Making it driver-validated is what lets the driver couple the no-output relaxation to `verification` and refuse the unsafe combinations (D11) — without that, the review pass showed a `deliverable` could reach the no-output path.
- **Evidence:** user input this session (chose the three-value field over a two-value field or catalog-guidance-only); feedback F3; review-team finding F1 (the no-output waiver had to couple to `Type`).
- **Rejected alternatives:**
  - A two-value `deliverable`/`non-deliverable` marker — rejected by the user because it collapses the distinct verification-vs-spike review semantics.
  - Catalog guidance only, with no template field — rejected because the driver would have no field to validate the no-output guard against (D11).
  - Keep `Type` producer/documentation-facing only (not driver-read) — rejected in review: the no-output guard requires the driver to validate `Type`, so a purely producer-facing marker could not close the silent-no-op path (F1).
- **Linked technical notes:** —
- **Driven by findings:** F1
- **Dependent decisions:** D8, D9, D11
- **Referenced in spec:** Outcome, Primary Flow, Coordinations

### D7: The template's Tests field becomes a type-aware Verification field

- **Question:** The template's `Tests` field and the vertical-slice framing ask for code test levels and layers. What accommodates a non-code deliverable?
- **Decision:** Rename the `Tests` field to `Verification` and make its content deliverable-type-aware: code test levels for code; read-the-file conformance and dry-run checks for docs and skills; result confirmation for a verification item. Make the vertical-slice framing type-aware in the same way. The `Verification` field is producer- and documentation-facing; the driver does not parse it (D10).
- **Rationale:** The classifier now describes docs and skills, but the item shape still asked for unit tests and API layers, forcing a repurposing of `Tests`. A type-aware `Verification` field names what actually verifies each deliverable kind.
- **Evidence:** user input this session (chose rename over keep-with-guidance); feedback F5.
- **Rejected alternatives:**
  - Keep the `Tests` field name and add type-aware guidance — rejected by the user because the name stays code-flavored even when the content is conformance checks.
- **Linked technical notes:** —
- **Driven by findings:** F9
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow

### D8: Verification and spike items carry result-confirming reviews

- **Question:** What is the "review" of an item that produces no reviewable deliverable, and what builds it?
- **Decision:** A `verification` item's build runs its named checks (unattended when automatable, human-in-the-loop when it includes manual dry-run scenarios) and its review is the operator confirming the result is sound — not a review of a change (and always a human review, per D12). A `spike` item's build runs a probe routed by question type (per D17) with autonomy per D19 (AFK-capable, producer-judged — the producer marks an interactive-skill spike `AFK` when its question is well-formed and correctly routed, `HITL` when exploratory; a quick empirical probe via a general-purpose agent is `AFK`) and records its finding as the deliverable; its review confirms the finding is recorded, non-empty, and sound.
- **Rationale:** A verification/spike item's value is a confirmed result or a recorded finding, so its review is a second-reader confirmation, which the driver already models as a human read. An empty spike finding is not a sound result, so the review rejects it. How a spike's build is routed among skills is settled separately in D17.
- **Evidence:** feedback F3; the driver captures a human read as the normalized verdict (`implement-work-items/references/human-review-capture.md`); review-team findings F6 (classification home) and F10 (empty-finding guard).
- **Rejected alternatives:**
  - Force verification/spike items through a deliverable-style change review — rejected because there may be no change to review, and the meaningful check is the result.
- **Linked technical notes:** —
- **Driven by findings:** F2, F6
- **Dependent decisions:** D9, D17
- **Referenced in spec:** Primary Flow, Alternate Flows and States (Verification pass, Spike), Edge Cases and Failure Modes

### D9: A verification item may declare no output and is then driven without a commit

- **Question:** How does the driver handle an item that legitimately creates or modifies nothing, given it halts a build that reports no files, scope-checks against Expected paths, and commits per item?
- **Decision:** Let a `verification` item declare `Expected paths: None`. For such an item the driver dispatches the build knowing zero files is the expected result, accepts a build that produced no files, and records the item complete as a distinct no-commit outcome rather than forcing an empty commit. `Expected paths: None` is legal *only* for a `verification` item; a `verification` that emits a report declares that path and commits normally. A no-output item whose build unexpectedly produces files does not silently no-commit — the change is surfaced as a scope finding for the operator (D14).
- **Rationale:** The review pass showed that keying the waiver off `Expected paths: None` alone — decoupled from `Type` — let a `deliverable` reach the accept-nothing path and route a failed build through as success. Coupling the waiver to `verification` (enforced by D11) closes that hole while still allowing a genuinely empty verification. Keying the no-output *handling* off the item being a no-output `verification` keeps the rule from silently swallowing an unexpected diff.
- **Evidence:** feedback F6; build-report contract halts a `built` status with no files (`references/build-report-contract.md`); scope check diffs against Expected paths (`references/review-verdict-contract.md`); the foreground protocol already avoids an empty commit (`references/foreground-handoff-protocol.md`); review-team findings F1, F3, F4, F5.
- **Rejected alternatives:**
  - Gate the no-output handling on `Expected paths: None` decoupled from `Type` (the original draft) — rejected in review because it made `deliverable` + `None` legal and opened a silent-no-op path (F1).
  - Require every `verification` to declare `None` — rejected because a verification may emit a report file (F11); the rule is one-directional (`None` ⇒ `verification`, not `verification` ⇒ `None`).
  - Keep Expected paths strictly required with no `None` — rejected because it forces an awkward value and a scope check that cannot pass cleanly (feedback F6).
- **Linked technical notes:** —
- **Driven by findings:** F1, F3, F4, F5
- **Dependent decisions:** D11, D14
- **Referenced in spec:** Outcome, Primary Flow, Alternate Flows and States (Verification pass), Edge Cases and Failure Modes

### D10: The extended format is backward compatible

- **Question:** What happens to work-items files written before this feature — without a `Type` field, using the old `Tests` field?
- **Decision:** The driver validates `Type` but reads a missing `Type` as `deliverable`, so an older file drives unchanged. The renamed `Verification` field is not one the driver parses (the driver reads only Expected paths, the routing markers, and Depends on), so a file that still says `Tests` drives identically. No migration of existing files is required.
- **Rationale:** The new `Type` marker defaults safely to `deliverable`; the renamed field is producer- and documentation-facing only, so renaming it cannot break the driver. The review pass corrected the initial phrasing "the driver does not parse `Type`": the driver *does* read `Type` for validation (D11), but a missing one defaults to `deliverable`, which is what preserves compatibility.
- **Evidence:** the driver validates and parses only `Expected paths`, `Requires pre-work decisions`, `Suggested implementation`, `Suggested review`, and `Depends on` today (`implement-work-items/SKILL.md` steps 1.7 and 3); it does not parse `Tests`.
- **Rejected alternatives:**
  - Make `Type` required — rejected because it would invalidate every existing work-items file for no behavioral gain.
- **Linked technical notes:** —
- **Driven by findings:** F1
- **Dependent decisions:** —
- **Referenced in spec:** Edge Cases and Failure Modes

### D11: The Type marker is driver-validated with startup refusals

- **Question:** What stops a marker combination that would route a failed or no-op build onto the no-output accept-nothing path?
- **Decision:** The driver reads `Type` at validation and refuses, before mutating the repository: a present `Type` outside the three values; `Expected paths: None` on any item that is not a `verification`; an `AFK` review on any `verification` item or any item declaring `Expected paths: None`; and a `` `none`, AFK `` build marker (a bare `none` build is always human-in-the-loop). A missing `Type` defaults to `deliverable`. An interactive-skill spike's `AFK`-vs-`HITL` is producer-judged (D19), not a driver refusal — such a spike run `AFK` produces its finding and returns; an edge-case gate fails recoverably, not corruptingly, so no hard guard is warranted. The producer applies these same refusals as it classifies and writes each item: because it authors from a well-formed catalog, the realistic way it would reach a refused combination is an operator override, so rather than write one it **declines the specific override field(s) that create the refused combination and restores the item's catalog-derived classification, naming the declined override and the conflict in the breakdown** — it does not transform the item to a different `Type` or output contract to make the override fit. The driver re-checks all the refusals as the last line, because a hand-edited file bypasses the producer. The refusal set is one shared contract: a change to it is applied to both skills in the same commit (a maintenance convention, not enforced by machinery). The producer-side trigger narrowing and the override-refusal exception land in the catalog's `Requires pre-work decisions` classification step and its Overrides note as well as the template — a required (semantic, not phrasing-only) `plan-implementation` change.
- **Rationale:** The no-output relaxation is only safe if the unsafe marker combinations cannot exist at run time. Converting them into loud pre-run refusals turns a silent mid-run no-op into a startup error the operator sees and fixes. Validating on both sides warns the operator at authoring time (producer) while keeping the driver as the last line against hand-edits. This also pins the canonical `` `general-purpose` agent `` build token so the producer and driver agree on the value.
- **Evidence:** review-team findings F1 (silent-no-op path), F2 (rubber-stamp review), and the edge-case findings on `none, AFK` and unrecognized `Type`; the driver already halts on undrivable items at startup (`implement-work-items/SKILL.md` step 1.7); producer-side validation added per operator direction this session.
- **Rejected alternatives:**
  - Warn and default an unrecognized `Type` to `deliverable` — rejected because `Type` now gates a safety-critical coupling, so an unrecognized value must halt, not silently degrade.
  - Enforce the coupling only in the producer, not the driver — rejected because a hand-edited file bypasses the producer, so the driver must re-check as the last line; the producer applies the refusals too, but is not the sole guard.
  - Resolve a refused override to the "nearest valid classification" (the round-1 wording) — rejected in review round 2 because "nearest valid" is destructive when no correction preserves the item's meaning (a `spike` + `Expected paths: None` override has no fix but flipping the item to a `verification`, changing its whole behavior); the producer declines the override and keeps the valid classification instead (review-findings F11).
  - Add a fifth refusal on an `AFK` interactive-skill spike — considered across the review (added R2, removed, restored R3) and finally removed (review-findings F20, D19): `research`/`investigate` run `AFK`-clean for well-formed questions, so an interactive-skill spike's autonomy is producer-judged, not driver-refused.
- **Linked technical notes:** —
- **Driven by findings:** F1, F2
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Startup Validation and Refusals, Edge Cases and Failure Modes, Coordinations

### D12: A no-output item is reviewed by a human confirmation

- **Question:** How is an item that produced no change reviewed, given an unattended review agent computes a diff and would pass a clean verdict over nothing?
- **Decision:** A `verification` item, and any item declaring `Expected paths: None`, must record a human review (`none` or `HITL`), never an `AFK` sub-agent review (enforced by D11). The human-review capture gains a no-output branch: the operator confirms the checks ran and the result is sound rather than reviewing an absent change, and the coverage attestation is "operator confirmed result."
- **Rationale:** An unattended review of an empty diff is a gate that inspects nothing — a rubber stamp. The operator confirming the result is the only meaningful review of a no-output item.
- **Evidence:** review-team findings F2; review-verdict contract computes the diff against Expected paths and attests coverage (`references/review-verdict-contract.md`); human-review capture points the reviewer at the item's change (`references/human-review-capture.md`).
- **Rejected alternatives:**
  - Allow an `AFK` review for a no-output item as a convention the producer should follow — rejected because a convention a hand-edit can violate is not a guard; it must be validated.
- **Linked technical notes:** —
- **Driven by findings:** F2
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Primary Flow, Startup Validation and Refusals, Edge Cases and Failure Modes, Coordinations

### D13: The build-report contract gains a skill-less and no-output shape

- **Question:** What does a general-purpose (skill-less) build, or a declared-no-output build, report, given the build-report contract assumes a skill with a green gate and halts on a build that produced no files?
- **Decision:** Extend the build-report contract so a general-purpose build reports without a skill-gate claim (verification is driver-side only), and a declared-no-output `verification` build is dispatched knowing zero files is expected and may report `built` with an empty file set as a clean completion. The empty-file halt still applies to any item that declared output.
- **Rationale:** Today the contract's `built` means "the implementation skill's gate is green" and an empty file set is a halt — a general-purpose agent runs no skill and a no-output verification changes no files, so both legitimate cases were unreportable. The contract must express them, or the feature's two new build shapes cannot report success.
- **Evidence:** the build-report contract's STATUS/FILES/gate semantics and empty-file halt (`references/build-report-contract.md`); driver step 3.3 copies the contract verbatim into the dispatch; review-team findings F3.
- **Rejected alternatives:**
  - Relax only the driver's parse of the report, not the dispatch instruction — rejected because the sub-agent still receives "list every file / empty is suspect" and would escalate as blocked (F3).
- **Linked technical notes:** T1
- **Driven by findings:** F3
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Alternate Flows and States (Agent-drafted non-code build), Coordinations

### D14: A no-commit completion is labeled, tracked, and idempotent

- **Question:** How does the operator tell a legitimately-empty verification from a silent no-op, and how does a no-commit item survive the driver's commit-range-based recovery?
- **Decision:** The driver labels a no-commit completion as its own outcome in the completion and halt summaries — naming the item, its `Type`, and its declared `Expected paths: None`, plus a count — and records it distinctly in its work-state. Because a no-commit item leaves no commit for the cherry-pick-forward recovery to carry, and the driver re-runs from the first item on re-invocation, the spec commits that a no-output item's execution must be idempotent (safe to repeat). The driver also asserts a clean working tree before each item, so a no-output item that unexpectedly left files cannot contaminate the next item's scope baseline.
- **Rationale:** Removing the empty-file halt guard removes the operator's only signal that a no-op happened; the compensating visibility (a labeled, counted outcome) must ship with it. The idempotency commitment replaces the commit-based deduplication the no-commit design gives up.
- **Evidence:** the completion summary and halt procedure report commit references/ranges (`implement-work-items/SKILL.md` step 4 and Halt Procedure); state.json records a per-item commit-range (step 2.2/3.4); scope-baseline is the per-item HEAD and the review sweeps untracked files (step 3.1, `references/review-verdict-contract.md`); review-team findings F4, F5.
- **Rejected alternatives:**
  - Report a no-commit item with an absent commit reference like any other — rejected because it is then indistinguishable from a silent no-op (F4).
- **Linked technical notes:** —
- **Driven by findings:** F4, F5
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D15: The catalog gains classification homes for verification and spike, and links guidance

- **Question:** How does the producer classify a verification pass or a spike, and how does the plugin-authoring guidance actually reach the build agent?
- **Decision:** The feature adds catalog homes (rows or `Type`-conditional guidance) for verification and spike: a verification runs its named checks with a human result-confirmation review; a spike's build is routed by question type (per D17) and records a finding reviewed for soundness. The plugin-definition-edit and catch-all classifications record the applicable authoring guidance as a linked reference on the item, so the driver — which passes only the item's references and the plan to the build agent — delivers it. The feature surfaces the assumption that the guidance is reachable (installed or vendored) in the target repo.
- **Rationale:** Without a catalog home, a spike meant to run `han-coding:investigate` unattended falls to the "no han skill fits" catch-all and is classified human-throughout, contradicting D8; and "informed by guidance" is inert unless the guidance is a linked reference the build agent receives.
- **Evidence:** the catalog's Table 1 has no verification/spike row and does not name `han-coding:investigate` (`deliverable-skill-catalog.md`); the driver passes the item's references and plan to the build agent (`implement-work-items/SKILL.md` step 3.3); review-team findings F6.
- **Rejected alternatives:**
  - Leave classification to the catch-all and producer judgment — rejected because it reproduces the exact feedback F3 gap the feature exists to close.
- **Linked technical notes:** —
- **Driven by findings:** F6
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Alternate Flows and States (Spike), Coordinations

### D16: An edit to an executable plugin artifact requires a human read

- **Question:** What stops an agent-drafted edit that breaks a skill or agent file (corrupt frontmatter, a dropped tool grant) from committing green, given the build's evidence is waived as untestable and the driver's verify step does not run the item's own conformance checks?
- **Decision:** An agent-drafted edit to an executable plugin artifact — a skill, agent, plugin manifest, or config the tooling loads — is reviewed by a human read. An unattended prose review (content-auditor / information-architect) is reserved for genuinely non-executable prose, where structural breakage carries no runtime blast radius.
- **Rationale:** For an executable artifact the build's untestable declaration cannot be the sole gate: a structurally-broken but prose-plausible edit would pass an unattended prose review, which judges comprehension, not whether the artifact loads. A human read is the smallest gate that catches it, and it matches the review the edit-existing classification already carries (D4).
- **Evidence:** the build-report untestable clause and the driver's project-level (not item-level) verify step (`references/build-report-contract.md`, `implement-work-items/SKILL.md` steps 3.3–3.4); review-verdict mapping shows content-auditor/information-architect judge prose, not structure (`references/review-verdict-contract.md`); review-team findings F7.
- **Rejected alternatives:**
  - Add a mechanical conformance gate the driver runs before commit — a stronger option, but heavier (a new driver capability and a per-artifact-type check); deferred in favor of the simpler human read that satisfies the same evidence, and recorded as a formal deferral with a reopen trigger in the spec's `## Deferred (YAGNI)` section rather than an informal "planned later" (review-findings F9). The human read stays correct even after the mechanical gate is added.
  - Keep "typically a human read" as guidance — rejected because "typically" admits the unattended prose review that misses structural breakage (F7).
- **Linked technical notes:** —
- **Driven by findings:** F7
- **Dependent decisions:** —
- **Referenced in spec:** Outcome, Alternate Flows and States (Agent-drafted non-code build, Editing an existing skill…), Edge Cases and Failure Modes

### D17: A spike's build routes by question type

- **Question:** Which skill or agent builds a spike, given a spike can probe code or non-code and the initial two-way heuristic (investigate vs. general-purpose) left out open-ended and non-code investigations?
- **Decision:** Route a spike's build by the shape of its question, not by code-vs-non-code: `han-coding:investigate` for a named symptom with a codebase root cause to trace; `han-core:research` for an open-ended question — options, prior art, how something works, or whether an approach would hold — which can pair repo and web evidence; and a general-purpose agent for a quick empirical probe resolvable in a single read or command. The producer's default is `research` unless the question is a named symptom with a codebase root cause. **Autonomy is settled in D19:** a spike's build is AFK-capable and escalates via the build report's `blocked` path when it needs the operator; on today's halt-only driver an interactive-skill spike defaults to `HITL` (a producer default, not a refusal), while a quick-probe general-purpose spike is `AFK`. A spike's finding is whatever the routed skill produces (a root-cause document is a valid finding); its output lands at the item's Expected path. Two foreground details land in `plan-implementation` (review-findings F14): the spike handoff must name the item's Expected path, and the spike's review is a finding-soundness confirmation (recorded, non-empty, answers the question) rather than the standard change review.
- **Rationale:** The two skills' own scopes prescribe the routing split, and the tool boundary enforces it: `investigate` has no web access and its agents are file-path-anchored with a fix-plan output shape, so it fits a symptom-shaped probe (on code or non-code files); `research` is question-shaped, pairs a web-facing research analyst with a codebase explorer, and outputs a recommendation or finding — exactly what a spike commits. (Autonomy — AFK-capable, producer-judged per item — is reasoned in D19.)
- **Evidence:** research-analyst investigation this session, confirmed by the evidence-based-investigator, across both skills' definitions and long-form docs — `investigate` scope and no-web tooling (`han-coding/skills/investigate/SKILL.md`), `research` scope and web-plus-repo reach (`han-core/skills/research/SKILL.md`), the file-path-anchored investigate agents versus the web-facing research analyst (`han-core/agents/`); the interactive clarify/overwrite/redirect/approval points and their collision with the driver's fail-closed AFK build-report parse (`han-core/skills/research/SKILL.md`, `han-coding/skills/investigate/SKILL.md`, `implement-work-items/SKILL.md` step 3.3), surfaced in iterative-plan-review round 1 (review-findings F1, F2, F6).
- **Rejected alternatives:**
  - The two-way heuristic (investigate for a codebase question, else general-purpose) — rejected because it routes an open-ended or non-code investigation to a bare general-purpose agent and never reaches `research`; kept on record as the strictly simpler version behind the `research`-route YAGNI note.
  - Always `research` for spikes — rejected because a genuinely symptom-shaped codebase probe loses `investigate`'s multi-angle tracing, git history, and adversarial fix validation.
- **YAGNI note (review-findings F7):** the `research` route rests on the feature's explicit support for open-ended spikes (feedback F3) and operator direction this session, not a specific spike that needed web reach; its `HITL`-today default (D19) bounds its cost to a foreground, operator-run skill, so it is kept over the simpler two-way fallback.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D19
- **Referenced in spec:** Alternate Flows and States (Spike)

### D18: The pre-work-decisions field is kept, with a producer routing note

- **Question:** Now that a `spike` Type exists, can the `Requires pre-work decisions` field be retired in favor of a spike (or ADR) item the dependent item depends on?
- **Decision:** Keep the field, but narrow its producer-side trigger and give the producer a decidable **ordered** routing rule (criteria can co-apply, so precedence matters): a decision whose answer must be permanently recorded and referenced is modeled as an architectural decision record the dependent item depends on; else a decision that requires reading files, running code, or gathering external evidence is modeled as a spike it depends on; else a decision statable and actionable in a single sentence stays on the inline `Requires pre-work decisions` flag. A decision that both needs investigation and must be recorded is a spike whose finding an ADR records. This narrows the field's former "an architectural decision or a design gate" trigger — a record-worthy architectural decision now routes to an ADR rather than the inline flag — so the trigger narrows in both the template's field definition and the catalog's `Requires pre-work decisions` classification step (a required `plan-implementation` change). Retiring the field itself is deferred as a separate change.
- **Rationale:** A spike produces and commits a *finding* (an empirical answer); a pre-work decision is an *ephemeral human judgment* that steers the same item's build. Spikes and the ADR row absorb the investigation-shaped and record-worthy decisions, but neither cleanly covers the pure judgment call — forcing it into a spike produces an empty finding the spike's own soundness review rejects (D8), and into an ADR manufactures a record nobody asked for. The inline gate is also materially lighter (one field and one pause versus a whole item with its own build, review, commit, and dependency edge). Review round 1 surfaced two gaps this decision now closes: "keep the field" silently contradicted the template's current "architectural decision" trigger (review-findings F3), and the three-way choice had no decidable rule (review-findings F4) — the single-sentence / requires-evidence / must-be-recorded discriminator resolves both.
- **Evidence:** junior-developer investigation this session: the field's definition and its "architectural decision or a design gate" trigger (`work-item-template.md`); the producer sets it (`plan-work-items` catalog); the driver's Decide step captures it into ephemeral, gitignored state and passes it to the builder (`implement-work-items/SKILL.md` steps 3.2, 2.2); the spike's empty-finding rejection (D8).
- **Rejected alternatives:**
  - Retire the field and model every pre-work decision as a spike or ADR item — rejected because it forces an extra item, build, review, commit, and dependency edge on every decision, manufactures artifacts for pure judgment calls, and is a producer↔driver contract change out of this feature's scope (D1).
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows and States (Spike), Out of Scope

### D19: Spike autonomy is AFK-capable, producer-judged per item

- **Question:** Must a spike routed to an interactive skill (`investigate`/`research`) be HITL, or can it run `AFK` and produce its finding unattended?
- **Decision:** Interactive-skill spikes are **AFK-capable today**. Run as an unattended build, `research` produces its report and returns (it writes the report and presents it, with no blocking approval gate and an explicit "proceed without a blocking confirmation"); `investigate` writes its finding and returns (its approval gate is about triggering a *fix*, which a spike does not want). The **producer** — which authors the spike's question — marks the spike `AFK` when the question is well-formed, correctly routed (per D17), and single-thread, and `HITL` when it is inherently exploratory or likely to need clarification. There is **no driver refusal**. The interactive gates that would block are avoidable edge cases the producer controls — a mis-route (avoided by D17's routing), a too-vague clarify (avoided by writing a specific question), and a compound multi-thread question (avoided by splitting) — plus one unavoidable gate, a re-run overwrite of an existing finding file (rare, recoverable). On any gate that does fire today, the sub-agent's behavior is undefined because no skill instructs it to emit `STATUS: blocked` — a recoverable halt, not corruption. A build-dispatch instruction that maps a routed skill's operator-gates to a `blocked` escalation (a `plan-implementation` enhancement), together with escalate-and-resume, upgrades those edge-case gates into clean mid-run escalations (full AFK-that-escalates-on-need); neither is required for AFK to work on the common case today.
- **Rationale:** Re-reading the skills showed `research` produces its report and closes with no blocking approval (Step 8 "write it to the output location and present it"; Step 4 "proceed without a blocking confirmation"), so a well-formed, correctly-routed, first-run, single-thread research spike runs `AFK` cleanly; `investigate` likewise writes its finding regardless of its fix-approval gate. The earlier round-1/2/3 framing (interactive-skill spikes can't be `AFK` → HITL, then a capability-gated refusal) over-read the skills' "present"/"approval" language as blocking and treated avoidable edge-case gates as deterministic. The producer, which writes the spike's question, is best placed to judge `AFK`-vs-`HITL` per item; a blanket refusal would foreground-run well-formed spikes for no benefit. The residual edge-case gates fail *recoverably* (a halt), not corruptingly, so a hard driver guard is not warranted.
- **Evidence:** operator decision this session (AFK-capable, producer-judged); `research/SKILL.md` — Step 1 clarify fires only on a too-vague question and overwrite only on a re-run, Step 2 out-of-scope fires only on a mis-routed non-research question, Step 4 "proceed without a blocking confirmation", Step 8 "write it to the output location and present it" (no blocking approval); `investigate/SKILL.md` — the finding is written before its Step 5 fix-approval gate, which a spike does not trigger.
- **Rejected alternatives:**
  - A hard (capability-gated or permanent) driver refusal of `AFK` interactive-skill spikes — rejected: `research`/`investigate` run `AFK`-clean for well-formed, correctly-routed questions, so a blanket refusal foreground-runs them for no benefit; the blocking gates are avoidable edge cases the producer controls plus a rare recoverable overwrite. (A fifth refusal was carried through the review — added R2, removed, restored R3 — and finally removed here once the skills' actual "no blocking approval" behavior was established; see review-findings F20.)
  - Make the AFK-with-escalation dispatch instruction a *prerequisite* for allowing `AFK` — rejected: it is an *enhancement* that upgrades recoverable edge-case halts into clean mid-run escalations, not a gate on the common case, which already works.
- **Linked technical notes:** —
- **Driven by findings:** — (supersedes the HITL/refusal framing of review-findings F1, F10, F15, F16; final position set by review-findings F20)
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows and States (Spike), Out of Scope
