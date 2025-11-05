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

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
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
                            Task {
                                await ProfileManager.shared.updateUsername(trimmed)
                            }
                        }
                        tempProfileName = currentProfile.username
                    }
                }, message: {
                    Text("Enter your LeetCode username")
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
        .task {
            // Load profile from MongoDB first
            await ProfileManager.shared.loadProfile(userId: "default_user")
            // Then load LeetCode stats
            await viewModel.load(username: currentProfile.username, userId: currentProfile.username)
        }
    }
    
    // Update homeContent to use viewModel.homeModel
    private var homeContent: some View {
        VStack(spacing: 20) {
            Text("Problems Solved")
                .font(.title2)
                .fontWeight(.semibold)
            
            // 3. Create the Chart View
            Chart([
                ProblemStats(category: "Easy", count: viewModel.homeModel.easySolved),
                ProblemStats(category: "Medium", count: viewModel.homeModel.mediumSolved),
                ProblemStats(category: "Hard", count: viewModel.homeModel.hardSolved)
            ]) { dataPoint in
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
                    Text("\(viewModel.homeModel.totalSolved)")
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
            
            // Difficulty Filter and Questions
            HStack {
                Text("Filter:")
                Picker("Difficulty", selection: $viewModel.selectedDifficulty) {
                    ForEach(viewModel.availableDifficulties, id: \.self) { diff in
                        Text(diff).tag(diff)
                    }
                }
                .onChange(of: viewModel.selectedDifficulty) { _ in
                    Task { try? await viewModel.loadQuestions() }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await ProfileManager.shared.manualRefresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Refresh LeetCode stats")
            }
            .padding(.top, 8)

            List(viewModel.questions) { q in
                HStack {
                    Text(q.title ?? q.titleSlug ?? "Untitled")
                        .font(.body)
                    Spacer()
                    Text(q.difficulty ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
