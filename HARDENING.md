<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.4.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.4.0** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Four `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression in a `run:` block is a script-injection risk because the expression is substituted by the GitHub Actions template engine before the shell ever sees the string. Affected lines: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, `run: bash "${{ github.action_path }}/scripts/run_review.sh"`, and `run: bash "${{ github.action_path }}/scripts/publish.sh"`. The safe alternative is to use the `$GITHUB_ACTION_PATH` environment variable (already available in composite actions) instead of the `${{ github.action_path }}` expression.

Locations:

- `action.yml:596`
- `action.yml:617`
- `action.yml:720`
- `action.yml:779`

### github-env-injection (severity: high)

In `scripts/check_review_needed.sh`, the variable `EFFECTIVE_FORGEJO_API_URL` is derived from the `FORGEJO_API_URL` environment variable, which is set from the caller-controlled `inputs.forgejo_api_url` action input. This value is written to `$GITHUB_OUTPUT` in four separate code paths (early-exit branches and the final output block) without the required sanitization step (`printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`). A calling workflow that supplies a `forgejo_api_url` value containing embedded newlines could inject arbitrary key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting step outputs such as `should_review`, `verdict`, or `resolved_platform`. Example unsafe write: `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"`.

Locations:

- `scripts/check_review_needed.sh:85`
- `scripts/check_review_needed.sh:100`
- `scripts/check_review_needed.sh:285`
- `scripts/check_review_needed.sh:370`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml by replacing all 4 occurrences of `bash "${{ github.action_path }}/scripts/..."` with `bash "$GITHUB_ACTION_PATH/scripts/..."` — the $GITHUB_ACTION_PATH env var is already available in composite actions and is not subject to template injection. Fixed github-env-injection in scripts/check_review_needed.sh by sanitizing EFFECTIVE_FORGEJO_API_URL at the point of assignment with `printf '%s' "${FORGEJO_API_URL:-}" | tr -d '\n\r'`, which covers all 4 write locations to $GITHUB_OUTPUT without requiring changes to each individual echo statement.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed scripts/sections/review.sh: Before writing ANALYSIS_ENGINE to $GITHUB_OUTPUT (via $OUTPUT_FILE), the value is now sanitized using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'` to strip any embedded newline or carriage return characters. This prevents a calling workflow from injecting arbitrary key-value pairs into $GITHUB_OUTPUT by supplying ai_model or ai_base_url inputs containing newline characters.

