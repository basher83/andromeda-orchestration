# Available Tools

## Task Management

`Task(description: string, prompt: string, subagent_type: string): void`
Launch a new agent to handle complex, multi-step tasks autonomously

`TodoWrite(todos: Array<{content: string, status: string, priority: string, id: string}>): void`
Create and manage a structured task list for tracking progress and organizing complex tasks

## File Operations

`Read(file_path: string, limit?: number, offset?: number): string`
Read a file from the local filesystem, supporting images, PDFs, and text files

`Write(file_path: string, content: string): void`
Write a file to the local filesystem (overwrites existing files)

`Edit(file_path: string, old_string: string, new_string: string, replace_all?: boolean): void`
Perform exact string replacements in files

`MultiEdit(file_path: string, edits: Array<{old_string: string, new_string: string, replace_all?: boolean}>): void`
Make multiple edits to a single file in one operation

`NotebookRead(notebook_path: string, cell_id?: string): object`
Read a Jupyter notebook (.ipynb file) and return all cells with their outputs

`NotebookEdit(notebook_path: string, new_source: string, cell_id?: string, cell_type?: string, edit_mode?: string): void`
Replace, insert, or delete cells in a Jupyter notebook

## Search and Navigation

`Bash(command: string, description?: string, timeout?: number): string`
Execute bash commands in a persistent shell session with proper handling

`Glob(pattern: string, path?: string): Array<string>`
Fast file pattern matching that works with any codebase size

`Grep(pattern: string, path?: string, glob?: string, type?: string, output_mode?: string, -i?: boolean, -n?: boolean, -A?: number, -B?: number, -C?: number, multiline?: boolean, head_limit?: number): object`
Powerful search tool built on ripgrep for finding patterns in files

`LS(path: string, ignore?: Array<string>): object`
List files and directories in a given absolute path

## Web Tools

`WebFetch(url: string, prompt: string): string`
Fetch content from a URL and process it using an AI model

`WebSearch(query: string, allowed_domains?: Array<string>, blocked_domains?: Array<string>): object`
Search the web and use results to inform responses

## Planning and Analysis

`ExitPlanMode(plan: string): void`
Exit plan mode after presenting implementation steps for coding tasks

## MCP Server Tools

`ListMcpResourcesTool(server?: string): Array<object>`
List available resources from configured MCP servers

`ReadMcpResourceTool(server: string, uri: string): object`
Read a specific resource from an MCP server

### Safety MCP

`mcp__safety-mcp-sse__check_package_security(packages: Array<{name: string, version?: string, ecosystem: string}>): object`
Check if Python packages contain vulnerabilities

`mcp__safety-mcp-sse__get_recommended_version(packages: Array<{name: string, ecosystem: string}>): object`
Get the recommended version for Python packages

`mcp__safety-mcp-sse__list_vulnerabilities_affecting_version(packages: Array<{name: string, version?: string, ecosystem: string}>): object`
List vulnerabilities affecting specific package versions

### Docker MCP

`mcp__docker-mcp__add_comment_to_pending_review(owner: string, repo: string, pullNumber: number, path: string, body: string, subjectType: string, line?: number, side?: string, startLine?: number, startSide?: string): void`
Add review comment to a pending pull request review

`mcp__docker-mcp__add_issue_comment(owner: string, repo: string, issue_number: number, body: string): void`
Add a comment to a specific GitHub issue

`mcp__docker-mcp__assign_copilot_to_issue(owner: string, repo: string, issueNumber: number): void`
Assign GitHub Copilot to work on a specific issue

`mcp__docker-mcp__cancel_workflow_run(owner: string, repo: string, run_id: number): void`
Cancel a GitHub Actions workflow run

`mcp__docker-mcp__create_and_submit_pull_request_review(owner: string, repo: string, pullNumber: number, body: string, event: string, commitID?: string): void`
Create and submit a review for a pull request

`mcp__docker-mcp__create_branch(owner: string, repo: string, branch: string, from_branch?: string): void`
Create a new branch in a GitHub repository

`mcp__docker-mcp__create_issue(owner: string, repo: string, title: string, body?: string, labels?: Array<string>, assignees?: Array<string>, milestone?: number): void`
Create a new issue in a GitHub repository

`mcp__docker-mcp__create_or_update_file(owner: string, repo: string, path: string, content: string, message: string, branch: string, sha?: string): void`
Create or update a single file in a GitHub repository

`mcp__docker-mcp__create_pending_pull_request_review(owner: string, repo: string, pullNumber: number, commitID?: string): void`
Create a pending review for a pull request

`mcp__docker-mcp__create_pull_request(owner: string, repo: string, title: string, head: string, base: string, body?: string, draft?: boolean, maintainer_can_modify?: boolean): void`
Create a new pull request in a GitHub repository

`mcp__docker-mcp__create_repository(name: string, description?: string, private?: boolean, autoInit?: boolean): void`
Create a new GitHub repository in your account

`mcp__docker-mcp__curl(args: Array<string>): string`
Run a curl command

`mcp__docker-mcp__delete_file(owner: string, repo: string, path: string, message: string, branch: string): void`
Delete a file from a GitHub repository

`mcp__docker-mcp__delete_pending_pull_request_review(owner: string, repo: string, pullNumber: number): void`
Delete the requester's latest pending pull request review

`mcp__docker-mcp__delete_workflow_run_logs(owner: string, repo: string, run_id: number): void`
Delete logs for a workflow run

`mcp__docker-mcp__dismiss_notification(threadID: string, state?: string): void`
Dismiss a notification by marking it as read or done

`mcp__docker-mcp__docker(args: Array<string>): string`
Use the docker CLI

`mcp__docker-mcp__download_workflow_run_artifact(owner: string, repo: string, artifact_id: number): string`
Get download URL for a workflow run artifact

`mcp__docker-mcp__fetch(url: string, max_length?: number, raw?: boolean, start_index?: number): string`
Fetch a URL from the internet and optionally extract its contents as markdown

`mcp__docker-mcp__fork_repository(owner: string, repo: string, organization?: string): void`
Fork a GitHub repository to your account or specified organization

`mcp__docker-mcp__get-library-docs(context7CompatibleLibraryID: string, tokens?: number, topic?: string): object`
Fetch up-to-date documentation for a library

`mcp__docker-mcp__get_code_scanning_alert(owner: string, repo: string, alertNumber: number): object`
Get details of a specific code scanning alert

`mcp__docker-mcp__get_commit(owner: string, repo: string, sha: string, page?: number, perPage?: number): object`
Get details for a commit from a GitHub repository

`mcp__docker-mcp__get_dependabot_alert(owner: string, repo: string, alertNumber: number): object`
Get details of a specific dependabot alert

`mcp__docker-mcp__get_discussion(owner: string, repo: string, discussionNumber: number): object`
Get a specific discussion by ID

`mcp__docker-mcp__get_discussion_comments(owner: string, repo: string, discussionNumber: number): object`
Get comments from a discussion

`mcp__docker-mcp__get_file_contents(owner: string, repo: string, path?: string, ref?: string, sha?: string): object`
Get the contents of a file or directory from a GitHub repository

`mcp__docker-mcp__get_issue(owner: string, repo: string, issue_number: number): object`
Get details of a specific issue in a GitHub repository

`mcp__docker-mcp__get_issue_comments(owner: string, repo: string, issue_number: number, page?: number, perPage?: number): object`
Get comments for a specific issue

`mcp__docker-mcp__get_job_logs(owner: string, repo: string, job_id?: number, run_id?: number, failed_only?: boolean, return_content?: boolean, tail_lines?: number): object`
Download logs for a specific workflow job or get all failed job logs

`mcp__docker-mcp__get_me(): object`
Get details of the authenticated GitHub user

`mcp__docker-mcp__get_notification_details(notificationID: string): object`
Get detailed information for a specific GitHub notification

`mcp__docker-mcp__get_pull_request(owner: string, repo: string, pullNumber: number): object`
Get details of a specific pull request

`mcp__docker-mcp__get_pull_request_comments(owner: string, repo: string, pullNumber: number): object`
Get comments for a specific pull request

`mcp__docker-mcp__get_pull_request_diff(owner: string, repo: string, pullNumber: number): string`
Get the diff of a pull request

`mcp__docker-mcp__get_pull_request_files(owner: string, repo: string, pullNumber: number, page?: number, perPage?: number): object`
Get the files changed in a specific pull request

`mcp__docker-mcp__get_pull_request_reviews(owner: string, repo: string, pullNumber: number): object`
Get reviews for a specific pull request

`mcp__docker-mcp__get_pull_request_status(owner: string, repo: string, pullNumber: number): object`
Get the status of a specific pull request

`mcp__docker-mcp__get_secret_scanning_alert(owner: string, repo: string, alertNumber: number): object`
Get details of a specific secret scanning alert

`mcp__docker-mcp__get_tag(owner: string, repo: string, tag: string): object`
Get details about a specific git tag

`mcp__docker-mcp__get_workflow_run(owner: string, repo: string, run_id: number): object`
Get details of a specific workflow run

`mcp__docker-mcp__get_workflow_run_logs(owner: string, repo: string, run_id: number): string`
Download logs for a specific workflow run (expensive operation)

`mcp__docker-mcp__get_workflow_run_usage(owner: string, repo: string, run_id: number): object`
Get usage metrics for a workflow run

`mcp__docker-mcp__list_branches(owner: string, repo: string, page?: number, perPage?: number): object`
List branches in a GitHub repository

`mcp__docker-mcp__list_code_scanning_alerts(owner: string, repo: string, state?: string, severity?: string, ref?: string, tool_name?: string): object`
List code scanning alerts in a repository

`mcp__docker-mcp__list_commits(owner: string, repo: string, sha?: string, author?: string, page?: number, perPage?: number): object`
Get list of commits of a branch in a repository

`mcp__docker-mcp__list_dependabot_alerts(owner: string, repo: string, state?: string, severity?: string): object`
List dependabot alerts in a repository

`mcp__docker-mcp__list_discussion_categories(owner: string, repo: string, first?: number, last?: number, after?: string, before?: string): object`
List discussion categories for a repository

`mcp__docker-mcp__list_discussions(owner: string, repo: string, category?: string): object`
List discussions for a repository

`mcp__docker-mcp__list_issues(owner: string, repo: string, state?: string, labels?: Array<string>, sort?: string, direction?: string, since?: string, page?: number, perPage?: number): object`
List issues in a GitHub repository

`mcp__docker-mcp__list_notifications(filter?: string, owner?: string, repo?: string, since?: string, before?: string, page?: number, perPage?: number): object`
List all GitHub notifications for the authenticated user

`mcp__docker-mcp__list_pull_requests(owner: string, repo: string, state?: string, head?: string, base?: string, sort?: string, direction?: string, page?: number, perPage?: number): object`
List pull requests in a repository

`mcp__docker-mcp__list_secret_scanning_alerts(owner: string, repo: string, state?: string, secret_type?: string, resolution?: string): object`
List secret scanning alerts in a repository

`mcp__docker-mcp__list_tags(owner: string, repo: string, page?: number, perPage?: number): object`
List git tags in a repository

`mcp__docker-mcp__list_workflow_jobs(owner: string, repo: string, run_id: number, filter?: string, page?: number, perPage?: number): object`
List jobs for a specific workflow run

`mcp__docker-mcp__list_workflow_run_artifacts(owner: string, repo: string, run_id: number, page?: number, perPage?: number): object`
List artifacts for a workflow run

`mcp__docker-mcp__list_workflow_runs(owner: string, repo: string, workflow_id: string, actor?: string, branch?: string, event?: string, status?: string, page?: number, perPage?: number): object`
List workflow runs for a specific workflow

`mcp__docker-mcp__list_workflows(owner: string, repo: string, page?: number, perPage?: number): object`
List workflows in a repository

`mcp__docker-mcp__manage_notification_subscription(notificationID: string, action: string): void`
Manage a notification subscription (ignore, watch, or delete)

`mcp__docker-mcp__manage_repository_notification_subscription(owner: string, repo: string, action: string): void`
Manage repository notification subscription

`mcp__docker-mcp__mark_all_notifications_read(lastReadAt?: string, owner?: string, repo?: string): void`
Mark all notifications as read

`mcp__docker-mcp__merge_pull_request(owner: string, repo: string, pullNumber: number, merge_method?: string, commit_title?: string, commit_message?: string): void`
Merge a pull request

`mcp__docker-mcp__perplexity_ask(messages: Array<{role: string, content: string}>): object`
Engage in conversation using the Sonar API

`mcp__docker-mcp__perplexity_reason(messages: Array<{role: string, content: string}>): object`
Perform reasoning tasks using Perplexity API

`mcp__docker-mcp__perplexity_research(messages: Array<{role: string, content: string}>): object`
Perform deep research using Perplexity API

`mcp__docker-mcp__push_files(owner: string, repo: string, branch: string, files: Array<{path: string, content: string}>, message: string): void`
Push multiple files to a repository in a single commit

`mcp__docker-mcp__request_copilot_review(owner: string, repo: string, pullNumber: number): void`
Request a GitHub Copilot code review for a pull request

`mcp__docker-mcp__rerun_failed_jobs(owner: string, repo: string, run_id: number): void`
Re-run only the failed jobs in a workflow run

`mcp__docker-mcp__rerun_workflow_run(owner: string, repo: string, run_id: number): void`
Re-run an entire workflow run

`mcp__docker-mcp__resolve-library-id(libraryName: string): object`
Resolve a package name to a Context7-compatible library ID

`mcp__docker-mcp__run_workflow(owner: string, repo: string, workflow_id: string, ref: string, inputs?: object): void`
Run an Actions workflow by ID or filename

`mcp__docker-mcp__search_code(q: string, sort?: string, order?: string, page?: number, perPage?: number): object`
Search for code across GitHub repositories

`mcp__docker-mcp__search_issues(query: string, sort?: string, order?: string, owner?: string, repo?: string, page?: number, perPage?: number): object`
Search for issues in GitHub repositories

`mcp__docker-mcp__search_orgs(query: string, sort?: string, order?: string, page?: number, perPage?: number): object`
Search for GitHub organizations exclusively

`mcp__docker-mcp__search_pull_requests(query: string, sort?: string, order?: string, owner?: string, repo?: string, page?: number, perPage?: number): object`
Search for pull requests in GitHub repositories

`mcp__docker-mcp__search_repositories(query: string, page?: number, perPage?: number): object`
Search for GitHub repositories

`mcp__docker-mcp__search_users(query: string, sort?: string, order?: string, page?: number, perPage?: number): object`
Search for GitHub users exclusively

`mcp__docker-mcp__submit_pending_pull_request_review(owner: string, repo: string, pullNumber: number, event: string, body?: string): void`
Submit the requester's latest pending pull request review

`mcp__docker-mcp__update_issue(owner: string, repo: string, issue_number: number, title?: string, body?: string, state?: string, labels?: Array<string>, assignees?: Array<string>, milestone?: number): void`
Update an existing issue

`mcp__docker-mcp__update_pull_request(owner: string, repo: string, pullNumber: number, title?: string, body?: string, state?: string, base?: string, maintainer_can_modify?: boolean): void`
Update an existing pull request

`mcp__docker-mcp__update_pull_request_branch(owner: string, repo: string, pullNumber: number, expectedHeadSha?: string): void`
Update pull request branch with latest changes from base

### DeepWiki MCP

`mcp__deepwiki__read_wiki_structure(repoName: string): object`
Get a list of documentation topics for a GitHub repository

`mcp__deepwiki__read_wiki_contents(repoName: string): object`
View documentation about a GitHub repository

`mcp__deepwiki__ask_question(repoName: string, question: string): object`
Ask any question about a GitHub repository

### Grep MCP

`mcp__grep__searchGitHub(query: string, language?: Array<string>, matchCase?: boolean, matchWholeWords?: boolean, path?: string, repo?: string, useRegexp?: boolean): object`
Find real-world code examples from over a million public GitHub repositories

### Serena MCP

`mcp__serena__list_dir(relative_path: string, recursive: boolean, max_answer_chars?: number): object`
List all non-gitignored files and directories in the given directory

`mcp__serena__find_file(file_mask: string, relative_path: string): object`
Find non-gitignored files matching the given file mask

`mcp__serena__replace_regex(relative_path: string, regex: string, repl: string, allow_multiple_occurrences?: boolean): void`
Replace occurrences of a regular expression in a file

`mcp__serena__search_for_pattern(substring_pattern: string, relative_path?: string, restrict_search_to_code_files?: boolean, paths_include_glob?: string, paths_exclude_glob?: string, context_lines_before?: number, context_lines_after?: number, max_answer_chars?: number): object`
Flexible search for arbitrary patterns in the codebase

`mcp__serena__restart_language_server(): void`
Restart the language server if editing errors occur

`mcp__serena__get_symbols_overview(relative_path: string, max_answer_chars?: number): object`
Get an overview of code symbols in a file or directory

`mcp__serena__find_symbol(name_path: string, relative_path?: string, substring_matching?: boolean, include_kinds?: Array<number>, exclude_kinds?: Array<number>, depth?: number, include_body?: boolean, max_answer_chars?: number): object`
Retrieve information on code entities based on name path

`mcp__serena__find_referencing_symbols(name_path: string, relative_path: string, include_kinds?: Array<number>, exclude_kinds?: Array<number>, max_answer_chars?: number): object`
Find symbols that reference the symbol at the given name path

`mcp__serena__replace_symbol_body(name_path: string, relative_path: string, body: string): void`
Replace the body of a symbol

`mcp__serena__insert_after_symbol(name_path: string, relative_path: string, body: string): void`
Insert content after the end of a symbol definition

`mcp__serena__insert_before_symbol(name_path: string, relative_path: string, body: string): void`
Insert content before the beginning of a symbol definition

`mcp__serena__write_memory(memory_name: string, content: string, max_answer_chars?: number): void`
Write information about the project to memory

`mcp__serena__read_memory(memory_file_name: string, max_answer_chars?: number): string`
Read the content of a memory file

`mcp__serena__list_memories(): Array<string>`
List available memories

`mcp__serena__delete_memory(memory_file_name: string): void`
Delete a memory file

`mcp__serena__remove_project(project_name: string): void`
Remove a project from Serena configuration

`mcp__serena__switch_modes(modes: Array<string>): void`
Activate desired modes

`mcp__serena__get_current_config(): object`
Print current agent configuration

`mcp__serena__check_onboarding_performed(): boolean`
Check whether project onboarding was performed

`mcp__serena__onboarding(): string`
Call if onboarding was not performed yet

`mcp__serena__think_about_collected_information(): void`
Reflect on collected information after searching

`mcp__serena__think_about_task_adherence(): void`
Think about task at hand before making code changes

`mcp__serena__think_about_whether_you_are_done(): void`
Reflect on task completion

`mcp__serena__summarize_changes(): void`
Summarize changes made to the codebase

`mcp__serena__prepare_for_new_conversation(): void`
Instructions for preparing for a new conversation

`mcp__serena__initial_instructions(): string`
Get initial instructions for the current coding project

### Infisical MCP

`mcp__infisical__create-secret(projectId: string, environmentSlug: string, secretName: string, secretPath?: string, secretValue?: string): void`
Create a new secret in Infisical

`mcp__infisical__delete-secret(projectId: string, environmentSlug: string, secretName: string, secretPath?: string): void`
Delete a secret in Infisical

`mcp__infisical__update-secret(projectId: string, environmentSlug: string, secretName: string, secretPath?: string, secretValue?: string, newSecretName?: string): void`
Update a secret in Infisical

`mcp__infisical__list-secrets(projectId: string, environmentSlug: string, secretPath?: string, includeImports?: boolean, expandSecretReferences?: boolean): object`
List all secrets in a given Infisical project and environment

`mcp__infisical__get-secret(projectId: string, environmentSlug: string, secretName: string, secretPath?: string, includeImports?: boolean, expandSecretReferences?: boolean): object`
Get a secret in Infisical

`mcp__infisical__create-project(projectName: string, type: string, description?: string, slug?: string, projectTemplate?: string, kmsKeyId?: string): void`
Create a new project in Infisical

`mcp__infisical__create-environment(projectId: string, name: string, slug: string, position?: number): void`
Create a new environment in Infisical

`mcp__infisical__create-folder(name: string, projectId: string, environment: string, path?: string, description?: string): void`
Create a new folder in Infisical

`mcp__infisical__invite-members-to-project(projectId: string, emails?: Array<string>, usernames?: Array<string>, roleSlugs?: Array<string>): void`
Invite members to a project in Infisical

`mcp__infisical__list-projects(type?: string): object`
List all projects in Infisical that the machine identity has access to

### IDE MCP

`mcp__ide__getDiagnostics(uri?: string): object`
Get language diagnostics from VS Code

`mcp__ide__executeCode(code: string): object`
Execute python code in the Jupyter kernel

### Context7 MCP

`mcp__context7__resolve-library-id(libraryName: string): object`
Resolve a package name to a Context7-compatible library ID

`mcp__context7__get-library-docs(context7CompatibleLibraryID: string, tokens?: number, topic?: string): object`
Fetch up-to-date documentation for a library

### Firecrawl MCP

`mcp__firecrawl__firecrawl_scrape(url: string, formats?: Array<string>, maxAge?: number, waitFor?: number, timeout?: number, includeTags?: Array<string>, excludeTags?: Array<string>, onlyMainContent?: boolean, removeBase64Images?: boolean, mobile?: boolean, skipTlsVerification?: boolean, location?: object, actions?: Array<object>, extract?: object): object`
Scrape content from a single URL with advanced options

`mcp__firecrawl__firecrawl_map(url: string, search?: string, ignoreSitemap?: boolean, includeSubdomains?: boolean, sitemapOnly?: boolean, limit?: number): Array<string>`
Map a website to discover all indexed URLs

`mcp__firecrawl__firecrawl_crawl(url: string, excludePaths?: Array<string>, includePaths?: Array<string>, maxDepth?: number, ignoreSitemap?: boolean, limit?: number, allowBackwardLinks?: boolean, allowExternalLinks?: boolean, deduplicateSimilarURLs?: boolean, ignoreQueryParameters?: boolean, scrapeOptions?: object, webhook?: string | object): string`
Start an asynchronous crawl job on a website

`mcp__firecrawl__firecrawl_check_crawl_status(id: string): object`
Check the status of a crawl job

`mcp__firecrawl__firecrawl_search(query: string, limit?: number, lang?: string, country?: string, filter?: string, tbs?: string, location?: object, scrapeOptions?: object): Array<object>`
Search the web and optionally extract content from search results

`mcp__firecrawl__firecrawl_extract(urls: Array<string>, prompt?: string, systemPrompt?: string, schema?: object, allowExternalLinks?: boolean, enableWebSearch?: boolean, includeSubdomains?: boolean): object`
Extract structured information from web pages using LLM capabilities

`mcp__firecrawl__firecrawl_deep_research(query: string, maxDepth?: number, timeLimit?: number, maxUrls?: number): object`
Conduct deep web research on a query using intelligent crawling

`mcp__firecrawl__firecrawl_generate_llmstxt(url: string, maxUrls?: number, showFullText?: boolean): object`
Generate a standardized llms.txt file for a given domain
