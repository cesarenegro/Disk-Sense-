import SwiftUI

struct SelectionCheckbox: View {
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: { isSelected.toggle() }) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .green : Color.white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}
