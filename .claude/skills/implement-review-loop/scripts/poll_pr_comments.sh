#!/usr/bin/env bash
#
# Poll for new PR comments using GitHub CLI
# Returns when new comments are found or timeout is reached
#
# Usage: poll_pr_comments.sh <owner/repo> <pr-number> [--timeout <minutes>] [--interval <seconds>]
#
# Example:
#   poll_pr_comments.sh myorg/myrepo 123 --timeout 30 --interval 60
#

set -euo pipefail

REPO="${1:-}"
PR_NUMBER="${2:-}"
TIMEOUT_MINUTES=60
POLL_INTERVAL=30
INITIAL_COMMENT_COUNT=""

usage() {
    echo "Usage: poll_pr_comments.sh <owner/repo> <pr-number> [--timeout <minutes>] [--interval <seconds>]"
    echo ""
    echo "Options:"
    echo "  --timeout <minutes>   Maximum time to wait (default: 60)"
    echo "  --interval <seconds>  Time between polls (default: 30)"
    echo ""
    echo "Example:"
    echo "  poll_pr_comments.sh myorg/myrepo 123 --timeout 30 --interval 60"
    exit 1
}

if [[ -z "$REPO" || -z "$PR_NUMBER" ]]; then
    usage
fi

shift 2

while [[ $# -gt 0 ]]; do
    case "$1" in
        --timeout)
            TIMEOUT_MINUTES="$2"
            shift 2
            ;;
        --interval)
            POLL_INTERVAL="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

get_comment_count() {
    local review_comments issue_comments total

    # Get review comments (inline code comments)
    review_comments=$(gh api "repos/${REPO}/pulls/${PR_NUMBER}/comments" --jq 'length' 2>/dev/null || echo "0")

    # Get issue comments (PR-level comments)
    issue_comments=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --jq 'length' 2>/dev/null || echo "0")

    total=$((review_comments + issue_comments))
    echo "$total"
}

get_unresolved_threads() {
    # Get review threads that are not resolved
    gh pr view "$PR_NUMBER" -R "$REPO" --json reviewDecision,reviews,latestReviews 2>/dev/null || echo "{}"
}

echo "Polling for comments on PR #${PR_NUMBER} in ${REPO}"
echo "Timeout: ${TIMEOUT_MINUTES} minutes, Poll interval: ${POLL_INTERVAL} seconds"
echo ""

# Get initial comment count
INITIAL_COMMENT_COUNT=$(get_comment_count)
echo "Initial comment count: ${INITIAL_COMMENT_COUNT}"

START_TIME=$(date +%s)
TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [[ $ELAPSED -ge $TIMEOUT_SECONDS ]]; then
        echo ""
        echo "Timeout reached after ${TIMEOUT_MINUTES} minutes"
        echo "No new comments detected"
        exit 0
    fi

    CURRENT_COUNT=$(get_comment_count)

    if [[ "$CURRENT_COUNT" -gt "$INITIAL_COMMENT_COUNT" ]]; then
        NEW_COMMENTS=$((CURRENT_COUNT - INITIAL_COMMENT_COUNT))
        echo ""
        echo "NEW_COMMENTS_DETECTED: ${NEW_COMMENTS} new comment(s) found!"
        echo "Total comments: ${CURRENT_COUNT}"
        exit 0
    fi

    REMAINING=$((TIMEOUT_SECONDS - ELAPSED))
    REMAINING_MINS=$((REMAINING / 60))
    echo -ne "\rWaiting... (${REMAINING_MINS}m remaining, current count: ${CURRENT_COUNT})    "

    sleep "$POLL_INTERVAL"
done
