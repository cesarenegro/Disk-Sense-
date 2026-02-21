import SwiftUI
import AppKit

struct CustomProgressWheelView: View {
    let progress: Double
    let title: String
    let subtitle: String
    let size: CGFloat
    let lineWidth: CGFloat

    init(
        progress: Double,
        title: String,
        subtitle: String,
        size: CGFloat = 120,
        lineWidth: CGFloat = ProgressArcView.defaultLineWidth
    ) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Progress arc
                ProgressArcView(progress: progress, lineWidth: lineWidth)

                // Percentage text
                Text(percentAttributedString)
                    .font(.system(size: 36, weight: .bold))
            }
            .frame(width: size, height: size)

            // Title and subtitle
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private extension CustomProgressWheelView {
    var percentAttributedString: AttributedString {
        let borderColor = NSColor(named: "Border") ?? .white
        let strokeColor = NSColor(named: "Text1") ?? .black
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: borderColor,
            .strokeColor: strokeColor,
            .strokeWidth: -1
        ]
        let nsAttributed = NSAttributedString(
            string: "\(Int(progress * 100))%",
            attributes: attributes
        )
        return AttributedString(nsAttributed)
    }
}

// MARK: - Preview
struct CustomProgressWheelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomProgressWheelView(
                progress: 0.65,
                title: "Scanning...",
                subtitle: "2.4 GB found",
                size: 200,
                lineWidth: 24
            )
            .frame(width: 240, height: 240)
            .padding()
            .previewDisplayName("65% Progress")
            
            CustomProgressWheelView(
                progress: 1.0,
                title: "Complete!",
                subtitle: "Scan finished",
                size: 160,
                lineWidth: 24
            )
            .frame(width: 200, height: 200)
            .padding()
            .previewDisplayName("100% Complete")
            
            CustomProgressWheelView(
                progress: 0.25,
                title: "Cleaning...",
                subtitle: "Removing junk files",
                size: 160,
                lineWidth: 24
            )
            .frame(width: 200, height: 200)
            .padding()
            .previewDisplayName("25% Progress")
        }
    }
}
