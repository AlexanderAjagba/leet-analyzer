//
//  StatsView.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import SwiftUI

struct StatsView: View {
    @StateObject private var controller = StatsController()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recent Problems")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await controller.forceRefreshProblems()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(controller.model.isLoading)
            }
            
            if let lastUpdated = controller.model.lastUpdated {
                Text("Last updated: \(lastUpdated, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if controller.model.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if controller.model.recentProblems.isEmpty {
                Text(controller.model.errorMessage ?? "No problems available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(controller.model.recentProblems) { problem in
                            ProblemRowView(problem: problem)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .task {
            await controller.loadRecentProblems()
        }
    }
}

struct ProblemRowView: View {
    let problem: LeetCodeProblem
    
    var difficultyColor: Color {
        switch problem.difficulty?.uppercased() {
        case "EASY":
            return .green
        case "MEDIUM":
            return .orange
        case "HARD":
            return .red
        default:
            return .secondary
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let title = problem.title {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                
                if let difficulty = problem.difficulty {
                    Text(difficulty.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if let paidOnly = problem.paidOnly, paidOnly {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    StatsView()
}
