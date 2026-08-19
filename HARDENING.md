<!-- markdownlint-disable -->

# Hardening Report: misospace--pr-reviewer-action/v2.0.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **misospace--pr-reviewer-action/v2.0.3** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Three `run:` steps in action.yml interpolate `${{ github.action_path }}` directly inside the shell command string (sub-rule a: any `${{ ... }}` expression directly in a `run:` block is a script-injection finding, regardless of context). The affected lines are:
- `run: bash "${{ github.action_path }}/scripts/check_review_needed.sh"` (Check whether review is needed step)
- `run: bash "${{ github.action_path }}/scripts/wait_for_ci.sh"` (Wait for CI checks step)
- `run: bash "${{ github.action_path }}/scripts/run_review.sh"` (Run AI review step)
Fix: hoist `github.action_path` into an `env:` variable (e.g. `GITHUB_ACTION_PATH: ${{ github.action_path }}`) and reference it as `"${GITHUB_ACTION_PATH}/scripts/..."` in the `run:` body.

Locations:

- `action.yml:560`
- `action.yml:580`
- `action.yml:720`

### github-env-injection (severity: high)

In `scripts/sections/review.sh`, the variable `ANALYSIS_ENGINE` is constructed from `inputs.*` values (`inputs.ai_model`, `inputs.ai_base_url`, `inputs.ai_api_format`, and their fallback/smart equivalents) and written to `$GITHUB_OUTPUT` (via `$OUTPUT_FILE`) without the required `printf '%s' ... | tr -d '\n\r'` sanitization:

```bash
echo "analysis_engine=$ANALYSIS_ENGINE" >> "$OUTPUT_FILE"
```

An attacker-controlled model name or base URL containing a newline could inject arbitrary key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting subsequent step outputs (e.g. flipping the `verdict` output). Fix: sanitize before writing:
```bash
safe_engine=$(printf '%s' "$ANALYSIS_ENGINE" | tr -d '\n\r')
echo "analysis_engine=$safe_engine" >> "$OUTPUT_FILE"
```

Locations:

- `scripts/sections/review.sh:360`

### github-env-injection (severity: high)

In `.github/workflows/manual-release.yml`, the `Normalize release metadata` step writes `$VERSION` (derived from `inputs.version`, a `workflow_dispatch` input) to `$GITHUB_OUTPUT` without the required `printf '%s' ... | tr -d '\n\r'` sanitization:

```bash
echo "tag=v$VERSION" >> "$GITHUB_OUTPUT"
echo "major_tag=v${VERSION%%.*}" >> "$GITHUB_OUTPUT"
```

Although a regex validates the format before the write, the check rules require the specific sanitization pipeline (`tr -d '\n\r'`) before every write of an `inputs.*`-derived value to a special environment file. Fix: apply sanitization:
```bash
safe_version=$(printf '%s' "$VERSION" | tr -d '\n\r')
echo "tag=v$safe_version" >> "$GITHUB_OUTPUT"
echo "major_tag=v${safe_version%%.*}" >> "$GITHUB_OUTPUT"
```

Locations:

- `.github/workflows/manual-release.yml:40`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed 3 script-injection findings in action.yml by hoisting github.action_path into env blocks (GITHUB_ACTION_PATH) for the check_review_needed.sh, wait_for_ci.sh, and run_review.sh steps. Fixed github-env-injection in scripts/sections/review.sh by sanitizing ANALYSIS_ENGINE with printf/tr before writing to $OUTPUT_FILE. Fixed github-env-injection in .github/workflows/manual-release.yml by sanitizing VERSION with printf/tr before writing tag and major_tag to $GITHUB_OUTPUT.

