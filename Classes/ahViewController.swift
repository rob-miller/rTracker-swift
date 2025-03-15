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
    var onDismiss: (String?, String?, Bool, Bool) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String? // Stores the datasource selection
    @State private var currentUnit: HKUnit? // Tracks the selected unit
    @State private var avgDataSwitch: Bool  // Tracks avg value switch
    @State private var prevDateSwitch: Bool  // Tracks previous date switch
    @State private var showingAvgInfo = false // For average info popup
    @State private var showingPrevDayInfo = false // For previous day info popup
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(selectedChoice: String?, selectedUnitString: String?, ahAvg: Bool, ahPrevD: Bool, onDismiss: @escaping (String?, String?, Bool, Bool) -> Void) {
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
        if let unitString = selectedUnitString {
            self._currentUnit = State(initialValue: HKUnit(from: unitString))
        } else {
            self._currentUnit = State(initialValue: nil)
        }
        avgDataSwitch = ahAvg
        prevDateSwitch = ahPrevD
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Picker (Choice Wheel)
                Picker("Choose data source", selection: $currentSelection) {
                    if rthk.configurations.isEmpty {
                        Text("Waiting for HealthKit data").tag("None") // Provide a single fallback choice
                    } else {
                        ForEach(rthk.configurations, id: \.displayName) { config in
                            Text(config.displayName).tag(config.displayName)
                        }
                    }
                }
                .pickerStyle(WheelPickerStyle()) // Wheel picker style
                .onChange(of: currentSelection) { newSelection in
                    currentUnit = nil
                    if let selectedConfig = rthk.configurations.first(where: { $0.displayName == newSelection }) {
                        if selectedConfig.unit != nil && selectedConfig.needUnit {
                            currentUnit = selectedConfig.unit?.first
                        }
                    }
                }
                
                // Fixed space for segmented control
                ZStack {
                    if let selectedConfig = rthk.configurations.first(where: { $0.displayName == currentSelection }) {
                        if selectedConfig.unit != nil {
                            UnitSegmentedControl(selectedConfig: selectedConfig, currentUnit: $currentUnit)
                                .onChange(of: selectedConfig.identifier) { newIdentifier in
                                    if let config = rthk.configurations.first(where: { $0.identifier == newIdentifier }),
                                       config.needUnit && currentUnit == nil {
                                        currentUnit = config.unit?.first
                                    }
                                }
                        }
                    } else {
                        Color.clear // Placeholder to maintain the height
                    }
                }
                .frame(height: 60) // Fixed height for the segmented control area
                
                // Switch for average multiple results
                ZStack {
                    if let selectedConfig = rthk.configurations.first(where: { $0.displayName == currentSelection }) {
                        if selectedConfig.aggregationStyle == .discreteArithmetic {
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
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 30)
                .sheet(isPresented: $showingAvgInfo) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Daily Average")
                            .font(.headline)
                        
                        Text("ON: Combines all readings from a single day (midnight to midnight) into one average value recorded at 12:00 noon. Ideal for metrics like weight or blood pressure where you want a single daily summary.")
                           .padding(.bottom, 5)

                        Text("OFF: Uses individual readings with their original timestamps. If multiple readings exist for the same time period, only the most recent one will be used. Better for tracking specific events throughout the day.")
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            showingAvgInfo = false
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
                
                // Switch for previous day
                ZStack {
                    if let selectedConfig = rthk.configurations.first(where: { $0.displayName == currentSelection }) {
                        if selectedConfig.aggregationStyle == .discreteArithmetic && avgDataSwitch {
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
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 30)
                .sheet(isPresented: $showingPrevDayInfo) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("For Previous Day")
                            .font(.headline)
                        
                        Text("ON: Assigns the data to the following day. Perfect for metrics like sleep tracking, where data collected overnight (e.g., from 10 PM to 6 AM) belongs conceptually to the next morning.")
                            .padding(.bottom, 5)
                        
                        Text("OFF: Keeps data assigned to the day it was collected. Best for most metrics like steps, exercise, or calorie intake where the data belongs to the day of activity.")
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            showingPrevDayInfo = false
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
            .padding()
            .navigationTitle("Choose source")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            if currentSelection == nil {
                                currentSelection = rthk.configurations.first?.displayName
                            }
                            onDismiss(currentSelection, currentUnit?.unitString, avgDataSwitch, prevDateSwitch)
                            dismiss()
                        }) {
                            Text("\u{2611}") // Ballot box with check
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Done")
                        .accessibilityIdentifier("confighk_done")
                        Spacer() // Pushes content to the left
                        Button("Update HealthKit Choices") {
                            rthk.dbInitialised = false
                            rthk.loadHealthKitConfigurations()
                        }
                    }
                }
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
