# healthKitData.swift Analysis Notes

## Purpose & Role
Defines HealthKit data query configurations for various health metrics, including data types, units, aggregation styles, and custom processing logic.

## Key Classes/Structs/Protocols
- `HealthDataQuery`: Main struct defining configuration for each HealthKit data type
- `AggregationType`: Enum defining custom grouping logic for different data patterns

## Important Methods/Functions
- `healthDataQueries`: Array containing all supported HealthKit data type configurations

## Dependencies & Relationships
- Imports HealthKit framework
- Used by healthKitSupport.swift for querying HealthKit data
- Defines configuration consumed by HealthKit query logic

## Notable Patterns & Conventions
- Each query specifies identifier, display name, units, aggregation style, and custom processing
- Custom processors handle complex data like sleep stage calculations
- AggregationType provides semantic meaning for different data patterns

## Implementation Details
- **AggregationType.cumulativeDaily**: Originally intended for Steps/Active Energy but redundant with nil case
- Sleep data uses `.groupedByNight` with custom time aggregation (12:00 PM boundaries)
- High frequency data (HRV, Heart Rate) uses `.highFrequency` 
- Low frequency data (Weight, Blood Pressure) uses `.lowFrequencyMultiple`

## Recent Development History
- Added aggregationType system to handle different data collection patterns
- Implemented sleep data aggregation with custom time boundaries
- Added support for sleep segment counting and cycle detection