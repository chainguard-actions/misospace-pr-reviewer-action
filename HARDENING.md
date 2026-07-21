<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.1.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Per the check rules, any `${{ ... }}` expression directly inside a `run:` shell command string is a script-injection finding regardless of which context it reads from. The affected steps are: 'Check whether review is needed' (`run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`), 'Wait for CI checks to complete' (`run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`), and 'Run AI review' (`run: bash "${{ github.action_path }}/scripts/run_review.sh"`). The safe alternative is to use the `$GITHUB_ACTION_PATH` environment variable instead.

Locations:

- `action.yml:504`
- `action.yml:522`
- `action.yml:567`

### github-env-injection (severity: high)

In scripts/check_review_needed.sh, the value of `EFFECTIVE_FORGEJO_API_URL` (derived directly from the `inputs.forgejo_api_url` composite action input via `EFFECTIVE_FORGEJO_API_URL="${FORGEJO_API_URL:-}"`) is written to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`). This occurs in multiple early-exit paths and the main output block. An attacker-controlled `forgejo_api_url` input containing newline characters could inject additional key=value pairs into the step outputs, potentially overwriting outputs such as `should_review` or `resolved_platform`.

Locations:

- `scripts/check_review_needed.sh:75`
- `scripts/check_review_needed.sh:276`
- `scripts/check_review_needed.sh:470`

### github-env-injection (severity: high)

In .github/workflows/manual-release.yml, the 'Normalize release metadata' step writes `tag=v$VERSION`, `major_tag=v${VERSION%%.*}`, `sha=$(git rev-parse HEAD)`, and `prerelease=$PRERELEASE` to `$GITHUB_OUTPUT`. `VERSION` is derived from `RAW_VERSION` which is set from `inputs.version` (a `workflow_dispatch` input). Although a regex validation is applied (`^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.-]+)?$`), the required sanitization step (`printf '%s' "$VERSION" | tr -d '\n\r'`) is not applied before the write. The regex does prevent newline injection in practice, but the sanitization step is required by the check rules for any write of untrusted-input-derived values to special environment files.

Locations:

- `.github/workflows/manual-release.yml:41`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three findings: (1) script-injection in action.yml: replaced `bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `bash "${{ github.action_path }}/scripts/run_review.sh"` with `bash "$GITHUB_ACTION_PATH/scripts/..."` to use the equivalent env var instead of a template expression in the shell string. (2) github-env-injection in scripts/check_review_needed.sh: sanitized `EFFECTIVE_FORGEJO_API_URL` before writing to $GITHUB_OUTPUT in all three locations (unrelated-label early exit, should_review=false early exit, and main output block) using `printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r'`. (3) github-env-injection in .github/workflows/manual-release.yml: sanitized VERSION-derived values (tag, major_tag, sha, prerelease) before writing to $GITHUB_OUTPUT using `printf '%s' "$VALUE" | tr -d '\n\r'`.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed github-env-injection in hardened/action/scripts/sections/review.sh. The six output values written to $GITHUB_OUTPUT via simple `echo` statements (analysis_engine, verdict, verdict_source, required_checks, review_route, escalation_reason) are now sanitized through `printf '%s' ... | tr -d '\n\r'` before being written. This prevents a caller supplying a newline-containing value for inputs like ai_model, ai_base_url, or ai_api_format from injecting additional key=value pairs into $GITHUB_OUTPUT and overriding downstream step outputs such as `verdict`. The review_markdown, findings, and evidence_digest outputs already used random heredoc delimiters and were not changed.

