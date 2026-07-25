#!/bin/sh
# Fake gh CLI for testing.
# Intercepts PR-related API calls and returns minimal fake data so the action
# can proceed through context-gathering without a real pull request.
# Unknown commands are forwarded to the real gh binary (REAL_GH env var).

ARGS="$*"
case "$ARGS" in
  "pr diff "*)
    # Return empty diff — no changes
    exit 0
    ;;
  "api repos/"*"/pulls/"*"/files"*)
    # Return empty files array
    printf '[]'
    exit 0
    ;;
  "api repos/"*"/pulls/"*"/reviews"*)
    # Return empty reviews array
    printf '[]'
    exit 0
    ;;
  "api repos/"*"/issues/"*"/comments"*)
    # Return empty comments array
    printf '[]'
    exit 0
    ;;
  "api repos/"*"/pulls/"*)
    # Return a minimal fake PR object (not files or reviews — those are matched above)
    printf '{"number":99999,"title":"Test PR","body":"","head":{"sha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","ref":"test-branch","repo":{"full_name":"test/repo"}},"base":{"sha":"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb","ref":"main","repo":{"full_name":"test/repo"}},"user":{"login":"tester"},"changed_files":0,"additions":0,"deletions":0,"html_url":"https://github.com/test/repo/pull/99999","state":"open"}'
    exit 0
    ;;
  "api repos/"*"/issues/"*)
    # Return a minimal fake issue object
    printf '{"number":1,"title":"Test Issue","body":"","state":"open","html_url":"https://github.com/test/repo/issues/1","labels":[]}'
    exit 0
    ;;
  *)
    # Forward to the real gh binary
    if [ -n "${REAL_GH:-}" ] && [ -x "$REAL_GH" ]; then
      exec "$REAL_GH" "$@"
    else
      exec /usr/bin/gh "$@"
    fi
    ;;
esac
