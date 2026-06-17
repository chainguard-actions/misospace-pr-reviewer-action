<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v1.2.9

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v1.2.9** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple `${{ }}` expressions are interpolated directly inside `run:` shell command strings in action.yml, violating sub-rule (a). This allows template substitution to inject arbitrary shell content before the shell parses the command.

1. Step 'Check whether review is needed': `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` — `${{ github.action_path }}` is interpolated directly into the shell command string.

2. Step 'Wait for CI checks to complete': `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` — same issue.

3. Step 'Run AI review': `run: bash "${{ github.action_path }}/scripts/run_review.sh"` — same issue.

4. Step 'Publish review comment' (shell script body): `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"` and `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "${{ steps.precheck.outputs.previous_head_sha || '' }}")"` — steps.* and github.* expressions interpolated directly in the multi-line shell script body.

5. Step 'Publish review comment (non-blocking)' (shell script body): same EFFECTIVE_SCOPE and METADATA_MARKER patterns with ${{ steps.* }} and ${{ github.* }} expressions directly in the shell script body.

6. Step 'Publish review verdict' (shell script body): `IS_FORK_PR="${{ steps.precheck.outputs.is_fork_pr }}"`, `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"`, `PREVIOUS_HEAD_SHA="${{ steps.precheck.outputs.previous_head_sha || '' }}"`, `BASELINE_CLEAN="${{ steps.precheck.outputs.baseline_clean || 'false' }}"`, and `METADATA_MARKER` with `${{ github.event.pull_request.base.sha }}` — all directly interpolated in the shell script body.

All of these should be moved to env: blocks and referenced as shell variables.

Locations:

- `action.yml:486`
- `action.yml:502`
- `action.yml:612`
- `action.yml:640`
- `action.yml:645`
- `action.yml:700`
- `action.yml:705`
- `action.yml:805`
- `action.yml:811`
- `action.yml:813`
- `action.yml:815`
- `action.yml:820`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all 6 script injection locations in action.yml:

1. 'Check whether review is needed' step: Added GITHUB_ACTION_PATH to env block, changed run command from `bash "${{ github.action_path }}/scripts/check_review_needed.sh"` to `bash "$GITHUB_ACTION_PATH/scripts/check_review_needed.sh"`.

2. 'Wait for CI checks to complete' step: Same fix for github.action_path.

3. 'Run AI review' step: Same fix for github.action_path.

4. 'Publish review comment' step: Added EFFECTIVE_REVIEW_SCOPE, BASE_SHA, PREVIOUS_HEAD_SHA to env block; replaced ${{ steps.precheck.outputs.effective_review_scope || 'full' }}, ${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}, and ${{ steps.precheck.outputs.previous_head_sha || '' }} in shell body with ${EFFECTIVE_REVIEW_SCOPE:-full}, ${BASE_SHA}, and ${PREVIOUS_HEAD_SHA:-}.

5. 'Publish review comment (non-blocking)' step: Added EFFECTIVE_REVIEW_SCOPE and BASE_SHA to env block; replaced same patterns.

6. 'Publish review verdict' step: Added IS_FORK_PR_INPUT, EFFECTIVE_REVIEW_SCOPE, PREVIOUS_HEAD_SHA_INPUT, BASELINE_CLEAN_INPUT, and BASE_SHA to env block; replaced all ${{ steps.precheck.outputs.* }} and ${{ github.event.pull_request.base.sha }} expressions in shell body with plain env variable references (IS_FORK_PR_INPUT, EFFECTIVE_REVIEW_SCOPE:-full, PREVIOUS_HEAD_SHA_INPUT:-,  BASELINE_CLEAN_INPUT:-false, BASE_SHA).

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in scripts/run_review.sh: The ANALYSIS_ENGINE variable (constructed from user-controlled inputs AI_MODEL, AI_BASE_URL, AI_API_FORMAT) was being written directly to $GITHUB_OUTPUT without sanitization. Added a sanitization step using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'` to strip newline characters before writing to $OUTPUT_FILE, preventing injection of arbitrary key=value pairs into GITHUB_OUTPUT.

