//
//  rTrackerUITests.swift
//  rTrackerUITests
//
//  Created by Robert Miller on 03/10/2023.
//  Copyright © 2023 Robert T. Miller. All rights reserved.
//

import XCTest

final class rTrackerUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        /*
         // can't do anything about access contacts alert
         
        addUIInterruptionMonitor(withDescription: "Contacts Permission") { (alert) -> Bool in
            if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
                return true
            }
            return false
        }
         */
        
        app.launch()
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTrackerDemoInstall() throws {
        app.tables.cells["trkr_👣rTracker demo{\n}"].tap()

        app.swipeRight()
        sleep(1)

        let fnTotalLabel = app.staticTexts["fnVal_total"]
        XCTAssertEqual(fnTotalLabel.label, "22.00")
    }

    func testEditTrackerRank() throws {
        
        let table = app.tables["trackerList"]

         // Get initial order of cell titles
         var initialTitles: [String] = []
         for i in 0..<table.cells.count {
             let cell = table.cells.element(boundBy: i)
             initialTitles.append(cell.staticTexts.firstMatch.label)
         }
        
        app.buttons["edit"].tap()
        app.tables.cells["configt_👣rTracker demo"].tap()
        
        let targCell = app.tables.cells["👣rTracker demo_Yes!"]
        let coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["👣rTracker demo_Yes!"].tap()
        
        //let voPicker = app.otherElements["avoPicker"]
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "bar")
        app.buttons["avoSave"].tap()
        app.buttons["addTrkrSave"].tap()
        app.buttons["rTracker"].tap()
        
        var newTitles: [String] = []
        for i in 0..<table.cells.count {
            let cell = table.cells.element(boundBy: i)
            newTitles.append(cell.staticTexts.firstMatch.label)
        }

        XCTAssertEqual(initialTitles, newTitles, "The order of cell titles has changed!")

    }
    
    func testTrackerDemoUse() throws {
        let rTdemoCell = app.tables.cells["trkr_👣rTracker demo{\n}"]
        sleep(1)
        
        let apacheAlert = app.alerts["rTracker is free software."]
        if apacheAlert.exists {
            apacheAlert.buttons["Accept"].tap()
            sleep(1)
        }
        let authAlert = app.alerts["Authorise notifications"]
        if authAlert.exists {
            authAlert.buttons["OK"].tap()
            sleep(1)
        }

        // enter demo tracker, if old data then discard, exit and re-enter
        rTdemoCell.tap()
        let exitTrkrBtn = app.buttons["< rTracker"]
        exitTrkrBtn.tap()
        let modAlert = app.alerts["👣rTracker demo modified"]
        if modAlert.exists {
            modAlert.buttons["Discard"].tap()
            sleep(1)
        }
        rTdemoCell.tap()
        sleep(1)
        // set number field
        let nField = app.textFields["👣rTracker demo_Number_numberfield"]
        nField.tap()
        nField.typeText("13.22")
        app.buttons["Done"].tap()
        
        // activate Yes! switch and verify
        let ySwitch = app.switches["👣rTracker demo_Yes!_switch"]
        ySwitch.tap()
        XCTAssertEqual(ySwitch.value as! String, "1", "The Yes! switch should be On")

        // confirm function total captures Yes! switch
        let fnTotalLabel = app.staticTexts["fnVal_total"]
        XCTAssertEqual(fnTotalLabel.label, "1.00")
        
        // test enable slider and default slider value counted
        let sliderEnable = app.switches["👣rTracker demo_Low|High_enable"]
        sliderEnable.tap()
        XCTAssertEqual(fnTotalLabel.label, "51.00")
        sliderEnable.tap()
        XCTAssertEqual(sliderEnable.value as! String, "0", "The sliderEnable switch should be Off")
        
        // test slider action enables and function counts result
        let slider = app.sliders["👣rTracker demo_Low|High_slider"]
        slider.adjust(toNormalizedSliderPosition: 0.25)  // sets to 24 slider value
        XCTAssertEqual(sliderEnable.value as! String, "1", "The sliderEnable switch should be On")
        XCTAssertEqual(fnTotalLabel.label, "25.00", "function total is incorrect (slider) before save")
        
        // test choice buttons enable and non-default values counted
        let choiceSeg = app.segmentedControls["👣rTracker demo_Choices with values (e.g. Likert scale)_choices"]
        choiceSeg.buttons["Bad"].tap()
        let choiceEnable = app.switches["👣rTracker demo_Choices with values (e.g. Likert scale)_enable"]
        XCTAssertEqual(choiceEnable.value as! String, "1", "The choiceEnable switch should be On")
        let fnChoiceVal = app.staticTexts["fnVal_choice value "]
        XCTAssertEqual(fnChoiceVal.label, "-2", "choice value incorrect")
        choiceSeg.buttons["Good"].tap()
        XCTAssertEqual(fnTotalLabel.label, "27.00", "function total is incorrect (choice) before save")
        
        // enter textbox editor
        let tbButton = app.buttons["👣rTracker demo_Text 📖 with history and search_tbButton"]
        tbButton.tap()
        
        // confirm on keyboard initially and insert 'rTracker'
        let tbseg = app.segmentedControls["tbox-seg-control"]
        let segKybd = tbseg.buttons["tbox-seg-keyboard"]
        XCTAssertTrue(segKybd.isSelected, "The 'tbox-seg-keyboard' segment should be selected")
        
        let tbtv = app.textViews["tbox-textview"]
        tbtv.typeText("rTracker\n")
        
        // confirm history exists, modify and add line
        tbseg.buttons["tbox-seg-history"].tap()
        let histWheel = app.pickerWheels.element(boundBy: 0)
        //histWheel.adjust(toPickerWheelValue: "Use the search 🔍 to find them")
        while histWheel.value as! String != "Use the search 🔍 to find them" {
            histWheel.swipeUp()  // or .swipeDown() depending on the direction needed
        }

        let tbAdd = app.buttons["tbox-add-sel-line"]
        tbAdd.tap()
        
        // add first contact
        tbseg.buttons["tbox-seg-contacts"].tap()

        /*
         // unable to dismiss contacts alert
        sleep(1)
        let contactsAlert = app.alerts["“rTracker” Would Like to Access Your Contacts"]
        if contactsAlert.exists {
            contactsAlert.buttons["OK"].tap()
            sleep(1)
        }
         */
        tbAdd.tap()
        
        let expectedTbContent = """
rTracker
Use the search 🔍 to find them
Kate Bell

"""
        // save and leave textbox editor
        app.buttons["tbox-save"].tap()
        app.buttons["👣rTracker demo"].tap()
        
        // confirm textbox button shows first line
        XCTAssertEqual(tbButton.label, expectedTbContent.replacingOccurrences(of: "\n", with: " "), "textBox button label not 'rTracker'")
        
        // set text string
        let olField = app.textFields["👣rTracker demo_One liner_textfield"]
        olField.tap()
        olField.typeText("rules!")
        
        // try to leave, should hit 'tracker modified' alert; choose save on alert, return to tracker list
        exitTrkrBtn.tap()
        
        XCTAssert(modAlert.exists, "tracker modified alert should be shown - to tracker list")
        modAlert.buttons["Save"].tap()

        // enter demo tracker again, trigger 'Yes!' and confirm swipeRight triggers alert; discard
        rTdemoCell.tap()
        ySwitch.tap()
        app.swipeRight()
        XCTAssert(modAlert.exists, "tracker modified alert should be shown - swipe right")
        modAlert.buttons["Discard"].tap()
        
        // confirm function and textfield values
        XCTAssertEqual(nField.value as! String, "13.22", "The number field's value is incorrect")
        XCTAssertEqual(fnTotalLabel.label, "27.00", "function total is incorrect after save")
        let fnActiveVals = app.staticTexts["fnVal_active values"]
        XCTAssertEqual(fnActiveVals.label, "6", "active values incorrect")
        
        XCTAssertEqual(olField.value as! String, "rules!", "The one liner field's value is incorrect")
        XCTAssertEqual(tbButton.label, expectedTbContent.replacingOccurrences(of: "\n", with: " "), "textBox button label not 'rTracker'")
        
        // confirm textBox value
        tbButton.tap()
        let foo = tbtv.value as! String
        print(">\(foo)<")
        print(">\(expectedTbContent)<")
        XCTAssertEqual((tbtv.value as! String), expectedTbContent, "The textbox content is incorrect")
        
        // return out and confirm
        app.buttons["👣rTracker demo"].tap()
        exitTrkrBtn.tap()
        XCTAssert(rTdemoCell.exists, "did not retrun to tracker list")
        
        
    }
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
