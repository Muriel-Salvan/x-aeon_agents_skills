---
name: analyzing-github-issue
description: Analyzes requirements described in a GitHub issue. What this does is read the Github issue content and devise an implementation plan. Use this when the USER is asking you to analyze a GitHub issue or get requirements from it. You can use this skill in PLAN mode.
metadata:
  agent: Plan
  dependencies: validating-production-quality
---

# Implementing a GitHub issue

## Sequential steps to be followed when using this skill

When implementing a GitHub issue, follow those steps.

### Create the analyzing-github-issue Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named analyzing-github-issue Execution Checklist with ALL steps of this skill.
- The analyzing-github-issue Execution Checklist MUST include ALL numbered steps explicitly.
- The analyzing-github-issue Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the analyzing-github-issue Execution Checklist as completed, and display again the analyzing-github-issue Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the analyzing-github-issue Execution Checklist remains open.

### 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am implementing a GitHub issue" to inform the USER that you are running this skill.

### 2. Get issue number (can be done during PLAN mode)

- ALWAYS use `agent: ask_followup_question` to ask the USER which GitHub issue should be analyzed, unless the USER already gave you this information in the prompt.

### 3. Get issue requirements (can be done during PLAN mode)

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use `cli: ruby {skill_path}/scripts/issue_details {issue_number}` to retrieve all the details of this GitHub issue.

Example with expected output as JSON:
```bash
ruby .cline/skills/analyzing-github-issue/scripts/issue_details 29
# => {"body":"# This is the Github issue body ...","comments":[],"labels":[],"number":29,"state":"OPEN","title":"This is the Github issue title","url":"https://github.com/my-user/my-repo/issues/29"}
```
Example of an error case with a non-existing Github issue:
```bash
ruby .cline/skills/analyzing-github-issue/scripts/issue_details 29
# GraphQL: Could not resolve to an issue or pull request with the number of 29. (repository.issue)
# .cline/skills/analyzing-github-issue/scripts/issue_details:9:in 'Kernel#system': Command failed with exit 1: gh issue view 29 --json=number,title,body,comments,labels,state,url (RuntimeError)
#       from .cline/skills/analyzing-github-issue/scripts/issue_details:9:in '<main>'
```

### 4. Come up with an implementation plan (can be done during PLAN mode)

- ALWAYS analyze the current code structure and content to understand how the GitHub issue should be implemented.
- ALWAYS analyze all the rules that you should adhere to when implementing a task.

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the analyzing-github-issue Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- This skill can be used during PLAN mode and is totally safe.
- You MUST use it every time the USER asks you to analyze a given Github issue.
- You MUST use it every time another skill specifically mentions `skill: analyzing-github-issue`.
- You can use it every time you need to analyze a Github issue to gather requirements.

## Usage and code examples

Those examples are given for a Linux environment. Adapt them if you are running in a Windows environment.

### When asked to analyze a Github issue

If the USER asked you to analyze a Github issue without specifying the number, this skill should perform the following commands:
```bash
# Use agent tool ask_followup_question to get the Github issue number from the USER
ruby .cline/skills/analyzing-github-issue/scripts/issue_details 42
```

### When asked to analyze the Github issue number 42

If the USER asked you to analyze the Github issue number 42, this skill should perform the following commands:
```bash
ruby .cline/skills/analyzing-github-issue/scripts/issue_details 42
```

### Example of implementation plan

```
### Current Code Structure

- `lib/my_class.rb`: Has the `debug_mode` accessor

### Implementation Plan

__Files to modify:__
- `lib/my_class.rb`
- `README.md`
- *.erb

__Changes:__

1. Create a `Logger` class within `lib/utils/logger.rb` that logs output.

2. Modify the `lib/my_class.rb` to:

   - Move existing debug logic to Logger`

### Expected Behavior

- `DEBUG=1 bundle exec bin/run` → debug mode enabled and logs visible in stdout
- `bundle exec bin/run` → debug mode disabled (current behavior)
```
