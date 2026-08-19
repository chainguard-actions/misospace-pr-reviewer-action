<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v1.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v1.3.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple `${{ }}` expressions are interpolated directly inside `run:` shell command strings in action.yml, violating the rule that no `${{ ... }}` expression should appear anywhere inside a `run:` shell command string.

1. Three steps use `run: bash "${{ github.action_path }}/scripts/<script>.sh"` — the `github.action_path` expression is substituted directly into the shell command before the shell parses it.

2. In the 'Publish review comment' step's multi-line run block:
   - `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"`
   - `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "${{ steps.precheck.outputs.previous_head_sha || '' }}")"`

3. In the 'Publish review comment (non-blocking)' step's multi-line run block:
   - `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"`
   - `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "")"`

4. In the 'Publish review verdict (native PR review)' step's multi-line run block:
   - `IS_FORK_PR="${{ steps.precheck.outputs.is_fork_pr }}"`
   - `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"`
   - `PREVIOUS_HEAD_SHA="${{ steps.precheck.outputs.previous_head_sha || '' }}"`
   - `BASELINE_CLEAN="${{ steps.precheck.outputs.baseline_clean || 'false' }}"`
   - `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "$PREVIOUS_HEAD_SHA")"`

All of these should be moved to `env:` blocks and referenced as `$ENV_VAR` (double-quoted) in the shell script body.

Locations:

- `action.yml:500`
- `action.yml:516`
- `action.yml:622`
- `action.yml:621`
- `action.yml:625`
- `action.yml:680`
- `action.yml:684`
- `action.yml:800`
- `action.yml:806`
- `action.yml:807`
- `action.yml:808`
- `action.yml:812`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all script injection issues in hardened/action/action.yml:

1. Three `run: bash "${{ github.action_path }}/scripts/..."` lines (check_review_needed.sh, wait_for_ci.sh, run_review.sh): Added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to each step's env block and replaced the inline expression with `$GITHUB_ACTION_PATH` in the run line.

2. 'Publish review comment' step: Added `EFFECTIVE_REVIEW_SCOPE`, `BASE_SHA`, and `PREVIOUS_HEAD_SHA_INPUT` env vars; replaced inline `${{ steps.precheck.outputs.effective_review_scope || 'full' }}`, `${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}`, and `${{ steps.precheck.outputs.previous_head_sha || '' }}` with env var references.

3. 'Publish review comment (non-blocking)' step: Added `EFFECTIVE_REVIEW_SCOPE` and `BASE_SHA` env vars; replaced inline expressions with env var references.

4. 'Publish review verdict (native PR review)' step: Added `IS_FORK_PR_INPUT`, `EFFECTIVE_REVIEW_SCOPE`, `PREVIOUS_HEAD_SHA_INPUT`, `BASELINE_CLEAN_INPUT`, and `BASE_SHA` env vars; replaced all five inline `${{ }}` expressions in the run block with env var references.

