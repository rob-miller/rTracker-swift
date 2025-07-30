# healthKitSupport.swift Analysis Notes

## Purpose & Role
Handles HealthKit integration for querying and processing health data based on configurations from healthKitData.swift.

## Key Classes/Structs/Protocols
- Main HealthKit query execution logic
- Timestamp extraction and processing
- Data aggregation handling for different HealthKit data types

## Important Methods/Functions
- Query execution methods for different aggregation styles
- Timestamp processing and collection
- Error handling for unsupported aggregation types

## Dependencies & Relationships
- Depends on healthKitData.swift for query configurations
- Uses HealthKit framework for data queries
- Provides processed data to tracker system

## Notable Patterns & Conventions
- Switch statement on aggregationStyle (.discreteArithmetic, .cumulative)
- Custom handling for different aggregationType values
- Error logging using DBGErr for unhandled cases

## Implementation Details
- **Line 1175 Issue**: Error for unhandled .cumulativeDaily aggregationType in .cumulative case
- Uses HKStatisticsCollectionQuery for cumulative data with daily intervals
- Custom sleep data processing with night-based grouping
- Handles predicate creation for category-based filtering

## Recent Development History
- Added support for aggregationType-based processing
- Implemented sleep data night grouping logic
- Added error handling for unsupported aggregation combinations