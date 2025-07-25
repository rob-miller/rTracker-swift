# trackerChartTimePlot.swift Analysis Notes

## Purpose & Role
Extension of TrackerChart that implements time series plotting functionality. Creates line charts and boolean dot plots showing data trends over time, with support for multiple data sources and intelligent Y-axis scaling.

## Key Classes/Structs/Protocols
- Extension of `TrackerChart` class
- `TimeSeriesData`: Helper struct containing id, name, type, dataPoints, and computed properties (values, minValue, maxValue, range, isBooleanType)

## Important Methods/Functions
- `setupTimeChartConfig()`: Creates UI with 4 data source selection buttons
- `generateTimeChartData()`: Main data processing - fetches data for selected sources and calculates Y-axis ranges
- `calculateYAxisRanges()`: Complex algorithm to determine shared vs individual Y-axis scaling
- `renderTimeChart()`: Orchestrates chart rendering with axes, data series, and legend
- `drawTimeSeriesData()`: Renders both line charts (numeric) and dot plots (boolean)
- `drawBooleanDots()`: Specialized rendering for boolean data as positioned dots
- `cycleYAxisView()`: Tap handler to cycle through different Y-axis views for multi-source charts
- `drawTimeChartLegend()`: Creates legend showing averages/counts for each data source

## Dependencies & Relationships
- Extends `TrackerChart` base functionality
- Uses `TimeSeriesData` struct for organized data handling
- Integrates with action button system (navigation functionality to first record)
- References `VOT_BOOLEAN`, `VOT_NUMBER`, `VOT_FUNC`, `VOT_SLIDER` value object types

## Notable Patterns & Conventions
- Up to 4 simultaneous data sources with color coding (blue, green, red, orange)
- Boolean data rendered as dots at fixed Y positions (40%, 45%, 50%, 55% of chart height)
- Numeric data rendered as connected line charts with individual data point dots
- Intelligent Y-axis grouping based on scale similarity, common units, and data overlap
- Tappable Y-axis to cycle through different source views in multi-source scenarios

## Implementation Details
- **Y-Axis Intelligence**:
  - Groups sources by common units (time, percentage, temperature keywords)
  - Groups by scale ratio similarity (within 3x range)
  - Falls back to overlap detection (20% minimum overlap)
  - Individual scaling for ungrouped sources
- **Action Button Integration**: Uses action button as navigation tool to jump to first record in date range and close charts
- **Date Marker Scaling**: Adaptive time axis labels (hourly, daily, monthly, yearly) based on date range
- **Boolean Handling**: Special case rendering with count display instead of averages in legend
- **Tap Interactions**: 
  - Data points show tooltips with value and date
  - Y-axis cycling between different source scales
  - Haptic feedback for user interactions

## Recent Development History
- **aa80b0b**: Enhanced boolean time plot Y-axis labels and switched to counts instead of averages
- **fb4f387**: Improved time chart scaling consistency and rotated tapped labels sideways
- **5a7502e**: Updated time chart legend to show averages in trace colors instead of generic text
- **5b44646**: Added average display functionality in time plot legends
- **848f8d8**: Major refactoring to separate chart functionality into individual files
- **328d6a1**: Reorganized UI layout (swapped date sliders with source buttons), expanded to 4 sources, fixed Y-axis interaction
- **428efe9**: Initial working implementation of time plots
- **5a025b9**: Fixed issue preventing boolean sources from being used in distribution background