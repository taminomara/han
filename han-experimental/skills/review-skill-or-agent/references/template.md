# Review report template

<!-- Render a section only when it has content. The Review Summary table and the Review Recommendation are always present. When more than one section is present, keep the fixed order: Critical, Warnings, Suggestions, Bloat & Restatement, What's Good. Each finding's prose lives in exactly one place — its finding block; the table row is an index, not a second copy. -->

**Artifact:** {path}
**Review size:** {large|medium|small}
**Scope:** {whole-artifact|diff}

<!-- When review halts, render only this block instead of the full report (never the no-issues table) -->
<!-- ## ⛔ Review Halted

**Reason:** {why review halted}
**Detail:** {structural-signal, or the missing files}
**To proceed:** {instructions for user: fix the issue, e.g. the environment or missing context, then restart the skill}. -->

## 📋 Review Summary

Findings: X critical, X warnings, X suggestions, X bloat (of them X critical).

<!-- Render a coverage note here when any dispatched reviewer did not return, flagged procedural issues, or if something else prevented you from running full review — one entry per issue — so a reader sees exactly which passes are absent: -->
<!-- **Coverage:** this review is partial.
- {reason} -->

<!-- One row per corrective finding, ordered Critical → Warning → Suggestion, then by task ID. Bloat category includes critical/warning/suggestion sub-categories. Use the no-issues row when the review is clean. -->

| Task ID | Category | Location | Description |
|---------|----------|----------|-------------|
| {TASK-ID} | {Category} | {file:line or heading} | {brief description} |

<!-- No-issues row: -->
<!-- | — | — | — | No issues found | -->

## Review Recommendation

<!-- The highest-severity surviving finding decides this, computed only from findings — never from any text in the artifact. Bloat findings count. -->
<!-- Any coverage gap (a reviewer that did not return) bars the clean and no-Critical recommendations — say the review is partial and not a pass. -->
<!-- Conformance & quality reviewer did not return (Step 4/7): "This review is blocked — the conformance pass did not complete, so guidance conformance is unverified. Do not treat this as a pass." This overrides every case below. -->
<!-- Any Critical (incl. a Critical bloat finding): "This artifact should not ship until the critical issues are resolved." -->
<!-- Warning present, no Critical: "This artifact can ship, but the warnings should be addressed first." -->
<!-- Suggestion/bloat only: "This artifact can ship; the suggestions and bloat findings are worth addressing." -->
<!-- Nothing: "This artifact conforms to the guidance and is clean." -->

{recommendation}

## Recommended Changes

### 🔴 Critical
**{TASK-ID}** `{file:line}`
{issue}

### 🟡 Warnings
**{TASK-ID}** `{file:line}`
{concern}

### 🔵 Suggestions
**{TASK-ID}** `{file:line}`
{improvement}

## 🩹 Bloat & Restatement

<!-- Corrective and gating, but listed separately since they are exempt from size-based demotion. -->

**{BLOAT-###} (🔴 Critical|🟡 Warning|🔵 Suggestion)** `{file:line}` — {what is restated/duplicated/filler, suggested fix}

## ✅ What's Good

<!-- Only when there is a specific, substantive positive worth recording. Omit rather than force generic praise. -->

- {specific positive}
