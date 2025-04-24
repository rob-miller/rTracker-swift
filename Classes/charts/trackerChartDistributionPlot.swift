//
//  trackerChartDistributionPlot.swift
//  rTracker
//
//  Created by Robert Miller on 23/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import UIKit

// MARK: - distribution plot implementation
extension TrackerChart {
    
    // Update setupDistributionPlotConfig to indicate Selection is optional
    internal func setupDistributionPlotConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for Background and Selection
        backgroundButton = createConfigButton(title: "Select Background Data", action: #selector(selectBackground))
        selectionButton = createConfigButton(title: "Select Segmentation Data (Optional)", action: #selector(selectSelection))
        
        // Configure layout - no longer using fillEqually distribution
        let stackView = UIStackView(arrangedSubviews: [
            sliderContainer,
            backgroundButton, selectionButton
            
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill  // Changed from fillEqually to fill
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
    
    @objc internal func selectBackground() {
        showPickerForValueObjSelection(type: "background")
    }
    
    @objc internal func selectSelection() {
        showPickerForValueObjSelection(type: "selection")
    }
    
    
    // MARK: - Updated drawDistributionAverages Method

    internal func drawDistributionAverages(
        backgroundValues: [Double],
        selectionData: [String: [Double]],
        categoryColors: [String: UIColor],
        orderedCategories: [String]
    ) {
        // remove previous average labels
        chartView.viewWithTag(3004)?.removeFromSuperview()
        let container = UIView(frame: chartView.bounds)
        container.tag = 3004
        chartView.addSubview(container)
        
        var yPos: CGFloat = 15
        let leftXPos: CGFloat = leftMargin + 10
        let rightXPos: CGFloat = chartView.bounds.width - rightMargin - 100 // Adjust width as needed
        let lineHeight: CGFloat = 16
        
        // Use the current display mode (average or count)
        let showCounts = showStatCounts
        
        // Get selection valueObj name
        let selectionVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["selection"] }
        
        // Add valueObj name at the top
        if let selectionName = selectionVO?.valueName {
            let titleLbl = UILabel(frame: CGRect(x: leftXPos, y: yPos, width: 220, height: lineHeight))
            titleLbl.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            titleLbl.textColor = .label
            titleLbl.text = selectionName
            
            // Make label tappable
            titleLbl.isUserInteractionEnabled = true
            titleLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleStatDisplayMode)))
            
            container.addSubview(titleLbl)
            yPos += lineHeight
        }
        
        // Background average (moved to right side)
        if !backgroundValues.isEmpty {
            let avg = backgroundValues.reduce(0.0, +) / Double(backgroundValues.count)
            let count = backgroundValues.count
            
            let bgLbl = UILabel(frame: CGRect(x: rightXPos, y: 15, width: 100, height: lineHeight))
            bgLbl.font = UIFont.systemFont(ofSize: 12)
            bgLbl.textColor = .label
            
            if showCounts {
                bgLbl.text = String(format: "Count: %d", count)
            } else {
                bgLbl.text = String(format: "Avg: %.2f", avg)
            }
            
            // Make label tappable
            bgLbl.isUserInteractionEnabled = true
            bgLbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleStatDisplayMode)))
            
            container.addSubview(bgLbl)
        }
        
        // Follow legend order for segmentation classes
        for category in orderedCategories {
            guard let values = selectionData[category], !values.isEmpty else { continue }
            
            let avg = values.reduce(0.0, +) / Double(values.count)
            let count = values.count
            
            let lbl = UILabel(frame: CGRect(x: leftXPos, y: yPos, width: 220, height: lineHeight))
            lbl.font = UIFont.systemFont(ofSize: 12)
            let visible = legendItemVisibility[category] ?? true
            let baseColor = categoryColors[category] ?? UIColor.label
            lbl.textColor = visible ? baseColor : baseColor.withAlphaComponent(0.3)
            
            if showCounts {
                lbl.text = String(format: "%@: %d", category, count)
            } else {
                lbl.text = String(format: "%@: %.2f", category, avg)
            }
            
            // Make label tappable
            lbl.isUserInteractionEnabled = true
            lbl.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleStatDisplayMode)))
            
            container.addSubview(lbl)
            yPos += lineHeight
        }
    }

    // Toggle between showing averages and counts
    @objc internal func toggleStatDisplayMode(_ sender: UITapGestureRecognizer) {
        // Add haptic feedback for better user experience
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Toggle the display mode
        showStatCounts.toggle()
        
        // Refresh the view with the new display mode
        if segmentedControl.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION {
            if let filteredSelData = chartData["filteredSelectionData"] as? [String: [Double]],
               let backgroundValues = chartData["backgroundValues"] as? [Double],
               let originalSelectionData = chartData["selectionData"] as? [String: [Double]] {
                
                let categoryData = generateCategoryColors(originalSelectionData.keys)
                let categoryColors = categoryData.colors
                let categoryValues = categoryData.values
                
                // Sort categories by their values
                let sortedCategories = Array(originalSelectionData.keys).sorted { (a, b) -> Bool in
                    return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
                }
                
                // Update the display
                drawDistributionAverages(
                    backgroundValues: backgroundValues,
                    selectionData: filteredSelData,
                    categoryColors: categoryColors,
                    orderedCategories: sortedCategories
                )
            }
        }
    }
    
    
    internal func drawCategoryLegend(
        in view: UIView,
        categories: [String],
        colors: [String: UIColor]
    ) {
        // Either update existing legend or create a new one
        let existingLegendView = view.viewWithTag(TAG_LEGEND_VIEW)
        
        // If legend already exists, update it rather than recreating
        if let legendView = existingLegendView {
            updateExistingLegend(legendView: legendView, categories: categories, colors: colors)
            return
        }
        
        // Create new legend if it doesn't exist
        createNewLegend(in: view, categories: categories, colors: colors)
    }

    // 3. Create a new method for updating existing legend
    internal func updateExistingLegend(
        legendView: UIView,
        categories: [String],
        colors: [String: UIColor]
    ) {
        // For each category, find its container in the legend and update appearance
        for (index, category) in categories.enumerated() {
            // Look for item container with the stored category
            for itemView in legendView.subviews {
                if let storedCategory = objc_getAssociatedObject(itemView, AssociatedKeys.legendCategory) as? String,
                   storedCategory == category {
                    // Found the matching container - update its appearance
                    let isVisible = legendItemVisibility[category] ?? true
                    
                    // Find and update the color indicator
                    if let colorView = itemView.subviews.first(where: { $0.frame.origin.x == 10 }) {
                        let baseColor = colors[category] ?? .black
                        if isVisible {
                            colorView.backgroundColor = baseColor
                            colorView.alpha = 1.0
                        } else {
                            colorView.backgroundColor = baseColor.withAlphaComponent(0.3)
                            colorView.alpha = 0.4
                        }
                    }
                    
                    // Find and update the label
                    if let label = itemView.subviews.first(where: { $0 is UILabel }) as? UILabel {
                        // Create attributed string with strikethrough if disabled
                        let attributedText: NSAttributedString
                        if isVisible {
                            attributedText = NSAttributedString(string: category)
                            label.textColor = .label
                            label.alpha = 1.0
                        } else {
                            // Add strikethrough for disabled items
                            let attributes: [NSAttributedString.Key: Any] = [
                                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                                .strikethroughColor: UIColor.systemGray,
                                .foregroundColor: UIColor.systemGray
                            ]
                            attributedText = NSAttributedString(string: category, attributes: attributes)
                            label.alpha = 0.5
                        }
                        
                        label.attributedText = attributedText
                    }
                    
                    // Update item position if needed
                    let yPosition = CGFloat(index) * (15 + 5) // itemHeight + padding
                    itemView.frame.origin.y = yPosition
                    
                    // Found and updated this category, move to next
                    break
                }
            }
        }
    }

    // 4. Move new legend creation to a separate method
    internal func createNewLegend(
        in view: UIView,
        categories: [String],
        colors: [String: UIColor]
    ) {
        let itemHeight: CGFloat = 15
        let padding: CGFloat = 5
        
        let legendHeight: CGFloat = CGFloat(categories.count) * (itemHeight + padding)
        
        let legendView = UIView(frame: CGRect(
            x: view.bounds.width - legendWidth - legendRightMargin,
            y: legendTopMargin + 10,
            width: legendWidth,
            height: legendHeight
        ))
        legendView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        legendView.layer.cornerRadius = 5
        legendView.layer.borderWidth = 0.5
        legendView.layer.borderColor = UIColor.systemGray.cgColor
        legendView.tag = TAG_LEGEND_VIEW
        legendView.isUserInteractionEnabled = true // Ensure legend view can receive touches
        //legendView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.addSubview(legendView)
        view.bringSubviewToFront(legendView)
        
        // Iterate through categories in their original order
        for (index, category) in categories.enumerated() {
            // Create container for each legend item to handle tap events
            let itemContainer = UIView(frame: CGRect(
                x: 0,
                y: CGFloat(index) * (itemHeight + padding),
                width: legendWidth,
                height: itemHeight + padding
            ))
            itemContainer.isUserInteractionEnabled = true
            /*
            itemContainer.backgroundColor = UIColor.red.withAlphaComponent(0.1)
            itemContainer.layer.borderWidth = 0.5  // Add border to see tap area
            itemContainer.layer.borderColor = UIColor.systemGray4.cgColor
             */
            legendView.addSubview(itemContainer)
            
            // Check visibility state
            let isVisible = legendItemVisibility[category] ?? true
            
            // Color indicator
            let colorView = UIView(frame: CGRect(
                x: 10,
                y: padding,
                width: 10,
                height: 10
            ))
            
            // If item is hidden, use a much lighter color and add strikethrough
            if isVisible {
                colorView.backgroundColor = colors[category] ?? .black
                colorView.alpha = 1.0
            } else {
                colorView.backgroundColor = (colors[category] ?? .black).withAlphaComponent(0.3)
                colorView.alpha = 0.4
            }
            
            colorView.layer.cornerRadius = 5
            itemContainer.addSubview(colorView)
            
            // Label
            let label = UILabel(frame: CGRect(
                x: 30,
                y: 0,
                width: legendWidth - 40,
                height: itemHeight
            ))
            
            // Create attributed string with strikethrough if disabled
            let attributedText: NSAttributedString
            if isVisible {
                attributedText = NSAttributedString(string: category)
                label.textColor = .label
                label.alpha = 1.0
            } else {
                // Add strikethrough for disabled items
                let attributes: [NSAttributedString.Key: Any] = [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.systemGray,
                    .foregroundColor: UIColor.systemGray
                ]
                attributedText = NSAttributedString(string: category, attributes: attributes)
                label.alpha = 0.5
            }
            
            label.attributedText = attributedText
            label.font = UIFont.systemFont(ofSize: 10)
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.7
            
            itemContainer.addSubview(label)
            
            // Add tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(legendItemTapped(_:)))
            itemContainer.addGestureRecognizer(tapGesture)
            
            // Store the category name using the ObjectAssociation pattern
            objc_setAssociatedObject(itemContainer, AssociatedKeys.legendCategory, category, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // Add title
        let selectionVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["selection"] }
        let titleLabel = UILabel(frame: CGRect(
            x: legendView.frame.minX,
            y: legendView.frame.minY - 20,
            width: legendWidth,
            height: 15
        ))
        titleLabel.text = selectionVO?.valueName ?? "Categories"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 10)
        titleLabel.tag = TAG_LEGEND_TITLE
        view.addSubview(titleLabel)
    }
    
    // Handle tap events on legend items
    @objc internal func legendItemTapped(_ sender: UITapGestureRecognizer) {
        DBGLog("Legend item tapped")
        
        guard let itemView = sender.view,
              let category = objc_getAssociatedObject(itemView, AssociatedKeys.legendCategory) as? String else {
            DBGLog("Failed to get category from tapped item")
            return
        }
        
        DBGLog("Tapped category: \(category)")
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Animate the tap with a quick scale effect
        UIView.animate(withDuration: 0.1, animations: {
            itemView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                itemView.transform = CGAffineTransform.identity
            }
        }
        
        // Toggle visibility state
        let currentVisibility = self.legendItemVisibility[category] ?? true
        self.legendItemVisibility[category] = !currentVisibility
        
        DBGLog("Toggled visibility for \(category) to \(!currentVisibility)")
        
        // Update the distribution plot
        self.updateDistributionPlotWithVisibility()
    }
    
    
     internal func generateCategoryColors(_ categories: Dictionary<String, [Double]>.Keys) -> (colors: [String: UIColor], values: [String: Int]) {
         var categoryColors: [String: UIColor] = [:]
         var categoryValues: [String: Int] = [:]
         
         // Check if this is a VOT_CHOICE selection and fetch categories once
         var choiceLabelToValue: [String: Int]? = nil
         if let selectionID = selectedValueObjIDs["selection"],
            let vo = self.tracker?.getValObj(selectionID),
            vo.vtype == VOT_CHOICE {
             let categoryMap = fetchChoiceCategories(forID: selectionID)
             // Create inverted map from label to value
             choiceLabelToValue = categoryMap.reduce(into: [:]) { result, pair in
                 result[pair.value] = pair.key
             }
         }
         
         // Assign values to categories
         for category in categories {
             if category == "no entry" {
                 categoryValues[category] = Int.min
                 continue
             }
             
             if let choiceMap = choiceLabelToValue {
                 // Handle VOT_CHOICE categories
                 if let value = choiceMap[category] {
                     categoryValues[category] = value
                     continue
                 }
             }
             
             // Handle other category types
             if let numValue = Int(category) {
                 categoryValues[category] = numValue
             } else if category == "true" {
                 categoryValues[category] = 1
             } else if category == "false" {
                 categoryValues[category] = 0
             } else if category == "low" {
                 categoryValues[category] = 0
             } else if category == "medium" {
                 categoryValues[category] = 1
             } else if category == "high" {
                 categoryValues[category] = 2
             }
         }
         
         // Find min and max values
         let filteredValues = categoryValues.values.filter { $0 != Int.min }
         if !filteredValues.isEmpty {
             let minCategoryValue = filteredValues.min() ?? 0
             let maxCategoryValue = filteredValues.max() ?? 1
             let categoryValueRange = max(1, maxCategoryValue - minCategoryValue)
             
             // Assign colors based on normalized value
             for (category, value) in categoryValues {
                 if category == "no entry" {
                     categoryColors[category] = UIColor.systemGreen
                 } else {
                     let normalizedValue = Double(value - minCategoryValue) / Double(categoryValueRange)
                     categoryColors[category] = getColorGradient(normalizedValue: normalizedValue)
                 }
             }
         }
         
         return (categoryColors, categoryValues)
     }
     
    
    internal func renderDistributionPlot() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard chartData["type"] as? String == "distribution",
              let backgroundValues = chartData["backgroundValues"] as? [Double],
              !backgroundValues.isEmpty else {
            noDataLabel.text = "No distribution data available"
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Get graph dimensions
        let graphWidth = chartView.bounds.width - leftMargin - rightMargin
        let graphHeight = chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace
        
        // Extract bin configuration
        let binCount = chartData["binCount"] as? Int ?? 10
        let paddedMinValue = chartData["minValue"] as? Double ?? (backgroundValues.min() ?? 0)
        let paddedMaxValue = chartData["maxValue"] as? Double ?? (backgroundValues.max() ?? 1)
        let binWidth = chartData["binWidth"] as? Double ?? ((paddedMaxValue - paddedMinValue) / Double(binCount))
        
        // Create bins for background data
        var backgroundBins = Array(repeating: 0, count: binCount)
        for value in backgroundValues {
            let binIndex = Int((value - paddedMinValue) / binWidth)
            if binIndex >= 0 && binIndex < binCount {
                backgroundBins[binIndex] += 1
            }
        }
        
        // Normalize background bins
        let totalBackgroundCount = Double(backgroundValues.count)
        let normalizedBackgroundBins = backgroundBins.map { Double($0) / totalBackgroundCount }
        
        // Process selection data if available
        let selectionData = chartData["selectionData"] as? [String: [Double]] ?? [:]
        
        // Calculate bins for each selection category
        let selectionBins = calculateSelectionBins(
            selectionData: selectionData,
            binCount: binCount,
            paddedMinValue: paddedMinValue,
            binWidth: binWidth
        )
        
        // Draw axes and grid
        drawDistributionAxes(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            paddedMinValue: paddedMinValue,
            paddedMaxValue: paddedMaxValue,
            binCount: binCount,
            normalizedBackgroundBins: normalizedBackgroundBins,
            selectionBins: selectionBins
        )
        
        // Draw histogram and selection lines
        drawDistributionHistogram(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            binCount: binCount,
            normalizedBackgroundBins: normalizedBackgroundBins,
            selectionBins: selectionBins
        )
        
        // Draw legend for categories
        if !selectionBins.isEmpty {
            let categoryData = generateCategoryColors(selectionBins.keys)
            let categoryColors = categoryData.colors
            let categoryValues = categoryData.values
            
            // Sort categories by their values (higher values first)
            let sortedCategories = Array(selectionBins.keys).sorted { (a, b) -> Bool in
                return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
            }
            
            DBGLog("\(sortedCategories)")
            /*
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
            )
            */
            
            // show averages
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: selectionData,
                categoryColors: categoryColors,
                orderedCategories: sortedCategories
            )
        } else {
            // show background average even when no selection data
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: [:],
                categoryColors: [:],
                orderedCategories: []
            )
        }
    }
    
    // Modified version of renderDistributionPlot that uses filteredSelectionData
    internal func renderDistributionPlotWithFiltered() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard chartData["type"] as? String == "distribution",
              let backgroundValues = chartData["backgroundValues"] as? [Double],
              !backgroundValues.isEmpty else {
            noDataLabel.text = "No distribution data available"
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Get graph dimensions
        let graphWidth = chartView.bounds.width - leftMargin - rightMargin
        let graphHeight = chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace
        
        // Extract bin configuration
        let binCount = chartData["binCount"] as? Int ?? 10
        let paddedMinValue = chartData["minValue"] as? Double ?? (backgroundValues.min() ?? 0)
        let paddedMaxValue = chartData["maxValue"] as? Double ?? (backgroundValues.max() ?? 1)
        let binWidth = chartData["binWidth"] as? Double ?? ((paddedMaxValue - paddedMinValue) / Double(binCount))
        
        // Create bins for background data
        var backgroundBins = Array(repeating: 0, count: binCount)
        for value in backgroundValues {
            let binIndex = Int((value - paddedMinValue) / binWidth)
            if binIndex >= 0 && binIndex < binCount {
                backgroundBins[binIndex] += 1
            }
        }
        
        // Normalize background bins
        let totalBackgroundCount = Double(backgroundValues.count)
        let normalizedBackgroundBins = backgroundBins.map { Double($0) / totalBackgroundCount }
        
        // Process selection data if available - use filtered data
        let selectionData = chartData["filteredSelectionData"] as? [String: [Double]] ?? [:]
        
        // Calculate bins for each selection category
        let selectionBins = calculateSelectionBins(
            selectionData: selectionData,
            binCount: binCount,
            paddedMinValue: paddedMinValue,
            binWidth: binWidth
        )
        
        // Draw axes and grid
        drawDistributionAxes(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            paddedMinValue: paddedMinValue,
            paddedMaxValue: paddedMaxValue,
            binCount: binCount,
            normalizedBackgroundBins: normalizedBackgroundBins,
            selectionBins: selectionBins
        )
        
        // Draw histogram and selection lines
        drawDistributionHistogram(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            binCount: binCount,
            normalizedBackgroundBins: normalizedBackgroundBins,
            selectionBins: selectionBins
        )
        
        // Draw legend for categories - use the original selectionData to show all possible categories
        if let originalSelectionData = chartData["selectionData"] as? [String: [Double]], !originalSelectionData.isEmpty {
            let categoryData = generateCategoryColors(originalSelectionData.keys)
            let categoryColors = categoryData.colors
            let categoryValues = categoryData.values
            
            // Sort categories by their values (higher values first)
            let sortedCategories = Array(originalSelectionData.keys).sorted { (a, b) -> Bool in
                return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
            }
            
            /*
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
            )
             */
            
            // averages/counts respecting current visibility (filteredSelectionData)
            let filteredSelData = chartData["filteredSelectionData"] as? [String: [Double]] ?? [:]
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: filteredSelData,
                categoryColors: categoryColors,
                orderedCategories: sortedCategories
            )
        } else {
            // background only average/count
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: [:],
                categoryColors: [:],
                orderedCategories: []
            )
        }
    }
    
    internal func drawDistributionAxes(
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        paddedMinValue: Double,
        paddedMaxValue: Double,
        binCount: Int,
        normalizedBackgroundBins: [Double],
        selectionBins: [String: [Double]]
    ) {
        // Create axes container
        let axesView = UIView(frame: chartView.bounds)
        chartView.addSubview(axesView)
        
        // Draw X and Y axes
        let xAxis = UIView(frame: CGRect(x: leftMargin, y: topMargin + graphHeight, width: graphWidth, height: 1))
        xAxis.backgroundColor = .label
        axesView.addSubview(xAxis)
        
        let yAxis = UIView(frame: CGRect(x: leftMargin, y: topMargin, width: 1, height: graphHeight))
        yAxis.backgroundColor = .label
        axesView.addSubview(yAxis)
        
        // Draw axis labels
        let backgroundVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["background"] }
        
        // X-axis label
        let xLabel = UILabel(frame: CGRect(x: leftMargin, y: topMargin + graphHeight + 25, width: graphWidth, height: 20))
        xLabel.text = backgroundVO?.valueName ?? "Value"
        xLabel.textAlignment = .center
        xLabel.font = UIFont.systemFont(ofSize: 12)
        axesView.addSubview(xLabel)
        
        // Y-axis label
        let yLabel = UILabel()
        yLabel.text = "Frequency"
        yLabel.font = UIFont.systemFont(ofSize: 12)
        yLabel.sizeToFit()
        yLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        yLabel.center = CGPoint(x: leftMargin - 45, y: topMargin + graphHeight/2)
        axesView.addSubview(yLabel)
        
        // Find the maximum normalized bin value for Y-axis scaling
        let maxBinValue = max(
            normalizedBackgroundBins.max() ?? 0,
            selectionBins.values.flatMap { $0 }.max() ?? 0
        )
        
        // Draw X-axis scale marks
        for i in 0...5 {
            let value = paddedMinValue + Double(i) * (paddedMaxValue - paddedMinValue) / 5.0
            let x = leftMargin + CGFloat(i) * graphWidth / 5.0
            
            // Grid line (lighter)
            if i > 0 {  // Skip the Y-axis line
                let gridLine = UIView(frame: CGRect(x: x, y: topMargin, width: 0.5, height: graphHeight))
                gridLine.backgroundColor = UIColor.systemGray4
                axesView.addSubview(gridLine)
            }
            
            // Tick mark
            let tick = UIView(frame: CGRect(x: x, y: topMargin + graphHeight, width: 1, height: 5))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            // Label
            let label = UILabel(frame: CGRect(x: x - 25, y: topMargin + graphHeight + 5, width: 50, height: 15))
            label.text = String(format: "%.1f", value)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
        
        // Draw Y-axis scale marks (percentage)
        for i in 0...5 {
            let percentage = (1.0 - Double(i) / 5.0) * maxBinValue * 100
            let y = topMargin + CGFloat(i) * graphHeight / 5.0
            
            // Grid line (lighter)
            if i > 0 {  // Skip the X-axis line
                let gridLine = UIView(frame: CGRect(x: leftMargin, y: y, width: graphWidth, height: 0.5))
                gridLine.backgroundColor = UIColor.systemGray4
                axesView.addSubview(gridLine)
            }
            
            // Tick mark
            let tick = UIView(frame: CGRect(x: leftMargin - 5, y: y, width: 5, height: 1))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            // Label
            let label = UILabel(frame: CGRect(x: leftMargin - 45, y: y - 8, width: 40, height: 15))
            label.text = String(format: "%.0f%%", percentage)
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
    }
    
    internal func drawDistributionHistogram(
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        binCount: Int,
        normalizedBackgroundBins: [Double],
        selectionBins: [String: [Double]]
    ) {
        // Find the maximum normalized bin value for scaling
        let maxBinValue = max(
            normalizedBackgroundBins.max() ?? 0.001,  // Ensure non-zero value
            selectionBins.values.flatMap { $0 }.max() ?? 0.001
        )
        
        // Clear any previous histogram elements
        // This ensures we don't have leftover views from previous renders
        for subview in chartView.subviews {
            if subview != noDataLabel && subview.tag == 1001 {
                subview.removeFromSuperview()
            }
        }
        
        // Draw background histogram
        let histogramView = UIView(frame: chartView.bounds)
        histogramView.tag = 1001  // Tag to identify for later removal
        chartView.addSubview(histogramView)
        
        for (index, value) in normalizedBackgroundBins.enumerated() {
            // Guard against invalid values
            guard !value.isNaN && !value.isInfinite && maxBinValue > 0 else {
                continue
            }
            
            let normalizedHeight = CGFloat(value / maxBinValue)
            // Ensure height is valid
            guard !normalizedHeight.isNaN && !normalizedHeight.isInfinite else {
                continue
            }
            
            let barHeight = normalizedHeight * graphHeight
            let barWidth = graphWidth / CGFloat(binCount)
            
            // Validate final dimensions
            guard !barHeight.isNaN && !barHeight.isInfinite && barHeight >= 0 else {
                continue
            }
            
            let x = leftMargin + CGFloat(index) * barWidth
            let y = topMargin + graphHeight - barHeight
            
            let barView = UIView(frame: CGRect(x: x, y: y, width: barWidth, height: barHeight))
            barView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
            histogramView.addSubview(barView)
        }
        
        // Draw selection lines
        let selectionView = UIView(frame: chartView.bounds)
        selectionView.tag = 1001  // Same tag for easy removal
        chartView.addSubview(selectionView)
        
        // Generate colors for categories
        let categoryData = generateCategoryColors(selectionBins.keys)
        let categoryColors = categoryData.colors
        
        // Draw category lines
        for (category, bins) in selectionBins {
            let linePath = UIBezierPath()
            let barWidth = graphWidth / CGFloat(binCount)
            var validPoints = false
            
            for (index, value) in bins.enumerated() {
                // Guard against invalid values
                guard !value.isNaN && !value.isInfinite && maxBinValue > 0 else {
                    continue
                }
                
                let normalizedHeight = CGFloat(value / maxBinValue)
                // Ensure height is valid
                guard !normalizedHeight.isNaN && !normalizedHeight.isInfinite else {
                    continue
                }
                
                let yPos = topMargin + graphHeight - normalizedHeight * graphHeight
                let xPos = leftMargin + CGFloat(index) * barWidth + barWidth / 2
                
                if index == 0 || !validPoints {
                    linePath.move(to: CGPoint(x: xPos, y: yPos))
                    validPoints = true
                } else {
                    linePath.addLine(to: CGPoint(x: xPos, y: yPos))
                }
            }
            
            // Only add the line if we have valid points
            if validPoints {
                let lineLayer = CAShapeLayer()
                lineLayer.path = linePath.cgPath
                lineLayer.strokeColor = categoryColors[category]?.cgColor ?? UIColor.black.cgColor
                lineLayer.fillColor = UIColor.clear.cgColor
                lineLayer.lineWidth = 2
                
                // Check visibility state and set initial opacity
                let isVisible = legendItemVisibility[category] ?? true
                lineLayer.opacity = isVisible ? 1.0 : 0.0
                
                // Store the category name with the layer for animation purposes
                objc_setAssociatedObject(lineLayer, AssociatedKeys.legendCategory, category, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                selectionView.layer.addSublayer(lineLayer)
            }
        }
    }

    
    // Update distribution plot with current visibility settings
    internal func updateDistributionPlotWithVisibility() {
        // Only update if we're on the distribution chart type
        guard segmentedControl.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION else {
            return
        }
        
        guard let selectionData = chartData["selectionData"] as? [String: [Double]] else {
            return
        }
        
        // Create a filtered version of selectionData based on visibility
        var filteredSelectionData: [String: [Double]] = [:]
        
        for (category, values) in selectionData {
            let isVisible = legendItemVisibility[category] ?? true
            if isVisible {
                filteredSelectionData[category] = values
            }
        }
        
        // Store the filtered data
        chartData["filteredSelectionData"] = filteredSelectionData
        
        // First, update the lines in the chart to reflect visibility changes
        animateVisibilityChanges()
        
        // Then, update the legend to reflect visibility changes, but don't recreate it
        if let originalSelectionData = chartData["selectionData"] as? [String: [Double]], !originalSelectionData.isEmpty {
            let categoryData = generateCategoryColors(originalSelectionData.keys)
            let categoryColors = categoryData.colors
            let categoryValues = categoryData.values
            
            // Sort categories by their values (higher values first)
            let sortedCategories = Array(originalSelectionData.keys).sorted { (a, b) -> Bool in
                return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
            }
            
            // Update the legend without recreating it
            
            /*
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
            )
            */
            
            // Update averages/counts respecting current visibility
            let filteredSelData = chartData["filteredSelectionData"] as? [String: [Double]] ?? [:]
            let backgroundValues = chartData["backgroundValues"] as? [Double] ?? []
            
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: filteredSelData,
                categoryColors: categoryColors,
                orderedCategories: sortedCategories
            )
        }
    }

    internal func animateVisibilityChanges() {
        DBGLog("Animating visibility changes")
        
        // First, find all line layers in the chart view
        var lineLayers: [String: CAShapeLayer] = [:]
        
        for subview in chartView.subviews {
            // Look for the selection view where we add line layers (tagged as 1001)
            if subview.tag == 1001 {
                for layer in subview.layer.sublayers ?? [] {
                    if let lineLayer = layer as? CAShapeLayer {
                        // Get category from associated object
                        if let category = objc_getAssociatedObject(lineLayer, AssociatedKeys.legendCategory) as? String {
                            lineLayers[category] = lineLayer
                            DBGLog("Found line layer for category: \(category)")
                        }
                    }
                }
            }
        }
        
        if lineLayers.isEmpty {
            DBGLog("No line layers found, rendering from scratch")
            // If we can't find existing lines (first render), just render the filtered data
            renderDistributionPlotWithFiltered()
            return
        }
        
        // Animate each line's opacity based on visibility
        for (category, isVisible) in legendItemVisibility {
            DBGLog("Processing category: \(category), visibility: \(isVisible)")
            if let layer = lineLayers[category] {
                // Create opacity animation
                let opacityAnimation = CABasicAnimation(keyPath: "opacity")
                opacityAnimation.fromValue = layer.opacity
                opacityAnimation.toValue = isVisible ? 1.0 : 0.0
                opacityAnimation.duration = 0.3
                opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                opacityAnimation.fillMode = .forwards
                opacityAnimation.isRemovedOnCompletion = false
                
                // Apply animation
                layer.add(opacityAnimation, forKey: "opacityAnimation")
                
                // Update final opacity value
                layer.opacity = isVisible ? 1.0 : 0.0
                DBGLog("Animated opacity for \(category) to \(isVisible ? 1.0 : 0.0)")
            } else {
                DBGLog("No layer found for category: \(category)")
            }
        }
        
        // Also update the averages/counts display to reflect current visibility
        if let backgroundValues = chartData["backgroundValues"] as? [Double],
           let filteredSelData = chartData["filteredSelectionData"] as? [String: [Double]],
           let originalSelectionData = chartData["selectionData"] as? [String: [Double]],
           !originalSelectionData.isEmpty {
            
            let categoryData = generateCategoryColors(originalSelectionData.keys)
            let categoryColors = categoryData.colors
            
            // Sort categories by their values
            let categoryValues = categoryData.values
            let sortedCategories = Array(originalSelectionData.keys).sorted { (a, b) -> Bool in
                return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
            }
            
            // Update averages/counts display
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: filteredSelData,
                categoryColors: categoryColors,
                orderedCategories: sortedCategories
            )
        }
    }
    
    // MARK: - Distribution Plot data handling
    
    
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
