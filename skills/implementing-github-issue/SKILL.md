---
name: implementing-github-issue
description: Implements what is described in a GitHub issue. What this does is first devise an implementation plan from the issue, execute the plan and validate production qualiy gates. Use this when the USER is asking you to implement a GitHub issue.
metadata:
  dependencies: analyzing-github-issue, validating-production-quality
  skip_quality_checks: Structure, Specificity
---

# Implementing a GitHub issue

## Sequential steps to be followed when using this skill

When implementing a GitHub issue, follow those steps.

### Create the implementing-github-issue Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named implementing-github-issue Execution Checklist with ALL steps of this skill.
- The implementing-github-issue Execution Checklist MUST include ALL numbered steps explicitly.
- The implementing-github-issue Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the implementing-github-issue Execution Checklist as completed, and display again the implementing-github-issue Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the implementing-github-issue Execution Checklist remains open.

### 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am implementing a GitHub issue" to inform the USER that you are running this skill.

### 2. Analyze the Github issue requirements to get an implementation plan (can be done during PLAN mode)

- ALWAYS use `skill: analyzing-github-issue` to get a full implementation plan. This plan will take into consideration requirements from the issue, USER inputs and the project's context.

### 3. Implement the issue following the implementation plan

- ALWAYS perform all the agreed steps from the implementation plan to implement the issue.
- ALWAYS perform a final verification of the implementation plan against all the actions you did. If you think some steps of the implementation plan were not implemented properly or are missing, fix it or inform the USER about those missing steps.

### 4. Validate all production quality checks

- ALWAYS use `skill: validating-production-quality` before attempting task completion to make sure that all needed quality gates are passing.

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the implementing-github-issue Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- You MUST use it every time the USER asks you to implement a Github issue.
- You MUST use it every time another skill specifically mentions `skill: implementing-github-issue`.
- You can use it every time you need to implement a Github issue.

## Usage and code examples

### Implementing a Github issue

This skill should perform the following steps:
1. Use the skill named analyzing-github-issue to get an implementation plan
2. Execute all the steps that are identified in the implementation plan
3. Use the skill named validating-production-quality to check all production quality gates
