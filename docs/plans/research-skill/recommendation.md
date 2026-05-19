# Should `/research` be a separate skill or an expansion of `/investigate`?

**Status:** Recommendation, ready for your review
**Date:** 2026-05-19
**Question:** You want a `/research` capability — research of ideas, possible
solutions, and information that sits outside bug/issue investigation. Should it
be a new skill, or should `/investigate` be expanded to cover it?

**Recommendation in one line:** Build `/research` as a **separate skill**, scoped
narrowly to open-ended, output-agnostic research, with reciprocal routing to its
neighbors.

---

## Plain-language summary

`/investigate` is not a general research tool that happens to focus on bugs. It
is a bug-shaped pipeline from end to end. It starts from a *symptom*, classifies
a *bug type* to pick specialists, traces backward through code, names a *root
cause*, designs a *fix*, and then sends an adversarial validator to attack that
fix. Its output template has sections called "Problem Statement," "Root Cause
Analysis," and "Final Summary → Fix." Every step feeds the next, and the whole
chain terminates at "a validated fix plan."

Research of ideas and options has a different shape. It starts from a *question*,
not a symptom. It produces a *landscape of options with trade-offs and a
recommendation*, not a causal chain ending in a fix. There is nothing to
"classify as a bug," no "root cause," and no "fix" for the validator to attack.

Han's own authoring guidance is explicit that a skill should do one thing, and
that closely-related capabilities get split into separate skills that point at
each other ("Does not X — use Y"). Every one of Han's 18 existing skills follows
that pattern; `gh-pr-review` and `code-review` are split even though one calls
the other internally, because the *trigger* differs. There is currently no skill
that owns open-ended research: `plan-a-feature`, `coding-standard`,
`gap-analysis`, and `architectural-analysis` each do research, but only as a
bounded step toward a fixed output (a spec, a standard, a gap report, an
architecture assessment). The slot for "I just want to research my options
before committing to anything" is genuinely unoccupied.

An adversarial validator was sent in specifically to break this conclusion. It
did not break it, but it did expose that the first-pass evidence oversold the
case. Several individual evidence items were wrong or backwards, the cost of a
new skill is higher than first claimed (closer to ~14 files than ~6 once
reciprocal routing is counted), and a third option — reframing `/investigate`
into a two-mode "deep-dive" skill — was never evaluated. That third option was
then evaluated and rejected: a two-mode skill is two concerns under one name,
which is exactly what Han's single-responsibility rule prohibits, and its
description would need *more* disambiguation than two clean skills, not less.

The core conclusion survives, for narrower and more defensible reasons than the
raw investigation stated: **separate skill, scoped tightly, with explicit
routing to its neighbors.**

---

## Evidence table: for and against each option

Evidence IDs reference the artifact files in
[`artifacts/`](./artifacts/). Validation IDs (V#) reference
[`artifacts/04-adversarial-validation.md`](./artifacts/04-adversarial-validation.md).
Strikethrough marks evidence the adversarial pass invalidated or corrected.

### Option A — Separate `/research` skill (RECOMMENDED)

| # | For (supports separate skill) | Against (cost / risk) | Source |
|---|-------------------------------|-----------------------|--------|
| 1 | `/investigate` is structurally a symptom → root cause → fix → validate pipeline; research has a different terminus (options + recommendation). The two don't share load-bearing logic, only a generic scaffold. | — | [01](./artifacts/01-investigate-skill-analysis.md) E2–E5, E10; V5 |
| 2 | Han's single-responsibility rule: "one skill, one concern." Research and bug-investigation are independent concerns — each is useful without the other. | — | [02](./artifacts/02-skill-taxonomy-guidance.md) E1, E3 |
| 3 | The "Does not X — use Y" boundary pattern in all 18 skills structurally requires a *separate* skill to point at. There is nowhere to point if research lives inside `/investigate`. | — | [02](./artifacts/02-skill-taxonomy-guidance.md) E11 |
| 4 | No current skill owns open-ended research. `plan-a-feature` / `coding-standard` / `gap-analysis` / `architectural-analysis` all do *bounded* research toward a fixed output. | The empty slot is *narrower* than "all research" — it is specifically output-agnostic research. The new skill must be scoped to exactly that, or it collides with those four. | [03](./artifacts/03-precedent-and-cost.md) E6–E10; V6 |
| 5 | Precedent: Han splits on *trigger* even when implementation overlaps heavily. | The cited precedent (`gh-pr-review` calling `/code-review`) relies on a sub-skill-call pattern that current guidance now discourages — so it is not a clean precedent to copy. | [03](./artifacts/03-precedent-and-cost.md) E3; ~~V3~~ |
| 6 | A separate skill keeps each description tight and its triggering accurate. | A `/research` skill itself risks trigger collisions with `plan-a-feature`, `coding-standard`, `gap-analysis`, `architectural-analysis`. Its description must carry reciprocal "Does not" routing to all four — this must be drafted and tested, not assumed. | [02](./artifacts/02-skill-taxonomy-guidance.md) E6; V7 |
| 7 | Adding a skill is a normalized, documented operation in Han (CONTRIBUTING.md checklist). | True cost is **~14+ file changes**, not 6: the new skill's 6 files plus reciprocal routing in the SKILL.md *and* long-form doc of each abutting neighbor, kept in sync as scope evolves. | [02](./artifacts/02-skill-taxonomy-guidance.md) E9; [03](./artifacts/03-precedent-and-cost.md) E11–E12; V8 |
| 8 | Existing agents are reusable for codebase-grounded research (`codebase-explorer`, `gap-analyzer`); `adversarial-validator` already works on non-bug recommendations (proven by this very analysis). | No existing agent is scoped to *external/idea-space* research; the new skill may need a new agent or a reframed brief for that posture. | [01](./artifacts/01-investigate-skill-analysis.md) E7; [03](./artifacts/03-precedent-and-cost.md) E13; ~~[01](./artifacts/01-investigate-skill-analysis.md) E6~~ corrected by V9 |

### Option B — Expand `/investigate` to also cover research

| # | For (supports expansion) | Against (why it's weaker) | Source |
|---|--------------------------|---------------------------|--------|
| 1 | Lower raw artifact count — no new skill directory, no new long-form doc, no count bumps in 3 files. | Single-responsibility rule prohibits one skill carrying two concerns; expansion = two skills stapled together under one name. | [02](./artifacts/02-skill-taxonomy-guidance.md) E1, E5 |
| 2 | The two workflows share an evidence-gathering scaffold (parallel agents → numbered findings → adversarial validation → summary). | The shared part is a generic shape; every *judgment-heavy* step (symptom classification, bug-specialist dispatch, causal-chain root cause, fix design, fix-targeted validation, the entire output template) diverges. Coupling is shallow, so "keep together when tightly coupled" does not apply. | [01](./artifacts/01-investigate-skill-analysis.md) E2–E5; V5 (answered) |
| 3 | `/investigate` Step 1 is already literally titled "Research and Investigation." | This is a one-word rename concern, not structural support either way. Originally cited as anti-expansion; corrected to neutral. | ~~[03](./artifacts/03-precedent-and-cost.md) E14~~ → V2 |
| 4 | `/investigate`'s noun list ("API calls, integrations, other aspects ... that need a deep dive") is broader than purely failure-framed. | The trigger *verbs* ("debug, troubleshoot, diagnose, why something is broken") still dominate routing. Description is *predominantly* failure-framed, not failure-locked — but expanding it makes the verb/noun tension worse, not better. | [01](./artifacts/01-investigate-skill-analysis.md) E1 softened by V1 |
| 5 | — | Expanding the description to add research triggers causes false routing: open-ended questions get pulled through adversarial fix-plan machinery. | [02](./artifacts/02-skill-taxonomy-guidance.md) E4, E6 |
| 6 | — | The long-form doc is the canonical source per concept; one doc carrying both "research" and "investigation" breaks the "one canonical source per concept" convention and makes the TL;DR unstatable in one sentence. | [01](./artifacts/01-investigate-skill-analysis.md) E8; [02](./artifacts/02-skill-taxonomy-guidance.md) E8, E10 |

### Option C — Reframe `/investigate` into a two-mode "deep-dive" skill (evaluated, rejected)

Surfaced by the adversarial pass (V4) as an unevaluated third option.
Evaluated against Han's own rules and rejected:

| # | Claim for Option C | Why it fails | Source |
|---|--------------------|--------------|--------|
| 1 | Fewer files; reuses the shared scaffold; no count bumps. | A two-mode skill is, by construction, one skill with two concerns — a direct violation of the single-responsibility rule. | [02](./artifacts/02-skill-taxonomy-guidance.md) E1 |
| 2 | One entry point is simpler for the user. | Its description must enumerate triggers for *both* modes and disambiguate from `code-review`/`architectural-analysis` (investigate side) *and* `plan-a-feature`/`coding-standard`/`gap-analysis`/`architectural-analysis` (research side) — strictly more disambiguation in one description than two clean ones each carry. Worse triggering, not better. | [02](./artifacts/02-skill-taxonomy-guidance.md) E6, E7; V7 |
| 3 | The shared engine justifies one skill. | Internal mode-branching at Step 1 reintroduces the exact structural rewrite E10 identified, now inside a SKILL.md whose every step assumes a symptom. Two step-trees under one prompt risks the "prompt so long the LLM can't follow it" failure the decomposition guidance warns against. | [01](./artifacts/01-investigate-skill-analysis.md) E10; [02](./artifacts/02-skill-taxonomy-guidance.md) E5 |

---

## Validation outcome and adjustments made

An `adversarial-validator` was dispatched to destroy the "separate skill"
conclusion. Full record:
[`artifacts/04-adversarial-validation.md`](./artifacts/04-adversarial-validation.md).
It produced 9 findings (V1–V9). The conclusion held; the evidence base was
corrected:

| Validation finding | Effect | Adjustment made in this report |
|--------------------|--------|-------------------------------|
| V1 — description is "predominantly" not "unambiguously" failure-framed | Weakens [01] E1 | Option B row 4 softened; no longer claims zero current overlap |
| V2 — [03] E14 ("Step 1 already called Research") was misread; it is neutral | Removes an anti-expansion point | Moved to Option B row 3, marked corrected/neutral |
| V3 — the `gh-pr-review`→`code-review` precedent leans on a now-discouraged sub-skill-call pattern | Weakens [03] E3 as precedent | Option A row 5 caveated; flagged as a separate housekeeping item below |
| V4 — a third option (two-mode reframe) was never evaluated | Gap in analysis | New **Option C** section added, evaluated, and rejected with reasons |
| V5 — split criteria applied without measuring the shared fraction | Demands rigor | Addressed: shared part is the generic scaffold only; all judgment-heavy steps diverge — coupling is shallow (Option A row 1, Option B row 2) |
| V6 — "slot is genuinely empty" overstated | Narrows the gap | Option A row 4: scope restricted to *output-agnostic* research |
| V7 — a `/research` skill faces its own trigger collisions | Real risk on the recommendation | Option A row 6: reciprocal routing to 4 neighbors made a hard requirement |
| V8 — cost is ~14+ files, not 6 | Corrects cost | Option A row 7 uses corrected figure |
| V9 — [01] E6 ("validator needs a fix to attack") is empirically false | Removes a structural argument | [01] E6 struck; this very validation proves the validator handles non-bug recommendations |

---

## Final recommendation

**Build `/research` as a separate skill.** Not because `/investigate` is "too
busy," but because they are structurally different processes: a research skill
starts from a question and ends at a recommended option among trade-offs; an
investigation starts from a symptom and ends at a validated fix. Han's
single-responsibility rule, its "Does not X — use Y" routing pattern (used by
all 18 skills), and the genuinely unoccupied open-ended-research slot all point
the same way. Expansion (Option B) violates single-responsibility and degrades
`/investigate`'s triggering. The two-mode reframe (Option C) is the same
violation wearing a different hat.

The recommendation is **Medium-confidence**: the conclusion is sound, but the
adversarial pass proved the first-pass evidence was oversold. Adopt it with
these constraints baked into the *next* step (the actual `/research` skill
plan), not deferred:

1. **Scope `/research` to open-ended, output-agnostic research only.** It is for
   "research my options / prior art / how X works before I commit." It is *not*
   spec-building (`/plan-a-feature`), standard-setting (`/coding-standard`),
   artifact comparison (`/gap-analysis`), or assessing existing architecture
   (`/architectural-analysis`).
2. **Draft and test the description's reciprocal routing against four
   neighbors** — `plan-a-feature`, `coding-standard`, `gap-analysis`,
   `architectural-analysis` — plus `investigate`. If clean disambiguation cannot
   fit the description budget, revisit this recommendation before building.
3. **Plan for the true cost: ~14+ file changes**, including reciprocal "Does
   not" lines in each neighbor's SKILL.md and long-form doc, kept in sync.
4. **Agent reuse:** `codebase-explorer` and `gap-analyzer` cover
   codebase-grounded research; `adversarial-validator` works on recommendations
   as-is (proven here). An external/idea-space research posture has no current
   agent — decide during planning whether to add one or reframe an existing
   brief.

### Housekeeping surfaced, not blocking

The adversarial pass (V3) found an unresolved contradiction between
`docs/guidance/skill-building-guidance/skill-composition.md` (prohibits skills
calling skills via the Skill tool) and `skill-decomposition.md` (still presents
`gh-pr-review → code-review` as a composition model). This is independent of the
`/research` decision but should be reconciled before either doc is cited as
authoritative for new skill design.

---

## Artifacts

All evidence is cross-referenced above by ID.

- [`artifacts/01-investigate-skill-analysis.md`](./artifacts/01-investigate-skill-analysis.md)
  — internals of `/investigate`; how tightly it is coupled to the bug/fix model.
- [`artifacts/02-skill-taxonomy-guidance.md`](./artifacts/02-skill-taxonomy-guidance.md)
  — Han's own authoring rules on splitting vs. expanding skills.
- [`artifacts/03-precedent-and-cost.md`](./artifacts/03-precedent-and-cost.md)
  — precedent across existing skill pairs, overlap with current skills, full
  cost of a new skill, agent reuse.
- [`artifacts/04-adversarial-validation.md`](./artifacts/04-adversarial-validation.md)
  — the adversarial attack on this recommendation (V1–V9), confidence, risks.
