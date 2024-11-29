/// Manages review creating based on Activity Levels
import Foundation
import StoreKit
import SwiftUI

/// A logging singleton to log whenever reviews complete. Called by the ``RecorderViewModel``
struct ReviewManager {
  @Environment(\.requestReview) private var requestReview

  @AppStorage("lastBundleAsked") private var lastBundleAsked: String = ""
  @AppStorage("timesVideoSaved") private var timesSaved = 0

  private let INITIAL_REVIEW_THRESHOLD = 5  // wait for 5 videos before asking
  private let FOLLOW_UP_REVIEW_THRESHOLD = 10  // wait for 10 videos before asking again
  private let REVIEW_WAIT = 3  // wait time for a review

  /// Logging completed recordings
  func logCompletedRecordings() {
    timesSaved += 1

    if shouldAskForReview() {
      waitAndAskForReview()
    }
  }

  /// Determines whether or not a review should be saved
  private func shouldAskForReview() -> Bool {
    // Checking if we have already asked for a review
    guard lastBundleAsked != Bundle.currentAppVersion else { return false }

    if lastBundleAsked.count == 0 {
      // Never asked before
      if timesSaved < INITIAL_REVIEW_THRESHOLD { return false }
      if let bundle = Bundle.currentAppVersion {
        lastBundleAsked = bundle
      }

      return true
    } else {
      // Already asked once
      if timesSaved < FOLLOW_UP_REVIEW_THRESHOLD { return false }
      if let bundle = Bundle.currentAppVersion {
        lastBundleAsked = bundle
      }

      return true
    }
  }

  /// Requests a review after a certain time
  private func waitAndAskForReview() {
    Task {
      try await Task.sleep(for: .seconds(REVIEW_WAIT))
      await requestReview()
    }
  }

  /// Asks for a review if the user requests it
  public func getReview() {
    Task {
      await requestReview()
    }
  }
}

let reviewManager = ReviewManager()
