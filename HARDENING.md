<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.10

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.10** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression inside a `run:` block is a script-injection risk because the expression is substituted by the Actions template engine before the shell ever sees the string. The three offending lines are:
1. `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (precheck step)
2. `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (ci_status step)
3. `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (review step)
The safe pattern is to hoist `github.action_path` into an `env:` variable (e.g. `ACTION_PATH: ${{ github.action_path }}`) and then reference `"${ACTION_PATH}/scripts/..."` in the run body — as the publish step already does correctly via `GITHUB_ACTION_PATH`.

Locations:

- `action.yml:621`
- `action.yml:663`
- `action.yml:733`

### github-env-injection (severity: high)

In the 'Normalize release metadata' step of manual-release.yml, the `VERSION` variable is derived from `inputs.version` (a `workflow_dispatch` user input) and written to `$GITHUB_OUTPUT` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. The script validates `VERSION` with a regex before writing, but the check requires the specific sanitization pipeline applied immediately before the write. The four values written are: `tag=v$VERSION`, `major_tag=v${VERSION%%.*}`, `sha=$(git rev-parse HEAD)`, and `prerelease=$PRERELEASE`. The `VERSION`-derived values should be sanitized with `safe=$(printf '%s' "$VERSION" | tr -d '\n\r')` before being echoed to `$GITHUB_OUTPUT`.

Locations:

- `.github/workflows/manual-release.yml:50`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three script-injection issues in action.yml by hoisting `github.action_path` into an `ACTION_PATH` env variable for each of the precheck, ci_status, and review steps, then referencing `${ACTION_PATH}/scripts/...` in the shell. Fixed github-env-injection in .github/workflows/manual-release.yml by adding `printf '%s' "$VAR" | tr -d '\n\r'` sanitization for all four values (tag, major_tag, sha, prerelease) before writing them to $GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed 5 github-env-injection vulnerabilities:

1. scripts/check_review_needed.sh (4 locations): Replaced all 4 plain `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL"` writes to $OUTPUT_FILE with `printf 'effective_forgejo_api_url=%s\n' "$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"`. The four locations were: (a) the unrelated-label early exit block, (b) the should_review=false short-circuit block, (c) the superseded-head early exit block, and (d) the main output block at the end of the script.

2. scripts/sections/review.sh (1 location): Replaced the plain `echo "analysis_engine=$ANALYSIS_ENGINE"` write to $OUTPUT_FILE with `printf 'analysis_engine=%s\n' "$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"`. This prevents model names or base URLs containing newline characters from injecting arbitrary key=value pairs into the step output file.

