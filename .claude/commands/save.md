# save Command

## Purpose
Create a versioned save file documenting the current work session's main focus and most recent developments

## Usage
When you want to save your current progress and context for future sessions, this command will:

- Identify the main theme/focus of the current work session
- Document the most recent and important changes
- Create a versioned save file in `.claude/saves/save.N.YYYY-MM-DD-MainTheme` format
- Focus on actionable context rather than historical details
- **Explicitly include any unfinished todo lists from the current session**

## Process
1. Analyze recent file modifications and changes made in current session
2. Identify the primary work theme (e.g., "iOS 26 button modernization", "HealthKit data cleanup", etc.)
3. Document key files modified and their current state
4. **Capture any active TodoWrite lists with pending/in_progress items**
5. Note any immediate next steps or pending issues
6. Create descriptive save file: `save.N.YYYY-MM-DD-MainTheme` (sequential number, date, theme with dashes)

## Save File Format
```
# Save [N] - [Date] - [Main Theme]

## Current Work Focus
[Primary objective and current progress]

## Key Files Modified
- [filename]: [brief description of changes and current state]
- [filename]: [brief description of changes and current state]

## Unfinished Todo Lists
[Complete reproduction of any active TodoWrite lists with status]
- ✅ [completed task]
- 🔄 [in_progress task]
- ⏳ [pending task]

## Immediate Next Steps
- [actionable items for next session]
- [pending issues or decisions needed]

## Context Notes
[Any important context that would help resume work efficiently]
```

## When to Use
- End of productive work sessions
- Before switching to completely different areas of the codebase
- When you want to preserve current context for later resume
- Before taking breaks from the project

## Note
Focuses on current/recent work rather than comprehensive project history. Designed for quick context restoration when resuming work.