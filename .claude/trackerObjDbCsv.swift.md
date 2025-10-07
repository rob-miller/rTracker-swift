# trackerObjDbCsv.swift Analysis Notes

## Purpose & Role
Extension of trackerObj class that handles database operations and CSV import/export functionality. Provides both synchronous and asynchronous data loading methods for optimal performance.

## Key Classes/Structs/Protocols
- Extension of trackerObj class
- Handles database operations for value objects (voData, voInfo, voConfig)
- CSV import/export functionality

## Important Methods/Functions
- `loadDataDict(_ dataDict: [String : [String : String]])` - Synchronous data loading, preserved for backward compatibility
- `loadDataDictAsync(_ dataDict:completion:)` - Asynchronous batch processing version for large datasets (line 1176)
- `processDataBatch()` - Helper method for batched async processing
- `insertTrackerVodata()` - Database insertion for tracker data
- `receiveRecord()` - CSV record processing
- Various database query methods

## Dependencies & Relationships
- Depends on tObjBase for database operations
- Uses rTracker_resource for progress bar updates
- Called from RootViewControllerFileLoad.swift during .rtrk import

## Notable Patterns & Conventions
- Uses direct SQL operations
- Progress bar updates via rTracker_resource.bumpProgressBar()
- Privacy level calculations for data entries
- Batch processing with configurable batch size (50 items default)
- Background queue processing with main queue UI updates

## Implementation Details
- Dual approach: synchronous method for small datasets, async for large ones
- Async version processes data in batches on background queue to prevent UI blocking
- Uses DispatchQueue.global(qos: .userInitiated) for processing
- Small delays between batches allow UI responsiveness
- Progress tracking maintained throughout async operations

## Recent Development History
- **2025-10-07**: Added transaction wrapping for massive performance improvement
  - `loadDataDict()`: Wrapped entire loop in BEGIN/COMMIT transaction
  - `loadDataDictAsync()`: Transaction wraps all batches from start to completion
  - Increased batch size from 10 to 50 for better transaction efficiency
  - Expected 10-100x speedup for large datasets (SQLite transaction optimization)
- Added async processing capabilities for large dataset imports
- Improved UI responsiveness during .rtrk file loading with batch processing
- Added autoreleasepool and proper thread management for better memory handling
- Enhanced progress updates with main thread scheduling between batches
- Fixed UI blocking issues by implementing proper background queue processing
- Maintained backward compatibility with existing synchronous interface