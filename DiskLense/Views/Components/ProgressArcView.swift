import SwiftUI

struct ProgressArcView: View {
    static let defaultLineWidth: CGFloat = 24

    let progress: Double
    let lineWidth: CGFloat
    let arcColor: Color
    let trackColor: Color

    init(
        progress: Double,
        lineWidth: CGFloat = Self.defaultLineWidth,
        arcColor: Color = Color("Text1"),
        trackColor: Color = Color("Border").opacity(0.35)
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.arcColor = arcColor
        self.trackColor = trackColor
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(arcColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}
