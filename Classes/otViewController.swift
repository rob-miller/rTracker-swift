//
//  otViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//
import SwiftUI

struct otViewController: View {
    let valueName: String
    var onDismiss: (String?, String?, Bool) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var currentTracker: String?
    @State private var currentValue: String?
    @State private var currentSwitch: Bool
    @State private var selectedSegment = 0
    @State private var showingInfoPopover = false

    var callerTrackerName: String? // Add this to store the caller's tracker name

    init(valueName: String, selectedTracker: String?, selectedValue: String?, otCurrent: Bool, callerTrackerName: String?, onDismiss: @escaping (String?, String?, Bool) -> Void) {
        self.valueName = valueName
        self.onDismiss = onDismiss
        self._currentTracker = State(initialValue: selectedTracker)
        self._currentValue = State(initialValue: selectedValue)
        self._currentSwitch = State(initialValue: otCurrent)
        self.callerTrackerName = callerTrackerName
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                // Custom header with valueObj name
                customHeader

                // Segmented Control
                Picker("Selection", selection: $selectedSegment) {
                    Text("Tracker").tag(0)
                    Text("Value").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: selectedSegment) { oldSegment, newSegment in
                    if newSegment == 1 && currentTracker == nil {
                        selectedSegment = 0
                    }
                }
                
                // Picker (Choice Wheel) changes based on segmented control
                if selectedSegment == 0 {
                    trackerPicker
                } else {
                    valuePicker
                }
                
                // "Only Current Data" Toggle Switch
                // "Only Current Data" Toggle Switch with Info Button
                HStack {
                    Toggle("Recent Only", isOn: $currentSwitch)
                    
                    Button(action: {
                        // This will be handled by the sheet or alert
                        showingInfoPopover = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Recent Only Information")
                }
                .padding()
                .sheet(isPresented: $showingInfoPopover) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Recent Only")
                            .font(.headline)
                        
                        Text("OFF: Always use the other tracker's most recent value, regardless of when it was recorded. Best for relatively stable measurements like height, weight, or blood type.")
                            .padding(.bottom, 5)
                        
                        Text("ON: Only use the other tracker's value if it was recorded after your previous entry in this tracker. Ideal for tracking correlations between events, like whether you exercised before sleeping or if medication affected your symptoms.")
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            showingInfoPopover = false
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

                Spacer()

                // Bottom button area (like configTVObjVC toolbar)
                HStack {
                    Spacer()

                    DoneButtonView {
                        onDismiss(currentTracker, currentValue, currentSwitch)
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityIdentifier("otvc_done")

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Set the first tracker if currentTracker is nil
                if currentTracker == nil {
                    let trackers = trackerList.shared.topLayoutNames
                    let filteredTrackers = trackers.filter { $0 != callerTrackerName }
                    if !filteredTrackers.isEmpty {
                        currentTracker = filteredTrackers[0]
                    }
                }
            }
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

    var trackerPicker: some View {
        // Get all trackers
        let allTrackers = trackerList.shared.topLayoutNames
        // Filter out the caller's tracker
        let filteredTrackers = allTrackers  // .filter { $0 != callerTrackerName }
        
        return VStack {
            Text("Select Tracker")
                .font(.headline)
                .padding(.bottom, 5)
            
            Picker("Choose tracker", selection: $currentTracker) {
                ForEach(filteredTrackers, id: \.self) { trackerName in
                    Text(trackerName).tag(trackerName as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .onChange(of: currentTracker) { oldTracker, newTracker in
                // Reset value when tracker changes
                currentValue = nil
            }
        }
    }
    
    var valuePicker: some View {
        let valueSet: [String] = {
            if let trackerName = currentTracker {
                let tid = trackerList.shared.getTIDfromNameDb(trackerName)[0]
                let to = trackerObj(tid)
                
                // Get all value names
                let allValues = to.toQry2AryS(sql: "select name from voConfig where priv <= \(privacyValue)")
                
                // Filter out values that have a recursive reference to the current tracker
                // Filter values and conditionally add "-<Any Value>-"
                let filteredValues = allValues.filter { valueName in
                    let vo = to.getValObjByName(valueName)
                    let otTrackerName = vo?.optDict["otTracker"]
                    return otTrackerName == nil || otTrackerName != callerTrackerName
                }

                // Only add "-<Any Value>-" if the tracker isn't referencing itself
                return (trackerName != callerTrackerName ? [OTANYNAME] : []) + filteredValues
            } else {
                return []
            }
        }()
        
        return VStack {
            Text("Select Value")
                .font(.headline)
                .padding(.bottom, 5)
            
            if currentTracker == nil {
                Text("Please select a tracker first")
                    .foregroundColor(.gray)
                    .padding()
            } else if valueSet.isEmpty {
                Text("No eligible values available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Picker("Choose value", selection: $currentValue) {
                    ForEach(valueSet, id: \.self) { valueName in
                        Text(valueName).tag(valueName as String?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .onAppear {
                    // Set the first value if currentValue is nil and values are available
                    if currentValue == nil && !valueSet.isEmpty {
                        currentValue = valueSet[0]
                    } else if !valueSet.contains(where: { $0 == currentValue }) {
                        // Reset currentValue if it's no longer in the filtered list
                        currentValue = valueSet.first
                    }
                }
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
        let barButton = rTracker_resource.createDoneButton(target: context.coordinator, action: #selector(Coordinator.tapped), accId: "otvc_done")
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
