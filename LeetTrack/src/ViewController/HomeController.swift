import Foundation
import SwiftUI

@MainActor
final class HomeController: ObservableObject {
    @Published var homeModel = HomeModel()

    private let userRepository: UserRepository
    private let sessionStore: SessionStore

    init(
        sessionStore: SessionStore,
        userRepository: UserRepository = UserRepository(http: HTTPClient())
    ) {
        self.sessionStore = sessionStore
        self.userRepository = userRepository

        // Mirror session's active user into homeModel (optional but convenient)
        homeModel.activeUser = sessionStore.activeUser
    }

    /// Load user data from your backend (which handles Mongo cache + refresh).
    func loadUserProfile(username: String) {
        Task {
            homeModel.isLoading = true
            homeModel.errorMessage = nil
            defer { homeModel.isLoading = false }

            do {
                // Set active user globally
                let user = User(username: username)
                sessionStore.activeUser = user
                homeModel.activeUser = user

                // Fetch concurrently
                async let statsTask = userRepository.fetchStats(username: username)
                async let easyTask = userRepository.fetchEasy(username: username)
                async let mediumTask = userRepository.fetchMedium(username: username)
                async let hardTask = userRepository.fetchHard(username: username)

                homeModel.stats = try await statsTask
                homeModel.easy = try await easyTask
                homeModel.medium = try await mediumTask
                homeModel.hard = try await hardTask

                homeModel.lastUpdated = Date()

                // Update recent users (dedupe + most recent first)
                homeModel.recentUsers.removeAll(where: { $0.username == username })
                homeModel.recentUsers.insert(user, at: 0)

            } catch {
                homeModel.errorMessage = "Failed to load user: \(error.localizedDescription)"
            }
        }
    }

    func forceRefreshProfile() {
        guard let username = sessionStore.activeUser?.username else { return }
        loadUserProfile(username: username)
    }

    func loadRecentUser(_ user: User) {
        loadUserProfile(username: user.username)
    }

    func clearProfile() {
        sessionStore.activeUser = nil
        homeModel.activeUser = nil

        homeModel.stats = nil
        homeModel.easy = nil
        homeModel.medium = nil
        homeModel.hard = nil

        homeModel.lastUpdated = nil
        homeModel.errorMessage = nil
    }

    func deleteUser(username: String) {
        // Local-only delete (since backend stores user data for caching purposes).
        homeModel.recentUsers.removeAll(where: { $0.username == username })

        if sessionStore.activeUser?.username == username {
            clearProfile()
        }
    }

    var hasValidProfile: Bool {
        homeModel.activeUser != nil && homeModel.errorMessage == nil
    }

    var profileNeedsRefresh: Bool {
        guard let last = homeModel.lastUpdated else { return true }
        return Date().timeIntervalSince(last) > 3600
    }
}
