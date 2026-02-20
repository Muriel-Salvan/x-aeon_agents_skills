---
name: syncing-branch-with-base
description: Syncs the current branch with its base. What this does is check the remote base branch, rebase the current one on the updated base and push it back to the remote. Use this when the base branch of the current branch may have diverged and you want to be sure that the current branch gets all latest changes of its base. This Skill is the canonical way to keep a branch up-to-date with its base. It must be used instead of merging the base branch, and always performs a rebase.
---

# Syncing the current branch with its base

## Sequential steps to be followed when using this skill

When syncing the current branch with its base, follow those steps.

### Create the syncing-branch-with-base Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named syncing-branch-with-base Execution Checklist with all steps of this skill.
- The syncing-branch-with-base Execution Checklist must include all numbered steps explicitly.
- The syncing-branch-with-base Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the syncing-branch-with-base Execution Checklist as completed, and display again the syncing-branch-with-base Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the syncing-branch-with-base Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am syncing the current branch with its base" to inform the user that you are running this skill.

### 2. Find the base branch name

- By default the base branch name is `main`.
- The base branch name is later referenced as {base_branch}.

### 3. Fetch the base branch from the github remote

- Always use `cli: git fetch --all` to retrieve the GitHub remote's base branch.

Example:
```bash
git fetch --all
```

### 4. Rebase the branch

- Always use `cli: git rebase github/{base_branch}` to bring your branch on top of its base as on the GitHub remote.
- Never use `cli: git merge`.
- Always fix any conflict you see during the rebase, and continue the rebase using `cli: git rebase --continue` until all your commits have been rebased properly.
- If you don't know how to solve a conflict, then always use `agent: ask_followup_question` to ask the user to help you solve the git conflict.

Example:
```bash
git rebase github/main
# Fix potential conflicts in files
git rebase --continue
# Use agent tool ask_followup_question about new potential conflicts that you don't understand how to solve
git rebase --continue
```

### 5. Push the rebased branch

- Always push your rebased branch to GitHub using the `--force-with-lease` option: `cli: git push github --force-with-lease`.
- If the push with `--force-with-lease` option failed, then always use `agent: ask_followup_question` to ask the user to help you solve the issue. It could be that another user contributed to the branch.

Example:
```bash
git push github --force-with-lease
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the syncing-branch-with-base Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- Always use it every time the user asks you to sync the branch with its base.
- Always use it every time another skill specifically mentions `skill: syncing-branch-with-base`.
- Use it every time you realize the base branch has divereged and you want to get the current branch up-to-date with its base.

## Usage and code examples

Those examples are given for a Linux environment. Adapt them if you are running in a Windows environment.

### Syncing the branch on main when there are not conflicts

```bash
git fetch --all
git rebase github/main
git push github --force-with-lease
```

### Syncing the branch on main when there are some conflicts on *.rb files that you can solve by yourself

```bash
git fetch --all
git rebase github/main
# Solve conflicts on *.rb files
git rebase --continue
git push github --force-with-lease
```

### Syncing the branch on main when there are some conflicts on *.rb files that you can't solve by yourself

```bash
git fetch --all
git rebase github/main
# Use agent tool ask_followup_question about new potential conflicts that you don't understand on *.rb
git rebase --continue
git push github --force-with-lease
```
