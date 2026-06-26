<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.0.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.0.2** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` — a `github.*` context expression — into shell command strings. Per the check rules, ANY `${{ ... }}` expression inside a `run:` block is a script-injection finding because the value flows through YAML template substitution before the shell processes it. The offending lines are:
1. `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (step: 'Check whether review is needed')
2. `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (step: 'Wait for CI checks to complete')
3. `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (step: 'Run AI review')
The safe pattern (already used in the 'Publish review' step) is to hoist `github.action_path` into an `env:` variable (e.g. `GITHUB_ACTION_PATH`) and reference it as `"${GITHUB_ACTION_PATH}/scripts/..."` in the `run:` block.

Locations:

- `action.yml:399`
- `action.yml:404`
- `action.yml:490`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed three script-injection findings in action.yml by hoisting `github.action_path` out of `run:` shell strings and into `env:` blocks. For each of the three steps ('Check whether review is needed', 'Wait for CI checks to complete', 'Run AI review'), added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to the step's `env:` block and replaced `bash "${{ github.action_path }}/scripts/....sh"` with `bash "${GITHUB_ACTION_PATH}/scripts/....sh"`. This matches the safe pattern already used in the 'Publish review' step.

