//
//  ahViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import SwiftUI
import HealthKit

struct ahViewController: View {
    var onDismiss: (String?, String?, Bool, Bool, String, String, String) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String? // Stores the datasource selection
    @State private var currentUnit: HKUnit? // Tracks the selected unit
    @State private var avgDataSwitch: Bool  // Tracks avg value switch
    @State private var prevDateSwitch: Bool  // Tracks previous date switch
    @State private var hrsMinSwitch: Bool = false  // Tracks hrs:mins display format switch
    @State private var ahFrequency: String = "daily"  // Tracks frequency selection
    @State private var ahTimeFilter: String = "all_day"  // Tracks time filter selection  
    @State private var ahAggregation: String = "avg"  // Tracks aggregation selection
    @State private var showingAvgInfo = false // For average info popup
    @State private var showingPrevDayInfo = false // For previous day info popup
    @State private var showingConfigInfo = false // For selected config info popup
    @State private var previousHrsMinState: Bool = false
    @State private var seenMinuteSelections: Set<String> = []  // Add this to track which selections we've seen
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(selectedChoice: String?, selectedUnitString: String?, ahPrevD: Bool, ahHrsMin: Bool = false, ahFrequency: String = "daily", ahTimeFilter: String = "all_day", ahAggregation: String = "avg", onDismiss: @escaping (String?, String?, Bool, Bool, String, String, String) -> Void) {
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
        if let unitString = selectedUnitString {
            self._currentUnit = State(initialValue: HKUnit(from: unitString))
        } else {
            self._currentUnit = State(initialValue: nil)
        }
        avgDataSwitch = false  // Always false - no averaging needed
        prevDateSwitch = ahPrevD
        _hrsMinSwitch = State(initialValue: ahHrsMin)
        _previousHrsMinState = State(initialValue: ahHrsMin)
        _ahFrequency = State(initialValue: ahFrequency)
        _ahTimeFilter = State(initialValue: ahTimeFilter)
        _ahAggregation = State(initialValue: ahAggregation)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Picker (Choice Wheel)
                dataSourcePicker
                    .onChange(of: currentSelection) { oldSelection, newSelection in
                        currentUnit = nil
                        if let selectedConfig = selectedConfiguration() {
                            if selectedConfig.unit != nil && selectedConfig.needUnit {
                                currentUnit = selectedConfig.unit?.first
                                
                                // If this selection offers minutes and we haven't seen it before
                                if let newSelection = newSelection,
                                   currentUnit?.unitString == "min" {
                                    if !seenMinuteSelections.contains(newSelection) {
                                        hrsMinSwitch = true  // Turn on for first time
                                        previousHrsMinState = true
                                        seenMinuteSelections.insert(newSelection)  // Mark as seen
                                    } else {
                                        hrsMinSwitch = previousHrsMinState  // Use previous state
                                    }
                                }
                            }
                        }
                    }
                
                // Unit selection control
                if let selectedConfig = selectedConfiguration(),
                   selectedConfig.unit != nil {
                    unitSelectionContent
                }
                
                // Hours:Minutes format switch (only for "min" unit)
                if currentUnit?.unitString == "min" {
                    hoursMinutesContent
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
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .navigationTitle("Choose source")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    navigationInfoButton
                }
                ToolbarItem(placement: .bottomBar) {
                    bottomToolbar
                }
            }
        }
    }
    
    // Navigation bar info button
    private var navigationInfoButton: some View {
        Group {
            if let selectedConfig = selectedConfiguration(),
               let info = selectedConfig.info,
               !info.isEmpty {
                Button(action: {
                    showingConfigInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Source Information")
                .sheet(isPresented: $showingConfigInfo) {
                    infoSheet(title: selectedConfig.displayName, content: info)
                }
            }
        }
    }
    
    private var dataSourcePicker: some View {
        Picker("Choose data source", selection: $currentSelection) {
            if rthk.configurations.isEmpty {
                Text("Waiting for HealthKit data").tag("None")
            } else {
                ForEach(rthk.configurations, id: \.displayName) { config in
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
    }
    
    private var unitSelectionContent: some View {
        UnitSegmentedControl(selectedConfig: selectedConfiguration()!, currentUnit: $currentUnit)
            .onChange(of: selectedConfiguration()?.identifier) { oldIdentifier, newIdentifier in
                if let config = rthk.configurations.first(where: { $0.identifier == newIdentifier }),
                   config.needUnit && currentUnit == nil {
                    currentUnit = config.unit?.first
                }
            }
            .onChange(of: currentUnit) { oldUnit, newUnit in
                // Reset hrs:mins switch if unit is not minutes
                if newUnit?.unitString == "min" {
                    hrsMinSwitch = previousHrsMinState
                } else {
                    hrsMinSwitch = false
                }
            }
            .frame(minHeight: 40)
    }
    
    private var hoursMinutesContent: some View {
        HStack {
            Text("Display minutes as hrs:mins")
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            Toggle("", isOn: $hrsMinSwitch)
                .labelsHidden()
                .onChange(of: hrsMinSwitch) { oldValue, newValue in
                    previousHrsMinState = newValue
                }
        }
        .padding(.horizontal)
        .frame(minHeight: 25)
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
                Text("Morning").tag("morning")
                Text("Daytime").tag("daytime")
                Text("Evening").tag("evening")
                Text("Sleep hours").tag("sleep_hours")
                Text("Wake hours").tag("wake_hours")
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
    
    private var bottomToolbar: some View {
        HStack {
            Button(action: {
                if currentSelection == nil {
                    currentSelection = rthk.configurations.first?.displayName
                }
                onDismiss(currentSelection, currentUnit?.unitString, prevDateSwitch, hrsMinSwitch, ahFrequency, ahTimeFilter, ahAggregation)
                dismiss()
            }) {
                Text("\u{2611}")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Done")
            .accessibilityIdentifier("confighk_done")
            
            Spacer()
            
            Button("Update HealthKit Choices") {
                rthk.dbInitialised = false
                rthk.loadHealthKitConfigurations()
            }
        }
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
