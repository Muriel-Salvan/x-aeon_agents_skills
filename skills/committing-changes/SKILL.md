---
name: committing-changes
description: Commits changes and pushes them on GitHub. Use when development and testing has been done and changes are ready to be committed and pushed to GitHub.
---

# Committing changes

When committing changes, follow those steps.

## Create the committing-changes Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named committing-changes Execution Checklist with ALL steps of this skill.
- The committing-changes Execution Checklist MUST include ALL numbered steps explicitly.
- The committing-changes Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the committing-changes Execution Checklist as completed, and display again the committing-changes Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the committing-changes Execution Checklist remains open.


## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am committing changes".

## 2. Stage all the files that should be part of the commit

- Identify all the files that make sense to commit altogether as part of 1 commit.
- ALWAYS use `cli: git add <file1> <file2> ... <fileN>` to stage those identified files.
- NEVER use `cli: git add --all`, because some files may be modified by the USER and should not be part of your commit.

## 3. Create a temporary file with the commit description

- Devise a meaningful commit comment that summarizes the changes you are going to commit.
- ALWAYS write the commit comment in a temporary file (later referenced as {description_file}), inside the directory `./tmp/commits`.

## 4. Create the commit

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use `cli: ruby {skill_path}/scripts/commit {description_file}` to create the git commit.
- NEVER use `cli: git commit` directly.
- ALWAYS delete the temporary description file {description_file} once the git commit has been done.

## 5. Push this commit on GitHub

- ALWAYS use `cli: git push github` to push the commit on GitHub.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the committing-changes Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

