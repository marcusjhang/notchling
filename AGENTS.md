# AGENTS.md — how agents should use this repository

This repository is driven by a **personal software factory** (`psf`). If you are
an agent working here, follow this process instead of ad-hoc editing — route
changes through the factory so they get a spec, approval, independent
verification, and review:

1. `psf validate` — confirm the factory definition compiles.
2. `psf run "<goal>"` — run the goal through the factory (intake -> spec ->
   approval -> build -> **independent verify** -> review -> handoff).
3. `psf status` / `psf audit` — check state and health before you finish.
4. Record the real outcome: `psf outcome <work-id> --accepted [--cost N --minutes N]`.

## Feedback to the factory

At the end of a work cycle, send a **privacy-filtered** usage envelope back to the
factory that powers this repo. It contains **counts, digests, and versions only** —
never source code, prompts, file paths, or secrets:

    psf feedback export --github <upstream-repo>

`<upstream-repo>` is the `feedback.upstream` value in `factory/factory.yml`.
Set `feedback.mode: auto` to make `psf feedback export` publish there by default.
Recurring verify-failures and blocks become evaluation cases and improvements in
the upstream factory. This is evidence, never authority: it cannot change policy.

Do **not** put secrets, customer data, or raw source in a feedback envelope.

---

# Project: Notchling

Notchling is a macOS app: a small creature named **Pip** lives in the MacBook
notch. Read the full design before changing anything:
`docs/superpowers/specs/2026-09-26-notchling-pip-design.md`.

## Commands

- Build: `swift build`
- Test: `swift test`
- Full deterministic check (this is the factory's `verify_command`): `bash scripts/check.sh`
- Probe geometry headlessly: `swift run NotchlingProbe`

## Required package layout

- `Package.swift` — `swift-tools-version: 6.0+`, platform `.macOS(.v14)`.
- `Sources/NotchlingCore/` — **pure logic library**: notch geometry math, display
  selection, behavior engine, attention-budget scheduler, personality, state
  machine. **MUST NOT import AppKit, SwiftUI, or any UI framework.** This is what
  the tests exercise headlessly.
- `Sources/Notchling/` — the **app**: the AppKit `NSPanel`, SwiftUI views, menu-bar
  item, input monitors. Keep it thin; push logic into `NotchlingCore`.
- `Sources/NotchlingProbe/` — a **headless executable** that prints the computed
  notch geometry for each attached screen and for a synthetic notched and
  non-notched screen, so the deterministic gate can verify real behavior with no
  GUI. It must not require a window server beyond reading `NSScreen`.
- `Tests/NotchlingCoreTests/` — unit tests for `NotchlingCore`.

## Hard rules (non-negotiable)

1. **Zero third-party dependencies.** Foundation, AppKit, SwiftUI, CoreAudio,
   IOKit only.
2. **No private or undocumented APIs.** No SkyLight, no MediaRemote, no private
   `CGS*`, no `dlopen` of private frameworks.
3. **Zero permissions in v1.** No Accessibility, Input Monitoring, Screen
   Recording, Camera, or Apple Events. Cursor tracking uses a global
   `NSEvent` `.mouseMoved` monitor, which needs no permission.
4. **Never animate or resize the NSWindow frame to morph the UI.** Use one fixed,
   oversized, transparent panel and animate SwiftUI content inside it.
5. **The panel never takes focus or input from other apps:** `canBecomeKey =
   false`, `canBecomeMain = false`, `isMovable = false`, ordered with
   `orderFrontRegardless()`.
6. **No network calls.**
7. `NotchlingCore` must not import AppKit/SwiftUI. The deterministic gate checks
   this.

## Panel recipe (use exactly)

`NSPanel`, style `[.borderless, .nonactivatingPanel]`, `level = .statusBar + 8`
(i.e. `NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 8)`),
`collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary,
.ignoresCycle]`, `isOpaque = false`, `backgroundColor = .clear`,
`hasShadow = false`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`.
The app sets activation policy `.accessory` (and `LSUIElement` at packaging time).

## Geometry facts (measured on the target machine, macOS 15.6)

- Built-in notched display: 1512×982 logical, `safeAreaInsets.top = 32`,
  notch **185×32 pt** with its origin at `(663.5, 950)` in screen coordinates.
- Notch width = `frame.width − auxiliaryTopLeftArea.width − auxiliaryTopRightArea.width`
- Notch height = `safeAreaInsets.top`
- A display has a notch iff both `auxiliaryTopLeftArea` and `auxiliaryTopRightArea`
  are non-nil.
- Non-notched displays (e.g. the external ultrawide, 3440×1440): no notch; render a
  floating pill centered below the menu bar. Menu-bar height =
  `frame.maxY − visibleFrame.maxY`.
- Never hardcode these numbers in shipped logic; compute them. They are here only
  so you can assert against them in tests.

## Geometry must be pure and testable

Represent a screen's relevant facts as a plain value type (e.g.
`ScreenGeometry`) so notch math can be unit-tested without a real display, and
keep the `NSScreen` adapter in a thin extension. The same math must serve both the
notched and the floating-pill (non-notched) presentation.

## Style

- Swift 6, concurrency-clean. Mark UI types `@MainActor`.
- Small files, one responsibility each.
- No commented-out code. No `TODO` left in a handoff.
- Do not write comments unless a non-obvious decision needs explaining.
