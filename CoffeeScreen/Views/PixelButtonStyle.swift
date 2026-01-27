import SwiftUI

// MARK: - Coffee Theme Colors

extension Color {
    static let coffeeBrown = Color(red: 0.44, green: 0.26, blue: 0.13)
    static let coffeeCream = Color(red: 0.96, green: 0.93, blue: 0.88)
    static let coffeeLight = Color(red: 0.85, green: 0.75, blue: 0.62)
    static let coffeeDark = Color(red: 0.30, green: 0.18, blue: 0.10)
}

// MARK: - Pixel Shape (8-bit style corners)

struct PixelShape: Shape {
    var cornerSize: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let c = cornerSize

        // Start from top-left, after the corner notch
        path.move(to: CGPoint(x: c, y: 0))

        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: rect.width - c, y: 0))

        // Top-right corner (stepped)
        path.addLine(to: CGPoint(x: rect.width - c, y: c))
        path.addLine(to: CGPoint(x: rect.width, y: c))

        // Right edge to bottom-right corner
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - c))

        // Bottom-right corner (stepped)
        path.addLine(to: CGPoint(x: rect.width - c, y: rect.height - c))
        path.addLine(to: CGPoint(x: rect.width - c, y: rect.height))

        // Bottom edge to bottom-left corner
        path.addLine(to: CGPoint(x: c, y: rect.height))

        // Bottom-left corner (stepped)
        path.addLine(to: CGPoint(x: c, y: rect.height - c))
        path.addLine(to: CGPoint(x: 0, y: rect.height - c))

        // Left edge to top-left corner
        path.addLine(to: CGPoint(x: 0, y: c))

        // Top-left corner (stepped)
        path.addLine(to: CGPoint(x: c, y: c))
        path.addLine(to: CGPoint(x: c, y: 0))

        path.closeSubpath()
        return path
    }
}

// MARK: - Pixel Button Style (Primary)

struct PixelButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    private var backgroundColor: Color {
        isDestructive ? Color.red.opacity(0.8) : Color.coffeeBrown
    }

    private var pressedColor: Color {
        isDestructive ? Color.red.opacity(0.6) : Color.coffeeDark
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Silkscreen-Regular", size: 12))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? pressedColor : backgroundColor)
            .clipShape(PixelShape(cornerSize: 4))
            .overlay(
                PixelShape(cornerSize: 4)
                    .stroke(Color.black.opacity(0.4), lineWidth: 2)
            )
            .overlay(
                // Inner highlight (top)
                VStack {
                    PixelShape(cornerSize: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)
                        .mask(
                            VStack {
                                Rectangle().frame(height: 3)
                                Spacer()
                            }
                        )
                    Spacer()
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Pixel Button Style (Secondary)

struct PixelButtonStyleSecondary: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Silkscreen-Regular", size: 12))
            .foregroundStyle(Color.coffeeDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? Color.coffeeLight : Color.coffeeCream)
            .clipShape(PixelShape(cornerSize: 4))
            .overlay(
                PixelShape(cornerSize: 4)
                    .stroke(Color.coffeeBrown.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Large Pixel Button Style (for Lock button)

struct PixelButtonStyleLarge: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("Silkscreen-Regular", size: 14))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isDisabled
                    ? Color.gray.opacity(0.5)
                    : (configuration.isPressed ? Color.coffeeDark : Color.coffeeBrown)
            )
            .clipShape(PixelShape(cornerSize: 6))
            .overlay(
                PixelShape(cornerSize: 6)
                    .stroke(Color.black.opacity(0.4), lineWidth: 3)
            )
            .overlay(
                // Inner highlight
                VStack {
                    Rectangle()
                        .fill(Color.white.opacity(isDisabled ? 0.05 : 0.15))
                        .frame(height: 4)
                        .padding(.horizontal, 6)
                        .padding(.top, 2)
                    Spacer()
                }
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == PixelButtonStyle {
    static var pixel: PixelButtonStyle { PixelButtonStyle() }
    static var pixelDestructive: PixelButtonStyle { PixelButtonStyle(isDestructive: true) }
}

extension ButtonStyle where Self == PixelButtonStyleSecondary {
    static var pixelSecondary: PixelButtonStyleSecondary { PixelButtonStyleSecondary() }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Lock Screen") {}
            .buttonStyle(PixelButtonStyleLarge())

        HStack(spacing: 12) {
            Button("Change") {}
                .buttonStyle(.pixel)

            Button("Delete") {}
                .buttonStyle(.pixelDestructive)
        }

        HStack(spacing: 12) {
            Button("Cancel") {}
                .buttonStyle(.pixelSecondary)

            Button("Save") {}
                .buttonStyle(.pixel)
        }
    }
    .padding(40)
    .background(Color.gray.opacity(0.1))
}
