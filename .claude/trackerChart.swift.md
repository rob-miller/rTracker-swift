# trackerChart.swift Analysis Notes

## Purpose & Role
Main controller class for the charts view in rTracker. Provides a tabbed interface for different chart types (Distribution, Time, Scatter, Pie) with shared date range controls and configuration options.

## Key Classes/Structs/Protocols
- `TrackerChart`: Main UIViewController subclass that implements UIPickerViewDelegate, UIPickerViewDataSource
- Chart type constants: CHART_TYPE_DISTRIBUTION (0), CHART_TYPE_TIME (1), CHART_TYPE_SCATTER (2), CHART_TYPE_PIE (3)

## Important Methods/Functions
- `setupView()`: Creates scroll view, segmented control, chart container, and configuration UI
- `setupDateSliders()`: Initializes date range sliders with proper interaction handling
- `setupSliderContainer()`: Sets up date range controls including zoom and lock functionality
- `actionButtonTapped()`: Handles context-sensitive button actions (recent data indicator for distribution, navigation for time charts)
- `updateActionButtonForChartType()`: Updates button appearance and behavior based on current chart type
- `navigateToFirstRecordAndCloseCharts()`: Time chart specific - closes charts and navigates to first record in date range
- `dateSliderChanged()`: Handles date range slider interactions with zoom and lock support
- `chartTypeChanged()`: Switches between different chart types and updates UI accordingly

## Dependencies & Relationships
- Extends functionality through chart-specific files (trackerChartDistributionPlot.swift, trackerChartTimePlot.swift, etc.)
- References `trackerObj` for data access and `valueObj` for tracker field information
- Uses `useTrackerController.setTrackerDate()` for navigation back to tracker records
- Implements debounced chart updates via `updateChartDataWithDebounce()`

## Notable Patterns & Conventions
- Uses internal visibility for most properties and methods (shared with chart extensions)
- Tag-based view identification (TAG_LEGEND_VIEW = 5001, TAG_LEGEND_TITLE = 5002)
- Extensive use of constraints and programmatic UI layout
- Chart data stored in `chartData` dictionary with type-specific structure
- Action button behavior varies by chart type (polymorphic button pattern)

## Implementation Details
- **Action Button System**: Renamed from `recentDataIndicatorButton`, now context-sensitive:
  - Distribution charts: Recent data indicator with cycle states (○●◑◐)
  - Time charts: Navigation button with arrow icon to jump to records
  - Scatter/Pie charts: Hidden
- **Date Range Management**: Complex slider system with zoom, lock, and relative/absolute date display
- **Chart Configuration**: Type-specific button layouts managed through `configContainer`
- **Privacy Integration**: Respects `privacyValue` for data filtering
- **Debounced Updates**: 100ms delay on chart updates during slider interaction

## Recent Development History
**Current Session (2025-01-15) - Button System Modernization:**
- **Toolbar done button**: Replaced system .done with yellow checkmark (createSaveButton) for markline text field
- **Picker done button**: Replaced text "Done" with blue checkmark.circle (createDoneButton) - no oblong shape issues
- **Picker cancel button**: Replaced text "Cancel" with X mark circle (createCancelButton) via .uiButton extension
- **Unified button integration**: Uses rTracker-resource functions with .uiButton pattern for UIButton extraction
- **Action button**: Left unchanged (shows "○" symbol) per user request - noted pie chart overlap issue

**Previous Commits:**
- **842fbd9**: Added time chart navigation button functionality and reused distribution plot button
- **9e35b72**: Added date range clamping to available tracker data
- **c35a296**: Tweaked recent data button positioning
- **4fb29af**: Added chart button to highlight last 3 entries (recent data indicator)
- **ecd7ad1**: Implemented start date offset slider (zoom functionality)
- **67af62c**: Added record count display between date labels
- **a287f4b**: Implemented ignore tracker record functionality for charts

## Current Issues & TODOs
- **COMPLETED**: Toolbar and picker button modernization with SF symbols
- **COMPLETED**: Integration with unified button creation system
- **COMPLETED**: .uiButton extension pattern implementation for picker buttons
- **NOTE**: Action button overlap with pie chart arrows (time tab) - potential future positioning adjustment needed

## Last Updated
2025-01-15 - Chart Button System Modernization:
- **Toolbar modernization**: Markline text field now uses yellow checkmark save button
- **Picker UI improvement**: Done/Cancel buttons now use SF symbols (blue checkmark.circle, X mark circle)
- **Architecture consistency**: All new buttons follow .uiButton extension pattern established across the app
- **Visual enhancement**: Modern SF symbols replace text labels for clearer button identification