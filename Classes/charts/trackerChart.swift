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
    internal let CHART_TYPE_DISTRIBUTION = 0
    internal let CHART_TYPE_TIME = 1
    internal let CHART_TYPE_SCATTER = 2
    internal let CHART_TYPE_PIE = 3
    
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
    
    internal let TAG_LEGEND_VIEW = 5001
    internal let TAG_LEGEND_TITLE = 5002
    
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
    // For toggling between average and count display in distribution charts
    internal var showStatCounts: Bool = false
    
    // Pie chart configuration
    internal var pieDataButton: UIButton!
    internal var showNoEntryInPieChart: Bool = true
    
    // Add time chart specific properties
    // Time chart configuration
    internal var timeSource1Button: UIButton!
    internal var timeSource2Button: UIButton!
    internal var timeSource3Button: UIButton!
    internal var timeSource4Button: UIButton!
    //internal var clearTimeSourceButton: UIButton!
    
    internal var timeChartSources: [Int] = [-1, -1, -1, -1]  // Up to 4 data sources for time chart
    internal var selectedYAxisMode: Int = 0  // To cycle through different axis modes when tapped
    internal var showValueLabels: Bool = false  // Toggle value labels
    internal var currentYAxisView: UIView?  // To track current y-axis view for tapping
    
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
    
    // Entry count label
    internal var entryCountLabel: UILabel!
    
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
    
    // zoom switch and slider
    internal var dateRangeZoomSwitch: UISwitch!
    internal var dateRangeZoomIcon: UIImageView!
    internal var dateRangeZoomSlider: UISlider!
    internal var zoomedEarliestDate: Date? // The zoomed earliest date
    internal var isDateRangeZoomed: Bool = false // Track the zoom state
    internal var dateRangeZoomContainer: UIView! // Container for zoom slider
    
    
    // recent data indicator button and state
    internal var recentDataIndicatorButton: UIButton!
    internal var recentDataIndicatorState: Int = 0 // 0=off, 1=last, 2=minus1, 3=minus2
    
    // height constraint property
    internal var zoomContainerHeightConstraint: NSLayoutConstraint!
    // track whether zoom is applied (separate from UI visibility)
    internal var isZoomActive: Bool = false
    
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
        segmentedControl = UISegmentedControl(items: ["Distribution", "Time", "Scatter", "Pie"])
        segmentedControl.selectedSegmentIndex = CHART_TYPE_DISTRIBUTION
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
        
        // Create recent data indicator button
        recentDataIndicatorButton = UIButton(type: .system)
        recentDataIndicatorButton.translatesAutoresizingMaskIntoConstraints = false
        recentDataIndicatorButton.setTitle("○", for: .normal)
        recentDataIndicatorButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        recentDataIndicatorButton.tintColor = .systemBlue
        recentDataIndicatorButton.addTarget(self, action: #selector(recentDataIndicatorTapped), for: .touchUpInside)
        
        // Create zoom icon
        dateRangeZoomIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        dateRangeZoomIcon.translatesAutoresizingMaskIntoConstraints = false
        dateRangeZoomIcon.tintColor = .secondaryLabel
        dateRangeZoomIcon.contentMode = .scaleAspectFit
        dateRangeZoomIcon.alpha = 0.5 // Greyed out initially
        
        // Create zoom switch
        dateRangeZoomSwitch = UISwitch()
        dateRangeZoomSwitch.translatesAutoresizingMaskIntoConstraints = false
        dateRangeZoomSwitch.isOn = false
        dateRangeZoomSwitch.addTarget(self, action: #selector(dateRangeZoomChanged), for: .valueChanged)
        
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
        
        // Create entry count label
        entryCountLabel = UILabel()
        entryCountLabel.translatesAutoresizingMaskIntoConstraints = false
        entryCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        entryCountLabel.textColor = .secondaryLabel
        entryCountLabel.textAlignment = .center
        
        
        // Create a special container just for the configurable elements
        let configControlsContainer = UIView()
        configControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        sliderContainer.addSubview(configControlsContainer)
        
        
        sliderContainer.addSubview(dateRangeLabel)
        sliderContainer.addSubview(recentDataIndicatorButton)
        sliderContainer.addSubview(dateRangeZoomIcon)
        sliderContainer.addSubview(dateRangeZoomSwitch)
        sliderContainer.addSubview(dateRangeLockIcon)
        sliderContainer.addSubview(dateRangeLockSwitch)
        sliderContainer.addSubview(startDateSlider)
        sliderContainer.addSubview(endDateSlider)
        sliderContainer.addSubview(startDateTextTappable)
        sliderContainer.addSubview(endDateTextTappable)
        sliderContainer.addSubview(entryCountLabel)
        
        
        
        
        // Create zoom range slider container (hidden initially)
        dateRangeZoomContainer = UIView()
        dateRangeZoomContainer.translatesAutoresizingMaskIntoConstraints = false
        dateRangeZoomContainer.isHidden = true
        //sliderContainer.addSubview(dateRangeZoomContainer)

        // Add the dynamic elements to the config container
        configControlsContainer.addSubview(dateRangeZoomContainer)
        
        // Create zoom slider
        dateRangeZoomSlider = UISlider()
        dateRangeZoomSlider.translatesAutoresizingMaskIntoConstraints = false
        dateRangeZoomSlider.minimumValue = 0
        dateRangeZoomSlider.maximumValue = 1
        dateRangeZoomSlider.value = 0
        dateRangeZoomSlider.addTarget(self, action: #selector(zoomSliderChanged), for: .valueChanged)
        dateRangeZoomSlider.minimumTrackTintColor = .systemOrange
        dateRangeZoomSlider.maximumTrackTintColor = .systemGray3
        dateRangeZoomSlider.thumbTintColor = .systemOrange
        dateRangeZoomContainer.addSubview(dateRangeZoomSlider)
        
        // Label for zoom slider
        let zoomSliderLabel = UILabel()
        zoomSliderLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomSliderLabel.text = "Start Date Offset"
        zoomSliderLabel.font = UIFont.systemFont(ofSize: 12)
        zoomSliderLabel.textColor = .secondaryLabel
        dateRangeZoomContainer.addSubview(zoomSliderLabel)

        
        // Create zoom container height constraint
        zoomContainerHeightConstraint = dateRangeZoomContainer.heightAnchor.constraint(equalToConstant: 0)
        zoomContainerHeightConstraint.isActive = true // Initially collapsed
        
        /*
         // Add these lines to highlight the sliderContainer for debugging
         sliderContainer.layer.borderWidth = 2.0
         sliderContainer.layer.borderColor = UIColor.red.cgColor
         sliderContainer.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
         */
        
        // Create constraints with proper priority for zoom container
        let zoomLabelTopConstraint = zoomSliderLabel.topAnchor.constraint(equalTo: dateRangeZoomContainer.topAnchor)
        zoomLabelTopConstraint.priority = UILayoutPriority(999) // Just below required
        
        let zoomSliderTopConstraint = dateRangeZoomSlider.topAnchor.constraint(equalTo: zoomSliderLabel.bottomAnchor, constant: 4)
        zoomSliderTopConstraint.priority = UILayoutPriority(999)
        
        let zoomSliderBottomConstraint = dateRangeZoomSlider.bottomAnchor.constraint(equalTo: dateRangeZoomContainer.bottomAnchor, constant: -4)
        zoomSliderBottomConstraint.priority = UILayoutPriority(999)
        
        NSLayoutConstraint.activate([
            dateRangeLabel.topAnchor.constraint(equalTo: sliderContainer.topAnchor, constant: 8),
            dateRangeLabel.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            
            // Position lock switch (right justified)
            dateRangeLockSwitch.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeLockSwitch.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            // Position lock icon
            dateRangeLockIcon.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeLockIcon.trailingAnchor.constraint(equalTo: dateRangeLockSwitch.leadingAnchor, constant: -8),
            dateRangeLockIcon.widthAnchor.constraint(equalToConstant: 16),
            dateRangeLockIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Position zoom switch next to lock icon
            dateRangeZoomSwitch.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeZoomSwitch.trailingAnchor.constraint(equalTo: dateRangeLockIcon.leadingAnchor, constant: -16),
            
            // Position zoom icon next to zoom switch
            dateRangeZoomIcon.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            dateRangeZoomIcon.trailingAnchor.constraint(equalTo: dateRangeZoomSwitch.leadingAnchor, constant: -8),
            dateRangeZoomIcon.widthAnchor.constraint(equalToConstant: 16),
            dateRangeZoomIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Position recent data indicator button to the left of zoom icon
            recentDataIndicatorButton.centerYAnchor.constraint(equalTo: dateRangeLabel.centerYAnchor),
            recentDataIndicatorButton.trailingAnchor.constraint(equalTo: dateRangeZoomIcon.leadingAnchor, constant: -16),
            recentDataIndicatorButton.widthAnchor.constraint(equalToConstant: 24),
            recentDataIndicatorButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Regular date sliders - position after the header
            startDateSlider.topAnchor.constraint(equalTo: dateRangeLockSwitch.bottomAnchor, constant: 10),
            startDateSlider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            startDateSlider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            endDateSlider.topAnchor.constraint(equalTo: startDateSlider.bottomAnchor, constant: 15),
            endDateSlider.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            endDateSlider.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            
            // Position start date tappable label
            startDateTextTappable.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 12),
            startDateTextTappable.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            startDateTextTappable.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.45),
            startDateTextTappable.heightAnchor.constraint(equalToConstant: 30),
            
            // Position end date tappable label
            endDateTextTappable.topAnchor.constraint(equalTo: endDateSlider.bottomAnchor, constant: 12),
            endDateTextTappable.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            endDateTextTappable.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.45),
            endDateTextTappable.heightAnchor.constraint(equalToConstant: 30),
            
            // Position entry count label between start and end date labels
            entryCountLabel.centerXAnchor.constraint(equalTo: sliderContainer.centerXAnchor),
            entryCountLabel.centerYAnchor.constraint(equalTo: startDateTextTappable.centerYAnchor),
            entryCountLabel.widthAnchor.constraint(equalTo: sliderContainer.widthAnchor, multiplier: 0.3),
            entryCountLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // Config container starts after the date labels
            configControlsContainer.topAnchor.constraint(equalTo: startDateTextTappable.bottomAnchor, constant: 12),
            configControlsContainer.leadingAnchor.constraint(equalTo: sliderContainer.leadingAnchor),
            configControlsContainer.trailingAnchor.constraint(equalTo: sliderContainer.trailingAnchor),
            configControlsContainer.bottomAnchor.constraint(equalTo: sliderContainer.bottomAnchor),
            
            // Position zoom container inside the config container
            dateRangeZoomContainer.topAnchor.constraint(equalTo: configControlsContainer.topAnchor),
            dateRangeZoomContainer.leadingAnchor.constraint(equalTo: configControlsContainer.leadingAnchor),
            dateRangeZoomContainer.trailingAnchor.constraint(equalTo: configControlsContainer.trailingAnchor),
            // Height constraint is managed separately
            
            // Zoom slider and label constraints (lower priority to avoid conflicts when collapsed)
            zoomLabelTopConstraint,
            zoomSliderLabel.leadingAnchor.constraint(equalTo: dateRangeZoomContainer.leadingAnchor),
            
            zoomSliderTopConstraint,
            dateRangeZoomSlider.leadingAnchor.constraint(equalTo: dateRangeZoomContainer.leadingAnchor),
            dateRangeZoomSlider.trailingAnchor.constraint(equalTo: dateRangeZoomContainer.trailingAnchor),
            zoomSliderBottomConstraint,
            
            // Make the container bottom anchor depend on the zoom container visibility
            sliderContainer.bottomAnchor.constraint(equalTo: dateRangeZoomContainer.bottomAnchor, constant: 10)
        ])
        
    }

    @objc internal func dateRangeZoomChanged(_ sender: UISwitch) {
        isDateRangeZoomed = sender.isOn
        
        // Toggle the height constraint with animation
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
            // Update icon
            self.dateRangeZoomIcon.alpha = self.isDateRangeZoomed ? 1.0 : 0.5
            
            // Manage height constraint
            if self.isDateRangeZoomed {
                self.dateRangeZoomContainer.alpha = 1.0
                self.dateRangeZoomContainer.isHidden = false
                self.zoomContainerHeightConstraint.constant = 50
            } else {
                self.dateRangeZoomContainer.alpha = 0.0
                self.zoomContainerHeightConstraint.constant = 0
            }
            
            // Force layout update
            self.view.layoutIfNeeded() // Update the entire view hierarchy
        } completion: { _ in
            if !self.isDateRangeZoomed {
                self.dateRangeZoomContainer.isHidden = true
            }
        }
        
        // This handles the zoom functionality initialization only
        if isDateRangeZoomed && zoomedEarliestDate == nil {
            zoomedEarliestDate = earliestDate
            dateRangeZoomSlider.value = 0
        }
    }
    
    // handle zoom slider changes
    @objc internal func zoomSliderChanged(_ sender: UISlider) {
        guard let earliest = earliestDate, let latest = latestDate else { return }
        
        // Activate zoom when slider is moved from zero
        if sender.value > 0 {
            isZoomActive = true
        } else {
            isZoomActive = false
        }
        
        // Calculate new zoomed earliest date
        let fullRange = latest.timeIntervalSince(earliest)
        let zoomPercentage = Double(sender.value)
        let zoomedTimeInterval = fullRange * zoomPercentage
        zoomedEarliestDate = earliest.addingTimeInterval(zoomedTimeInterval)
        
        // Update the start and end date sliders to use the new range
        updateDateSlidersForZoomedRange()
        
        // Update the chart
        updateChartDataWithDebounce()
    }
    
    // Handle recent data indicator button taps
    @objc internal func recentDataIndicatorTapped(_ sender: UIButton) {
        // Cycle through states: 0=off, 1=last, 2=minus1, 3=minus2, back to 0
        recentDataIndicatorState = (recentDataIndicatorState + 1) % 4
        
        // Update button appearance
        switch recentDataIndicatorState {
        case 0: // Off
            sender.setTitle("○", for: .normal)
            sender.tintColor = .systemBlue
        case 1: // Last entry
            sender.setTitle("●", for: .normal)
            sender.tintColor = .systemRed
        case 2: // Minus 1 entry
            sender.setTitle("◑", for: .normal)
            sender.tintColor = .systemGreen
        case 3: // Minus 2 entry
            sender.setTitle("◐", for: .normal)
            sender.tintColor = .systemOrange
        default:
            break
        }
        
        // Update the chart to draw/remove the indicator line
        updateChartDataWithDebounce()
    }
    
    // Helper method to update date sliders for zoomed range
    private func updateDateSlidersForZoomedRange() {
        guard let zoomedEarliest = zoomedEarliestDate,
              let latest = latestDate,
              let currentStart = selectedStartDate,
              let _ = selectedEndDate else { return }
        
        // Calculate where current selection sits in zoomed range
        let zoomedRange = latest.timeIntervalSince(zoomedEarliest)
        
        // Adjust if current selections are outside zoomed range
        if currentStart < zoomedEarliest {
            selectedStartDate = zoomedEarliest
        }
        
        // Update slider values based on new range
        if zoomedRange > 0 {
            startDateSlider.value = Float((selectedStartDate!.timeIntervalSince(zoomedEarliest)) / zoomedRange)
            endDateSlider.value = Float((selectedEndDate!.timeIntervalSince(zoomedEarliest)) / zoomedRange)
        }
        
        // Update date labels
        updateDateLabels()
    }
    
    // Helper to reset to full date range -- not used
    private func resetToFullDateRange() {
        guard let earliest = earliestDate, let latest = latestDate else { return }
        
        // Reset the effective earliest date
        zoomedEarliestDate = earliest
        
        // Update slider values based on full range
        let fullRange = latest.timeIntervalSince(earliest)
        if fullRange > 0 {
            startDateSlider.value = Float((selectedStartDate!.timeIntervalSince(earliest)) / fullRange)
            endDateSlider.value = Float((selectedEndDate!.timeIntervalSince(earliest)) / fullRange)
        }
        
        // Update date labels
        updateDateLabels()
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
            "pieData": [VOT_BOOLEAN, VOT_CHOICE],
            "timeSource1": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN],
            "timeSource2": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN],
            "timeSource3": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN],
            "timeSource4": [VOT_NUMBER, VOT_FUNC, VOT_SLIDER, VOT_BOOLEAN]
        ]
        
        // Initialize empty selections
        selectedValueObjIDs = [
            "xAxis": -1,
            "yAxis": -1,
            "color": -1,
            "background": -1,
            "selection": -1,
            "pieData": -1,
            "timeSource1": -1,
            "timeSource2": -1,
            "timeSource3": -1,
            "timeSource4": -1
        ]
        
        // Setup initial configuration based on selected chart type
        // Set initial visibility of recent data button
        recentDataIndicatorButton.isHidden = (segmentedControl.selectedSegmentIndex != CHART_TYPE_DISTRIBUTION)
        
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
    
    internal func showPickerForTimeValueObjSelection(sourceIndex: Int) {
        // Store current selection type
        currentPickerType = "timeSource\(sourceIndex + 1)"
        
        // Get eligible valueObjs for time chart
        filteredValueObjs = getEligibleValueObjsForTimeChart()
        
        // Update picker
        pickerView.reloadAllComponents()
        
        // If a valueObj is already selected, select it in the picker
        if timeChartSources[sourceIndex] != -1 {
            if let index = filteredValueObjs.firstIndex(where: { $0.vid == timeChartSources[sourceIndex] }) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        // Show picker
        pickerContainer.isHidden = false
    }
    
    // Update dismissPicker to handle "None" selection
    @objc internal func dismissPicker() {
        // Get selected row
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        
        // Update selection if valid
        if selectedRow >= 0 && selectedRow < filteredValueObjs.count {
            let selected = filteredValueObjs[selectedRow]
            let previousSelection = selectedValueObjIDs[currentPickerType]
            
            // Check if "None" was selected (vid = -2)
            if selected.vid == -2 {
                // Special handling for "None" option
                if currentPickerType.hasPrefix("timeSource") {
                    // For time sources, update the corresponding timeChartSources array
                    let sourceIndex = Int(currentPickerType.dropFirst("timeSource".count))! - 1
                    if sourceIndex >= 0 && sourceIndex < timeChartSources.count {
                        timeChartSources[sourceIndex] = -1 // Set to -1 to indicate "none"
                    }
                } else {
                    // For other fields, set to -1 to indicate "none selected"
                    selectedValueObjIDs[currentPickerType] = -1
                }
            } else {
                // Normal selection
                selectedValueObjIDs[currentPickerType] = selected.vid
                
                // Update timeChartSources if this is a time source selection
                if currentPickerType.hasPrefix("timeSource") {
                    let sourceIndex = Int(currentPickerType.dropFirst("timeSource".count))! - 1
                    if sourceIndex >= 0 && sourceIndex < timeChartSources.count {
                        timeChartSources[sourceIndex] = selected.vid
                    }
                }
            }
            
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
                    } else if currentPickerType == "color" && previousSelection != selected.vid {
                        // Add this condition to clear color axis config when color is changed
                        axisConfig.removeValue(forKey: "colorAxis")
                        analyzeScatterData() // Recalculate axis scales including color scale
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
            } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_PIE {
                if selectedValueObjIDs["pieData"] != -1 {
                    generatePieChartData()
                }
            } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_TIME {
                // Update chart if at least one source is selected
                if timeChartSources.contains(where: { $0 != -1 }) {
                    generateTimeChartData()
                } else {
                    // If all sources are cleared, reset the chart view
                    for subview in chartView.subviews {
                        if subview != noDataLabel {
                            subview.removeFromSuperview()
                        }
                    }
                    noDataLabel.text = "Configure chart options below"
                    noDataLabel.isHidden = false
                }
            }
            
            // Update button title
            updateButtonTitles()
        }
        
        // Hide picker
        pickerContainer.isHidden = true
    }
    
    @objc internal func cancelPicker() {
        // Hide picker without saving selection
        pickerContainer.isHidden = true
    }
    
    
    // Update the updateButtonTitles method to handle "None" selection
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
                selectionButton.setTitle("Select Segmentation Data (Optional)", for: .normal)
            }
        } else if segmentedControl.selectedSegmentIndex == CHART_TYPE_TIME {
            // Update time chart source buttons
            for i in 0..<4 {
                let sourceID = timeChartSources[i]
                if sourceID != -1 {
                    let sourceVO = tracker?.valObjTable.first { $0.vid == sourceID }
                    let buttonTitle = sourceVO?.valueName ?? "Source \(i+1)"
                    
                    switch i {
                    case 0:
                        timeSource1Button.setTitle(buttonTitle, for: .normal)
                    case 1:
                        timeSource2Button.setTitle(buttonTitle, for: .normal)
                    case 2:
                        timeSource3Button.setTitle(buttonTitle, for: .normal)
                    case 3:
                        timeSource4Button.setTitle(buttonTitle, for: .normal)
                    default:
                        break
                    }
                } else {
                    // Set default titles for unselected sources
                    switch i {
                    case 0:
                        timeSource1Button.setTitle("Select Data Source 1", for: .normal)
                    case 1:
                        timeSource2Button.setTitle("Data Source 2 (Optional)", for: .normal)
                    case 2:
                        timeSource3Button.setTitle("Data Source 3 (Optional)", for: .normal)
                    case 3:
                        timeSource4Button.setTitle("Data Source 4 (Optional)", for: .normal)
                    default:
                        break
                    }
                }
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
    
    // Update pickerView delegate methods to show "None" as a distinct option
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        guard row < filteredValueObjs.count else { return nil }
        let valueObj = filteredValueObjs[row]
        
        // Special handling for "None" option
        if valueObj.vid == -2 {
            return NSAttributedString(
                string: "None",
                attributes: [.foregroundColor: UIColor.systemRed]
            )
        }
        
        // Regular handling for normal value objects
        let title = valueObj.valueName ?? "Unknown"
        
        // Format the title based on type
        let typeString: String
        switch valueObj.vtype {
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

    internal func countEntriesBetweenDates(start: Date, end: Date) -> Int {
        guard let tracker = tracker else { return 0 }
        
        let startTimestamp = Int(start.timeIntervalSince1970)
        let endTimestamp = Int(end.timeIntervalSince1970)
        
        let sql = """
        SELECT COUNT(date) FROM trkrData 
        WHERE date >= \(startTimestamp) AND date <= \(endTimestamp)
        """
        return tracker.toQry2Int(sql: sql)

    }
    
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
        
        // Update entry count label
        if let startDate = selectedStartDate, let endDate = selectedEndDate {
            let count = countEntriesBetweenDates(start: startDate, end: endDate)
            entryCountLabel.text = "\(count)"
        } else {
            entryCountLabel.text = "0"
        }
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
        // Show/hide recent data button based on chart type
        recentDataIndicatorButton.isHidden = (sender.selectedSegmentIndex != CHART_TYPE_DISTRIBUTION)
        
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
        } else if sender.selectedSegmentIndex == CHART_TYPE_TIME {
            setupTimeChartConfig()
            
            // Check if any data sources are selected for time chart
            if timeChartSources.contains(where: { $0 != -1 }) {
                generateTimeChartData()
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
        // Use zoomedEarliestDate instead of earliestDate if zoom is active
        let effectiveEarliestDate = isZoomActive ? zoomedEarliestDate : earliestDate

        // If we don't have date ranges yet, use default range of last year
        if effectiveEarliestDate == nil || latestDate == nil {
            let now = Date()
            let calendar = Calendar.current
            earliestDate = calendar.date(byAdding: .year, value: -1, to: now)
            latestDate = now
            zoomedEarliestDate = earliestDate
        }
        
        guard let effectiveEarliestDate = effectiveEarliestDate, let latestDate = latestDate else { return }
        
        let timeRange = max(1.0, latestDate.timeIntervalSince(effectiveEarliestDate)) // Ensure non-zero range
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
            selectedStartDate = effectiveEarliestDate.addingTimeInterval(startInterval)
            
            if dateRangeLockSwitch.isOn {
                // Lock mode: Keep date range constant
                if let startDate = selectedStartDate {
                    // Move end date to maintain fixed range
                    selectedEndDate = calendar.date(byAdding: .day, value: daysBetweenDates, to: startDate)
                    
                    // Update end slider position
                    if let endDate = selectedEndDate {
                        let endInterval = endDate.timeIntervalSince(effectiveEarliestDate)
                        let normalizedEndValue = Float(min(1.0, endInterval / timeRange))
                        endDateSlider.value = normalizedEndValue
                        
                        // Ensure end date doesn't exceed latest date
                        if endDate > latestDate {
                            // Adjust both sliders to respect the boundary
                            selectedEndDate = latestDate
                            endDateSlider.value = 1.0
                            
                            // Adjust start date back by daysBetweenDates
                            selectedStartDate = calendar.date(byAdding: .day, value: -daysBetweenDates, to: latestDate)
                            let adjustedStartInterval = selectedStartDate!.timeIntervalSince(effectiveEarliestDate)
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
                        let endInterval = minEndDate.timeIntervalSince(effectiveEarliestDate)
                        endDateSlider.value = Float(min(1.0, endInterval / timeRange))
                    }
                }
            }
        } else if sender == endDateSlider {
            // Calculate new end date
            let endInterval = TimeInterval(sender.value) * timeRange
            selectedEndDate = effectiveEarliestDate.addingTimeInterval(endInterval)
            
            if dateRangeLockSwitch.isOn {
                // Lock mode: Keep date range constant
                if let endDate = selectedEndDate {
                    // Move start date to maintain fixed range
                    selectedStartDate = calendar.date(byAdding: .day, value: -daysBetweenDates, to: endDate)
                    
                    // Update start slider position
                    if let startDate = selectedStartDate {
                        let startInterval = startDate.timeIntervalSince(effectiveEarliestDate)
                        let normalizedStartValue = Float(max(0.0, startInterval / timeRange))
                        startDateSlider.value = normalizedStartValue
                        
                        // Ensure start date doesn't go below earliest date
                        if startDate < effectiveEarliestDate {
                            // Adjust both sliders to respect the boundary
                            selectedStartDate = earliestDate
                            startDateSlider.value = 0.0
                            
                            // Adjust end date forward by daysBetweenDates
                            selectedEndDate = calendar.date(byAdding: .day, value: daysBetweenDates, to: effectiveEarliestDate)
                            let adjustedEndInterval = selectedEndDate!.timeIntervalSince(effectiveEarliestDate)
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
                        let startInterval = minStartDate.timeIntervalSince(effectiveEarliestDate)
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
                } else if self.segmentedControl.selectedSegmentIndex == self.CHART_TYPE_TIME {
                    // Handle time chart updates
                    if self.timeChartSources.contains(where: { $0 != -1 }) {
                        self.generateTimeChartData()
                    }
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
    
    
    // MARK: data handling
    
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
        
        /*
        let sql = """
        SELECT date, val FROM voData 
        WHERE id = \(id) AND date >= \(startTimestamp) AND date <= \(endTimestamp)
        ORDER BY date
        """
        */
        
        let sql = """
        SELECT v.date, v.val FROM voData v
        LEFT JOIN ignoreRecords i ON v.date = i.date
        WHERE v.id = \(id) AND v.date >= \(startTimestamp) AND v.date <= \(endTimestamp)
        AND i.date IS NULL
        ORDER BY v.date
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
    
    internal func loadDateRanges() {
        guard tracker != nil else { return }
        
        // Get date range from tracker data
        let dateRange = fetchDateRange()
        earliestDate = dateRange.earliest
        latestDate = dateRange.latest
        
        selectedStartDate = earliestDate
        selectedEndDate = latestDate
        
        // Initialize zoom-related properties
        zoomedEarliestDate = earliestDate
        
        // Update date labels
        updateDateLabels()
        
        // Update axis configurations if they exist
        updateChartData()
    }
}
