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
- **Boolean Functions**: `before` and `after` compare record date/time against configured timestamp, returning 1.0 for true or nil for false
- **Caching**: Uses `lastCalcValue` and `lastEpd0` for performance optimization
- **Database Integration**: Stores calculated results in `voData` table with tracking in `voFNstatus`

## Backward Compatibility Architecture

**⚠️ CRITICAL: Function Token Values Must Never Change**

Users store functions as arrays of numeric tokens in the database. Changing token numeric values breaks existing saved functions.

### Function Allocation Pattern

```
FROZEN OLD FUNCTIONS (Before FNOLDLAST):
  FNSTART = -1
  FN1ARGFIRST through FN1ARGLAST (original 1-arg functions)
  FN2ARGFIRST through FN2ARGLAST (original 2-arg functions)
  FNPARENOPEN, FNPARENCLOSE (parentheses)
  FNTIMEFIRST through FNTIMELAST (original time functions)
  FNCONSTANT (constant value function)
  FNOLDLAST = FNCONSTANT

NEW FUNCTION ALLOCATION SPACES (Add new functions here):
  Gap of 10 from previous section

  FNNEW1ARGFIRST = FNOLDLAST - 10
    [New 1-arg functions: min, max, count, elapsed_*, delay, round, classify, not]
  FNNEW1ARGLAST = FNNEW1ARGFIRST - 100  (100 space allocation)

  FNNEW2ARGFIRST = FNNEW1ARGLAST - 10
    [New 2-arg functions: AND, OR, XOR, ==, !=, >, <, >=, <=, floor, ceiling]
  FNNEW2ARGLAST = FNNEW2ARGFIRST - 100  (100 space allocation)

  FNNEWTIMEFIRST = FNNEW2ARGLAST - 10
    [New time functions: mins, secs]
  FNNEWTIMELAST = FNNEWTIMEFIRST - 100  (100 space allocation)

  FNNEWOTHERFIRST = FNNEWTIMELAST - 10
    [New other functions: before, after]
  FNNEWOTHERLAST = FNNEWOTHERFIRST - 100  (100 space allocation)

  FNFIN = FNNEWOTHERLAST  (marks end of all function tokens)
```

### Adding New Functions - Complete Checklist

**Step 1: Define Token Constants**
1. Add token constant in appropriate allocation space (between FIRST and LAST)
2. If new category needed, create new allocation chain with -10 gap and 100-slot reservation
3. Update FNFIN to point to last LAST marker

**Step 2: Create Arrays for Picker Display**
1. Add to appropriate array constant (ARG1FNS, ARG2FNS, TIMEFNS, OTHERFNS, etc.)
   - Example: `let OTHERFNS = [FNCONSTANT, FNBEFORE, FNAFTER]`
2. Add display string to corresponding string array
   - Example: `let OTHERSTRS = [FNCONSTANT_TITLE, "before", "after"]`
3. Update count constant
   - Example: `let OTHERCNT = OTHERFNS.count`

**Step 3: Create Picker Property (if new category)**
1. Add private var: `private var _fnCategoryOps: [Int]?`
2. Add computed property that returns array from constants:
   ```swift
   var fnCategoryOps: [Int] {
       if nil == _fnCategoryOps {
           _fnCategoryOps = Array(CATEGORYFNS[..<CATEGORYCNT])
       }
       return _fnCategoryOps!
   }
   ```

**Step 4: Update fnStrDict Initialization**
1. Add loop to populate dictionary in `fnStrDict` computed property:
   ```swift
   for op in fnCategoryOps {
       fnTokNSNarr.append(NSNumber(value:op))
   }
   ```

**Step 5: Implement Evaluation Logic**
1. Add case in `calcFunctionValue()` switch statement for function token
2. Implement calculation logic and return appropriate value

**Step 6: Update voFunctionConfig.swift**
1. Create `ftAddCategorySet()` function to add tokens to picker
2. Call from `ftStartSet()` to include in initial picker options
3. Update `updateFnTitles()` state machine to handle new function
4. Add UI elements if function needs configuration (constants, dates, etc.)
5. Update `voFnDefnStr()` display logic for proper string formatting

**Critical Rules**:
- Never change values before FNOLDLAST
- Never insert tokens that shift existing values
- Never reuse deallocated token values
- Always maintain -10 gaps between categories
- Always allocate 100 slots minimum per category

### Sandwich Token Structure

Functions with configurable parameters (like `constant`, `before`, `after`) use sandwich structure:
- Format: `[TOKEN, value, TOKEN]`
- Example: `[FNCONSTANT, 42.0, FNCONSTANT]` or `[FNBEFORE, 1704067200, FNBEFORE]`
- Opening token signals value follows
- Closing token marks end of value
- Enables proper deletion (remove all 3 elements)
- Reuses `constantPending`/`constantClosePending` flags in display logic

## Current Issues & TODOs
✅ Fixed caching logic bug where setFNrecalc() didn't prevent cached value usage
✅ Added fnDirty flag check to caching condition in update() method
✅ Reset lastEpd0 in setFNrecalc() to ensure proper cache invalidation
✅ Added FNNEWOTHER allocation space for before/after functions
✅ Implemented before/after date comparison functions with timestamp storage
✅ Created fnOtherOps property to make OTHERFNS available to picker system
✅ Updated fnStrDict initialization to include fnOtherOps array

## Recent Development History
- 2025-10-03: **Complete before/after function implementation**
  - Added FNBEFORE and FNAFTER tokens in FNNEWOTHER allocation space
  - Created fnOtherOps computed property following fn1args/fn2args/fnTimeOps pattern
  - Updated fnStrDict initialization to iterate through fnOtherOps for proper string mapping
  - Implemented evaluation logic in calcFunctionValue() for date comparisons
  - Added comprehensive checklist for adding new functions to codebase
- 2025-08-25: Fixed caching logic in setFNrecalc() and update() methods to properly respect fnDirty flag
- Recent commits focused on logical operations with nil handling (6575eb3, 746e7c6)
- Added progress bar support for full refresh operations (834d4d3)
- Implemented ignoreRecords functionality for data filtering (8ce0ce1)
- Enhanced average calculations to require at least 2 entries (7f78cd2)
- Performance improvements with pull-to-refresh mechanisms (b4966ac)

## Last Updated
2025-10-03 - Completed before/after function implementation with fnOtherOps property and updated fnStrDict. Documented complete checklist for adding new functions to picker system.