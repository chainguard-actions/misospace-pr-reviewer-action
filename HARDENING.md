<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.8

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.8** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression in a `run:` block is a script-injection finding regardless of which context it reads from. The affected steps are: 'Check whether review is needed' (`run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`), 'Wait for CI checks to complete' (`run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`), and 'Run AI review' (`run: bash "${{ github.action_path }}/scripts/run_review.sh"`). The 'Publish review' step correctly hoists `github.action_path` into an env var (`GITHUB_ACTION_PATH: ${{ github.action_path }}`) and uses `${GITHUB_ACTION_PATH}` in the shell body — that pattern is safe and should be applied to the other three steps.

Locations:

- `action.yml:476`
- `action.yml:497`
- `action.yml:570`

### github-env-injection (severity: high)

In scripts/check_review_needed.sh, the variable `EFFECTIVE_FORGEJO_API_URL` — derived directly from `inputs.forgejo_api_url` (an action input, and therefore attacker-controllable) — is written to `$GITHUB_OUTPUT` via `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` without the required newline-stripping sanitization (`printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`). This occurs at multiple early-exit paths and in the main output block. A value containing embedded newlines could inject additional key=value pairs into GITHUB_OUTPUT, potentially overwriting other step outputs (e.g. `should_review`, `resolved_platform`) and influencing downstream step behavior.

Locations:

- `scripts/check_review_needed.sh:68`
- `scripts/check_review_needed.sh:97`
- `scripts/check_review_needed.sh:340`
- `scripts/check_review_needed.sh:393`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml: added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to the env blocks of the 'Check whether review is needed', 'Wait for CI checks to complete', and 'Run AI review' steps, and changed their run lines from `bash "${{ github.action_path }}/scripts/..."` to `bash "${GITHUB_ACTION_PATH}/scripts/..."`. Fixed github-env-injection in scripts/check_review_needed.sh: added a single sanitization step immediately after EFFECTIVE_FORGEJO_API_URL is assigned (`EFFECTIVE_FORGEJO_API_URL="$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"`), which covers all four GITHUB_OUTPUT write locations.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in scripts/sections/review.sh: replaced the direct `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` with a two-step approach that first sanitizes ANALYSIS_ENGINE by stripping newline characters using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'` into `_safe_analysis_engine`, then writes the sanitized value to $OUTPUT_FILE. This matches the existing sanitization pattern used for EFFECTIVE_FORGEJO_API_URL in check_review_needed.sh and prevents newline injection attacks via attacker-controlled model name or base URL inputs.

