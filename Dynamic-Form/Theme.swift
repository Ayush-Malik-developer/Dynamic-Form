//
//  Theme.swift
//  Eulerity Take-Home Exercise
//
//  Created by Ayush Malik on 01/06/26.
//

import Foundation
import SwiftUI

// MARK: - Theme model

struct Theme: Decodable {
    let backgroundColor: String
    let textColor: String
    let borderColor: String
    let errorColor: String

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor       = "text_color"
        case borderColor     = "border_color"
        case errorColor      = "error_color"
    }

    init(backgroundColor: String, textColor: String, borderColor: String, errorColor: String) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.errorColor = errorColor
    }

    /// Any missing key falls back to the default theme value.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColor = (try? c.decode(String.self, forKey: .backgroundColor)) ?? Theme.default.backgroundColor
        textColor       = (try? c.decode(String.self, forKey: .textColor))       ?? Theme.default.textColor
        borderColor     = (try? c.decode(String.self, forKey: .borderColor))     ?? Theme.default.borderColor
        errorColor      = (try? c.decode(String.self, forKey: .errorColor))      ?? Theme.default.errorColor
    }

    static let `default` = Theme(
        backgroundColor: "#FFFFFF",
        textColor:       "#111827",
        borderColor:     "#D1D5DB",
        errorColor:      "#B91C1C"
    )
}


// MARK: - Resolved colors (parsed once)

struct ThemeColors {
    let background: Color
    let text: Color
    let border: Color
    let error: Color

    init(_ theme: Theme) {
        background = Color(hex: theme.backgroundColor, fallback: .white)
        text       = Color(hex: theme.textColor,       fallback: .primary)
        border     = Color(hex: theme.borderColor,     fallback: .gray)
        error      = Color(hex: theme.errorColor,      fallback: .red)
    }
}

// MARK: - Hex parsing

extension Color {
    /// Supports #RGB, #RRGGBB, and #RRGGBBAA. Falls back on anything malformed.
    init(hex: String, fallback: Color = .gray) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else {
            self = fallback
            return
        }

        let r, g, b, a: Double
        switch cleaned.count {
        case 3: // RGB (4 bits per channel)
            r = Double((int >> 8) & 0xF) / 15
            g = Double((int >> 4) & 0xF) / 15
            b = Double(int & 0xF) / 15
            a = 1
        case 6: // RRGGBB
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
            a = 1
        case 8: // RRGGBBAA
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >> 8) & 0xFF) / 255
            a = Double(int & 0xFF) / 255
        default:
            self = fallback
            return
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
