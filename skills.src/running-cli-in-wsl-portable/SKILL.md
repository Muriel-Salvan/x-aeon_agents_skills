---
name: running-cli-in-wsl-portable
description: Runs Bash command lines in a Portable installation under WSL. Use when a command line should be run under a WSL portable environment.
---

# Running CLI in WSL Portable

When running a bash command under a WSL portable environment, follow those steps.
The original bash command to be run is later referenced as {original_cli}.

## 1. Inform the USER

- ALWAYS inform the user that you are running this skill, saying "SKILL: I am running a command under WSL Portable environment".

## 2. Run the command line with the right prefix

- Find this skill directory absolute path, later referenced as {skill_absolute_path}.
- ALWAYS use `cli: {skill_absolute_path}\scripts\wsl_portable_bash.cmd "{original_cli}"`.
