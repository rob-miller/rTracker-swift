# healthKitData.swift Analysis Notes

## Purpose & Role
Defines HealthKit data query configurations for health metrics, workouts, and category data including data types, units, aggregation styles, custom processing logic, and menu tab organization system.

## Key Classes/Structs/Protocols
- `MenuTab`: Enum defining UI tab organization (Metrics/Sleep/Workouts)
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
- **Workout Generation**: Programmatically creates Duration/Energy/Distance queries for all supported workout types
- **Category Support**: Extensive workout categorization for UI filtering and organization
- **Sleep Analysis**: Renamed sleep types (e.g., "Sleep: Awake" → "Sleep: Awake", "Sleep - Core" → "Core Sleep")
- **New Data Types**: Added Sleeping Wrist Temperature (Sleep tab) and Mindful Minutes (Workouts tab override)
- **Version Compatibility**: Conditional workout type inclusion based on iOS availability (14.0+, 16.0+)
- Sleep data uses `.groupedByNight` with custom time aggregation (12:00 PM boundaries)
- High frequency data (HRV, Heart Rate) uses `.highFrequency`

## Recent Development History
- **Latest Changes**: Major expansion with comprehensive workout support and menu organization
- **MenuTab System**: Added three-tab organization with override capability for custom placement
- **Workout Support**: Added hundreds of workout types with automatic query generation
- **New HealthKit Types**: Sleeping Wrist Temperature and Mindful Minutes with appropriate tab placement
- **Category Organization**: WorkoutCategory enum for UI filtering and logical grouping
- **Sleep Display Names**: Improved sleep analysis display names for better clarity

## Last Updated
2025-09-28: Major restructuring with MenuTab system, comprehensive workout support (200+ workout types), and expanded HealthDataQuery struct. Added SampleType/WorkoutMetric/WorkoutCategory enums, programmatic workout query generation, and MenuTab override system for flexible UI organization.