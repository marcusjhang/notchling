import AppKit
import NotchlingCore

func makeGeometry(_ screen: NSScreen) -> ScreenGeometry {
    let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    func rect(_ value: CGRect) -> Rect {
        Rect(x: Double(value.minX), y: Double(value.minY), width: Double(value.width), height: Double(value.height))
    }
    return ScreenGeometry(
        displayID: displayID,
        frame: rect(screen.frame),
        visibleFrame: rect(screen.visibleFrame),
        safeAreaTop: Double(screen.safeAreaInsets.top),
        auxiliaryTopLeftArea: screen.auxiliaryTopLeftArea.map(rect),
        auxiliaryTopRightArea: screen.auxiliaryTopRightArea.map(rect)
    )
}

func format(_ rect: Rect) -> String {
    let x = String(format: "%.1f", rect.minX)
    let y = String(format: "%.1f", rect.minY)
    let w = String(format: "%.1f", rect.width)
    let h = String(format: "%.1f", rect.height)
    return "(x: \(x), y: \(y), w: \(w), h: \(h))"
}

func describe(_ label: String, _ geometry: ScreenGeometry) -> String {
    let base = "\(label): frame=\(format(geometry.frame)) menuBarHeight=\(String(format: "%.1f", geometry.menuBarHeight)) hasNotch=\(geometry.hasNotch)"
    switch geometry.presentation {
    case .notch(let rect):
        return base + " presentation=notch rect=\(format(rect))"
    case .floatingPill(let rect):
        return base + " presentation=floatingPill rect=\(format(rect))"
    }
}

func presentationDescription(_ geometry: ScreenGeometry) -> String {
    switch geometry.presentation {
    case .notch(let rect):
        return "notch rect=\(format(rect))"
    case .floatingPill(let rect):
        return "floatingPill rect=\(format(rect))"
    }
}

let attached = NSScreen.screens.map(makeGeometry)
if attached.isEmpty {
    print("attached screens: none")
} else {
    for (index, geometry) in attached.enumerated() {
        print(describe("attached[\(index)]", geometry))
    }
}

let syntheticNotched = ScreenGeometry(
    displayID: 1,
    frame: Rect(x: 0, y: 0, width: 1512, height: 982),
    visibleFrame: Rect(x: 0, y: 0, width: 1512, height: 950),
    safeAreaTop: 32,
    auxiliaryTopLeftArea: Rect(x: 0, y: 950, width: 663.5, height: 32),
    auxiliaryTopRightArea: Rect(x: 848.5, y: 950, width: 663.5, height: 32)
)
print(describe("synthetic-notched", syntheticNotched))

let syntheticPlain = ScreenGeometry(
    displayID: 2,
    frame: Rect(x: 0, y: 0, width: 3440, height: 1440),
    visibleFrame: Rect(x: 0, y: 0, width: 3440, height: 1415),
    safeAreaTop: 0
)
print(describe("synthetic-non-notched", syntheticPlain))

// Mirrors the running app: selection is made from the real attached screens,
// so a non-notched-only machine reports a floating pill.
if let selected = DisplaySelection.preferred(from: attached) {
    print("display selection: displayID=\(selected.displayID) hasNotch=\(selected.hasNotch) presentation=\(presentationDescription(selected))")
} else {
    print("display selection: no attached screens")
}

// Demonstrates the same rule on the synthetic pair: the notched screen wins.
if let synthetic = DisplaySelection.preferred(from: [syntheticPlain, syntheticNotched]) {
    print("synthetic selection: displayID=\(synthetic.displayID) hasNotch=\(synthetic.hasNotch) presentation=\(presentationDescription(synthetic))")
}
