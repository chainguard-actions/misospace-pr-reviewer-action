<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.11

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.11** was hardened automatically. 2 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression inside a `run:` block — including `github.*` contexts — is a script-injection risk because the value is substituted by the YAML template engine before the shell ever sees it. The affected lines are:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (Check whether review is needed step)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (Wait for CI checks step)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (Run AI review step)

The fix is to hoist `github.action_path` into an env var (e.g. `ACTION_PATH: ${{ github.action_path }}`) and reference it as `"$ACTION_PATH"` in the shell, as the Publish review step already does correctly with `GITHUB_ACTION_PATH`.

Locations:

- `action.yml:494`
- `action.yml:519`
- `action.yml:607`

### github-env-injection (severity: high)

In `scripts/check_review_needed.sh`, the variable `EFFECTIVE_FORGEJO_API_URL` — which is derived from `inputs.forgejo_api_url` (an action input set by the calling workflow via `FORGEJO_API_URL: ${{ inputs.forgejo_api_url || ... }}` in action.yml) — is written to `$GITHUB_OUTPUT` in multiple places without the required `printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'` sanitization step. A caller supplying a value containing newlines could inject arbitrary additional key=value pairs into the step output, potentially overwriting outputs such as `resolved_platform` or `should_review`. The unsanitized writes appear in all four early-exit and normal-exit paths:
- `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` (multiple locations)

Locations:

- `scripts/check_review_needed.sh:97`
- `scripts/check_review_needed.sh:230`
- `scripts/check_review_needed.sh:380`
- `scripts/check_review_needed.sh:407`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml by hoisting `github.action_path` into an `ACTION_PATH` env var for three steps (check_review_needed, wait_for_ci, run_review) and referencing `$ACTION_PATH` in the shell. Fixed github-env-injection in scripts/check_review_needed.sh by sanitizing `EFFECTIVE_FORGEJO_API_URL` with `printf '%s' ... | tr -d '\n\r'` immediately after it is assigned, covering all four GITHUB_OUTPUT write locations.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'Normalize release metadata' step of .github/workflows/manual-release.yml, added mandatory sanitization using `printf '%s' "$VAR" | tr -d '\n\r'` for all values derived from the user-controlled `inputs.version` before writing to $GITHUB_OUTPUT. Created SAFE_VERSION, SAFE_MAJOR, SAFE_PRERELEASE, and SAFE_SHA variables and used them in the heredoc block that writes to $GITHUB_OUTPUT, preventing any potential newline-based injection attacks.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in hardened/action/scripts/sections/review.sh at line 280. The ANALYSIS_ENGINE variable (constructed from user-controlled inputs AI_MODEL, AI_BASE_URL, AI_API_FORMAT, and their fallback/smart counterparts) was written directly to $GITHUB_OUTPUT without sanitization. Added a sanitization step: `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` and changed the echo to use `$safe_analysis_engine` instead of `$ANALYSIS_ENGINE`. This prevents a caller who supplies a model name or base URL containing a newline character from injecting arbitrary key=value pairs into the GITHUB_OUTPUT file.

