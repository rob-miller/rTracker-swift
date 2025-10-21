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

### .rtrk File Format
- **XML-based property list** containing two main components:
  1. **`configDict`**: Tracker configuration (plist dictionary format)
     - `optDict`: Tracker metadata (name, privacy, version, dimensions)
     - `valObjTable`: Array of value object definitions (fields to track)
     - `reminders`: Reminder configurations
     - `tid`: Tracker ID
  2. **`dataDict`**: Actual tracking data (dictionary, NOT CSV)
     - Key-value pairs mapping timestamps to data records
     - Loaded via `trackerObj.loadDataDictAsync()`

### CSV File Support
Four types of CSV files are supported:
1. **rtCSV format** (`.rtcsv` extension):
   - Self-describing CSV with metadata in second line
   - Second line format: `,"type:subtype:id","type:subtype:id",...`
   - Can automatically create new trackers without existing definition
   - Validated via `is_rtcsv()` regex check (lines 69-101)

2. **Standard CSV with `_in` suffix** (`trackername_in.csv`):
   - Must match existing tracker by name
   - Requires `TIMESTAMP_LABEL` as first column
   - Parsed via Matt Gallagher's CSVParser

3. **Inbox CSV files** (`.csv` or `.rtcsv` in Inbox directory):
   - Same rules as above but loaded from Inbox location
   - Files deleted after successful import

4. **SceneDelegate-imported CSV files** (`trackername.csv` in Documents):
   - Added 2025-10-07 for consistency with .rtrk handling
   - Must match existing tracker name exactly
   - Excludes `_out.csv` files (app-generated exports)
   - Allows users to share CSV files to app via iOS share sheet
   - Files deleted after successful import

### Three-Stage Loading Pipeline
1. **Stage 1** (lines 677-706): Load tracker definitions
   - Process `_in.plist` files (config only)
   - Process `.rtrk` files (config + prepare data)

2. **Stage 2** (lines 375-482): Load .rtrk data
   - Extract `dataDict` from .rtrk files
   - Import via `loadDataDictAsync()` with progress updates
   - Recalculate functions after data import
   - Present merge vs. create choice if tracker name exists

3. **Stage 3** (lines 103-272): Load CSV data
   - Process `_in.csv`, `_in.rtcsv` files
   - Process Inbox `.csv` and `.rtcsv` files
   - Create new trackers for valid rtCSV files
   - Alert user if CSV has no matching tracker

### Merge vs. Create Logic
When importing .rtrk with existing tracker name (lines 289-328):
- **Merge option**: Updates existing tracker config, changes TID to match import
  - Stashes original for potential rejection
  - Merges value objects via `confirmTOdict()`
- **Create New option**: Appends "-new" to tracker name
  - Assigns new TID via `fixDictTID()`
  - Adds to tracker list as separate tracker
- Demos auto-merge without prompting (line 291)

## Current Issues & TODOs
- No known issues

## Recent Development History
- **2025-10-07**: Fixed CSV file loading from SceneDelegate + performance improvements
  - **Bug Fix**: Added tracker name matching for CSV files in Documents (lines 185-195)
    - Allows SceneDelegate-saved CSV files to load (consistent with .rtrk behavior)
    - Safely excludes `_out.csv` app-generated exports
    - Validates tracker exists before attempting load
  - **Performance**: Added transaction wrapping to CSV parsing
    - Wrapped `parseRows()` call in `doCSVLoad()` with BEGIN/COMMIT transaction
    - All `receiveRecord()` callbacks now execute within single transaction
    - Expected 10-50x speedup for large CSV files
- Implemented fully asynchronous .rtrk import process to prevent UI blocking
- Added proper loading indicators and progress feedback
- Fixed compile errors with weak self capture in completion handlers
- Enhanced progress bar positioning for modern iPhone compatibility
- Disabled UI interaction blocking during progress operations to allow scrolling

## Last Updated
2025-10-07: Fixed CSV file loading bug - CSV files shared via SceneDelegate now load correctly by matching tracker names (excluding _out.csv exports). Added transaction wrapping for 10-50x CSV loading speedup. Added comprehensive documentation of file formats and loading pipeline.