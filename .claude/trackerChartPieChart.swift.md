# trackerChartPieChart.swift Analysis Notes

## Purpose & Role
Extension of TrackerChart that implements pie chart functionality. Creates circular charts showing proportional data distribution, primarily designed for boolean and choice-type tracker variables to visualize categorical data proportions.

## Key Classes/Structs/Protocols
- Extension of `TrackerChart` class
- No additional types defined - uses parent class structures

## Important Methods/Functions
- `setupPieChartConfig()`: Creates UI with single data selection button and "no entry" toggle
- `generatePieChartData()`: Main data processing method that categorizes and counts data values
- `renderPieChart()`: Main rendering method that draws pie segments and labels
- `drawPieSlices()`: Renders individual pie segments with calculated angles and colors
- `drawPieLabels()`: Adds percentage labels to pie segments
- `processPieDataBoolean()` / `processPieDataChoice()`: Type-specific data processing methods

## Dependencies & Relationships
- Extends `TrackerChart` base functionality
- Uses `fetchDataForValueObj()` and `fetchChoiceCategories()` for data retrieval
- Designed primarily for VOT_BOOLEAN and VOT_CHOICE value object types
- No action button functionality (button is hidden for pie charts)

## Notable Patterns & Conventions
- Single data source selection (unlike multi-source time charts)
- Automatic categorization based on value object type (boolean: true/false, choice: category labels)
- Optional "no entry" segment inclusion via `showNoEntryInPieChart` toggle
- Color coding with different colors for each category
- Percentage-based labeling on pie segments

## Implementation Details
- **Data Processing**: Counts occurrences of each category value within date range
- **Segment Calculation**: Converts counts to percentages and calculates pie slice angles
- **Color Mapping**: Assigns distinct colors to each category for visual differentiation
- **No Entry Handling**: Special handling for records without data entries (optional inclusion)
- **Privacy Integration**: Respects privacy settings when fetching and displaying data
- **Action Button**: Hidden for pie charts - no specific action button functionality
- **Segment Filtering**: Removes 0% segments and empty category names for cleaner display

## Recent Development History
- **898658c**: Enhanced pie chart by removing 0% segments and empty category name segments for cleaner display
- **848f8d8**: Major refactoring to separate chart functionality into individual files
- **8ae0246**: Initial refactoring to file-based chart organization  
- **9fc06b5**: Added Y-axis labels and enhanced data loading capabilities (general chart improvements)