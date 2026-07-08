#!/usr/bin/env bash
# Ephemeral crafted-branch checks for scan-run-history.sh.
# Usage: scan-run-history.test.sh <path-to-scan-run-history.sh>
#
# Covers three concerns: run classification (fresh/resume/refuse/no-base) and the
# injection/boundary defenses; block-aware Log reconstruction (lifecycle entries
# come only from the Log: block, never from the labeled blocks below it); and the
# plan-folder-derived ledger path (dirname of the work-items path, not repo root).
# A writer<->reader round-trip proves the write-run-record.sh output reconstructs
# to the exact four-token lifecycle. Pure bash; no jq/python3.
set -u

# Resolve the script under test to an absolute path once: the checks cd into
# throwaway repos, so a relative $1 would not resolve from there.
SCRIPT=$(cd "$(dirname -- "$1")" && pwd)/$(basename -- "$1")
# The writer lives beside the reader; the round-trip check drives it.
WRITER=$(dirname -- "$SCRIPT")/write-run-record.sh

PASS=0; FAIL=0
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

get() { printf '%s\n' "$1" | awk -F': ' -v k="$2" '$1==k{print $2; exit}'; }
# Extract the lines between the items-start / items-end markers.
items() { printf '%s\n' "$1" | awk '/^items-start$/{f=1;next} /^items-end$/{f=0} f'; }

mkrepo() { git init -q -b "$2" "$1"; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t; }
cempty() { git -C "$1" commit -q --allow-empty "${@:2}"; }

# ============================================================================
# Classification and injection/boundary defenses
# ============================================================================

# 1. develop-base fresh: base passed as arg, no run commits -> fresh
d=$TMPROOT/develop
mkrepo "$d" develop
cempty "$d" -m init
git -C "$d" checkout -q -b feature
out=$(cd "$d" && bash "$SCRIPT" "docs/plans/x/work-items.md" "develop")
cls=$(get "$out" classification)
[ "$cls" = fresh ] && ok "develop-base fresh" || fail "develop-base fresh (got: $cls)"

# 2. glob path normalization: '*' component must stay literal
g=$TMPROOT/glob
mkrepo "$g" main
cempty "$g" -m init
mkdir -p "$g/alpha" "$g/beta" "$g/gamma"
out=$(cd "$g" && bash "$SCRIPT" "docs/*/work-items.md" "main")
wip=$(get "$out" work-items-path)
[ "$wip" = "docs/*/work-items.md" ] && ok "glob path literal" || fail "glob path literal (got: $wip)"

# 3. matching trailer -> resume
r=$TMPROOT/resume
mkrepo "$r" main
cempty "$r" -m init
git -C "$r" checkout -q -b run
cempty "$r" -m "run item" -m "Implement-Work-Items-Run: docs/plans/x/work-items.md"
out=$(cd "$r" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
cls=$(get "$out" classification)
[ "$cls" = resume ] && ok "matching trailer resume" || fail "matching trailer resume (got: $cls)"

# 4. no run commits -> fresh
f=$TMPROOT/fresh
mkrepo "$f" main
cempty "$f" -m init
git -C "$f" checkout -q -b run
out=$(cd "$f" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
cls=$(get "$out" classification)
[ "$cls" = fresh ] && ok "no-trailer fresh" || fail "no-trailer fresh (got: $cls)"

# 5. foreign commits, no matching trailer -> refuse
x=$TMPROOT/refuse
mkrepo "$x" main
cempty "$x" -m init
git -C "$x" checkout -q -b run
cempty "$x" -m "foreign work, no trailer"
out=$(cd "$x" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
cls=$(get "$out" classification)
[ "$cls" = refuse ] && ok "foreign refuse" || fail "foreign refuse (got: $cls)"

# 6. differently-spelled equivalent path -> resume
s=$TMPROOT/spelled
mkrepo "$s" main
cempty "$s" -m init
git -C "$s" checkout -q -b run
cempty "$s" -m "run" -m "Implement-Work-Items-Run: docs/plans/x/work-items.md"
out=$(cd "$s" && bash "$SCRIPT" "./docs/plans/x/../x/work-items.md/" "main")
cls=$(get "$out" classification)
[ "$cls" = resume ] && ok "diff-spelled resume" || fail "diff-spelled resume (got: $cls)"

# 7. empty/missing base -> no-base (never defaults to HEAD)
n=$TMPROOT/nobase
mkrepo "$n" main
cempty "$n" -m init
out=$(cd "$n" && bash "$SCRIPT" "docs/plans/x/work-items.md" "")
cls=$(get "$out" classification)
base=$(get "$out" base)
{ [ "$cls" = no-base ] && [ "$base" = none ]; } && ok "empty base no-base" || fail "empty base no-base (got cls: $cls, base: $base)"

# 8. empty path arg must not false-resume off git's empty trailer lines
e=$TMPROOT/emptypath
mkrepo "$e" main
cempty "$e" -m init
git -C "$e" checkout -q -b run
cempty "$e" -m "foreign work, no trailer"
out=$(cd "$e" && bash "$SCRIPT" "" "main")
cls=$(get "$out" classification)
[ "$cls" = refuse ] && ok "empty path no false-resume" || fail "empty path no false-resume (got: $cls)"

# 9. non-empty but unresolvable base must not silently -> fresh
b=$TMPROOT/badbase
mkrepo "$b" main
cempty "$b" -m init
git -C "$b" checkout -q -b run
cempty "$b" -m "some work"
out=$(cd "$b" && bash "$SCRIPT" "docs/plans/x/work-items.md" "no-such-ref")
cls=$(get "$out" classification)
[ "$cls" = no-base ] && ok "unresolvable base no-base" || fail "unresolvable base no-base (got: $cls)"

# 10. option-like base ref must not be parsed as a git option (no file write)
p=$TMPROOT/inject
mkrepo "$p" main
cempty "$p" -m init
git -C "$p" checkout -q -b run
cempty "$p" -m "work"
PWNED="$p/PWNED"
out=$(cd "$p" && bash "$SCRIPT" "docs/plans/x/work-items.md" "--output=$PWNED")
cls=$(get "$out" classification)
{ [ "$cls" = no-base ] && [ ! -e "$PWNED" ]; } && ok "arg-injection blocked" || fail "arg-injection blocked (cls: $cls, file: $([ -e "$PWNED" ] && echo yes || echo no))"

# 11. whitespace-only base ref must not silently -> fresh
w=$TMPROOT/wsbase
mkrepo "$w" main
cempty "$w" -m init
git -C "$w" checkout -q -b run
cempty "$w" -m "work"
out=$(cd "$w" && bash "$SCRIPT" "docs/plans/x/work-items.md" "   ")
cls=$(get "$out" classification)
[ "$cls" = no-base ] && ok "whitespace base no-base" || fail "whitespace base no-base (got: $cls)"

# ============================================================================
# Block-aware Log reconstruction
# ============================================================================
# The lifecycle regex must apply ONLY inside the Log: block. A labeled block
# below the Log (Corrections / Coherence approvals / Below-threshold
# dispositions) is parsed on its own label and must never contribute a
# lifecycle item, even when a block line happens to share the `- <token>: <W-N>`
# shape.

# Commit a ledger at the plan-folder-derived path and record the run trailer, so
# the reader classifies `resume` and reconstructs items from the committed ledger.
# $1 = repo, $2 = work-items path (its dirname is the plan folder), $3 = ledger body.
commit_ledger() {
  local repo="$1" wip="$2" body="$3" plandir
  plandir=$(dirname -- "$wip")
  mkdir -p "$repo/$plandir/.implement-work-items"
  printf '%s' "$body" > "$repo/$plandir/.implement-work-items/progress.md"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "run bookkeeping" -m "Implement-Work-Items-Run: $wip"
}

# 12. A Below-threshold block line shaped like a Log entry is NOT a lifecycle item.
bl=$TMPROOT/blockline
mkrepo "$bl" main
cempty "$bl" -m init
git -C "$bl" checkout -q -b run
commit_ledger "$bl" "docs/plans/x/work-items.md" "# implement-work-items progress

Run config:

- work items: docs/plans/x/work-items.md

Log:

- start-of-item: W-1
- done: W-1

Below-threshold dispositions:

- skip: W-9
"
out=$(cd "$bl" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
# W-1 done must appear; the block's `- skip: W-9` must NOT reconstruct as an item.
{ printf '%s\n' "$it" | grep -qx "W-1 done unresolved" \
  && ! printf '%s\n' "$it" | grep -q "W-9"; } \
  && ok "block line not a lifecycle item" \
  || fail "block line not a lifecycle item (items: $(printf '%s' "$it" | tr '\n' '|'))"

# 13. All three sibling blocks present: only the Log lifecycle is reconstructed.
tb=$TMPROOT/threeblocks
mkrepo "$tb" main
cempty "$tb" -m init
git -C "$tb" checkout -q -b run
commit_ledger "$tb" "docs/plans/x/work-items.md" "# implement-work-items progress

Run config:

- work items: docs/plans/x/work-items.md

Log:

- start-of-item: W-1
- done: W-1
- start-of-item: W-2
- no-commit-done: W-2
- start-of-item: W-3
- skip: W-3

Corrections:

- W-1: prefer explicit return types on exported functions

Coherence approvals:

- W-4: src/shared/config.ts

Below-threshold dispositions:

- done: W-8
- W-1: fixed SUG-2 (naming); left SUG-3 (comment style)
"
out=$(cd "$tb" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
expected="W-1 done unresolved
W-2 done-no-commit
W-3 skipped"
{ [ "$it" = "$expected" ]; } \
  && ok "blocks do not perturb Log reconstruction" \
  || fail "blocks do not perturb Log reconstruction (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 14. W-1-vs-W-10 substring trap: distinct items, no cross-contamination.
sub=$TMPROOT/substr
mkrepo "$sub" main
cempty "$sub" -m init
git -C "$sub" checkout -q -b run
commit_ledger "$sub" "docs/plans/x/work-items.md" "# implement-work-items progress

Log:

- start-of-item: W-1
- done: W-1
- start-of-item: W-10
- skip: W-10
"
out=$(cd "$sub" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
expected="W-1 done unresolved
W-10 skipped"
[ "$it" = "$expected" ] \
  && ok "W-1 vs W-10 substring distinct" \
  || fail "W-1 vs W-10 substring distinct (got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Plan-folder-derived ledger path
# ============================================================================
# The ledger path is dirname(NORM_PATH)/.implement-work-items/progress.md, not a
# repo-root-anchored path. Committed read and working-tree fallback both use it.

# 15. Committed ledger under a nested plan folder is read from the derived path.
nd=$TMPROOT/nested
mkrepo "$nd" main
cempty "$nd" -m init
git -C "$nd" checkout -q -b run
commit_ledger "$nd" "docs/plans/deep/nest/work-items.md" "# implement-work-items progress

Log:

- start-of-item: W-1
- done: W-1
"
out=$(cd "$nd" && bash "$SCRIPT" "docs/plans/deep/nest/work-items.md" "main")
it=$(items "$out")
[ "$it" = "W-1 done unresolved" ] \
  && ok "derived committed ledger path (nested)" \
  || fail "derived committed ledger path (nested) (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 16. A ledger at the repo-root path must NOT be read when the plan folder is nested.
rr=$TMPROOT/rootledger
mkrepo "$rr" main
cempty "$rr" -m init
git -C "$rr" checkout -q -b run
mkdir -p "$rr/.implement-work-items"
printf '# implement-work-items progress\n\nLog:\n\n- start-of-item: W-99\n- done: W-99\n' \
  > "$rr/.implement-work-items/progress.md"
git -C "$rr" add -A
git -C "$rr" commit -q -m "stray root ledger" -m "Implement-Work-Items-Run: docs/plans/x/work-items.md"
out=$(cd "$rr" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
# The plan folder is docs/plans/x, so the reader must not pick up the root ledger's W-99.
{ ! printf '%s\n' "$it" | grep -q "W-99"; } \
  && ok "root ledger ignored for nested plan folder" \
  || fail "root ledger ignored for nested plan folder (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 17. Working-tree fallback: uncommitted ledger at the derived path populates items.
wt=$TMPROOT/worktree
mkrepo "$wt" main
cempty "$wt" -m init
git -C "$wt" checkout -q -b run
cempty "$wt" -m "run" -m "Implement-Work-Items-Run: docs/plans/x/work-items.md"
mkdir -p "$wt/docs/plans/x/.implement-work-items"
printf '# implement-work-items progress\n\nLog:\n\n- start-of-item: W-5\n- skip: W-5\n' \
  > "$wt/docs/plans/x/.implement-work-items/progress.md"
out=$(cd "$wt" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
[ "$it" = "W-5 skipped" ] \
  && ok "working-tree fallback at derived path" \
  || fail "working-tree fallback at derived path (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 18. A `..`/`./` work-items path resolves to the same derived ledger path.
dp=$TMPROOT/dotpath
mkrepo "$dp" main
cempty "$dp" -m init
git -C "$dp" checkout -q -b run
commit_ledger "$dp" "docs/plans/x/work-items.md" "# implement-work-items progress

Log:

- start-of-item: W-7
- done: W-7
"
out=$(cd "$dp" && bash "$SCRIPT" "./docs/plans/x/../x/work-items.md" "main")
it=$(items "$out")
{ [ "$(get "$out" classification)" = resume ] && [ "$it" = "W-7 done unresolved" ]; } \
  && ok "dot-segment path resolves derived ledger" \
  || fail "dot-segment path resolves derived ledger (cls: $(get "$out" classification), got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Done-from-ledger (never from commit presence)
# ============================================================================

# 19. A `done` whose item-trailer commit is in range -> done resolved.
rs=$TMPROOT/resolved
mkrepo "$rs" main
cempty "$rs" -m init
git -C "$rs" checkout -q -b run
cempty "$rs" -m "code for W-1" -m "Implement-Work-Items-Item: W-1"
commit_ledger "$rs" "docs/plans/x/work-items.md" "# implement-work-items progress

Log:

- start-of-item: W-1
- done: W-1
"
out=$(cd "$rs" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
[ "$it" = "W-1 done resolved" ] \
  && ok "done with item-trailer is resolved" \
  || fail "done with item-trailer is resolved (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 20. A `done` with no item-trailer commit -> done unresolved (never inferred).
un=$TMPROOT/unresolved
mkrepo "$un" main
cempty "$un" -m init
git -C "$un" checkout -q -b run
commit_ledger "$un" "docs/plans/x/work-items.md" "# implement-work-items progress

Log:

- start-of-item: W-1
- done: W-1
"
out=$(cd "$un" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
[ "$it" = "W-1 done unresolved" ] \
  && ok "done without item-trailer is unresolved" \
  || fail "done without item-trailer is unresolved (got: $(printf '%s' "$it" | tr '\n' '|'))"

# 21. Empty ledger -> empty items block.
el=$TMPROOT/emptyledger
mkrepo "$el" main
cempty "$el" -m init
git -C "$el" checkout -q -b run
cempty "$el" -m "run" -m "Implement-Work-Items-Run: docs/plans/x/work-items.md"
out=$(cd "$el" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
[ -z "$it" ] \
  && ok "empty ledger empty items" \
  || fail "empty ledger empty items (got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Writer <-> reader round-trip
# ============================================================================
# The writer's output, committed at the derived path, must reconstruct to the
# exact four-token lifecycle, and the block writes must not appear as items.

# 22. write-run-record.sh init + log + block, then scan reconstructs the lifecycle.
rt=$TMPROOT/roundtrip
mkrepo "$rt" main
cempty "$rt" -m init
git -C "$rt" checkout -q -b run
wip="docs/plans/x/work-items.md"
rec="$rt/docs/plans/x/.implement-work-items/progress.md"
mkdir -p "$(dirname -- "$rec")"
bash "$WRITER" init "$rec" warning 3 inherit main run "npm test" "$wip"
bash "$WRITER" log "$rec" start-of-item W-1
bash "$WRITER" log "$rec" done W-1
bash "$WRITER" log "$rec" start-of-item W-2
bash "$WRITER" log "$rec" no-commit-done W-2
bash "$WRITER" log "$rec" start-of-item W-10
bash "$WRITER" log "$rec" skip W-10
# Block writes that must not leak into the Log reconstruction.
bash "$WRITER" block "$rec" corrections "W-1: prefer explicit return types"
bash "$WRITER" block "$rec" coherence "W-4: src/shared/config.ts"
bash "$WRITER" block "$rec" below-threshold "W-1: fixed SUG-2; left SUG-3"
git -C "$rt" add -A
git -C "$rt" commit -q -m "run bookkeeping" -m "Implement-Work-Items-Run: $wip"
out=$(cd "$rt" && bash "$SCRIPT" "$wip" "main")
it=$(items "$out")
expected="W-1 done unresolved
W-2 done-no-commit
W-10 skipped"
{ [ "$(get "$out" classification)" = resume ] && [ "$it" = "$expected" ]; } \
  && ok "writer<->reader round-trip lifecycle" \
  || fail "writer<->reader round-trip lifecycle (cls: $(get "$out" classification), got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Ledger-path confinement (no read outside the repo tree)
# ============================================================================
# The working-tree `cat` fallback must never read a ledger outside the repo. A
# work-items path that still begins with a `..` component after normalization has
# no valid in-repo plan folder, so the derived path is confined to the root-
# anchored ledger rather than reaching a sibling directory next to the repo.

# 23. A `../outside/...` path must NOT disclose a sibling repo-external ledger.
tr_root=$TMPROOT/traversal
mkdir -p "$tr_root/outside/.implement-work-items"
printf '# implement-work-items progress\n\nLog:\n\n- start-of-item: W-666\n- done: W-666\n' \
  > "$tr_root/outside/.implement-work-items/progress.md"
tv=$tr_root/repo
mkrepo "$tv" main
cempty "$tv" -m init
git -C "$tv" checkout -q -b run
cempty "$tv" -m "run" -m "Implement-Work-Items-Run: ../outside/work-items.md"
out=$(cd "$tv" && bash "$SCRIPT" "../outside/work-items.md" "main")
it=$(items "$out")
# The outside item id must never appear: the derived path is confined in-repo.
{ ! printf '%s\n' "$it" | grep -q "W-666"; } \
  && ok "outside ledger not disclosed by traversal path" \
  || fail "outside ledger not disclosed by traversal path (got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Root-level plan-folder derivation (PLAN_DIR="")
# ============================================================================
# A work-items.md at the repo root leaves the plan folder empty, so the ledger
# path is the root-anchored `.implement-work-items/progress.md`. This branch must
# perform a real ledger read, not just fall through empty.

# 24. Root-level work items with a root ledger -> resume, reconstructed item.
rl=$TMPROOT/rootlevel
mkrepo "$rl" main
cempty "$rl" -m init
git -C "$rl" checkout -q -b run
mkdir -p "$rl/.implement-work-items"
printf '# implement-work-items progress\n\nLog:\n\n- start-of-item: W-1\n- done: W-1\n' \
  > "$rl/.implement-work-items/progress.md"
git -C "$rl" add -A
git -C "$rl" commit -q -m "run bookkeeping" -m "Implement-Work-Items-Run: work-items.md"
out=$(cd "$rl" && bash "$SCRIPT" "work-items.md" "main")
it=$(items "$out")
{ [ "$(get "$out" classification)" = resume ] && [ "$it" = "W-1 done unresolved" ]; } \
  && ok "root-level derivation reads root ledger" \
  || fail "root-level derivation reads root ledger (cls: $(get "$out" classification), got: $(printf '%s' "$it" | tr '\n' '|'))"

# ============================================================================
# Log block-gate: `- <token>: <id>` lines with NO `Log:` header
# ============================================================================
# Lifecycle entries are read only inside the Log: block. A ledger whose entries
# appear with no `Log:` header must reconstruct to zero items — the block gate
# never starts, so nothing is parsed.

# 25. Lifecycle-shaped lines with no `Log:` header -> empty items block.
nh=$TMPROOT/nolog
mkrepo "$nh" main
cempty "$nh" -m init
git -C "$nh" checkout -q -b run
commit_ledger "$nh" "docs/plans/x/work-items.md" "# implement-work-items progress

Run config:

- work items: docs/plans/x/work-items.md

- start-of-item: W-1
- done: W-1
- start-of-item: W-2
- skip: W-2
"
out=$(cd "$nh" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
{ [ "$(get "$out" classification)" = resume ] && [ -z "$it" ]; } \
  && ok "no Log header reconstructs empty items" \
  || fail "no Log header reconstructs empty items (cls: $(get "$out" classification), got: $(printf '%s' "$it" | tr '\n' '|'))"

# 26. A `Log:` header with trailing whitespace still opens the block. The header
# carries a literal trailing space (built via printf so it is not editor-stripped).
tw=$TMPROOT/trailws
mkrepo "$tw" main
cempty "$tw" -m init
git -C "$tw" checkout -q -b run
tw_body=$(printf '# implement-work-items progress\n\nLog: \n\n- start-of-item: W-1\n- done: W-1\n')
commit_ledger "$tw" "docs/plans/x/work-items.md" "$tw_body"
out=$(cd "$tw" && bash "$SCRIPT" "docs/plans/x/work-items.md" "main")
it=$(items "$out")
[ "$it" = "W-1 done unresolved" ] \
  && ok "Log header tolerates trailing whitespace" \
  || fail "Log header tolerates trailing whitespace (got: $(printf '%s' "$it" | tr '\n' '|'))"

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
