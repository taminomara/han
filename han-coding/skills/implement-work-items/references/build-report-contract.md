# Build-report contract

The driver dispatches each build and fix sub-agent through the `Agent` tool with
a prompt that instructs the sub-agent to run `han-coding:tdd` and to return its
result in the exact format below. The `Agent` path returns free-form text with
no schema validation, so this contract is imposed by instruction and the driver
parses it fail-closed: a return that is missing a required section, uses a
status outside the fixed vocabulary, or omits evidence the change requires is
**untrustworthy** and halts the run.

Copy the "Required return format" block verbatim into the build and fix dispatch
prompts. Do not paraphrase the section headers: the driver parses on them. Each
`<...>` placeholder describes what to put in that section; replace it with the
actual content.

## Required return format

Return exactly these named sections, each header on its own line, in this order:

```
STATUS: <"built" = the item was implemented and the tdd gate is green. "blocked"
= the item cannot be completed and you are escalating it in ESCALATION. No other
value is valid.>

FILES:
- <repo-root-relative path> (<created | modified | deleted>)
- <one line per file changed; a rename is a delete of the old path plus an add of
  the new. List every file. The driver's own git inspection is authoritative for
  the scope check; this list is your declaration and a cross-check.>

RED-TO-GREEN EVIDENCE:
<The observed test-failure-then-pass evidence. For new behavior: the test added,
its observed failing run (the failing assertion or the missing symbol, with the
runner's summary line), then its observed passing run after the production code
landed. For a bug fix: the regression or smoke test that reproduces the fault,
red before the fix and green after; a fix adds the corrected behavior, so it
carries this evidence too. Use the single line "not applicable (untestable:
<reason>)" ONLY when the change has no testable surface, such as a
documentation-only fix or a change to an untestable artifact like a skill or
other markdown with no test harness.>

FINAL GATE:
- <check name>: <pass | fail | not run | not required>: <the runner's summary
  line. One line per configured check; list each test suite separately (for
  example "unit tests" and "e2e tests" when both exist), plus lint and build. Use
  "not required" only when a check genuinely does not apply to this project,
  never to skip a check that exists. This is your self-report; the driver re-runs
  the project's checks itself and trusts its own result over this section.>

ESCALATION:
<When STATUS is blocked: the blocker you could not resolve (the spec contradicts
the item, the acceptance criteria are unsatisfiable, or the item cannot be built
as written), with enough detail for the operator to act. When STATUS is built:
the single word "none".>
```

## How the driver parses it (halt conditions)

The driver treats any of the following as an untrustworthy report and halts the
run through the Halt Procedure, rather than committing or advancing:

- Any of the five named sections is missing or empty.
- STATUS is a value other than `built` or `blocked`.
- STATUS is `built` but FILES lists no path (a build with no file changes; the
  driver also confirms this against its own git inspection, after exclusions).
- RED-TO-GREEN EVIDENCE neither shows an observed failing run followed by a
  passing run nor declares "not applicable (untestable: <reason>)". A change with
  a testable surface (new behavior or a bug fix) must carry the evidence; only a
  genuinely untestable change may use the not-applicable declaration.
- STATUS is `blocked` but ESCALATION is empty.

A STATUS of `blocked` is a clean escalation, not a malformed report: the driver
halts and surfaces the ESCALATION content as the halt's supporting evidence. A
FINAL GATE that reports a failing check is not itself a halt condition here; the
driver re-runs verification independently and routes a genuine failure into the
fix loop.
