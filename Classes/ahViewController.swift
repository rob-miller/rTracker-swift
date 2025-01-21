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
    var onDismiss: (String?, String?) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String? // Stores the datasource selection
    @State private var currentUnit: HKUnit? // Tracks the selected unit
    @State private var isFilePickerPresented = false
    
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(selectedChoice: String?, selectedUnitString: String?, onDismiss: @escaping (String?, String?) -> Void) {
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
        if let unitString = selectedUnitString {
            self._currentUnit = State(initialValue: HKUnit(from: unitString))
        } else {
            self._currentUnit = State(initialValue: nil)
        }
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
                        //currentSelection = rthk.configurations.first?.displayName ?? "None"
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
                
            }
            .padding()
            .navigationTitle("Choose source")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button(action: {
                            //if currentSelection == nil {
                            //    currentSelection = rthk.configurations.first?.displayName ?? "None"
                            //}
                            onDismiss(currentSelection, currentUnit?.unitString)
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



