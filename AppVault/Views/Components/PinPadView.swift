import SwiftUI

struct PinPadView: View {
    let digitCount: Int
    @Binding var pin: String
    var onComplete: (String) -> Void

    private let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 28) {
            dotRow
            grid
        }
    }

    private var dotRow: some View {
        HStack(spacing: 18) {
            ForEach(0..<digitCount, id: \.self) { i in
                ZStack {
                    Circle()
                        .stroke(Color.vaultAccent.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    if i < pin.count {
                        Circle()
                            .fill(Color.vaultAccent)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pin.count)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 14) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(row, id: \.self) { label in
                        if label.isEmpty {
                            Color.clear.frame(width: 82, height: 82)
                        } else {
                            PinButton(label: label) { handleTap(label) }
                        }
                    }
                }
            }
        }
    }

    private func handleTap(_ label: String) {
        if label == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
        } else if pin.count < digitCount {
            pin.append(label)
            if pin.count == digitCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    onComplete(pin)
                }
            }
        }
    }
}

private struct PinButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color.vaultCard)
                    .frame(width: 82, height: 82)
                    .overlay(Circle().stroke(Color.vaultCardBorder, lineWidth: 1))

                if label == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                } else {
                    Text(label)
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
