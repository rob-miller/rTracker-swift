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
            drawColorLegend(in: chartView, minValue: minColor, maxValue: maxColor)
        }
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
                let normalizedColorValue = (colorValue - minColor) / colorRange
                pointColor = getColorGradient(normalizedValue: normalizedColorValue)
            } else {
                // Adapt color based on current interface style
                if self.traitCollection.userInterfaceStyle == .dark {
                    pointColor = UIColor.white  // White points on dark background
                } else {
                    pointColor = UIColor.black  // Black points on light background
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
                if let key = AssociatedKeys.pointData {
                    objc_setAssociatedObject(pointView, key, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            }
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
            
            drawCategoryLegend(
                in: chartView,
                categories: sortedCategories,
                colors: categoryColors
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
                selectionView.layer.addSublayer(lineLayer)
            }
        }
    }
    
    internal func generateCategoryColors(_ categories: Dictionary<String, [Double]>.Keys) -> (colors: [String: UIColor], values: [String: Int]) {
        var categoryColors: [String: UIColor] = [:]
        var categoryValues: [String: Int] = [:]
        
        // Assign values to categories
        for category in categories {
            // Special case for no_entry
            if category == "no_entry" {
                categoryColors[category] = UIColor.systemGreen
                continue
            }
            
            // Try to convert numerical categories
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
            } else {
                // For non-standard categories, look up the value from the selection object
                if let selectionID = selectedValueObjIDs["selection"], selectionID != -1 {
                    let categoryMap = fetchChoiceCategories(forID: selectionID)
                    // Find the key in categoryMap that has the category as its value
                    for (value, label) in categoryMap {
                        if label == category {
                            categoryValues[category] = value
                            break
                        }
                    }
                }
            }
        }
        
        // Find min and max values
        let filteredValues = categoryValues.values
        if !filteredValues.isEmpty {
            let minCategoryValue = filteredValues.min() ?? 0
            let maxCategoryValue = filteredValues.max() ?? 1
            let categoryValueRange = max(1, maxCategoryValue - minCategoryValue)
            
            // Assign colors based on normalized value
            for (category, value) in categoryValues {
                let normalizedValue = Double(value - minCategoryValue) / Double(categoryValueRange)
                categoryColors[category] = getColorGradient(normalizedValue: normalizedValue)
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
        y: legendTopMargin,
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
    
    // Add min label
    let minLabel = UILabel(frame: CGRect(
        x: gradientView.frame.minX,
        y: gradientView.frame.maxY + 5,
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
        y: gradientView.frame.maxY + 5,
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
        y: gradientView.frame.minY - 20,
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
    view.addSubview(legendView)
    
    // Iterate through categories in their original order
    for (index, category) in categories.enumerated() {
        // Color indicator
        let colorView = UIView(frame: CGRect(
            x: 10,
            y: CGFloat(index) * (itemHeight + padding) + padding,
            width: 10,
            height: 10
        ))
        colorView.backgroundColor = colors[category] ?? .black
        colorView.layer.cornerRadius = 5
        legendView.addSubview(colorView)
        
        // Label
        let label = UILabel(frame: CGRect(
            x: 30,
            y: CGFloat(index) * (itemHeight + padding),
            width: legendWidth - 40,
            height: itemHeight
        ))
        label.text = category
        label.font = UIFont.systemFont(ofSize: 10)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        legendView.addSubview(label)
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
