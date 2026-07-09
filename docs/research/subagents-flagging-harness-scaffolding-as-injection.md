# Research: Are agents mistaking legitimate Claude Code harness content for prompt injection?

One-sentence question: several Claude Code subagents reported a "prompt injection" on tool use (a fake date system-reminder, a fake "MCP Server Instructions" block, and an "Auto Mode Active" directive); is the operator's suspicion correct that these were legitimate Claude Code harness instructions the agents confused for an attack, was it caused by a recent harness change, and are there recent bug reports about it?

Evidence mode: strict (evidence required; no exploratory opt-in).

## Summary

Yes, your suspicion is correct. The subagents saw real Claude Code harness scaffolding, the current-date system-reminder, the aggregated "MCP Server Instructions" block, and the "Auto Mode Active" directive, and mistook it for a prompt-injection attack hidden inside tool output. The proof is in the transcript itself: the exact content the subagent "flagged" appears nowhere in any of the file-read results the harness actually recorded. It was delivered by the harness around the tool output, not inside the files the agent read, and the same blocks are present in this very research session right now (this session even received the identical TaskCreate/TaskUpdate reminder mid-run). This is a known, publicly reported class of false positive on the Claude Code issue tracker, including one report that describes this precise mechanism: MCP server instructions getting appended to a subagent's tool output, and the subagent calling it an injection.

What is not supported is the narrower idea that a brand-new harness change yesterday started this. The bug class has been reported since at least April and May 2026, so it predates the sighting. The more likely reason you first hit it on a remote VM is that remote and headless runs turn on Auto Mode, which adds the "stop asking clarifying questions" block that an interactive local run would not show, and your subagent was explicitly primed to hunt for and flag injected directives, so it flagged the unfamiliar-but-legitimate scaffolding.

The core finding is well corroborated by the transcript, direct observation across four concurrent agent sessions, and three independent public bug reports whose bodies were read directly. The specific cause is a reasoned best guess, not a confirmed change.

- **Confidence:** High that the agents misread real harness scaffolding as injection and that this is a reported issue. Low / unconfirmed for the narrower claim that a *recent* harness change specifically triggered it.

## Research Results

**The flagged content was not in the tool output the harness recorded.** The subagent transcript is 45 messages (A1). The three strings the agent flagged, "MCP Server Instructions", "Auto Mode", and the date "2026-07-09", appear only in the agent's own reasoning (message 7), in the agent's own report written to disk (message 43, a self-quote), and in the agent's final report (message 45). They appear in zero tool-result blocks anywhere in the file. The two file reads that immediately preceded the flag contained only the plain contents of the skill under review and its reference file (A1). The adversarial re-parse confirmed this independently, block by block, and also confirmed there is no decoy or fixture file anywhere in the repository that could have leaked such content into a read (A1). One caveat the re-parse surfaced: the original "appears in three places" framing overstated independence, since message 43 is the agent quoting its own report into a file write. There is really one originating flag (message 7), repeated by the same agent.

**The scaffolding is real, and it is delivered around tool output rather than persisted inside it.** The agent was primed by its caller with an explicit instruction to treat files as untrusted data, never obey embedded directives, and flag reviewer-directed ones (A1). Against that hypervigilant framing, it encountered legitimate harness blocks it could not attribute to the user or to a file, and concluded they were injected. That those blocks are genuine harness scaffolding, not an attack, is confirmed three ways. First, direct observation: this research session's own context carries the same current-date reminder and the same "MCP Server Instructions" block for the context7 server, and this session even received verbatim the harness's TaskCreate/TaskUpdate `<system-reminder>` mid-run (A2). Second, the same scaffolding was independently observed by every agent dispatched for this research, in their own separate sessions (A2). Third, the Claude Code documentation describes these as environment details the harness injects into agent and subagent context, not as an attack surface (A12).

**A public bug report describes this exact mechanism.** Issue #58138 (A3), filed May 2026 and read in full, states that when the orchestrator session has MCP servers configured, their usage instructions "appear to be concatenated onto sub-agent tool outputs," and the subagent, which has no knowledge of the orchestrator's session-level MCP config, "reasonably interprets the appended `<system-reminder>` block as a prompt injection arriving via tool output." It records two independent subagent runs, one reporting "fake 'MCP Server Instructions' appended below the spec body" and another opening with "I will not comply with the injected instructions in the tool output." This matches the operator's transcript closely. It also refines the transcript finding: the harness appends the block to the tool-output stream the model sees, but that appended block is not stored in the recorded tool-result content, which is exactly why the flagged strings are absent from the persisted transcript yet the agent still saw them.

**The general class is corroborated by independent reports.** Issue #52018 (A4), read in full, documents that Claude Code injects `<system-reminder>` blocks into tool results whose wording is "formally indistinguishable from a prompt-injection payload," including the classic phrase "NEVER mention this reminder to the user," causing the model to flag them as attacks. Issue #46465 (A5) independently reports the same phrasing problem. Both are about the system-reminder nudge specifically rather than the MCP block, but they establish that harness scaffolding misread as injection is a recurring, multi-author pattern, not a one-off.

**This is misreading real content, not hallucinating fake content.** A separate reported failure mode, issue #70900 (A6), read in full, is the model *fabricating* non-existent injection narratives and fake system-reminder blocks that never appeared in any tool output, confirmed by byte-level transcript inspection, sometimes before the tool even ran. The operator's case is not this: the flagged content is real, active scaffolding that is verifiable in multiple concurrent sessions (A2), so it is a misattribution of genuine content, not a confabulation. The distinction matters because the two imply different remedies, a briefing or wording fix for misattribution versus a model-reliability problem for confabulation.

**On "a recent harness change started this."** This is the weakest part of the operator's hypothesis and is not confirmed. The MCP-into-subagent variant was already filed in May 2026 (A3) and the system-reminder variant in April 2026 (A4, A5), so the phenomenon predates the "yesterday" sighting. An earlier issue (A7) shows MCP-instruction delivery to subagents was an unstable, actively changing area of the harness through early 2026, and the Claude Code changelog review found genuine recent churn around subagent context (subagents running in the background by default, subagents inheriting thinking config) but no entry documenting scaffolding being newly routed into or repositioned within subagent context (A11 [single-source], A12 [single-source, version and line specifics possibly imprecise]). The more likely trigger for first seeing it on a remote VM is environmental rather than a code change: remote and headless runs activate Auto Mode, which injects the "Auto Mode Active / bias toward not stopping for clarifying questions" block (A9, A10) that a local interactive run would not display, so the subagent met an extra unfamiliar block and, already primed to hunt for injections, flagged the whole set.

## Options to Consider

These are the competing explanations for what the subagents actually experienced. They are genuine alternatives, so the section is included; the recommendation selects among them.

### O1: The agents misread real harness scaffolding as injection (false positive on genuine content)

- **What it is:** The harness delivered legitimate scaffolding (date reminder, MCP Server Instructions block, Auto Mode directive) around the tool output; the primed subagent could not attribute it and flagged it as an embedded injection.
- **Trade-offs:** Fully consistent with the transcript, with direct observation of the same scaffolding in four concurrent sessions, and with a public report of the identical mechanism. The residual limitation is that a transcript proves the content was not in the *recorded* tool-result, not that it was absent from the model's context; that residual actually supports this explanation, because out-of-band delivery is the mechanism.
- **Rests on:** (A1), (A2), (A3), (A4), (A5), (A12)
- **Evidence status:** corroborated

### O2: The agents hallucinated scaffolding that was never present (confabulation)

- **What it is:** The model invented the injection narrative and the blocks, matching the pattern in issue #70900, rather than reading anything real.
- **Trade-offs:** The transcript footprint (zero occurrences in tool-results) is superficially compatible with this, but the flagged content is real, active scaffolding verifiable right now in separate sessions, whereas #70900's hallmark is content that provably never existed anywhere. That discriminator rules this out for this transcript.
- **Rests on:** (A6), contradicted for this case by (A2)
- **Evidence status:** corroborated as a real but distinct failure mode; ruled out as the explanation here

### O3: A genuine malicious injection arrived through the same out-of-band channel

- **What it is:** An attacker forged content that looks identical to harness scaffolding and delivered it via the same side channel, so the agent's alarm was correct.
- **Trade-offs:** Cannot be disproven from a transcript in the abstract, but is effectively ruled out for this run: the subagent's only inputs were local file reads (verified clean), local git and find commands, and writes to a scratchpad. There was no web fetch and no external data-returning tool in the run that could have carried attacker-controlled content, so the out-of-band block could only have originated from the harness. The content is also a verbatim match to known-legitimate scaffolding.
- **Rests on:** contradicted by (A1), (A2)
- **Evidence status:** effectively ruled out for this transcript; retained as a theoretical residual

## Recommendation

- **Recommendation:** Your suspicion is correct (O1). The subagents observed legitimate Claude Code harness scaffolding, the current-date system-reminder, the aggregated MCP Server Instructions block, and the Auto Mode directive, and misclassified it as a prompt injection embedded in tool output. It is a known, publicly reported false-positive class, and one filed issue (#58138) describes this exact MCP-instructions-into-subagent-output mechanism. It is not a confabulation (O2) and not a genuine attack (O3). The separate claim that a recent harness change caused it is not supported; treat "recent change" as unconfirmed and the likely trigger as environmental (remote or headless Auto Mode adding an extra block) combined with the subagent being explicitly primed to flag embedded directives.
- **Evidence basis:** The core finding rests on corroborated evidence: the transcript itself (A1), direct observation of the same scaffolding across four concurrent agent sessions including the verbatim TaskCreate reminder (A2), and three public issues whose bodies were read directly, one matching the exact mechanism (A3) and two establishing the general class (A4, A5), plus the discriminating hallucination report (A6). The "not a recent change" conclusion rests on the dates of those filed issues (A3 May 2026, A4 April 2026) and a changelog review that found no matching entry (A11 [single-source]). The environmental-trigger explanation for the remote-VM sighting rests on the Auto Mode mechanism (A9 [single-source], A10 [single-source]) and product-behavior documentation (A12 [single-source]); it is a reasoned best guess, not a confirmed root cause, which is why the cause sub-claim is rated Low.

## Validation

### V1: Are the transcript claims a grep artifact rather than a real role separation?

- **Strategy:** Challenge the Evidence
- **Investigation:** Re-parsed all 45 JSONL messages, classified every content block by type, searched every block for the flagged strings, and confirmed only user and assistant roles exist (no hidden system role that could conceal a harness block).
- **Result:** Confirmed
- **Impact:** The flagged strings occur only in the agent's own text (message 7), its self-quoted file write (message 43), and its final report (message 45), and in no tool-result across all 45 messages. Adjustment: the earlier "three places" framing overstated independence; there is one originating flag repeated by the same agent.

### V2: Could the injected block be hidden in a large or tail-truncated tool result, or in a repo fixture?

- **Strategy:** Challenge the Evidence
- **Investigation:** Full, non-truncated scan of the two large reads and their tails, plus a repository-wide search for the flagged block strings.
- **Result:** Confirmed
- **Impact:** No hidden content in any tool-result tail and no decoy or fixture file in the repository. The one near-miss (the reviewed skill's own legitimate prose about untrusted-content markers) supports rather than undermines the finding, since it shows the in-repo framing that primed the agent's pattern-matching.

### V3: Does "not in the recorded transcript" equal "not in the model's context"?

- **Strategy:** Challenge the Assumptions
- **Investigation:** Assessed whether harness scaffolding delivered out-of-band would be persisted into the tool-result content array, cross-checked against the mechanism described in issue #58138.
- **Result:** Partially Refuted, and the gap favors the conclusion
- **Impact:** The transcript proves the content was not in the recorded tool-result, not that it was absent from context. That is precisely the benign mechanism: #58138 (A3) describes the harness appending the block to the tool-output stream the model sees while it does not persist into the stored result. The residual it leaves open, a malicious actor exploiting the same channel, is addressed by O3 and effectively ruled out for this run, because the subagent had no attacker-controlled input channel (only local reads and local shell), so the block could only have come from the harness.

### V4: Is this misreading real content, or the hallucination pattern of issue #70900?

- **Strategy:** Challenge the Assumptions
- **Investigation:** Compared the transcript against #70900's confabulation pattern, and read #70900's body directly.
- **Result:** Partially Refuted on the transcript alone, resolved by external corroboration
- **Impact:** A transcript footprint alone does not discriminate the two, since both leave the flagged content out of tool-results. The discriminator is that the flagged content here is real, active scaffolding verifiable in separate concurrent sessions (A2), whereas #70900 (A6) is content that provably never existed. This is O1, not the #70900 pattern.

### V5: Is "a recent harness change caused this" actually supported?

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** The validator (no web access) could only check the han plugin suite's own changelog, which is the wrong artifact for Claude Code CLI behavior. The Claude Code changelog was reviewed separately by the web-facing research (A11).
- **Result:** Refuted as stated; downgraded to unconfirmed inference
- **Impact:** The bug class predates the sighting (A3 May 2026, A4 April 2026), and no changelog entry documents scaffolding newly routed into subagents (A11). Adjustment: the report now presents "recent change" as unconfirmed and offers an environmental trigger (remote or headless Auto Mode plus priming) as the more likely explanation, rated Low.

### V6: Does a matching issue title establish the mechanism, or only topical relevance?

- **Strategy:** Challenge the Evidence-Gathering Integrity
- **Investigation:** The validator flagged that issue #58138 was verified by title only, and that discounting it would remove the only source naming the subagent-tool-output channel. In response, the bodies of #58138, #52018, and #70900 were read directly via the GitHub API.
- **Result:** Gap closed
- **Impact:** #58138's body confirms the exact mechanism (MCP instructions concatenated onto subagent tool output, flagged as injection), so the specific-mechanism claim no longer rests on a title alone. #52018's body confirms the general class and quotes the same reminder this session received. The specific mechanism is now body-confirmed.

### V7: Was a fix supplied to validate?

- **Strategy:** Challenge the Fix
- **Investigation:** Re-read the request; no remediation was proposed, only a root-cause question.
- **Result:** Confirmed (no fix in scope)
- **Impact:** None to validate. If a mitigation is later proposed (for example, briefing dispatched subagents to distinguish harness scaffolding from injected content), validate it separately.

### Adjustments Made

- Reframed the "appears in three places" evidence as one originating flag repeated by the same agent (V1).
- Downgraded "a recent harness change caused this" from asserted cause to unconfirmed inference, and added the environmental-trigger explanation for the remote-VM sighting (V5).
- Read the bodies of the load-bearing issues so the specific mechanism rests on confirmed content rather than titles (V6).

### Confidence Assessment

- **Confidence:** High for the core finding (agents misread real harness scaffolding as injection; it is a reported issue with a matching mechanism). Low for the narrower cause claim (that a recent harness change specifically triggered it).
- **Remaining Risks:** The transcript cannot prove the model's live context matched the persisted record, only that the flagged content was not in the recorded tool-result; the benign reading is strongly supported but the theoretical out-of-band-forgery residual (O3) cannot be disproven in the abstract. The direct-observation corroboration (A2) is same-day and same-operator-environment, strong across four concurrent sessions but not replicated across days or unrelated environments. The Auto Mode blog (A9) and Simon Willison write-up (A10), and the claude-code-guide version and line-number specifics (A12), were not independently re-verified; the auto-mode mechanism is nonetheless independently visible in this session's own context. Issues #46465 (A5), #29655 (A7), and #31447 (A8) were verified by existence and title, not by body.

## Sources

| ID | Source | Link / location | Retrieved | Trust class | Summary (one line) | Evidence status |
|---|---|---|---|---|---|---|
| A1 | Subagent transcript that raised the flag | `provided: /home/taminomara/.local/state/claude-clc/personal/projects/-home-taminomara-p-han/0b90af1b-b3d5-4709-8d05-8ebe5166771d/subagents/agent-a4d71ec26d7ee7328.jsonl` | n/a | provided | Flagged strings appear only in the agent's own messages, never in any tool-result; agent was primed to flag embedded directives | corroborated by A2, A3 |
| A2 | Direct observation of live harness scaffolding | `provided: this research session and its four dispatched agent sessions` | 2026-07-09 | provided | The date reminder, the context7 MCP Server Instructions block, and the TaskCreate/TaskUpdate reminder are present in-session; every dispatched agent saw the same | corroborated by A3, A4, A12 |
| A3 | GitHub issue #58138, MCP instructions appended to subagent tool output | https://github.com/anthropics/claude-code/issues/58138 | 2026-07-09 | web | Exact mechanism: session MCP instructions concatenated onto subagent tool output; subagent flags it as injection embedded in tool output | corroborated by A2, A7; body read directly |
| A4 | GitHub issue #52018, system-reminder nudges indistinguishable from injection | https://github.com/anthropics/claude-code/issues/52018 | 2026-07-09 | web | Harness injects `<system-reminder>` blocks into tool results with wording identical to injection, causing false positives; quotes the TaskCreate reminder | corroborated by A5; body read directly |
| A5 | GitHub issue #46465, harness system-reminder phrasing like injection | https://github.com/anthropics/claude-code/issues/46465 | 2026-07-09 | web | Independent report of the same system-reminder phrasing problem across multiple tools | corroborates A4; verified by title, body not read |
| A6 | GitHub issue #70900, model fabricates non-existent injections | https://github.com/anthropics/claude-code/issues/70900 | 2026-07-09 | web | Distinct failure mode: model invents fake injection narratives and blocks that never appeared in tool output, confirmed by byte-level inspection | distinct pattern, ruled out here by A2; body read directly |
| A7 | GitHub issue #29655, subagents do not receive MCP instructions | https://github.com/anthropics/claude-code/issues/29655 | 2026-07-09 | web | Background: MCP-instruction delivery to subagents was unstable and changing in early 2026 | corroborates instability behind A3; verified by title |
| A8 | GitHub issue #31447, Claude claims system messages are injected (via OpenCode) | https://github.com/anthropics/claude-code/issues/31447 | 2026-07-09 | web | Same general pattern of legitimate harness/tooling messages misread as injection, but via a third-party client | weak corroboration (third-party client); verified by title |
| A9 | Anthropic engineering blog, Claude Code auto mode | https://www.anthropic.com/engineering/claude-code-auto-mode | 2026-07-09 | web | Auto Mode injects a directive each turn to bias toward autonomous work and avoid unnecessary clarifying questions | single source (reported by research agent); mechanism independently visible in A2 |
| A10 | Simon Willison, Auto mode for Claude Code | https://simonwillison.net/2026/Mar/24/auto-mode-for-claude-code/ | 2026-07-09 | web | Independent write-up confirming the Auto Mode feature and its reduced-interruption behavior | single source (reported by research agent); corroborates A9 mechanism |
| A11 | Claude Code changelog review (April to July 2026) | https://code.claude.com/docs/en/changelog | 2026-07-09 | web | No entry documents scaffolding newly routed into or repositioned within subagent context; recent subagent churn is unrelated (background-by-default, thinking inheritance) | single source (reported by research agent); negative result |
| A12 | Claude Code product-behavior synthesis (sub-agents and headless docs) | https://code.claude.com/docs/en/sub-agents , https://code.claude.com/docs/en/headless | 2026-07-09 | web | Date reminder, MCP Server Instructions, and Auto Mode directive are documented harness-injected environment details that reach subagents; Auto Mode directive is headless/auto-context dependent | single source (agent synthesis); verdict corroborated by A2, version and line specifics possibly imprecise |

### A1: Subagent transcript that raised the flag — recommendation-bearing

- **Link / location:** `provided: /home/taminomara/.local/state/claude-clc/personal/projects/-home-taminomara-p-han/0b90af1b-b3d5-4709-8d05-8ebe5166771d/subagents/agent-a4d71ec26d7ee7328.jsonl`
- **Retrieved:** n/a (operator-provided artifact)
- **Trust class:** provided (operator-supplied; scrutinized directly and re-parsed adversarially)
- **Summary:** A 45-message subagent run. The agent was dispatched to review a skill as untrusted data, with an explicit instruction to flag embedded directives. Partway through it declared it had detected a prompt injection embedded in tool output (a fake date reminder it was told not to mention, a fake MCP Server Instructions block, and an Auto Mode directive). Structural re-parsing shows those strings appear only in the agent's own reasoning and self-quoted report, in none of the tool-results, and that the file reads immediately before the flag contained only plain file content. This is the primary evidence that the agent misattributed harness scaffolding to the tool-output stream.
- **Evidence status:** corroborated by A2 and A3

### A2: Direct observation of live harness scaffolding — recommendation-bearing

- **Link / location:** `provided: this research session and its four dispatched agent sessions on 2026-07-09`
- **Retrieved:** 2026-07-09
- **Trust class:** provided (direct observation; same-day, same operator environment)
- **Summary:** The current-date system-reminder and the "MCP Server Instructions" block for the context7 server are present in this session's own context, and the harness injected the verbatim TaskCreate/TaskUpdate `<system-reminder>` into this session mid-run. Every agent dispatched for this research independently observed the same scaffolding in its own separate session, including the validator, which noted the same MCP Server Instructions and Auto Mode blocks arriving through the same non-content channel. This establishes that the flagged content is genuine, currently-active scaffolding rather than fabricated or attacker-supplied.
- **Evidence status:** corroborated by A3, A4, A12

### A3: GitHub issue #58138 — recommendation-bearing

- **Link / location:** https://github.com/anthropics/claude-code/issues/58138
- **Retrieved:** 2026-07-09 (existence, title, and body confirmed via the public GitHub API)
- **Trust class:** web (official repository issue tracker; outside the trust boundary but primary for this claim)
- **Summary:** Filed 2026-05-11, closed as duplicate. Reports that when the orchestrator session has MCP servers configured, their usage instructions (delivered at session start in a `<system-reminder>`) are concatenated onto subagent tool outputs, and the subagent, unaware of the orchestrator's config, interprets the appended block as a prompt injection arriving via tool output. Records two independent subagent runs (one reporting "fake 'MCP Server Instructions' appended below the spec body," another opening with "I will not comply with the injected instructions in the tool output") and a diagnostic run that traced the appended block to session-level MCP instructions rather than file content. This is the closest public match to the operator's transcript and confirms both the mechanism and why the content is absent from the persisted tool-result.
- **Evidence status:** corroborated by A2 and A7; body read directly

### A4: GitHub issue #52018 — recommendation-bearing

- **Link / location:** https://github.com/anthropics/claude-code/issues/52018
- **Retrieved:** 2026-07-09 (existence, title, and body confirmed via the public GitHub API)
- **Trust class:** web (official repository issue tracker; primary for this claim)
- **Summary:** Filed 2026-04-22, closed as duplicate/stale. Documents that Claude Code injects `<system-reminder>` blocks into tool results to nudge task-tracking use, and that their wording (including "NEVER mention this reminder to the user") is formally indistinguishable from a prompt-injection payload, leading the model to flag them as attacks and sometimes misattribute them to a website or local file. Its verbatim quote of the TaskCreate/TaskUpdate reminder matches the reminder this research session itself received, making it a direct, independent corroboration of the general false-positive class.
- **Evidence status:** corroborated by A5; body read directly
