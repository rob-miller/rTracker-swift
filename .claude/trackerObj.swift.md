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

## Current Issues & TODOs
✅ Fixed single-date processing issue
✅ Eliminated code duplication between Phase 1 and Phase 2
✅ Fixed caching logic in voFunction to respect fnDirty flag

## Recent Development History
- 2025-08-25: Fixed processFnData single-date mode and code organization
- 75a7491 working on high/low freq data like hrv vs weight vs sleep
- 23f1aad change vtypeNames to static array not always newly allocated
- 90bdfac revert colorSet, colorName re-ordering, make static array not always newly allocated
- 47f5d16 streakCount instrumentation and checks against current date

## Last Updated
2025-08-25 - Fixed processFnData single-date processing and refactored for cleaner code organization