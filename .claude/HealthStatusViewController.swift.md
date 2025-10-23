# HealthStatusViewController Analysis Notes

## Purpose & Role
SwiftUI view displaying Apple Health data source status and managing HealthKit permissions. Provides unified interface for viewing configuration state and re-triggering authorization requests.

## Key Classes/Structs/Protocols
- `HealthStatusViewController`: Main SwiftUI view struct
- Uses `trackerList.shared` for database queries
- Uses `rtHealthKit.shared` for permission management
- Integrates with `healthDataQueries` from healthkitData.swift

## Important Methods/Functions
- `init(showConfigInstructions:)`: Constructor with conditional instruction text parameter
- `loadHealthSources()`: Queries database for configured HealthKit sources and their status
- `managePermissions()`: Triggers HealthKit authorization request and refreshes status
- `statusIcon(for:)`: Returns appropriate SF symbol for status value
- `statusText(for:)`: Returns human-readable status string
- `statusColor(for:)`: Returns color coding for status value

## Dependencies & Relationships
- Imports: SwiftUI, HealthKit
- Depends on: trackerList (database access), rtHealthKit (permission management), healthDataQueries (available sources)
- Called from: RootViewController.btnHealth(), voNumber.showHealthStatus()

## Notable Patterns & Conventions
- Conditional UI based on `showConfigInstructions` parameter
- Database-driven list using SQL queries
- State management with @State properties
- Alert pattern for permission results
- Form sheet presentation style

## Implementation Details
- **Status Mapping**: Uses enableStatus enum values from healthkitData.swift
  - 1 = enabled → ✅ "Enabled" (green)
  - 2 = notAuthorised → ⚠️ "Not Authorized" (orange)
  - 3 = notPresent → ❌ "No Data" (red)
  - 4 = hidden → filtered out (not shown)
- **Database Query**: `SELECT name, hkid, disabled FROM rthealthkit WHERE disabled != 4 ORDER BY name`
- **Permission Flow**:
  1. User taps "Manage Permissions" button
  2. Calls `rtHealthKit.requestHealthKitAuthorization()` with all available queries
  3. On success, triggers `updateAuthorisations()` to refresh database
  4. Reloads list to show updated status
- **Instruction Text**: Conditional top section explains configuration workflow
  - Shown in RootViewController context (showConfigInstructions: true)
  - Hidden in voNumber context (already at config screen)

## Current Issues & TODOs
- **FIXED (2025-10-15)**: Duplicate sleep entries showing in UI (grouped by unique identifier now)
- **FIXED (2025-10-15)**: Status showing "Unknown" instead of actual status values
- All functionality implemented and working
- No known issues

## Recent Development History
**Initial Implementation (2025-10-15):**
- Created new SwiftUI view for Apple Health status display
- Database-driven list of configured sources
- Status icon and color coding
- Permission management integration
- Conditional instruction text based on calling context

## Last Updated
2025-10-21 - **Added Dismissal Callback Support:**
- **New onDismiss Parameter**:
  - Added optional `onDismiss: (() -> Void)?` property to struct
  - Updated `init` to accept optional callback: `init(showConfigInstructions: Bool = true, onDismiss: (() -> Void)? = nil)`
  - Callback stored as property for use in Done button
- **Done Button Enhancement**:
  - Modified Done button to call `onDismiss?()` before `dismiss()`
  - Allows parent view controllers to detect dismissal and take action
  - Callback fires when user taps Done button (programmatic dismissal)
  - Swipe dismissal handled separately via `UIAdaptivePresentationControllerDelegate` in parent
- **Usage Pattern**:
  - RootViewController passes callback to refresh health button and check guidance
  - voNumber passes callback to refresh inline button and check guidance
  - Callback executes before view dismisses (intentionally for coordination)
  - Parent views add 0.3s delay before presenting guidance alert to avoid conflict
- **Integration**:
  - Works with existing delegate pattern for swipe dismissal
  - Provides dual-path dismissal handling (Done button vs swipe)
  - No changes to existing functionality - purely additive
- **Benefits**:
  - Enables parent views to respond to dismissal
  - Supports guidance alert presentation after dismissal
  - Clean separation of SwiftUI view logic from UIKit parent coordination

Previous update:
2025-10-15 - **Updated Manage Permissions Button Icon** (line 80):
- **Symbol Change**: `"heart.text.square"` → `"heart.fill"`
- Consistent with health status button icon throughout app
- Button already uses red background (.red) with white text/icon
- Icon now matches the dynamic health button in toolbar and inline forms

Previous update:
2025-10-15 - **Deduplication with Display Name Mapping** (lines 170-208):
- **Problem**: Multiple duplicate entries for sleep variants (12 entries in database)
- **Root Cause**: All sleep variants share same HealthKit identifier `HKCategoryTypeIdentifierSleepAnalysis`
  - Different display names in DB: "Core Sleep", "REM Sleep", "Deep Sleep Segments", etc.
  - But only ONE HealthKit permission needed for all variants
  - Database has separate rows for each variant with same `hkid`
- **Fix**: Group by unique `hkid` using Dictionary and provide friendly display names
  - Use `identifierMap: [String: (name: String, status: Int)]` to deduplicate
  - Added `getDisplayName(for:currentName:)` helper to map identifiers to user-friendly names
  - `HKCategoryTypeIdentifierSleepAnalysis` → "Sleep Analysis"
  - `HKCategoryTypeIdentifierMindfulSession` → "Mindful Session"
  - Other identifiers use the database name as-is
  - Reduces 12+ sleep entries to 1 "Sleep Analysis" entry
- **Result**: Clean UI showing actual HealthKit permissions with clear, consistent names

Previous update:
2025-10-15 - **SQL Query Bug Fix** (line 172):
- **Problem**: Status displayed as "Unknown" for all entries despite updateAuthorisations() working correctly
- **Root Cause**: SQL query returned 3 columns but `toQry2ArySSSI()` expects tuple (String, String, String, Int)
  - Original query: `SELECT name, hkid, disabled FROM rthealthkit...`
  - Code accessed `$0.3` (4th element) but only 3 columns existed
  - Result: Default value (likely 0) doesn't match any status enum (1/2/3)
- **Fix**: Added dummy 3rd string column to match function signature
  - New query: `SELECT name, hkid, '' as dummy, disabled FROM rthealthkit...`
  - Now `$0.3` correctly accesses the `disabled` Int column
- **Result**: Status icons and text now display correctly (Enabled/Not Authorized/No Data)

Previous update:
2025-10-15 - Initial Implementation:
- **SwiftUI View**: New file created with complete implementation
- **Database Integration**: Queries rthealthkit table for source status
- **Status Display**: Icon + text + color coding for each source
- **Permission Management**: "Manage Permissions" button triggers full re-authorization
- **Conditional UI**: showConfigInstructions parameter controls top text display
- **Navigation**: "Done" button dismisses form sheet
- **Alert Pattern**: Shows result of permission request
- **Preview Support**: Debug preview provider included
