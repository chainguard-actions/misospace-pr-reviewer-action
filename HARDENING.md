<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.5.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.5.0** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) violation: Four `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Per the script-injection check, ANY `${{ ... }}` expression directly inside a `run:` block is a finding regardless of which context it reads from. The fix is to hoist the value into an `env:` variable (e.g. `ACTION_PATH: ${{ github.action_path }}`) and reference it as `"$ACTION_PATH"` in the shell script.

Offending lines:
1. `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (step: Check whether review is needed)
2. `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (step: Wait for CI checks to complete)
3. `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (step: Run AI review)
4. `run: bash "${{ github.action_path }}/scripts/publish.sh"` (step: Publish review)

Locations:

- `action.yml:1`
- `action.yml:1`
- `action.yml:1`
- `action.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all four script-injection findings in action.yml. Each `run:` step that directly interpolated `${{ github.action_path }}` inside the shell command string was corrected by hoisting the value into the step's `env:` block and referencing it as a plain shell variable. Steps 1-3 had `ACTION_PATH: ${{ github.action_path }}` added to their `env:` blocks; step 4 (Publish review) already had `GITHUB_ACTION_PATH: ${{ github.action_path }}` in its `env:` block and only needed the `run:` line updated to use `$GITHUB_ACTION_PATH`.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed 5 github-env-injection vulnerabilities:
1. scripts/sections/review.sh: Added `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` before writing `analysis_engine=$safe_analysis_engine` to GITHUB_OUTPUT, preventing newline injection via user-controlled AI_MODEL/AI_BASE_URL inputs.
2. scripts/check_review_needed.sh (4 locations): Replaced all bare `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL"` writes with inline sanitization `echo "effective_forgejo_api_url=$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"` in the unrelated-label exit block, the precheck call #1 skip block, the superseded-head skip block, and the final output block.

