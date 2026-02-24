---
name: enforcing-project-rules
description: Enforces project-level operational rules that govern how the agent interacts with the workspace, CLI, and version control. What this does is enumerating governance rules that you should always follow when working in a project. Use this in ALL tasks executed inside a repository to ensure compliance with project constraints such as working directory rules and git branch restrictions.
---

# Enforcing project rules

## Inform the user

- Always tell the user "SKILL: I am enforcing project rules" to inform the user that you are running this skill.

## Non-negotiable Rules and Constraints to follow (MANDATORY)

### Rule: Execute all CLI commands from the workspace's root directory

#### Example: Incorrect

```bash
cd scripts
./run_tests ../spec/*_spec.rb
```

#### Example: Correct

```bash
./scripts/run_tests spec/*_spec.rb
```

#### Rationale

The API entry points and tools of a repository all have a consistent usage that does not depend on the caller context. Everything starts from the workspace root directory.

### Rule: Use only the git branch that is already checked out

#### Example: Incorrect

```bash
git checkout {another_branch}
git switch {another_branch}
```

#### Rationale

The current branch gives you a safe space to modify files without impacting other branches.

## When to use it

- Always use it every time another skill specifically mentions `skill: enforcing-project-rules`.
- Always use it every time the user asks you to follow project rules.
- Always use it every time you implement a task in a project.
