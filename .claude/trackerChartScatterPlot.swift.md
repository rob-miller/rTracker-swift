# trackerChartScatterPlot.swift Analysis Notes

## Purpose & Role
Extension of TrackerChart that implements scatter plot functionality. Creates X-Y scatter plots with optional color coding by a third variable, useful for exploring relationships between multiple tracker variables.

## Key Classes/Structs/Protocols
- Extension of `TrackerChart` class
- No additional types defined - uses parent class structures

## Important Methods/Functions
- `setupScatterPlotConfig()`: Creates UI with X-axis, Y-axis, and optional color selection buttons
- `generateScatterPlotData()`: Main data processing method that correlates data points across selected variables
- `analyzeScatterData()`: Calculates axis ranges and scales using full data range for consistent scaling
- `renderScatterPlot()`: Main rendering method that draws axes, data points, and optional color coding
- `drawScatterAxes()`: Renders X and Y axes with appropriate tick marks and labels
- `drawScatterPoints()`: Plots individual data points with optional color mapping
- `showPointDetails()`: Tap handler for data point interaction showing detailed information

## Dependencies & Relationships
- Extends `TrackerChart` base functionality
- Uses `fetchDataForValueObj()` for data retrieval across multiple value objects
- Integrates with axis configuration system for persistent scaling
- No action button functionality (button is hidden for scatter plots)

## Notable Patterns & Conventions
- Requires both X and Y axis selection before chart generation
- Optional color coding with gradient mapping (blue to red through purple)
- Data point correlation by timestamp (entries from same date/time)
- Interactive data points with tap-to-show-details functionality
- Axis scaling preserved in `axisConfig` for consistent zoom behavior

## Implementation Details
- **Data Correlation**: Matches data points by timestamp across different value objects
- **Color Mapping**: When color variable selected, uses gradient from blue (low) to red (high) values
- **Axis Management**: Independent X and Y axis configuration with mutual exclusion (can't use same variable for both)
- **Point Interaction**: Associated objects store point data for tooltip display
- **Privacy Integration**: Respects privacy settings when fetching data
- **Action Button**: Hidden for scatter plots - no specific action button functionality
- **Dynamic Point Sizing**: Point size scales logarithmically from 3px (1000+ points) to 10px (1-10 points) to prevent overlapping in dense data regions

## Recent Development History
- **Current**: Added dynamic point sizing that scales from 3-10px based on data density to prevent point overlap
- **03e9c0f**: Fixed chart date range slider height constraint issues when magnifying glass enabled
- **11fc207**: Resolved constraint complaints on chart date sliders
- **848f8d8**: Major refactoring to separate chart functionality into individual files
- **8ae0246**: Initial refactoring to file-based chart organization
- **9fc06b5**: Added Y-axis labels and enhanced data loading capabilities

## Last Updated
2025-10-05: Added dynamic point sizing based on data density - point size now scales logarithmically from 3px (dense) to 10px (sparse)