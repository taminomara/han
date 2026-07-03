# Review-verdict contract

The driver dispatches the review as one depth-1 sub-agent through the `Agent`
tool. That sub-agent runs the item's recorded review, maps its findings into the
one **normalized verdict** below, persists the full record, and returns only the
condensed verdict. The driver gates one shape for every source:

- `han-coding:code-review` (skill) fans out its panel at depth 2.
- `han-core:content-auditor` / `han-core:information-architect` (agents) run against the change.
- a human read is captured directly (see [human-review-capture.md](./human-review-capture.md)).

The `Agent` path is unvalidated, so this contract is imposed by instruction and
parsed fail-closed: a verdict the driver cannot trust as a clean, full-coverage
pass is **untrustworthy** and halts the run.

Copy the "Required return format" block plus the source's row from "Severity
mapping" into the dispatch prompt. Do not paraphrase the headers; the driver
parses on them.

## Reference material the dispatch supplies

Every source gets the work item and the spec sections it references. A
**content audit** additionally gets the **prior version of the edited document**
(the reference it compares against); without it the verdict is unreliable.

## Required return format

Return exactly these sections, each header on its own line, in order:

```
RECOMMENDATION: <one-line headline, verbatim (for example "do-not-merge", "approve
with suggestions", "approve"). A Critical finding yields do-not-merge.>

COVERAGE:
<attest the review ran, in the source's form (see "Coverage"). Report any part
that should have run and did not.>

FINDINGS (at and above the gate threshold: <critical | warning>):
- <TASK-ID> (<tier>) <location>: <one-line claim>
- <one line per finding at or above the threshold: task ID, normalized tier
  (Critical | Warning | Suggestion), location (see "Location"), claim. A security
  finding shows its tier inline, e.g. "SEC-001 (Critical)".>
<or the single line "none at or above the gate threshold" for a clean pass>

BELOW THRESHOLD (counts only):
- Suggestion: <N>
- YAGNI: <N>
- Security below threshold: <N>
<counts only; full detail lives in the durable record. Report 0 for a class the
source lacks.>

DURABLE RECORD: <repo-root-relative path to the full record you wrote,
.implement-work-items/reviews/<W-N>.md, using the same task IDs. Required on every
verdict, including a clean one.>
```

## Severity mapping

Each source maps its native findings into the driver's three tiers before it fills
FINDINGS:

| Source | Mapping |
|---|---|
| `code-review` | identity (Critical/Warning/Suggestion); YAGNI advisory, never gates; each `SEC-<n>` gates by its own tier |
| `information-architect` | Blocks comprehension → Critical; Degrades → Warning; Friction → Suggestion; Polish → below threshold |
| `content-auditor` | each Missing fact → Warning; Present and Correctly Removed are not findings; no Critical (no field to derive it from) |
| human read | operator states the tier directly, confirmed against the threshold ([human-review-capture.md](./human-review-capture.md)) |

## Coverage

- Panel (`code-review`): name the members that ran; report any that did not.
- Single agent (`content-auditor`, `information-architect`): attest the agent ran to completion.
- Human read: attest the operator reviewed the change.

The driver halts on an **absent** attestation, not on one that omits panel wording.

## Location

`file_path:line_number` for code; a document anchor (a heading, or "document-wide")
for prose. A prose finding needs no line number.

## Gate

The item clears when FINDINGS is "none at or above the gate threshold". Any listed
finding gates (or, at fix-cap zero, halts). A `none`-review item runs no review and
clears on a verification pass alone.

## Halt conditions

Halt as untrustworthy (never a cleared gate, never a not-cleared fix round) when:

- RECOMMENDATION missing or empty.
- COVERAGE missing, empty, or reporting that part of the review did not run.
- FINDINGS missing, or a finding omits its tier (not evaluable against the threshold).
- DURABLE RECORD missing, empty, or unreadable.
