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
    * Use `{variable_name}` to identify placeholders.
    * Be clear and consistent about commands: always use backticks to identify a command, and use a prefix for the command type. Here are the prefixes in use:
      * `cli: `: Used for command-line tools. Ex: ``Use `cli: ls -la` to list all the files``.
      * `agent: `: Used for agent commands. Ex: ``Use `agent: ask_followup_question` to ask the USER about the intent``.
      * `skill: `: Used for skills. Ex: ``Use `skill: creating-pull-request` to create the PR for {branch}``.
    * Use some capital words in a consistent way:
      * `USER` represents the developer asking the agent to perform a task.
      * `ALWAYS` is used to emphasize that a specific step is mandatory (ex.: ``ALWAYS use `cli: gh` to gather issue information``).
      * `NEVER` is used to emphasize that a specific step should never be done (ex.: ``NEVER use `cli: gh` to create a PR``).
  * About skill semantics:
    * A skill is better followed when it consists only in a sequence of easily identified steps (like a workflow). Don't use vague guidelines in a skill.
    * When another skill is performing a sub-task of your skill, reference it explicitely, like ``Use `skill: skill_name` to perform this action`` instead of `Perform this action`. Don't rely on the model understanding that `skill_name` was the right skill to perform the action.
    * Always ask the agent to inform the user about executing the skill.

## General principles

Those principles allow for a safe agent interaction, while keeping its agility.

* The USER sets the branch for the agent, in a worktree.
* Agents should never switch branches.
* Agents automatically push their changes to the github remote, and create a Pull Request for their branch.
* Agents can rebase their branch.

## License

See [LICENSE file](LICENSE).
