---
name: syncing-branch-with-base
description: Syncs the current branch with its base. Use when the base branch of the current branch may have diverged and you want to be sure that the current branch gets all latest changes of its base. This Skill is the canonical way to keep a branch up-to-date with its base. It must be used instead of merging the base branch, and always performs a rebase.
---

# Syncing branch with base

When syncing the current branch on its base, follow these steps.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am syncing the current branch with its base".

## 2. Find the base branch name

- By default the base branch name is `main`.
- The base branch name is later referenced as {base_branch}.

## 3. Fetch the base branch from the github remote

- ALWAYS use `cli: git fetch --all` to retrieve the github remote's base branch.

## 4. Rebase the branch

- ALWAYS use `cli: git rebase github/{base_branch}` to bring your branch on top of its base as on the github remote.
- NEVER use `cli: git merge`.
- ALWAYS fix any conflict you see during the rebase, and continue the rebase using `cli: git rebase --continue` until all your commits have been rebased properly.
- If you don't know how to solve a conflict, ALWAYS use `agent: ask_followup_question` to ask the USER to help you solve the git conflict.

## 5. Push the rebased branch

- ALWAYS push your rebased branch to github using the `--force-with-lease` option: `cli: git push github --force-with-lease`.
- If the push with `--force-with-lease` option failed, ALWAYS use `agent: ask_followup_question` to ask the USER to help you solve the issue. It could be that another user contributed to the branch.
