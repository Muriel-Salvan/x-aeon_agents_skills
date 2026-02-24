---
name: editing-files
description: Edits text files of any kind. What this does is defining a set of rules to follow when editing or creating any file. Use this when the user is asking to create or edit any file or when you need to create or edit files.
---

# Editing files

## Inform the user

- Always tell the user "SKILL: I am editing files" to inform the user that you are running this skill.

## Rules to be followed when editing files

- Always end any text file with an empty line.
  For example, avoid this:
  ```ruby
  puts 'Hello World'```
  Prefer this:
  ```ruby
  puts 'Hello World'
  ```

- When editing big files, `agent: replace_in_file` tool may not work properly.
  Always check that the file is containing the edits you expect.
  If the edits were not performed, then always use `agent: write_in_file` with the whole file's content.

## When to use it

- Always use it every time another skill specifically mentions `skill: editing-files`.
- Always use it every time the user asks you to create or edit a file.
- Always use it every time you need to create or edit a file.
