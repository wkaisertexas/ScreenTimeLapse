//
//  TimeLapzeUITests.swift
//  TimeLapzeUITests
//
//  Created by William Kaiser on 11/21/24.
//

import XCTest

final class TimeLapzeUITests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testExample() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    app.activate()

    app.wait(for: .runningForeground, timeout: 10)

    let menuBarExtra = app.images["menuBarApp"]

    for window in app.windows.allElementsBoundByAccessibilityElement {
      if window.isHittable {
        window.click()
      }
    }

    print(app)
    print(app)

    print("Windows------------")
    print(app.windows.allElementsBoundByAccessibilityElement)
    print("Getting the Menu bars------------")
    print(app.menuBars.allElementsBoundByAccessibilityElement)
    print("Menu Buttons------------")
    print(app.menuButtons.allElementsBoundByAccessibilityElement)
    print("Menu bar items------------")
    print(app.menuBarItems.allElementsBoundByAccessibilityElement)
    print("menus------------")
    print(app.menus.allElementsBoundByAccessibilityElement)
    print("browsers------------")
    print(app.browsers.allElementsBoundByAccessibilityElement)
    print("menu buttons------------")

    print(app.menuButtons.allElementsBoundByAccessibilityElement)
    print(app.alerts.allElementsBoundByAccessibilityElement)

    for item in app.menuBars.allElementsBoundByAccessibilityElement {
      print(item)
      if item.identifier == "menuBarApp" {
        XCTAssertTrue(false, "Found")
      }
    }

    for item in app.menuBarItems.allElementsBoundByAccessibilityElement {
      print(item)
      if item.identifier == "menuBarApp" {
        XCTAssertTrue(false, "Found")
      }
    }

    for element in app.menuBarItems.allElementsBoundByAccessibilityElement {
      print("Element: \(element), Identifier: \(element.identifier), Title: \(element.label)")
    }
    for element in app.menuBars.allElementsBoundByAccessibilityElement {
      print("Element: \(element), Identifier: \(element.identifier), Title: \(element.label)")
    }

    XCTAssertTrue(menuBarExtra.waitForExistence(timeout: 10), "Menu bar extra did not appear")

  }

  @MainActor
  func testLaunchPerformance() throws {
    //      if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
    //        // This measures how long it takes to launch your application.
    //          measure(metrics: [XCTApplicationLaunchMetric()]) {
    //            XCUIApplication().launch()
    //          }
    //      }
  }
}
