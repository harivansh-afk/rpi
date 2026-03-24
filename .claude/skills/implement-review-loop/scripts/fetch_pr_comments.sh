#!/usr/bin/env bash
#
# Fetch all PR comments (both inline review comments and PR-level comments)
# Outputs structured JSON for Claude to process
#
# Usage: fetch_pr_comments.sh <owner/repo> <pr-number> [--unresolved-only]
#
# Example:
#   fetch_pr_comments.sh myorg/myrepo 123
#   fetch_pr_comments.sh myorg/myrepo 123 --unresolved-only
#

set -euo pipefail

REPO="${1:-}"
PR_NUMBER="${2:-}"
UNRESOLVED_ONLY=false

usage() {
    echo "Usage: fetch_pr_comments.sh <owner/repo> <pr-number> [--unresolved-only]"
    echo ""
    echo "Options:"
    echo "  --unresolved-only   Only show unresolved review threads"
    echo ""
    echo "Example:"
    echo "  fetch_pr_comments.sh myorg/myrepo 123"
    exit 1
}

if [[ -z "$REPO" || -z "$PR_NUMBER" ]]; then
    usage
fi

shift 2

while [[ $# -gt 0 ]]; do
    case "$1" in
        --unresolved-only)
            UNRESOLVED_ONLY=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

echo "# PR #${PR_NUMBER} Comments"
echo ""

# Fetch inline review comments
echo "## Inline Review Comments"
echo ""

REVIEW_COMMENTS=$(gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments" \
    --jq '.[] | "### \(.path):\(.line // .original_line // "N/A")\n**Author:** \(.user.login)\n**Created:** \(.created_at)\n\n\(.body)\n\n---\n"' 2>/dev/null || echo "No inline comments")

if [[ -n "$REVIEW_COMMENTS" && "$REVIEW_COMMENTS" != "No inline comments" ]]; then
    echo "$REVIEW_COMMENTS"
else
    echo "No inline review comments."
    echo ""
fi

# Fetch PR-level comments (issue comments)
echo "## PR-Level Comments"
echo ""

ISSUE_COMMENTS=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq '.[] | "### Comment by \(.user.login)\n**Created:** \(.created_at)\n\n\(.body)\n\n---\n"' 2>/dev/null || echo "No PR comments")

if [[ -n "$ISSUE_COMMENTS" && "$ISSUE_COMMENTS" != "No PR comments" ]]; then
    echo "$ISSUE_COMMENTS"
else
    echo "No PR-level comments."
    echo ""
fi

# Fetch review threads with resolution status
echo "## Review Threads Summary"
echo ""

gh pr view "$PR_NUMBER" -R "$REPO" --json reviews,reviewDecision \
    --jq '"Review Decision: \(.reviewDecision // "PENDING")\n\nReviews:\n" + (.reviews | map("- \(.author.login): \(.state)") | join("\n"))' 2>/dev/null || echo "Could not fetch review summary"

echo ""
