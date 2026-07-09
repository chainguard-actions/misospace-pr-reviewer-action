<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.1.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three run: blocks in action.yml directly interpolate ${{ github.action_path }} inside the shell command string. Any ${{ ... }} expression in a run: block is a script-injection finding regardless of which context it reads from. The affected lines are: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `run: bash "${{ github.action_path }}/scripts/run_review.sh"`. The fix is to hoist github.action_path into an env: variable (e.g. ACTION_PATH: ${{ github.action_path }}) and reference $ACTION_PATH in the run: block.

Locations:

- `action.yml:450`
- `action.yml:470`
- `action.yml:560`

### github-env-injection (severity: high)

scripts/check_review_needed.sh writes the value of EFFECTIVE_FORGEJO_API_URL (sourced from inputs.forgejo_api_url via the FORGEJO_API_URL env var) directly to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). An attacker-controlled value containing newlines could inject additional key=value pairs into the step outputs, potentially overriding outputs such as 'should_review' or 'resolved_platform'. The write appears in three places (early-exit paths and the main output block): `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"`.

Locations:

- `scripts/check_review_needed.sh:85`
- `scripts/check_review_needed.sh:330`
- `scripts/check_review_needed.sh:560`

### github-env-injection (severity: high)

scripts/sections/review.sh writes ANALYSIS_ENGINE to $GITHUB_OUTPUT without sanitization. ANALYSIS_ENGINE is constructed from user-controlled inputs including AI_MODEL (inputs.ai_model), AI_BASE_URL (inputs.ai_base_url), and AI_API_FORMAT (inputs.ai_api_format) in the form "$AI_MODEL@$AI_BASE_URL ($AI_API_FORMAT)". If any of these inputs contain newline characters, additional key=value pairs could be injected into the step outputs. The write is: `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"`.

Locations:

- `scripts/sections/review.sh:320`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed 3 script-injection findings in action.yml: hoisted `github.action_path` into an `ACTION_PATH` env variable for the check_review_needed.sh, wait_for_ci.sh, and run_review.sh run: blocks. Fixed 2 github-env-injection findings: (1) in scripts/check_review_needed.sh, sanitized EFFECTIVE_FORGEJO_API_URL with `printf '%s' ... | tr -d '\n\r'` immediately after assignment so all three $GITHUB_OUTPUT write locations use the sanitized value; (2) in scripts/sections/review.sh, sanitized ANALYSIS_ENGINE into safe_analysis_engine before writing to $OUTPUT_FILE.

