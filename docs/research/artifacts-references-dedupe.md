# Research: Deduplicating the Artifacts and References Sections of `/research` Output

Open-ended question: Should the `/research` report template keep both an Artifacts section and a References section, drop one of them, or merge them into a single section — and what should change in the skill, the template, and the existing reports?

Evidence mode: strict.

## Summary

The Artifacts and References sections of a `/research` report carry overlapping information for the same reader task. Every field in References (title, link, retrieved date) is already in Artifacts; Artifacts adds trust class, summary, and evidence status. Established conventions for evidence-bearing reports support keeping two sections only when each carries genuinely different information for genuinely different reader tasks. The current pattern does not meet that test.

The recommended change is to merge the two into one section that keeps every field the current Artifacts section carries, plus the bibliography role References currently plays, and to rename it to "Sources" so a reader can recognize it as the authoritative citation list. If the team prefers to keep the existing name, dropping References and leaving Artifacts in place is an acceptable second choice — it removes the same redundancy with less surface change.

How solid it is: well-corroborated. The redundancy is verifiable from the template and existing reports. The recommendation is supported by multiple independent conventions (academic single-list defaults, the APA annotated-bibliography pattern, the structural-table-vs-bibliography test from systematic-review methodology). The preference for renaming rests on judgment, not on user-research evidence; the team can choose to skip the rename without losing the dedupe.

## Research Results

The redundancy is real. The template defines an Artifacts entry with five fields (link/location, retrieved date, trust class, summary, evidence status) and a References entry with three (title, full link, retrieved date) (A12, A13). The fields in References are a subset of the fields in Artifacts (A14 — reasoning). On a real report, the A1 entry in Artifacts carries everything its References line carries plus the trust class, the summary paragraph, and the corroboration status (A15). All six existing reports under `docs/research/` follow the same dual pattern (A16). No prose rationale exists in the seven repository files most likely to carry it (A17 [single-source: 7-file inventory, not exhaustive]).

Prior art on evidence-bearing reports converges on a single principle: two citation-bearing sections are justified when each answers a different reader question, and no single section can answer both without becoming too dense. IEEE, APA, and Pandoc default to one unified list (A1, A3, A9). Chicago's Notes-Bibliography style keeps two sections because shortened footnotes serve point-of-use lookup while the bibliography serves comprehensive survey — genuinely different reader tasks (A4). IETF splits Normative and Informative References as a procedural partition of one section, not as a structured-registry-plus-bibliography pair (A2 [single-source]). PRISMA systematic-review methodology keeps a structured characteristics table alongside a references list because the table carries study design, population, intervention, outcomes, and risk-of-bias — information that cannot fit in a flat citation line — while the references support retrieval (A7, A8). PRISMA's test fails against the current Han template: References carries no field Artifacts does not already carry.

The APA annotated bibliography is the closest convention to what a merged Han section would be: one indexed list where each entry carries citation data and a structured evaluation (A3). It is a familiar pattern, not an exotic construct. Single-source legal prior art on exhibits, Tables of Authorities, and bibliographies is consistent with the same principle but adds nothing the Chicago and PRISMA evidence does not already establish, and the legal analogy is the weakest of the conventions surveyed (A5 [single-source], A6 [single-source]).

The Han writing-voice profile imposes no constraint on section naming or citation formatting (A18 [single-source]). A section renamed to "Sources" or "Cited Sources" is voice-compatible.

Codebase-vs-web framing surfaced one conflict worth recording: PRISMA is the only convention that explicitly endorses two overlapping sections, and it does so under conditions that the current Han template does not meet. Reading PRISMA as "two sections are good" misses the conditional. PRISMA is cited here as a falsification test the current pattern fails, not as a model to emulate.

## Options to Consider

### O1: Drop References, keep Artifacts

- **What it is:** Remove the References section entirely. Artifacts becomes the single source for IDs, links, retrieval dates, trust class, summaries, and evidence status. The skill and the long-form docs are updated to describe one section instead of two.
- **Trade-offs:** Removes the duplication with the smallest possible surface change. Loses the dedicated flat-bibliography-at-the-bottom convention familiar to readers of academic and professional reports. Keeps the existing term "Artifacts" — a reader unfamiliar with it has to infer that this is the citation registry.
- **Rests on:** A1, A3, A9, A12, A13, A14 (reasoning), A15, A16
- **Evidence status:** corroborated

### O2: Drop Artifacts, push structured fields inline

- **What it is:** Keep References as the single section. Move trust class, summary, and evidence status into the body prose as inline annotations beside each cross-reference.
- **Trade-offs:** Keeps the familiar bibliography convention but loses the stable-ID registry pattern that inline cross-referencing depends on. Inline annotations would repeat every time a source is cited, ballooning the body text. There would no longer be a single surface where a reader (or an adversarial validator) can review all source evaluations at once.
- **Rests on:** A4, A7, A8 (all against this direction)
- **Evidence status:** weakly supported; no prior-art convention recommends merging a structured per-source registry into body prose

### O3: Merge into one section named "Sources" (or "Cited Sources")

- **What it is:** One section, renamed to "Sources" or "Cited Sources," that carries everything the current Artifacts entry carries (ID, link, retrieved date, trust class, summary, evidence status). The current References section is removed; its citation role is absorbed into the merged section. The skill and the long-form docs are updated. Inline cross-references continue to use the `A#` IDs.
- **Trade-offs:** Eliminates dual maintenance, preserves the stable-ID lookup, retains all structured metadata. The merged section is denser per entry than a flat bibliography line, which can feel heavier on reports with many artifacts. The rename adds editing surface (every doc that mentions "Artifacts" or "References" by name has to change).
- **Rests on:** A3, A4, A7, A8, A12, A13, A14 (reasoning), A15, A16, A18
- **Evidence status:** corroborated

### O4: Drop References, rename Artifacts to "Sources"

- **What it is:** A blend of O1 and the rename portion of O3. Keep the Artifacts section's structure, drop References, and rename "Artifacts" to "Sources" or "Cited Sources" so the section reads as the authoritative bibliography. Add a short header at the document end pointing back to "Sources" if desired.
- **Trade-offs:** Addresses the unfamiliar-terminology concern without introducing a second decision about which fields to keep. Structurally identical to O1; the only difference is the section name.
- **Rests on:** A1, A3, A9, A12, A13, A14 (reasoning), A15, A18
- **Evidence status:** corroborated on the principle; the specific choice of name rests on A3 (annotated bibliography analog) and A18 (voice profile is permissive)

## Recommendation

**Recommendation:** O3 — merge into one section named "Sources." If the team prefers not to rename "Artifacts," O1 is an acceptable second choice that removes the same redundancy. O2 is not supported by the evidence.

**Evidence basis:** The decisive evidence is corroborated.

- That References is a strict subset of Artifacts and that no field of References is unique to it: A12, A13, A15 (all codebase, directly verifiable). A14 records the inference that ties these together and is labeled as reasoning, not as a separate artifact.
- That two citation-bearing sections are justified only when each carries different information for different reader tasks: A4 (Chicago), A7 (PRISMA), A8 (UNC PRISMA guide). Chicago and PRISMA corroborate each other on this principle.
- That a single registry is the convention's default when there is no such difference: A1, A3, A9 (IEEE, APA, Pandoc).
- That the merged-section convention has a familiar name in academic writing (annotated bibliography): A3 [single-source on this specific point, supported by general academic convention].
- That the rename is voice-compatible and does not break any other repository rule: A11, A16, A17 [single-source — the inventory is bounded], A18 [single-source].

The choice of O3 over O1 rests on a judgment call about whether "Sources" is more legible to readers than "Artifacts." No user-research evidence supports that claim; the team can defensibly choose O1 instead. Either resolves the redundancy. O2 is rejected because no prior-art convention supports pushing structured per-source metadata entirely into body prose.

**Implementation surface (what the change must touch):**

- `plugin/skills/research/SKILL.md` lines 28 and 126 (both mention "References section" by name).
- `plugin/skills/research/references/research-report-template.md` lines 84–123 (current Artifacts and References sections).
- `docs/skills/research.md` lines 11 and 20 (both describe the dual-section structure to operators).
- `docs/how-to/research-a-decision.md` line 16 (mentions References section by name).

**Existing-reports policy:** Leave the six existing reports under `docs/research/` as they are. Each is a snapshot of a research run rendered against the template that was current at the time. Mechanical migration is non-trivial (References lines were not always rendered with the same author/title formatting as the corresponding Artifacts entries, per V7), and there is no operational benefit to rewriting historical reports to match a newer format. Future reports use the new format from the cutover. The CHANGELOG records the template change so a reader who notices the difference can trace it.

## Validation

The recommendation went through an adversarial validation pass that produced nine findings (V1–V9). The findings did not overturn the recommendation; they refined it.

### V1: Line numbers approximate, not exact

- **Strategy:** Challenge the Evidence
- **Investigation:** Re-read the cited files. The Artifacts section header is at line 84 of the template; the first sample entry runs to line 100. The "always present" prose is at lines 87–92. The cited range "84–110" is workable but imprecise.
- **Result:** Partially Refuted
- **Impact:** Artifact summaries clarified — the cited ranges bound the sections; field-level callouts are at the lines shown. Conclusion unaffected.

### V2: A14 is a derived inference, not a codebase artifact

- **Strategy:** Challenge the Evidence
- **Investigation:** Re-read the canonical evidence rule. A14 ("References is a strict subset of Artifacts") is a comparison synthesized from A12 and A13, not an independently sourced repository fact.
- **Result:** Confirmed
- **Impact:** A14 reclassified as reasoning, not as a codebase artifact. The subset relationship is still demonstrable from A12 and A13 read together, and is shown in practice by A15. The recommendation does not change.

### V3: PRISMA cited as falsification test, not as a model

- **Strategy:** Challenge the Evidence
- **Investigation:** Re-checked the PRISMA framing. PRISMA's structured table carries study-level metadata (design, population, intervention, outcomes, risk-of-bias) that does not fit in a flat citation line. Han's current References carries no such information. PRISMA's two-section design is justified by content asymmetry that Han's pattern does not exhibit.
- **Result:** Confirmed (the framing is correct, but it was at risk of being misread as endorsement)
- **Impact:** The Research Results section now explicitly labels PRISMA as a falsification test the current pattern fails, rather than as a convention Han should emulate.

### V4: Missing option — URL-extractability fast-path for long reports

- **Strategy:** Challenge the Options Framing
- **Investigation:** On `on-call-engineer-research.md`, the Artifacts section runs 355 lines (line 184 to line 539) across 44 entries. The References section provides a compact fast-path to URLs. O3 as originally drafted does not address how a reader scans all URLs quickly in a merged section.
- **Result:** Confirmed gap
- **Impact:** Recorded under Remaining Risks. Mitigation: a Sources entry's first line carries the link, so a reader scanning URLs reads roughly the same number of lines as a flat References list. The lookup is no slower; only the per-entry density is higher. If long-report URL extraction becomes a real friction point, a future optional summary-of-IDs subheader can be added without changing the recommendation.

### V5: "No rationale exists anywhere" was a bounded inventory

- **Strategy:** Challenge the Evidence
- **Investigation:** A17 cited seven files where no rationale appears. Did not exhaustively search commit history, issue comments, or design-conversation traces.
- **Result:** Partially Refuted
- **Impact:** A17 relabeled as single-source — the absence of rationale in seven likely-carrier files is real; an absolute claim of "nowhere in the repo" is not supported. The recommendation does not depend on the rationale being absent; it stands on the structural-redundancy finding regardless.

### V6: Implementation surface is broader than originally named

- **Strategy:** Challenge the Fix
- **Investigation:** Searched for "References section" and `## References` outside the existing report files. Found mentions in `plugin/skills/research/SKILL.md` (lines 28 and 126), `docs/skills/research.md` (lines 11 and 20), and `docs/how-to/research-a-decision.md` (line 16) — in addition to the template itself.
- **Result:** Confirmed gap
- **Impact:** Implementation Surface section expanded to name all five locations. The `research-analyst` agent does not emit a References section and does not need to change.

### V7: Existing-reports migration is unaddressed

- **Strategy:** Challenge the Fix
- **Investigation:** All six reports under `docs/research/` use the dual-section pattern. Sampled `on-call-engineer-research.md`: the References A1 line uses author-first formatting that does not exactly match the Artifacts A1 header; mechanical migration is not trivial.
- **Result:** Confirmed gap
- **Impact:** Existing-Reports Policy section added to the recommendation. Existing reports are left as-is; the template change applies forward. CHANGELOG records the change.

### V8: Legal prior art (A5, A6) is the weakest cited evidence

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** A5 is a vendor site; A6 is Wikipedia. Neither is directly analogous to software-tool reports. Their corroboration of each other is not independent of the legal domain.
- **Result:** Partially Refuted
- **Impact:** A5 and A6 marked as single-source. The recommendation does not depend on the legal analogy — discounting both leaves Chicago, PRISMA, and the single-list-default conventions intact. Recommendation unaffected.

### V9: O3-over-O1 preference rests on a judgment call

- **Strategy:** Challenge the Recommendation
- **Investigation:** Without A3 (the annotated-bibliography analog) and without evidence that readers find "Artifacts" confusing, O1 and O3 are functionally equivalent dedupe options.
- **Result:** Partially Refuted
- **Impact:** Recommendation now states O3 explicitly, names O1 as an acceptable second choice, and acknowledges that the rename rests on judgment, not on user-research evidence.

### Adjustments Made

- A14 reclassified as reasoning, not as a codebase artifact.
- A17 noted as a bounded seven-file inventory rather than an exhaustive claim.
- A5 and A6 marked as single-source within the legal domain; recommendation re-confirmed without them.
- PRISMA framing made explicit as a falsification test rather than a model.
- Implementation Surface expanded to name five files instead of three.
- Existing-Reports Policy added (leave existing reports as-is).
- Recommendation re-framed: O3 first, O1 second, with explicit acknowledgment that the rename is a judgment call.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  - The O3-over-O1 preference is not evidence-grounded on user comprehension. The team should be comfortable that the rename is worth the editing surface before adopting O3 over O1.
  - V4 (URL-extractability on long reports) is a real ergonomic concern. The current six reports are not painful, but a future report with hundreds of artifacts may make the case for a separate quick-reference subheader. This is a forward-looking risk, not a current blocker.
  - The existing-reports decision is an "as-is" call. If a reader of a future report compares it against an older report and is confused by the structural change, the CHANGELOG entry is the only signpost. The reader cost is small but non-zero.
  - A17 is bounded; if a hidden design rationale exists in commit history or issue traces and explains the split (for example, an external tool that scrapes the References section), the recommendation is wrong. No evidence of such a tool was found.

## Artifacts

### A1: IEEE Citation Style Guide — University of Pittsburgh LibGuide

- **Link / location:** https://pitt.libguides.com/citationhelp/ieee
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** IEEE uses a single unified References section at the end of a document. No structured evidence list or exhibits registry runs in parallel. Entries are author, title, publication, access date in bracketed-number order.
- **Evidence status:** corroborated by A3, A9

### A2: IESG Statement — Normative and Informative References (IETF)

- **Link / location:** https://datatracker.ietf.org/doc/statement-iesg-iesg-statement-normative-and-informative-references-20060419
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** IETF RFCs split References into Normative and Informative subsections inside a single References block. Same entry format in both. The split is a procedural classification (normative references gate publication), not a structured-registry-plus-bibliography pair.
- **Evidence status:** single source (caveated)

### A3: APA Style — Reference Lists vs. Bibliographies

- **Link / location:** https://apastyle.apa.org/style-grammar-guidelines/references/lists-vs-bibliographies
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** APA distinguishes a reference list (sources cited) from a bibliography (background reading) and recommends reference lists for most publications. Annotated bibliographies are defined (entry plus evaluative note in one list) but APA does not recommend running both an annotated list and a flat list in the same document.
- **Evidence status:** corroborated by A4

### A4: Chicago Manual of Style — Notes and Bibliography System

- **Link / location:** https://www.chicagomanualofstyle.org/tools_citationguide.html
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Chicago Notes-Bibliography runs two parallel citation surfaces — shortened footnotes at point of use carrying a specific page, and a full bibliography at the end carrying the full page range and complete publication data. The two carry genuinely different information for different reader tasks.
- **Evidence status:** corroborated by A3

### A5: Expert Witness Reports — Expert Institute Best Practices

- **Link / location:** https://www.expertinstitute.com/resources/insights/drafting-expert-witness-reports-pitfalls-best-practices/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Legal expert reports distinguish exhibits (documents analyzed or created by the expert, listed by label, date, Bates stamp) from a bibliography (authorities and research consulted). Both recommended; functional split is direct evidence vs. background sources. Vendor source.
- **Evidence status:** single source (caveated — vendor, legal-domain only)

### A6: Table of Authorities — Wikipedia

- **Link / location:** https://en.wikipedia.org/wiki/Table_of_authorities
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** A Table of Authorities indexes every cited authority in an appellate brief with the page numbers where each appears. Distinct from exhibits (actual documents) and bibliography (background reading). Each section carries non-overlapping information for distinct reader tasks. Tertiary source.
- **Evidence status:** single source (caveated — Wikipedia, legal-domain only)

### A7: PRISMA 2020 — Systematic Review Reporting Guidelines

- **Link / location:** https://pmc.ncbi.nlm.nih.gov/articles/PMC8007028/
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** PRISMA-compliant systematic reviews have included studies appear in both a characteristics table (structured metadata: design, population, intervention, outcomes, risk-of-bias) and a references list (full citations). Explicitly treated as complementary, not redundant: the table enables synthesis and quality assessment; the references enable retrieval and verification. The two sections carry information that cannot fit in the other section's format.
- **Evidence status:** corroborated by A8

### A8: Systematic Reviews — Data Extraction Guide, UNC Chapel Hill

- **Link / location:** https://guides.lib.unc.edu/systematic-reviews/extract-data
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Confirms that structured extraction tables (analysis-oriented) and bibliographies (citation-oriented) serve different functions in systematic-review methodology, and that neither replaces the other.
- **Evidence status:** corroborated by A7

### A9: Pandoc — Citations and Bibliography Handling

- **Link / location:** https://pandoc.org/MANUAL.html
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Pandoc produces a single flat bibliography section at document end driven by an external `.bib` or equivalent file. No native support for a structured metadata registry alongside a flat bibliography. The inline-citation workaround eliminates the end-of-document bibliography rather than adding a parallel section.
- **Evidence status:** single source (caveated)

### A10: NATO Admiralty Code

- **Link / location:** https://en.wikipedia.org/wiki/Admiralty_code
- **Retrieved:** 2026-05-28
- **Trust class:** web
- **Summary:** Two-character source-reliability (A–F) and information-credibility (1–6) ratings annotate sources in intelligence reports. Ratings attach at citation, not collected into a separate registry section. No standardized two-section pattern for evidence reports established.
- **Evidence status:** single source (caveated)

### A11: SKILL.md mandates both sections "always present"

- **Link / location:** plugin/skills/research/SKILL.md:28 and plugin/skills/research/SKILL.md:126
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** Line 28 says "The Artifacts and References sections are always present, even for a minimal run." Line 126 in Step 8 repeats the mandate during report rendering.
- **Evidence status:** corroborated by A12, A13

### A12: Template defines Artifacts with five fields

- **Link / location:** plugin/skills/research/references/research-report-template.md:84–110 (section header at line 84; first sample entry at lines 94–100)
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** Artifacts entry carries Link/location, Retrieved, Trust class, Summary paragraph, Evidence status. Comment block (lines 87–92) labels the section "ALWAYS present, even for a minimal run — never omitted."
- **Evidence status:** corroborated by A11

### A13: Template defines References with three fields

- **Link / location:** plugin/skills/research/references/research-report-template.md:112–123
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** References entry carries full title, full URL or location, retrieved date. Comment block (lines 114–118) calls it "AT THE VERY BOTTOM. One line per artifact: the full pointer to the artifact and its original source… This section is always present."
- **Evidence status:** corroborated by A11

### A14: References is a strict subset of Artifacts (reasoning, not an artifact)

- **Link / location:** derived from A12 and A13 via field comparison
- **Retrieved:** n/a
- **Trust class:** reasoning (not codebase — reclassified per V2)
- **Summary:** Every field in a References entry (title, link, retrieved date) is also in the matching Artifacts entry. Trust class, summary, and evidence status are absent from References. Under Han's evidence rule this is a reasoning step, not an independently sourced artifact.
- **Evidence status:** reasoning step, demonstrated by A15

### A15: Real report — `on-call-engineer-research.md` A1 entries

- **Link / location:** docs/research/on-call-engineer-research.md:188–195 (Artifacts A1) and docs/research/on-call-engineer-research.md:542 (References A1)
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** Artifacts A1 carries author, title, publisher, year, link, retrieved date, trust class, summary paragraph, and corroboration status. References A1 carries author, title, publisher, year, link, retrieved date — every value also in Artifacts. Trust class, summary, and corroboration absent.
- **Evidence status:** corroborated by A12, A13 (template definitions match what the report renders)

### A16: All six existing reports use the dual-section pattern

- **Link / location:** docs/research/adhd-application-to-han.md; docs/research/adhd-application-to-han.with-disambiguation.md; docs/research/evidence-hierarchy.md; docs/research/how-to-docs-structure.md; docs/research/on-call-engineer-research.md; docs/research/runbook-skill-research.md
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** Every report contains exactly one `## Artifacts` section and one `## References` section. No reports under `docs/plans/*/research/`. Total affected by a template change: six.
- **Evidence status:** single source (codebase inventory)

### A17: No prose rationale for the split in seven likely-carrier files

- **Link / location:** docs/agents/research-analyst.md; docs/skills/research.md:11,80–81; docs/how-to/research-a-decision.md; docs/yagni.md; docs/concepts.md; docs/evidence.md; plugin/references/evidence-rule.md
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** Every mention of the two sections describes them as part of the fixed structure but does not justify the split. The canonical evidence rule defines trust class, corroboration, and no-evidence labeling — fields that all map to the Artifacts section, none to References. The inventory is bounded; commit history and issue traces were not exhaustively searched.
- **Evidence status:** single source (bounded inventory)

### A18: Writing voice does not constrain section naming

- **Link / location:** docs/writing-voice.md
- **Retrieved:** n/a
- **Trust class:** codebase
- **Summary:** The voice profile addresses jargon, second person, em-dashes, named libraries and versions. No constraints on report-section naming, citation formatting, or registry structure. A merged section named "Sources" or "Cited Sources" is voice-compatible.
- **Evidence status:** single source (codebase inventory)

## References

- **A1** — IEEE Citation Style Guide. University of Pittsburgh LibGuide. https://pitt.libguides.com/citationhelp/ieee. Retrieved 2026-05-28.
- **A2** — IESG Statement: Normative and Informative References. IETF Datatracker. https://datatracker.ietf.org/doc/statement-iesg-iesg-statement-normative-and-informative-references-20060419. Retrieved 2026-05-28.
- **A3** — Reference lists versus bibliographies. APA Style. https://apastyle.apa.org/style-grammar-guidelines/references/lists-vs-bibliographies. Retrieved 2026-05-28.
- **A4** — The Chicago Manual of Style: Citation Guide. https://www.chicagomanualofstyle.org/tools_citationguide.html. Retrieved 2026-05-28.
- **A5** — Drafting Expert Witness Reports: Pitfalls and Best Practices. Expert Institute. https://www.expertinstitute.com/resources/insights/drafting-expert-witness-reports-pitfalls-best-practices/. Retrieved 2026-05-28.
- **A6** — Table of authorities. Wikipedia. https://en.wikipedia.org/wiki/Table_of_authorities. Retrieved 2026-05-28.
- **A7** — The PRISMA 2020 statement: an updated guideline for reporting systematic reviews. PubMed Central. https://pmc.ncbi.nlm.nih.gov/articles/PMC8007028/. Retrieved 2026-05-28.
- **A8** — Step 7: Extract Data from Included Studies. Systematic Reviews Guide, UNC Chapel Hill. https://guides.lib.unc.edu/systematic-reviews/extract-data. Retrieved 2026-05-28.
- **A9** — Pandoc User's Guide. https://pandoc.org/MANUAL.html. Retrieved 2026-05-28.
- **A10** — Admiralty code. Wikipedia. https://en.wikipedia.org/wiki/Admiralty_code. Retrieved 2026-05-28.
- **A11** — Han: research skill instructions. plugin/skills/research/SKILL.md, lines 28 and 126.
- **A12** — Han: research report template, Artifacts section. plugin/skills/research/references/research-report-template.md, lines 84–110.
- **A13** — Han: research report template, References section. plugin/skills/research/references/research-report-template.md, lines 112–123.
- **A14** — Reasoning step: References is a strict subset of Artifacts. Derived from A12 and A13.
- **A15** — Han: existing research report. docs/research/on-call-engineer-research.md, lines 188–195 (Artifacts A1) and line 542 (References A1).
- **A16** — Han: research-report inventory. docs/research/{adhd-application-to-han.md, adhd-application-to-han.with-disambiguation.md, evidence-hierarchy.md, how-to-docs-structure.md, on-call-engineer-research.md, runbook-skill-research.md}.
- **A17** — Han: rationale-search inventory. docs/agents/research-analyst.md; docs/skills/research.md; docs/how-to/research-a-decision.md; docs/yagni.md; docs/concepts.md; docs/evidence.md; plugin/references/evidence-rule.md.
- **A18** — Han: writing voice profile. docs/writing-voice.md.
