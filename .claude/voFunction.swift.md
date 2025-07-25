# voFunction.swift Analysis Notes

## Purpose & Role
Implements function value objects that can calculate derived values from other tracker data using mathematical operations, aggregations (sum, avg, min, max), time calculations, and logical operations. Functions are evaluated dynamically based on current tracker state and historical data.

## Key Classes/Structs/Protocols
- `voFunction`: Main class extending `voState` for function value objects
- Function constants: Various `FN*` constants defining operation types (-1 to negative values)
- Time range constants: `FREP*` constants for time period definitions

## Important Methods/Functions
- `calcFunctionValue(withCurrent:fn2op:)`: Core recursive function evaluation engine
- `update(_:)`: Main entry point that calculates and returns function result as string
- `getEpDate(_:maxdate:)`: Calculates endpoint dates for time range calculations
- `loadFnArray()`/`saveFnArray()`: Serialization of function expression arrays
- `setFnVal(_:dispatchGroup:)`: Stores calculated values to database for graphing

## Dependencies & Relationships
- Inherits from `voState` (UI state base class)
- Uses `trackerObj` for database queries and value object access
- Depends on SQLite3 for data storage and retrieval
- Integrates with charting system via `vogd` and graph data

## Notable Patterns & Conventions
- Functions stored as arrays of NSNumbers representing tokens (operators, function IDs, value object IDs)
- Negative constants for function IDs to distinguish from positive value object IDs
- Recursive descent parser for function evaluation
- Extensive debug logging with `#if FUNCTIONDBG` conditionals
- Error handling via global `FnErr` flag and nil return values

## Implementation Details
- **Return Value Strategy**: Functions return `nil` internally (empty string `""` externally) when calculations cannot be performed, rather than returning '0'
- **Time Calculations**: Support for elapsed time, calendar periods, and relative date ranges
- **Logical Operations**: Implement AND, OR, XOR, comparison operators with nil-aware semantics
- **Caching**: Uses `lastCalcValue` and `lastEpd0` for performance optimization
- **Database Integration**: Stores calculated results in `voData` table with tracking in `voFNstatus`

## Recent Development History
- Recent commits focused on logical operations with nil handling (6575eb3, 746e7c6)
- Added progress bar support for full refresh operations (834d4d3)
- Implemented ignoreRecords functionality for data filtering (8ce0ce1)
- Enhanced average calculations to require at least 2 entries (7f78cd2)
- Performance improvements with pull-to-refresh mechanisms (b4966ac)