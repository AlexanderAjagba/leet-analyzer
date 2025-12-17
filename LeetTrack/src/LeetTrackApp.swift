import SwiftUI

@main
struct LeetTrackApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

        WindowGroup {
            HomeView(sessionStore: session)
                .environmentObject(session)
        }
    }
}
