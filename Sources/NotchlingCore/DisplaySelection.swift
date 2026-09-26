import Foundation

public enum DisplaySelection {
    public static func preferred(from displays: [ScreenGeometry]) -> ScreenGeometry? {
        displays.first(where: \.hasNotch) ?? displays.first
    }
}
