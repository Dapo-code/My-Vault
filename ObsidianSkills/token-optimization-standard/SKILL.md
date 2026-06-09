---
name: token-optimization-standard
description: Enforce token-efficient skill and workflow design using budgets, mode-based execution, concise outputs, and strict stop rules.
---

# Token Optimization Standard Skill

## Goal
Minimize token usage across skill execution while preserving reliability and clarity.

## Required Parameters
Collect these before applying this standard:

1. target_skill_path
- Path to the skill file being created or updated.

2. use_case
- One sentence describing the user outcome the skill must support.

3. default_mode
- `fast` or `standard`.

4. hard_response_cap
- Maximum allowed response length in words.

## Optional Parameters
1. deep_mode_triggers
- Conditions that are allowed to activate `deep` mode.

2. clarification_questions_cap
- Maximum number of questions before execution.

3. examples_policy
- `none`, `minimal`, or `on-request`.

## Token Budget Rules
1. Every skill must define three modes: `fast`, `standard`, and `deep`.
2. `fast` mode is default unless the task requires higher fidelity.
3. `deep` mode can run only when a trigger condition is explicitly true.
4. Keep required parameters to the minimum needed to act safely.
5. Keep optional parameters focused on branching and edge-case control.
6. Use a strict output contract with fixed headings.
7. Keep validation checklist to 3-5 checks.
8. Do not include long examples unless `examples_policy` allows it.

## Workflow Pattern
1. Router pass
- Decide mode and execution path in 3 lines or less.

2. Execute pass
- Return only decisions, edits, and outcomes.

3. Validate pass
- Return pass/fail and top issues only.

4. Final pass
- Return concise summary and next actions.

## Required Sections For New Skills
Every new SKILL.md should include these sections:

1. Goal
2. Required Parameters
3. Optional Parameters
4. Mode Selector
5. Steps
6. Output Contract
7. Validation Checklist
8. Stop Rules
9. Related

## Output Contract Template
Use this exact skeleton where possible:

```md
## Output Contract
- Mode: <fast|standard|deep>
- Summary: 2-4 lines
- Changes Made: bullet list
- Validation: pass|fail and top 3 issues
- Next Actions: optional numbered list
```

## Stop Rules
1. Ask a clarifying question if any required parameter is missing.
2. Stop and ask user confirmation before running deep mode.
3. Stop if the request conflicts with repository policy.

## Validation Checklist
- Skill includes mode selector with `fast`, `standard`, and `deep`.
- Skill includes an explicit output contract.
- Skill includes stop rules and deep mode triggers.
- Skill keeps validation checklist to 3-5 checks.
- Skill avoids long examples by default.

## Related
- [[ObsidianSkills/token-optimization-standard/token-optimization-standard|Token Optimization Standard Note]]
- [[ObsidianSkills/skill-format-guide/skill-format-guide|Skill Format Guide Note]]
- [[ObsidianSkills/skills-changelog|Skills Change Log]]
