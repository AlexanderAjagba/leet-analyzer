import Foundation

@MainActor
final class StatsController: ObservableObject {
    @Published var model = StatsModel()

    private let userRepository: UserRepository
    private let sessionStore: SessionStore

    init(
        sessionStore: SessionStore,
        userRepository: UserRepository = UserRepository(http: HTTPClient())
    ) {
        self.sessionStore = sessionStore
        self.userRepository = userRepository
    }

    func loadRecentSubmissions(username: String? = nil) async {
        let targetUsername = username ?? sessionStore.activeUser?.username

        guard let targetUsername, !targetUsername.isEmpty else {
            model.isLoading = false
            model.errorMessage = "Set a username to see recent submissions."
            model.recentSubmissions = []
            model.lastUpdated = nil
            return
        }

        model.isLoading = true
        model.errorMessage = nil
        defer { model.isLoading = false }

        do {
            let resp = try await userRepository.fetchRecentSubmissions(username: targetUsername)
            model.recentSubmissions = resp.submissions
            model.lastUpdated = Date()
        } catch {
            model.errorMessage = "Failed to load recent submissions."
            // keep existing submissions so UI doesn't flash empty
        }
    }

    func forceRefresh(username: String? = nil) async {
        await loadRecentSubmissions(username: username)
    }
}
