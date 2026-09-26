#!/usr/bin/env bash
# Deterministic factory gate for Notchling.
#
# The factory runs this in the isolated build workspace after every implement
# attempt. Any non-zero exit fails verification and loops the work item back to
# BUILD. It must therefore be fast, deterministic, and unambiguous.
set -euo pipefail
cd "$(dirname "$0")/.."

fail() { echo "check FAILED: $*" >&2; exit 1; }

[ -f Package.swift ] || fail "Package.swift is missing at the repo root"

echo "== guard: NotchlingCore must stay pure (no UI frameworks) =="
if grep -RInE '^[[:space:]]*import[[:space:]]+(AppKit|SwiftUI|Cocoa)([[:space:]]|$)' \
     Sources/NotchlingCore 2>/dev/null; then
  fail "NotchlingCore imports AppKit/SwiftUI; it must stay a pure logic library"
fi

echo "== guard: no private frameworks / dynamic loading =="
if grep -RInE '(SkyLight|MediaRemote|dlopen|CGS[A-Z])' Sources 2>/dev/null; then
  fail "private/undocumented API reference found in Sources"
fi

echo "== swift build =="
swift build

echo "== swift test =="
swift test

echo "== headless geometry probe =="
swift run NotchlingProbe >/dev/null

echo "check OK"
