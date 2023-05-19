//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  rTrackerUITests.swift
//  rTrackerUITests
//
//  Created by Rob Miller on 29/09/2015.
//  Copyright © 2015 Robert T. Miller. All rights reserved.
//

class rTrackerUITests: XCTestCase {
    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // Use recording to get started writing UI tests.

        let app = XCUIApplication()
        app.navigationBars["rTracker"].buttons["Add"].tap()

        let tablesQuery = app.tables
        tablesQuery?.textFields["Name this Tracker"]?.tap()
        tablesQuery?.children(matching: .cell).element(boundBy: 0).children(matching: .textField).element.typeText("Newt")
        tablesQuery?.staticTexts["Add an item or value to track"]?.tap()

        let textField = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .textField).element
        textField.tap()
        textField.typeText("n")
        app.keys["more, numbers"].tap()
        textField.typeText("1")
        app.typeText("\n")
        app.pickerWheels["1 of 12"].swipeUp()
        app.pickerWheels["dots, 1 of 4"].swipeUp()

        let saveButton = app.navigationBars.matching(identifier: "Configure Item").buttons["Save"] as? XCUIElement
        saveButton?.tap()
        tablesQuery?.staticTexts["add another thing to track"]?.tap()
        app.pickerWheels["number, 1 of 8"].press(forDuration: 1.1)
        textField.tap()
        textField.typeText("t1")
        app.typeText("\n")

        let toolbarsQuery = app.toolbars
        toolbarsQuery?.buttons["2699"]?.tap()
        app.buttons["checked"].tap()
        toolbarsQuery?.buttons["2611"]?.tap()
        saveButton?.tap()
        app.navigationBars["Add tracker"].buttons["Save"].tap()
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
}