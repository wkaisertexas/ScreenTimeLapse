/// Manages review creating based on Activity Levels
import Foundation
import SwiftUI
import StoreKit

/// A logging singleton to log whenever reviews complete. Called by the ``RecorderViewModel``
struct ReviewManager {
    @Environment(\.requestReview) private var requestReview
    
    @AppStorage("lastBundleAsked") private var lastBundleAsked: String = ""
    @AppStorage("timesVideoSaved") private var timesSaved = 0
    
    private let INITIAL_REVIEW_THRESHOLD = 5 // wait for 5 videos before asking
    private let FOLLOW_UP_REVIEW_THRESHOLD = 10 // wait for 10 videos before asking again
    
    /// Logging completed recordings
    func logCompletedRecordings() {
        timesSaved += 1
        
        if shouldAskForReview() {
            waitAndAskForReview()
        }
    }
    
    /// Determines whether or not a review should be saved
    private func shouldAskForReview () -> Bool {
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
            try await Task.sleep(for: .seconds(3))
            await requestReview()
        }
    }
}

let reviewManager = ReviewManager()
