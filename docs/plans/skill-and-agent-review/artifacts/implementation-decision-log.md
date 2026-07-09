# Implementation Decision Log: Skill and Agent Review

<!--
This file records every implementation decision committed while planning Skill and Agent Review.
Behavioral and implementation statements live in [../feature-implementation-plan.md](../feature-implementation-plan.md) —
this file captures the question, rationale, evidence, and rejected alternatives for each decision.
Round-by-round history lives in [implementation-iteration-history.md](implementation-iteration-history.md).

Cross-referencing invariants:
- `Driven by rounds:` — R# IDs from implementation-iteration-history.md that added or changed this decision.
- `Dependent decisions:` — D# IDs of later decisions that rest on this one.
- `Referenced in plan:` — sections of ../feature-implementation-plan.md that cite this decision.

Spec decisions carried forward from the specification decision log are cited as
D1–D15 (spec-log IDs); implementation decisions minted here are D-1, D-2, ...
-->

## Trivial decisions

- D-1: Base pattern is `han-coding/skills/code-review` — the new skill mirrors code-review's layout (`SKILL.md` + `references/` + `scripts/detect-*.sh`), its size-override argument shape, its untrusted-marker mechanism, and its validator discipline, per the spec's stated base and the discovery notes. — Referenced in plan: Implementation Approach, Architecture and Integration Points.
- D-2: Skill name is `review-skill-or-agent` — the invocable name (spec F20/JD-008 left it to implementation), following the sibling `{noun}-builder` / `code-review` naming conventions. — Referenced in plan: Architecture and Integration Points, Definition of Done.
- D-3: Output is a single review report mirroring code-review's structure (summary table, single recommendation, severity-ordered findings) — spec D12, unchanged by implementation. — Referenced in plan: Runtime Behavior.
- D-4: Severity tiers are Critical / Warning / Suggestion, identical to code-review's, so a gating caller maps by identity — spec D7, unchanged by implementation. — Referenced in plan: Runtime Behavior, Testing Strategy.
- D-5: SKILL.md step skeleton mirrors code-review's numbered-step structure (receive target+scope; resolve+halt-check guidance; resolve type; classify size + select roster; inline conformance + bloat passes; dispatch reviewer(s) with untrusted markers; consolidate + de-dup + classify; adversarial-validator pass; render report) — junior-developer buildability pass; no alternative worth discussing given the base. — Referenced in plan: Implementation Approach, Runtime Behavior, Decomposition and Sequencing.

## Full decisions

### D-6: Home the skill in a new `han-experimental` plugin, not in `han-plugin-builder`

- **Question:** Which plugin owns the new skill, given it dispatches `han-core` agents and grounds against `han-plugin-builder` guidance, and neither of those is a dependency `han-plugin-builder` currently declares?
- **Decision:** Create a new opt-in plugin `han-experimental` and home `review-skill-or-agent` in it. `han-experimental/.claude-plugin/plugin.json` carries name `han-experimental`, an experimental-framing description, version `0.1.0`, and `"dependencies": ["han-core", "han-plugin-builder"]` (han-core for the dispatched agents, han-plugin-builder for the guidance references). The plugin is opt-in and is NOT bundled by the `han` meta-plugin. A `han-experimental` entry is added to `.claude-plugin/marketplace.json` mirroring an existing entry's shape.
- **Rationale:** The skill needs both `han-core` (it dispatches `han-core:junior-developer` and focused reviewers) and `han-plugin-builder` (it grounds against the guidance references). Adding those dependencies to `han-plugin-builder` would break that plugin's stated "depends on nothing" identity, which its own `plugin.json` description and marketplace entry both assert. A new experimental plugin lets this skill ship with the dependencies it needs without changing `han-plugin-builder`'s identity, and defers the vendoring question until upstream maintainers state preferences. This supersedes the spec's trivial D13 (home = `han-plugin-builder`); the feature spec is left unedited and the supersession is recorded here.
- **Evidence:** `han-plugin-builder/.claude-plugin/plugin.json` and its marketplace entry both state "depends on nothing" / "dependency-free"; discovery notes name the han-core dependency gap ("`han-plugin-builder` depends on nothing, so it does NOT currently declare a `han-core` dependency — dependency gap to resolve"); user pivot (authoritative) directing a new `han-experimental` home. Spec D13 (`artifacts/decision-log.md`, Trivial decisions) is the superseded home decision.
- **Rejected alternatives:**
  - Home in `han-plugin-builder` and add `han-core` + (self) dependencies — rejected because it breaks the "depends on nothing" identity that plugin's manifest and marketplace entry assert; the pivot chose to preserve that identity.
  - Home near code-review in `han-coding` — already rejected at spec time (spec D13) because the rubric and nearest siblings live in the plugin-building plugin; the experimental home keeps that adjacency via the `han-plugin-builder` dependency without moving the skill into the coding plugin.
- **Specialist owner:** `project-manager` (plugin topology); `software-architect` if a later home change is proposed.
- **Revisit criterion:** Upstream maintainers state a preferred permanent home (e.g., blessing the skill into `han-plugin-builder` with a dependency change, or vendoring it), or the experimental plugin accumulates a second skill that changes its framing.
- **Dissent (if any):** —
- **Driven by rounds:** R1 (user pivot)
- **Dependent decisions:** D-7, D-8, D-9
- **Referenced in plan:** Outcome, Context, Architecture and Integration Points, Decomposition and Sequencing

### D-7: The skill is NOT vendored; vendoring deferred until maintainers state a preference

- **Question:** Should `init-guidance.sh` be extended to vendor the review skill into a target repo (as it vendors the three plugin-building skills), or is the skill left unvendored?
- **Decision:** The skill is not vendored. `init-guidance.sh` is left unchanged and the review skill runs only where `han-experimental` is installed. The vendored-guidance branch of the runtime guidance resolution (D-9) is retained defensively but is a secondary path, because an unvendored skill will normally resolve the installed guidance copy.
- **Rationale:** Vendoring is a mechanism owned by the plugin-building plugin's init step and rewrites `${CLAUDE_PLUGIN_ROOT}` paths at vendor time. Extending it for an experimental skill commits maintainers to a distribution shape before they have stated a preference; the pivot explicitly defers that. Not vendoring is the strictly simpler shape and removes the need to touch `init-guidance.sh` now.
- **Evidence:** Discovery notes describe `init-guidance.sh` vendoring exactly three skills and `sed`-rewriting the `${CLAUDE_PLUGIN_ROOT}` guidance path; user pivot ("NOT vendored ... defer vendoring until upstream maintainers state preferences").
- **Rejected alternatives:**
  - Extend `init-guidance.sh` to vendor the review skill now — rejected under YAGNI and the pivot: no cited consumer needs the skill to run in a vendored-only repo yet, and vendoring commits maintainers to a distribution shape prematurely.
- **Specialist owner:** `project-manager`; `devops-engineer` if a distribution/vendoring change is later proposed.
- **Revisit criterion:** A consumer needs the review to run in a repo that has vendored the guidance but not installed `han-experimental`, or maintainers ask for the skill to be vendored.
- **Dissent (if any):** —
- **Driven by rounds:** R1 (user pivot)
- **Dependent decisions:** D-9
- **Referenced in plan:** Context, Architecture and Integration Points, Deferred (YAGNI)

### D-8: Guidance resolution stays dynamic via a runtime `detect-guidance` script (reverses the specialists' co-located simplification)

- **Question:** Because the skill is no longer co-located with the guidance, `${CLAUDE_PLUGIN_ROOT}` points at `han-experimental` and a co-located guidance path fails. How does the skill resolve `han-plugin-builder`'s guidance at runtime?
- **Decision:** Guidance resolution stays dynamic. A `detect-guidance` script (paired with, or split from, the type/context detector — see D-9) probes for the type-appropriate guidance subtree in order: (1) the installed `han-plugin-builder` guidance references at the sibling-plugin path relative to the plugins root, then (2) a repo-local `.claude/skills/plugin-guidance/references/`, preferring the installed (trusted) copy when both resolve. It halts on an absent or incomplete-for-the-resolved-type copy. The manifest / type-subtree completeness check (a static per-type list of expected guidance filenames) is kept. The content-level cross-copy staleness comparison from spec D9 is dropped (see Deferred (YAGNI)): content integrity of a vendored copy belongs to the vendoring mechanism, not to this review.
- **Rationale:** The discovery notes reasoned that because vendoring `sed`-rewrites the baked-in `${CLAUDE_PLUGIN_ROOT}` path, guidance resolution could reduce to a co-located existence check and the "prefer bundled when both resolve" logic might be unnecessary. That reasoning held only while the skill was co-located with the guidance in `han-plugin-builder`. Under the pivot (D-6) the skill lives in `han-experimental`, so `${CLAUDE_PLUGIN_ROOT}` no longer points at the guidance and the co-located path fails; dynamic resolution is required and the trust-order preference (spec D9/F3) becomes load-bearing again. Dropping only the content-level staleness comparison keeps the halt-on-absent/incomplete guard (the false-approve prevention D9 exists for) while removing a check whose responsibility sits with the vendoring mechanism.
- **Evidence:** User pivot ("D9 stays dynamic ... resolve `han-plugin-builder`'s guidance at runtime via a `detect-guidance` script"); discovery notes' guidance-location facts (installed `${CLAUDE_PLUGIN_ROOT}/skills/guidance/references/`, vendored `.claude/skills/plugin-guidance/references/`, type split `skill-building-guidance/` vs `agent-building-guidelines/`); spec D9 and F3 (trust-order preference, halt-on-absent/partial); `han-coding/skills/code-review/scripts/detect-review-context.sh` (the `key: value` degrade-cleanly detector pattern).
- **Rejected alternatives:**
  - Co-located existence check only, no dynamic resolution (the discovery-notes simplification, adopted by the specialists) — rejected because the pivot moves the skill out of `han-plugin-builder`, so `${CLAUDE_PLUGIN_ROOT}` points at the wrong plugin and the co-located path never resolves.
  - Hardcode the `han-plugin-builder` guidance path — rejected (spec D9) because it breaks when the plugin is installed under a different root or the guidance is vendored, and defeats the portability the feature checks for.
  - Keep the content-level cross-copy staleness comparison — deferred under YAGNI: content integrity of vendored guidance is the vendoring mechanism's responsibility, and "prefer the trusted installed copy" covers the practical case.
- **Specialist owner:** `edge-case-explorer` (detection script behavior); `adversarial-security-analyst` (trust-order and false-approve prevention).
- **Revisit criterion:** A version-marker mechanism is added to vendored guidance (which would make a content-level staleness comparison cheap and meaningful), or the sibling-plugin path resolution proves unreliable across install layouts.
- **Dissent (if any):** —
- **Driven by rounds:** R1 (user pivot, reversing the aggregated specialist simplification)
- **Dependent decisions:** D-9
- **Referenced in plan:** Implementation Approach, Runtime Behavior, Security Posture, Decomposition and Sequencing
- **Supersedes:** the discovery-notes co-located-check simplification of spec D9; carries spec D9's halt-on-absent/partial and trust-order intent forward.

### D-9: Type-and-context detection script contract, type routing, and two distinct halt messages

- **Question:** What does the detection script emit, how is artifact type routed, and what are the halt shapes?
- **Decision:** A `detect-guidance-and-type-context.sh` script (may split into two scripts) emits `key: value` lines: `target-shape`, `target-type`, `structural-signal`, `guidance-root`, `guidance-complete`, `guidance-missing-files`, and git-scope context, degrading cleanly like `detect-review-context.sh` (e.g. `git-available: false`). Type routing (spec D5) is path-shape first — a directory containing `SKILL.md` routes to skill; a `.md` under an agents location routes to agent — then frontmatter confirmation (`allowed-tools` for a skill vs `tools` + `model` for an agent, which are mutually exclusive in the corpus). The completeness check uses a static per-type manifest of expected guidance filenames (the skill subtree ~ the files under `skill-building-guidance/`; the agent subtree ~ `agent-building-guidelines/`). The review renders TWO DISTINCT halt messages: a structural-misfire halt ("resembles a {type} but fails the structural test: {signal}") and a neither-type halt ("not a skill or agent ... route to {tool}").
- **Rationale:** Spec D5 requires the structural-misfire and neither-type halts to be distinct, and the discovery notes confirm the guidance subtree filenames the manifest lists. Path-shape-then-frontmatter routing matches how the builders split (skill-builder Step 6 vs agent-builder Step 6) and uses a signal (`allowed-tools` vs `tools`+`model`) that is mutually exclusive in the corpus, so it disambiguates a path-shape near-miss.
- **Evidence:** Spec D5 and Edge Cases (structural-misfire row, neither-type row); `han-coding/skills/code-review/scripts/detect-review-context.sh` (`key: value` degrade-cleanly pattern); guidance subtree filenames confirmed on disk under `han-plugin-builder/skills/guidance/references/skill-building-guidance/` and `.../agent-building-guidelines/`; skill-builder/agent-builder Step 6 type split (spec D5 evidence).
- **Rejected alternatives:**
  - Frontmatter-first routing — rejected because a mid-edit artifact with malformed frontmatter would fail to route even when its path shape is unambiguous; path-shape first with frontmatter as confirmation degrades better.
  - A single generic halt message for both misfire and neither-type — rejected because spec D5 requires them distinct so a caller and an operator can tell a fixable structural mismatch from an out-of-scope target.
- **Specialist owner:** `edge-case-explorer`.
- **Revisit criterion:** A new artifact type enters scope (spec D14 currently keeps hooks/plugin-config out), or the corpus stops guaranteeing `allowed-tools`/`tools`+`model` mutual exclusivity.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Decomposition and Sequencing, Testing Strategy
- **Depends on:** D-6, D-8

### D-10: `references/bloat-classification.md` closes OI-1 — a three-tier bloat rubric spanning the six bloat categories

- **Question:** (Closes spec OI-1.) What severity heuristics assign a specific bloat instance to Critical, Warning, or Suggestion?
- **Decision:** Create `references/bloat-classification.md`, mirroring code-review's `references/agent-finding-classification.md` structure (per-source CRIT/WARN/SUGG bands, each defined by concrete examples, "when uncertain prefer lower"). The file opens with an inline note stating the spec-D6 size-demotion EXEMPTION (bloat findings never demote for being small). The three tiers span the six bloat categories: **Critical** = contradictory or drifting restatement that makes the artifact wrong or unrunnable; **Warning** = reference-duplication, re-explaining a rule stated a line earlier, or consistent (non-drifting) three-fold "apply rule X to A, B, and C" repetition (attention tax); **Suggestion** = single-instance restatement-of-the-obvious, filler transitions, back-referential meta-commentary. Each tier carries 2-3 worked examples. Category alone does not fix the tier: severity is driven by contradiction / drift / repetition-count, not by which of the six categories a finding falls in.
- **Rationale:** Spec OI-1 explicitly resolves "when plan-implementation drafts the bloat rubric and its worked examples," and does not block implementation. The tiering rule (contradiction/drift/count drives severity, not category) keeps the rubric from mechanically stapling a fixed severity to each category, which would misclassify a benign single restatement as high-severity or a wrong-making drift as low. Mirroring `agent-finding-classification.md` reuses a proven structure the base skill already ships.
- **Evidence:** Spec OI-1 (resolution assigned to plan-implementation, non-blocking); spec D6 (bloat is corrective, gating, exempt from size demotion); `han-coding/skills/code-review/references/agent-finding-classification.md` (per-source bands + examples + "prefer lower" structure, per discovery notes); the six bloat categories enumerated in the spec Outcome and Primary Flow step 5; the bloat rules codified in `han-plugin-builder/skills/guidance/references/skill-building-guidance/writing-effective-instructions.md` and `context-hygiene.md` (spec D6 evidence).
- **Rejected alternatives:**
  - Fix one severity per bloat category — rejected because it misclassifies: a single reference restatement and a wrong-making contradictory restatement are different severities even within "restatement," and a benign consistent three-fold repetition differs from a drifting one.
  - Leave OI-1 open into implementation — rejected per the synthesis instruction to close it; the rubric above IS the closure and lives in the named file.
- **Specialist owner:** `test-engineer` (rubric + worked examples); `edge-case-explorer` (tier boundary cases).
- **Revisit criterion:** Worked examples during the build reveal a bloat instance that fits none of the three tiers cleanly, or a review run shows systematic mis-tiering.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** D-11
- **Referenced in plan:** Implementation Approach, Runtime Behavior, Testing Strategy, Decomposition and Sequencing

### D-11: Size classification and roster of the artifact under review closes OI-2

- **Question:** (Closes spec OI-2.) How is the artifact under review classified by size and complexity, what is the size-override keyword, and which reviewers does each size add beyond the generalist?
- **Decision:** Size is classified from the artifact under review, grounded in the repo's measured distribution (skill bodies cluster 60–290 lines / 0–4 references; `implement-work-items` alone at 533 lines / 8 references is the named "large" exemplar). Thresholds:
  - **Skill** — Small: `<~250` lines AND `0–2` references AND no self-dispatch (default). Medium: `250–450` lines OR `3–5` references OR dispatches `1–2` agents. Large: `>~450` lines OR `6+` references OR dispatches `3+` / multi-mode.
  - **Agent** (single file, line-count only): Small `<~150`; Medium `150–300` OR 1 sub-dispatch; Large `>~300` OR multi-sub-dispatch.

  The default is "default to small, escalate on clear signal" (code-review Step 3.1 language). Roster scales by INSTANCE COUNT of the generalist, not by new agent types (honoring spec D4's rejected dedicated-agent alternative): Small/Medium = `han-core:junior-developer` ×1 over the full artifact; Large = `han-core:junior-developer` ×1 full plus additional instances scoped per reference-cluster / flow-phase. The optional caller `size` override reuses `arguments: size` with `argument-hint: "[size: small | medium | large]"`, bound at a single authoritative binding site (mirroring code-review Step 3.1's "authoritative source for {size}"). The override affects ONLY roster selection; it never alters the bloat or conformance passes, which always run over the full artifact (spec D6, D10).
- **Rationale:** Spec OI-2 explicitly resolves "when plan-implementation drafts the size classification, the override argument, and the roster." Grounding thresholds in the repo's measured line/reference distribution (rather than round numbers) ties the classification to real evidence and puts `implement-work-items` on the correct side of the Large boundary as the named exemplar. Scaling by instance count of the one generalist keeps the roster honoring D4's "no new specialist agent" decision. Binding the override once and scoping its effect to roster-only prevents an override from silently narrowing the always-run passes, which would undercut D6.
- **Evidence:** Spec OI-2 and D4 (roster scales with the artifact; caller may override; generalist is the floor; no new specialist agent), spec F29/F30 (roster scaling + size override added in the iterative-plan-review pass); `han-coding/skills/code-review/SKILL.md` Steps 3.1–3.2 (size classification, roster selection, "authoritative source for {size}", "default to small, escalate on clear signal"); the measured repo distribution and `implement-work-items` at 533/8 as the large exemplar (test-engineer, this round).
- **Rejected alternatives:**
  - Add new dedicated reviewer agent types at larger sizes — rejected because spec D4 deferred a dedicated conformance-reviewer agent under YAGNI; scaling instance count of the existing generalist satisfies the same need.
  - Let the size override alter the conformance/bloat passes too (skip passes at "small") — rejected because it would silently narrow the always-run bloat scan, directly undercutting spec D6; override affects roster only.
  - Round-number thresholds unanchored to the repo — rejected in favor of thresholds anchored to the measured distribution so the named large exemplar lands on the correct side.
- **Specialist owner:** `test-engineer`.
- **Revisit criterion:** The measured skill/agent size distribution shifts materially (new large exemplars appear), or a review run shows the thresholds mis-sizing common artifacts.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Implementation Approach, Runtime Behavior, Testing Strategy, Decomposition and Sequencing
- **Depends on:** D-10 (bloat pass always runs regardless of size)

### D-12: `allowed-tools` is the minimal set `Read, Grep, Glob, Bash(find *), Agent`

- **Question:** What tool grants does the skill's frontmatter declare, given code-review grants git/gh/make/npm?
- **Decision:** `allowed-tools: Read, Grep, Glob, Bash(find *), Agent` only. code-review's `Bash(git *)`, `Bash(gh *)`, `Bash(make *)`, `Bash(npm *)` grants are dropped. `Bash(find *)` is retained and justified by the `detect-guidance` search (D-8).
- **Rationale:** The skill reviews prose artifacts, resolves guidance by searching the filesystem, and dispatches agents; it never runs a build, a package manager, or GitHub operations. Granting tools it does not use violates the least-privilege / self-conformance the skill itself checks for and is a YAGNI over-grant. Git context (for change-scope) is read via the detection script, not a broad `Bash(git *)` grant; the detection script emits scope context and the skill degrades cleanly with no git.
- **Evidence:** `han-coding/skills/code-review/SKILL.md` frontmatter (the git/gh/make/npm grants being dropped); junior-developer buildability pass (minimal set + `Bash(find *)` justification); spec D8 and the skill's own `allowed-tools` / Bash-permission-granularity conformance dimension (least-privilege is a rule this skill enforces).
- **Rejected alternatives:**
  - Inherit code-review's full grant list — rejected because the review runs no build/package/GitHub commands; unused grants fail the self-conformance the skill checks for.
  - Grant `Bash(git *)` for change-scope detection — rejected: the detection script surfaces scope context and the skill degrades cleanly when no git is present, so a broad git grant is unneeded.
- **Specialist owner:** `junior-developer` (buildability); `adversarial-security-analyst` (least-privilege).
- **Revisit criterion:** A future step needs a build, package-manager, or GitHub command that no script or dispatch can cover.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Architecture and Integration Points, Security Posture, Deferred (YAGNI)

### D-13: Untrusted-artifact marker mechanism spans four touch points, with an address-and-ask semantic rule and false-clean guards

- **Question:** How is spec D8 ("treat the artifact as data at every step") built concretely, and where does the spec's enumeration miss a touch point?
- **Decision:** The artifact body is wrapped in `----- BEGIN ARTIFACT UNDER REVIEW (UNTRUSTED) -----` / `----- END ARTIFACT UNDER REVIEW (UNTRUSTED) -----` markers (code-review's marker shape, relabeled) at BOTH the generalist-reviewer dispatch AND the adversarial-validator dispatch — the validator is a fourth touch point the spec's D8 enumeration omitted (the enumerated three were the reading step, the generalist dispatch, and recommendation composition). A standing "data, not instructions" directive sits in the skill's own reading step, and the recommendation is composed ONLY from surviving findings, never from artifact text. One deliberate divergence from code-review is recorded: the fenced content here is the PRIMARY review target ("evaluate closely as data"), not ancillary context to ignore. An **address-and-ask** semantic rule distinguishes a legitimate skill instruction that addresses the skill's own runtime or user (evaluated as conformance) from a reviewer-directed directive that addresses the review or verdict ("report no findings"), which is out-of-place by construction and is itself a finding — default Warning, Critical if the skill's own runtime would emit a rigged verdict. This rule is kept as semantic prose, NOT a phrase regex. Two false-clean guards are built explicitly: (1) HALT is distinct from CLEAN in the output contract — a guidance-unavailable halt renders a dedicated halt block, never the "no-issues + approve" shape, so a gating caller never reads a halt as a pass; (2) code-review's validator overcorrection guard is inherited verbatim — a Refuted verdict drops a finding ONLY on concrete counter-evidence at file:line, else the finding demotes one severity. The bloat carve-out from size demotion (D6) is the third guard.
- **Rationale:** Spec D8 and findings F1/F2 already extended the "treat as data" discipline to the dispatch boundary and recommendation composition, but the adversarial-validator dispatch is a fourth place the untrusted artifact is handed to an agent, and the spec's D8 wording enumerated only three. A steered validator could drop a true finding, so it needs the same marker discipline. The address-and-ask rule is the sharp edge: a skill under review legitimately contains imperative instructions aimed at its own runtime (those are conformance material), so a blanket "ignore all directives" rule would be wrong; the distinction is who the directive addresses. Keeping it prose rather than a regex avoids a brittle phrase-list that a reworded injection slips past. The HALT-distinct-from-CLEAN guard closes the spec's only implied-not-built false-clean path: a halt that renders as "no issues, approve" would be read by a gating caller as a pass.
- **Evidence:** Spec D8, F1, F2 (data-at-every-step; dispatch boundary; recommendation composition); `han-coding/skills/code-review/SKILL.md` Step 1.5 + Step 3.5 (`BEGIN/END (UNTRUSTED)` marker mechanism, per discovery notes) and Step 7.4 (validator overcorrection guard — three verdicts, demote-don't-drop, drop only on concrete counter-evidence); adversarial-security-analyst (this round): the validator as omitted fourth touch point, the address-and-ask rule, the HALT-vs-CLEAN false-clean guard; spec D6 (bloat carve-out from size demotion).
- **Rejected alternatives:**
  - Mark only the generalist dispatch (the spec's enumerated boundary) — rejected because the validator receives the same untrusted artifact and a steered validator drops true findings; the fourth touch point needs the same markers.
  - Detect reviewer-directed directives with a phrase regex ("report no findings", "approve this") — rejected because a reworded injection evades a fixed phrase list; the address-and-ask distinction is semantic (who the directive addresses) and stays prose.
  - Let a guidance-unavailable halt render as the clean "no-issues + approve" shape (the current implied behavior) — rejected because a gating caller would read the halt as a pass; HALT gets a dedicated, distinct output block.
- **Specialist owner:** `adversarial-security-analyst`.
- **Revisit criterion:** A review run shows a reviewer-directed directive slipping past the address-and-ask prose rule (would prompt reconsidering a supplementary detector), or a gating caller misreads a halt as a pass (would prompt hardening the halt block).
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Security Posture, Testing Strategy, Decomposition and Sequencing

### D-14: Oversize handling, scope parsing, and de-duplication mechanics

- **Question:** How are the oversize-body conformance finding (spec D10), invocation-scope parsing (spec D10), and cross-dimension de-duplication (spec D15) built concretely?
- **Decision:**
  - **Oversize (spec D10):** a skill body over 500 lines (the `progressive-disclosure.md` ceiling) is a Warning conformance finding. There is NO body-line cap for agents (the agent guidance defines none — do not invent one). A description over 1024 chars is the existing Description conformance check, not a new oversize class. The read path is unchanged: the full artifact is always read.
  - **Scope:** scope is parsed from the invocation INTENT in prose (not a script). The git-diff detection runs only when scope = change; when no diff resolves, the review falls back to whole-artifact review with conservative severity and an explicit report line noting the fallback. Bloat findings respect scope but are never demoted for being small (spec D6).
  - **De-duplication (spec D15, JD-003):** de-duplication happens in the consolidation step. The conformance pass owns tool / dispatch / routing findings; the dispatched generalist references an overlapping conformance finding rather than raising a duplicate. The skill inherits code-review's Step 9.0 self-consistency check and Step 9.1 rule-10 overlap-reference rule.
- **Rationale:** Spec D10 already made an oversize body a conformance finding rather than a truncation trigger and set the read path; the concrete threshold (500 lines) is the progressive-disclosure ceiling the guidance itself states, and the absence of an agent cap follows the guidance having none (inventing one would fail the skill's own reference-grounding). Parsing scope from stated intent (prose) rather than sniffing git matches spec D10's "state intent rather than infer it" principle; the no-diff fallback mirrors code-review's conservative-severity-with-no-diff behavior. De-dup in consolidation with a named owning pass is spec D15's mechanism, and code-review already ships the Step 9.0 / 9.1-rule-10 machinery to inherit.
- **Evidence:** Spec D10 (oversize body is a conformance finding; full read; scope stated by invocation; conservative severity with no diff) and Edge Cases (large-artifact row, no-git row); spec D15 (overlap-reference precedence) and F9; `han-plugin-builder/skills/guidance/references/skill-building-guidance/progressive-disclosure.md` (skill-body ceiling); `han-coding/skills/code-review/SKILL.md` Step 9.0 (self-consistency) and Step 9.1 rule 10 (overlap-reference) and rule 9 (highest-severity-wins); edge-case-explorer (oversize, no-git/scope) and junior-developer (JD-003 de-dup mechanics), this round.
- **Rejected alternatives:**
  - Invent a body-line cap for agents — rejected because the agent guidance defines none; a review that grounds against guidance must not raise a finding the guidance does not support.
  - Sniff git state to decide scope — rejected (spec D10) because it makes behavior depend on environment rather than stated intent; scope is parsed from the invocation and git detection runs only when scope = change.
  - Truncate or sample an oversize body — rejected (spec D10/F18) because it blinds the whole-artifact bloat scan; oversize is a finding, not a read-path change.
- **Specialist owner:** `edge-case-explorer` (oversize, scope); `junior-developer` (de-dup mechanics).
- **Revisit criterion:** The progressive-disclosure guidance changes the skill-body ceiling, or the agent guidance introduces a body cap.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Runtime Behavior, Testing Strategy, Decomposition and Sequencing

### D-15: Reciprocal sibling-description edits to skill-builder / agent-builder are deferred until the skill is blessed

- **Question:** The skill's description disambiguates against `skill-builder` and `agent-builder`; the both-directions disambiguation rule the skill itself enforces implies reciprocal edits to those siblings' descriptions. Are those edits made now?
- **Decision:** Defer the reciprocal sibling-description edits to `skill-builder` and `agent-builder` until the experimental skill is blessed. The new skill's own description carries its four components and disambiguates against the siblings ("Does not BUILD a skill/agent — use skill-builder/agent-builder; does not review documentation — use content/IA reviewers; does not review application code — use code-review"); the reverse-direction edits are recorded as a plan open item.
- **Rationale:** The both-directions disambiguation rule normally requires reciprocal edits, but `skill-builder` and `agent-builder` live in `han-plugin-builder` while this skill lives in the separate, experimental `han-experimental` (D-6). Editing a stable plugin's skill descriptions to point at an experimental skill in another plugin couples a blessed plugin to an unblessed one before maintainers have signed off. Deferring keeps the coupling out until the skill is blessed; the one-directional disambiguation on the new skill's side is sufficient for a reader routing to it.
- **Evidence:** junior-developer (JD-008) recommending deferral because the skill is in a different, experimental plugin; the both-directions disambiguation rule in `han-plugin-builder/skills/guidance/references/skill-building-guidance/skill-description-frontmatter.md` (the rule the skill enforces); D-6 (separate experimental plugin).
- **Rejected alternatives:**
  - Edit skill-builder and agent-builder descriptions now to reciprocally disambiguate — rejected because it couples a blessed, stable plugin to an unblessed experimental one before maintainers sign off.
- **Specialist owner:** `information-architect` (sibling disambiguation) when the skill is blessed.
- **Revisit criterion:** The skill is blessed / promoted out of `han-experimental` (e.g., into `han-plugin-builder`), at which point the reciprocal edits are made.
- **Dissent (if any):** —
- **Driven by rounds:** R1
- **Dependent decisions:** —
- **Referenced in plan:** Deferred (YAGNI), Open Items
- **Depends on:** D-6
