import SwiftUI

struct PipPlaceholderView: View {
    let target: CGRect

    var body: some View {
        GeometryReader { _ in
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
                .frame(width: target.width, height: target.height)
                .position(x: target.midX, y: target.midY)
        }
        .allowsHitTesting(false)
    }
}
