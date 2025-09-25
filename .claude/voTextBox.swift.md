# voTextBox.swift Analysis Notes

## Purpose & Role
UI state class for multi-line text box input with picker integration for history and contacts. Handles text editing, picker views, and save button management.

## Key Classes/Structs/Protocols
- voTextBox: Subclass of voState for text box value objects
- Implements UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate
- Manages text input with optional picker integration

## Important Methods/Functions
- **dataEditVDidLoad()**: Sets up voDataEdit view with back button and modern iOS 26 save button
- **textViewDidChange()**: NEW - Dynamic save button that only appears when text is modified
- **saveAction()**: Handles save button press with text processing and cleanup
- **tbBtnAction()**: Creates and presents voDataEdit for text editing
- **segmentChanged()**: Switches between keyboard, history, and contacts input modes

## Dependencies & Relationships
- Inherits from voState (UI state management base class)
- Creates and manages voDataEdit instances for full-screen text editing
- Integrates with CustomAccessoryView for input mode switching
- Uses rTracker_resource.createSaveButton for modern button styling

## Notable Patterns & Conventions
- **Dynamic Save Button Logic**: Save button only appears when text differs from original value
- **Input Mode Switching**: Segmented control for keyboard/history/contacts
- **Accessibility Integration**: Full accessibility support with proper identifiers
- **Modern iOS 26 Styling**: Uses centralized button creation from rTracker-resource

## Implementation Details

### NEW: Dynamic Save Button System (Added in Current Session)
- **Smart Button Display**: Save button only appears in `textViewDidChange()` when text is modified
- **Automatic Hiding**: Button disappears if user reverts text back to original value
- **iOS 26 Styling**: Uses `rTracker_resource.createSaveButton()` for consistent modern appearance
- **Performance**: Only creates button when actually needed, not on every text change

### Text Input Modes
- **SEGKEYBOARD (0)**: Standard keyboard input
- **SEGHISTORY (1)**: Picker showing text input history
- **SEGPEOPLE (2)**: Contact picker integration (requires permission)

### View Controller Integration
- **dataEditVDidLoad()**: Sets up both back and save buttons for voDataEdit
- **Proper Delegation**: voDataEdit no longer overrides the save button
- **Clean Architecture**: Centralized button management prevents UI conflicts

## Current Issues & TODOs
- **RESOLVED**: Empty white button issue eliminated by proper save button delegation
- **RESOLVED**: Save button now appears/disappears dynamically based on text changes
- **RESOLVED**: iOS 26 styling consistently applied through rTracker-resource

## Recent Development History
**Current Session - Major Updates:**
- **Dynamic Save Button**: Implemented smart save button that only shows when text is modified
- **iOS 26 Integration**: Updated to use centralized `rTracker_resource.createSaveButton()`
- **Button Delegation**: Proper setup in `dataEditVDidLoad()` eliminates voDataEdit conflicts
- **Performance**: Save button creation moved to `textViewDidChange()` for efficiency
- **Clean UI**: Eliminated empty button artifacts and override conflicts

## Last Updated
Current session - Added dynamic save button system with iOS 26 styling and intelligent show/hide behavior based on text modifications