<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.2.0** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Per the check rules, ANY `${{ ... }}` expression directly inside a `run:` shell command string is a script-injection finding, including `github.*` contexts. The affected lines are:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (Check whether review is needed step)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (Wait for CI checks to complete step)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (Run AI review step)

The safe pattern is to hoist `github.action_path` into an `env:` variable (e.g. `GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference it as `"${GITHUB_ACTION_PATH}/scripts/..."` in the run: body. The Publish review step already does this correctly.

Locations:

- `action.yml:700`
- `action.yml:726`
- `action.yml:840`

### github-env-injection (severity: high)

In the 'Normalize release metadata' step of manual-release.yml, the `workflow_dispatch` input `inputs.version` is mapped to env var `RAW_VERSION` and then written to `$GITHUB_OUTPUT` via `echo "tag=v$VERSION"`, `echo "major_tag=v${VERSION%%.*}"`, `echo "sha=$(git rev-parse HEAD)"`, and `echo "prerelease=$PRERELEASE"` without the required sanitization step (`printf '%s' "$VERSION" | tr -d '\n\r'`). Although a regex validates the version format (which would prevent newline injection in practice), the check requires the explicit `tr -d '\n\r'` sanitization pipeline before every write of a value derived from an untrusted input source to a special environment file.

Locations:

- `.github/workflows/manual-release.yml:46`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed two security findings:

1. script-injection (action.yml, lines ~700, ~726, ~840): Three `run:` steps were directly interpolating `${{ github.action_path }}` inside the shell command string. Fixed by adding `GITHUB_ACTION_PATH: ${{ github.action_path }}` to each step's `env:` block and changing the `run:` commands to use `bash "${GITHUB_ACTION_PATH}/scripts/..."` instead.

2. github-env-injection (.github/workflows/manual-release.yml, line ~46): The 'Normalize release metadata' step was writing values derived from `inputs.version` to `$GITHUB_OUTPUT` without newline sanitization. Fixed by introducing `SAFE_VERSION`, `SAFE_MAJOR`, `SAFE_SHA`, and `SAFE_PRERELEASE` variables, each sanitized with `printf '%s' "$VAR" | tr -d '\n\r'`, and using those safe variables in the `echo` statements that write to `$GITHUB_OUTPUT`.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection findings:
1. hardened/action/scripts/check_review_needed.sh: Sanitized EFFECTIVE_FORGEJO_API_URL at the single assignment point (after platform_resolve()) using `printf '%s' "${FORGEJO_API_URL:-}" | tr -d '\n\r'`. This covers all four write locations (the unrelated-label early exit, the superseded-head early exit, the should_review=false early exit, and the normal end-of-script path) since they all reference the same variable.
2. hardened/action/scripts/sections/review.sh: Added sanitization of ANALYSIS_ENGINE before writing to $OUTPUT_FILE: `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` and changed the echo to use `$safe_analysis_engine` instead of `$ANALYSIS_ENGINE`.

