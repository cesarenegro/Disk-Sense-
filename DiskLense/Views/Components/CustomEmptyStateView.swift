import SwiftUI

struct CustomEmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(actionTitle)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
