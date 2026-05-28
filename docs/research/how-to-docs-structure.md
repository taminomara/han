# Research: Where and how should Han add how-to documents for planning, bug triage, and research workflows?

The question: how should Han add a set of how-to / workflow documents (covering planning, bug triage, and research) so they are findable, scannable, and easy for new users to follow, while staying inside Han's existing conventions about one canonical source per concept?

Evidence mode: **strict**. Every recommendation rests on cited evidence (codebase or web), and any claim that is not corroborated by an independent source carries a `[single-source]` mark.

## Summary

Han already documents these three workflows in several places: `docs/quickstart.md` Paths A, B, and E sketch the planning, triage-and-investigate, and research chains; every skill long-form doc carries a "How to get the most out of it" section with single-skill tips; and `docs/skills/README.md` lists multi-skill compositions in a "How skills compose" section. The issue's draft content adds a genuinely missing layer on top of those: the specific prompt templates an operator types, the decisions made between skills, and the manual review steps that happen between skill invocations. That depth is not present anywhere today.

The recommended structure is to add a new `docs/how-to/` directory with three separate per-workflow files — one each for planning, bug triage, and research — and to recast `docs/quickstart.md`'s overlapping paths as path-pickers that link into the new how-to docs rather than duplicating their content. Each new how-to opens with a "Before you begin" and "What you'll end up with" header block, groups its steps into named phases, writes branching steps inline using "if/then" phrasing, and follows Han's existing voice rules (second-person imperative, ordinal signposting, no em-dashes, mentor tone).

This recommendation rests on well-corroborated evidence for the per-document structure (Diátaxis + Carroll minimalism + cognitive load grouping) and well-corroborated evidence for separating how-to from reference (Diátaxis + three production examples, downgraded for scale). The single point that does not survive validation is treating Han's new directory as a no-op for the existing docs: a content-ownership plan that re-scopes quickstart and the skill-doc "How to get the most out of it" sections is part of the deliverable, not optional.

## Research Results

Diátaxis (A1) names four documentation types and argues that mixing how-to with reference is "at the heart of a vast number of problems in documentation." A how-to guide is a recipe for a competent user executing a known task; it differs from a tutorial (learning-oriented) and from a reference (system-oriented). The framework does not prescribe granularity within the how-to category, but it consistently advocates for one specific goal per guide. The Divio documentation system (A4) is the predecessor publication of the same framework by the same author, so it is not independent corroboration; the framework counts as one source, not two.

Mark Baker's Every Page is Page One principle (A6, A7) argues that web users arrive at any page from search, so each page must be self-contained, establish context immediately, and link richly to related pages along subject affinities. This favors separate per-workflow pages over a combined document for related workflows. Carroll's minimalism (A18) reinforces the same point from cognitive science: short, task-oriented, independent modules outperform long combined manuals, with a cited finding of roughly 50% faster learning when a 94-page manual was replaced by 25 task cards (single-source on the specific quantitative result).

Three production developer documentation sets implement separate top-level locations for how-to versus reference: GitHub Actions (A11), Supabase (A15), and Cloudflare Workers (A16). These are independent confirmation of the pattern, but with a meaningful caveat surfaced in validation: all three are large-scale documentation surfaces (hundreds of pages, multi-team authoring). Han has roughly 50 documentation files. The pattern is therefore evidence that separation scales, not evidence that separation is correct at Han's scale `[scale-mismatched]`. Stripe (A13, A14) integrates how-to content with reference inside product sections, but relies on a three-column interactive layout that Han's Markdown-based docs cannot replicate; the pattern that is replicable — embedding cross-skill workflow tips inside skill long-form docs — is something Han already does in every "How to get the most out of it" section.

For step-level structure inside a recipe, cognitive load research recommends grouping steps into named phases of 3–4 items rather than presenting flat lists of 10+ steps (A10, A12). The "4–7 working memory items" figure cited in A12 derives from Miller's Law (1956), a foundational psychology finding that is independently replicated and is not load-bearing on A12 specifically. Tom Johnson (A9) recommends a layered hierarchy — portal → section landing → individual how-to — with on-page TOCs at junction points, articles in the 800–3,000 word range rather than micro-fragments, and "Next Steps" sections to orient readers mid-procedure. For decision points within a recipe, BufferBuffer (A19) recommends writing branching steps inline using "if/then" phrasing rather than promoting branches to visual callout boxes; this is single-source and is the least well-evidenced specific technique below.

For entry orientation, four independent sources converge on the same pattern: open each recipe with a "Before you begin" / prerequisites block and a "What you'll end up with" / stated outcome block (A1, A6, A9, A10). This lets first-time readers self-filter on prerequisites and self-assess relevance before investing time in the steps.

Han's existing structure adds a real constraint that the open-web evidence cannot anticipate. Han's CLAUDE.md states: "One canonical source per concept. The long-form doc in `docs/skills/` or `docs/agents/` is canonical for that skill or agent. Index entries carry one-sentence scent plus a link. The README never duplicates long-form content." A new `docs/how-to/` directory does not violate any explicit folder rule (the "no new top-level folders" rule applies only to plans and research per the surrounding context in CLAUDE.md), but it does create a duplication risk against three existing locations: `docs/quickstart.md` Paths A/B/E already cover the same three workflows at a high level; the 21 skill long-form docs each carry a "How to get the most out of it" section that often contains cross-skill workflow tips; and `docs/skills/README.md` "How skills compose" lists multi-skill chains in prose. Adding how-to docs without re-scoping those locations creates day-one conflict with the canonical-source rule.

## Options to Consider

### O1-A: One combined doc covering all three workflows

- **What it is:** A single Markdown file (for example `docs/workflows.md`) with three top-level sections — planning, triage, research — each containing the full step-by-step recipe.
- **Trade-offs:** Easier to scan across workflows in one read. Worse information scent: a reader arriving from search for "investigate a bug" lands at the top of a file dominated by planning content and must scroll past it. Harder to deep-link from other docs. Compounds maintenance pressure as the file grows.
- **Rests on:** A9 (favors substantial articles over micro-fragments), contradicted by A1, A6, A18.
- **Evidence status:** single source for the pro side; contradicted by three independent sources.

### O1-B: Separate per-workflow files, joined by an index page (recommended for Q1)

- **What it is:** Three separate files — for example `docs/how-to/plan-a-feature.md`, `docs/how-to/triage-and-investigate-a-bug.md`, `docs/how-to/research-a-decision.md` — each standalone, joined by a `docs/how-to/README.md` index with one-sentence scent lines and links.
- **Trade-offs:** Each page is self-contained, search-friendly, and deep-linkable. The index adds a small amount of duplicated metadata. Multi-skill chains that cross workflows must be cross-linked between files; this is cheap in Markdown.
- **Rests on:** A1, A4 (same framework — counts once), A6, A7, A11, A15, A16, A18.
- **Evidence status:** corroborated by multiple independent sources; the framework appears once, not twice. The production examples (A11, A15, A16) are scale-mismatched and act as directional evidence rather than confirmation at Han's scale.

### O2-A: New `docs/how-to/` directory, separate from `docs/skills/` and `docs/quickstart.md`

- **What it is:** A new top-level directory under `docs/` that holds the how-to files. Linked from the root `README.md`, `docs/skills/README.md`, and `docs/quickstart.md`.
- **Trade-offs:** Mirrors the Diátaxis separation between how-to and reference. Requires explicit content-ownership decisions for the three locations that already touch this content (quickstart, skill docs, skills README); without those, it violates the canonical-source rule on day one. Adds a `CLAUDE.md` map update.
- **Rests on:** A1, A11, A15, A16 (with the scale caveat from V3 in validation).
- **Evidence status:** corroborated by one framework and three production examples; the framework is single-author (V8), and the production examples are at much larger scale than Han (V3).

### O2-B: Extend `docs/quickstart.md` with deeper procedural content under existing paths

- **What it is:** Expand each of the five quickstart paths in place, adding the per-step procedural depth (specific prompts, decisions, manual review notes) inside the existing path bullets. No new files.
- **Trade-offs:** Avoids the canonical-source conflict — quickstart becomes the single source for path-based workflow guidance. Risks a single very long file (quickstart is ~117 lines today, would likely exceed 400–500 lines). Loses search-engine deep-link granularity per workflow.
- **Rests on:** A9 (substantial articles are preferable to micro-fragments). Contradicted by A6 (EPPO favors standalone pages).
- **Evidence status:** single-source for the pro side; trades against the recommended separate-pages pattern.

### O2-C: Fold workflow content into existing skill long-form docs' "How to get the most out of it" sections

- **What it is:** Expand each skill doc's existing tips section into a multi-skill workflow walkthrough. No new files, no quickstart changes.
- **Trade-offs:** Already partially present, so the path of least disruption. But quickly creates the problem the validator surfaced (V7): multi-skill workflows would have to be repeated in every skill they touch, and "how do I plan a feature end-to-end" would be split across `plan-a-feature.md`, `plan-implementation.md`, `iterative-plan-review.md`, and `plan-work-items.md`. No single page would answer the question.
- **Rests on:** Codebase observation that this pattern already exists.
- **Evidence status:** codebase-grounded for the existing pattern. The scaling failure (workflow repetition across skill docs) is reasoning, not evidenced — but is structurally obvious from the per-file model.

### O3-A: Phase-chunked numbered steps with named phase headers (recommended for Q3)

- **What it is:** Inside each how-to, group the 5–12 steps into 2–4 named phases (e.g., "Phase 1: Spec the work," "Phase 2: Plan implementation," "Phase 3: Break into work items") with H3 headers above the numbered steps in each phase.
- **Trade-offs:** Works in plain Markdown with no special rendering. Reduces working-memory load by chunking. Does not hide any content from experienced readers. Requires a real phase model per workflow.
- **Rests on:** A10, A12 (working memory grouping — independently corroborated by Miller's Law), A18 (minimalism), A1 (Diátaxis structure).
- **Evidence status:** corroborated by multiple independent sources.

### O3-B: Accordions / collapsible sections per step

- **What it is:** Hide step detail behind expandable widgets, surfacing only step titles by default.
- **Trade-offs:** Requires interactive rendering. Han's docs are plain Markdown; accordions are not natively supported. Hiding steps can cause readers to miss prerequisites before they reach them.
- **Rests on:** A5, A20 (UX progressive disclosure in general).
- **Evidence status:** single-source for the technique applied to documentation specifically; not viable in Han's rendering context.

### O3-D: Stated outcome and prerequisites block at the top of each how-to (recommended additive)

- **What it is:** Open each how-to with two short blocks — "Before you begin" (prerequisites: skills, tools, prior state) and "What you'll end up with" (the concrete artifact or outcome).
- **Trade-offs:** Adds repeated structural boilerplate per page. New readers immediately self-filter on prerequisites and self-assess relevance. Compatible with every other structural option.
- **Rests on:** A1, A6, A9, A10.
- **Evidence status:** corroborated by four independent sources.

### O4-A: Phase chunks plus inline conditional phrasing for branches (recommended for Q4 alongside O4-C and O4-D)

- **What it is:** Inside the phase-chunked structure, write decision points inline within the numbered steps: "If you have a phased build doc, run `/plan-a-feature for phase {N}`; otherwise, run `/plan-a-feature on {feature}`." Reserve callout boxes for irreversible-action warnings and shortcuts.
- **Trade-offs:** Inline branching scales to one or two branches per step. Beyond that, the linear flow breaks down.
- **Rests on:** A10, A12, A18, A19 (single-source for the specific inline branching recommendation).
- **Evidence status:** the chunking component is well-corroborated; the inline-branching technique itself rests on a single source `[single-source]` and should be revisited if a how-to's decision tree exceeds two branches per step.

### O4-C: "Before you begin" / "What you'll end up with" headers (recommended for Q4, same as O3-D)

- See O3-D above.

### O4-D: Happy-path first, with variations in a trailing section (recommended for Q4)

- **What it is:** Document the most common path through the workflow as the main flow. Move alternative paths (different starting conditions, non-standard tooling) to a trailing "Variations" section.
- **Trade-offs:** First-time readers with standard setup follow a clean linear flow. Readers with variations must scroll past the happy path to find their case. Requires author judgment about what "happy path" means for the population.
- **Rests on:** A13, A14 (Stripe's "fast paths for the happy flow"), A18.
- **Evidence status:** corroborated.

## Recommendation

- **Recommendation:**
  - **Q1 (one vs. many):** O1-B — separate per-workflow files joined by an index.
  - **Q2 (location):** O2-A — a new `docs/how-to/` directory, **conditional on a content-ownership plan** that re-scopes `docs/quickstart.md` Paths A/B/E and the relevant skill long-form `## How to get the most out of it` sections to point into the new how-to docs rather than duplicating their content. Without the re-scoping, the recommendation does not survive Han's canonical-source rule; it must ship as part of the same change.
  - **Q3 (progressive disclosure):** O3-A (phase-chunked numbered steps) + O3-D (outcome + prerequisites block at the top).
  - **Q4 (cognitive load for 5+ step recipes):** O4-C (Before you begin / What you'll end up with) + O4-A (phase chunks + inline branching, with the inline-branching caveat) + O4-D (happy path first, variations trailing).

- **Evidence basis:**
  - The per-document structure (O1-B + O3-A + O3-D + O4-C + O4-D) rests on multiple independent corroborated sources (Diátaxis, Carroll, Baker, cognitive load research, Tom Johnson's navigation principles).
  - The location decision (O2-A) rests on one documentation framework (Diátaxis, single author) plus three production examples that are scale-mismatched (V3). At Han's scale (~50 docs) the production-examples corroboration weakens to directional. The framework's recommendation still stands on its own, but the operator should treat O2-A as a calibrated bet rather than an overdetermined choice. The recommendation is conditional on the content-ownership re-scoping work being treated as part of the same change.
  - The inline-branching technique (O4-A second half) rests on a single source (A19) and should be revisited if any how-to develops a decision tree more than two branches deep.

## Validation

### V1: The "no new top-level folders" rule was misapplied as a constraint

- **Strategy:** Challenge the Evidence
- **Investigation:** Re-read CLAUDE.md lines 126–131 in full. The "do not invent new top-level folders for these artifacts" rule has a scoped antecedent — "these artifacts" refers to plans and research, not to documentation in general.
- **Result:** Refuted (in the recommendation's favor).
- **Impact:** The synthesis no longer cites CLAUDE.md as an obstacle to a new `docs/how-to/` directory. CLAUDE.md remains an obstacle for the canonical-source rule (V2 / V6 / V7), not for the folder itself.

### V2: The "one canonical source per concept" rule is a real constraint against O2-A as originally framed

- **Strategy:** Challenge the Evidence
- **Investigation:** CLAUDE.md line 135: "One canonical source per concept." Quickstart Paths A, B, and E already document the planning, triage-investigate, and research workflows; every skill long-form doc has a "How to get the most out of it" section; `docs/skills/README.md` has a "How skills compose" section. The proposed how-tos cover the same workflows.
- **Result:** Refuted.
- **Impact:** The recommendation now requires a content-ownership re-scoping of quickstart and the affected skill-doc sections as part of the same change. The how-to directory cannot ship as a pure addition.

### V3: The three production examples are scale-mismatched

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** GitHub Actions, Supabase, and Cloudflare Workers each have hundreds of pages of documentation. Han has roughly 50 files. The structural problem these platforms solved (readers drowning in content-type mixing at large scale) does not directly apply at Han's scale.
- **Result:** Partially refuted.
- **Impact:** The production examples drop from "confirmation" to "directional evidence." The Diátaxis framework still independently favors separation, so the recommendation stands but with reduced confidence. Acknowledged in the Confidence Assessment.

### V4: A12's working-memory figure is not load-bearing

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** The "4–7 items" figure traces to Miller's Law (1956), a widely replicated cognitive psychology finding. The Learnnovators article (A12) is a tertiary repetition. Phase chunking is also independently recommended by Diátaxis and Carroll minimalism.
- **Result:** Confirmed.
- **Impact:** No change. A12 remains in the artifact registry; the recommendation does not break if A12 is removed.

### V5: The Stripe pattern is closer to Han's existing convention than the synthesis acknowledged

- **Strategy:** Challenge the Evidence
- **Investigation:** Every Han skill long-form doc already embeds workflow tips inside reference content via "How to get the most out of it." That is Stripe's integration pattern (without the three-column layout).
- **Result:** Partially refuted.
- **Impact:** O2-A must be argued as an improvement over the existing integrated pattern, not as a replacement for an absent one. The argument: existing skill docs hold single-skill tips well, but cannot hold multi-skill end-to-end recipes without repeating the recipe across every skill it touches. That is the specific reader problem O2-A solves.

### V6: Quickstart had no designated fate in the original recommendation

- **Strategy:** Challenge the Fix
- **Investigation:** Quickstart Paths A, B, E already cover planning, triage-investigate, and research. The original recommendation did not say what happens to them.
- **Result:** Refuted.
- **Impact:** The recommendation is now explicit: quickstart's overlapping paths are recast as path-pickers (one-sentence scent + link into the how-to). Detailed steps move to how-to. This is part of the same change, not a follow-up.

### V7: The skill-doc "How to get the most out of it" sections need an explicit content ownership boundary

- **Strategy:** Challenge the Fix
- **Investigation:** Several skill docs' tips sections already contain cross-skill workflow guidance (e.g., `/investigate` mentions pairing with `/iterative-plan-review`; `/plan-a-feature` mentions pairing with `/plan-implementation`).
- **Result:** Refuted.
- **Impact:** The recommendation now includes a content-ownership boundary: skill long-form docs hold single-skill tips and brief "pairs with X next" pointers that link into the how-to. Multi-step end-to-end workflows live in `docs/how-to/`.

### V8: Diátaxis and Divio are the same framework by the same author

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** Both A1 (diataxis.fr) and A4 (docs.divio.com) are Daniele Procida's work. Diátaxis is the evolved current canonical name; Divio is the predecessor publication.
- **Result:** Refuted.
- **Impact:** The corroboration for O2-A drops from "framework × 2 + three production examples" to "framework × 1 + three scale-mismatched production examples." The framework still independently endorses the pattern, but the apparent strength is reduced. Reflected in the Confidence Assessment.

### Adjustments Made

The recommendation was rewritten in three places:
1. **Q2 (location):** O2-A is now conditional on a content-ownership re-scoping plan covering quickstart Paths A/B/E and the relevant skill-doc "How to get the most out of it" sections. The re-scoping must ship in the same change.
2. **Evidence basis:** Diátaxis and Divio are counted once (not twice). Production examples are explicitly downgraded to directional evidence.
3. **Inline branching:** O4-A's inline-branching component is marked `[single-source]` and flagged for revisit if any how-to develops a decision tree more than two branches deep.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  - The location recommendation (O2-A) rests on one framework and scale-mismatched production examples. A small-scale plugin doing this exact split would be stronger evidence; no such example was found in the search.
  - The inline-branching technique for decision points rests on a single source.
  - The content-ownership re-scoping is now part of the recommendation but its blast radius depends on how many skill-doc tips sections contain multi-skill content. A quick survey before implementation will tighten this.
  - `CLAUDE.md`'s "When to use which doc" section needs a new entry for the how-to directory. Without that, the project map drifts out of sync with the directory structure on day one. The change should ship together.

## Artifacts

### A1: Diátaxis — How-to Guides

- **Link / location:** https://diataxis.fr/how-to-guides/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Defines how-to guides as task-oriented directions for already-competent users working on real problems; distinguishes them from tutorials (learning-oriented) and reference (system-oriented). States that "crossing or blurring the boundaries" between content types is the source of many documentation problems. Does not prescribe directory structure or granularity within how-to.
- **Evidence status:** corroborated by A6, A7, A11, A15, A16, A18. Note: A4 (Divio) is the same framework by the same author and is counted once with A1.

### A4: Divio Documentation System — How-to Guides

- **Link / location:** https://docs.divio.com/documentation-system/how-to-guides/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Predecessor publication of Diátaxis by the same author. Same conceptual framework. Retained in the registry for completeness but does not count as independent corroboration of A1.
- **Evidence status:** same source as A1.

### A5: Nielsen Norman Group — Progressive Disclosure

- **Link / location:** https://www.nngroup.com/articles/progressive-disclosure/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Distinguishes progressive disclosure (hierarchical, optional depth) from staged disclosure (linear wizard). For recipe content, staged disclosure prevents skipping ahead; progressive disclosure serves both new and experienced readers.
- **Evidence status:** corroborated by A20.

### A6: Mark Baker — Every Page is Page One

- **Link / location:** https://techwhirl.com/every-page-page-one-topic-based-authoring-tech-comm-web/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Web readers arrive at any page from search; every page must be self-contained, establish context immediately, have a single purpose, and link richly to related pages.
- **Evidence status:** corroborated by A7.

### A7: Mark Baker — TOC in Bottom-Up Information Architecture

- **Link / location:** https://everypageispageone.com/2015/02/20/the-role-of-the-toc-in-a-bottom-up-information-architecture/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Comprehensive top-down TOCs don't scale; favor multiple small local TOCs at junction points and link pages by subject affinity.
- **Evidence status:** corroborated by A6.

### A9: Tom Johnson — Documentation Navigation Design Principles

- **Link / location:** https://idratherbewriting.com/files/doc-navigation-wtd/design-principles-for-doc-navigation/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Five navigation principles: hierarchy (≤2 levels), progressive disclosure (portal → product → section → page), modular self-contained chunks (800–3,000 words), rich inline linking, and surfacing popular paths.
- **Evidence status:** corroborated by A5, A6.

### A10: Cognitive Load Theory in Technical Writing — Hire A Writer

- **Link / location:** https://www.hireawriter.us/technical-content/cognitive-load-theory-in-technical-writing
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Recommends chunking, numbered lists over dense prose for procedural steps, progressive disclosure across overview → quickstart → details → advanced, and consistent structure per document.
- **Evidence status:** corroborated by A12, A18.

### A11: GitHub Actions Documentation — Navigation Structure

- **Link / location:** https://docs.github.com/en/actions
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Five distinct top-level sections: Getting Started, Concepts, How-tos, Tutorials, Reference. How-tos are further sub-grouped by goal cluster.
- **Evidence status:** corroborated by A15, A16. Scale-mismatched relative to Han per V3.

### A12: Chunking and Cognitive Load — Learnnovators

- **Link / location:** https://learnnovators.com/blog/chunking-breaking-learning-into-bite-sized-pieces/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Working memory holds 4–7 items. Grouping procedures into named phases reduces cognitive load. The figure traces to Miller's Law (1956), independently replicated.
- **Evidence status:** corroborated by A10, A18; primary source (Miller 1956) is independently established.

### A13: Stripe Documentation Architecture — APIdog teardown

- **Link / location:** https://apidog.com/blog/stripe-docs/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Stripe integrates how-to content with reference inside product sections using a three-column interactive layout with code-on-hover and one-click language switching.
- **Evidence status:** corroborated by A14.

### A14: Stripe Documentation Architecture — Moesif teardown

- **Link / location:** https://www.moesif.com/blog/best-practices/api-product-management/the-stripe-developer-experience-and-docs-teardown/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Independent confirmation of A13's structural description; adds detail on Stripe's emphasis on "fast paths for the happy flow."
- **Evidence status:** corroborated by A13.

### A15: Supabase Documentation Navigation

- **Link / location:** https://supabase.com/docs
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Hard separation between guides (Getting Started, Products, Build, Manage) and a dedicated Reference section (API, CLI).
- **Evidence status:** corroborated by A11, A16. Scale-mismatched per V3.

### A16: Cloudflare Workers Documentation Sections

- **Link / location:** https://developers.cloudflare.com/workers/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Distinct top-level sections for Framework Guides, Tutorials, Examples, Reference, and Configuration.
- **Evidence status:** corroborated by A11, A15. Scale-mismatched per V3.

### A18: John Carroll Minimalism — InstructionalDesign.org

- **Link / location:** https://www.instructionaldesign.org/theories/minimalism/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Four minimalism principles: immediate meaningful tasks, minimize passive reading, include error recognition/recovery, make modules independent of sequence. Self-contained, task-oriented, non-sequential modules outperform combined manuals.
- **Evidence status:** corroborated by A6.

### A19: BufferBuffer — Callouts in Procedural Documentation

- **Link / location:** https://bufferbuffer.com/when-to-use-notes-warnings-and-callouts-in-tech-writing-and-when-not-to/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Recommends inline conditional phrasing for branching steps; reserves callout boxes for shortcuts and irreversible-action warnings.
- **Evidence status:** single source.

### A20: Progressive Disclosure — LogRocket

- **Link / location:** https://blog.logrocket.com/ux-design/progressive-disclosure-ux-types-use-cases/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Three implementation techniques (content layering, accordions, hover/click reveal). Recommends ≤3 levels of disclosure depth.
- **Evidence status:** corroborated by A5.

### A21: Han `docs/quickstart.md` (current state)

- **Link / location:** `docs/quickstart.md`
- **Retrieved:** n/a (codebase)
- **Trust class:** codebase
- **Summary:** Five path-based recipes (A: plan a feature; B: investigate a bug; C: review code; D: set up a project; E: research options) plus a "Combining paths" section. Paths A, B, and E directly overlap with the three workflows in issue #20.
- **Evidence status:** codebase-grounded.

### A22: Han `docs/skills/README.md` "How skills compose" section

- **Link / location:** `docs/skills/README.md` (How skills compose section)
- **Retrieved:** n/a (codebase)
- **Trust class:** codebase
- **Summary:** Lists multi-skill compositions in prose: triage → investigate, create specs → plan implementation → iterate → break into work items, discover → document → standardize, and more. Touches the same workflow chains as issue #20.
- **Evidence status:** codebase-grounded.

### A23: Han skill long-form docs — "How to get the most out of it" sections

- **Link / location:** `docs/skills/*.md` (multiple files)
- **Retrieved:** n/a (codebase)
- **Trust class:** codebase
- **Summary:** Every skill long-form doc carries a "How to get the most out of it" section with usage tips. Several contain cross-skill workflow guidance (e.g., `plan-a-feature.md` "Pair with `/plan-implementation` next"; `investigate.md` pairing with `/iterative-plan-review`; `research.md` pairing with `/plan-a-feature`).
- **Evidence status:** codebase-grounded.

### A24: Han `docs/writing-voice.md` — voice rules for procedural content

- **Link / location:** `docs/writing-voice.md`
- **Retrieved:** n/a (codebase)
- **Trust class:** codebase
- **Summary:** Direct second-person imperative dominates tutorials; ordinal signposting ("First, Second, Lastly") is the signature pattern for technical walkthroughs; no em-dashes; no "just"; no "actually"; no "leverage"; first-person presence in long technical articles is non-negotiable.
- **Evidence status:** codebase-grounded.

### A25: Han `CLAUDE.md` — "One canonical source per concept" convention

- **Link / location:** `CLAUDE.md`
- **Retrieved:** n/a (codebase)
- **Trust class:** codebase
- **Summary:** States that the long-form doc in `docs/skills/` or `docs/agents/` is canonical for that skill or agent, and that the README never duplicates long-form content. Triggered by V2 / V6 / V7 in validation.
- **Evidence status:** codebase-grounded.

## References

- **A1** — Diátaxis: How-to Guides. https://diataxis.fr/how-to-guides/ (retrieved 2026-05-28).
- **A4** — Divio Documentation System: How-to Guides. https://docs.divio.com/documentation-system/how-to-guides/ (retrieved 2026-05-28).
- **A5** — Nielsen Norman Group: Progressive Disclosure. https://www.nngroup.com/articles/progressive-disclosure/ (retrieved 2026-05-28).
- **A6** — Mark Baker, "Every Page is Page One: Topic-Based Authoring for Tech Comm in the Web Age." https://techwhirl.com/every-page-page-one-topic-based-authoring-tech-comm-web/ (retrieved 2026-05-28).
- **A7** — Mark Baker, "The Role of the TOC in a Bottom-Up Information Architecture." https://everypageispageone.com/2015/02/20/the-role-of-the-toc-in-a-bottom-up-information-architecture/ (retrieved 2026-05-28).
- **A9** — Tom Johnson, "Design Principles for Doc Navigation." https://idratherbewriting.com/files/doc-navigation-wtd/design-principles-for-doc-navigation/ (retrieved 2026-05-28).
- **A10** — Hire A Writer: Cognitive Load Theory in Technical Writing. https://www.hireawriter.us/technical-content/cognitive-load-theory-in-technical-writing (retrieved 2026-05-28).
- **A11** — GitHub Actions Documentation. https://docs.github.com/en/actions (retrieved 2026-05-28).
- **A12** — Learnnovators: Chunking — Breaking Learning into Bite-Sized Pieces. https://learnnovators.com/blog/chunking-breaking-learning-into-bite-sized-pieces/ (retrieved 2026-05-28).
- **A13** — APIdog: Why Stripe's API Docs Are the Benchmark. https://apidog.com/blog/stripe-docs/ (retrieved 2026-05-28).
- **A14** — Moesif: The Stripe Developer Experience and Docs Teardown. https://www.moesif.com/blog/best-practices/api-product-management/the-stripe-developer-experience-and-docs-teardown/ (retrieved 2026-05-28).
- **A15** — Supabase Documentation. https://supabase.com/docs (retrieved 2026-05-28).
- **A16** — Cloudflare Workers Documentation. https://developers.cloudflare.com/workers/ (retrieved 2026-05-28).
- **A18** — InstructionalDesign.org: Minimalism (Carroll). https://www.instructionaldesign.org/theories/minimalism/ (retrieved 2026-05-28).
- **A19** — BufferBuffer: When to Use Notes, Warnings, and Callouts in Tech Writing. https://bufferbuffer.com/when-to-use-notes-warnings-and-callouts-in-tech-writing-and-when-not-to/ (retrieved 2026-05-28).
- **A20** — LogRocket: Progressive Disclosure UX. https://blog.logrocket.com/ux-design/progressive-disclosure-ux-types-use-cases/ (retrieved 2026-05-28).
- **A21** — Han: `docs/quickstart.md` (current state).
- **A22** — Han: `docs/skills/README.md` ("How skills compose" section).
- **A23** — Han: `docs/skills/*.md` ("How to get the most out of it" sections in skill long-form docs).
- **A24** — Han: `docs/writing-voice.md` (voice rules for procedural content).
- **A25** — Han: `CLAUDE.md` ("One canonical source per concept" convention).
