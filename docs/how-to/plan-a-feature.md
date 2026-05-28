# How To: Plan a Feature, End to End

A walkthrough of the full planning loop for a new feature, from a rough idea to a list of independently grabbable work items, using han's planning skills in sequence.

> See also: [How-to index](./README.md) · [Quickstart](../quickstart.md) · [Skills](../skills/README.md)

## Before you begin

- You have a rough feature idea. One or two sentences is enough. Han walks you from there.
- You have somewhere to put the artifacts. A folder under `docs/features/`, `docs/plans/`, or wherever your project keeps planning work. If you do not, han will propose a folder before creating files.
- You have any upstream product context the feature has already accumulated. A PRD, a linked issue, a meeting transcript, a Slack thread, a Notion page. Bring whatever you have. The skills will not invent product intent.

If any of those are missing, the workflow still runs but you will answer more questions yourself instead of letting the skills cite codebase evidence.

## What you'll end up with

- A `feature-specification.md` that describes what the feature does at the behavioral level.
- A `feature-implementation-plan.md` that describes how to build it.
- A `work-items.md` with one entry per independently grabbable piece of work.
- For larger features, a `build-phase-outline.md` that orders the work into demoable vertical slices, and a per-phase spec and plan rather than a single monolithic one.
- Decision logs and review findings alongside each artifact, cross-referenced by stable IDs so a future reader can trace every commitment back to the evidence that drove it.

When you have all of those, the planning loop is complete and the work is ready to be turned into issue tickets or implemented directly.

## The happy path

The workflow is grouped into three phases. The first phase produces the behavioral spec. The second phase produces an implementation plan for a single slice of the work. The third phase turns that plan into individual work items.

### Phase 1: Spec the feature

1. **Run [`/plan-a-feature`](../skills/plan-a-feature.md) with the rough idea and an output folder.** A prompt that works well:

    > `/plan-a-feature on building out {feature idea}, using {reference} as a starting point. It needs to {live here, do this, use that, etc}. Write the plan to {plan file location} as we go.`

    Han runs an evidence-based interview that walks the design tree: foundational decisions first (what, who, outcome, trigger), then behavioral (flows, states, coordinations), then boundary (edge cases, out of scope), then interaction (UI / API surface). The skill explores the codebase, ADRs, and coding standards before surfacing each question, so most questions arrive with a recommended answer already attached.

2. **Walk through every open item and decide.** When the skill surfaces a question, accept the recommendation, redirect it, or ask for an alternative. Decisions you make here flow into the spec; decisions you defer land in an Open Items section so they do not silently disappear.

3. **Decide whether the feature needs phasing.** If the spec describes a small, single-subsystem feature, skip Phase 2's step 1 and jump to step 2. If the spec is medium or large — multiple subsystems, multiple new coordinations, or anything you would not be comfortable shipping in one PR — phase the build.

### Phase 2: Plan the implementation

1. **If the feature needs phasing, run [`/plan-a-phased-build`](../skills/plan-a-phased-build.md).** A prompt that works well:

    > `/plan-a-phased-build {plan file location}`

    The skill splits the spec into a numbered sequence of vertical-slice phases. Each phase is independently demoable to a real person, and each builds on the prior. The output is a `build-phase-outline.md` next to the spec.

2. **Spec the next phase.** If you phased the build, run `/plan-a-feature` again, this time for a specific phase:

    > `/plan-a-feature for phase {N} of {phased build doc}`

    If you skipped phasing, the original spec from Phase 1 is the spec for this step; move directly to step 3.

3. **Manually review the spec.** Read what han produced. Look for anything that drifted from the original idea, anything you do not understand, and anything that contradicts a decision you remember making. Push back where needed; han adjusts in place.

4. **Iterate on the spec.** Run [`/iterative-plan-review`](../skills/iterative-plan-review.md) against the spec and watch it refute assumptions, correct inconsistencies, and surface gaps you missed.

    > `/iterative-plan-review {plan file location}`

    Manually review again after iteration completes. Walk through any new open items the review surfaced before moving on.

5. **Plan the implementation for this slice.** Run [`/plan-implementation`](../skills/plan-implementation.md):

    > `/plan-implementation {phase N feature spec file location}`

    The skill runs a project-manager-led team conversation among specialist sub-agents to produce a `feature-implementation-plan.md`. Walk through any open items the project-manager surfaces and decide.

6. **Iterate on the implementation plan.** Run `/iterative-plan-review` again, this time against the implementation plan:

    > `/iterative-plan-review {phase N implementation plan file location}`

    Walk through any new open items.

### Phase 3: Break the plan into work

1. **Run [`/plan-work-items`](../skills/plan-work-items.md).** A prompt that works well:

    > `/plan-work-items {phase N implementation plan file location}`

    The skill writes a `work-items.md` file in the plan folder. Each entry is independently grabbable, sized to be picked up alone, and traceable back to the section of the implementation plan it implements.

2. **Review the work items.** Check that the granularity matches your team's appetite and that nothing important got merged into a single item by mistake. The skill is happy to re-run if you want to resplit.

3. **Hand off.** Turn the items into issue tickets or work them directly. When you sit down to build, run [`/tdd`](../skills/tdd.md) on the first item to drive it test-first through a red-green-refactor loop with an enforced observed-failure gate.

## Variations

- **Sharing the spec for non-technical sign-off.** After Phase 1 produces a `feature-specification.md`, run [`/stakeholder-summary`](../skills/stakeholder-summary.md) before moving to Phase 2. It produces a plain-language summary with Mermaid diagrams that you can share with leadership, product, or customer-facing reviewers before the team commits to building.

- **Skipping the phased build.** For small features (single subsystem, no cross-service integration, no migration), the phased build adds overhead without adding clarity. Run `/plan-implementation` directly against the spec from Phase 1 and proceed to Phase 3.

- **Re-running a step after a constraint changes.** If a stakeholder reopens a decision after the spec hardens, re-run `/plan-a-feature` with the new context. The existing spec, decision log, and team findings become inputs to the new run, and the cross-reference IDs carry forward so prior references stay stable. The same is true of `/plan-implementation` against a changed spec.

- **When the iterative review produces a fix-the-plan ask that is bigger than expected.** If `/iterative-plan-review` surfaces a gap that materially changes the spec rather than refining the plan, go back and re-run `/plan-a-feature` for that slice before continuing. The plan is only as good as the spec under it.

## What you should expect at each step

- **Han asks for evidence first.** Most questions arrive with a recommended answer drawn from the codebase, ADRs, or coding standards. Treat the recommendation as the default; redirect only when you have a reason.
- **Open items are not failures.** Every plan-shaped artifact has an Open Items section. If a question cannot be answered with the available evidence, it lands there rather than getting an invented answer. Walk through open items deliberately at the end of each step.
- **Iteration is part of the loop, not a sign something went wrong.** `/iterative-plan-review` is expected to find things. A clean review is the unusual outcome.
- **Sizing happens automatically.** Most of the planning skills classify the work as small, medium, or large and default to small. Pass `medium` or `large` as the first positional argument if you know the work is bigger than the default. See [Sizing](../sizing.md).

## Where to go next

- [`/tdd`](../skills/tdd.md) is the next step when work items are ready to build. It is han's only execution skill.
- [Triage and investigate a bug](./triage-and-investigate-a-bug.md) is the right guide when the work is not a new feature but a fix.
- [Research a decision](./research-a-decision.md) is the right guide when you are not ready to spec because the underlying decision (which library, which pattern, which approach) has not been made yet.
- The skill long-form docs ([plan-a-feature](../skills/plan-a-feature.md), [plan-a-phased-build](../skills/plan-a-phased-build.md), [plan-implementation](../skills/plan-implementation.md), [iterative-plan-review](../skills/iterative-plan-review.md), [plan-work-items](../skills/plan-work-items.md), [tdd](../skills/tdd.md)) cover each step in depth. The how-to tells you how they fit together; the long-form docs tell you what each one does on its own.
