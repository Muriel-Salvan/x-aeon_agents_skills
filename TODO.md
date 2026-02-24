* Write a proper README file.
* Use templates to better guide the format of commit comments and PR descriptions.
* Extract the generate_skills executable into a generic Rubygem that generates skills following agents best practices
* Add a conventions skill that explains conventions used:
  * Commands with skill/agent/cli prefixes.
* Ideas for blog post:
  * Very difficult to evaluate model's accuracy as it changes a lot over short periodes of time (cf the monitoring site).
  * Repeatitive safe guard rails on check lists and validations, hence need for prompt generation and optimization.
  * If it can be technically automated in a script, do it. Leave prompts for things that depend on context or on reasoning decisions.
  * Better results under Linux envs: models were trained like taht and their default conventions or CLI will often be Linux based, even if they can later correct for Windows.
  * Use Plan and Act modes.
  * Different models have different behaviors: well-formed prompts are very important but even when it is well written, some models won't follow prompt instructions, especially when those instructions become large (like test + doc + commit + push).
* Check anthropic's skill-creator skill: https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
* Check security warnings that we got from installation and fix them.
