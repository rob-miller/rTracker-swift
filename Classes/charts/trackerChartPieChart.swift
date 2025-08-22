//
//  trackerChartPieChart.swift
//  rTracker
//
//  Created by Robert Miller on 23/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//


import UIKit

// MARK: - Pie Chart Extensions
extension TrackerChart {
    
    
    
    internal func setupPieChartConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for pie chart source selection
        pieSource1Button = createConfigButton(title: "Select Data Source 1", action: #selector(selectPieSource1))
        pieSource2Button = createConfigButton(title: "Select Data Source 2 (Optional)", action: #selector(selectPieSource2))
        pieSource3Button = createConfigButton(title: "Select Data Source 3 (Optional)", action: #selector(selectPieSource3))
        pieSource4Button = createConfigButton(title: "Select Data Source 4 (Optional)", action: #selector(selectPieSource4))
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            sliderContainer,
            pieSource1Button,
            pieSource2Button,
            pieSource3Button,
            pieSource4Button
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
        
        // Update button with any previously selected values
        updateButtonTitles()
    }
    
    
    // Add new function to generate pie chart data
    func generatePieChartData() {
        guard let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              let tracker = tracker,
              pieChartSources[0] != -1 else { // Source 1 is required
            return
        }
        
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        // Determine how many sources are selected
        let selectedSources = pieChartSources.filter { $0 != -1 }
        let isMultiSource = selectedSources.count > 1
        
        var valueCounts: [String: Int] = [:]
        
        if isMultiSource {
            // MULTI-SOURCE MODE: Show proportion of each source's total contribution
            DBGLog("=== Multi-Source Pie Chart Mode ===")
            
            // For each selected source, calculate its total contribution over the date range
            for sourceID in selectedSources {
                guard let valueObj = tracker.valObjTable.first(where: { $0.vid == sourceID }) else { continue }
                
                // Fetch data for this source
                let excludeEmpty = valueObj.vtype == VOT_CHOICE || valueObj.vtype == VOT_NUMBER || valueObj.vtype == VOT_FUNC
                let data = fetchDataForValueObj(id: sourceID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
                
                // Calculate total for this source based on its type
                var sourceTotal: Double = 0
                
                switch valueObj.vtype {
                case VOT_BOOLEAN:
                    // For boolean, count "true" values as 1, "false" as 0
                    sourceTotal = data.reduce(0) { total, entry in
                        total + (entry.1 >= 0.5 ? 1.0 : 0.0)
                    }
                    
                case VOT_CHOICE:
                    // For choice, count each entry as 1 (just count occurrences)
                    sourceTotal = Double(data.count)
                    
                case VOT_NUMBER, VOT_FUNC:
                    // For numeric, sum all values
                    sourceTotal = data.reduce(0) { total, entry in
                        total + entry.1
                    }
                    
                default:
                    sourceTotal = Double(data.count)
                }
                
                // Store the total for this source using the source name
                let sourceName = valueObj.valueName ?? "Unknown Source"
                valueCounts[sourceName] = Int(sourceTotal)
                
                DBGLog("Source \(sourceName): Total = \(sourceTotal)")
            }
            
        } else {
            // SINGLE-SOURCE MODE: Show detailed breakdown of values within the single source
            DBGLog("=== Single-Source Pie Chart Mode ===")
            
            let pieDataID = pieChartSources[0]
            guard let valueObj = tracker.valObjTable.first(where: { $0.vid == pieDataID }) else { return }
            
            // Get total number of entries in date range for "No Entry" calculation
            let totalCountSQL = "SELECT COUNT(*) FROM trkrData WHERE date >= \(startTimestamp) AND date <= \(endTimestamp) AND minpriv <= \(privacyValue)"
            let totalPossibleEntries = tracker.toQry2Int(sql: totalCountSQL)
            
            // Fetch data for the selected value object
            let excludeEmpty = valueObj.vtype == VOT_CHOICE || valueObj.vtype == VOT_NUMBER || valueObj.vtype == VOT_FUNC
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            
            // Process the data based on the valueObj type (original single-source logic)
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
                    }
                }
                
                // Before calculating "No Entry", remove any categories with zero counts
                let keysToRemove = valueCounts.keys.filter { key in
                    return key != "No Entry" && valueCounts[key] == 0
                }
                for key in keysToRemove {
                    valueCounts.removeValue(forKey: key)
                }
                
                // Remove empty string categories
                if let emptyCount = valueCounts[""] {
                    DBGLog("Removing empty string category with count: \(emptyCount)")
                    valueCounts.removeValue(forKey: "")
                }
                
                // Calculate no entries
                let totalEntries = valueCounts.values.reduce(0, +)
                valueCounts["No Entry"] = totalPossibleEntries - totalEntries
                
            case VOT_NUMBER, VOT_FUNC:
                // For numeric data, create bins based on data range
                if !data.isEmpty {
                    let values = data.map { $0.1 }
                    let minValue = values.min() ?? 0
                    let maxValue = values.max() ?? 0
                    
                    // Calculate range to determine decimal precision
                    let range = maxValue - minValue
                    let formatString = range > 99 ? "%.0f" : "%.2f"
                    let rangeFormatString = range > 99 ? "%.0f - %.0f" : "%.2f - %.2f"
                    
                    // If all values are the same, create a single category
                    if minValue == maxValue {
                        let valueStr = String(format: formatString, minValue)
                        valueCounts[valueStr] = values.count
                    } else {
                        // Determine optimal number of bins (between 2 and CHOICES)
                        let binCount = min(CHOICES, max(2, min(values.count / 2, 6)))
                        let binWidth = range / Double(binCount)
                        
                        // Initialize bins
                        var binCounts: [Int] = Array(repeating: 0, count: binCount)
                        var binLabels: [String] = []
                        
                        // Create bin labels
                        for i in 0..<binCount {
                            let binMin = minValue + Double(i) * binWidth
                            let binMax = minValue + Double(i + 1) * binWidth
                            binLabels.append(String(format: rangeFormatString, binMin, binMax))
                        }
                        
                        // Assign values to bins
                        for value in values {
                            var binIndex = Int((value - minValue) / binWidth)
                            // Handle the edge case where value equals maxValue
                            if binIndex >= binCount {
                                binIndex = binCount - 1
                            }
                            binCounts[binIndex] += 1
                        }
                        
                        // Store results
                        for i in 0..<binCount {
                            if binCounts[i] > 0 {  // Only include non-empty bins
                                valueCounts[binLabels[i]] = binCounts[i]
                            }
                        }
                    }
                }
                
                // Calculate "No Entry" for numeric data
                let recordedEntries = valueCounts.values.reduce(0, +)
                if totalPossibleEntries > recordedEntries {
                    valueCounts["No Entry"] = totalPossibleEntries - recordedEntries
                }
                
            default:
                break
            }
        }
        
        // Store the complete data
        chartData["pieData"] = valueCounts
        chartData["isMultiSource"] = isMultiSource
        
        // Calculate total for percentages
        let total = valueCounts.values.reduce(0, +)
        var percentages: [String: Double] = [:]
        for (key, count) in valueCounts {
            percentages[key] = Double(count) / Double(total) * 100.0
        }
        chartData["piePercentages"] = percentages
        
        // Determine which segment contains the most recent data entry (only for single source)
        if !isMultiSource {
            determineRecentDataSegment()
        } else {
            // Clear recent data segment for multi-source mode
            chartData["recentDataSegment"] = nil
        }
        
        // Trigger chart update
        renderPieChart()
    }

    // MARK: - Recent Data Detection
    
    // Determine which segment contains the most recent data entries
    internal func determineRecentDataSegment() {
        // Only work in single-source mode
        guard pieChartSources[0] != -1,
              pieChartSources.filter({ $0 != -1 }).count == 1,
              let startDate = selectedStartDate,
              let endDate = selectedEndDate,
              let tracker = tracker else {
            chartData["recentDataSegment"] = nil
            return
        }
        
        let pieDataID = pieChartSources[0]
        
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        // Get recent entries based on the indicator state
        var recentEntries: [(Date, Double)] = []
        let valueObj = tracker.valObjTable.first(where: { $0.vid == pieDataID })
        let excludeEmpty = valueObj?.vtype == VOT_CHOICE || valueObj?.vtype == VOT_NUMBER || valueObj?.vtype == VOT_FUNC
        
        switch recentDataIndicatorState {
        case 1: // Last entry
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            if let lastEntry = data.max(by: { $0.0 < $1.0 }) {
                recentEntries = [lastEntry]
            }
        case 2: // Minus 1 entry (second to last)
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            let sortedData = data.sorted { $0.0 > $1.0 } // Sort by date descending
            if sortedData.count >= 2 {
                recentEntries = [sortedData[1]] // Second entry (minus 1)
            }
        case 3: // Minus 2 entry (third to last)
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            let sortedData = data.sorted { $0.0 > $1.0 } // Sort by date descending
            if sortedData.count >= 3 {
                recentEntries = [sortedData[2]] // Third entry (minus 2)
            }
        case 4: // Minus 3 entry (fourth to last)
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            let sortedData = data.sorted { $0.0 > $1.0 } // Sort by date descending
            if sortedData.count >= 4 {
                recentEntries = [sortedData[3]] // Fourth entry (minus 3)
            }
        case 5: // Minus 4 entry (fifth to last)
            let data = fetchDataForValueObj(id: pieDataID, startTimestamp: startTimestamp, endTimestamp: endTimestamp, excludeEmptyValues: excludeEmpty)
            let sortedData = data.sorted { $0.0 > $1.0 } // Sort by date descending
            if sortedData.count >= 5 {
                recentEntries = [sortedData[4]] // Fifth entry (minus 4)
            }
        default: // Off
            chartData["recentDataSegment"] = nil
            return
        }
        
        // Determine which segment the recent entry belongs to
        if let recentEntry = recentEntries.first,
           let valueObj = valueObj {
            let recentValue = recentEntry.1
            var segmentKey: String?
            
            switch valueObj.vtype {
            case VOT_BOOLEAN:
                let boolValue = recentValue >= 0.5
                segmentKey = boolValue ? "True" : "False"
                
            case VOT_CHOICE:
                let categoryNdx = valueObj.getChoiceIndex(forDouble: recentValue)
                segmentKey = valueObj.optDict["c\(categoryNdx)"]
                
            case VOT_NUMBER, VOT_FUNC:
                // Find which bin this value falls into
                if let valueCounts = chartData["pieData"] as? [String: Int] {
                    for key in valueCounts.keys {
                        if key.contains("-") {
                            // Parse range "min - max"
                            let components = key.components(separatedBy: " - ")
                            if components.count == 2,
                               let minVal = Double(components[0]),
                               let maxVal = Double(components[1]) {
                                if recentValue >= minVal && recentValue <= maxVal {
                                    segmentKey = key
                                    break
                                }
                            }
                        } else if let singleVal = Double(key), singleVal == recentValue {
                            // Single value segment
                            segmentKey = key
                            break
                        }
                    }
                }
                
            default:
                break
            }
            
            chartData["recentDataSegment"] = segmentKey
        } else {
            chartData["recentDataSegment"] = nil
        }
    }
    
    // MARK: - Rendering Methods
    
   

    // Add this method to the TrackerChart extension in trackerChartPlots.swift
    @objc internal func toggleNoEntryInPieChart(_ sender: UITapGestureRecognizer) {
        // Only work in single-source mode
        let isMultiSource = chartData["isMultiSource"] as? Bool ?? false
        guard !isMultiSource else { return }
        
        // Check if we have a "No Entry" category to toggle
        if let valueCounts = chartData["pieData"] as? [String: Int],
           pieChartSources[0] != -1,
           let valueObj = tracker?.valObjTable.first(where: { $0.vid == pieChartSources[0] }) {
            
            // Boolean data doesn't separate "No Entry" from "False"
            if valueObj.vtype == VOT_BOOLEAN {
                // For boolean do nothing
                return
            }
            
            // Only toggle if there's a "No Entry" category
            if valueCounts["No Entry"] != nil {
                // Toggle the state
                showNoEntryInPieChart.toggle()
                
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // This is critical - remove any existing gesture recognizers from the previous view
                // before generating the new pie chart to avoid conflicts
                if let existingPieView = chartView.viewWithTag(2001) {
                    existingPieView.gestureRecognizers?.forEach { existingPieView.removeGestureRecognizer($0) }
                }
                
                // Regenerate the pie chart with the new setting
                renderPieChart()
            }
        }
    }
    
    // Modify the renderPieChart method to include tap gesture and apply the filter
    internal func renderPieChart() {
        // Clear existing subviews except noDataLabel
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard var valueCounts = chartData["pieData"] as? [String: Int],
              !valueCounts.isEmpty else {
            noDataLabel.isHidden = false
            return
        }
        
        DBGLog("=== Pie Chart Categories and Counts ===")
        for (key, count) in valueCounts {
            DBGLog("Category: \"\(key)\" - Count: \(count) - Percentage: \(Double(count) / Double(valueCounts.values.reduce(0, +)) * 100)%")
        }

        // log whether we're showing "No Entry" or not
        DBGLog("showNoEntryInPieChart: \(showNoEntryInPieChart)")
        
        // Get chart mode and handle data accordingly
        let isMultiSource = chartData["isMultiSource"] as? Bool ?? false
        
        // Get valueObj type for single-source mode (needed for "No Entry" filtering)
        let valueObj: valueObj?
        if !isMultiSource && pieChartSources[0] != -1 {
            valueObj = tracker?.valObjTable.first(where: { $0.vid == pieChartSources[0] })
        } else {
            valueObj = nil
        }
        
        // Check if we have a value object to determine if this is boolean data
        let isBooleanData = valueObj?.vtype == VOT_BOOLEAN
        
        // For boolean data, never filter out "No Entry" (it's already handled as part of "False")
        let hasNoEntry = valueCounts["No Entry"] != nil
        
        // Filter out "No Entry" if hidden and this is single-source mode with non-boolean data
        if !isMultiSource && !showNoEntryInPieChart && hasNoEntry && !isBooleanData {
            valueCounts.removeValue(forKey: "No Entry")
            
            DBGLog("=== After removing No Entry ===")
            for (key, count) in valueCounts {
                let recalculatedTotal = Double(valueCounts.values.reduce(0, +))
                let percentage = Double(count) / recalculatedTotal * 100
                DBGLog("Category: \"\(key)\" - Count: \(count) - Percentage: \(percentage)%")
            }
        }
        
        // Check if filtered data is empty
        if valueCounts.isEmpty {
            noDataLabel.text = "No data available"
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Calculate dimensions
        let padding: CGFloat = 20
        let size = min(chartView.bounds.width, chartView.bounds.height) - padding * 2
        let center = CGPoint(x: chartView.bounds.width / 2, y: chartView.bounds.height / 2)
        
        // Create pie chart view with tag to identify it
        let pieChartView = UIView(frame: CGRect(x: 0, y: 0, width: chartView.bounds.width, height: chartView.bounds.height))
        pieChartView.tag = 2001 // Use a specific tag to identify the pie chart view
        chartView.addSubview(pieChartView)
        
        // Track which specific corner positions are already used
        // Each corner has 2 positions: upper and lower (e.g., "top-left-upper", "top-left-lower")
        var usedCornerPositions: Set<String> = []
        let maxCornerLabels = 8 // 4 corners × 2 positions each
        
        // Add tap gesture to toggle "No Entry" visibility
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleNoEntryInPieChart(_:)))
        pieChartView.addGestureRecognizer(tapGesture)
        pieChartView.isUserInteractionEnabled = true
        
        // Calculate total for percentages
        let total = Double(valueCounts.values.reduce(0, +))
        
        var entries: [(key: String, value: Int, color: UIColor)] = []
        
        if isMultiSource {
            // MULTI-SOURCE MODE: Use consistent colors for source names
            let sortedKeys = Array(valueCounts.keys).sorted()
            let colors = generateConsistentColors(keys: sortedKeys)
            
            entries = sortedKeys.compactMap { key in
                if let count = valueCounts[key] {
                    return (key, count, colors[key] ?? .systemGray)
                }
                return nil
            }
        } else if let vo = valueObj {
            // SINGLE-SOURCE MODE: Use original color logic based on valueObj type
            switch vo.vtype {
            case VOT_BOOLEAN:
                // Fixed boolean colors - only True and False for boolean data
                let booleanColors: [String: UIColor] = [
                    "True": UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // Red
                    "False": UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)  // Blue
                ]
                
                // For boolean, we only have True and False (no separate "No Entry")
                let orderedKeys = ["True", "False"]
                entries = orderedKeys.compactMap { key in
                    if let count = valueCounts[key] {
                        return (key, count, booleanColors[key] ?? .systemGray)
                    }
                    return nil
                }
                
            case VOT_CHOICE:
                let colorSet = rTracker_resource.colorSet  // Use original colorSet for choice indices
                var choiceColors: [String: UIColor] = [:]
                
                // Get ordered keys from valueObj's optDict - ensuring consistent order
                var orderedKeys: [String] = []
                let categoryMap = fetchChoiceCategories(forID: vo.vid)
                
                // Get the categoryMap values in ascending order of keys
                let sortedCategories = categoryMap.sorted { $0.key < $1.key }
                for (_, category) in sortedCategories {
                    orderedKeys.append(category)
                }
                
                // Add "No Entry" at the end
                orderedKeys.append("No Entry")
                
                // Build color mapping from valueObj's optDict
                for i in 0..<CHOICES {
                    if let choiceName = vo.optDict["c\(i)"] {
                        let colorIndex = Int(vo.optDict["cc\(i)"] ?? "0") ?? 0
                        choiceColors[choiceName] = colorSet[colorIndex]
                    }
                }
                choiceColors["No Entry"] = .systemGray
                
                // Create entries in our defined order
                entries = orderedKeys.compactMap { key in
                    if let count = valueCounts[key] {
                        return (key, count, choiceColors[key] ?? .systemGray)
                    }
                    return nil
                }
                
            default:
                // Use consistent colors with consistent ordering
                let sortedKeys = Array(valueCounts.keys).sorted()
                let colors = generateConsistentColors(keys: sortedKeys)
                
                entries = sortedKeys.compactMap { key in
                    if let count = valueCounts[key] {
                        return (key, count, colors[key] ?? .systemGray)
                    }
                    return nil
                }
            }
        } else {
            // Fallback for cases where we don't have a valueObj
            let sortedKeys = Array(valueCounts.keys).sorted()
            let colors = generateConsistentColors(keys: sortedKeys)
            
            entries = sortedKeys.compactMap { key in
                if let count = valueCounts[key] {
                    return (key, count, colors[key] ?? .systemGray)
                }
                return nil
            }
        }
        
        // Filter out entries with zero or very small values (less than 0.1%)
        entries = entries.filter { entry in
            let (_, value, _) = entry
            return value > 0 && (Double(value) / total) > 0.001
        }
        
        // Draw segments - always start from top (-π/2) and go clockwise
        var currentAngle: CGFloat = -.pi / 2 // Start from top
        
        // Collect leader line data to draw after all segments
        var leaderLineData: [(path: UIBezierPath, color: UIColor)] = []
        
        // Collect outside label data to draw after leader lines
        var outsideLabelData: [(label: UILabel, point: CGPoint)] = []
        
        // Use a consistent starting point for each segment
        for (key, value, color) in entries {
            //let isFirstSegment = index == 0
            //let isLastSegment = index == entries.count - 1
            let percentage = Double(value) / total
            let segmentSize = CGFloat(percentage * 2 * .pi)
            let startAngle = currentAngle
            let endAngle = startAngle + segmentSize
            
            DBGLog("Drawing segment for: \"\(key)\" - Value: \(value) - Percentage: \(percentage * 100)%")
            DBGLog("  Angle range: \(startAngle) to \(endAngle) (size: \(segmentSize))")
            
            // Create segment path
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: size / 2, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            
            // Create segment layer
            let segmentLayer = CAShapeLayer()
            segmentLayer.path = path.cgPath
            segmentLayer.fillColor = color.cgColor
            segmentLayer.strokeColor = UIColor.white.cgColor
            segmentLayer.lineWidth = 1
            
            // Store the key name with the layer for potential interaction
            objc_setAssociatedObject(segmentLayer, AssociatedKeys.legendCategory, key, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            pieChartView.layer.addSublayer(segmentLayer)
            
            // Add label
            let labelAngle = startAngle + segmentSize/2 // Center of segment
            
            let label = UILabel()
            label.text = "\(key)\n\(Int(percentage * 100))%"
            label.numberOfLines = 2
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.sizeToFit()
            
            // Calculate arc width at the label radius to see if label fits
            let labelRadius = size / 2 * 0.7 // 70% of radius for inside positioning
            let arcWidthAtLabelRadius = labelRadius * segmentSize // Arc length = radius * angle
            let labelFitsInside = label.bounds.width <= arcWidthAtLabelRadius && segmentSize > 0.3 // Also check minimum angle
            
            // Check if this is a narrow vertical segment (avoiding top area where tabs are)
            let normalizedAngle = (labelAngle + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
            let isNarrowVerticalSegment = !labelFitsInside && segmentSize < 0.5 && (normalizedAngle > .pi * 0.2 && normalizedAngle < .pi * 1.8)
            let canUseCornerPosition = usedCornerPositions.count < maxCornerLabels
            
            let labelPoint: CGPoint
            
            if labelFitsInside {
                // Label fits inside - position at 70% of radius
                labelPoint = CGPoint(
                    x: center.x + cos(labelAngle) * labelRadius,
                    y: center.y + sin(labelAngle) * labelRadius
                )
                
                // Determine text color based on segment color for inside labels
                let brightness = color.getBrightness()
                label.textColor = brightness > 0.6 ? .black : .white
                
            } else if isNarrowVerticalSegment && canUseCornerPosition {
                // Place in corner of the square containing the pie circle
                let squareSize = size + 40 // Add padding around pie
                let halfSquare = squareSize / 2
                let edgeInset: CGFloat = 20 // Inset from square edges to keep labels fully inside
                
                // Determine preferred corners based on segment position
                let preferredCorners: [String]
                if normalizedAngle >= .pi * 1.5 && normalizedAngle < .pi * 2.0 {
                    // 12 to 3
                    preferredCorners = ["top-right", "bottom-right", "top-left", "bottom-left"]
                } else if normalizedAngle >= .pi * 0.0 && normalizedAngle < .pi * 0.5 {
                    // 3 to 6
                    preferredCorners = ["bottom-right", "top-right", "bottom-left", "top-left"]
                } else if normalizedAngle >= .pi * 0.5 && normalizedAngle < .pi * 1.0 {
                    // 6 to 9
                    preferredCorners = ["bottom-left", "top-left", "bottom-right", "top-right"]
                } else if normalizedAngle >= .pi * 1.0 && normalizedAngle < .pi * 1.5 {
                    // 9 to 12
                    preferredCorners = ["top-left", "top-right", "bottom-left", "bottom-right"]
                } else {
                    // Default to top-left if angle is unexpected
                    preferredCorners = ["top-left", "top-right", "bottom-left", "bottom-right"]
                }

                // Find first available position (try upper then lower for each corner)
                var selectedPosition = "top-left-upper" // fallback
                
                for corner in preferredCorners {
                    var preferUpper = true
                    if normalizedAngle >= .pi && normalizedAngle  <= .pi * 1.5 { // 9 to 12
                        if corner == "top-left" {
                            preferUpper = false
                        }
                    } else if normalizedAngle >= .pi * 0.5 && normalizedAngle < .pi { // 6 to 9
                        if corner == "bottom-left" {
                            preferUpper = false
                        }
                    }


                    if !preferUpper {
                        // For angles past 6 o'clock, prefer bottom corners first
                        let lowerPosition = "\(corner)-lower"
                        if !usedCornerPositions.contains(lowerPosition) {
                            selectedPosition = lowerPosition
                            usedCornerPositions.insert(lowerPosition)
                            break
                        }
                        
                        // Try upper position
                        let upperPosition = "\(corner)-upper"
                        if !usedCornerPositions.contains(upperPosition) {
                            selectedPosition = upperPosition
                            usedCornerPositions.insert(upperPosition)
                            break
                        }
                    } else {
                        // Try upper position first
                        let upperPosition = "\(corner)-upper"
                        if !usedCornerPositions.contains(upperPosition) {
                            selectedPosition = upperPosition
                            usedCornerPositions.insert(upperPosition)
                            break
                        }
                        
                        // Try lower position
                        let lowerPosition = "\(corner)-lower"
                        if !usedCornerPositions.contains(lowerPosition) {
                            selectedPosition = lowerPosition
                            usedCornerPositions.insert(lowerPosition)
                            break
                        }
                    }
                }
                
                // Convert position name to coordinates with edge insets and vertical spacing
                let verticalSpacing: CGFloat = 30 // Space between upper and lower positions
                let components = selectedPosition.components(separatedBy: "-")
                let cornerName = components.count >= 2 ? "\(components[0])-\(components[1])" : "top-left"
                let isUpper = components.last == "upper"
                
                let baseCorner: CGPoint
                switch cornerName {
                case "bottom-left":
                    baseCorner = CGPoint(x: center.x - halfSquare + edgeInset, y: center.y + halfSquare - edgeInset)
                case "bottom-right":
                    baseCorner = CGPoint(x: center.x + halfSquare - edgeInset, y: center.y + halfSquare - edgeInset)
                case "top-left":
                    baseCorner = CGPoint(x: center.x - halfSquare + edgeInset, y: center.y - halfSquare + edgeInset)
                case "top-right":
                    baseCorner = CGPoint(x: center.x + halfSquare - edgeInset, y: center.y - halfSquare + edgeInset)
                default:
                    baseCorner = CGPoint(x: center.x - halfSquare + edgeInset, y: center.y - halfSquare + edgeInset)
                }
                
                // Adjust vertical position for upper/lower
                let corner: CGPoint
                if cornerName == "top-left" {
                    // For top-left: upper is closer to corner later segments, lower is earlier segments
                    corner = CGPoint(x: baseCorner.x, y: baseCorner.y + (isUpper ? 0 : verticalSpacing))
                } else if cornerName == "bottom-left" {
                    // For bottom-left with segments past 6 o'clock: lower is closer to corner (earlier segments), upper is later segments
                    corner = CGPoint(x: baseCorner.x, y: baseCorner.y - (isUpper ? verticalSpacing : 0))
                } else if cornerName == "top-right" {
                    // For top right: upper is closer to corner, lower is further down
                    corner = CGPoint(x: baseCorner.x, y: baseCorner.y + (isUpper ?  0 : verticalSpacing))

                } else {
                    // For bottom right: upper is further up, lower is closer to corner
                    corner = CGPoint(x: baseCorner.x, y: baseCorner.y - (isUpper ? verticalSpacing : 0))
                }
                
                labelPoint = corner
                
                // Style for corner labels
                label.textColor = .black
                label.backgroundColor = UIColor.white.withAlphaComponent(0.9)
                label.layer.cornerRadius = 4
                label.layer.masksToBounds = true
                label.layer.borderWidth = 1
                label.layer.borderColor = UIColor.lightGray.cgColor
                
                // Determine if we need a direct line (when segment and corner are on opposite visual sides)
                // iOS coordinate system has Y increasing downward, so visual layout flipped from angle math
                // Visual top half: 9 o'clock to 3 o'clock -> angles: π to 2π 

                //let normalizedLabelAngle = (labelAngle + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
                //let segmentInVisualTopHalf = normalizedLabelAngle > 3 * .pi/2 || normalizedLabelAngle < .pi/2
                let segmentInVisualTopHalf = normalizedAngle > .pi && normalizedAngle < 2 * .pi  
                let cornerInVisualTopHalf = cornerName.hasPrefix("top")
                let mustCrossPie = segmentInVisualTopHalf != cornerInVisualTopHalf
                
                let leaderPath = UIBezierPath()
                
                if mustCrossPie {
                    // Direct line from segment center to corner when crossing pie
                    let segmentCenterPoint = CGPoint(
                        x: center.x + cos(labelAngle) * (size / 4), // Start from quarter radius
                        y: center.y + sin(labelAngle) * (size / 4)
                    )
                    leaderPath.move(to: segmentCenterPoint)
                    leaderPath.addLine(to: corner)
                } else {
                    // L-shaped line when segment and corner are on same side
                    let segmentEdgePoint = CGPoint(
                        x: center.x + cos(labelAngle) * (size / 2),
                        y: center.y + sin(labelAngle) * (size / 2)
                    )
                    
                    // Extend radially outward - shorter for inner labels to avoid crossing
                    let radialExtension: CGFloat
                    if cornerName.hasPrefix("top") {
                        // For top corners: lower label uses shorter extension to avoid upper label line
                        radialExtension = isUpper ? 15 : 8
                    } else {
                        // For bottom corners: upper label uses shorter extension to avoid lower label line
                        radialExtension = isUpper ? 8 : 15
                    }
                    let bendPoint = CGPoint(
                        x: segmentEdgePoint.x + cos(labelAngle) * radialExtension,
                        y: segmentEdgePoint.y + sin(labelAngle) * radialExtension
                    )
                    
                    // Create L-shaped path: segment edge → bend point → corner
                    leaderPath.move(to: segmentEdgePoint)
                    leaderPath.addLine(to: bendPoint)
                    leaderPath.addLine(to: corner)
                }
                
                // Store leader line data for later drawing
                leaderLineData.append((path: leaderPath, color: UIColor.darkGray))
                
            } else {
                // For other cases, use the original radial positioning but closer to pie
                labelPoint = CGPoint(
                    x: center.x + cos(labelAngle) * (size / 2 * 1.1),
                    y: center.y + sin(labelAngle) * (size / 2 * 1.1)
                )
                
                // Determine text color based on segment color
                let brightness = color.getBrightness()
                label.textColor = brightness > 0.6 ? .black : .white
            }
            
            // Center label around calculated point
            label.frame = CGRect(
                x: labelPoint.x - label.bounds.width / 2,
                y: labelPoint.y - label.bounds.height / 2,
                width: label.bounds.width,
                height: label.bounds.height
            )
            
            // Add inside labels immediately, collect outside labels for later
            if labelFitsInside {
                pieChartView.addSubview(label)
            } else {
                outsideLabelData.append((label: label, point: labelPoint))
            }
            
            // Move to next segment position
            currentAngle += segmentSize
        }
        
        // Draw all leader lines after segments to ensure they appear on top
        for leaderData in leaderLineData {
            let leaderLayer = CAShapeLayer()
            leaderLayer.path = leaderData.path.cgPath
            leaderLayer.strokeColor = leaderData.color.cgColor
            leaderLayer.fillColor = UIColor.clear.cgColor
            leaderLayer.lineWidth = 1
            leaderLayer.lineCap = .round
            leaderLayer.lineDashPattern = [3, 2] // Dashed line
            
            pieChartView.layer.addSublayer(leaderLayer)
        }
        
        // Draw all outside labels after leader lines to ensure correct z-order
        for labelData in outsideLabelData {
            pieChartView.addSubview(labelData.label)
        }
        
        // Draw recent data indicator line if needed (only in single-source mode)
        if !isMultiSource && recentDataIndicatorState > 0,
           let recentSegmentKey = chartData["recentDataSegment"] as? String {
            drawRecentDataIndicatorLine(in: pieChartView, center: center, radius: size / 2, for: recentSegmentKey, entries: entries, filteredValueCounts: valueCounts)
        }
    }
    
    // Draw recent data indicator line in the center of the specified segment
    private func drawRecentDataIndicatorLine(in pieChartView: UIView, center: CGPoint, radius: CGFloat, for segmentKey: String, entries: [(key: String, value: Int, color: UIColor)], filteredValueCounts: [String: Int]) {
        // Calculate the angle for the target segment using the same filtered data that's actually rendered
        let total = Double(filteredValueCounts.values.reduce(0, +))
        var currentAngle: CGFloat = -.pi / 2 // Start from top
        
        for (key, value, segmentColor) in entries {
            let percentage = Double(value) / total
            let segmentSize = CGFloat(percentage * 2 * .pi)
            
            if key == segmentKey {
                // Found the target segment - draw line in its center
                let centerAngle = currentAngle + segmentSize / 2
                
                // Calculate line endpoints - from center to edge of segment
                let startPoint = center // Start from center of pie
                let endPoint = CGPoint(
                    x: center.x + cos(centerAngle) * (radius * 0.95), // End at 95% of radius
                    y: center.y + sin(centerAngle) * (radius * 0.95)
                )
                
                // Create the line view
                let lineView = UIView()
                lineView.frame = CGRect(x: 0, y: 0, width: 2, height: sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2)))
                lineView.center = CGPoint(
                    x: (startPoint.x + endPoint.x) / 2,
                    y: (startPoint.y + endPoint.y) / 2
                )
                
                // Determine line color based on indicator state, but check for conflicts with segment color
                var lineColor: UIColor
                switch recentDataIndicatorState {
                case 1:
                    lineColor = rTracker_resource.colorSpectrum[0] // red
                case 2:
                    lineColor = rTracker_resource.colorSpectrum[1] // green
                case 3:
                    lineColor = rTracker_resource.colorSpectrum[2] // blue
                case 4:
                    lineColor = rTracker_resource.colorSpectrum[3] // cyan
                case 5:
                    lineColor = rTracker_resource.colorSpectrum[4] // yellow
                default:
                    lineColor = .black
                }
                
                // Check if line color conflicts with segment color - if so, use black for contrast
                if lineColor.isEqual(segmentColor) {
                    lineColor = .black
                }
                
                lineView.backgroundColor = lineColor
                
                // Rotate the line to match the angle
                lineView.transform = CGAffineTransform(rotationAngle: centerAngle + .pi / 2)
                
                // Add the line to the pie chart view
                pieChartView.addSubview(lineView)
                break
            }
            
            currentAngle += segmentSize
        }
    }
    
    
     private func generateConsistentColors(keys: [String]) -> [String: UIColor] {
         var colorMap: [String: UIColor] = [:]
         
         // Handle "No Entry" separately
         let regularKeys = keys.filter { $0 != "No Entry" }
         
         // Use colorSet sequence for consistent colors
         let colorSet = rTracker_resource.colorSpectrum
         for (index, key) in regularKeys.enumerated() {
             let colorIndex = index % colorSet.count
             colorMap[key] = colorSet[colorIndex]
         }
         
         // Always use gray for "No Entry"
         if keys.contains("No Entry") {
             colorMap["No Entry"] = .systemGray
         }
         
         return colorMap
     }
    
    private func generatePieChartColors(count: Int) -> [UIColor] {
        guard let pieDataID = selectedValueObjIDs["pieData"],
              let valueObj = tracker?.valObjTable.first(where: { $0.vid == pieDataID }) else {
            return []
        }
        
        switch valueObj.vtype {
        case VOT_BOOLEAN:
            return []  // Handled in renderPieChart
            
        case VOT_CHOICE:
            var choiceColors: [String: UIColor] = [:]
            let colorSet = rTracker_resource.colorSet  // Use original colorSet for choice indices
            
            // Build mapping of choice names to their assigned colors
            for i in 0..<CHOICES {
                // Get choice name from 'c{i}'
                if let choiceName = valueObj.optDict["c\(i)"] {
                    // Get color index from 'cc{i}'
                    let colorIndex = Int(valueObj.optDict["cc\(i)"] ?? "0") ?? 0
                    choiceColors[choiceName] = colorSet[colorIndex]
                }
            }
            choiceColors["No Entry"] = .systemGray
            
            // Return empty array - we'll use the mapping in renderPieChart
            return []
            
        default:
            // Use colorSet sequence for other types
            var colors: [UIColor] = []
            let colorSet = rTracker_resource.colorSpectrum
            for i in 0..<count {
                let colorIndex = i % colorSet.count
                colors.append(colorSet[colorIndex])
            }
            return colors
        }
    }
}


extension UIColor {
    func getBrightness() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Using perceived brightness formula
        return ((red * 299) + (green * 587) + (blue * 114)) / 1000
    }
}
