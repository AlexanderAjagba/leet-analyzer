import SwiftUI

struct DailyQuestionView: View {
    @StateObject private var controller = DailyQuestionController()

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Question")
                .font(.title2)
                .fontWeight(.semibold)

            content

            Spacer()
        }
        .padding()
        .task {
            await controller.loadDailyQuestion()
        }
    }

    @ViewBuilder
    private var content: some View {
        if controller.model.isLoading {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if let dq = controller.model.dailyQuestion {
            VStack(alignment: .leading, spacing: 12) {
                Text(dq.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Text("Difficulty: \(dq.difficulty)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let url = URL(string: dq.link) {
                    Link("View on LeetCode", destination: url)
                        .font(.body)
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
    }
}
