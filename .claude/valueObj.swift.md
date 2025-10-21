# valueObj.swift Analysis Notes

## Purpose & Role
Base class for all tracked value objects in rTracker. Defines the core data structure and protocol for value objects that represent different types of data entry controls (numbers, text, sliders, choices, etc.). Each valueObj contains a voState instance for UI management.

## Key Classes/Structs/Protocols
- `valueObj`: Main base class for all value objects
- `voProtocol`: Protocol defining interface for value objects
- `voState`: UI state management (via `vos` property)
- Constants: VOT_NUMBER, VOT_TEXT, VOT_TEXTB, VOT_SLIDER, VOT_CHOICE, VOT_BOOLEAN, VOT_FUNC, VOT_INFO

## Important Methods/Functions
[To be populated during analysis]

## Dependencies & Relationships
- Imports: Foundation, CoreFoundation, UIKit
- Contains: voState instance via `vos` property
- Used by: All specific value object types (voNumber, voText, etc.)
- Database interaction: voData table for storing values

## Notable Patterns & Conventions
- Type constants tied to rTracker-resource vtypeNames array
- Maximum 8 choices for VOT_CHOICE type
- Swiftify converted from Objective-C

## Implementation Details
[To be populated during analysis]

## Recent Development History
- `65d8bfd`: Implement AnyValue for otsrc; implement mergeDates and otsrc loads all other tracker dates
- `69cb997`: Only recent default true for otsrc values
- `ad48123`: Block interaction for otsrc valueObjs
- `da3c929`: Comments, remove dbg messages
- `c516239`: Cleanup commented out sections and unused switch actions