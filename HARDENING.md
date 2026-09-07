<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.3.2** was hardened automatically. 1 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Four `run:` blocks in action.yml interpolate `${{ github.action_path }}` directly inside shell command strings. Per the script-injection check, ANY `${{ ... }}` expression directly inside a `run:` block is a finding — including `github.*` contexts — because the value flows through YAML template substitution before the shell sees it. The safe alternative is to reference the pre-set `$GITHUB_ACTION_PATH` environment variable instead. Offending lines:
1. `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (step: Check whether review is needed)
2. `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (step: Wait for CI checks to complete)
3. `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (step: Run AI review)
4. `run: bash "${{ github.action_path }}/scripts/publish.sh"` (step: Publish review)

Locations:

- `action.yml:700`
- `action.yml:720`
- `action.yml:830`
- `action.yml:890`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed all four script-injection findings in hardened/action/action.yml by replacing `${{ github.action_path }}` with `$GITHUB_ACTION_PATH` in the four `run:` lines:
1. `run: bash "$GITHUB_ACTION_PATH/scripts/check_review_needed.sh"` (step: Check whether review is needed)
2. `run: bash "$GITHUB_ACTION_PATH/scripts/wait_for_ci.sh"` (step: Wait for CI checks to complete)
3. `run: bash "$GITHUB_ACTION_PATH/scripts/run_review.sh"` (step: Run AI review)
4. `run: bash "$GITHUB_ACTION_PATH/scripts/publish.sh"` (step: Publish review)

The `$GITHUB_ACTION_PATH` environment variable is automatically set by GitHub Actions for composite actions, so no additional env block entries were needed for steps 1-3. Step 4 (Publish review) already had `GITHUB_ACTION_PATH: ${{ github.action_path }}` in its env block, which remains safe as it's in the env block rather than the run: shell string.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed 5 unsanitized GITHUB_OUTPUT writes across 2 files:

1. `scripts/check_review_needed.sh` (4 locations): All 4 occurrences of `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL"` were replaced with `printf 'effective_forgejo_api_url=%s\n' "$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"`. This covers the unrelated-label early-exit block, the should_review=false skip block, the superseded-head early-exit block, and the final output block.

2. `scripts/sections/review.sh` (1 location): The `echo "analysis_engine=$ANALYSIS_ENGINE"` write was replaced with `printf 'analysis_engine=%s\n' "$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')" >> "$OUTPUT_FILE"`. ANALYSIS_ENGINE is constructed from caller-controlled inputs (AI_MODEL, AI_BASE_URL, AI_API_FORMAT) and could carry injected newlines.

The sanitization pattern `printf '%s' "$VAR" | tr -d '\n\r'` strips all newline and carriage-return characters before writing to $GITHUB_OUTPUT, preventing a caller from injecting arbitrary key=value pairs into the step output file.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Moved four workflow_dispatch input expressions from the 'Run eval harness' step's run: block into its env: block. Specifically: `${{ inputs.corpus || 'evals/corpus-agentic.json' }}` → INPUT_CORPUS, `${{ inputs.modes || 'tools_off native_loop' }}` → INPUT_MODES, `${{ inputs.runs-per-mode || 10 }}` → INPUT_RUNS_PER_MODE, and `${{ inputs.max-prs || '' }}` → INPUT_MAX_PRS. The shell script now references these as plain environment variables (${INPUT_CORPUS}, ${INPUT_MODES}, ${INPUT_RUNS_PER_MODE}, ${INPUT_MAX_PRS}), eliminating the script injection risk.

### Iteration 4

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in .github/workflows/manual-release.yml. In the 'Normalize release metadata' step, the user-controlled VERSION variable (derived from inputs.version) was written to $GITHUB_OUTPUT without sanitization. The bash regex check using =~ does not prevent newline injection because $ matches before a trailing newline in bash ERE. Fixed by adding sanitization steps: SAFE_VERSION=$(printf '%s' "$VERSION" | tr -d '\n\r'), SAFE_MAJOR=$(printf '%s' "${VERSION%%.*}" | tr -d '\n\r'), and SAFE_SHA=$(git rev-parse HEAD | tr -d '\n\r') before writing to $GITHUB_OUTPUT. All four output values (tag, major_tag, sha, prerelease) now use the sanitized variables.

