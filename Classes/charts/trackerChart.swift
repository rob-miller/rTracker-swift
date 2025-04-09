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
    
    // MARK: - Constants
    
    // Chart type constants
    internal let CHART_TYPE_SCATTER = 0
    internal let CHART_TYPE_DISTRIBUTION = 1
    internal let CHART_TYPE_PIE = 2
    
    // Chart layout constants
    internal let leftMargin: CGFloat = 60     // Space for y-axis labels
    internal let rightMargin: CGFloat = 40    // Consistent right margin
    internal let topMargin: CGFloat = 60      // Space for title and legends
    internal let bottomMargin: CGFloat = 40   // Space for x-axis labels
    internal let extraBottomSpace: CGFloat = 30 // Extra space for correlation text
    
    // Legend constants
    internal let legendWidth: CGFloat = 120
    internal let legendHeight: CGFloat = 20
    internal let legendRightMargin: CGFloat = 15
    internal let legendTopMargin: CGFloat = 15
    
    // MARK: - Properties
    
    // Reference to the tracker
    var tracker: trackerObj?
    
    // Main view elements
    internal var chartView: UIView!
    internal var noDataLabel: UILabel!
    internal var segmentedControl: UISegmentedControl!
    
    // Chart configuration elements
    internal var configContainer: UIView!
    
    // Scatter plot configuration
    internal var xAxisButton: UIButton!
    internal var yAxisButton: UIButton!
    internal var colorButton: UIButton!
    
    // Distribution plot configuration
    internal var backgroundButton: UIButton!
    internal var selectionButton: UIButton!
    // track legend item visibility
    internal var legendItemVisibility: [String: Bool] = [:]
    internal var saveLegendItemVisibility = false
    
    // Pie chart configuration
    internal var pieDataButton: UIButton!
    internal var showNoEntryInPieChart: Bool = true
    
    // Date range sliders
    internal var startDateSlider: UISlider!
    internal var endDateSlider: UISlider!
    internal var startDateLabel: UILabel!
    internal var endDateLabel: UILabel!
    
    // for debouncing
    internal var chartUpdateWorkItem: DispatchWorkItem?
    
    // date lock
    internal var dateRangeLockSwitch: UISwitch!
    internal var dateRangeLockIcon: UIImageView!
    
    // date slider container
    internal var sliderContainer: UIView!
    
    // Date labels
    internal var startDateTextTappable: UILabel!
    internal var endDateTextTappable: UILabel!
    internal var showStartDateAsRelative: Bool = false
    internal var showEndDateAsRelative: Bool = false
    internal var sliderHeightConstraint: NSLayoutConstraint!
    internal var sliderContainerHeightConstraint: NSLayoutConstraint!
    
    // Data selection
    internal var selectedValueObjIDs: [String: Int] = [:]
    internal var allowedValueObjTypes: [String: [Int]] = [:]
    internal var currentPickerType: String = ""
    internal var pickerView: UIPickerView!
    internal var pickerContainer: UIView!
    internal var filteredValueObjs: [valueObj] = []
    
    // Date range
    internal var earliestDate: Date?
    internal var latestDate: Date?
    internal var selectedStartDate: Date?
    internal var selectedEndDate: Date?
    
    // Chart data
    internal var chartData: [String: Any] = [:]
    
    // Axis scaling information (persisted across date range changes)
    internal var axisConfig: [String: Any] = [:] // Stores min, max values for axes
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure view
        setupView()
        
        // Set up date sliders - this should happen only once
         setupDateSliders()
        
        // Set up slider container
        setupSliderContainer()
        
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
        
        // Keep navigation bar, hide toolbar
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        loadDateRanges()
    }
    
    /*
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // This is optional - only if you want to restore the toolbar state
        // when navigating away from this screen
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    */
    // MARK: - UI Setup
    
    internal func setupView() {
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
        segmentedControl = UISegmentedControl(items: ["Scatter", "Distribution", "Pie"])
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
            chartView.heightAnchor.constraint(equalToConstant: 350), // Fixed height instead of multiplier
            
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
            xAxisButton, yAxisButton, colorButton,
            sliderContainer
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
            
            // Set a fixed height constraint for the slider container
            //sliderContainer.heightAnchor.constraint(equalToConstant: 120)  // Increased height for sliders
        ])
        
        // Update buttons with any previously selected values
        updateButtonTitles()
    }
    
    internal func setupDistributionPlotConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create buttons for Background and Selection
        backgroundButton = createConfigButton(title: "Select Background Data", action: #selector(selectBackground))
        selectionButton = createConfigButton(title: "Select Segmentation Data", action: #selector(selectSelection))
        
        // Configure layout - no longer using fillEqually distribution
        let stackView = UIStackView(arrangedSubviews: [
            backgroundButton, selectionButton,
            sliderContainer
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
            
            // Set a fixed height constraint for the slider container
            //sliderContainer.heightAnchor.constraint(equalToConstant: 120)  // Increased height for sliders
        ])
        
        // Update buttons with any previously selected values
        updateButtonTitles()
    }
    
    internal func setupPieChartConfig() {
        // Remove existing subviews
        for subview in configContainer.subviews {
            subview.removeFromSuperview()
        }
        
        // Create button for data selection
        pieDataButton = createConfigButton(title: "Select Data", action: #selector(selectPieData))
        
        // Configure layout
        let stackView = UIStackView(arrangedSubviews: [
            pieDataButton,
            sliderContainer
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
    
    internal func setupDateSliders() {
        // Create start date slider with proper interaction
        startDateSlider = UISlider()
        startDateSlider.translatesAutoresizingMaskIntoConstraints = false
        startDateSlider.minimumValue = 0
        startDateSlider.maximumValue = 1
        startDateSlider.value = 0
        startDateSlider.addTarget(self, action: #selector(dateSliderChanged), for: .valueChanged)
        startDateSlider.minimumTrackTintColor = .systemBlue
        startDateSlider.maximumTrackTintColor = .systemGray3
        startDateSlider.thumbTintColor = .systemBlue
        startDateSlider.isContinuous = true
        
        // Create end date slider with proper interaction
        endDateSlider = UISlider()
        endDateSlider.translatesAutoresizingMaskIntoConstraints = false
        endDateSlider.minimumValue = 0
        endDateSlider.maximumValue = 1
        endDateSlider.value = 1
        endDateSlider.addTarget(self, action: #selector(dateSliderChanged), for: .valueChanged)
        endDateSlider.minimumTrackTintColor = .systemBlue
        endDateSlider.maximumTrackTintColor = .systemGray3
        endDateSlider.thumbTintColor = .systemBlue
        endDateSlider.isContinuous = true

        // Original labels (kept for compatibility)
        startDateLabel = UILabel()
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateLabel.font = UIFont.systemFont(ofSize: 12)
        startDateLabel.textColor = .secondaryLabel
        
        endDateLabel = UILabel()
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        endDateLabel.font = UIFont.systemFont(ofSize: 12)
        endDateLabel.textColor = .secondaryLabel
        endDateLabel.textAlignment = .right
        
        // Add tappable text labels for showing date or days ago
        startDateTextTappable = UILabel()
        startDateTextTappable.translatesAutoresizingMaskIntoConstraints = false
        startDateTextTappable.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        startDateTextTappable.textColor = .label
        startDateTextTappable.text = "Start Date" // Default text until dates are loaded
        startDateTextTappable.isUserInteractionEnabled = true
        startDateTextTappable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleStartDateFormat)))
        
        endDateTextTappable = UILabel()
        endDateTextTappable.translatesAutoresizingMaskIntoConstraints = false
        endDateTextTappable.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        endDateTextTappable.textColor = .label
        endDateTextTappable.text = "End Date" // Default text until dates are loaded
        endDateTextTappable.textAlignment = .right
        endDateTextTappable.isUserInteractionEnabled = true
        endDateTextTappable.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleEndDateFormat)))
        /*
        // Add visual indicator that these labels are tappable
        startDateTextTappable.layer.cornerRadius = 8
        startDateTextTappable.layer.borderWidth = 1.0
        startDateTextTappable.layer.borderColor = UIColor.systemGray4.cgColor
        startDateTextTappable.clipsToBounds = true
        startDateTextTappable.backgroundColor = .systemBackground
        startDateTextTappable.textAlignment = .center
        
        endDateTextTappable.layer.cornerRadius = 8
        endDateTextTappable.layer.borderWidth = 1.0
        endDateTextTappable.layer.borderColor = UIColor.systemGray4.cgColor
        endDateTextTappable.clipsToBounds = true
        endDateTextTappable.backgroundColor = .systemBackground
        endDateTextTappable.textAlignment = .center
        */
    }

    internal func setupSliderContainer() {
        sliderContainer = UIView()
        sliderContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let dateRangeLabel = UILabel()
        dateRangeLabel.translatesAutoresizingMaskIntoConstraints = false
        dateRangeLabel.text = "Date Range"
        dateRangeLabel.font = UIFont.boldSystemFont(ofSize: 14)
        
        // Create lock icon
        dateRangeLockIcon = UIImageView(image: UIImage(systemName: "lock"))
        dateRangeLockIcon.translatesAutoresizingMaskIntoConstraints = false
        dateRangeLockIcon.tintColor = .secondaryLabel
        dateRangeLockIcon.contentMode = .scaleAspectFit
        dateRangeLockIcon.alpha = 0.5 // Greyed out initially
        
        // Create lock switch
        dateRangeLockSwitch = UISwitch()
        dateRangeLockSwitch.translatesAutoresizingMaskIntoConstraints = false
        dateRangeLockSwitch.isOn = false
        dateRangeLockSwitch.isEnabled = false // Disabled initially
        dateRangeLockSwitch.addTarget(self, action: #selector(dateRangeLockChanged), for: .valueChanged)
        
        sliderContainer.addSubview(dateRangeLabel)
        sliderContainer.addSubview(dateRangeLockIcon)
        sliderContainer.addSubview(dateRangeLockSwitch)
        sliderContainer.addSubview(startDateSlider)
        sliderContainer.addSubview(endDateSlider)
        //sliderContainer.addSubview(startDateLabel)
        //sliderContainer.addSubview(endDateLabel)
        sliderContainer.addSubview(startDateTextTappable)
        sliderContainer.addSubview(endDateTextTappable)
        
        /*
        // Add these lines to highlight the sliderContainer for debugging
        sliderContainer.layer.borderWidth = 2.0
        sliderContainer.layer.borderColor = UIColor.red.cgColor
        sliderContainer.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
        */

        NSLayoutConstraint.activate([
            dateRangeLabel.topAnchor.constraint(equalTo: sliderContainer.topAnchor, constant: 8),
            dateRangeLabel.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            
            // Position lock icon
            dateRangeLockIcon.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeLockIcon.trailingAnchor.constraint(equalTo: dateRangeLockSwitch.leadingAnchor, constant: -8),
            dateRangeLockIcon.widthAnchor.constraint(equalToConstant: 16),
            dateRangeLockIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Position lock switch
            dateRangeLockSwitch.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeLockSwitch.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            // Increase the spacing between elements
            //startDateSlider.topAnchor.constraint(equalTo: startDateTextTappable.bottomAnchor, constant: 10),
            startDateSlider.topAnchor.constraint(equalTo: dateRangeLockSwitch.bottomAnchor, constant: 10),
            startDateSlider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            startDateSlider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            // Increase the spacing between sliders
            endDateSlider.topAnchor.constraint(equalTo: startDateSlider.bottomAnchor, constant: 15),
            endDateSlider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            endDateSlider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            
            // Position start date tappable label
            //startDateTextTappable.topAnchor.constraint(equalTo: dateRangeLabel.bottomAnchor, constant: 12),
            startDateTextTappable.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 12),

            startDateTextTappable.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            startDateTextTappable.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.45),
            startDateTextTappable.heightAnchor.constraint(equalToConstant: 30),
            
            // Position end date tappable label
            //endDateTextTappable.topAnchor.constraint(equalTo: dateRangeLabel.bottomAnchor, constant: 12),
            endDateTextTappable.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 12),
            endDateTextTappable.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            endDateTextTappable.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.45),
            endDateTextTappable.heightAnchor.constraint(equalToConstant: 30),
            
            /*
            // Position original labels below sliders
            startDateLabel.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 8),
            startDateLabel.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            startDateLabel.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.5),
            
            endDateLabel.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 8),
            endDateLabel.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            endDateLabel.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.5),
            */
            
            //sliderContainer.bottomAnchor.constraint(equalTo: endDateLabel.bottomAnchor, constant: 10)
            sliderContainer.bottomAnchor.constraint(equalTo: endDateTextTappable.bottomAnchor, constant: 10)
        ])

    }
    
    // Add new methods to toggle between date formats
    @objc internal func toggleStartDateFormat(_ sender: UITapGestureRecognizer) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Flash animation to indicate tap was recognized
        UIView.animate(withDuration: 0.1, animations: {
            self.startDateTextTappable.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startDateTextTappable.alpha = 1.0
            }
        }
        
        showStartDateAsRelative.toggle()
        updateDateLabels()
    }

    @objc internal func toggleEndDateFormat(_ sender: UITapGestureRecognizer) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Flash animation to indicate tap was recognized
        UIView.animate(withDuration: 0.1, animations: {
            self.endDateTextTappable.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.endDateTextTappable.alpha = 1.0
            }
        }
        
        showEndDateAsRelative.toggle()
        updateDateLabels()
    }
    
    internal func createConfigButton(title: String, action: Selector) -> UIButton {
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
    
    internal func setupPickerView() {
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
    
    internal func initializeChartConfigurations() {
        // Set allowable value object types for each configuration
        allowedValueObjTypes = [
            "xAxis": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER],
            "yAxis": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER],
            "color": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN, VOT_CHOICE],
            "background": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_CHOICE],
            "selection": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN, VOT_CHOICE],
            "pieData": [VOT_BOOLEAN, VOT_CHOICE]
        ]
        
        // Initialize empty selections
        selectedValueObjIDs = [
            "xAxis": -1,
            "yAxis": -1,
            "color": -1,
            "background": -1,
            "selection": -1,
            "pieData": -1
        ]
        
        // Setup initial configuration based on selected chart type
        if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
            setupScatterPlotConfig()
        } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION {
            setupDistributionPlotConfig()
        } else {
            setupPieChartConfig()
        }
    }
    
      @objc internal func selectXAxis() {
          showPickerForValueObjSelection(type: "xAxis")
      }
      
      @objc internal func selectYAxis() {
          showPickerForValueObjSelection(type: "yAxis")
      }
      
      @objc internal func selectColor() {
          showPickerForValueObjSelection(type: "color")
      }
      
      @objc internal func selectBackground() {
          showPickerForValueObjSelection(type: "background")
      }
      
      @objc internal func selectSelection() {
          showPickerForValueObjSelection(type: "selection")
      }
      
      @objc internal func selectPieData() {
          showPickerForValueObjSelection(type: "pieData")
      }
      
      internal func showPickerForValueObjSelection(type: String) {
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
      
    @objc internal func dismissPicker() {
        // Get selected row
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        
        // Update selection if valid
        if selectedRow >= 0 && selectedRow < filteredValueObjs.count {
            let selected = filteredValueObjs[selectedRow]
            let previousSelection = selectedValueObjIDs[currentPickerType]
            selectedValueObjIDs[currentPickerType] = selected.vid
            
            // Update button title
            updateButtonTitles()
            
            // Update chart if necessary components are selected
            if segmentedControl.selectedSegmentIndex == CHART_TYPE_SCATTER {
                if selectedValueObjIDs["xAxis"] != -1 && selectedValueObjIDs["yAxis"] != -1 {
                    // Check if we're changing a fundamental axis, and if so, clear the axis config
                    if currentPickerType == "xAxis" && previousSelection != selected.vid {
                        axisConfig.removeValue(forKey: "xAxis")
                        analyzeScatterData() // Recalculate axis scales with full data range
                    } else if currentPickerType == "yAxis" && previousSelection != selected.vid {
                        axisConfig.removeValue(forKey: "yAxis")
                        analyzeScatterData() // Recalculate axis scales with full data range
                    } else {
                        generateScatterPlotData() // Just update with current config
                    }
                }
            } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION {
                if selectedValueObjIDs["background"] != -1 {
                    if currentPickerType == "background" && previousSelection != selected.vid {
                        axisConfig.removeValue(forKey: "background")  // cause full chart reset
                        saveLegendItemVisibility = true  // but keep choices for segmented data shown
                    }
                    generateDistributionPlotData()
                }
            } else {
                if selectedValueObjIDs["pieData"] != -1 {
                    generatePieChartData()
                }
            }
        }
        
        // Hide picker
        pickerContainer.isHidden = true
    }
      
      @objc internal func cancelPicker() {
          // Hide picker without saving selection
          pickerContainer.isHidden = true
      }
      

    internal func updateButtonTitles() {
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
        } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION {
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
        } else {
            // Update pie chart button title
            if let pieID = selectedValueObjIDs["pieData"], pieID != -1 {
                let pieVO = tracker?.valObjTable.first { $0.vid == pieID }
                pieDataButton.setTitle(pieVO?.valueName ?? "Data", for: .normal)
            } else {
                pieDataButton.setTitle("Select Data", for: .normal)
            }
        }
    }
    
    internal struct AssociatedKeys {
        // Static objects to use as unique keys
        static let pointDataKey = NSString("pointDataKey")
        static let legendCategoryKey = NSString("legendCategoryKey")
        
        // Use these directly, no need for & prefix
        static var pointData: UnsafeRawPointer {
            return UnsafeRawPointer(Unmanaged.passUnretained(pointDataKey).toOpaque())
        }
        static var legendCategory: UnsafeRawPointer {
            return UnsafeRawPointer(Unmanaged.passUnretained(legendCategoryKey).toOpaque())
        }
    }
    // Use:
    // objc_setAssociatedObject(lineLayer, AssociatedKeys.legendCategory, category, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

    // And when getting:
    // objc_getAssociatedObject(lineLayer, AssociatedKeys.legendCategory) as? String
     
    
    @objc internal func showPointDetails(_ sender: UITapGestureRecognizer) {
        /*
        guard let pointView = sender.view,
              let pointData = objc_getAssociatedObject(pointView, &AssociatedKeys.pointData) as? [String: Any] else {
            return
        }
         */
        
        guard let pointView = sender.view,
              let pointData = objc_getAssociatedObject(pointView, AssociatedKeys.pointData) as? [String: Any] else {
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
    
    @objc internal func dismissView() {
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
internal struct AssociatedKeys {
    static var pointData = "pointData"
}


extension TrackerChart {
    
 
    // Update date labels with current date values
    internal func updateDateLabels() {
        // Set default dates if not set yet
        if selectedStartDate == nil || selectedEndDate == nil {
            let now = Date()
            let calendar = Calendar.current
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            
            selectedStartDate = selectedStartDate ?? oneMonthAgo
            selectedEndDate = selectedEndDate ?? now
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        // Create calendar for date component calculations
        let calendar = Calendar.current
        //let now = Date()
        
        // Set start date to beginning of day (00:00)
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedStartDate!)
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        let startOfDay = calendar.date(from: startComponents) ?? selectedStartDate!
        
        // Set end date to end of day (23:59)
        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedEndDate!)
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        let endOfDay = calendar.date(from: endComponents) ?? selectedEndDate!
        
        // Update the actual dates being used
        selectedStartDate = startOfDay
        selectedEndDate = endOfDay
        
        // Format the dates
        let startDateStr = dateFormatter.string(from: startOfDay)
        let endDateStr = dateFormatter.string(from: endOfDay)
        
        // Calculate days ago using start of day for both dates
        let endStartOfDay = calendar.startOfDay(for: endOfDay)
        let nowStartOfDay = calendar.startOfDay(for: Date())
        
        let startDaysComponents = calendar.dateComponents([.day], from: calendar.startOfDay(for: startOfDay), to: nowStartOfDay)
        let endDaysComponents = calendar.dateComponents([.day], from: endStartOfDay, to: nowStartOfDay)
        
        let startDaysAgo = startDaysComponents.day ?? 0
        let endDaysAgo = endDaysComponents.day ?? 0
        
        // Add visual feedback when labels are tapped
        UIView.animate(withDuration: 0.2) {
            // Update the tappable labels with appropriate format
            if self.showStartDateAsRelative {
                self.startDateTextTappable.text = self.formatDaysAgo(startDaysAgo)
            } else {
                self.startDateTextTappable.text = startDateStr
            }
            
            if self.showEndDateAsRelative {
                self.endDateTextTappable.text = self.formatDaysAgo(endDaysAgo)
            } else {
                self.endDateTextTappable.text = endDateStr
            }
        }
        
        // Keep original labels updated for compatibility (though they're hidden)
        startDateLabel.text = startDateStr
        endDateLabel.text = endDateStr
    }
   
    // MARK: - Utility Functions

    internal func formatDaysAgo(_ days: Int) -> String {
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day ago"
        }
        return "\(days) days ago"
    }

    // MARK: - UI Actions
    
    @objc internal func chartTypeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == CHART_TYPE_SCATTER {
            setupScatterPlotConfig()
            
            // Check if X and Y axes are selected for scatter plot
            if selectedValueObjIDs["xAxis"] != -1 && selectedValueObjIDs["yAxis"] != -1 {
                if axisConfig["xAxis"] == nil || axisConfig["yAxis"] == nil {
                    analyzeScatterData()
                } else {
                    // Ensure we're using the current date range
                    generateScatterPlotData()
                }
            } else {
                // Clear the chart and show instruction
                for subview in chartView.subviews {
                    if subview != noDataLabel {
                        subview.removeFromSuperview()
                    }
                }
                noDataLabel.text = "Configure chart options below"
                noDataLabel.isHidden = false
            }
        } else if sender.selectedSegmentIndex == CHART_TYPE_DISTRIBUTION {
            setupDistributionPlotConfig()
            
            // Check if background data is selected for distribution plot
            if selectedValueObjIDs["background"] != -1 {
                if axisConfig["background"] == nil {
                    analyzeDistributionData()
                } else {
                    // Ensure we're using the current date range
                    generateDistributionPlotData()
                }
            } else {
                // Clear the chart and show instruction
                for subview in chartView.subviews {
                    if subview != noDataLabel {
                        subview.removeFromSuperview()
                    }
                }
                noDataLabel.text = "Configure chart options below"
                noDataLabel.isHidden = false
            }
        } else {
            setupPieChartConfig()
            
            // Check if pie data is selected
            if selectedValueObjIDs["pieData"] != -1 {
                generatePieChartData()
            } else {
                // Clear the chart and show instruction
                for subview in chartView.subviews {
                    if subview != noDataLabel {
                        subview.removeFromSuperview()
                    }
                }
                noDataLabel.text = "Configure chart options below"
                noDataLabel.isHidden = false
            }
        }
        
        // Make sure date labels are updated
        updateDateLabels()
    }
    
    @objc internal func dateRangeLockChanged(_ sender: UISwitch) {
        // The lock state can be accessed via dateRangeLockSwitch.isOn
        // You might want to update UI or behavior when lock is toggled
    }
    
    @objc internal func dateSliderChanged(_ sender: UISlider) {
        // If we don't have date ranges yet, use default range of last year
        if earliestDate == nil || latestDate == nil {
            let now = Date()
            let calendar = Calendar.current
            earliestDate = calendar.date(byAdding: .year, value: -1, to: now)
            latestDate = now
        }
        
        guard let earliestDate = earliestDate, let latestDate = latestDate else { return }
        
        let timeRange = max(1.0, latestDate.timeIntervalSince(earliestDate)) // Ensure non-zero range
        let calendar = Calendar.current
        
        // Store previous dates for lock mode calculations
        let previousStartDate = selectedStartDate
        let previousEndDate = selectedEndDate
        
        // Calculate the previous date range in days
        var daysBetweenDates = 0
        if let start = previousStartDate, let end = previousEndDate {
            daysBetweenDates = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        }
        
        // Update dates based on slider values and lock state
        if sender == startDateSlider {
            // Calculate new start date
            let startInterval = TimeInterval(sender.value) * timeRange
            selectedStartDate = earliestDate.addingTimeInterval(startInterval)
            
            if dateRangeLockSwitch.isOn {
                // Lock mode: Keep date range constant
                if let startDate = selectedStartDate {
                    // Move end date to maintain fixed range
                    selectedEndDate = calendar.date(byAdding: .day, value: daysBetweenDates, to: startDate)
                    
                    // Update end slider position
                    if let endDate = selectedEndDate {
                        let endInterval = endDate.timeIntervalSince(earliestDate)
                        let normalizedEndValue = Float(min(1.0, endInterval / timeRange))
                        endDateSlider.value = normalizedEndValue
                        
                        // Ensure end date doesn't exceed latest date
                        if endDate > latestDate {
                            // Adjust both sliders to respect the boundary
                            selectedEndDate = latestDate
                            endDateSlider.value = 1.0
                            
                            // Adjust start date back by daysBetweenDates
                            selectedStartDate = calendar.date(byAdding: .day, value: -daysBetweenDates, to: latestDate)
                            let adjustedStartInterval = selectedStartDate!.timeIntervalSince(earliestDate)
                            startDateSlider.value = Float(max(0.0, min(1.0, adjustedStartInterval / timeRange)))
                        }
                    }
                }
            } else {
                // Unlocked mode: Ensure start date is not after end date - 1 day
                if let endDate = selectedEndDate, let startDate = selectedStartDate {
                    // Minimum 1 day between dates
                    let minEndDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
                    
                    if endDate < minEndDate {
                        // Push end date forward
                        selectedEndDate = minEndDate
                        let endInterval = minEndDate.timeIntervalSince(earliestDate)
                        endDateSlider.value = Float(min(1.0, endInterval / timeRange))
                    }
                }
            }
        } else if sender == endDateSlider {
            // Calculate new end date
            let endInterval = TimeInterval(sender.value) * timeRange
            selectedEndDate = earliestDate.addingTimeInterval(endInterval)
            
            if dateRangeLockSwitch.isOn {
                // Lock mode: Keep date range constant
                if let endDate = selectedEndDate {
                    // Move start date to maintain fixed range
                    selectedStartDate = calendar.date(byAdding: .day, value: -daysBetweenDates, to: endDate)
                    
                    // Update start slider position
                    if let startDate = selectedStartDate {
                        let startInterval = startDate.timeIntervalSince(earliestDate)
                        let normalizedStartValue = Float(max(0.0, startInterval / timeRange))
                        startDateSlider.value = normalizedStartValue
                        
                        // Ensure start date doesn't go below earliest date
                        if startDate < earliestDate {
                            // Adjust both sliders to respect the boundary
                            selectedStartDate = earliestDate
                            startDateSlider.value = 0.0
                            
                            // Adjust end date forward by daysBetweenDates
                            selectedEndDate = calendar.date(byAdding: .day, value: daysBetweenDates, to: earliestDate)
                            let adjustedEndInterval = selectedEndDate!.timeIntervalSince(earliestDate)
                            endDateSlider.value = Float(min(1.0, adjustedEndInterval / timeRange))
                        }
                    }
                }
            } else {
                // Unlocked mode: Ensure end date is not before start date + 1 day
                if let startDate = selectedStartDate, let endDate = selectedEndDate {
                    // Minimum 1 day between dates
                    let minStartDate = calendar.date(byAdding: .day, value: -1, to: endDate) ?? endDate
                    
                    if startDate > minStartDate {
                        // Push start date backward
                        selectedStartDate = minStartDate
                        let startInterval = minStartDate.timeIntervalSince(earliestDate)
                        startDateSlider.value = Float(max(0.0, startInterval / timeRange))
                    }
                }
            }
        }
        
        // Check if we should enable or disable the lock switch
        updateLockSwitchState()
        
        // Update the date labels
        updateDateLabels()
        
        // Use a debounced update for chart data to prevent performance issues during sliding
        // Remove the tracking check - now we update during sliding too
        updateChartDataWithDebounce()
    }

    // Add this method for debounced updates
    internal func updateChartDataWithDebounce() {
        // Cancel any existing work item
        chartUpdateWorkItem?.cancel()
        
        // Create a new work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Update the chart based on current selection
                if self.segmentedControl.selectedSegmentIndex == self.CHART_TYPE_SCATTER {
                    self.generateScatterPlotData()
                } else if self.segmentedControl.selectedSegmentIndex == self.CHART_TYPE_DISTRIBUTION {
                    self.saveLegendItemVisibility = true  // keep choices for just date range change
                    self.generateDistributionPlotData()
                } else {
                    self.generatePieChartData()
                }
            }
        }
        
        // Store reference to new work item
        chartUpdateWorkItem = workItem
        
        // Schedule the work item to execute after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    internal func updateLockSwitchState() {
        // Check if either slider is not at the extreme
        let startNotAtMin = startDateSlider.value > 0.001 // Allow for floating point imprecision
        let endNotAtMax = endDateSlider.value < 0.999 // Allow for floating point imprecision
        
        // Enable the switch if date range is not covering full data range
        let shouldEnable = startNotAtMin || endNotAtMax
        
        // Only update if state is changing
        if dateRangeLockSwitch.isEnabled != shouldEnable {
            dateRangeLockSwitch.isEnabled = shouldEnable
            
            // Update icon appearance
            UIView.animate(withDuration: 0.3) {
                self.dateRangeLockIcon.alpha = shouldEnable ? 1.0 : 0.5
            }
        }
    }
        

        
}
