#!/bin/sh
# Fake gh CLI for testing the pr-reviewer action.
# Returns fake PR data so the action can proceed without a real PR.
# Handles --jq flag by piping output through jq.

REPO="${GITHUB_REPOSITORY:-owner/repo}"

# Helper: apply --jq expression if present in remaining args
apply_jq() {
  local json="$1"
  shift
  local jq_expr=""
  local prev=""
  for arg in "$@"; do
    if [ "$prev" = "--jq" ]; then
      jq_expr="$arg"
    fi
    prev="$arg"
  done
  if [ -n "$jq_expr" ]; then
    printf '%s' "$json" | jq -r "$jq_expr"
  else
    printf '%s\n' "$json"
  fi
}

# Extract PR number from a URL like repos/owner/repo/pulls/123
extract_pr_number() {
  printf '%s' "$1" | sed -n 's|.*/pulls/\([0-9]*\).*|\1|p'
}

# Build a fake PR object with the given PR number
fake_pr_object() {
  local pr_num="${1:-1}"
  cat <<EOF
{
  "number": ${pr_num},
  "title": "Test PR",
  "body": "Test pull request body",
  "state": "open",
  "html_url": "https://github.com/${REPO}/pull/${pr_num}",
  "changed_files": 1,
  "additions": 5,
  "deletions": 2,
  "head": {
    "sha": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "ref": "feature-branch",
    "repo": {
      "full_name": "${REPO}"
    }
  },
  "base": {
    "sha": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "ref": "main",
    "repo": {
      "full_name": "${REPO}"
    }
  },
  "user": {
    "login": "testuser"
  }
}
EOF
}

case "$1" in
  api)
    shift
    # Find the URL (first non-flag arg after 'api')
    url=""
    for arg in "$@"; do
      case "$arg" in
        -*) ;;
        *)
          if [ -z "$url" ]; then
            url="$arg"
          fi
          ;;
      esac
    done

    case "$url" in
      repos/*/pulls/*/files*)
        apply_jq '[]' "$@"
        ;;
      repos/*/pulls/*/reviews*)
        apply_jq '[]' "$@"
        ;;
      repos/*/issues/*/comments*)
        apply_jq '[]' "$@"
        ;;
      repos/*/pulls/*)
        pr_num="$(extract_pr_number "$url")"
        apply_jq "$(fake_pr_object "$pr_num")" "$@"
        ;;
      repos/*/commits/*/check-runs*)
        apply_jq '{"check_runs":[],"total_count":0}' "$@"
        ;;
      repos/*/commits/*/status*)
        apply_jq '{"state":"success","statuses":[],"total_count":0}' "$@"
        ;;
      graphql)
        echo '{"data":{}}'
        ;;
      *)
        # Unknown API call - return empty object
        echo '{}'
        ;;
    esac
    ;;

  pr)
    shift
    case "$1" in
      diff)
        # Return empty diff (no changes)
        exit 0
        ;;
      comment)
        # Pretend to post a comment successfully
        exit 0
        ;;
      review)
        # Pretend to submit a review successfully
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;

  auth)
    # Pretend to be authenticated
    exit 0
    ;;

  *)
    # Unknown command - exit 0 to not break the action
    exit 0
    ;;
esac
