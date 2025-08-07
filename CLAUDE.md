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

### Code Consolidation Principles

**Always minimize code duplication by consolidating similar functionality:**

- **Single Source of Truth**: Prefer one function handling a conceptual task everywhere it's needed instead of multiple bespoke variants with minor differences
- **Data-Driven Behavior**: Always prefer data parameters to naturally determine behavior instead of complex conditionals
- **Natural Flow**: Let the data flow determine behavior rather than testing for cases
- **Completion-Driven Context**: Use completion handlers to let the calling context determine what to do with results, rather than passing flags or mode parameters
- **Unified Processing**: Apply consistent processing (filtering, aggregation, validation) across all code paths to handle edge cases automatically

**Examples of Good Consolidation:**
- ✅ `processHealthQuery()` - Single function handles all HealthKit scenarios using frequency and configuration parameters
- ✅ `performHealthQuery(startDate:endDate:)` - Single function where `endDate = nil` triggers point query, `endDate = Date` triggers range query  
- ✅ Always apply filtering and aggregation - handles unexpected multi-result cases automatically

**Anti-Patterns to Avoid:**
- ❌ Separate `processDaily()` and `processTimeSlot()` functions with mostly identical logic
- ❌ Complex conditional logic testing for `needsTimeSlotProcessing` flags  
- ❌ Multiple similar functions that differ only in parameter handling
- ❌ Bespoke result processing in each calling context

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

## 🚨 MANDATORY SOURCE CODE ANALYSIS WORKFLOW 🚨

### ⛔ FIRST-TIME FILE ANALYSIS PROTOCOL ⛔

**🚨 CRITICAL RULE: The Read tool is BANNED for NEW .swift files until notes workflow is completed 🚨**

**ENFORCEMENT**: The FIRST time you analyze any source file in a session, MUST follow this exact sequence:

1. **MANDATORY FIRST STEP**: Run `ls -la .claude/` to verify directory exists
2. **MANDATORY SECOND STEP**: Check for `[filename].md` notes file 
3. **MANDATORY THIRD STEP**: If no notes file exists, CREATE IT FIRST before any Read operations
4. **MANDATORY FOURTH STEP**: If notes file exists, READ IT FIRST before source code
5. **MANDATORY FIFTH STEP**: Run `git log --oneline --follow [filepath]` for history
6. **ONLY THEN**: Proceed with Read tool on source code

### 🔄 SUBSEQUENT EDITS WORKFLOW 🔄

**STREAMLINED PROCESS**: After completing the first-time analysis workflow for a file:
- ✅ **Subsequent edits**: Can proceed directly to Read tool - notes workflow already completed
- ✅ **Quick changes**: No need to re-read notes file for simple edits in same session
- ⚠️ **Major changes**: Update notes file after significant modifications
- 🚨 **New session**: If working on the file in a completely new session, re-read notes file first

### 🚫 WORKFLOW VIOLATIONS ARE UNACCEPTABLE 🚫

**ZERO TOLERANCE POLICY**: 
- Reading source code without following this workflow is a CRITICAL ERROR for FIRST-TIME analysis
- No exceptions for "simple" tasks or "quick" edits on NEW files
- This applies to ALL .swift files without exception
- Once notes workflow completed for a file in a session, subsequent edits are streamlined

**IMMEDIATE CONSEQUENCES OF VIOLATIONS**:
- Loss of development context and history
- Inability to maintain code evolution tracking  
- Poor code maintenance and debugging
- Repeated analysis work and inefficiency
- Missing critical implementation details

### 📋 FIRST-TIME FILE ANALYSIS CHECKLIST

**⚠️ ONLY for FIRST time analyzing a .swift file in a session ⚠️**

**STEP 1: DIRECTORY VERIFICATION (REQUIRED ONCE PER SESSION)**
```bash
# Run this command FIRST, always:
ls -la .claude/
```
- [ ] ✅ Confirmed `.claude/` directory exists and contains files
- [ ] ⚠️ If no `.claude/` directory: You are in WRONG DIRECTORY - cd to correct path
- [ ] 🛑 If still no directory: STOP and ASK FOR HELP

**STEP 2: NOTES FILE CHECK (REQUIRED FOR NEW FILE)**  
- [ ] ✅ Target file identified: `[Classes/filename.swift]`
- [ ] ✅ Checked for existing notes file: `.claude/[filename.swift.md]`
- [ ] ✅ Notes file status determined: EXISTS / MISSING

**STEP 3A: IF NOTES FILE MISSING (REQUIRED CREATION)**
- [ ] ✅ Git history reviewed: `git log --oneline --follow [filepath]`
- [ ] ✅ Notes file created using EXACT template below
- [ ] ✅ Template filled with basic information from git history
- [ ] 🚨 **NO Read tool usage until notes file created**

**STEP 3B: IF NOTES FILE EXISTS (REQUIRED FIRST READ)**
- [ ] ✅ Existing notes file read completely
- [ ] ✅ Current state and issues understood
- [ ] ✅ Recent development history reviewed
- [ ] ✅ Ready to update notes with new findings

**STEP 4: FIRST-TIME AUTHORIZATION (REQUIRED)**
- [ ] ✅ All above steps completed
- [ ] ✅ Notes workflow fully satisfied  
- [ ] ✅ Authorization granted to use Read tool
- [ ] ✅ **FILE MARKED AS ANALYZED** - subsequent edits can proceed directly

**🛑 CHECKPOINT: If ANY checkbox above is unchecked, STOP and complete it NOW**

### 📋 SUBSEQUENT EDITS CHECKLIST

**✅ STREAMLINED: For files already analyzed in current session**

- [ ] ✅ File previously analyzed with notes workflow completed
- [ ] ✅ Notes file exists and was read during first analysis  
- [ ] ✅ Proceed directly to Read tool - no additional workflow required
- [ ] ⚠️ **Remember**: Update notes file after making significant changes

### 📝 MANDATORY NOTES FILE TEMPLATE

**⚠️ Use this EXACT template for ALL new notes files:**

```markdown
# [FileName] Analysis Notes

## Purpose & Role
[Brief description of what this file does - REQUIRED]

## Key Classes/Structs/Protocols  
[List main types defined - REQUIRED]

## Important Methods/Functions
[Key functions and their purposes - REQUIRED]

## Dependencies & Relationships
[What this file imports/depends on, what depends on it - REQUIRED]

## Notable Patterns & Conventions
[Code style, patterns, quirks specific to this file - REQUIRED]

## Implementation Details
[Important implementation notes, gotchas, performance considerations - REQUIRED]

## Current Issues & TODOs
[Any known problems, incomplete features, or planned improvements - UPDATE FREQUENTLY]

## Recent Development History
[Key recent commits and changes from git log - REQUIRED]

## Last Updated
[Date and brief description of last analysis - UPDATE AFTER EACH SESSION]
```

### 🔄 NOTES MAINTENANCE REQUIREMENTS

**DURING EVERY SESSION:**
- ✅ Update "Current Issues & TODOs" section with new findings
- ✅ Remove resolved issues from notes
- ✅ Add new problems discovered during analysis
- ✅ Update "Last Updated" section with current date
- ✅ Keep notes current with actual file state

**AFTER MAKING CHANGES:**
- ✅ Update relevant sections to reflect new code state
- ✅ Document significant modifications in "Recent Development History"
- ✅ Remove outdated information that no longer applies

### 🚨 EMERGENCY WORKFLOW VIOLATION PROTOCOL 🚨

**If you realize you've read source code without following this workflow:**

1. **IMMEDIATELY STOP** all current analysis
2. **CONFESS** the violation explicitly
3. **CREATE** the missing notes file using the template
4. **BACKFILL** the notes with information from the code you already read
5. **CONTINUE** only after notes are properly created and populated

### ⛔ FINAL ENFORCEMENT STATEMENT ⛔

**This workflow is NON-NEGOTIABLE and applies to:**
- ✅ **FIRST-TIME ANALYSIS**: All .swift files require notes workflow before first Read operation
- ✅ **NEW SESSIONS**: Re-read notes file when starting work on a file in a new session  
- ✅ **SUBSEQUENT EDITS**: Streamlined process after first-time workflow completed
- ✅ **NOTES MAINTENANCE**: Always update notes after significant changes

**WORKFLOW SUMMARY:**
- 🚨 **First time touching a file**: Complete full notes workflow
- ⚡ **Additional edits same session**: Proceed directly to Read tool
- 📝 **Always**: Keep notes current with code changes
- 🔄 **New session**: Re-read existing notes file first

**NO EXCEPTIONS FOR FIRST-TIME ANALYSIS. STREAMLINED FOR SUBSEQUENT EDITS.**
