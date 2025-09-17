# voDataEdit.swift Analysis Notes

## Purpose & Role
Data entry view controller for text/text box value objects - handles multi-line text editing with keyboard management

## Key Classes/Structs/Protocols
- voDataEdit: UIViewController subclass for text data editing
- Keyboard management for text input views

## Important Methods/Functions
- viewDidLoad(): Initial setup and keyboard notifications
- getInitTVF(): Text view frame calculations
- keyboardWillShow(): Keyboard display handling
- Text display and editing functionality

## Dependencies & Relationships
- Inherits from UIViewController
- Works with valueObj text types (voText, voTextBox)
- Integrates with rTracker's keyboard management system

## Notable Patterns & Conventions
- Uses DBGLog for debug messaging with automatic context
- Frame calculation methods for text view positioning
- Keyboard notification handling pattern

## Implementation Details
- Text view frame calculations appear problematic (negative heights in logs)
- Keyboard management affects view layout
- Background uses "graph paper" pattern from rTracker theming

## Current Issues & TODOs
- ✅ FIXED: Frame calculations showing negative heights - replaced with safe area-based calculation
- ✅ CLARIFIED: Keyboard auto-display is correct behavior for empty fields (user intends to type)
- Text box visibility should now be resolved with frame calculation fix
- Need to test that stored text displays properly with corrected frames

## Recent Development History
- 9773bba: "otsrc no taps for choice, text box" - Recent tap handling changes
- 8cf72fb: Various display and external source updates
- 0261917: External source tracker display changes with tap catching
- Multiple accessibility and UI improvements in recent commits
- Originally converted from Objective-C via Swiftify

## Last Updated
2025-09-17: Fixed getInitTVF() frame calculation using safe area insets instead of problematic toolbar frame values. This resolves iOS 18 compatibility issue causing negative frame heights and invisible text views.