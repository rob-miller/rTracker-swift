# notifyReminderViewController.swift Analysis Notes

## Purpose & Role
Controller for setting up reminder notifications for trackers. Manages complex UI for scheduling reminders with various repeat patterns (daily, weekly, monthly), time ranges, and notification text.

## Key Classes/Structs/Protocols
- `notifyReminderViewController`: Main view controller class inheriting from UIViewController, UITextFieldDelegate
- Uses `notifyReminder` model object to store reminder settings
- Works with `trackerObj` to get tracker information

## Important Methods/Functions
- `viewDidLoad()`: Sets up UI, loads images, configures weekday buttons based on calendar settings
- `guiFromNr()`: Updates UI controls from notifyReminder object state
- `@IBAction` methods: Handle user interactions (buttons, sliders, text fields)
- `setEveryTrackerBtnName()`, `setDelayDaysButtonTitle()`: Update button titles
- Time management methods: `startSliderAction`, `finishSliderAction`, `startHrChange`, etc.

## Dependencies & Relationships
- Imports UIKit
- Uses `trackerObj` and `notifyReminder` from tracker system
- Uses `rTracker_resource` for localization (hasAmPm)
- Called from `configTVObjVC` which initializes it with XIB
- Uses checked.png/unchecked.png images for button states

## Notable Patterns & Conventions
- Uses @IBOutlet properties connected to XIB file
- Uses @IBAction methods for user interactions
- Maintains weekdays array with calendar-aware ordering
- Complex state management for different reminder modes (hours/days/weeks/months)
- Hidden/shown UI elements based on reminder configuration

## Implementation Details
- XIB-based UI with extensive constraint system
- Complex navigation bar with prev/next buttons
- Time sliders with minute precision (0-1439 range)
- Weekday buttons arranged in horizontal stack
- Conditional UI elements (month days field, tracker button, etc.)
- AM/PM handling based on locale settings

## Current Issues & TODOs
- **COMPLETED**: Successfully converted from XIB to programmatic UI
- All @IBOutlet properties converted to regular properties and created programmatically
- All @IBAction methods converted to regular methods with target-action wiring
- Auto Layout constraints implemented programmatically matching XIB layout
- All button actions and text field delegates properly wired up

## Recent Development History
- ios26: eliminate flipHorizontal transition (1315eff)
- Major reminder system rework and testing (94b38b7, 66cc792, 7b9bcc9)
- Accessibility improvements (1533186)
- Keyboard scrolling fixes (7623494)
- Original conversion from Objective-C via Swiftify (e41ceb5)

## Last Updated
2025-09-26 - Completed XIB to programmatic UI conversion. All UI elements now created programmatically with Auto Layout constraints. XIB file dependency removed.