---
name: syncing-branch-with-base
description: Syncs the current branch with its base. What this does is check the remote base branch, rebase the current one on the updated base and push it back to the remote. Use this when the base branch of the current branch may have diverged and you want to be sure that the current branch gets all latest changes of its base. This Skill is the canonical way to keep a branch up-to-date with its base. It must be used instead of merging the base branch, and always performs a rebase.
---

# Syncing the current branch with its base

## Sequential steps to be followed when using this skill

When syncing the current branch with its base, follow those steps.

### Create the syncing-branch-with-base Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named syncing-branch-with-base Execution Checklist with ALL steps of this skill.
- The syncing-branch-with-base Execution Checklist MUST include ALL numbered steps explicitly.
- The syncing-branch-with-base Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the syncing-branch-with-base Execution Checklist as completed, and display again the syncing-branch-with-base Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the syncing-branch-with-base Execution Checklist remains open.

### 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am syncing the current branch with its base" to inform the USER that you are running this skill.

### 2. Find the base branch name

- By default the base branch name is `main`.
- The base branch name is later referenced as {base_branch}.

### 3. Fetch the base branch from the github remote

- ALWAYS use `cli: git fetch --all` to retrieve the GitHub remote's base branch.

### 4. Rebase the branch

- ALWAYS use `cli: git rebase github/{base_branch}` to bring your branch on top of its base as on the GitHub remote.
- NEVER use `cli: git merge`.
- ALWAYS fix any conflict you see during the rebase, and continue the rebase using `cli: git rebase --continue` until all your commits have been rebased properly.
- If you don't know how to solve a conflict, ALWAYS use `agent: ask_followup_question` to ask the USER to help you solve the git conflict.

### 5. Push the rebased branch

- ALWAYS push your rebased branch to GitHub using the `--force-with-lease` option: `cli: git push github --force-with-lease`.
- If the push with `--force-with-lease` option failed, ALWAYS use `agent: ask_followup_question` to ask the USER to help you solve the issue. It could be that another user contributed to the branch.

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the syncing-branch-with-base Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
