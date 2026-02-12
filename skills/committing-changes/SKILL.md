---
name: committing-changes
description: Commits changes and pushes them on Github. Use when development and testing has been done and changes are ready to be committed and pushed to Github.
---

# Committing changes

When committing changes, follow those steps.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am committing changes".

## 2. Stage all the files that should be part of the commit

- Identify all the files that make sense to commit altogether as part of 1 commit.
- ALWAYS add those identified files using `git add <file1> <file2> ... <fileN>`.
- NEVER use `git add --all`, because some files may be modified by the USER and should not be part of your commit.

## 3. Create a temporary file with the commit description

- Devise a meaningful commit comment that summarizes the changes you are going to commit.
- ALWAYS write the commit comment in a temporary file (later referenced as {description_file}), inside the directory `./tmp/commits`.

## 4. Create the commit

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use the CLI command `ruby {skill_path}/scripts/commit {description_file}` to create the git commit.
- NEVER use `git commit` directly.
- ALWAYS delete the temporary description file {description_file} once the git commit has been done.

## 5. Push this commit on Github

- ALWAYS push the commit on Github using `git push github`.

## 6. Make sure a Pull Request is created for the current branch

- ALWAYS check on the corresponding Github project if there is already a Pull Request created for the current branch.
- If there isn't any Pull Request for the current branch, ALWAYS use the Skill `creating-pull-request` to create one.
