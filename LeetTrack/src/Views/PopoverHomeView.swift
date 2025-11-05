import SwiftUI
import Charts

// Define the tab selections
enum TabSelection: CaseIterable {
    case home
    case dailyQuestion
    case stats
    
    var title: String {
        switch self {
        case .home:
            return "Home"
        case .dailyQuestion:
            return "Daily"
        case .stats:
            return "Stats"
        }
    }
    
    var iconName: String {
        switch self {
        case .home:
            return "house.fill"
        case .dailyQuestion:
            return "calendar.badge.clock"
        case .stats:
            return "chart.pie.fill"
        }
    }
}

// TabView solution for macOS with profile name
struct PopoverHomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @State private var selectedTab: TabSelection = .home
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject private var currentProfile: Profile = ProfileManager.shared.currentProfile
    @State private var isEditingProfile: Bool = false
    @State private var tempProfileName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile header
            HStack {
                Button(action: {
                    tempProfileName = currentProfile.username
                    isEditingProfile = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        
                        Text(currentProfile.username)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Tab view content
            TabView(selection: $selectedTab) {
                // Home Tab
                VStack(spacing: 20) {
                    Text("Problems Solved")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Chart([
                        ProblemStats(category: "Easy", count: viewModel.homeModel.easySolved),
                        ProblemStats(category: "Medium", count: viewModel.homeModel.mediumSolved),
                        ProblemStats(category: "Hard", count: viewModel.homeModel.hardSolved)
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
                            Text("\(viewModel.homeModel.totalSolved)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartLegend(position: .bottom, alignment: .center)
                    .frame(height: 250) // Reduced height to accommodate profile header
                    
                    Spacer()
                }
                .padding()
                .tabItem {
                    Image(systemName: TabSelection.home.iconName)
                    Text(TabSelection.home.title)
                }
                .tag(TabSelection.home)
                
                // Daily Question Tab
                PopoverDaily()
                    .tabItem {
                        Image(systemName: TabSelection.dailyQuestion.iconName)
                        Text(TabSelection.dailyQuestion.title)
                    }
                    .tag(TabSelection.dailyQuestion)
                
                // Stats Tab
                PopoverStats()
                    .tabItem {
                        Image(systemName: TabSelection.stats.iconName)
                        Text(TabSelection.stats.title)
                    }
                    .tag(TabSelection.stats)
            }
        }
        .frame(width: 400, height: 400)
        .alert("Edit Profile Name", isPresented: $isEditingProfile,actions: {
            TextField("Profile Name", text: $tempProfileName)
            Button("Cancel", role: .cancel) {
                tempProfileName = currentProfile.username
            }
            Button("Save") {
                let trimmed = tempProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    Task {
                        await ProfileManager.shared.updateUsername(trimmed)
                    }
                }
                tempProfileName = currentProfile.username
            }
        }, message: {
            Text("Enter your LeetCode username")
        })
        .task {
            // Load profile from MongoDB first
            await ProfileManager.shared.loadProfile(userId: "default_user")
            // Then load LeetCode stats
            await viewModel.load(username: currentProfile.username, userId: currentProfile.username)
        }
    }
}
// Function where you can handle the profile name change
private func handleProfileNameChange(newName: String) {
    // Add your logic here for when the profile name is changed
    print("Profile name changed to: \(newName)")
    // You can save to UserDefaults, Core Data, or whatever storage you prefer
}


#Preview {
    PopoverHomeView()
        .frame(width: 400, height: 400)
}
