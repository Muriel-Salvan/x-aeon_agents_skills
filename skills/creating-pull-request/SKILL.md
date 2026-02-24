---
name: creating-pull-request
description: Creates a Pull Request for the current git branch on GitHub. Use this when a Pull Request needs to be created to track the current feature branch changes on GitHub.
---

# Creating a Pull Request

## Sequential steps to be followed when using this skill

When creating a Pull Request, follow those steps.

### Create the creating-pull-request Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named creating-pull-request Execution Checklist with all steps of this skill.
- The creating-pull-request Execution Checklist must include all numbered steps explicitly.
- The creating-pull-request Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the creating-pull-request Execution Checklist as completed, and display again the creating-pull-request Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the creating-pull-request Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am creating a Pull Request" to inform the user that you are running this skill.

### 2. Ask the user about additional list of GitHub issues linked to this Pull Request

- Always use `agent: ask_followup_question` to ask the user which GitHub issues are closed by or related to this Pull Request, even if you know of some of those issues already. There could be more GitHub issues that you are not aware of.

### 3. Devise the list of GitHub issues linked to this Pull Request

- Use the information from all the user prompts to know which additional issues are closed by or related to this Pull Request.

### 4. Create a temporary file with a good description for the Pull Request

- Always devise a meaningful Pull Request description for all the changes that you have in the current branch, and for the task you want to achieve in this branch.
- Always add a section in the Pull Request description that lists all GitHub issues closed by or related to this Pull Request (devised in step 2), with mentions like "Closes #{issue_id}" or "Relates to #{issue_id}".
- Always add a section in the Pull Request description that contains the exact initial prompt of the user for this task, and all user inputs or precisions that you have received from the user while implementing the task.
- Always use `agent: write_to_file` tool to write the devised Pull Request description in a temporary file (later referenced as {pr_description_file}), inside the directory `./.tmp_agents/prs`.

Example of a Pull Request description:
```markdown
This PR implements conditional debug logging in STDOUT.

## Changes

- Modified `lib/my_class.rb` to check for `DEBUG=1` environment variable.
- Updated `README.md` with instructions on how to use the new debugging feature.

## Related Issues

- Closes #29
- Relates to #28

## Original Request

> Add support to debug mode to implement issue 29.
> No need to modify the tests.
```

### 5. Create the Pull Request between the current branch and main

- Find this skill directory path, later referenced as {skill_path}.
- Always devise a meaningful title for this Pull Request, later references as {pr_title}.
- Always use `cli: ruby {skill_path}/scripts/create_pr {pr_title} {pr_description_file}` to create the Pull Request.
- Never use `cli: gh` directly to create Pull Requests; the script wrapper must be used to handle multiline descriptions and append the AI agent signature to the Pull Request description.

Example:
```bash
ruby .cline/skills/creating-pull-request/scripts/create_pr "Add support for debug mode in CLI arguments" ./.tmp_agents/prs/pr_desc.txt
```

### 6. Delete the temporary description file

- Always delete the temporary description file {pr_description_file} once the Pull Request has been created.

Example:
```bash
rm ./.tmp_agents/prs/pr_desc.txt
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the creating-pull-request Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- Always use it every time another skill specifically mentions `skill: creating-pull-request`.
- Always use it every time the user asks you to create a Pull Request.
- Always use it every time you need to create a Pull Request.

## Usage and code examples

Those examples are given for a Linux environment. Adapt them if you are running in a Windows environment.

### Creating a Pull Request for a branch already pushed

This skill should perform the following commands:
```bash
# Use agent tool ask_followup_question to ask the user about GitHub issue numbers that relate to this Pull Request
# Use agent tool write_to_file to create file ././.tmp_agents/prs/pr_desc.txt
ruby .cline/skills/creating-pull-request/scripts/create_pr "Add support for debug mode in CLI arguments" ./.tmp_agents/prs/pr_desc.txt
rm ./.tmp_agents/prs/pr_desc.txt
```
