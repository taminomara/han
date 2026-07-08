#!/usr/bin/env bash
# Append-only bookkeeping writer for the implement-work-items run record
# (progress.md). Mechanism only: it formats and appends the lines and blocks
# the record protocol defines and makes no proceed / discard judgment. It never
# runs git and never rewrites an existing line; every write appends. Output is
# line-oriented and byte-for-byte per the protocol, since the scan reader parses
# it. Pure bash: no jq, no python3.
#
# Fail loud, no partial write: a bad subcommand, an unknown Log token, a missing
# argument, or an unwritable path exits non-zero and leaves the record
# unchanged. Writes stage to a temp file and mv into place atomically, so a
# failed write never leaves a half-written record.
#
# Usage:
#   write-run-record.sh init <record> <gate> <fix-cap> <model> <base> <branch> <verify> <work-items>
#       Write the opening config block and the `Log:` header to a fresh record.
#   write-run-record.sh log <record> <token> <W-N>
#       Append `- <token>: <W-N>` under the `Log:` block. <token> must be one of
#       start-of-item, done, no-commit-done, skip.
#   write-run-record.sh block <record> <name> <text>
#       Append `- <text>` to a labeled block, creating the block header (with a
#       preceding blank line) on first use. <name> is one of corrections,
#       coherence, below-threshold.

set -u
set -o pipefail

die() { echo "write-run-record: $*" >&2; exit 1; }

# Reject any free-text argument that is not a single printable line: a newline or
# a control character (including tab/CR) could forge a grammar-valid Log entry or
# split one appended line into several. $1 = label for the error, $2 = value.
require_single_line() {
  case "$2" in
    *$'\n'*) die "$1 must be a single line (no newline): $2" ;;
  esac
  case "$2" in
    *[[:cntrl:]]*) die "$1 must not contain control characters" ;;
  esac
}

# Replace the record atomically with $2 (already the full, final content): stage
# into a temp file in the record's own directory, then mv it into place. A
# failed write leaves the record untouched. Runs in the current shell so a die
# aborts the whole script. $1 = record path, $2 = content (printed verbatim).
write_atomic() {
  local rec="$1" content="$2" dir tmp
  dir=$(dirname -- "$rec")
  [ -d "$dir" ] || die "no such directory for record: $dir"
  tmp=$(mktemp "$dir/.write-run-record.XXXXXX") || die "cannot create temp file in $dir"
  printf '%s' "$content" >"$tmp" || { rm -f "$tmp"; die "write failed for $rec"; }
  mv -f -- "$tmp" "$rec" || { rm -f "$tmp"; die "cannot replace $rec"; }
}

# Append lines to an existing record: current content, then each arg as its own
# line. Never edits an existing line in place.
append_atomic() {
  local rec="$1"; shift
  [ -f "$rec" ] || die "no such record: $rec"
  # Read the current content on its own so a cat failure is not masked by a
  # trailing sentinel command; { cat && printf x; } fails the substitution if cat
  # does, and the sentinel still preserves a trailing newline on success.
  local body added
  body=$({ cat -- "$rec" && printf x; }) || die "cannot read record: $rec"
  body="${body%x}"
  added=$(printf '%s\n' "$@")
  write_atomic "$rec" "${body}${added}"$'\n'
}

cmd_init() {
  [ "$#" -eq 8 ] || die "init needs 8 args (record gate fix-cap model base branch verify work-items)"
  local rec="$1" gate="$2" fixcap="$3" model="$4" base="$5" branch="$6" verify="$7" items="$8"
  # Guard every config arg the same way as free-text Log/block input: a newline or
  # control char in any of them could forge a grammar-valid Log line the reader
  # then misreads. Reject before any write, so a bad arg leaves no record.
  require_single_line "gate" "$gate"
  require_single_line "fix-cap" "$fixcap"
  require_single_line "model" "$model"
  require_single_line "base" "$base"
  require_single_line "branch" "$branch"
  require_single_line "verify" "$verify"
  require_single_line "work items" "$items"
  # Append-only contract: never clobber an existing non-empty record and discard
  # its Log history. An empty placeholder file is not a real record and may be
  # initialized over.
  [ -s "$rec" ] && die "record already exists, refusing to overwrite: $rec"
  local content
  printf -v content '%s\n\n%s\n\n- gate: %s\n- fix-cap: %s\n- model: %s\n- base: %s\n- branch: %s\n- verify: %s\n- work items: %s\n\n%s\n' \
    "# implement-work-items progress" "Run config:" \
    "$gate" "$fixcap" "$model" "$base" "$branch" "$verify" "$items" "Log:"
  write_atomic "$rec" "$content"
}

cmd_log() {
  [ "$#" -eq 3 ] || die "log needs 3 args (record token item)"
  local rec="$1" token="$2" item="$3"
  case "$token" in
    start-of-item|done|no-commit-done|skip) ;;
    *) die "invalid log token: $token (want start-of-item|done|no-commit-done|skip)" ;;
  esac
  [[ "$item" =~ ^W-[0-9]+$ ]] || die "invalid item id: $item (want W-<n>)"
  [ -f "$rec" ] || die "no such record: $rec"
  local loghdrs
  loghdrs=$(grep -Fxc "Log:" -- "$rec") || true
  [ "$loghdrs" -eq 1 ] || die "record must have exactly one Log: header, found $loghdrs: $rec"
  # Insert the new entry at the end of the contiguous Log: block — the run of
  # `- ` lines right after the `Log:` header, up to the first blank line or EOF —
  # never at end-of-file, so a later block append cannot push a Log line under a
  # sibling block and corrupt the Log reconstruction.
  # Run the transform on its own so its exit status is not masked by a trailing
  # sentinel command. The awk appends its own `x` sentinel to preserve a trailing
  # newline; if awk fails, the status is caught here and the write is aborted with
  # the original record left intact.
  local content
  content=$(awk -v line="- ${token}: ${item}" '
    { buf[NR] = $0 }
    /^Log:$/ && !seen { loghdr = NR; seen = 1 }
    END {
      ins = loghdr
      for (i = loghdr + 1; i <= NR; i++) {
        if (buf[i] == "") break
        ins = i
      }
      for (i = 1; i <= NR; i++) {
        print buf[i]
        if (i == ins) print line
      }
      printf "x"
    }
  ' <"$rec") || die "failed to rewrite Log block for $rec"
  write_atomic "$rec" "${content%x}"
}

cmd_block() {
  [ "$#" -eq 3 ] || die "block needs 3 args (record name text)"
  local rec="$1" name="$2" text="$3" header
  case "$name" in
    corrections)     header="Corrections:" ;;
    coherence)       header="Coherence approvals:" ;;
    below-threshold) header="Below-threshold dispositions:" ;;
    *) die "unknown block: $name (want corrections|coherence|below-threshold)" ;;
  esac
  require_single_line "block text" "$text"
  [ -f "$rec" ] || die "no such record: $rec"
  # Create the header (with a preceding blank line) the first time only; each
  # block is parsed on its own label, so this never disturbs Log: or a sibling.
  if grep -Fxq "$header" -- "$rec"; then
    append_atomic "$rec" "- ${text}"
  else
    append_atomic "$rec" "" "$header" "" "- ${text}"
  fi
}

sub="${1:-}"
[ -n "$sub" ] || die "usage: init|log|block ..."
shift || true

case "$sub" in
  init)  cmd_init "$@" ;;
  log)   cmd_log "$@" ;;
  block) cmd_block "$@" ;;
  *)     die "unknown subcommand: $sub" ;;
esac
