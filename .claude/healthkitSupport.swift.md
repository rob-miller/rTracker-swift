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
- `requestHealthKitAuthorization()`: Handles authorization requests for all sample types
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