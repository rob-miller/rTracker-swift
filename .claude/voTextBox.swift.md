# voTextBox.swift Analysis Notes

## Purpose & Role
UI state class for multi-line text box input with picker integration for history and contacts. Handles text editing, picker views, and save button management. Contains CustomAccessoryView class for programmatic accessory view creation.

## Key Classes/Structs/Protocols
- **CustomAccessoryView**: Custom UIView for text input accessory (fully programmatic as of 2025-09-26)
- **voTextBox**: Subclass of voState for text box value objects
- Implements UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate
- Manages text input with optional picker integration

## Important Methods/Functions
- **CustomAccessoryView.instanceFromNib()**: Creates programmatic accessory view (replaces XIB loading)
- **CustomAccessoryView.setupUI()**: Configures all UI elements programmatically with iOS 26 patterns
- **addPickerData()**: Adds selected history/contact data and triggers save button display
- **dataEditVDidLoad()**: Sets up voDataEdit view with back button and modern iOS 26 save button
- **textViewDidChange()**: Dynamic save button that only appears when text is modified
- **saveAction()**: Handles save button press with text processing and cleanup
- **tbBtnAction()**: Creates and presents voDataEdit for text editing
- **segmentChanged()**: Switches between keyboard, history, and contacts input modes

## Dependencies & Relationships
- Inherits from voState (UI state management base class)
- Creates and manages voDataEdit instances for full-screen text editing
- Contains CustomAccessoryView class for programmatic accessory view (no longer XIB-dependent)
- Uses rTracker_resource.createActionButton and createStyledButton for iOS 26 button patterns
- Uses rTracker_resource.createSaveButton for modern button styling

## Notable Patterns & Conventions
- **Programmatic UI Creation**: Complete elimination of XIB dependency with setupUI() pattern
- **Dynamic Save Button Logic**: Save button only appears when text differs from original value
- **Input Mode Switching**: Segmented control for keyboard/history/contacts with mutually exclusive controls
- **Accessibility Integration**: Full accessibility support with proper identifiers maintained in programmatic UI
- **Modern iOS 26 Styling**: Uses centralized button creation from rTracker-resource (.uiButton extraction pattern)
- **Constraint Priority Management**: 999 priority constraints to avoid picker layout conflicts

## Implementation Details

### NEW: Programmatic CustomAccessoryView (Added 2025-09-26)
- **Complete XIB Removal**: voTBacc2.xib eliminated, full programmatic UI creation
- **setupUI() Pattern**: Creates all subviews and constraints programmatically following iOS 26 patterns
- **UI Elements**:
  - Main segmented control: 👥 📖 ⌨ (contacts/history/keyboard)
  - Add button: plus.circle symbol using createActionButton (24pt)
  - Search segmented control: ✔︎ 🔍 (use/search mode)
  - Or/And segmented control: ∪ ∩ (union/intersection - mathematical symbols)
  - Clear button: xmark.circle with red tint using createStyledButton (24pt)
- **Layout Strategy**: Mutually exclusive controls share positions (clear button and or/and segmented control)
- **Constraint Management**: 999 priority to avoid picker conflicts, proper spacing to prevent overlap

### Dynamic Save Button System
- **Smart Button Display**: Save button only appears in `textViewDidChange()` when text is modified
- **Automatic Hiding**: Button disappears if user reverts text back to original value
- **iOS 26 Styling**: Uses `rTracker_resource.createSaveButton()` for consistent modern appearance
- **Performance**: Only creates button when actually needed, not on every text change
- **Picker Integration Fix**: `addPickerData()` manually triggers `textViewDidChange()` to show save button

### Text Input Modes
- **SEGKEYBOARD (2)**: Standard keyboard input (default)
- **SEGHISTORY (1)**: Picker showing text input history
- **SEGPEOPLE (0)**: Contact picker integration (requires permission)

### View Controller Integration
- **dataEditVDidLoad()**: Sets up both back and save buttons for voDataEdit
- **Proper Delegation**: voDataEdit no longer overrides the save button
- **Clean Architecture**: Centralized button management prevents UI conflicts

## Current Issues & TODOs
- **RESOLVED**: Empty white button issue eliminated by proper save button delegation
- **RESOLVED**: Save button now appears/disappears dynamically based on text changes
- **RESOLVED**: iOS 26 styling consistently applied through rTracker-resource
- **RESOLVED**: voTBacc2.xib dependency completely eliminated - full programmatic UI
- **RESOLVED**: Save button display issue when adding picker data - manual textViewDidChange trigger added
- **RESOLVED**: Layout overlap issues - proper constraint positioning for mutually exclusive controls

## Recent Development History

**2025-09-26 Session - Complete XIB Elimination:**
- **voTBacc2.xib Removal**: Completely eliminated XIB file dependency
- **Programmatic UI Creation**: Implemented full setupUI() method with createSubviews() and setupConstraints()
- **iOS 26 Button Integration**: All buttons now use createActionButton and createStyledButton patterns
- **Layout Fixes**: Resolved control overlap issues with proper constraint positioning
- **Save Button Picker Fix**: Added manual textViewDidChange() trigger in addPickerData() for consistent save button behavior
- **Accessibility Preservation**: Maintained all accessibility identifiers and labels in programmatic UI

**Previous Session - Dynamic Save Button:**
- **Dynamic Save Button**: Implemented smart save button that only shows when text is modified
- **iOS 26 Integration**: Updated to use centralized `rTracker_resource.createSaveButton()`
- **Button Delegation**: Proper setup in `dataEditVDidLoad()` eliminates voDataEdit conflicts
- **Performance**: Save button creation moved to `textViewDidChange()` for efficiency
- **Clean UI**: Eliminated empty button artifacts and override conflicts

## Last Updated
2025-09-26 - Complete voTBacc2.xib elimination with full programmatic CustomAccessoryView implementation, iOS 26 button patterns, layout fixes, and save button picker integration