//
//  DailyQuestion.swift
//  LeetTrack
//
//  Created by Alexander Ajagba on 8/7/25.
//

import SwiftUI

struct DailyQuestion: View {
    @StateObject private var controller = DailyQuestionController()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Question")
                .font(.title2)
                .fontWeight(.semibold)
            
            if controller.model.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let dailyQuestion = controller.model.dailyQuestion {
                VStack(alignment: .leading, spacing: 12) {
                    if let title = dailyQuestion.title {
                        Text(title)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let difficulty = dailyQuestion.difficulty {
                        Text("Difficulty: \(difficulty)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let link = dailyQuestion.link, let url = URL(string: link) {
                        Link("View on LeetCode", destination: url)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                Text(controller.model.errorMessage ?? "Not available right now")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .task {
            await controller.loadDailyQuestion()
        }
    }
}


#Preview {
    DailyQuestion()
}
