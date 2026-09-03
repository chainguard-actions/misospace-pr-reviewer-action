<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.3.0** was hardened automatically. 2 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) violation: Four `${{ inputs.* }}` expressions are directly interpolated inside the `run:` shell script body of the "Run eval harness" step. The lines `CORPUS="${{ inputs.corpus || 'evals/corpus-agentic.json' }}"`, `MODES="${{ inputs.modes || 'tools_off native_loop' }}"`, `RUNS_PER_MODE="${{ inputs.runs-per-mode || 10 }}"`, and `MAX_PRS="${{ inputs.max-prs || '' }}"` allow any user who can trigger the `workflow_dispatch` event to inject arbitrary shell commands. The values should be moved to the `env:` block and referenced as quoted `"$VAR"` shell variables in the run body.

Locations:

- `.github/workflows/eval-harness.yaml:73`
- `.github/workflows/eval-harness.yaml:74`
- `.github/workflows/eval-harness.yaml:75`
- `.github/workflows/eval-harness.yaml:76`

### script-injection (severity: high)

Rule (a) violation: Three composite-action steps use `run: bash "${{ github.action_path }}/scripts/..."` — the `${{ github.action_path }}` expression is directly interpolated inside the `run:` command string. Per the check rules, ANY `${{ ... }}` expression (including `github.*` contexts) directly inside a `run:` shell command is a script-injection finding because the value flows through YAML template substitution before the shell processes it. The safe pattern (used correctly in the "Publish review" step) is to hoist the value into an `env:` variable (`GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference it as `"${GITHUB_ACTION_PATH}"` in the run body. Affected steps: "Check whether review is needed" (`run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`), "Wait for CI checks to complete" (`run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`), and "Run AI review" (`run: bash "${{ github.action_path }}/scripts/run_review.sh"`).

Locations:

- `action.yml:638`
- `action.yml:720`
- `action.yml:730`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed two script-injection findings:

1. `.github/workflows/eval-harness.yaml`: Moved four `${{ inputs.* }}` expressions (corpus, modes, runs-per-mode, max-prs) from the `run:` shell body into the step's `env:` block as `INPUT_CORPUS`, `INPUT_MODES`, `INPUT_RUNS_PER_MODE`, and `INPUT_MAX_PRS`. The shell body now references these as plain environment variables.

2. `action.yml`: Fixed three steps ('Check whether review is needed', 'Wait for CI checks to complete', 'Run AI review') that used `run: bash "${{ github.action_path }}/scripts/..."`. Added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to each step's `env:` block and updated the `run:` command to use `bash "${GITHUB_ACTION_PATH}/scripts/..."` instead.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed two github-env-injection findings:
1. scripts/check_review_needed.sh: Sanitized EFFECTIVE_FORGEJO_API_URL at the point of assignment (platform resolution section) using `printf '%s' "${FORGEJO_API_URL:-}" | tr -d '\n\r'`. This single fix covers all 4 output locations (the unrelated-label early exit, the should_review=false early exit, the superseded-head early exit, and the final output block).
2. scripts/sections/review.sh: Added a sanitization step before writing ANALYSIS_ENGINE to $GITHUB_OUTPUT: `safe_analysis_engine="$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"` and then writing `$safe_analysis_engine` instead of `$ANALYSIS_ENGINE`.

### Iteration 3

**Fixes applied:** github-env-injection

**Notes:**

Fixed the 'Normalize release metadata' step in .github/workflows/manual-release.yml. All four values written to $GITHUB_OUTPUT (tag, major_tag, sha, prerelease) are now sanitized with `printf '%s' ... | tr -d '\n\r'` before being written. The values are stored in safe_tag, safe_major_tag, safe_sha, and safe_prerelease variables respectively, then written to $GITHUB_OUTPUT. This prevents newline injection attacks via the workflow_dispatch `inputs.version` input.

