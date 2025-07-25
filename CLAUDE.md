# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
rTracker is an iOS app for creating local databases ("trackers") to log timestamped data. Each tracker uses sqlite3 for data storage, with the tracker list itself stored in a separate database. The app supports various UI controls (number/text fields, sliders, radio buttons, checkboxes) for data entry and provides graphical data visualization.

## Architecture
- **Core Classes**: `trackerObj` (main tracker logic), `valueObj` (base class for tracked values with voProtocol)
- **Value State Classes**: `voState` (base UI state class), with subclasses `voNumber`, `voText`, `voTextBox`, `voSlider`, `voChoice`, `voBoolean`, `voFunction`, `voInfo`
- **Class Hierarchy**: `valueObj` contains a `voState` instance (via `vos` property) - the UI classes are NOT direct subclasses of `valueObj`
- **UI Structure**: Portrait mode shows data entry forms
- **Data Flow**: SQLite3 databases per tracker + master tracker list database
- **Graphing**: 
  - Legacy landscape mode shows basic time-series graph (limited functionality)
  - Modern iOS Charts system in `Classes/charts/` runs in portrait mode, accessed via button on tracker's 'new record' page
  - Chart types: Time plots, scatter plots, distribution plots, pie charts

## Build Commands
**Important**: Do not run build commands automatically - they consume excessive tokens. Only run when explicitly requested by the user.
- `xcodebuild -scheme rTracker-devel build` - Build development version
- `xcodebuild -scheme rTracker build` - Build release version
- `xcodebuild -scheme rTracker-devel test` - Run UI tests
- `xcodebuild -scheme rTracker-devel -destination 'platform=iOS Simulator,name=iPhone 14' test -only-testing:rTrackerUITests/rTrackerUITests/test_rTracker` - Run specific test

## Code Style Guidelines
- Swift 5.0 conventions with camelCase for methods and variables
- Classes begin with lowercase (trackerObj, valueObj)
- Constants use UPPERCASE (e.g., SAVERTNDFLT)
- Prefix private properties with underscore (_trackerName)
- Error handling uses custom debug logging functions: DBGLog, DBGWarn, DBGErr
- Use #if DEBUGLOG, #if DEBUGWARN, #if DEBUGERR for conditional debug code
- Include copyright and license in file headers
- Use MARK: comments for code organization
- The codebase was converted from Objective-C using Swiftify

## Debug Configuration
- Debug flags are set in build configurations (Debug no-log, Debug reminder, etc.)
- Main debug controls in `Classes/dbg-defs.swift` 
- Conditional compilation flags control logging levels and debug features
- Test configuration uses "Debug no-log" build configuration

## Key Components
- **TimesSquare**: Modified calendar component for date selection
- **CSV Support**: Import/export functionality via CSVParser
- **HealthKit Integration**: Data sharing with Apple Health
- **Local Notifications**: Reminder system for tracking
- **Privacy**: Optional graphical password protection
- **URL Schemes**: Support for rTracker:// and rTracker://tid=N URLs

## Source Code Analysis Workflow

### ⚠️ CRITICAL WORKFLOW VIOLATION CHECK ⚠️
**FAILURE TO FOLLOW THIS WORKFLOW IS A CRITICAL ERROR**

Before reading ANY source code file, you MUST:
1. **STOP** and check: Does `.claude/[filename].md` exist?
2. If NO: Create the notes file FIRST using the mandatory template below
3. If YES: Read the notes file FIRST to understand current state
4. **NEVER PROCEED** without completing steps 1-3

**VIOLATION CONSEQUENCES**: 
Skipping this workflow leads to:
- Lost context from previous analysis
- Repeated work and inefficiency  
- Missing critical implementation details
- Inability to track code evolution
- Poor debugging and maintenance

---

### Pre-Analysis Checklist (MANDATORY)
Before analyzing any source file, complete this checklist:
- [ ] File path identified: _______________
- [ ] Checked for existing notes file in `.claude/[filename].md`
- [ ] Notes file exists? If NO, create using template below
- [ ] Git history reviewed with: `git log --oneline --follow [filepath]`
- [ ] Notes file read/updated to reflect CURRENT state
- [ ] Ready to proceed with analysis

**CHECKPOINT**: Before using Read tool on any .swift file:
- Have you checked for and created/updated the notes file?
- Have you reviewed recent git history?
- Are you ready to update the notes file with new findings?

**If any answer is NO, STOP and complete the missing steps.**

---

### MANDATORY Steps for Source Code Analysis:

**Step 1: Notes File Audit (ALWAYS FIRST)**
Before beginning any code analysis:
1. List all files you plan to examine
2. Check for existing notes files for each in `.claude/` directory
3. Create missing notes files using the template below
4. Only then proceed with analysis

**Step 2: Check for existing notes file**
Look in `.claude/` directory for a file named after the source file (e.g., for `Classes/trackerObj.swift`, check `.claude/trackerObj.swift.md`)

**Step 3: Review development history** 
Use `git log --oneline --follow [filepath]` to understand recent changes and development patterns for the file

**Step 4: Create notes file if missing**
If no notes file exists, you MUST create one with the following structure:
   ```markdown
   # [FileName] Analysis Notes
   
   ## Purpose & Role
   [Brief description of what this file does]
   
   ## Key Classes/Structs/Protocols
   [List main types defined]
   
   ## Important Methods/Functions
   [Key functions and their purposes]
   
   ## Dependencies & Relationships
   [What this file imports/depends on, what depends on it]
   
   ## Notable Patterns & Conventions
   [Code style, patterns, quirks specific to this file]
   
   ## Implementation Details
   [Important implementation notes, gotchas, performance considerations]
   
   ## Recent Development History
   [Key recent commits and changes from git log]
   ```

**Step 5: Update notes during analysis**
While working with the file, you MUST update the notes file to reflect the CURRENT state:
   - **Remove resolved issues**: If you fix a bug or performance problem, remove the issue description from the notes
   - **Add new issues**: If you discover new problems, add them to the appropriate section
   - **Update descriptions**: If your changes significantly alter the file's purpose or key methods, update those sections
   - **Keep current**: The notes should always describe the file as it exists NOW, not its historical problems
   - **Use git history section**: Track significant changes and detect regressions by referencing recent commits

**Step 6: Keep notes current and concise**
The notes file should be a snapshot of the file's current state to enable rapid analysis. Use the "Recent Development History" section to track when major changes occurred, but don't accumulate a list of every issue ever fixed.

---

### FINAL WARNING
**Do not proceed with any file analysis without completing Steps 1-4. This workflow is required for ALL source code files to maintain consistency and facilitate future work.**

**WORKFLOW VALIDATION**: If you realize you've read a source file without following this workflow, immediately stop what you're doing and create the missing notes file before continuing.