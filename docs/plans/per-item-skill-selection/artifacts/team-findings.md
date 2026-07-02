# Team Findings: Per-Item Skill Selection for Work Items

<!--
Records every finding raised by the review team for this feature, and how each was
resolved. Behavioral outcomes live in ../feature-specification.md; decisions the
findings affected live in decision-log.md. Major findings get full fields; minor
findings are one-line bullets. F# is a single shared counter.

Review team (Step 6): han-core:junior-developer, han-core:edge-case-explorer,
han-core:user-experience-designer, han-core:gap-analyzer. The gap-analyzer's full
report is at gap-analysis-vs-core-loop.md.
-->

## Major findings

### F1: Driver behavior on a mixed file was specified two contradictory ways

- **Agent:** junior-developer (JD-001); corroborated by edge-case-explorer (EC6/EC7) and gap-analyzer (GAP-005).
- **Finding:** The spec said both "drives the items whose combination it supports and refuses the rest" (a partial run) and "refuses at startup rather than driving a partial set" (a whole-run refusal). D5 had decided *when* to refuse (startup) but not *whether* a mixed file drives a subset or refuses entirely. A partial run is also unsafe: items run in dependency order, so skipping a non-drivable prerequisite could run a dependent item with an unmet dependency.
- **Resolution:** The driver refuses the whole run at startup, before any branch, if any item is not driver-drivable, naming the offending items — consistent with the core loop's "any HITL item is a startup refusal, not a partial run." Outcome, Primary Flow step 8, the mixed-file and all-AFK-non-drivable edge rows, and Coordinations were rewritten to say this one way.
- **Resolved by:** user input (chose whole-run startup refusal)
- **Affected decisions:** D5, D10
- **Changed in spec:** Outcome; Primary Flow; Edge Cases and Failure Modes; Coordinations

### F2: Bare items with "no build skill" collided with the driver's missing-field refusal

- **Agent:** junior-developer (JD-002); corroborated by gap-analyzer (GAP-002).
- **Finding:** The producer "records the field on every item" and the driver "refuses a file whose items lack it," yet a bare item has "no build skill." If a bare item omits the field, it is indistinguishable from a pre-feature file, so the driver's "field missing → re-run the producer" refusal would fire on a legitimately bare new item with a misleading remedy.
- **Resolution:** A bare item carries the explicit value `none`; a field the producer never wrote (a pre-feature file) is the only "missing" case. The driver distinguishes explicit `none` (a bare `HITL` item, caught by the whole-run drivability refusal) from an omitted field (a pre-feature file, refused with a re-run remedy). Actors/Preconditions, Primary Flow steps 3/6, and the two relevant edge rows were updated.
- **Resolved by:** evidence
- **Affected decisions:** D6, D9
- **Changed in spec:** Actors and Triggers; Primary Flow; Edge Cases and Failure Modes

### F3: Override re-derivation could silently strip an item's independent HITL need

- **Agent:** edge-case-explorer (EC2).
- **Finding:** D4 gives two independent paths to `HITL`: an interactive skill, or the item independently needing a human. D7 re-derived `Type` "from the overridden build skill." An override to a non-interactive skill (e.g. `tdd`) on an architectural-decision item would flip it to `AFK`, dropping the required human review with no warning, and the driver would then run it unattended.
- **Resolution:** Re-derivation preserves the independent-human need: an item that independently needs a human stays `HITL` regardless of the overridden skill. D4 and D7 state this, with a dedicated edge row.
- **Resolved by:** evidence
- **Affected decisions:** D4, D7
- **Changed in spec:** Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes

### F4: Type derivation for a suggested or overridden non-han skill was undefined

- **Agent:** edge-case-explorer (EC3).
- **Finding:** For auto-suggestion the spec said "never derive `AFK`; default to `HITL`," but for an explicit override to a non-han skill D7's "re-derive from the overridden skill" applied, and D8's "can't tell if it's interactive" was not restated — leaving the implementer to invent a rule.
- **Resolution:** A non-han skill (suggested or overridden) never yields `AFK`; the item is `HITL`, because the producer cannot confirm the skill's interactivity. Stated in D7, D8, Primary Flow step 5, and an edge row.
- **Resolved by:** evidence
- **Affected decisions:** D7, D8
- **Changed in spec:** Primary Flow; Edge Cases and Failure Modes

### F5: An installed-but-wrong override was unflagged, and driver-readiness risked a false positive

- **Agent:** edge-case-explorer (EC4).
- **Finding:** The only defined mismatch flag was `tdd`-on-non-testable. An override such as `project-documentation` on a code item produced an `AFK` item; if the closing recommendation judged driver-readiness by "is it `AFK`?" it would call that item driver-ready, and the driver would then refuse it — misleading guidance.
- **Resolution:** The mismatch flag is generalized to any skill-vs-nature mismatch, and driver-readiness is judged by matching the item's recorded combination against the driver's supported combination (`tdd` + `code-review`), not by `AFK` alone. Stated in D5, D7, Primary Flow, and an edge row.
- **Resolved by:** evidence
- **Affected decisions:** D5, D7
- **Changed in spec:** Primary Flow; Edge Cases and Failure Modes

### F6: The uninstalled-fallback prompt broke the producer's autonomous, never-gate identity

- **Agent:** junior-developer (JD-006), user-experience-designer (UX-005, UX-006), edge-case-explorer (EC5).
- **Finding:** The post-write "install-and-re-derive or keep bare" prompt was the skill's only gate, had an undefined no-answer path (could hang an unattended run), and required an unspecified in-session re-classification and file-rewrite process. A simpler version satisfies the same need.
- **Resolution:** The prompt is removed. The producer records the bare item, prints an install recommendation at the end, and exits; the operator installs and re-runs (or asks for re-derivation) afterward. D9 rewritten; Primary Flow step 6, the not-installed alternate flow, User Interactions error states, and a Deferred entry updated.
- **Resolved by:** user input (chose print-and-re-run over an in-session prompt)
- **Affected decisions:** D9
- **Changed in spec:** Primary Flow; Alternate Flows and States; User Interactions; Deferred (YAGNI)

### F7: The reopen-trigger claim overclaimed a condition that is not met

- **Agent:** gap-analyzer (GAP-001).
- **Finding:** The core loop's reopen trigger requires "a second non-interactive code-producing skill exists" AND "a decision tree plus a non-han affordance." Only the second is met; `refactor` is interactive, so `tdd` remains the only autonomous code skill. The spec asserted "This reopens..." without disclosing the unmet conjunct.
- **Resolution:** The spec intro and D1 now state the trigger is only partly met and that the reopening rests on the broader per-item value and operator direction, not a second drivable code skill.
- **Resolved by:** evidence
- **Affected decisions:** D1
- **Changed in spec:** Outcome (intro)

### F8: A dual-nature item would silently drop one deliverable

- **Agent:** edge-case-explorer (EC1).
- **Finding:** The one-to-one nature→skill mapping presupposes a single deliverable. An item that is definitively both code and documentation (e.g. "implement X and write its runbook") would get one skill and silently miss the other deliverable; the low-confidence flag only covered *uncertain-which*, not *certain-both*.
- **Resolution:** A dual-nature item is split into separate vertical-slice items (per the producer's existing vertical-slice discipline); when it cannot be cleanly split, the producer records the dominant skill and flags the uncovered nature. Added as trivial decision D11, Primary Flow step 2, and an edge row.
- **Resolved by:** evidence
- **Affected decisions:** D2, D11
- **Changed in spec:** Primary Flow; Edge Cases and Failure Modes

### F9: Per-item dispatch left the tdd build-report contract and the fix-loop dispatch unaddressed

- **Agent:** gap-analyzer (GAP-003, GAP-004).
- **Finding:** The spec said the driver "dispatches the recorded build skill" for the initial build but did not confirm (a) that a `tdd` item still requires the observed test-failure-then-pass evidence, nor (b) that the fix-round dispatch (also hardcoded to `tdd` today) reads the recorded skill too.
- **Resolution:** The driver dispatches the recorded implementation skill in both the initial build and each fix round, preserving each skill's dispatch contract (for `tdd`, the test-failure-then-pass requirement is unchanged). Stated in D6, Primary Flow step 8, and Coordinations.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Primary Flow; Coordinations

### F10: The AFK-vs-drivable distinction was illegible per item, and an edge example mis-classified documentation

- **Agent:** junior-developer (JD-004, JD-005), user-experience-designer (UX-001), edge-case-explorer (EC6, EC7).
- **Finding:** "Driver-drivable" was defined only in the decision log and referred to by four phrases; the per-item breakdown showed only two-state `Type`, so an operator could not tell a driver-ready item from an AFK-but-needs-a-hand one without cross-referencing. The "every item HITL" edge row used an all-documentation plan as its example, but `project-documentation` is `AFK` per D4 (it is AFK-but-non-drivable, not HITL), and the all-AFK-non-drivable case had no row.
- **Resolution:** The breakdown marks each item driver-ready or needs-a-hand; the closing recommendation sorts items into three groups (driver-ready, run-the-skill-yourself, needs-a-human-decision). The mis-classified example is fixed (all-HITL uses an all-new-skill plan) and a separate all-AFK-non-drivable edge row added. D5 and D10 updated.
- **Resolved by:** evidence
- **Affected decisions:** D5, D10
- **Changed in spec:** Primary Flow; Edge Cases and Failure Modes; User Interactions

### F11: "Mismatch" named two very different outcomes

- **Agent:** user-experience-designer (UX-009).
- **Finding:** A `tdd`-on-non-testable override is *honored and recorded* ("flagged as a mismatch"), while an uninstalled-skill override is *not applied* (the item becomes bare `HITL`, the choice kept only as a recommendation). Both wore the word "mismatch," so an operator who overrode toward an uninstalled skill could believe their choice still stood.
- **Resolution:** The two are named distinctly: "honored but flagged as a mismatch" (recorded, questionable) versus "not applied — skill not installed; item is bare `HITL`, choice kept as a recommendation." D7, D9, Primary Flow, Alternate Flows, Edge Cases, and User Interactions use the split vocabulary.
- **Resolved by:** evidence
- **Affected decisions:** D7, D9
- **Changed in spec:** Primary Flow; Alternate Flows and States; Edge Cases and Failure Modes; User Interactions

### F12: Overrides reference items that do not exist yet, and could fail silently

- **Agent:** user-experience-designer (UX-002, UX-003).
- **Finding:** Stable `W-N` IDs are assigned during drafting, so at invocation/marker time the operator can only name an item by description. The spec never said how the producer resolves a description to an item, nor what happens on a zero- or multi-match, and an unparseable marker could be silently ignored — leaving the breakdown showing the auto-chosen skill as if the override applied.
- **Resolution:** An override names its target by description; the producer binds it to a drafted item and reports how each override resolved (applied to which item, unmatched, or ambiguous), never silently dropping one. The exact marker grammar is left to `plan-implementation`. Stated in D7, Primary Flow step 5, Alternate Flows, User Interactions, and Out of Scope.
- **Resolved by:** evidence
- **Affected decisions:** D7
- **Changed in spec:** Primary Flow; Alternate Flows and States; User Interactions; Out of Scope

### F13: The field was named two ways — "implementation skill" and "build skill"

- **Agent:** junior-developer (JD-003).
- **Finding:** The Outcome and D6's title used "implementation skill"; the rest of the spec used "build skill." The field the producer writes and the driver reads must have exactly one name.
- **Resolution:** Standardized on "implementation skill" throughout (matching the reopened deferral's vocabulary), in the spec, D6, and cross-references.
- **Resolved by:** evidence
- **Affected decisions:** D6
- **Changed in spec:** Outcome; Primary Flow; Actors and Triggers; Edge Cases and Failure Modes; Coordinations

### F14: The interleaving of skill-selection and Type-derivation with the existing producer step was unstated

- **Agent:** junior-developer (JD-007).
- **Finding:** The producer already assigns `Type` in its `project-manager` drafting step; the spec did not say whether that step still runs, where skill selection sits relative to it, or in what order `Type` is computed now that it has two inputs (skill interactivity plus the item's own human need).
- **Resolution:** The spec states that classification, skill/review selection, and `Type` derivation happen while the items are drafted, and that `Type` follows the skill's interactivity with the independent-human need preserved. The precise placement within the producer's existing steps is an implementation-plan concern handed to `plan-implementation`.
- **Resolved by:** project-manager synthesis
- **Affected decisions:** —
- **Changed in spec:** Primary Flow

## Minor edits

- F15: "No changes to the han skills" in Out of Scope was imprecise — the producer and driver are han skills this feature changes; reworded to "no changes to the build and review skills; the producer and driver are in scope." — junior-developer (JD-010) — Out of Scope.
- F16: "Open Items: None" / "0 remaining" were asserted before the review team ran; now accurate after this review pass and synthesis. — junior-developer (JD-011) — Summary; Open Items.
- F17: The review field's value domain omitted "human read" and "none"; now stated as skill, agent, `human read`, or `none`. — junior-developer (JD-009) — Primary Flow; (D6).
- F18: Breakdown flags now name their remedy (how to override) so they are actionable; the invocation argument-hint should advertise overrides (left to plan-implementation). — user-experience-designer (UX-008, UX-004) — User Interactions.
- F19: The installed-skill detection mechanism is pure implementation; the spec states only the behavior (skills are detected, not assumed) and hands the mechanism to plan-implementation. — edge-case-explorer (EC8) — Out of Scope.
- F20: D6's "ready for a wider supported set later" was a YAGNI tell; the rationale is re-anchored on the present use (guidance for humans and the refuse-or-drive decision). — junior-developer (JD-012) — (D6 rationale).
