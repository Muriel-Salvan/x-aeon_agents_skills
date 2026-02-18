---
name: validating-production-quality
description: Validates that the task is following all production-grade quality checks. What this does is check for regressions, update documentation, update the branch on the latest base, commit any remaining changes, push them on Github and create a Pull Request. Use this when attempting task completion on a task or when the USER asks for validating production qulity gates.
metadata:
  dependencies: updating-doc, committing-changes, syncing-branch-with-base, creating-pull-request
---

# Validating production quality

## Sequential steps to be followed when using this skill

When validating production quality, follow those steps.

### Create the validating-production-quality Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named validating-production-quality Execution Checklist with ALL steps of this skill.
- The validating-production-quality Execution Checklist MUST include ALL numbered steps explicitly.
- The validating-production-quality Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the validating-production-quality Execution Checklist as completed, and display again the validating-production-quality Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the validating-production-quality Execution Checklist remains open.

### 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am validating production quality" to inform the USER that you are running this skill.

### 2. Fix any potential regression

- ALWAYS run all test scenarios.
- ALWAYS fix all the failures that you see in the tests output.

### 3. Update documentation

- ALWAYS use `skill: updating-doc` to update the project documentation.

### 4. Commit all pending modifications

- ALWAYS use `skill: committing-changes` to commit all your changes in the current branch.

### 5. Sync the branch with its base

- ALWAYS use `skill: syncing-branch-with-base` to make sure the current branch is up-to-date with its base.

### 6. Remove any merge commit in the current branch

- ALWAYS check that there is no merge commit between the current branch and its base.
- IF you find any merge commit, THEN ALWAYS remove them by rebasing the branch in a linear way, using `cli: git rebase`, and push again to the Github remote using `--force-with-lease` option.

### 7. Create a Pull Request for the current branch

- ALWAYS check on the corresponding GitHub project if there is already a Pull Request created for the current branch.
- IF there isn't any Pull Request for the current branch, THEN ALWAYS use `skill: creating-pull-request` to create one.

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the validating-production-quality Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
