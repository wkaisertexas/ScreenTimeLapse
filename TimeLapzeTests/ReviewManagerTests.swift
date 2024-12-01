import SwiftUI
import XCTest

@testable import TimeLapze

/// Does not ask for a review, just logs that it is called
class ReviewManagerTestable: ReviewManager {
  /// How many times ``waitAndAskForReview`` was called
  var reviewsAskedFor: Int = 0

  /// Editable app vresion
  var appVersion: String = "1.0"

  override func getCurrentAppVersion() -> String? {
    return appVersion
  }

  /// Does not ask for a review, just logs that it is called
  override func waitAndAskForReview() {
    reviewsAskedFor += 1
  }
}

/// Testing the ``ReviewManager``
final class ReviewManagerTests: XCTestCase {
  override func setUp() {
    super.setUp()

    UserDefaults.standard.removeObject(forKey: "timesVideoSaved")
    UserDefaults.standard.removeObject(forKey: "lastBundleAsked")
  }

  override func tearDown() {
    UserDefaults.standard.removeObject(forKey: "timesVideoSaved")
    UserDefaults.standard.removeObject(forKey: "lastBundleAsked")

    super.tearDown()
  }

  /// Tests the logic of calling and asking for a review on time
  func testInitialReview() throws {
    let reviewManager = ReviewManagerTestable()

    XCTAssertTrue(reviewManager.initialReviewThreshold > 1, "Should ask for a review at least once")
    XCTAssertTrue(
      reviewManager.followUpReviewThreshold > reviewManager.initialReviewThreshold,
      "Follow up should be greater than the intial threshold")

    for _ in 1...reviewManager.initialReviewThreshold {
      XCTAssertTrue(reviewManager.reviewsAskedFor == 0, "Should not have asked yet")
      reviewManager.logCompletedRecordings()
    }

    XCTAssertTrue(reviewManager.reviewsAskedFor == 1, "Should have asked for a review once")
  }

  /// Tests reviewing the new app
  func testNewAppVersion() throws {
    let reviewManager = ReviewManagerTestable()

    // first review
    for _ in 1...reviewManager.initialReviewThreshold {
      XCTAssertTrue(reviewManager.reviewsAskedFor == 0, "Should not have asked yet")
      reviewManager.logCompletedRecordings()
    }

    XCTAssertTrue(reviewManager.reviewsAskedFor == 1, "Should have asked for a review once")

    // updating the app version
    reviewManager.appVersion = "1.1"

    // Follow up testing
    for _ in 1...(reviewManager.followUpReviewThreshold - reviewManager.initialReviewThreshold) {
      XCTAssertTrue(reviewManager.reviewsAskedFor == 1, "Should only have asked once")
      reviewManager.logCompletedRecordings()
    }

    XCTAssert(reviewManager.reviewsAskedFor == 2, "Should have asked for another review")
  }
}
