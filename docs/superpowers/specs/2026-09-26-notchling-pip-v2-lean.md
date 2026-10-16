# Notchling v2 — Cuter, Smaller, Extremely Lightweight

Status: agreed direction (2026-09-26). Binding for milestones P1–P4.

## Baseline (measured, packaged app, idle on built-in display)

- CPU ~0.4–3.4% (spiky, avg ~2%) — above the <1% goal.
- RSS ~29 MB; app bundle 788 KB.
- Panel window is **half the screen** (1512×491 built-in, 3440×720 ultrawide)
  while Pip is only 34pt tall.
- Idle cost comes from a 6 fps `Timer` re-drawing ~11 stroked SwiftUI shapes plus
  `.shadow()`, `.compositingGroup()`, and a `.blur()` glow every tick.

## Goals (measurable)

- **Light:** idle CPU **≤ 0.3% avg**, engaged **≤ 1.5%**, **0% while napping,
  muted, or the display is asleep/locked**; idle wakeups **≤ 1/s**, 0 at rest;
  window surface **≤ 200×180**.
- **Small:** Pip **≈ 22pt tall** (floor 18pt), configurable by a single constant.
- **Cute:** satisfies the art checklist in §Cute and passes a human look at the
  rendered previews.
- Every measurable item is covered by an automated test or `scripts/perf.sh`.

## Cutest plan (baby-schema chibi)

1. Proportions: head:body ≈ **1.35:1**; narrow shoulders, short body.
2. Eyes: **larger, lower** (centre slightly below face midline), **closer
   together**, **two catchlights** each (big + tiny).
3. Face: tiny **`‿` smile**; open happy mouth on tap; **blush cheeks**.
4. Line: thinner outline (~1px), outline the **outer silhouette only**.
5. Palette (Soft & Cozy):
   body `#F3EDE3`, belly `#FFFBF3`, blush `#F5B8AD`, inner ear `#F2A9A0`,
   ink `#2B2A28`, nightcap `#8E9BB0`, glow `#FFC76B`.
6. Motion: anticipation + overshoot squash/stretch, slow breathing, head tilt,
   ear flick, blink "pop", occasional hop. Spring physics, not linear.

Art directions (owner picks): **(A) Soft & Cozy chibi** (default), (B) pastel
marshmallow (rounder, no outline), (C) pixel-art sprite (lightest).

## Super small plan

- Single source of truth: `PipPlacement.figureHeight ≈ 22` (floor 18); width by
  aspect ~0.85. Both notch and floating-pill presentations shrink together.
- Panel envelope = figure × (max animation amplitude + shadow margin), fixed,
  anchored at the notch lip; target **≤ 160×140**.
- Add a minimum-size/readability test and render a 1× and 2× preview.

## Extremely lightweight plan

### Tier A — cheap wins on the SwiftUI path (low risk)
1. Shrink the fixed panel to the content envelope.
2. Bake the drop shadow into static art (or drop it); remove the per-frame
   `.blur()` glow (use an additive soft ellipse only while charging).
3. Drop `.compositingGroup()` from the per-frame path.
4. Drive breathing with a **single long-lived Core Animation** (autoreversing
   scale/rotation) instead of re-emitting a pose each tick; invalidate the view
   only on **discrete events** (blink, gaze change, mood change, reactions).
5. Cadence: engaged **24 fps**, idle **4 fps**, nap **0** (stop the timer; wake
   on cursor/audio/power events), mute/sleep/lock **0**.
6. Merge body+belly+head+ears into precomputed paths; recompute layout only on
   size change.

### Tier B — Core Animation rewrite (max lightweight, if Tier A is not enough)
- Replace the SwiftUI figure with a small `NSView` hosting 4–6 `CAShapeLayer`s
  (body, head+ears+tuft, eyes ×2, catchlights, accessory).
- Breathing = `CABasicAnimation` (repeat, autoreverse) → render server, ~0% CPU.
- Blink = one-shot `CAKeyframeAnimation` armed by a single low-frequency timer.
- Gaze/emote = set layer transforms **on events only**.
- All decision logic still lives in `NotchlingCore` (unchanged, tested).
- Enables art direction (C) pixel-art: one `CGImage` + transforms.

Do **Tier A first**, measure, then **Tier B** only if idle is not ~0%.

## Verification harness

- `scripts/perf.sh` — launch packaged app, settle, sample `%cpu` over 15s; assert
  idle avg ≤ 0.3% (engaged ≤ 1.5%). Non-zero exit on failure.
- Render-cost test — offscreen `ImageRenderer` of `PipFigure` across N poses;
  assert total time < budget (headless regression guard).
- Panel-size test — pure envelope function asserted ≤ 200×180 (no GUI).
- Cadence tests — idle ≥ 1/4 s; nap/mute/sleep ⇒ timer `nil`.
- `scripts/render-preview.sh` — emit `preview/*.png` for the poses idle, blink,
  happy, doze, nap, charging, nightcap for human sign-off.
- The existing gate `bash scripts/check.sh` stays green (no AppKit in Core, no
  private APIs, build, tests, probe).

## Guardrail

`AGENTS.md` rule 4 is amended: one **fixed** transparent panel sized to the
content's maximum animation envelope — never resized to morph the UI.

## Factory milestones

- **P1 — Cuter Pip:** §Cute changes + previews. Human sign-off on cuteness.
- **P2 — Super small:** §Super small (22pt + envelope + tests + previews).
- **P3 — Tier A lightweight:** §Tier A + `scripts/perf.sh`.
- **P4 — Tier B CA rewrite:** only if P3 idle is not ~0%.

CPU acceptance is automatable via `perf.sh`, so P3/P4 can be fully verified by
the factory; cuteness (P1) requires an owner look at the previews.
