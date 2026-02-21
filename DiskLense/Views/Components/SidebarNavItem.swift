import SwiftUI

struct SidebarNavItem: View {
    let title: String
    let assetIcon: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    let inactiveColor: Color?

    init(
        title: String,
        assetIcon: String,
        isSelected: Bool,
        accentColor: Color = AppTheme.accent,
        inactiveColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.assetIcon = assetIcon
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.inactiveColor = inactiveColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(assetIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(isSelected ? 1 : 0.9)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .fill(isSelected ? accentColor : (inactiveColor ?? Color.white.opacity(0.08)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0.25 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

