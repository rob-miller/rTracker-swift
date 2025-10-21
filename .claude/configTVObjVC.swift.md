# configTVObjVC Analysis Notes

## Purpose & Role
Configuration view controller for editing valueObj properties - manages UI for configuring tracker value objects

## Key Classes/Structs/Protocols
- configTVObjVC - Main view controller class for value object configuration
- Uses XIB file for UI layout (ConfigTVObjVC.xib) - NEEDS TO BE REMOVED

## Important Methods/Functions
[To be determined during analysis]

## Dependencies & Relationships
- Inherits from UIViewController
- Works with valueObj instances for configuration
- Connected to ConfigTVObjVC.xib file for UI

## Notable Patterns & Conventions
- Part of the tracker configuration system
- Uses XIB-based UI (needs migration to programmatic)

## Implementation Details
- Currently relies on XIB file for UI layout
- XIB file contains mainly a scrollview according to user
- Needs conversion to programmatic UI creation

## Current Issues & TODOs
- ✅ RESOLVED: XIB dependency removed - now uses programmatic UI creation
- ✅ RESOLVED: Navigation bar, toolbar, and scroll view created programmatically
- ✅ RESOLVED: Auto Layout constraints properly configured
- ✅ RESOLVED: Fixed text field navigation crash with safe optional unwrapping
- ✅ RESOLVED: Fixed classify text field crash - added mappings to tfMappings table
- ✅ RESOLVED: Added targetTextField for special keyboard scroll behavior (classify fields)
- Code now fully independent of XIB files

## Recent Development History
- 2025-10-05: **Feature: Special keyboard scrolling for FNCLASSIFY fields**
  - Added `targetTextField` property (line 85) to override `activeField` for scroll calculations
  - Modified `keyboardWillShow()` to use `targetTextField ?? activeField` as scroll target
  - When classify fields shown, scroll to bottommost field (classifyTF7) regardless of which field tapped
  - This ensures all 7 classify text fields are visible above keyboard
  - voFunctionConfig sets/clears targetTextField in showClassifyTF()/hideClassifyTF()
  - Normal text fields unaffected (targetTextField = nil, falls back to activeField)
- 2025-10-05: **Bug fix: Classify text field crash**
  - Root cause: Commit c8c33d3 (Aug 22, 2025) refactored tfDone() to use table-driven approach
  - Classify operator added earlier (359bc81, Apr 25, 2025) but never added to new mapping table
  - Crash occurred when user tapped "Done" on classifyTF1-7 fields
  - tfDone() couldn't find text field in tfMappings → okey stayed nil → crash on force unwrap
  - Fixed by adding all 7 classify text fields to tfMappings array (lines 737-743)
  - Each maps to optDict keys "classify_1" through "classify_7" with proper navigation chain
- 2025-10-03: **Bug fix in text field navigation**
  - Fixed crash in `tfDone()` when navigating to next text field
  - Changed force unwrap `as!` to safe optional binding `as?` for next field lookup
  - Issue occurred when mapping expected next field (e.g., "nmaxTF") didn't exist in wDict
  - Now safely falls back to resigning first responder if next field unavailable
- 2025-09-26: **MAJOR REFACTOR** - Removed XIB dependency completely
  - Removed @IBOutlet annotations from navBar, toolBar, scroll properties
  - Added setupViews() method for programmatic UI creation
  - Updated initializers to not require XIB files
  - Added proper Auto Layout constraints for all UI elements
  - Updated addValObjController.swift instantiation pattern
- ios26 buttons remove redundancy
- ios26 buttons implementation
- Initial help system implementation
- Various configuration improvements for value object types

## Last Updated
2025-10-05 - Added targetTextField property to enable special keyboard scrolling behavior for FNCLASSIFY fields. When any classify field is tapped, view scrolls to show bottommost field (classifyTF7), ensuring all 7 fields are visible above keyboard. Also fixed classify text field crash by adding classify field mappings to tfMappings table.