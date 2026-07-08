#!/usr/bin/env bash
# Ephemeral crafted-repo checks for detect-driver-context.sh.
# Usage: detect-driver-context.test.sh <path-to-detect-driver-context.sh>
#
# Covers the base-resolution evidence the detector adds: per-candidate
# behind/ahead counts against HEAD for the fixed candidate set (local main /
# master, origin/*, upstream/*), skipping candidates that do not resolve; and
# the read-only fetch-status flag sourced from IWI_FETCH_STATUS. Also asserts
# the detector stays read-only (no git fetch) and preserves its pre-existing
# output. Pure bash; no jq/python3.
set -u

# Resolve the script under test to an absolute path once: the checks cd into
# throwaway repos, so a relative $1 would not resolve from there.
SCRIPT=$(cd "$(dirname -- "$1")" && pwd)/$(basename -- "$1")

PASS=0; FAIL=0
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# Extract the value of a `key: value` line (first match wins).
get() { printf '%s\n' "$1" | awk -F': ' -v k="$2" '$1==k{print $2; exit}'; }
# Extract the `behind: <B> ahead: <A>` payload of a candidate line for <ref>.
cand() { printf '%s\n' "$1" | awk -v r="$2" '$1=="candidate:" && $2==r {print $3, $4, $5, $6; exit}'; }

mkrepo() { git init -q -b "$2" "$1"; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t; }
cempty() { git -C "$1" commit -q --allow-empty "${@:2}"; }

# ============================================================================
# Per-candidate behind/ahead against HEAD
# ============================================================================

# 1. In-sync: HEAD is the candidate itself -> behind 0 ahead 0.
s=$TMPROOT/insync
mkrepo "$s" main
cempty "$s" -m init
out=$(cd "$s" && bash "$SCRIPT")
[ "$(cand "$out" main)" = "behind: 0 ahead: 0" ] \
  && ok "in-sync candidate behind 0 ahead 0" \
  || fail "in-sync candidate behind 0 ahead 0 (got: $(cand "$out" main))"

# 2. Ahead: branch is N commits ahead of the base candidate.
a=$TMPROOT/ahead
mkrepo "$a" main
cempty "$a" -m init
git -C "$a" checkout -q -b feature
cempty "$a" -m f1
cempty "$a" -m f2
cempty "$a" -m f3
out=$(cd "$a" && bash "$SCRIPT")
[ "$(cand "$out" main)" = "behind: 0 ahead: 3" ] \
  && ok "ahead candidate behind 0 ahead 3" \
  || fail "ahead candidate behind 0 ahead 3 (got: $(cand "$out" main))"

# 3. Behind: branch is N commits behind the base candidate.
b=$TMPROOT/behind
mkrepo "$b" main
cempty "$b" -m init
git -C "$b" checkout -q -b feature
git -C "$b" checkout -q main
cempty "$b" -m m1
cempty "$b" -m m2
git -C "$b" checkout -q feature
out=$(cd "$b" && bash "$SCRIPT")
[ "$(cand "$out" main)" = "behind: 2 ahead: 0" ] \
  && ok "behind candidate behind 2 ahead 0" \
  || fail "behind candidate behind 2 ahead 0 (got: $(cand "$out" main))"

# 4. Diverged: commits on both the base and HEAD not shared.
d=$TMPROOT/diverged
mkrepo "$d" main
cempty "$d" -m init
git -C "$d" checkout -q -b feature
cempty "$d" -m f1
cempty "$d" -m f2
git -C "$d" checkout -q main
cempty "$d" -m m1
git -C "$d" checkout -q feature
out=$(cd "$d" && bash "$SCRIPT")
[ "$(cand "$out" main)" = "behind: 1 ahead: 2" ] \
  && ok "diverged candidate behind 1 ahead 2" \
  || fail "diverged candidate behind 1 ahead 2 (got: $(cand "$out" main))"

# 5. A candidate that does not resolve emits no candidate line.
nr=$TMPROOT/noresolve
mkrepo "$nr" main
cempty "$nr" -m init
out=$(cd "$nr" && bash "$SCRIPT")
# No remote, so origin/main and upstream/main must not appear.
{ ! printf '%s\n' "$out" | grep -q "candidate: origin/main" \
  && ! printf '%s\n' "$out" | grep -q "candidate: upstream/main"; } \
  && ok "unresolved candidates skipped" \
  || fail "unresolved candidates skipped (candidates: $(printf '%s\n' "$out" | grep '^candidate:' | tr '\n' '|'))"

# 6. A resolving remote candidate is emitted with its own counts. A remote is
# faked by writing refs/remotes/origin/main; the detector reads it read-only.
rc=$TMPROOT/remotecand
mkrepo "$rc" main
cempty "$rc" -m init
# origin/main sits at init; HEAD advances two commits -> behind 0 ahead 2.
git -C "$rc" update-ref refs/remotes/origin/main HEAD
cempty "$rc" -m c1
cempty "$rc" -m c2
out=$(cd "$rc" && bash "$SCRIPT")
[ "$(cand "$out" origin/main)" = "behind: 0 ahead: 2" ] \
  && ok "resolving origin/main candidate emitted" \
  || fail "resolving origin/main candidate emitted (got: $(cand "$out" origin/main))"

# 7. master and upstream/* candidates are recognized too.
uc=$TMPROOT/upstreamcand
mkrepo "$uc" master
cempty "$uc" -m init
git -C "$uc" update-ref refs/remotes/upstream/master HEAD
cempty "$uc" -m c1
out=$(cd "$uc" && bash "$SCRIPT")
{ [ "$(cand "$out" master)" = "behind: 0 ahead: 0" ] \
  && [ "$(cand "$out" upstream/master)" = "behind: 0 ahead: 1" ]; } \
  && ok "master and upstream/master candidates emitted" \
  || fail "master and upstream/master candidates emitted (master: $(cand "$out" master), upstream/master: $(cand "$out" upstream/master))"

# ============================================================================
# Detached HEAD
# ============================================================================

# 8. Detached HEAD: branch is none, candidates are still computed against HEAD.
dh=$TMPROOT/detached
mkrepo "$dh" main
cempty "$dh" -m init
cempty "$dh" -m c1
cempty "$dh" -m c2
# Detach one commit back so main is 1 ahead of HEAD (HEAD is 1 behind main).
prev=$(git -C "$dh" rev-parse HEAD~1)
git -C "$dh" checkout -q "$prev"
out=$(cd "$dh" && bash "$SCRIPT")
{ [ "$(get "$out" branch)" = none ] \
  && [ "$(cand "$out" main)" = "behind: 1 ahead: 0" ]; } \
  && ok "detached HEAD branch none, candidates still emitted" \
  || fail "detached HEAD branch none, candidates still emitted (branch: $(get "$out" branch), main: $(cand "$out" main))"

# ============================================================================
# fetch-status flag (read-only, from IWI_FETCH_STATUS)
# ============================================================================

# 9. IWI_FETCH_STATUS=ok -> fetch-status: ok.
fo=$TMPROOT/fetchok
mkrepo "$fo" main
cempty "$fo" -m init
out=$(cd "$fo" && IWI_FETCH_STATUS=ok bash "$SCRIPT")
[ "$(get "$out" fetch-status)" = ok ] \
  && ok "fetch-status ok when IWI_FETCH_STATUS=ok" \
  || fail "fetch-status ok when IWI_FETCH_STATUS=ok (got: $(get "$out" fetch-status))"

# 10. IWI_FETCH_STATUS=failed -> fetch-status: failed.
ff=$TMPROOT/fetchfailed
mkrepo "$ff" main
cempty "$ff" -m init
out=$(cd "$ff" && IWI_FETCH_STATUS=failed bash "$SCRIPT")
[ "$(get "$out" fetch-status)" = failed ] \
  && ok "fetch-status failed when IWI_FETCH_STATUS=failed" \
  || fail "fetch-status failed when IWI_FETCH_STATUS=failed (got: $(get "$out" fetch-status))"

# 11. IWI_FETCH_STATUS unset -> fetch-status: unknown.
fu=$TMPROOT/fetchunset
mkrepo "$fu" main
cempty "$fu" -m init
out=$(cd "$fu" && env -u IWI_FETCH_STATUS bash "$SCRIPT")
[ "$(get "$out" fetch-status)" = unknown ] \
  && ok "fetch-status unknown when IWI_FETCH_STATUS unset" \
  || fail "fetch-status unknown when IWI_FETCH_STATUS unset (got: $(get "$out" fetch-status))"

# ============================================================================
# Read-only: the detector performs no fetch / no network write
# ============================================================================

# 12. The detector must not run `git fetch`. A sabotaged `git` on PATH that
# fails on any `fetch` invocation must not perturb the detector's output.
ro=$TMPROOT/readonly
mkrepo "$ro" main
cempty "$ro" -m init
bindir=$TMPROOT/fakebin
mkdir -p "$bindir"
realgit=$(command -v git)
cat > "$bindir/git" <<EOF
#!/usr/bin/env bash
if [ "\$1" = fetch ]; then echo "FETCH-CALLED" >&2; exit 1; fi
exec "$realgit" "\$@"
EOF
chmod +x "$bindir/git"
out=$(cd "$ro" && PATH="$bindir:$PATH" bash "$SCRIPT" 2>"$TMPROOT/ro.err")
{ ! grep -q "FETCH-CALLED" "$TMPROOT/ro.err" \
  && [ "$(get "$out" candidate:)" != "" -o "$(cand "$out" main)" = "behind: 0 ahead: 0" ]; } \
  && ok "detector runs no git fetch" \
  || fail "detector runs no git fetch (stderr: $(tr '\n' '|' < "$TMPROOT/ro.err"))"

# ============================================================================
# Pre-existing output preserved
# ============================================================================

# 13. The pre-existing key lines and the uncommitted marker block still appear.
pe=$TMPROOT/preserved
mkrepo "$pe" main
cempty "$pe" -m init
printf '{"scripts":{"test":"echo t"}}\n' > "$pe/package.json"
out=$(cd "$pe" && bash "$SCRIPT")
{ [ "$(get "$out" git-available)" = true ] \
  && [ "$(get "$out" branch)" = main ] \
  && printf '%s\n' "$out" | grep -qx "uncommitted-start" \
  && printf '%s\n' "$out" | grep -qx "uncommitted-end" \
  && printf '%s\n' "$out" | grep -qx "manifest: package.json" \
  && [ "$(get "$out" inferred-test-command)" = "npm test" ]; } \
  && ok "pre-existing output preserved" \
  || fail "pre-existing output preserved (out: $(printf '%s' "$out" | tr '\n' '|'))"

# 14. Git-absent handling is preserved: when not in a work tree, the git block
# reports false/none and no candidate lines are emitted.
ng=$TMPROOT/nogit
mkdir -p "$ng"
out=$(cd "$ng" && bash "$SCRIPT")
{ [ "$(get "$out" git-available)" = false ] \
  && [ "$(get "$out" branch)" = none ] \
  && ! printf '%s\n' "$out" | grep -q '^candidate:'; } \
  && ok "git-absent handling preserved" \
  || fail "git-absent handling preserved (out: $(printf '%s' "$out" | tr '\n' '|'))"

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
