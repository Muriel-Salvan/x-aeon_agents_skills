---
name: implementing-github-issue
description: Implements what is described in a Github issue. Use when the USER is asking you to implement a Github issue.
---

# Implementing a Github issue changes

When implementing a Github issue, follow those steps.

## 1. Inform the USER

- You MUST inform the user that you are running this skill, saying "SKILL: I am implementing a Github issue".

## 2. Get issue requirements

- Use the `ask_followup_question` command to ask the USER which Github issue should be implemented, unless the USER already gave you this information in the prompt.
- Find this skill directory path, later referenced as {skill_path}.
- You MUST use the CLI command `ruby {skill_path}/scripts/issue_details {issue_number}` to retrieve all the details of this Github issue.

## 3. Come up with an implementation plan

- You MUST analyze the current code structure and content to understand how the Github issue should be implemented.
- You MUST analyze all the rules that you should adhere to when implementing a task.

## 4. Implement the issue following the implementation plan

- You MUST perform all the agreed steps from the implementation plan to implement the issue.
- You MUST perform a final verification of the implementation plan against all the actions you did. If you think some steps of the implementation plan were not implemented properly or are missing, fix it or inform the USER about those missing steps.
