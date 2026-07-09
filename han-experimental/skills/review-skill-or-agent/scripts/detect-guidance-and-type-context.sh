#!/usr/bin/env bash
# Resolve the review target's type and the plugin-authoring guidance root, and
# report the guidance's completeness. Emits `key: value` lines the SKILL body
# branches on. Degrades cleanly (emits none/neither, never crashes) so a missing
# guidance install halts the review rather than erroring.
#
# Usage: detect-guidance-and-type-context.sh <target-path>
set -uo pipefail

TARGET="${1:-}"

emit() { printf '%s: %s\n' "$1" "$2"; }

# --- 1. Resolve the target's structural type ------------------------------
# skill    : a directory containing SKILL.md with skill-shaped frontmatter
# agent    : a .md file under an agents/ path with agent-shaped frontmatter
# mismatch : resembles a type by location but the structural test fails
# neither  : not a skill or agent
frontmatter_shape() {
  # Reads the first frontmatter block of $1; echoes "skill", "agent", or "unknown".
  local f="$1" head
  head="$(sed -n '1,40p' "$f" 2>/dev/null)"
  if printf '%s' "$head" | grep -qE '^allowed-tools:'; then
    echo skill
  elif printf '%s' "$head" | grep -qE '^(tools|model):'; then
    echo agent
  else
    echo unknown
  fi
}

TYPE=neither
SIGNAL="target is neither a skill directory nor an agent file"

if [ -z "$TARGET" ] || [ ! -e "$TARGET" ]; then
  TYPE=neither
  SIGNAL="target path is empty or does not exist"
elif [ -d "$TARGET" ]; then
  if [ -f "$TARGET/SKILL.md" ]; then
    if [ "$(frontmatter_shape "$TARGET/SKILL.md")" = agent ]; then
      TYPE=mismatch
      SIGNAL="directory has SKILL.md but its frontmatter is agent-shaped (model set, no allowed-tools)"
    else
      TYPE=skill
      SIGNAL="directory with SKILL.md"
    fi
  else
    TYPE=mismatch
    SIGNAL="directory given but no SKILL.md found at $TARGET/SKILL.md"
  fi
elif [ -f "$TARGET" ] && [ "${TARGET##*.}" = md ]; then
  case "$TARGET" in
    */agents/*)
      if [ "$(frontmatter_shape "$TARGET")" = skill ]; then
        TYPE=mismatch
        SIGNAL="file under agents/ but its frontmatter is skill-shaped (allowed-tools present, no model)"
      else
        TYPE=agent
        SIGNAL="markdown file under an agents/ path"
      fi
      ;;
    *)
      TYPE=neither
      SIGNAL="markdown file that is neither a SKILL.md in a skill directory nor under an agents/ path"
      ;;
  esac
fi

emit target-path "${TARGET//$'\n'/ }"   # strip newlines so a crafted caller target cannot forge a key: value line
emit target-type "$TYPE"
emit structural-signal "$SIGNAL"

# Cheap roster signals for the target: how many reference files it carries, and
# whether it ships supporting scripts. The orchestrator reads the fuzzier signals
# (interaction model, control-flow complexity) from the body itself.
if [ "$TYPE" = skill ]; then
  rc="$(find "$TARGET/references" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
  hs=false
  [ -n "$(find "$TARGET/scripts" -maxdepth 1 -type f 2>/dev/null)" ] && hs=true
  blc="$(wc -l < "$TARGET/SKILL.md" 2>/dev/null | tr -d ' ')"
  emit reference-count "${rc:-0}"
  emit has-scripts "$hs"
  emit body-line-count "${blc:-0}"
elif [ "$TYPE" = agent ]; then
  blc="$(wc -l < "$TARGET" 2>/dev/null | tr -d ' ')"
  emit reference-count 0
  emit has-scripts false
  emit body-line-count "${blc:-0}"
fi

# Stop here for targets that carry no type — no guidance to resolve.
if [ "$TYPE" = neither ] || [ "$TYPE" = mismatch ]; then
  emit guidance-root none
  emit guidance-complete false
  exit 0
fi

# --- 2. Locate the authoring-guidance root --------------------------------
# Prefer the installed han-plugin-builder copy (trusted) over a repo-local
# vendored copy (mutable in the working tree).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"   # skills/<name>/scripts -> plugin root
PLUGINS_PARENT="$(dirname "$PLUGIN_ROOT")"

GUIDANCE_ROOT=none
# (a) sibling plugin, flat layout
if [ -d "$PLUGINS_PARENT/han-plugin-builder/skills/guidance/references" ]; then
  GUIDANCE_ROOT="$PLUGINS_PARENT/han-plugin-builder/skills/guidance/references"
else
  # (b) sibling plugin, one nesting level down (marketplace layout)
  found="$(find "$PLUGINS_PARENT" -maxdepth 4 -type d -path '*/han-plugin-builder/skills/guidance/references' 2>/dev/null | head -n 1)"
  if [ -n "$found" ]; then
    GUIDANCE_ROOT="$found"
  elif [ -d ".claude/skills/plugin-guidance/references" ]; then
    # (c) repo-local vendored copy, relative to CWD
    GUIDANCE_ROOT=".claude/skills/plugin-guidance/references"
  fi
fi

emit guidance-root "$GUIDANCE_ROOT"

if [ "$GUIDANCE_ROOT" = none ]; then
  emit guidance-complete false
  exit 0
fi

# --- 3. Completeness of the type-appropriate subtree ----------------------
if [ "$TYPE" = skill ]; then
  SUBTREE="$GUIDANCE_ROOT/skill-building-guidance"
  # Every file the review-checklist and finding-classification bands ground against, so a
  # partial guidance install cannot report complete and leave a check ungrounded (SUGG-002).
  REQUIRED="skill-description-frontmatter.md skill-description-length.md naming-conventions.md progressive-disclosure.md skill-reference-files.md writing-effective-instructions.md workflow-patterns.md allowed-tools-bash-permissions.md allowed-tools-AskUserQuestion.md security-restrictions.md agent-dispatch-namespacing.md graceful-degradation.md dynamic-project-discovery.md optional-git-repositories.md script-execution-instructions.md success-criteria-and-testing.md"
else
  SUBTREE="$GUIDANCE_ROOT/agent-building-guidelines"
  REQUIRED="agent-domain-focus.md agent-description-length.md agent-model-selection.md agent-external-files.md multi-agent-economics.md graceful-degradation.md"
fi

emit guidance-subtree "$SUBTREE"

if [ ! -d "$SUBTREE" ] || [ ! -f "$GUIDANCE_ROOT/plugin-entity-taxonomy.md" ]; then
  emit guidance-complete false
  emit guidance-missing "type subtree $SUBTREE or plugin-entity-taxonomy.md absent"
  exit 0
fi

MISSING=""
for f in $REQUIRED; do
  [ -f "$SUBTREE/$f" ] || MISSING="$MISSING $f"
done

if [ -n "$MISSING" ]; then
  emit guidance-complete false
  emit guidance-missing "${MISSING# }"
else
  emit guidance-complete true
fi
