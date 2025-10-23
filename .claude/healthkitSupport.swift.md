# healthKitSupport.swift Analysis Notes

## Purpose & Role
Handles HealthKit integration for querying and processing health metrics, category data, and workout data based on configurations from healthKitData.swift. Supports all three sample types with appropriate authorization and data existence checking.

## Key Classes/Structs/Protocols
- `rtHealthKit`: Main ObservableObject class for HealthKit integration
- Handles quantity types, category types, and workout types with unified processing
- Authorization status checking and data existence verification
- Configuration loading and storage with MenuTab preservation

## Important Methods/Functions
- `loadHealthKitConfigurations()`: Loads and processes all HealthKit configurations with MenuTab preservation
- `checkHealthKitAuthorization()`: Checks authorization status without showing permission sheet, updates database accordingly
- `requestHealthKitAuthorization()`: Handles authorization requests for all sample types (shows permission sheet)
- `workoutPredicate(for:startDate:endDate:)`: Creates predicates for workout queries with activity and location filtering
- `handleCategoryTypeQuery()`: Specialized handler for category data including Mindful Minutes
- `handleWorkoutQuery()`: Processes workout data for duration, energy, and distance metrics
- Switch-based sample type handling (quantity/category/workout) in authorization and data checking

## Dependencies & Relationships
- Depends on healthKitData.swift for query configurations including MenuTab system
- Uses HealthKit framework for comprehensive data queries (quantity/category/workout types)
- Integrates with `HealthDataQuery.makeSampleType()` for type creation
- Provides processed data to tracker system with proper MenuTab preservation

## Notable Patterns & Conventions
- Switch statement on `query.sampleType` for unified type handling (.quantity/.category/.workout)
- Consistent authorization checking pattern across all sample types
- Predicate construction for workout activity and location filtering
- MenuTab preservation in configuration loading to prevent override loss
- Specialized value conversion for category data (duration calculations)

## Implementation Details
- **Three-Way Sample Type Support**: Unified handling for quantity/category/workout types
- **Critical MenuTab Fix**: Preserved menuTab field in loadHealthKitConfigurations() reconstruction
- **Workout Predicate Construction**: Supports activity type filtering and indoor/outdoor location filtering
- **Category Data Processing**: Handles duration calculations for Mindful Minutes and other category types
- **Authorization Management**: Comprehensive permission requests for all supported HealthKit types
- Custom sleep data processing with night-based grouping
- Handles predicate creation for category-based filtering

## Recent Development History
- **Latest Changes**: Major expansion to support comprehensive workout tracking and MenuTab system
- **Sample Type Restructuring**: Replaced string-based type checking with SampleType enum handling
- **Workout Support**: Added complete workout query support with activity and location filtering
- **Category Data Expansion**: Enhanced category type handling for Mindful Minutes and other types
- **MenuTab Preservation**: Fixed critical bug where menuTab overrides were lost during configuration loading
- **Authorization Updates**: Extended permission requests to include workout types

## Current Issues & TODOs
- **COMPLETED (2025-10-15)**: Fixed sleep category name parsing in updateAuthorisations
- **COMPLETED (2025-10-08)**: Added Awake Segments case handler for counting nighttime awakenings
- **COMPLETED (2025-09-29)**: Fixed date attribution for interval-based measurements using `useEndDate` flag
- **COMPLETED (2025-09-29)**: Fixed sleep cycles/segments/transitions naming mismatch

## Last Updated
2025-10-21: **Removed checkHealthKitAuthorization() and Fixed Read Permission Detection** (lines 153-377):
- **Critical Discovery**: HealthKit's `authorizationStatus(for:)` only checks WRITE permissions, not READ permissions
  - Line 217 comment confirmed: `// only checks write access, cannot query read access`
  - Privacy feature: Apps can't determine if user denied READ access or if there's no data
  - `checkHealthKitAuthorization()` always returned `.sharingDenied` for read-only access
- **Problem**: `updateAuthorisations(request: false)` only checked authorization, didn't query data
  - Called broken `checkHealthKitAuthorization()` function
  - Database incorrectly updated with status 2 (denied) even when read access was granted
  - Button icon showed wrong state after external permission changes
- **Solution**: Restructured to ALWAYS query for actual data in both paths
  - **Deleted** `checkHealthKitAuthorization()` function entirely (lines 379-446 removed)
  - **Restructured** `updateAuthorisations()` with helper function `runDataCheckingLoop()`
  - `request: true` → Request permissions THEN query data
  - `request: false` → Skip permission request, query data directly
  - Both paths now check authorization status AND data existence
- **Data Checking Flow** (extracted as closure):
  - Queries HealthKit for actual sample data
  - Sets status 1 (enabled) if authorized AND data exists
  - Sets status 3 (notPresent) if authorized but no data
  - Sets status 2 (notAuthorised) if not authorized
- **Impact**:
  - ✅ Detects external permission changes (Settings app)
  - ✅ Button icon correctly reflects actual data availability
  - ✅ No more false "Sharing Denied" for enabled read permissions
  - ✅ Async button update works properly (queries data instead of broken auth check)
  - ✅ Database stays accurate across app sessions

Previous update:
2025-10-21: **Made Database Cleanup Optional in checkHealthKitAuthorization()** (lines 375-383):
- **Previous Problem**: Function always deleted entire database on every call
  - Caused data loss when async button update ran at app startup
  - Button showed correct icon initially, then async task wiped database and changed icon
  - Status 1 (authorized with data) entries were lost and replaced with status 2/3
- **Solution**: Added `cleanDatabase: Bool = false` parameter
  - Database only deleted when explicitly requested with `cleanDatabase: true`
  - Default behavior (`cleanDatabase: false`) preserves existing data
  - Uses INSERT...ON CONFLICT DO UPDATE to update existing entries without deletion
- **Impact**:
  - Async button update no longer wipes database
  - Status 1 entries preserved across app sessions
  - Icon stays correct after permissions are granted
  - Orphaned entries handled by ON CONFLICT UPDATE (existing entries updated, new ones inserted)

Previous update:
2025-10-21: **Added Database Cleanup in checkHealthKitAuthorization()** (lines 378-381):
- **Problem**: Database contained orphaned/stale entries with old display names
  - Old sleep entries: "Sleep - Core" (with dash)
  - Current entries: "Core Sleep" (no dash) or "Sleep: Awake" (with colon)
  - Old workout entries with obsolete identifiers
  - Result: 49 status 1 (enabled) items that were never updated, causing wrong icon
- **Root Cause**: Display name changes over time left duplicate/orphaned database rows
- **Solution**: Added `DELETE FROM rthealthkit` at start of `checkHealthKitAuthorization()`
  - Clears all existing entries before repopulating
  - Ensures database always matches current `healthDataQueries` array
  - Eliminates orphaned entries with old naming conventions
- **Impact**:
  - No more stale status 1 entries
  - Icon correctly shows `heart` when all permissions denied
  - Database stays synchronized with code configuration
  - Clean slate on every authorization check

Previous update:
2025-10-21: **Fixed Database Overwrite Bug in updateAuthorisations()** - Major refactoring (lines 153-373):
- **Critical Bug**: Second loop (lines 172-369) was overwriting correct database values set by `checkHealthKitAuthorization()`
  - Lines 222-223, 242-243, 349-350: Forced `status = .sharingAuthorized` even when `.sharingDenied`
  - This caused denied items to be marked as status 3 (notPresent) instead of status 2 (notAuthorised)
  - Result: Wrong icon displayed (heart.fill instead of heart)
- **Root Cause**: Both `checkHealthKitAuthorization()` AND data-checking loop ran for `request==false`, causing double-processing
- **Solution**: Restructured function to prevent redundant processing:
  - `request==true`: Request authorization → Check authorization + data existence → Update database
  - `request==false`: Check authorization only → Update database → Done (NO data checking)
- **Code Changes**:
  - Moved data-checking loop (formerly lines 172-369) INSIDE `if request` block
  - Added separate `else` block for `request==false` that only calls `checkHealthKitAuthorization()`
  - Eliminated double-processing and database overwrites
- **Behavior Now**:
  - When permissions denied: Correctly sets status 2 (notAuthorised) and keeps it
  - Icon logic correctly shows `heart` (empty) when no status 1 items exist
  - No spurious "Authorized but No Data Present" messages for denied items
- **Impact**: Fixes icon state and database integrity for all authorization scenarios

Previous update:
2025-10-21: **Refactored Authorization Checking** - Created new `checkHealthKitAuthorization()` function (lines 375-486):
- **Refactoring**: Extracted authorization checking logic from `updateAuthorisations()` into dedicated function
- **Function Signature**: `checkHealthKitAuthorization(healthDataQueries: [HealthDataQuery])` - mirrors `requestHealthKitAuthorization()`
- **Purpose**: Checks authorization status without showing permission sheet, updates database accordingly
- **Implementation**:
  - Loops through all `healthDataQueries` to check authorization status
  - Uses `healthStore.authorizationStatus(for:)` for read-only permission checking
  - Handles all three sample types: `.quantity`, `.category`, `.workout`
  - Updates database based on three authorization states:
    - `.notDetermined`: Sets `enableStatus.notAuthorised` (permission not requested yet)
    - `.sharingDenied`: Sets `enableStatus.notAuthorised` (permission explicitly denied)
    - `.sharingAuthorized`: Sets `enableStatus.enabled` (permission granted)
- **Key Feature**: No permission sheet shown - only reads existing authorization state
- **Database Updates**: Uses same SQL pattern as rest of function (INSERT...ON CONFLICT DO UPDATE)
- **Caller**: `updateAuthorisations()` now calls this function when `request == false` (line 167)

Previous update:
2025-10-15: **Sleep Category Name Parsing Fix** - Fixed critical bug in `updateAuthorisations()` function (lines 241-310):
- **Problem**: Function was parsing sleep display names expecting dash separator (e.g., "Sleep - Awake"), but actual names use colon or no separator (e.g., "Sleep: Awake", "Core Sleep")
- **Symptom**: All sleep categories logged "No suffix found in displayName" errors and failed to check for data availability
- **Solution**: Replaced complex string splitting/parsing logic with direct display name matching using switch statement
- **Fixed Display Names**:
  - "Sleep: Awake", "Core Sleep", "REM Sleep", "Deep Sleep"
  - "Sleep", "Specified Sleep", "Sleep: In Bed"
  - "Deep Sleep Segments", "REM Sleep Segments", "Awake Segments"
  - "Sleep Cycles", "Sleep Transitions"
- **Also Fixed**: Line 315 - Changed "Sleep - Cycles" to "Sleep Cycles" for REM check consistency
- **Result**: Eliminates all parsing errors, correctly checks for sleep data availability, proper authorization status in database
- **Code Quality**: Simpler, more maintainable switch statement vs complex parsing with fallthrough cases

Previous update:
2025-10-08: **Awake Segments Handler Added** - Added new switch case in `handleSleepAnalysisQuery()` for "Awake Segments" (lines 684-698). Uses `countSleepSegments()` with:
- `targetValue: HKCategoryValueSleepAnalysis.awake.rawValue`
- `allowedGapValues: [:]` (no gaps allowed)
- `maxGapMinutes: 0`
- `minDurationMinutes: 2` (only count awake periods of 2+ minutes)

This reuses the existing `identifySleepSegments()` infrastructure, matching the awake segment logic already used in `countSleepCycles()` function (lines 900-905).

Previous:
2025-09-29: **Sleep Cycles Naming Fix** - Fixed critical bug in `handleSleepAnalysisQuery()` where switch cases used incorrect display names with dashes ("Sleep - Cycles", "Sleep - Deep Segments", etc.) instead of the actual names from healthkitData.swift ("Sleep Cycles", "Deep Sleep Segments", etc.). This caused specialized counting functions to never execute, resulting in 0 values for sleep cycles, segments, and transitions. Fixed by updating switch cases to match actual display names (lines 649, 665, 684, 697).

Previous: 2025-09-29 - Date Attribution Fix for interval-based measurements.