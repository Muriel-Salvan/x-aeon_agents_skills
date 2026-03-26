# X-Aeon Agents skills

This repository defines a set of AI agents skills that are used for X-Aeon projects.

## Ways skills are written

* Follow guidelines from the following sources:
  * [agentskills.io](https://agentskills.io/specification)
  * [Claude code best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
* Help agents follow those skills and their steps by using the following guidelines:
  * About skill name and YAML frontmatter:
    * Always name skills using `<verb>[-<object>-[<context>]]`.
    * Use gerund in the skill name.
    * Use third person in the skill description.
    * Always add a `Use when ...` part of the skill description.
  * About skill content:
    * Use Markdown for the skill's content.
    * Use imperative verbs (ex: `Read the README file to know about the CLI usage`).
    * Separate ordered steps in the skill's content using Markdown's headers (ex: `## 5. Perform data analysis`), and give details of this step using bullet points.
    * Don't mix several commands in 1 step. Split steps if several commands are involved.
    * Use `{variable_name}` to identify placeholders.
    * Be clear and consistent about commands: always use backticks to identify a command, and use a prefix for the command type. Here are the prefixes in use:
      * `cli: `: Used for command-line tools. Ex: ``Use `cli: ls -la` to list all the files``.
      * `agent: `: Used for agent commands. Ex: ``Use `agent: ask_followup_question` to ask the USER about the intent``.
      * `skill: `: Used for skills. Ex: ``Use `skill: creating-pull-request` to create the PR for {branch}``.
    * Don't use capital wordings as it adds emotional noise and is different from non-capitalized tokens used during LLMs training.
    * Use some wording in a consistent way. Those words are inspired by https://github.com/rohitg00/skillkit/blob/39b94534ec1c3698c0dec3a005744dafa99e63e9/packages/core/src/quality/index.ts
      * `User` represents the developer asking the agent to perform a task.
      * `Always` is used to emphasize that a specific step is mandatory (ex.: ``Always use `cli: gh` to gather issue information``).
      * `Never` is used to emphasize that a specific step should never be done (ex.: ``Never use `cli: gh` to create a PR``).
      * `If` ... `then` ... `else` are used to clearly identify some branching decisions.
      * `Plan` and `Act` modes refer to precisely the 2 ways of executing skills by the agents.
  * About skill semantics:
    * A skill is better followed when it consists only in a sequence of easily identified steps (like a workflow). Don't use vague guidelines in a skill.
    * When another skill is performing a sub-task of your skill, reference it explicitely, like ``Use `skill: skill_name` to perform this action`` instead of `Perform this action`. Don't rely on the model understanding that `skill_name` was the right skill to perform the action.
    * Always ask the agent to inform the user about executing the skill.
    * Any step that can be coded and automated with a tool should be implemented in a tool. Never rely on the guarantee that models will follow steps, unless they are implemented in a tool.

## General principles

Those principles allow for a safe agent interaction, while keeping its agility.

* The user sets the branch for the agent, in a worktree.
* Agents should never switch branches.
* Agents automatically push their changes to the github remote, and create a Pull Request for their branch.
* Agents can rebase their branch.

## Generating skills from ERB templates

Some skills are written as ERB templates (files ending with `.erb`) to allow dynamic content generation. To generate the final skill files from these templates, run the following executable:

```bash
bundle exec ruby bin/generate_skills
```

This will:
- Find all `.erb` files in the `skills/` directory
- Process them using the ERB engine (with `XAeonAgentsSkills::GenHelpers` available)
- Generate the corresponding output files (removing the `.erb` extension)

The following helper methods are available in ERB templates:
- `XAeonAgentsSkills::GenHelpers.init_skill_checklist` - Returns the "Create Execution Checklist (MANDATORY)" section
- `XAeonAgentsSkills::GenHelpers.validate_skill_checklist` - Returns the "Final Verification (MANDATORY)" section

## Addressing Pull Request Comments

The `address_pull_request_comments` CLI tool provides functionality to automatically address comments made on GitHub Pull Requests. This tool:

- Fetches unresolved PR comments using the `check_unresolved_pr_comments` script
- Identifies comments directed at the agent (starting with `/agent`)
- Processes each comment to determine if code changes are needed
- Implements required changes following project conventions
- Generates appropriate replies to each comment
- Uses the `reply_to_comment` script to post responses

### Code Documentation

The `address_pull_request_comments` method in `lib/x-aeon_agents_skills/agents.rb` uses the "aprc" prefix in its step names, which stands for "Address Pull Request Comments". This prefix helps organize and identify the sequential steps involved in the PR comment addressing workflow:

- `aprc_a_gather_comments`: Gather and analyze PR comments directed at the agent
- `aprc_b_extract_requirements`: Extract actionable requirements from agent-directed comments  
- `aprc_c_reply_to_comment`: Generate and post replies to each processed comment

Each step is clearly documented with inline comments explaining its purpose and functionality within the overall workflow.

### Usage

To address PR comments, use the following workflow:

```bash
# 1. Get comments
ruby .cline/skills/addressing-pull-request-comments/scripts/check_unresolved_pr_comments

# 2. For each unanswered comment starting with `/agent`:
# 2.1. Apply necessary code changes if needed
# 2.2. Create .x-aeon_agents/tmp/replies/comment_1234567_reply.md with the appropriate reply
# 2.3. Reply to the comment
ruby .cline/skills/addressing-pull-request-comments/scripts/reply_to_comment 3 1234567 .x-aeon_agents/tmp/replies/comment_1234567_reply.md
```

The skill automatically handles the complete workflow from comment detection to response generation and posting.

## License

See [LICENSE file](LICENSE).
