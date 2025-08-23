import SwiftUI
@main
struct LeetTrackApp: App {
  // keep one instance of your view-model
//  @StateObject private var dbViewModel = DatabaseViewModel()

  var body: some Scene {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    WindowGroup {
      HomeView()
//        .environmentObject(dbViewModel)
    }
  }
}

