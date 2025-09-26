# rTracker-resource.swift Analysis Notes

## Purpose & Role
Central utility class providing shared resources and UI components across the app. Handles activity indicators, progress bars, alerts, file operations, and various app-wide utilities.

## Key Classes/Structs/Protocols
- Static utility class with class methods
- Manages global UI state for loading indicators
- Provides centralized file path and utility functions

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
- **COMPLETED**: Major button consolidation - Reduced from 25+ functions to 4 core functions
- **COMPLETED**: Updated all client files to use consolidated button functions
- **COMPLETED**: Fixed all compilation errors across UseTrackerController, voNumber, trackerChart, privacyV, addValObjController, RootViewController, addTrackerController
- **COMPLETED**: Maintained all visual styling and functionality while eliminating code duplication
- **COMPLETED**: Standardized button sizing (18pt default, 16pt for keyboard accessories)
- **COMPLETED**: Implemented color theming (yellow primary saves, blue secondary done, red cancel/reject)
- **COMPLETED**: Preserved backward compatibility with pre-iOS 26 fallbacks
- All button system refactoring and consolidation work is now complete

## Last Updated
2025-09-26 - MAJOR BUTTON CONSOLIDATION SESSION:
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