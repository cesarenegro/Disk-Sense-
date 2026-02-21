import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppController

    /// AppShellView ti passa un callback per andare a FlashClean e triggerare scan
    var onScan: (() -> Void)?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.contentTop, AppTheme.contentBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer(minLength: 10)

                hero

                VStack(spacing: 10) {
                    Text("MacTidy - make your Mac like new")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)

                    Text("Scan your Mac and safely remove unnecessary files")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 24)

                scanButton

                Spacer()
            }
            .frame(maxWidth: AppTheme.contentMaxWidth)
            .padding(.horizontal, 32)
        }
    }

    private var hero: some View {
        Image(Asset.hero)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 520)
            .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 18)
            .padding(.top, 24)
    }

    private var scanButton: some View {
        Button {
            onScan?()
        } label: {
            Text("Scan")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 280, height: 68)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.accent)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

