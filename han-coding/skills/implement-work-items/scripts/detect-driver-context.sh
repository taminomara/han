#!/usr/bin/env bash
# Detect git state, uncommitted files, and infer verification commands from
# project manifests for the implement-work-items driver. Run ONCE in Step 1.
#
# Per-item verification runs do NOT use this script: they call the resolved
# verification commands directly so the loop is not interrupted by a
# per-invocation approval every item. Command inference here is a best-effort
# fallback used only when CLAUDE.md / project-discovery.md did not resolve the
# commands; the emitted commands are suggestions the operator confirms at the
# plan preview, not authority. Output is line-oriented key: value pairs.

# --- git state ---------------------------------------------------------------
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "git-available: true"
  BRANCH=$(git branch --show-current)
  echo "branch: ${BRANCH:-none}"
  if git symbolic-ref --short refs/remotes/origin/HEAD &>/dev/null; then
    echo "default-branch: $(git symbolic-ref --short refs/remotes/origin/HEAD)"
  else
    echo "default-branch: none"
  fi
  # Uncommitted entries (tracked and untracked), honoring .gitignore and
  # .git/info/exclude. The driver compares this list against the planning
  # artifacts for the clean-tree check; anything else uncommitted is a refusal.
  echo "uncommitted-start"
  git status --porcelain
  echo "uncommitted-end"
else
  echo "git-available: false"
  echo "branch: none"
  echo "default-branch: none"
  echo "uncommitted-start"
  echo "uncommitted-end"
fi

# --- manifest-inferred commands ----------------------------------------------
# First match wins per category. These are suggestions; the operator confirms.
TEST_CMD=""
LINT_CMD=""
BUILD_CMD=""

if [ -f package.json ]; then
  echo "manifest: package.json"
  grep -q '"test"[[:space:]]*:' package.json && TEST_CMD="npm test"
  grep -q '"lint"[[:space:]]*:' package.json && LINT_CMD="npm run lint"
  grep -q '"build"[[:space:]]*:' package.json && BUILD_CMD="npm run build"
fi

if [ -z "$TEST_CMD" ] && { [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.cfg ] || [ -f tox.ini ]; }; then
  echo "manifest: python (pyproject/pytest)"
  TEST_CMD="pytest"
fi

if [ -z "$TEST_CMD" ] && [ -f go.mod ]; then
  echo "manifest: go.mod"
  TEST_CMD="go test ./..."
  BUILD_CMD="go build ./..."
fi

if [ -z "$TEST_CMD" ] && [ -f Cargo.toml ]; then
  echo "manifest: Cargo.toml"
  TEST_CMD="cargo test"
  BUILD_CMD="cargo build"
fi

if [ -z "$TEST_CMD" ] && { [ -f Gemfile ] || [ -f Rakefile ] || [ -d spec ]; }; then
  echo "manifest: ruby (Gemfile/Rakefile)"
  if [ -d spec ]; then TEST_CMD="bundle exec rspec"; else TEST_CMD="bundle exec rake test"; fi
fi

if [ -z "$TEST_CMD" ] && [ -f mix.exs ]; then
  echo "manifest: mix.exs"
  TEST_CMD="mix test"
fi

if [ -z "$TEST_CMD" ] && { [ -f pom.xml ]; }; then
  echo "manifest: pom.xml"
  TEST_CMD="mvn test"
  BUILD_CMD="mvn package"
fi

if [ -z "$TEST_CMD" ] && { [ -f build.gradle ] || [ -f build.gradle.kts ]; }; then
  echo "manifest: gradle"
  TEST_CMD="gradle test"
  BUILD_CMD="gradle build"
fi

if [ -z "$TEST_CMD" ] && [ -n "$(find . -maxdepth 3 -name '*.csproj' -print -quit 2>/dev/null)" ]; then
  echo "manifest: dotnet (.csproj)"
  TEST_CMD="dotnet test"
  BUILD_CMD="dotnet build"
fi

# A Makefile with a test target is a common override regardless of language.
if [ -f Makefile ] && grep -qE '^test:' Makefile; then
  echo "manifest: Makefile (test target)"
  [ -z "$TEST_CMD" ] && TEST_CMD="make test"
  grep -qE '^lint:' Makefile && [ -z "$LINT_CMD" ] && LINT_CMD="make lint"
  grep -qE '^build:' Makefile && [ -z "$BUILD_CMD" ] && BUILD_CMD="make build"
fi

echo "inferred-test-command: ${TEST_CMD:-none}"
echo "inferred-lint-command: ${LINT_CMD:-none}"
echo "inferred-build-command: ${BUILD_CMD:-none}"
