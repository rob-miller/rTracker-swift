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
        
        // Create button for data selection
        pieDataButton = createConfigButton(title: "Select Data", action: #selector(selectPieData))
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            sliderContainer,
            pieDataButton
            
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

    // MARK: - Rendering Methods
    
   

    // Add this method to the TrackerChart extension in trackerChartPlots.swift
    @objc internal func toggleNoEntryInPieChart(_ sender: UITapGestureRecognizer) {
        // Check if we have a "No Entry" category to toggle
        if let valueCounts = chartData["pieData"] as? [String: Int],
           let valueObj = selectedValueObjIDs["pieData"].flatMap({ id in
               tracker?.valObjTable.first(where: { $0.vid == id })
           }) {
            
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
        
        // Get valueObj type and prepare colors
        let valueObj = selectedValueObjIDs["pieData"].flatMap { pieDataID in
            tracker?.valObjTable.first(where: { $0.vid == pieDataID })
        }
        
        // Check if we have a value object to determine if this is boolean data
        let isBooleanData = valueObj?.vtype == VOT_BOOLEAN
        
        // For boolean data, never filter out "No Entry" (it's already handled as part of "False")
        let hasNoEntry = valueCounts["No Entry"] != nil
        
        // Filter out "No Entry" if hidden and this is not boolean data
        if !showNoEntryInPieChart && hasNoEntry && !isBooleanData {
            valueCounts.removeValue(forKey: "No Entry")
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
        
        // Add tap gesture to toggle "No Entry" visibility
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleNoEntryInPieChart(_:)))
        pieChartView.addGestureRecognizer(tapGesture)
        pieChartView.isUserInteractionEnabled = true
        
        // Calculate total for percentages
        let total = Double(valueCounts.values.reduce(0, +))
        
        var entries: [(key: String, value: Int, color: UIColor)] = []
        
        if let vo = valueObj {
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
                let colorSet = rTracker_resource.colorSet()
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
        }
        
        // Draw segments - always start from top (-π/2) and go clockwise
        var currentAngle: CGFloat = -.pi / 2 // Start from top
        
        // Use a consistent starting point for each segment
        for (key, value, color) in entries {
            let percentage = Double(value) / total
            let segmentSize = CGFloat(percentage * 2 * .pi)
            let startAngle = currentAngle
            let endAngle = startAngle + segmentSize
            
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
            let labelRadius = size / 2 * 0.7 // Position label at 70% of radius
            let labelPoint = CGPoint(
                x: center.x + cos(labelAngle) * labelRadius,
                y: center.y + sin(labelAngle) * labelRadius
            )
            
            let label = UILabel()
            label.text = "\(key)\n\(Int(percentage * 100))%"
            label.numberOfLines = 2
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.sizeToFit()
            
            // Determine if we should use dark or light text based on segment color
            let brightness = color.getBrightness()
            label.textColor = brightness > 0.6 ? .black : .white
            
            // Center label around calculated point
            label.frame = CGRect(
                x: labelPoint.x - label.bounds.width / 2,
                y: labelPoint.y - label.bounds.height / 2,
                width: label.bounds.width,
                height: label.bounds.height
            )
            
            pieChartView.addSubview(label)
            
            // Move to next segment position
            currentAngle += segmentSize
        }
    }
    
    
     private func generateConsistentColors(keys: [String]) -> [String: UIColor] {
         var colorMap: [String: UIColor] = [:]
         
         // Handle "No Entry" separately
         let regularKeys = keys.filter { $0 != "No Entry" }
         
         // Assign consistent colors based on hash of key
         for (index, key) in regularKeys.enumerated() {
             // Use both key and its position for consistency
             var hasher = Hasher()
             hasher.combine(key)
             hasher.combine(index)
             let hash = hasher.finalize()
             
             // Use hash to generate a consistent hue
             let hueValue = abs(CGFloat(hash % 100) / 100.0)
             colorMap[key] = UIColor(hue: hueValue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
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
            let colorSet = rTracker_resource.colorSet()
            
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
            // Original color generation for other types
            var colors: [UIColor] = []
            for i in 0..<count {
                let hue = CGFloat(i) / CGFloat(count)
                let color = UIColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
                colors.append(color)
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
