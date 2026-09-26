import AppKit

// Renders Pip into every size iconutil expects. Run as:
//   swift scripts/make-icon.swift <output.iconset>
// It is a build-time helper only; the shipping app never runs it.

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: make-icon <iconset-dir>\n".utf8))
    exit(2)
}

let output = URL(fileURLWithPath: arguments[1], isDirectory: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
}

func drawPip(in rect: NSRect) {
    let side = rect.width
    let background = NSBezierPath(
        roundedRect: rect.insetBy(dx: side * 0.06, dy: side * 0.06),
        xRadius: side * 0.22,
        yRadius: side * 0.22
    )
    color(0.15, 0.14, 0.13).setFill()
    background.fill()

    let outline = max(1, side * 0.022)
    let bodyRect = NSRect(
        x: rect.midX - side * 0.28,
        y: rect.minY + side * 0.14,
        width: side * 0.56,
        height: side * 0.60
    )
    let headRect = NSRect(
        x: rect.midX - side * 0.33,
        y: rect.minY + side * 0.36,
        width: side * 0.66,
        height: side * 0.56
    )

    let ears = NSBezierPath()
    let earWidth = side * 0.20
    let earHeight = side * 0.24
    ears.appendTriangle(
        NSPoint(x: headRect.minX + headRect.width * 0.22, y: headRect.maxY - earHeight * 0.25),
        NSPoint(x: headRect.minX + headRect.width * 0.22 - earWidth * 0.4, y: headRect.maxY + earHeight),
        NSPoint(x: headRect.minX + headRect.width * 0.22 + earWidth, y: headRect.maxY + earHeight * 0.05)
    )
    ears.appendTriangle(
        NSPoint(x: headRect.maxX - headRect.width * 0.22, y: headRect.maxY - earHeight * 0.25),
        NSPoint(x: headRect.maxX - headRect.width * 0.22 + earWidth * 0.4, y: headRect.maxY + earHeight),
        NSPoint(x: headRect.maxX - headRect.width * 0.22 - earWidth, y: headRect.maxY + earHeight * 0.05)
    )
    color(0.93, 0.91, 0.87).setFill()
    ears.fill()
    color(0.17, 0.16, 0.15).setStroke()
    ears.lineWidth = outline
    ears.stroke()

    let body = NSBezierPath(ovalIn: bodyRect)
    color(0.93, 0.91, 0.87).setFill()
    body.fill()
    color(0.17, 0.16, 0.15).setStroke()
    body.lineWidth = outline
    body.stroke()

    let head = NSBezierPath(ovalIn: headRect)
    color(0.93, 0.91, 0.87).setFill()
    head.fill()
    color(0.17, 0.16, 0.15).setStroke()
    head.lineWidth = outline
    head.stroke()

    let belly = NSBezierPath(ovalIn: NSRect(
        x: bodyRect.midX - bodyRect.width * 0.20,
        y: bodyRect.minY + bodyRect.height * 0.18,
        width: bodyRect.width * 0.40,
        height: bodyRect.height * 0.34
    ))
    color(1.0, 0.97, 0.93).setFill()
    belly.fill()

    let eyeWidth = headRect.width * 0.20
    let eyeHeight = headRect.height * 0.34
    for offset in [-headRect.width * 0.19, headRect.width * 0.19] {
        let eye = NSBezierPath(ovalIn: NSRect(
            x: headRect.midX + offset - eyeWidth / 2,
            y: headRect.midY - eyeHeight * 0.15,
            width: eyeWidth,
            height: eyeHeight
        ))
        color(0.17, 0.16, 0.15).setFill()
        eye.fill()
    }
}

func render(size: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    drawPip(in: NSRect(x: 0, y: 0, width: size, height: size))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for (name, size) in sizes {
    guard let data = render(size: size) else {
        FileHandle.standardError.write(Data("failed to render \(name)\n".utf8))
        exit(1)
    }
    try data.write(to: output.appendingPathComponent(name))
}

print("wrote \(sizes.count) icon images to \(output.path)")

private extension NSBezierPath {
    func appendTriangle(_ a: NSPoint, _ b: NSPoint, _ c: NSPoint) {
        move(to: a)
        line(to: b)
        line(to: c)
        close()
    }
}
