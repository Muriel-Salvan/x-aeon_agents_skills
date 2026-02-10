---
name: committing-changes
description: Commits changes and pushes them on Github. Use when development and testing has been done and changes are ready to be committed and pushed to Github.
---

# Committing changes

When committing changes, follow those steps.

## 1. Inform the USER

- You MUST inform the user that you are running this skill, saying "SKILL: I am committing changes".

## 2. Stage all the files that should be part of the commit

- Identify all the files that make sense to commit altogether as part of 1 commit.
- Add those identified files using `git add <file1> <file2> ... <fileN>`.

## 3. Create a temporary file with the commit description

- Devise a meaningful commit comment, and write it in a temporary file (later referenced as {{description_file}}), inside the directory `./tmp`.

## 4. Create the commit

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS create a git commit using `ruby {skill_path}/scripts/commit {description_file}`.
- NEVER use `git commit` directly.
- Delete the temporary description file {description_file} once the git commit has been done.

## 5. Push this commit on Github

- Push the commit on Github using `git push github`.

## 6. Make sure a Pull Request is created for the current branch

- Check on the Github project if there is already a Pull Request created for the current branch.
- If there isn't any Pull Request for the current branch, create one.
