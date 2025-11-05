import Foundation

/// Repository providing stats and problems with in-memory session cache
final class LeetCodeRepository {
    private let api: LeetCodeAPI

    private var statsCache: [String: (timestamp: Date, value: LeetCodeUserStatsResponse)] = [:]
    private var problemsCache: [String: (timestamp: Date, value: [LeetCodeProblem])] = [:]
    private var dailyQuestionCache: (timestamp: Date, value: LeetCodeDailyQuestion)?
    private let cacheTTL: TimeInterval = 300

    init(api: LeetCodeAPI = LeetCodeAPI()) {
        self.api = api
    }

    func getStats(username: String) async throws -> LeetCodeUserStatsResponse {
        if let cached = statsCache[username], Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.value
        }
        let stats = try await api.fetchUserStats(username: username)
        statsCache[username] = (Date(), stats)
        return stats
    }

    func getProblems(difficulty: String?) async throws -> [LeetCodeProblem] {
        let key = (difficulty ?? "ALL").uppercased()
        if let cached = problemsCache[key], Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.value
        }
        let problems = try await api.fetchProblems(difficulty: difficulty)
        problemsCache[key] = (Date(), problems)
        return problems
    }

    func getDailyQuestion() async throws -> LeetCodeDailyQuestion {
        if let cached = dailyQuestionCache, Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.value
        }
        let daily = try await api.fetchDailyQuestion()
        dailyQuestionCache = (Date(), daily)
        return daily
    }
}


