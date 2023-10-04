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
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
