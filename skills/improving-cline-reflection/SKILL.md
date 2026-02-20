---
name: improving-cline-reflection
description: 'Improves Cline reflection from user feedback. What this does is reflect on the user feedback and guidance, then suggests changes in Cline rules and skills. Use this when you are using `agent: attempt_completion` tool for any task that involved user feedback provided at any point during the conversation, or involved multiple non-trivial steps (e.g., multiple file edits, complex logic generation).'
---

# Improving Cline reflection

Offer opportunities to continuously improve `.clinerules` and skills, based on user interactions and feedback.

## Sequential steps to be followed when using this skill

When improving Cline reflection, follow those steps.

### Create the improving-cline-reflection Execution Checklist (MANDATORY)

- Before executing anything, create a checklist named improving-cline-reflection Execution Checklist with all steps of this skill.
- The improving-cline-reflection Execution Checklist must include all numbered steps explicitly.
- The improving-cline-reflection Execution Checklist must be displayed to the user.
- After completing each step of this skill, mark the item in the improving-cline-reflection Execution Checklist as completed, and display again the improving-cline-reflection Execution Checklist to the user.
- Do not skip any item.
- If an item cannot be executed, explicitly explain why.
- Never mark the skill as completed while any item from the improving-cline-reflection Execution Checklist remains open.

### 1. Inform the user

- Always tell the user "SKILL: I am improving Cline reflection" to inform the user that you are running this skill.

### 2. Offer Reflection

- Always use `agent: ask_followup_question` to ask the user: "Before I complete the task, would you like me to reflect on our interaction and suggest potential improvements to the active `.clinerules` and skills?"
- Skip all remaining steps of this skill if the user declines or doesn't respond affirmatively.

### 3. If User Confirms

- If the user confirmed, perform the following steps.

#### 3.1. Review Interaction

- Synthesize all feedback provided by the user throughout the entire conversation history for the task.
- Analyze how this feedback relates to the active `.clinerules` and skills, and identify areas where modified instructions could have improved the outcome or better aligned with user preferences.

#### 3.2. Identify Active Skills and Rules

- List the specific skills and Cline rules that were active during the task.
- Report this list to the user.

#### 3.3. Formulate & Propose Improvements

- Generate specific, actionable suggestions for improving the *content* of the relevant active rule files.
- Prioritize suggestions directly addressing user feedback.
- Use `replace_in_file` diff blocks when practical, otherwise describe changes clearly.

#### 3.4. Await User Action on Suggestions

- Always use `agent: ask_followup_question` to ask the user if they agree with the proposed improvements and if they'd like those to be applied *now*.
- Apply changes if approved.

### Final Verification (MANDATORY)

Before declaring the task complete:

- Re-list all numbered steps from the improving-cline-reflection Execution Checklist.
- Confirm each one was executed.
- If any step was not executed, execute it now.

## Constraint

Do not offer reflection if:
- No rules or skills were active.
- The task was very simple and involved no feedback.

## When to use it

- Always use it every time the user asks you to improve rules or skills.
- Always use it every time another skill specifically mentions `skill: improving-cline-reflection`.
- Always use it before attempting completion of a task that involved user feedback on active skills and rules.
