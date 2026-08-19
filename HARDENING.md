<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.0.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.0.2** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml interpolate `${{ github.action_path }}` directly inside the shell command string. Although `github.action_path` is GitHub-controlled, the expression still flows through YAML template substitution before the shell sees it, making it a script-injection risk per the check rules. The safe pattern is to hoist the value into an `env:` variable (e.g. `GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference `"${GITHUB_ACTION_PATH}/scripts/..."` in the run body. Offending lines: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `run: bash "${{ github.action_path }}/scripts/run_review.sh"`.

Locations:

- `action.yml:560`
- `action.yml:580`
- `action.yml:680`

### github-env-injection (severity: high)

In the 'Normalize release metadata' step, the `workflow_dispatch` input `inputs.version` is mapped to the env var `RAW_VERSION`, then processed into `VERSION`, and written directly to `$GITHUB_OUTPUT` via `echo "tag=v$VERSION" >> "$GITHUB_OUTPUT"` and `echo "major_tag=v${VERSION%%.*}" >> "$GITHUB_OUTPUT"` without the prescribed sanitization step (`printf '%s' "$VERSION" | tr -d '\n\r'`). A regex validation is performed before the write, but the rules require the `printf | tr -d` sanitization pipeline immediately before every write of a value derived from an untrusted input source. The `inputs.version` field is a `workflow_dispatch` input and is attacker-controllable.

Locations:

- `.github/workflows/manual-release.yml:43`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

1. script-injection (action.yml, lines ~560/580/680): For each of the three run: steps that called bash with ${{ github.action_path }} interpolated directly in the shell string, added `GITHUB_ACTION_PATH: ${{ github.action_path }}` to the step's env: block and changed the run: command to reference `${GITHUB_ACTION_PATH}` (the env variable) instead. This prevents the expression from flowing through YAML template substitution into the shell command string.

2. github-env-injection (.github/workflows/manual-release.yml, line ~43): In the 'Normalize release metadata' step, added a sanitization step using `SAFE_VERSION="$(printf '%s' "$VERSION" | tr -d '\n\r')"` immediately before writing to $GITHUB_OUTPUT, and replaced `$VERSION` / `${VERSION%%.*}` with `${SAFE_VERSION}` / `${SAFE_VERSION%%.*}` in the echo statements. This ensures the attacker-controllable inputs.version value cannot inject newlines into GITHUB_OUTPUT.

