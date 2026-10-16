import Foundation

/// A plain sRGB colour, kept free of any UI framework so the palette can be
/// asserted byte-for-byte in tests and shared with the headless renderer.
public struct RGB: Equatable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var hex: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }
}

/// Pip's Soft & Cozy palette. These are the exact bytes the art checklist fixes;
/// the view layer converts them to `Color` and the previews paint them directly.
public enum PipPalette {
    public static let body = RGB(0xF3, 0xED, 0xE3)
    public static let belly = RGB(0xFF, 0xFB, 0xF3)
    public static let blush = RGB(0xF5, 0xB8, 0xAD)
    public static let innerEar = RGB(0xF2, 0xA9, 0xA0)
    public static let ink = RGB(0x2B, 0x2A, 0x28)
    public static let nightcap = RGB(0x8E, 0x9B, 0xB0)
    public static let glow = RGB(0xFF, 0xC7, 0x6B)
}
