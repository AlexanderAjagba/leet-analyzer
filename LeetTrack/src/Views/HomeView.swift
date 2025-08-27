//
//  ContentView.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 5/5/25.
//

import SwiftUI
import Charts

// 1. Define the data structure for your chart
struct ProblemStats: Identifiable {
    let category: String
    let count: Int
    let id = UUID()
}

enum SelectedView: String, CaseIterable, Identifiable {
    case home = "Home"
    case dailyQuestion = "Daily Question"
    case lastSolved = "Last Solved"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .dailyQuestion:
            return "questionmark.circle"
        case .lastSolved:
            return "chart.bar"
        }
    }
}

// 2. Create some sample data
let problemData: [ProblemStats] = [
    .init(category: "Easy", count: 85),
    .init(category: "Medium", count: 150),
    .init(category: "Hard", count: 45)
]

// views are merged together and theres a need for navigationPath or stack
// check this stackoverflow: https://stackoverflow.com/questions/77928289/remove-the-current-view-and-then-navigate-to-another-view-in-swiftui

struct HomeView: View {
    // Calculate the total number of problems solved
    private var totalProblems: Int {
        problemData.reduce(0) { $0 + $1.count }
    }
    
    @State private var selectedView: SelectedView? = .home
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SelectedView.allCases, selection: $selectedView) { view in
                NavigationLink(value: view) {
                    Label(view.rawValue, systemImage: view.systemImage)
                }
            }
            .navigationTitle("LeetTrack")
            .frame(minWidth: 200)
        } detail: {
            // Detail content
            if let selectedView = selectedView {
                switch selectedView {
                case .home:
                    homeContent
                        .navigationTitle("Home")
                case .dailyQuestion:
                    DailyQuestion()
                        .navigationTitle("Daily Question")
                case .lastSolved:
                    Stats()
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
        .navigationSplitViewStyle(.balanced)
    }
    
    // Your original home content as a computed property
    private var homeContent: some View {
        VStack(spacing: 20) {
            Text("Problems Solved")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 3. Create the Chart View
            Chart(problemData) { dataPoint in
                // Use a SectorMark for pie/donut charts
                SectorMark(
                    // The 'angle' determines the size of the slice
                    angle: .value("Count", dataPoint.count),
                    // This is the key to making it a donut chart!
                    innerRadius: .ratio(0.6),
                    // Adds a small gap between slices
                    angularInset: 1.5
                )
                // Style the slice with a rounded corner
                .cornerRadius(5)
                // Color each slice based on its category
                .foregroundStyle(by: .value("Category", dataPoint.category))
            }
            // Add text in the center of the donut chart
            .chartOverlay { proxy in
                VStack {
                    Text("\(totalProblems)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // Adds a legend below the chart
            .chartLegend(position: .bottom, alignment: .center)
            .frame(height: 300)
            
            Spacer() // Pushes the chart to the top
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
