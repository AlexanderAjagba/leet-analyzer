import Foundation

final class ProblemRepository {
    private let http: HTTPClient
    private let baseURL: URL

    init(http: HTTPClient, baseURL: URL = APIConfig.localBaseURL) {
        self.http = http
        self.baseURL = baseURL
    }

    func fetchProblemOfTheDay() async throws -> DailyQuestion {
        let url = baseURL
            .appendingPathComponent("problems")
            .appendingPathComponent("problem-of-the-day")
        return try await http.get(url)
    }
}
