# Review Findings: implement-work-items Driver Automation and Resumability Hardening

Records every finding from `iterative-plan-review` passes over this spec, and how each was resolved. The spec is the primary artifact (edited in place); decisions live in [decision-log.md](decision-log.md) and load-bearing mechanics in [feature-technical-notes.md](feature-technical-notes.md). Round history is in [review-iteration-history.md](review-iteration-history.md).

Spec-aware mode: engaged. Findings continue the numbering from the `plan-a-feature` team-findings (F1–F13); this review starts at F14.

## Major findings

### F14: The no-commit audit terminal state is now redundant

- **Agent:** self-review (lightweight); user-proposed
- **Category:** YAGNI candidate (strictly simpler version available)
- **Finding:** The spec's No-output audit flow, and the underlying skill it revises, carry a distinct no-code-commit terminal state for audits — recorded in the skill as the `no-commit-done` Log token and reconstructed as the `done-no-commit` state. Its sole purpose is to stop resume/re-grounding from flagging an audit's legitimately-absent code commit as a missing-commit divergence. The user asked whether it can now be dropped, proposing instead that the audit result be committed as a separate commit.
- **Evidence considered:** `references/durable-record-protocol.md` §Integrity gives `no-commit-done` its own positively-safe row ("valid as-is — it carries no commit by design"); `scripts/scan-run-history.sh` maps the `no-commit-done` token to the `done-no-commit` reconstructed state; `references/no-output-completion.md` and `SKILL.md` Step 3.4 / Halt Procedure special-case it in completion and halt reporting; the second-run retrospective explicitly flagged the `done-no-commit`/`no-commit-done` split as repeatedly reading like a bug. Decisive: this session's D8 captures an audit's findings in the committed review/confirmation record, and D11 commits each round's review record when it is written — so under the revised spec an audit **always** produces a committed artifact. The premise of `no-commit-done` ("this item has no commit") is therefore already false. (Trust class: codebase + provided operator feedback.)
- **Resolution:** Dropped the distinct no-commit terminal state (simpler-version path). An audit completes with an ordinary `done` entry backed by the commit of its confirmation record (which D8 + D11 already produce), and resume verifies a completed audit by the same "done ⇒ backing commit resolves" rule it uses for any item — retiring the separate integrity row, the completion/halt special-casing, and the confusing reconstructed-state-versus-token naming split. The user's "separate commit" idea is honored in the cleaner form of reusing the already-committed confirmation record rather than forcing a new commit. Amended D8 (decision, rejected alternatives, cross-refs) and D14 (integrity rule unified), and added T2 for the resolution-commit mechanic. At implementation time this ripples as pure simplification into the record protocol (drop the token), the history scanner (drop the reconstructed state), and completion/halt reporting (audits are ordinary done items).
- **Resolved by:** evidence
- **Raised in round:** R1
- **Changed in plan:** No-output audit (Exit), Edge Cases and Failure Modes
- **Changed in tech-notes:** T2

### F15: Decision-staleness handling adds a fuzzy detection branch

- **Agent:** self-review (lightweight simplicity audit)
- **Category:** YAGNI candidate (strictly simpler version available)
- **Finding:** D10's resume handling had the driver detect whether a recorded decision's item "materially changed" and surface-and-ask if so. "Material change" is an undefined, fuzzy criterion, and the detection is a new logic branch — added complexity in a feature whose stated purpose is to make the skill leaner. The user's simplicity lens surfaced it.
- **Evidence considered:** The Resume flow already "announces the concrete next action and waits for the operator's go-ahead" (spec Resume; `SKILL.md` Step 2.3 today does the same). So a human gate already exists at exactly the point a stale decision would steer a build; the material-change detection duplicates that gate with driver-side logic and would additionally require defining "material change." (Trust class: codebase + spec.)
- **Resolution:** Replaced the driver-side material-change detection with surfacing the restored decision in the resume announcement the driver already makes; the operator confirms or corrects it before the go-ahead. Same safety (a stale decision is caught by a human before it steers a build), no new detection branch, nothing to define. A decision that no longer maps to a current item surfaces as an ordinary reconstruction mismatch. Merged the two D10 edge-case rows into one. Amended D10 (decision, rationale, rejected alternatives, cross-refs).
- **Resolved by:** evidence
- **Raised in round:** R2
- **Changed in plan:** Resume, Edge Cases and Failure Modes
- **Changed in tech-notes:** —

## Minor edits

- F16: Primary Flow step 3 restated the pre-run commit-or-stash / green-suite detail already in Preconditions; trimmed to a pointer — self-review — Primary Flow.
