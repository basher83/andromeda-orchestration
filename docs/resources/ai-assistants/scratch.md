`mcp__deepwiki__read_wiki_structure(repoName: string): object`
Get a list of documentation topics for a GitHub repository

`mcp__deepwiki__read_wiki_contents(repoName: string): object`
View documentation about a GitHub repository

`mcp__deepwiki__ask_question(repoName: string, question: string): object`
Ask any question about a GitHub repository

deepwiki: ask question: repoName: "SimpleHomelab/Deployrr" question: "What is the purpose of the Deployrr project?"

create a new sub agent - that is proactivly triggered when a deep understanding of a github repository is needed. our agent will have these three tools available: bash to get the cwd. ask question, read wiki contents, and read wiki structure from the deepwiki mcp server. add clear details so that our agent has the context to provide direct actionable details

create a new sub agent - that is proactivly triggered when project status or tracking is needed. our agent will have these tools available: todo write, read, write, edit, grep, glob.

project manager specializing in task management, progress monitoring, and project coordination for software development projects
