import Foundation
final class UserRepository {
    private let http: HTTPClient
    private let baseURL: URL

    init(http: HTTPClient, baseURL: URL = APIConfig.localBaseURL) {
        self.http = http
        self.baseURL = baseURL
    }

    private func userPath(_ username: String, _ suffix: String) -> URL {
        let escaped = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        return baseURL
            .appendingPathComponent("user")
            .appendingPathComponent(escaped)
            .appendingPathComponent(suffix)
    }

    func fetchStats(username: String) async throws -> UserStats {
        try await http.get(userPath(username, "stats"))
    }

    func fetchEasy(username: String) async throws -> EasyResponse {
        try await http.get(userPath(username, "easy"))
    }

    func fetchMedium(username: String) async throws -> MediumResponse {
        try await http.get(userPath(username, "medium"))
    }

    func fetchHard(username: String) async throws -> HardResponse {
        try await http.get(userPath(username, "hard"))
    }

    func fetchRecentSubmissions(username: String) async throws -> RecentSubmissionsResponse {
        try await http.get(userPath(username, "recent-submissions"))
    }
}
