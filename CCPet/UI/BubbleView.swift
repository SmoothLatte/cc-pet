import SwiftUI

enum BubbleStyle {
    case success, error, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return Color(white: 0.5)
        }
    }
}

struct BubbleView: View {
    let title: String
    let message: String
    let style: BubbleStyle

    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.icon)
                .font(.system(size: 22))
                .foregroundColor(style.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 260, height: 60)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style.color.opacity(0.3), lineWidth: 1)
        )
        .offset(x: shakeOffset)
        .onAppear {
            guard style == .success else { return }
            Task { @MainActor in
                for offset in [CGFloat(-6), 6, -4, 4, -2, 0] {
                    withAnimation(.linear(duration: 0.06)) {
                        shakeOffset = offset
                    }
                    try? await Task.sleep(for: .milliseconds(60))
                }
            }
        }
    }
}
