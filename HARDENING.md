<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v1.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v1.3.0** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Multiple `${{ }}` expressions are directly interpolated inside `run:` shell script bodies in action.yml, bypassing shell quoting and enabling script injection.

**Step: 'Check whether review is needed'** — `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` — the `${{ github.action_path }}` expression is interpolated directly into the shell command string.

**Step: 'Wait for CI checks to complete'** — `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` — same pattern.

**Step: 'Run AI review'** — `run: bash "${{ github.action_path }}/scripts/run_review.sh"` — same pattern.

**Step: 'Publish review comment'** — Inside the `run: |` block: `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"` and `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "${{ steps.precheck.outputs.previous_head_sha || '' }}")"` — step outputs and github context values are interpolated directly into shell commands.

**Step: 'Publish review comment (non-blocking)'** — Same `EFFECTIVE_SCOPE` and `METADATA_MARKER` patterns with `${{ steps.precheck.outputs.* }}` and `${{ github.event.pull_request.base.sha }}` directly in the shell script body.

**Step: 'Publish review verdict (native PR review)'** — Inside the `run: |` block: `IS_FORK_PR="${{ steps.precheck.outputs.is_fork_pr }}"`, `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"`, `PREVIOUS_HEAD_SHA="${{ steps.precheck.outputs.previous_head_sha || '' }}"`, `BASELINE_CLEAN="${{ steps.precheck.outputs.baseline_clean || 'false' }}"`, and `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "$PREVIOUS_HEAD_SHA")"` — all directly interpolated in shell.

All `${{ ... }}` expressions inside `run:` blocks are template-substituted before the shell ever sees the string, allowing an attacker who controls the substituted value to inject arbitrary shell commands. The safe pattern is to pass values through `env:` variables and reference them as `$VAR` (already done for most inputs, but not for these inline uses).

Locations:

- `action.yml:790`
- `action.yml:812`
- `action.yml:960`
- `action.yml:1002`
- `action.yml:1008`
- `action.yml:1087`
- `action.yml:1093`
- `action.yml:1233`
- `action.yml:1241`
- `action.yml:1243`
- `action.yml:1245`
- `action.yml:1252`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all script injection issues in action.yml:

1. **'Check whether review is needed' step**: Added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to env block and changed `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` to `run: bash "${GITHUB_ACTION_PATH}/scripts/check_review_needed.sh"`.

2. **'Wait for CI checks to complete' step**: Same fix - added `GITHUB_ACTION_PATH` to env and used `${GITHUB_ACTION_PATH}` in run command.

3. **'Run AI review' step**: Added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to env block and changed `run: bash "${{ github.action_path }}/scripts/run_review.sh"` to use `${GITHUB_ACTION_PATH}`.

4. **'Publish review comment' step**: Added `EFFECTIVE_REVIEW_SCOPE`, `BASE_SHA`, and `PREVIOUS_HEAD_SHA` to env block. Replaced inline `${{ steps.precheck.outputs.effective_review_scope || 'full' }}`, `${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}`, and `${{ steps.precheck.outputs.previous_head_sha || '' }}` with `${EFFECTIVE_REVIEW_SCOPE:-full}`, `${BASE_SHA:-}`, and `${PREVIOUS_HEAD_SHA:-}` respectively.

5. **'Publish review comment (non-blocking)' step**: Same pattern - added `EFFECTIVE_REVIEW_SCOPE` and `BASE_SHA` to env block and replaced inline expressions.

6. **'Publish review verdict (native PR review)' step**: Added `IS_FORK_PR_INPUT`, `EFFECTIVE_REVIEW_SCOPE`, `PREVIOUS_HEAD_SHA_INPUT`, `BASELINE_CLEAN_INPUT`, and `BASE_SHA` to env block. Replaced all five inline `${{ }}` expressions with env var references using safe default fallbacks.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection vulnerability in scripts/run_review.sh. The ANALYSIS_ENGINE variable is constructed from user-controlled inputs (AI_MODEL, AI_BASE_URL, AI_API_FORMAT) and was previously written directly to $GITHUB_OUTPUT without newline sanitization. The fix adds a sanitization step: `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` before the write, so the output line becomes `echo "analysis_engine=$safe_analysis_engine" >> "$OUTPUT_FILE"`. This prevents a malicious caller from injecting newlines to add arbitrary key=value pairs to GITHUB_OUTPUT (e.g., flipping the `verdict` output).

