import SwiftUI

struct IntelligenceToolView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppTheme.contentTop, AppTheme.contentBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    header

                    VStack(spacing: 14) {
                        NavigationLink {
                            DiskVisualizerView()
                        } label: {
                            IntelligenceActionButton(
                                title: "Disk Visualizer (Storage Map)",
                                systemIcon: "square.grid.3x3.square"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ProjectJunkDetectorView()
                        } label: {
                            IntelligenceActionButton(
                                title: "Project Junk Detector (Pro)",
                                systemIcon: "hammer"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            OldFilesAnalyzerView()
                        } label: {
                            IntelligenceActionButton(
                                title: "Old Files Analyzer",
                                systemIcon: "clock.arrow.circlepath"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            DownloadsIntelligenceView()
                        } label: {
                            IntelligenceActionButton(
                                title: "Download Folder Intelligence",
                                systemIcon: "arrow.down.circle"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ReviewDecisionPanelView()
                        } label: {
                            IntelligenceActionButton(
                                title: "Review & Decision Panel",
                                systemIcon: "tray.full",
                                backgroundColor: Color("ButtonLight")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
                .padding(.top, 24)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Intelligence Tool")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Choose an analysis to run")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private struct IntelligenceActionButton: View {
    let title: String
    let systemIcon: String
    var backgroundColor: Color = Color.white.opacity(0.08)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    IntelligenceToolView()
        .frame(width: 1000, height: 720)
}
