import SwiftUI
import Charts

enum TabSelection: CaseIterable {
    case home, dailyQuestion, stats

    var title: String {
        switch self {
        case .home: return "Home"
        case .dailyQuestion: return "Daily"
        case .stats: return "Stats"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .dailyQuestion: return "calendar.badge.clock"
        case .stats: return "chart.pie.fill"
        }
    }
}

struct PopoverHomeView: View {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var homeController: HomeController

    @State private var selectedTab: TabSelection = .home
    @State private var isEditingUsername = false
    @State private var tempUsername = ""

    init() {
        let session = SessionStore()
        _sessionStore = StateObject(wrappedValue: session)
        _homeController = StateObject(wrappedValue: HomeController(sessionStore: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $selectedTab) {
                homeTab
                    .tabItem { Image(systemName: TabSelection.home.iconName); Text(TabSelection.home.title) }
                    .tag(TabSelection.home)

                PopoverDaily()
                    .tabItem { Image(systemName: TabSelection.dailyQuestion.iconName); Text(TabSelection.dailyQuestion.title) }
                    .tag(TabSelection.dailyQuestion)

                // This assumes your PopoverStats init takes sessionStore:
                PopoverStats(sessionStore: sessionStore)
                    .tabItem { Image(systemName: TabSelection.stats.iconName); Text(TabSelection.stats.title) }
                    .tag(TabSelection.stats)
            }
        }
        .frame(width: 400, height: 400)
        .alert("Edit Username", isPresented: $isEditingUsername) {
            TextField("LeetCode username", text: $tempUsername)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                sessionStore.setActiveUser(username: trimmed)
            }
        } message: {
            Text("Enter your LeetCode username")
        }
        .task {
            if sessionStore.activeUser == nil {
                sessionStore.setActiveUser(username: "starlegendgod")
                homeController.loadUserProfile(username: "starlegendgod")
            }
        }
        .onChange(of: sessionStore.activeUser?.username) { _, newValue in
            guard let newValue else { return }
            homeController.loadUserProfile(username: newValue)
        }
        .environmentObject(sessionStore)
    }

    private var header: some View {
        HStack {
            Button {
                tempUsername = sessionStore.activeUser?.username ?? ""
                isEditingUsername = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))

                    Text(sessionStore.activeUser?.username ?? "Set username")
                        .font(.headline)
                        .fontWeight(.medium)

                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                homeController.forceRefreshProfile()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .disabled(homeController.homeModel.isLoading || sessionStore.activeUser == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var homeTab: some View {
        VStack(spacing: 16) {
            Text("Problems Solved")
                .font(.title2)
                .fontWeight(.semibold)

            if homeController.homeModel.isLoading {
                ProgressView("Loading...").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = homeController.homeModel.errorMessage {
                Text(err).foregroundStyle(.secondary)
            } else {
                Chart([
                    ProblemStats(category: "Easy", count: homeController.homeModel.easySolved),
                    ProblemStats(category: "Medium", count: homeController.homeModel.mediumSolved),
                    ProblemStats(category: "Hard", count: homeController.homeModel.hardSolved)
                ]) { dataPoint in
                    SectorMark(
                        angle: .value("Count", dataPoint.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", dataPoint.category))
                }
                .overlay {
                    VStack {
                        Text("\(homeController.homeModel.totalSolved)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 250)

                Text("Updated \(homeController.homeModel.dataAge)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}
