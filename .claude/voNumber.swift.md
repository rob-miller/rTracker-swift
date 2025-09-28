# voNumber.swift Analysis Notes

## Purpose & Role
Handles numeric input fields in trackers, supporting manual entry, HealthKit integration, and other tracker data sources. Manages display, validation, data storage, and external data synchronization for numeric values. Includes enhanced ahPrevD (previous day) support with proper date shifting logic.

## Key Classes/Structs/Protocols
- `voNumber`: Main class extending `voState` and implementing `UITextFieldDelegate`
- `UITextField` (`dtf`): The primary input control
- `rtHealthKit`: Shared instance for HealthKit integration
- Static `healthKitCache`: Caches HealthKit data by source-date-unit key

## Important Methods/Functions
- `voDisplay(_:)`: Creates and configures the text field, handles HealthKit/Other Tracker data loading
- `update(_:)`: Returns current value, handles time format conversion
- `loadHKdata(forDate:dispatchGroup:)`: Loads HealthKit data into database with enhanced ahPrevD support
- `clearHKdata(forDate:)`: Removes HealthKit-sourced data from database
- `createTextField()`: Sets up the UITextField with proper formatting and input accessories
- `textFieldDidEndEditing(_:)`: Handles value changes and notifications
- `processHealthQuery()`: Enhanced HealthKit data processing with proper date shifting for ahPrevD
- `getHealthKitDates()`: Improved date handling using `HealthDataQuery.makeSampleType()`

## Dependencies & Relationships
- Imports: Foundation, UIKit, SwiftUI, HealthKit
- Extends: `voState`
- Implements: `UITextFieldDelegate`
- Uses: `rtHealthKit`, `trackerObj`, `valueObj`
- Database tables: `voData`, `voHKstatus`, `trkrData`

## Notable Patterns & Conventions
- Lazy initialization of text field with frame-based recreation
- HealthKit caching with compound keys
- Time format conversion (HH:MM to minutes)
- External data overlay system for non-editable fields
- Placeholder text varies based on data source type
- Input accessory toolbar with Done and minus buttons (modern SF symbols)

## Implementation Details
- **Enhanced ahPrevD Support**: Proper date shifting logic - shifts trkrData dates forward for storage, shifts HealthKit query dates backward
- **HealthKit Integration**: Uses `HealthDataQuery.makeSampleType()` for unified type creation, supports all sample types
- **Date Management**: Complex dual-direction shifting for ahPrevD mode to handle "previous day" data attribution
- **Debug Enhancements**: Added debug date limiting (3 months back) and improved logging with target dates
- **Data Storage**: Values stored as text in voData table, with associated voHKstatus entries for HealthKit tracking
- **Display Logic**: Shows "<no data>" for empty HealthKit fields, different placeholders for manual vs external data
- **Input Handling**: Decimal pad keyboard with blue checkmark Done button (checkmark.circle), minus/plus toggle button (minus.forwardslash.plus) for sign changes
- **Privacy**: Respects privacy levels for data access

## Recent Development History
**Latest Changes (2025-09-28) - Enhanced ahPrevD and HealthKit Integration:**
- **Major ahPrevD Overhaul**: Complete redesign of previous day logic with proper bidirectional date shifting
- **HealthKit Type Support**: Updated to use `HealthDataQuery.makeSampleType()` for unified quantity/category/workout support
- **Date Shifting Logic**:
  - For ahPrevD: Store dates shifted +1 day in trkrData, query HealthKit with dates shifted -1 day
  - Ensures "previous day" data appears on correct tracker date
- **Debug Enhancements**: Added 3-month debug date limiting and improved target date logging
- **Storage Date Calculation**: Enhanced processHealthQuery to handle date shifting for proper storage location

**Previous Major Changes:**
- **Keyboard Accessory Modernization**: SF symbol buttons (checkmark.circle, minus.forwardslash.plus)
- **Data Management Fixes**: Prevented manual data deletion when disabling HealthKit sources
- **Cache Improvements**: Enhanced HealthKit caching with unit-specific keys

## Current Issues & TODOs
- **COMPLETED**: Enhanced ahPrevD implementation with proper date shifting
- **COMPLETED**: HealthKit integration updated for all sample types (quantity/category/workout)
- **COMPLETED**: Debug enhancements for development efficiency
- **COMPLETED**: Keyboard accessory button modernization with SF symbols

## Issues Fixed
- **HealthKit Data Clearing Bug**: The loadHKdata query was incorrectly processing dates with manually-entered data, creating voHKstatus entries that caused manual data to be deleted when HealthKit was disabled. Fixed by modifying the SQL query to exclude dates that already have manually-entered voData.
- **HealthKit Cross-Contamination Bug** (2025-08-26): Fixed issue where low-frequency HealthKit valueObjs would repeatedly reprocess dates where we already knew there was `noData`. The complex OR-based SQL query only excluded `stat = hkData` entries but allowed `stat = noData` entries to be reprocessed indefinitely. Simplified to exclude ANY existing voHKstatus entry for the specific valueObj, preventing unnecessary reprocessing of dates we've already attempted.

## Last Updated
2025-09-28 - Enhanced ahPrevD and HealthKit Integration:
- **Major ahPrevD Redesign**: Implemented proper bidirectional date shifting for accurate "previous day" data attribution
- **HealthKit Type Unification**: Updated to support all sample types (quantity/category/workout) via `makeSampleType()`
- **Debug Improvements**: Added 3-month debug date limiting and enhanced target date logging
- **Storage Logic Enhancement**: Proper date shifting in processHealthQuery for correct data placement
- **Complex Date Management**: Handles shifting dates forward for storage, backward for queries in ahPrevD mode