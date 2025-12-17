import Foundation

public struct HomeModel {
    public var isLoading: Bool = false
    public var errorMessage: String?

    public var recentUsers: [User] = []
    public var activeUser: User? = nil

    // /user/:id/stats
    public var stats: UserStats? = nil

    // /user/:id/easy|medium|hard
    public var easy: EasyResponse? = nil
    public var medium: MediumResponse? = nil
    public var hard: HardResponse? = nil

    public var lastUpdated: Date? = nil

    // MARK: - Computed helpers

    public var username: String {
        activeUser?.username ?? "Unknown"
    }

    public var totalSolved: Int {
        stats?.totalSolved ?? 0
    }

    public var easySolved: Int {
        easy?.easySolved ?? 0
    }

    public var mediumSolved: Int {
        medium?.mediumSolved ?? 0
    }

    public var hardSolved: Int {
        hard?.hardSolved ?? 0
    }

    public var userRanking: Int? {
        stats?.ranking
    }

    public var dataAge: String {
        guard let lastUpdated else { return "Never" }
        let dt = Date().timeIntervalSince(lastUpdated)

        if dt < 60 { return "Just now" }
        if dt < 3600 { return "\(Int(dt / 60))m ago" }
        if dt < 86400 { return "\(Int(dt / 3600))h ago" }
        return "\(Int(dt / 86400))d ago"
    }

    public var statsSummary: [(String, Int, String)] {
        [
            ("Total", totalSolved, "blue"),
            ("Easy", easySolved, "green"),
            ("Medium", mediumSolved, "orange"),
            ("Hard", hardSolved, "red")
        ]
    }
}
