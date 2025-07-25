# addTrackerController.swift Analysis Notes

## Purpose & Role
Controller for creating and modifying trackers. Handles tracker configuration, valueObj management, and crucially contains the logic for detecting HealthKit configuration changes and cleaning up data appropriately.

## Key Classes/Structs/Protocols
- `addTrackerController`: Main class for tracker editing
- Works with `trackerObj`, `valueObj`, and various configuration controllers
- Manages temporary tracker objects during editing

## Important Methods/Functions
- `btnSave()`: Main save logic that includes HealthKit change detection
- HealthKit change detection logic (lines 331-356): Compares old vs new HealthKit settings
- Data cleanup logic: Removes HealthKit data when sources are changed/disabled

## Dependencies & Relationships
- Integrates with `trackerObj` for data management
- Uses `valueObj` configurations and `voState` subclasses
- Manages `trackerList` updates
- Handles database cleanup operations

## Notable Patterns & Conventions
- Temporary object pattern for safe editing
- Comprehensive option comparison for detecting changes
- Careful data cleanup when external sources are modified

## Implementation Details
- **HealthKit Change Detection**: Compares multiple HealthKit options (source, unit, averaging, etc.)
- **Data Cleanup**: Uses `clearHKdata()` when HealthKit settings change
- **Database Maintenance**: Removes orphaned trkrData entries after data cleanup

## Recent Development History
- `2e64587`: Added un/hide functionality for trackers and valueObjs
- `66b26ec`: Implemented hidden valueObjs feature
- `c0d44b0`: Added "no graph" option at valueObj level
- `3c43c7f`: Organized voData delete routines

## Critical Issue Previously Present
The HealthKit change detection correctly calls `clearHKdata()` when settings change, but the subsequent trkrData cleanup was overly aggressive. However, this was not the root cause of the manual data deletion issue - that was in the `voNumber.loadHKdata()` query logic that incorrectly processed manually-entered data.