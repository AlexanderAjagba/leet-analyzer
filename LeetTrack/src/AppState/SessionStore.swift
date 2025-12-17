import Foundation

@MainActor
public final class SessionStore: ObservableObject {
    @Published var activeUser: User? = nil

    func setActiveUser(username: String) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            activeUser = nil
            return
        }
        activeUser = User(username: trimmed)
    }

    func clear() {
        activeUser = nil
    }
}
