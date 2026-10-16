import Foundation
import CoreGraphics
import NotchlingCore
import NotchlingUI

// Headless preview renderer. Walks Pip's poses and writes one PNG each at 1x and
// 2x into the target directory (default: preview/). Run as
// scripts/render-preview.sh.

@MainActor
func renderAll(into directory: URL) {
    do {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
        FileHandle.standardError.write(Data("could not create \(directory.path): \(error)\n".utf8))
        exit(2)
    }

    for entry in PipPose.previewPoses {
        for scale: CGFloat in [1, 2] {
            guard let data = PipPreview.pngData(for: entry.pose, scale: scale) else {
                FileHandle.standardError.write(Data("failed to render \(entry.name)@\(Int(scale))x\n".utf8))
                exit(1)
            }
            let name = "\(entry.name)@\(Int(scale))x"
            let url = directory.appendingPathComponent("\(name).png")
            do {
                try data.write(to: url)
                print(url.path)
            } catch {
                FileHandle.standardError.write(Data("failed to write \(name): \(error)\n".utf8))
                exit(1)
            }
        }
    }
}

let directory = URL(
    fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "preview",
    isDirectory: true
)
renderAll(into: directory)
