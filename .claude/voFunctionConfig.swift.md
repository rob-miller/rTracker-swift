# voFunctionConfig Analysis Notes

## Purpose & Role
Configuration and UI management for function-type value objects (voFunction), providing interface for building and editing mathematical/logical functions

## Key Classes/Structs/Protocols
Extension of `voFunction` class containing all configuration UI logic

## Important Methods/Functions
- `voFnDefnStr()`: Converts function array to human-readable string with special handling for different token types
- `btnAdd()`: Adds selected function token to fnArray with special handling for constant, before/after, and classify
- `btnDelete()`: Removes last token from fnArray with special handling for multi-element functions
- `updateFnTitles()`: State machine determining which tokens are valid to add next
- `drawFuncOptsDefinition()`: Creates UI for function definition page
- `drawFuncOptsRange()`: Creates UI for function range/endpoint configuration
- `drawFuncOptsOverview()`: Creates summary view of function configuration
- `showConstTF()/hideConstTF()`: Show/hide constant value input
- `showDateTimeTF()/hideDateTimeTF()`: Show/hide date/time picker for before/after
- `showClassifyTF()/hideClassifyTF()`: Show/hide classify value inputs

## Dependencies & Relationships
- Extends `voFunction` class from voFunction.swift
- Uses `configTVObjVC` for UI view controller integration
- Accesses `vo.optDict` for persistent storage of configuration values
- Integrates with `rtDocs` help system via `getOperatorDocIdentifier()`

## Notable Patterns & Conventions
- Three-page configuration interface (Overview, Range, Definition) using segmented control
- Picker-based token selection with context-sensitive UI elements
- Hidden UI elements (addsv: false) shown only when relevant token selected
- State machine in `updateFnTitles()` enforces valid function syntax

## Implementation Details

### Function String Display Logic
The `voFnDefnStr()` method uses state flags to properly display function syntax:
- `closePending`: Track when closing bracket `]` needed for 1-arg functions and before/after
- `constantPending`: Next item is a value (not token/vid) - used for constant, before, after
- `constantClosePending`: Value has been displayed, next token closes the sandwich
- `arg2Pending`: Looking for second argument in 2-arg operations
- `openParenCount`: Track parenthesis nesting depth

**Before/After Display Format**: These functions display as `before[date]` or `after[date]`:
- Opening token: outputs function name + `[`, sets both `constantPending=true` and `closePending=true`
- Value: outputs formatted date, closes bracket with `]` if `closePending=true`
- Closing token: handled by `constantClosePending` logic (sandwich pattern)

### Sandwich Token Pattern
Functions with configurable values use sandwich structure:
- `constant`: `[FNCONSTANT, numeric_value, FNCONSTANT]` → displays as just the number
- `before`: `[FNBEFORE, timestamp_int, FNBEFORE]` → displays as `before[date]`
- `after`: `[FNAFTER, timestamp_int, FNAFTER]` → displays as `after[date]`
- Display logic: Opening token sets `constantPending=true`, value displays and sets `constantClosePending=true`, closing token resets flags

### Shared UI Pattern
Single input control serves multiple similar functions based on picker selection:
- ONE constant text field for all constant values
- ONE date/time picker button for both before and after functions
- System determines context from current picker selection
- Values stored temporarily in `vo.optDict[DTKEY/LCKEY]` until added to fnArray

### Value Storage Pattern
Two-tier storage approach:
1. **fnArray**: Actual values used in function calculation (NSNumbers in sandwich structure)
2. **vo.optDict**: Persistent storage for UI state, enables re-editing:
   - `LCKEY` ("fdlc"): Last constant value for text field pre-population
   - `DTKEY` ("fddt"): Last datetime timestamp for button display/editing
   - `"classify_N"`: Text values for classify function buckets

## Current Issues & TODOs
- Unused variable 'ep2' at line 531 needs fixing
✅ Added before/after date comparison functions with date/time picker UI
✅ Implemented shared UI pattern for date/time configuration
✅ Created ftAddOtherSet() to populate picker with before/after functions
✅ Fixed voFnDefnStr() to display before/after as `before[date]` format with proper bracket closure
✅ Fixed date/time picker button alignment with label
✅ Fixed date/time picker button visibility (hidden by default, shown on selection)
✅ Added special keyboard scrolling for classify text fields via targetTextField mechanism

## Recent Development History
- 2025-10-05: **Special keyboard scrolling for classify text fields**
  - Modified `showClassifyTF()` to set `ctvovcp?.targetTextField` to classifyTF7 (bottommost field)
  - Modified `hideClassifyTF()` to clear `ctvovcp?.targetTextField = nil`
  - Works with new targetTextField property in configTVObjVC
  - When ANY classify field tapped, keyboard appears and view scrolls to show classifyTF7
  - This ensures all 7 classify text fields are visible above keyboard
  - User can now fill any field (e.g., just field 3) without sequential tapping
- 2025-10-03: **Before/after function UI implementation**
  - Created `ftAddOtherSet()` function to add OTHERFNS to picker (mirrors ftAddFnSet/ftAddTimeSet pattern)
  - Called `ftAddOtherSet()` from `ftStartSet()` to make before/after appear in picker
  - Removed duplicate FNCONSTANT addition (now handled by ftAddOtherSet)
  - Updated `voFnDefnStr()` to display before/after with function name and brackets: `before[12/25/24]`
  - Fixed bracket closure logic: opening token sets `closePending=true`, value adds `]` when flag true
  - Separated FNBEFORE/FNAFTER handling from FNCONSTANT in display logic
  - Added date/time picker modal with UIDatePicker in .pageSheet presentation
  - Fixed button alignment by manually adjusting frame to match label height/Y position
  - Fixed button visibility by removing from superview initially (configActionBtn always adds to scroll)
  - Implemented UIAction closure-based done handler for proper modal dismissal
- b71c989: make frep picker - help more robust
- 66e777a: docs for range endpoints; clean up dbg messages
- 12c495c: initial implementation of help system - fn defn page
- 866cfdd: ios26 segmented control access issue
- c8c33d3: min2, max2, display as hrs:mins added to voFn; configTVObj more table driven; comment sleep other 0 values

## Last Updated
2025-10-05: Added special keyboard scrolling for classify text fields. When any classify field is tapped, view scrolls to show bottommost field (classifyTF7), ensuring all 7 fields are visible above keyboard. Implemented via targetTextField mechanism in configTVObjVC.