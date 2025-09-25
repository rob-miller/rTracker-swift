# restart Command

## Purpose
Read a save file and restore work context to resume where you left off

## Usage
**Basic**: `restart` - loads the most recent save file
**Specific**: `restart [N]` - loads save file number N

When starting a new session and you want to quickly get back into the context of your previous work:

- Without argument: Automatically finds the highest numbered save file in `.claude/saves/` (searches for `save.N.*` pattern)
- With argument N: Loads the specific save file starting with `save.N.` (matches `save.N.YYYY-MM-DD-MainTheme`)
- Reads and presents the selected session's context
- Restores understanding of work focus and progress
- **Recreates any unfinished todo lists using TodoWrite tool**

## Process
1. If no argument provided: Scan `.claude/saves/` for most recent save file (pattern: `save.*`)
2. If argument N provided: Find and load the save file matching `save.N.*` pattern
3. Read and parse the selected save file content
4. Present the session's work focus and progress
5. **Automatically recreate any unfinished TodoWrite lists from the save file**
6. Highlight immediate next steps for continuation

## What Gets Restored
- **Main work theme and current objectives**
- **Key files that were being modified**
- **Complete todo lists with their exact status** (pending/in_progress/completed)
- **Immediate next steps and pending decisions**
- **Important context notes for efficient resumption**

## Output Format
```
🔄 Restoring from Save [N] - [Date] - [Main Theme]

📋 WORK FOCUS: [Main theme]

📁 KEY FILES:
- [filename]: [status]

✅ RECREATING TODO LIST:
[TodoWrite tool executed with saved todos]

🎯 NEXT STEPS:
- [actionable items]

💡 CONTEXT:
[relevant notes]
```

## Examples
- `restart` → loads most recent save file (e.g., save.15.2025-01-15-iOS26-Privacy-Fixes)
- `restart 3` → loads save.3.* file specifically
- `restart 127` → loads save.127.* file

## When to Use
- Beginning of new work sessions
- After breaks or time away from the project
- When context switching back to this project
- To review or return to a previous work state
- To quickly understand any session's state

## Note
Designed for seamless work continuation by restoring both mental context and active todo tracking. The optional argument allows returning to any previous work state, not just the latest.