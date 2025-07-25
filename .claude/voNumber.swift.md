# voNumber.swift Analysis Notes

## Purpose & Role
Handles numeric input fields in trackers, supporting manual entry, HealthKit integration, and other tracker data sources. Manages display, validation, data storage, and external data synchronization for numeric values.

## Key Classes/Structs/Protocols
- `voNumber`: Main class extending `voState` and implementing `UITextFieldDelegate`
- `UITextField` (`dtf`): The primary input control
- `rtHealthKit`: Shared instance for HealthKit integration
- Static `healthKitCache`: Caches HealthKit data by source-date-unit key

## Important Methods/Functions
- `voDisplay(_:)`: Creates and configures the text field, handles HealthKit/Other Tracker data loading
- `update(_:)`: Returns current value, handles time format conversion
- `loadHKdata(forDate:dispatchGroup:)`: Loads HealthKit data into database
- `clearHKdata(forDate:)`: Removes HealthKit-sourced data from database
- `createTextField()`: Sets up the UITextField with proper formatting and input accessories
- `textFieldDidEndEditing(_:)`: Handles value changes and notifications

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
- Input accessory toolbar with Done and minus buttons

## Implementation Details
- **HealthKit Integration**: Queries HealthKit on display, caches results, handles averaging and previous-day options
- **Data Storage**: Values stored as text in voData table, with associated voHKstatus entries for HealthKit tracking
- **Display Logic**: Shows "<no data>" for empty HealthKit fields, different placeholders for manual vs external data
- **Input Handling**: Decimal pad keyboard with custom Done button, minus button for negation
- **Privacy**: Respects privacy levels for data access

## Recent Development History
- `bcb59f1` (Latest): Fixed issue where disabling HealthKit source incorrectly deleted manually entered data
- `2df5306`: Added "<no data>" display for empty fields from external sources
- `a0d3a8a`: Fixed resetData clearing voNumber during data loading
- `65d8bfd`: Implemented AnyValue for other tracker sources, mergeDates functionality
- `834d4d3`: Added progress bar support for full refresh operations
- `1759803`: Fixed regression where null HealthKit data showed as 0, improved cache key with unit

## Current Issues Fixed
- **HealthKit Data Clearing Bug**: The loadHKdata query was incorrectly processing dates with manually-entered data, creating voHKstatus entries that caused manual data to be deleted when HealthKit was disabled. Fixed by modifying the SQL query to exclude dates that already have manually-entered voData.