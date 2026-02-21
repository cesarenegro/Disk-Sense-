import SwiftUI

struct ReviewDecisionPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ActionListManager.shared
    @State private var showConfirm = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.contentTop, AppTheme.contentBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                header

                totalSummary

                list

                actions

                logSection

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .confirmationDialog(
            "Move selected items to Trash?",
            isPresented: $showConfirm,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Move to Trash", role: .destructive) {
                    Task { await manager.confirmTrashSelected() }
                }
            },
            message: {
                Text("This will move \(manager.items.count) items (\(formattedBytes(manager.totalBytes))) to Trash.")
            }
        )
    }

    private var header: some View {
        HStack {
            Button("←") { dismiss() }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: 6) {
                Text("Review & Decision Panel")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Review queued items before moving to Trash")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var totalSummary: some View {
        HStack {
            Text("Total Reclaimable")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Text(formattedBytes(manager.totalBytes))
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(manager.items) { item in
                    ActionListRow(item: item, remove: { manager.remove(path: item.path) })
                }

                if manager.items.isEmpty {
                    CustomEmptyStateView(
                        title: "Action List Empty",
                        message: "Add items from any module to review them here.",
                        icon: "tray",
                        actionTitle: "Open Trash",
                        action: { manager.openTrash() }
                    )
                    .frame(height: 220)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            SidebarStyleButton(
                title: "Open Trash",
                assetIcon: Asset.icSmartClean,
                isEnabled: true,
                action: { manager.openTrash() }
            )

            SidebarStyleButton(
                title: "Move to Trash",
                assetIcon: Asset.icSmartClean,
                isEnabled: !manager.items.isEmpty,
                action: { showConfirm = true }
            )
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Actions")
                .font(.headline)
                .foregroundColor(.white)

            if manager.logs.isEmpty {
                Text("No actions yet")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ForEach(manager.logs.prefix(5)) { entry in
                    Text("\(entry.date.formatted(date: .numeric, time: .shortened)) • \(entry.items.count) items • \(entry.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private struct ActionListRow: View {
    let item: ActionListItem
    let remove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(item.source)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }

            HStack {
                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer()

                Button("Remove") { remove() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct SidebarStyleButton: View {
    let title: String
    let assetIcon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(assetIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(isEnabled ? 1 : 0.5)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .fill(isEnabled ? AppTheme.accent : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.25 : 0.12), lineWidth: 1)
            )
            .frame(width: 200)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    ReviewDecisionPanelView()
        .frame(width: 1000, height: 720)
}
