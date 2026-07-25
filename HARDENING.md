<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.5** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml interpolate `${{ github.action_path }}` directly inside the shell command string. Per the check rules, any `${{ ... }}` expression inside a `run:` block is a script-injection finding regardless of which context it reads from. The safe alternative is to use the pre-set `$GITHUB_ACTION_PATH` environment variable instead of the template expression.

Offending lines:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (step: Check whether review is needed)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (step: Wait for CI checks to complete)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (step: Run AI review)

Locations:

- `action.yml:750`
- `action.yml:780`
- `action.yml:950`

### github-env-injection (severity: high)

The variable `EFFECTIVE_FORGEJO_API_URL` is set directly from `FORGEJO_API_URL` (which is populated from `inputs.forgejo_api_url`, a caller-controlled input), and then written to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). A newline embedded in the input value could inject arbitrary additional key=value pairs into the step output file. This write occurs in three code paths (two early-exit blocks and the main output block at the end of the script).

Locations:

- `scripts/check_review_needed.sh:100`
- `scripts/check_review_needed.sh:350`
- `scripts/check_review_needed.sh:600`

### github-env-injection (severity: high)

The variable `ANALYSIS_ENGINE` is constructed from `$AI_MODEL`, `$AI_BASE_URL`, and `$AI_API_FORMAT` — all of which are populated from caller-controlled inputs (`inputs.ai_model`, `inputs.ai_base_url`, `inputs.ai_api_format`) via the step's `env:` block. This value is then written to `$GITHUB_OUTPUT` with `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` without the required sanitization step (`printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'`). A newline embedded in any of the input values could inject arbitrary additional key=value pairs into the step output file, potentially overwriting outputs such as `verdict`.

Locations:

- `scripts/sections/review.sh:340`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three script-injection findings in action.yml by replacing '${{ github.action_path }}' template expressions inside run: shell strings with the pre-set '$GITHUB_ACTION_PATH' environment variable for all three steps (check_review_needed.sh, wait_for_ci.sh, run_review.sh). Fixed three github-env-injection instances in scripts/check_review_needed.sh by sanitizing EFFECTIVE_FORGEJO_API_URL with 'printf | tr -d newlines' before writing to $GITHUB_OUTPUT in all three code paths (label no-op early exit, diff-unchanged early exit, and main output block). Fixed one github-env-injection instance in scripts/sections/review.sh by sanitizing ANALYSIS_ENGINE with 'printf | tr -d newlines' before writing to $GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the 'Normalize release metadata' step in .github/workflows/manual-release.yml. The user-controlled VERSION value (derived from inputs.version via RAW_VERSION env var) is now sanitized with `printf '%s' "$VERSION" | tr -d '\n\r'` before being written to GITHUB_OUTPUT. The MAJOR version suffix and PRERELEASE flag are also sanitized. This closes the bash ERE `$`-before-newline bypass where a value like `1.2.3\n` could pass the regex guard but still inject additional key=value pairs into GITHUB_OUTPUT, potentially overwriting downstream step outputs like `sha` or `prerelease`.

