* Make the current rules as part of a skill.
* Make the tmp folder location part of an ERB helper.
* Write a proper README file.
* Use templates to better guide the format of commit comments and PR descriptions.
* Add the reviewing PR skills.
* Extract the generate_skills executable into a generic Rubygem that generates skills following agents best practices
* Add Ruby rules:
  - NEVER add frozen_string_literal comment in files.
* In the update doc skill, don't ask anymore to check for TOC updates outside the task scope.
* In the PR and commits skills: make deletion of temp files a full step.
* In the PR and commits skills: precise the exact tool write_to_file to generate the files so that they don't try CLI generation.
* In the implement-github-issue skill, make it clear that first 4 sections are to be executed in PLAN mode. Naybe come up with skills that are PLAN mode only?
* Add a conventions skill that explains conventions used:
  * Commands with skill/agent/cli prefixes.
* In the validate production skill, move the semilinearity check in a step in itself.
* In all skills: the inform the user should mention the tool to be used instead of "say".
* Ideas for blog post:
  * Very difficult to evaluate model's accuracy as it changes a lot over short periodes of time (cf the monitoring site).
  * Repeatitive safe guard rails on check lists and validations, hence need for prompt generation and optimization.
  * If it can be technically automated in a script, do it. Leave prompts for things that depend on context or on reasoning decisions.
  * Better results under Linux envs: models were trained like taht and their default conventions or CLI will often be Linux based, even if they can later correct for Windows.
  * Use Plan and Act modes.
  * Different models have different behaviors: well-formed prompts are very important but even when it is well written, some models won't follow prompt instructions, especially when those instructions become large (like test + doc + commit + push).
* Check anthropic's skill-creator skill: https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
