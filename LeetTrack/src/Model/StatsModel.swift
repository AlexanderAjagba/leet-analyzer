//
//  StatsModel.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import Foundation

struct StatsModel {
    var recentProblems: [LeetCodeProblem] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastUpdated: Date?
    
    // Check if data needs refresh (older than 1 hour)
    var needsRefresh: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 3600 // 1 hour
    }
}
