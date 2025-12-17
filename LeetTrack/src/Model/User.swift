import Foundation

public struct User: Codable, Equatable, Hashable, Identifiable {
    public var id: String { username }
    let username: String
}

// /user/:id/stats
public struct UserStats: Codable, Equatable {
    let username: String
    let totalSolved: Int
    let ranking: Int?

    let totalSubmissionsCount: Int?
    let totalSubmissionsAttempts: Int?
    let totalSubmissionsByDifficulty: [DifficultySubmission]?
}

public struct DifficultySubmission: Codable, Equatable, Identifiable {
    public var id: String { difficulty }
    let difficulty: String
    let count: Int?
    let submissions: Int?
}

// /user/:id/easy
public struct EasyResponse: Codable, Equatable {
    let username: String
    let easySolved: Int
    let totalEasy: Int
}

// /user/:id/medium
public struct MediumResponse: Codable, Equatable {
    let username: String
    let mediumSolved: Int
    let totalMedium: Int
}

// /user/:id/hard
public struct HardResponse: Codable, Equatable {
    let username: String
    let hardSolved: Int
    let totalHard: Int
}

// /user/:id/recent-submissions
public struct RecentSubmissionsResponse: Codable, Equatable {
    let username: String
    let submissions: [RecentSubmission]
}
