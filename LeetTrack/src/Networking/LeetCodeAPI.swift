import Foundation

// MARK: - Public endpoints of alfa-leetcode-api
// Base: https://alfa-leetcode-api.onrender.com
// - "/:username"                  -> Profile + solved counts
// - "/:username/solved"          -> Solved counts by difficulty
// - "/problems"                  -> Problems list
// - "/problems?difficulty=EASY"  -> Problems filtered by difficulty (EASY|MEDIUM|HARD)

struct LeetCodeUserStatsResponse: Decodable {
    let totalSolved: Int?
    let totalQuestions: Int?
    let easySolved: Int?
    let mediumSolved: Int?
    let hardSolved: Int?
    let ranking: Int?
}

struct LeetCodeProblem: Decodable, Identifiable {
    let id: String
    let title: String?
    let titleSlug: String?
    let difficulty: String?
    let paidOnly: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "questionId"
        case title
        case titleSlug
        case difficulty
        case paidOnly
    }
}

struct LeetCodeDailyQuestion: Decodable {
    let title: String?
    let link: String?
    let questionId: String?
    let difficulty: String?
}

final class LeetCodeAPI {
    private let baseURL: String
    private let client: HTTPClient

    init(baseURL: String = "https://alfa-leetcode-api.onrender.com", client: HTTPClient = HTTPClient()) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.client = client
    }

    func fetchUserStats(username: String) async throws -> LeetCodeUserStatsResponse {
        let url = URL(string: "\(baseURL)/\(username)")!
        return try await client.get(url, responseType: LeetCodeUserStatsResponse.self)
    }

    func fetchProblems(difficulty: String? = nil) async throws -> [LeetCodeProblem] {
        var components = URLComponents(string: "\(baseURL)/problems")!
        if let difficulty, !difficulty.isEmpty {
            components.queryItems = [URLQueryItem(name: "difficulty", value: difficulty.uppercased())]
        }
        let url = components.url!
        return try await client.get(url, responseType: [LeetCodeProblem].self)
    }

    func fetchDailyQuestion() async throws -> LeetCodeDailyQuestion {
        let url = URL(string: "\(baseURL)/daily")!
        return try await client.get(url, responseType: LeetCodeDailyQuestion.self)
    }
}


