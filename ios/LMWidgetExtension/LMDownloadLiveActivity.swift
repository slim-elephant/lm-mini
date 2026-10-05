//
//  LMDownloadLiveActivity.swift
//  LMWidgetExtension
//
//  Live Activity for Hugging Face / on-device download progress.
//  Free for every user (chat-generation Live Activity stays Pro).
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LMDownloadActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var displayName: String
        var progress: Double
        var statusText: String
    }

    var displayName: String
}

@available(iOS 16.2, *)
struct LMDownloadLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LMDownloadActivityAttributes.self) { context in
            LMDownloadLockScreenView(context: context)
                .widgetURL(URL(string: "lmmini://models"))
        } dynamicIsland: { context in
            let progress = context.state.progress.clampedProgress
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(progress.percentLabel)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundColor(.purple)
                        .padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.displayName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(downloadStatusLine(context.state.statusText))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        ProgressView(value: progress)
                            .tint(.purple)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.purple)
            } compactTrailing: {
                Text(progress.percentLabel)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundColor(.purple)
            } minimal: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.purple)
            }
        }
    }
}

@available(iOS 16.2, *)
private struct LMDownloadLockScreenView: View {
    let context: ActivityViewContext<LMDownloadActivityAttributes>
    private let purple = Color.purple

    var body: some View {
        let progress = context.state.progress.clampedProgress
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(purple.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(purple)
                        .font(.system(size: 14, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("LM Mini")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(context.state.displayName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 8)
                Text(progress.percentLabel)
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundColor(purple)
            }

            Text(downloadStatusLine(context.state.statusText))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            ProgressView(value: progress)
                .tint(purple)
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
    }
}

private extension Double {
    var clampedProgress: Double { min(1, max(0, self)) }

    /// Round so 1.6% shows as 2%, matching Dart `(progress * 100).round()`.
    var percentLabel: String {
        "\(Int((self * 100).rounded()))%"
    }
}

/// Status under the title. Ignore a second "12%" string — percent lives
/// in the trailing label only.
private func downloadStatusLine(_ statusText: String) -> String {
    let trimmed = statusText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "Downloading…" }
    if trimmed.range(of: #"^\d{1,3}%$"#, options: .regularExpression) != nil {
        return "Downloading…"
    }
    return trimmed
}
