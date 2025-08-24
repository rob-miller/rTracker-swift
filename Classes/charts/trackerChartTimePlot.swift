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
    
    

    internal func setupTimeChartConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for data source selection
        timeSource1Button = createConfigButton(title: "Select Data Source 1", action: #selector(selectTimeSource1))
        timeSource2Button = createConfigButton(title: "Select Data Source 2 (Optional)", action: #selector(selectTimeSource2))
        timeSource3Button = createConfigButton(title: "Select Data Source 3 (Optional)", action: #selector(selectTimeSource3))
        timeSource4Button = createConfigButton(title: "Select Data Source 4 (Optional)", action: #selector(selectTimeSource4))
        //clearTimeSourceButton = createConfigButton(title: "Clear All Sources", action: #selector(clearTimeSources))
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            sliderContainer,
            timeSource1Button,
            timeSource2Button,
            timeSource3Button,
            timeSource4Button,
            //clearTimeSourceButton
            
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        configContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: configContainer.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: configContainer.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: configContainer.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: configContainer.bottomAnchor)
        ])
        
        // Update buttons with any previously selected values
        updateButtonTitles()
    }
    
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
            
            // Fetch data points for this source, excluding empty values to avoid plotting 0 for missing data
            let dataPoints = fetchDataForValueObj(id: sourceID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: true)
            
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
        
        // Debug logging for sourcesData
        DBGLog("DEBUG: generateTimeChartData created \(sourcesData.count) sources")
        for (i, sourceData) in sourcesData.enumerated() {
            DBGLog("DEBUG: Source \(i): id=\(sourceData["id"] ?? "nil"), name=\(sourceData["name"] ?? "nil"), dataPoints=\(((sourceData["dataPoints"] as? [(Date, Double)])?.count ?? 0))")
        }
        
        // Debug logging for allTimeSeriesData
        DBGLog("DEBUG: allTimeSeriesData has \(allTimeSeriesData.count) series")
        for (i, series) in allTimeSeriesData.enumerated() {
            DBGLog("DEBUG: TimeSeriesData \(i): id=\(series.id), name=\(series.name), dataPoints=\(series.dataPoints.count)")
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
        DBGLog("DEBUG: findSeriesWithCommonUnits returned \(commonUnitSeries.count) series: \(commonUnitSeries.map { "\($0.id):\($0.name)" })")
        
        // IMPROVEMENT 2: Always check scale ratios first for consistency
        let seriesGroups = groupSeriesByScaleRatio(nonBooleanSeries)
        
        // If we have both common units and scale ratio groups, prefer scale ratio for consistency
        if !commonUnitSeries.isEmpty && commonUnitSeries.count > 1 && seriesGroups.filter({ $0.count > 1 }).isEmpty {
            DBGLog("DEBUG: Using common units path for shared Y-axis (no scale ratio groups found)")
            // Use a shared range for series with common units, starting at 0 if appropriate
            let minVal = shouldStartAtZero(commonUnitSeries) ? 0 : commonUnitSeries.map { $0.minValue }.min() ?? 0
            let maxVal = commonUnitSeries.map { $0.maxValue }.max() ?? 1
            let groupIds = commonUnitSeries.map { $0.id }
            
            // Create individual ranges for series not in the shared group
            let ungroupedSeries = nonBooleanSeries.filter { !groupIds.contains($0.id) }
            let individualRanges = ungroupedSeries.reduce(into: [Int: [String: Double]]()) { result, series in
                let minVal = shouldStartAtZero([series]) ? 0 : series.minValue
                let paddingFactor = 0.05 // 5% padding
                let range = max(0.1, series.maxValue - minVal)
                
                result[series.id] = [
                    "min": minVal - (range * paddingFactor),
                    "max": series.maxValue + (range * paddingFactor)
                ]
            }
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": groupIds,
                "ranges": individualRanges
            ]
        }
        
        // IMPROVEMENT 2: Check based on value scale ratios (already called above)
        // Find the largest group that has more than one series
        if let largestGroup = seriesGroups.filter({ $0.count > 1 }).max(by: { $0.count < $1.count }) {
            DBGLog("DEBUG: Using scale ratio path for shared Y-axis")
            let groupIds = largestGroup.map { $0.id }
            let minVal = shouldStartAtZero(largestGroup) ? 0 : largestGroup.map { $0.minValue }.min() ?? 0
            let maxVal = largestGroup.map { $0.maxValue }.max() ?? 1
            
            DBGLog("DEBUG: Largest group selected: \(largestGroup.count) series, IDs: \(groupIds), range: \(minVal) to \(maxVal)")
            
            // Create individual ranges for series not in the shared group (including single-item groups)
            let ungroupedSeries = nonBooleanSeries.filter { !groupIds.contains($0.id) }
            let individualRanges = ungroupedSeries.reduce(into: [Int: [String: Double]]()) { result, series in
                let minVal = shouldStartAtZero([series]) ? 0 : series.minValue
                let paddingFactor = 0.05 // 5% padding
                let range = max(0.1, series.maxValue - minVal)
                
                DBGLog("DEBUG: Individual range calc for series \(series.id) (\(series.name)): minValue=\(series.minValue), maxValue=\(series.maxValue), shouldStartAtZero=\(shouldStartAtZero([series])), calculated minVal=\(minVal), range=\(range)")
                
                let finalMin = minVal - (range * paddingFactor)
                let finalMax = series.maxValue + (range * paddingFactor)
                
                result[series.id] = [
                    "min": finalMin,
                    "max": finalMax
                ]
                
                DBGLog("DEBUG: Final individual range for series \(series.id): min=\(finalMin), max=\(finalMax)")
            }
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": groupIds,
                "ranges": individualRanges
            ]
        }
        
        // If all above checks fail, fall back to the original overlap check
        // but with a more nuanced approach
        let potentiallySharedGroups = findOverlappingGroups(nonBooleanSeries)
        DBGLog("DEBUG: findOverlappingGroups returned \(potentiallySharedGroups.count) groups")
        if let largestGroup = potentiallySharedGroups.max(by: { $0.count < $1.count }), largestGroup.count > 1 {
            DBGLog("DEBUG: Using overlap groups path for shared Y-axis, group size: \(largestGroup.count)")
            let groupIds = largestGroup.map { $0.id }
            let minVal = shouldStartAtZero(largestGroup) ? 0 : largestGroup.map { $0.minValue }.min() ?? 0
            let maxVal = largestGroup.map { $0.maxValue }.max() ?? 1
            
            // Create individual ranges for series not in the shared group
            let ungroupedSeries = nonBooleanSeries.filter { !groupIds.contains($0.id) }
            let individualRanges = ungroupedSeries.reduce(into: [Int: [String: Double]]()) { result, series in
                let minVal = shouldStartAtZero([series]) ? 0 : series.minValue
                let paddingFactor = 0.05 // 5% padding
                let range = max(0.1, series.maxValue - minVal)
                
                result[series.id] = [
                    "min": minVal - (range * paddingFactor),
                    "max": series.maxValue + (range * paddingFactor)
                ]
            }
            
            return [
                "mode": "shared",
                "min": minVal,
                "max": maxVal,
                "sharedIds": groupIds,
                "ranges": individualRanges
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
        let maxRatioThreshold = 3.0
        
        DBGLog("DEBUG: groupSeriesByScaleRatio called with \(series.count) series")
        for (i, s) in series.enumerated() {
            DBGLog("DEBUG: Series \(i): id=\(s.id), name=\(s.name), maxValue=\(s.maxValue)")
        }
        
        var groups: [[TimeSeriesData]] = []
        var processedIds = Set<Int>()
        
        for i in 0..<series.count {
            if processedIds.contains(series[i].id) { continue }
            
            var currentGroup: [TimeSeriesData] = [series[i]]
            processedIds.insert(series[i].id)
            
            DBGLog("DEBUG: Starting group with series \(i) (id=\(series[i].id), maxValue=\(series[i].maxValue))")
            
            for j in 0..<series.count {
                if i == j || processedIds.contains(series[j].id) { continue }
                
                let maxValue1 = max(abs(series[i].maxValue), 0.001) // Avoid division by zero
                let maxValue2 = max(abs(series[j].maxValue), 0.001)
                
                let ratio = maxValue1 > maxValue2 ? maxValue1 / maxValue2 : maxValue2 / maxValue1
                
                DBGLog("DEBUG: Comparing series \(i) (max=\(maxValue1)) with series \(j) (max=\(maxValue2)), ratio=\(ratio)")
                
                if ratio <= maxRatioThreshold {
                    DBGLog("DEBUG: Adding series \(j) to group (ratio \(ratio) <= \(maxRatioThreshold))")
                    currentGroup.append(series[j])
                    processedIds.insert(series[j].id)
                } else {
                    DBGLog("DEBUG: NOT adding series \(j) to group (ratio \(ratio) > \(maxRatioThreshold))")
                }
            }
            
            DBGLog("DEBUG: Final group size: \(currentGroup.count), IDs: \(currentGroup.map { $0.id })")
            // Always append the group, even if it's a single series
            groups.append(currentGroup)
        }
        
        DBGLog("DEBUG: Total groups created: \(groups.count)")
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
                
                if overlapPercent >= 0.2 || (ratio <= 3.0 && (r1Min >= 0 && r2Min >= 0)) {
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
        
        // If series has time-related names, start at zero
        if hasTimeRelatedNames {
            return true
        }
        
        // For other series, be more conservative about starting at zero
        // Only start at zero if ALL series have minimum values very close to zero
        let allNonNegative = series.allSatisfy { $0.minValue >= 0 }
        let allMinsVeryCloseToZero = series.allSatisfy {
            let range = $0.maxValue - $0.minValue
            return range > 0 && $0.minValue / $0.maxValue < 0.1 // Min is less than 10% of max value
        }
        
        return allNonNegative && allMinsVeryCloseToZero
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
        
        // Ensure the axes (and therefore the Y-axis view) sit on top so they receive taps
        if let axesView = chartView.viewWithTag(2002) {
            chartView.bringSubviewToFront(axesView)
        }
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
            // Fixed range for boolean data (0-1) - show single "1" at 50% position
            drawYAxisTicks(
                in: yAxisView,
                min: yAxisRanges["min"] as? Double ?? 0.0,
                max: yAxisRanges["max"] as? Double ?? 1.0,
                graphHeight: graphHeight,
                color: .label,
                isBooleanData: true,
                booleanSeriesIndex: 2  // Use index 2 for 50% position (0.5)
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
                color: .label,
                isBooleanData: false,
                booleanSeriesIndex: 0
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
                    color: .label,
                    isBooleanData: false,
                    booleanSeriesIndex: 0
                )
            } else {
                // Fallback to default range
                drawYAxisTicks(
                    in: yAxisView,
                    min: 0.0,
                    max: 1.0,
                    graphHeight: graphHeight,
                    color: .label,
                    isBooleanData: false,
                    booleanSeriesIndex: 0
                )
            }
            
        default:
            // Default to a 0-1 range
            drawYAxisTicks(
                in: yAxisView,
                min: 0.0,
                max: 1.0,
                graphHeight: graphHeight,
                color: .label,
                isBooleanData: false,
                booleanSeriesIndex: 0
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
        color: UIColor,
        isBooleanData: Bool = false,
        booleanSeriesIndex: Int = 0
    ) {
        // Handle boolean data separately
        if isBooleanData {
            // For boolean data, show only a single tick at the Y position where dots are plotted
            let booleanYPositions: [CGFloat] = [0.4, 0.45, 0.5, 0.55]
            let yPositionRatio = booleanYPositions[booleanSeriesIndex % booleanYPositions.count]
            let y = graphHeight * yPositionRatio
            
            // Single tick mark
            let tick = UIView(frame: CGRect(x: view.bounds.width - 5, y: y, width: 5, height: 1))
            tick.backgroundColor = color
            view.addSubview(tick)
            
            // Single label showing "1" at the tick position
            let label = UILabel(frame: CGRect(x: 0, y: y - 8, width: view.bounds.width - 10, height: 15))
            label.text = "1"
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            label.textColor = color
            view.addSubview(label)
            
            return
        }
        
        // Create tick marks and labels for non-boolean data
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
            } else if abs(value) < 0.01 && value != 0.0 {
                // For very small values (but not zero), use scientific notation
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
                if value == 0.0 {
                    label.text = "0.000"
                } else {
                    label.text = String(format: "%.3f", value)
                }
            } else if range < 1 {
                // For medium ranges, use 2 decimal places
                if value == 0.0 {
                    label.text = "0.00"
                } else {
                    label.text = String(format: "%.2f", value)
                }
            } else if range < 10 {
                // For larger ranges, use 1 decimal place
                if value == 0.0 {
                    label.text = "0.0"
                } else {
                    label.text = String(format: "%.1f", value)
                }
            } else {
                // For very large ranges, use no decimal places
                if value == 0.0 {
                    label.text = "0"
                } else {
                    label.text = String(format: "%.0f", value)
                }
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
        
        // Colors for each series using colorSet sequence
        let seriesColors = rTracker_resource.colorSpectrum
        
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
        } else if mode == "shared" {
            // In shared mode, we also need individual ranges for ungrouped series
            individualRanges = yAxisRanges["ranges"] as? [Int: [String: Double]] ?? [:]
        }
        
        DBGLog("DEBUG: individualRanges = \(individualRanges)")
        
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
            
            // Debug logging
            DBGLog("DEBUG: Processing series \(index), id: \(id), name: \(sourceData["name"] ?? "unknown")")
            DBGLog("DEBUG: Data points count: \(dataPoints.count)")
            
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
                } else {
                    DBGLog("DEBUG: No individual range found for series \(id), using defaults")
                }
            default:
                // Default ranges
                minY = 0
                maxY = 1
            }
            
            // Debug logging for Y-axis ranges
            DBGLog("DEBUG: Y-axis range for series \(index): minY=\(minY), maxY=\(maxY), range=\(maxY - minY)")
            DBGLog("DEBUG: Mode: \(mode), sharedIds: \(sharedIds)")
            
            // Skip if no data points or invalid range
            if dataPoints.isEmpty || maxY - minY <= 0 {
                DBGLog("DEBUG: SKIPPING series \(index) - dataPoints.isEmpty: \(dataPoints.isEmpty), invalid range: \(maxY - minY <= 0)")
                continue
            }
            
            DBGLog("DEBUG: RENDERING series \(index) with color: \(seriesColors[index])")
            
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
                    containerView: dataPointsView,
                    seriesIndex: index
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
        containerView: UIView,
        seriesIndex: Int
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
            // Position boolean dots at different Y positions based on series index
            // Use positions near the center: 40%, 45%, 50%, 55% of chart height
            let booleanYPositions: [CGFloat] = [0.4, 0.45, 0.5, 0.55]
            let yPositionRatio = booleanYPositions[seriesIndex % booleanYPositions.count]
            let y = topMargin + graphHeight * yPositionRatio
            
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
        // Debug logging
        DBGLog("DEBUG: drawTimeSeries called with \(dataPoints.count) points, color: \(color)")
        DBGLog("DEBUG: Date range: \(startDate) to \(startDate.addingTimeInterval(totalTimeInterval))")
        if !dataPoints.isEmpty {
            DBGLog("DEBUG: First point: \(dataPoints.first!)")
            DBGLog("DEBUG: Last point: \(dataPoints.last!)")
        }
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
        var pointsInRange = 0
        var pointsOutOfRange = 0
        
        for (date, value) in sortedPoints {
            // Calculate position
            let timeOffset = date.timeIntervalSince(startDate)
            let progress = timeOffset / totalTimeInterval
            
            // Skip if out of range
            if progress < 0 || progress > 1 {
                pointsOutOfRange += 1
                continue
            }
            pointsInRange += 1
            
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
        
        // Debug logging
        DBGLog("DEBUG: Points in range: \(pointsInRange), out of range: \(pointsOutOfRange)")
        DBGLog("DEBUG: Total visual elements created: \(dotViews.count)")
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
        
        // Get available individual ranges (works for both individual and shared modes)
        let individualRanges = yAxisRanges["ranges"] as? [Int: [String: Double]] ?? [:]
        
        // Only cycle if we have multiple sources and ranges available
        let sharedIds = yAxisRanges["sharedIds"] as? [Int] ?? []
        let totalSourcesWithRanges = Set(sharedIds + Array(individualRanges.keys)).count
        let hasMultipleRanges = (mode == "individual" && sourcesData.count > 1) || 
                               (mode == "shared" && totalSourcesWithRanges > 1) ||
                               (mode == "fixed" && sourcesData.count > 1)
        
        if hasMultipleRanges {
            // Remove current y-axis view (which includes the indicator label)
            currentYAxisView?.removeFromSuperview()
            
            // Create list of sources that have any range (shared or individual)
            let sourcesWithRanges: [Int]
            if mode == "individual" {
                // In individual mode, all sources should have ranges
                sourcesWithRanges = sourcesData.compactMap { $0["id"] as? Int }
            } else if mode == "fixed" {
                // In fixed mode (boolean-only data), all sources can be cycled
                sourcesWithRanges = sourcesData.compactMap { $0["id"] as? Int }
            } else {
                // In shared mode, include ALL sources (both shared and individual)
                let sharedIds = yAxisRanges["sharedIds"] as? [Int] ?? []
                let individualIds = Array(individualRanges.keys)
                let allIds = Set(sharedIds + individualIds)
                sourcesWithRanges = Array(allIds).sorted()
            }
            
            // If no sources with ranges, fallback to all sources
            let cyclableSourceIds = sourcesWithRanges.isEmpty ? sourcesData.compactMap { $0["id"] as? Int } : sourcesWithRanges
            
            guard !cyclableSourceIds.isEmpty else { return }
            
            // Increment the mode (cycle through sources that have individual ranges)
            selectedYAxisMode = (selectedYAxisMode + 1) % cyclableSourceIds.count
            
            DBGLog("DEBUG: Y-axis cycling - selectedYAxisMode: \(selectedYAxisMode), cyclableSourceIds.count: \(cyclableSourceIds.count), cyclableSourceIds: \(cyclableSourceIds)")
            
            let currentSourceId = cyclableSourceIds[selectedYAxisMode]
            
            // Find the source data for this ID
            guard let sourceData = sourcesData.first(where: { $0["id"] as? Int == currentSourceId }) else {
                DBGLog("DEBUG: Could not find sourceData for currentSourceId: \(currentSourceId)")
                return
            }
            
            DBGLog("DEBUG: Found sourceData for ID \(currentSourceId): \(sourceData["name"] ?? "unknown")")
            
            // Get Y-axis range for this source
            var minY: Double = 0.0
            var maxY: Double = 1.0
            
            if mode == "individual" {
                // In individual mode, get range from individualRanges
                if let range = individualRanges[currentSourceId] {
                    minY = range["min"] ?? 0.0
                    maxY = range["max"] ?? 1.0
                    DBGLog("DEBUG: Using individual range for ID \(currentSourceId): \(minY) to \(maxY)")
                } else {
                    DBGLog("DEBUG: No individual range found for ID \(currentSourceId) in individual mode")
                }
            } else if mode == "shared" {
                // In shared mode, check if source is in shared group or has individual range
                let sharedIds = yAxisRanges["sharedIds"] as? [Int] ?? []
                if sharedIds.contains(currentSourceId) {
                    // Use shared range
                    minY = yAxisRanges["min"] as? Double ?? 0.0
                    maxY = yAxisRanges["max"] as? Double ?? 1.0
                    DBGLog("DEBUG: Using shared range for ID \(currentSourceId): \(minY) to \(maxY)")
                } else if let range = individualRanges[currentSourceId] {
                    // Use individual range
                    minY = range["min"] ?? 0.0
                    maxY = range["max"] ?? 1.0
                    DBGLog("DEBUG: Using individual range for ID \(currentSourceId): \(minY) to \(maxY)")
                } else {
                    DBGLog("DEBUG: No range found for ID \(currentSourceId) in shared mode")
                }
            } else if mode == "fixed" {
                // In fixed mode (boolean-only data), use fixed range
                minY = yAxisRanges["min"] as? Double ?? 0.0
                maxY = yAxisRanges["max"] as? Double ?? 1.0
                DBGLog("DEBUG: Using fixed range for boolean ID \(currentSourceId): \(minY) to \(maxY)")
            }
            
            // Create a new Y-axis view
            let yAxisView = UIView(frame: CGRect(x: 0, y: topMargin, width: leftMargin, height: chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace))
            yAxisView.clipsToBounds = false  // Allow rotated label to extend beyond bounds
            
            // Draw ticks with the color of the current series
            let seriesColors = rTracker_resource.colorSpectrum
            let sourceIndex = sourcesData.firstIndex(where: { $0["id"] as? Int == currentSourceId }) ?? 0
            let color = seriesColors[sourceIndex % seriesColors.count]
            
            // Check if this is boolean data
            let isBooleanData = sourceData["type"] as? Int == VOT_BOOLEAN
            
            drawYAxisTicks(
                in: yAxisView,
                min: minY,
                max: maxY,
                graphHeight: chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace,
                color: color,
                isBooleanData: isBooleanData,
                booleanSeriesIndex: sourceIndex
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
                let yAxisHeight = chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace
                // Position title in yAxisView like the tick labels
                let labelX: CGFloat = -85  // Small margin from left edge of yAxisView
                let labelY: CGFloat = yAxisHeight - 20 //yAxisHeight - 150  // Position near bottom of y-axis area
                let labelWidth: CGFloat = yAxisView.bounds.height * 0.9  // Use yAxisView height for text width after rotation
                let labelHeight: CGFloat = 20  // Height becomes width after rotation
                let indicatorLabel = UILabel(frame: CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight))
                indicatorLabel.text = name
                indicatorLabel.textColor = color
                indicatorLabel.font = UIFont.boldSystemFont(ofSize: 14)
                indicatorLabel.adjustsFontSizeToFitWidth = false
                indicatorLabel.textAlignment = .center
                indicatorLabel.numberOfLines = 2  // Maximum 2 lines as requested
                //indicatorLabel.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)  // Visible background to see label bounds
                indicatorLabel.layer.anchorPoint = CGPoint(x: 0, y: 0.5)  // Rotate around left edge
                indicatorLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
                indicatorLabel.tag = 3001  // Tag to identify the label for removal
                
                // Add to yAxisView like the tick labels
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
            UIColor.systemRed,
            UIColor.systemOrange
        ]
        
        // Calculate legend height based on number of sources (back to single line)
        let itemHeight: CGFloat = 15  // Back to original height for single line
        let padding: CGFloat = 5
        
        let legendHeight: CGFloat = CGFloat(sourcesData.count) * (itemHeight + padding)
        
        let legendView = UIView(frame: CGRect(
            x: chartView.bounds.width - legendWidth - legendRightMargin,
            y: legendTopMargin - 5,  // Moved up from +10 to -5
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
                  let type = sourceData["type"] as? Int,
                  let dataPoints = sourceData["dataPoints"] as? [(Date, Double)] else {
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
            
            // Calculate and display average
            let values = dataPoints.map { $0.1 }
            let averageText: String
            
            if isBooleanType {
                // For boolean data, show count of true values instead of percentage
                // This is more meaningful since boolean data may only store "true" entries
                let trueCount = values.filter { $0 >= 0.5 }.count
                averageText = "\(trueCount)"
            } else {
                // For numeric data, calculate average (without "Avg:" prefix)
                let average = values.isEmpty ? 0.0 : values.reduce(0.0, +) / Double(values.count)
                averageText = String(format: "%.2f", average)
            }
            
            // Average label in trace color (replaces the line/dot indicator)
            let averageLabel = UILabel(frame: CGRect(
                x: 5,
                y: 0,
                width: 40,
                height: itemHeight
            ))
            averageLabel.text = averageText
            averageLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
            averageLabel.textColor = color
            averageLabel.textAlignment = .center
            averageLabel.adjustsFontSizeToFitWidth = true
            averageLabel.minimumScaleFactor = 0.7
            itemContainer.addSubview(averageLabel)
            
            // Name label
            let nameLabel = UILabel(frame: CGRect(
                x: 50,
                y: 0,
                width: legendWidth - 55,
                height: itemHeight
            ))
            nameLabel.text = name
            nameLabel.font = UIFont.systemFont(ofSize: 10)
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.7
            itemContainer.addSubview(nameLabel)
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
        
        // Calculate total years in span
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        let totalYears = endYear - startYear + 1
        
        // Determine optimal year interval and label format based on span and available space
        let (yearInterval, useAbbreviated) = calculateOptimalYearInterval(totalYears: totalYears, graphWidth: graphWidth)
        
        // Get start year rounded down to the beginning of the year
        var components = calendar.dateComponents([.year], from: startDate)
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let roundedStartDate = calendar.date(from: components) else { return }
        
        // Track label positions to prevent overlap
        var labelPositions: [CGFloat] = []
        let minimumLabelSpacing: CGFloat = useAbbreviated ? 25 : 35 // Minimum space between label centers
        
        // Iterate through years within the range at calculated interval
        var currentDate = roundedStartDate
        var yearCount = 0
        
        while currentDate <= endDate {
            let currentYear = calendar.component(.year, from: currentDate)
            
            // Only show labels at the calculated interval, plus always show start and end years
            let shouldShowLabel = (yearCount % yearInterval == 0) || 
                                  (currentYear == startYear) || 
                                  (currentYear == endYear) ||
                                  (currentYear % 10 == 0) // Always show decade boundaries
            
            if shouldShowLabel {
                // Calculate position
                let progress = currentDate.timeIntervalSince(startDate) / totalInterval
                let x = leftMargin + CGFloat(progress) * graphWidth
                
                // Check for collision with existing labels
                let wouldCollide = labelPositions.contains { abs($0 - x) < minimumLabelSpacing }
                
                // Only show if within bounds and no collision
                if x >= leftMargin && x <= leftMargin + graphWidth && !wouldCollide {
                    // Draw tick mark
                    let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
                    tick.backgroundColor = .label
                    axesView.addSubview(tick)
                    
                    // Format year label based on span length
                    let yearText: String
                    if useAbbreviated {
                        // Use abbreviated format like '12, '15, '20
                        yearText = "'\(String(currentYear).suffix(2))"
                    } else {
                        // Use full 4-digit year
                        yearText = String(currentYear)
                    }
                    
                    // Calculate label width based on text
                    let labelWidth = useAbbreviated ? 20 : 30
                    let label = UILabel(frame: CGRect(x: x - CGFloat(labelWidth/2), y: topMargin + graphHeight + 5, width: CGFloat(labelWidth), height: 15))
                    label.text = yearText
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: 10)
                    axesView.addSubview(label)
                    
                    // Track this label position
                    labelPositions.append(x)
                }
            }
            
            // Move to next year
            currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
            yearCount += 1
        }
    }
    
    // Calculate optimal year interval and format for readable labels
    private func calculateOptimalYearInterval(totalYears: Int, graphWidth: CGFloat) -> (interval: Int, useAbbreviated: Bool) {
        // Estimate available space per year
        let spacePerYear = graphWidth / CGFloat(totalYears)
        
        // Determine interval and format based on available space and total span
        switch totalYears {
        case 1...4:
            // Short span - show all years if space allows
            return (1, false)
            
        case 5...8:
            // Medium span - show every other year, or every year if there's space
            return spacePerYear > 40 ? (1, false) : (2, false)
            
        case 9...15:
            // Longer span - show every 2-3 years
            return spacePerYear > 25 ? (2, false) : (3, false)
            
        case 16...25:
            // Long span - show every 3-5 years, consider abbreviation
            if spacePerYear > 30 {
                return (3, false)
            } else if spacePerYear > 20 {
                return (2, true) // Abbreviated format
            } else {
                return (5, true)
            }
            
        default:
            // Very long span (>25 years) - use abbreviated format with decade-based intervals
            if spacePerYear > 25 {
                return (5, true)
            } else {
                return (10, true) // Show decades only
            }
        }
    }
    
    
    @objc internal func selectTimeSource1() {
        currentPickerType = "timeSource1"
        showPickerForValueObjSelection(type: "timeSource1")
    }
    
    @objc internal func selectTimeSource2() {
        currentPickerType = "timeSource2"
        showPickerForValueObjSelection(type: "timeSource2")
    }
    
    @objc internal func selectTimeSource3() {
        currentPickerType = "timeSource3"
        showPickerForValueObjSelection(type: "timeSource3")
    }
    
    @objc internal func selectTimeSource4() {
        currentPickerType = "timeSource4"
        showPickerForValueObjSelection(type: "timeSource4")
    }
}
