---
name: iterate-design-discussion
description: iterate on design discussion based on user feedback
---

# Iterate Design Discussion

You are iterating on an existing design discussion document based on user feedback.

## Input

- `docPath`: Path to the existing design discussion document (e.g., `.humanlayer/tasks/ENG-XXXX-description/YYYY-MM-DD-design-discussion.md`)
- The users feedback, or path to a ticket file with comments or feedback

## Initial Check

If the user calls this with no instructions or feedback, ask them for their feedback:

```
I'm ready to iterate on the design discussion. What feedback or changes would you like me to incorporate?
```

Then wait for the user's feedback before proceeding.

## Steps

1. **Read the existing document FULLY**:
   - Use Read tool WITHOUT limit/offset to read the entire document at `docPath`
   - Understand the current design decisions and open questions

2. **If a ticket file is provided, read it for feedback**:
   - Look for comments mentioning you (linear-assistant, LinearLayer, claude)
   - These comments contain instructions/feedback from the user

3. **If the user gives any input**:
   - DO NOT just accept the correction blindly
   - Spawn research tasks to verify the information if needed
   - Read the specific files/directories they mention
   - Only proceed once you've verified the facts yourself

4. **Process the feedback**:
   - If user answered design questions: Move them to "Resolved Design Questions" with rationale
   - If user requested changes to patterns: Update the patterns section
   - If user provided new constraints: Add to "What we're not doing" or update scope
   - Keep the same YAML frontmatter and format

5. **Spawn sub-agents for follow-up research** (if needed):

   **For deeper investigation:**
   - **codebase-locator**: Find more specific files (e.g., "find all files that handle [specific component]")
   - **codebase-analyzer**: Understand implementation details (e.g., "analyze how [system] works")
   - **codebase-pattern-finder**: Find similar features we can model after

   Each agent knows how to:
   - Find the right files and code patterns
   - Identify conventions and patterns to follow
   - Look for integration points and dependencies
   - Return specific file:line references
   - Find tests and examples

   Do not run agents in the background - FOREGROUND AGENTS ONLY.

<important if="the user asks you to find how things work or add detail about existing functionality">
  prefer to use an inital pass with one of more subagents before reading files yourself
</important>

6. **Update document** (if changes needed):
   - Update the document at the same `docPath`
   - Move answered questions to "Resolved Design Questions" section
   - Update patterns with new code examples if discovered
   - Add any new design questions that emerged

7. **Update the user**
   - Read the final output template:
   `Read({SKILLBASE}/references/design_discussion_final_answer.md)`
   - Respond with a summary following the template, including GitHub permalinks.

<guidance>
## Cloud Permalinks

When you write or edit documents in .humanlayer/tasks/, a cloud permalink is automatically provided in the hook response.
- The permalink appears as `additionalContext` after Write/Edit/MultiEdit operations
- Use this permalink in your final output for easy navigation
- Example format: `http(s)://{DOMAIN}/artifacts/{artifactId}`

## Markdown Formatting

When writing markdown files that contain code blocks showing other markdown (like README examples or SKILL.md templates), use 4 backticks (````) for the outer fence so inner 3-backtick code blocks don't prematurely close it:

````markdown
# Example README
## Installation
```bash
npm install example
```
````
</guidance>
