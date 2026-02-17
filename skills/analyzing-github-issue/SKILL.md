---
name: analyzing-github-issue
description: Analyzes requirements described in a GitHub issue. What this does is read the Github issue content and devise an implementation plan. Use this when the USER is asking you to analyze a GitHub issue or get requirements from it. You should use this skill in PLAN mode.
metadata:
  agent: Plan
  dependencies: validating-production-quality
---

# Implementing a GitHub issue

When implementing a GitHub issue, follow those steps.

## Create the analyzing-github-issue Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named analyzing-github-issue Execution Checklist with ALL steps of this skill.
- The analyzing-github-issue Execution Checklist MUST include ALL numbered steps explicitly.
- The analyzing-github-issue Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the analyzing-github-issue Execution Checklist as completed, and display again the analyzing-github-issue Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the analyzing-github-issue Execution Checklist remains open.

## 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am implementing a GitHub issue" to inform the USER that you are running this skill.

## 2. Get issue number (can be done during PLAN mode)

- ALWAYS use `agent: ask_followup_question` to ask the USER which GitHub issue should be implemented, unless the USER already gave you this information in the prompt.

## 3. Get issue requirements (can be done during PLAN mode)

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use `cli: ruby {skill_path}/scripts/issue_details {issue_number}` to retrieve all the details of this GitHub issue.

## 4. Come up with an implementation plan (can be done during PLAN mode)

- ALWAYS analyze the current code structure and content to understand how the GitHub issue should be implemented.
- ALWAYS analyze all the rules that you should adhere to when implementing a task.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the analyzing-github-issue Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
