# update-notes Command

## Purpose
Update all analysis notes files for project files modified in the current session

## Usage
When you've made changes to source files during a session, run this command to update the corresponding `.claude/[filename].swift.md` notes files with:

- Current session changes and modifications
- Updated "Implementation Details" sections
- New "Current Issues & TODOs" status
- Refreshed "Recent Development History"
- Updated "Last Updated" timestamp

## Process
1. Identify all .swift files that were Read or Edit during current session
2. For each file, read the corresponding `.claude/[filename].swift.md` notes file
3. Update relevant sections based on changes made:
   - Add new implementation details
   - Update current issues status (mark resolved items)
   - Add session changes to development history
   - Update "Last Updated" with current date and brief description
4. Preserve existing historical information and analysis

## ⚠️ IMPORTANT: Line Number Guidelines
**AVOID specific line numbers in notes files whenever possible**

- Code changes frequently, making line numbers stale and misleading
- **Instead of**: "Lines 720-767 contain date adjustment logic"
- **Prefer**: "Date adjustment logic in loadHKdata function"
- **Exception**: Use line numbers ONLY when absolutely necessary for precision (e.g., very recent changes in current session)
- **Best practice**: Reference function/method names, class names, or logical sections instead
- If you must include line numbers, add a disclaimer: "(approximate location, may shift with code changes)"

### Reasoning:
Line numbers become obsolete as code evolves. Functional references remain stable and are easier to search for in the codebase.

## When to Use
- End of coding sessions after making significant changes
- Before switching to work on different parts of the codebase
- After completing feature implementations or bug fixes
- When major architectural changes have been made

## Example
If you modified `trackerObj.swift` and `voNumber.swift` during the session, this command will update both `.claude/trackerObj.swift.md` and `.claude/voNumber.swift.md` with the current session's changes.

## Note
This maintains the mandatory notes workflow and ensures documentation stays current with code evolution.