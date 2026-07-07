# Research: Extracting a Reusable "Review Core" from code-review, and What Review Skills It Would Unlock

*Open-ended question: Can Han's `code-review` engine — classify size → select a panel of specialist sub-agents by signal → dispatch in parallel → collect → calibrate/demote → adversarially validate → synthesize one verdict — be factored into a reusable "review meta-skill" core that other reviews build on? What additional review skills would that unlock? And which Han tools already support automated review gating? (Builds on prior research at `docs/plans/autonomous-driver-per-item-skill-selection/research/reviewing-non-code-work-items.md`.)*

*Evidence mode: **strict** (evidence required; every claim carries a source and an evidence status).*

## Summary

The honest answer is smaller than the question implies. Han already runs a recognizable "size it, pick a panel of specialists, run them in parallel, then write one report" pattern across a named family of six skills, so the *shape* is clearly reusable. But the part people usually mean by "code-review's core" — the machinery that turns raw specialist findings into a trustworthy verdict (the calibration directive, the reachability filter, the adversarial re-check, the self-consistency pass) — is mostly unique to `code-review` and is not actually duplicated elsewhere. Only one small piece (how agents are launched in parallel) is genuinely copy-pasted. So building a big configurable "review engine" that every review plugs into would be solving a duplication problem Han mostly does not have yet, and it risks the classic "wrong abstraction" trap where a shared thing slowly fills up with special cases.

The one thing that *is* a real, load-bearing shared seam is the review **verdict contract** already living inside `implement-work-items`: a fixed output shape (headline recommendation, coverage, findings, escalation) that lets a code review, a documentation audit, or a human read all be gated the same way. That contract — not a shared orchestration engine — is what other reviews should "build on." The highest-value move is to lift that contract out of `implement-work-items`, strip the driver-specific bits, and make it the standard output shape any reviewer speaks.

On new review skills: Han already has capable, unattended reviewer agents for documentation, config/infrastructure, database schemas, UX, and plans, and the driver can already point at them directly. So the biggest win is not writing new review skills — it is the shared contract that lets those existing agents gate work. If standalone review skills are still wanted (the way `/code-review` exists on its own), documentation, config/infra, and schema review are the sensible first candidates because the agents already exist and those artifact types are the most gate-worthy. Reviewing Han's own skills and agents should stay a human read: that is a deliberate policy in the in-flight plans, not a missing tool.

This is a solid direction rather than a certainty. The core recommendation (make the contract the seam; don't build a rigid meta-skill) got *stronger* under adversarial validation, because the validator showed the orchestration is even less shared than first claimed. The prioritization of which new skills to build is softer, because the strongest reason first given for documentation review turned out to be wrong. Well-corroborated on the direction; qualified on the build order.

- **Confidence:** Medium

## Research Results

**Han already has a named "sizing-aware swarming skill" family, so the panel *shape* is reusable — but that is a weaker claim than "the whole code-review core is shared."** The CHANGELOG names exactly six skills built on the same sizing-aware swarm pattern: `code-review`, `gap-analysis`, `iterative-plan-review`, `plan-a-feature`, `plan-implementation`, and `architectural-analysis` (A12). Every skill in this family, plus `research` and `investigate`, shares the same launch primitive — batch all agents into one message, one `Agent` call each, run concurrently (A1, A6–A10, A13). That primitive is the *only* thing that is near-verbatim across the family (A13). Above it, the steps diverge substantially: size is classified by file count in `code-review`, by gap count in `gap-analysis`, and by options/domain/reach signals in `research`; `architectural-analysis` runs no adversarial-validator at all (its synthesis spine is `risk-analyst` + `software-architect`); `test-planning` has no size-classification step; `investigate` has no size bands and no severities (A6, A7, A10; validated in V1, V2).

**The part of `code-review` that is actually distinctive — the verdict-hardening machinery — is not duplicated anywhere, so there is little DRY pressure to extract it.** The size-scaled calibration directive shipped verbatim to every agent (A3), the reachability phrase-match demotion gate (A4), the independent adversarial-validation reconciliation (A5), and the self-consistency check are concentrated in `code-review`. `architectural-analysis` and `test-planning` do not carry the calibration directive text; where other skills do run an adversarial-validator, they use it for a different purpose (validating gaps, or validating a root-cause and fix), not for reconciling a severitied finding list (A5, A8, A10; validated in V2). In other words, "run a panel then synthesize" is shared; "turn a panel's output into a gated verdict" is a `code-review` specialty. A configurable engine that tried to own the second part would immediately face per-skill special cases — the decay signature Metz warns about (A23, A25).

**The genuinely reusable seam is the verdict contract, not an orchestration engine — but it is currently welded to `implement-work-items`.** `implement-work-items` defines a fixed review output shape — `RECOMMENDATION` / `COVERAGE` / `FINDINGS (at/above threshold)` / `BELOW THRESHOLD` / `DURABLE RECORD` / `ESCALATION` — parsed fail-closed, and it already maps four heterogeneous reviewers into it: `code-review` (identity), `information-architect` (Blocks→Critical, Degrades→Warning, Friction→Suggestion), `content-auditor` (each Missing fact→Warning), and a human read (operator states the tier) (A11). This is exactly the "interface other reviews build on" the question asks about — reviews interoperate through a common *output* shape while each keeps its own orchestration. The caveat: the contract as written carries driver-specific fields — a hard-coded `.implement-work-items/reviews/…` durable-record path, a `scope-baseline commit`, `Expected paths`, and a panel-coverage attestation tied to the code-review roster (A11; validated in V3). Making it a general plug interface is real design work — strip roughly half and redesign the rest — not a rename.

**Han's reviewer roster is broad, and the driver can already dispatch non-code reviewers directly, which reframes "what new review skills are needed."** Of 23 agents, about ten emit verdict-style, severitied findings — `adversarial-security-analyst`, `on-call-engineer`, `data-engineer`, `devops-engineer`, `information-architect`, `content-auditor`, `user-experience-designer`, `junior-developer`, `gap-analyzer`, `adversarial-validator` — mapping cleanly onto artifact types: code, application-source resilience, schemas/migrations/queries, config/IaC/pipelines, doc information-architecture, doc facts, UI/UX, plans/ADRs/standards/PRDs, and spec-conformance (A15, A16). The reviewer/discoverer split is a useful lens but not a hard structural property — the "discoverer" analysts (`structural`, `behavioral`, `concurrency`, `edge-case`, `test`) also emit finding series (A15; validated in V8). Critically, `implement-work-items` already dispatches `content-auditor` and `information-architect` *directly* when an item names them — no wrapper skill sits in between (A19; validated in V4). So a `documentation-review` skill would be a convenience/standardization wrapper around agents the driver can already call, not an unblock.

**Each reviewer speaks a different finding dialect, so the value is in the shared contract that translates them — this is the automated-gating story.** Severity vocabularies diverge across the roster: `CRIT/WARN/SUGG` (code), `SEC-###` Critical/High/Medium (security), `DOR-###`/`DATA-###`/`OCE-###` Blocks/Degrades/Friction/Polish/YAGNI (devops/data/on-call), `IA-###` Blocks/Degrades/Friction/Polish (IA), `GAP-###` Missing/Partial/Divergent/Implicit (gaps) (A17). They cannot be sequenced into one gate without the mapping table the verdict contract already provides (A11, A17). This is Han's automated-review-gating mechanism, and it is the same conclusion the prior autonomous-driver-per-item-skill-selection research reached from the routing angle: the contract/adapter is the prerequisite, not new reviewers.

**Prior art says the panel-then-synthesize pattern is sound and the DRY guardrails say "don't extract early" — and Han sits right on that line.** The orchestrator-worker / fan-out-then-synthesize pattern is well-attested at production scale (Anthropic's multi-agent research system; Mixture-of-Agents; LangGraph's shipped pluggable-worker supervisor) (A26, A27, A28), and Template Method is the textbook fit for "invariant skeleton + pluggable steps" — with the textbook weakness that conditionals accumulate as steps diverge (A25). Against that, Metz's "duplication is cheaper than the wrong abstraction" and the Rule of Three say to wait for three genuine instances of the *same* sequence before extracting (A23, A24). Han's shared *launch primitive* clears that bar easily; its *verdict-hardening sequence* does not — it has essentially one full instance. Han's own DRY precedent (`evidence-rule.md`, `yagni-rule.md` vendored and referenced across plugins) works precisely because those are self-contained *rules* a skill can "apply" and get deterministic behavior; an orchestration spine is a *pattern* each skill instantiates differently, so "apply the spine reference" yields no behavior on its own (A14; validated in V5).

**On which non-code artifacts are worth a structured review, the prior art tiers cleanly by whether an objective oracle exists (A39).** Config/IaC and schemas are the strongest hard-gate candidates — mature, deterministic tooling (Checkov, OPA/Conftest, Trivy; Buf, Confluent Schema Registry) (A32, A35). API specs gate well too (Spectral for style, oasdiff for breaking changes) (A34). Documentation splits: structure/style is gate-worthy (Vale, markdownlint, run as a hard gate at GitLab), but factual accuracy stays advisory and needs reference grounding (A33, A40). Prompt/agent/skill review splits the same way — deterministic assertions can gate, LLM-judged quality cannot reliably (Promptfoo) (A36). ADRs, runbooks, and coding-standard documents have no objective oracle and no dedicated linter; they are advisory-only (A37, A38). Mapping this onto Han's roster: the artifact types where Han *both* has a capable agent *and* the artifact is gate-worthy are documentation (structure), config/IaC, and schemas.

**A note on the panel-reliability caveat, and why it barely applies to Han [reasoning].** Some sources warn that a panel of LLM judges suffers correlated errors — nine judges can be worth about two independent votes (A22, A29). That literature is about panels answering the *same* question. Han's specialists each answer a *different* question (security vs. data vs. runtime), so the caveat largely does not apply to its fan-out (validated in V6). The prior draft's stronger claim — that the caveat "mainly bites the adversarial-validation step" — is wrong: that step runs a *single* validator, which has no peers to correlate with (V6). The caveat would only apply to a hypothetical future design that ran several judges on the same finding list, which does not exist today. This reasoning is not load-bearing for any recommendation, and its two supporting sources are unverifiable 2026 preprints (A22, A29; see V7).

## Options to Consider

The central decision is *what form*, if any, the extraction should take. Four options, from most to least ambitious.

### O1: A full parameterized "review meta-skill" (config-driven orchestrator)

- **What it is:** One shared orchestration skill owns the whole spine (classify → select roster → dispatch → collect → demote → validate → render); each concrete review supplies its roster, rubric, template, and demotion rules as configuration.
- **Trade-offs:** Matches the Template Method / orchestrator-worker prior art (A25, A26, A28) and would let plumbing improvements benefit every review at once. But the full spine is instantiated at most 2–3 times, not 5–6 (A6, A7, A10; V1), and the sequences diverge materially (no validator in `architectural-analysis`, no size step in `test-planning`, unique second-round in `gap-analysis`, unique reachability gate + self-consistency in `code-review`) (A4, A6, A7, A8; V1, V2). A single skeleton would accumulate conditional hooks — Metz's exact decay signature (A23, A25). Also hard to express well in Han's prose-skill medium.
- **Rests on:** A1, A4–A10, A12, A23, A25 (V1, V2).
- **Evidence status:** corroborated that the pattern exists and that the divergences make it risky.

### O2: Extract a shared *reference/convention* for the swarm pattern (Han-native DRY)

- **What it is:** Vendor a shared reference documenting the genuinely-shared conventions (the parallel-dispatch primitive; the "sizing-aware swarming skill" family conventions the CHANGELOG already names), which each review SKILL.md links to instead of restating.
- **Trade-offs:** Low-risk documentation of an existing convention, and it follows Han's real DRY precedent (A14). But that precedent works for context-free *rules*, whereas the swarm is a *pattern* each skill instantiates differently, so a spine reference cannot be "applied" for behavior — it mostly documents, and once written it creates pressure to make divergent skills conform (A14; V5). The true verbatim duplication it would remove is narrow (the launch primitive only) (A13; V2).
- **Rests on:** A12, A13, A14 (V2, V5).
- **Evidence status:** corroborated; benefit is modest because real duplication is narrow.

### O3: Status quo — extract only the smallest primitives, no top-level core

- **What it is:** Leave each review skill owning its own sequence; at most factor the one-line parallel-dispatch framing.
- **Trade-offs:** Zero wrong-abstraction risk and honest about how little is actually shared (A13; V1, V2). But it leaves the one real cross-skill dependency — the verdict contract — welded inside `implement-work-items`, so nothing else can reuse it cleanly (A11; V3), and it does nothing to make heterogeneous reviewers gateable in a standard way.
- **Rests on:** A11, A13 (V1, V2, V3).
- **Evidence status:** corroborated; under-serves the one genuine interoperability need.

### O4: Formalize the verdict contract as the shared plug interface (leave orchestration duplicated)

- **What it is:** Lift the review verdict contract out of `implement-work-items`, strip the driver-specific fields (durable-record path, scope-baseline, Expected-paths, code-roster coverage), and publish it as the standard output shape *any* reviewer — skill, agent, or human — returns. Each review keeps its own orchestration.
- **Trade-offs:** Targets the one artifact that demonstrably needs cross-skill stability (`implement-work-items` already depends on it; it already normalizes four reviewers) (A11), and directly enables automated gating of heterogeneous reviewers via its mapping table (A11, A17). It is the minimal investment that unblocks "other reviews build on this." Cost: it is genuine design work (strip ~half, redesign the rest), not a rename (A11; V3), and by itself it does not remove the (narrow) orchestration duplication.
- **Rests on:** A11, A16, A17 (V3, V5).
- **Evidence status:** corroborated that the contract exists, normalizes four sources, and is the real seam; corroborated that generalizing it is non-trivial.

## Recommendation

- **Recommendation:** Pursue **O4 as the primary extraction, optionally paired with a reduced O2, and explicitly reject O1.** The reusable core other reviews should build on is the **verdict contract (the interface), not a shared orchestration engine.** Concretely:
  1. **Generalize the verdict contract (O4).** Lift `implement-work-items`'s review verdict shape into a shared reference, strip the driver-specific fields, and make `RECOMMENDATION / COVERAGE / FINDINGS / BELOW THRESHOLD / ESCALATION` the standard output any reviewer returns, with the source→tier mapping table as its adapter (A11, A17). This is where the demonstrated cross-skill dependency lives and what makes Han's heterogeneous reviewers gateable uniformly — the same conclusion the prior autonomous-driver-per-item-skill-selection research reached from the routing side.
  2. **Optionally capture the one shared primitive as a light convention (reduced O2).** Document the parallel-dispatch framing and the named "sizing-aware swarming skill" conventions so they stop being copy-pasted (A12, A13). Keep it a documented convention, not a behavior-bearing engine.
  3. **Do not build a rigid parameterized meta-skill (reject O1).** The full spine is shared only ~2–3 times and the verdict-hardening sequence essentially once; a config-driven skeleton would accumulate per-skill conditionals (A4, A6–A10, A23, A25; V1, V2).
  4. **On new review skills, lead with the contract, not wrappers.** Because the driver can already dispatch existing reviewer agents directly (A19; V4), the biggest gating win is the shared contract, not new skills. *If* standalone review skills are still wanted for direct operator invocation (as `/code-review` exists apart from the driver), prioritize by "agent already exists" × "gate-worthy": **documentation-review** (wrap `content-auditor` + `information-architect`; structure gate-worthy, facts advisory) (A15, A33, A40), then **config/infra-review** (wrap `devops-engineer`) and **data/schema-review** (wrap `data-engineer`) — the most gate-worthy non-code artifacts with agents already present (A15, A32, A35). Treat these as convenience/standardization, not unblocks.
  5. **Keep skills, agents, ADRs, runbooks, and coding-standard documents human-reviewed.** No objective oracle exists for these (A37, A38), and the in-flight plan makes a human read of edits to loaded artifacts (skills/agents/manifests) a deliberate policy (decision D16), not a capability gap to automate away (A20; V9). Note the gap; respect the policy.

- **Evidence basis:**
  - *Corroborated (survives discarding the unverifiable 2026 preprints — see V7):* every codebase current-state claim about the swarm family, the divergences, the verdict contract and its driver-specific fields, the reviewer roster, the finding-format divergence, the direct-dispatch behavior, and the D16 human-read policy (A1–A21, directly verified in Validation); the software-design guardrails (Metz, Rule of Three, Template Method) (A23, A24, A25); the orchestrator-worker prior art (A26, A27, A28); and the gate-worthiness tiering and tooling maturity (A32–A36, A38, A39, A40).
  - *Single-source / caveated:* the "diverse small judges beat one large; disagreement as a routing signal" practitioner claim (A30); the ADR LLM-review study (A37, a 2026 preprint).
  - *Not load-bearing:* the panel-correlated-error caveat (A22, A29) and the reasoning built on it (R7/V6) inform none of the five recommendation items; they are carried only as a labeled aside.
  - *In strict mode this stands as a recommendation, not "no clear winner":* the central call (contract-as-seam; reject the rigid meta-skill) rests on corroborated codebase and verifiable-literature evidence and was reinforced, not weakened, by validation. The softer part is the *build order* of new skills, explicitly flagged.

## Validation

### V1: "The shared spine is instantiated 5–6 times" (the rule-of-three basis for extraction)

- **Strategy:** Challenge the Evidence.
- **Investigation:** Read each cited SKILL.md end-to-end and mapped its steps to the seven-element spine; grepped for `adversarial-validator` and size-classification language; cross-checked the CHANGELOG's own list of sizing-aware swarming skills.
- **Result:** Partially Refuted.
- **Impact:** The *full* spine is instantiated at most 2–3 times. `architectural-analysis` has no adversarial-validation step; `test-planning` has no size classification. The CHANGELOG names the canonical family as `code-review`, `gap-analysis`, `iterative-plan-review`, `plan-a-feature`, `plan-implementation`, `architectural-analysis` — the research surveyed a partly-different set (substituting `test-planning`/`investigate`). Only the parallel-dispatch primitive is shared across all. This weakens O1/O2 and is the main reason the recommendation shifted to the minimal O4.

### V2: A12's "near-verbatim calibration directive across five skills" claim

- **Strategy:** Challenge the Evidence.
- **Investigation:** Grepped for the calibration-directive text and compared each occurrence; checked where adversarial-validation actually runs.
- **Result:** Refuted for "near-verbatim"; only the parallel-dispatch framing is genuinely shared verbatim. `research`'s "calibration" is about research depth, not finding severity — a different concept under the same label.
- **Impact:** The true duplication is narrow. This removes most of the DRY urgency behind O1/O2 and reinforces leading with the contract (O4).

### V3: The verdict contract is a ready-made general plug interface

- **Strategy:** Challenge the Evidence.
- **Investigation:** Read `review-verdict-contract.md` in full; inspected its fields and references.
- **Result:** Partially Refuted.
- **Impact:** The contract really does normalize four sources, but it carries `implement-work-items`-specific machinery (durable-record path, scope-baseline commit, Expected-paths, code-roster coverage). Generalizing it is non-trivial design work. Folded into recommendation item 1 as an explicit "strip and redesign," not a rename.

### V4: A documentation-review skill "directly unblocks implement-work-items non-code gating"

- **Strategy:** Challenge the Recommendation.
- **Investigation:** Read `implement-work-items/SKILL.md` review-dispatch lines and the in-flight non-code-classification spec.
- **Result:** Refuted.
- **Impact:** The driver already dispatches `content-auditor`/`information-architect` directly when an item names them; the in-flight plan addresses *routing/classification*, not a missing review skill. The "directly unblocks" rationale was removed; documentation-review is reframed as a convenience wrapper, and the recommendation now leads with the contract rather than new skills.

### V5: O2 is genuinely distinct and correct, and the option set is complete

- **Strategy:** Challenge the Options Framing.
- **Investigation:** Read `evidence-rule.md` and `yagni-rule.md`; confirmed `yagni-rule.md` is byte-identical across its vendored copies; compared "rule" vs "pattern" reuse.
- **Result:** Partially Refuted.
- **Impact:** The A14 precedent is for context-free *rules*, not for a *pattern* each skill instantiates differently, so a spine reference is weaker than framed. A missing option — **O4, formalize only the verdict contract** — was added and became the recommended primary, because it scopes work to where the interoperability need demonstrably exists.

### V6: R7's "correlated-error caveat mainly bites the adversarial-validation step"

- **Strategy:** Challenge the Assumptions.
- **Investigation:** Read `code-review` Step 7.4; compared to what the correlated-error sources actually claim.
- **Result:** Partially Refuted.
- **Impact:** The main conclusion (domain-partitioned specialists are diverse by construction, so the caveat barely applies) is sound. But the adversarial-validation step runs a *single* validator with no peers, so the caveat does not bite there either — the sub-claim was wrong and was removed. R7 is now carried as a labeled, non-load-bearing aside.

### V7: Discount test — remove the unverifiable 2026 preprints (A22, A29, A31, A37)

- **Strategy:** Challenge the Evidence-Gathering Integrity.
- **Investigation:** Traced each 2026 preprint to the claims it supports; checked whether verifiable sources plus codebase carry those claims.
- **Result:** Recommendation survives; the preprints are decorative, not load-bearing.
- **Impact:** The four preprints cluster precisely on the contested sub-questions — the same pattern the prior autonomous-driver-per-item-skill-selection research flagged in its own V8. None reverses anything. Confidence is stated as resting on codebase + verifiable sources, and the preprints are labeled so they do not inflate the rating.

### V8: A15's "~10 reviewers" is the full, structurally-distinct reviewer set

- **Strategy:** Challenge the Evidence.
- **Investigation:** Listed all 23 agents; read `code-review` Step 7.1's finding-series table.
- **Result:** Partially Refuted.
- **Impact:** There are 23 agents; the "discoverer" analysts also emit severitied finding series, so the reviewer/discoverer split is a synthesis lens, not a hard property. The roster is *broader* than stated, which if anything strengthens "the reviewers exist; the missing piece is the contract." A18's gap is real but narrower than "no reviewer."

### V9: A18's gap justifies building skill/agent/ADR review

- **Strategy:** Challenge the Assumptions.
- **Investigation:** Read decision D16 in the non-code-classification spec and the driver's review routing; checked prose-reviewer coverage of ADR/runbook/standard documents.
- **Result:** Partially Refuted.
- **Impact:** `content-auditor`/`information-architect` can already review the prose artifacts (ADRs, runbooks, standards documents). For skills/agents/manifests, D16 makes a human read a deliberate policy because no automated reviewer can verify structural integrity (frontmatter, tool grants). The recommendation now explicitly keeps these human-reviewed and does not propose automating skill/agent review.

### Adjustments Made

- Corrected the spine-sharing claim from "5–6 full instances" to "the launch primitive is universal; the full spine is ~2–3 instances; the verdict-hardening sequence is essentially one" (V1, V2).
- Added **O4 (formalize only the verdict contract)** and made it the recommended primary; demoted O1 to explicitly-rejected and O2 to optional/reduced (V5).
- Removed the "documentation-review directly unblocks the driver" rationale; reframed new review skills as convenience/standardization and made the shared contract the lead recommendation (V4).
- Reframed the panel-diversity reasoning (R7) as a labeled, non-load-bearing aside and dropped its incorrect sub-claim (V6).
- Labeled the four 2026 preprints as non-load-bearing after the discount test (V7).
- Reframed the reviewer-roster and non-code-gap claims as narrower than first stated and added the D16 human-read policy as a deliberate choice to respect (V8, V9).
- The recommendation was **not** rewritten to "no clear winner": the central direction survived and strengthened under validation.

### Confidence Assessment

- **Confidence:** Medium.
- **Remaining Risks:**
  1. Three named sizing-aware skills (`iterative-plan-review`, `plan-a-feature`, `plan-implementation`) were not read in this pass; reading them could adjust exactly how many complete spine instances exist — in either direction — though it is unlikely to overturn "reject the rigid meta-skill."
  2. Generalizing the verdict contract (O4) depends on design choices not yet made; whether stripping the driver-specific fields is minor or substantial was reasoned from the contract text, not prototyped.
  3. The build-order for new review skills is the softest part of the recommendation — its strongest first-given rationale was refuted (V4), so it rests on "agents exist × gate-worthy," which is sound but not decisive.
  4. A meaningful share of the panel/aggregation web evidence is unverifiable 2026 preprints (A22, A29, A31) plus one single-source ADR study (A37); all are non-load-bearing here, but any conclusion that leaned on them would be advisory only.
  5. The in-flight plans (`autonomous-driver-per-item-skill-selection`, `autonomous-driver-resume`, `autonomous-driver-non-code-classification`) are untracked and unshipped; D16 and the routing direction are current intent, not final ground truth.

## Sources

| ID | Source | Link / location | Retrieved | Trust class | Summary (one line) | Evidence status |
|---|---|---|---|---|---|---|
| A1 | code-review pipeline | `han-coding/skills/code-review/SKILL.md` | n/a | codebase | Classify→select roster→parallel dispatch→collect→reachability-demote→adversarial-validate→synthesize→verify | corroborated (V1) |
| A2 | code-review roster + file-signal table | `han-coding/skills/code-review/SKILL.md:125-150` | n/a | codebase | Always junior-developer + security; conditional specialists by file signal | corroborated |
| A3 | Size calibration directive | `han-coding/skills/code-review/SKILL.md:153-178` | n/a | codebase | 25-line size-scaled demotion directive shipped verbatim to agents; not shared elsewhere | corroborated (V2) |
| A4 | Reachability demotion gate | `han-coding/skills/code-review/SKILL.md:332-349` | n/a | codebase | Phrase-match one-severity demotion; code-review-only | corroborated (V2) |
| A5 | Adversarial-validation reconciliation | `han-coding/skills/code-review/SKILL.md:361-388` | n/a | codebase | Single validator re-attacks finding list; Confirmed/Partially-Refuted/Refuted reconciliation | corroborated |
| A6 | architectural-analysis pipeline | `han-coding/skills/architectural-analysis/SKILL.md` | n/a | codebase | Same swarm shape but NO adversarial-validator (risk-analyst + architect synthesis instead) | corroborated (V1) |
| A7 | test-planning pipeline | `han-coding/skills/test-planning/SKILL.md` | n/a | codebase | Dispatch→merge→review; NO size classification step | corroborated (V1) |
| A8 | gap-analysis pipeline | `han-core/skills/gap-analysis/SKILL.md` | n/a | codebase | Swarm + adversarial-validate + conditional 2nd round unique to it | corroborated |
| A9 | research pipeline (this skill) | `han-core/skills/research/SKILL.md` | n/a | codebase | Classify→dispatch→validate→synthesize; every section renders (no lazy-omit) | corroborated |
| A10 | investigate pipeline | `han-coding/skills/investigate/SKILL.md` | n/a | codebase | Dispatch→evidence→validate; no size bands, no severities | corroborated (V1) |
| A11 | Review verdict contract | `han-coding/skills/implement-work-items/references/review-verdict-contract.md` | n/a | codebase | Fixed RECOMMENDATION/COVERAGE/FINDINGS/BELOW-THRESHOLD/DURABLE-RECORD/ESCALATION; maps 4 sources; carries driver-specific fields | corroborated (V3) |
| A12 | "Sizing-aware swarming skill" family | `CHANGELOG.md:501,761` | n/a | codebase | Canonical six: code-review, gap-analysis, iterative-plan-review, plan-a-feature, plan-implementation, architectural-analysis | corroborated (V1) |
| A13 | Genuine duplication is narrow | `han-*/skills/*/SKILL.md` (dispatch framing) | n/a | codebase | Only the parallel-dispatch primitive is near-verbatim across the family | corroborated (V2) |
| A14 | DRY-via-shared-reference precedent | `han-core/references/evidence-rule.md`, `…/yagni-rule.md` | n/a | codebase | Vendored + referenced rules; work because they are context-free rules, not patterns | corroborated (V5) |
| A15 | Agent roster (23 agents; ~10 verdict-style) | `han-core/agents/` | n/a | codebase | Broad reviewer roster; reviewer/discoverer split is a lens, not a hard property | corroborated (V8) |
| A16 | Artifact→reviewer map | `han-core/agents/*` (synthesis) | n/a | codebase | code→roster; docs→content-auditor/IA; config→devops; schema→data; UX→UX; plans/ADRs→junior-dev; spec→gap-analyzer | corroborated |
| A17 | Finding-format divergence | `han-core/agents/*` | n/a | codebase | Each reviewer uses a distinct severity vocabulary/ID scheme; incompatible without the A11 mapping | corroborated |
| A18 | No dedicated reviewer *skill* for some artifacts | `han-*/skills/*` | n/a | codebase | No standalone skill reviews skills/agents/runbooks/standard-docs/ADRs as primary artifact (prose reviewers can still read the prose ones) | corroborated but narrowed (V9) |
| A19 | Driver dispatches non-code reviewers directly | `han-coding/skills/implement-work-items/SKILL.md:~227` | n/a | codebase | Names content-auditor/information-architect and dispatches them directly — no wrapper skill | corroborated (V4) |
| A20 | D16 human-read policy | `docs/plans/autonomous-driver-non-code-classification/feature-specification.md` | n/a | codebase | Edits to loaded artifacts (skill/agent/manifest) require a human read by policy | corroborated (V9); planned, not shipped |
| A21 | In-flight plans | `docs/plans/{autonomous-driver-per-item-skill-selection,autonomous-driver-resume,autonomous-driver-non-code-classification}/` | n/a | codebase | Routing/resume/classification direction; planned, not shipped | corroborated as direction |
| A22 | Correlated errors in LLM panels | https://arxiv.org/abs/2605.29800 | 2026-07-04 | web | 9-judge panel ≈ 2 effective votes | single source (2026 preprint, unverifiable; non-load-bearing) (V7) |
| A23 | The Wrong Abstraction (Metz) | https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction | 2026-07-04 | web | Duplication is cheaper than the wrong abstraction; decay signature = accumulating conditionals | corroborated by A24 |
| A24 | Rule of Three | https://understandlegacycode.com/blog/refactoring-rule-of-three/ | 2026-07-04 | web | Wait for three real instances before extracting a shared abstraction | corroborated by A23 |
| A25 | Template Method (GoF) | https://refactoring.guru/design-patterns/template-method | 2026-07-04 | web | Invariant skeleton + pluggable steps; weakness = conditionals accumulate as steps diverge | corroborated by A26 |
| A26 | Building Effective Agents (Anthropic) | https://www.anthropic.com/research/building-effective-agents | 2026-07-04 | web | Orchestrator-workers, parallelization, evaluator-optimizer patterns | corroborated by A27, A28 |
| A27 | Mixture-of-Agents | https://arxiv.org/abs/2406.04692 | 2026-07-04 | web | Layered fan-out then aggregator synthesis beats single model | corroborated by A26 (2024, verifiable) |
| A28 | LangGraph supervisor | https://github.com/langchain-ai/langgraph-supervisor-py | 2026-07-04 | web | Shipped reusable orchestrator taking pluggable worker agents | corroborated by A26 |
| A29 | Bias contagion; diversity>size | https://arxiv.org/abs/2606.20493 | 2026-07-04 | web | Committee diversity reduces contagion more than size | single source (2026 preprint, unverifiable; non-load-bearing) (V7) |
| A30 | LLM-jury in practice (orq.ai) | https://orq.ai/blog/llm-juries-in-practice | 2026-07-04 | web | Diverse small judges beat one large; disagreement as a routing signal | single source (caveated) |
| A31 | Aggregation methods (BT-sigma; regime map) | https://arxiv.org/abs/2602.16610 ; https://arxiv.org/abs/2606.01034 | 2026-07-04 | web | Per-judge reliability weighting; simple aggregation often wins | single source (2026 preprints, unverifiable; non-load-bearing) (V7) |
| A32 | Policy-as-code / IaC gating | https://spacelift.io/blog/policy-as-code-tools ; https://www.env0.com/blog/top-infrastructure-as-code-security-tools | 2026-07-04 | web | Checkov/OPA/Trivy mature hard gates; tfsec→Trivy; Terrascan dead | corroborated (both agree) |
| A33 | Doc gating (Vale + markdownlint) | https://docs.gitlab.com/development/documentation/testing/vale/ ; https://www.datadoghq.com/blog/engineering/how-we-use-vale-to-improve-our-documentation-editing-process/ | 2026-07-04 | web | Style/structure gate-worthy (GitLab hard gate); facts not checked | corroborated |
| A34 | API spec gating (Spectral + oasdiff) | https://stoplight.io/open-source/spectral ; https://www.oasdiff.com/ | 2026-07-04 | web | Spectral lints style; oasdiff blocks breaking changes | corroborated |
| A35 | Schema gating (Buf / Confluent) | https://buf.build/docs/breaking/ | 2026-07-04 | web | Wire-compatibility breaking-change gate; server-side rejection | corroborated |
| A36 | Prompt/agent eval (Promptfoo) | https://www.promptfoo.dev/docs/integrations/ci-cd/ ; https://www.confident-ai.com/blog/llm-agent-evaluation-complete-guide | 2026-07-04 | web | Deterministic assertions gate; LLM-judged quality advisory | corroborated |
| A37 | ADR LLM-review study | https://arxiv.org/abs/2602.07609 | 2026-07-04 | web | LLMs good on code-inferable ADR decisions, fail on implicit/organizational | single source (2026 preprint, caveated) |
| A38 | No dedicated ADR/runbook linter | https://adr.github.io/ | 2026-07-04 | web | ADR tooling is creation/publication, not quality-linting | corroborated (verifiable negative) |
| A39 | Gate-worthiness criterion | https://www.devopstraininginstitute.com/blog/10-cicd-quality-gates-for-production-level-reliability ; https://dev.to/gaya3bollineni/why-binary-cicd-quality-gates-fail-at-scale-and-a-risk-based-alternative-1jf2 | 2026-07-04 | web | Hard gate iff deterministic oracle + uniform failure consequence; else advisory | corroborated |
| A40 | LLM fact-checking needs a reference (FACTS) | https://storage.googleapis.com/deepmind-media/FACTS/FACTS_benchmark_suite_paper.pdf | 2026-07-04 | web | State-of-the-art fact-checking depends on human-curated reference rubrics | corroborated by A33 |

### A11: Review verdict contract — recommendation-bearing

- **Link / location:** `han-coding/skills/implement-work-items/references/review-verdict-contract.md`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Defines the normalized shape any review sub-agent must return — `RECOMMENDATION`, `COVERAGE`, `FINDINGS (at/above threshold)`, `BELOW THRESHOLD`, `DURABLE RECORD`, `ESCALATION` — parsed fail-closed, and already maps four heterogeneous reviewers into it (code-review identity; information-architect Blocks/Degrades/Friction→tiers; content-auditor Missing→Warning; human read states the tier). It is the one genuine cross-skill seam and the basis for O4. It also carries `implement-work-items`-specific fields (durable-record path, scope-baseline commit, Expected-paths, code-roster coverage), so generalizing it is real design work, not a rename.
- **Evidence status:** corroborated; driver-specific coupling verified in V3.

### A12: The "sizing-aware swarming skill" family — recommendation-bearing

- **Link / location:** `CHANGELOG.md:501,761` (and the sizing-docs references)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** Han already names a canonical family of six sizing-aware swarming skills — `code-review`, `gap-analysis`, `iterative-plan-review`, `plan-a-feature`, `plan-implementation`, `architectural-analysis`. This confirms the panel *shape* is a real, recognized abstraction (supporting a light convention, reduced O2), while also showing the family is not defined by the verdict-hardening steps that are unique to `code-review` (supporting rejection of O1).
- **Evidence status:** corroborated; the survey's substitution of `test-planning`/`investigate` for three planning skills was corrected in V1.

### A19: Driver dispatches non-code reviewers directly — recommendation-bearing

- **Link / location:** `han-coding/skills/implement-work-items/SKILL.md:~227`
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor)
- **Summary:** When a work item names a reviewer agent (for example `content-auditor` or `information-architect`), the driver dispatches that agent directly. This is why a new `documentation-review` skill would be a convenience wrapper rather than an unblock, and why the recommendation leads with the shared contract instead of new review skills.
- **Evidence status:** corroborated; the "directly unblocks" claim it refutes was corrected in V4.

### A20: D16 human-read policy for loaded artifacts — recommendation-bearing

- **Link / location:** `docs/plans/autonomous-driver-non-code-classification/feature-specification.md` (decision D16)
- **Retrieved:** n/a
- **Trust class:** codebase (trusted current-state anchor; planned, not shipped)
- **Summary:** Establishes that an edit to an artifact the tooling loads (a skill, agent, or manifest) requires a human read so a structurally-broken draft cannot ship green. This is a deliberate human-in-the-loop policy, not a reviewer-capability gap, and is why the recommendation keeps skill/agent review human rather than proposing an automated skill/agent reviewer.
- **Evidence status:** corroborated; supersedes the overstated A18 gap per V9.
