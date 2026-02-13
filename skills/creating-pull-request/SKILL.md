---
name: creating-pull-request
description: Creates a Pull Request for the current git branch on GitHub. Use when a Pull Request needs to be created to track the current feature branch changes on GitHub.
---

# Creating a Pull Request

When creating a Pull Request, follow those steps.

## Create the creating-pull-request Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named creating-pull-request Execution Checklist with ALL steps of this skill.
- The creating-pull-request Execution Checklist MUST include ALL numbered steps explicitly.
- The creating-pull-request Execution Checklist MUST be displayed to the USER.
- After completing each step of this skill, mark the item in the creating-pull-request Execution Checklist as completed, and display again the creating-pull-request Execution Checklist to the USER.
- Do NOT skip any item.
- If an item cannot be executed, explicitly explain why.
- NEVER mark the skill as completed while any item from the creating-pull-request Execution Checklist remains open.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am creating a Pull Request".

## 2. Devise the list of GitHub issues linked to this Pull Request

- ALWAYS use `agent: ask_followup_question` to ask the USER which GitHub issues are closed by or related to this Pull Request, even if you know of some of those issues already. There could be more GitHub issues that you are not aware of.
- Also use any information from the previous USER prompts to know which additional issues are closed by or related to this Pull Request.

## 3. Create a temporary file with a good description for the Pull Request

- ALWAYS devise a meaningful Pull Request description for all the changes that you have in the current branch, and for the task you want to achieve in this branch.
- ALWAYS add a section in the Pull Request description that lists all GitHub issues closed by or related to this Pull Request (devised in step 2), with mentions like "Closes #{issue_id}" or "Relates to #{issue_id}".
- ALWAYS add a section in the Pull Request description that contains the exact initial prompt of the USER for this task, and all USER inputs or precisions that you have received from the USER while implementing the task.
- ALWAYS write the devised Pull Request description in a temporary file (later referenced as {pr_description_file}), inside the directory `./tmp/prs`.

## 4. Create the Pull Request between the current branch and main

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS devise a meaningful title for this Pull Request, later references as {pr_title}.
- ALWAYS use `cli: ruby {skill_path}/scripts/create_pr {pr_title} {pr_description_file}` to create the Pull Request.
- NEVER use `cli: gh` directly to create Pull Requests; the script wrapper must be used to handle multiline descriptions and append the AI agent signature to the Pull Request description.
- ALWAYS delete the temporary description file {pr_description_file} once the Pull Request has been created.

## Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the creating-pull-request Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.
