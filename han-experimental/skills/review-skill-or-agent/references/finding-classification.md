# Finding Classification

## Size classification of the artifact under review

Default to **small**; escalate only when a signal below clearly holds; when a signal is borderline, stay smaller. A stated numeric threshold (a line count, a file count) is never itself borderline — "borderline" governs a measured value near but not at a cutoff, not the cutoff number.

**Skill target:**
- **Small** — `SKILL.md` body under ~250 lines, 0–2 reference files, sequential flow, dispatches no agents of its own.
- **Medium** — body ~250–450 lines, or 3–5 reference files, or the skill dispatches 1–2 agents itself.
- **Large** — body over ~450 lines, or 6+ reference files, or the skill dispatches 3+ agents or runs a multi-mode branching flow.

`has-scripts: true` is a soft nudge toward the larger of two adjacent bands (a script adds a resilience surface); it never escalates on its own.

**Agent target** (single file, line count only — agents carry no reference tree):
- **Small** — under ~150 lines, single role, no sub-agent dispatch.
- **Medium** — ~150–300 lines, or coordinates one sub-agent dispatch.
- **Large** — over ~300 lines, or dispatches multiple sub-agents / runs a multi-phase protocol.

State the chosen size and its signal in one line.

## Size-based severity calibration

Governs which corrective findings escalate to the bands below; bloat is excluded as its own pool.

- **Small** — escalate Critical findings; raise a Warning only when the review scope directly covers the issue; omit Suggestions.
- **Medium** — escalate Critical and Warning; raise Suggestions only for directly-covered issues.
- **Large** — all severities in scope.

When uncertain about a severity, prefer the **lower** one. In a `whole-artifact` scope with nothing to compare against, treat findings conservatively — do not escalate on "newness".

## Per-class bands

### Guidance conformance (owns tool / dispatch / routing findings)
- **Critical** — the artifact will not load, dispatch, or run a step as written: unsafe frontmatter or angle brackets, `AskUserQuestion` in `allowed-tools`, a bare or unresolvable agent-dispatch name, a step using a tool the frontmatter does not grant, a missing referenced file a step needs.
- **Warning** — a guidance rule broken in a way that misleads but still runs: a description missing a four-component element or a both-directions sibling boundary, a Bash grant broader than the steps use, missing graceful degradation on a tool-dependent step, an oversize skill body (>500 lines), a fuzzy step that should be a deterministic script.
- **Suggestion** — a conformance nicety: a clearer heading, a reference that could hold content the body inlines, a naming tidy-up.

### Generalist reviewer (clarity)
- **Critical** — only a named violation of a documented guidance rule that breaks execution; clarity-for-its-own-sake is never Critical.
- **Warning** — a baked-in assumption or ambiguous routing a first-time reader would misread, or a convention the plugin follows elsewhere but this artifact breaks.
- **Suggestion** — unclear naming, confusing flow, an optional clarifying note.

Do not duplicate a generalist finding when the conformance pass already owns it — reference the conformance finding instead.

### Quality lenses (prose flow, correctness, automatable steps, edge cases, portability)

Produced by the conformance & quality reviewer alongside conformance.

- **Critical** — an internal contradiction or unhandled edge case that makes the artifact emit a wrong or unsafe result when it runs.
- **Warning** — a step whose correctness a reader cannot verify as written, an automatable check left as fuzzy prose, a portability gap (a hardcoded path or an assumption that breaks when the artifact runs elsewhere).
- **Suggestion** — a flow or wording improvement that does not affect correctness.

### Information architecture (`information-architect`, skills only)
- **Critical** — never; an IA problem does not stop the artifact running.
- **Warning** — a body-vs-`references/` split or reference-tree layout that would lose or mislead a first-time reader, or step ordering that defeats orientation (content the progressive-disclosure guidance says belongs in `references/` inlined in the body, or vice versa).
- **Suggestion** — navigation or labeling polish a reader can live with.

### Security of the artifact's own design (`adversarial-security-analyst`, by signal)
- **Critical** — a demonstrated unsafe path in the artifact's design: it feeds untrusted input to an agent or a script without the isolation the guidance requires, or runs a script on unvalidated external data.
- **Warning** — a safety discipline the guidance requires that the artifact omits, without a demonstrated exploit (untrusted content read without marker discipline, an over-broad tool grant on a path that touches external data).
- **Suggestion** — a hardening nicety on a path the artifact controls.

### Content audit (`content-auditor`, change scope only)
- **Critical** — the edit dropped a rule or step whose absence breaks the artifact.
- **Warning** — the edit dropped a load-bearing instruction that still runs but now misleads or under-specifies. Content that was present-and-kept or correctly-removed is not a finding.

### Operator experience (`user-experience-designer`, by signal)
- **Critical** — never; a UX problem does not stop the artifact running.
- **Warning** — an interaction that would mislead the operator into a wrong or destructive choice: an unlabeled or ambiguous menu option, a confirmation gate missing before an irreversible action, an unclear attended/unattended distinction, a missing error or recovery state.
- **Suggestion** — wording, ordering, or feedback polish on the operator flow.

### Control-flow edge cases (`edge-case-explorer`, by signal)
- **Critical** — a boundary or combined state that makes the skill run a step wrongly or loop without terminating (a counter that never resets, a state pair with no handling).
- **Warning** — an unhandled boundary the skill should address (zero-item, single-item, cap-reached mid-flow, resume after halt) that degrades rather than breaks.
- **Suggestion** — a defensively-worth-noting case unlikely in practice.

### Script resilience (`on-call-engineer` / `devops-engineer`, by signal)
- **Critical** — a script defect that corrupts state or loses work: a non-atomic write or commit that can leave a half-applied result, a non-idempotent operation on a retry path, a swallowed error that hides a failed step.
- **Warning** — a resilience gap short of corruption: a missing fail-fast guard, an unquoted expansion, a temp-file race, an exit code the skill branches on but the script never sets.
- **Suggestion** — a hardening nicety on a path that cannot corrupt state.

### Script-invocation contract (owned by the conformance & quality reviewer)
- **Critical** — the skill instructs a script run without the invocation syntax an agent needs (no `${CLAUDE_SKILL_DIR}` path, missing or mis-ordered arguments), or branches on a key or exit code the script never emits — the step cannot execute as written.
- **Warning** — the invocation runs but drifts from `script-execution-instructions.md` (a fenced code block instead of a prose step, a bare relative path, an uncaptured output the next step needs).
- **Suggestion** — a clarity improvement to an otherwise correct invocation.
