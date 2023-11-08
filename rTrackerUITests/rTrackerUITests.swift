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
        
        // clear alerts if first run
        sleep(1)
        //print(String("docs dir= \(rTracker_resource.ioFilePath(nil, access: true))"))
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
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTrackerDemoInstall() throws {
        app.tables.cells["trkr_👣rTracker demo"].tap()

        app.swipeRight()
        sleep(1)

        let fnTotalLabel = app.staticTexts["fnVal_total"]
        XCTAssertEqual(fnTotalLabel.label, "22.00")
        
        app.buttons["< rTracker"].tap()
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
        
        var targCell = app.tables.cells["👣rTracker demo_Yes!"]
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

        // restore original config
        app.buttons["edit"].tap()
        app.tables.cells["configt_👣rTracker demo"].tap()
        
        //let targCell = app.tables.cells["👣rTracker demo_Yes!"]
        //let coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["👣rTracker demo_Yes!"].tap()
        
        //let voPicker = app.otherElements["avoPicker"]
        app.pickerWheels.element(boundBy: 2).adjust(toPickerWheelValue: "dots")
        app.buttons["avoSave"].tap()
        app.buttons["addTrkrSave"].tap()
        app.buttons["rTracker"].tap()
        
        app.buttons["edit"].tap()
        app.segmentedControls["configTlistMode"].buttons["tlistMoveDel"].tap()
        targCell = app.tables.cells["configt_🚴 Exercise"]
        let moveToCell = app.tables.cells["configt_☕️🍷 Drinks"]
        var moveBtn = targCell.buttons["Reorder 🚴 Exercise"]
        moveBtn.press(forDuration: 0.5, thenDragTo: moveToCell)
        app.buttons["rTracker"].tap()
        
        sleep(1)
        
        let temp = initialTitles[2]
        initialTitles[2] = initialTitles[3]
        initialTitles[3] = temp
        
        newTitles = []
        for i in 0..<table.cells.count {
            let cell = table.cells.element(boundBy: i)
            newTitles.append(cell.staticTexts.firstMatch.label)
        }
        
        XCTAssertEqual(initialTitles, newTitles, "The order of cell titles is wrong")
        
        app.buttons["edit"].tap()
        app.segmentedControls["configTlistMode"].buttons["tlistMoveDel"].tap()
        
        moveBtn = moveToCell.buttons["Reorder ☕️🍷 Drinks"]
        moveBtn.press(forDuration: 0.5, thenDragTo: targCell)
    }
    
    func testSearchSetup() throws {
        let carCell = app.tables.cells["trkr_🚗 Car"]
        carCell.tap()
        
        let odFld = app.textFields["🚗 Car_odometer_numberfield"]
        let fuFld = app.textFields["🚗 Car_fuel_numberfield"]
        let tcFld = app.textFields["🚗 Car_total cost_numberfield"]
        let tfSw = app.switches["🚗 Car_tank full_switch"]
        let tbBtn = app.buttons["🚗 Car_notes_tbButton"]
        let tbtv = app.textViews["tbox-textview"]

        for i in 1...5 {
            odFld.tap()
            odFld.typeText("\(i)")
            fuFld.tap()
            fuFld.typeText("2")
            tcFld.tap()
            tcFld.typeText("4")
            tfSw.tap()
            tbBtn.tap()
            sleep(1)
            tbtv.tap()
            tbtv.typeText("target \(i)\n")
            if i<4 && i>1 {
                tbtv.typeText("extra\n")
            }
            if i<3 {
                tbtv.typeText("overlap\n")
            }
            // save and leave textbox editor
            app.buttons["tbox-save"].tap()
            app.buttons["🚗 Car"].tap()
            // save and return to car tracker
            app.buttons["trkrSave"].tap()
            if i != 5 {
                sleep(1)
                carCell.tap()
            }
        }
    }
    
    func testSearch() throws {
        let carCell = app.tables.cells["trkr_🚗 Car"]
        carCell.tap()
        
        let odFld = app.textFields["🚗 Car_odometer_numberfield"]
        /*
        let fuFld = app.textFields["🚗 Car_fuel_numberfield"]
        let tcFld = app.textFields["🚗 Car_total cost_numberfield"]
        let tfSw = app.switches["🚗 Car_tank full_switch"]
         */
        let tbBtn = app.buttons["🚗 Car_notes_tbButton"]
        let tbtv = app.textViews["tbox-textview"]
        
        XCTAssertEqual(odFld.value as! String, "54321", "odometer field not last value")
        
        tbBtn.tap()
        tbtv.tap()
        tbtv.typeText("extra\n")
        
        let srchSeg = app.segmentedControls["tbox-seg-search"]
        srchSeg.buttons["tbox-mode-srch"].tap()
        app.buttons["tbox-save"].tap()
        app.buttons["🚗 Car"].tap()
        sleep(1)
        let srchBtn = app.buttons["trkrSearch"]
        XCTAssert(srchBtn.exists, "no mag glass button")
        srchBtn.tap()
        var srchAlert = app.alerts["Search results"]
        XCTAssert(srchAlert.exists, "no search results alert")
        var alertBodyText = srchAlert.staticTexts.element(boundBy: 1).label
        var firstThreeWords = alertBodyText.split(separator: " ").prefix(3).joined(separator: " ")
        XCTAssertEqual(firstThreeWords, "2 entries highlighted", "alert text wrong 1")
        srchAlert.buttons["OK"].tap()
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "321", "odometer field not first result 321")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "21", "odometer field not second result 21")
        
        let ffBtn = app.buttons["Fast forward"]
        XCTAssert(ffBtn.exists, "no skip forward button")
        ffBtn.tap()
        
        tbBtn.tap()
        tbtv.tap()
        tbtv.typeText("extra\n")
        tbtv.typeText("overlap\n")
        srchSeg.buttons["tbox-mode-srch"].tap()
        app.buttons["tbox-save"].tap()
        app.buttons["🚗 Car"].tap()
        sleep(1)
        srchBtn.tap()
        srchAlert = app.alerts["Search results"]
        alertBodyText = srchAlert.staticTexts.element(boundBy: 1).label
        firstThreeWords = alertBodyText.split(separator: " ").prefix(3).joined(separator: " ")
        XCTAssertEqual(firstThreeWords, "3 entries highlighted", "alert text wrong 2")
        srchAlert.buttons["OK"].tap()
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "321", "odometer field not first result 321")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "21", "odometer field not second result 21")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "1", "odometer field not third result 1")
        ffBtn.tap()
        
        tbBtn.tap()
        tbtv.tap()
        tbtv.typeText("extra\n")
        tbtv.typeText("overlap\n")
        srchSeg.buttons["tbox-mode-srch"].tap()
        let srchMode = app.segmentedControls["tbox-seg-search-mode"]
        srchMode.buttons["tbox-srch-and"].tap()
        app.buttons["tbox-save"].tap()
        app.buttons["🚗 Car"].tap()
        sleep(1)
        srchBtn.tap()
        srchAlert = app.alerts["Search results"]
        alertBodyText = srchAlert.staticTexts.element(boundBy: 1).label
        firstThreeWords = alertBodyText.split(separator: " ").prefix(3).joined(separator: " ")
        XCTAssertEqual(firstThreeWords, "1 entries highlighted", "alert text wrong 2")
        srchAlert.buttons["OK"].tap()
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "21", "odometer field not second result 21")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "21", "went past result 1")
        ffBtn.tap()
        
        tbBtn.tap()
        tbtv.tap()
        tbtv.typeText("target 5\n")
        tbtv.typeText("overlap\n")
        srchSeg.buttons["tbox-mode-srch"].tap()
        app.buttons["tbox-save"].tap()
        app.buttons["🚗 Car"].tap()
        sleep(1)
        srchBtn.tap()
        srchAlert = app.alerts["Search results"]
        alertBodyText = srchAlert.staticTexts.element(boundBy: 1).label
        firstThreeWords = alertBodyText.split(separator: " ").prefix(3).joined(separator: " ")
        XCTAssertEqual(firstThreeWords, "3 entries highlighted", "alert text wrong 2")
        srchAlert.buttons["OK"].tap()
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "54321", "odometer field not first result 321")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "21", "odometer field not second result 21")
        app.swipeRight()
        XCTAssertEqual(odFld.value as! String, "1", "odometer field not third result 1")
        ffBtn.tap()
    }
    
    func testSearchClear() throws {
        app.buttons["edit"].tap()
        app.segmentedControls["configTlistMode"].buttons["tlistMoveDel"].tap()
        let carCell = app.tables.cells["configt_🚗 Car"]
        carCell.tap()
        sleep(1)
        carCell.buttons["Delete"].tap()
        let delAlert = app.alerts["Delete tracker 🚗 Car"]
        let delRecBtn = delAlert.buttons["Remove records only"]
        if delRecBtn.exists {
            delRecBtn.tap()
        } else {
            delAlert.buttons["Cancel"].tap()
        }

        app.buttons["rTracker"].tap()
        //app.tables.cells["configt_👣rTracker demo"].tap()
    }
    
    func testTrackerDemoUse() throws {
        let rTdemoCell = app.tables.cells["trkr_👣rTracker demo"]

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
        XCTAssertEqual(tbButton.label, expectedTbContent.replacingOccurrences(of: "\n", with: " "), "textBox button label not as expected")
        
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
        XCTAssertEqual((tbtv.value as! String), expectedTbContent, "The textbox content is incorrect")
        
        // return out and confirm
        app.buttons["👣rTracker demo"].tap()
        exitTrkrBtn.tap()
        XCTAssert(rTdemoCell.exists, "did not retrun to tracker list")
    }
    
    func testTrackerDemoClear() throws {
        let rTdemoCell = app.tables.cells["trkr_👣rTracker demo"]

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
        app.swipeRight()
        app.buttons["Delete"].tap()
        app.alerts["Delete entry"].buttons["Yes, delete"].tap()
        exitTrkrBtn.tap()
    }
    
    func testDeleteNewTracker() throws {
        let ttt = app.tables.cells["trkr_testTracker"]
        if ttt.exists {
            app.buttons["Edit"].tap()
            app.segmentedControls["configTlistMode"].buttons["tlistMoveDel"].tap()
            let targCell = app.tables.cells["configt_testTracker"]
            targCell.tap()
            sleep(1)
            targCell.buttons["Delete"].tap()
            let delAlert = app.alerts["Delete tracker testTracker"]
            let delTrkrBtn = delAlert.buttons["Delete tracker"]
            delTrkrBtn.tap()
            app.buttons["rTracker"].tap()
        }
    }
    
    func testClearNewTracker() throws {
        app.buttons["Edit"].tap()
        app.segmentedControls["configTlistMode"].buttons["tlistMoveDel"].tap()
        let targCell = app.tables.cells["configt_testTracker"]
        targCell.tap()
        sleep(1)
        targCell.buttons["Delete"].tap()
        let delAlert = app.alerts["Delete tracker testTracker"]
        let delRecBtn = delAlert.buttons["Remove records only"]
        if delRecBtn.exists {
            delRecBtn.tap()
        } else {
            delAlert.buttons["Cancel"].tap()
        }
        app.buttons["rTracker"].tap()
    }
    
    func testCreateNewTracker() throws {
        func addVal(_ targStr: String, noSave: Bool = false) {
            vname.tap()
            vname.typeText("v\(targStr)\n")
            //app.buttons["Done"].tap()
            while vpicker.value as! String != targStr {
                //vpicker.swipeUp()  // or .swipeDown() depending on the direction needed
                vpicker.adjust(toPickerWheelValue: targStr)
            }
            if noSave {
                return
            }
            saveBtn.tap()
            sleep(1)
            
            addValBtn.tap()
        }
        app.buttons["add"].tap()
        
        let addValBtn = app.tables.cells["trkrAddValue"]
        addValBtn.tap()
        
        let saveBtn = app.buttons["avoSave"]
        let avoCancel = app.buttons["avoCancel"]
        saveBtn.tap()
        
        var alert = app.alerts["Save Item"]
        XCTAssert(alert.exists, "no value set name alert")
        alert.buttons["OK"].tap()
        
        let vname = app.textFields["valueName"]
        let vpicker = app.pickerWheels.element(boundBy: 0)
        let avoConfig = app.buttons["avoConfig"]
        
        addVal("function", noSave:true)
        avoConfig.tap()
        alert = app.alerts["No variables for function"]
        XCTAssert(alert.exists, "no function need variables alert")
        alert.buttons["OK"].tap()
        app.buttons["avoCancel"].tap()
        addValBtn.tap()
        
        addVal("number")
        addVal("text")
        
        addVal("textbox", noSave:true)
        avoConfig.tap()
        app.buttons["tnull_vtextbox_tbnlBtn"].tap()
        app.buttons["configtvo_done"].tap()
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("slider")
        
        for i in 1...2 {
            addVal("choice", noSave:true)
            if i==1 {
                saveBtn.tap()
                alert = app.alerts["Save Choice"]
                XCTAssert(alert.exists, "no set choice alert")
                alert.buttons["OK"].tap()
            }
            
            vname.tap()
            vname.tap() // de-select exiting text
            vname.typeText("\(i)\n")
            //app.buttons["Done"].tap()
            //sleep(1)
            avoConfig.tap()
            for j in 1...(i*4) {
                    let tf = app.textFields["tnull_vchoice\(i)_\(j-1)tf"]
                    tf.tap()
                    tf.typeText("c\(j)\n")
                if i>1 {
                    let vtf = app.textFields["tnull_vchoice2_\(j-1)tfv"]
                    vtf.tap()
                    vtf.typeText("\(8-j)\n")
                }
            }
            app.buttons["configtvo_done"].tap()
            saveBtn.tap()
            addValBtn.tap()
        }
        

        addVal("yes/no")
        addVal("function")
        
        addVal("info", noSave:true)
        avoConfig.tap()
        let ival = app.textFields["tnull_vinfo_ivalTF"]
        ival.tap()
        ival.typeText("2.3\n")
        app.buttons["configtvo_done"].tap()
        saveBtn.tap()
        addValBtn.tap()
        
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("sumvnum")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("civnum")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("vc1")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("ynvc2")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("vtxt")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("vtb")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("sliderVal")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("vc2")
        saveBtn.tap()
        addValBtn.tap()
        
        addVal("function", noSave:true)
        vname.tap()
        vname.typeText("vnfo")
        saveBtn.tap()
        addValBtn.tap()
        
        
        avoCancel.tap()  // exit last addValObj
        
        let trkrSave = app.buttons["addTrkrSave"]
        trkrSave.tap()
        alert = app.alerts["Save Tracker"]
        XCTAssert(alert.exists, "no tracker set name alert")
        alert.buttons["OK"].tap()
        
        let tname = app.textFields["addTrkrName"]
        tname.tap()
        tname.typeText("testTracker")
        trkrSave.tap()
        
        //sleep(3)
        XCTAssert(app.tables.cells["trkr_testTracker"].exists, "new tracker not found")
    }
    
    func testModifyNewTracker() throws {
        app.buttons["edit"].tap()
        app.tables.cells["configt_testTracker"].tap()
        
        app.buttons["modTrkrConfig"].tap()
        app.buttons["testTracker_srBtn"].tap()
        app.buttons["configtvo_done"].tap()
        
        var targCell = app.tables.cells["testTracker_vfunction"]
        var coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        let fnSeg = app.segmentedControls["fnConfigSeg"]
        fnSeg.buttons["fnRange"].tap()
        
        var visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        if let currentPicker = visiblePickers.first {
            // Interact with the currentPicker
            currentPicker.adjust(toPickerWheelValue: "days")
        }

        //app.pickerWheels[testTracker_vfunction_frPkr].adjust(toPickerWheelValue: "days")
        
        app.textFields["testTracker_vfunction_fr0TF"].tap()
        app.textFields["testTracker_vfunction_fr0TF"].typeText("1\n")
        
        fnSeg.buttons["fnDefinition"].tap()
        //let pkr = app.pickerWheels.element(boundBy: 0)
        let add = app.buttons["configtv_fdaBtn"]
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        var pkr = visiblePickers.first!
        
        if pkr.exists {
            pkr.adjust(toPickerWheelValue: "sum")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vnumber")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "change_in")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vchoice1")
            add.tap()
            //delete test
            app.buttons["configtv_fddBtn"].tap()
            pkr.adjust(toPickerWheelValue: "vnumber")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vchoice1")
            add.tap()
            pkr.adjust(toPickerWheelValue: "-")
            add.tap()
            pkr.adjust(toPickerWheelValue: "(")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vyes/no")
            add.tap()
            pkr.adjust(toPickerWheelValue: "*")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vchoice2")
            add.tap()
            pkr.adjust(toPickerWheelValue: ")")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vtext")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vtextbox")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vslider")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vchoice2")
            add.tap()
            pkr.adjust(toPickerWheelValue: "+")
            add.tap()
            pkr.adjust(toPickerWheelValue: "vinfo")
            add.tap()
            pkr.adjust(toPickerWheelValue: "/")
            add.tap()
            pkr.adjust(toPickerWheelValue: "constant")
            add.tap()
        }

        let alert = app.alerts["Need Value"]
        XCTAssert(alert.exists, "no need value alert")
        alert.buttons["OK"].tap()
        app.textFields["testTracker_vfunction_fdcTF"].tap()
        app.textFields["testTracker_vfunction_fdcTF"].typeText("2\n")
        add.tap()
        
        fnSeg.buttons["Overview"].tap()
        let expectedRangeContent = "-1 days to current entry"
        let expectedDefnContent = "sum[vnumber] + change_in[vnumber] + vchoice1 - ( vyes/no * vchoice2 + vchoice1 ) + vtext + vtextbox + vslider + vchoice2 + vinfo /  2  "
        let rangeTV = app.textViews["configtv_frangeTV"]
        let defnTV = app.textViews["configtv_fdefnTV"]
        
        XCTAssertEqual(expectedRangeContent, rangeTV.value as? String)
        XCTAssertEqual(expectedDefnContent, defnTV.value as? String)
        
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //app.buttons["addTrkrSave"].tap()
        
        //--
        targCell = app.tables.cells["testTracker_sumvnum"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnRange"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        if let currentPicker = visiblePickers.first {
            // Interact with the currentPicker
            currentPicker.adjust(toPickerWheelValue: "days")
        }
        
        app.textFields["testTracker_sumvnum_fr0TF"].tap()
        app.textFields["testTracker_sumvnum_fr0TF"].typeText("1\n")
        
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "sum")
        add.tap()
        pkr.adjust(toPickerWheelValue: "vnumber")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        
        //--
        targCell = app.tables.cells["testTracker_civnum"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnRange"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        if let currentPicker = visiblePickers.first {
            // Interact with the currentPicker
            currentPicker.adjust(toPickerWheelValue: "days")
        }
        
        app.textFields["testTracker_civnum_fr0TF"].tap()
        app.textFields["testTracker_civnum_fr0TF"].typeText("1\n")
        
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "change_in")
        add.tap()
        pkr.adjust(toPickerWheelValue: "vnumber")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        
        //-
        targCell = app.tables.cells["testTracker_vc1"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "vchoice1")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        targCell = app.tables.cells["testTracker_ynvc2"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "(")
        add.tap()
        pkr.adjust(toPickerWheelValue: "vyes/no")
        add.tap()
        pkr.adjust(toPickerWheelValue: "*")
        add.tap()
        pkr.adjust(toPickerWheelValue: "vchoice2")
        add.tap()
        pkr.adjust(toPickerWheelValue: "+")
        add.tap()
        pkr.adjust(toPickerWheelValue: "vchoice1")
        add.tap()
        pkr.adjust(toPickerWheelValue: ")")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        targCell = app.tables.cells["testTracker_vtxt"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "vtext")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        app.swipeUp()
        //--
        targCell = app.tables.cells["testTracker_vtb"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "vtextbox")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        targCell = app.tables.cells["testTracker_sliderVal"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        pkr.adjust(toPickerWheelValue: "vslider")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        targCell = app.tables.cells["testTracker_vc2"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "vchoice2")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        targCell = app.tables.cells["testTracker_vnfo"]
        coordinate = targCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)) // center of the cell
        coordinate.tap()
        //app.tables.cells["testTracker_vfunction"].tap()
        app.buttons["avoConfig"].tap()
        fnSeg.buttons["fnDefinition"].tap()
        visiblePickers = app.pickerWheels.allElementsBoundByIndex.filter { $0.isHittable }
        pkr = visiblePickers.first!
        pkr.adjust(toPickerWheelValue: "vinfo")
        add.tap()
        app.buttons["configtvo_done"].tap()
        app.buttons["avoSave"].tap()
        //--
        
        app.buttons["addTrkrSave"].tap()
        
        app.buttons["rTracker"].tap()
    }
    
    func testPopulateNewTracker() throws {
        let strs = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight"]
        let choices = ["c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", ]
        app.tables.cells["trkr_testTracker"].tap()
        for i in 1...8 {
            app.textFields["testTracker_vnumber_numberfield"].tap()
            app.textFields["testTracker_vnumber_numberfield"].typeText("\(2*i)\n")
            app.textFields["testTracker_vtext_textfield"].tap()
            
            app.textFields["testTracker_vtext_textfield"].typeText("\(strs[i])\n")
            app.buttons["testTracker_vtextbox_tbButton"].tap()
            let tbtv = app.textViews["tbox-textview"]
            tbtv.tap()
            for j in 0...i {
                tbtv.typeText("\(strs[j])\n")
            }
            app.buttons["tbox-save"].tap()
            app.buttons["testTracker"].tap()
            
            let slider = app.sliders["testTracker_vslider_slider"]
            slider.adjust(toNormalizedSliderPosition: (CGFloat(i) * 0.1))
            if let sliderValue = slider.value as? String {
                print("slider val: \(sliderValue)")
            }
            let choice1Seg = app.segmentedControls["testTracker_vchoice1_choices"]
            if i<5 {
                choice1Seg.buttons[choices[i-1]].tap()
            }
            let choice2Seg = app.segmentedControls["testTracker_vchoice2_choices"]
            choice2Seg.buttons[choices[8 - i]].tap()
            
            if i % 2 == 0 {
                app.switches["testTracker_vyes/no_switch"].tap()
            }
            
            app.buttons["trkrSave"].tap()
        }
        app.buttons["< rTracker"].tap()
    }
    
    func testNewTrackerGo() throws {
        do {
            try testDeleteNewTracker()
            try testCreateNewTracker()
            try testModifyNewTracker()
            try testPopulateNewTracker()
        } catch {
            XCTFail("error: \(error)")
        }
        print("new tracker test done.")
        
    }
    
    func testLaunch() throws {
        app.tables.cells["trkr_testTracker"].tap()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        app.swipeRight()
        print("launched.")
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
