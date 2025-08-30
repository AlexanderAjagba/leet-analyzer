import SwiftUI
import Charts

// 1. Define the data structure for your chart (assuming this exists)
//struct ProblemStats: Identifiable {
//    let category: String
//    let count: Int
//    let id = UUID()
//}
//
//// Sample data for the chart to make the preview work
//let problemData: [ProblemStats] = [
//    .init(category: "Easy", count: 120),
//    .init(category: "Medium", count: 180),
//    .init(category: "Hard", count: 45)
//]

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
    private var totalProblems: Int {
        problemData.reduce(0) { $0 + $1.count }
    }
    
    @State private var selectedTab: TabSelection = .home
    @State private var profileName: String = "User" // Default profile name
    @State private var isEditingProfile: Bool = false
    @State private var tempProfileName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile header
            HStack {
                Button(action: {
                    tempProfileName = profileName
                    isEditingProfile = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        
                        Text(profileName)
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
                    
                    Chart(problemData) { dataPoint in
                        SectorMark(
                            angle: .value("Count", dataPoint.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Category", dataPoint.category))
                    }
                    .chartOverlay { _ in
                        VStack {
                            Text("\(totalProblems)")
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
        .alert("Edit Profile Name", isPresented: $isEditingProfile) {
            TextField("Profile Name", text: $tempProfileName)
                .textFieldStyle(.roundedBorder)
            
            Button("Cancel", role: .cancel) {
                tempProfileName = ""
            }
            
            Button("Save") {
                if !tempProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    profileName = tempProfileName
                    // Handle the text entry here - you can add your logic
                    handleProfileNameChange(newName: profileName)
                }
                tempProfileName = ""
            }
        } message: {
            Text("Enter your profile name")
        }
    }
    
    // Function where you can handle the profile name change
    private func handleProfileNameChange(newName: String) {
        // Add your logic here for when the profile name is changed
        print("Profile name changed to: \(newName)")
        // You can save to UserDefaults, Core Data, or whatever storage you prefer
    }
}

#Preview {
    PopoverHomeView()
        .frame(width: 400, height: 400)
}
