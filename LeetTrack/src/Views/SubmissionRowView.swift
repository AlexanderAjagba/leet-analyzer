import SwiftUI

struct SubmissionRowView: View {
    let submission: RecentSubmission

    private var statusColor: Color {
        switch (submission.status ?? "").lowercased() {
        case "accepted": return .green
        case "wrong answer": return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(submission.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if let status = submission.status {
                        Text(status.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if let lang = submission.language {
                        Text(lang)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
