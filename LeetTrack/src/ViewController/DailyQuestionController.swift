import Foundation

@MainActor
final class DailyQuestionController: ObservableObject {
    @Published var model = DailyQuestionModel()

    private let problemRepository: ProblemRepository

    init(problemRepository: ProblemRepository = ProblemRepository(http: HTTPClient())) {
        self.problemRepository = problemRepository
    }

    func loadDailyQuestion() async {
        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }

        do {
            model.dailyQuestion = try await problemRepository.fetchProblemOfTheDay()
        } catch {
            model.errorMessage = "Not available right now"
            model.dailyQuestion = nil
        }
    }

    // With your new backend caching, “force refresh” usually means “hit backend again”.
    func forceRefreshDailyQuestion() async {
        await loadDailyQuestion()
    }
}
