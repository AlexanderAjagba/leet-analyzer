import SwiftUI

struct PopoverDaily: View {
    @StateObject private var controller = DailyQuestionController()

    var body: some View {
        VStack(spacing: 20) {
            header
            content
            Spacer()
        }
        .padding()
        .task {
            await controller.loadDailyQuestion()
        }
    }

    private var header: some View {
        HStack {
            Text("Daily Question")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                Task { await controller.forceRefreshDailyQuestion() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(controller.model.isLoading)
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
