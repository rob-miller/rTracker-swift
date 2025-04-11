//
//  trackerChartTimePlot.swift
//  rTracker
//
//  Created by Robert Miller on 09/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import UIKit

// MARK: - time line plot implementation
extension TrackerChart {
    
    internal func getEligibleValueObjsForTimeChart() -> [valueObj] {
        guard let tracker = tracker else { return [] }
        
        // Allow all numeric, boolean, slider, function types for time chart
        let allowedTypes = [VOT_NUMBER, VOT_BOOLEAN, VOT_FUNC, VOT_SLIDER]
        
        // Filter valueObjs based on type and privacy
        let eligibleVOs = tracker.valObjTable.filter { vo in
            // Check if type is allowed
            guard allowedTypes.contains(vo.vtype) else { return false }
            
            // Check privacy settings (if applicable)
            let privacy = vo.optDict["privacy"] ?? "0"
            return Int(privacy) ?? 0 <= privacyValue
        }
        
        return eligibleVOs
    }
    
    @objc internal func clearTimeSources() {
        // Clear all time chart sources
        timeChartSources = [-1, -1, -1]
        
        // Reset button titles
        timeSource1Button.setTitle("Select Data Source 1", for: .normal)
        timeSource2Button.setTitle("Select Data Source 2 (Optional)", for: .normal)
        timeSource3Button.setTitle("Select Data Source 3 (Optional)", for: .normal)
        
        // Clear the chart and show instruction
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        noDataLabel.text = "Configure chart options below"
        noDataLabel.isHidden = false
        
        // Reset y-axis mode
        selectedYAxisMode = 0
    }
    
    // 11. File: trackerChartDataHandling.swift - Add TimeSeriesData struct and methods
    // Add these to the TrackerChart extension

    // Helper struct for time series data
    internal struct TimeSeriesData {
        let id: Int
        let name: String
        let type: Int
        let dataPoints: [(Date, Double)]
        let index: Int
        
        var values: [Double] {
            return dataPoints.map { $0.1 }
        }
        
        var minValue: Double {
            return values.min() ?? 0
        }
        
        var maxValue: Double {
            return values.max() ?? 1
        }
        
        var range: Double {
            return maxValue - minValue
        }
        
        var isBooleanType: Bool {
            return type == VOT_BOOLEAN
        }
    }

    // Generate time chart data
    internal func generateTimeChartData() {
        guard tracker != nil,
              let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate,
              timeChartSources.contains(where: { $0 != -1 }) else {
            noDataLabel.text = "Please select at least one data source"
            noDataLabel.isHidden = false
            return
        }
        
        // Convert date range to Unix timestamps for SQL query
        let startTimestamp = Int(selectedStartDate.timeIntervalSince1970)
        let endTimestamp = Int(selectedEndDate.timeIntervalSince1970)
        
        // Collect data for each selected source
        var sourcesData: [[String: Any]] = []
        var allTimeSeriesData: [TimeSeriesData] = []
        
        for (index, sourceID) in timeChartSources.enumerated() {
            guard sourceID != -1 else { continue }
            
            // Get value object details
            guard let valueObj = tracker?.valObjTable.first(where: { $0.vid == sourceID }) else { continue }
            
            // Fetch data points for this source
            let dataPoints = fetchDataForValueObj(id: sourceID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
            
            // Skip if no data
            if dataPoints.isEmpty { continue }
            
            // Create a time series data structure
            let timeSeriesData = TimeSeriesData(
                id: sourceID,
                name: valueObj.valueName ?? "Source \(index + 1)",
                type: valueObj.vtype,
                dataPoints: dataPoints,
                index: index
            )
            
            allTimeSeriesData.append(timeSeriesData)
            
            // Store source data
            let sourceData: [String: Any] = [
                "id": sourceID,
                "name": valueObj.valueName ?? "Source \(index + 1)",
                "type": valueObj.vtype,
                "dataPoints": dataPoints,
                "index": index
            ]
            
            sourcesData.append(sourceData)
        }
        
        // If no data, show message
        if sourcesData.isEmpty {
            noDataLabel.text = "No data found in the selected date range"
            noDataLabel.isHidden = false
            return
        }
        
        // Calculate Y-axis ranges
        let yAxisRanges = calculateYAxisRanges(allTimeSeriesData)
        
        // Store the chart data
        chartData = [
            "type": "time",
            "sourcesData": sourcesData,
            "yAxisRanges": yAxisRanges
        ]
        
        // Render the chart
        renderTimeChart()
    }

    // Calculate appropriate Y-axis ranges for the time series data
    internal func calculateYAxisRangesX(_ timeSeriesData: [TimeSeriesData]) -> [String: Any] {
        guard !timeSeriesData.isEmpty else {
            return ["mode": "individual"]
        }
        
        // For boolean data, the range is always 0 to 1
        let nonBooleanSeries = timeSeriesData.filter { !$0.isBooleanType }
        
        // If we only have boolean data, use a fixed range
        if nonBooleanSeries.isEmpty {
            return [
                "mode": "fixed",
                "min": 0.0,
                "max": 1.0
            ]
        }
        
        // Check if we can use a shared Y-axis
        // First get the ranges of all non-boolean series
        let ranges = nonBooleanSeries.map { series -> (min: Double, max: Double, id: Int) in
            // Add padding for single value or very small ranges
            let range = max(0.1, series.range)
            let paddedMin = series.minValue - (range * 0.05)
            let paddedMax = series.maxValue + (range * 0.05)
            return (paddedMin, paddedMax, series.id)
        }
        
        // Check if ranges overlap by at least 25%
        if ranges.count > 1 {
            var sharedRanges: [[Int]] = [] // Groups of sources that can share a Y-axis
            
            // Test each pair of ranges for overlap
            for i in 0..<ranges.count-1 {
                for j in i+1..<ranges.count {
                    let r1 = ranges[i]
                    let r2 = ranges[j]
                    
                    let r1Size = r1.max - r1.min
                    let r2Size = r2.max - r2.min
                    
                    // Calculate overlap
                    let overlapMin = max(r1.min, r2.min)
                    let overlapMax = min(r1.max, r2.max)
                    let overlap = max(0, overlapMax - overlapMin)
                    
                    // Check if overlap is at least 25% of the smaller range
                    let smallerRange = min(r1Size, r2Size)
                    let overlapPercent = overlap / smallerRange
                    
                    if overlapPercent >= 0.25 {
                        // These ranges can share a Y-axis
                        // Find if either is already in a group
                        var groupIndex: Int? = nil
                        for (idx, group) in sharedRanges.enumerated() {
                            if group.contains(r1.id) || group.contains(r2.id) {
                                groupIndex = idx
                                break
                            }
                        }
                        
                        if let idx = groupIndex {
                            // Add to existing group
                            if !sharedRanges[idx].contains(r1.id) {
                                sharedRanges[idx].append(r1.id)
                            }
                            if !sharedRanges[idx].contains(r2.id) {
                                sharedRanges[idx].append(r2.id)
                            }
                        } else {
                            // Create new group
                            sharedRanges.append([r1.id, r2.id])
                        }
                    }
                }
            }
            
            // If we found groups that can share, use the shared range
            if !sharedRanges.isEmpty {
                // Find the largest group
                let largestGroup = sharedRanges.max(by: { $0.count < $1.count }) ?? []
                
                // For sources in the largest group, calculate a shared range
                if largestGroup.count > 1 {
                    let groupRanges = ranges.filter { largestGroup.contains($0.id) }
                    let minVal = groupRanges.map { $0.min }.min() ?? 0
                    let maxVal = groupRanges.map { $0.max }.max() ?? 1
                    
                    return [
                        "mode": "shared",
                        "min": minVal,
                        "max": maxVal,
                        "sharedIds": largestGroup
                    ]
                }
            }
        }
        
        // Default to individual ranges
        let individualRanges = ranges.reduce(into: [Int: [String: Double]]()) { result, range in
            result[range.id] = [
                "min": range.min,
                "max": range.max
            ]
        }
        
        return [
            "mode": "individual",
            "ranges": individualRanges
        ]
    }

    // Calculate appropriate Y-axis ranges for the time series data
    internal func calculateYAxisRanges(_ timeSeriesData: [TimeSeriesData]) -> [String: Any] {
        guard !timeSeriesData.isEmpty else {
            return ["mode": "individual"]
        }
        
        // For boolean data, the range is always 0 to 1
        let nonBooleanSeries = timeSeriesData.filter { !$0.isBooleanType }
        
        // If we only have boolean data, use a fixed range
        if nonBooleanSeries.isEmpty {
            return [
                "mode": "fixed",
                "min": 0.0,
                "max": 1.0
            ]
        }
        
        // IMPROVEMENT 1: Check for common units in value names
        let commonUnitSeries = findSeriesWithCommonUnits(nonBooleanSeries)
        if !commonUnitSeries.isEmpty && commonUnitSeries.count > 1 {
            // Use a shared range for series with common units, starting at 0 if appropriate
            let minVal = shouldStartAtZero(commonUnitSeries) ? 0 : commonUnitSeries.map { $0.minValue }.min() ?? 0
            let maxVal = commonUnitSeries.map { $0.maxValue }.max() ?? 1
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": commonUnitSeries.map { $0.id }
            ]
        }
        
        // IMPROVEMENT 2: Check based on value scale ratios
        let seriesGroups = groupSeriesByScaleRatio(nonBooleanSeries)
        if let largestGroup = seriesGroups.max(by: { $0.count < $1.count }), largestGroup.count > 1 {
            let groupIds = largestGroup.map { $0.id }
            let minVal = shouldStartAtZero(largestGroup) ? 0 : largestGroup.map { $0.minValue }.min() ?? 0
            let maxVal = largestGroup.map { $0.maxValue }.max() ?? 1
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": groupIds
            ]
        }
        
        // If all above checks fail, fall back to the original overlap check
        // but with a more nuanced approach
        let potentiallySharedGroups = findOverlappingGroups(nonBooleanSeries)
        if let largestGroup = potentiallySharedGroups.max(by: { $0.count < $1.count }), largestGroup.count > 1 {
            let groupIds = largestGroup.map { $0.id }
            let minVal = shouldStartAtZero(largestGroup) ? 0 : largestGroup.map { $0.minValue }.min() ?? 0
            let maxVal = largestGroup.map { $0.maxValue }.max() ?? 1
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": groupIds
            ]
        }
        
        // Default to individual ranges if no groups can be formed
        let individualRanges = nonBooleanSeries.reduce(into: [Int: [String: Double]]()) { result, series in
            // For non-grouped series, also consider if they should start at zero
            let minVal = shouldStartAtZero([series]) ? 0 : series.minValue
            let paddingFactor = 0.05 // 5% padding
            let range = max(0.1, series.maxValue - minVal)
            
            result[series.id] = [
                "min": minVal - (range * paddingFactor),
                "max": series.maxValue + (range * paddingFactor)
            ]
        }
        
        return [
            "mode": "individual",
            "ranges": individualRanges
        ]
    }

    // Helper function to identify series that might have common units
    private func findSeriesWithCommonUnits(_ series: [TimeSeriesData]) -> [TimeSeriesData] {
        // Keywords that might indicate time measurements in minutes
        let timeKeywords = ["minute", "min", "sleep", "duration", "time"]
        let percentageKeywords = ["percent", "%", "ratio", "rate"]
        let temperatureKeywords = ["temp", "temperature", "degree", "celsius", "fahrenheit"]
        
        // Group series by potential common units
        let timeRelated = series.filter { data in
            let name = data.name.lowercased()
            return timeKeywords.contains { name.contains($0) }
        }
        
        let percentageRelated = series.filter { data in
            let name = data.name.lowercased()
            return percentageKeywords.contains { name.contains($0) }
        }
        
        let temperatureRelated = series.filter { data in
            let name = data.name.lowercased()
            return temperatureKeywords.contains { name.contains($0) }
        }
        
        // Return the largest group (if any)
        let groups = [timeRelated, percentageRelated, temperatureRelated].filter { !$0.isEmpty }
        return groups.max(by: { $0.count < $1.count }) ?? []
    }

    // Helper function to group series by value scale similarity
    private func groupSeriesByScaleRatio(_ series: [TimeSeriesData]) -> [[TimeSeriesData]] {
        guard series.count > 1 else { return [] }
        
        // Maximum ratio between max values to be considered similar scale
        let maxRatioThreshold = 10.0
        
        var groups: [[TimeSeriesData]] = []
        var processedIds = Set<Int>()
        
        for i in 0..<series.count {
            if processedIds.contains(series[i].id) { continue }
            
            var currentGroup: [TimeSeriesData] = [series[i]]
            processedIds.insert(series[i].id)
            
            for j in 0..<series.count {
                if i == j || processedIds.contains(series[j].id) { continue }
                
                let maxValue1 = max(abs(series[i].maxValue), 0.001) // Avoid division by zero
                let maxValue2 = max(abs(series[j].maxValue), 0.001)
                
                let ratio = maxValue1 > maxValue2 ? maxValue1 / maxValue2 : maxValue2 / maxValue1
                
                if ratio <= maxRatioThreshold {
                    currentGroup.append(series[j])
                    processedIds.insert(series[j].id)
                }
            }
            
            if currentGroup.count > 1 {
                groups.append(currentGroup)
            }
        }
        
        return groups
    }

    // Helper function to find overlapping groups with a more nuanced approach
    private func findOverlappingGroups(_ series: [TimeSeriesData]) -> [[TimeSeriesData]] {
        guard series.count > 1 else { return [] }
        
        var groups: [[TimeSeriesData]] = []
        var processedIds = Set<Int>()
        
        for i in 0..<series.count {
            if processedIds.contains(series[i].id) { continue }
            
            var currentGroup: [TimeSeriesData] = [series[i]]
            processedIds.insert(series[i].id)
            
            let r1Min = series[i].minValue
            let r1Max = series[i].maxValue
            let r1Size = r1Max - r1Min
            
            for j in 0..<series.count {
                if i == j || processedIds.contains(series[j].id) { continue }
                
                let r2Min = series[j].minValue
                let r2Max = series[j].maxValue
                let r2Size = r2Max - r2Min
                
                // Calculate overlap
                let overlapMin = max(r1Min, r2Min)
                let overlapMax = min(r1Max, r2Max)
                let overlap = max(0, overlapMax - overlapMin)
                
                // Check for substantial overlap (20% instead of 25%)
                let smallerRange = min(r1Size, r2Size)
                let overlapPercent = overlap / smallerRange
                
                // Also consider similar magnitudes even without direct overlap
                let maxValue1 = max(abs(r1Max), 0.001)
                let maxValue2 = max(abs(r2Max), 0.001)
                let ratio = maxValue1 > maxValue2 ? maxValue1 / maxValue2 : maxValue2 / maxValue1
                
                if overlapPercent >= 0.2 || (ratio <= 5.0 && (r1Min >= 0 && r2Min >= 0)) {
                    currentGroup.append(series[j])
                    processedIds.insert(series[j].id)
                }
            }
            
            if currentGroup.count > 1 {
                groups.append(currentGroup)
            }
        }
        
        return groups
    }

    // Helper function to determine if a group of series should start at zero
    private func shouldStartAtZero(_ series: [TimeSeriesData]) -> Bool {
        // Time series measurements typically start at zero
        // Check if the minimum values are close to zero compared to the max values
        
        let timeKeywords = ["minute", "min", "sleep", "duration", "time", "count", "steps", "calories"]
        let hasTimeRelatedNames = series.contains { data in
            let name = data.name.lowercased()
            return timeKeywords.contains { name.contains($0) }
        }
        
        // If series has time-related names or all series have non-negative mins
        // that are small compared to their max values
        let allNonNegative = series.allSatisfy { $0.minValue >= 0 }
        let allMinsSmallRelativeToMax = series.allSatisfy {
            let range = $0.maxValue - $0.minValue
            return range > 0 && $0.minValue / range < 0.2 // Min is less than 20% of range
        }
        
        return hasTimeRelatedNames || (allNonNegative && allMinsSmallRelativeToMax)
    }
    // Add rendering methods
    // Implement the renderTimeChart method and related methods to draw the time chart

    // Render the time chart
    internal func renderTimeChart() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard chartData["type"] as? String == "time",
              let sourcesData = chartData["sourcesData"] as? [[String: Any]],
              !sourcesData.isEmpty else {
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Get graph dimensions
        let graphWidth = chartView.bounds.width - leftMargin - rightMargin
        let graphHeight = chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace
        
        // Get date range for X-axis
        guard let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate else {
            return
        }
        
        // Get the Y-axis ranges
        guard let yAxisRanges = chartData["yAxisRanges"] as? [String: Any] else {
            return
        }
        
        // Draw base axes
        drawTimeChartAxes(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            yAxisRanges: yAxisRanges
        )
        
        // Draw data series
        drawTimeSeriesData(
            sourcesData: sourcesData,
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            yAxisRanges: yAxisRanges
        )
        
        // Draw legend
        drawTimeChartLegend(sourcesData: sourcesData)
    }

    // Draw the axes for the time chart
    internal func drawTimeChartAxes(
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        startDate: Date,
        endDate: Date,
        yAxisRanges: [String: Any]
    ) {
        // Create axes container
        let axesView = UIView(frame: chartView.bounds)
        axesView.tag = 2002  // Tag to identify the axes view
        chartView.addSubview(axesView)
        
        // Draw X and Y axes
        let xAxis = UIView(frame: CGRect(x: leftMargin, y: topMargin + graphHeight, width: graphWidth, height: 1))
        xAxis.backgroundColor = .label
        axesView.addSubview(xAxis)
        
        let yAxis = UIView(frame: CGRect(x: leftMargin, y: topMargin, width: 1, height: graphHeight))
        yAxis.backgroundColor = .label
        axesView.addSubview(yAxis)
        
        // Draw Y-axis with tick marks based on the mode
        let yAxisView = drawTimeChartYAxis(
            graphHeight: graphHeight,
            yAxisRanges: yAxisRanges
        )
        
        // Add a tap recognizer to the Y-axis to cycle through views
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cycleYAxisView(_:)))
        yAxisView.addGestureRecognizer(tapGesture)
        yAxisView.isUserInteractionEnabled = true
        axesView.addSubview(yAxisView)
        currentYAxisView = yAxisView
        
        // Draw date markers on X-axis
        drawDateMarkers(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            startDate: startDate,
            endDate: endDate,
            axesView: axesView
        )
    }

    // Draw the Y-axis with appropriate labels
    internal func drawTimeChartYAxis(
        graphHeight: CGFloat,
        yAxisRanges: [String: Any]
    ) -> UIView {
        let yAxisView = UIView(frame: CGRect(x: 0, y: topMargin, width: leftMargin, height: graphHeight))
        
        let mode = yAxisRanges["mode"] as? String ?? "individual"
        
        switch mode {
        case "fixed":
            // Fixed range for boolean data (0-1)
            drawYAxisTicks(
                in: yAxisView,
                min: yAxisRanges["min"] as? Double ?? 0.0,
                max: yAxisRanges["max"] as? Double ?? 1.0,
                graphHeight: graphHeight,
                color: .label
            )
            
        case "shared":
            // Shared Y-axis for overlapping ranges
            let min = yAxisRanges["min"] as? Double ?? 0.0
            let max = yAxisRanges["max"] as? Double ?? 1.0
            drawYAxisTicks(
                in: yAxisView,
                min: min,
                max: max,
                graphHeight: graphHeight,
                color: .label
            )
            
        case "individual":
            // For individual ranges, show the first one by default
            if let individualRanges = yAxisRanges["ranges"] as? [Int: [String: Double]],
               let firstRange = individualRanges.first?.value {
                let min = firstRange["min"] ?? 0.0
                let max = firstRange["max"] ?? 1.0
                drawYAxisTicks(
                    in: yAxisView,
                    min: min,
                    max: max,
                    graphHeight: graphHeight,
                    color: .label
                )
            } else {
                // Fallback to default range
                drawYAxisTicks(
                    in: yAxisView,
                    min: 0.0,
                    max: 1.0,
                    graphHeight: graphHeight,
                    color: .label
                )
            }
            
        default:
            // Default to a 0-1 range
            drawYAxisTicks(
                in: yAxisView,
                min: 0.0,
                max: 1.0,
                graphHeight: graphHeight,
                color: .label
            )
        }
        
        return yAxisView
    }

    // Continuation of the Time Chart Implementation - Rendering Logic

    // Draw Y-axis tick marks and labels
    internal func drawYAxisTicks(
        in view: UIView,
        min: Double,
        max: Double,
        graphHeight: CGFloat,
        color: UIColor
    ) {
        // Create tick marks and labels
        let tickCount = 5
        let range = max - min
        
        for i in 0...tickCount {
            let value = max - Double(i) * range / Double(tickCount)
            let y = CGFloat(i) * graphHeight / CGFloat(tickCount)
            
            // Grid line (lighter)
            if i > 0 {  // Skip the X-axis line
                let gridLine = UIView(frame: CGRect(x: 0, y: y, width: view.bounds.width + chartView.bounds.width - leftMargin - rightMargin, height: 0.5))
                gridLine.backgroundColor = UIColor.systemGray4
                view.addSubview(gridLine)
            }
            
            // Tick mark
            let tick = UIView(frame: CGRect(x: view.bounds.width - 5, y: y, width: 5, height: 1))
            tick.backgroundColor = color
            view.addSubview(tick)
            
            // Label
            let label = UILabel(frame: CGRect(x: 0, y: y - 8, width: view.bounds.width - 10, height: 15))
            
            // Format the label based on the value
            // For boolean data, only show 0 and 1
            if range == 1.0 && min == 0.0 && max == 1.0 {
                if i == 0 || i == tickCount {
                    label.text = String(format: "%.0f", value)
                } else {
                    label.text = ""
                }
            } else if abs(value) < 0.01 {
                // For very small values, use scientific notation
                label.text = String(format: "%.2e", value)
            } else if abs(value) > 1000 {
                // For large values, use K/M notation
                if abs(value) > 1000000 {
                    label.text = String(format: "%.1fM", value / 1000000)
                } else {
                    label.text = String(format: "%.1fK", value / 1000)
                }
            } else if range < 0.1 {
                // For small ranges, use more decimal places
                label.text = String(format: "%.3f", value)
            } else if range < 1 {
                label.text = String(format: "%.2f", value)
            } else if range < 10 {
                label.text = String(format: "%.1f", value)
            } else {
                label.text = String(format: "%.0f", value)
            }
            
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            label.textColor = color
            view.addSubview(label)
        }
    }

    // Draw date markers on the X-axis
    internal func drawDateMarkers(
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        startDate: Date,
        endDate: Date,
        axesView: UIView
    ) {
        let dateInterval = endDate.timeIntervalSince(startDate)
        //let calendar = Calendar.current
        
        // Determine appropriate date format based on interval
        let dateFormatter = DateFormatter()
        
        if dateInterval <= 86400 * 2 {  // Less than 2 days
            dateFormatter.dateFormat = "HH:mm"
            drawHourlyMarkers(startDate: startDate, endDate: endDate, graphWidth: graphWidth, graphHeight: graphHeight, axesView: axesView, dateFormatter: dateFormatter)
        } else if dateInterval <= 86400 * 31 {  // Less than a month
            dateFormatter.dateFormat = "d MMM"
            drawDailyMarkers(startDate: startDate, endDate: endDate, graphWidth: graphWidth, graphHeight: graphHeight, axesView: axesView, dateFormatter: dateFormatter)
        } else if dateInterval <= 86400 * 365 {  // Less than a year
            dateFormatter.dateFormat = "MMM"
            drawMonthlyMarkers(startDate: startDate, endDate: endDate, graphWidth: graphWidth, graphHeight: graphHeight, axesView: axesView, dateFormatter: dateFormatter)
        } else {  // More than a year
            dateFormatter.dateFormat = "yyyy"
            drawYearlyMarkers(startDate: startDate, endDate: endDate, graphWidth: graphWidth, graphHeight: graphHeight, axesView: axesView, dateFormatter: dateFormatter)
        }
    }

    // Draw hourly markers
    internal func drawHourlyMarkers(
        startDate: Date,
        endDate: Date,
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        axesView: UIView,
        dateFormatter: DateFormatter
    ) {
        let calendar = Calendar.current
        let totalInterval = endDate.timeIntervalSince(startDate)
        
        // Get start hour rounded down to the nearest hour
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
        components.minute = 0
        components.second = 0
        
        guard let roundedStartDate = calendar.date(from: components) else { return }
        
        // Calculate appropriate hour intervals based on total duration
        let hourInterval: Int
        if totalInterval <= 86400 {  // 1 day
            hourInterval = 3
        } else {
            hourInterval = 6
        }
        
        // Iterate through hours within the range
        var currentDate = roundedStartDate
        while currentDate <= endDate {
            // Calculate position
            let progress = currentDate.timeIntervalSince(startDate) / totalInterval
            let x = leftMargin + CGFloat(progress) * graphWidth
            
            // Only show if within the graph bounds
            if x >= leftMargin && x <= leftMargin + graphWidth {
                // Draw tick mark
                let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
                tick.backgroundColor = .label
                axesView.addSubview(tick)
                
                // Draw hour label only at interval points
                let hour = calendar.component(.hour, from: currentDate)
                if hour % hourInterval == 0 {
                    let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
                    label.text = dateFormatter.string(from: currentDate)
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: 10)
                    axesView.addSubview(label)
                }
            }
            
            // Move to next hour
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        }
    }

    // Draw the time series data
    internal func drawTimeSeriesData(
        sourcesData: [[String: Any]],
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        startDate: Date,
        endDate: Date,
        yAxisRanges: [String: Any]
    ) {
        // Create data points container
        let dataPointsView = UIView(frame: chartView.bounds)
        dataPointsView.tag = 2003  // Tag to identify the data points view
        chartView.addSubview(dataPointsView)
        
        // Get the mode
        let mode = yAxisRanges["mode"] as? String ?? "individual"
        
        // Colors for each series (blue, green, red)
        let seriesColors: [UIColor] = [
            UIColor.systemBlue,
            UIColor.systemGreen,
            UIColor.systemRed
        ]
        
        // Shared y-axis range (if applicable)
        var sharedMinY: Double = 0
        var sharedMaxY: Double = 1
        var sharedIds: [Int] = []
        
        if mode == "shared" {
            sharedMinY = yAxisRanges["min"] as? Double ?? 0
            sharedMaxY = yAxisRanges["max"] as? Double ?? 1
            sharedIds = yAxisRanges["sharedIds"] as? [Int] ?? []
        } else if mode == "fixed" {
            sharedMinY = yAxisRanges["min"] as? Double ?? 0
            sharedMaxY = yAxisRanges["max"] as? Double ?? 1
        }
        
        // Individual ranges (if applicable)
        var individualRanges: [Int: [String: Double]] = [:]
        if mode == "individual" {
            individualRanges = yAxisRanges["ranges"] as? [Int: [String: Double]] ?? [:]
        }
        
        // Total time range for x-axis positioning
        let totalTimeInterval = endDate.timeIntervalSince(startDate)
        
        // Draw each series
        for (index, sourceData) in sourcesData.enumerated() {
            guard index < seriesColors.count,
                  let dataPoints = sourceData["dataPoints"] as? [(Date, Double)],
                  let sourceType = sourceData["type"] as? Int,
                  let id = sourceData["id"] as? Int else {
                continue
            }
            
            // Get min/max Y values for this series
            var minY: Double = 0
            var maxY: Double = 1
            
            switch mode {
            case "shared":
                // Use shared range if this ID is in the shared group
                if sharedIds.contains(id) {
                    minY = sharedMinY
                    maxY = sharedMaxY
                } else if let range = individualRanges[id] {
                    // Otherwise use individual range
                    minY = range["min"] ?? 0
                    maxY = range["max"] ?? 1
                }
            case "fixed":
                // Use fixed range (typically for boolean data)
                minY = sharedMinY
                maxY = sharedMaxY
            case "individual":
                // Use individual range for this source
                if let range = individualRanges[id] {
                    minY = range["min"] ?? 0
                    maxY = range["max"] ?? 1
                }
            default:
                // Default ranges
                minY = 0
                maxY = 1
            }
            
            // Skip if no data points or invalid range
            if dataPoints.isEmpty || maxY - minY <= 0 {
                continue
            }
            
            let isBooleanType = sourceType == VOT_BOOLEAN
            let color = seriesColors[index]
            
            if isBooleanType {
                // For boolean data, draw dots only for "true" values
                drawBooleanDots(
                    dataPoints: dataPoints,
                    graphWidth: graphWidth,
                    graphHeight: graphHeight,
                    totalTimeInterval: totalTimeInterval,
                    startDate: startDate,
                    color: color,
                    containerView: dataPointsView
                )
            } else {
                // For numeric data, draw lines
                drawTimeSeries(
                    dataPoints: dataPoints,
                    graphWidth: graphWidth,
                    graphHeight: graphHeight,
                    totalTimeInterval: totalTimeInterval,
                    startDate: startDate,
                    minY: minY,
                    maxY: maxY,
                    color: color,
                    containerView: dataPointsView
                )
            }
        }
    }

    // Draw boolean data as dots for true values
    internal func drawBooleanDots(
        dataPoints: [(Date, Double)],
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        totalTimeInterval: TimeInterval,
        startDate: Date,
        color: UIColor,
        containerView: UIView
    ) {
        let dotSize: CGFloat = 6
        
        for (date, value) in dataPoints {
            // Only draw dots for "true" values (value >= 0.5)
            guard value >= 0.5 else { continue }
            
            // Calculate position
            let timeOffset = date.timeIntervalSince(startDate)
            let progress = timeOffset / totalTimeInterval
            
            // Skip if out of range
            if progress < 0 || progress > 1 {
                continue
            }
            
            let x = leftMargin + CGFloat(progress) * graphWidth
            let y = topMargin + graphHeight / 2  // Center vertically for boolean data
            
            // Create dot
            let dotView = UIView(frame: CGRect(
                x: x - dotSize/2,
                y: y - dotSize/2,
                width: dotSize,
                height: dotSize
            ))
            dotView.backgroundColor = color
            dotView.layer.cornerRadius = dotSize / 2
            containerView.addSubview(dotView)
            
            // Add date tooltip on tap
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showTimePointDetails(_:)))
            dotView.addGestureRecognizer(tapGesture)
            dotView.isUserInteractionEnabled = true
            
            // Store the data for tooltips
            let userData = ["value": value, "date": date] as [String: Any]
            objc_setAssociatedObject(dotView, AssociatedKeys.pointData, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // Draw numeric data as a line chart
    internal func drawTimeSeries(
        dataPoints: [(Date, Double)],
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        totalTimeInterval: TimeInterval,
        startDate: Date,
        minY: Double,
        maxY: Double,
        color: UIColor,
        containerView: UIView
    ) {
        // Need at least two points to draw a line
        guard dataPoints.count >= 2 else {
            // If only one point, draw a dot
            if dataPoints.count == 1 {
                let (date, value) = dataPoints[0]
                let timeOffset = date.timeIntervalSince(startDate)
                let progress = timeOffset / totalTimeInterval
                
                // Skip if out of range
                if progress < 0 || progress > 1 {
                    return
                }
                
                let x = leftMargin + CGFloat(progress) * graphWidth
                let yRange = maxY - minY
                let y = topMargin + graphHeight - CGFloat((value - minY) / yRange) * graphHeight
                
                // Create dot
                let dotSize: CGFloat = 6
                let dotView = UIView(frame: CGRect(
                    x: x - dotSize/2,
                    y: y - dotSize/2,
                    width: dotSize,
                    height: dotSize
                ))
                dotView.backgroundColor = color
                dotView.layer.cornerRadius = dotSize / 2
                containerView.addSubview(dotView)
                
                // Add tooltip
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showTimePointDetails(_:)))
                dotView.addGestureRecognizer(tapGesture)
                dotView.isUserInteractionEnabled = true
                
                let userData = ["value": value, "date": date] as [String: Any]
                objc_setAssociatedObject(dotView, AssociatedKeys.pointData, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return
        }
        
        // Sort data points by date
        let sortedPoints = dataPoints.sorted { $0.0 < $1.0 }
        
        // Create path for line
        let linePath = UIBezierPath()
        var firstPoint = true
        var dotViews: [UIView] = []
        
        for (date, value) in sortedPoints {
            // Calculate position
            let timeOffset = date.timeIntervalSince(startDate)
            let progress = timeOffset / totalTimeInterval
            
            // Skip if out of range
            if progress < 0 || progress > 1 {
                continue
            }
            
            let x = leftMargin + CGFloat(progress) * graphWidth
            let yRange = maxY - minY
            let y = topMargin + graphHeight - CGFloat((value - minY) / yRange) * graphHeight
            
            // Add point to path
            if firstPoint {
                linePath.move(to: CGPoint(x: x, y: y))
                firstPoint = false
            } else {
                linePath.addLine(to: CGPoint(x: x, y: y))
            }
            
            // Create a small dot at each data point
            let dotSize: CGFloat = 5
            let dotView = UIView(frame: CGRect(
                x: x - dotSize/2,
                y: y - dotSize/2,
                width: dotSize,
                height: dotSize
            ))
            dotView.backgroundColor = color
            dotView.layer.cornerRadius = dotSize / 2
            
            // Add tooltip
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showTimePointDetails(_:)))
            dotView.addGestureRecognizer(tapGesture)
            dotView.isUserInteractionEnabled = true
            
            let userData = ["value": value, "date": date] as [String: Any]
            objc_setAssociatedObject(dotView, AssociatedKeys.pointData, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            dotViews.append(dotView)
        }
        
        // Create line layer
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = color.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        containerView.layer.addSublayer(lineLayer)
        
        // Add dot views after adding the line
        for dotView in dotViews {
            containerView.addSubview(dotView)
        }
    }

    // Show tooltip for data point
    @objc internal func showTimePointDetails(_ sender: UITapGestureRecognizer) {
        guard let pointView = sender.view,
              let pointData = objc_getAssociatedObject(pointView, AssociatedKeys.pointData) as? [String: Any] else {
            return
        }
        
        // Extract point data
        let value = pointData["value"] as? Double ?? 0
        let date = pointData["date"] as? Date ?? Date()
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: date)
        
        // Create alert with details
        let alert = UIAlertController(
            title: "Data Point Details",
            message: """
                Value: \(String(format: "%.2f", value))
                Date: \(dateString)
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // Cycle through Y-axis views when the Y-axis is tapped
    @objc internal func cycleYAxisView(_ sender: UITapGestureRecognizer) {
        guard let sourcesData = chartData["sourcesData"] as? [[String: Any]],
              let yAxisRanges = chartData["yAxisRanges"] as? [String: Any],
              let axesView = chartView.viewWithTag(2002) else {
            return
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Check the mode
        let mode = yAxisRanges["mode"] as? String ?? "individual"
        
        // Only cycle in individual mode with multiple sources
        if mode == "individual" && sourcesData.count > 1 {
            // Remove current y-axis view
            currentYAxisView?.removeFromSuperview()
            
            // Increment the mode
            selectedYAxisMode = (selectedYAxisMode + 1) % sourcesData.count
            
            guard selectedYAxisMode < sourcesData.count else {
                return
            }
            
            let sourceData = sourcesData[selectedYAxisMode]
            guard let id = sourceData["id"] as? Int else {
                return
            }
            
            // Get individual ranges
            guard let individualRanges = yAxisRanges["ranges"] as? [Int: [String: Double]],
                  let range = individualRanges[id] else {
                return
            }
            
            // Get min and max values
            let minY = range["min"] ?? 0.0
            let maxY = range["max"] ?? 1.0
            
            // Create a new Y-axis view
            let yAxisView = UIView(frame: CGRect(x: 0, y: topMargin, width: leftMargin, height: chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace))
            
            // Draw ticks with the color of the current series
            let seriesColors: [UIColor] = [UIColor.systemBlue, UIColor.systemGreen, UIColor.systemRed]
            let color = seriesColors[selectedYAxisMode % seriesColors.count]
            
            drawYAxisTicks(
                in: yAxisView,
                min: minY,
                max: maxY,
                graphHeight: chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace,
                color: color
            )
            
            // Add a tap recognizer to the Y-axis to cycle through views
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cycleYAxisView(_:)))
            yAxisView.addGestureRecognizer(tapGesture)
            yAxisView.isUserInteractionEnabled = true
            
            // Add to the axes view
            axesView.addSubview(yAxisView)
            currentYAxisView = yAxisView
            
            // Add indicator to show which source is currently selected
            if let name = sourceData["name"] as? String {
                let indicatorLabel = UILabel(frame: CGRect(x: 5, y: 5, width: leftMargin - 10, height: 20))
                indicatorLabel.text = name
                indicatorLabel.textColor = color
                indicatorLabel.font = UIFont.boldSystemFont(ofSize: 10)
                indicatorLabel.adjustsFontSizeToFitWidth = true
                indicatorLabel.textAlignment = .center
                yAxisView.addSubview(indicatorLabel)
            }
        }
    }

    // Draw a legend for the time chart
    internal func drawTimeChartLegend(sourcesData: [[String: Any]]) {
        // Colors for each series
        let seriesColors: [UIColor] = [
            UIColor.systemBlue,
            UIColor.systemGreen,
            UIColor.systemRed
        ]
        
        // Calculate legend height based on number of sources
        let itemHeight: CGFloat = 15
        let padding: CGFloat = 5
        
        let legendHeight: CGFloat = CGFloat(sourcesData.count) * (itemHeight + padding)
        
        let legendView = UIView(frame: CGRect(
            x: chartView.bounds.width - legendWidth - legendRightMargin,
            y: legendTopMargin + 10,
            width: legendWidth,
            height: legendHeight
        ))
        legendView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        legendView.layer.cornerRadius = 5
        legendView.layer.borderWidth = 0.5
        legendView.layer.borderColor = UIColor.systemGray.cgColor
        chartView.addSubview(legendView)
        
        // Add legend items
        for (index, sourceData) in sourcesData.enumerated() {
            guard index < seriesColors.count,
                  let name = sourceData["name"] as? String,
                  let type = sourceData["type"] as? Int else {
                continue
            }
            
            let color = seriesColors[index]
            let isBooleanType = type == VOT_BOOLEAN
            
            // Create container for the legend item
            let itemContainer = UIView(frame: CGRect(
                x: 0,
                y: CGFloat(index) * (itemHeight + padding),
                width: legendWidth,
                height: itemHeight + padding
            ))
            legendView.addSubview(itemContainer)
            
            // Type indicator
            var indicatorView: UIView
            
            if isBooleanType {
                // For boolean, show a dot
                let dotSize: CGFloat = 8
                let dotView = UIView(frame: CGRect(x: 10, y: (itemHeight - dotSize) / 2, width: dotSize, height: dotSize))
                dotView.backgroundColor = color
                dotView.layer.cornerRadius = dotSize / 2
                indicatorView = dotView
            } else {
                // For other types, show a line
                let lineView = UIView(frame: CGRect(x: 10, y: itemHeight / 2, width: 15, height: 2))
                lineView.backgroundColor = color
                indicatorView = lineView
            }
            
            itemContainer.addSubview(indicatorView)
            
            // Label
            let label = UILabel(frame: CGRect(
                x: 35,
                y: 0,
                width: legendWidth - 45,
                height: itemHeight
            ))
            label.text = name
            label.font = UIFont.systemFont(ofSize: 10)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            itemContainer.addSubview(label)
        }
    }
    
    // Draw daily markers
    internal func drawDailyMarkers(
        startDate: Date,
        endDate: Date,
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        axesView: UIView,
        dateFormatter: DateFormatter
    ) {
        let calendar = Calendar.current
        let totalInterval = endDate.timeIntervalSince(startDate)
        
        // Get start day rounded down to the beginning of the day
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let roundedStartDate = calendar.date(from: components) else { return }
        
        // Calculate appropriate day intervals based on total duration
        let dayInterval: Int
        let days = Int(totalInterval / 86400) + 1
        
        if days <= 7 {  // A week or less
            dayInterval = 1
        } else if days <= 14 {
            dayInterval = 2
        } else {
            dayInterval = 7  // Weekly for longer periods
        }
        
        // Iterate through days within the range
        var currentDate = roundedStartDate
        while currentDate <= endDate {
            // Calculate position
            let progress = currentDate.timeIntervalSince(startDate) / totalInterval
            let x = leftMargin + CGFloat(progress) * graphWidth
            
            // Only show if within the graph bounds
            if x >= leftMargin && x <= leftMargin + graphWidth {
                // Draw tick mark
                let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
                tick.backgroundColor = .label
                axesView.addSubview(tick)
                
                // Draw day label using the provided formatter
                let dayOfMonth = calendar.component(.day, from: currentDate)
                if dayInterval == 7 {
                    // For weekly interval, only show Mondays
                    let weekday = calendar.component(.weekday, from: currentDate)
                    if weekday == 2 {  // Monday
                        let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
                        label.text = dateFormatter.string(from: currentDate)
                        label.textAlignment = .center
                        label.font = UIFont.systemFont(ofSize: 10)
                        axesView.addSubview(label)
                    }
                } else if dayOfMonth % dayInterval == 1 || dayOfMonth == 1 {
                    // For other intervals, show based on day of month
                    let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
                    label.text = dateFormatter.string(from: currentDate)
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: 10)
                    axesView.addSubview(label)
                }
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }

    // Draw monthly markers
    internal func drawMonthlyMarkers(
        startDate: Date,
        endDate: Date,
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        axesView: UIView,
        dateFormatter: DateFormatter
    ) {
        let calendar = Calendar.current
        let totalInterval = endDate.timeIntervalSince(startDate)
        
        // Get start month rounded down to the beginning of the month
        var components = calendar.dateComponents([.year, .month], from: startDate)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let roundedStartDate = calendar.date(from: components) else { return }
        
        // Iterate through months within the range
        var currentDate = roundedStartDate
        while currentDate <= endDate {
            // Calculate position
            let progress = currentDate.timeIntervalSince(startDate) / totalInterval
            let x = leftMargin + CGFloat(progress) * graphWidth
            
            // Only show if within the graph bounds
            if x >= leftMargin && x <= leftMargin + graphWidth {
                // Draw tick mark
                let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
                tick.backgroundColor = .label
                axesView.addSubview(tick)
                
                // Draw month label
                let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
                label.text = dateFormatter.string(from: currentDate)
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 10)
                axesView.addSubview(label)
            }
            
            // Move to next month
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
    }

    // Draw yearly markers
    internal func drawYearlyMarkers(
        startDate: Date,
        endDate: Date,
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        axesView: UIView,
        dateFormatter: DateFormatter
    ) {
        let calendar = Calendar.current
        let totalInterval = endDate.timeIntervalSince(startDate)
        
        // Get start year rounded down to the beginning of the year
        var components = calendar.dateComponents([.year], from: startDate)
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let roundedStartDate = calendar.date(from: components) else { return }
        
        // Iterate through years within the range
        var currentDate = roundedStartDate
        while currentDate <= endDate {
            // Calculate position
            let progress = currentDate.timeIntervalSince(startDate) / totalInterval
            let x = leftMargin + CGFloat(progress) * graphWidth
            
            // Only show if within the graph bounds
            if x >= leftMargin && x <= leftMargin + graphWidth {
                // Draw tick mark
                let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
                tick.backgroundColor = .label
                axesView.addSubview(tick)
                
                // Draw year label
                let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
                label.text = dateFormatter.string(from: currentDate)
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 10)
                axesView.addSubview(label)
            }
            
            // Move to next year
            currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
        }
    }
    
}
