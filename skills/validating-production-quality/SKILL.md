---
name: validating-production-quality
description: Validates that the task is following all production-grade quality checks. What this does is check for regressions, update documentation, update the branch on the latest base, commit any remaining changes, push them on GitHub and create a Pull Request. Use this when attempting task completion on a task or when the user asks for validating production qulity gates.
metadata:
  dependencies: updating-doc, committing-changes, syncing-branch-with-base, creating-pull-request
---

# Validating production quality

## Sequential steps to be followed when using this skill

When validating production quality, follow those steps.

### Create the validating-production-quality Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named validating-production-quality Execution Checklist with all steps of this skill.
- The validating-production-quality Execution Checklist must include all numbered steps explicitly.
- The validating-production-quality Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the validating-production-quality Execution Checklist as completed, and display again the validating-production-quality Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the validating-production-quality Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am validating production quality" to inform the user that you are running this skill.

### 2. Fix any potential regression

- Always run all test scenarios.
- Always fix all the failures that you see in the tests output.

For example, in a Python project:
```bash
python -m unittest
```

### 3. Update documentation

- Always use `skill: updating-doc` to update the project documentation.

### 4. Commit all pending modifications

- Always use `skill: committing-changes` to commit all your changes in the current branch.

### 5. Sync the branch with its base

- Always use `skill: syncing-branch-with-base` to make sure the current branch is up-to-date with its base.

### 6. Remove any merge commit in the current branch

- Always check that there is no merge commit between the current branch and its base.
- If you find any merge commit, then always remove them by rebasing the branch in a linear way, using `cli: git rebase`, and push again to the GitHub remote using `--force-with-lease` option.

Example, in case of merge commits found:
```bash
git log --oneline --ancestry-path main..my_branch
git rebase main
git push github --force-with-lease
```

### 7. Create a Pull Request for the current branch

- Always check on the corresponding GitHub project if there is already a Pull Request created for the current branch.
- If there isn't any Pull Request for the current branch, then always use `skill: creating-pull-request` to create one.

Example to check for a Pull Request:
```bash
gh pr list
# Execute skill creating-pull-request if our branch is not in this list
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the validating-production-quality Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- Always use it every time the user asks you to validate production quality gates.
- Always use it every time another skill specifically mentions `skill: validating-production-quality`.
- Always use it just before attempting completion of a task that is a full production-grade feature or bug fix.

## Usage and code examples

### Before attempting completion on a task

```bash
# 1. Check tests
python -m unittest
# Fix any failing test

# 2. Run skill updating-doc.

# 3. Run skill committing-changes.

# 4. Run skill syncing-branch-with-base

# 5. Remove merge commits
git log --oneline --ancestry-path main..my_branch
git rebase main
git push github --force-with-lease

# 6. Create Pull Request if not already present
gh pr list
# Run skill creating-pull-request
```
