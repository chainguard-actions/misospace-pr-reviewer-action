<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.1.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml directly interpolate `${{ github.action_path }}` inside the shell command string. Any `${{ ... }}` expression in a `run:` block is a script-injection finding regardless of which context it reads from. The affected steps are:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (Check whether review is needed step)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (Wait for CI checks to complete step)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (Run AI review step)
These should use the `$GITHUB_ACTION_PATH` environment variable (already available on the runner) instead of the `${{ github.action_path }}` expression.

Locations:

- `action.yml`

### github-env-injection (severity: high)

In scripts/check_review_needed.sh, the value of `EFFECTIVE_FORGEJO_API_URL` (derived from `inputs.forgejo_api_url`, a workflow-controlled input passed via the `FORGEJO_API_URL` env var) is written to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). The unsanitized write is: `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"`. An attacker-controlled value containing embedded newlines could inject arbitrary key=value pairs into the step output, potentially overriding outputs such as `should_review` or `resolved_platform`.

Locations:

- `scripts/check_review_needed.sh`

### github-env-injection (severity: high)

In scripts/sections/review.sh, the value of `ANALYSIS_ENGINE` is written to `$GITHUB_OUTPUT` without the required sanitization step. `ANALYSIS_ENGINE` is built as `"$AI_MODEL@$AI_BASE_URL ($AI_API_FORMAT)"` where `AI_MODEL` and `AI_BASE_URL` come from `inputs.ai_model` and `inputs.ai_base_url` (workflow-controlled inputs). The unsanitized write is: `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"`. A calling workflow that supplies a model name or base URL containing newlines could inject arbitrary key=value pairs into the step output.

Locations:

- `scripts/sections/review.sh`

### github-env-injection (severity: high)

In .github/workflows/manual-release.yml, the `Normalize release metadata` step writes `inputs.version` (via `RAW_VERSION` -> `VERSION`) to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). The unsanitized writes are: `echo "tag=v$VERSION" >> "$GITHUB_OUTPUT"` and `echo "major_tag=v${VERSION%%.*}" >> "$GITHUB_OUTPUT"`. Although a regex validation is applied before the write (which would reject newlines), the check rules require the sanitization step to be applied immediately before every write to a special environment file when the source is an untrusted input.

Locations:

- `.github/workflows/manual-release.yml`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed 4 findings across 4 files: (1) action.yml: replaced '${{ github.action_path }}' with '$GITHUB_ACTION_PATH' in the three run: steps (check_review_needed.sh, wait_for_ci.sh, run_review.sh); (2) scripts/check_review_needed.sh: sanitized EFFECTIVE_FORGEJO_API_URL at assignment time using 'printf | tr -d newlines' so all three write locations use the already-sanitized value; (3) scripts/sections/review.sh: sanitized ANALYSIS_ENGINE into safe_analysis_engine before writing to $OUTPUT_FILE; (4) .github/workflows/manual-release.yml: sanitized VERSION into SAFE_VERSION using 'printf | tr -d newlines' before writing tag and major_tag to $GITHUB_OUTPUT.

