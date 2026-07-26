//
//  APIDebugLogView.swift
//  Simmr
//
//  Shake-to-open (see ShakeDetector) internal screen for inspecting OpenAI
//  request/response traffic on a real device — TestFlight testers can't
//  attach a debugger, so this is the fastest way to see exactly what a
//  failed generation sent and got back. Never shown in a production App
//  Store build — see BuildEnvironment.isDebugToolsEnabled.
//

import SwiftUI

struct APIDebugLogView: View {
    @ObservedObject private var store = APIDebugLogStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.logs.isEmpty {
                    ContentUnavailableView(
                        "No API Calls Yet",
                        systemImage: "network",
                        description: Text("Requests to OpenAI will show up here as they happen.")
                    )
                } else {
                    List(store.logs) { entry in
                        NavigationLink {
                            APICallDetailView(entry: entry)
                        } label: {
                            APICallRow(entry: entry)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Theme.Colors.creamBackground)
            .navigationTitle("API Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) { store.clear() }
                        .disabled(store.logs.isEmpty)
                }
            }
        }
    }
}

private struct APICallRow: View {
    let entry: APICallLog

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(entry.isSuccess ? Color.green : Theme.Colors.coral)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.model ?? entry.endpoint)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textDark)

                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()

            Text(entry.timestamp, style: .time)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(.vertical, Theme.Spacing.xxs)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let statusCode = entry.statusCode { parts.append("HTTP \(statusCode)") }
        parts.append(String(format: "%.1fs", entry.duration))
        if let error = entry.error { parts.append(error) }
        return parts.joined(separator: " · ")
    }
}

private struct APICallDetailView: View {
    let entry: APICallLog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                summarySection
                if let error = entry.error {
                    errorSection(error)
                }
                if let requestBody = entry.requestBody {
                    ExpandableBodySection(title: "Request", text: requestBody)
                }
                if let responseBody = entry.responseBody {
                    ExpandableBodySection(title: "Response", text: responseBody)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.creamBackground)
        .navigationTitle(entry.endpoint)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Error")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textDark)
            Text(error)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Theme.Colors.coral)
                .textSelection(.enabled)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            summaryRow("Status", entry.isSuccess ? "Success" : "Failure", valueColor: entry.isSuccess ? .green : Theme.Colors.coral)
            if let statusCode = entry.statusCode {
                summaryRow("HTTP code", "\(statusCode)")
            }
            summaryRow("Duration", String(format: "%.2fs", entry.duration))
            summaryRow("Time", entry.timestamp.formatted(date: .abbreviated, time: .standard))
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }

    private func summaryRow(_ label: String, _ value: String, valueColor: Color = Theme.Colors.textDark) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
            Spacer()
            Text(value)
                .font(Theme.Typography.footnote.weight(.semibold))
                .foregroundStyle(valueColor)
        }
    }

}

/// Collapsed by default — request/response bodies can be long, so this lets
/// someone scanning a call tap open only the one they actually need instead
/// of scrolling past both in full every time.
private struct ExpandableBodySection: View {
    let title: String
    let text: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textDark)
                    Text("(\(text.count) chars)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textMuted)
                    Spacer()
                    if isExpanded {
                        Button {
                            UIPasteboard.general.string = text
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Theme.Colors.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(text)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textDark)
                    .textSelection(.enabled)
                    .padding(.top, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

#Preview {
    APIDebugLogView()
}
