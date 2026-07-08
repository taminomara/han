#!/usr/bin/env bash
# Ephemeral crafted-branch checks for scan-run-history.sh.
# Usage: harness.sh <path-to-scan-run-history.sh>
set -u
SCRIPT="$1"
PASS=0; FAIL=0
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

get() { printf '%s\n' "$1" | awk -F': ' -v k="$2" '$1==k{print $2; exit}'; }

mkrepo() { git init -q -b "$2" "$1"; git -C "$1" config user.email t@t.t; git -C "$1" config user.name t; }
cempty() { git -C "$1" commit -q --allow-empty "${@:2}"; }

# 1. develop-base fresh (WARN-001): base passed as arg, no run commits -> fresh
d=$TMPROOT/develop
mkrepo "$d" develop
cempty "$d" -m init
git -C "$d" checkout -q -b feature
out=$(cd "$d" && bash "$SCRIPT" "docs/plans/x/work-items.md" "develop")
cls=$(get "$out" classification)
[ "$cls" = fresh ] && ok "develop-base fresh" || fail "develop-base fresh (got: $cls)"

# 2. glob path normalization (WARN-002): '*' component must stay literal
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

# 8. SUGG-001: empty path arg must not false-resume off git's empty trailer lines
e=$TMPROOT/emptypath
mkrepo "$e" main
cempty "$e" -m init
git -C "$e" checkout -q -b run
cempty "$e" -m "foreign work, no trailer"
out=$(cd "$e" && bash "$SCRIPT" "" "main")
cls=$(get "$out" classification)
[ "$cls" = refuse ] && ok "empty path no false-resume" || fail "empty path no false-resume (got: $cls)"

# 9. SUGG-005/WARN-001: non-empty but unresolvable base must not silently -> fresh
b=$TMPROOT/badbase
mkrepo "$b" main
cempty "$b" -m init
git -C "$b" checkout -q -b run
cempty "$b" -m "some work"
out=$(cd "$b" && bash "$SCRIPT" "docs/plans/x/work-items.md" "no-such-ref")
cls=$(get "$out" classification)
[ "$cls" = no-base ] && ok "unresolvable base no-base" || fail "unresolvable base no-base (got: $cls)"

# 10. SEC-001: option-like base ref must not be parsed as a git option (no file write)
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

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
