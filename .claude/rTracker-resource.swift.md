# rTracker-resource.swift Analysis Notes

## Purpose & Role
Central utility class providing shared resources and UI components across the app. Handles activity indicators, progress bars, alerts, file operations, and various app-wide utilities.

## Key Classes/Structs/Protocols
- Static utility class with class methods
- Manages global UI state for loading indicators
- Provides centralized file path and utility functions
- **settingsIcon**: Global constant for settings button SF Symbol ("gear")

## Important Methods/Functions
- `startActivityIndicator(_:navItem:disable:str:)` - Shows modern styled loading spinner with message
- `finishActivityIndicator(_:navItem:disable:)` - Removes activity indicator and restores UI state
- `startProgressBar(_:navItem:disable:yloc:)` - Creates progress bar at specified Y location
- `finishProgressBar(_:navItem:disable:)` - Removes progress bar and restores interaction
- `setProgressVal(_:)` - Updates progress bar value thread-safely
- `bumpProgressBar()` - Increments progress counter for batch operations
- `alert(_:msg:vc:)` - Shows alert dialogs with proper threading
- `ioFilePath(_:access:)` - Provides file paths for app documents

### iOS 26 Button Creation Functions - CONSOLIDATED SYSTEM
**MAJOR CONSOLIDATION (2025-09-26)**: Reduced from 25+ functions to 4 core functions

**Core Functions (Final Architecture):**
- `createStyledButton(_:_:_:backgroundColor:symbolColor:borderColor:borderWidth:symbolSize:fallbackSystemItem:fallbackTitle:)` - Base button creator
- `createDoneButton(target:action:preferYellow:symbolSize:)` - Yellow/blue checkmark (default 18pt)
- `createActionButton(target:action:symbolName:tintColor:symbolSize:fallbackSystemItem:fallbackTitle:)` - Generic symbol button (default 18pt)
- `createNavigationButton(target:action:direction:style:)` - Back/forward navigation with direction enum
- `createSettingsButton(target:action:accId:)` - Settings/configuration button with gear icon (uses settingsIcon constant)

**Removed Functions (25+ eliminated):**
- ~~All UseTrackerController-specific functions~~ → Use `createActionButton`
- ~~All Privacy-specific functions~~ → Use `createActionButton`
- ~~createSaveButton, createAddButton, createBackButton, etc.~~ → Use consolidated functions
- ~~createEditButton, createCopyButton, createClearButton, etc.~~ → Use `createActionButton`
- ~~All keyboard accessory functions~~ → Use `createDoneButton` and `createActionButton`

## Dependencies & Relationships
- Used throughout the app for UI feedback during long operations
- Central dependency for file loading operations
- Provides thread-safe UI updates via safeDispatchSync

## Notable Patterns & Conventions
- All methods are class methods (static utility pattern)
- Thread-safe UI updates using performSelector on main thread
- Global state management for preventing multiple indicators
- Modern iOS design with system colors and styling

## Implementation Details
- **Modern Activity Indicator Styling**:
  - Dynamically centered on screen (200x120 container)
  - Semi-transparent background with rounded corners (16pt radius)
  - Subtle shadow and border for depth and definition
  - System blue colored spinner with medium weight font
  - Support for multi-line text messages
- **Progress Bar Management**:
  - Configurable Y position for Dynamic Island/notch avoidance
  - Optional UI interaction disabling during operations
  - Thread-safe progress updates with automatic batching
- **Memory Management**:
  - Proper cleanup of UI elements and references
  - Global state tracking to prevent duplicate indicators

## iOS 26 Button System Implementation Details
**Major addition during current session:**
- **createSaveButton**: Yellow circle (RGB: 0.85, 0.7, 0.05) background, yellow-tinted white checkmark, 1pt border
- **createAddButton**: White background with blue plus symbol using `.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)`
- **createBackButton**: White background with black/white chevron.left (follows .label color)
- **createEditButton**: White background with slider.horizontal.3 symbol (setup/configuration)
- **createCopyButton**: White background with document.on.document symbol

**Common iOS 26 Pattern:**
- Uses `UIButton.Configuration.filled()` with `.capsule` corner style
- 22pt symbol size, `.regular` weight
- `hidesSharedBackground = true` on UIBarButtonItem
- Pre-iOS 26 fallbacks to appropriate system buttons
- Consistent `.label` color for visibility in light/dark modes

## Recent Development History
**Current Session (2025-09-26) - MAJOR BUTTON CONSOLIDATION:**
- **MASSIVE REFACTOR**: Reduced 25+ button functions to 4 core functions
- **Eliminated Functions**: Removed createSaveButton, createAddButton, createBackButton, createEditButton, createCopyButton, createClearButton, createLockButton, createPrivacySaveButton, createLeftChevronCircleButton, createRightChevronCircleButton, createCancelBinButton, createCancelButton, createMenuButton, createAcceptButton, createCalendarButton, createSearchButton, createDeleteButton, createSkipToEndButton, createChartButton, createDoneButton (old), createMinusButton
- **New Architecture**: 4 consolidated functions with parameters for customization
- **Updated Files**: UseTrackerController.swift, voNumber.swift, trackerChart.swift, privacyV.swift, addValObjController.swift, RootViewController.swift, addTrackerController.swift
- **Fixed Compilation**: Resolved all button-related compilation errors across the codebase
- **Maintained Compatibility**: All visual appearance and functionality preserved with cleaner code

**Previous Session (2025-01-15) - Privacy Button Refactoring:**
- **iOS 26 Button System**: Added complete modern button creation system with 5 button types
- **Color Implementation**: Fixed symbol coloring using `.withTintColor()` method instead of `baseForegroundColor`
- **Centralized Button Creation**: All iOS 26 buttons now created through rTracker-resource
- **Fallback Support**: Proper pre-iOS 26 fallbacks for all button types
- Enhanced visual design with shadows, borders, and proper typography (activity indicators)
- Improved centering and responsiveness across different screen sizes
- Added support for multi-line loading messages
- Maintained backward compatibility with existing API

## Current Issues & TODOs
- **COMPLETED (2025-10-22)**: Added notification support for toolbar visibility refresh after HealthKit database updates
- **COMPLETED**: Major button consolidation - Reduced from 25+ functions to 5 core functions
- **COMPLETED**: Updated all client files to use consolidated button functions
- **COMPLETED**: Fixed all compilation errors across UseTrackerController, voNumber, trackerChart, privacyV, addValObjController, RootViewController, addTrackerController
- **COMPLETED**: Maintained all visual styling and functionality while eliminating code duplication
- **COMPLETED**: Standardized button sizing (18pt default, 16pt for keyboard accessories)
- **COMPLETED**: Implemented color theming (yellow primary saves, blue secondary done, red cancel/reject)
- **COMPLETED**: Preserved backward compatibility with pre-iOS 26 fallbacks
- **COMPLETED**: Settings button refactoring - Centralized settings icon using "gear" SF Symbol with settingsIcon constant
- **COMPLETED** (2025-10-16): Privacy button migration to iOS 26 SF symbols with legacy PNG fallback support
- All button system refactoring and consolidation work is now complete

## Last Updated
2025-10-22 - **Added Notification for HealthKit Database Updates** (lines 1617-1620):
- **Problem**: `hide_health_button_when_enabled` preference caused button to stay hidden after permissions revoked
  - When user revoked HealthKit permissions in Settings app and returned to rTracker
  - `refreshToolBar()` checked database synchronously before async `updateAuthorisations()` completed
  - Database still had old status values (1 or 3 = authorized)
  - Button stayed hidden even though it should have become visible
- **Solution**: Post notification after async database update completes
  - **New Notification**: `healthKitDatabaseUpdated` posted in `createHealthButton()` completion handler
  - Posted ALWAYS after `updateAuthorisations()` finishes (line 1618-1620)
  - Even if button icon doesn't change, toolbar visibility might need update
  - RootViewController listens for notification and refreshes toolbar with fresh database values
- **Implementation Details**:
  - Notification posted on main queue for immediate delivery
  - Posted before checking if icon changed (lines 1617-1620, before guard statement)
  - Handles edge case: all permissions revoked but button was hidden
  - Second toolbar refresh uses updated database to correctly show button
- **Benefits**:
  - ✅ Fixes toolbar visibility bug with `hide_health_button_when_enabled` preference
  - ✅ No timing dependencies or arbitrary delays
  - ✅ Works for any database state change detected by async update
  - ✅ Clean separation: icon update (in createHealthButton) vs visibility update (in RootViewController)

Previous update:
2025-10-21 - **Added Health Access Guidance Alert Function**:
- **New Function**: `showHealthEnableGuidance(from:)` - Centralized guidance alert for enabling HealthKit access
- **Location**: After help methods, following existing utility pattern
- **Purpose**: Shows user instructions when they dismiss HealthStatusViewController with no enabled data
- **Message Content**:
  - Title: "Enable Health Access"
  - Instructions: "If you tapped 'Don't Allow', you can enable access to your health data..."
  - 4-step guide: Open Health app → Profile picture → Apps → rTracker → Turn On All
- **Parameter**: Takes `UIViewController` to present alert from correct context
- **Usage**: Called from both RootViewController and voNumber when HealthStatusViewController dismissed
- **Pattern**: Follows existing help method patterns (`showHelp`, `showHelpWithAttributedContent`)
- **Benefits**:
  - Eliminates code duplication (single implementation vs two identical methods)
  - Centralized message - easy to update guidance text in one location
  - Consistent with rTracker-resource utility architecture

Previous update:
2025-10-21 - **Simplified Health Button Icon Logic** (lines 1569-1589):
- **Problem**: Complex logic with three states (heart, heart.fill, arrow.trianglehead.clockwise.heart) was unnecessary
  - For HealthKit read access, app cannot distinguish between "not authorized" (status 2) and "no data" (status 3)
  - Both appear identically to the user (no readable data)
  - The refresh icon state was misleading and not actionable
- **Solution**: Simplified to two states based on actual readable data
  - `heart`: Nothing has data (empty, all hidden, or all status 2/3)
  - `heart.fill` (healthKitIcon): Something has readable data (at least one status 1)
- **Status Values**:
  - 1 = enabled (authorized AND has data) ← Only this indicates readable data
  - 2 = notAuthorised ← No readable data
  - 3 = notPresent (authorized but no data) ← No readable data
  - 4 = hidden (user disabled) ← Filtered out
- **Logic Flow**:
  1. If statuses empty → heart (no setup)
  2. Filter out hidden (status 4)
  3. If all hidden → heart (nothing visible)
  4. If any status 1 → heart.fill (has data)
  5. Otherwise → heart (authorized but no data, or not authorized)
- **Benefits**: Clearer user feedback, simpler code, reflects actual HealthKit read limitations

Previous update:
2025-10-16 - **Privacy Button Migration to iOS 26 SF Symbols:**
- **New privacyIcon Constant**: Line 49 - `let privacyIcon = "sunglasses"`
  - Centralized SF Symbol name for privacy buttons
  - Follows pattern of settingsIcon and healthKitIcon constants
- **Enhanced createStyledButton**: Line 1350 - Added `legacyImageName: String?` parameter
  - Supports bespoke PNG images for pre-iOS 26 fallback
  - Line 1383-1394: New fallback branch checks for legacyImageName first
  - Creates UIButton with PNG image when provided (preserves frame sizing)
  - Falls back to systemItem/title if no legacy image
- **Privacy Button SF Symbol States**:
  - Green sunglasses.fill: Privacy off, no private trackers (closedview-button-7.png)
  - Red sunglasses.fill: Privacy off, some private trackers (shadeview-button-7.png)
  - Black sunglasses outline: Privacy unlocked (fullview-button-blue-7.png)
- **Benefits**:
  - Zero code duplication - single parameter addition to existing function
  - Maintains full backward compatibility with PNG images
  - Consistent with consolidated button architecture
  - Eliminates manual UIButton creation in RootViewController
- **Pattern**: legacyImageName allows single-button fallback without duplicating button creation logic
- **Syntax**: Verified with swiftc - compilation successful

Previous update:
2025-10-15 - **Added healthKitIcon Constant** (line 46, 1556):
- **New Constant**: `let healthKitIcon = "heart.fill"`
- **Purpose**: Centralized SF Symbol name for HealthKit/Apple Health icons
- **Pattern**: Matches existing `settingsIcon = "gear"` constant pattern (line 43)
- **Usage**: Replaces hardcoded "heart.fill" strings throughout codebase
- **Locations Using Constant**:
  - rTracker-resource.swift line 1556: Dynamic health button logic (`createHealthButton`)
  - voState.swift: Source indicators (2 locations)
  - addTrackerController.swift: ValueObj list indicators
  - HealthStatusViewController.swift: Manage Permissions button
- **Benefits**: Single source of truth, easier to update icon globally, consistent with settings icon pattern

Previous update:
2025-10-15 - **Maintained Consistent UIBarButtonItem Pattern** (removed inconsistent inline approach):
- **Pattern Preserved**: ALL button creation functions return `UIBarButtonItem` (never UIButton directly)
- **Inline Usage**: Use `.uiButton` extension to extract underlying button when needed for inline placement
- **Consistency**: Same pattern used throughout codebase:
  - privacyV: 6 buttons using `.uiButton` (lines 380, 402, 424, 449, 524, 548)
  - voNumber keyboard: 2 buttons using `.uiButton` (lines 123, 131)
  - datePickerVC: 4 buttons using `.uiButton` (lines 195, 200, 205, 212)
  - ppwV: 2 buttons using `.uiButton` (lines 129, 153)
  - voTextBox: 2 buttons using `.uiButton` (lines 82, 110)
- **Health Button**: Uses `createHealthButton().uiButton` for inline placement (no special function needed)
- **Architecture**: 6 consolidated button functions remain unchanged (no inline-specific variants)
- **Extension**: `.uiButton` property on UIBarButtonItem (lines 1575-1579) provides standard extraction pattern
- **Correction**: Removed previously added `createInlineHealthButton()` to maintain consistency

Previous update:
2025-10-15 - **Updated "All Good" Status Logic** (lines 1551-1556):
- **Problem**: Previous logic required ALL sources to have data (status 1) for heart.fill icon
  - Unrealistic: users won't have data for every workout type (skiing, swimming, etc.)
  - Many metrics require specific devices or activities users don't do
  - Made "all good" state unachievable for most users
- **Solution**: Changed condition from `$0 == 1` to `$0 == 1 || $0 == 3`
  - Status 1 (enabled with data): ✅ Good
  - Status 3 (authorized but no data): ✅ Good (user is authorized, just hasn't used it yet)
  - Status 2 (not authorized): ❌ Needs action
- **Symbol Logic Now**:
  - `heart.fill`: All sources are authorized (status 1 or 3)
  - `arrow.trianglehead.clockwise.heart`: Any source not authorized (status 2)
  - `heart`: No configurations or all hidden
- **Impact**: Makes "all good" state achievable and realistic for users

Previous update:
2025-10-15 - Added Apple Health Status Button with Dynamic Icon Selection:
- **New `createHealthButton()` Function**: Lines 1522-1571
  - Queries database: `SELECT disabled FROM rthealthkit` to determine button state
  - **Internal Symbol Logic**: Function automatically selects appropriate SF symbol based on data
  - Filters out hidden entries (status 4) before analyzing active configurations
  - Uses `.systemRed` tint color for all states
  - Fallback emoji: ❤️ for pre-SF symbol iOS versions
  - **Key Design**: Caller doesn't need to determine state - button function handles everything
- **Pattern Consistency**: Follows existing `createSettingsButton()` pattern but with smart state detection
- **Usage**: Called from both RootViewController and voNumber configuration screen
- **Core Architecture Now**: 6 consolidated button functions (createStyledButton, createDoneButton, createActionButton, createNavigationButton, createSettingsButton, createHealthButton)

Previous update:
2025-10-15 - SETTINGS BUTTON REFACTORING:
- **Added settingsIcon constant**: Global "gear" SF Symbol constant for settings buttons
- **Added createSettingsButton function**: Dedicated function for settings/configuration buttons
- **Replaced "slider.horizontal.3"**: All uses now reference settingsIcon constant instead of hardcoded string
- **Updated 4 files**: RootViewController, addTrackerController, addValObjController, privacyV
- **Centralized Icon Management**: Single source of truth for settings icon symbol name
- **Core Architecture Now**: 5 consolidated button functions (createStyledButton, createDoneButton, createActionButton, createNavigationButton, createSettingsButton)

Previous session - 2025-09-26 - MAJOR BUTTON CONSOLIDATION SESSION:
- **MASSIVE REFACTOR**: Reduced 25+ button creation functions to 4 core functions
- **Architecture Overhaul**: createDoneButton, createActionButton, createNavigationButton, createStyledButton (base)
- **Updated 7 files**: UseTrackerController, voNumber, trackerChart, privacyV, addValObjController, RootViewController, addTrackerController
- **Eliminated ~500+ lines**: Removed all duplicate button creation functions
- **Fixed Compilation**: Resolved all button-related compilation errors across the codebase
- **Preserved Functionality**: All visual styling and behavior maintained with cleaner, consolidated code
- **Final Architecture**: Complete button system consolidation without functionality loss

Previous session - Privacy Button Refactoring:
- **Major Refactor**: Eliminated ~110+ lines of duplicate code by removing createStyledUIButton and all createXUIButton functions
- **Added Extension**: UIBarButtonItem.uiButton property for privacy views that need direct UIButton access
- **Unified API**: Single button creation functions (returns UIBarButtonItem) with .uiButton extension for view usage
- **Updated Files**: privacyV.swift and ppwV.swift to use new .uiButton extension pattern
- **Architecture**: More Swift-idiomatic approach using extensions instead of duplicate function APIs