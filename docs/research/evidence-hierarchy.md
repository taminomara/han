# Research: Hierarchy of Evidence Confidence for the Han Plugin

What canonical hierarchy of evidence confidence should Han adopt, modeled after the YAGNI canonical pair, to anchor the "evidence-based" language that runs through nearly every skill and agent?

Evidence mode: **strict** (default — every load-bearing claim cites a source the reader can check).

## Summary

Six disciplines that have formalized this question — medicine, historiography, law, intelligence analysis, journalism, and academic research — agree on five structural principles, and three of those principles already appear, in fragments, in the Han codebase (in the `/research` skill's trust classes and corroboration gate, and in the YAGNI evidence test). The strongest evidence-backed answer is **not** a new ranked-tier framework imported wholesale from medicine or intelligence; those frameworks have well-documented failure modes when their original domain assumptions are broken. The strongest answer is to write a small canonical doc that defines "evidence-based" by naming the structural principles already operating in Han, extract the corroboration-and-no-evidence-labeling rules from `/research` into a shared reference, and treat the source-proximity ordering ("running code > documentation") as a directional heuristic that requires judgment rather than as a strict tier list. The recommendation rests on cross-domain corroborated evidence and on the Han codebase as the current-state anchor; the validator surfaced that a more ambitious "full hierarchy" recommendation overreached its evidence and is rejected. The recommendation is well-corroborated on structure; its scope is deliberately narrow because no Han failure attributable to weak-evidence acceptance has been documented yet.

## Research Results

### Six disciplines, five recurring principles

Medicine, historiography, law, intelligence analysis, journalism, and academic research have all formalized hierarchies of evidence confidence. Five principles appear independently in the majority of these disciplines and are therefore the most robustly corroborated takeaways for a software-engineering practice.

**Principle 1: proximity to the originating event or data beats distance.** Eyewitness testimony beats secondhand report beats hearsay (A9). Primary sources beat secondary sources beat tertiary sources (A10 [single-source], A11, A23). Named on-the-record sources beat anonymous attribution (A15, A16). In software-engineering practice, the analogue is that observed runtime behavior in the actual execution environment outranks documentation of intended behavior (A33, A34, A40); the Pragmatic Programmer states this directly as "Don't assume it — prove it" (A33), and Feathers operationalizes it: when a system goes into production, it becomes its own specification (A34, A40). The principle is cross-domain corroborated; the *specific concrete ordering* it implies for software (production > tests > code > commit messages > docs > blogs > LLM output) is contested and not flowchartable without judgment rules (see V5, V8).

**Principle 2: independent corroboration multiplies credibility; single-source claims are structurally weaker.** GRADE upgrades certainty when independent studies confirm an effect (A3). The Admiralty Code's top credibility rating is reserved for information confirmed by other sources (A6). Historiography establishes probability through agreement among independent sources (A9). Journalism's two-to-three-source rule for anonymous claims (A15, A16) and the SPJ's explicit corroboration obligation (A24) operationalize the principle. The philosophical root, traced to Robert Boyle, frames witnessing as "a collective act" (A22). The principle is the most heavily corroborated of the five — A3, A6, A9, A15, A16, A22, A24 all converge.

**Principle 3: the no-evidence state is a distinct epistemic state, not the bottom of the tier list.** The Admiralty Code names it F-6: reliability and credibility cannot be judged (A6). GRADE distinguishes "very low certainty" from "no evidence" and prescribes an expert-evidence survey method for the latter [single-source: A17, but consistent with A3 on the tier structure]. Historiography accepts secondary-as-working-original when no primary survives, with an explicit weaker label (A9). Law's "case of first impression" triggers analogical reasoning rather than suspension of judgment (A13, A14). Journalism's default in the no-source case is near-silence (A16). The cross-domain pattern is consistent: treating "no evidence" as identical to "weakest tier of evidence" loses signal.

**Principle 4: certainty of evidence and strength of recommendation are separable.** GRADE's central innovation, independently echoed by the legal mandatory-vs-persuasive distinction (A12) and the journalism named-vs-anonymous attribution tiers (A15, A16), is that the quality of underlying evidence and the actionability of decisions derived from it are not the same thing (A3, A4). Conflating them either freezes action when evidence is weak or treats weak-evidence decisions as if they were settled.

**Principle 5: source type, information type, and evidential value are independently evaluated.** The Evidence Explained framework from genealogy formalizes this as Sources → Information → Evidence → Proof, with each axis judged separately (A23). The Admiralty Code's two-axis structure attempts the same separation (A6). A "primary source" can carry secondary information (a document reporting what someone else told its author); a "low-tier source" can carry a corroborated true claim. The principle protects against collapsing source type into a single quality score.

### What software-engineering practice adds

Software-engineering literature does not converge on a single numbered hierarchy. ACM SIGSOFT explicitly rejects a gold-standard tier model for the field (A25 [single-source]). The EBSE lineage (A30, A43, A45) adapts medical systematic-review methodology but acknowledges its findings have not reached practitioners (A44 [single-source, pre-publication]). The practitioner literature adds three software-specific refinements to the cross-domain principles:

- **The passing-test asymmetry.** Dijkstra's foundational limit: tests prove the presence of bugs, not absence (A36). A failing test is stronger evidence than a passing test of the same code (A36, A37). The concrete-ordering version of Principle 1 obscures this — both passing and failing tests would sit at the same tier — so the principle is best read as directional, not as a strict ladder.
- **The reproducibility gate.** Scientific-method debugging (Zeller, A28; delta debugging, A29; UCSD/This Dot Labs writeups, A32, A51) treats a reproducible minimal failure as causally clean evidence and an unreproducible report as a prompt to instrument rather than a fact about the system. "Works on my machine" is the canonical violation.
- **Named software failure modes.** Documentation drift (A52 [single-source]); Stack Overflow copy-paste at 15.4% of 1.3M Android apps containing vulnerable snippets (A46, A47); cargo-cult adoption of patterns whose rationale is not understood (A41); LLM hallucination, where pre-publication evidence shows even modern models have a blind spot when implementation drifts while documentation stays plausible (A49 [single-source, pre-publication]). Each names a class of evidence whose quality cannot be inferred from its surface form.

When two pieces of software-engineering evidence at the same tier disagree, the oracle-problem literature (A39, A42) is the named framework: no algorithmic tie-breaker exists; the human with domain authority is the final oracle. Kaner's eight consistency oracles (A42) — alignment with specification, user expectations, comparable products, prior versions, standards, claims/documentation, general expectations, and purpose — are the implicit framework practitioners already use.

### What Han already has

Three of the five structural principles already operate, in fragments, in the Han codebase:

- The `/research` skill defines **trust classes** that operationalize Principle 5: codebase = trusted current-state anchor, web = outside the trust boundary, provided = operator-supplied with interested-party scrutiny (A55). The trust-class machinery is currently scoped to the `/research` skill alone — it is not inherited by `/investigate`, `/plan-a-feature`, `/iterative-plan-review`, or `/gap-analysis` (V1).
- The `/research` skill defines a **corroboration gate** that operationalizes Principle 2: a web claim that bears on the recommendation and has no independent corroboration is marked single-source and cannot be the sole basis for the recommendation in strict mode (A55, A56). Again, scoped to `/research` and `research-analyst`.
- The `/research` skill defines a **current-state anchor and conflict surfacing rule** that touches Principle 3 and Principle 5: when codebase evidence contradicts web evidence, the conflict is surfaced explicitly and the codebase wins (A55, line 112).
- The YAGNI rule defines **five parallel categories of acceptable evidence** (user-described need, named dependency, production code path, regulatory rule, documented incident or metric) (A53, A54). These are *categories that pass an inclusion test*, not *tiers of confidence*. The YAGNI test answers "is there any evidence at all?" and is silent on "how strong is it?".

What Han does not have is a single canonical statement of these primitives that the rest of the plugin can point at, and Han does not extend the corroboration gate or trust classes to the skills that work with evidence outside the `/research` flow.

### Conflicts surfaced by validation

Two cross-domain claims do not survive scrutiny without qualification. First, the "running code > documentation" ordering, while consistent across the practitioner literature surveyed, is contested in formal-methods, specification-compliance, and regulatory contexts where the specification is the authoritative source against which behavior is judged (V8). The Google SRE book's "symptom-over-cause" framing (A31 [single-source on the implicit ranking]) is about monitoring philosophy, not evidence hierarchy, and using it to support a hard ordering between code and docs is a selective reading (V8). Second, the corroboration gate as defined for web sources does not transfer cleanly to codebase evidence: a single file path at a specific line number is not made unreliable by being a single source; demanding a "second independent code path to confirm" would either be vacuous or reject valid root-cause findings (V9).

## Options to Consider

### O1: Adopt GRADE's four-tier certainty model, adapted

- **What it is:** Verbal certainty tiers (High / Moderate / Low / Very Low) with explicit upgrade and downgrade factors and an expert-evidence survey for the no-evidence case; separates certainty of evidence from strength of recommendation.
- **Trade-offs:** Built for population-level intervention studies; mapping to software is approximate; requires calibrated judgment to assign and adjust tiers; ACM SIGSOFT explicitly rejects gold-standard hierarchies for software engineering (A25). Importing GRADE wholesale into Han would create the labels first and the judgment that calibrates them later, in the wrong order.
- **Rests on:** A3, A4, A5, A17, A25.
- **Evidence status:** corroborated on the GRADE structure (A3, A4, A5); single-source on the explicit rejection-for-software (A25).

### O2: Adopt the Admiralty Code 6x6 two-axis model

- **What it is:** Two independent axes — source reliability (A–F) and information credibility (1–6) — with F-6 as the explicit no-evidence label.
- **Trade-offs:** The two axes are demonstrably not independent in practice; 87% of real ratings cluster on the diagonal (A7). System lacks formal definitions for "authenticity," "trustworthiness," "competency"; poor inter-analyst consistency; no mechanism for combining ratings. Operationalizing it for a Han skill would require training and calibration the plugin's users do not necessarily have.
- **Rests on:** A6, A7, A8.
- **Evidence status:** corroborated on the structure; corroborated on the failure modes (A6 with A7, A8).

### O3: Adopt the historiographical analytical progression

- **What it is:** Sources → Information → Evidence → Proof, with the Bernheim/Langlois-Seignobos conflict-resolution rules layered on top.
- **Trade-offs:** Built for textual analysis; lacks certainty tiers and decision-strength layer; would need to be combined with another framework to bridge from classification to action. Strongest on the principle that source type, information type, and evidential value are independent — but Han's `/research` already operationalizes this via trust classes (A55), so the marginal addition is small.
- **Rests on:** A9, A23.
- **Evidence status:** corroborated on the framework; the application to software is reasoning.

### O4: Adopt the academic primary/secondary/tertiary tiered model

- **What it is:** Three tiers of source type — firsthand, analysis of firsthand, compilation of analysis — applied to software evidence (production logs primary, post-mortems secondary, blog posts tertiary).
- **Trade-offs:** Low cognitive overhead and easy to teach; no upgrade/downgrade logic; no no-evidence handling; collapses source type with information quality, which the Evidence Explained framework (A23) shows is a flaw — a "primary source" can carry secondary information, and vice versa.
- **Rests on:** A10 [single-source caveated — search summary], A11, A23.
- **Evidence status:** corroborated on the academic tier scheme; the limitation is corroborated by A23.

### O5: Build a full composite framework drawing from all hierarchies

- **What it is:** Source-type categorization (from academic and historiography) + corroboration rules (from journalism and EBM) + four certainty tiers (from GRADE) + certainty/recommendation separation + explicit no-evidence label (from Admiralty/GRADE) + provenance discipline (from journalism).
- **Trade-offs:** Design overhead is high; risk of incoherence when component principles conflict (e.g., GRADE's study-design starting points have no natural mapping to the Admiralty's source-reliability axis); risk that teams simplify back to one principle and lose the composite's benefit. As proposed, the concrete tier list for Principle 1 is not flowchartable without additional judgment rules that the synthesis did not supply (V5).
- **Rests on:** A3, A4, A5, A6, A9, A10, A11, A13, A14, A16, A23, A24.
- **Evidence status:** the structural principles are corroborated; the composition decision is reasoning.

### O6: Do nothing — keep YAGNI's five parallel categories as the only evidence test

- **What it is:** Leave the term "evidence-based" undefined as a quality dimension; rely on YAGNI's five parallel categories of acceptable evidence (A53, A54) to gate inclusion of items, and accept that "how strong is the evidence" is judged ad hoc by skills and agents.
- **Trade-offs:** Honors Han's own YAGNI rule applied to itself: the proposal in issue #19 does not cite a documented Han failure attributable to weak-evidence acceptance, only the reporter's observation that the term lacks canonical definition (V2). No Han skill has produced a measurably bad output because it could not distinguish strong from weak evidence. By Han's own evidence test (A53, line 28), the absence of a forcing function suggests deferral. Risk: the term continues to drift in usage as skills are added; eventually a real failure surfaces that this work could have prevented.
- **Rests on:** A53, A54; V2.
- **Evidence status:** corroborated by the Han codebase and the validator's V2 finding.

### O7: Extract `/research`'s existing trust-class and corroboration rules into a shared reference, without adding a new evidence-quality tier

- **What it is:** Create `docs/evidence.md` and `plugin/references/evidence-rule.md` (paralleling the YAGNI pair) that define "evidence-based" by canonizing what `/research` already operationalizes: trust classes (codebase / provided / web), the corroboration gate (single-source caveat), the current-state anchor on conflict, and an explicit no-evidence label. Cite these from skills that currently use "evidence-based" without referencing the primitives (`/investigate`, `/plan-a-feature`, `/iterative-plan-review`, `/gap-analysis`). Treat Principle 1's source-proximity ordering as a directional heuristic in the doc, not a strict ladder — note the passing-test asymmetry (A36, A37) and the formal-methods/spec-compliance inversion (V8) so the heuristic is honest about its scope. Do not import GRADE labels or the Admiralty axes. Scope the corroboration gate's extension carefully — the gate as currently defined applies to web sources bearing on a recommendation (V9); extending it to codebase evidence in `/investigate` requires an adaptation step the doc would call out as future work, not commit.
- **Trade-offs:** Smaller in scope than O5; does not import the contested portions of any single hierarchy; relies on principles already operating in Han, so it formalizes existing behavior rather than introducing parallel machinery. Does not give skills a four-tier verbal label they can attach to evidence. Defers the trickier scope work (corroboration in codebase contexts) until that question has been forced. Risk: the doc may look thinner than the reporter expected, since it does not produce an ordered tier list of evidence types.
- **Rests on:** A53, A54, A55, A56, A57, A58, A59 (codebase), plus the cross-domain principles A3, A6, A9, A15, A16, A22, A23, A24.
- **Evidence status:** corroborated by both the cross-domain prior art and the Han codebase as the current-state anchor.

## Recommendation

- **Recommendation:** **O7 — extract the existing `/research` primitives into a shared canonical pair, cite them from the skills that need them, frame Principle 1 as a directional heuristic, and defer the hard scope-extension work until a real Han failure forces it.**

  The reporter's request (a canonical "evidence-based" doc paralleling YAGNI) is satisfied by writing the pair. The deeper "hierarchy of confidence" goal is satisfied by canonizing the corroboration gate and the no-evidence label that `/research` already enforces, plus naming the proximity-to-origin principle as a directional heuristic. The framework should not import GRADE's four labels (no calibrated judgment exists in Han to use them; A25 explicitly rejects gold-standard hierarchies for software) and should not introduce the Admiralty axes (their independence breaks in practice; A7). It should not commit to a strict ordering of "running code > tests > codebase > commits > docs > blogs > LLM output" because the prior art does not corroborate the *strict* ordering (V5, V8) and because doing so without judgment rules will produce inconsistent outputs across skill invocations.

- **Evidence basis:**
  - **Corroborated:** that the proximity-to-origin principle is real and cross-domain (A9, A10, A11, A15, A16, A23, A33, A34, A40); that corroboration multiplies credibility (A3, A6, A9, A15, A16, A22, A24); that the no-evidence state must be labeled rather than collapsed into "very weak" (A6, A9, A13, A14, A16, A17); that the Han codebase already operates three of these principles in `/research` (A55, A56) and that the YAGNI rule (A53, A54) provides the existing pattern to mirror.
  - **Single-source (caveated):** GRADE's specific expert-evidence survey method for the no-evidence case (A17); ACM SIGSOFT's explicit rejection of gold-standard hierarchies for software engineering (A25); Charity Majors / Honeycomb on production observation as highest-fidelity evidence (A35, interested party); the LLM-trust-allocation pre-publication paper (A49); the Brookbush recency-bias position (A21); the National Academies combinatorial prescription (A48); the reqproof code-spec-requirement framing (A52); the Google SRE symptom-over-cause framing as an evidence ranking specifically (A31); the three-tier debugging ranking from This Dot Labs (A32). The recommendation does not rest solely on any of these single sources.
  - **Rejected:** the more ambitious framing in the synthesis draft — that Han should adopt a full composite (O5) with a strict source-proximity ordering — is rejected on validator findings V1, V2, V5, V8, V9.
  - **Reasoning step that does not appear in any artifact:** that the marginal value of a four-tier verbal label (High/Moderate/Low/Very Low) is below the cost of importing it into Han, when Han has no calibrated judgment to apply the labels consistently. This is a design judgment, not a sourced claim; the recommendation is robust without it (O5 remains a valid alternative if the team disagrees).

## Validation

### V1: The "corroboration gate already operational" claim was false at codebase scope

- **Strategy:** Challenge the Evidence; Challenge the Recommendation (codebase fit).
- **Investigation:** The validator read `/plugin/skills/investigate/SKILL.md` and `/plugin/agents/evidence-based-investigator.md` in full; neither contains corroboration-gate, single-source-caveat, or trust-class language. The gate exists only in `/research` and `research-analyst`.
- **Result:** Refuted (for the broader scope). Confirmed that the gate exists in `/research`.
- **Impact:** The synthesis's claim that Principle 2 was an "extension" of something already broadly operational in Han was inaccurate. The recommendation language was tightened: extending the gate to `/investigate`, `/plan-a-feature`, `/iterative-plan-review`, and `/gap-analysis` is new work, not incremental extension, and the recommendation now defers committing to that extension until the adaptation is specified.

### V2: O6 (do nothing) was strawmanned against Han's own YAGNI test

- **Strategy:** Challenge the Options Framing; Challenge the Recommendation (bias).
- **Investigation:** The synthesis cited no concrete Han skill failure caused by absence of evidence-quality tiers; no production-attributable bug from weak-evidence acceptance; no Han user complaint. By Han's own YAGNI evidence test (A53, line 28), this is the YAGNI deferral case.
- **Result:** Refuted.
- **Impact:** O6 is now an honestly-framed option. The recommendation was rewritten to acknowledge the absence of a forcing function and to narrow scope to writing the canonical pair while deferring the more ambitious scope extension.

### V3: A35 (Charity Majors/Honeycomb) and A40 (Feathers summary) inflated software-engineering corroboration

- **Strategy:** Challenge the Evidence (interested-party weight).
- **Investigation:** A40 is a summary of A34 (Feathers), not an independent source. A35 is interested-party (Honeycomb). The software-engineering leg of Principle 1 (production > docs) therefore rests on A33 and A34 — two practitioner books — plus a vendor source and a non-independent summary. A25 (ACM SIGSOFT) is itself single-source but is treated as decisive against GRADE, an asymmetric treatment.
- **Result:** Partially Refuted.
- **Impact:** The synthesis's claim of "four independent software-engineering corroborators" was deflated to two. The recommendation now explicitly notes the software-engineering leg rests on a narrower base than the cross-domain leg, and Principle 1 is framed as directional rather than empirically dominant.

### V4: A44 and A49 are pre-publication; A49 was the sole motivation for Han-specific Principle-3 need

- **Strategy:** Challenge the Evidence (provenance and replication).
- **Investigation:** A44 (ICSE 2026 vision paper) is pre-publication and not load-bearing for the recommendation itself. A49 (arXiv 2604.03447) is pre-publication, unreplicated, and was the primary citation for "LLM hallucination as a documented failure mode in Han's relevant context."
- **Result:** Partially Refuted.
- **Impact:** A44 was retained as background only. A49 was kept but the LLM-hallucination claim it supports is now marked [single-source, pre-publication], and the recommendation no longer leans on it as the Han-specific motivator for Principle 3 — the historical/medicine corroboration carries the principle.

### V5: The concrete proximity-to-origin tier ordering is not flowchartable

- **Strategy:** Challenge the Recommendation (practical applicability).
- **Investigation:** Splitting "codebase source" from "maintainer commit messages" requires a judgment call not currently defined in Han. Passing tests and failing tests would sit at the same tier in the proposed ordering, but A36 and A37 establish they are asymmetric in evidence weight. A skill applying the ordering would face immediate underdetermination at the first tier boundary.
- **Result:** Refuted.
- **Impact:** The recommendation now treats Principle 1 as a directional heuristic, not a strict ladder. The canonical doc should describe proximity-to-origin as a principle that requires judgment, name the passing-test asymmetry, and refuse to commit to a numbered tier ordering until concrete decision rules exist.

### V6: A10 (search-summary only) was counted as a corroboration node

- **Strategy:** Challenge the Evidence-Gathering Integrity.
- **Investigation:** A10 was collected via search summary, never directly fetched. By the `/research` skill's own rule (A55, line 110), this is the single-source case. Counting it as a corroboration node violates the rule the proposal would enshrine.
- **Result:** Partially Refuted.
- **Impact:** A10's evidence status is now explicitly [single-source caveated]. A9 and A11 carry the historiographical and academic-tier claims; A10 does not. Evidence density in the registry is slightly lower than the draft implied.

### V7: A minimum-viable option (O7) was missing from the options set

- **Strategy:** Challenge the Options Framing.
- **Investigation:** The synthesis presented O6 (do nothing) and O5 (full composite) as the bracketing options, creating a false dichotomy that steered toward O5. A minimal extension — share `/research`'s existing primitives without a new evidence-quality tier layer — was not surfaced.
- **Result:** Refuted.
- **Impact:** O7 was added to the options list and became the recommendation. The recommendation now sits between O6 (do nothing) and O5 (full composite) on a defensible evidence basis.

### V8: The recommendation reproduced the reporter's framing without surfacing counter-evidence

- **Strategy:** Challenge the Recommendation (bias).
- **Investigation:** The reporter named "running code > documentation" as an example, and Principle 1 as originally framed reproduced that ordering exactly. The synthesis cited no prior art for the formal-methods or specification-compliance positions where documentation is the authoritative source. A31 (Google SRE) was selectively read.
- **Result:** Refuted.
- **Impact:** Principle 1 is now explicitly framed as directional, with named conditions under which it inverts (formal-methods contexts, specification compliance, regulatory contexts where the spec is the legally binding artifact).

### V9: The corroboration gate does not transfer cleanly from web evidence to codebase evidence

- **Strategy:** Challenge the Recommendation (codebase fit).
- **Investigation:** The corroboration gate as defined applies to web sources bearing on a recommendation. A single file path at a specific line number is not unreliable for being a single source; demanding "a second independent code path to confirm" would either be vacuous (the file path is itself a second "source") or break valid single-file root-cause findings.
- **Result:** Refuted.
- **Impact:** The recommendation now scopes the corroboration-gate extension to web-sourced claims only, and treats the codebase-evidence adaptation as deferred work for whichever skill needs it (likely `/investigate`), not as something to commit in the canonical doc.

### Adjustments Made

The draft recommendation was O5 (full composite, three principles operationalized with a concrete tier ordering). It was rewritten to O7 (minimum-viable extension of `/research`'s existing primitives, with Principle 1 as a directional heuristic and the corroboration-gate scope-extension deferred). O6 was added to the options list and honestly framed. A10's evidence status was downgraded. A49's load-bearing role was removed. Principle 1's strict-ordering claim was withdrawn and replaced with a directional formulation.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  1. No documented Han failure attributable to weak-evidence acceptance has been cited (V2). By Han's own YAGNI rule, the proposal itself is on thin ice; O6 (do nothing) remains a defensible position and the recommendation is in part a concession to the reporter's request rather than a forced response to an observed failure.
  2. The corroboration-gate extension to codebase contexts is deferred (V9). When that work is forced, the adaptation rule will need to be specified, and the canonical doc may need to be amended.
  3. The proximity-to-origin principle as a directional heuristic does not give a skill a deterministic answer when sources of different proximities disagree (V5). The oracle-problem literature (A39, A42) is the named framework, but it explicitly says no algorithmic tie-breaker exists — the human is the final oracle. The doc should make this honest.
  4. A35 (Honeycomb, interested party), A48 (National Academies, single source), and the pre-publication sources A44 and A49 do not carry the recommendation, but they are present in the registry. A reader should not be surprised by their evidence-status labels.
  5. The cross-domain principles were surveyed via Wikipedia, encyclopedia entries, and one major handbook per discipline (CDC for GRADE, SANS for Admiralty, USC Law for legal authority). Deeper scholarship in any single discipline could surface refinements the report missed.

## Artifacts

### A1: Wikipedia — Hierarchy of Evidence

- **Link / location:** https://en.wikipedia.org/wiki/Hierarchy_of_evidence
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Surveys the evidence pyramid as used in medicine, naming several competing sub-frameworks (Guyatt/Sackett 1995, OCEBM 2011, GRADE). Notes that over 195 published hierarchies exist. Documents scholarly criticism (Stegenga, Cartwright and Worrall, Borgerson, Concato, Blunt). All hierarchies share the principle of reducing systematic bias.
- **Evidence status:** corroborated by A3, A4, A5 on tier structure; criticism positions corroborated by A2

### A2: PMC — "Hierarchy of EBM pyramid: classification beyond ranking"

- **Link / location:** https://pmc.ncbi.nlm.nih.gov/articles/PMC4732774/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Argues that the pyramid's levels should function as classification tools, not as a strict ranking. Claims higher-level designs are impossible without lower-level studies first.
- **Evidence status:** corroborated by A1 on the pyramid; unique on the anti-ranking argument

### A3: CDC ACIP GRADE Handbook — Chapter 7

- **Link / location:** https://www.cdc.gov/acip-grade-handbook/hcp/chapter-7-grade-criteria-determining-certainty-of-evidence/index.html
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Defines GRADE's four certainty tiers (High, Moderate, Low, Very Low). RCTs start at High; non-randomized studies start at Low. Five downgrade factors; three upgrade factors for non-randomized evidence only.
- **Evidence status:** corroborated by A4, A5, A17

### A4: PMC — "The hierarchy of evidence: Levels and grades of recommendation"

- **Link / location:** https://pmc.ncbi.nlm.nih.gov/articles/PMC2981887/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Describes the study-design pyramid; distinguishes "levels of evidence" (design quality) from "grades of recommendation" (actionability). Integration of evidence quality, harms/benefits, setting, and population required for recommendations.
- **Evidence status:** corroborated by A1, A3

### A5: PMC — "Extending an evidence hierarchy to include topics other than treatment"

- **Link / location:** https://pmc.ncbi.nlm.nih.gov/articles/PMC2700132/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Australia's NHMRC revision of Level I–IV to cover diagnostic, prognostic, aetiologic, screening questions. Establishes that one hierarchy cannot serve all question types without adaptation.
- **Evidence status:** corroborated by A1, A3, A4

### A6: Wikipedia — Admiralty Code

- **Link / location:** https://en.wikipedia.org/wiki/Admiralty_code
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** NATO 6x6 two-axis system: source reliability (A–F) and information credibility (1–6). F-6 is the explicit no-evidence label.
- **Evidence status:** corroborated by A7, A8

### A7: Blockint — Critical Review of the Admiralty Code

- **Link / location:** https://www.blockint.nl/intel-analysis/critical-review-of-the-admiralty-code/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Documents failure modes: 87% of ratings cluster on the diagonal (axes not independent); B3 vs C2 ambiguity; lacks formal definitions; structurally amplifies confirmation bias.
- **Evidence status:** corroborated by A8 on the structure; unique in the critical analysis

### A8: SANS Institute — Admiralty System in Cyber Threat Intelligence

- **Link / location:** https://www.sans.org/blog/enhance-your-cyber-threat-intelligence-with-the-admiralty-system/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Applies Admiralty to CTI; documents that actors can shift ratings F6 to B2 in days; data overload makes consistent manual rating difficult.
- **Evidence status:** corroborated by A6, A7

### A9: Wikipedia — Historical Method

- **Link / location:** https://en.wikipedia.org/wiki/Historical_method
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Bernheim/Langlois-Seignobos seven-step source criticism. Eyewitness preferred; independent agreement multiplies credibility; secondary-as-working-original when primary lost.
- **Evidence status:** corroborated by A23; unique on the specific seven rules

### A10: history.berkeley.edu — Primary/Secondary/Tertiary Sources in History

- **Link / location:** https://history.berkeley.edu/sites/default/files/history_source_types.pdf
- **Retrieved:** 2026-05-28 (via search summary, not directly fetched)
- **Trust class:** web
- **Summary:** Search-result confirmation that primary sources are firsthand evidence, secondary analyze primary, tertiary compile secondary.
- **Evidence status:** single source (caveated — search summary only)

### A11: Ohio State Pressbooks — Primary, Secondary, and Tertiary Sources

- **Link / location:** https://ohiostate.pressbooks.pub/choosingsources/chapter/primary-secondary-tertiary-sources/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Academic source-tier definitions; tertiary sources generally not acceptable as cited sources.
- **Evidence status:** corroborated by A23

### A12: USC Law — Weight of Authority

- **Link / location:** https://guides.law.sc.edu/LRAWSpring/LRAW/hierarchyofauthority
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Primary authority (law itself) vs secondary (explanation, never binding). Within primary, mandatory vs persuasive within jurisdiction.
- **Evidence status:** corroborated by A13, A14

### A13: Cornell LII — First Impression

- **Link / location:** https://www.law.cornell.edu/wex/first_impression
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Cases with no governing precedent; courts seek guidance from other jurisdictions or reason by analogy.
- **Evidence status:** corroborated by A14

### A14: Wikipedia — Analogy (law)

- **Link / location:** https://en.wikipedia.org/wiki/Analogy_(law)
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** When a gap exists in law and no norm governs, judges fill it by analogy to relevantly similar cases.
- **Evidence status:** corroborated by A13

### A15: Wikipedia — Source (journalism)

- **Link / location:** https://en.wikipedia.org/wiki/Source_(journalism)
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Attribution tiers from on-the-record through deep background. Two-source rule for anonymous claims in most outlets. Names canonical single-source failure cases (Newsweek Qur'an retraction, OJ Simpson coverage).
- **Evidence status:** corroborated by A16, A24

### A16: AALEP / Reuters — Essentials of Sourcing for Journalists

- **Link / location:** https://www.aalep.eu/essentials-sourcing-journalists
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Named sources rank highest; anonymous sub-tiers (authoritative, official, designated); vague "informed sources" unacceptable; two-to-three-source rule for anonymous.
- **Evidence status:** corroborated by A15

### A17: J. Clinical Epidemiology — GRADE notes: No Evidence

- **Link / location:** https://www.jclinepi.com/article/S0895-4356(21)00069-X/fulltext
- **Retrieved:** 2026-05-28 (page returned 403; content from search summary)
- **Trust class:** web
- **Summary:** GRADE handles no-published-evidence via expert-evidence survey collecting observational data, not opinions. Expert opinion not scored. Strong recommendations discouraged at Low/Very Low certainty.
- **Evidence status:** single source (caveated on method); corroborated by A3 on tier structure

### A18: Wikipedia — Information Laundering

- **Link / location:** https://en.wikipedia.org/wiki/Information_laundering
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Surfacing unverified content into mainstream legitimacy; citation laundering; platform amplification; citation farms.
- **Evidence status:** corroborated by A19

### A19: Daily Journal — Citation Laundering in Law

- **Link / location:** https://www.dailyjournal.com/article/390260-citation-laundering-how-fake-cases-gain-legitimacy-by-passing-through-real-legal-documents
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Fabricated legal authority entering legitimate documents and acquiring institutional credibility through downstream re-citation.
- **Evidence status:** corroborated by A18

### A20: Globalsecurity.org — Intelligence Analytical Biases

- **Link / location:** https://www.globalsecurity.org/intell/ops/bias.htm
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Named biases: confirmation, mirror imaging, anchoring, groupthink, belief perseverance, layering, overconfidence.
- **Evidence status:** single source on the full named list

### A21: Brookbush Institute — New Research Is Not Better Research

- **Link / location:** https://brookbushinstitute.com/articles/new-research-is-not-better-research
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Recency-bias institutional failure modes; argues quality is judged by controls and replication, not timing.
- **Evidence status:** single source on the named institutional failures

### A22: Stanford Encyclopedia of Philosophy — Evidence

- **Link / location:** https://plato.stanford.edu/entries/evidence/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Evidence enhances justification; intersubjective accessibility essential; Boyle's "collective act of witnessing."
- **Evidence status:** corroborated by A9 on corroboration philosophy

### A23: Evidence Explained — QuickLesson 2

- **Link / location:** https://www.evidenceexplained.com/content/quicklesson-2-sources-vs-information-vs-evidence-vs-proof
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Sources → Information → Evidence → Proof; source type, information type, and evidential value are independently evaluated.
- **Evidence status:** corroborated by A9, A11

### A24: SPJ — Code of Ethics

- **Link / location:** https://www.spj.org/spj-code-of-ethics/
- **Retrieved:** 2026-05-28 (page returned 403; content from search summary)
- **Trust class:** web
- **Summary:** Corroboration or rebuttal required; provenance tracing obligation; "cannot hide behind the excuse that the source told me."
- **Evidence status:** corroborated by A15, A16

### A25: ACM SIGSOFT — Empirical Standards for Software Engineering

- **Link / location:** https://www2.sigsoft.org/EmpiricalStandards/about/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Method-specific standards; explicitly does not define tiers of evidence quality; does not privilege positivism.
- **Evidence status:** single source on the software-specific rejection

### A26: Making Software (Oram & Wilson, O'Reilly 2010)

- **Link / location:** https://books.google.com/books/about/Making_Software.html?id=DxuGi5h2-HEC
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Empirical findings should supersede intuition; establishes "evidence is not proof."
- **Evidence status:** corroborated by A27, A43

### A27: Ybrikman review of Making Software

- **Link / location:** https://www.ybrikman.com/blog/2015/03/23/making-software/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Independent review confirming Making Software's stance: "convincing evidence motivates change."
- **Evidence status:** corroborated by A26

### A28: Zeller — Why Programs Fail

- **Link / location:** https://www.oreilly.com/library/view/why-programs-fail/9780123745156/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Scientific-method debugging: observe, hypothesize, predict, experiment. Reproducible failure is foundation of valid evidence.
- **Evidence status:** corroborated by A29, A51

### A29: debuggingbook.org — Delta Debugger

- **Link / location:** https://www.debuggingbook.org/html/DeltaDebugger.html
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** 1-minimality as causally clean evidence; requires deterministic reproduction.
- **Evidence status:** corroborated by A28

### A30: Kitchenham & Charters — EBSE Guidelines

- **Link / location:** https://www.scirp.org/reference/ReferencesPapers?ReferenceID=1555797
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Foundational EBSE document adapting EBM systematic-review methodology to software engineering; descending authority from systematic reviews to expert opinion to practitioner anecdote.
- **Evidence status:** corroborated by A43, A45

### A31: Google SRE Book — Monitoring Distributed Systems

- **Link / location:** https://sre.google/sre-book/monitoring-distributed-systems/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Symptom-oriented signals over cause-oriented; four golden signals; white-box vs black-box monitoring.
- **Evidence status:** single source on the implicit symptom > cause ranking as an evidence claim specifically

### A32: This Dot Labs — Scientific Mindset in Debugging Part 2

- **Link / location:** https://www.thisdot.co/blog/the-importance-of-a-scientific-mindset-in-software-engineering-part-2
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Three-tier debugging evidence ranking: logs/traces/code history > docs/issues/SO > indirect; cross-referencing required.
- **Evidence status:** single source; consistent with A28, A31

### A33: Pragmatic Programmer — Tips

- **Link / location:** https://pragprog.com/tips/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** "Don't Assume It — Prove It"; "Read the Damn Error Message"; time code in target environment.
- **Evidence status:** corroborated by A34

### A34: Feathers — Characterization Testing

- **Link / location:** https://michaelfeathers.silvrback.com/characterization-testing
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** "When a system goes into production, it becomes its own specification"; observed behavior > intent for legacy.
- **Evidence status:** corroborated by A40 (summary, not independent)

### A35: Charity Majors — Observability category

- **Link / location:** https://charity.wtf/category/observability/
- **Retrieved:** 2026-05-28
- **Trust class:** web (interested party — Honeycomb)
- **Summary:** Production with rich context is highest-fidelity evidence; tests cannot catch non-RFC requests.
- **Evidence status:** single source, interested party

### A36: Dijkstra — EWD303

- **Link / location:** https://www.cs.utexas.edu/~EWD/transcriptions/EWD03xx/EWD303.html
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Testing shows the presence, not the absence, of bugs.
- **Evidence status:** corroborated by A37

### A37: Hillel Wayne — Testing Can Show the Presence of Bugs

- **Link / location:** https://buttondown.com/hillelwayne/archive/testing-can-show-the-presence-of-bugs-but-not-the/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Modern treatment of Dijkstra's limit; detection > absence inference; defense in depth.
- **Evidence status:** corroborated by A36, A38

### A38: Hillel Wayne — Business Case for Formal Methods

- **Link / location:** https://www.hillelwayne.com/post/business-case-formal-methods/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Three-layer model: formal specification (design-level), testing (implementation-level), production observation (actual user states).
- **Evidence status:** corroborated by A37

### A39: Barr, Harman et al. — The Oracle Problem in Software Testing (IEEE TSE 2015)

- **Link / location:** https://ieeexplore.ieee.org/document/6963470/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Academic survey; when no automated oracle exists, human is the final oracle drawing on informal specifications and domain knowledge.
- **Evidence status:** corroborated by A42

### A40: understandlegacycode.com — Key Points of Working Effectively with Legacy Code

- **Link / location:** https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Third-party summary of Feathers; "what the code actually does is more important than what it should do."
- **Evidence status:** summary of A34 (not independent)

### A41: Wikipedia — Cargo Cult Programming

- **Link / location:** https://en.wikipedia.org/wiki/Cargo_cult_programming
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Defines cargo-cult programming as applying patterns without evidence; McConnell's framing on imitating practices without understanding reasons.
- **Evidence status:** corroborated by secondary sources

### A42: Kaner — Oracle Problem and Teaching of Software Testing

- **Link / location:** https://kaner.com/?p=190
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Oracles are heuristic, not definitive; references Bach and Bolton's eight consistency categories.
- **Evidence status:** corroborated by A39

### A43: pasemes.github.io — What Is Evidence-Based Practice?

- **Link / location:** https://pasemes.github.io/blog/what-is-evidence-based-practice/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Accessible EBSE description; practitioners resist research-over-experience hierarchy; RCT gold standard does not translate to software.
- **Evidence status:** corroborated by A30, A45

### A44: Bridging the Gap — ICSE 2026 vision paper

- **Link / location:** https://arxiv.org/abs/2602.08015
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Proposes adapting health-science Evidence to Decision frameworks; systematic-review findings not reaching practitioners after 20+ years.
- **Evidence status:** single source (pre-publication)

### A45: Seeking Enlightenment EBP — arXiv 2403.16827

- **Link / location:** https://arxiv.org/html/2403.16827v1
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** EBP applied to research software engineering team; EBP cannot replace professional experience; spectrum from informal search to systematic review.
- **Evidence status:** corroborated by A30, A43

### A46: Stack Overflow Considered Harmful (IEEE S&P 2017)

- **Link / location:** https://www.ieee-security.org/TC/SP2017/papers/7.pdf
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** 15.4% of 1.3M Android apps contain vulnerable Stack Overflow snippets; 19.8% of highly reputable contributors rarely update answers.
- **Evidence status:** corroborated by A47

### A47: Stack Overflow Blog — Preventing Security Weaknesses

- **Link / location:** https://stackoverflow.blog/2019/12/02/preventing-the-top-security-weaknesses-found-in-stack-overflow-code-snippets/
- **Retrieved:** 2026-05-28
- **Trust class:** web (interested party — Stack Overflow itself)
- **Summary:** Stack Overflow acknowledges vulnerable snippets propagated to GitHub projects.
- **Evidence status:** corroborated by A46; interested party

### A48: National Academies — Software for Dependable Systems Ch 6

- **Link / location:** https://www.nationalacademies.org/read/11923/chapter/6
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Testing alone insufficient; process adherence insufficient; dependability cases must combine formal proofs, informal reasoning, and mechanical inference.
- **Evidence status:** single source on the combinatorial prescription

### A49: Measuring LLM Trust Allocation — arXiv 2604.03447

- **Link / location:** https://arxiv.org/pdf/2604.03447
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Models detect explicit documentation bugs (67–94%) and Javadoc/implementation contradictions (50–91%) but have a systematic blind spot when implementation drifts while documentation stays plausible.
- **Evidence status:** single source (pre-publication, unreplicated)

### A50: Keunwoo Lee — review of Accelerate

- **Link / location:** https://keunwoo.com/notes/accelerate-devops/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Independent critique; survey methodology sits low on empirical evidence hierarchy; identifies halo effects and circular reasoning in claims.
- **Evidence status:** single source (one reviewer)

### A51: This Dot Labs / UCSD — Scientific Debugging Method

- **Link / location:** https://cseweb.ucsd.edu/classes/wi10/cse15L/c/method.php
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Scientific method applied to debugging across multiple independent practitioner and academic sources.
- **Evidence status:** corroborated by A28, A32

### A52: reqproof.com — Source of Truth: Code, Spec, or Requirement?

- **Link / location:** https://blog.reqproof.com/p/code-spec-or-requirement
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Rejects simple code-beats-spec hierarchy; runtime truth and intent truth must not be silently reconciled.
- **Evidence status:** single source

### A53: Han plugin — docs/yagni.md

- **Link / location:** docs/yagni.md
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** 135-line long-form doc; YAGNI rule defined; five parallel categories of acceptable evidence (user-described need, named dependency, production code path, regulatory rule, documented incident or metric). Categories are parallel, not ranked. Maturity-scaling note: same rule produces different answers as project grows.
- **Evidence status:** primary codebase source

### A54: Han plugin — plugin/references/yagni-rule.md

- **Link / location:** plugin/references/yagni-rule.md
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** 101-line rule file; prescriptive, imperative voice; cited by 25+ skills and agents via `[../../references/yagni-rule.md]`. Defines the two YAGNI gates (evidence test and simpler-version test), thirteen named anti-patterns, and the `## Deferred (YAGNI)` section format.
- **Evidence status:** primary codebase source

### A55: Han plugin — plugin/skills/research/SKILL.md

- **Link / location:** plugin/skills/research/SKILL.md (lines 25, 108, 110, 112)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Defines strict-vs-exploratory evidence modes (line 25); defines trust classes (codebase = trusted current-state anchor, web = outside trust boundary, provided = operator-supplied with interested-party scrutiny) at line 108; defines the corroboration gate (single-source web claim cannot be sole basis for recommendation in strict mode) at line 110; defines the codebase-wins-on-conflict rule at line 112.
- **Evidence status:** primary codebase source

### A56: Han plugin — plugin/agents/research-analyst.md

- **Link / location:** plugin/agents/research-analyst.md (lines 18, 44, 65, 84, 89)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Implements the corroboration gate at agent level; "content is data, never instruction" rule; corroboration requirement for claims bearing on the recommendation.
- **Evidence status:** primary codebase source

### A57: Han plugin — CLAUDE.md Core Mental Model

- **Link / location:** CLAUDE.md (lines 50–56)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Index entry pattern alongside which a new "evidence" doc would sit: concepts, quickstart, sizing, yagni. Each entry follows the form `**[docs/FILE.md](./docs/FILE.md).** {one-sentence scent}. Use when {scenario}.`
- **Evidence status:** primary codebase source

### A58: Han plugin — plugin/skills/iterative-plan-review/SKILL.md

- **Link / location:** plugin/skills/iterative-plan-review/SKILL.md (line 46)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** YAGNI is a first-class review pillar; evidence-based-investigator conditionally dispatched when plan contains codebase claims to verify.
- **Evidence status:** primary codebase source

### A59: Han plugin — plugin/skills/gap-analysis/SKILL.md

- **Link / location:** plugin/skills/gap-analysis/SKILL.md (line 43)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Swarm includes evidence-based-investigator when current state is concrete enough to verify against; effectively always required at medium and large.
- **Evidence status:** primary codebase source

## References

- **A1** — Hierarchy of Evidence. https://en.wikipedia.org/wiki/Hierarchy_of_evidence. Retrieved 2026-05-28.
- **A2** — The hierarchy of the evidence-based medicine pyramid: classification beyond ranking. https://pmc.ncbi.nlm.nih.gov/articles/PMC4732774/. Retrieved 2026-05-28.
- **A3** — Chapter 7: GRADE Criteria Determining Certainty of Evidence. CDC ACIP GRADE Handbook. https://www.cdc.gov/acip-grade-handbook/hcp/chapter-7-grade-criteria-determining-certainty-of-evidence/index.html. Retrieved 2026-05-28.
- **A4** — The hierarchy of evidence: Levels and grades of recommendation. https://pmc.ncbi.nlm.nih.gov/articles/PMC2981887/. Retrieved 2026-05-28.
- **A5** — Extending an evidence hierarchy to include topics other than treatment. https://pmc.ncbi.nlm.nih.gov/articles/PMC2700132/. Retrieved 2026-05-28.
- **A6** — Admiralty code. https://en.wikipedia.org/wiki/Admiralty_code. Retrieved 2026-05-28.
- **A7** — Critical review of the Admiralty Code. https://www.blockint.nl/intel-analysis/critical-review-of-the-admiralty-code/. Retrieved 2026-05-28.
- **A8** — Enhance your Cyber Threat Intelligence with the Admiralty System. SANS Institute. https://www.sans.org/blog/enhance-your-cyber-threat-intelligence-with-the-admiralty-system/. Retrieved 2026-05-28.
- **A9** — Historical method. https://en.wikipedia.org/wiki/Historical_method. Retrieved 2026-05-28.
- **A10** — Primary, Secondary, and Tertiary Sources in History. https://history.berkeley.edu/sites/default/files/history_source_types.pdf. Retrieved 2026-05-28 (search summary only).
- **A11** — Primary, Secondary, and Tertiary Sources. Ohio State Pressbooks. https://ohiostate.pressbooks.pub/choosingsources/chapter/primary-secondary-tertiary-sources/. Retrieved 2026-05-28.
- **A12** — Weight of Authority — LRAW Research Spring 2026. University of South Carolina. https://guides.law.sc.edu/LRAWSpring/LRAW/hierarchyofauthority. Retrieved 2026-05-28.
- **A13** — first impression. Legal Information Institute. https://www.law.cornell.edu/wex/first_impression. Retrieved 2026-05-28.
- **A14** — Analogy (law). https://en.wikipedia.org/wiki/Analogy_(law). Retrieved 2026-05-28.
- **A15** — Source (journalism). https://en.wikipedia.org/wiki/Source_(journalism). Retrieved 2026-05-28.
- **A16** — The Essentials of Sourcing for Journalists. AALEP. https://www.aalep.eu/essentials-sourcing-journalists. Retrieved 2026-05-28.
- **A17** — GRADE notes: How to use GRADE when there is "no" evidence. Journal of Clinical Epidemiology. https://www.jclinepi.com/article/S0895-4356(21)00069-X/fulltext. Retrieved 2026-05-28.
- **A18** — Information laundering. https://en.wikipedia.org/wiki/Information_laundering. Retrieved 2026-05-28.
- **A19** — Citation Laundering: How Fake Cases Gain Legitimacy. Daily Journal. https://www.dailyjournal.com/article/390260-citation-laundering-how-fake-cases-gain-legitimacy-by-passing-through-real-legal-documents. Retrieved 2026-05-28.
- **A20** — Intelligence Analytical Biases. Globalsecurity.org. https://www.globalsecurity.org/intell/ops/bias.htm. Retrieved 2026-05-28.
- **A21** — New Research is NOT Better Research. Brookbush Institute. https://brookbushinstitute.com/articles/new-research-is-not-better-research. Retrieved 2026-05-28.
- **A22** — Evidence. Stanford Encyclopedia of Philosophy. https://plato.stanford.edu/entries/evidence/. Retrieved 2026-05-28.
- **A23** — QuickLesson 2: Sources vs. Information vs. Evidence vs. Proof. Evidence Explained. https://www.evidenceexplained.com/content/quicklesson-2-sources-vs-information-vs-evidence-vs-proof. Retrieved 2026-05-28.
- **A24** — SPJ's Code of Ethics. Society of Professional Journalists. https://www.spj.org/spj-code-of-ethics/. Retrieved 2026-05-28.
- **A25** — Empirical Standards for Software Engineering. ACM SIGSOFT. https://www2.sigsoft.org/EmpiricalStandards/about/. Retrieved 2026-05-28.
- **A26** — Making Software: What Really Works, and Why We Believe It. Oram & Wilson, O'Reilly 2010. https://books.google.com/books/about/Making_Software.html?id=DxuGi5h2-HEC. Retrieved 2026-05-28.
- **A27** — Review of Making Software. Yevgeniy Brikman. https://www.ybrikman.com/blog/2015/03/23/making-software/. Retrieved 2026-05-28.
- **A28** — Why Programs Fail: A Guide to Systematic Debugging. Andreas Zeller. https://www.oreilly.com/library/view/why-programs-fail/9780123745156/. Retrieved 2026-05-28.
- **A29** — Delta Debugger. debuggingbook.org. https://www.debuggingbook.org/html/DeltaDebugger.html. Retrieved 2026-05-28.
- **A30** — Guidelines for Performing Systematic Literature Reviews in Software Engineering. Kitchenham & Charters 2007. https://www.scirp.org/reference/ReferencesPapers?ReferenceID=1555797. Retrieved 2026-05-28.
- **A31** — Monitoring Distributed Systems. Google SRE Book. https://sre.google/sre-book/monitoring-distributed-systems/. Retrieved 2026-05-28.
- **A32** — The Importance of a Scientific Mindset in Software Engineering, Part 2. This Dot Labs. https://www.thisdot.co/blog/the-importance-of-a-scientific-mindset-in-software-engineering-part-2. Retrieved 2026-05-28.
- **A33** — Pragmatic Programmer Tips. https://pragprog.com/tips/. Retrieved 2026-05-28.
- **A34** — Characterization Testing. Michael Feathers. https://michaelfeathers.silvrback.com/characterization-testing. Retrieved 2026-05-28.
- **A35** — Observability category. Charity Majors. https://charity.wtf/category/observability/. Retrieved 2026-05-28.
- **A36** — EWD303: On the Reliability of Programs. Edsger W. Dijkstra. https://www.cs.utexas.edu/~EWD/transcriptions/EWD03xx/EWD303.html. Retrieved 2026-05-28.
- **A37** — Testing Can Show the Presence of Bugs But Not the Absence. Hillel Wayne. https://buttondown.com/hillelwayne/archive/testing-can-show-the-presence-of-bugs-but-not-the/. Retrieved 2026-05-28.
- **A38** — The Business Case for Formal Methods. Hillel Wayne. https://www.hillelwayne.com/post/business-case-formal-methods/. Retrieved 2026-05-28.
- **A39** — The Oracle Problem in Software Testing: A Survey. Barr, Harman et al., IEEE TSE 2015. https://ieeexplore.ieee.org/document/6963470/. Retrieved 2026-05-28.
- **A40** — Key Points of Working Effectively with Legacy Code. understandlegacycode.com. https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/. Retrieved 2026-05-28.
- **A41** — Cargo cult programming. https://en.wikipedia.org/wiki/Cargo_cult_programming. Retrieved 2026-05-28.
- **A42** — The Oracle Problem and the Teaching of Software Testing. Cem Kaner. https://kaner.com/?p=190. Retrieved 2026-05-28.
- **A43** — What Is Evidence-Based Practice and Why Software Engineers Should Be Aware of It? https://pasemes.github.io/blog/what-is-evidence-based-practice/. Retrieved 2026-05-28.
- **A44** — Bridging the Gap: Adapting Evidence to Decision Frameworks. arXiv 2602.08015 (ICSE 2026 vision paper). https://arxiv.org/abs/2602.08015. Retrieved 2026-05-28.
- **A45** — Seeking Enlightenment: Incorporating Evidence-Based Practice Techniques in a Research Software Engineering Team. arXiv 2403.16827. https://arxiv.org/html/2403.16827v1. Retrieved 2026-05-28.
- **A46** — Stack Overflow Considered Harmful? The Impact of Copy-Paste on Android Application Security. IEEE S&P 2017. https://www.ieee-security.org/TC/SP2017/papers/7.pdf. Retrieved 2026-05-28.
- **A47** — Preventing the Top Security Weaknesses Found in Stack Overflow Code Snippets. Stack Overflow Blog 2019. https://stackoverflow.blog/2019/12/02/preventing-the-top-security-weaknesses-found-in-stack-overflow-code-snippets/. Retrieved 2026-05-28.
- **A48** — Software for Dependable Systems: Sufficient Evidence? National Academies, Chapter 6. https://www.nationalacademies.org/read/11923/chapter/6. Retrieved 2026-05-28.
- **A49** — Measuring LLM Trust Allocation Across Conflicting Software Artifacts. arXiv 2604.03447. https://arxiv.org/pdf/2604.03447. Retrieved 2026-05-28.
- **A50** — Review of Accelerate. Keunwoo Lee. https://keunwoo.com/notes/accelerate-devops/. Retrieved 2026-05-28.
- **A51** — Scientific Debugging Method. UCSD CSE 15L. https://cseweb.ucsd.edu/classes/wi10/cse15L/c/method.php. Retrieved 2026-05-28.
- **A52** — Source of Truth: Code, Spec, or Requirement? reqproof.com. https://blog.reqproof.com/p/code-spec-or-requirement. Retrieved 2026-05-28.
- **A53** — Han plugin YAGNI long-form doc. docs/yagni.md.
- **A54** — Han plugin YAGNI rule reference. plugin/references/yagni-rule.md.
- **A55** — Han plugin research skill. plugin/skills/research/SKILL.md (lines 25, 108, 110, 112).
- **A56** — Han plugin research-analyst agent. plugin/agents/research-analyst.md (lines 18, 44, 65, 84, 89).
- **A57** — Han plugin core mental model index. CLAUDE.md (lines 50–56).
- **A58** — Han plugin iterative-plan-review skill. plugin/skills/iterative-plan-review/SKILL.md (line 46).
- **A59** — Han plugin gap-analysis skill. plugin/skills/gap-analysis/SKILL.md (line 43).
