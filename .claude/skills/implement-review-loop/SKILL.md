---
name: implement-review-loop
description: Implement code from a plan, create PRs with Graphite CLI (gt create/submit), wait for code reviews, and iterate on feedback. Use when the user says "implement", "implement the plan", "create PR", "review loop", or wants to go from plan to merged PR. This skill handles the full cycle - implement code, create branch with Graphite, submit PR, wait for reviews (without wasting tokens), read comments, fix code, and push updates.
---

# Implement Review Loop

End-to-end workflow for implementing code from a plan, creating PRs with Graphite, and iterating on review feedback.

## Prerequisites

- Graphite CLI installed (`gt --version`)
- GitHub CLI installed (`gh --version`)
- Repository initialized with Graphite (`gt init` if not)
- Devin Review available via npx (`npx devin-review`)

## Workflow Overview

```
Plan -> Implement -> Create Branch (gt) -> Submit PR -> Wait for Review -> Read Comments -> Fix -> Push -> Repeat
```

## Phase 1: Implement the Plan

1. Read the current plan (from context, file, or conversation)
2. Implement all changes specified in the plan
3. Run tests and linting to verify implementation
4. Stage changes: `git add <specific-files>`

## Phase 2: Create Branch and PR with Graphite

Create branch with auto-generated name from commit message:

```bash
gt create --all --message "feat: <description from plan>"
```

Submit the PR with auto-generated description:

```bash
gt submit --ai --stack
```

Or with manual title/description:

```bash
gt submit --edit-title --edit-description
```

Capture the PR URL from output for later use.

## Phase 3: Request Code Review (Optional)

Run Devin Review for AI-powered code review:

```bash
cd /path/to/repo
npx devin-review https://github.com/owner/repo/pull/123
```

This creates an isolated worktree and sends diff to Devin for analysis.

## Phase 4: Wait for Reviews (Token-Efficient)

Use the polling script to wait without consuming tokens:

```bash
./scripts/poll_pr_comments.sh owner/repo 123 --timeout 60 --interval 30
```

The script:

- Polls GitHub API every 30 seconds (configurable)
- Returns when new comments are detected
- Exits after timeout with no-comments status
- Does NOT consume Claude context while waiting

For CI checks:

```bash
./scripts/wait_for_checks.sh owner/repo 123 --timeout 15
```

## Phase 5: Read and Address Comments

Fetch all comments for review:

```bash
./scripts/fetch_pr_comments.sh owner/repo 123
```

This outputs:

- Inline review comments with file:line locations
- PR-level comments
- Review decision status

For each comment:

1. Read the feedback
2. Implement the fix
3. Stage the changes

## Phase 6: Push Updates

Amend current commit and push:

```bash
gt modify --all
gt submit
```

Or create a new fixup commit:

```bash
gt create --all --message "fix: address review feedback"
gt submit
```

## Phase 7: Loop Until Approved

Repeat phases 4-6 until:

- All comments are resolved
- PR is approved
- Ready to merge

## Quick Reference

| Task           | Command                                  |
| -------------- | ---------------------------------------- |
| Create branch  | `gt create -am "feat: description"`      |
| Submit PR      | `gt submit --ai --stack`                 |
| View PR        | `gt pr`                                  |
| Amend changes  | `gt modify -a`                           |
| Push updates   | `gt submit`                              |
| Poll comments  | `./scripts/poll_pr_comments.sh repo pr`  |
| Fetch comments | `./scripts/fetch_pr_comments.sh repo pr` |
| Devin review   | `npx devin-review <pr-url>`              |

## Bundled Scripts

### poll_pr_comments.sh

Polls for new PR comments without consuming context:

```bash
./scripts/poll_pr_comments.sh <owner/repo> <pr-number> [--timeout <min>] [--interval <sec>]
```

### wait_for_checks.sh

Waits for GitHub checks to complete:

```bash
./scripts/wait_for_checks.sh <owner/repo> <pr-number> [--timeout <min>]
```

### fetch_pr_comments.sh

Fetches and formats all PR comments:

```bash
./scripts/fetch_pr_comments.sh <owner/repo> <pr-number> [--unresolved-only]
```
