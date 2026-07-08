# Investigation: The planning chain does not force interface/data contracts to concrete form before implementation

Investigation report. Read the Summary for the diagnosis; the Planned Fix section is a recommendation to carry into a proper `plan-a-feature` → `plan-implementation` cycle, not work applied here. The subject under investigation is the Han planning skill chain itself (`plan-a-feature` → `plan-implementation` → `plan-work-items`), not application code; the grounding incident is the `progress.md` ledger from `docs/plans/autonomous-driver-resume`.

## Summary

- **Root Cause:** Two independent, additive gaps let a concrete contract reach implementation un-pinned: (1) no specialist brief or gate in `plan-a-feature`/`plan-implementation` requires every external format/contract the plan introduces to be specified to a concrete, parseable form — the plan pinned the ledger's *envelope* (file path, trailer key, normalization, exclusion) but never its *payload grammar* (the entry line syntax), and the finding was never even raised (E7, E13); and (2) `plan-work-items`' one-file-per-item decomposition split a single cross-cutting contract across three work items with a hidden ordering dependency and no rule against it (E10, E11, E14).
- **Fix:** A small, two-layer change — make `plan-implementation`'s decision log require the concrete grammar inline (the same way it already pins a key name) and make its specialist pass look for un-pinned formats; make `plan-work-items` pin a shared contract in its foundation item before slicing consumers; and add a cheap `iterative-plan-review` backstop with a mechanical banned-phrase grep — dropping the 8-category checklist and the "deferred-with-reason" escape hatch that validation showed would reproduce the bug.
- **Why Correct:** The strongest evidence is that `plan-implementation` already pins a decision-bearing value of exactly this class concretely — the `Implement-Work-Items-Run:` trailer key (E9) — under an altitude rule that explicitly permits "a key name" in the plan; the line grammar is the same class of value and was left out only by inconsistency, so requiring it costs no new machinery and violates no stated principle (V7).
- **Validation Outcome:** Two adversarial validators confirmed the diagnosis on git-verified evidence but forced material adjustments: the root cause was narrowed to the payload grammar, split into two additive gaps, and re-seated upstream of the count-based gate; the fix was cut down and its escape hatch removed. The counter-hypothesis that `plan-work-items` alone could close the gap was refuted (V4).
- **Remaining Risks:** See Confidence Assessment. The evidence is a single dogfooded incident whose qualitative framing rests partly on a self-authored, uncommitted retrospective; the fix is prose executed by the same class of agent that missed the gap, mitigated but not eliminated by one mechanical grep.

## Provenance: pre-existing upstream, not caused by this branch

The gap is pre-existing in `upstream/main` (`testdouble/han`), not introduced by the `feat/autonomous-driver-core-loop` branch it was found on. Verified with `git fetch` + `git diff upstream/main HEAD`:

- The three skills at the heart of the root cause — `plan-a-feature`, `plan-implementation`, and `iterative-plan-review` — are **byte-identical** between this branch and `upstream/main` (the diff is empty for each skill directory). Every primary-locus finding (E2, E3, E4, E6, E7, E9, E12, E15) therefore reproduces unchanged on upstream.
- The branch *does* edit `plan-work-items`, but only to add driver-routing markers (`Type`, `Suggested implementation` / `Suggested review`, `Expected paths`) and a `deliverable-skill-catalog.md`. The fields the investigation cites as failing to force a concrete contract — the generic acceptance-criteria placeholders (E10, E14) and the `reference-artifact-inventory.md` "not draftable" handling (E11) — are **unchanged from upstream**, as is the one-file-per-item vertical-slice directive behind the decomposition gap (E10, E13).
- The grounding incident ran on this branch's newer `plan-work-items` template (W-1 carries `Type. deliverable`, `Suggested implementation`, etc.), so the branch is the *version present at the failure*, but its new fields are orthogonal to contract pinning — it neither introduced nor mitigated the gap.

Implication for the fix: it lands on the shared skills and should target `upstream/main`, not this feature branch.

## Problem Statement

- **Symptom:** The `autonomous-driver-resume` plan chain specified creating a durable `progress.md` ledger and even named its entry types and fields, but never pinned the concrete line-level format. The operator had to invent the format during implementation. In git terms: work item W-1 (commit `246cd86`) shipped the schema doc with no line grammar; W-2's scanner (commit `ed08f6e`) invented a parsing regex against an undefined format; W-6 (commit `8cee275`, self-described as a "restructure") retrofitted the worked grammar back into the schema doc a day later.
- **Expected behavior:** A trusted implementation plan should carry every contract the build must conform to — file formats, schemas, API/event contracts, module/CLI signatures, config schemas, error/exit contracts, identity conventions, behavior-bearing state machines — to a concrete, buildable form (inline, or a reference to an artifact that already exists concretely), so no builder invents a shared contract mid-implementation.
- **Conditions:** Occurs when a contract is (a) classified as pure implementation detail by `plan-a-feature` (correctly out of the behavior-only spec), and (b) "resolved" by `plan-implementation` at the envelope level (which file, which key) without the payload being pinned, and (c) split across work items by `plan-work-items` so no single item owns the whole contract.
- **Impact:** A shared contract invented mid-build risks silent incompatibility between the component that writes it and the component that reads it (here, the ledger writer in W-6 vs. the scanner in W-2). In this run the drift was caught by human review; nothing in the planning chain would have caught it, and an unattended run would not have.

## Root Cause Analysis

### Root Cause

Two independent gaps compound: no specialist brief or checkpoint in `plan-a-feature` → `plan-implementation` requires a plan-introduced external format/contract to be specified to a concrete grammar before build (the finding was never raised at all — E7, E13), and `plan-work-items` has no rule preventing a single cross-cutting contract from being split across work items, with only a passive "not draftable" flag that never fired here (E11, E14).

### Detailed Analysis

**The chain is designed so each stage defers to the next, but no stage owns a "make it concrete" checkpoint.** `plan-a-feature` deliberately excludes implementation detail from the behavior-only spec (E2) and its routing rule 3 says a pure-implementation data shape should not even be recorded as an Open Item (E3). `plan-implementation` is the correct owner — it is the one stage whose job is to resolve the spec's Open Items and pure-implementation questions — and here it did resolve most of the contract concretely: the committed-file location, the `.gitignore` exclusion, the `Implement-Work-Items-Run:` trailer key, and its normalization algorithm are all pinned in the plan's decision log (E9). What it left open was narrower than "the whole contract": only the entry line grammar (`- <token>: <W-N>`) and the field layout of the five entry types. That remainder was packaged as the deliverable of work unit W-1 — a build artifact, `references/durable-record-protocol.md`, to be authored during implementation (E8).

**A tension the chain does not resolve.** `plan-a-feature`'s rule 3 predicts that pure-implementation shapes vanish silently (not tracked anywhere — E3). The actual spec did better: it recorded "the exact form of the durable progress record" as a deliberate delegation in its Open Items (E1), technically overriding rule 3. So the delegation was visible. The failure is that nothing downstream converted "delegated to `plan-implementation`" into "pinned by `plan-implementation`." Visibility of the open question did not produce a concrete answer, because no checkpoint demanded one.

**The gap was invisible to the finding-generation step, not merely mis-classified by the gate.** `plan-implementation`'s only hard stop is a count-based "spec-maturity gate" that trips on ≥2 `T#`-contradictions or ≥5 `spec-level` (behavioral) findings (E6). An un-pinned format is neither, so it would fall through as ordinary `plan-level` work. But the actual Round-1 claim ledger for this feature shows the deeper problem: all 17 claims raised were `plan-level`, zero `spec-level`, zero `T#`-contradiction, and the missing line grammar never appeared as a claim at all (E7). No specialist brief in the team-review step directs any agent to check "does every external format this plan introduces have a literal worked example or grammar?" — so the gap was never surfaced as a candidate for any gate to evaluate. This is a coverage failure upstream of the gate, which is why the cheapest fix targets the specialist brief and the decision-log field, not the gate's trip counts.

**The altitude rule does not justify the deferral.** `plan-implementation`'s operating principle says not to inline a full file block, but it explicitly carves out "the specific values that are themselves decisions (a flag default, a key name, a threshold)" as belonging in the plan (E12). The trailer key name is exactly such a value and was pinned. The entry line grammar is the same class of decision-bearing value — one sentence, not a full file block — and could have been pinned under the same rule. It was left out by inconsistent application of an otherwise-adequate rule, not by a design constraint that forbids it. This is what makes the fix cheap: it asks the decision log to treat a format grammar the way it already treats a key name.

**The second, independent gap is decomposition.** `plan-work-items` breaks a *trusted* plan into atomic, one-file-per-item vertical slices. It trusts the plan by provenance and is forbidden from annotating it (E10). Its safeguard against an undefined contract is a passive "work items that consume an undefined contract are not draftable" flag (E11) — a detect-and-skip mechanism, never a create mechanism. Here that flag never fired: W-1's acceptance criteria only required the schema to "name all five entry types" and "express minimal fields," which a prose description satisfies without a worked grammar, so the gap read as satisfied (E14). The one-file-per-item heuristic then split the single ledger contract across W-1 (schema), W-2 (scanner that reads it), and W-6 (writer that emits it), creating a hidden ordering dependency that only human review caught (E13). This gap is additive: even a perfectly pinned plan could still be sliced badly, and even perfect slicing cannot invent a grammar the plan never carried. Fixing one leaves the other live.

## Planned Fix

### Approach

Add a concrete-contract checkpoint at the one stage that owns contract resolution (`plan-implementation`), reusing the mechanism that already pins a key name; land the already-anticipated foundation-item decomposition rule in `plan-work-items`; and add a cheap, mechanically-checkable backstop in `iterative-plan-review` — deliberately omitting the 8-category checklist and any "deferred-with-reason" escape hatch.

The fix is tiered so it stays proportionate to single-incident evidence:

- **Tier 1 (core, directly addresses the incident and the plan-of-record):** the `plan-implementation` decision-log rule (#1) and the `plan-work-items` foundation-item rule (#4).
- **Tier 2 (cheap backstops, recommended):** the `plan-implementation` specialist-brief line (#2), the `iterative-plan-review` keyword + banned-phrase grep (#3), and the light template note (#5).

### Changes

#### `han-planning/skills/plan-implementation/references/implementation-decision-log-template.md`

- **Change:** Add a rule to the `Decision:` field guidance: when a decision resolves an external contract, format, schema, interface, or identity convention, the `Decision:` field must carry the concrete specification inline — a literal worked example, grammar line, or field layout — or link to an artifact that already exists concretely. A decision whose content is "authored during the build," a deliverable name with no inlined contract, or a "Resolves when: resolved" tautology does not close the item.
- **Evidence:** (E8), (E9), (E12), (V7).
- **Standards:** `docs/writing-voice.md` (no em-dashes, direct second person); YAGNI rule (`han-planning/references/yagni-rule.md`) — this reuses the existing "key name is a decision worth inlining" carve-out rather than adding machinery.
- **Details:** This is the sharpest, cheapest lever: it makes the decision log treat a format grammar the way it already treated the `Implement-Work-Items-Run:` trailer key. No new section, no checklist. The banned-phrase list ("authored during the build", "TBD at build", "authored later", "Resolves when: resolved") is what the `iterative-plan-review` grep in #3 keys on, giving the rule a mechanical proxy rather than pure prose.

#### `han-planning/skills/plan-implementation/SKILL.md`

- **Change:** Add one directive to the Step-4 specialist briefs and one deterministic Step-5 binary check. Specialist directive: "Every external file/wire/data format, schema, or contract this plan introduces must be specified to a concrete grammar or a worked example; flag any that carries only a prose or field-name description." Step-5 check: a binary "does every plan-committed external format have a literal example or grammar line? (Y/N)" recorded alongside the existing spec-maturity computation — not folded into its count-based trip conditions.
- **Evidence:** (E7), (V8 from the root-cause validation; fix-validator V3).
- **Standards:** `docs/writing-voice.md`; the deterministic-check style already used by the spec-maturity gate.
- **Details:** This targets the real failure locus — the finding was never generated (E7), so making the count-based gate stricter would not have helped. A separate binary check keeps the count-based gate's logic intact (fix-validator V3 confirmed bolting onto it breaks it).

#### `han-planning/skills/plan-implementation/references/feature-implementation-plan-template.md`

- **Change:** Add a single instruction to the existing "Data Model and Persistence" and "External Interfaces" comment blocks: any format, schema, or contract the feature introduces appears here as a worked example or a link to a concrete existing artifact, never as a promise to author one during the build. No new section; no multi-row checklist.
- **Evidence:** (E4), (fix-validator V2 — the 8-category checklist is YAGNI bloat most features would leave mostly "N/A").
- **Standards:** YAGNI rule; `docs/writing-voice.md`.
- **Details:** Deliberately a one-line strengthening of two existing prose slots rather than a new "Interface & Data Contracts" checklist, because the evidence is a single incident and a full taxonomy would be symmetry-for-its-own-sake.

#### `han-planning/skills/iterative-plan-review/SKILL.md` (and `references/iteration-checklist.md`)

- **Change:** Add `format`, `contract`, `schema`, `interface`, and `signature` to the major-finding force-up keyword list (currently `auth`, `PII`, `race`, `ordering`, `coordination`, `edge case`, `T#`). Add one iteration-checklist line: "any external contract the plan references but does not pin to a worked example or an existing concrete artifact is a major finding." Add a mechanical proxy: grep the plan for the banned deferral phrases from #1, and for referenced contract artifacts that do not exist or are stubs.
- **Evidence:** (E15), (fix-validator V6 — the fix needs a mechanical check, not only prose).
- **Standards:** `docs/writing-voice.md`; existing force-up-keyword and checklist conventions in this skill.
- **Details:** This is the backstop that would have caught the "Resolves when: resolved" tautology on a stress-test pass. The grep is the one concrete mechanical proxy in the whole fix; it is what makes the new instruction bite harder than the soft "Resolves when" field that already failed.

#### `han-planning/skills/plan-work-items/SKILL.md`, `references/reference-artifact-inventory.md`, `references/work-item-template.md`

- **Change:** (a) Add a decomposition rule: a shared cross-item contract must be pinned concretely in the foundation item (or already present in the plan) before its consumer items are sliced, and consumers are sequenced to conform. (b) Strengthen the missing-artifact handling so a work item whose deliverable *is* a contract/schema doc must carry the concrete contract in its acceptance criteria, and broaden the inventory beyond HTTP `api-contracts.md` to any shared contract (file format, schema, config, event). (c) The acceptance-criteria requirement closes the hole where the "not draftable" flag never fired because prose satisfied it.
- **Evidence:** (E10), (E11), (E14), (E13), (V4).
- **Standards:** YAGNI rule; `docs/writing-voice.md`; existing work-item-template and inventory conventions.
- **Details:** This lands the exact work the operator's improvement #4 and the hardening plan's deferred item already anticipated ("pin shared contracts in the foundation item; reopen when the work-items planning skill is taken up for hardening"), so it supersedes that deferral rather than duplicating or contradicting it (see Adjustments Made).

## Evidence Summary

### E1: The spec deferred the record's exact form by design, with a falsifiable resolution condition

- **Source:** `docs/plans/autonomous-driver-resume/feature-specification.md:174-183`
- **Finding:**
  ```
  - **The exact form of the durable progress record** ... Deferred by design to `plan-implementation` ([T1]...).
    - **Resolves when:** `plan-implementation` selects the record form against the target repo's hook and history constraints.
    - **Blocks implementation:** No.
  ```
- **Relevance:** The spec honestly parked the record *form* as an Open Item with a concrete, checkable resolution owner and condition. The chain's failure is downstream: nothing converted this delegation into a pinned answer.

### E2: `plan-a-feature` excludes implementation detail and data shapes from the behavior-only spec

- **Source:** `han-planning/skills/plan-a-feature/SKILL.md:26`; `references/feature-specification-template.md:27-38`
- **Finding:** The spec captures "WHAT the feature does, for WHOM, and WHY"; "Library or protocol mechanics" and data-shape detail "MAY NOT APPEAR IN THIS FILE."
- **Relevance:** Correct by design — a behavior-only spec should not carry a serialized format. This establishes that the pinning duty legitimately belongs downstream, not in `plan-a-feature`.

### E3: `plan-a-feature` routing rule 3 says a pure-implementation data shape is not tracked even as an Open Item

- **Source:** `han-planning/skills/plan-a-feature/SKILL.md:90-96`
- **Finding:**
  ```
  3. **Otherwise the question is pure implementation.** Do not settle it here. Do not put it in the spec, tech-notes, or Open Items. `plan-implementation` owns it.
  ```
- **Relevance:** Predicts a silent hand-off with no explicit flag. In tension with E1 (the spec *did* track the delegation), a tension the chain never resolves — visibility alone did not force a concrete answer.

### E4: The plan template asks for narrative "posture," not a serialized contract

- **Source:** `han-planning/skills/plan-implementation/references/feature-implementation-plan-template.md:61-71`
- **Finding:** "Data Model and Persistence" asks for "Schema changes, migrations, data movement"; "External Interfaces" asks for "Contract shape and versioning posture" — prose invitations with no required concrete-format field, and the section carries no lazy-creation gate.
- **Relevance:** The template does not compel a concrete contract; "standard REST conventions" or a fields-only description satisfies its letter.

### E5: `plan-work-items` trusts the plan by provenance and cannot annotate it

- **Source:** `han-planning/skills/plan-work-items/SKILL.md:4-13`, `:38`
- **Finding:** Breaks "a trusted implementation plan"; "Do NOT modify, annotate, or comment on the source implementation plan or context. It is read-only input."
- **Relevance:** The last stage before slicing has no mechanism to push a missing contract back into the plan. Trust is defined by upstream provenance, not by a contract-completeness check.

### E6: The spec-maturity gate trips only on behavioral gaps and `T#`-contradictions

- **Source:** `han-planning/skills/plan-implementation/SKILL.md:151-164`
- **Finding:** Gate trips on "≥ 2 `T#`-contradictions ... by ≥ 2 distinct specialists" or "≥ 5 `spec-level` findings ... by ≥ 3 distinct specialists"; `spec-level` means "requires a behavioral decision the spec never committed to." Everything else is `plan-level`.
- **Relevance:** An un-pinned format is neither trip condition; it is downgraded to ordinary `plan-level` work.

### E7: The Round-1 claim ledger shows the gap was never even raised

- **Source:** `docs/plans/autonomous-driver-resume/artifacts/implementation-iteration-history.md:10-41`
- **Finding:** All 17 Round-1 claims are tagged `plan-level`; 0 `spec-level`; 0 `T#`-contradiction. The missing entry line grammar appears nowhere in the ledger.
- **Relevance:** The failure is a specialist-brief *coverage* gap upstream of the gate — no brief directs anyone to check for un-pinned formats — not a gate-classification failure. This re-seats the cheapest fix at the specialist brief and decision-log field.

### E8: The plan closed the Open Item with a tautology and packaged the schema as a build deliverable

- **Source:** `docs/plans/autonomous-driver-resume/feature-implementation-plan.md:169-178`, `:74`
- **Finding:** OI-1 "resolved to a committed ledger at `.implement-work-items/progress.md` located by the `Implement-Work-Items-Run` trailer"; "**Resolves when:** resolved."; deliverables table row 1 assigns "Entry schema" to `references/durable-record-protocol.md`, a file to be authored during the build.
- **Relevance:** "Resolves when: resolved" is content-free (contrast the spec's falsifiable condition in E1). The remaining concreteness — the line grammar — was delegated to a build artifact.

### E9: The plan *did* pin the envelope concretely — including a key name of exactly the class the fix targets

- **Source:** `docs/plans/autonomous-driver-resume/artifacts/implementation-decision-log.md` D-1 (lines 28-43), D-2 (lines 45-59)
- **Finding:** D-1 pins the committed-file location and `.gitignore` exclusion; D-2 pins the exact trailer key `Implement-Work-Items-Run:` and its exact-match normalization semantics.
- **Relevance:** Narrows the root cause: the plan deferred only the *payload grammar*, not the whole contract. It also proves the mechanism the fix reuses — a decision-bearing value (a key name) pinned concretely in the decision log — already exists and works.

### E10: `plan-work-items` faithfully carried the deferred format forward; W-1's acceptance criteria are structural, not syntactic

- **Source:** `docs/plans/autonomous-driver-resume/work-items.md:17-54`
- **Finding:** W-1 "Define the five ledger entry types and their minimal fields"; acceptance criteria check that the file "defines the five entry types with minimal fields" and that trailers are "specified" — none require a line grammar. W-1 is graded `none, HITL` (human read).
- **Relevance:** The one place the format could have been pinned before its consumers were built required only prose, checked by human skim.

### E11: `plan-work-items`' missing-contract safeguard is passive detect-and-skip, not create

- **Source:** `han-planning/skills/plan-work-items/references/reference-artifact-inventory.md:31-33`
- **Finding:** "Work items that consume an undefined contract are not draftable." Missing-artifact handling flags dependents; nothing authors the contract.
- **Relevance:** Refutes the counter-hypothesis that `plan-work-items` could close the gap alone — it can only stop, never pin.

### E12: The altitude rule explicitly permits a decision-bearing value like a key name in the plan

- **Source:** `han-planning/skills/plan-implementation/SKILL.md:27`
- **Finding:** "Inline only the specific values that are themselves decisions (a flag default, a key name, a threshold). A full file block ... belongs in the file it configures."
- **Relevance:** The deferral is not YAGNI/altitude-justified. The trailer key was pinned under this carve-out; the one-line grammar is the same class and could have been too. The gap is inconsistent application, not a design constraint.

### E13: The operator's own retrospective independently names the decomposition failure

- **Source:** `docs/implement-work-items-first-run-feedback.md:44-48`, `:79-80` (untracked; no git history)
- **Finding:** "The ledger format was defined nowhere (W-1), invented by the scanner (W-2), and retrofitted into the writer (W-6) ... the format should have been pinned concretely in the foundation item with its consumers sequenced to conform." Improvement #4: "Make the foundation item define shared contracts concretely, and flag consumers."
- **Relevance:** Corroborates the incident and locates half the fix (decomposition). Note: self-authored and uncommitted (see V6) — the git history (commits `246cd86`/`ed08f6e`/`8cee275`) independently verifies the technical fact; this doc supplies the framing.

### E14: The concrete grammar first appears in the build artifact, invented by the scanner and retrofitted later

- **Source:** `han-coding/skills/implement-work-items/references/durable-record-protocol.md:25-58`; `scripts/scan-run-history.sh:144`; commits `246cd86`, `ed08f6e`, `8cee275`
- **Finding:** W-1 (`246cd86`) shipped no line grammar; the scanner regex `^-[[:space:]]+(start-of-item|no-commit-done|done|skip):...` (`ed08f6e`) is the first concrete grammar anywhere; W-6 (`8cee275`, "Restructure the protocol into Protocol + Format (worked example) + ...") retrofitted it into the schema doc.
- **Relevance:** Git-verified proof the format was authored during the build, not in planning — the technical claim survives independent of E13's self-report.

### E15: `iterative-plan-review` has no force-up keyword or checklist item for an un-pinned contract

- **Source:** `han-planning/skills/iterative-plan-review/SKILL.md:163`, `:209`; `references/iteration-checklist.md`
- **Finding:** Major force-up keywords are `auth`, `PII`, `race`, `ordering`, `coordination`, `edge case`, `T#` — none for `format`/`contract`/`schema`/`interface`. The checklist covers assumptions, overlap, ambiguity, and stability, with no un-pinned-contract check.
- **Relevance:** The stress-test backstop was not primed to catch the gap either, so no pass in the chain would have flagged it.

### E16: A cross-category gap analysis finds no forcing function for concreteness anywhere in the chain

- **Source:** This investigation's `gap-analyzer` pass over the three skills' templates and steps (`han-planning/skills/{plan-a-feature,plan-implementation,plan-work-items}/` SKILL.md files and their reference templates). Reproducible by re-reading those templates for a required section that forces any contract category to concrete form.
- **Finding:** Across the three skills' templates and steps: persisted schemas and module/CLI signatures have *no* slot (MISSING); data/file formats, API contracts, config schemas, error/exit contracts, and identity conventions are touched only via optional specialists or narrative prose (PARTIAL); zero categories have a required gate forcing concreteness before hand-off.
- **Relevance:** Answers the user's second question — the same gap that dropped the ledger format can drop any of these categories. The structural absence is established by direct reading of the templates, independent of the single incident.

## Validation Results

Two `han-core:adversarial-validator` passes ran in parallel: one attacking the root cause, one attacking the fix. Both re-read every cited file and git commit.

### Counter-Evidence Investigated

#### V1: Every file:line citation and the git chronology

- **Hypothesis:** Citations are stale or paraphrased; the grammar might predate the build.
- **Investigation:** Re-read all cited ranges; ran `git show` on `246cd86`, `ed08f6e`, `8cee275` and the spec-freeze commit.
- **Result:** Confirmed. Every citation is accurate to the line; the grammar first appears in the build commit, not in planning.
- **Impact:** The evidentiary base is solid; no adjustment to the facts.

#### V2: The plan resolved most of the contract, so "author it during the build" overstates the gap

- **Hypothesis:** The root cause overstates breadth — the plan pinned only nothing/everything.
- **Investigation:** Read D-1 and D-2 in full against what shipped.
- **Result:** Partially Refuted. The plan pinned the file path, exclusion mechanism, trailer key, and normalization; only the entry line grammar and field layout were deferred.
- **Impact:** Narrowed the root cause to the *payload grammar* (envelope-vs-payload framing in the Detailed Analysis; E9).

#### V3: The spec tracked the delegation as an Open Item, contradicting rule 3

- **Hypothesis:** E1 and E3 reinforce each other.
- **Investigation:** Compared `plan-a-feature/SKILL.md:96` against `feature-specification.md:174-183`.
- **Result:** Partially Refuted — they are in tension; the spec overrode rule 3 by recording the delegation.
- **Impact:** Added the explicit tension paragraph; the failure is that visibility did not force concreteness, not that the item vanished.

#### V4: `plan-work-items` alone could close the gap, making a `plan-implementation` gate redundant

- **Hypothesis:** The "not draftable" flag has enough leverage.
- **Investigation:** Read `plan-work-items/SKILL.md` and `reference-artifact-inventory.md` in full; checked W-1's acceptance criteria.
- **Result:** Refuted. The flag is passive detect-and-skip, never a create mechanism, and it never fired here because prose satisfied W-1's criteria.
- **Impact:** Confirms `plan-implementation` as the correct primary owner and keeps `plan-work-items` as an additive second layer (E11, E14).

#### V5: The decomposition heuristic is the real cause, leaving `plan-implementation` blameless

- **Hypothesis:** One-file-per-item splitting is the whole bug, fixable entirely in `plan-work-items`.
- **Investigation:** Read the operator retrospective and the hardening plan's scoping decision.
- **Result:** Partially Refuted — the decomposition gap is real and independent, but does not subsume the plan-stage gap: D-1 could have pinned the grammar before W-1 existed and did not.
- **Impact:** Root cause revised to name *two* additive gaps; fix addresses both layers.

#### V6: The corroborating retrospective is single-sourced, self-authored, and uncommitted

- **Hypothesis:** `docs/implement-work-items-first-run-feedback.md` is independent corroboration.
- **Investigation:** `git log` (no history) and `git status` (untracked); read line 10 ("the driver's (Claude's) retrospective").
- **Result:** Partially Refuted — not independent. The technical claim survives on git history (V1); the "only human review caught it" framing rests on this one self-report.
- **Impact:** Evidence Summary marks E13 as self-authored framing vs E14's git-verified fact; recorded as a remaining risk.

#### V7: The gap is YAGNI/altitude-correct by design, so no gate should exist

- **Hypothesis:** The altitude rule intentionally keeps formats out of the plan.
- **Investigation:** Read the rule's full text against what D-2 pinned.
- **Result:** Refuted. The rule carves out "a key name" as belonging in the plan; the grammar is the same class and was omitted by inconsistency.
- **Impact:** This became the fix's cheapest lever (change #1): pin the grammar the way the key name was already pinned (E12).

#### V8: The spec-maturity gate mechanics are the fix locus

- **Hypothesis:** E7's "gate can't catch it" is speculation.
- **Investigation:** Read the actual Round-1 claim ledger.
- **Result:** Confirmed with primary data — 0/17 claims raised the gap; it was invisible to all four specialists.
- **Impact:** Re-seated the fix upstream of the gate: strengthen the Step-4 specialist brief and add a separate binary Step-5 check, not the count-based trip conditions (change #2).

#### V9 (fix): The 8-category checklist is YAGNI bloat and the count-based gate is the wrong mount

- **Hypothesis:** A full contracts taxonomy and a gate hook are the right shape.
- **Investigation:** Checked the YAGNI rule's auto-flags and the gate's count logic.
- **Result:** Confirmed both flaws — most features leave the taxonomy mostly "N/A"; the count-based gate breaks if a binary condition is bolted on.
- **Impact:** Dropped the checklist (change #3 is a one-line note) and used a separate binary check (change #2).

#### V10 (fix): The "deferred-with-reason" state is an escape hatch that reproduces the bug

- **Hypothesis:** A three-state Pinned/Deferred-with-reason/N/A checklist is safe.
- **Investigation:** Traced the original case through the proposed checklist.
- **Result:** Confirmed — an author could write "grammar depends on the serialization library, TBD at build" and pass.
- **Impact:** Removed the deferred state entirely; the rule is binary (concrete or the plan is not done), backed by the banned-phrase grep (changes #1, #3).

#### V11 (fix): The fix duplicates or contradicts the hardening plan's plan-of-record

- **Hypothesis:** Relocating the fix to `plan-implementation` collides with the hardening plan's deferral to `plan-work-items`.
- **Investigation:** Read `docs/plans/autonomous-driver-first-run-hardening/feature-specification.md:120-123`.
- **Result:** Confirmed as an unreconciled conflict in the original fix draft.
- **Impact:** See Adjustments Made — the two gaps are additive, so the fix keeps the `plan-work-items` decomposition rule (landing the deferred item) and *adds* the upstream `plan-implementation` coverage rule; nothing is relocated away from `plan-work-items`.

### Adjustments Made

- **Narrowed the root cause** to the payload grammar (envelope pinned, payload deferred) — triggered by V2/E9.
- **Split the root cause into two additive gaps** (chain coverage + decomposition) — triggered by V5.
- **Re-seated the primary fix** at the specialist brief and decision-log field, with a separate binary Step-5 check rather than the count-based gate — triggered by V8/V9.
- **Dropped the 8-category "Interface & Data Contracts" checklist** for a one-line template note — triggered by V9.
- **Removed the "deferred-with-reason" escape hatch**; the rule is binary and backed by a banned-phrase grep — triggered by V10.
- **Reconciled with the hardening plan:** the `plan-work-items` change lands that plan's deferred "pin shared contracts in the foundation item" item (its stated reopen trigger — "when the work-items planning skill is taken up for hardening" — is now met), while the `plan-implementation` change is net-new upstream coverage the operator's improvement #4 did not identify. The hardening plan's deferred-item note should be updated to point here so the repo does not carry two statements of where the duty lives — triggered by V11.
- **Marked the evidence as single-incident and partly self-reported**; sized the fix in two tiers accordingly — triggered by V6.

### Confidence Assessment

- **Confidence:** Medium-High on the diagnosis; Medium on the fix as specified.
- **Remaining Risks:**
  - **Single-instance evidence.** The whole diagnosis rests on one dogfooded feature. Other plans in `docs/plans/` were not exhaustively checked; it is possible this is the exception and most plans pin formats fine (survivor-bias risk). The two-tier fix is sized to this uncertainty — Tier 1 is proportionate to the one incident; Tier 2 is cheap enough to justify on the structural gap alone (E16).
  - **Enforceability.** These are prose instructions executed by the same class of agent that missed the gap. The `iterative-plan-review` banned-phrase grep is the one mechanical proxy; everything else relies on the agent following the instruction. Confidence that this beats the "Resolves when: resolved" field it replaces should stay Medium until the grep proxy is in place and, ideally, extended (e.g., Glob-verifying a referenced contract artifact exists).
  - **Agent-definition vs skill-brief locus.** Whether `structural-analyst`/`behavioral-analyst` should carry a latent "specify the wire format" instruction in their own definitions (a prompt-adherence question) versus the skill's specialist brief (a definition-gap question) was not resolved; change #2 puts it in the brief, which is the cheaper and more local fix, but the agent-definition option remains open.
  - **`iterative-plan-review` counterfactual unproven.** No negative-control run confirms it would have missed the gap in practice (E15 shows only that it was not primed to catch it).

## Coding Standards Reference

| Standard | Source | Applies To |
|----------|--------|------------|
| No em-dashes, direct second person, plainspoken mentor tone | `docs/writing-voice.md` | Every edited `SKILL.md`, template, and reference file |
| YAGNI / evidence rule — no speculative sections; simplest version that satisfies the evidence | `han-planning/references/yagni-rule.md` | Sizing of the fix (drove dropping the 8-category checklist and the escape hatch) |
| Decision-bearing values (a key name, a flag default) belong in the plan | `han-planning/skills/plan-implementation/SKILL.md:27` | Change #1 — the concrete-grammar rule reuses this existing carve-out |
| Skill/agent authoring conventions | `han-plugin-builder/skills/guidance/references/` | Structure of the edited skills and templates |
| Contributor process for editing skills/docs | `CONTRIBUTING.md` | All changes in `han-planning/` |
