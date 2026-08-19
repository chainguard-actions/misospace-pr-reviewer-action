<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v1.2.9

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v1.2.9** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) violation: Multiple `${{ ... }}` expressions are directly interpolated inside `run:` shell script bodies in three composite action steps, bypassing the env: indirection safety layer. In the 'Publish review comment' step, `EFFECTIVE_SCOPE="${{ steps.precheck.outputs.effective_review_scope || 'full' }}"` and `METADATA_MARKER="$(build_metadata_marker "${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}" "${{ steps.precheck.outputs.previous_head_sha || '' }}")"` are assigned inline in the shell script body. The same pattern repeats in 'Publish review comment (non-blocking)' and 'Publish review verdict' steps, which additionally inline `IS_FORK_PR="${{ steps.precheck.outputs.is_fork_pr }}"`, `PREVIOUS_HEAD_SHA="${{ steps.precheck.outputs.previous_head_sha || '' }}"`, and `BASELINE_CLEAN="${{ steps.precheck.outputs.baseline_clean || 'false' }}"`. The `github.event.pull_request.base.sha` value comes from the PR event payload and is attacker-influenced; all `steps.*.outputs.*` values flow from earlier steps that process PR content. Any of these values containing shell metacharacters will be interpreted by the shell before assignment.

Locations:

- `action.yml:480`
- `action.yml:483`
- `action.yml:530`
- `action.yml:533`
- `action.yml:596`
- `action.yml:600`
- `action.yml:601`
- `action.yml:602`
- `action.yml:605`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed script injection in three composite action steps by moving all ${{ ... }} expressions from run: shell script bodies into the step's env: block. Changes made to hardened/action/action.yml:

1. 'Publish review comment' step: Added EFFECTIVE_REVIEW_SCOPE (${{ steps.precheck.outputs.effective_review_scope }}), BASE_SHA (${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}), and PREVIOUS_HEAD_SHA (${{ steps.precheck.outputs.previous_head_sha }}) to env:. Replaced inline ${{ }} assignments with ${EFFECTIVE_REVIEW_SCOPE:-full}, ${BASE_SHA}, and ${PREVIOUS_HEAD_SHA:-} in the run: block.

2. 'Publish review comment (non-blocking)' step: Added EFFECTIVE_REVIEW_SCOPE and BASE_SHA to env:. Replaced inline ${{ }} assignments with ${EFFECTIVE_REVIEW_SCOPE:-full} and ${BASE_SHA} in the run: block.

3. 'Publish review verdict (native PR review)' step: Added IS_FORK_PR_INPUT (${{ steps.precheck.outputs.is_fork_pr }}), EFFECTIVE_REVIEW_SCOPE (${{ steps.precheck.outputs.effective_review_scope }}), PREVIOUS_HEAD_SHA_INPUT (${{ steps.precheck.outputs.previous_head_sha }}), BASELINE_CLEAN_INPUT (${{ steps.precheck.outputs.baseline_clean }}), and BASE_SHA (${{ github.event.pull_request.base.sha || steps.precheck.outputs.base_sha }}) to env:. Replaced all inline ${{ }} assignments with plain env var references in the run: block.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml by replacing `bash "${{ github.action_path }}/scripts/..."` with `bash "$GITHUB_ACTION_PATH/scripts/..."` in all three affected run: blocks (check_review_needed.sh, wait_for_ci.sh, run_review.sh). GITHUB_ACTION_PATH is a built-in GitHub Actions runner environment variable automatically available in all composite action steps, so no env: block changes were needed. Fixed github-env-injection in scripts/run_review.sh by sanitizing ANALYSIS_ENGINE before writing to $OUTPUT_FILE: added `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` and changed the echo to use `$safe_analysis_engine` instead of `$ANALYSIS_ENGINE` directly.

