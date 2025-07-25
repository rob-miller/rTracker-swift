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

## Recent Development History
- Completely redesigned activity indicator with modern iOS styling
- Enhanced visual design with shadows, borders, and proper typography
- Improved centering and responsiveness across different screen sizes
- Added support for multi-line loading messages
- Maintained backward compatibility with existing API