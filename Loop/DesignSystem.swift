//
//  DesignSystem.swift
//  Loop
//

import SwiftUI

enum LoopDS {

    enum Colors {
        // Backgrounds
        static let background = Color(.systemBackground)
        static let surface = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // Primary accent — deep teal
        static let accent = Color(light: Color(hex: "1B4F72"), dark: Color(hex: "5DADE2"))

        // Semantic glucose
        static let glucoseSafe    = Color(hex: "27AE60")
        static let glucoseWarning = Color(hex: "F39C12")
        static let glucoseUrgent  = Color(hex: "E74C3C")

        // Tints
        static let insulinTint   = Color(hex: "2E86AB")
        static let carbTint      = Color(hex: "E67E22")
        static let biometricTint = Color(hex: "8E44AD")

        // Text
        static let primary   = Color(.label)
        static let secondary = Color(.secondaryLabel)
        static let tertiary  = Color(.tertiaryLabel)
    }

    enum Typography {
        static let largeTitle  = Font.largeTitle.weight(.bold)
        static let title       = Font.title2.weight(.semibold)
        static let headline    = Font.headline
        static let body        = Font.body
        static let subheadline = Font.subheadline
        static let caption     = Font.caption
        static let caption2    = Font.caption2

        // For numeric readouts — monospaced digits for stability
        static let readout      = Font.system(size: 28, weight: .bold, design: .rounded).monospacedDigit()
        static let readoutSmall = Font.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit()
        static let metric       = Font.system(size: 16, weight: .semibold, design: .rounded).monospacedDigit()
    }

    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let card: CGFloat = 20
    }

    enum Shadow {
        static func card(scheme: ColorScheme) -> some View {
            EmptyView()
        }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}
