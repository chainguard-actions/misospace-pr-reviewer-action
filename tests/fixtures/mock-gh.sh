#!/bin/sh
# Comprehensive fake gh binary for act-based tests.
# Handles --jq flags by piping through jq, and covers all API endpoints
# the action calls during precheck and review phases.

# Parse arguments to extract --jq expression and --repo flag
JQ_EXPR=""
REPO_FLAG=""
METHOD=""
INPUT_FILE=""
SILENT=""
prev=""
for arg in "$@"; do
  case "$prev" in
    --jq) JQ_EXPR="$arg" ;;
    --repo) REPO_FLAG="$arg" ;;
    -X|--method) METHOD="$arg" ;;
    --input) INPUT_FILE="$arg" ;;
  esac
  prev="$arg"
done

# Helper: emit JSON, optionally filtered by --jq
emit_json() {
  if [ -n "$JQ_EXPR" ]; then
    printf '%s' "$1" | jq -r "$JQ_EXPR" 2>/dev/null || printf '%s' "$1" | jq "$JQ_EXPR" 2>/dev/null || true
  else
    printf '%s' "$1"
  fi
}

case "$1" in
  pr)
    case "$2" in
      diff)
        # gh pr diff <number> --repo <repo>
        printf 'diff --git a/README.md b/README.md\nindex 000..111 100644\n--- a/README.md\n+++ b/README.md\n@@ -1 +1,2 @@\n # Test\n+Added line\n'
        ;;
      comment)
        # gh pr comment ... — succeed silently
        exit 0
        ;;
      review)
        # gh pr review ... — succeed silently
        exit 0
        ;;
      view)
        # gh pr view ... — return minimal PR JSON
        emit_json '{"number":1,"title":"Test PR","body":"Test body","state":"open","url":"https://github.com/test/repo/pull/1"}'
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  api)
    # Handle -X DELETE (label removal) and similar
    case "$*" in
      *DELETE*)
        exit 0
        ;;
    esac

    # $2 is the endpoint path (or a flag like -X)
    # Find the actual endpoint (first non-flag argument after 'api')
    ENDPOINT=""
    skip_next=0
    for arg in "$@"; do
      [ "$arg" = "api" ] && continue
      if [ "$skip_next" = "1" ]; then
        skip_next=0
        continue
      fi
      case "$arg" in
        -X|--method|--jq|--input|-f|-F|-H|--header|--field|--raw-field|--paginate)
          skip_next=1
          continue
          ;;
        -*)
          continue
          ;;
        *)
          if [ -z "$ENDPOINT" ]; then
            ENDPOINT="$arg"
          fi
          ;;
      esac
    done

    case "$ENDPOINT" in
      *pulls/1/files*)
        emit_json '[{"filename":"README.md","status":"modified","additions":1,"deletions":0,"changes":1}]'
        ;;
      *pulls/1/reviews*)
        emit_json '[]'
        ;;
      *issues/1/comments*)
        emit_json '[]'
        ;;
      *pulls/1*)
        emit_json '{"number":1,"title":"Test PR","body":"Test body","head":{"sha":"abc123def456abc123def456abc123def456abc1","ref":"feature","repo":{"full_name":"test/repo"}},"base":{"sha":"def456abc123def456abc123def456abc123def4","ref":"main","repo":{"full_name":"test/repo"}},"user":{"login":"testuser"},"changed_files":1,"additions":1,"deletions":0,"html_url":"https://github.com/test/repo/pull/1"}'
        ;;
      *commits/*/check-runs*)
        emit_json '{"check_runs":[],"total_count":0}'
        ;;
      *commits/*/status*)
        emit_json '{"state":"success","statuses":[]}'
        ;;
      *issues/1*)
        emit_json '{"number":1,"title":"Test Issue","state":"open","html_url":"https://github.com/test/repo/issues/1","labels":[],"body":"Test issue body"}'
        ;;
      *compare/*)
        emit_json '{"url":"","html_url":"","status":"ahead","ahead_by":1,"behind_by":0,"commits":[],"files":[]}'
        ;;
      graphql)
        emit_json '{"data":{}}'
        ;;
      *)
        emit_json '{}'
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
