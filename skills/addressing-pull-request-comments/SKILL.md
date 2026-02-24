---
name: addressing-pull-request-comments
description: Addresses comments made on the GitHub Pull Request tracking changes of the current branch. What this does is read all Pull Requests comments addressed to the agent, improve or fix the code based on those comments, and reply too each one of those comments. Use this when the user is asking you to address the comments made on the current branch's Pull Request. Use this skill also in Plan mode.
metadata:
  agent: Plan
---

# Addressing Pull Request comments

## Sequential steps to be followed when using this skill

When addressing Pull Request comments, follow those steps.

### Create the addressing-pull-request-comments Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named addressing-pull-request-comments Execution Checklist with all steps of this skill.
- The addressing-pull-request-comments Execution Checklist must include all numbered steps explicitly.
- The addressing-pull-request-comments Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the addressing-pull-request-comments Execution Checklist as completed, and display again the addressing-pull-request-comments Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the addressing-pull-request-comments Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am addressing Pull Request comments" to inform the user that you are running this skill.

### 2. Fetch Pull Request comments (can be done during Plan mode)

- Find this skill directory path, later referenced as {skill_path}.
- Always use `cli: ruby {skill_path}/scripts/check_unresolved_pr_comments` to know about all the unresolved PR comments.

Example with expected output as JSON:
```bash
ruby .cline/skills/addressing-pull-request-comments/scripts/check_unresolved_pr_comments
# => Repository Github handle: Muriel-Salvan/ruby-neural-nets
# Branch name: main
# Found 1 Pull Requests dealing with this branch (numbers 3)
# Unresolved review threads and comments found on Pull Request #3:
# {
#   "data": {
#     "repository": {
#       "pullRequest": {
#         "url": "https://github.com/Muriel-Salvan/ruby-neural-nets/pull/3",
#         "reviewDecision": null,
#         "reviewThreads": {
#           "edges": [
#             {
#               "node": {
#                 "isResolved": false,
#                 "comments": {
#                   "totalCount": 1,
#                   "nodes": [
#                     {
#                       "databaseId": 2718057900,
# [...]
#                       "body": "Tests are failing. Please check again and fix it.",
#                       "subjectType": "LINE",
#                       "path": "lib/ruby_neural_nets/datasets/file_to_image_magick.rb",
#                       "commit": {
#                         "oid": "9ca8a54eccded4df1ea32520a05bce6f8bc665dd",
#                         "message": "Silence ffmpeg output by monkey-patching Open3.capture3 and Kernel.system to intercept and silence ffmpeg commands"
#                       },
#                     }
#                   ]
#                 }
#               }
#             }
#           ]
#         }
#       }
#     }
#   }
# }

```
Example of an error case with a non-existing Pull Request:
```bash
ruby .cline/skills/addressing-pull-request-comments/scripts/check_unresolved_pr_comments
# => Repository Github handle: Muriel-Salvan/x-aeon_agents_skills
# Branch name: main
# Found 0 Pull Requests dealing with this branch (numbers )
```

### 3. Consider all comments directed at the agent (can be done during Plan mode)

- Select all the comments that start with the string `/agent` and that don't have a reply from an agent (starting with `[Cline ({model})]` in the reply).
- Store those selected comments in a list referenced as {comments_list}.

### 4. Process each comment in {comments_list}

For each comment selected in {comments_list}, perform the following steps:

#### 4.1. Check if the comment requests a change or improvement (can be done during Plan mode)

- If yes, analyze the changes in Plan mode, the ask the user to switch to Act mode if not done already to perform those changes. Improve or fix the code as needed, following all existing rules.
- If no, skip code changes and continue to step 4.2.

Example of a comment asking for a code change:
```
/agent Refactor this method as it is too big
```
Example of a comment just asking a question, without needing code changes:
```
/agent I don't understand. Why are we using this API?
```

#### 4.2. Create a temporary file with your reply to the comment

- If you added new commits because of that comment, then always explain what improvements you made in your reply body.
- If the user was asking a question in his comment, then always give an answer to his question in your reply body.
- If you think the user comment did not need any code change, then always explain the reason why you think so in your reply body.
- Always use `agent: write_to_file` tool to write the reply body in a temporary file (later referenced as {reply_body_file}), inside the directory `./.tmp_agents/replies`.

Example of a reply explaining a code change:
```markdown
I refactored the method by splitting its parsing and publishing steps in 2 different methods:
* *query_parse*: Handles the parsing
* *query_publish*: Handles the publishing
I added the corresponding unit tests in spec/scenarios/queries_spec.rb
```
Example of a reply just answering a question without code change:
```markdown
This API is mainly used to fetch the results from our database.
We use it as it is the official documented way of retrieving our data, and it handles security gates for us.
```

#### 4.3. Reply to the comment

- Find the Pull Request number (later referenced as {pull_request_number}) and original comment database ID (later referenced as {comment_database_id}) from the comment data.
- Find this skill directory path, later referenced as {skill_path}.
- Always use `cli: ruby {skill_path}/scripts/reply_to_comment {pull_request_number} {comment_database_id} {reply_body_file}` to reply to the comment.
- Never use `cli: gh` directly to reply to comments.

Example:
```bash
ruby .cline/skills/addressing-pull-request-comments/scripts/reply_to_comment 3 2718057900 ./.tmp_agents/replies/comment_2718057900_reply.md
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the addressing-pull-request-comments Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- This skill can be used during Plan mode till code changes become needed.
- Always use it every time the user asks you to address Pull Request comments.
- Always use it every time another skill specifically mentions `skill: addressing-pull-request-comments`.
- Always use it every time you need to address Pull Request comments.

## Usage and code examples

Those examples are given for a Linux environment. Adapt them if you are running in a Windows environment.

### Steps to perform to address new comments

```bash
# 1. Get comments
ruby .cline/skills/addressing-pull-request-comments/scripts/check_unresolved_pr_comments
# 2. Loop over each unanswered comment that starts with `/agent`. For each one of them:
# 2.1. Apply necessary code changes if needed
# 2.2. Create ./.tmp_agents/replies/comment_1234567_reply.md with the appropriate reply
# 2.3. Reply to the comment
ruby .cline/skills/addressing-pull-request-comments/scripts/reply_to_comment 3 1234567 ./.tmp_agents/replies/comment_1234567_reply.md
```
