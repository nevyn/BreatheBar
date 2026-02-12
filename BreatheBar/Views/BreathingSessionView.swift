import SwiftUI

// MARK: - Leaf Petal Shape

/// A teardrop/leaf shape matching the app icon silhouette.
struct LeafPetal: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Tip at top center
        path.move(to: CGPoint(x: w * 0.5, y: 0))

        // Right side curve down to base
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.85, y: h * 0.25),
            control2: CGPoint(x: w * 0.75, y: h * 0.8)
        )

        // Left side curve back up to tip
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: w * 0.25, y: h * 0.8),
            control2: CGPoint(x: w * 0.15, y: h * 0.25)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Petal Flower View

/// A Mindfulness-style animated flower with two layers of leaf petals.
/// The layers rotate continuously for a sense of progression, while the
/// expansion/contraction loops in cadence with the breathing cycle.
struct PetalFlowerView: View {
    let expansion: Double
    let elapsed: Double
    let cycleLength: Double

    private let petalCount = 7

    var body: some View {
        // Continuous rotation independent of breathing phase
        let rotation1 = elapsed * 8    // ~45s per full turn
        let rotation2 = elapsed * -5   // counter-rotate, ~72s per full turn

        ZStack {
            // Layer 1: outer petals (green)
            ForEach(0..<petalCount, id: \.self) { index in
                let angle = Double(index) * 360.0 / Double(petalCount)
                let offset = 5.0 + expansion * 35.0

                LeafPetal()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.35, green: 0.78, blue: 0.50),
                                Color(red: 0.25, green: 0.65, blue: 0.40),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.75)
                    .frame(width: 26, height: 52)
                    .shadow(color: Color(red: 0.15, green: 0.40, blue: 0.25).opacity(0.35), radius: 5, y: 2)
                    .offset(y: -offset)
                    .rotationEffect(.degrees(angle + rotation1))
            }

            // Layer 2: inner petals (teal, with slight timing offset)
            petalLayer2(rotation: rotation2)
        }
        .scaleEffect(0.88 + expansion * 0.12)
    }

    private func petalLayer2(rotation: Double) -> some View {
        let phase2 = -cos((elapsed - 0.4) * .pi * 2.0 / cycleLength)
        let expansion2 = phase2 * 0.5 + 0.5
        let halfAngle = 360.0 / Double(petalCount) / 2.0

        return ForEach(0..<petalCount, id: \.self) { index in
            let angle = Double(index) * 360.0 / Double(petalCount) + halfAngle
            let offset = 3.0 + expansion2 * 28.0

            LeafPetal()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.45, green: 0.75, blue: 0.70),
                            Color(red: 0.35, green: 0.60, blue: 0.58),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.65)
                .frame(width: 22, height: 44)
                .shadow(color: Color(red: 0.15, green: 0.35, blue: 0.30).opacity(0.30), radius: 4, y: 1)
                .offset(y: -offset)
                .rotationEffect(.degrees(angle + rotation))
        }
    }
}

// MARK: - Breathing Session View

/// The guided breathing UI shown as a floating panel.
struct BreathingSessionView: View {
    let startDate: Date
    /// Duration of one inhale (or exhale) in seconds.
    let cadence: Double
    let onDone: () -> Void

    /// Full breathing cycle = inhale + exhale.
    private var cycleLength: Double { cadence * 2.0 }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)

            // -cos starts at -1 (contracted), rises to +1 (expanded)
            let breathPhase = -cos(elapsed * .pi * 2.0 / cycleLength)
            let expansion = breathPhase * 0.5 + 0.5
            // Text opacity: fade through zero at phase transitions
            let s = sin(elapsed * .pi * 2.0 / cycleLength)
            let inhaleOpacity = max(0, min(1, (s - 0.15) * 5.0))
            let exhaleOpacity = max(0, min(1, (-s - 0.15) * 5.0))

            VStack(spacing: 16) {
                ZStack {
                    Text("Breathe in…")
                        .opacity(inhaleOpacity)
                    Text("Breathe out…")
                        .opacity(exhaleOpacity)
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(height: 20)

                PetalFlowerView(expansion: expansion, elapsed: elapsed, cycleLength: cycleLength)
                    .frame(width: 160, height: 160)

                Button(action: onDone) {
                    Text("Done breathing")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.40, green: 0.72, blue: 0.55))
            }
            .padding(.horizontal, 30)
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 250)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
