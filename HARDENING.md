<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.1.2** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Three `run:` blocks in action.yml directly interpolate `${{ github.action_path }}` inside shell command strings. Any `${{ ... }}` expression inside a `run:` block is a script-injection risk because the value is substituted by the YAML template engine before the shell sees it, bypassing shell quoting. The safe pattern is to route the value through an `env:` variable (as the publish step already does with `GITHUB_ACTION_PATH: ${{ github.action_path }}`). Offending lines: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `run: bash "${{ github.action_path }}/scripts/run_review.sh"`.

Locations:

- `action.yml:700`
- `action.yml:730`
- `action.yml:800`

### github-env-injection (severity: high)

The `EFFECTIVE_FORGEJO_API_URL` variable — derived directly from `inputs.forgejo_api_url` (a caller-controlled composite-action input) — is written to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). A value containing a newline character would allow injection of arbitrary additional key=value pairs into the step outputs, potentially overwriting outputs such as `should_review`, `resolved_platform`, or `is_fork_pr`. This write occurs in three places in scripts/check_review_needed.sh: the main output block at the end of the script, and two early-exit paths.

Locations:

- `scripts/check_review_needed.sh:88`
- `scripts/check_review_needed.sh:340`
- `scripts/check_review_needed.sh:580`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml: added GITHUB_ACTION_PATH: ${{ github.action_path }} to the env: blocks of the 'Check whether review is needed', 'Wait for CI checks to complete', and 'Run AI review' steps, and updated their run: commands to use $GITHUB_ACTION_PATH instead of the ${{ github.action_path }} template expression. Fixed github-env-injection in scripts/check_review_needed.sh: sanitized EFFECTIVE_FORGEJO_API_URL with `printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT in all three locations (early exit for unrelated label, early exit when should_review=false, and the main output block at the end of the script).

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in hardened/action/scripts/sections/review.sh at line 300. The ANALYSIS_ENGINE variable (composed from user-controlled inputs like ai_model, ai_base_url, ai_fallback_model, ai_fallback_base_url, ai_smart_model, ai_smart_base_url) was written directly to $OUTPUT_FILE (GITHUB_OUTPUT) without sanitization. The fix introduces a `safe_analysis_engine` variable that strips newlines and carriage returns using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'` before writing to $OUTPUT_FILE, preventing newline injection attacks that could override other step outputs such as 'verdict'.

