# addTrackerController.swift Analysis Notes

## Purpose & Role
Controller for creating and modifying trackers. Handles tracker configuration, valueObj management, and crucially contains the logic for detecting HealthKit configuration changes and cleaning up data appropriately.

## Key Classes/Structs/Protocols
- `addTrackerController`: Main class for tracker editing
- Works with `trackerObj`, `valueObj`, and various configuration controllers
- Manages temporary tracker objects during editing

## Important Methods/Functions
- `btnSave()`: Main save logic that includes HealthKit change detection
- HealthKit change detection logic (lines 331-356): Compares old vs new HealthKit settings
- Data cleanup logic: Removes HealthKit data when sources are changed/disabled

## Dependencies & Relationships
- Integrates with `trackerObj` for data management
- Uses `valueObj` configurations and `voState` subclasses
- Manages `trackerList` updates
- Handles database cleanup operations

## Notable Patterns & Conventions
- Temporary object pattern for safe editing
- Comprehensive option comparison for detecting changes
- Careful data cleanup when external sources are modified

## Implementation Details
- **HealthKit Change Detection**: Compares multiple HealthKit options (source, unit, averaging, etc.)
- **Data Cleanup**: Uses `clearHKdata()` when HealthKit settings change
- **Database Maintenance**: Removes orphaned trkrData entries after data cleanup

## Recent Development History
**Current Session (2025-09-26) - Button Consolidation Fixes:**
- **FIXED**: Updated `createBackButton()` → `createNavigationButton(direction: .left)` (line 67)
- **FIXED**: Updated `createEditButton()` → `createActionButton(symbolName: "slider.horizontal.3")` (line 93)
- **FIXED**: Updated `createCopyButton()` → `createActionButton(symbolName: "doc.on.doc")` (line 100)
- **Architecture**: All buttons now use consolidated 4-function system
- **Compilation**: Resolved all button-related compilation errors

**Previous Git History:**
- `2e64587`: Added un/hide functionality for trackers and valueObjs
- `66b26ec`: Implemented hidden valueObjs feature
- `c0d44b0`: Added "no graph" option at valueObj level
- `3c43c7f`: Organized voData delete routines

## iOS 26 Button Integration Details
**Navigation Bar Button Updates:**
- **Left Navigation**:
  - Edit mode: `createBackButton()` with chevron.left in white circle
  - Create mode: `createBackButton()` for consistent styling
- **Right Navigation**: `createSaveButton()` with yellow checkmark circle
- **Toolbar Buttons**:
  - Setup: `createEditButton()` with slider.horizontal.3 icon
  - Copy: `createCopyButton()` with document.on.document icon

## Critical Issue Previously Present
The HealthKit change detection correctly calls `clearHKdata()` when settings change, but the subsequent trkrData cleanup was overly aggressive. However, this was not the root cause of the manual data deletion issue - that was in the `voNumber.loadHKdata()` query logic that incorrectly processed manually-entered data.

## Last Updated
2025-10-16 - **Added "from Apple Health" to Table Subtitles** (lines 511-528):
- **Enhancement**: Added "from Apple Health" text to subtitles for HealthKit-enabled number valueObjs
- **Location**: addTrackerController table view subtitle generation
- **Implementation**:
  - Added `healthIndicator` variable: `isAhkSource ? "from Apple Health - " : ""`
  - Updated no-graph case (line 516): `"\(vtypeNames) - \(healthIndicator)no graph"`
  - Updated standard format case (line 528): `"\(vtypeNames) - \(healthIndicator)\(voGraphSet!) - \(colorNames)"`
  - Choice and Info cases unchanged (they don't support HealthKit)
- **Behavior**:
  - Number with HealthKit: `"number - from Apple Health - line - red"`
  - Number without HealthKit: `"number - line - red"`
  - Number with HealthKit, no graph: `"number - from Apple Health - no graph"`
  - Other types unchanged: `"choice - dots"`, `"info"`, etc.
- **Type-safe**: Only VOT_NUMBER can have `ahksrc == "1"`, so indicator naturally only appears for numbers
- **Complements existing red heart icon** at lines 495-498 for visual consistency

Previous update:
2025-10-15 - **Updated HealthKit Source Indicator** (lines 495, 498):
- **Symbol Change**: `"heart.text.square"` → `"heart.fill"` for HealthKit sources
- **Color Change**: `.systemBlue` → `.systemRed` for HealthKit sources
- Maintains `.systemBlue` for Other Tracker ("link") and Function sources
- Consistent with health status button and UseTrackerController indicators
- Clear visual distinction: Red heart = HealthKit, Blue link = Other Tracker, Blue function = Function
- Affects valueObj list display in tracker configuration screen

Previous update:
2025-09-26 - Button consolidation fixes applied:
- Updated to use consolidated button system (createNavigationButton, createActionButton)
- Resolved compilation errors from button function consolidation
- All button functionality preserved with cleaner implementation