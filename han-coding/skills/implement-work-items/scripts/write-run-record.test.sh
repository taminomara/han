#!/usr/bin/env bash
# Unit checks for write-run-record.sh — the append-only bookkeeping writer.
# Usage: write-run-record.test.sh <path-to-write-run-record.sh>
# Pure bash; no git, jq, or python3. The writer touches a plain file, so the
# sandbox is a tmp dir with no repo.
set -u
SCRIPT="$1"
PASS=0; FAIL=0
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# eq <label> <expected> <actual>
eq() { if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected [$2], got [$3])"; fi; }

# A fresh record path under a per-test subdir.
newrec() { local d; d=$(mktemp -d "$TMPROOT/rec.XXXXXX"); echo "$d/progress.md"; }

# 1. init writes the exact config block + Log: header to a fresh path
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/checkout "npm test; npm run lint" docs/plans/checkout/work-items.md
read -r -d '' EXPECT_INIT <<'EOF'
# implement-work-items progress

Run config:

- gate: warning
- fix-cap: 3
- model: inherit
- base: origin/main
- branch: feat/checkout
- verify: npm test; npm run lint
- work items: docs/plans/checkout/work-items.md

Log:
EOF
eq "init exact config+Log block" "$EXPECT_INIT" "$(cat "$r")"

# 2. log appends `- <token>: <W-N>` under Log: for each of the four tokens
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
bash "$SCRIPT" log "$r" done W-1
bash "$SCRIPT" log "$r" start-of-item W-2
bash "$SCRIPT" log "$r" no-commit-done W-2
bash "$SCRIPT" log "$r" start-of-item W-3
bash "$SCRIPT" log "$r" skip W-3
logtail=$(awk '/^Log:$/{f=1;next} f' "$r")
read -r -d '' EXPECT_LOG <<'EOF'
- start-of-item: W-1
- done: W-1
- start-of-item: W-2
- no-commit-done: W-2
- start-of-item: W-3
- skip: W-3
EOF
eq "log appends four tokens under Log:" "$EXPECT_LOG" "$logtail"

# 3. an invalid log token fails loud (non-zero) and leaves the record unchanged
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
before=$(cat "$r")
if bash "$SCRIPT" log "$r" bogus-token W-2 2>/dev/null; then
  fail "invalid token exits non-zero"
else
  ok "invalid token exits non-zero"
fi
eq "invalid token leaves record unchanged" "$before" "$(cat "$r")"

# 4. a block append creates the header once (with a preceding blank line), then
#    appends further lines without recreating the header
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
bash "$SCRIPT" block "$r" corrections "W-1: prefer explicit return types on exported functions"
bash "$SCRIPT" block "$r" corrections "W-2: name booleans as questions"
read -r -d '' EXPECT_CORR <<'EOF'
Corrections:

- W-1: prefer explicit return types on exported functions
- W-2: name booleans as questions
EOF
corrblock=$(awk '/^Corrections:$/{f=1} f' "$r")
eq "corrections block: header once then append" "$EXPECT_CORR" "$corrblock"
# header must appear exactly once
hdrcount=$(grep -c '^Corrections:$' "$r")
eq "corrections header written exactly once" "1" "$hdrcount"

# 5. the coherence and below-threshold names map to their protocol headers
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" block "$r" coherence "W-4: src/shared/config.ts"
bash "$SCRIPT" block "$r" below-threshold "W-1: fixed SUG-2 (naming); left SUG-3 (comment style)"
read -r -d '' EXPECT_COH <<'EOF'
Coherence approvals:

- W-4: src/shared/config.ts
EOF
cohblock=$(awk '/^Coherence approvals:$/{f=1} /^Below-threshold/{f=0} f' "$r")
eq "coherence name maps to header" "$EXPECT_COH" "$cohblock"
read -r -d '' EXPECT_BT <<'EOF'
Below-threshold dispositions:

- W-1: fixed SUG-2 (naming); left SUG-3 (comment style)
EOF
btblock=$(awk '/^Below-threshold dispositions:$/{f=1} f' "$r")
eq "below-threshold name maps to header" "$EXPECT_BT" "$btblock"

# 6. appending to a block does not perturb the Log: block (lines intact, ordered)
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
bash "$SCRIPT" block "$r" corrections "W-1: a correction"
bash "$SCRIPT" log "$r" done W-1
bash "$SCRIPT" block "$r" coherence "W-1: some/path.ts"
bash "$SCRIPT" log "$r" start-of-item W-2
bash "$SCRIPT" block "$r" corrections "W-2: another correction"
bash "$SCRIPT" log "$r" skip W-2
logblock=$(awk '/^Log:$/{f=1;next} /^$/{f=0} f' "$r")
read -r -d '' EXPECT_LOG6 <<'EOF'
- start-of-item: W-1
- done: W-1
- start-of-item: W-2
- skip: W-2
EOF
eq "block appends do not perturb Log: block" "$EXPECT_LOG6" "$logblock"

# 7. bad subcommand, missing args, and unknown block name each fail loud
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
if bash "$SCRIPT" bogus "$r" 2>/dev/null; then fail "unknown subcommand exits non-zero"; else ok "unknown subcommand exits non-zero"; fi
if bash "$SCRIPT" 2>/dev/null; then fail "no subcommand exits non-zero"; else ok "no subcommand exits non-zero"; fi
if bash "$SCRIPT" log "$r" done 2>/dev/null; then fail "log missing arg exits non-zero"; else ok "log missing arg exits non-zero"; fi
if bash "$SCRIPT" init "$r" warning 2>/dev/null; then fail "init missing args exits non-zero"; else ok "init missing args exits non-zero"; fi
if bash "$SCRIPT" block "$r" nosuchblock "text" 2>/dev/null; then fail "unknown block exits non-zero"; else ok "unknown block exits non-zero"; fi
# none of the failing calls perturbed the record: it still equals a fresh init
ref7=$(newrec)
bash "$SCRIPT" init "$ref7" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
eq "failed calls left record unchanged" "$(cat "$ref7")" "$(cat "$r")"
# log/block against a non-existent record must fail loud and not create it
missing="$TMPROOT/nope/progress.md"
if bash "$SCRIPT" log "$missing" done W-1 2>/dev/null; then fail "log on missing record exits non-zero"; else ok "log on missing record exits non-zero"; fi
if bash "$SCRIPT" block "$missing" corrections "x" 2>/dev/null; then fail "block on missing record exits non-zero"; else ok "block on missing record exits non-zero"; fi
[ ! -e "$missing" ] && ok "missing record not created" || fail "missing record not created"

# 8. an unwritable target dir fails loud and leaves no partial temp artifact
ro="$TMPROOT/readonly"
mkdir -p "$ro"; chmod a-w "$ro"
if bash "$SCRIPT" init "$ro/progress.md" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md 2>/dev/null; then
  fail "init into unwritable dir exits non-zero"
else
  ok "init into unwritable dir exits non-zero"
fi
[ ! -e "$ro/progress.md" ] && ok "no record left in unwritable dir" || fail "no record left in unwritable dir"
straytmp=$(find "$ro" -name '.write-run-record.*' 2>/dev/null)
eq "no temp artifact left behind" "" "$straytmp"
chmod u+w "$ro"

# 8b. a write that fails after the record exists leaves the ORIGINAL intact
#     (atomicity: temp-then-mv, never a truncating in-place write)
rw="$TMPROOT/atomic"
mkdir -p "$rw"
rec8="$rw/progress.md"
bash "$SCRIPT" init "$rec8" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$rec8" start-of-item W-1
orig8=$(cat "$rec8")
chmod a-w "$rw"                     # dir read-only: temp create / mv must fail
if bash "$SCRIPT" log "$rec8" done W-1 2>/dev/null; then
  fail "append into now-unwritable dir exits non-zero"
else
  ok "append into now-unwritable dir exits non-zero"
fi
chmod u+w "$rw"
eq "original record intact after failed append" "$orig8" "$(cat "$rec8")"
straytmp8=$(find "$rw" -name '.write-run-record.*' 2>/dev/null)
eq "no temp artifact after failed append" "" "$straytmp8"

# 9. round-trip grammar: every Log: entry line in a produced record matches
#    `- <token>: <W-N>` with <token> in the four-token set. Guards the byte-for-
#    byte contract the scan reader parses.
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
bash "$SCRIPT" log "$r" done W-1
bash "$SCRIPT" log "$r" start-of-item W-10
bash "$SCRIPT" log "$r" no-commit-done W-10
bash "$SCRIPT" log "$r" start-of-item W-3
bash "$SCRIPT" log "$r" skip W-3
bash "$SCRIPT" block "$r" corrections "W-1: a note"   # a non-Log block line must not count as a Log entry
bad=$(awk '
  /^Log:$/{f=1;next}
  f && /^$/{f=0}
  f && $0 !~ /^- (start-of-item|done|no-commit-done|skip): W-[0-9]+$/ { print }
' "$r")
eq "every Log entry matches the grammar" "" "$bad"
# and there must actually be six entries (not zero, which would vacuously pass)
n=$(awk '/^Log:$/{f=1;next} f && /^$/{f=0} f' "$r" | grep -c '^- ')
eq "round-trip produced all six Log entries" "6" "$n"

# 10. log rejects a malformed item id (must match ^W-[0-9]+$): fail loud, no write
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
before=$(cat "$r")
if bash "$SCRIPT" log "$r" done "bogus-id" 2>/dev/null; then fail "log rejects malformed item id"; else ok "log rejects malformed item id"; fi
eq "malformed item id leaves record unchanged" "$before" "$(cat "$r")"

# 11. log rejects a newline-carrying item id that would forge a second Log entry
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
before=$(cat "$r")
inject=$'W-1\n- done: W-9'
if bash "$SCRIPT" log "$r" start-of-item "$inject" 2>/dev/null; then fail "log rejects newline-injected item id"; else ok "log rejects newline-injected item id"; fi
eq "newline-injected item id leaves record unchanged" "$before" "$(cat "$r")"
# the forged entry must be absent
forged=$(grep -c '^- done: W-9$' "$r")
eq "no forged Log entry from injected newline" "0" "$forged"

# 12. block rejects text with an embedded newline that would inject a Log-shaped
#     line: fail loud, no write
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
before=$(cat "$r")
btext=$'W-1: legit note\n- done: W-9'
if bash "$SCRIPT" block "$r" corrections "$btext" 2>/dev/null; then fail "block rejects newline in text"; else ok "block rejects newline in text"; fi
eq "newline block text leaves record unchanged" "$before" "$(cat "$r")"
forged=$(grep -c '^- done: W-9$' "$r")
eq "no forged Log entry from block newline" "0" "$forged"

# 13. block rejects text with a control character (e.g. a bare CR): fail loud, no write
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
before=$(cat "$r")
ctext=$'W-1: has a \tcontrol char'   # embedded TAB
if bash "$SCRIPT" block "$r" corrections "$ctext" 2>/dev/null; then fail "block rejects control char in text"; else ok "block rejects control char in text"; fi
eq "control-char block text leaves record unchanged" "$before" "$(cat "$r")"

# 14. a mid-stream failure in the content-producing step (here: awk) must abort
#     non-zero and leave the ORIGINAL record intact — never write truncated
#     content at exit 0 (the masked-pipe-status bug).
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
orig14=$(cat "$r")
shimdir=$(mktemp -d "$TMPROOT/shim.XXXXXX")
# a fake awk that emits partial output then fails, simulating a mid-stream error
printf '#!/usr/bin/env bash\nprintf "TRUNCATED\\n"\nexit 1\n' > "$shimdir/awk"
chmod +x "$shimdir/awk"
if PATH="$shimdir:$PATH" bash "$SCRIPT" log "$r" done W-1 2>/dev/null; then
  fail "failed content transform exits non-zero"
else
  ok "failed content transform exits non-zero"
fi
eq "original record intact after failed transform" "$orig14" "$(cat "$r")"

# 15. a record with two `Log:` headers is malformed: log must fail loud (non-zero,
#     no write) rather than silently insert after the first and reorder.
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
printf '\nLog:\n' >>"$r"          # a second, forged Log: header
before=$(cat "$r")
if bash "$SCRIPT" log "$r" done W-1 2>/dev/null; then fail "log on double-Log record exits non-zero"; else ok "log on double-Log record exits non-zero"; fi
eq "double-Log record unchanged after refused log" "$before" "$(cat "$r")"

# 16. a record with no `Log:` header at all: log must still fail loud, no write
r=$(newrec)
printf '# something else\n\nnot a record\n' >"$r"
before=$(cat "$r")
if bash "$SCRIPT" log "$r" done W-1 2>/dev/null; then fail "log on no-Log record exits non-zero"; else ok "log on no-Log record exits non-zero"; fi
eq "no-Log record unchanged after refused log" "$before" "$(cat "$r")"

# 17. init refuses to overwrite an existing non-empty record (append-only
#     contract): fail loud, no write, Log history preserved.
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
bash "$SCRIPT" log "$r" done W-1
before=$(cat "$r")
if bash "$SCRIPT" init "$r" error 5 opus origin/dev feat/y "make test" docs/y/work-items.md 2>/dev/null; then
  fail "init refuses to overwrite existing record"
else
  ok "init refuses to overwrite existing record"
fi
eq "existing record intact after refused init" "$before" "$(cat "$r")"

# 18. init into a pre-existing EMPTY file is allowed (a zero-byte placeholder is
#     not a real record; the write proceeds).
r=$(newrec)
: >"$r"                            # create an empty file at the target path
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
hdr=$(head -1 "$r")
eq "init proceeds over an empty placeholder file" "# implement-work-items progress" "$hdr"

# 19. init rejects a newline-carrying config arg that would forge a Log entry:
#     fail loud (non-zero), do not create the record, no forged Log line.
d19=$(mktemp -d "$TMPROOT/init19.XXXXXX")
rec19="$d19/progress.md"
inject=$'origin/main\n- skip: W-9'
if bash "$SCRIPT" init "$rec19" warning 3 inherit "$inject" feat/x "npm test" docs/x/work-items.md 2>/dev/null; then
  fail "init rejects newline-injected config arg"
else
  ok "init rejects newline-injected config arg"
fi
[ ! -e "$rec19" ] && ok "init injection record not created" || fail "init injection record not created"
# count the forged line only if a record exists at all; a non-existent record
# trivially carries no forged entry (grep on a missing path prints nothing).
if [ -e "$rec19" ]; then forged19=$(grep -c '^- skip: W-9$' "$rec19"); else forged19=0; fi
eq "no forged Log entry from init injection" "0" "$forged19"

# 20. a mid-stream failure in the block content-reading step (here: cat, the
#     producer append_atomic reads the current record with) must abort non-zero
#     and leave the ORIGINAL record intact — the sibling of the awk-shim guard,
#     reached by every block.
r=$(newrec)
bash "$SCRIPT" init "$r" warning 3 inherit origin/main feat/x "npm test" docs/x/work-items.md
bash "$SCRIPT" log "$r" start-of-item W-1
orig20=$(cat "$r")
shimdir20=$(mktemp -d "$TMPROOT/shim20.XXXXXX")
# a fake cat that emits partial output then fails, simulating a mid-stream error
printf '#!/usr/bin/env bash\nprintf "TRUNCATED\\n"\nexit 1\n' > "$shimdir20/cat"
chmod +x "$shimdir20/cat"
if PATH="$shimdir20:$PATH" bash "$SCRIPT" block "$r" corrections "W-1: a note" 2>/dev/null; then
  fail "failed content read (cat) exits non-zero"
else
  ok "failed content read (cat) exits non-zero"
fi
eq "original record intact after failed cat read" "$orig20" "$(cat "$r")"

echo "----"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
