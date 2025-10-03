//
//  ahViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import SwiftUI
import HealthKit
import UIKit

struct ahViewController: View {
    // Debug flag: Set to true to show all workout category designs
    private let SHOW_ALL_WORKOUT_CATEGORIES = false

    let valueName: String
    var onDismiss: (String?, String?, Bool, String, String, String) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String? // Stores the datasource selection
    @State private var currentUnit: HKUnit? // Tracks the selected unit
    @State private var avgDataSwitch: Bool  // Tracks avg value switch
    @State private var prevDateSwitch: Bool  // Tracks previous date switch
    @State private var ahFrequency: String = "daily"  // Tracks frequency selection
    @State private var ahTimeFilter: String = "all_day"  // Tracks time filter selection
    @State private var ahAggregation: String = "avg"  // Tracks aggregation selection
    @State private var showingAvgInfo = false // For average info popup
    @State private var showingPrevDayInfo = false // For previous day info popup
    @State private var showingConfigInfo = false // For selected config info popup
    @State private var seenMinuteSelections: Set<String> = []  // Add this to track which selections we've seen
    @State private var sampleFilter: SampleFilter = .metrics
    @State private var workoutFilter: WorkoutCategoryFilter = .all
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(valueName: String, selectedChoice: String?, selectedUnitString: String?, ahPrevD: Bool, ahFrequency: String = "daily", ahTimeFilter: String = "all_day", ahAggregation: String = "avg", onDismiss: @escaping (String?, String?, Bool, String, String, String) -> Void) {
        self.valueName = valueName
        self.onDismiss = onDismiss

        self._currentSelection = State(initialValue: selectedChoice)

        if let choice = selectedChoice,
           let match = healthDataQueries.first(where: { $0.displayName == choice }) {
            // Determine effective menu tab (same logic as effectiveMenuTab function)
            let effectiveTab: MenuTab
            if let override = match.menuTab {
                effectiveTab = override
            } else {
                switch match.sampleType {
                case .quantity: effectiveTab = .metrics
                case .category: effectiveTab = .sleep
                case .workout: effectiveTab = .workouts
                }
            }

            _sampleFilter = State(initialValue: SampleFilter(menuTab: effectiveTab))
            // Set workout filter if we're going to the workouts tab and have a workout category
            if effectiveTab == .workouts && match.workoutCategory != nil {
                _workoutFilter = State(initialValue: WorkoutCategoryFilter(category: match.workoutCategory))
            }
        }

        if let unitString = selectedUnitString {
            self._currentUnit = State(initialValue: HKUnit(from: unitString))
        } else {
            self._currentUnit = State(initialValue: nil)
        }
        avgDataSwitch = false  // Always false - no averaging needed
        prevDateSwitch = ahPrevD
        _ahFrequency = State(initialValue: ahFrequency)
        _ahTimeFilter = State(initialValue: ahTimeFilter)
        _ahAggregation = State(initialValue: ahAggregation)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Custom header with valueObj name
                customHeader

                // Sample type selector
                sampleTypeSelector
                if sampleFilter == .workouts {
                    workoutCategorySelector
                }

                // Picker (Choice Wheel)
                dataSourcePicker
                    .onChange(of: currentSelection) { oldSelection, newSelection in
                        currentUnit = nil
                        if let selectedConfig = selectedConfiguration() {
                            if selectedConfig.unit != nil && selectedConfig.needUnit {
                                currentUnit = selectedConfig.unit?.first
                                
                            }
                        }
                    }

                infoButtonRow

                // Unit selection control
                if let selectedConfig = selectedConfiguration(),
                   selectedConfig.unit != nil {
                    unitSelectionContent
                }
                
                
                // Average data switch
                // averageDataSection
                
                // Previous day switch
                previousDaySection
                
                // High frequency controls
                if shouldShowNewControls() {
                    frequencyContent
                    timeFilterContent
                    aggregationContent
                }

                // Push everything to top
                Spacer()

                // Update HealthKit Choices button (fixed position above done button)
                Button(action: {
                    rthk.dbInitialised = false
                    rthk.loadHealthKitConfigurations()
                }) {
                    Text("Update HealthKit Choices")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundColor(.blue)
                        .background(
                            Capsule()
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                }
                .accessibilityIdentifier("confighk_refresh")
                .padding(.bottom, 12)

                // Centered done button at bottom (like configTVObjVC and otViewController)
                HStack {
                    Spacer()

                    DoneButtonView {
                        if currentSelection == nil {
                            currentSelection = rthk.configurations.first?.displayName
                        }
                        onDismiss(currentSelection, currentUnit?.unitString, prevDateSwitch, ahFrequency, ahTimeFilter, ahAggregation)
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityIdentifier("confighk_done")

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var customHeader: some View {
        VStack(spacing: 4) {
            Text(valueName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Choose data source")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var infoButtonRow: some View {
        HStack {
            Spacer()
            if selectedInfo != nil {
                HelpInfoButtonView {
                    showingConfigInfo = true
                }
                .frame(width: 30, height: 30)
                .accessibilityLabel("Source Information")
                .accessibilityIdentifier("confighk_info")
            } else {
                Color.clear
                    .frame(width: 30, height: 30)
            }
        }
        .frame(height: 34)
        .padding(.trailing, 8)
        .sheet(isPresented: $showingConfigInfo) {
            if let info = selectedInfo {
                infoSheet(title: info.title, content: info.message)
            } else {
                EmptyView()
            }
        }
    }
    
    private var dataSourcePicker: some View {
        Picker("Choose data source", selection: $currentSelection) {
            let configs = filteredConfigurations
            if configs.isEmpty {
                let message = rthk.configurations.isEmpty ? "Waiting for HealthKit data" : "No entries in this category"
                Text(message).tag("None")
            } else {
                ForEach(configs, id: \.displayName) { config in
                    HStack {
                        Text(config.displayName)
                        
                        // Show info indicator if needed
                        if let info = config.info, !info.isEmpty {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    .tag(config.displayName)
                }
            }
        }
        .pickerStyle(WheelPickerStyle())
        .frame(maxHeight: 120)
        .clipped()
        .onAppear(perform: ensureSelectionMatchesFilter)
        .onChange(of: sampleFilter) { _, _ in
            ensureSelectionMatchesFilter()
        }
        .onChange(of: workoutFilter) { _, _ in
            ensureSelectionMatchesFilter()
        }
        .onReceive(rthk.$configurations) { _ in
            ensureSelectionMatchesFilter()
        }
    }

    private var selectedInfo: (title: String, message: String)? {
        guard let config = selectedConfiguration(),
              let info = config.info,
              !info.isEmpty else {
            return nil
        }
        return (config.displayName, info)
    }

    private var unitSelectionContent: some View {
        Group {
            if let config = selectedConfiguration() {
                UnitSegmentedControl(selectedConfig: config, currentUnit: $currentUnit)
                    .onChange(of: selectedConfiguration()?.identifier) { oldIdentifier, newIdentifier in
                        if let config = rthk.configurations.first(where: { $0.identifier == newIdentifier }),
                           config.needUnit && currentUnit == nil {
                            currentUnit = config.unit?.first
                        }
                    }
            }
        }
        .frame(minHeight: 40)
    }
    
    
    /*
    private var averageDataSection: some View {
        ZStack {
            // Show old toggle only for data sources that don't have aggregationType specified
            // or for .lowFrequencyMultiple sources that may benefit from simple averaging
            if shouldShowOldAverageToggle() {
                HStack {
                    Text("Average daily results at 12:00")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingAvgInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Daily Average Information")
                    
                    Spacer()
                    Toggle("", isOn: $avgDataSwitch)
                        .labelsHidden()
                }
                .padding()
            } else {
                Color.clear
            }
        }
        .frame(height: 30)
        .sheet(isPresented: $showingAvgInfo) {
            infoSheet(
                title: "Daily Average",
                content: "ON: Combines all readings from a single day (midnight to midnight) into one average value recorded at 12:00 noon. Ideal for metrics like weight or blood pressure where you want a single daily summary.\n\nOFF: Uses individual readings with their original timestamps. If multiple readings exist for the same time period, only the most recent one will be used. Better for tracking specific events throughout the day."
            )
        }
    }
    */
    private var previousDaySection: some View {
        // Always show previous day option regardless of data source type
        HStack {
            Text("For previous day")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Button(action: {
                showingPrevDayInfo = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Previous Day Information")
            
            Spacer()
            Toggle("", isOn: $prevDateSwitch)
                .labelsHidden()
        }
        .padding(.horizontal)
        .frame(minHeight: 25)
        .sheet(isPresented: $showingPrevDayInfo) {
            infoSheet(
                title: "For Previous Day",
                content: "ON: Assigns the data to the following day.  Like active energy for a sleep tracker, where the activity might affect your sleep the following night.\n\nOFF: Keeps data assigned to the day it was collected. Best for an exercise or calorie tracker where the data belongs to the day of activity."
            )
        }
    }
    
    private var frequencyContent: some View {
        VStack {
            HStack {
                Text("Frequency")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Picker("Frequency", selection: $ahFrequency) {
                Text("Daily").tag("daily")
                Text("Every 1h").tag("every_1h")
                Text("Every 2h").tag("every_2h")
                Text("Every 4h").tag("every_4h")
                Text("Every 6h").tag("every_6h")
                Text("Every 8h").tag("every_8h")
                Text("Twice daily").tag("twice_daily")
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal)
        .frame(minHeight: 45)
    }
    
    private var timeFilterContent: some View {
        VStack {
            HStack {
                Text("Time Filter")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Picker("Time Filter", selection: $ahTimeFilter) {
                Text("All day").tag("all_day")
                Text("Morning 6-10").tag("morning")
                Text("Daytime 10-18").tag("daytime")
                Text("Evening 18-23").tag("evening")
                Text("Sleep hours 23-6").tag("sleep_hours")
                Text("Wake hours 6-23").tag("wake_hours")
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal)
        .frame(minHeight: 45)
    }
    
    private var aggregationContent: some View {
        VStack {
            HStack {
                Text("Aggregation")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Picker("Aggregation", selection: $ahAggregation) {
                Text("Average").tag("avg")
                Text("Sum").tag("sum")
                Text("First").tag("first")
                Text("Last").tag("last")
                Text("Minimum").tag("min")
                Text("Maximum").tag("max")
                Text("Median").tag("median")
            }
            .pickerStyle(MenuPickerStyle())
        }
        .padding(.horizontal)
        .frame(minHeight: 45)
    }
    
    // Helper function to find the selected configuration
    private func selectedConfiguration() -> HealthDataQuery? {
        return rthk.configurations.first { $0.displayName == currentSelection }
    }
    
    // Determine if new controls (frequency/time filter/aggregation) should be shown
    private func shouldShowNewControls() -> Bool {
        guard let config = selectedConfiguration() else { return false }
        
        // Show new controls for .highFrequency sources that need full control
        return config.aggregationType == .highFrequency
    }
    
    // Determine if Sum option should appear in aggregation picker
    private func shouldShowSumOption() -> Bool {
        // Sum option is no longer needed - HealthKit provides daily totals automatically
        return false
    }
    
    // Reusable info sheet view
    private func infoSheet(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .padding(.bottom, 5)
            
            Spacer()
            
            Button("Dismiss") {
                // This will close whichever sheet is open
                showingAvgInfo = false
                showingPrevDayInfo = false
                showingConfigInfo = false
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

// MARK: - Sample type filtering helpers

extension ahViewController {
    private enum SampleFilter: String, CaseIterable, Identifiable {
        case metrics
        case sleep
        case workouts

        var id: String { rawValue }

        var title: String {
            switch self {
            case .metrics:
                return MenuTab.metrics.title
            case .sleep:
                return MenuTab.sleep.title
            case .workouts:
                return MenuTab.workouts.title
            }
        }

        var icon: String {
            switch self {
            case .metrics:
                return MenuTab.metrics.icon
            case .sleep:
                return MenuTab.sleep.icon
            case .workouts:
                return MenuTab.workouts.icon
            }
        }

        var sampleType: HealthDataQuery.SampleType {
            switch self {
            case .metrics:
                return .quantity
            case .sleep:
                return .category
            case .workouts:
                return .workout
            }
        }

        init(sampleType: HealthDataQuery.SampleType) {
            switch sampleType {
            case .quantity:
                self = .metrics
            case .category:
                self = .sleep
            case .workout:
                self = .workouts
            }
        }

        init(menuTab: MenuTab) {
            switch menuTab {
            case .metrics:
                self = .metrics
            case .sleep:
                self = .sleep
            case .workouts:
                self = .workouts
            }
        }
    }

    private func effectiveMenuTab(for config: HealthDataQuery) -> MenuTab {
        // Debug: Always log what we're checking
        DBGLog("Checking \(config.displayName) - menuTab: \(config.menuTab?.rawValue ?? "nil"), sampleType: \(config.sampleType)")

        // Use override if specified
        if let override = config.menuTab {
            DBGLog("\(config.displayName) using override tab: \(override)")
            return override
        }
        // Otherwise use default based on sampleType
        let defaultTab: MenuTab
        switch config.sampleType {
        case .quantity: defaultTab = .metrics
        case .category: defaultTab = .sleep
        case .workout: defaultTab = .workouts
        }
        DBGLog("\(config.displayName) using default tab: \(defaultTab)")
        return defaultTab
    }

    private var filteredConfigurations: [HealthDataQuery] {
        switch sampleFilter {
        case .metrics:
            return rthk.configurations
                .filter { effectiveMenuTab(for: $0) == .metrics }
        case .sleep:
            return rthk.configurations
                .filter { effectiveMenuTab(for: $0) == .sleep }
        case .workouts:
            return rthk.configurations
                .filter { config in
                    guard effectiveMenuTab(for: config) == .workouts else { return false }
                    if let category = workoutFilter.category {
                        return config.workoutCategory == category
                    }
                    return true
                }
                .sorted { $0.displayName < $1.displayName }
        }
    }

    private var availableWorkoutCategories: [WorkoutCategoryFilter] {
        // Debug mode: show all categories to preview designs
        if SHOW_ALL_WORKOUT_CATEGORIES {
            return WorkoutCategoryFilter.allCases
        }

        // Production mode: only show categories with actual entries
        var categories: Set<WorkoutCategoryFilter> = [.all]

        let workoutConfigs = rthk.configurations.filter { effectiveMenuTab(for: $0) == .workouts }

        for config in workoutConfigs {
            if let category = config.workoutCategory {
                let filter = WorkoutCategoryFilter(category: category)
                categories.insert(filter)
            }
        }

        // Return in original enum order for consistency
        return WorkoutCategoryFilter.allCases.filter { categories.contains($0) }
    }

    private var sampleTypeSelector: some View {
        Picker("Data Category", selection: $sampleFilter) {
            ForEach(SampleFilter.allCases) { filter in
                if #available(iOS 26.0, *) {
                    Image(systemName: filter.icon).tag(filter)
                } else {
                    Text(filter.title).tag(filter)
                }
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .accessibilityIdentifier("confighk_category")
    }

    private var workoutCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableWorkoutCategories) { filter in
                    let isSelected = workoutFilter == filter
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            workoutFilter = filter
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 12))
                            Text(filter.title)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color.blue : Color(.secondarySystemFill))
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("confighk_workout_category_\(filter.rawValue)")
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func ensureSelectionMatchesFilter() {
        let configs = filteredConfigurations
        if configs.isEmpty {
            currentSelection = nil
            currentUnit = nil
            return
        }

        if let current = currentSelection,
           configs.contains(where: { $0.displayName == current }) {
            if let config = selectedConfiguration(), config.needUnit && currentUnit == nil {
                currentUnit = config.unit?.first
            }
            return
        }

        if let first = configs.first {
            currentSelection = first.displayName
            if first.needUnit {
                currentUnit = first.unit?.first
            } else {
                currentUnit = nil
            }
        }
    }

    private enum WorkoutCategoryFilter: String, CaseIterable, Identifiable {
        case all
        case cardio
        case training
        case sports
        case mindAndBody
        case outdoor
        case wheel
        case other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .cardio: return "Cardio"
            case .training: return "Training"
            case .sports: return "Sports"
            case .mindAndBody: return "Mind & Body"
            case .outdoor: return "Outdoor"
            case .wheel: return "Wheel"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .all: return "list.bullet.circle.fill"
            case .cardio: return "heart.circle.fill"
            case .training: return "dumbbell.fill"
            case .sports: return "sportscourt.fill"
            case .mindAndBody: return "brain.fill"
            case .outdoor: return "tree.fill"
            case .wheel: return "figure.roll"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var category: HealthDataQuery.WorkoutCategory? {
            switch self {
            case .all: return nil
            case .cardio: return .cardio
            case .training: return .training
            case .sports: return .sports
            case .mindAndBody: return .mindAndBody
            case .outdoor: return .outdoor
            case .wheel: return .wheelchair
            case .other: return .other
            }
        }

        init(category: HealthDataQuery.WorkoutCategory?) {
            guard let category = category else {
                self = .all
                return
            }
            switch category {
            case .cardio: self = .cardio
            case .training: self = .training
            case .sports: self = .sports
            case .mindAndBody: self = .mindAndBody
            case .outdoor: self = .outdoor
            case .wheelchair: self = .wheel
            case .other: self = .other
            }
        }
    }
}

struct UnitSegmentedControl: View {
    let selectedConfig: HealthDataQuery
    @Binding var currentUnit: HKUnit?
    
    var body: some View {
        HStack {
            ForEach(selectedConfig.unit ?? [], id: \.self) { unit in
                let isSelected = currentUnit == unit // Simplify selection logic
                
                Button(action: {
                    if selectedConfig.needUnit {
                        currentUnit = unit // Always enforce selection
                    } else {
                        currentUnit = isSelected ? nil : unit // Toggle selection
                    }
                }) {
                    Text(unit.unitString)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color.gray : Color.clear)
                        .foregroundColor(isSelected ? .white : .blue)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .onAppear {
            if selectedConfig.needUnit && currentUnit == nil {
                currentUnit = selectedConfig.unit?.first
            }
        }
    }
}

// MARK: - UIKit helpers

private struct DoneButtonView: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> UIButton {
        let barButton = rTracker_resource.createDoneButton(target: context.coordinator, action: #selector(Coordinator.tapped))
        if let button = barButton.uiButton {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentHuggingPriority(.required, for: .vertical)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            context.coordinator.button = button

            // Use intrinsic content size to maintain circular shape
            let intrinsicSize = button.intrinsicContentSize
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: intrinsicSize.width),
                button.heightAnchor.constraint(equalToConstant: intrinsicSize.height),
                button.widthAnchor.constraint(equalTo: button.heightAnchor) // Maintain 1:1 aspect ratio
            ])

            return button
        }

        // Fallback for pre-iOS 26
        let fallback = UIButton(type: .system)
        fallback.setTitle("Done", for: .normal)
        fallback.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        context.coordinator.button = fallback
        return fallback
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.isUserInteractionEnabled = true
    }

    final class Coordinator: NSObject {
        let action: () -> Void
        weak var button: UIButton?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}

private struct HelpInfoButtonView: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> UIButton {
        let barButton = rTracker_resource.createHelpInfoButton(target: context.coordinator, action: #selector(Coordinator.tapped))
        if let button = barButton.customView as? UIButton {
            context.coordinator.button = button
            return button
        }

        let fallback = UIButton(type: .infoDark)
        fallback.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        context.coordinator.button = fallback
        return fallback
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.isUserInteractionEnabled = true
    }

    final class Coordinator: NSObject {
        let action: () -> Void
        weak var button: UIButton?

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}
