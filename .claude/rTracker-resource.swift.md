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

### NEW: iOS 26 Button Creation Functions (Added in Session)
- `createSaveButton(target:action:)` - Yellow checkmark circle save button
- `createAddButton(target:action:)` - Blue plus circle add button
- `createBackButton(target:action:)` - Left chevron circle back button
- `createEditButton(target:action:)` - Three sliders edit button
- `createCopyButton(target:action:)` - Document stack copy button

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
- **iOS 26 Button System**: Added complete modern button creation system with 5 button types
- **Color Implementation**: Fixed symbol coloring using `.withTintColor()` method instead of `baseForegroundColor`
- **Centralized Button Creation**: All iOS 26 buttons now created through rTracker-resource
- **Fallback Support**: Proper pre-iOS 26 fallbacks for all button types
- Enhanced visual design with shadows, borders, and proper typography (activity indicators)
- Improved centering and responsiveness across different screen sizes
- Added support for multi-line loading messages
- Maintained backward compatibility with existing API

## Current Issues & TODOs
- **NEXT SESSION**: Refactor to generic `createStyledButton()` function to reduce code duplication
- **NEXT SESSION**: Add privacy-specific buttons (clear, lock, chevron circles, cancel bin, special save)
- **NEXT SESSION**: Update privacy files (ppwV.swift, privacyV.swift, privacy.swift) with new buttons

## Last Updated
Current session - Added complete iOS 26 button system with 5 button creation functions and centralized styling