/// Manages review creating based on Activity Levels
import Foundation
import StoreKit
import SwiftUI

/// A logging singleton to log whenever reviews complete. Called by the ``RecorderViewModel``
class ReviewManager {
  static let shared = ReviewManager()
  
  @Environment(\.requestReview) private var requestReview

  
  @AppStorage("lastBundleAsked") private var lastBundleAsked: String = ""
  
  /// Videos saved by the user
  @AppStorage("timesVideoSaved") private var timesSaved: Int = 0
  
  /// Initial video ask threshold
  let initialReviewThreshold: Int = 5
  
  /// Second video ask threshold only when the bundle ID changes
  let followUpReviewThreshold: Int = 10
  
  /// Sleep time after a recording finishes to ask
  let reviewWait = 3.0

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
    guard lastBundleAsked != getCurrentAppVersion() else { return false }

    if lastBundleAsked == "" {
      // Never asked before
      if timesSaved < initialReviewThreshold { return false }
      if let bundle = getCurrentAppVersion() {
        lastBundleAsked = bundle
      }

      return true
    } else {
      // Already asked once
      if timesSaved < followUpReviewThreshold { return false }
      if let bundle = getCurrentAppVersion() {
        lastBundleAsked = bundle
      }

      return true
    }
  }
  
  func getCurrentAppVersion() -> String? {
    Bundle.currentAppVersion
  }

  /// Requests a review after a certain time
  func waitAndAskForReview() {
    Task {
      try await Task.sleep(for: .seconds(reviewWait))
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
