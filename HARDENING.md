<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.7** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml interpolate `${{ github.action_path }}` directly inside the run command string. Any `${{ ... }}` expression in a `run:` block is a script-injection risk because YAML template substitution occurs before the shell sees the string. The publish step correctly hoists this into an env var (`GITHUB_ACTION_PATH: ${{ github.action_path }}`), but the other three steps do not. Offending lines: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `run: bash "${{ github.action_path }}/scripts/run_review.sh"`.

Locations:

- `action.yml:500`
- `action.yml:510`
- `action.yml:650`

### github-env-injection (severity: high)

The variable `EFFECTIVE_FORGEJO_API_URL` is derived from the action input `inputs.forgejo_api_url` (or `github.server_url`) via the env block `FORGEJO_API_URL: ${{ inputs.forgejo_api_url || (github.server_url != 'https://github.com' && github.server_url) || '' }}`. In scripts/check_review_needed.sh it is written to `$GITHUB_OUTPUT` multiple times (early-exit blocks and main exit) with plain `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` — without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A crafted input value containing embedded newlines could inject additional key=value pairs into GITHUB_OUTPUT (e.g., flipping the `verdict` output).

Locations:

- `scripts/check_review_needed.sh:100`
- `scripts/check_review_needed.sh:380`
- `scripts/check_review_needed.sh:600`

### github-env-injection (severity: high)

The variable `ANALYSIS_ENGINE` is built from `AI_MODEL`, `AI_BASE_URL`, and `AI_API_FORMAT`, which are set from action inputs `inputs.ai_model`, `inputs.ai_base_url`, and `inputs.ai_api_format` respectively. In scripts/sections/review.sh it is written to `$GITHUB_OUTPUT` as `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A crafted input value containing embedded newlines could inject additional key=value pairs into GITHUB_OUTPUT.

Locations:

- `scripts/sections/review.sh:340`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed 3 findings across 3 files:

1. action.yml (script-injection): Added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to the env blocks of the 'Check whether review is needed', 'Wait for CI checks to complete', and 'Run AI review' steps. Changed their `run:` commands from `bash "${{ github.action_path }}/scripts/..."` to `bash "$GITHUB_ACTION_PATH/scripts/..."` to eliminate direct ${{ }} interpolation in run strings.

2. scripts/check_review_needed.sh (github-env-injection): Sanitized EFFECTIVE_FORGEJO_API_URL at the point of assignment using `printf '%s' "${FORGEJO_API_URL:-}" | tr -d '\n\r'`. This covers all three downstream writes to $OUTPUT_FILE (two early-exit blocks and the main exit path).

3. scripts/sections/review.sh (github-env-injection): Added `SAFE_ANALYSIS_ENGINE="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` before the `echo "analysis_engine=..."` write to $OUTPUT_FILE, and used the sanitized variable in the echo.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the 'Normalize release metadata' step in .github/workflows/manual-release.yml. Each value derived from the workflow input (tag, major_tag, sha, prerelease) is now sanitized with `printf '%s' ... | tr -d '\n\r'` before being written to $GITHUB_OUTPUT. The sanitized values are stored in SAFE_TAG, SAFE_MAJOR_TAG, SAFE_SHA, and SAFE_PRERELEASE variables, which are then written to $GITHUB_OUTPUT instead of the raw derived values.

