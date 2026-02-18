---
name: committing-changes
description: Commits changes and pushes them on GitHub. What this does is stage relevant files, create a git commit and push it on Github. Use this when development and testing has been done and changes are ready to be committed and pushed to GitHub.
---

# Committing changes

## Sequential steps to be followed when using this skill

When committing changes, follow those steps.

### Create the committing-changes Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named committing-changes Execution Checklist with ALL steps of this skill.
- The committing-changes Execution Checklist MUST include ALL numbered steps explicitly.
- The committing-changes Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the committing-changes Execution Checklist as completed, and display again the committing-changes Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the committing-changes Execution Checklist remains open.

### 1. Inform the USER

- ALWAYS tell the USER "SKILL: I am committing changes" to inform the USER that you are running this skill.

### 2. Stage all the files that should be part of the commit

- Identify all the files that make sense to commit altogether as part of 1 commit.
- ALWAYS use `cli: git add {file1} {file2} ... {fileN}` to stage those identified files.
- NEVER use `cli: git add --all`, because some files may be modified by the USER and should not be part of your commit.

Example:
```bash
git add lib/my_lib/my_class.rb README.md
```

### 3. Create a temporary file with the commit description

- Devise a meaningful commit comment that summarizes the changes you are going to commit.
- ALWAYS use `agent: write_to_file` tool to write the commit comment in a temporary file (later referenced as {description_file}), inside the directory `./.tmp_agents/commits`.

### 4. Create the commit

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS use `cli: ruby {skill_path}/scripts/commit {description_file}` to create the git commit.
- NEVER use `cli: git commit` directly.

Example:
```bash
ruby .cline/skills/committing-changes/scripts/commit ./.tmp_agents/commits/commit_desc.txt
```

### 5. Delete the temporary commit description file

- ALWAYS delete the temporary description file {description_file} once the git commit has been done.

Example:
```bash
rm ./.tmp_agents/commits/commit_desc.txt
```

### 6. Push this commit on GitHub

- ALWAYS use `cli: git push github` to push the commit on GitHub.

Example:
```bash
git push github
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the committing-changes Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- You MUST use it every time the USER asks you to commit your changes.
- You MUST use it every time another skill specifically mentions `skill: committing-changes`.
- You can use it every time you need to commit your changes.

## Usage and code examples

Those examples are given for a Linux environment. Adapt them if you are running in a Windows environment.

### When project code, docs and tests were modified

If you modified `lib/my_lib/my_class.rb`, `README.md` and `spec/scenarios/my_tests.rb` files for the task, this skill should perform the following commands:
```bash
git add lib/my_lib/my_class.rb README.md spec/scenarios/my_tests.rb
# Use agent tool write_to_file to create file ././.tmp_agents/commits/commit_desc.txt
ruby {skill_path}/scripts/commit ././.tmp_agents/commits/commit_desc.txt
rm ././.tmp_agents/commits/commit_desc.txt
git push github
```
