---
name: validating-production-quality
description: Validates that the task is following all production-grade quality checks. Use before attempting task completion on a task or when the USER asks for it.
---

# Validating production quality

When validating production quality for the task at hand, follow those steps.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am validating production quality".

## 2. Fix any potential regression

- ALWAYS run all test scenarios.
- ALWAYS fix all the failures that you see in the tests output.

## 3. Check that documentation is up-to-date

- ALWAYS use `skill: updating-doc` to update the project documentation.

## 4. Make sure all modifications are pushed

- ALWAYS use `skill: committing-changes` to commit all your changes in the current branch.

## 5. Make sure the branch is up-to-date with its base

- ALWAYS use `skill: syncing-branch-with-base` to make sure the current branch is up-to-date with its base.
- ALWAYS check that there is no merge commit between the current branch and its base.
  - If you find any merge commit, ALWAYS remove them by rebasing the branch in a linear way.

## 6. Make sure a Pull Request is created for the current branch

- ALWAYS check on the corresponding GitHub project if there is already a Pull Request created for the current branch.
- If there isn't any Pull Request for the current branch, ALWAYS use `skill: creating-pull-request` to create one.
