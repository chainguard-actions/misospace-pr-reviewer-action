<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.2.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.2.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) violation: workflow_dispatch inputs are directly interpolated inside a run: shell command string without routing through an env: block. The lines `CORPUS="${{ inputs.corpus || 'evals/corpus-agentic.json' }}"`, `MODES="${{ inputs.modes || 'tools_off native_loop' }}"`, `RUNS_PER_MODE="${{ inputs.runs-per-mode || 10 }}"`, and `MAX_PRS="${{ inputs.max-prs || '' }}"` appear inside the run: block of the 'Run eval harness' step. An attacker who can trigger workflow_dispatch can inject arbitrary shell commands through these inputs.

Locations:

- `.github/workflows/eval-harness.yaml:57`

### github-env-injection (severity: high)

The ANALYSIS_ENGINE variable is derived from composite action inputs inputs.ai_model, inputs.ai_base_url, and inputs.ai_api_format (all user-controlled) and written directly to $GITHUB_OUTPUT with `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A calling workflow can supply a newline-containing model name or base URL to inject arbitrary key=value pairs into GITHUB_OUTPUT, potentially overwriting subsequent step outputs such as the verdict.

Locations:

- `scripts/sections/review.sh:297`

### github-env-injection (severity: high)

The EFFECTIVE_FORGEJO_API_URL variable is set directly from the composite action input inputs.forgejo_api_url (via the FORGEJO_API_URL env var) and written to $GITHUB_OUTPUT in multiple places with `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A calling workflow can supply a newline-containing forgejo_api_url value to inject arbitrary key=value pairs into GITHUB_OUTPUT.

Locations:

- `scripts/check_review_needed.sh:75`
- `scripts/check_review_needed.sh:138`
- `scripts/check_review_needed.sh:253`
- `scripts/check_review_needed.sh:330`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three security findings: (1) script-injection in .github/workflows/eval-harness.yaml: moved all four workflow_dispatch inputs (corpus, modes, runs-per-mode, max-prs) from direct ${{ }} interpolation inside the run: block into the step's env: block as INPUT_CORPUS, INPUT_MODES, INPUT_RUNS_PER_MODE, INPUT_MAX_PRS; the run: block now references them as plain environment variables. (2) github-env-injection in scripts/sections/review.sh: sanitized ANALYSIS_ENGINE before writing to $OUTPUT_FILE using `printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r'` stored in safe_analysis_engine. (3) github-env-injection in scripts/check_review_needed.sh: sanitized EFFECTIVE_FORGEJO_API_URL once right after it's set (covering all 4 write locations) using `printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`.

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml: hoisted `github.action_path` into `ACTION_PATH` env var for all three affected steps ('Check whether review is needed', 'Wait for CI checks to complete', 'Run AI review') and replaced inline `${{ github.action_path }}` in run: strings with `$ACTION_PATH`. Fixed github-env-injection in .github/workflows/manual-release.yml: added `SAFE_VERSION="$(printf '%s' "$VERSION" | tr -d '\n\r')"` sanitization step before writing tag and major_tag to $GITHUB_OUTPUT, preventing newline injection attacks from workflow_dispatch version input.

