# Team Findings: Non-code, meta, and non-deliverable work items

This file records every finding raised by the review team for this feature, and how each was resolved. Behavioral outcomes live in [../feature-specification.md](../feature-specification.md); decisions the findings affected live in [decision-log.md](decision-log.md); load-bearing mechanics live in [feature-technical-notes.md](feature-technical-notes.md).

Review team: `han-core:junior-developer`, `han-core:test-engineer`, `han-core:edge-case-explorer`, `han-core:on-call-engineer`. The four converged on one root design flaw (the no-output waiver was decoupled from `Type`, opening a silent-no-op path while the spec claimed the driver "routes on `Type`") and its propagation gaps into the driver's build, review, commit, and validation contracts. Findings below are consolidated across agents by the design change each drives.

## Major findings

### F1: The no-output waiver was decoupled from `Type`, opening a silent-no-op path

- **Agent:** on-call-engineer (F1), junior-developer (F1, F2), edge-case-explorer (EC-2, EC-9), test-engineer (U2)
- **Finding:** The draft D9 keyed the no-output waiver on `Expected paths: None` alone and explicitly "not off the `Type` marker," so `Type: deliverable` + `Expected paths: None` was spec-legal and would route a genuinely failed or no-op build through the relaxed accept-no-files / skip-scope / no-commit path — exactly the case the build-report halt guard exists to catch. Meanwhile the spec's Coordinations claimed the driver "routes on `Type`," which no mechanism actually did (the driver has no `Type` concept today). A `spike` with `Expected paths: None` (EC-2) would likewise discard its finding; an unrecognized `Type` value (EC-9) had no defined behavior.
- **Resolution:** Make `Type` a driver-validated marker (D11). `Expected paths: None` is legal only for `Type: verification`; a `deliverable` or `spike` declaring `None`, a `none, AFK` build marker, and an unrecognized `Type` are all startup refusals. Revised D9 couples the no-output handling to `verification`; revised D10 states the driver validates `Type` but defaults a missing one to `deliverable`.
- **Resolved by:** evidence
- **Affected decisions:** D6, D9, D10, D11
- **Affected tech-notes:** —
- **Changed in spec:** Outcome, Primary Flow, Startup Validation and Refusals, Edge Cases and Failure Modes, Coordinations

### F2: An unattended review over a no-output item rubber-stamps an empty diff

- **Agent:** on-call-engineer (F2), junior-developer (F7), edge-case-explorer (EC-11)
- **Finding:** D8 described a verification review as a human confirmation, but nothing enforced it; a verification item produced (or hand-edited) with an `AFK` review would have its review sub-agent compute a diff against `Expected paths: None`, find nothing, and return a clean pass over nothing — a gate that inspected nothing. The human-review-capture protocol also points the reviewer at "the item's change," which is empty for a no-output item.
- **Resolution:** A `verification` (or any `Expected paths: None`) item must record a human review, never an `AFK` sub-agent review (D12). The human-review-capture gains a no-output branch: the operator confirms the checks ran and the result is sound rather than reviewing an absent change, and the coverage attestation is "operator confirmed result."
- **Resolved by:** evidence
- **Affected decisions:** D8, D11, D12
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows and States (Verification pass), Startup Validation and Refusals, Edge Cases and Failure Modes

### F3: The build-report contract forbids a clean no-output build and assumes a skill with a gate

- **Agent:** edge-case-explorer (EC-1, EC-13), junior-developer (F4, F5, F9), test-engineer (P1, P4)
- **Finding:** The build-report contract halts on `STATUS: built` with an empty FILES list, and its dispatch prompt (copied verbatim) tells the sub-agent to run "the item's recorded implementation skill" and reports `built` as "the implementation skill's gate is green." A general-purpose agent runs no skill and has no gate, and a legitimate no-output build must report zero files — the exact halt condition. So both the skill-less build (A) and the no-output build had no valid way to report success; the "almost no new machinery" claim in D3 held only for the dispatch shape, not the report shape.
- **Resolution:** The build-report contract gains a skill-less-build shape and a no-output carve-out (D13): a general-purpose build reports without a skill-gate claim (verification is driver-side only), a declared-no-output build is dispatched knowing zero files is the expected result, and `STATUS: built` with empty FILES is a clean completion only for an item that declared `Expected paths: None`. The agent-as-build dispatch path exists but is newly exercised for builds and is treated as such.
- **Resolved by:** evidence
- **Affected decisions:** D3, D9, D13
- **Affected tech-notes:** T1
- **Changed in spec:** Alternate Flows and States (Agent-drafted non-code build, Verification pass), Coordinations, Edge Cases and Failure Modes

### F4: A no-commit completion has no labeled outcome, no durable trace, and no idempotency guarantee

- **Agent:** on-call-engineer (F3, F4), edge-case-explorer (EC-8)
- **Finding:** The driver's completion summary reports each item as "committed with its reference/range" or "halted" — a no-commit completion fits neither, so a legitimate empty verification is indistinguishable from a silent no-op that slipped the relaxed guard. state.json's `commit-range` stays null with no way to tell "done, no commit" from "not yet done," and because a no-commit item leaves no commit, the halt procedure's commit-range-based cherry-pick recovery can silently drop it; the spec never commits that a no-output item's execution is safe to repeat.
- **Resolution:** The driver labels a no-commit completion as its own outcome in the completion and halt summaries (naming the item, its `Type`, and its declared `Expected paths: None`) plus a count, records it distinctly in state.json, and the spec commits that a no-output item's execution must be idempotent since the no-commit design removes commit-based deduplication (D14).
- **Resolved by:** evidence
- **Affected decisions:** D9, D14
- **Affected tech-notes:** —
- **Changed in spec:** Primary Flow, Edge Cases and Failure Modes

### F5: A no-output item that unexpectedly leaves files contaminates the next item's scope baseline

- **Agent:** edge-case-explorer (EC-3, EC-7), junior-developer (F6)
- **Finding:** If a no-output build leaves files in the working tree, the driver's per-item `scope-baseline` (the unchanged HEAD) means the next item's review sweep picks up the prior item's uncommitted files as its own scope, raising false scope findings; the "declared `None` but produced files" quadrant was undefined, and D9 self-contradicted (skip commit vs. the commit step staging the diff).
- **Resolution:** Before recording each item's scope-baseline the driver asserts a clean tree (only driver artifacts allowed); a `None` item that produces files is surfaced as a scope finding for the operator to resolve, never silently carried or silently no-committed (D14, D9).
- **Resolved by:** evidence
- **Affected decisions:** D9, D14
- **Affected tech-notes:** —
- **Changed in spec:** Edge Cases and Failure Modes

### F6: The catalog has no classification home for verification/spike, and guidance is not guaranteed to reach the build agent

- **Agent:** junior-developer (F8, F10, F11), edge-case-explorer (EC-4, EC-5), test-engineer (P5, P6, P10, P11, U4)
- **Finding:** The `Type` marker (D6) and the spike build choice (D8) gave the producer no catalog row to select — a codebase spike meant to run `han-coding:investigate` would fall to the "no han skill fits" catch-all and be classified human-throughout, contradicting D8. "Informed by the plugin-authoring guidance" (D4/D5) assumed guidance reaches the general-purpose build agent, but the driver passes only the item's References and the plan, and guidance is a vendored plugin skill, not necessarily a repo doc in a target repo. `general-purpose agent, AFK` also read as conflicting with the catalog's "never auto-`AFK` an unconfirmed non-han skill" guardrail.
- **Resolution:** The feature adds catalog homes (rows or `Type`-conditional guidance) for verification and spike, naming `han-coding:investigate` for a codebase spike and defining "codebase question" (the probe requires reading and reasoning about source code, not just documents); the edit-existing and catch-all classifications record the applicable guidance as a linked Reference so the build agent receives it, and the feature surfaces the assumption that guidance is reachable/vendored in the target repo; the catalog states `general-purpose` is exempt from the never-auto-`AFK` guardrail because it is a built-in agent, not an installed non-han skill (D15).
- **Resolved by:** evidence
- **Affected decisions:** D4, D5, D8, D15
- **Affected tech-notes:** T1
- **Changed in spec:** Alternate Flows and States (Editing an existing skill…, Verification pass, Spike), Coordinations

### F7: An agent-drafted edit to an executable plugin artifact can ship broken with only "typically" a human read

- **Agent:** on-call-engineer (F5, F6)
- **Finding:** For an agent-drafted plugin edit, the build's red-to-green evidence is waived as untestable, the driver's verify step runs project-level checks (not the item's own conformance checks, which D10 leaves inert), and the review was only "typically a human read" — the word admits an `AFK` prose review (content-auditor / information-architect) that judges comprehension, not whether the artifact still loads. A structurally-broken but prose-plausible edit (corrupt frontmatter, dropped `allowed-tools`) would commit green.
- **Resolution:** An agent-drafted edit to an executable plugin artifact (a skill, agent, plugin manifest, or config the tooling loads) requires a human read; `AFK` prose review is reserved for genuinely non-executable prose where structural breakage carries no runtime blast radius (D16). The "typically" qualifier is removed from the spec.
- **Resolved by:** evidence
- **Affected decisions:** D3, D4, D16
- **Affected tech-notes:** —
- **Changed in spec:** Alternate Flows and States (Agent-drafted non-code build, Editing an existing skill…), Edge Cases and Failure Modes

## Minor edits

- F8: "human read, plus `AFK` or `HITL`" is a phantom, self-contradictory marker (a human read is inherently `HITL`; the literal marker is `none, HITL`) — align spec vocabulary to the literal markers — junior-developer (F7) — Primary Flow, Alternate Flows.
- F9: the `Tests`→`Verification` field rename (operator-visible vocabulary) was relegated to implementation while `Type` was named as vocabulary — treat both consistently and name the `Verification` field in the spec — junior-developer (F12) — Primary Flow.
- F10: a spike whose finding file is empty passes all gates — the spike's soundness review must confirm the finding is recorded and non-empty — edge-case-explorer (EC-10) — Alternate Flows (Spike).
- F11: a verification item may legitimately produce a report file (`Type: verification` with a non-empty `Expected paths`) — name this valid combination so producers do not treat verification as always no-output — edge-case-explorer (EC-12) — Alternate Flows (Verification pass).
- F12: the spec Summary carried unfilled `N`/`—` placeholders while claiming completeness — fill the counts — junior-developer (F13) — Summary.
- F13: `Type` field position in the template is unspecified — a template-ordering detail left to plan-implementation, noted here so it is not lost — test-engineer (U1) — —.
