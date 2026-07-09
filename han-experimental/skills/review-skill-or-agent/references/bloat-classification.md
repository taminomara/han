# Bloat and Restatement Classification

Severity is driven by what the bloat *does* — mislead, tax attention, or merely add a line — not by which category it falls in, so use the bands below rather than a category-to-tier lookup.

## Critical

Restatement that makes the artifact wrong or unrunnable — narrow by design, reserved for defects that *restatement itself* produces:

- **Contradictory restatement** — the same rule stated twice with materially different content, so a reader following the artifact literally cannot tell which instruction governs.
- **Repetition that drifts** — "apply X: it's A, B, and C rules" where A, B, and C are each described differently in X, so the reader cannot tell deliberate scoping from copy-paste drift.

*This is Critical:* Step 2 says "always dispatch the reviewer for every artifact"; Step 5, restating the rule "for completeness," says "dispatch the reviewer only for large artifacts." Two restatements of one rule that disagree.

*Also Critical:* "perform shift procedure as stated by `shift-procedure.md`: shift should be atomic and idempotent", while "shift-procedure.md" allows non-atomic shifts and doesn't mention idempotency at all.

## Warning

The default tier: bloat that does not mislead but taxes a reader's and the model's attention on every run.

- **Duplication of a linked reference** — the body restates rules or examples a `references/` file already fully specifies (not a one-line pointer — an actual inline re-statement).
- **Re-explaining a rule stated earlier** — a step restates a constraint the preceding sentence or step already set, adding no new information.
- **Repetition without drift** — "apply X: its A, B, and C rules" while just pointing to X is enough. Warning, not Suggestion, because it repeats.

*This is Warning:* a step says "Read the full file for context, not just the diff, because partial context leads to wrong conclusions," immediately followed by "Remember: always read the whole file, since incomplete reads produce incomplete answers." Same rule, same reasoning, two sentences apart.

*Also warning:* "read sub-agent prompt from `prompt.md` and pass it verbatim: its ground rules section and its output format section". Agent will read sub-agent prompt one way or another, no need to describe it here.

*Not a warning:* "apply step 1 and 2 from `shift-procedure.md`" if `shift-procedure.md` contains more steps. Explicit mention of 1 and 2 serves to narrow `shift-procedure.md`.

## Suggestion

Single-instance bloat that costs a little attention but does not repeat or restate a documented rule.

- **Restatement of the obvious** — a self-evident consequence a competent reader already infers ("since the file is now saved, the write is complete").
- **Filler transitions** — "Now let's move on to the next step," "With that done, we can proceed" — connective tissue with no instructional content.
- **Back-referential meta-commentary** — "as mentioned above," "as we discussed in Step 2," when the pointer adds no instruction the reader needs to act.
- **Audience-mismatched reference** — prose that orients a reader other than the agent executing it: a dispatched sub-agent's brief that describes the orchestrator's own logic, a comparison to a sibling skill or agent, or a justification for why the artifact was designed a certain way. The executing reader cannot act on any of it — a worker's brief carries only what the worker does, and design rationale belongs in the design docs where a maintainer will look.
- **Negative-space filling** — a sentence narrating what a step does *not* do, what moved elsewhere, or what it used to do: "this step never verifies X — that happens in step Y." Nothing in the step raised X, so the reader never expected it here; the disclaimer answers a question no one asked and quietly puts X back in the reader's head. This is the residue an LLM leaves when it strips an instruction while simplifying and then cannot resist explaining the gap — the absence needs no narration; delete it.

*This is Suggestion:* a step opens with "As mentioned in the introduction, this skill reviews self-contained python scripts." A single non-repeating, non-misleading instance.

*Also Suggestion:* a worker's dispatch brief explains that "the orchestrator will then de-duplicate and validate your findings" — the worker doesn't need this information to act; or an intro adds "this step no longer resolves the guidance path itself; that moved to the detector," narrating an absence the reader never noticed.

## The heuristic the pass applies

For each candidate, ask what it *does*: makes the artifact wrong (Critical), repeats or duplicates a rule (Warning), or adds a self-evident, filler, misplaced, or negative-space line once (Suggestion).

The reader-reaction test: if a sentence makes a capable reader think "well, duh," "you just said that," "I've never seen that and don't need to," or "nothing raised that" — it is bloat, and cutting it loses no instruction.

The LLM smell test: three-fold repetition, negative space filling.
