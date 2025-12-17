import SwiftUI

public struct StatsView: View {
    @StateObject private var controller: StatsController

    init(sessionStore: SessionStore) {
        _controller = StateObject(wrappedValue: StatsController(sessionStore: sessionStore))
    }

    public var body: some View {
        VStack(spacing: 20) {
            header

            if let lastUpdated = controller.model.lastUpdated {
                Text("Last updated: \(lastUpdated, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            content

            Spacer()
        }
        .padding()
        .task {
            await controller.loadRecentSubmissions()
        }
    }

    private var header: some View {
        HStack {
            Text("Recent Submissions")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                Task { await controller.forceRefresh() }
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

        } else if controller.model.recentSubmissions.isEmpty {
            Text(controller.model.errorMessage ?? "No submissions available")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(controller.model.recentSubmissions) { sub in
                        SubmissionRowView(submission: sub)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
