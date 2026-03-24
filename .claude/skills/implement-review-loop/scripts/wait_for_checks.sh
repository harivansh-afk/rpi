#!/usr/bin/env bash
#
# Wait for GitHub checks to complete on a PR
# Returns check status when all checks complete or timeout is reached
#
# Usage: wait_for_checks.sh <owner/repo> <pr-number> [--timeout <minutes>]
#
# Example:
#   wait_for_checks.sh myorg/myrepo 123 --timeout 15
#

set -euo pipefail

REPO="${1:-}"
PR_NUMBER="${2:-}"
TIMEOUT_MINUTES=30
POLL_INTERVAL=15

usage() {
    echo "Usage: wait_for_checks.sh <owner/repo> <pr-number> [--timeout <minutes>]"
    echo ""
    echo "Options:"
    echo "  --timeout <minutes>   Maximum time to wait (default: 30)"
    echo ""
    echo "Example:"
    echo "  wait_for_checks.sh myorg/myrepo 123 --timeout 15"
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
        *)
            usage
            ;;
    esac
done

echo "Waiting for checks on PR #${PR_NUMBER} in ${REPO}"
echo "Timeout: ${TIMEOUT_MINUTES} minutes"
echo ""

START_TIME=$(date +%s)
TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [[ $ELAPSED -ge $TIMEOUT_SECONDS ]]; then
        echo ""
        echo "TIMEOUT: Checks did not complete within ${TIMEOUT_MINUTES} minutes"
        exit 1
    fi

    # Get check status
    CHECK_STATUS=$(gh pr checks "$PR_NUMBER" -R "$REPO" 2>/dev/null || echo "error")

    # Check if all checks passed
    if echo "$CHECK_STATUS" | grep -q "All checks were successful"; then
        echo ""
        echo "CHECKS_PASSED: All checks successful"
        exit 0
    fi

    # Check if any checks failed
    if echo "$CHECK_STATUS" | grep -qE "fail|error"; then
        echo ""
        echo "CHECKS_FAILED: Some checks failed"
        echo "$CHECK_STATUS"
        exit 1
    fi

    # Check if checks are still pending
    PENDING=$(echo "$CHECK_STATUS" | grep -c "pending\|queued\|in_progress" || true)

    if [[ "$PENDING" -eq 0 ]]; then
        # No pending checks and no failures means success
        echo ""
        echo "CHECKS_COMPLETE"
        echo "$CHECK_STATUS"
        exit 0
    fi

    REMAINING=$((TIMEOUT_SECONDS - ELAPSED))
    REMAINING_MINS=$((REMAINING / 60))
    echo -ne "\rWaiting for checks... (${REMAINING_MINS}m remaining, ${PENDING} pending)    "

    sleep "$POLL_INTERVAL"
done
