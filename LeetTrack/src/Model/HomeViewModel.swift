import Foundation

class HomeViewModel: ObservableObject {
    @Published var homeModel = HomeModel()
    private let leetRepository = LeetCodeRepository()
    @Published var questions: [LeetCodeProblem] = []
    @Published var availableDifficulties: [String] = ["All", "Easy", "Medium", "Hard"]
    @Published var selectedDifficulty: String = "All"

    @MainActor
    func load(username: String, userId: String) async {
        homeModel.isLoading = true
        defer { homeModel.isLoading = false }
        homeModel.errorMessage = nil

        do {
            // Fetch stats from LeetCode API
            let stats = try await leetRepository.getStats(username: ProfileManager.shared.currentProfile.username)
            await MainActor.run {
                let profile = ProfileManager.shared.currentProfile
                profile.ranking = stats.ranking
                profile.easyQuestions = stats.easySolved
                profile.mediumQuestions = stats.mediumSolved
                profile.hardQuestions = stats.hardSolved
                profile.totalQuestions = stats.totalSolved
                profile.lastUpdated = Date()
            }

            try await loadQuestions()
        } catch {
            await MainActor.run { self.homeModel.errorMessage = error.localizedDescription }
        }
    }

    func loadQuestions() async throws {
        let difficulty = selectedDifficulty == "All" ? nil : selectedDifficulty
        let items = try await leetRepository.getProblems(difficulty: difficulty)
        await MainActor.run { self.questions = items }
    }
}
