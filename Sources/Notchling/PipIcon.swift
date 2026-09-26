import AppKit

/// Draws Pip's head as a menu-bar template image, derived from the same round
/// silhouette as the on-screen creature: a soft head, two ears, and two eye
/// cut-outs. Template rendering lets the system tint it for light and dark menu
/// bars.
enum PipIcon {
    static func menuBar() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            draw(in: rect)
            return true
        }
        image.isTemplate = true
        return image
    }

    static func draw(in rect: NSRect) {
        let color = NSColor.black
        color.setFill()

        let head = rect.insetBy(dx: rect.width * 0.14, dy: rect.height * 0.20)
        let ears = NSBezierPath()
        let earWidth = head.width * 0.34
        let earHeight = head.height * 0.42
        ears.appendTriangle(
            NSPoint(x: head.minX + head.width * 0.20, y: head.maxY - earHeight * 0.30),
            NSPoint(x: head.minX + head.width * 0.20 - earWidth * 0.5, y: head.maxY + earHeight),
            NSPoint(x: head.minX + head.width * 0.20 + earWidth, y: head.maxY + earHeight * 0.1)
        )
        ears.appendTriangle(
            NSPoint(x: head.maxX - head.width * 0.20, y: head.maxY - earHeight * 0.30),
            NSPoint(x: head.maxX - head.width * 0.20 + earWidth * 0.5, y: head.maxY + earHeight),
            NSPoint(x: head.maxX - head.width * 0.20 - earWidth, y: head.maxY + earHeight * 0.1)
        )
        ears.fill()

        let headPath = NSBezierPath(ovalIn: head)
        let eyeWidth = head.width * 0.20
        let eyeHeight = head.height * 0.30
        let eyeY = head.midY - eyeHeight * 0.25
        let eyeOffset = head.width * 0.21
        headPath.appendOval(in: NSRect(
            x: head.midX - eyeOffset - eyeWidth / 2,
            y: eyeY,
            width: eyeWidth,
            height: eyeHeight
        ))
        headPath.appendOval(in: NSRect(
            x: head.midX + eyeOffset - eyeWidth / 2,
            y: eyeY,
            width: eyeWidth,
            height: eyeHeight
        ))
        headPath.windingRule = .evenOdd
        headPath.fill()
    }
}

private extension NSBezierPath {
    func appendTriangle(_ a: NSPoint, _ b: NSPoint, _ c: NSPoint) {
        move(to: a)
        line(to: b)
        line(to: c)
        close()
    }
}
