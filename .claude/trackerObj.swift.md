# trackerObj Analysis Notes

## Purpose & Role
Main tracker logic class that manages individual trackers, their data, and operations including HealthKit integration and data loading processes.

## Key Classes/Structs/Protocols  
trackerObj - Core tracker management class
ProcessingState - Internal class for tracking function processing progress

## Important Methods/Functions
- processFnData(forDate:dispatchGroup:forceAll:completion:) - Main function processing orchestrator
- processFnDataForDate(progressState:) - Helper function for processing functions on a single date
- loadHKdata, loadOTdata, loadFNdata - Data loading methods
- mergeDates(inDates:set12:aggregationTime:) - Merges incoming dates with existing tracker dates, returns Sets (newDates, matchedDates)
- generateTimeSlots(from:frequency:aggregationTime:) - Generates time slot dates for high-frequency data, returns Sets (newDates, matchedDates)

## Dependencies & Relationships
Core class used throughout the app for tracker management

## Notable Patterns & Conventions
Swift 5.0 conventions, uses custom debug logging functions
Refactored to eliminate code duplication using helper functions

## Implementation Details
- processFnData now properly handles three modes: forceAll, specified date, and normal processing
- Single-date mode fixed to process only the requested date instead of all future dates
- Code duplication eliminated by extracting processFnDataForDate helper function
- Phase 1 processes missing historical dates, Phase 2 processes future dates
- progressState.currentDate properly managed throughout processing phases
- **Set-Based Date Deduplication (2025-10-02)**:
  - mergeDates and generateTimeSlots now return `Set<TimeInterval>` instead of `[TimeInterval]`
  - Automatic deduplication via Set insertion - no manual duplicate checking needed
  - Removed O(n) `.contains()` checks (lines 538-540) - Sets handle this with O(1) insertion
  - Uses `.insert()` instead of `.append()` for both newDates and matchedDates
  - Filter results wrapped in `Set()` to maintain Set type consistency

## Current Issues & TODOs
✅ COMPLETED (2025-10-02): Set-based deduplication for mergeDates and generateTimeSlots
✅ Fixed single-date processing issue
✅ Eliminated code duplication between Phase 1 and Phase 2
✅ Fixed caching logic in voFunction to respect fnDirty flag
✅ Added transaction wrapping for Phase 2 future dates processing loop

## Recent Development History
**Latest Changes (2025-10-07) - Transaction Wrapping for Performance:**
- **saveConfig()**: Added BEGIN/COMMIT transaction wrapper (lines 1776, 1806)
  - Wraps DELETE operations + INSERT loop for all valueObjs
  - Expected 5-20x speedup, especially during .rtrk import
- **confirmTOdict()**: Added BEGIN/COMMIT transaction wrapper (lines 1130, 1212)
  - Wraps entire value object merge/creation loop
  - Prevents individual disk writes for each valueObj during .rtrk merge
  - Expected 5-20x speedup for merge operations

**Previous Changes (2025-10-02) - Set-Based Deduplication:**
- **mergeDates Return Type**: Changed from `(newDates: [TimeInterval], matchedDates: [TimeInterval])` to `(newDates: Set<TimeInterval>, matchedDates: Set<TimeInterval>)` (line 446)
- **generateTimeSlots Return Type**: Changed from Arrays to Sets (line 596)
- **Internal Variables**: Changed `var newDates/matchedDates: [TimeInterval]` to `Set<TimeInterval>` (lines 452-453, 602-603)
- **Removed Duplicate Checking**: Eliminated manual `.contains()` check at lines 538-540 - Sets handle uniqueness automatically
- **Method Calls**: Replaced `.append()` with `.insert()` throughout both functions (lines 538, 542, 663, 666)
- **Filter Operations**: Wrapped filter results in `Set()` to maintain type consistency (lines 548, 559, 673-674)
- **Benefits**: O(1) insertion vs O(n) duplicate checking, automatic deduplication, cleaner code

**Previous Changes:**
- 2025-08-25: Fixed processFnData single-date mode and code organization
- 75a7491 working on high/low freq data like hrv vs weight vs sleep
- 23f1aad change vtypeNames to static array not always newly allocated
- 90bdfac revert colorSet, colorName re-ordering, make static array not always newly allocated
- 47f5d16 streakCount instrumentation and checks against current date

## Last Updated
2025-10-02 - Set-Based Deduplication for mergeDates and generateTimeSlots:
- Converted return types and internal variables from Arrays to Sets
- Eliminated manual duplicate checking (O(n)) in favor of Set insertion (O(1))
- Maintains backward compatibility via Array conversion at call sites in voNumber.swift
- Improves performance especially with large date ranges and prevents duplicate HealthKit queries

Previous update:
2025-08-29 - Added SQL transaction wrapping for Phase 2 processing loop to match Phase 1 pattern