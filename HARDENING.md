<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v1.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v1.3.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Multiple ${{ }} expressions are interpolated directly inside run: shell command strings in action.yml, violating rule (a). This applies to all contexts including steps.*, github.*, and runner.* — any ${{ ... }} inside a run: block is a script-injection risk because the value is substituted by the YAML template engine before the shell ever sees it.

Affected occurrences:
1. Step 'Check whether review is needed': `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` — ${{ github.action_path }} interpolated directly in the shell command.
2. Step 'Wait for CI checks to complete': `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` — same pattern.
3. Step 'Run AI review': `run: bash "${{ github.action_path }}/scripts/run_review.sh"` — same pattern.
4. Step 'Publish review comment' run: body: `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"` and `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "${{ steps.precheck.outputs.previous_head_sha || '' }}")"` — ${{ }} expressions assigned to shell variables inside the script body.
5. Step 'Publish review comment (non-blocking)' run: body: same EFFECTIVE_SCOPE and METADATA_MARKER patterns with ${{ }} expressions.
6. Step 'Publish review verdict (native PR review)' run: body: IS_FORK_PR, EFFECTIVE_SCOPE, PREVIOUS_HEAD_SHA, BASELINE_CLEAN, and METADATA_MARKER all use ${{ }} expressions directly in the shell script body.

All of these should be moved to the step's env: block and referenced as double-quoted $ENV_VAR in the shell script.

Locations:

- `action.yml:718`
- `action.yml:738`
- `action.yml:880`
- `action.yml:917`
- `action.yml:922`
- `action.yml:992`
- `action.yml:997`
- `action.yml:1123`
- `action.yml:1130`
- `action.yml:1132`
- `action.yml:1134`
- `action.yml:1140`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all 6 script injection occurrences in action.yml:

1. 'Check whether review is needed' step: Added GITHUB_ACTION_PATH to env block, changed `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` to `run: bash "${GITHUB_ACTION_PATH}/scripts/check_review_needed.sh"`.

2. 'Wait for CI checks to complete' step: Added GITHUB_ACTION_PATH to env block, changed `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` to `run: bash "${GITHUB_ACTION_PATH}/scripts/wait_for_ci.sh"`.

3. 'Run AI review' step: Added GITHUB_ACTION_PATH to env block, changed `run: bash "${{ github.action_path }}/scripts/run_review.sh"` to `run: bash "${GITHUB_ACTION_PATH}/scripts/run_review.sh"`.

4. 'Publish review comment' step: Added EFFECTIVE_REVIEW_SCOPE, BASE_SHA, and PREVIOUS_HEAD_SHA_RAW to env block. Replaced inline `${{ steps.precheck.outputs.effective_review_scope || 'full' }}`, `${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}`, and `${{ steps.precheck.outputs.previous_head_sha || '' }}` with env var references.

5. 'Publish review comment (non-blocking)' step: Added EFFECTIVE_REVIEW_SCOPE and BASE_SHA to env block. Replaced inline `${{ }}` expressions with env var references.

6. 'Publish review verdict (native PR review)' step: Added IS_FORK_PR_RAW, EFFECTIVE_REVIEW_SCOPE, PREVIOUS_HEAD_SHA_RAW, BASELINE_CLEAN_RAW, and BASE_SHA to env block. Replaced all inline `${{ }}` expressions (IS_FORK_PR, EFFECTIVE_SCOPE, PREVIOUS_HEAD_SHA, BASELINE_CLEAN, METADATA_MARKER) with env var references.

