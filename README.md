# Notchling

A tiny creature named **Pip** who lives in the MacBook notch.

Notchling is a macOS companion app: Pip perches on the lip of the notch, breathes,
blinks, looks around, naps while you work, and quietly reacts to your music, your
charging cable, and the time of day. He does nothing useful. He makes your Mac feel
a little more alive.

> **Starting work here?** Read [`HANDOVER.md`](HANDOVER.md) — current state and the
> exact next commands.
>
> Design and product plan:
> [`docs/superpowers/specs/2026-09-26-notchling-pip-design.md`](docs/superpowers/specs/2026-09-26-notchling-pip-design.md)

## How it's built

This repository is driven by a **personal software factory** (`psf`). Changes are
routed through the factory so each one gets a spec, an independent verifier, and a
review before handoff:

```
psf validate
psf run --git --harness opencode --model deepseek/deepseek-flash "<goal>"
psf status
```

The deterministic gate (`gates.verify_command` → `bash scripts/check.sh`) requires
the package to build, the tests to pass, and `NotchlingCore` to stay free of UI
frameworks.

## Package layout

| Path | What it is |
|---|---|
| `Sources/NotchlingCore/` | Pure logic: notch geometry, display selection, behavior engine, scheduler. No AppKit/SwiftUI. |
| `Sources/Notchling/` | The app: `NSPanel` overlay, SwiftUI views, menu-bar item. |
| `Sources/NotchlingProbe/` | Headless executable that prints computed geometry. |
| `Tests/NotchlingCoreTests/` | Unit tests for the core. |

## Commands

- Build: `swift build`
- Test: `swift test`
- Full deterministic check: `bash scripts/check.sh`
- Probe geometry headlessly: `swift run NotchlingProbe`
- Package the app: `bash scripts/package.sh` (writes `dist/Notchling.app`)
- Run the packaged app: `open dist/Notchling.app`

## Packaging and settings

`scripts/package.sh` builds `dist/Notchling.app`: an `LSUIElement` (menu-bar-only)
bundle with the creature icon and an ad-hoc signature, so it opens with one
menu-bar item, no Dock icon, and no ordinary window. Personality, Mute, and
Launch at Login are stored in `UserDefaults` under `com.notchling.pip.*` and
restored on the next launch. Pip prefers a notched display and falls back to a
floating pill, rebuilding a single panel when displays change and pausing
animation while muted, napping, or the display is asleep or locked.

## Hard rules

- Zero third-party dependencies. Foundation / AppKit / SwiftUI / CoreAudio / IOKit only.
- No private or undocumented APIs.
- Zero permissions in v1.
- The panel never takes focus or input from other apps.
- `NotchlingCore` never imports AppKit or SwiftUI.

See [`AGENTS.md`](AGENTS.md) for the full contract.

## License

MIT — see [`LICENSE`](LICENSE).
