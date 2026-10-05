//
//  LMChatLiveActivity.swift
//  LMWidgetExtension
//
//  Live Activity for showing chat generation progress on Lock Screen and Dynamic Island.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes

struct LMChatActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String       // "loading", "processing", "generating", "imaging", "complete", "error"
        var statusText: String   // Human-readable status
        var modelName: String
        var tokenCount: Int
        var tokensPerSecond: Double
        var elapsedSeconds: Int
        var kind: String = "chat"
        var progress: Double = 0

        var isImaging: Bool { kind == "image" || status == "imaging" }
    }
    
    var chatTitle: String
}

// MARK: - Live Activity Widget

@available(iOS 16.2, *)
struct LMChatLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LMChatActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LMChatLockScreenView(context: context)
                .widgetURL(URL(string: "lmmini://newchat"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isImaging ? "photo.fill" : "message.fill")
                        .foregroundColor(.purple)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isImaging {
                        if context.state.progress >= 0.05 {
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    } else if context.state.tokenCount > 0 {
                        Text("\(context.state.tokenCount) tokens")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.modelName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        statusIcon(for: context.state.status)
                        Text(context.state.statusText)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if context.state.tokensPerSecond > 0 {
                            Text(String(format: "%.1f t/s", context.state.tokensPerSecond))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        if context.state.elapsedSeconds > 0 {
                            Text(formatTime(context.state.elapsedSeconds))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isImaging ? "photo.fill" : "message.fill")
                    .foregroundColor(.purple)
            } compactTrailing: {
                if context.state.isImaging {
                    if context.state.progress >= 0.05 {
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.caption2)
                            .monospacedDigit()
                    } else {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                } else if context.state.status == "generating" && context.state.tokenCount > 0 {
                    Text("\(context.state.tokenCount)")
                        .font(.caption2)
                        .monospacedDigit()
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            } minimal: {
                Image(systemName: context.state.isImaging ? "photo.fill" : "message.fill")
                    .foregroundColor(.purple)
            }
        }
    }
    
    @ViewBuilder
    func statusIcon(for status: String) -> some View {
        switch status {
        case "loading":
            Image(systemName: "arrow.down.circle")
                .foregroundColor(.orange)
                .font(.caption)
        case "processing":
            Image(systemName: "gearshape.2")
                .foregroundColor(.blue)
                .font(.caption)
        case "generating":
            Image(systemName: "text.cursor")
                .foregroundColor(.green)
                .font(.caption)
        case "imaging":
            Image(systemName: "photo")
                .foregroundColor(.green)
                .font(.caption)
        case "complete":
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        default:
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct LMChatLockScreenView: View {
    let context: ActivityViewContext<LMChatActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row: app glyph + model + elapsed
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: context.state.isImaging ? "photo.fill" : "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 14, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("LM Mini")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(context.state.modelName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                }
                Spacer()
                if context.state.elapsedSeconds > 0 {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(formatTime(context.state.elapsedSeconds))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.primary)
                        Text("elapsed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Status row with icon + text + animated dot
            HStack(spacing: 6) {
                statusIcon
                Text(context.state.statusText)
                    .font(.subheadline)
                    .lineLimit(2)
                Spacer()
                if context.state.status == "generating" || context.state.isImaging {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }

            // Token metrics row — always visible during generation
            if !context.state.isImaging &&
                (context.state.status == "generating" ||
                context.state.status == "complete") {
                HStack(spacing: 16) {
                    metricChip(
                        icon: "text.alignleft",
                        label: "tokens",
                        value: "\(context.state.tokenCount)")
                    if context.state.tokensPerSecond > 0 {
                        metricChip(
                            icon: "speedometer",
                            label: "t/s",
                            value: String(format: "%.1f", context.state.tokensPerSecond))
                    }
                    Spacer()
                }
            }

            // Progress bar — driven by tokens when generating, indeterminate during load
            if context.state.status != "complete" && context.state.status != "error" {
                if context.state.isImaging {
                    if context.state.progress >= 0.05 {
                        ProgressView(value: min(1.0, max(0.0, context.state.progress)))
                            .progressViewStyle(.linear)
                            .tint(.purple)
                    } else {
                        ProgressView()
                            .progressViewStyle(.linear)
                            .tint(.purple)
                    }
                } else if context.state.status == "generating" && context.state.tokenCount > 0 {
                    // Cap the visual bar at 512 tokens; reset cycle past that.
                    let progress = min(1.0, Double(context.state.tokenCount % 512) / 512.0)
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.purple)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(.purple)
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground).opacity(0.8))
    }

    @ViewBuilder
    private func metricChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    var statusIcon: some View {
        switch context.state.status {
        case "loading":
            Image(systemName: "arrow.down.circle")
                .foregroundColor(.orange)
        case "processing":
            Image(systemName: "gearshape.2")
                .foregroundColor(.blue)
        case "generating":
            Image(systemName: "text.cursor")
                .foregroundColor(.green)
        case "imaging":
            Image(systemName: "photo")
                .foregroundColor(.green)
        case "complete":
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case "error":
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        default:
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.secondary)
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
