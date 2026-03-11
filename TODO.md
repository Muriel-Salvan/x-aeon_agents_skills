* Make the WSL CLI tool a Ruby script to avoid paths and slashes issues
* The model reported is wrong. Fix this.
* The list of rules should also have a checklist. We see that some of them are missed. It should report a summary of all the rules it has read.
* Remove the editing-files skill. We should use linters to check for missing lines, and Cline should be intelligent enough to catch missed edits (anyway those should go away soon).
* Remove the semilinearity check: it should be in tests.
* Consider removing the analyzing-github-issue skill: models know how to do it
* Consider using short tasks instead of full skills, orchestrated by a tool that would use the cline CLI and memory banks for context kept between tasks. For example:
  * 1 task for planning
  * 1 task for implementation
  * 1 task for testing
  * 1 task for updating doc
  * 1 task for commiting + rebasing + pushing
  * 1 task for creating PR
  Goal would be to reduce the amount of skills or rules each task needs, so that it gets focused on what it needs to do given previous context.
  Each task could even be performed by different models, and in parallel
* Write a proper README file.
* Use templates to better guide the format of commit comments and PR descriptions.
* Extract the generate_skills executable into a generic Rubygem that generates skills following agents best practices
* Add a conventions skill that explains conventions used:
  * Commands with skill/agent/cli prefixes.
* Ideas for blog post:
  * Very difficult to evaluate model's accuracy as it changes a lot over short periodes of time (cf the monitoring site).
    * Even 2 prompts right one after another can have very different results: 1 follows skills, the other not.
    * Make sure tools are working perfectly: when they are not the agent will try plenty of workarounds and that will contribute A LOT to context dilution later.
  * Repeatitive safe guard rails on check lists and validations, hence need for prompt generation and optimization.
  * If it can be technically automated in a script, do it. Leave prompts for things that depend on context or on reasoning decisions.
  * Better results under Linux envs: models were trained like taht and their default conventions or CLI will often be Linux based, even if they can later correct for Windows.
  * Use Plan and Act modes.
  * Different models have different behaviors: well-formed prompts are very important but even when it is well written, some models won't follow prompt instructions, especially when those instructions become large (like test + doc + commit + push).
  * For Cline, there is no need for double checks (upon completion) when models are good. That can reduce tokens usage.
  * Better to replace existing default tools than having wrappers: if we want a different CLI than rspec, better to have a rspec tool in PATH that wraps the real rspec than having a rspec_wrapper tool.
  * Models get lose a lot of accuracy between versions (example gpt-5.3-codex is much worse than gpt-5.2-codex).
  * Models are good at performing small tasks, not huge workflows. We need workflows orchestrators handling context and memory.
* Check anthropic's skill-creator skill: https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
* Check security warnings that we got from installation and fix them.
* Move the Cline Ruby connector into a Rubygem.
