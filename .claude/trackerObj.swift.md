# trackerObj Analysis Notes

## Purpose & Role
Main tracker logic class that manages individual trackers, their data, and operations including HealthKit integration and data loading processes.

## Key Classes/Structs/Protocols  
trackerObj - Core tracker management class

## Important Methods/Functions
Need to analyze for FullRefreshProgress related methods including loadHKdata, loadOTdata, loadFNdata

## Dependencies & Relationships
Core class used throughout the app for tracker management

## Notable Patterns & Conventions
Swift 5.0 conventions, uses custom debug logging functions

## Implementation Details
To be analyzed - focus on FullRefreshProgress system

## Current Issues & TODOs
Need to analyze current progress reporting system and modify for phase-based progress

## Recent Development History
- 75a7491 working on high/low freq data like hrv vs weight vs sleep
- 23f1aad change vtypeNames to static array not always newly allocated
- 90bdfac revert colorSet, colorName re-ordering, make static array not always newly allocated
- 47f5d16 streakCount instrumentation and checks against current date

## Last Updated
2025-08-11 - Initial analysis for FullRefreshProgress modification