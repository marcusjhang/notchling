import Foundation

public enum Presentation: Equatable, Sendable {
    case notch(Rect)
    case floatingPill(Rect)

    public var rect: Rect {
        switch self {
        case .notch(let rect), .floatingPill(let rect):
            return rect
        }
    }
}

public struct ScreenGeometry: Equatable, Sendable {
    public static let floatingPillSize = Size(width: 220, height: 30)
    public static let floatingPillTopGap: Double = 6

    public var displayID: UInt32
    public var frame: Rect
    public var visibleFrame: Rect
    public var safeAreaTop: Double
    public var auxiliaryTopLeftArea: Rect?
    public var auxiliaryTopRightArea: Rect?

    public init(
        displayID: UInt32 = 0,
        frame: Rect,
        visibleFrame: Rect,
        safeAreaTop: Double,
        auxiliaryTopLeftArea: Rect? = nil,
        auxiliaryTopRightArea: Rect? = nil
    ) {
        self.displayID = displayID
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeftArea = auxiliaryTopLeftArea
        self.auxiliaryTopRightArea = auxiliaryTopRightArea
    }

    public var hasNotch: Bool {
        auxiliaryTopLeftArea != nil && auxiliaryTopRightArea != nil
    }

    public var menuBarHeight: Double {
        max(0, frame.maxY - visibleFrame.maxY)
    }

    public var notchRect: Rect? {
        guard let left = auxiliaryTopLeftArea, let right = auxiliaryTopRightArea else {
            return nil
        }
        let width = frame.width - left.width - right.width
        return Rect(
            x: frame.minX + left.width,
            y: frame.maxY - safeAreaTop,
            width: width,
            height: safeAreaTop
        )
    }

    public var floatingPillRect: Rect {
        let size = Self.floatingPillSize
        let width = min(size.width, frame.width)
        let top = frame.maxY - menuBarHeight - Self.floatingPillTopGap
        return Rect(
            x: frame.midX - width / 2,
            y: top - size.height,
            width: width,
            height: size.height
        )
    }

    public var presentation: Presentation {
        if let notchRect {
            return .notch(notchRect)
        }
        return .floatingPill(floatingPillRect)
    }
}
