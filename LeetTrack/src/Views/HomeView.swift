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
    @ObservedObject var profileManager = ProfileManager.shared
    @ObservedObject private var currentProfile: Profile = ProfileManager.shared.currentProfile
    @State private var isEditingProfile: Bool = false
    @State private var tempProfileName: String = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
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
                .alert("Edit Profile Name", isPresented: $isEditingProfile, actions: {
                    TextField("Profile Name", text: $tempProfileName)
                    Button("Cancel", role: .cancel) {
                        tempProfileName = currentProfile.username
                    }
                    Button("Save") {
                        let trimmed = tempProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            currentProfile.username = trimmed
                        }
                        tempProfileName = currentProfile.username
                    }
                }, message: {
                    Text("Enter your profile name")
                })
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor))
            }
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
                    angle: .value("Count", dataPoint.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Category", dataPoint.category))
            }
            // Center text inside the donut
            .overlay {
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
