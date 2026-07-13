<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.1.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **misospace--pr-reviewer-action/v2.1.3** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Three `run:` steps in action.yml interpolate `${{ github.action_path }}` directly inside the shell command string. Any `${{ ... }}` expression inside a `run:` block is a script-injection finding regardless of which context it reads from. The offending lines are: `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"`, `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"`, and `run: bash "${{ github.action_path }}/scripts/run_review.sh"`. The safe pattern is to hoist `github.action_path` into an `env:` variable (e.g. `ACTION_PATH: ${{ github.action_path }}`) and reference `$ACTION_PATH` in the run block.

Locations:

- `action.yml:490`
- `action.yml:510`
- `action.yml:560`

### github-env-injection (severity: high)

The script `scripts/check_review_needed.sh` (called from action.yml's `run:` block) writes `EFFECTIVE_FORGEJO_API_URL` to `$GITHUB_OUTPUT` without the required sanitization step. `EFFECTIVE_FORGEJO_API_URL` is derived from `FORGEJO_API_URL` which is set from `inputs.forgejo_api_url` (an untrusted composite-action input). The write `echo "effective_forgejo_api_url=$EFFECTIVE_FORGEJO_API_URL" >> "$OUTPUT_FILE"` appears three times (early-exit paths and the main path). A newline in `inputs.forgejo_api_url` could inject arbitrary step outputs. The fix is: `safe=$(printf '%s' "$EFFECTIVE_FORGEJO_API_URL" | tr -d '\n\r')` before each write.

Locations:

- `scripts/check_review_needed.sh:97`
- `scripts/check_review_needed.sh:280`
- `scripts/check_review_needed.sh:430`

### github-env-injection (severity: high)

The script `scripts/sections/review.sh` (called from action.yml's `run:` block) writes `ANALYSIS_ENGINE` to `$GITHUB_OUTPUT` without the required sanitization step. `ANALYSIS_ENGINE` is constructed as `"$AI_MODEL@$AI_BASE_URL ($AI_API_FORMAT)"` where `AI_MODEL`, `AI_BASE_URL`, and `AI_API_FORMAT` all come from `inputs.*` (untrusted composite-action inputs). The write `echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"` is unsanitized. A newline in any of those inputs could inject arbitrary step outputs. The fix is: `safe=$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')` before the write.

Locations:

- `scripts/sections/review.sh:350`

### github-env-injection (severity: high)

In `.github/workflows/manual-release.yml`, the `Normalize release metadata` step writes `$VERSION` (derived from `inputs.version`, a `workflow_dispatch` input) to `$GITHUB_OUTPUT` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. While a regex check (`^[0-9]+\.[0-9]+\.[0-9]+...`) is applied before the write and does prevent newline injection in practice, the required sanitization pipeline is not present. The write block `echo "tag=v$VERSION" >> "$GITHUB_OUTPUT"` etc. should be preceded by explicit sanitization.

Locations:

- `.github/workflows/manual-release.yml:48`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four findings: (1) script-injection in action.yml: moved github.action_path into ACTION_PATH env variable for all three run: steps (check_review_needed.sh, wait_for_ci.sh, run_review.sh); (2) github-env-injection in scripts/check_review_needed.sh: sanitized EFFECTIVE_FORGEJO_API_URL with printf/tr -d '\n\r' immediately after it is set, covering all three write locations; (3) github-env-injection in scripts/sections/review.sh: sanitized ANALYSIS_ENGINE into safe_analysis_engine before writing to OUTPUT_FILE; (4) github-env-injection in .github/workflows/manual-release.yml: sanitized VERSION into safe_version with printf/tr -d '\n\r' before writing tag/major_tag to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed script injection vulnerabilities in two files:

1. scripts/sections/review.sh (maybe_escalate_review function, line ~270): Replaced the python3 -c string that interpolated $ESCALATE_ON_INCOMPLETE_REQUIRED_CHECKS, $ESCALATE_ON_FAST_REQUEST_CHANGES, $ESCALATE_ON_FAST_LOW_CONFIDENCE, $ESCALATE_ON_TOOL_OR_EVIDENCE_BLOCKERS, $ESCALATE_ON_DIRTY_BASELINE, $ESCALATE_ON_TOOL_PLANNING_FAILURE, and $DIRTY_BASELINE directly into Python code. Now uses environment variables (_ESC_ON_INCOMPLETE, _ESC_ON_REQUEST_CHANGES, etc.) passed to python3 with a single-quoted heredoc (<<'PY'), and reads them via os.environ.get() in Python.

2. scripts/sections/config.sh (three functions, lines ~450-480):
   - reassemble_sse_response(): Replaced python3 -c with interpolated $response_file and $api_format. Now uses _SSE_RESPONSE_FILE and _SSE_API_FORMAT env vars with a single-quoted heredoc.
   - parse_and_validate(): Replaced python3 -c with interpolated $response_file. Now uses _PARSE_RESPONSE_FILE env var with a single-quoted heredoc.
   - apply_all_enforcement_wrapper(): Replaced python3 -c with interpolated $verdict_policy, $validate_checks, $validation_mode, $evidence_blocker_enabled, $tool_failure_enabled, $tool_min_successful, and $carry_forward. Now uses _VERDICT_POLICY, _VALIDATE_CHECKS, _VALIDATION_MODE, _EVIDENCE_BLOCKER_ENABLED, _TOOL_FAILURE_ENABLED, _TOOL_MIN_SUCCESSFUL, and _CARRY_FORWARD env vars with a single-quoted heredoc. Also added integer validation for tool_min_successful before use.

