# RootViewControllerFileLoad.swift Analysis Notes

## Purpose & Role
Extension of RootViewController that handles file loading operations including .rtrk, .plist, and .csv file imports. Manages asynchronous file processing with proper UI feedback and progress indicators.

## Key Classes/Structs/Protocols
- Extension of RootViewController class
- Handles file import operations for tracker data and configurations
- Manages UI states during long-running import operations

## Important Methods/Functions
- `handleOpenFileURL(_:tname:completion:)` - Main entry point for .rtrk file processing with async UI management
- `loadTrackerDict(_:tname:completion:)` - Handles tracker configuration loading with user choice dialogs
- `loadTrackerCsvFiles(completion:)` - Processes CSV data files asynchronously
- `loadTrackerPlistFiles(completion:)` - Handles tracker definition files
- `processNextFile(files:index:completion:)` - Sequential file processing with completion handlers
- `doCSVLoad(_:to:fname:)` - CSV parsing and data import

## Dependencies & Relationships
- Depends on trackerObj for tracker management
- Uses trackerList for tracker registration
- Calls trackerObjDbCsv.loadDataDictAsync for async data import
- Uses rTracker_resource for UI indicators and progress bars

## Notable Patterns & Conventions
- Extensive use of completion handlers for async operations
- Background queue processing with main queue UI updates
- Sequential file processing to prevent resource conflicts
- Proper weak self capture to prevent retain cycles
- Loading indicators with descriptive messages at each stage

## Implementation Details
- Progress bars positioned at 100pt from top to avoid Dynamic Island/notch
- Progress bar disable parameter set to false to allow scrolling during import
- Multi-stage loading process: tracker config → data import → post-processing
- Proper error handling and file cleanup after processing
- Thread-safe UI updates with DispatchQueue coordination

## Recent Development History
- Implemented fully asynchronous .rtrk import process to prevent UI blocking
- Added proper loading indicators and progress feedback
- Fixed compile errors with weak self capture in completion handlers
- Enhanced progress bar positioning for modern iPhone compatibility
- Disabled UI interaction blocking during progress operations to allow scrolling