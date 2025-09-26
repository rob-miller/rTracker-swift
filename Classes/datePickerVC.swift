//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
///************
/// datePickerVC.swift
/// Copyright 2010-2021 Robert T. Miller
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
//  datePicker.m
//  rTracker
//
//  Created by Robert Miller on 14/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

import UIKit

///************
/// datePickerVC.h
/// Copyright 2010-2021 Robert T. Miller
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

//  datePicker.h
//  rTracker
//
//  this support screen enables the user to specify a date/time to navigate, create or edit  entries for a tracker
//
//  Created by Robert Miller on 14/10/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//


let SEG_DATE = 0
let SEG_TIME = 1


class datePickerVC: UIViewController {

    var myTitle: String?
    var dpr: dpRslt?
    var titleLabel: UILabel!
    var datePicker: UIDatePicker!
    var entryNewBtn: UIBarButtonItem!
    var dateSetBtn: UIBarButtonItem!
    var dateGotoBtn: UIBarButtonItem!
    var cancelBtn: UIBarButtonItem!
    var buttonStackView: UIStackView!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func btnCancel(_ btn: UIButton?) {
        dpr?.date = datePicker.date
        dpr?.action = DPA_CANCEL
        dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        titleLabel.text = myTitle

        datePicker.maximumDate = Date()
        if let aDate = dpr?.date {
            datePicker.date = aDate
        }
    }

    func setupViews() {
        view.backgroundColor = .systemBackground

        // Set up modal presentation
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        // Create title label
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        view.addSubview(titleLabel)

        // Create date picker
        datePicker = UIDatePicker()
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .wheels
        view.addSubview(datePicker)

        // Create buttons using iOS 26 patterns and extract UIButtons
        entryNewBtn = rTracker_resource.createActionButton(
            target: self,
            action: #selector(entryNewBtnAction),
            symbolName: "doc.badge.plus",
            symbolSize: 24,
            fallbackTitle: "New Entry"
        )

        dateSetBtn = rTracker_resource.createDoneButton(
            target: self,
            action: #selector(dateSetBtnAction),
            preferYellow: false,
            symbolSize: 24
        )

        dateGotoBtn = rTracker_resource.createActionButton(
            target: self,
            action: #selector(dateGotoBtnAction),
            symbolName: "arrow.right.circle",
            symbolSize: 24,
            fallbackTitle: "Go to Date"
        )

        cancelBtn = rTracker_resource.createStyledButton(
            symbolName: "xmark.circle",
            target: self,
            action: #selector(btnCancel(_:)),
            symbolSize: 24,
            fallbackTitle: "Cancel"
        )

        // Create horizontal button stack
        buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = 16
        view.addSubview(buttonStackView)

        // Extract UIButtons from UIBarButtonItems and add to stack
        if let entryNewButton = entryNewBtn.uiButton {
            entryNewButton.translatesAutoresizingMaskIntoConstraints = false
            buttonStackView.addArrangedSubview(entryNewButton)
        }

        if let dateSetButton = dateSetBtn.uiButton {
            dateSetButton.translatesAutoresizingMaskIntoConstraints = false
            buttonStackView.addArrangedSubview(dateSetButton)
        }

        if let dateGotoButton = dateGotoBtn.uiButton {
            dateGotoButton.translatesAutoresizingMaskIntoConstraints = false
            buttonStackView.addArrangedSubview(dateGotoButton)
        }

        // Create cancel button at bottom
        var cancelButton: UIButton?
        if let button = cancelBtn.uiButton {
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)
            cancelButton = button
        }

        // Set up constraints
        var constraints: [NSLayoutConstraint] = [
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Date picker constraints
            datePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Button stack constraints
            buttonStackView.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            buttonStackView.heightAnchor.constraint(equalToConstant: 60)
        ]

        // Add cancel button constraints if button was created
        if let cancelButton = cancelButton {
            constraints.append(contentsOf: [
                cancelButton.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20),
                cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                cancelButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }

        NSLayoutConstraint.activate(constraints)

        // Add tap-outside-to-dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)

        // Check if tap is outside of date picker and button areas
        if !datePicker.frame.contains(location) &&
           !buttonStackView.frame.contains(location) &&
           !titleLabel.frame.contains(location) {
            btnCancel(nil)
        }
    }

    override func didReceiveMemoryWarning() {
        // Releases the view if it doesn't have a superview.
        super.didReceiveMemoryWarning()

        // Release any cached data, images, etc that aren't in use.
    }




    // MARK: -
    // MARK: button actions

    @objc func cancelEvent(_ sender: Any) {
    }

    @objc func entryNewBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_NEW
        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }

    //- (IBAction) entryCopyBtnAction;
    @objc func dateSetBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_SET
        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }


    //- (IBAction) dateModeChoice:(id)sender;
    @objc func dateGotoBtnAction() {
        dpr?.date = datePicker.date
        dpr?.action = DPA_GOTO

        dismiss(animated: true)

        (presentationController?.delegate as? UIViewController)?.beginAppearanceTransition(true, animated: true)
        (presentationController?.delegate as? UIViewController)?.endAppearanceTransition()
    }

}
