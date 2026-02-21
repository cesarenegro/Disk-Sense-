import SwiftUI

struct CustomProgressWheelView: View {
    let progress: Double
    let title: String
    let subtitle: String
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    init(
        progress: Double,
        title: String,
        subtitle: String,
        color: Color,
        size: CGFloat = 120,
        lineWidth: CGFloat = 10
    ) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Percentage text
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
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

// MARK: - Preview
struct CustomProgressWheelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CustomProgressWheelView(
                progress: 0.65,
                title: "Scanning...",
                subtitle: "2.4 GB found",
                color: .blue,
                size: 200,
                lineWidth: 16
            )
            .frame(width: 240, height: 240)
            .padding()
            .previewDisplayName("65% Progress")
            
            CustomProgressWheelView(
                progress: 1.0,
                title: "Complete!",
                subtitle: "Scan finished",
                color: .green,
                size: 160,
                lineWidth: 12
            )
            .frame(width: 200, height: 200)
            .padding()
            .previewDisplayName("100% Complete")
            
            CustomProgressWheelView(
                progress: 0.25,
                title: "Cleaning...",
                subtitle: "Removing junk files",
                color: .orange,
                size: 160,
                lineWidth: 12
            )
            .frame(width: 200, height: 200)
            .padding()
            .previewDisplayName("25% Progress")
        }
    }
}
