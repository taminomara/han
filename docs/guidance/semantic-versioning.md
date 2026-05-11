# Semantic Versioning for Plugins

Plugin versions in `plugin.json` follow [semantic versioning](https://semver.org/). Claude Code and other agents rely on the `version` field (synced to `marketplace.json` via `scripts/build.sh marketplace`) to detect that updates are available. Incorrect or stale versions mean agents won't know a plugin has changed, and users won't receive updates.

## Major Version (X.0.0) — Breaking Changes

Bump the major version when the update would break existing users' expectations or workflows.

Examples:

- Skill rewrites that fundamentally change behavior or output format
- Removing a skill from a plugin
- Renaming a skill (breaks existing `/skill-name` invocations)
- Major behavior changes that would surprise existing users (e.g., a review skill that now auto-posts instead of showing a draft)

## Minor Version (x.Y.0) — Backwards-Compatible Additions

Bump the minor version when adding new functionality that doesn't change existing behavior.

Examples:

- Adding a new skill to a plugin (new file, no existing files changed)
- Adding a new `references/` file to an existing skill
- Adding new optional capabilities to an existing skill without changing existing behavior

## Patch Version (x.y.Z) — Bug Fixes

Bump the patch version for fixes that don't change behavior from the user's perspective.

Examples:

- Fixing a typo in a skill description or prompt
- Fixing a broken context injection command
- Adjusting `allowed-tools` to fix permission issues
- Updating a script to handle an edge case

## One Bump Per Branch

**The rule:** a plugin's version bumps **exactly once per unmerged branch**. Additional changes on the same branch do not add further bumps, unless a later change escalates to a higher semver octet — in which case the bump is **recalculated from the branch's baseline**, not stacked on top of the previous bump.

The priority order is **major > minor > patch**. The baseline is whatever version of the plugin is on `main` at the point the branch diverged (or, for a branch that renames or resets a plugin, the reset version established on the branch — see "Plugin rename or reset" below).

### How to apply the rule

1. **First change on the branch:** bump the version for that change (patch, minor, or major) from the baseline.
2. **Subsequent same-or-lower-priority changes:** leave the version alone. The existing bump already covers them.
3. **Subsequent higher-priority change:** re-bump **from the baseline**, using the new level. Reset lower segments as semver requires (a minor bump resets patch to 0; a major bump resets both minor and patch to 0). Do not stack.

### Examples

Assume `main` is at **v1.0.0** in every example below.

**Example 1 — Multiple same-priority changes**

| Step | Change | Version | Why |
|------|--------|---------|-----|
| 1 | Fix a typo (patch) | **v1.0.1** | First change on the branch — patch bump from baseline |
| 2 | Fix another typo (patch) | **v1.0.1** | Same priority as step 1 — no additional bump |
| 3 | Fix a third typo (patch) | **v1.0.1** | Still the one patch bump — no additional bump |

**Example 2 — Escalation through priorities**

| Step | Change | Version | Why |
|------|--------|---------|-----|
| 1 | Fix a typo (patch) | **v1.0.1** | Patch bump from baseline |
| 2 | Fix another typo (patch) | **v1.0.1** | Same priority — no additional bump |
| 3 | Add a new skill (minor) | **v1.1.0** | Higher priority — re-bump from baseline as minor, absorbs the patch |
| 4 | Add another new skill (minor) | **v1.1.0** | Same priority as step 3 — no additional bump |
| 5 | Remove an existing skill (major) | **v2.0.0** | Higher priority — re-bump from baseline as major, absorbs minor and patch |

The final version merged to `main` is **v2.0.0**, not v2.1.1 or v1.1.1.

### Plugin rename or reset

If a branch renames a plugin, splits one plugin into two, or otherwise resets a plugin's version baseline to a new value (e.g., setting a renamed plugin to **v1.0.0** as the start of its new identity), the reset **is** the branch's one bump. It carries the effective weight of a major change. Subsequent changes on the same branch — new skills, bug fixes, removals — do not bump further, because no change can escalate higher than the reset.

For example, if a branch renames `foo` to `bar` and sets `bar`'s version to **v1.0.0**, then adding a new skill to `bar` on the same branch does **not** bump to v1.1.0. The version stays at **v1.0.0** — the rename/reset already covers the branch's change set.

After bumping (or not bumping), run `scripts/build.sh marketplace` to sync the current `plugin.json` version to `marketplace.json`.

## Summary Checklist

1. **One version bump per branch.** The first change bumps the version from the baseline on `main` (or from a reset baseline established on the branch).
2. **Subsequent same-or-lower-priority changes do not bump.** The existing bump already covers them.
3. **Higher-priority changes re-bump from the baseline.** Do not stack bumps — a minor change followed by a major change ends at **v2.0.0**, not v2.1.0 or v2.1.1.
4. **Major:** breaking changes, removals, renames, behavior surprises.
5. **Minor:** new skills, new files, new optional capabilities.
6. **Patch:** typo fixes, permission fixes, edge case handling.
7. **Plugin rename or reset** is itself the branch's one bump; no further bumps on that branch.
8. Run `scripts/build.sh marketplace` after bumping to sync `marketplace.json`.
9. When in doubt, bump minor — it signals "something new" without implying breakage.

Cross-reference: [Context Injection Commands](./skill-building-guidance/context-injection-commands.md) | [allowed-tools: AskUserQuestion](./skill-building-guidance/allowed-tools-AskUserQuestion.md)
