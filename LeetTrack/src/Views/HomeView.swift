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
enum SelectedView {
    case home
    case dailyQuestion
    case lastSolved
}
// 2. Create some sample data
let problemData: [ProblemStats] = [
    .init(category: "Easy", count: 85),
    .init(category: "Medium", count: 150),
    .init(category: "Hard", count: 45)
]


struct HomeView: View {
    // Calculate the total number of problems solved
    private var totalProblems: Int {
        problemData.reduce(0) { $0 + $1.count }
    }
    
    @State private var selectedView: SelectedView = .home
    @State private var buttonClick: Bool = false
    func selectionTab() -> some View {
        VStack {
            switch selectedView {
            case .home:
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            case .dailyQuestion:
                DailyQuestion()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .move(edge: .top)
                    ))
            case .lastSolved:
                Stats()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
    }
    var body: some View {
        // State to track which view is currently selected
        VStack(spacing: 20) {
            // Tab buttons to switch views
            HStack(spacing: 20) {
                Button("Home") {
                    withAnimation(.spring()) {
                        selectedView = .home
                        buttonClick = true
                    }
                }
                .foregroundColor(selectedView == .home ? .blue : .primary)
                .fontWeight(selectedView == .home ? .bold : .regular)
                
                Button("Daily Question") {
                    withAnimation(.spring()) {
                        selectedView = .dailyQuestion
                        buttonClick = true
                    }
                }
                .foregroundColor(selectedView == .dailyQuestion ? .blue : .primary)
                .fontWeight(selectedView == .dailyQuestion ? .bold : .regular)
                
                Button("Last Solved") {
                    withAnimation(.spring()) {
                        selectedView = .lastSolved
                        buttonClick = true
                    }
                }
                .foregroundColor(selectedView == .lastSolved ? .blue : .primary)
                .fontWeight(selectedView == .lastSolved ? .bold : .regular)
            }
            .padding()
            
            // Conditional view display with animations
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedView)
            if buttonClick {
                selectionTab()
            }
            
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
