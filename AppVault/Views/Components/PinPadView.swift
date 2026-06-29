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
        VStack(spacing: 24) {
            dotRow
            grid
        }
    }

    private var dotRow: some View {
        HStack(spacing: 16) {
            ForEach(0..<digitCount, id: \.self) { i in
                Circle()
                    .fill(i < pin.count ? Color.vaultAccent : Color.vaultCard)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.vaultAccent.opacity(0.4), lineWidth: 1.5)
                    )
                    .scaleEffect(i < pin.count ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2), value: pin.count)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { label in
                        if label.isEmpty {
                            Color.clear.frame(width: 80, height: 80)
                        } else {
                            PinButton(label: label) {
                                handleTap(label)
                            }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onComplete(pin)
                }
            }
        }
    }
}

private struct PinButton: View {
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(isPressed ? Color.vaultAccent.opacity(0.3) : Color.vaultCard)
                    .frame(width: 80, height: 80)

                if label == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text(label)
                        .font(.system(size: 28, weight: .light, design: .rounded))
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
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.15), value: configuration.isPressed)
    }
}
