//
//  trackerChartDataHandling.swift
//  rTracker
//
//  Created by Robert Miller on 31/03/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import UIKit

// MARK: - Data Handling Extensions
extension TrackerChart {
    
    
    internal func generateScatterPlotData() {
        guard tracker != nil,
              let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate,
              selectedValueObjIDs["xAxis"] != -1,
              selectedValueObjIDs["yAxis"] != -1 else {
            noDataLabel.text = "Please select X and Y axes"
            noDataLabel.isHidden = false
            return
        }
        
        // Get the selected value objects
        let xAxisID = selectedValueObjIDs["xAxis"]!
        let yAxisID = selectedValueObjIDs["yAxis"]!
        let colorID = selectedValueObjIDs["color"]!
        
        // Convert date range to Unix timestamps for SQL query
        let startTimestamp = Int(selectedStartDate.timeIntervalSince1970)
        let endTimestamp = Int(selectedEndDate.timeIntervalSince1970)
        
        // Query data points where both X and Y values exist for the same date
        let xData = fetchDataForValueObj(id: xAxisID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        let yData = fetchDataForValueObj(id: yAxisID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // If color is selected, fetch color data
        var colorData: [(Date, Double)] = []
        if colorID != -1 {
            colorData = fetchDataForValueObj(id: colorID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        }
        
        // Organize data by date
        var dataByDate: [Date: [String: Double]] = [:]
        
        // Process X data
        for (date, value) in xData {
            if dataByDate[date] == nil {
                dataByDate[date] = [:]
            }
            dataByDate[date]?["x"] = value
        }
        
        // Process Y data
        for (date, value) in yData {
            if dataByDate[date] == nil {
                dataByDate[date] = [:]
            }
            dataByDate[date]?["y"] = value
        }
        
        // Process color data if available
        if !colorData.isEmpty {
            for (date, value) in colorData {
                if dataByDate[date] != nil {
                    dataByDate[date]?["color"] = value
                }
            }
        }
        
        // Convert to array of points
        var points: [[String: Any]] = []
        var xValues: [Double] = []
        var yValues: [Double] = []
        
        for (date, values) in dataByDate {
            // Only include points with both X and Y values
            if let x = values["x"], let y = values["y"] {
                var point: [String: Any] = ["x": x, "y": y, "date": date]
                
                // Add color if available
                if let color = values["color"] {
                    point["color"] = color
                }
                
                points.append(point)
                xValues.append(x)
                yValues.append(y)
            }
        }
        
        // Calculate correlation if we have enough data points
        var correlation: Double? = nil
        if xValues.count > 1 {
            correlation = calculatePearsonCorrelation(x: xValues, y: yValues)
        }
        
        // Store the data for plotting
        chartData = [
            "type": "scatter",
            "points": points,
            "correlation": correlation as Any
        ]
        
        // Render the chart
        renderScatterPlot()
    }
    
    internal func generateDistributionPlotData() {
        guard tracker != nil,
              let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate,
              selectedValueObjIDs["background"] != -1 else {
            noDataLabel.text = "Please select background data"
            noDataLabel.isHidden = false
            return
        }
        
        // Get the selected value objects
        let backgroundID = selectedValueObjIDs["background"]!
        let selectionID = selectedValueObjIDs["selection"]!
        
        // Convert date range to Unix timestamps for SQL query
        let startTimestamp = Int(selectedStartDate.timeIntervalSince1970)
        let endTimestamp = Int(selectedEndDate.timeIntervalSince1970)
        
        // Fetch background data
        let backgroundData = fetchDataForValueObj(id: backgroundID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Check if we actually have data
        if backgroundData.isEmpty {
            noDataLabel.text = "No data found in the selected date range"
            noDataLabel.isHidden = false
            return
        }
        
        // Extract just the values for histogram
        let backgroundValues = backgroundData.map { $0.1 }
        
        // Get axis configuration or create it if it doesn't exist
        var backgroundConfig = axisConfig["background"] as? [String: Any] ?? [:]
        if backgroundConfig.isEmpty {
            // Calculate range with padding
            let minValue = backgroundValues.min() ?? 0
            let maxValue = backgroundValues.max() ?? 1
            let range = max(0.001, maxValue - minValue) * 1.05
            let paddedMinValue = minValue - range * 0.025
            let paddedMaxValue = maxValue + range * 0.025
            
            // Calculate number of bins based on data size
            let binCount = min(20, max(5, backgroundValues.count / 5))
            
            backgroundConfig = [
                "min": paddedMinValue,
                "max": paddedMaxValue,
                "binCount": binCount,
                "binWidth": (paddedMaxValue - paddedMinValue) / Double(max(1, binCount))
            ]
            axisConfig["background"] = backgroundConfig
        }
        
        // Extract configuration values
        let paddedMinValue = backgroundConfig["min"] as? Double ?? 0
        let paddedMaxValue = backgroundConfig["max"] as? Double ?? 100
        let binCount = backgroundConfig["binCount"] as? Int ?? 10
        let binWidth = backgroundConfig["binWidth"] as? Double ?? ((paddedMaxValue - paddedMinValue) / Double(binCount))
        
        // Initialize container for selection data
        var selectionData: [String: [Double]] = [:]
        
        // Reset legendItemVisibility when generating new data
        if !saveLegendItemVisibility {
            legendItemVisibility = [:]
        }
        
        // If selection is specified, fetch and organize by categories
        if selectionID != -1 {
            processSelectionData(
                selectionID: selectionID,
                startTimestamp: startTimestamp,
                endTimestamp: endTimestamp,
                backgroundData: backgroundData,
                selectionData: &selectionData
            )
        }
        
        // Store the data for plotting
        chartData = [
            "type": "distribution",
            "backgroundValues": backgroundValues,
            "selectionData": selectionData,
            "filteredSelectionData": selectionData, // Initialize filtered data with all data
            "binCount": binCount,
            "minValue": paddedMinValue,
            "maxValue": paddedMaxValue,
            "binWidth": binWidth
        ]
        
        // Initialize all legends as visible
        if !saveLegendItemVisibility {
            for category in selectionData.keys {
                legendItemVisibility[category] = true
            }
        }
        
        saveLegendItemVisibility = false  // one-shot use
        
        // Render the chart
        renderDistributionPlotWithFiltered()
    }
    
    // Extract the selection data processing into a separate method
    internal func processSelectionData(
        selectionID: Int,
        startTimestamp: Int,
        endTimestamp: Int,
        backgroundData: [(Date, Double)],
        selectionData: inout [String: [Double]]
    ) {
        guard let tracker = tracker else { return }
        
        // Find the value object to determine its type
        let selectionVO = tracker.valObjTable.first { $0.vid == selectionID }
        
        if let selectionVO = selectionVO {
            if selectionVO.vtype == VOT_BOOLEAN {
                processBooleanSelectionData(
                    selectionID: selectionID,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    backgroundData: backgroundData,
                    selectionData: &selectionData
                )
            } else if selectionVO.vtype == VOT_CHOICE {
                processChoiceSelectionData(
                    selectionID: selectionID,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    backgroundData: backgroundData,
                    selectionData: &selectionData
                )
            } else {
                processNumericSelectionData(
                    selectionID: selectionID,
                    startTimestamp: startTimestamp,
                    endTimestamp: endTimestamp,
                    backgroundData: backgroundData,
                    selectionData: &selectionData
                )
            }
        }
    }
    
    internal func processBooleanSelectionData(
        selectionID: Int,
        startTimestamp: Int,
        endTimestamp: Int,
        backgroundData: [(Date, Double)],
        selectionData: inout [String: [Double]]
    ) {
        // For boolean, we have true and false categories
        let booleanData = fetchDataForValueObj(id: selectionID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Create date lookup for boolean values
        var booleanByDate: [Date: Double] = [:]
        for (date, value) in booleanData {
            booleanByDate[date] = value
        }
        
        // Group background data by boolean value
        var trueValues: [Double] = []
        var falseValues: [Double] = []
        
        for (date, value) in backgroundData {
            if let boolValue = booleanByDate[date] {
                if boolValue >= 0.5 {
                    trueValues.append(value)
                } else {
                    falseValues.append(value)
                }
            } else {
                falseValues.append(value) // No entry counts as false
            }
        }
        
        selectionData["true"] = trueValues
        selectionData["false"] = falseValues
    }
    
    internal func processChoiceSelectionData(
        selectionID: Int,
        startTimestamp: Int,
        endTimestamp: Int,
        backgroundData: [(Date, Double)],
        selectionData: inout [String: [Double]]
    ) {
        // For choice, we need to handle multiple categories
        let choiceData = fetchDataForValueObj(id: selectionID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Create date lookup for choice values
        var choiceByDate: [Date: Double] = [:]
        for (date, value) in choiceData {
            choiceByDate[date] = value
        }
        
        // Get choice categories from voInfo
        let choiceCategories = fetchChoiceCategories(forID: selectionID)
        
        // Initialize arrays for each category
        var categoryValues: [String: [Double]] = [:]
        for (_, label) in choiceCategories {
            categoryValues[label] = []
        }
        categoryValues["no entry"] = [] // For no data
        
        // Group background data by choice value
        for (date, value) in backgroundData {
            if let choiceValue = choiceByDate[date] {
                let roundedValue = Int(round(choiceValue))
                
                // Find the matching category
                let category = findChoiceCategory(forValue: roundedValue, inCategories: choiceCategories) ?? "no entry" // "unknown"
                
                if categoryValues[category] != nil {
                    categoryValues[category]?.append(value)
                } else {
                    categoryValues[category] = [value]
                }
            } else {
                categoryValues["no entry"]?.append(value)
            }
        }
        
        // Copy only non-empty categories
        for (category, values) in categoryValues {
            if !values.isEmpty {
                selectionData[category] = values
            }
        }
    }
    
    internal func processNumericSelectionData(
        selectionID: Int,
        startTimestamp: Int,
        endTimestamp: Int,
        backgroundData: [(Date, Double)],
        selectionData: inout [String: [Double]]
    ) {
        // For numeric types, we create ranges or bins
        let numericData = fetchDataForValueObj(id: selectionID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Create date lookup for numeric values
        var numericByDate: [Date: Double] = [:]
        for (date, value) in numericData {
            numericByDate[date] = value
        }
        
        if !numericData.isEmpty {
            // Get unique values
            let uniqueValues = Array(Set(numericData.map { $0.1 })).sorted()
            
            var lowValues: [Double] = []
            var midValues: [Double] = []
            var highValues: [Double] = []
            var noEntryValues: [Double] = []
            
            // Handle cases based on number of unique values
            switch uniqueValues.count {
            case 0:
                // All values should be "no entry"
                for (_, bgValue) in backgroundData {
                    noEntryValues.append(bgValue)
                }
                
            case 1:
                // All values should be "medium"
                for (date, bgValue) in backgroundData {
                    if numericByDate[date] != nil {
                        midValues.append(bgValue)
                    } else {
                        noEntryValues.append(bgValue)
                    }
                }
                
            case 2:
                // Split into "low" and "high"
                for (date, bgValue) in backgroundData {
                    if let numValue = numericByDate[date] {
                        if numValue == uniqueValues[0] {
                            lowValues.append(bgValue)
                        } else {
                            highValues.append(bgValue)
                        }
                    } else {
                        noEntryValues.append(bgValue)
                    }
                }
                
            default:
                // Original quartile logic for 3 or more unique values
                let values = numericData.map { $0.1 }.sorted()
                let q1Index = values.count / 4
                let q3Index = (values.count * 3) / 4
                
                var q1 = values[q1Index]
                var q3 = values[q3Index]
                
                if (q1 == values[0] || q3 == values[values.count-1]) {
                    if (q1 == values[0]) {
                        q1 = values[findFirstGreaterThan(values, q3)]
                        q3 = q1 + (values[values.count-1] - q1)/2
                    } else if (q3 == values[values.count-1]) {
                        q3 = values[findLastLessThan(values, q1)]
                        q1 = (q3 - values[0])/2
                    }
                }
                
                for (date, bgValue) in backgroundData {
                    if let numValue = numericByDate[date] {
                        if numValue < q1 {
                            lowValues.append(bgValue)
                        } else if numValue > q3 {
                            highValues.append(bgValue)
                        } else {
                            midValues.append(bgValue)
                        }
                    } else {
                        noEntryValues.append(bgValue)
                    }
                }
            }
            
            // Assign the categorized values
            if !lowValues.isEmpty {
                selectionData["low"] = lowValues
            }
            if !midValues.isEmpty {
                selectionData["medium"] = midValues
            }
            if !highValues.isEmpty {
                selectionData["high"] = highValues
            }
            selectionData["no entry"] = noEntryValues
        }
    }
    
    internal func findChoiceCategory(forValue value: Int, inCategories categories: [Int: String]) -> String? {
        return categories[value]
    }
    
    
    internal func calculateSelectionBins(
        selectionData: [String: [Double]],
        binCount: Int,
        paddedMinValue: Double,
        binWidth: Double
    ) -> [String: [Double]] {
        var selectionBins: [String: [Double]] = [:]
        
        for (category, values) in selectionData {
            guard !values.isEmpty else { continue }
            
            var bins = Array(repeating: 0, count: binCount)
            for value in values {
                let binIndex = Int((value - paddedMinValue) / binWidth)
                if binIndex >= 0 && binIndex < binCount {
                    bins[binIndex] += 1
                }
            }
            
            // Normalize bins
            let totalCount = Double(values.count)
            selectionBins[category] = bins.map { Double($0) / totalCount }
        }
        
        return selectionBins
    }
    
    
    internal func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double {
        // Ensure arrays have the same length
        guard x.count == y.count, x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        
        // Calculate means
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        
        // Calculate correlation components
        var sumXY = 0.0
        var sumX2 = 0.0
        var sumY2 = 0.0
        
        for i in 0..<x.count {
            let xDiff = x[i] - meanX
            let yDiff = y[i] - meanY
            sumXY += xDiff * yDiff
            sumX2 += xDiff * xDiff
            sumY2 += yDiff * yDiff
        }
        
        // Calculate correlation coefficient
        if sumX2 == 0 || sumY2 == 0 {
            return 0
        }
        return sumXY / sqrt(sumX2 * sumY2)
    }
    
    // MARK: - Data Analysis and Chart Generation

    // Helper function to fetch actual data ranges from database
    func fetchDateRange() -> (earliest: Date?, latest: Date?) {
        guard let tracker = tracker else { return (nil, nil) }
        
        // SQL query to get min and max dates from trkrData
        let sql = "SELECT MIN(date), MAX(date) FROM trkrData WHERE minpriv <= \(privacyValue)"
        
        // Execute the query using tracker's query function
        if let results = tracker.toQry2IntInt(sql: sql) {
            
            // Get timestamps as seconds since 1970
            let minDate = Date(timeIntervalSince1970: TimeInterval(results.0))
            let maxDate = Date(timeIntervalSince1970: TimeInterval(results.1))
            return (minDate, maxDate)
        }
        
        return(nil,nil)
    }
    
    // Analyze scatter data to set axis scales (using full data range)
    internal func analyzeScatterData() {
        guard tracker != nil,
              let earliestDate = earliestDate,
              let latestDate = latestDate,
              selectedValueObjIDs["xAxis"] != -1,
              selectedValueObjIDs["yAxis"] != -1 else {
            return
        }
        
        // Get the selected value objects
        let xAxisID = selectedValueObjIDs["xAxis"]!
        let yAxisID = selectedValueObjIDs["yAxis"]!
        let colorID = selectedValueObjIDs["color"]!
        
        // Convert date range to Unix timestamps for SQL query
        let startTimestamp = Int(earliestDate.timeIntervalSince1970)
        let endTimestamp = Int(latestDate.timeIntervalSince1970)
        
        // Fetch full data range for axis scaling
        let xData = fetchDataForValueObj(id: xAxisID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        let yData = fetchDataForValueObj(id: yAxisID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Fetch color data if available
        var colorData: [(Date, Double)] = []
        if colorID != -1 {
            colorData = fetchDataForValueObj(id: colorID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        }
        
        // Calculate axis ranges
        let xValues = xData.map { $0.1 }
        let yValues = yData.map { $0.1 }
        let colorValues = colorData.map { $0.1 }
        
        if !xValues.isEmpty && !yValues.isEmpty {
            // Calculate X axis range with padding
            let minX = xValues.min() ?? 0
            let maxX = xValues.max() ?? 1
            let xRange = max(0.001, maxX - minX) * 1.1
            let paddedMinX = minX - xRange * 0.05
            let paddedMaxX = maxX + xRange * 0.05
            
            // Calculate Y axis range with padding
            let minY = yValues.min() ?? 0
            let maxY = yValues.max() ?? 1
            let yRange = max(0.001, maxY - minY) * 1.1
            let paddedMinY = minY - yRange * 0.05
            let paddedMaxY = maxY + yRange * 0.05
            
            // Store axis configuration for future use
            axisConfig["xAxis"] = ["min": paddedMinX, "max": paddedMaxX]
            axisConfig["yAxis"] = ["min": paddedMinY, "max": paddedMaxY]
            
            // Store color range if available
            if !colorValues.isEmpty {
                let minColor = colorValues.min() ?? 0
                let maxColor = colorValues.max() ?? 1
                axisConfig["colorAxis"] = ["min": minColor, "max": maxColor]
            }
        }
        
        // Now generate plot data with the current date range
        generateScatterPlotData()
    }
    
    // Analyze distribution data to set axis scales (using full data range)
    internal func analyzeDistributionData() {
        guard tracker != nil,
              let earliestDate = earliestDate,
              let latestDate = latestDate,
              selectedValueObjIDs["background"] != -1 else {
            return
        }
        
        // Get the selected value objects
        let backgroundID = selectedValueObjIDs["background"]!
        
        // Convert date range to Unix timestamps for SQL query
        let startTimestamp = Int(earliestDate.timeIntervalSince1970)
        let endTimestamp = Int(latestDate.timeIntervalSince1970)
        
        // Fetch full data range for background data
        let backgroundData = fetchDataForValueObj(id: backgroundID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        // Calculate background data range
        let backgroundValues = backgroundData.map { $0.1 }
        
        if !backgroundValues.isEmpty {
            // Calculate range with padding
            let minValue = backgroundValues.min() ?? 0
            let maxValue = backgroundValues.max() ?? 1
            let range = max(0.001, maxValue - minValue) * 1.05
            let paddedMinValue = minValue - range * 0.025
            let paddedMaxValue = maxValue + range * 0.025
            
            // Calculate number of bins based on data size
            let binCount = min(20, backgroundValues.count / 5)
            
            // Store axis configuration for future use
            axisConfig["background"] = [
                "min": paddedMinValue,
                "max": paddedMaxValue,
                "binCount": binCount > 0 ? binCount : 10,
                "binWidth": (paddedMaxValue - paddedMinValue) / Double(max(1, binCount))
            ]
        }
        
        // Now generate plot data with the current date range
        generateDistributionPlotData()
    }
    
    // Add new function to generate pie chart data
    func generatePieChartData() {
        guard let pieDataID = selectedValueObjIDs["pieData"],
              let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              let tracker = tracker else {
            return
        }
        
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        // Get total number of entries in date range
        let totalCountSQL = "SELECT COUNT(*) FROM trkrData WHERE date >= \(startTimestamp) AND date <= \(endTimestamp) AND minpriv <= \(privacyValue)"
        let totalPossibleEntries = tracker.toQry2Int(sql: totalCountSQL)
        
        // Fetch data for the selected value object
        let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
        
        var valueCounts: [String: Int] = [:]
        
        // Process the data based on the valueObj type
        if let valueObj = tracker.valObjTable.first(where: { $0.vid == pieDataID }) {
            switch valueObj.vtype {
            case VOT_BOOLEAN:
                // For boolean, we'll only have "True" and "False" (which includes no entry)
                valueCounts["True"] = 0
                valueCounts["False"] = 0
                
                for (_, value) in data {
                    let boolValue = value >= 0.5
                    let key = boolValue ? "True" : "False"
                    valueCounts[key]? += 1
                }
                
                // Add the remaining entries to "False" since they weren't marked as "True"
                let recordedEntries = valueCounts["True"]! + valueCounts["False"]!
                valueCounts["False"]! += totalPossibleEntries - recordedEntries
                
            case VOT_CHOICE:
                let categories = fetchChoiceCategories(forID: pieDataID)
                valueCounts["No Entry"] = 0
                
                // Initialize all categories to 0
                for (_, category) in categories {
                    valueCounts[category] = 0
                }
                
                for (_, value) in data {
                    let categoryNdx = valueObj.getChoiceIndex(forDouble: value)
                    if let category = valueObj.optDict["c\(categoryNdx)"] {
                        valueCounts[category]? += 1
                    } else {
                        DBGLog("no category for \(value)")
                        DBGLog("valueObj: \(valueObj)")
                    }
                }
                
                // Calculate no entries
                let totalEntries = valueCounts.values.reduce(0, +)
                valueCounts["No Entry"] = totalPossibleEntries - totalEntries
                
            default:
                break
            }
        }
        
        // Store the complete data
        chartData["pieData"] = valueCounts
        
        // Calculate total for percentages
        let total = valueCounts.values.reduce(0, +)
        var percentages: [String: Double] = [:]
        for (key, count) in valueCounts {
            percentages[key] = Double(count) / Double(total) * 100.0
        }
        chartData["piePercentages"] = percentages
        
        // Trigger chart update
        renderPieChart()
    }

    
    // Update getEligibleValueObjs to add a "None" option
    internal func getEligibleValueObjs(for configType: String) -> [valueObj] {
        guard let tracker = tracker else { return [] }
        
        // Create a dummy "None" value object using the proper initializer
         let noneVO = valueObj(
             data: tracker,
             in_vid: -2,            // Use -2 as a special ID for "None" (-1 is already used for unselected state)
             in_vtype: VOT_INFO,          // Use -1 as a special type for "None"
             in_vname: "None",      // Display name
             in_vcolor: 0,
             in_vgraphtype: 0,
             in_vpriv: 0
         )
        
        // Skip adding "None" for time chart sources that are already None
        // This check prevents adding multiple "None" entries when a source is already None
        if configType.hasPrefix("timeSource") {
            let sourceIndex = Int(configType.dropFirst("timeSource".count))! - 1
            if sourceIndex >= 0 && sourceIndex < timeChartSources.count && timeChartSources[sourceIndex] == -1 {
                // If this time source is already None, don't add the None option
            } else {
                // Add None option for time chart sources
                var results: [valueObj] = [noneVO]
                
                // Get allowed types for this configuration
                let allowedTypes = allowedValueObjTypes[configType] ?? []
                
                // Filter valueObjs based on type and privacy
                let eligibleVOs = tracker.valObjTable.filter { vo in
                    // Check if type is allowed
                    guard allowedTypes.contains(vo.vtype) else { return false }
                    
                    // Check privacy settings (if applicable)
                    let privacy = vo.optDict["privacy"] ?? "0"
                    return Int(privacy) ?? 0 <= privacyValue
                }
                
                // Further filter based on exclusions (for X and Y axes)
                let filtered: [valueObj]
                if configType == "xAxis" {
                    // Exclude Y axis selection from X options
                    filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["yAxis"] }
                } else if configType == "yAxis" {
                    // Exclude X axis selection from Y options
                    filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["xAxis"] }
                } else {
                    filtered = eligibleVOs
                }
                
                results.append(contentsOf: filtered)
                return results
            }
        } else if configType == "color" || configType == "selection" {
            // Add None option for these optional fields
            var results: [valueObj] = [noneVO]
            
            // Get allowed types for this configuration
            let allowedTypes = allowedValueObjTypes[configType] ?? []
            
            // Filter valueObjs based on type and privacy
            let eligibleVOs = tracker.valObjTable.filter { vo in
                // Check if type is allowed
                guard allowedTypes.contains(vo.vtype) else { return false }
                
                // Check privacy settings (if applicable)
                let privacy = vo.optDict["privacy"] ?? "0"
                return Int(privacy) ?? 0 <= privacyValue
            }
            
            // Further filter based on exclusions (for X and Y axes)
            let filtered: [valueObj]
            if configType == "xAxis" {
                // Exclude Y axis selection from X options
                filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["yAxis"] }
            } else if configType == "yAxis" {
                // Exclude X axis selection from Y options
                filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["xAxis"] }
            } else {
                filtered = eligibleVOs
            }
            
            results.append(contentsOf: filtered)
            return results
        }
        
        // For required fields, proceed with the original implementation
        // Get allowed types for this configuration
        let allowedTypes = allowedValueObjTypes[configType] ?? []
        
        // Filter valueObjs based on type and privacy
        let eligibleVOs = tracker.valObjTable.filter { vo in
            // Check if type is allowed
            guard allowedTypes.contains(vo.vtype) else { return false }
            
            // Check privacy settings (if applicable)
            let privacy = vo.optDict["privacy"] ?? "0"
            return Int(privacy) ?? 0 <= privacyValue
        }
        
        // Further filter based on exclusions (for X and Y axes)
        let filtered: [valueObj]
        if configType == "xAxis" {
            // Exclude Y axis selection from X options
            filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["yAxis"] }
        } else if configType == "yAxis" {
            // Exclude X axis selection from Y options
            filtered = eligibleVOs.filter { $0.vid != selectedValueObjIDs["xAxis"] }
        } else {
            filtered = eligibleVOs
        }
        
        return filtered
    }
    
    // MARK: - Data Fetching
    
    internal func fetchDataForValueObj(id: Int, startTimestamp: Int, endTimestamp: Int) -> [(Date, Double)] {
        // This would query the database for data points
        guard id != -1, let tracker = tracker else { return [] }
        
        let sql = """
        SELECT date, val FROM voData 
        WHERE id = \(id) AND date >= \(startTimestamp) AND date <= \(endTimestamp)
        ORDER BY date
        """
        
        return tracker.toQry2AryDate(sql: sql)
    }
    
    internal func fetchChoiceCategories(forID id: Int) -> [Int: String] {
        guard let tracker = tracker else { return [:] }
        
        // Check if there are custom values
        var sql = """
        SELECT field, val FROM voInfo 
        WHERE id = \(id) AND field LIKE 'cv%'
        """
        var customValues: [Int: Int] = [:]
        
        // Fetch custom values
        let customValuesResults = tracker.toQry2Ary(sql: sql)
        for result in customValuesResults {
            if let field = result.0 as? String, let valStr = result.1 as? String, let val = Int(valStr) {
                // Extract index from 'cv0', 'cv1', etc.
                if let indexStr = field.dropFirst(2).first, let ndx = Int(String(indexStr)) {
                    customValues[ndx] = val
                }
            }
        }
        
        // query the voInfo table for choice labels
        sql = """
        SELECT field, val FROM voInfo 
        WHERE id = \(id) AND field LIKE 'c%' AND val IS NOT NULL
        """
        
        var categories: [Int: String] = [:]
        
        // Fetch categories
        let categoryResults = tracker.toQry2Ary(sql: sql)
        for result in categoryResults {
            if let field = result.0 as? String, let label = result.1 as? String {
                // Extract index from 'c0', 'c1', etc.
                if let indexStr = field.dropFirst(1).first, let index = Int(String(indexStr)) {
                    // Check if there's a custom value for this field
                    if let customValue = customValues[index] {
                        categories[customValue] = label
                    } else {
                        // If no custom value, assign index + 1 (so c0=1, c1=2, etc.)
                        categories[index + 1] = label
                    }
                }
            }
        }
        
        return categories
    }
    
    // Helper method for data processing
    internal func findFirstGreaterThan(_ sortedArray: [Double], _ threshold: Double) -> Int {
        var low = 0
        var high = sortedArray.count - 1
        var result: Int? = nil
        
        while low <= high {
            let mid = (low + high) / 2
            if sortedArray[mid] > threshold {
                // This could be our answer, but let's check if there's a smaller one
                result = mid
                high = mid - 1
            } else {
                low = mid + 1
            }
        }
        
        return result ?? high
    }
    
    internal func findLastLessThan(_ array: [Double], _ threshold: Double) -> Int {
        var low = 0
        var high = array.count - 1
        var result: Int? = nil
        
        while low <= high {
            let mid = (low + high) / 2
            if array[mid] < threshold {
                // This could be our answer, but let's check if there's a larger one
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        
        return result ?? low
    }
}
