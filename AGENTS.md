# Skills System

<!-- SKILLKIT_SKILLS_START -->

## Available Skills

- **addressing-pull-request-comments**: Addresses comments made on the GitHub Pull Request tracking changes of the current branch. What this does is read all Pull Requests comments addressed to the agent, improve or fix the code based on those comments, and reply too each one of those comments. Use this when the user is asking you to address the comments made on the current branch's Pull Request. Use this skill also in Plan mode.
- **analyzing-github-issue**: Analyzes requirements described in a GitHub issue. What this does is read the GitHub issue content and devise an implementation plan. Use this when the user is asking you to analyze a GitHub issue or get requirements from it. Use this skill also in Plan mode.
- **applying-ruby-conventions**: Applies idiomatic Ruby conventions, structure, and best practices when writing or modifying Ruby code. What this does is defining a set of rules to follow when dealing with any Ruby file. Use this when the user is asking to create, edit, refactor, or review Ruby files or when the project contains Ruby source code. Use this skill also in Plan mode.
- **applying-test-conventions**: Applies idiomatic test conventions, structure, and best practices when writing or modifying unit tests. What this does is defining a set of rules to follow when dealing with any test file. Use this when the user is asking to create, edit, refactor, or review test files or when the project contains test scenarios. Use this skill also in Plan mode.
- **committing-changes**: Commits changes and pushes them on GitHub. What this does is stage relevant files, create a git commit and push it on GitHub. Use this when development and testing has been done and changes are ready to be committed and pushed to GitHub.
- **creating-pull-request**: Creates a Pull Request for the current git branch on GitHub. Use this when a Pull Request needs to be created to track the current feature branch changes on GitHub.
- **editing-files**: Edits text files of any kind. What this does is defining a set of rules to follow when editing or creating any file. Use this when the user is asking to create or edit any file or when you need to create or edit files.
- **enforcing-project-rules**: Enforces project-level operational rules that govern how the agent interacts with the workspace, CLI, and version control. What this does is enumerating governance rules that you should always follow when working in a project. Use this in ALL tasks executed inside a repository to ensure compliance with project constraints such as working directory rules and git branch restrictions. Use this skill also in Plan mode.
- **implementing-github-issue**: Implements what is described in a GitHub issue. What this does is first devise an implementation plan from the issue, execute the plan and validate production qualiy gates. Use this when the user is asking you to implement a GitHub issue. Use this skill also in Plan mode.
- **improving-agent-reflection**: Proposes focused, high-value improvements to your active rules and skills. What this does is reflect on the user feedback and guidance, then suggests changes in Cline rules and skills. Use this when you are about to complete a task that involved user feedback provided at any point during the conversation, or involved multiple non-trivial steps (e.g., multiple file edits, complex logic generation).
- **running-cli-in-wsl-portable**: Runs Bash command lines in a Portable installation under WSL. What this does is execute the command line inside a Portable bash installation in WSL. Use this when a command line should be run under a WSL portable environment.
- **syncing-branch-with-base**: Syncs the current branch with its base. What this does is check the remote base branch, rebase the current one on the updated base and push it back to the remote. Use this when the base branch of the current branch may have diverged and you want to be sure that the current branch gets all latest changes of its base. This Skill is the canonical way to keep a branch up-to-date with its base. It must be used instead of merging the base branch, and always performs a rebase.
- **updating-doc**: Update the documentation of the project. What this does is update the README file of the project, its CLI usage and its Table of Content. Use this when a new development has been completed or when the user is asking for documentation or README to be updated.
- **validating-production-quality**: Validates that the task is following all production-grade quality checks. What this does is check for regressions, update documentation, update the branch on the latest base, commit any remaining changes, push them on GitHub and create a Pull Request. Use this when attempting task completion on a task or when the user asks for validating production qulity gates.

## How to Use Skills

When a task matches one of the available skills, load it to get detailed instructions:

```bash
skillkit read <skill-name>
```

Or with npx:

```bash
npx skillkit read <skill-name>
```

## Skills Data

<skills_system>
<usage>
Skills provide specialized capabilities and domain knowledge.
- Invoke: `skillkit read <skill-name>`
- Base directory provided in output for resolving resources
- Only use skills listed below
- Each invocation is stateless
</usage>

<available_skills>

<skill>
<name>addressing-pull-request-comments</name>
<description>Addresses comments made on the GitHub Pull Request tracking changes of the current branch. What this does is read all Pull Requests comments addressed to the agent, improve or fix the code based on those comments, and reply too each one of those comments. Use this when the user is asking you to address the comments made on the current branch&apos;s Pull Request. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>analyzing-github-issue</name>
<description>Analyzes requirements described in a GitHub issue. What this does is read the GitHub issue content and devise an implementation plan. Use this when the user is asking you to analyze a GitHub issue or get requirements from it. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>applying-ruby-conventions</name>
<description>Applies idiomatic Ruby conventions, structure, and best practices when writing or modifying Ruby code. What this does is defining a set of rules to follow when dealing with any Ruby file. Use this when the user is asking to create, edit, refactor, or review Ruby files or when the project contains Ruby source code. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>applying-test-conventions</name>
<description>Applies idiomatic test conventions, structure, and best practices when writing or modifying unit tests. What this does is defining a set of rules to follow when dealing with any test file. Use this when the user is asking to create, edit, refactor, or review test files or when the project contains test scenarios. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>committing-changes</name>
<description>Commits changes and pushes them on GitHub. What this does is stage relevant files, create a git commit and push it on GitHub. Use this when development and testing has been done and changes are ready to be committed and pushed to GitHub.</description>
<location>project</location>
</skill>

<skill>
<name>creating-pull-request</name>
<description>Creates a Pull Request for the current git branch on GitHub. Use this when a Pull Request needs to be created to track the current feature branch changes on GitHub.</description>
<location>project</location>
</skill>

<skill>
<name>editing-files</name>
<description>Edits text files of any kind. What this does is defining a set of rules to follow when editing or creating any file. Use this when the user is asking to create or edit any file or when you need to create or edit files.</description>
<location>project</location>
</skill>

<skill>
<name>enforcing-project-rules</name>
<description>Enforces project-level operational rules that govern how the agent interacts with the workspace, CLI, and version control. What this does is enumerating governance rules that you should always follow when working in a project. Use this in ALL tasks executed inside a repository to ensure compliance with project constraints such as working directory rules and git branch restrictions. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>implementing-github-issue</name>
<description>Implements what is described in a GitHub issue. What this does is first devise an implementation plan from the issue, execute the plan and validate production qualiy gates. Use this when the user is asking you to implement a GitHub issue. Use this skill also in Plan mode.</description>
<location>project</location>
</skill>

<skill>
<name>improving-agent-reflection</name>
<description>Proposes focused, high-value improvements to your active rules and skills. What this does is reflect on the user feedback and guidance, then suggests changes in Cline rules and skills. Use this when you are about to complete a task that involved user feedback provided at any point during the conversation, or involved multiple non-trivial steps (e.g., multiple file edits, complex logic generation).</description>
<location>project</location>
</skill>

<skill>
<name>running-cli-in-wsl-portable</name>
<description>Runs Bash command lines in a Portable installation under WSL. What this does is execute the command line inside a Portable bash installation in WSL. Use this when a command line should be run under a WSL portable environment.</description>
<location>project</location>
</skill>

<skill>
<name>syncing-branch-with-base</name>
<description>Syncs the current branch with its base. What this does is check the remote base branch, rebase the current one on the updated base and push it back to the remote. Use this when the base branch of the current branch may have diverged and you want to be sure that the current branch gets all latest changes of its base. This Skill is the canonical way to keep a branch up-to-date with its base. It must be used instead of merging the base branch, and always performs a rebase.</description>
<location>project</location>
</skill>

<skill>
<name>updating-doc</name>
<description>Update the documentation of the project. What this does is update the README file of the project, its CLI usage and its Table of Content. Use this when a new development has been completed or when the user is asking for documentation or README to be updated.</description>
<location>project</location>
</skill>

<skill>
<name>validating-production-quality</name>
<description>Validates that the task is following all production-grade quality checks. What this does is check for regressions, update documentation, update the branch on the latest base, commit any remaining changes, push them on GitHub and create a Pull Request. Use this when attempting task completion on a task or when the user asks for validating production qulity gates.</description>
<location>project</location>
</skill>

</available_skills>
</skills_system>

<!-- SKILLKIT_SKILLS_END -->
