# Decision Log: Per-Item Skill Selection for Work Items

<!--
Records every decision settled while specifying this feature. Behavioral statements
live in ../feature-specification.md; this file holds the history, rationale, evidence,
and rejected alternatives.
-->

## Trivial decisions

- D10: Closing recommendation and per-item drivability marker — the producer marks each item driver-ready or needs-a-hand in the breakdown, and its closing recommendation sorts items into three groups (driver-ready `tdd` + `code-review`; run-the-skill-yourself for an `AFK` item whose build and review are both autonomous-or-not-applicable but not the driver's combination, like `project-documentation` + `content-auditor` or `guidance` + `none`; needs-a-human for every `HITL` item — an interactive skill, a `human read` review, a pre-work gate, or a bare item), so a mixed or non-drivable set is not mistaken for a fully drivable one and an item needing a human review is never labeled "no human needed" (driven by findings F1, F10, F21). — Referenced in spec: Primary Flow, Edge Cases and Failure Modes, User Interactions.
- D11: Dual-nature items are split into vertical slices — a work item whose deliverable spans two natures (for example code plus its runbook) is split into one item per deliverable and skill, following the producer's existing vertical-slice discipline; when it cannot be cleanly split, the producer records the dominant skill and flags the uncovered nature (considered recording a single skill and silently dropping the second deliverable; rejected because the vertical-slice rule already forbids thick items and a dropped deliverable is invisible) (driven by finding F8). — Referenced in spec: Primary Flow, Edge Cases and Failure Modes.

## Full decisions

### D1: Scope, producer selects and driver consumes

- **Question:** How far does this feature reach — does `plan-work-items` only record a chosen skill, or does the autonomous driver also consume it?
- **Decision:** `plan-work-items` selects and records the implementation skill, the review, and the three autonomy signals ([D4](#d4-recorded-autonomy-signals-replace-the-afkhitl-type)) per item; `implement-work-items` reads them, computes each item's autonomy from the signals (replacing its reliance on the core loop's `Type` field), and dispatches the skill and review per item instead of assuming `tdd` + `code-review`, driving only files whose every item is fully autonomous and of a supported combination and refusing the rest at startup. This reopens the core loop's deferred "Per-item implementation-skill selection" and extends its per-item field set. The reopen trigger is only partly met: it requires both "a second non-interactive code-producing skill exists" AND "a decision tree plus a non-han affordance." The second conjunct is delivered; the first is not — `refactor` turned out interactive ([D4](#d4-recorded-autonomy-signals-replace-the-afkhitl-type)), leaving `tdd` the only autonomous code skill — so the reopening rests on the broader per-item value (correct typing, the right skill recorded for humans and future drivers, and the non-han affordance) and operator direction, which the spec states plainly rather than claiming a clean trigger.
- **Rationale:** A recorded field the driver ignores would be inert and, worse, actively wrong: the driver today hardcodes `tdd` with a `tdd`-shaped build-report contract, so an item recorded for another skill would be mis-driven. Making the driver read the fields keeps the choice honest end to end, while keeping the driver's supported set narrow ([D5](#d5-driver-drivability-is-computed-from-the-signals)) keeps the change minimal.
- **Evidence:** The core loop defers this exact item and names its reopen trigger — "a second non-interactive code-producing skill exists AND the design adds a skill-selection decision tree plus an affordance for the operator to allow non-han skills" (`autonomous-driver-core-loop/feature-specification.md`, Deferred (YAGNI); decision log D16, D19). The driver hardcodes `han-coding:tdd` in its build step and `han-coding:code-review` in its review step, with a `tdd`-specific build-report contract (`han-coding/skills/implement-work-items/SKILL.md`). User input chose "producer + minimal driver read" and, for review, "add field + driver consumes it."
- **Rejected alternatives:**
  - Producer-only, driver untouched — rejected because the driver would mis-drive any non-`tdd` item as `tdd`, leaving the field inert and unsafe.
  - Producer + full driver support for every non-interactive skill (per-skill build/verify contracts now) — rejected as over-scoped; only `tdd` is drivable today ([D5](#d5-driver-drivability-is-computed-from-the-signals)), so the extra contracts would have no live consumer.
  - Claim the reopen trigger is cleanly met — rejected as an overclaim; `refactor` is interactive, so the spec discloses the partially-met trigger instead.
- **Linked technical notes:** —
- **Driven by findings:** F7 (reopen-trigger overclaim disclosed), F25 (driver computes autonomy from the signals, replacing the `Type` gate)
- **Dependent decisions:** D4, D5, D6
- **Referenced in spec:** Outcome (intro); Actors and Triggers; Coordinations

### D2: Deliverable-nature decision tree and skill catalog

- **Question:** By what does the producer pick a skill, and which skills are in the catalog?
- **Decision:** The producer classifies each item by the nature of its deliverable and selects the matching han skill: testable code → `tdd`; behavior-preserving restructuring → `refactor`; a new skill → `skill-builder`; a new agent → `agent-builder`; vendoring or refreshing plugin-building guidance → `guidance`; feature or system documentation → `project-documentation`; an ADR → `architectural-decision-record`; a coding standard → `coding-standard`; a runbook → `runbook`. The documentation family is included so non-code work items get a named skill rather than a wrong `tdd` default or a bare item. An item spanning two natures is split into vertical slices ([D11](#trivial-decisions)).
- **Rationale:** The producer already classifies each item (it assigns `Type`), so classifying deliverable nature is a natural extension. Matching nature to the skill whose stated purpose is that nature is the most legible rule and lets the operator and the driver both act on the choice. Including the documentation family is low cost (the mappings are one-to-one) and directly useful: it tells whoever implements the item exactly what to run.
- **Evidence:** Each skill's stated purpose in its description/frontmatter — `tdd` ("write code... test-first"), `refactor` ("restructure existing code without changing its behavior"), `skill-builder`/`agent-builder` ("builds a new... skill/agent"), `guidance` ("init and update steps that install and refresh the plugin-building skills"), `project-documentation`, `architectural-decision-record`, `coding-standard`, `runbook` (`han-core/skills/`, `han-coding/skills/`, `han-plugin-builder/skills/`). User input chose to add the documentation family.
- **Rejected alternatives:**
  - Code + plugin-building only (no documentation family) — rejected by the user; a "write the runbook" item would land as a bare item with no skill named, losing useful guidance for cheap gain.
  - Route documentation only through the non-han scan — rejected because han has first-class documentation skills; leaning on the low-confidence scanning heuristic for common doc work would be worse than a direct mapping.
- **Linked technical notes:** —
- **Driven by findings:** F8 (dual-nature split cross-referenced to D11), F23 (`guidance` review recorded `none` so the review-selection tree is total)
- **Dependent decisions:** D3, D4, D11
- **Referenced in spec:** Outcome; Primary Flow; Coordinations

### D3: tdd only for testable deliverables

- **Question:** Is `tdd` the default skill for any item without a clearer fit?
- **Decision:** `tdd` is selected only for a deliverable that has tests to lead it (code, or anything test-verifiable). The producer never defaults a non-testable deliverable (documentation, a vendoring step, an ADR) to `tdd`; when a deliverable's nature is ambiguous it flags the item low-confidence rather than defaulting to `tdd`.
- **Rationale:** `tdd`'s whole loop is test-first; pointing it at a deliverable with no tests produces no red-green evidence and, downstream, the driver's `tdd` build-report contract (which requires observed test-failure-then-pass) would reject it. Defaulting to `tdd` would systematically mis-type and mis-drive non-code work.
- **Evidence:** `tdd` drives behavior "through red-green-refactor with an enforced observed-failure gate" (`han-coding/skills/tdd/SKILL.md`); the driver treats a `tdd` report missing test-failure-then-pass evidence as untrustworthy and halts (`autonomous-driver-core-loop/feature-specification.md`, Edge Cases; `implement-work-items` build-report contract). User input ("we shouldn't recommend tdd for non-testable things").
- **Rejected alternatives:**
  - Default to `tdd` for anything without a clearer fit (today's implicit behavior) — rejected because it mis-types non-testable work and feeds the driver reports it must reject.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D5
- **Referenced in spec:** Outcome; Primary Flow; Edge Cases and Failure Modes

### D4: Recorded autonomy signals replace the AFK/HITL type

- **Question:** How is each item classified for autonomy — a single `AFK`/`HITL` type, or something finer — and what does the producer record?
- **Decision:** The single `Type` field is replaced by three recorded per-item signals: whether the **build phase runs unattended**, whether the **review phase runs unattended**, and whether a **human decision is required before work starts**. AFK/HITL survives only as a *derived* label: an item is **fully autonomous** ("AFK") when its build and review both run unattended and no pre-work decision is required, and **needs a human** ("HITL") otherwise. For a han skill the producer derives the build signal from the skill's known behavior (`tdd`, `project-documentation`, `guidance` run unattended; `refactor`, `skill-builder`, `agent-builder`, `architectural-decision-record`, `runbook`, `coding-standard` stop for a human) and the review signal from the review's known behavior (`code-review`, `content-auditor`, `information-architect` run unattended; `human read` does not; `none` means no review runs). For a user-defined skill it cannot infer behavior, so it takes the operator's declaration and defaults the phase to not-unattended. The pre-work-decision signal is a gate resolved once, distinct from a skill that needs a human throughout; a bare item (implementation skill `none`) has no unattended build.
- **Rationale:** A single AFK/HITL bit is lossy in two ways the human-in-the-loop driver (the named next feature) cannot afford: it cannot tell an autonomous build with a human review from a fully-manual item, and it cannot tell a gate-then-autonomous item from a throughout-interactive one — yet those need opposite orchestration (sub-agent one phase and foreground the other; gate once then delegate). Recording the three signals lets that driver read which phase needs a human. Reconstructing them from the skill fields only works for han skills; for a user-defined skill the producer cannot infer interactivity, so the signal must be recorded, not derived. Replacing the field (rather than keeping a derived `Type`) avoids a stored value that can drift from the signals it summarizes.
- **Evidence:** For non-han skills the producer "cannot reliably tell whether an arbitrary skill is code-producing or interactive" ([D8](#d8-non-han-skills-suggested-only-when-no-han-skill-fits)), so autonomy is not inferable for them. `refactor` stops and waits (no-coverage and re-scope gates, `han-coding/skills/refactor/SKILL.md`); `skill-builder`/`agent-builder` are interview-driven; `architectural-decision-record`, `runbook`, `coding-standard` contain "ask the user" gates; `tdd` "runs autonomously with no gate" (core loop D16); `project-documentation`/`guidance` show no gates. The human-in-the-loop driver is named upcoming work (operator direction; reference plan's deferred HITL path), which supplies the consumer for the recorded signals. User input chose to replace `Type` with the three signals and to let the operator declare a non-han skill's autonomy.
- **Rejected alternatives:**
  - Keep a single `Type` (AFK/HITL) field — rejected (findings F21, F25): it cannot represent an autonomous build with a human review, or a gate-then-autonomous item, and forces a user-defined skill to `HITL` because its interactivity is unknown.
  - Keep `Type` as a derived rollup alongside the three signals — rejected by the operator: a stored derived value can drift from the signals; consumers compute the label instead.
  - Defer the decomposition and reconstruct the signals from the skill fields — rejected (finding F25): reconstruction holds only for han skills; for user-defined skills the signals are not inferable, and the human-in-the-loop driver is a named dependency, so recording them now is groundwork, not speculation.
  - Treat `refactor` as non-interactive because its happy path is autonomous — rejected: its stop-and-wait gates can fire mid-run and a disposable sub-agent cannot answer them.
- **Linked technical notes:** —
- **Driven by findings:** F3 (independent-human need preserved), F21 (review autonomy is an input), F25 (three signals replace `Type`; non-han autonomy declared)
- **Dependent decisions:** D5, D6, D7, D8
- **Referenced in spec:** Outcome; Primary Flow; Edge Cases and Failure Modes; Coordinations; Deferred (YAGNI)

### D5: Driver-drivability is computed from the signals

- **Question:** Which items can the driver run unattended, and what does it do with a file that contains any it cannot?
- **Decision:** The driver computes each item's autonomy from the three recorded signals (build unattended, review unattended, no pre-work decision) rather than reading a stored `Type`. An item is driver-drivable only when it is fully autonomous *and* its skill-and-review combination is one the driver supports — today, `tdd` built and `code-review` reviewed. The driver validates this at startup, before the plan preview and before any branch, and if any item is not driver-drivable (it needs a human, or it is fully autonomous but of an unsupported combination such as `guidance`, `project-documentation`, or a declared-autonomous user skill) it refuses the whole run at startup, naming the offending items, rather than driving a partial set. Driver-readiness is judged by matching the item's recorded combination against the supported combination, not by the fully-autonomous label alone.
- **Rationale:** `tdd` is the only build skill that is both autonomous and test-verifiable through the driver's `tdd` report contract, and `code-review` is the correct review for the code it produces, so that pairing is the only combination the driver can build, verify, and gate unattended today. Whole-run refusal at startup (not a partial run) matches the core loop's committed behavior — "one containing any `HITL`-typed item is a startup refusal, not a partial run" — and avoids running an item in dependency order whose prerequisite was a skipped, non-drivable item.
- **Evidence:** The core loop refuses the whole run at startup on any item it cannot drive (`plan-work-items` Step 5; core loop D13, D19; `autonomous-driver-core-loop/feature-specification.md` Primary Flow step 1). The driver already refuses non-drivable items, missing fields, before mutating anything, and processes items in topological dependency order (`han-coding/skills/implement-work-items/SKILL.md`, Steps 1 and 3). `tdd` autonomous+verifiable and the only such combination follows from [D3](#d3-tdd-only-for-testable-deliverables), [D4](#d4-recorded-autonomy-signals-replace-the-afkhitl-type).
- **Rejected alternatives:**
  - Read a stored `Type` to gate the driver — rejected (finding F25): `Type` is replaced by the three signals, which the driver computes autonomy from.
  - Drive the supported subset and skip the rest (partial run) — rejected (finding F1): items run in dependency order, so skipping a non-drivable prerequisite could run a dependent item with an unmet dependency, and it diverges from the core loop's all-or-nothing startup posture.
  - Let the driver branch, then halt mid-run on an unsupported item — rejected in favor of a startup refusal that leaves the repository untouched.
- **Linked technical notes:** —
- **Driven by findings:** F1 (whole-run refusal, not partial), F5 (readiness judged by combination), F10 (drivability legibility), F25 (autonomy computed from signals, not a `Type` field)
- **Dependent decisions:** D6
- **Referenced in spec:** Outcome; Primary Flow; Edge Cases and Failure Modes; Coordinations; Deferred (YAGNI)

### D6: Per-item fields, implementation skill, review, and autonomy signals

- **Question:** What is recorded on each item, who reads it, and how do bare items and older files interact with validation?
- **Decision:** The work-item producer, its template, and its file-format reference gain, per item: an **implementation skill** (which skill builds it; a skill name, or `none` for a bare item), a **review** (a review skill, a review agent, `human read`, or `none`), and the three autonomy signals from [D4](#d4-recorded-autonomy-signals-replace-the-afkhitl-type) (build unattended, review unattended, pre-work decision). These *replace* the core loop's `Type` field (`expected-paths` stays). "Implementation skill" is the single field name (not "build skill"). The producer records all of it on every item; a bare item carries the explicit implementation skill `none`, distinct from a field the producer never wrote. The driver validates the fields' presence at startup (an item that omits them marks a pre-feature file and is refused with a re-run remedy), computes autonomy from the signals rather than reading `Type`, names the skill and review in its plan preview, and dispatches the recorded implementation skill and review per item — in both the initial build and each fix round — preserving each dispatched skill's contract, so a `tdd` item still requires observed test-failure-then-pass evidence. Because the driver no longer reads `Type`, the producer change and the driver companion change ship together.
- **Rationale:** A data field cannot be imposed by a dispatch instruction the way a return contract can; it must be recorded by the producer that has the context. The review is a separate field because the operator asked it to vary per item; the three signals are separate fields because they are not inferable for user-defined skills and a future human-in-the-loop driver reads them per phase ([D4](#d4-recorded-autonomy-signals-replace-the-afkhitl-type)). The explicit `none` value keeps the "field present on every item" invariant true for bare items while letting the driver distinguish them from an old-format file.
- **Evidence:** The core loop added `Type` and `expected-paths` as required per-item fields and deferred `implementation-skill` only because `tdd` was then the sole value (core loop D19, D16); the driver reads `Type`/`expected-paths` and hardcodes `tdd`/`code-review` in both the build and fix-round dispatch (`han-coding/skills/implement-work-items/SKILL.md`, Steps 1.7, 3.1, 3.4); the work-item template has no such field (`han-planning/skills/plan-work-items/references/work-item-template.md`). User input chose "add field + driver consumes it" and, later, to replace `Type` with the three signals.
- **Rejected alternatives:**
  - Keep the `Type` field alongside the new fields — rejected (finding F25): a stored derived value can drift; the driver computes autonomy from the signals.
  - Two names for the implementation field ("implementation skill" and "build skill") — rejected (finding F13); one field needs one name.
  - Omit the fields on bare items — rejected (finding F2); an omitted field is indistinguishable from a pre-feature file and would trip the driver's missing-field refusal on a legitimately bare item.
  - Have the driver infer the skill or autonomy at run time — rejected because a fresh run-time guess is unreliable (and impossible for a non-han skill's autonomy); the producer already has the classification.
- **Linked technical notes:** —
- **Driven by findings:** F2 (bare-item explicit `none`), F9 (fix-round dispatch + `tdd` contract preserved), F13 (single field name), F23 (`none` also covers a step with no applicable review), F25 (three signals replace `Type`)
- **Dependent decisions:** —
- **Referenced in spec:** Outcome; Primary Flow; Actors and Triggers; Edge Cases and Failure Modes; Coordinations

### D7: Overrides by invocation instruction and pre-written marker

- **Question:** How does the operator override the auto-chosen skill or review for a specific item, and how is each override typed and reported?
- **Decision:** The operator can override the implementation skill, the review, and/or a non-han skill's declared autonomy for a named item two ways: an instruction in the invocation, or a per-item marker left in the source plan or context (read without modifying it). Because item identifiers are assigned during drafting, an override names its target by description; the producer binds it to a drafted item and reports how each override resolved — applied to which item, unmatched, or ambiguous — never silently dropping one. An override replaces the selected value(s) and the item's autonomy signals are recomputed: re-derived from a han skill, or taken from the operator's declaration for a non-han skill (default not-unattended); the pre-work-decision signal is unaffected by a skill override, so an item that independently needs a human still needs one. An override whose skill does not match the item's nature is honored (operator authority) but flagged as a mismatch; an override naming an uninstalled skill is recorded as a recommendation but the item becomes bare (a distinct outcome from an honored mismatch, and named as such).
- **Rationale:** `plan-work-items` runs autonomously with no mid-run prompts, so an override must arrive at invocation or already be present in the input; supporting both a live instruction and a pre-written marker covers ad-hoc and repeatable use without adding a prompt. Honoring-but-flagging preserves operator authority while surfacing a likely mistake; reporting the binding prevents a silent override miss; re-derivation that keeps independent-human and non-han items `HITL` prevents an override from silently making an item look driver-ready when it is not.
- **Evidence:** `plan-work-items` "runs autonomously end to end" and "never gate[s] on approval to continue" (`han-planning/skills/plan-work-items/SKILL.md`, Operating Principles); the skill must not modify the source plan ("It is read-only input", Rules); stable IDs `W-N` are assigned in Step 6, after classification, so overrides cannot reference them at invocation time. User input chose "both."
- **Rejected alternatives:**
  - Invocation-time instruction only — rejected by the user; a pre-written marker makes repeated runs reproducible.
  - Pre-written marker only — rejected by the user; an ad-hoc override should not require editing the source.
  - Recompute autonomy from the overridden skill alone, dropping the pre-work-decision signal — rejected (finding F3): it drops an item's independent human need.
  - Only flag `tdd`-on-non-testable mismatches — rejected (finding F5): any skill-vs-nature mismatch should be flagged, and an uninstalled override is a distinct outcome (finding F11).
  - Silently ignore an override that cannot be bound to an item — rejected (finding F12); the producer reports the resolution.
- **Linked technical notes:** —
- **Driven by findings:** F3, F4 (non-han items not auto-`AFK`), F5, F11 (distinct vocabulary for mismatch vs not-applied), F12 (override-resolution reporting), F25 (override can declare a non-han skill's autonomy)
- **Dependent decisions:** —
- **Referenced in spec:** Outcome; Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes; User Interactions; Coordinations

### D8: Non-han skills suggested only when no han skill fits

- **Question:** How aggressively does the producer scan installed non-han skills, and does it ever assign one or derive `AFK` from one?
- **Decision:** The han catalog is the prioritized, trusted source. Only when no han skill matches an item's nature does the producer scan the installed skills and, if a non-han skill plausibly fits, surface it as a low-confidence suggestion in the breakdown — never auto-assigned. The producer cannot infer a non-han skill's autonomy, so it records the build/review phase as not-unattended *unless the operator declares it autonomous*; a declared-autonomous user skill can be fully autonomous (superseding the earlier blanket "non-han → HITL"), though the current driver still refuses it as an unsupported combination and a future driver consumes the signal.
- **Rationale:** Han's own skills have known interactivity and purpose the producer can classify with confidence; an arbitrary installed skill does not — its autonomy is not inferable, so to support a user-defined AFK skill the operator must be able to declare it. Defaulting an undeclared non-han phase to not-unattended keeps the driver from attempting work whose autonomy is unknown, while the declaration lets the operator's "use my skill X" affordance actually be drivable by a future driver.
- **Evidence:** User input ("suggest only when no han skill fits," "han's native skills prioritized," and the producer "can't reliably tell whether an arbitrary skill is code-producing and non-interactive").
- **Rejected alternatives:**
  - Always list non-han alternatives per item — rejected as noise that competes with the trusted han choice.
  - Never scan; han catalog only — rejected by the user, who wanted a "suggest something else" path.
  - Auto-assign a matching non-han skill — rejected because the producer cannot confirm its interactivity or code-production.
  - Force every non-han skill to needs-a-human with no way to declare autonomy — rejected (finding F25): it makes the operator's "use my skill X" affordance undrivable even when the operator knows the skill runs unattended.
- **Linked technical notes:** —
- **Driven by findings:** F4 (undeclared non-han phase is not-unattended), F25 (operator can declare non-han autonomy)
- **Dependent decisions:** —
- **Referenced in spec:** Outcome; Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes

### D9: Uninstalled best-fit falls back to bare HITL

- **Question:** What happens when the best-fit skill is not installed (for example `skill-builder`/`agent-builder`/`guidance` when `han-plugin-builder` is absent)?
- **Decision:** The item falls back to a bare `HITL` item with implementation skill `none` — never a `tdd` substitute — keeping the recommended skill as a note on the item. The producer runs to completion autonomously and prints an install recommendation for each such item at the end of the run (install the named plugin, then re-run `plan-work-items`, or ask for those items to be re-derived); it does not prompt mid-run, and there is no in-session re-derive gate.
- **Rationale:** Substituting `tdd` for an absent builder would let the driver attempt to build and verify a deliverable (a skill, an agent) that `tdd` cannot produce and tests cannot check; a bare `HITL` item honestly says "a human must do this" while preserving the recommendation for when the plugin is installed. Printing the recommendation at the end (rather than an in-session prompt) keeps the producer's autonomous, never-gate identity, has no undefined no-answer path that could hang an unattended run, and needs no in-session file-rewrite process — re-running the (idempotent) skill after installing re-derives the affected items.
- **Evidence:** `skill-builder`, `agent-builder`, and `guidance` ship in `han-plugin-builder`, which the meta-plugin does not bundle, so they may be absent (`CLAUDE.md`; `han-plugin-builder/`). `plan-work-items` "runs autonomously end to end," "never gate[s] on approval," and writes incrementally so it "never lose[s] work" (`han-planning/skills/plan-work-items/SKILL.md`). User input: fall back to bare HITL (not `tdd`); "print suggestion at the end. User can install and ask agent to adjust derived skills."
- **Rejected alternatives:**
  - Fall back to `tdd` — rejected by the user; an uninstalled builder's output cannot be test-verified.
  - Halt and require installation before continuing — rejected because it breaks the autonomous end-to-end flow and loses the rest of the breakdown.
  - Prompt after writing whether to install-and-re-derive — rejected (findings F6; `junior-developer`, `user-experience-designer`, `edge-case-explorer`): it adds the skill's only gate, has an undefined no-answer path, and needs an unspecified in-session re-derive/file-rewrite process; the printed recommendation plus re-run satisfies the same need.
- **Linked technical notes:** —
- **Driven by findings:** F2 (bare-item explicit `none`), F6 (in-session prompt dropped for a printed recommendation), F11 (not-applied-vs-mismatch vocabulary)
- **Dependent decisions:** —
- **Referenced in spec:** Outcome; Actors and Triggers; Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes; User Interactions; Coordinations
