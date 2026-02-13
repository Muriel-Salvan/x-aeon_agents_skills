---
name: implementing-github-issue
description: Implements what is described in a GitHub issue. Use when the USER is asking you to implement a GitHub issue.
---

# Implementing a GitHub issue

When implementing a GitHub issue, follow those steps.

## Create the implementing-github-issue Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named implementing-github-issue Execution Checklist with ALL steps of this skill.
- The implementing-github-issue Execution Checklist MUST include ALL numbered steps explicitly.
- The implementing-github-issue Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the implementing-github-issue Execution Checklist as completed, and display again the implementing-github-issue Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the implementing-github-issue Execution Checklist remains open.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am implementing a GitHub issue".

## 2. Get issue requirements

- ALWAYS use `agent: ask_followup_question` to ask the USER which GitHub issue should be implemented, unless the USER already gave you this information in the prompt.
- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use `cli: ruby {skill_path}/scripts/issue_details {issue_number}` to retrieve all the details of this GitHub issue.

## 3. Come up with an implementation plan

- ALWAYS analyze the current code structure and content to understand how the GitHub issue should be implemented.
- ALWAYS analyze all the rules that you should adhere to when implementing a task.

## 4. Implement the issue following the implementation plan

- ALWAYS perform all the agreed steps from the implementation plan to implement the issue.
- ALWAYS perform a final verification of the implementation plan against all the actions you did. If you think some steps of the implementation plan were not implemented properly or are missing, fix it or inform the USER about those missing steps.

## 5. Validate all production quality checks

- ALWAYS use `skill: validating-production-quality` before attempting task completion to make sure that all needed quality gates are ok.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the implementing-github-issue Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
