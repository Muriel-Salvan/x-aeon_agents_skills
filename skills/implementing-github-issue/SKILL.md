---
name: implementing-github-issue
description: Implements what is described in a GitHub issue. What this does is first devise an implementation plan from the issue, execute the plan and validate production qualiy gates. Use this when the USER is asking you to implement a GitHub issue.
metadata:
  dependencies: analyzing-github-issue, validating-production-quality
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

- ALWAYS tell the USER "SKILL: I am implementing a GitHub issue" to inform the USER that you are running this skill.

## 2. Analyze the Github issue requirements to get an implementation plan (can be done during PLAN mode)

- ALWAYS use `skill: analyzing-github-issue` to get a full implementation plan. This plan will take into consideration requirements from the issue, USER inputs and the project's context.

## 3. Implement the issue following the implementation plan

- ALWAYS perform all the agreed steps from the implementation plan to implement the issue.
- ALWAYS perform a final verification of the implementation plan against all the actions you did. If you think some steps of the implementation plan were not implemented properly or are missing, fix it or inform the USER about those missing steps.

## 4. Validate all production quality checks

- ALWAYS use `skill: validating-production-quality` before attempting task completion to make sure that all needed quality gates are passing.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the implementing-github-issue Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
