//
//  trackerChartPlots.swift
//  rTracker
//
//  Created by Robert Miller on 31/03/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import UIKit

// MARK: - Chart Rendering Extensions
extension TrackerChart {
    
    // MARK: - Rendering Methods
    
    internal func renderScatterPlot() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard chartData["type"] as? String == "scatter",
              let points = chartData["points"] as? [[String: Any]],
              !points.isEmpty else {
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Get graph dimensions
        let graphWidth = chartView.bounds.width - leftMargin - rightMargin
        let graphHeight = chartView.bounds.height - topMargin - bottomMargin - extraBottomSpace
        
        // Get axis configurations - use stored axis ranges if available
        var paddedMinX: Double = 0
        var paddedMaxX: Double = 1
        var paddedMinY: Double = 0
        var paddedMaxY: Double = 1
        
        if let xAxisConfig = axisConfig["xAxis"] as? [String: Any],
           let minX = xAxisConfig["min"] as? Double,
           let maxX = xAxisConfig["max"] as? Double {
            paddedMinX = minX
            paddedMaxX = maxX
        } else {
            // If no stored axis config, calculate from current data
            let xValues = points.compactMap { $0["x"] as? Double }
            if !xValues.isEmpty {
                let minX = xValues.min() ?? 0
                let maxX = xValues.max() ?? 1
                let xRange = max(0.001, maxX - minX) * 1.1
                paddedMinX = minX - xRange * 0.05
                paddedMaxX = maxX + xRange * 0.05
            }
        }
        
        if let yAxisConfig = axisConfig["yAxis"] as? [String: Any],
           let minY = yAxisConfig["min"] as? Double,
           let maxY = yAxisConfig["max"] as? Double {
            paddedMinY = minY
            paddedMaxY = maxY
        } else {
            // If no stored axis config, calculate from current data
            let yValues = points.compactMap { $0["y"] as? Double }
            if !yValues.isEmpty {
                let minY = yValues.min() ?? 0
                let maxY = yValues.max() ?? 1
                let yRange = max(0.001, maxY - minY) * 1.1
                paddedMinY = minY - yRange * 0.05
                paddedMaxY = maxY + yRange * 0.05
            }
        }
        
        // Color mapping configuration
        let colorValues = points.compactMap { $0["color"] as? Double }
        let useColorMap = !colorValues.isEmpty
        var minColor: Double = 0
        var maxColor: Double = 1
        
        if useColorMap {
            if let colorAxisConfig = axisConfig["colorAxis"] as? [String: Any],
               let minC = colorAxisConfig["min"] as? Double,
               let maxC = colorAxisConfig["max"] as? Double {
                minColor = minC
                maxColor = maxC
            } else {
                minColor = colorValues.min() ?? 0
                maxColor = colorValues.max() ?? 1
            }
        }
        
        // Draw axes and grid
        drawScatterAxes(
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            paddedMinX: paddedMinX,
            paddedMaxX: paddedMaxX,
            paddedMinY: paddedMinY,
            paddedMaxY: paddedMaxY
        )
        
        // Draw data points
        drawScatterPoints(
            points: points,
            graphWidth: graphWidth,
            graphHeight: graphHeight,
            paddedMinX: paddedMinX,
            paddedMaxX: paddedMaxX,
            paddedMinY: paddedMinY,
            paddedMaxY: paddedMaxY,
            minColor: minColor,
            maxColor: maxColor,
            useColorMap: useColorMap
        )
        
        // Draw correlation if available
        if let correlation = chartData["correlation"] as? Double {
            let correlationLabel = UILabel(frame: CGRect(x: leftMargin + 10, y: 15, width: 150, height: 20))
            correlationLabel.text = String(format: "Correlation: %.3f", correlation)
            correlationLabel.textAlignment = .left
            correlationLabel.font = UIFont.systemFont(ofSize: 12)
            correlationLabel.textColor = .secondaryLabel
            chartView.addSubview(correlationLabel)
        }
        
        // Draw color legend if needed
        if useColorMap {
            // Check if the color variable is boolean
            if let colorID = selectedValueObjIDs["color"],
               let colorVO = tracker?.valObjTable.first(where: { $0.vid == colorID }),
               colorVO.vtype == VOT_BOOLEAN {
                // Draw boolean legend
                drawBooleanColorLegend(in: chartView)
            } else {
                // Draw continuous gradient legend
                drawColorLegend(in: chartView, minValue: minColor, maxValue: maxColor)
            }
        }
    }
    
    internal func drawBooleanColorLegend(in view: UIView) {
        // Create a legend container
        let legendView = UIView(frame: CGRect(
            x: view.bounds.width - legendWidth - legendRightMargin,
            y: legendTopMargin + 4,
            width: legendWidth,
            height: legendHeight * 2 + 0 // Give more height for two items
        ))
        legendView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        legendView.layer.cornerRadius = 5
        legendView.layer.borderWidth = 0.5
        legendView.layer.borderColor = UIColor.systemGray.cgColor
        view.addSubview(legendView)
        
        // Colors for true and no entry (treated as false)
        let trueColor = UIColor.systemRed
        let noEntryColor = UIColor.systemBlue
        
        // True indicator
        let trueIndicator = UIView(frame: CGRect(
            x: 10,
            y: 5,
            width: 10,
            height: 10
        ))
        trueIndicator.backgroundColor = trueColor
        trueIndicator.layer.cornerRadius = 5
        legendView.addSubview(trueIndicator)
        
        // True label
        let trueLabel = UILabel(frame: CGRect(
            x: 30,
            y: 0,
            width: legendWidth - 40,
            height: 20
        ))
        trueLabel.text = "True"
        trueLabel.font = UIFont.systemFont(ofSize: 12)
        legendView.addSubview(trueLabel)
        
        // No Entry indicator (treated as False)
        let noEntryIndicator = UIView(frame: CGRect(
            x: 10,
            y: 25,
            width: 10,
            height: 10
        ))
        noEntryIndicator.backgroundColor = noEntryColor
        noEntryIndicator.layer.cornerRadius = 5
        legendView.addSubview(noEntryIndicator)
        
        // No Entry label
        let noEntryLabel = UILabel(frame: CGRect(
            x: 30,
            y: 20,
            width: legendWidth - 40,
            height: 20
        ))
        noEntryLabel.text = "False"
        noEntryLabel.font = UIFont.systemFont(ofSize: 12)
        legendView.addSubview(noEntryLabel)
        
        // Add title label
        let colorVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["color"] }
        let titleLabel = UILabel(frame: CGRect(
            x: legendView.frame.minX,
            y: legendView.frame.minY - 18,
            width: legendWidth,
            height: 15
        ))
        titleLabel.text = colorVO?.valueName ?? "Color"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(titleLabel)
    }


    
    internal func drawScatterAxes(
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        paddedMinX: Double,
        paddedMaxX: Double,
        paddedMinY: Double,
        paddedMaxY: Double
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
        let xVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["xAxis"] }
        let yVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["yAxis"] }
        
        // X-axis label - moved further down from tick labels
        let xLabel = UILabel(frame: CGRect(x: leftMargin, y: topMargin + graphHeight + 25, width: graphWidth, height: 20))
        xLabel.text = xVO?.valueName ?? "X Axis"
        xLabel.textAlignment = .center
        xLabel.font = UIFont.systemFont(ofSize: 12)
        axesView.addSubview(xLabel)
        
        // Y-axis label - moved further left from tick labels
        let yLabel = UILabel()
        yLabel.text = yVO?.valueName ?? "Y Axis"
        yLabel.font = UIFont.systemFont(ofSize: 12)
        yLabel.sizeToFit()
        yLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        yLabel.center = CGPoint(x: leftMargin - 45, y: topMargin + graphHeight/2) // Moved further left
        axesView.addSubview(yLabel)
        
        // Draw grid lines and scale markers
        // X scale
        for i in 0...5 {
            let value = paddedMinX + Double(i) * (paddedMaxX - paddedMinX) / 5.0
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
        
        // Y scale
        for i in 0...5 {
            let value = paddedMaxY - Double(i) * (paddedMaxY - paddedMinY) / 5.0
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
            let label = UILabel(frame: CGRect(x: leftMargin - 50, y: y - 8, width: 45, height: 15))
            label.text = String(format: "%.1f", value)
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
    }
    
    internal func drawScatterPoints(
        points: [[String: Any]],
        graphWidth: CGFloat,
        graphHeight: CGFloat,
        paddedMinX: Double,
        paddedMaxX: Double,
        paddedMinY: Double,
        paddedMaxY: Double,
        minColor: Double,
        maxColor: Double,
        useColorMap: Bool
    ) {
        // Create points container
        let pointsContainerView = UIView(frame: chartView.bounds)
        chartView.addSubview(pointsContainerView)
        
        // Calculate color range
        let colorRange = max(0.001, maxColor - minColor)
        
        for point in points {
            guard let x = point["x"] as? Double,
                  let y = point["y"] as? Double else { continue }
            
            // Convert to view coordinates
            let xPos = leftMargin + CGFloat((x - paddedMinX) / (paddedMaxX - paddedMinX)) * graphWidth
            let yPos = topMargin + graphHeight - CGFloat((y - paddedMinY) / (paddedMaxY - paddedMinY)) * graphHeight
            
            // Determine color
            var pointColor: UIColor
            if useColorMap, let colorValue = point["color"] as? Double {
                // Check if color variable is boolean
                if let colorID = selectedValueObjIDs["color"],
                   let colorVO = tracker?.valObjTable.first(where: { $0.vid == colorID }),
                   colorVO.vtype == VOT_BOOLEAN {
                    // For boolean, we use red for true values, and points without a value (no entry)
                    // will use the default color logic below (treated as "false")
                    pointColor = colorValue >= 0.5 ? UIColor.systemRed : UIColor.systemBlue
                } else {
                    // Use gradient for continuous values
                    let normalizedColorValue = (colorValue - minColor) / colorRange
                    pointColor = getColorGradient(normalizedValue: normalizedColorValue)
                }
            } else {
                // Check if we're using a boolean color and this point has no color value
                // This means it's a "no entry" which we want to treat as "false"
                if useColorMap,
                   let colorID = selectedValueObjIDs["color"],
                   let colorVO = tracker?.valObjTable.first(where: { $0.vid == colorID }),
                   colorVO.vtype == VOT_BOOLEAN {
                    pointColor = UIColor.systemBlue  // Treat as "false"
                } else {
                    // Adapt color based on current interface style for other cases
                    if self.traitCollection.userInterfaceStyle == .dark {
                        pointColor = UIColor.white  // White points on dark background
                    } else {
                        pointColor = UIColor.black  // Black points on light background
                    }
                }
            }
            // Create point view
            let pointSize: CGFloat = 8
            let pointView = UIView(frame: CGRect(x: xPos - pointSize/2, y: yPos - pointSize/2, width: pointSize, height: pointSize))
            pointView.backgroundColor = pointColor
            pointView.layer.cornerRadius = pointSize / 2
            pointsContainerView.addSubview(pointView)
            
            // Add date tooltip on tap
            if let date = point["date"] as? Date {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showPointDetails(_:)))
                pointView.addGestureRecognizer(tapGesture)
                pointView.isUserInteractionEnabled = true
                
                // Store the actual data in a dictionary accessible by objectForKey
                let userData = ["x": x, "y": y, "date": date, "colorValue": point["color"] as? Double as Any] as [String : Any]
                //objc_setAssociatedObject(pointView, &AssociatedKeys.pointData, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                let key = AssociatedKeys.pointData
                objc_setAssociatedObject(pointView, key, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
            }
        }
    }
    
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
        let xPos: CGFloat = leftMargin + 10
        let lineHeight: CGFloat = 16
        
        // Background average (always first)
        if !backgroundValues.isEmpty {
            let avg = backgroundValues.reduce(0.0, +) / Double(backgroundValues.count)
            let lbl = UILabel(frame: CGRect(x: xPos, y: yPos, width: 220, height: lineHeight))
            lbl.font = UIFont.systemFont(ofSize: 12)
            lbl.textColor = .label
            lbl.text = String(format: "Avg (all): %.2f", avg)
            container.addSubview(lbl)
            yPos += lineHeight
        }
        
        // Follow legend order
        for category in orderedCategories {
            guard let values = selectionData[category], !values.isEmpty else { continue }
            let avg = values.reduce(0.0, +) / Double(values.count)
            let lbl = UILabel(frame: CGRect(x: xPos, y: yPos, width: 220, height: lineHeight))
            lbl.font = UIFont.systemFont(ofSize: 12)
            let visible = legendItemVisibility[category] ?? true
            let baseColor = categoryColors[category] ?? UIColor.label
            lbl.textColor = visible ? baseColor : baseColor.withAlphaComponent(0.3)
            lbl.text = String(format: "%@: %.2f", category, avg)
            container.addSubview(lbl)
            yPos += lineHeight
        }
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
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
            )
            
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
            
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
            )
            // averages respecting current visibility (filteredSelectionData)
            let filteredSelData = chartData["filteredSelectionData"] as? [String: [Double]] ?? [:]
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: filteredSelData,
                categoryColors: categoryColors,
                orderedCategories: sortedCategories
            )
        } else {
            // background only average
            drawDistributionAverages(
                backgroundValues: backgroundValues,
                selectionData: [:],
                categoryColors: [:],
                orderedCategories: []
            )
        }
    }
    
    
    
    
    // MARK: - Chart Data Generation and Rendering
    
    internal func updateChartData() {
        // Update chart data if axes are selected
        if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
            if selectedValueObjIDs["xAxis"] != -1 && selectedValueObjIDs["yAxis"] != -1 {
                if axisConfig["xAxis"] == nil || axisConfig["yAxis"] == nil {
                    // If no axis config exists, perform full data fetch to set axes scales
                    analyzeScatterData()
                } else {
                    // If axis config exists, just update the plot data with the current date range
                    generateScatterPlotData()
                }
            }
        } else {
            if selectedValueObjIDs["background"] != -1 {
                if axisConfig["background"] == nil {
                    // If no axis config exists, perform full data fetch
                    analyzeDistributionData()
                } else {
                    // If axis config exists, just update the plot data with the current date range
                    generateDistributionPlotData()
                }
            }
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
    
    
    internal func getColorGradient(normalizedValue: Double) -> UIColor {
        // Blue (0) to Red (1) gradient through purple
        let clampedValue = max(0, min(1, normalizedValue))
        
        if clampedValue < 0.5 {
            // Blue to Purple
            let t = clampedValue * 2
            let r = CGFloat(t) * 0.5
            let g = 0.0
            let b = 1.0
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            // Purple to Red
            let t = (clampedValue - 0.5) * 2
            let r = 0.5 + CGFloat(t) * 0.5
            let g = 0.0
            let b = 1.0 - CGFloat(t)
            return UIColor(red: r, green: g, blue: b, alpha: 1.0)
        }
    }
    
    // MARK: - Rendering Methods
    
    
    internal func drawColorLegend(
        in view: UIView,
        minValue: Double,
        maxValue: Double
    ) {
        // Create gradient view
        let gradientView = UIView(frame: CGRect(
            x: view.bounds.width - legendWidth - legendRightMargin,
            y: legendTopMargin + 4,
            width: legendWidth,
            height: legendHeight
        ))
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [
            UIColor.blue.cgColor,
            UIColor.purple.cgColor,
            UIColor.red.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientView.layer.addSublayer(gradientLayer)
        gradientView.layer.cornerRadius = 3
        gradientView.layer.masksToBounds = true
        view.addSubview(gradientView)
        
        let minMaxLabelYoffset: CGFloat = 1
        // Add min label
        let minLabel = UILabel(frame: CGRect(
            x: gradientView.frame.minX,
            y: gradientView.frame.maxY + minMaxLabelYoffset,
            width: 50,
            height: 15
        ))
        minLabel.text = String(format: "%.1f", minValue)
        minLabel.textAlignment = .left
        minLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(minLabel)
        
        // Add max label
        let maxLabel = UILabel(frame: CGRect(
            x: gradientView.frame.maxX - 50,
            y: gradientView.frame.maxY + minMaxLabelYoffset,
            width: 50,
            height: 15
        ))
        maxLabel.text = String(format: "%.1f", maxValue)
        maxLabel.textAlignment = .right
        maxLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(maxLabel)
        
        // Add title label
        let colorVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["color"] }
        let titleLabel = UILabel(frame: CGRect(
            x: gradientView.frame.minX,
            y: gradientView.frame.minY - 16,
            width: legendWidth,
            height: 15
        ))
        titleLabel.text = colorVO?.valueName ?? "Color"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 10)
        view.addSubview(titleLabel)
    }
    
    
    internal func drawCategoryLegend(
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
            //legendView.isUserInteractionEnabled = true
            view.addSubview(legendView)
            
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
                //itemContainer.backgroundColor = UIColor.red.withAlphaComponent(0.1)
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
                itemContainer.isUserInteractionEnabled = true
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
            view.addSubview(titleLabel)
        }
        
    // Handle tap events on legend items
    @objc internal func legendItemTapped(_ sender: UITapGestureRecognizer) {
        guard let itemView = sender.view,
              let category = objc_getAssociatedObject(itemView, AssociatedKeys.legendCategory) as? String else {
            return
        }
        
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
        
        // Update the distribution plot
        self.updateDistributionPlotWithVisibility()
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
            
            // First, update the legend to reflect the new visibility state
            // Find and remove the current legend
            for subview in chartView.subviews {
                // Check if this is the legend view by its position
                 if subview.frame.origin.x == chartView.bounds.width - legendWidth - legendRightMargin &&
                    subview.frame.origin.y == legendTopMargin + 10 {
                     // Found the legend view
                     subview.removeFromSuperview()
                     
                     // Also remove the title label which is just above the legend
                     for otherSubview in chartView.subviews {
                         if let titleLabel = otherSubview as? UILabel,
                            titleLabel.frame.origin.y == subview.frame.origin.y - 20 {
                             titleLabel.removeFromSuperview()
                             break
                         }
                     }
                     break
                 }
            }
            
            // Get category data for redrawing the legend
            if let originalSelectionData = chartData["selectionData"] as? [String: [Double]], !originalSelectionData.isEmpty {
                let categoryData = generateCategoryColors(originalSelectionData.keys)
                let categoryColors = categoryData.colors
                let categoryValues = categoryData.values
                
                // Sort categories by their values (higher values first)
                let sortedCategories = Array(originalSelectionData.keys).sorted { (a, b) -> Bool in
                    return (categoryValues[a] ?? 0) > (categoryValues[b] ?? 0)
                }
                
                // Redraw the legend with updated visibility states
                drawCategoryLegend(
                    in: chartView,
                    categories: sortedCategories,
                    colors: categoryColors
                )
            }
            
            // Then, animate visibility changes for the lines
            animateVisibilityChanges()
        }
        
        // Animate the visibility changes of category lines
        internal func animateVisibilityChanges() {
            // First, find all line layers in the chart view
            var lineLayers: [String: CAShapeLayer] = [:]
            
            for subview in chartView.subviews {
                // Look for the selection view where we add line layers
                if subview.tag == 1001 {
                    for layer in subview.layer.sublayers ?? [] {
                        if let lineLayer = layer as? CAShapeLayer {
                            // Get category from associated object
                            if let category = objc_getAssociatedObject(lineLayer, AssociatedKeys.legendCategory) as? String {
                                lineLayers[category] = lineLayer
                            }
                        }
                    }
                }
            }
            
            if lineLayers.isEmpty {
                // If we can't find existing lines (first render), just render the filtered data
                renderDistributionPlotWithFiltered()
                return
            }
            
            // Animate each line's opacity based on visibility
            for (category, isVisible) in legendItemVisibility {
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
                }
            }
        }
    
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
    
    // MARK: - Data Loading
    
    internal func loadDateRanges() {
        guard tracker != nil else { return }
        
        // Get date range from tracker data
        let dateRange = fetchDateRange()
        earliestDate = dateRange.earliest
        latestDate = dateRange.latest
        
        selectedStartDate = earliestDate
        selectedEndDate = latestDate
        
        // Update date labels
        updateDateLabels()
        
        // Update axis configurations if they exist
        updateChartData()
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
