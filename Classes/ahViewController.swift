//
//  ahViewController.swift
//  rTracker
//
//  Created by Robert Miller on 05/01/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import SwiftUI

struct ahViewController: View {
    var selectedChoice: String = "" // Selected item in the picker
    var onDismiss: (String) -> Void
    @Environment(\.dismiss) var dismiss // For the Back/Exit button
    @State private var choices: [String] = ["None", "Option 1", "Option 2", "Option 3"] // Data for the picker
    @State private var currentSelection: String
    @State private var isFilePickerPresented = false
    @State private var selectedFileURL: URL?
    
    init(selectedChoice: String, onDismiss: @escaping (String) -> Void) {
        self.selectedChoice = selectedChoice
        self.onDismiss = onDismiss
        self._currentSelection = State(initialValue: selectedChoice)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Picker (Choice Wheel)
                Picker("Select an Option", selection: $currentSelection) {
                    ForEach(choices, id: \.self) { choice in
                        Text(choice).tag(choice)
                    }
                }
                .pickerStyle(WheelPickerStyle()) // Wheel picker style
                
                // Button to Update Choices
                Button("Update Choices") {
                    isFilePickerPresented = true
                }
                .sheet(isPresented: $isFilePickerPresented) {
                    FilePickerWrapper { fileURL in
                        isFilePickerPresented = false
                        if let fileURL = fileURL {
                            print("Selected file: \(fileURL)")
                            //processFile(fileURL)
                        } else {
                            print("File selection canceled")
                        }
                    }
                }
                
                // Exit Button
                Button("Exit") {
                    onDismiss(currentSelection) // Pass back the selected value
                    dismiss()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
            }
            .padding()
            .navigationTitle("Configure Options") // Navigation bar title
        }
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    // Function to update choices
    func updateChoices() {
        isFilePickerPresented = true
        choices = ["None", "New Option 1", "New Option 2", "New Option 3"]
    }
    
    func processFile(_ fileURL: URL) {
        // Logic to read and update choices based on the file
        do {
            let fileContents = try String(contentsOf: fileURL)
            choices = ["None", "New Option 1", "New Option 2", "New Option 3"]
            //choices = fileContents.split(separator: "\n").map { String($0) }
            print("Choices updated to: \(choices)")
        } catch {
            print("Failed to read file: \(error)")
        }
    }
}

#Preview {
    ahViewController(
        selectedChoice: "Option 1",
        onDismiss: { updatedChoice in
            print("Dismissed with choice: \(updatedChoice)")
        }
    )
}
