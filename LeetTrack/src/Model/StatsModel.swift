//
//  StatsModel.swift
//  LeetTrack
//

import Foundation

public struct RecentSubmission: Codable, Equatable, Identifiable {
    public var id: String { "\(titleSlug ?? title)-\(timestamp ?? "")" }

    let title: String
    let titleSlug: String?
    let status: String?
    let language: String?
    let timestamp: String?  // ISO-ish string from your backend
}

struct StatsModel {
    var recentSubmissions: [RecentSubmission] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastUpdated: Date?

    // Check if data needs refresh (older than 1 hour)
    var needsRefresh: Bool {
        guard let lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 3600
    }
}
