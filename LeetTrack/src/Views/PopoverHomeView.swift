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

// TabView solution for macOS
struct PopoverHomeView: View {
    private var totalProblems: Int {
        problemData.reduce(0) { $0 + $1.count }
    }
    
    @State private var selectedTab: TabSelection = .home
    
    var body: some View {
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
                .frame(height: 300)
                
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
        .frame(width: 400, height: 400)
    }
}

#Preview {
    PopoverHomeView()
        .frame(width: 400, height: 400)
}
