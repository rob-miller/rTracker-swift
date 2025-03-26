///************
/// trackerChart.swift
/// Copyright 2025 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

//
//  trackerChart.swift
//  rTracker
//
//  this screen presents the charts for a specified tracker
//
//  Created by Robert Miller on 21/03/2025.
//  Copyright 2025 Robert T. Miller. All rights reserved.
//


import UIKit

class TrackerChart: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Properties
    
    // Reference to the tracker
    var tracker: trackerObj?
    
    // Main view elements
    private var chartView: UIView!
    private var noDataLabel: UILabel!
    private var segmentedControl: UISegmentedControl!
    
    // Chart type constants
    private let CHART_TYPE_SCATTER = 0
    private let CHART_TYPE_DISTRIBUTION = 1
    
    // Chart configuration elements
    private var configContainer: UIView!
    
    // Scatter plot configuration
    private var xAxisButton: UIButton!
    private var yAxisButton: UIButton!
    private var colorButton: UIButton!
    
    // Distribution plot configuration
    private var backgroundButton: UIButton!
    private var selectionButton: UIButton!
    
    // Date range sliders
    private var startDateSlider: UISlider!
    private var endDateSlider: UISlider!
    private var startDateLabel: UILabel!
    private var endDateLabel: UILabel!
    
    // Data selection
    private var selectedValueObjIDs: [String: Int] = [:]
    private var allowedValueObjTypes: [String: [Int]] = [:]
    private var currentPickerType: String = ""
    private var pickerView: UIPickerView!
    private var pickerContainer: UIView!
    private var filteredValueObjs: [valueObj] = []
    
    // Date range
    private var earliestDate: Date?
    private var latestDate: Date?
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?
    
    // Chart data
    private var chartData: [String: Any] = [:]
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure view
        setupView()
        
        // Initialize configurations
        initializeChartConfigurations()
        
        // Set up navigation bar
        title = "Charts"
        
        // Add a back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissView)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDateRanges()
    }
    
    // MARK: - UI Setup
    
    // In setupView() method, add a scroll view as the main container
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        // Create a scroll view to contain all content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Create a content view inside scroll view
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Create a segmented control for different chart types
        segmentedControl = UISegmentedControl(items: ["Scatter", "Distribution"])
        segmentedControl.selectedSegmentIndex = CHART_TYPE_SCATTER
        segmentedControl.addTarget(self, action: #selector(chartTypeChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(segmentedControl)
        
        // Set fixed height for segmented control
        segmentedControl.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        // Create the main chart view container
        chartView = UIView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .systemBackground
        chartView.layer.borderWidth = 1
        chartView.layer.borderColor = UIColor.systemGray5.cgColor
        chartView.layer.cornerRadius = 8
        contentView.addSubview(chartView)
        
        // Create a "no data" label for initial state
        noDataLabel = UILabel()
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        noDataLabel.text = "Configure chart options below"
        noDataLabel.textColor = .secondaryLabel
        noDataLabel.textAlignment = .center
        chartView.addSubview(noDataLabel)
        
        // Container for configuration options
        configContainer = UIView()
        configContainer.translatesAutoresizingMaskIntoConstraints = false
        configContainer.backgroundColor = .systemBackground
        contentView.addSubview(configContainer)
        
        // Setup picker view (hidden initially)
        setupPickerView()
        
        // Set up constraints for scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor), // Same width as scroll view
            
            // Segmented control
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Chart view
            chartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            chartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 300), // Fixed height instead of multiplier
            
            // No data label
            noDataLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),
            
            // Configuration container
            configContainer.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 16),
            configContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            configContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            configContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupScatterPlotConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for X, Y, and Color selection
        xAxisButton = createConfigButton(title: "Select X Axis", action: #selector(selectXAxis))
        yAxisButton = createConfigButton(title: "Select Y Axis", action: #selector(selectYAxis))
        colorButton = createConfigButton(title: "Select Color (Optional)", action: #selector(selectColor))
        
        // Create date sliders
        setupDateSliders()
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            xAxisButton, yAxisButton, colorButton,
            createSliderContainer()
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
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
    
    private func setupDistributionPlotConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for Background and Selection
        backgroundButton = createConfigButton(title: "Select Background Data", action: #selector(selectBackground))
        selectionButton = createConfigButton(title: "Select Segmentation Data", action: #selector(selectSelection))
        
        // Create date sliders
        setupDateSliders()
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            backgroundButton, selectionButton,
            createSliderContainer()
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
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
    
    private func setupDateSliders() {
        startDateSlider = UISlider()
        startDateSlider.translatesAutoresizingMaskIntoConstraints = false
        startDateSlider.minimumValue = 0
        startDateSlider.maximumValue = 1
        startDateSlider.value = 0
        startDateSlider.addTarget(self, action: #selector(dateSliderChanged), for: .valueChanged)
        
        endDateSlider = UISlider()
        endDateSlider.translatesAutoresizingMaskIntoConstraints = false
        endDateSlider.minimumValue = 0
        endDateSlider.maximumValue = 1
        endDateSlider.value = 1
        endDateSlider.addTarget(self, action: #selector(dateSliderChanged), for: .valueChanged)
        
        startDateLabel = UILabel()
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateLabel.font = UIFont.systemFont(ofSize: 12)
        startDateLabel.textColor = .secondaryLabel
        
        endDateLabel = UILabel()
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        endDateLabel.font = UIFont.systemFont(ofSize: 12)
        endDateLabel.textColor = .secondaryLabel
        endDateLabel.textAlignment = .right
    }
    
    private func createSliderContainer() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let dateRangeLabel = UILabel()
        dateRangeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateRangeLabel.text = "Date Range"
        dateRangeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        
        container.addSubview(dateRangeLabel)
        container.addSubview(startDateSlider)
        container.addSubview(endDateSlider)
        container.addSubview(startDateLabel)
        container.addSubview(endDateLabel)
        
        NSLayoutConstraint.activate([
            dateRangeLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            dateRangeLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dateRangeLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            startDateSlider.topAnchor.constraint(equalTo: dateRangeLabel.bottomAnchor, constant: 8),
            startDateSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            startDateSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            endDateSlider.topAnchor.constraint(equalTo: startDateSlider.bottomAnchor, constant: 16),
            endDateSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            endDateSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            startDateLabel.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 8),
            startDateLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            startDateLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.5),
            
            endDateLabel.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 8),
            endDateLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            endDateLabel.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.5)
        ])
        
        return container
    }
    
    private func createConfigButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.contentHorizontalAlignment = .center
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }
    
    private func setupPickerView() {
        pickerContainer = UIView()
        pickerContainer.translatesAutoresizingMaskIntoConstraints = false
        pickerContainer.backgroundColor = .systemBackground
        pickerContainer.layer.cornerRadius = 12
        pickerContainer.layer.shadowColor = UIColor.black.cgColor
        pickerContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        pickerContainer.layer.shadowOpacity = 0.3
        pickerContainer.layer.shadowRadius = 4
        pickerContainer.isHidden = true
        view.addSubview(pickerContainer)
        
        pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerContainer.addSubview(pickerView)
        
        let doneButton = UIButton(type: .system)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        doneButton.addTarget(self, action: #selector(dismissPicker), for: .touchUpInside)
        pickerContainer.addSubview(doneButton)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(cancelPicker), for: .touchUpInside)
        pickerContainer.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            pickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pickerContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            pickerContainer.heightAnchor.constraint(equalToConstant: 300),
            
            pickerView.topAnchor.constraint(equalTo: pickerContainer.topAnchor, constant: 10),
            pickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -10),
            
            cancelButton.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            doneButton.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Initialization
    
    private func initializeChartConfigurations() {
        // Set allowable value object types for each configuration
        allowedValueObjTypes = [
            "xAxis": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER],
            "yAxis": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER],
            "color": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN, VOT_CHOICE],
            "background": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN, VOT_CHOICE],
            "selection": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN, VOT_CHOICE]
        ]
        
        // Initialize empty selections
        selectedValueObjIDs = [
            "xAxis": -1,
            "yAxis": -1,
            "color": -1,
            "background": -1,
            "selection": -1
        ]
        
        // Setup initial configuration based on selected chart type
        if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
            setupScatterPlotConfig()
        } else {
            setupDistributionPlotConfig()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadDateRanges() {
        guard let tracker = tracker else { return }
        
        // Get date range from tracker data
        // This would typically query the database for the earliest and latest dates
        // For now, we'll use a placeholder implementation
        
        // Example implementation to fetch date range
        let dateRange = fetchDateRange()
        earliestDate = dateRange.earliest
        latestDate = dateRange.latest
        
        selectedStartDate = earliestDate
        selectedEndDate = latestDate
        
        // Update date labels
        updateDateLabels()
        
        // Regenerate chart data if both dates are set
        if let selectedStartDate = selectedStartDate, let selectedEndDate = selectedEndDate {
            if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
                generateScatterPlotData()
            } else {
                generateDistributionPlotData()
            }
        }
    }
    
    @objc private func selectXAxis() {
        showPickerForValueObjSelection(type: "xAxis")
    }
    
    @objc private func selectYAxis() {
        showPickerForValueObjSelection(type: "yAxis")
    }
    
    @objc private func selectColor() {
        showPickerForValueObjSelection(type: "color")
    }
    
    @objc private func selectBackground() {
        showPickerForValueObjSelection(type: "background")
    }
    
    @objc private func selectSelection() {
        showPickerForValueObjSelection(type: "selection")
    }
    
    private func showPickerForValueObjSelection(type: String) {
        // Store current selection type
        currentPickerType = type
        
        // Get eligible valueObjs for this selection
        filteredValueObjs = getEligibleValueObjs(for: type)
        
        // Update picker
        pickerView.reloadAllComponents()
        
        // If a valueObj is already selected, select it in the picker
        if let selectedID = selectedValueObjIDs[type], selectedID != -1 {
            if let index = filteredValueObjs.firstIndex(where: { $0.vid == selectedID }) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        // Show picker
        pickerContainer.isHidden = false
    }
    
    @objc private func dismissPicker() {
        // Get selected row
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        
        // Update selection if valid
        if selectedRow >= 0 && selectedRow < filteredValueObjs.count {
            let selected = filteredValueObjs[selectedRow]
            selectedValueObjIDs[currentPickerType] = selected.vid
            
            // Update button title
            updateButtonTitles()
            
            // Update chart if necessary components are selected
            if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
                if selectedValueObjIDs["xAxis"] != -1 && selectedValueObjIDs["yAxis"] != -1 {
                    generateScatterPlotData()
                }
            } else {
                if selectedValueObjIDs["background"] != -1 {
                    generateDistributionPlotData()
                }
            }
        }
        
        // Hide picker
        pickerContainer.isHidden = true
    }
    
    @objc private func cancelPicker() {
        // Hide picker without saving selection
        pickerContainer.isHidden = true
    }
    
    private func updateButtonTitles() {
        // Update scatter plot button titles
        if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
            if let xID = selectedValueObjIDs["xAxis"], xID != -1 {
                let xVO = tracker?.valObjTable.first { $0.vid == xID }
                xAxisButton.setTitle(xVO?.valueName ?? "X Axis", for: .normal)
            } else {
                xAxisButton.setTitle("Select X Axis", for: .normal)
            }
            
            if let yID = selectedValueObjIDs["yAxis"], yID != -1 {
                let yVO = tracker?.valObjTable.first { $0.vid == yID }
                yAxisButton.setTitle(yVO?.valueName ?? "Y Axis", for: .normal)
            } else {
                yAxisButton.setTitle("Select Y Axis", for: .normal)
            }
            
            if let colorID = selectedValueObjIDs["color"], colorID != -1 {
                let colorVO = tracker?.valObjTable.first { $0.vid == colorID }
                colorButton.setTitle(colorVO?.valueName ?? "Color", for: .normal)
            } else {
                colorButton.setTitle("Select Color (Optional)", for: .normal)
            }
        } else {
            // Update distribution plot button titles
            if let bgID = selectedValueObjIDs["background"], bgID != -1 {
                let bgVO = tracker?.valObjTable.first { $0.vid == bgID }
                backgroundButton.setTitle(bgVO?.valueName ?? "Background Data", for: .normal)
            } else {
                backgroundButton.setTitle("Select Background Data", for: .normal)
            }
            
            if let selID = selectedValueObjIDs["selection"], selID != -1 {
                let selVO = tracker?.valObjTable.first { $0.vid == selID }
                selectionButton.setTitle(selVO?.valueName ?? "Segmentation Data", for: .normal)
            } else {
                selectionButton.setTitle("Select Segmentation Data", for: .normal)
            }
        }
    }
    
    @objc private func showPointDetails(_ sender: UITapGestureRecognizer) {
        guard let pointView = sender.view,
              let pointData = objc_getAssociatedObject(pointView, &AssociatedKeys.pointData) as? [String: Any] else {
            return
        }
        
        // Extract point data
        let x = pointData["x"] as? Double ?? 0
        let y = pointData["y"] as? Double ?? 0
        let date = pointData["date"] as? Date ?? Date()
        let colorValue = pointData["colorValue"] as? Double
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: date)
        
        // Create alert with details
        let alert = UIAlertController(
            title: "Data Point Details",
            message: """
                X: \(String(format: "%.2f", x))
                Y: \(String(format: "%.2f", y))
                Date: \(dateString)
                \(colorValue != nil ? "Color value: \(String(format: "%.2f", colorValue!))" : "")
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func dismissView() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UIPickerViewDelegate, UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filteredValueObjs.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row < filteredValueObjs.count else { return nil }
        return filteredValueObjs[row].valueName
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        guard row < filteredValueObjs.count else { return nil }
        let title = filteredValueObjs[row].valueName ?? "Unknown"
        
        // Format the title based on type
        let typeString: String
        switch filteredValueObjs[row].vtype {
        case VOT_NUMBER:
            typeString = " (Number)"
        case VOT_SLIDER:
            typeString = " (Slider)"
        case VOT_FUNC:
            typeString = " (Function)"
        case VOT_BOOLEAN:
            typeString = " (Boolean)"
        case VOT_CHOICE:
            typeString = " (Choice)"
        default:
            typeString = ""
        }
        
        let attributedTitle = NSMutableAttributedString(string: title)
        let typeAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        let typeAttribString = NSAttributedString(string: typeString, attributes: typeAttributes)
        attributedTitle.append(typeAttribString)
        
        return attributedTitle
    }
}

// For storing associated objects with UIView
private struct AssociatedKeys {
    static var pointData = "pointData"
}

// Extension to implement the database query function for date-based data
extension TrackerChart {
    
    // Helper function to fetch actual data ranges from database
    func fetchDateRange() -> (earliest: Date?, latest: Date?) {
        guard let tracker = tracker else { return (nil, nil) }
        
        // SQL query to get min and max dates from trkrData
        let sql = "SELECT MIN(date), MAX(date) FROM trkrData WHERE minpriv <= \(privacyValue)"
        
        // Execute the query using tracker's query function
        let results = tracker.toQry2Ary(sql: sql)
        
        if !results.isEmpty, let result = results.first {
            var minDate: Date? = nil
            var maxDate: Date? = nil
            
            // Get timestamps as seconds since 1970
            if let minTimestamp = result.0 as? Int64, minTimestamp > 0 {
                minDate = Date(timeIntervalSince1970: TimeInterval(minTimestamp))
            }
            
            if let maxTimestamp = result.1 as? Int64, maxTimestamp > 0 {
                maxDate = Date(timeIntervalSince1970: TimeInterval(maxTimestamp))
            }
            
            return (minDate, maxDate)
        }
        
        // Fallback to current date range if query fails
        let now = Date()
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)
        
        return (oneYearAgo, now)
    }
    
    private func updateDateLabels() {
        guard let startDate = selectedStartDate, let endDate = selectedEndDate else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        startDateLabel.text = dateFormatter.string(from: startDate)
        endDateLabel.text = dateFormatter.string(from: endDate)
    }
    
    private func getEligibleValueObjs(for configType: String) -> [valueObj] {
        guard let tracker = tracker else { return [] }
        
        // Get allowed types for this configuration
        let allowedTypes = allowedValueObjTypes[configType] ?? []
        
        // Filter valueObjs based on type and privacy
        let eligibleVOs = tracker.valObjTable.filter { vo in
            // Check if type is allowed
            guard allowedTypes.contains(vo.vtype) else { return false }
            
            // Check privacy settings (if applicable)
            // This assumes there's a property to check privacy or a way to query it
            // Implement the actual privacy check based on your data model
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
    
    // MARK: - Chart Data Generation
    
    private func generateScatterPlotData() {
        guard let tracker = tracker,
              let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate,
              selectedValueObjIDs["xAxis"] != -1,
              selectedValueObjIDs["yAxis"] != -1 else {
            noDataLabel.text = "Please select X and Y axes"
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
                } else {
                    point["color"] = nil
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
            "correlation": correlation
        ]
        
        // Render the chart
        renderScatterPlot()
    }
    
    private func generateDistributionPlotData() {
        guard let tracker = tracker,
              let selectedStartDate = selectedStartDate,
              let selectedEndDate = selectedEndDate,
              selectedValueObjIDs["background"] != -1 else {
            noDataLabel.text = "Please select background data"
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
        
        // Extract just the values for histogram
        let backgroundValues = backgroundData.map { $0.1 }
        
        // Initialize container for selection data
        var selectionData: [String: [Double]] = [:]
        
        // If selection is specified, fetch and organize by categories
        if selectionID != -1 {
            // Find the value object to determine its type
            let selectionVO = tracker.valObjTable.first { $0.vid == selectionID }
            
            if let selectionVO = selectionVO {
                if selectionVO.vtype == VOT_BOOLEAN {
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
                    
                } else if selectionVO.vtype == VOT_CHOICE {
                    // For choice, we need to handle multiple categories
                    let choiceData = fetchDataForValueObj(id: selectionID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
                    
                    // Create date lookup for choice values
                    var choiceByDate: [Date: Double] = [:]
                    for (date, value) in choiceData {
                        choiceByDate[date] = value
                    }
                    
                    // Get choice categories from votInfo
                    let choiceCategories = fetchChoiceCategories(forID: selectionID)
                    
                    // Initialize arrays for each category
                    var categoryValues: [String: [Double]] = [:]
                    for (index, label) in choiceCategories {
                        categoryValues[label] = []
                    }
                    categoryValues["no_entry"] = [] // For no data
                    
                    // Group background data by choice value
                    for (date, value) in backgroundData {
                        if let choiceValue = choiceByDate[date] {
                            let roundedValue = Int(round(choiceValue))
                            
                            // Find the matching category
                            let category = findChoiceCategory(forValue: roundedValue, inCategories: choiceCategories) ?? "unknown"
                            
                            if let _ = categoryValues[category] {
                                categoryValues[category]?.append(value)
                            } else {
                                categoryValues[category] = [value]
                            }
                        } else {
                            categoryValues["no_entry"]?.append(value)
                        }
                    }
                    
                    // Copy only non-empty categories
                    for (category, values) in categoryValues {
                        if !values.isEmpty {
                            selectionData[category] = values
                        }
                    }
                } else {
                    // For numeric types, we could create ranges or bins
                    // This is a simplified implementation - you may want to enhance it
                    let numericData = fetchDataForValueObj(id: selectionID, startTimestamp: startTimestamp, endTimestamp: endTimestamp)
                    
                    // Create date lookup for numeric values
                    var numericByDate: [Date: Double] = [:]
                    for (date, value) in numericData {
                        numericByDate[date] = value
                    }
                    
                    // For simplicity, divide into low, medium, high based on quartiles
                    if !numericData.isEmpty {
                        let values = numericData.map { $0.1 }.sorted()
                        let q1Index = values.count / 4
                        let q3Index = (values.count * 3) / 4
                        
                        let q1 = values[q1Index]
                        let q3 = values[q3Index]
                        
                        var lowValues: [Double] = []
                        var midValues: [Double] = []
                        var highValues: [Double] = []
                        var noEntryValues: [Double] = []
                        
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
                        
                        selectionData["low"] = lowValues
                        selectionData["medium"] = midValues
                        selectionData["high"] = highValues
                        selectionData["no_entry"] = noEntryValues
                    }
                }
            }
        }
        
        // Store the data for plotting
        chartData = [
            "type": "distribution",
            "backgroundValues": backgroundValues,
            "selectionData": selectionData
        ]
        
        // Render the chart
        renderDistributionPlot()
    }
    
    // MARK: - Data Fetching Helpers
    
    private func fetchDataForValueObj(id: Int, startTimestamp: Int, endTimestamp: Int) -> [(Date, Double)] {
        // This would query the database for data points
        guard id != -1, let tracker = tracker else { return [] }
        
        // Example SQL query
        let sql = """
        SELECT date, val FROM voData 
        WHERE id = \(id) AND date >= \(startTimestamp) AND date <= \(endTimestamp)
        ORDER BY date
        """
        
        // Call the function on tracker
        return tracker.toQry2AryDate(sql: sql)
    }
    
    private func fetchChoiceCategories(forID id: Int) -> [Int: String] {
        guard let tracker = tracker else { return [:] }
        
        // This would query the votInfo table for choice labels
        // Example SQL query
        let sql = """
        SELECT field, val FROM votInfo 
        WHERE id = \(id) AND field LIKE 'c%' AND val IS NOT NULL
        """
        
        var categories: [Int: String] = [:]
        
        // Check if there are custom values
        let customValuesSql = """
        SELECT field, val FROM votInfo 
        WHERE id = \(id) AND field LIKE 'cv%'
        """
        var customValues: [String: Int] = [:]
        
        // Fetch custom values
        let customValuesResults = tracker.toQry2Ary(sql: customValuesSql)
        for result in customValuesResults {
            if let field = result.0 as? String, let valStr = result.1 as? String, let val = Int(valStr) {
                // Extract index from 'cv0', 'cv1', etc.
                if let indexStr = field.dropFirst(2).first, let index = Int(String(indexStr)) {
                    customValues[field] = val
                }
            }
        }
        
        // Fetch categories
        let categoryResults = tracker.toQry2Ary(sql: sql)
        for result in categoryResults {
            if let field = result.0 as? String, let label = result.1 as? String {
                // Extract index from 'c0', 'c1', etc.
                if let indexStr = field.dropFirst(1).first, let index = Int(String(indexStr)) {
                    // Check if there's a custom value for this field
                    let value = customValues["cv\(index)"] ?? (index + 1)
                    categories[value] = label
                }
            }
        }
        
        return categories
    }
    
    private func findChoiceCategory(forValue value: Int, inCategories categories: [Int: String]) -> String? {
        return categories[value]
    }
    
    // MARK: - Rendering
    
    private func renderScatterPlot() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard let chartData = chartData as? [String: Any],
              chartData["type"] as? String == "scatter",
              let points = chartData["points"] as? [[String: Any]],
              !points.isEmpty else {
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Setup basic dimensions
        let margin: CGFloat = 40
        let graphWidth = chartView.bounds.width - 2 * margin
        let graphHeight = chartView.bounds.height - 2 * margin - 30  // Extra space for correlation
        
        // Draw axes
        let axesView = UIView(frame: chartView.bounds)
        chartView.addSubview(axesView)
        
        let xAxis = UIView(frame: CGRect(x: margin, y: margin + graphHeight, width: graphWidth, height: 1))
        xAxis.backgroundColor = .label
        axesView.addSubview(xAxis)
        
        let yAxis = UIView(frame: CGRect(x: margin, y: margin, width: 1, height: graphHeight))
        yAxis.backgroundColor = .label
        axesView.addSubview(yAxis)
        
        // Find data range
        let xValues = points.compactMap { $0["x"] as? Double }
        let yValues = points.compactMap { $0["y"] as? Double }
        let colorValues = points.compactMap { $0["color"] as? Double }
        
        guard !xValues.isEmpty, !yValues.isEmpty else { return }
        
        let minX = xValues.min() ?? 0
        let maxX = xValues.max() ?? 1
        let minY = yValues.min() ?? 0
        let maxY = yValues.max() ?? 1
        
        // Add some padding to the ranges
        let xRange = max(0.001, maxX - minX) * 1.1
        let yRange = max(0.001, maxY - minY) * 1.1
        let paddedMinX = minX - xRange * 0.05
        let paddedMaxX = maxX + xRange * 0.05
        let paddedMinY = minY - yRange * 0.05
        let paddedMaxY = maxY + yRange * 0.05
        
        // Create colorMap function if we have color data
        let useColorMap = !colorValues.isEmpty
        let minColor = colorValues.min() ?? 0
        let maxColor = colorValues.max() ?? 1
        let colorRange = max(0.001, maxColor - minColor)
        
        // Draw axis labels
        let xVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["xAxis"] }
        let yVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["yAxis"] }
        
        let xLabel = UILabel(frame: CGRect(x: margin, y: margin + graphHeight + 10, width: graphWidth, height: 20))
        xLabel.text = xVO?.valueName ?? "X Axis"
        xLabel.textAlignment = .center
        xLabel.font = UIFont.systemFont(ofSize: 12)
        axesView.addSubview(xLabel)
        
        let yLabel = UILabel()
        yLabel.text = yVO?.valueName ?? "Y Axis"
        yLabel.font = UIFont.systemFont(ofSize: 12)
        yLabel.sizeToFit()
        yLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        yLabel.center = CGPoint(x: margin - 20, y: margin + graphHeight/2)
        axesView.addSubview(yLabel)
        
        // Draw scale markers
        // X scale
        for i in 0...5 {
            let value = paddedMinX + Double(i) * (paddedMaxX - paddedMinX) / 5.0
            let x = margin + CGFloat(i) * graphWidth / 5.0
            
            let tick = UIView(frame: CGRect(x: x, y: margin + graphHeight, width: 1, height: 5))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            let label = UILabel(frame: CGRect(x: x - 25, y: margin + graphHeight + 5, width: 50, height: 15))
            label.text = String(format: "%.1f", value)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
        
        // Y scale
        for i in 0...5 {
            let value = paddedMaxY - Double(i) * (paddedMaxY - paddedMinY) / 5.0
            let y = margin + CGFloat(i) * graphHeight / 5.0
            
            let tick = UIView(frame: CGRect(x: margin - 5, y: y, width: 5, height: 1))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            let label = UILabel(frame: CGRect(x: margin - 35, y: y - 8, width: 30, height: 15))
            label.text = String(format: "%.1f", value)
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
        
        // Draw points
        let pointsContainerView = UIView(frame: chartView.bounds)
        chartView.addSubview(pointsContainerView)
        
        for point in points {
            guard let x = point["x"] as? Double,
                  let y = point["y"] as? Double else { continue }
            
            // Convert to view coordinates
            let xPos = margin + CGFloat((x - paddedMinX) / (paddedMaxX - paddedMinX)) * graphWidth
            let yPos = margin + graphHeight - CGFloat((y - paddedMinY) / (paddedMaxY - paddedMinY)) * graphHeight
            
            // Determine color
            var pointColor: UIColor = .black
            if useColorMap, let colorValue = point["color"] as? Double {
                let normalizedColorValue = (colorValue - minColor) / colorRange
                pointColor = getColorGradient(normalizedValue: normalizedColorValue)
            }
            
            // Create point view
            let pointSize: CGFloat = 8
            let pointView = UIView(frame: CGRect(x: xPos - pointSize/2, y: yPos - pointSize/2, width: pointSize, height: pointSize))
            pointView.backgroundColor = pointColor
            pointView.layer.cornerRadius = pointSize / 2
            pointsContainerView.addSubview(pointView)
            
            // Add date tooltip on tap
            if let date = point["date"] as? Date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let dateString = dateFormatter.string(from: date)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showPointDetails(_:)))
                pointView.addGestureRecognizer(tapGesture)
                pointView.isUserInteractionEnabled = true
                pointView.accessibilityLabel = "Data point: x=\(x), y=\(y), date=\(dateString)"
                
                // Store values in tag
                pointView.tag = pointsContainerView.subviews.count  // Use index as tag
                // Store the actual data in a dictionary accessible by objectForKey
                let userData = ["x": x, "y": y, "date": date, "colorValue": point["color"] as? Double ?? 0] as [String : Any]
                objc_setAssociatedObject(pointView, &AssociatedKeys.pointData, userData, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        
        // Draw correlation if available
        if let correlation = chartData["correlation"] as? Double {
            let correlationLabel = UILabel(frame: CGRect(x: margin + graphWidth - 150, y: margin - 25, width: 150, height: 20))
            correlationLabel.text = String(format: "Correlation: %.3f", correlation)
            correlationLabel.textAlignment = .right
            correlationLabel.font = UIFont.systemFont(ofSize: 12)
            correlationLabel.textColor = .secondaryLabel
            chartView.addSubview(correlationLabel)
        }
        
        // Draw color legend if needed
        if useColorMap {
            drawColorLegend(in: chartView, minValue: minColor, maxValue: maxColor)
        }
    }
    
    private func renderDistributionPlot() {
        // Clear existing content
        for subview in chartView.subviews {
            if subview != noDataLabel {
                subview.removeFromSuperview()
            }
        }
        
        guard let chartData = chartData as? [String: Any],
              chartData["type"] as? String == "distribution",
              let backgroundValues = chartData["backgroundValues"] as? [Double],
              !backgroundValues.isEmpty else {
            noDataLabel.isHidden = false
            return
        }
        
        noDataLabel.isHidden = true
        
        // Setup basic dimensions
        let margin: CGFloat = 40
        let graphWidth = chartView.bounds.width - 2 * margin
        let graphHeight = chartView.bounds.height - 2 * margin - 30
        
        // Create histogram bins
        let binCount = min(20, backgroundValues.count / 5)  // Ensure reasonable bin count
        guard binCount > 0 else { return }
        
        // Find data range
        let minValue = backgroundValues.min() ?? 0
        let maxValue = backgroundValues.max() ?? 1
        let range = max(0.001, maxValue - minValue) * 1.05
        let paddedMinValue = minValue - range * 0.025
        let paddedMaxValue = maxValue + range * 0.025
        let binWidth = (paddedMaxValue - paddedMinValue) / Double(binCount)
        
        // Create bins
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
        
        // Draw axes
        let axesView = UIView(frame: chartView.bounds)
        chartView.addSubview(axesView)
        
        let xAxis = UIView(frame: CGRect(x: margin, y: margin + graphHeight, width: graphWidth, height: 1))
        xAxis.backgroundColor = .label
        axesView.addSubview(xAxis)
        
        let yAxis = UIView(frame: CGRect(x: margin, y: margin, width: 1, height: graphHeight))
        yAxis.backgroundColor = .label
        axesView.addSubview(yAxis)
        
        // Find the maximum normalized bin value
        let maxBinValue = max(
            normalizedBackgroundBins.max() ?? 0,
            selectionBins.values.flatMap { $0 }.max() ?? 0
        )
        
        // Draw axis labels
        let backgroundVO = tracker?.valObjTable.first { $0.vid == selectedValueObjIDs["background"] }
        
        let xLabel = UILabel(frame: CGRect(x: margin, y: margin + graphHeight + 10, width: graphWidth, height: 20))
        xLabel.text = backgroundVO?.valueName ?? "Value"
        xLabel.textAlignment = .center
        xLabel.font = UIFont.systemFont(ofSize: 12)
        axesView.addSubview(xLabel)
        
        let yLabel = UILabel()
        yLabel.text = "Frequency"
        yLabel.font = UIFont.systemFont(ofSize: 12)
        yLabel.sizeToFit()
        yLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        yLabel.center = CGPoint(x: margin - 20, y: margin + graphHeight/2)
        axesView.addSubview(yLabel)
        
        // Draw scale markers
        // X scale
        for i in 0...5 {
            let value = paddedMinValue + Double(i) * (paddedMaxValue - paddedMinValue) / 5.0
            let x = margin + CGFloat(i) * graphWidth / 5.0
            
            let tick = UIView(frame: CGRect(x: x, y: margin + graphHeight, width: 1, height: 5))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            let label = UILabel(frame: CGRect(x: x - 25, y: margin + graphHeight + 5, width: 50, height: 15))
            label.text = String(format: "%.1f", value)
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
        
        // Y scale (percentage)
        for i in 0...5 {
            let percentage = (1.0 - Double(i) / 5.0) * maxBinValue * 100
            let y = margin + CGFloat(i) * graphHeight / 5.0
            
            let tick = UIView(frame: CGRect(x: margin - 5, y: y, width: 5, height: 1))
            tick.backgroundColor = .label
            axesView.addSubview(tick)
            
            let label = UILabel(frame: CGRect(x: margin - 35, y: y - 8, width: 30, height: 15))
            label.text = String(format: "%.0f%%", percentage)
            label.textAlignment = .right
            label.font = UIFont.systemFont(ofSize: 10)
            axesView.addSubview(label)
        }
        
        // Draw background histogram
        let histogramView = UIView(frame: chartView.bounds)
        chartView.addSubview(histogramView)
        
        for (index, value) in normalizedBackgroundBins.enumerated() {
            let normalizedHeight = CGFloat(value / maxBinValue)
            let barHeight = normalizedHeight * graphHeight
            let barWidth = graphWidth / CGFloat(binCount)
            
            let x = margin + CGFloat(index) * barWidth
            let y = margin + graphHeight - barHeight
            
            let barView = UIView(frame: CGRect(x: x, y: y, width: barWidth, height: barHeight))
            barView.backgroundColor = UIColor.systemGray.withAlphaComponent(0.5)
            histogramView.addSubview(barView)
        }
        
        // Draw selection lines
        let selectionView = UIView(frame: chartView.bounds)
        chartView.addSubview(selectionView)
        
        // Generate colors for each category
        let categoryCount = selectionBins.count
        var categoryColors: [String: UIColor] = [:]
        
        for (index, category) in selectionBins.keys.enumerated() {
            let normalizedValue = categoryCount > 1 ? Double(index) / Double(categoryCount - 1) : 0.5
            categoryColors[category] = getColorGradient(normalizedValue: normalizedValue)
        }
        
        // Draw category lines
        for (category, bins) in selectionBins {
            let linePath = UIBezierPath()
            let barWidth = graphWidth / CGFloat(binCount)
            
            for (index, value) in bins.enumerated() {
                let normalizedHeight = CGFloat(value / maxBinValue)
                let yPos = margin + graphHeight - normalizedHeight * graphHeight
                let xPos = margin + CGFloat(index) * barWidth + barWidth / 2
                
                if index == 0 {
                    linePath.move(to: CGPoint(x: xPos, y: yPos))
                } else {
                    linePath.addLine(to: CGPoint(x: xPos, y: yPos))
                }
            }
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = linePath.cgPath
            lineLayer.strokeColor = categoryColors[category]?.cgColor ?? UIColor.black.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            lineLayer.lineWidth = 2
            selectionView.layer.addSublayer(lineLayer)
        }
        
        // Draw legend for categories
        if !selectionBins.isEmpty {
            drawCategoryLegend(in: chartView, categories: Array(selectionBins.keys), colors: categoryColors)
        }
    }
    
    private func drawColorLegend(in view: UIView, minValue: Double, maxValue: Double) {
        let legendWidth: CGFloat = 150
        let legendHeight: CGFloat = 20
        let margin: CGFloat = 40
        
        // Create gradient view
        let gradientView = UIView(frame: CGRect(
            x: view.bounds.width - legendWidth - margin,
            y: margin,
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
    
    private func drawCategoryLegend(in view: UIView, categories: [String], colors: [String: UIColor]) {
        let legendWidth: CGFloat = 150
        let itemHeight: CGFloat = 15
        let margin: CGFloat = 40
        let padding: CGFloat = 5
        
        let legendHeight: CGFloat = CGFloat(categories.count) * (itemHeight + padding)
        
        let legendView = UIView(frame: CGRect(
            x: view.bounds.width - legendWidth - margin,
            y: margin,
            width: legendWidth,
            height: legendHeight
        ))
        legendView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        legendView.layer.cornerRadius = 5
        legendView.layer.borderWidth = 0.5
        legendView.layer.borderColor = UIColor.systemGray.cgColor
        view.addSubview(legendView)
        
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
    
    // MARK: - Utility Functions
    
    private func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double {
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
    
    private func getColorGradient(normalizedValue: Double) -> UIColor {
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
    
    // MARK: - UI Actions
    
    @objc private func chartTypeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == CHART_TYPE_SCATTER {
            setupScatterPlotConfig()
            if let chartData = chartData as? [String: Any], chartData["type"] as? String == "scatter" {
                renderScatterPlot()
            } else {
                noDataLabel.text = "Configure chart options below"
                noDataLabel.isHidden = false
            }
        } else {
            setupDistributionPlotConfig()
            if let chartData = chartData as? [String: Any], chartData["type"] as? String == "distribution" {
                renderDistributionPlot()
            } else {
                noDataLabel.text = "Configure chart options below"
                noDataLabel.isHidden = false
            }
        }
    }
    
    @objc private func dateSliderChanged(_ sender: UISlider) {
        guard let earliestDate = earliestDate, let latestDate = latestDate else { return }
        
        let timeRange = latestDate.timeIntervalSince(earliestDate)
        
        if sender == startDateSlider {
            let startInterval = TimeInterval(sender.value) * timeRange
            selectedStartDate = earliestDate.addingTimeInterval(startInterval)
        } else if sender == endDateSlider {
            let endInterval = TimeInterval(sender.value) * timeRange
            selectedEndDate = earliestDate.addingTimeInterval(endInterval)
        }
        
        updateDateLabels()
        
        // Regenerate chart data if both dates are set
        if let selectedStartDate = selectedStartDate, let selectedEndDate = selectedEndDate {
            if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
                generateScatterPlotData()
            } else {
                generateDistributionPlotData()
            }
        }
    }
}

