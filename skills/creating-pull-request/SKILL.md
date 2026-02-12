---
name: creating-pull-request
description: Creates a Pull Request for the current git branch on Github. Use when a Pull Request needs to be created to track the current feature branch changes on Github.
---

# Creating Pull Request

When creating a Pull Request, follow those steps.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am creating a Pull Request on Github".

## 2. Devise the list of Github issues linked to this Pull Request

- ALWAYS ask the USER which Github issues are closed by or related to this Pull Request, even if you know of some of those issues already. There could be more Github issues that you are not aware of.
- Use any information from the previous USER prompts to know which additional issues are closed by or related to this Pull Request.

## 3. Create a temporary file with a good description for the Pull Request

- ALWAYS devise a meaningful Pull Request description for all the changes that you have in the current branch, and for the task you want to achieve in this branch.
- ALWAYS add a section in the Pull Request description that lists all Github issues closed by or related to this Pull Request (devised in step 2), with mentions like "Closes #{issue_id}" or "Relates to #{issue_id}".
- ALWAYS add a section in the Pull Request description that contains the exact initial prompt of the USER for this task, and all USER inputs or precisions that you have received from the USER while implementing the task.
- ALWAYS write the devised Pull Request description in a temporary file (later referenced as {pr_description_file}), inside the directory `./tmp/prs`.

## 4. Create the Pull Request between the current branch and main

- Find this skill directory path, later referenced as {skill_path}.
- ALWAYS devise a meaningful title for this Pull Request, later references as {pr_title}.
- ALWAYS use `cli: ruby {skill_path}/scripts/create_pr {pr_title} {pr_description_file}` to create the Pull Request.
- NEVER use `cli: gh` to create Pull Requests.
- ALWAYS delete the temporary description file {pr_description_file} once the Pull Request has been created.
