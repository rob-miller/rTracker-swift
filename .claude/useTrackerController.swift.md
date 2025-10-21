# useTrackerController.swift Analysis Notes

## Purpose & Role
Main view controller for data entry in trackers. Displays value objects in a table view, handles data input, manages external data loading (HealthKit/Other Trackers), and provides navigation between tracker entries.

## Key Classes/Structs/Protocols
- `useTrackerController`: Main class extending `UIViewController`
- Implements: `UITableViewDelegate`, `UITableViewDataSource`, `UITextFieldDelegate`, `MFMailComposeViewControllerDelegate`, `UIAdaptivePresentationControllerDelegate`, `RefreshProgressDelegate`
- Contains: `trackerObj`, `trackerList`, various UI components

## Important Methods/Functions
- `viewDidLoad()`: Sets up UI, loads external data sources (HealthKit/Other Trackers)
- `updateTrackerTableView()`: Refreshes the table display, handles ignored record tinting, forces function recalculation via setFNrecalc()
- `updateTableCells(_:)`: Updates specific cells, forces function recalculation for changed values
- `pullToRefreshStarted(_:)`: Handles pull-to-refresh gestures with progressive refresh
- `handleFullRefresh()`: Comprehensive data reload from all external sources
- `loadTrackerDate(_:)`: Navigates to specific dates, handles data loading/saving, calls updateTrackerTableView()
- `saveActions()`: Saves current tracker data and manages rejectable tracker acceptance

## Dependencies & Relationships
- Heavy integration with `trackerObj` for data management
- Uses `valueObj` and `voState` for individual field handling
- Connects to HealthKit and Other Tracker systems
- Manages `datePickerVC` and `trackerCalViewController` for date navigation
- **Uses DatePickerResult** from datePickerVC.swift for modal communication
- Links to chart system via `TrackerChart` and `graphTrackerVC`

## Notable Patterns & Conventions
- Extensive use of dispatch groups for async data loading
- Pull-to-refresh with progressive escalation (single pull vs multiple pulls)
- Privacy-aware data handling with `privacyValue` checking
- Background data loading with activity indicators and progress bars
- Swipe gesture navigation between dates
- Comprehensive toolbar management with contextual buttons

## Implementation Details
- **Data Loading**: Sequential loading of HealthKit → Other Tracker (non-self) → Function → Other Tracker (self) data
- **Progress Tracking**: Implements `RefreshProgressDelegate` with detailed progress calculation
- **Memory Management**: Careful cleanup of observers and temporary data
- **UI State**: Handles view rotation, keyboard management, and modal presentations
- **Export Features**: Multiple export formats (CSV, tracker files) with sharing
- **Date Picker Integration**: Uses lazy `DatePickerResult` property for communication with modal date pickers
  - `.new` action: Creates new entry with save conflict checking via `createNewEntry()`
  - `.set` action: Changes tracker date and marks as modified (needSave = true)
  - `.goto`/`.gotoPost` actions: Navigates to selected date with save conflict checking
  - Cancel handling: Restores original tracker date when user cancels save alerts

## Recent Development History
**Current Session (2025-10-21) - Function Cache Invalidation Fix:**
- **MAJOR BUG FIX**: Added `setFNrecalc()` call in `updateTrackerTableView()` for VOT_FUNC objects (lines 1274-1276)
- **Problem**: When user changed date for a record, function values used stale cached values
  - Cache validation only checked `ep0date` (previous endpoint), not `epd1` (current entry timestamp from `trackerDate`)
  - Day-of-week functions showed BOTH old and new days as true
  - Any function depending on current entry date (`epd1`) would show incorrect cached results
- **Root Cause**: `updateTrackerTableView()` set `vo.display = nil` but didn't invalidate function caches
- **Fix**: Added VOT_FUNC check with `vo.vos?.setFNrecalc()` call
  - Matches existing pattern in `updateTableCells()` (line 172)
  - Forces cache invalidation by clearing `lastCalcValue` and setting `lastEpd0 = -1`
  - Ensures functions recalculate with new `trackerDate`/`epd1` value
- **Impact**: Functions now correctly recalculate when date changes via currDateBtn or loadTrackerDate()
- **Related**: voFunction.swift (cache validation logic), datePickerVC.swift (date selection)

**Previous Session (2025-09-26) - Date Picker Modernization and Save Handling:**
- **MAJOR**: Updated DatePickerResult integration from legacy dpRslt to modern enum-based system
- **Enhanced save conflict handling**: Added `createNewEntry()` function with proper unsaved changes checking
- **Fixed cancel behavior**: Implemented `originalTrackerDate` restoration when user cancels save alerts
- **Save workflow improvements**:
  - `.new` action now uses `createNewEntry()` with save conflict checking before creating entries
  - `.set` action properly marks tracker as modified (needSave = true) when changing dates
  - Added `CSNEWENTRY` constant and alert response handling for new entry conflicts
- **UI consistency fixes**: Cancel button now correctly displays original tracker date, not attempted goto date
- **Modern enum usage**: All date picker actions now use `.new`, `.set`, `.goto`, `.gotoPost` instead of integer constants

**Previous Session (2025-01-15) - Button System Refactoring:**
- **Eliminated ~216 lines of duplicate code**: Replaced verbose iOS 26 conditional button creation with unified button system
- **Updated 8 buttons**: backButton, menuBtn, calBtn, searchBtn, delBtn, skip2EndBtn, createChartBtn using rTracker-resource functions
- **Color theming**: Pale green calendar, pale blue menu, red back button in rejectable mode, blue search, red delete
- **SF Symbol integration**: Modern symbols (calendar, magnifyingglass.circle, xmark.bin, chevron.forward.to.line, chart.line.uptrend.xyaxis)
- **Accept button enhancement**: Uses arrow.down.doc.fill SF symbol in green for clear import acceptance indication
- **Architecture improvement**: Single source of truth for button styling in rTracker-resource.swift

**Previous Session (September 2025)**: Implemented comprehensive iOS 26 Liquid Glass solution to remove solid white backgrounds on ALL buttons: navigation bar buttons (save, share/menu, back) use hidesSharedBackground=true with standard UIBarButtonItem, toolbar buttons (delete, skip-to-end, chart, calendar, search, date/time) use UIButton.Configuration.glass() with hidesSharedBackground=true. Replaced desk inbox emoji with familiar square.and.arrow.up share icon.
- `1b8f625`: Fixed issue with save-return behavior not resetting data when viewing history
- `c6247bc`: Resolved first view not showing latest HealthKit data
- `49f0a95`: Addressed swipe right navigation definition issues
- `834d4d3`: Implemented comprehensive progress bar for full refresh operations
- `6715510`: Blocked rotation to graph during refresh, added documentation
- `66b26ec`: Added support for hidden valueObjs functionality

## Current Architecture Notes
- **Button System**: All buttons now use unified rTracker-resource functions with consistent iOS 26 styling
- **Refresh System**: Two-tier refresh (light refresh for current record, full refresh for all data)
- **Data Sources**: Supports HealthKit, Other Trackers, Function calculations, and manual entry
- **Privacy Integration**: Respects tracker and valueObj privacy levels
- **Export System**: Comprehensive sharing with temporary file management
- **Navigation**: Complex date navigation with search set support and swipe gestures

## Current Issues & TODOs
- ✅ **COMPLETED (2025-10-21)**: Fixed function cache invalidation when date changes
- ✅ **COMPLETED (2025-10-08)**: Fixed swipe right looping behavior at oldest record
- ✅ **COMPLETED**: DatePickerResult modernization with enum-based actions
- ✅ **COMPLETED**: Save conflict handling for new entries via createNewEntry()
- ✅ **COMPLETED**: Cancel behavior fixed - restores original tracker date
- ✅ **COMPLETED**: Button code duplication eliminated - all 8 buttons now use unified system
- ✅ **COMPLETED**: Color theming implemented for visual distinction
- ✅ **COMPLETED**: SF Symbol integration for modern appearance
- ✅ **COMPLETED**: Accept/reject mode visual clarity with red/green color coding

## Last Updated
2025-10-21 - **Function Cache Invalidation Fix**: Fixed critical bug where function values showed stale cached results when record date was changed. Added `setFNrecalc()` call in `updateTrackerTableView()` at lines 1274-1276 to force function recalculation when `trackerDate` changes. The cache validation logic only checked `ep0date` (previous endpoint) but missed when `epd1` (current entry timestamp) changed, causing day-of-week functions to show both old and new days as true. The fix matches the existing pattern in `updateTableCells()` and ensures all functions recalculate with the new date.

Previous updates:
- 2025-10-08 - Swipe Right Boundary Fix: Prevented looping at oldest record
- 2025-09-26 - Date Picker Modernization: Enhanced save conflict handling and UI consistency fixes