# How To: Triage and Investigate a Bug

A walkthrough for getting from "something is broken" to a root cause backed by file-level evidence and a fix plan you can trust. The primary tool is [`/investigate`](../skills/investigate.md); [`/issue-triage`](../skills/issue-triage.md) handles the cases where you need to document the report for later instead of working it now.

> See also: [How-to index](./README.md) · [Quickstart](../quickstart.md) · [Skills](../skills/README.md)

## Before you begin

- You have a concrete symptom. An error message, a stack trace, a screenshot, a failed deploy, a customer report. The sharper the symptom, the faster the investigation converges.
- You have access to relevant logs. Application logs, container logs, monitoring dashboards, Sentry events, whatever the project uses. Han's agents read the codebase; they cannot see your logs unless you bring them in.
- You know which repository the bug lives in. If the symptom crosses service boundaries, you will name each one as you go.

## What you'll end up with

- For an immediate investigation: an investigation report with the symptoms, numbered evidence (`E1, E2, …`), root-cause analysis, a fix plan, and validation findings (`V1, V2, …`) from an adversarial pass that already tried to break the fix.
- For a triage: a structured issue document that classifies what you know and what you do not, plus a recommendation for the right next skill (often `/investigate`, sometimes `/research` or `/plan-a-feature`).

When you have a report whose recommendation has survived adversarial review, the investigation is complete. When you have a triage document filed in the right place, the issue is captured and ready to pick up later.

## The happy path

The workflow has two short phases. The first phase decides whether to investigate now or triage for later. The second phase does the actual investigation and validation. Most bugs route through Phase 2 directly; Phase 1 only takes a step when the report is too vague to investigate or when you do not have time to work it today.

### Phase 1: Decide whether to investigate now

1. **Read the report you have.** If it names a specific symptom, a reproduction path, or a specific failure mode, skip to Phase 2. If it is vague ("the site feels slow," "something is wrong with billing"), move to step 2.

2. **If the report is vague or incomplete, run [`/issue-triage`](../skills/issue-triage.md).** A prompt that works well:

    > `/issue-triage {context: this bug was found here, where I saw this error, screenshot, link to the report, etc.}`

    The skill classifies the issue, names what information is missing, assesses severity and reproducibility, and recommends a next step. The recommendation is usually `/investigate`, but for some reports it is `/research` (a question, not a bug) or `/plan-a-feature` (a missing capability, not a defect).

3. **If you want to capture the report for later instead of investigating now**, ask han to post the triage output into your issue tracker. For a GitHub-based project:

    > Post the triage report as an issue in {owner/repo}.

    The triage document becomes the body of the issue. When someone picks it up later, they can run `/investigate` against it.

### Phase 2: Investigate

1. **Run [`/investigate`](../skills/investigate.md) with the concrete symptom and any context you already have.** A prompt that works well:

    > `/investigate {context: this bug was found here, where I saw this error, screenshot, link, etc.}`

    Han dispatches at least two `evidence-based-investigator` agents in parallel, each working a different angle (the error path, the data flow). When the symptom calls for it, a specialist also dispatches: `concurrency-analyst` for intermittent / race / timeout bugs, `behavioral-analyst` for data-flow and error-propagation bugs, `data-engineer` for schema, query, or migration bugs.

2. **Bring in the logs.** Han's agents do not see production logs unless you give them. As the investigation runs, paste in the log excerpts that line up with the symptoms:

    > Examine these relevant log excerpts: {paste}. Use what's there to narrow the angle.

    Substitute whichever log source is authoritative for your project: container logs from `docker-compose logs`, the Render / Heroku / Fly dashboard, Sentry events, an APM trace, a Grafana panel.

3. **If you have a browser integration configured, use it.** When the symptom is observable in the UI:

    > Use the browser integration to view the screen at {URL}, reproduce the steps, and capture the errors.

    Han can navigate the UI, capture screenshots, read the console, and pull network requests. The actual error in the browser often points the investigation at a place the codebase trace would not reach on its own.

4. **Read the draft report and push back.** The skill presents an investigation report with numbered evidence, a root-cause analysis, a fix plan, and the validator's adversarial findings. Read each section. If the validator already pushed back on the root cause and reshaped the fix, that is the workflow doing its job — read the `V#` adjustments carefully.

5. **If the fix plan needs further stress-testing, iterate on it.** When the fix touches cross-cutting concerns or you do not yet trust the plan:

    > `/iterative-plan-review {investigation file location}`

    Walk through any new open items. Otherwise, move to step 6.

6. **Approve the plan or push back.** When the plan is ready, approve it and let han implement the fix. If something still does not sit right, ask han to revise the part that does not survive your reading; the investigation will re-validate before presenting again.

## Variations

- **The report is actually a feature request.** `/issue-triage` will sometimes return "this is a missing capability, not a defect" and recommend `/plan-a-feature`. Follow the recommendation; do not force a fix on a non-bug.

- **The investigation finds no root cause.** When the evidence does not converge on a single root cause, the report says so and names what additional evidence (a log range, a specific reproduction, a specific user account) would close the gap. Gather what is named and re-run; do not let the skill guess.

- **The bug is intermittent.** Mention the intermittent nature in the prompt. Han routes a `concurrency-analyst` into the investigation alongside the generalist investigators. Without that signal, intermittent failures often get classified as a data-flow problem and the analysis misses the race.

- **You want to confirm the fix held after shipping.** Re-run `/investigate` against the incident context with *"did this fix hold?"* framing. Validation findings from the new run confirm or falsify the hypothesis under production conditions.

- **The investigation surfaces a procedure the team will reuse.** When the same symptom is likely to recur, pair `/investigate` with [`/runbook`](../skills/runbook.md). Investigate captures the root cause and fix; the runbook captures the procedure for the next engineer who sees the same symptom.

## What you should expect at each step

- **Evidence is numbered.** Every claim the investigation rests on gets an `E#` ID. The root-cause analysis cites those IDs directly, so you can trace every conclusion back to its source.
- **The validator pushes back.** The adversarial validation step is not ceremony. It frequently downgrades a root cause, surfaces counter-evidence, and reshapes the fix. Treat `V#` findings as first-class input, not as a review pass to skim past.
- **Some bugs do not survive triage.** A non-trivial fraction of reported "bugs" turn out to be expected behavior, an unimplemented feature, or a configuration issue. `/issue-triage` is honest about this; it is not a failure to find out the report is not what it looked like.
- **A re-run is cheap.** Investigations are stateless. If the first run misses, re-run with the new context and the agents start fresh.

## Where to go next

- [Plan a feature, end to end](./plan-a-feature.md) is the right guide when triage says the report is a missing capability rather than a defect.
- [Research a decision](./research-a-decision.md) is the right guide when triage says the report is really a question about an approach the team has not yet picked.
- The skill long-form docs ([investigate](../skills/investigate.md), [issue-triage](../skills/issue-triage.md), [iterative-plan-review](../skills/iterative-plan-review.md), [runbook](../skills/runbook.md)) cover each step in depth.
- [`/code-review`](../skills/code-review.md) is the right next step when the fix lands and you want a review of the change end-to-end before merge.
