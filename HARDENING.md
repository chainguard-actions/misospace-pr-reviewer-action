<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.9

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.9** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression in a `run:` block flows through YAML template substitution before the shell sees it, making it a script-injection risk. The safe pattern is to expose the value via an `env:` variable and reference it as `$GITHUB_ACTION_PATH` in the shell body. Affected steps: 'Check whether review is needed' (`run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`), 'Wait for CI checks to complete' (`run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`), and 'Run AI review' (`run: bash "${{ github.action_path }}/scripts/run_review.sh"`).

Locations:

- `action.yml:480`
- `action.yml:510`
- `action.yml:600`

### github-env-injection (severity: high)

The 'Normalize release metadata' step in manual-release.yml writes values derived from `inputs.version` (a `workflow_dispatch` input, which is attacker-controllable) to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). The values `tag=v$VERSION`, `major_tag=v${VERSION%%.*}`, and `prerelease=$PRERELEASE` are written via plain `echo` to `$GITHUB_OUTPUT`. Although a regex validation (`^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$`) is applied before the write, the check requires the specific `tr -d '\n\r'` sanitization pattern to be applied immediately before each write.

Locations:

- `.github/workflows/manual-release.yml:55`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed script-injection in action.yml: moved `${{ github.action_path }}` out of the `run:` shell string and into the `env:` block as `ACTION_PATH: ${{ github.action_path }}` for all three affected steps ('Check whether review is needed', 'Wait for CI checks to complete', 'Run AI review'). The `run:` commands now reference `$ACTION_PATH` as a plain shell variable. Fixed github-env-injection in .github/workflows/manual-release.yml: the 'Normalize release metadata' step now sanitizes all four values (tag, major_tag, sha, prerelease) with `printf '%s' "$VAR" | tr -d '\n\r'` before writing them to $GITHUB_OUTPUT, preventing newline injection attacks via the attacker-controllable `inputs.version` workflow_dispatch input.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed 5 github-env-injection vulnerabilities:

1. hardened/action/scripts/check_review_needed.sh (4 locations):
   - Line ~100 (unrelated-label early exit): replaced `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL"` with `printf 'effective_forgejo_api_url=%s\n' "$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')"`
   - Line ~370 (should_review=false early exit): same fix
   - Line ~600 (superseded-head early exit): same fix
   - Line ~640 (main exit): same fix, with `>> "$OUTPUT_FILE"` appended directly

2. hardened/action/scripts/sections/review.sh (1 location):
   - Line ~340: replaced `echo "analysis_engine=$ANALYSIS_ENGINE"` with `printf 'analysis_engine=%s\n' "$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')"`

All caller-controlled values (EFFECTIVE_FORGEJO_API_URL derived from inputs.forgejo_api_url, and ANALYSIS_ENGINE composed from inputs.ai_model/ai_base_url/ai_api_format) are now sanitized with `tr -d '\n\r'` before being written to $GITHUB_OUTPUT, preventing newline injection attacks.

