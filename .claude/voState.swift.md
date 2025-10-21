# voState.swift Analysis Notes

## Purpose & Role
Base UI state class for value objects in rTracker. Manages the UI presentation and interaction for value objects, implementing the voProtocol. Each voState instance is contained within a valueObj and handles the visual representation and user interaction.

## Key Classes/Structs/Protocols
- `voState`: Base UI state class implementing voProtocol
- `voProtocol`: Protocol defining interface for value object UI states
- `valueObj`: Parent value object (via `vo` property)
- `trackerObj`: Parent tracker (via `MyTracker` property)

## Important Methods/Functions
- `getValCap()`: Returns value capacity (10 characters)
- `getNumVal()`: Converts value to Double, returns 0 for invalid values
[To be populated during analysis]

## Dependencies & Relationships
- Imports: Foundation, UIKit
- Implements: voProtocol
- Contains: valueObj reference, trackerObj reference
- UI: vosFrame for layout, weak ViewController reference

## Notable Patterns & Conventions
- Weak reference to view controller to avoid retain cycles
- Default value capacity of 10 characters
- Swiftify converted from Objective-C
- Sets useVO = true on initialization

## Implementation Details
[To be populated during analysis]

## Recent Development History
- **2025-10-16 (Second Update)**: Fixed HealthKit icon/subtitle display for current/unsaved records (lines 618-644)
  - **FIXED**: Heart icon and subtitle now appear for current records when `ahksrc == "1"`
  - Modified `isCurrentEntryFromHealthKit()` to distinguish between saved vs unsaved records
  - Added database check: `SELECT EXISTS(SELECT 1 FROM trkrData WHERE date = ...)`
  - **Logic flow:**
    - If record NOT in database (current/new) → Show icon/subtitle when `ahksrc == "1"` (configured)
    - If record IN database (historical) → Query `voHKstatus` to check actual data source
  - **Behavior:** Current records now correctly show HealthKit branding when HealthKit is enabled
    - Example: New weight entry with smart scale enabled shows heart icon + subtitle
    - Historical manual entries still correctly show NO icon (even if HealthKit is enabled)
- **2025-10-16**: Added per-entry Apple Health detection with subtitle (lines 618-634, 641, 707-756)
  - **FIXED**: Heart icon and subtitle now only appear for entries where data actually came from Apple Health
  - Added `isCurrentEntryFromHealthKit()` helper method (lines 618-634)
    - Queries `voHKstatus` table for current tracker date to determine data source
    - Returns true only if `stat = 1` (hkData), meaning data came from Apple Health
    - Handles cases: manual entry (no voHKstatus), HealthKit data (stat=1), no data found (stat=0)
  - Updated `setupLabelForCell()` to use helper method (lines 707-743)
    - `isFromHealthKit` variable replaces `ahksrc == "1"` checks
    - Icon and tint color logic updated: red heart only for HealthKit-sourced entries
    - Subtitle only shown for entries with `isFromHealthKit = true`
  - Updated `voTVCellHeight()` to use helper method (line 641)
    - Cell height adjusted dynamically based on actual data source per entry
  - Subtitle text: "from Apple Health" (11pt, `.secondaryLabel` color)
  - **Behavior**: Mixed trackers now correctly show icon/subtitle only for HealthKit entries
    - Example: Weight tracker with manual entries + smart scale data
    - Manual entries: No icon, no subtitle
    - Smart scale entries: Red heart icon + "from Apple Health" subtitle
- **2025-10-15**: Updated HealthKit source indicator symbol and color (lines 577, 579, 710, 712)
  - Changed symbol from `"heart.text.square"` to `"heart.fill"` for HealthKit sources
  - Changed color from `.systemBlue` to `.systemRed` for HealthKit sources
  - Maintains `.systemBlue` for Other Tracker ("link") and Function sources
  - Consistent with health status button icon and color scheme
  - Clear visual distinction: Red heart = HealthKit, Blue link = Other Tracker, Blue function = Function
- `65d8bfd`: Implement AnyValue for otsrc; implement mergeDates and otsrc loads all other tracker dates
- `834d4d3`: Implement progress bar for useTracker full refresh
- `da3c929`: Comments, remove dbg messages
- `66b26ec`: Implement hidden valueObjs
- `6869287`: fn updates with current tracker; vos.update accepts String?

## Last Updated
2025-10-16 - **HealthKit Icon Fix for Current Records**: Modified `isCurrentEntryFromHealthKit()` to check if record exists in database before querying `voHKstatus`. For unsaved/current records, now correctly shows HealthKit icon and subtitle when `ahksrc == "1"` (configured for HealthKit). For saved/historical records, continues to query actual data source from `voHKstatus` table. This ensures current records display HealthKit branding appropriately while maintaining accurate historical data source indicators.