<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.3.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): ${{ inputs.* }} expressions are directly interpolated inside a run: shell command string in the 'Run eval harness' step. The workflow_dispatch inputs `corpus`, `modes`, `runs-per-mode`, and `max-prs` are user-controlled and are assigned directly as shell variable values via YAML template substitution before the shell sees them. An attacker who can trigger the workflow can inject arbitrary shell commands. Example offending lines:
  CORPUS="${{ inputs.corpus || 'evals/corpus-agentic.json' }}"
  MODES="${{ inputs.modes || 'tools_off native_loop' }}"
  RUNS_PER_MODE="${{ inputs.runs-per-mode || 10 }}"
  MAX_PRS="${{ inputs.max-prs || '' }}"
Fix: move each input into an env: block and reference the env var inside the run: script.

Locations:

- `.github/workflows/eval-harness.yaml:68`
- `.github/workflows/eval-harness.yaml:69`
- `.github/workflows/eval-harness.yaml:70`
- `.github/workflows/eval-harness.yaml:71`

### script-injection (severity: high)

Sub-rule (a): ${{ github.action_path }} (a github.* context expression) is directly interpolated inside run: shell command strings in four composite-action steps. Although github.action_path is GitHub-controlled and not attacker-supplied, any ${{ ... }} expression in a run: block flows through YAML template substitution before the shell processes it, making it a script-injection pattern per the check rules. Offending lines:
  run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"
  run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"
  run: bash "${{ github.action_path }}/scripts/run_review.sh"
  run: bash "${{ github.action_path }}/scripts/publish.sh"
Fix: use the $GITHUB_ACTION_PATH environment variable instead (already available in composite action steps).

Locations:

- `action.yml:556`
- `action.yml:590`
- `action.yml:680`
- `action.yml:720`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed two script-injection findings:
1. `.github/workflows/eval-harness.yaml`: Moved `${{ inputs.corpus }}`, `${{ inputs.modes }}`, `${{ inputs.runs-per-mode }}`, and `${{ inputs.max-prs }}` expressions from the `run:` shell body into the step's `env:` block (as INPUT_CORPUS, INPUT_MODES, INPUT_RUNS_PER_MODE, INPUT_MAX_PRS). The run script now references these as plain environment variables.
2. `action.yml`: Replaced all four `run: bash "${{ github.action_path }}/scripts/..."` lines with `run: bash "$GITHUB_ACTION_PATH/scripts/..."`, using the automatically-available environment variable instead of a YAML template expression in the shell command string.

