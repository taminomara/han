#!/usr/bin/env bash
# Scan the current branch's own history for the implement-work-items run record
# and emit the facts SKILL.md Step 1 interprets. Deterministic detector only:
# it classifies the invocation and reconstructs entry state; it makes no
# proceed / discard / surface judgment. Output is line-oriented key: value pairs
# plus one marker-delimited items block, mirroring detect-driver-context.sh.
#
# Usage: scan-run-history.sh <work-items-path> <base-ref>
#
# Arg 1 is the resolved work-items path; the caller passes it repo-root-relative
# (the run trailer records it that way). It is normalized as a pure string —
# strip a leading `./`, resolve `..`/`.` segments, drop a trailing slash — so a
# differently-spelled but equivalent repo-root-relative path still matches. It
# does not resolve an absolute or cwd-relative path to repo-root; that is the
# caller's precondition.
#
# Arg 2 is the base ref the caller already resolved (SKILL.md Step 1). History is
# scoped to commits on HEAD but not on that base, so a fresh run off any base —
# including a non-standard one like `develop` — is not misread as a foreign base.
# The script never re-derives the base and never defaults to scanning HEAD.
#
# Classification (over commits on HEAD but not on <base-ref>):
#   fresh    - no such commits (an empty branch of run work)
#   resume   - a commit carries `Implement-Work-Items-Run: <normalized path>`
#   refuse   - such commits exist but none records this path (a foreign base)
#   no-base  - <base-ref> was empty, missing, or did not resolve to a commit; the
#              caller must resolve a base before a run decision (the script will
#              not guess). The offending ref (or `none`) is echoed on the base line.
# Both run identity and the per-item code-commit reference are read as git
# trailers (exact key match), never as commit-message substrings.
#
# The items block reconstructs each ledger item's state from
# .implement-work-items/progress.md (started / done / done-no-commit / skipped;
# an item absent from the ledger is pending, which SKILL.md derives against the
# work-items file). A `done` line also carries its commit-resolution status:
# `resolved` when a scanned commit carries `Implement-Work-Items-Item: <id>`,
# `unresolved` otherwise. The items block is meaningful only on `resume`; on
# fresh / refuse / no-base the caller ignores it (a stray working-tree ledger
# may still populate it).

RAW_PATH="${1:-}"
BASE_REF="${2:-}"

# --- path normalization (pure string; no filesystem touch) -------------------
normalize_path() {
  local raw="$1" comp lead="" out=()
  [[ "$raw" == /* ]] && lead="/"
  local parts
  IFS='/' read -ra parts <<< "$raw"
  for comp in "${parts[@]}"; do
    case "$comp" in
      ''|'.') ;;
      '..')
        if [ ${#out[@]} -gt 0 ] && [ "${out[${#out[@]}-1]}" != ".." ]; then
          unset 'out[${#out[@]}-1]'
          out=("${out[@]}")
        elif [ -z "$lead" ]; then
          out+=("..")
        fi
        ;;
      *) out+=("$comp") ;;
    esac
  done
  local joined
  joined=$(IFS='/'; echo "${out[*]}")
  printf '%s' "${lead}${joined}"
}

NORM_PATH="$(normalize_path "$RAW_PATH")"
echo "work-items-path: ${NORM_PATH}"

# --- git guard (mirror detect-driver-context.sh robustness) ------------------
if ! command -v git &>/dev/null || ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "git-available: false"
  echo "branch: none"
  echo "classification: fresh"
  echo "commits-scanned: 0"
  echo "items-start"
  echo "items-end"
  exit 0
fi
echo "git-available: true"
BRANCH=$(git branch --show-current)
echo "branch: ${BRANCH:-none}"

# --- scope to commits on this branch but not on its base ---------------------
# The base ref is supplied by the caller, which resolves it once; excluding its
# inherited history keeps a fresh run off a real base branch from being misread
# as a foreign base. With no base — or one that does not resolve to a commit —
# there is no range to scan: never fall back to HEAD (that would count inherited
# commits as run work). Emit a distinct signal the caller must resolve instead of
# guessing. `--end-of-options` pins the ref as an operand so a value like
# `--output=<file>` can never be parsed as a git option.
if [ -z "$BASE_REF" ] || ! git rev-parse --verify --quiet --end-of-options "${BASE_REF}^{commit}" >/dev/null 2>&1; then
  echo "base: ${BASE_REF:-none}"
  echo "classification: no-base"
  echo "commits-scanned: 0"
  echo "items-start"
  echo "items-end"
  exit 0
fi
echo "base: ${BASE_REF}"

# `--end-of-options` sits last so the base ref is always an operand, never a git
# option; any later flags (e.g. `--format`) must precede the range accordingly.
RANGE=(HEAD --not --end-of-options "$BASE_REF")
COMMIT_COUNT=$(git rev-list --count "${RANGE[@]}" 2>/dev/null || echo 0)
mapfile -t RUN_VALUES < <(git log \
  --format='%(trailers:key=Implement-Work-Items-Run,valueonly=true)' "${RANGE[@]}" 2>/dev/null)
mapfile -t ITEM_VALUES < <(git log \
  --format='%(trailers:key=Implement-Work-Items-Item,valueonly=true)' "${RANGE[@]}" 2>/dev/null)

# --- classify ----------------------------------------------------------------
CLASS="refuse"
if [ "${COMMIT_COUNT:-0}" -eq 0 ]; then
  CLASS="fresh"
elif [ -n "$NORM_PATH" ] && printf '%s\n' "${RUN_VALUES[@]}" | grep -Fxq "$NORM_PATH"; then
  CLASS="resume"
fi
echo "classification: ${CLASS}"
echo "commits-scanned: ${COMMIT_COUNT:-0}"

# --- reconstruct per-item entry state from the committed ledger --------------
LEDGER=$(git show HEAD:.implement-work-items/progress.md 2>/dev/null)
if [ -z "$LEDGER" ]; then
  TOP=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$TOP" ] && [ -f "$TOP/.implement-work-items/progress.md" ]; then
    LEDGER=$(cat "$TOP/.implement-work-items/progress.md")
  fi
fi

# Which items have a resolvable code commit (item-id trailer in the scanned range).
declare -A ITEM_RESOLVED
for v in "${ITEM_VALUES[@]}"; do
  [ -n "$v" ] && ITEM_RESOLVED["$v"]=1
done

# Last entry wins per item; start-of-item always precedes its terminal entry.
# The `- <token>: <id>` line grammar is a contract shared with the ledger writer;
# a writer that changes it silently reconstructs zero items.
declare -A ITEM_STATE
ITEM_ORDER=()
while IFS= read -r line; do
  if [[ "$line" =~ ^-[[:space:]]+(start-of-item|no-commit-done|done|skip):[[:space:]]*([^[:space:]]+) ]]; then
    tok="${BASH_REMATCH[1]}"
    item="${BASH_REMATCH[2]}"
    case "$tok" in
      start-of-item)   state="started" ;;
      done)            state="done" ;;
      no-commit-done)  state="done-no-commit" ;;
      skip)            state="skipped" ;;
    esac
    if [ -z "${ITEM_STATE[$item]+x}" ]; then
      ITEM_ORDER+=("$item")
    fi
    ITEM_STATE["$item"]="$state"
  fi
done <<< "$LEDGER"

echo "items-start"
for item in "${ITEM_ORDER[@]}"; do
  state="${ITEM_STATE[$item]}"
  if [ "$state" = "done" ]; then
    if [ -n "${ITEM_RESOLVED[$item]+x}" ]; then
      echo "$item done resolved"
    else
      echo "$item done unresolved"
    fi
  else
    echo "$item $state"
  fi
done
echo "items-end"
