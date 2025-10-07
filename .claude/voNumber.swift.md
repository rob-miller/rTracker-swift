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
- `loadHKdata(forDate:dispatchGroup:)`: Loads HealthKit data into database with enhanced ahPrevD support
- `clearHKdata(forDate:)`: Removes HealthKit-sourced data from database
- `createTextField()`: Sets up the UITextField with proper formatting and input accessories
- `textFieldDidEndEditing(_:)`: Handles value changes and notifications
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
**Latest Changes (2025-10-02) - Date Adjustment Section Removed:**
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