<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.0.0** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression directly inside a `run:` block is a script-injection finding regardless of which context it reads from. The offending lines are:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` ("Check whether review is needed" step)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` ("Wait for CI checks to complete" step)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` ("Run AI review" step)
The safe pattern is to hoist `github.action_path` into an `env:` variable (e.g. `GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference it as `"${GITHUB_ACTION_PATH}/scripts/..."` in the shell body — which the "Publish review" step already does correctly.

Locations:

- `action.yml:570`
- `action.yml:580`
- `action.yml:650`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all three script-injection findings in action.yml by moving `${{ github.action_path }}` out of `run:` shell strings and into the step's `env:` block as `GITHUB_ACTION_PATH: ${{ github.action_path }}`. Updated the three `run:` lines to use `bash "${GITHUB_ACTION_PATH}/scripts/...sh"` instead of `bash "${{ github.action_path }}/scripts/...sh"`. The affected steps were: 'Check whether review is needed' (check_review_needed.sh), 'Wait for CI checks to complete' (wait_for_ci.sh), and 'Run AI review' (run_review.sh). This matches the safe pattern already used by the 'Publish review' step.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In scripts/sections/review.sh, sanitized the ANALYSIS_ENGINE variable before writing it to $GITHUB_OUTPUT (via $OUTPUT_FILE). Added `_safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` and replaced the direct `echo "analysis_engine=$ANALYSIS_ENGINE"` write with `echo "analysis_engine=$_safe_analysis_engine"`. This prevents newline injection from workflow-controlled inputs (ai_model, ai_base_url, ai_api_format) from injecting arbitrary key=value pairs into GITHUB_OUTPUT.

