# dbg-defs.swift Analysis Notes

## Purpose & Role
Provides debug logging infrastructure with colored output, timestamps, and helper functions for date formatting. Controls compilation-time debug flags and logging levels.

## Key Classes/Structs/Protocols
- `DBGColor`: Enum defining ANSI color codes for colored terminal output (RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, ORANGE, VIOLET)
- Global functions: `DBGLog`, `DBGWarn`, `DBGErr` - Conditional compilation-controlled debug logging
- Helper functions: `ltd()`, `i2ltd()` - Date formatting for debug output

## Important Methods/Functions
- `coloredFileName(_:)`: Returns colored filename string based on module name
- `DBGLog(_:color:file:function:line:)`: Main debug logging with optional color, automatic timestamp/location
- `DBGWarn(_:file:function:line:)`: Warning-level logging in yellow
- `DBGErr(_:file:function:line:)`: Error-level logging in red
- `ltd(_:secs:)`: Formats Date as "HH:mm dd-MM-yy" or with seconds
- `i2ltd(_:secs:)`: Formats Int Unix timestamp with "i:" prefix for identification
- `dbgNSAssert(_:_:)`: Debug assertion wrapper

## Dependencies & Relationships
- Foundation framework
- Used throughout entire codebase for debug output
- Compilation flags: DEBUGLOG, DEBUGWARN, DEBUGERR, DEBUGASSERT

## Notable Patterns & Conventions
- Automatic source location capture via default parameters (`#file`, `#function`, `#line`)
- ANSI escape codes for terminal colors
- Conditional compilation eliminates debug code in release builds
- Timestamp precision: 6 decimal places for accurate timing analysis

## Implementation Details
- **Timestamp Format (2025-10-02)**: Uses `String(format: "%.6f", CFAbsoluteTimeGetCurrent())` for consistent 6-decimal precision
  - Prevents patterns like `781038509.382641` vs `781038509.38622` (missing leading zero)
  - Enables accurate timing analysis between log statements
- **Date Formatting Helpers (2025-10-02)**:
  - `ltd()`: Formats Date objects as local time "HH:mm dd-MM-yy" (or with seconds)
  - `i2ltd()`: Formats Int timestamps with "i:" prefix to distinguish from Date objects
  - Replaces verbose `Date(timeIntervalSince1970:).description` throughout codebase
- **Color System**: Maps module names to colors for visual organization in logs
- **Compilation Control**: Debug statements completely removed in non-debug builds via `#if` directives

## Current Issues & TODOs
✅ COMPLETED (2025-10-02): 6-decimal timestamp precision for consistent formatting
✅ COMPLETED (2025-10-02): Date formatting helper functions (ltd/i2ltd)
✅ COMPLETED: Colored output system
✅ COMPLETED: Automatic source location tracking

## Recent Development History
**Latest Changes (2025-10-02) - Timestamp Precision and Date Helpers:**
- **6-Decimal Timestamps**: Changed from direct `CFAbsoluteTimeGetCurrent()` to `String(format: "%.6f", ...)` in DBGLog, DBGWarn, DBGErr (lines 144, 161, 172)
- **Date Formatting Helpers**: Added `ltd()` and `i2ltd()` functions (lines 184-199)
  - `ltd(Date, secs: Bool = false)`: Returns "HH:mm dd-MM-yy" or "HH:mm:ss dd-MM-yy"
  - `i2ltd(Int, secs: Bool = false)`: Returns "i:HH:mm dd-MM-yy" with prefix for Int timestamps
  - Uses `Calendar.current.timeZone` for local time conversion
- **Cleaner Logs**: Enables consistent, readable date formatting throughout codebase

**Previous Changes:**
- 0bef0e0: Cleanup dbg message formatting
- 4a266cb: Added ORANGE color for debug messages
- 5655496: More dbglog colors added
- 689afc5: Initial colored debug message implementation
- c056888: Added timestamps to debug statements

## Last Updated
2025-10-02 - Timestamp Precision and Date Formatting Helpers:
- Implemented 6-decimal timestamp formatting to prevent inconsistent decimal places
- Added ltd() and i2ltd() helper functions for consistent date formatting
- Replaced Date().description with human-readable local time format
- All debug functions (DBGLog, DBGWarn, DBGErr) now show timestamps with full precision
