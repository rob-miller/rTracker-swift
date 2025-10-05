//
//  trackerChartScatterPlot.swift
//  rTracker
//
//  Created by Robert Miller on 23/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import UIKit

// MARK: - scatter plot Extensions
extension TrackerChart {
    
    
    internal func setupScatterPlotConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for X, Y, and Color selection
        xAxisButton = createConfigButton(title: "Select X Axis", action: #selector(selectXAxis))
        yAxisButton = createConfigButton(title: "Select Y Axis", action: #selector(selectYAxis))
        colorButton = createConfigButton(title: "Select Color (Optional)", action: #selector(selectColor))
        
        // Configure layout - no longer using fillEqually distribution
        let stackView = UIStackView(arrangedSubviews: [
            sliderContainer,
            xAxisButton, yAxisButton, colorButton
            
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
            stackView.bottomAnchor.constraint(equalTo: configContainer.bottomAnchor),
            
            // Set a dynamic height constraint for the slider container that adjusts for magnifier glass
            sliderContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 160)  // More space for sliders
        ])
        
        // Update buttons with any previously selected values
        updateButtonTitles()
    }
    
    
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

        // Calculate dynamic point size based on number of points
        // More points = smaller size to prevent overlapping
        // Formula: Size scales from 3px (dense) to 10px (sparse) using logarithmic scale
        let pointCount = max(1, points.count)
        let pointSize: CGFloat = max(3, min(10, 10 - log10(Double(pointCount)) * 2))

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
            // Create point view (pointSize calculated above based on total point count)
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
     
    // MARK: - data handling
    
    
    
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
    
    
}

