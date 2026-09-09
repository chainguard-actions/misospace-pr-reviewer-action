<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.3.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.3.3** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Four `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string (e.g., `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`). Per the check definition, ANY `${{ ... }}` expression — including `github.*` context values — interpolated directly in a `run:` block is a script-injection finding because the value flows through YAML template substitution before the shell sees it. The safe pattern is to use the pre-set environment variable `$GITHUB_ACTION_PATH` instead.

Locations:

- `action.yml:570`
- `action.yml:590`
- `action.yml:700`
- `action.yml:840`

### github-env-injection (severity: high)

In `scripts/check_review_needed.sh`, the variable `EFFECTIVE_FORGEJO_API_URL` (derived from `inputs.forgejo_api_url`, a caller-controlled input) is written to `$GITHUB_OUTPUT` in four places via `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` without the required newline-stripping sanitization (`printf '%s' "$VAR" | tr -d '\n\r'`). A newline embedded in `inputs.forgejo_api_url` would allow injection of arbitrary key=value pairs into GITHUB_OUTPUT, potentially overwriting step outputs such as `should_review` or `verdict`.

Locations:

- `scripts/check_review_needed.sh:72`
- `scripts/check_review_needed.sh:213`
- `scripts/check_review_needed.sh:258`
- `scripts/check_review_needed.sh:360`

### github-env-injection (severity: high)

In `scripts/sections/review.sh`, the variable `ANALYSIS_ENGINE` is written to `$GITHUB_OUTPUT` via `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` without sanitization. `ANALYSIS_ENGINE` is constructed from `$AI_MODEL@$AI_BASE_URL ($AI_API_FORMAT)` where `AI_MODEL` and `AI_BASE_URL` are env vars set from `inputs.ai_model` and `inputs.ai_base_url` (caller-controlled inputs). A newline in either input would allow injection of arbitrary key=value pairs into GITHUB_OUTPUT.

Locations:

- `scripts/sections/review.sh:280`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed 3 findings across 3 files:

1. action.yml (script-injection, 4 locations): Replaced `run: bash "${{ github.action_path }}/scripts/....sh"` with `run: bash "$GITHUB_ACTION_PATH/scripts/....sh"` for all four run: steps (check_review_needed.sh, wait_for_ci.sh, run_review.sh, publish.sh). The publish step already had GITHUB_ACTION_PATH in its env: block; the other steps rely on the built-in GITHUB_ACTION_PATH env var provided by GitHub Actions.

2. scripts/check_review_needed.sh (github-env-injection, 4 locations): Replaced all four `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL"` writes with `printf 'effective_forgejo_api_url=%s\n' "$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"` to strip newlines before writing to GITHUB_OUTPUT.

3. scripts/sections/review.sh (github-env-injection, 1 location): Replaced `echo "analysis_engine=$ANALYSIS_ENGINE"` with `printf 'analysis_engine=%s\n' "$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` to strip newlines before writing to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Moved four ${{ inputs.* }} expressions from the 'Run eval harness' step's run: shell script body into the step's env: block as INPUT_CORPUS, INPUT_MODES, INPUT_RUNS_PER_MODE, and INPUT_MAX_PRS. The shell script now uses shell parameter expansion with defaults (e.g., ${INPUT_CORPUS:-evals/corpus-agentic.json}) instead of template substitution, preventing actors with workflow_dispatch access from injecting arbitrary shell commands through these inputs.

