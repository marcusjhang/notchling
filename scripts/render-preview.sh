#!/usr/bin/env bash
# Renders Pip's poses to preview/*.png so the owner can judge cuteness.
#
# Runs headless (no window is ever created): the renderer uses SwiftUI's
# offscreen ImageRenderer against the same PipFigure the app draws. Safe to run
# with no window server.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT_DIR="${1:-preview}"
mkdir -p "$OUT_DIR"

swift run NotchlingRender "$OUT_DIR"

echo "wrote previews to $OUT_DIR/"
