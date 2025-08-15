---
allowed-tools: mcp__github__get_pull_request, mcp__github__get_pull_request_diff, mcp__github__get_pull_request_files, mcp__github__get_pull_request_comments, mcp__github__get_pull_request_reviews, mcp__github__get_pull_request_status, mcp__github__list_workflow_runs, mcp__github__get_job_logs
argument-hint: [PR number]
description: Gather comprehensive context about a PR (comments, reviews, CI status)
---

# PR Context Gathering

Gather comprehensive context about pull request #$ARGUMENTS in the basher83/docs repository.

## Your Task

1. **Get PR Overview**
   - Call mcp__github__get_pull_request with owner="basher83", repo="docs", pullNumber=$ARGUMENTS
   - Note the title, description, author, base/head branches, and current state

2. **Check Status**
   - Call mcp__github__get_pull_request_status with owner="basher83", repo="docs", pullNumber=$ARGUMENTS
   - Check for merge conflicts and CI check status

3. **Review Changes**
   - Call mcp__github__get_pull_request_files with owner="basher83", repo="docs", pullNumber=$ARGUMENTS to list changed files
   - Call mcp__github__get_pull_request_diff with owner="basher83", repo="docs", pullNumber=$ARGUMENTS to see actual changes

4. **Read Discussions**
   - Call mcp__github__get_pull_request_comments with owner="basher83", repo="docs", pullNumber=$ARGUMENTS
   - Call mcp__github__get_pull_request_reviews with owner="basher83", repo="docs", pullNumber=$ARGUMENTS
   - Note any requested changes or unresolved feedback

5. **Check CI (if failing)**
   - If checks are failing, call mcp__github__list_workflow_runs with owner="basher83", repo="docs" to find failed runs
   - For failed runs, call mcp__github__get_job_logs with owner="basher83", repo="docs", run_id=[id], failed_only=true

## Summary Format

Provide a structured summary with:

- **PR #$ARGUMENTS Overview**: Title, author, target branch, current status
- **Changes**: Files modified, additions/deletions, change patterns
- **Review Status**: Approvals, requested changes, unresolved comments
- **CI Status**: Pass/fail status, specific errors if any
- **Next Actions**: Clear recommendations for what needs attention
