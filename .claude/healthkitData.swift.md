# healthKitData.swift Analysis Notes

## Purpose & Role
Defines HealthKit data query configurations for health metrics, workouts, and category data including data types, units, aggregation styles, custom processing logic, and menu tab organization system.

## Key Classes/Structs/Protocols
- `MenuTab`: Enum defining UI tab organization (Metrics/Sleep/Workouts) with title and icon properties
- `HealthDataQuery`: Main struct defining configuration for each HealthKit data type with extensive workout support
- `SampleType`: Enum categorizing data as quantity/category/workout
- `WorkoutMetric`: Enum for workout measurement types (duration/totalEnergy/totalDistance)
- `WorkoutCategory`: Enum organizing workouts by type (cardio/training/sports/mindAndBody/outdoor/wheelchair/other)
- `AggregationType`: Enum defining custom grouping logic for different data patterns

## Important Methods/Functions
- `healthDataQueries`: Computed property combining base queries and workout queries
- `baseHealthDataQueries`: Array of traditional health metrics and sleep analysis configurations
- `workoutHealthDataQueries`: Generated array of all workout type configurations
- `workoutDescriptors`: Static data defining all supported workout types with categories
- `HealthDataQuery.makeSampleType()`: Extension method to create appropriate HKSampleType from configuration

## Dependencies & Relationships
- Imports HealthKit framework
- Used by healthKitSupport.swift for querying HealthKit data
- Defines configuration consumed by HealthKit query logic

## Notable Patterns & Conventions
- Each query specifies identifier, display name, units, aggregation style, custom processing, and menu tab placement
- Custom processors handle complex data like sleep stage calculations
- AggregationType provides semantic meaning for different data patterns
- Workout queries auto-generated from descriptors with consistent naming patterns
- MenuTab override system allows custom placement (e.g., Mindful Minutes in Workouts tab)

## Implementation Details
- **MenuTab System**: Three-tab organization (Metrics/Sleep/Workouts) with optional overrides
  - MenuTab enum with `title` (String) and `icon` (String) properties
  - SF Symbol icons: ruler (Metrics), powersleep (Sleep), figure.run (Workouts)
  - Used by ahViewController for segmented control display with iOS 26+ icon support
- **Workout Generation**: Programmatically creates Duration/Energy/Distance queries for all supported workout types
- **Category Support**: Extensive workout categorization for UI filtering and organization
- **Combined Workout Queries**: Rowing combined queries (indoor+outdoor merging) are defined but commented out, not included in healthDataQueries
- **Sleep Analysis**: Renamed sleep types (e.g., "Sleep: Awake" → "Sleep: Awake", "Sleep - Core" → "Core Sleep")
- **New Data Types**: Added Sleeping Wrist Temperature (Sleep tab) and Mindful Minutes (Workouts tab override)
- **Version Compatibility**: Conditional workout type inclusion based on iOS availability (14.0+, 16.0+)
- Sleep data uses `.groupedByNight` with custom time aggregation (12:00 PM boundaries)
- High frequency data (HRV, Heart Rate) uses `.highFrequency`

## Recent Development History
**Latest Changes (2025-10-02) - Rowing Combined Queries Disabled:**
- **Commented Out**: Three rowing combined workout queries (Duration/Energy/Distance) that merged indoor and outdoor rowing
- **Reason**: Not currently in use, kept for potential future reference
- **Impact**: `healthDataQueries` array no longer includes `+ rowingCombinedQueries`
- **Code Preserved**: Full `rowingCombinedQueries` array definition wrapped in /* */ comments
- **Original Purpose**: These queries were designed to merge indoor and outdoor rowing workouts for users who record distance indoors

**Previous Changes (2025-10-02) - MenuTab SF Symbol Icons:**
- **Icon Property Added**: MenuTab enum now includes `icon` computed property
- **SF Symbol Mapping**: metrics → "ruler", sleep → "powersleep", workouts → "figure.run"
- **Purpose**: Supports iOS 26+ icon display in ahViewController segmented control
- **Maintains Compatibility**: `title` property unchanged for older iOS versions

**Previous Changes**: Major expansion with comprehensive workout support and menu organization
- **MenuTab System**: Added three-tab organization with override capability for custom placement
- **Workout Support**: Added hundreds of workout types with automatic query generation
- **New HealthKit Types**: Sleeping Wrist Temperature and Mindful Minutes with appropriate tab placement
- **Category Organization**: WorkoutCategory enum for UI filtering and logical grouping
- **Sleep Display Names**: Improved sleep analysis display names for better clarity

## Current Issues & TODOs
- **COMPLETED (2025-10-08)**: Added Awake Segments query for counting nighttime awakenings
- **COMPLETED (2025-10-02)**: Rowing combined queries commented out (not in use)
- **COMPLETED (2025-10-02)**: Added SF symbol icons to MenuTab enum
- **COMPLETED (2025-09-29)**: Fixed sleeping wrist temperature date attribution by adding `useEndDate` flag

## Last Updated
2025-10-08 - **Awake Segments Added**:
- **New Query**: Added "Awake Segments" HealthDataQuery to count nighttime awakenings
- **Location**: Inserted after "REM Sleep Segments" (line 395-415)
- **Configuration**: Uses same pattern as Deep/REM segments with 2-minute minimum duration
- **Info**: "Counts the number of awake segments during the night. Only awake periods of at least 2 minutes are counted as segments."
- **Consistency**: Matches the awake segment logic already used in Sleep Cycles calculation

Previous update:
2025-10-02 - Rowing Combined Queries Disabled:
- **Code Cleanup**: Commented out three rowing combined workout queries (Duration/Energy/Distance)
- **Rationale**: Not currently in use, but preserved for potential future implementation
- **Impact**: Simplified `healthDataQueries` array by removing `+ rowingCombinedQueries`
- **Original Purpose**: These queries merged indoor and outdoor rowing workouts for users recording distance indoors

Previous update (same day):
2025-10-02 - MenuTab SF Symbol Icons:
- **Icon Support**: Added `icon` computed property to MenuTab enum for iOS 26+ UI enhancement
- **Integration**: Works with ahViewController segmented control conditional display
- **Backward Compatible**: Existing `title` property maintains text label support

Previous update:
2025-09-29: **Date Attribution Fix** - Added `useEndDate: Bool` field to HealthDataQuery struct to handle interval-based measurements that should be attributed to the end of their interval rather than the start. Applied to Sleeping Wrist Temperature to fix overnight measurement attribution (previously attributed to evening instead of morning).

Previous: 2025-09-28 - Major restructuring with MenuTab system, comprehensive workout support (200+ workout types), and expanded HealthDataQuery struct.