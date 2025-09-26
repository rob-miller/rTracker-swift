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
- Input accessory toolbar with Done and minus buttons (modern SF symbols)

## Implementation Details
- **HealthKit Integration**: Queries HealthKit on display, caches results, handles averaging and previous-day options
- **Data Storage**: Values stored as text in voData table, with associated voHKstatus entries for HealthKit tracking
- **Display Logic**: Shows "<no data>" for empty HealthKit fields, different placeholders for manual vs external data
- **Input Handling**: Decimal pad keyboard with blue checkmark Done button (checkmark.circle), minus/plus toggle button (minus.forwardslash.plus) for sign changes
- **Privacy**: Respects privacy levels for data access

## Recent Development History
**Current Session (2025-01-15) - Keyboard Accessory Button Refactoring:**
- **Replaced text buttons with SF symbols**: Done button now shows blue checkmark.circle, minus button shows minus.forwardslash.plus
- **Unified button system integration**: Uses rTracker-resource.createDoneButton() and createMinusButton() with .uiButton extension
- **Modern appearance**: 16pt SF symbols instead of text labels for better visual clarity
- **Architecture consistency**: Follows same .uiButton extension pattern as other modernized components

**Previous Commits:**
- `bcb59f1`: Fixed issue where disabling HealthKit source incorrectly deleted manually entered data
- `2df5306`: Added "<no data>" display for empty fields from external sources
- `a0d3a8a`: Fixed resetData clearing voNumber during data loading
- `65d8bfd`: Implemented AnyValue for other tracker sources, mergeDates functionality
- `834d4d3`: Added progress bar support for full refresh operations
- `1759803`: Fixed regression where null HealthKit data showed as 0, improved cache key with unit

## Current Issues & TODOs
- **COMPLETED**: Keyboard accessory button modernization with SF symbols
- **COMPLETED**: Integration with unified button creation system
- **COMPLETED**: .uiButton extension pattern implementation

## Issues Fixed
- **HealthKit Data Clearing Bug**: The loadHKdata query was incorrectly processing dates with manually-entered data, creating voHKstatus entries that caused manual data to be deleted when HealthKit was disabled. Fixed by modifying the SQL query to exclude dates that already have manually-entered voData.
- **HealthKit Cross-Contamination Bug** (2025-08-26): Fixed issue where low-frequency HealthKit valueObjs would repeatedly reprocess dates where we already knew there was `noData`. The complex OR-based SQL query only excluded `stat = hkData` entries but allowed `stat = noData` entries to be reprocessed indefinitely. Simplified to exclude ANY existing voHKstatus entry for the specific valueObj, preventing unnecessary reprocessing of dates we've already attempted.

## Last Updated
2025-01-15 - Keyboard Accessory Button Modernization:
- **SF Symbol integration**: Replaced "Done" text with blue checkmark.circle, "−" text with minus.forwardslash.plus symbol
- **Unified button system**: Uses rTracker-resource button functions with .uiButton extension extraction
- **Visual improvement**: Modern 16pt SF symbols provide clearer visual indication of button functions
- **Architecture alignment**: Follows established .uiButton extension pattern used across the app