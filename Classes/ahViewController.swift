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
    var onDismiss: (String?, String?, Bool, Bool, Bool) -> Void  // Updated to include hrsMinSwitch
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String? // Stores the datasource selection
    @State private var currentUnit: HKUnit? // Tracks the selected unit
    @State private var avgDataSwitch: Bool  // Tracks avg value switch
    @State private var prevDateSwitch: Bool  // Tracks previous date switch
    @State private var hrsMinSwitch: Bool = false  // Tracks hrs:mins display format switch
    @State private var showingAvgInfo = false // For average info popup
    @State private var showingPrevDayInfo = false // For previous day info popup
    @State private var showingConfigInfo = false // For selected config info popup
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(selectedChoice: String?, selectedUnitString: String?, ahAvg: Bool, ahPrevD: Bool, ahHrsMin: Bool = false, onDismiss: @escaping (String?, String?, Bool, Bool, Bool) -> Void) {
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
        if let unitString = selectedUnitString {
            self._currentUnit = State(initialValue: HKUnit(from: unitString))
        } else {
            self._currentUnit = State(initialValue: nil)
        }
        avgDataSwitch = ahAvg
        prevDateSwitch = ahPrevD
        _hrsMinSwitch = State(initialValue: ahHrsMin)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Extract the info button section to a separate view
                configInfoSection
                
                // Picker (Choice Wheel)
                dataSourcePicker
                
                // Unit selection control
                unitSelectionArea
                
                // Hours:Minutes format switch (only for "min" unit)
                hoursMinutesSection
                
                // Average data switch
                averageDataSection
                
                // Previous day switch
                previousDaySection
            }
            .padding()
            .navigationTitle("Choose source")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    bottomToolbar
                }
            }
        }
    }
    
    // Extract complex sections into computed properties
    private var configInfoSection: some View {
        Group {
            if let selectedConfig = selectedConfiguration(),
               let info = selectedConfig.info,
               !info.isEmpty {
                HStack {
                    Text("Choose data source")
                        .font(.headline)
                    
                    Button(action: {
                        showingConfigInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Source Information")
                    
                    Spacer()
                }
                .padding(.horizontal)
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
        .onChange(of: currentSelection) { newSelection in
            currentUnit = nil
            if let selectedConfig = selectedConfiguration() {
                if selectedConfig.unit != nil && selectedConfig.needUnit {
                    currentUnit = selectedConfig.unit?.first
                }
            }
        }
    }
    
    private var unitSelectionArea: some View {
        ZStack {
            if let selectedConfig = selectedConfiguration(),
               selectedConfig.unit != nil {
                UnitSegmentedControl(selectedConfig: selectedConfig, currentUnit: $currentUnit)
                    .onChange(of: selectedConfig.identifier) { newIdentifier in
                        if let config = rthk.configurations.first(where: { $0.identifier == newIdentifier }),
                           config.needUnit && currentUnit == nil {
                            currentUnit = config.unit?.first
                        }
                    }
                    .onChange(of: currentUnit) { newUnit in
                        // Reset hrs:mins switch if unit is not minutes
                        if newUnit?.unitString != "min" {
                            hrsMinSwitch = false
                        }
                    }
            } else {
                Color.clear
            }
        }
        .frame(height: 60)
    }
    
    // Simplified hours:minutes section with just a label
    private var hoursMinutesSection: some View {
        ZStack {
            if currentUnit?.unitString == "min" {
                HStack {
                    Text("Display minutes as hrs:mins")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    Toggle("", isOn: $hrsMinSwitch)
                        .labelsHidden()
                }
                .padding()
            } else {
                Color.clear
            }
        }
        .frame(height: 30)
    }
    
    private var averageDataSection: some View {
        ZStack {
            if let selectedConfig = selectedConfiguration(),
               selectedConfig.aggregationStyle == .discreteArithmetic {
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
    
    private var previousDaySection: some View {
        ZStack {
            if let selectedConfig = selectedConfiguration()
               // ,
               //selectedConfig.aggregationStyle == .discreteArithmetic && avgDataSwitch
            {
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
                .padding()
            } else {
                Color.clear
            }
        }
        .frame(height: 30)
        .sheet(isPresented: $showingPrevDayInfo) {
            infoSheet(
                title: "For Previous Day",
                content: "ON: Assigns the data to the following day. Perfect for a sleep tracker, where the activity might affect your sleep the following night.\n\nOFF: Keeps data assigned to the day it was collected. Best for an exercise or calorie tracker where the data belongs to the day of activity."
            )
        }
    }
    
    private var bottomToolbar: some View {
        HStack {
            Button(action: {
                if currentSelection == nil {
                    currentSelection = rthk.configurations.first?.displayName
                }
                onDismiss(currentSelection, currentUnit?.unitString, avgDataSwitch, prevDateSwitch, hrsMinSwitch)
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
