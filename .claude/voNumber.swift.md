# voNumber.swift Analysis Notes

## Purpose & Role
Handles numeric input fields in trackers, supporting manual entry, HealthKit integration, and other tracker data sources. Manages display, validation, data storage, and external data synchronization for numeric values. Includes enhanced ahPrevD (previous day) support with proper date shifting logic.

## Key Classes/Structs/Protocols
- `voNumber`: Main class extending `voState` and implementing `UITextFieldDelegate`
- `UITextField` (`dtf`): The primary input control
- `rtHealthKit`: Shared instance for HealthKit integration
- Static `healthKitCache`: Caches HealthKit data by source-date-unit key

## Important Methods/Functions
- `voDisplay(_:)`: Creates and configures the text field, handles HealthKit/Other Tracker data loading
- `update(_:)`: Returns current value, handles time format conversion
- `loadHKdata(forDate:dispatchGroup:)`: Loads HealthKit data into database with enhanced ahPrevD support and ahkTimeSrc handling
- `clearHKdata(forDate:)`: Removes HealthKit-sourced data from database
- `createTextField()`: Sets up the UITextField with proper formatting and input accessories
- `textFieldDidEndEditing(_:)`: Handles value changes and notifications
- `handleHkTimeSrc(datesToMerge:tracker:srcName:)`: Distance-sorted greedy matching algorithm for ahkTimeSrc mode
- `processHealthQuery()`: Enhanced HealthKit data processing with proper date shifting for ahPrevD
- `getHealthKitDates()`: Improved date handling using `HealthDataQuery.makeSampleType()`

## Dependencies & Relationships
- Imports: Foundation, UIKit, SwiftUI, HealthKit
- Extends: `voState`
- Implements: `UITextFieldDelegate`
- Uses: `rtHealthKit`, `trackerObj`, `valueObj`
- Database tables: `voData`, `voHKstatus`, `trkrData`

## Notable Patterns & Conventions
- Lazy initialization of text field with frame-based recreation
- HealthKit caching with compound keys
- Time format conversion (HH:MM to minutes)
- External data overlay system for non-editable fields
- Placeholder text varies based on data source type
- Input accessory toolbar with Done and minus buttons (modern SF symbols)

## Implementation Details
- **ahkTimeSrc Support**: When tracker has time source designated, uses distance-sorted matching instead of 12:00 normalization
  - `handleHkTimeSrc()` function implements optimal nearest-neighbor algorithm
  - Builds candidate (HK sample, trkrData) pairs, sorts by distance, greedily assigns shortest matches
  - Unmatched samples create new trkrData entries at actual HealthKit timestamps
  - Preserves actual measurement times (e.g., 08:45, 14:30, 19:20) instead of collapsing to 12:00
- **Enhanced ahPrevD Support**: Proper date shifting logic - shifts trkrData dates forward for storage, shifts HealthKit query dates backward
- **HealthKit Integration**: Uses `HealthDataQuery.makeSampleType()` for unified type creation, supports all sample types
- **Date Management**: Complex dual-direction shifting for ahPrevD mode to handle "previous day" data attribution
  - Date adjustments handled by mergeDates (for aggregationTime) and processHealthQuery (for sleep_hours)
  - Previous redundant adjustment logic in loadHKdata has been removed (commented out)
- **Debug Enhancements**: Added debug date limiting (3 months back) and improved logging with target dates
- **Data Storage**: Values stored as text in voData table, with associated voHKstatus entries for HealthKit tracking
- **Display Logic**: Shows "<no data>" for empty HealthKit fields, different placeholders for manual vs external data
- **Input Handling**: Decimal pad keyboard with blue checkmark Done button (checkmark.circle), minus/plus toggle button (minus.forwardslash.plus) for sign changes
- **Privacy**: Respects privacy levels for data access

## Recent Development History
**Latest Changes (2025-10-13) - Consistent Ghosted Display for Empty HealthKit Data:**
- **UI Improvement**: Changed empty HealthKit data display for physiological units to use ghosted placeholder
- **Problem**: Current records showed "No HealthKit data available" as solid text, while historical records showed ghosted "<no data>" placeholder
- **Solution**: Changed line 265 from `self?.noHKdataMsg` to `""` (empty string)
- **Behavior**:
  - Time/count units still show "0" as solid text (unchanged)
  - Physiological units (mmHg, bpm, etc.) now show ghosted "<no data>" placeholder (consistent with historical)
- **Impact**: Blood pressure systolic/diastolic now display consistently across current and historical records
- **Note**: `noHKdataMsg` property at line 33 is now unused and can be removed in future cleanup

**Latest Changes (2025-10-13) - Singleton Frequency Implementation:**
- **handleSingletonMatching() Function**: New function (lines 1623-1687) for singleton frequency support
  - Matches each HK date to closest tracker timestamp on same calendar day
  - **If no tracker entry exists: SKIPS that day** (does NOT create entries)
  - If tracker entry exists: finds closest timestamp using minimum distance
  - Returns (newDates, matchedDates) tuple like handleHkTimeSrc
  - Logs distance in minutes for debugging: "Δ42min"
  - **Key behavior**: Only populates **existing** tracker entries, never creates new ones
  - **Optimization** (lines 1634-1647): Batch database query instead of per-day queries
    - Queries ALL tracker timestamps once (1 SQL query instead of N)
    - Groups by calendar day in memory using dictionary: `[String: [TimeInterval]]`
    - Fast O(1) dictionary lookup per HK date instead of repeated SQL queries
    - Major performance improvement when processing multiple days
- **Date Processing Logic Update**: Modified loadHKdata date merging section (lines 1026-1054)
  - Added `if frequency == "singleton"` branch before `else if frequency == "daily"`
  - Singleton calls handleSingletonMatching() instead of mergeDates or handleHkTimeSrc
  - Maintains separate paths: singleton → daily → time slots
- **processHealthQuery() Enhancement**: Updated to handle singleton queries (lines 1802-1814, 1836-1871)
  - **Optimized Query Window**: Singleton queries ±2 hour window around target timestamp (4 hours total)
  - Window clamped to calendar day boundaries (doesn't cross midnight)
  - 6x smaller queries than full day (4 hours vs 24 hours)
  - Stores targetTimestamp for finding closest match
  - Completion handler branches: singleton uses findClosestResult, others use time filter + aggregation
  - Time filter and aggregation completely bypassed for singleton
- **findClosestResult() Function**: New helper function (lines 1913-1934)
  - Takes all HK results from day query and target timestamp
  - Returns single result with minimum abs(result.date - targetTimestamp)
  - Logs distance in minutes: "Δ15min from target"
  - Returns nil if no results
- **calculateEndDate() Update**: Comment updated (line 1898) to clarify singleton returns nil like daily
- **Singleton Behavior**: Picks single closest HK datapoint to tracker timestamp per day
  - **Query window**: ±2 hours around target (4-hour total window)
  - No time filtering (searches within window)
  - No aggregation (one value per day)
  - Target is existing tracker entry timestamp (from ahkTimeSrc or manual entry)
  - Only searches within ±2 hour window on same calendar day
  - **Does NOT create new tracker entries** - only fills existing ones
  - **Performance**: 6x faster queries than full-day search
- **Use Cases**:
  - With ahkTimeSrc: Time source creates entries → singleton fills HK values at those timestamps
  - Without ahkTimeSrc: Singleton only fills days where user manually created entries
- **UI Integration**: Works with ahViewController.swift changes (singleton picker option, conditional UI hiding)

**Previous Changes (2025-10-13) - High-Frequency Data Fix for ahkTimeSrc:**
- **Bug Fix**: Excluded high-frequency data from ahkTimeSrc matching to prevent excessive logging
- **Problem**: High-frequency HealthKit data (100+ HRV samples) triggered 100+ identical log messages
- **Root Cause**: `collapseTimeFilterWindow()` with `timeFilter="all_day"` returned all timestamps unchanged, causing `handleHkTimeSrc()` to process each individual sample
- **Solution**: Added `isHighFrequency` check at line 1025 to route high-freq data to `mergeDates()` instead of `handleHkTimeSrc()`
- **Rationale**: ahkTimeSrc is designed for discrete measurements (blood pressure readings), not aggregated high-freq data (HRV, heart rate)
- **Impact**: High-frequency data now correctly aggregates to single daily value regardless of ahkTimeSrc setting

**Previous Changes (2025-10-13) - ahkTimeSrc Distance-Sorted Matching:**
- **New Feature**: Support for `tracker.optDict["ahkTimeSrc"]` to preserve actual HealthKit timestamps
- **handleHkTimeSrc() Function**: New private helper function implementing distance-sorted greedy matching algorithm
  - Queries existing trkrData for same calendar day
  - Builds all possible (HK sample, trkrData) candidate pairs with distances
  - Sorts candidates by distance (shortest first) - key for optimal matching
  - Greedy assignment: matches shortest distances first using nearest unused neighbor
  - Unmatched HK samples become new trkrData entries at actual times
  - Complexity: O(nm log nm) where n=samples, m=trkrData entries
- **loadHKdata Integration**: Modified date merging logic in loadHKdata function
  - Detects `trackerHasTimeSrc` flag from tracker.optDict
  - Calls `handleHkTimeSrc()` instead of `mergeDates()` when ahkTimeSrc enabled
  - Falls back to normal `mergeDates()` behavior (12:00 normalization) when disabled
- **Code Organization**: Refactored 82 lines of inline matching logic into dedicated function
- **Benefits**: Near-optimal timestamp matching, no arbitrary time thresholds, handles all edge cases naturally
- **Use Case**: Blood pressure tracker with multiple readings per day (08:45, 14:30, 19:20) creates separate entries

**Previous Changes (2025-10-02) - Date Adjustment Section Removed:**
- **Commented Out Entire Section**: The 36-hour window guard and all date adjustment logic (aggregation boundary and sleep_hours) has been commented out in loadHKdata function
- **Reason**: mergeDates already handles aggregationTime, processHealthQuery handles sleep_hours - adjustments were redundant
- **Comment Note**: "think not needed because mergedates handles aggregationTime, processHealthWQuery handles sleep_hours"
- **Code Preserved**: Entire block wrapped in /* */ for potential future reference
- **Impact**: Simplified loadHKdata logic by removing duplicate date handling

**Previous Changes (2025-10-02) - Date Adjustment Conditional (NOW REMOVED):**
- **36-Hour Window Guard**: Added conditional check to only apply aggregation boundary and sleep_hours adjustments when both dates defined and window < 36 hours
- **NOTE**: This entire section was subsequently commented out as redundant

**Previous Changes (2025-10-02) - Major Deduplication and Helper Functions:**
- **Set-Based Deduplication**: Converted `newDates` and `matchedDates` from Arrays to Sets to automatically eliminate duplicates
  - voNumber.swift lines 671-672: Changed declarations to `Set<TimeInterval>`
  - trackerObj.swift mergeDates/generateTimeSlots: Updated return types and implementations to use Sets
  - Removed manual O(n) duplicate checking (lines 538-540 in trackerObj.swift)
  - Used `.union()` for combining sets instead of array concatenation
- **Date Formatting Helpers**: Added `ltd()` and `i2ltd()` functions in dbg-defs.swift
  - `ltd(Date, secs: Bool = false)`: Formats Date as "HH:mm dd-MM-yy" or "HH:mm:ss dd-MM-yy"
  - `i2ltd(Int, secs: Bool = false)`: Formats Unix timestamp with "i:" prefix for identification
  - Replaced all `Date(timeIntervalSince1970:).description` with cleaner `i2ltd()`/`ltd()` throughout loadHKdata
- **Timestamp Precision**: Updated DBGLog/DBGWarn/DBGErr to show 6 decimal places (String.format "%.6f")
- **Debug Date Limiting**: Enhanced to support both months and days (debugMonthsBack=0, debugDaysBack=3)
- **Sleep Hours Query Fix**: Updated processHealthQuery to handle sleep_hours time filter correctly
  - Added timeFilter parameter to calculateEndDate
  - Adjusts startDate to 23:00 previous day for sleep_hours + daily frequency
  - Returns proper endDate of 06:00 tracker day
  - Lines 1490-1511, 1540-1571
- **Window Logging**: Reduced spam - logs first, last, and every 10th window only (line 887-893)
- **daysBetween Fix**: Ensures at least 1 day to prevent division issues (line 853)

**Previous Changes (2025-10-01) - Sleep Hours Time Filter Date Adjustment (CORRECTED):**
- **Fixed HRV Sleep Hours Window**: Implemented missing date adjustment for high-frequency data with `sleep_hours` time filter
- **Correct Timezone Handling**: Uses `.byAdding` instead of `.bySettingHour` to avoid timezone offset bugs
- **Consistent Query Windows**: Now queries fixed 23:00 previous day to 06:00 tracker day (local time) regardless of refresh time
- **Implements XXX Comment**: Addresses the long-standing XXX comment at line 763 about sleep hours date adjustment
- **Location**: Lines 735-768 in loadHKdata function
- **Bug Fix**: Initial implementation using `.bySettingHour` had timezone issues (added offset instead of handling correctly); corrected to use `.byAdding .hour` for precise time arithmetic

**Previous Changes (2025-09-28) - Enhanced ahPrevD and HealthKit Integration:**
- **Major ahPrevD Overhaul**: Complete redesign of previous day logic with proper bidirectional date shifting
- **HealthKit Type Support**: Updated to use `HealthDataQuery.makeSampleType()` for unified quantity/category/workout support
- **Date Shifting Logic**:
  - For ahPrevD: Store dates shifted +1 day in trkrData, query HealthKit with dates shifted -1 day
  - Ensures "previous day" data appears on correct tracker date
- **Debug Enhancements**: Added 3-month debug date limiting and improved target date logging
- **Storage Date Calculation**: Enhanced processHealthQuery to handle date shifting for proper storage location

**Previous Major Changes:**
- **Keyboard Accessory Modernization**: SF symbol buttons (checkmark.circle, minus.forwardslash.plus)
- **Data Management Fixes**: Prevented manual data deletion when disabling HealthKit sources
- **Cache Improvements**: Enhanced HealthKit caching with unit-specific keys

## Current Issues & TODOs
- **COMPLETED** (2025-10-15): Added Apple Health status button to configuration screen
- **COMPLETED** (2025-10-13): Ghosted placeholder display for empty physiological HealthKit data
- **COMPLETED** (2025-10-13): High-frequency data excluded from ahkTimeSrc matching to prevent log spam
- **COMPLETED** (2025-10-13): ahkTimeSrc feature - distance-sorted matching for actual timestamps
- **COMPLETED** (2025-10-09): Unit-based zero display for no-data HealthKit values
- **COMPLETED** (2025-10-07): Transaction handling bug fix - prevent "no transaction in progress" error
- **COMPLETED** (2025-10-02): Set-based deduplication to eliminate duplicate HealthKit queries
- **COMPLETED** (2025-10-02): Date formatting helper functions (ltd/i2ltd) for cleaner debug logs
- **COMPLETED** (2025-10-02): Sleep hours query fix in processHealthQuery
- **COMPLETED** (2025-10-01): Sleep hours time filter date adjustment for consistent query windows
- **COMPLETED**: Enhanced ahPrevD implementation with proper date shifting
- **COMPLETED**: HealthKit integration updated for all sample types (quantity/category/workout)
- **COMPLETED**: Debug enhancements for development efficiency
- **COMPLETED**: Keyboard accessory button modernization with SF symbols

## Issues Fixed
- **Transaction Overlap Error** (2025-10-07): Fixed "cannot start a transaction within a transaction" and "no transaction in progress" errors when opening trackers with HealthKit data. Root cause: When processing multiple HealthKit valueObjs sequentially, a single long transaction with async operations caused the COMMIT to execute too late - the second valueObj's BEGIN would run before the first's COMMIT completed. Solution: Restructured into three separate transactions that each commit synchronously before control returns to caller, preventing overlap between sequential valueObj processing.
- **HRV Sleep Hours Inconsistent Values Bug** (2025-10-01): Fixed issue where HRV with sleep_hours time filter returned different values for the same date when refreshed at different times. Root cause was rolling 24-hour query window that varied based on refresh time. Solution: Added fixed time window adjustment (23:00 previous day to 06:00 tracker day, local time) for high-frequency data with sleep_hours filter at lines 735-761. Initial implementation using `.bySettingHour` had timezone bugs (offset applied incorrectly); corrected to use `.byAdding .hour` for accurate time arithmetic. Implements the XXX comment at line 763 that identified this missing feature.
- **HealthKit Data Clearing Bug**: The loadHKdata query was incorrectly processing dates with manually-entered data, creating voHKstatus entries that caused manual data to be deleted when HealthKit was disabled. Fixed by modifying the SQL query to exclude dates that already have manually-entered voData.
- **HealthKit Cross-Contamination Bug** (2025-08-26): Fixed issue where low-frequency HealthKit valueObjs would repeatedly reprocess dates where we already knew there was `noData`. The complex OR-based SQL query only excluded `stat = hkData` entries but allowed `stat = noData` entries to be reprocessed indefinitely. Simplified to exclude ANY existing voHKstatus entry for the specific valueObj, preventing unnecessary reprocessing of dates we've already attempted.

## Last Updated
2025-10-15 - **Fixed Health Button Horizontal Position** (line 1562-1564):
- **Problem**: Button overlapped right 1/3 of switch instead of being positioned to the right
  - Line 1564 calculated: `x: frame.origin.x + frame.size.width + SPACE`
  - But `frame.size.width` was set to `labframe.size.height` (label height, ~20pt)
  - UISwitch actual width is ~51pt (intrinsic size)
  - Button appeared at x + 20pt instead of x + 51pt
- **Root Cause**: configSwitch returns the frame passed to it, which doesn't reflect UISwitch intrinsic size
  - UISwitch enforces its own standard width regardless of frame
  - Frame width was arbitrarily set to label height for layout purposes
- **Solution**: Use standard UISwitch width constant (51pt) instead of frame.size.width
  - Added: `let switchWidth: CGFloat = 51.0  // Standard UISwitch width`
  - Changed x calculation to: `frame.origin.x + switchWidth + SPACE`
- **Result**: Button now positioned correctly to the right of switch with proper spacing

Previous update:
2025-10-15 - **Fixed Health Button Positioning and Presentation** (lines 1421-1433, 1569):
- **Problem 1 - Wrong Parent View**: Button added to `ctvovc.view` instead of `ctvovc.scroll`
  - All form elements (switches, labels, etc.) are added to scroll view
  - Button was positioned relative to scroll content but added to wrong container
  - Result: Button appeared in wrong location
- **Problem 2 - Presentation Not Working**: Complex navigation controller logic failed silently
  - Conditional check for navigationController might have been failing
  - No error logging when presentation failed
- **Solution 1 - Scroll View** (line 1569):
  - Changed: `ctvovc.view.addSubview(healthButton)`
  - To: `ctvovc.scroll.addSubview(healthButton)`
  - Now consistent with switch positioning (configSwitch adds to scroll at line 545)
- **Solution 2 - Direct Presentation** (lines 1429-1432):
  - Changed: Complex conditional with navigationController
  - To: `ctvovcp?.present(hostingController, animated: true)`
  - Same proven pattern as `configAppleHealthView()` (line 1490)
  - Added completion handler with debug log
- **Result**: Button now appears in correct location and opens HealthStatusViewController on tap

Previous update:
2025-10-15 - **Fixed Health Button Using Standard UIBarButtonItem Pattern** (lines 1555-1570):
- **Problem**: Initial implementation broke established iOS 26 button pattern
  - Created custom `createInlineHealthButton()` that returned UIButton directly
  - Violated pattern used throughout codebase where ALL functions return UIBarButtonItem
- **Solution**: Use standard `.uiButton` extraction pattern (same as everywhere else)
  - `createHealthButton()` returns UIBarButtonItem (consistent with all button functions)
  - Use `.uiButton` property to extract underlying UIButton
  - Same pattern as voNumber keyboard buttons (lines 123, 131)
  - Same pattern as privacyV buttons, datePickerVC, ppwV, voTextBox
- **Implementation**:
  ```swift
  let healthButtonItem = rTracker_resource.createHealthButton(...)
  if let healthButton = healthButtonItem.uiButton {
      healthButton.frame = CGRect(...)
      ctvovc.view.addSubview(healthButton)
  }
  ```
- **Button Positioning**: To right of ahsBtn switch, 30pt width, aligned height, same line as label
- **Action Handler**: Lines 1421-1434 `showHealthStatus()` - presents `HealthStatusViewController` without config instructions
- **Integration**: Uses standard `createHealthButton()` with `.uiButton` extraction
- **Symbol States**: heart/heart.fill/arrow.trianglehead.clockwise.heart based on DB status
- **Consistency**: Now follows same pattern as all other inline button placements
- **Accessibility ID**: `voNumber_health` for UI testing

Previous update:
2025-10-13 - Consistent Ghosted Display for Empty HealthKit Data:
- **UI Fix**: Changed empty HealthKit data display for physiological units to use ghosted placeholder instead of solid text
- **Change**: Modified voDisplay function at line 265 from `self?.noHKdataMsg` to `""` (empty string)
- **Behavior Before**:
  - Current record: "No HealthKit data available" as solid text
  - Historical record: "<no data>" as ghosted placeholder
  - Inconsistent appearance between current and historical
- **Behavior After**:
  - Current record: "<no data>" as ghosted placeholder (uses UITextField.placeholder)
  - Historical record: "<no data>" as ghosted placeholder (unchanged)
  - Consistent ghosted appearance across all views
- **Units Affected**: Physiological metrics (mmHg, bpm, %, ms, etc.) - time/count units still show "0" as intended
- **User Experience**: Blood pressure systolic/diastolic now have consistent ghosted display whether viewing current or historical records

Previous update:
2025-10-13 - High-Frequency Data Fix for ahkTimeSrc:
- **Bug Fix**: Excluded high-frequency HealthKit data from ahkTimeSrc matching algorithm
- **Problem**: High-frequency valueObjs (HRV, heart rate) with 100+ samples per day were logging excessive "→ NEW (no unused trkrData)" messages
- **Root Cause**: `collapseTimeFilterWindow()` with `timeFilter="all_day"` returned all individual timestamps unchanged, causing `handleHkTimeSrc()` to process each sample separately
- **Implementation** ([voNumber.swift:1025-1040](Classes/voNumber.swift#L1025-L1040)):
  - Added `isHighFrequency` check: `queryConfig.aggregationType == .highFrequency`
  - Modified conditional: `if trackerHasTimeSrc && !isHighFrequency` routes only discrete measurements to `handleHkTimeSrc()`
  - High-frequency data now always uses `mergeDates()` with 12:00 normalization, regardless of ahkTimeSrc setting
- **Rationale**: ahkTimeSrc is designed for discrete measurements (multiple blood pressure readings per day), not aggregated high-frequency data (HRV averaging 100 samples into 1 daily value)
- **Impact**: Eliminates log spam, ensures high-freq data aggregates correctly to single daily entry

Previous update:
2025-10-13 - ahkTimeSrc Distance-Sorted Matching Algorithm:
- **New Feature**: Trackers can now preserve actual HealthKit timestamps when `ahkTimeSrc` is set
- **Implementation**:
  - Added `handleHkTimeSrc()` private function with optimal nearest-neighbor matching algorithm
  - Modified loadHKdata to call handleHkTimeSrc() or mergeDates() based on tracker configuration
  - Refactored code for better organization (extracted 82-line algorithm into dedicated function)
- **Algorithm**: Distance-sorted greedy matching - builds candidate pairs, sorts by distance, assigns shortest matches first
- **Behavior**: When ahkTimeSrc enabled, matches HK samples to nearest unused trkrData timestamp; unmatched samples create new entries
- **Benefits**: Preserves measurement timing context (e.g., morning vs evening blood pressure), eliminates arbitrary thresholds
- **Backwards Compatible**: Normal 12:00 normalization behavior unchanged when ahkTimeSrc not set

Previous update:
2025-10-09 - Unit-Based Zero Display for No-Data HealthKit Values:
- **Feature**: Added intelligent no-data display based on unit type
- **Implementation**:
  - **Helper Method** (lines 35-52): `shouldShowZeroForNoData(unit:)` checks if unit is time (min/hr) or count
  - **Display Logic** (lines 255-263): Conditionally shows "0" for time/count units, message for physiological metrics
- **Behavior**:
  - **Time/Count Units** (minutes, hours, count): Display "0", process as "0" in functions
    - Examples: Sleep duration, mindful minutes, sleep segments, awakenings
  - **Physiological Units** (milliseconds, bpm, mmHg, percent, etc.): Display message, process as empty
    - Examples: HRV, heart rate, blood pressure, oxygen saturation
- **Rationale**: Zero is meaningful for time/count accumulations (0 minutes of deep sleep = valid data), but misleading for physiological measurements (0 bpm ≠ no data)
- **Function Processing**: Time/count zeros pass through `update()` as "0" for correct aggregation in functions

Previous update:
2025-10-07 - Transaction Overlap Bug Fix:
- **Fixed Transaction Overlap Errors**: Restructured loadHKdata to use three separate, non-overlapping transactions
- **Implementation**:
  - **Transaction 1** (trkrData INSERTs): Lines 1027-1070, commits before async work begins
  - **Transaction 2** (voData/voHKstatus INSERTs): Lines 1141-1252, wraps async HealthKit query callbacks
  - **Transaction 3** (cleanup operations): Lines 1259-1291, final UPDATE and INSERT
- **Key Changes**: Added `transactionStarted` and `dataTransactionStarted` flags (lines 673-674), moved commits to execute synchronously before control returns
- **Performance**: All database operations remain within transactions for batching benefits
- **Safety**: Prevents transaction overlap when processing multiple HealthKit valueObjs sequentially

Previous update:
2025-10-02 - Date Adjustment Section Removed (Code Simplification):
- **Removed Redundant Logic**: Commented out entire date adjustment section in loadHKdata (aggregation boundary and sleep_hours handling)
- **Rationale**: mergeDates already handles aggregationTime, processHealthQuery already handles sleep_hours - adjustments were duplicative
- **Code Preserved**: Entire block wrapped in /* */ comments for potential future reference
- **Impact**: Cleaner, simpler loadHKdata logic without duplicate date handling

Previous update (same day, now superseded):
2025-10-02 - Date Adjustment Conditional (36-Hour Window Guard) - REMOVED:
- **This change was reversed**: The conditional date adjustment logic was added then subsequently commented out as redundant

Previous update:
2025-10-02 - Major Deduplication, Helper Functions, and Sleep Hours Query Fix:
- **Set-Based Deduplication**: Eliminated duplicate HealthKit queries by converting newDates/matchedDates to Sets
- **Date Formatting Helpers**: Added ltd() and i2ltd() for cleaner debug logs with consistent formatting
- **Sleep Hours Query Fix**: processHealthQuery now correctly handles sleep_hours time filter with proper date adjustments (lines 1490-1511, 1540-1571)
- **Debug Improvements**: 6-decimal timestamp precision, flexible debug date limiting, reduced window logging spam
- **Architecture**: Sets provide automatic deduplication, O(1) insertions, and cleaner union operations vs manual array duplicate checking

Previous update:
2025-10-01 - Sleep Hours Time Filter Date Adjustment (CORRECTED):
- **Fixed HRV Inconsistent Values**: Implemented fixed time window (23:00 previous day to 06:00 tracker day) for high-frequency data with sleep_hours filter
- **Timezone Bug Fix**: Corrected from `.bySettingHour` (which incorrectly added timezone offset) to `.byAdding .hour` for accurate time arithmetic
- **Consistent Query Behavior**: Same tracker date now always queries same HealthKit samples regardless of refresh time
- **Code Location**: Lines 735-768 in loadHKdata function, implementing long-standing XXX comment requirement