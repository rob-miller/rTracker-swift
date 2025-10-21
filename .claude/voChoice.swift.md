# voChoice.swift Analysis Notes

## Purpose & Role
Handles choice/radio button input fields in trackers. Manages segmented controls for single-choice selection from predefined options. Each choice has an index and label.

## Key Classes/Structs/Protocols
[To be populated during analysis]

## Important Methods/Functions
[To be populated during analysis]

## Dependencies & Relationships
- Extends: voState
- Database: voData table stores choice index values
- Choice definitions stored in voInfo table with 'c0', 'c1', etc. keys

## Notable Patterns & Conventions
[To be populated during analysis]

## Implementation Details
[To be populated during analysis]

## Recent Development History
- `ad48123`: Block interaction for otsrc valueObjs
- `9773bba`: otsrc no taps for choice, text box
- `c0d44b0`: implement no graph as graph option at addValObj level
- `69b1f0d`: improve options screen