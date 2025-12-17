import SwiftUI
import Charts

// structure for your chart
struct ProblemStats: Identifiable {
    let category: String
    let count: Int
    let id = UUID()
}

enum SelectedView: String, CaseIterable, Identifiable {
    case home = "Home"
    case dailyQuestion = "Daily Question"
    case lastSolved = "Last Solved"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .dailyQuestion: return "questionmark.circle"
        case .lastSolved: return "chart.bar"
        }
    }
}

struct HomeView: View {
    @ObservedObject private var sessionStore: SessionStore
    @StateObject private var homeController: HomeController

    @State private var selectedView: SelectedView? = .home
    @State private var isEditingUsername = false
    @State private var tempUsername = ""

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        _homeController = StateObject(wrappedValue: HomeController(sessionStore: sessionStore))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            // Optional: set a default user once
            if sessionStore.activeUser == nil {
                let defaultUser = "starlegendgod"
                sessionStore.setActiveUser(username: defaultUser)
                homeController.loadUserProfile(username: defaultUser)
            }
        }
        .onChange(of: sessionStore.activeUser?.username) { _, newValue in
            guard let newValue, !newValue.isEmpty else { return }
            homeController.loadUserProfile(username: newValue)
        }
        .environmentObject(sessionStore)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack {
                Text("Sections")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            List(SelectedView.allCases, selection: $selectedView) { view in
                Label(view.rawValue, systemImage: view.systemImage)
                    .tag(view)
            }
            .navigationTitle("LeetTrack")

            usernameHeader
        }
        .frame(minWidth: 200)
    }

    private var usernameHeader: some View {
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
        }
        .alert("Edit Username", isPresented: $isEditingUsername) {
            TextField("LeetCode username", text: $tempUsername)

            Button("Cancel", role: .cancel) {}

            Button("Save") {
                let trimmed = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                sessionStore.setActiveUser(username: trimmed)
            }
        } message: {
            Text("Enter your LeetCode username")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedView {
            switch selectedView {
            case .home:
                homeContent
                    .navigationTitle("Home")

            case .dailyQuestion:
                DailyQuestionView()
                    .navigationTitle("Daily Question")

            case .lastSolved:
                StatsView(sessionStore: sessionStore)
                    .navigationTitle("Statistics")
            }
        } else {
            ContentUnavailableView(
                "Select a View",
                systemImage: "sidebar.left",
                description: Text("Choose an option from the sidebar")
            )
        }
    }

    private var homeContent: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Problems Solved")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    homeController.forceRefreshProfile()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(homeController.homeModel.isLoading || sessionStore.activeUser == nil)
                .help("Refresh")
            }

            if homeController.homeModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if let err = homeController.homeModel.errorMessage {
                Text(err)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else if homeController.homeModel.totalSolved == 0 {
                ContentUnavailableView(
                    "No stats yet",
                    systemImage: "chart.pie",
                    description: Text("Try refresh or check the username.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                .frame(height: 300)

                Text("Updated \(homeController.homeModel.dataAge)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}
