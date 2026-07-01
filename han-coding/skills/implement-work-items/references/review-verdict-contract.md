# Review-verdict contract

The driver dispatches the review stage as one sub-agent at depth 1 through the
`Agent` tool. That sub-agent retains the `Agent` tool so it can run
`han-coding:code-review` and let that skill fan out its specialist panel at
depth 2, keeping the panel's deliberation out of the driver's context. The
sub-agent persists the full review record to a driver artifact and returns only
the condensed verdict below.

The `Agent` path returns free-form text with no schema validation, so this
contract is imposed by instruction and the driver parses it fail-closed: a
verdict the driver cannot trust as a clean, full-coverage pass is
**untrustworthy** and halts the run rather than being treated as a cleared gate.

Copy the "Required return format" block verbatim into the review and re-review
dispatch prompts. Do not paraphrase the section headers: the driver parses on
them. Each `<...>` placeholder describes what to put in that section; replace it
with the actual content.

## Required return format

Return exactly these named sections, each header on its own line, in this order:

```
RECOMMENDATION: <the code-review Review Recommendation, verbatim on one line (for
example "do-not-merge", "approve with suggestions", or "approve"). A Critical
finding yields a do-not-merge recommendation. This is the human-legible headline
of the verdict.>

COVERAGE:
<The full-coverage attestation: state that the review ran at full specialist
coverage and name the code-review panel members that ran. If any selected panel
member did not run or returned nothing, say so here rather than omitting it; a
partially-covered panel is reported, not hidden.>

FINDINGS (at and above the gate threshold: <critical | warning>):
- <TASK-ID> (<severity>) <file:line>: <one-line claim>
- <one line per finding at or above the threshold, each with its code-review task
  ID, its severity, its file:line (the code location the finding concerns, in
  code-review's file_path:line_number form, not a location in the durable
  record), and a one-line claim. A security finding uses its SEC-<n> task ID and
  always shows its severity tier explicitly (for example "SEC-001 (Critical)"),
  because the SEC id does not encode a tier; it is placed here when that tier is
  at or above the threshold, the same as any other finding.>
<or the single line "none at or above the gate threshold" when the item clears
the gate, so the driver can tell a clean pass from a missing section>

BELOW THRESHOLD (counts only):
- Suggestion: <N>
- YAGNI: <N>
- Security below threshold: <N>
<counts only, for findings below the threshold; the full detail, including every
security finding, lives in the durable record, and these do not gate>

DURABLE RECORD: <repo-root-relative path to the full record you wrote,
.implement-work-items/reviews/<W-N>.md. Write the record with the same task IDs
you list above, so a reader can join a condensed finding to its full entry.
The fix sub-agent reads it during a fix round and the operator reads it after
a review-gated halt, so it is required on every verdict.>
```

## Gate evaluation

The item clears the review gate when FINDINGS reports "none at or above the gate
threshold". Any finding listed under FINDINGS is a gate-blocking finding that
enters the fix loop (or, at a fix cap of zero, halts the run). Severities are
`code-review`'s vocabulary: Critical, Warning, and Suggestion, plus the advisory
YAGNI class (never gating) and Security findings (SEC). Security is not a
severity of its own: each `code-review` security finding carries its own severity
tier (Critical, Warning, or Suggestion), so a security finding gates by that tier
exactly like any other finding, and the verdict shows the tier inline because the
`SEC-<n>` id does not encode it.

## How the driver parses it (halt conditions)

The driver treats any of the following as an untrustworthy verdict and halts the
run through the Halt Procedure, rather than treating the gate as cleared:

- RECOMMENDATION is missing or empty.
- COVERAGE is missing or empty (an empty verdict with no coverage attestation).
- COVERAGE reports a partially-covered panel (any selected member did not run).
- FINDINGS is not evaluable against the threshold: the section is missing, or a
  listed finding omits its severity so the driver cannot tell whether it sits at
  or above the threshold (a security finding shown without its Critical, Warning,
  or Suggestion tier is not evaluable).
- DURABLE RECORD is missing, empty, or names a path the driver cannot read.

An untrustworthy verdict halts immediately, both on the initial review and on a
fix-round re-review; it is never counted as a not-cleared fix round.
