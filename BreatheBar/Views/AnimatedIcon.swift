import SwiftUI

struct AnimatedIcon: View {
    let isActive: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .symbolRenderingMode(isActive ? .multicolor : .monochrome)
            .foregroundStyle(isActive ? Color.green : Color.primary)
            .opacity(isActive ? 0.5 + 0.5 * sin(Double(animationPhase)) : 1.0)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
            .onAppear {
                if isActive {
                    startAnimation()
                }
            }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animationPhase = .pi
        }
    }
    
    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0
        }
    }
}

#Preview("Idle") {
    AnimatedIcon(isActive: false)
        .padding()
}

#Preview("Active") {
    AnimatedIcon(isActive: true)
        .padding()
}
