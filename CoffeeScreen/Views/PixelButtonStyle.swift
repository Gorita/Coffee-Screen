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
    @State private var isHovered: Bool = false

    private var backgroundColor: Color {
        isDestructive ? Color(red: 0.85, green: 0.30, blue: 0.30) : Color.coffeeBrown
    }

    private var pressedColor: Color {
        isDestructive ? Color(red: 0.70, green: 0.25, blue: 0.25) : Color.coffeeDark
    }

    func makeBody(configuration: Configuration) -> some View {
        let elevation: CGFloat = configuration.isPressed ? 0 : (isHovered ? 4 : 2)
        let yOffset: CGFloat = configuration.isPressed ? 2 : (isHovered ? -1 : 0)

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
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.4), radius: 0, x: 0, y: elevation)
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Pixel Button Style (Secondary)

struct PixelButtonStyleSecondary: ButtonStyle {
    @State private var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let elevation: CGFloat = configuration.isPressed ? 0 : (isHovered ? 4 : 2)
        let yOffset: CGFloat = configuration.isPressed ? 2 : (isHovered ? -1 : 0)

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
            .compositingGroup()
            .shadow(color: Color.coffeeBrown.opacity(0.3), radius: 0, x: 0, y: elevation)
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Large Pixel Button Style (for Lock button)

struct PixelButtonStyleLarge: ButtonStyle {
    var isDisabled: Bool = false
    @State private var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let elevation: CGFloat = isDisabled ? 0 : (configuration.isPressed ? 0 : (isHovered ? 6 : 3))
        let yOffset: CGFloat = isDisabled ? 0 : (configuration.isPressed ? 3 : (isHovered ? -1 : 0))

        configuration.label
            .font(.custom("Silkscreen-Regular", size: 14))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                isDisabled
                    ? Color.gray
                    : (configuration.isPressed ? Color.coffeeDark : Color.coffeeBrown)
            )
            .clipShape(PixelShape(cornerSize: 6))
            .overlay(
                PixelShape(cornerSize: 6)
                    .stroke(Color.black.opacity(0.4), lineWidth: 3)
            )
            .compositingGroup()
            .shadow(color: Color.black.opacity(0.5), radius: 0, x: 0, y: elevation)
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                if !isDisabled {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Pixel Icon Button Style (for small icon buttons)

struct PixelIconButtonStyle: ButtonStyle {
    @State private var isHovered: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let elevation: CGFloat = configuration.isPressed ? 0 : (isHovered ? 3 : 1)
        let yOffset: CGFloat = configuration.isPressed ? 1 : (isHovered ? -1 : 0)

        configuration.label
            .font(.system(size: 14))
            .foregroundStyle(isHovered ? Color.coffeeBrown : Color.coffeeBrown.opacity(0.8))
            .padding(6)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.coffeeLight : Color.white)
            )
            .overlay(
                Circle()
                    .stroke(Color.coffeeBrown.opacity(0.3), lineWidth: 1)
            )
            .compositingGroup()
            .shadow(color: Color.coffeeBrown.opacity(0.4), radius: 0, x: 0, y: elevation)
            .offset(y: yOffset)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
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

extension ButtonStyle where Self == PixelIconButtonStyle {
    static var pixelIcon: PixelIconButtonStyle { PixelIconButtonStyle() }
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
