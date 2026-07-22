<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.2** was hardened automatically. 2 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Three `run:` blocks in action.yml interpolate `${{ github.action_path }}` directly inside the shell command string (rule a). Any `${{ ... }}` expression embedded in a `run:` script is a script-injection finding regardless of which context it reads from. The safe pattern — already used by the 'Publish review' step — is to hoist the value into an `env:` variable (e.g. `GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference it as `${GITHUB_ACTION_PATH}` in the shell body. Affected lines:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (step: 'Check whether review is needed')
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (step: 'Wait for CI checks to complete')
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (step: 'Run AI review')

Locations:

- `action.yml:530`
- `action.yml:545`
- `action.yml:620`

### github-env-injection (severity: high)

In scripts/check_review_needed.sh, the variable `EFFECTIVE_FORGEJO_API_URL` — derived directly from `${FORGEJO_API_URL:-}`, which is set from `inputs.forgejo_api_url` in the action's env block — is written to `$GITHUB_OUTPUT` (via `$OUTPUT_FILE`) without the required sanitization step (`printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`). A caller-supplied URL containing embedded newline characters could inject additional `key=value` pairs into GITHUB_OUTPUT, potentially overwriting step outputs such as `resolved_platform`, `should_review`, or `diff_fingerprint`. The unsanitized write occurs at three locations (early-exit for unrelated-label, early-exit for diff-unchanged, and the normal completion path).

Locations:

- `scripts/check_review_needed.sh:80`
- `scripts/check_review_needed.sh:310`
- `scripts/check_review_needed.sh:540`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml: added GITHUB_ACTION_PATH env var to the 'Check whether review is needed', 'Wait for CI checks to complete', and 'Run AI review' steps, replacing inline ${{ github.action_path }} expressions in run: blocks with ${GITHUB_ACTION_PATH}. Fixed github-env-injection in scripts/check_review_needed.sh: sanitized EFFECTIVE_FORGEJO_API_URL with `printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT at all three locations (unrelated-label early exit ~line 80, diff-unchanged early exit ~line 310, and normal completion path ~line 540).

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In hardened/action/scripts/sections/review.sh, added sanitization of the ANALYSIS_ENGINE variable before writing it to $GITHUB_OUTPUT (via $OUTPUT_FILE). The fix introduces a `safe_analysis_engine` variable that strips newlines and carriage returns using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'`, then writes `safe_analysis_engine` instead of the raw `ANALYSIS_ENGINE` to the output file. This prevents injection of arbitrary key=value pairs into GITHUB_OUTPUT via embedded newlines in user-controlled inputs (ai_model, ai_base_url, ai_api_format, and their fallback/smart counterparts).

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

In .github/workflows/manual-release.yml, the 'Normalize release metadata' step now sanitizes all four GITHUB_OUTPUT writes using the prescribed pattern: each value (tag, major_tag, sha, prerelease) is first passed through `printf '%s' ... | tr -d '\n\r'` into a SAFE_* variable, and the SAFE_* variables are then written to $GITHUB_OUTPUT. This satisfies the required sanitization pattern while preserving the existing regex validation and overall step logic.

