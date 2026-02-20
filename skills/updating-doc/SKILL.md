---
name: updating-doc
description: Update the documentation of the project. What this does is update the README file of the project, its CLI usage and its Table of Content. Use this when a new development has been completed or when the user is asking for documentation or README to be updated.
---

# Updating documentation

## Sequential steps to be followed when using this skill

When updating documentation, follow those steps.

### Create the updating-doc Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named updating-doc Execution Checklist with all steps of this skill.
- The updating-doc Execution Checklist must include all numbered steps explicitly.
- The updating-doc Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the updating-doc Execution Checklist as completed, and display again the updating-doc Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the updating-doc Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am updating documentation" to inform the user that you are running this skill.

### 2. Check the existing README content

- Always read the existing README content and think about which parts of it should be updated with the task you just implemented.
- Always adapt the content to what is relevant for the task you implemented.

For example, if README.md has such a section:
```markdown
## Main features

This executable processes input data files (*.csv) to output statistics.
```
and you just implemented a feature adding a timeout feature,
then you should update this README section like this:
```markdown
## Main features

This executable processes input data files (*.csv) to output statistics.

### 3. Timeout

If processing a file takes more than a given number of seconds, then processing stops and an error is returned (timeout behaviour).
```

### 4. Update the README CLI usage section

- Always check if the real CLI options are documented correctly in the Usage section of the README file.

For example, if README.md has such a section:
```markdown
## CLI options

* `--process FILE`: Specify the file to process
```
and you just implemented a feature adding a CLI timeout option,
then you should update this README section like this:
```markdown
## CLI options

* `--process FILE`: Specify the file to process
* `--timeout SECS`: Specify the number of seconds before processing times out (default: 60)
```

### 5. Update the README table of content

- Devise the hierarchical list of all Markdown headers that are in the README file, of all levels. Don't forget about headers that you may have added in previous steps.
- Always make sure that the section "Table of Contents" of the README file is listing exactly all the headers as local links to their section, and indented in accordance with their hierarchical level in the file.

For example, if README.md has such a section:
```markdown
## Table of Content

- [Main features](#main_features)
- [CLI options](#cli_options)
- [Testing](#testing)
- [License](#license)
```
and you just add a sub-section describing the timeout feature,
then you should update this README section like this:
```markdown
## Table of Content

- [Main features](#main_features)
  - [Timeout](#timeout)
- [CLI options](#cli_options)
- [Testing](#testing)
- [License](#license)
```

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the updating-doc Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## When to use it

- Always use it every time the user asks you to update documentation.
- Always use it every time another skill specifically mentions `skill: updating-doc`.
- Use it every time you think documentation should be updated after implementing some changes in the code or tests.

## Usage and code examples

### Updating various sections of README.md when implementing a timeout feature

If README.md has this content before running this skill:
```markdown
# Data processing

## Table of Content

- [Main features](#main_features)
- [CLI options](#cli_options)
- [Testing](#testing)
- [License](#license)

## Main features

This executable processes input data files (*.csv) to output statistics.

## CLI options

* `--process FILE`: Specify the file to process

## Testing

Run `rspec`.

## License

* BSD.
```
Then README.md should have this kind of content after running this skill:
Before:
```markdown
# Data processing

## Table of Content

- [Main features](#main_features)
  - [Timeout](#timeout)
- [CLI options](#cli_options)
- [Testing](#testing)
- [License](#license)

## Main features

This executable processes input data files (*.csv) to output statistics.

### Timeout

If processing a file takes more than a given number of seconds, then processing stops and an error is returned (timeout behaviour).

## CLI options

* `--process FILE`: Specify the file to process
* `--timeout SECS`: Specify the number of seconds before processing times out (default: 60)

## Testing

Run `rspec`.

## License

* BSD.
```
