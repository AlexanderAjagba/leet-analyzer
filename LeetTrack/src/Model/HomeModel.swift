import Foundation

public struct HomeModel {
    public var profile: Profile?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var recentProfiles: [Profile] = []
    
    // Computed properties for easy access to stats
    public var totalSolved: Int {
        return profile?.totalQuestions ?? 0
    }
    
    public var easySolved: Int {
        return profile?.easyQuestions ?? 0
    }
    
    public var mediumSolved: Int {
        return profile?.mediumQuestions ?? 0
    }
    
    public var hardSolved: Int {
        return profile?.hardQuestions ?? 0
    }
    
    public var userRanking: Int? {
        return profile?.ranking
    }
    
    public var username: String {
        return profile?.username ?? "Unknown"
    }
    
    public var lastUpdated: Date? {
        return profile?.lastUpdated
    }
    
    public var dataAge: String {
        guard let lastUpdated = lastUpdated else { return "Never" }
        
        let timeInterval = Date().timeIntervalSince(lastUpdated)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    // Helper method to get progress percentage for each difficulty
    public func getProgressPercentage(for difficulty: String) -> Double {
        guard let profile = profile else { return 0.0 }
        
        switch difficulty.lowercased() {
        case "easy":
            return profile.easyQuestions != nil ? Double(profile.easyQuestions!) / 100.0 : 0.0
        case "medium":
            return profile.mediumQuestions != nil ? Double(profile.mediumQuestions!) / 100.0 : 0.0
        case "hard":
            return profile.hardQuestions != nil ? Double(profile.hardQuestions!) / 100.0 : 0.0
        default:
            return 0.0
        }
    }
    
    // Get statistics summary for display
    public var statsSummary: [(String, Int, String)] {
        return [
            ("Total", totalSolved, "blue"),
            ("Easy", easySolved, "green"),
            ("Medium", mediumSolved, "orange"),
            ("Hard", hardSolved, "red")
        ]
    }
}
