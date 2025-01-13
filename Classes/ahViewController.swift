//
//  ahViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import SwiftUI

struct ahViewController: View {
    var onDismiss: (String) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var currentSelection: String // Stores the user's selection
    @State private var isFilePickerPresented = false
    
    @ObservedObject var rthk = rtHealthKit.shared
    
    init(selectedChoice: String, onDismiss: @escaping (String) -> Void) {
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Picker (Choice Wheel)
                Picker("Choose data source", selection: $currentSelection) {
                    if rthk.configurations.isEmpty {
                        Text("Waiting for HealthKit data").tag("None") // Provide a single fallback choice
                    } else {
                        ForEach(rthk.configurations, id: \.identifier) { config in
                            Text(config.displayName).tag(config.displayName)
                        }
                        //currentSelection = rthk.configurations.first?.displayName ?? "None"
                    }
                }
                .pickerStyle(WheelPickerStyle()) // Wheel picker style
                /*.onAppear {
                    // Update currentSelection if configurations are loaded
                    if !rthk.configurations.isEmpty, currentSelection == "None" {
                        currentSelection = rthk.configurations.first?.displayName ?? "None"
                    }
                }*/
                
                // Button to Update Choices
                Button("Update Choices") {
                    rthk.dbInitialised = false
                    rthk.loadHealthKitConfigurations()
                }
            }
            .padding()
            .navigationTitle("Choose source")
            .toolbar {
                            ToolbarItem(placement: .bottomBar) {
                                HStack {
                                    Button(action: {
                                        if currentSelection == "None" {
                                            currentSelection = rthk.configurations.first?.displayName ?? "None"
                                        }
                                        onDismiss(currentSelection)
                                        dismiss()
                                    }) {
                                        Text("\u{2611}") // Ballot box with check
                                            .font(.system(size: 28))
                                            .foregroundColor(.blue)
                                    }
                                    .accessibilityLabel("Done")
                                    .accessibilityIdentifier("confighk_done")
                                    Spacer() // Pushes content to the left
                                }
                            }
                        }
        }
    }
}

#Preview {
    ahViewController(
        selectedChoice: "Option 1",
        onDismiss: { updatedChoice in
            DBGLog("Dismissed with choice: \(updatedChoice)")
        }
    )
}
