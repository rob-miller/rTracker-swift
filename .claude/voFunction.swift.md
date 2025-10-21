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
- **Time Duration Operators**: weeks, days, hours, minutes, seconds - require both epd0 and epd1, calculate difference and convert to specified units
- **Day-of-Week Operators**: Sunday through Saturday - use only epd1, return 1.0 if entry falls on that day, nil otherwise
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
    [New time functions: mins, secs, Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday]
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
✅ **COMPLETED (2025-10-21)**: Implemented day-of-week operators (Sunday through Saturday)
✅ **COMPLETED (2025-10-08)**: Implemented floor and ceiling as 1-arg functions
✅ **COMPLETED (2025-10-08)**: Fixed min2/max2 display from symbols to text
✅ **COMPLETED (2025-10-08)**: Fixed stale function display by removing early return cache
✅ **COMPLETED (2025-10-08)**: Fixed fnDirty flag not being reset after calculation
✅ Fixed caching logic bug where setFNrecalc() didn't prevent cached value usage
✅ Added fnDirty flag check to caching condition in update() method
✅ Reset lastEpd0 in setFNrecalc() to ensure proper cache invalidation
✅ Added FNNEWOTHER allocation space for before/after functions
✅ Implemented before/after date comparison functions with timestamp storage
✅ Created fnOtherOps property to make OTHERFNS available to picker system
✅ Updated fnStrDict initialization to include fnOtherOps array

## Recent Development History
- 2025-10-21: **Fixed Function Caching Bug When TrackerDate Changes**
  - **Bug**: When user changed date for a record, day-of-week functions showed BOTH old and new days as true
  - **Root Cause**: Cache validation in `update()` only checked `ep0date` (previous endpoint), NOT `epd1` (current entry date from `trackerDate`)
    - Cache key: `if ep0date == lastEpd0 && !lastCalcValue.isEmpty && !fnDirty` (line 1366)
    - When `trackerDate` changed, `epd1` would be different but cache wasn't invalidated
    - Function returned OLD cached value calculated with OLD `epd1`
  - **Fix**: Added `vo.vos?.setFNrecalc()` call in `updateTrackerTableView()` (useTrackerController.swift:1274-1276)
    - Matches existing pattern in `updateTableCells()` (line 172)
    - Forces cache invalidation when date changes
    - Ensures functions recalculate with new `trackerDate`/`epd1` value
  - **Impact**: Fixes day-of-week operators and any other functions that depend on current entry timestamp (`epd1`)
  - **Related files**: useTrackerController.swift (updateTrackerTableView function)
- 2025-10-21: **Fixed Critical Epoch Bug in Day-of-Week Operators**
  - **Bug**: Line 1220 used wrong epoch - `timeIntervalSinceReferenceDate` instead of `timeIntervalSince1970`
  - **Impact**: Systematic 4-day offset error (Tuesday detected as Saturday, Monday as Friday)
  - **Root Cause**:
    - `timeIntervalSinceReferenceDate` = January 1, 2001 epoch
    - `timeIntervalSince1970` = January 1, 1970 epoch (Unix epoch)
    - Difference: 978,307,200 seconds (~31 years)
  - **Fix**: Changed to `Date(timeIntervalSince1970: TimeInterval(epd1))` at line 1220
  - **Rationale**: rTracker stores all timestamps as Unix epoch (timeIntervalSince1970)
    - Database queries use `timeIntervalSince1970` (valueObj.swift:513, 516)
    - All date conversions throughout codebase use `timeIntervalSince1970`
    - `before/after` functions compare Unix epoch timestamps directly
- 2025-10-21: **Implemented Day-of-Week Operators (Sunday through Saturday)**
  - **New Helper Function**: Added `isFnDayOfWeek()` at line 138 to check if token is FNTIMESUNDAY...FNTIMESATURDAY
  - **Token Constants**: Already defined at lines 124-130 (FNTIMESUNDAY through FNTIMESATURDAY)
  - **Arrays**: Already in TIMEFNS and TIMESTRS arrays (lines 166-167)
  - **Evaluation Logic**: Added in `calcFunctionValue()` at lines 1217-1241
    - Handles day-of-week operators BEFORE time duration operators (different requirements)
    - Uses only `epd1` (current entry timestamp), does NOT require `epd0`
    - Converts epd1 to Date using `timeIntervalSince1970` (Unix epoch)
    - Uses `Calendar.current` to get weekday component (1=Sunday through 7=Saturday)
    - Returns 1.0 if weekday matches the operator's expected day, nil otherwise
    - Matches pattern of `before/after` operators (boolean result using only epd1)
  - **Time Duration Operators**: Wrapped existing weeks/days/hrs/mins/secs logic in else block (lines 1242-1292)
    - These operators require BOTH epd0 and epd1 (calculate time difference)
    - Separated from day-of-week operators which only need epd1
  - **Debug Logging**: Added FUNCTIONDBG logging for day-of-week evaluation (line 1240)
  - **Documentation**: Already existed in rtDocs.swift (lines 186-218)
  - **UI Support**: Already existed in voFunctionConfig.swift (lines 821-827)
  - **Use Cases**:
    - Filter entries by day of week (e.g., "sum of calories on Sundays")
    - Conditional logic based on day (e.g., "if Monday then 1 else 0")
    - Time-based analysis (e.g., "average sleep on weekends vs weekdays")
- 2025-10-08: **Changed Logical Operators to Programming Style**
  - **NOT operator**: Changed from `¬` to `!` (line 146 in ARG1STRS)
  - **AND operator**: Changed from `∧` to `&` (line 150 in ARG2STRS)
  - **OR operator**: Changed from `∨` to `|` (line 150 in ARG2STRS)
  - **XOR operator**: Changed from `⊕` to `^` (line 150 in ARG2STRS)
  - **Config updates**: Updated voFunctionConfig.swift doc mappings (lines 819, 830-832)
  - **Documentation**: Updated rtDocs.swift titles and examples (lines 176-177, 215, 220, 225)
  - **Rationale**: Programming-style operators are more familiar, easier to type (ASCII-only), and match user preference
  - **Compatibility**: No backward compatibility issues - stored functions use numeric tokens, not display strings
- 2025-10-08: **Implemented Floor and Ceiling Functions**
  - **New Functions**: Added FN1ARGFLOOR and FN1ARGCEILING as 1-arg functions (lines 86-87)
  - **Array Updates**: Added to ARG1FNS and ARG1STRS with "⌊" and "⌈" symbols (lines 145-146)
  - **Evaluation Logic**: Implemented in calcFunctionValue() switch (lines 883-897)
    - FN1ARGFLOOR: Uses Swift's floor() function to round down to nearest integer
    - FN1ARGCEILING: Uses Swift's ceil() function to round up to nearest integer
    - Both return nil when input is nil (nullV1 handling)
  - **Fixed min2/max2 Display**: Changed ARG2STRS from "⌊⌈" symbols to "><"/"<>" symbols (line 150)
  - **Rationale**: Floor/ceiling are 1-arg rounding functions, min2/max2 are 2-arg binary operators
  - **Documentation**: Floor/ceiling docs already existed, added new min2/max2 docs in rtDocs.swift
  - **Config Updates**: Added min2/max2 doc mappings in voFunctionConfig.swift (lines 847-848)
- 2025-10-08: **Fixed Numeric Conversion and Threshold Comparison in Classify**
  - **Problem**: Textbox value "10\n" failed to match numeric threshold "10"
  - **Bug 1 (Line 660)**: `Double(sv1 ?? "")` failed on "10\n" due to newline, returned 0.0
    - Fixed: Added `trimmedSv1 = sv1?.trimmingCharacters(in: .whitespacesAndNewlines)` before conversion
    - Now "10\n" → "10" → 10.0 correctly
  - **Bug 2 (Line 763)**: Used `v1 > matchDbl` comparison, so 10.0 NOT > 10.0 = false
    - Fixed: Changed to `v1 >= matchDbl` for inclusive threshold matching
    - Now value exactly matching threshold triggers classification
  - **Impact**:
    - Numeric classifications now work with textbox input (handles newlines/spaces)
    - Threshold values are inclusive (>= instead of >)
    - "10" matches threshold "10", "20" matches threshold "20", etc.
- 2025-10-08: **Fixed Nil Return Bug + FUNCTIONDBG Control Flow**
  - **Root Cause**: When classify returned nil (no match), function still displayed old value
  - **Bug 1 (Line 1324)**: When calculation returned nil, code executed:
    ```swift
    } else {
        lastCalcValue = ""  // Set to empty
        fnDirty = false
    }
    return instr ?? ""  // ❌ Returned OLD value from instr instead of ""!
    ```
  - **Bug 2 (Lines 1291)**: FUNCTIONDBG code had early return, altering control flow in debug builds
  - **The Fix**:
    1. Line 1324: Changed `return instr ?? ""` to `return lastCalcValue` (returns empty string for nil)
    2. Lines 1288-1299: Moved cache logic outside FUNCTIONDBG block, debug now only logs
  - **Why This Works**:
    - Nil results now correctly return empty string
    - Debug and release builds follow same control flow
    - Proper endpoint-based caching preserved (line 1297-1299)
  - **Impact**: Classify correctly clears when text doesn't match, all functions handle nil properly
- 2025-10-08: **Removed Broken Early Return Cache (Line 1288-1290)**
  - Removed `if instr?.isEmpty == false && !fnDirty` early return
  - `fnDirty` only set during batch operations, not interactive editing
  - Functions now recalculate during editing (correct), cached via endpoint comparison
- 2025-10-08: **fnDirty Flag Reset Fix** (lines 1313, 1318)
  - Added `fnDirty = false` after successful/nil calculations
  - Ensures flag works correctly during batch operations: true = needs recalc, false = current
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
2025-10-21 - Fixed function caching bug when trackerDate changes. Added `setFNrecalc()` call in `updateTrackerTableView()` to force function recalculation when the record date is changed. Previously, the cache validation only checked `ep0date` (previous endpoint) and missed when `epd1` (current entry date) changed, causing day-of-week functions to show both old and new days as true. The fix matches the existing pattern in `updateTableCells()` and ensures all functions that depend on the current entry timestamp recalculate correctly when dates change.