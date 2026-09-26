# Notchling — Product Plan & Design Spec

**A tiny creature named Pip who lives in the MacBook notch.**

Date: 2026-09-26
Status: Draft — awaiting approval
Owner: Marcus

---

## 1. One-liner

Pip is a small, hand-drawn creature who perches on the lip of your MacBook notch,
breathes, blinks, looks around, naps when you're busy, and quietly reacts to your
music, your charging cable, and the time of day. It does not do anything useful.
It is there to make your Mac feel a little more alive.

## 2. Why build this

**The honest market read (researched 2026-09-26):**

| Signal | Finding |
|---|---|
| Dedicated notch-pet apps | **0 ratings each** on the US Mac App Store (Notch Pet, KeyPets, Dockitty, MaoMao, Pixel Pets). Nobody has traction. |
| Desktop pets generally | **Bongo Cat: 23,618★** (pushed today), oneko.js 1,320★, Pets Therapy 3.7★/51 ratings. The genre clearly resonates. |
| Notch *utility* apps | Boring Notch 10,864★, Atoll 4,772★, NotchDrop 2,116★ — thriving and commoditized. |

Conclusion: "notch mascot" is an **unproven commercial lane** — either no demand or
no one has built one with real craft. But the *personal* value is high and the
build is cheap and permission-free.

**Therefore this is scoped as a personal, craft-first project.** Optimize for
Marcus happily running it every day, not for App Store revenue. If it turns out
delightful, distribution is a later question.

### 2.1 The unclaimed lane

Every shipping notch app competes on **utility** (now-playing, file shelf, HUD
replacement). The delightful, well-made version of the *character* lane is
unclaimed. The proof points that people want this: Notch Pet ($3.99, "does not do
anything"), KeyPets (types along with you), Dockitty (naps on your windows),
Bongo Cat (mirrors your hands).

### 2.2 The rule that separates cute from gimmicky

| Cute | Gimmicky |
|---|---|
| Ambient, present, never demanding | Hijacks cursor/keys/focus |
| Reacts but never obstructs | Blocks content |
| Idle life when ignored | Only moves when poked |
| No punishment, no guilt, no streaks | "Your pet ran away" |
| Restraint + hard off switch | No mute, mounting chaos |
| A few perfect animations | Fifty wobbly ones |

Desktop Goose is the cautionary tale: charming until it steals the cursor. Pip
will never take input, never block a click, never nag.

---

## 3. The character: Pip

**Pip** is a small round creature — a soft blob with a big head, two large
expressive eyes, a little tuft, small ears, and two tiny arms that grip the
notch lip. It lives *in* the notch and hangs *down* from it.

### 3.1 Why hanging below the notch

The notch is pure black and only ~185×32pt on this machine. A creature drawn
*inside* it is invisible against itself. By having Pip perch on the bottom lip and
hang into the screen, it lives against the wallpaper where it is visible, while the
notch becomes its burrow/doorway — Pip can retreat up into it and "hide."

### 3.2 Design language

- **Silhouette-first.** Must read at 40–70pt tall. Big head:body ratio (baby
  schema), round forms, no small fiddly details.
- **Reads on any wallpaper.** Warm light-grey body with a soft dark outline and a
  cream belly; coral inner-ears and nose; large dark eyes with white catchlights.
  A subtle drop shadow separates it from the desktop. Works on light *and* dark.
- **Eyes do the heavy lifting.** All emotion is carried by eye shape, eyelid
  position, pupil direction, and body posture — no brow detail needed.
- **Palette (Soft & Cozy default):**
  - body `#ECE7DE`, outline `#2B2A28` (soft, ~2pt), belly `#FFF8EE`
  - eyes `#2B2A28`, catchlight `#FFFFFF`
  - inner ear / nose / blush `#F2A9A0`
  - nap Zzz / accents `#8E9BAE`
- **Alternate skin:** Pixel-art retro and Neon/cyber are stretch goals, not v1.

### 3.3 Independently animated parts

`body` (squash/stretch) · `head` (offset/rotation for look-around) · `eyes`
(pupils, eyelids, catchlights) · `tuft` + `ears` (secondary/overlap motion) ·
`arms` (grip lip, tap, wave) · `belly` (breathing) · `mouth` (subtle) ·
`blush` (opacity).

---

## 4. Experience

### 4.1 The four layers of behavior

1. **Continuous breathing** — the always-on baseline. Slow squash/stretch on a
   ~2.5s cycle. Pip is never fully frozen.
2. **Micro-behaviors** — short, randomized flourishes on an **attention budget**:
   blink, look around, ear/tuft twitch, weight shift, stretch, yawn, scratch.
3. **Moods / states** — longer arcs: `idle → doze → nap → wake`; morning perk;
   late-night nightcap; low-battery sleepy.
4. **Reactions** — interrupts to inputs: cursor near, hover, click, audio playing,
   power connected. Each plays, then Pip returns to whatever it was doing.

### 4.2 State machine

```
                 ┌──────────────────────────────────────────────┐
                 │                 AMBIENT                       │
   launch ──────▶│  Breathe (always)                             │
                 │    ├─ micro: Blink / LookAround / Twitch /    │
                 │    │        Shift / Stretch / Yawn            │
                 │    └─ long:  Idle ──▶ Doze ──▶ Nap ──▶ Wake   │
                 └───────▲───────────────────────────────────────┘
                         │ resolve after reaction (resume prior state)
                 ┌───────┴───────────────────────────────────────┐
                 │                REACTIVE                        │
                 │  CursorNear · Hover · Click · MusicPlaying ·   │
                 │  Charging · TimeOfDay · ScreenWake             │
                 └───────────────────────────────────────────────┘
```

**Priority:** Reactive > Mood > Micro-behavior. Continuous breathing underlies all.
Nap is interruptible by cursor/audio/input. Reactions never queue up — a new one
preempts and re-resolves.

### 4.3 Attention budget (the anti-distraction core)

A scheduler decides *how often* micro-behaviors fire, so Pip feels alive without
becoming a fidgeting distraction.

| Personality | Micro-behavior cadence | Naps after | Cursor following | Music |
|---|---|---|---|---|
| **Quiet** | every ~25–45s | ~90s idle | subtle (eyes only) | no |
| **Companion** *(default)* | every ~8–20s | ~5 min idle | yes | gentle bob |
| **Playful** | every ~4–10s | ~10 min idle | yes, exaggerated | full dance |

Rendering also backs off: when napping or when the display is asleep/locked, Pip
renders at 0–2fps (or pauses entirely).

### 4.4 Reactions in detail

| Input | Detection (all public APIs, no permissions) | Pip's behavior |
|---|---|---|
| Cursor near | global `NSEvent` `.mouseMoved` monitor → `NSEvent.mouseLocation` tested against notch/figure rect | perks up, eyes+head track cursor within limits, leans toward it |
| Hover on Pip | SwiftUI `.onHover` + matching `.contentShape` | emerges further from the notch, happy wiggle, tuft perks |
| Click | SwiftUI tap | happy bounce + squash-and-stretch; occasionally a little "chirp" pose |
| Music playing | CoreAudio: default output device `kAudioDevicePropertyDeviceIsRunningSomewhere` (boolean only, no audio capture) | bobs/sways while audio runs, settles when it stops |
| Charging | IOKit power source / `NSProcessInfo` thermal or `IOPSGetTimeRemainingEstimate`& friends | warm glow, snuggles down, slow content breathing |
| Low battery | same | sleepy, droopy ears |
| Time of day | clock | morning stretch + perk; late night = nightcap + yawns; midday = neutral |
| Screen wake | `NSWorkspace.didWakeNotification` / screensleep | stretch, blink awake, resume |
| Ambient idle | clock of last interaction | doze → nap with floating "z" |

### 4.5 What Pip will never do (anti-features)

No file shelf, no clipboard, no AI chat, no games, no notifications, no HUD
replacement, no ads, no telemetry, no accounts. No cursor stealing, no window
hijacking, no blocking input, no guilt/streaks/"your pet is sad". No private
frameworks in v1. If we ever add utility, it must be opt-in and off by default.

**v1 permission set: none.** No Accessibility, no Input Monitoring, no Screen
Recording, no Camera. If typing reactions are added later they are opt-in and
gated behind an explicit enable.

---

## 5. Scope & milestones

### v1 — "Alive" (the goal)
M0. **Skeleton** — SwiftPM package, accessory app, panel appears at the notch with
    a debug shape; correct on built-in (185×32) and floating-pill fallback on the
    ultrawide.
M1. **Character static** — Pip drawn, perched, correct scale/position/hit area.
M2. **Idle life** — breathing, blinking, look-around, micro-behaviors, nap cycle.
    Personality dial wired.
M3. **Reactivity** — cursor following, hover emerge, click bounce.
M4. **System reactions** — music bob, charging glow, time-of-day moods.
M5. **Polish** — menu-bar menu (personality, mute, quit, launch at login),
    multi-display handling, sleep/wake, screen-change handling, performance pass.
M6. **Packaging** — `Notchling.app` bundle, icon, ad-hoc signature, `open` to run,
    short README.

### Later (explicitly deferred)
Typing reactions (opt-in, needs Input Monitoring) · window-napping (Pip strolls
onto your active window) · beat-accurate dancing (audio tap) · seasonal skins ·
multiple creatures · iPhone/Apple-Watch companion. Each is its own design cycle.

### Success criteria
1. Marcus leaves it running for a week and doesn't want to quit it.
2. Idle CPU **< 1%**, no measurable battery impact, no fan.
3. It makes him smile at least once a day.
4. It never interrupts or blocks work. Ever.

---

## 6. Technical architecture

### 6.1 Stack
Swift 6.2 / SwiftUI + AppKit, macOS 14+ (developed on macOS 15.6, Xcode 26.3).
Built with SwiftPM and packaged into a `.app`. No third-party dependencies.

### 6.2 Module map

| Module | Responsibility |
|---|---|
| `AppLifecycle` | `NSApplication` accessory policy, menu-bar item, launch-at-login, mute/personality, quit |
| `NotchGeometry` | `NSScreen` extensions; notch rect from `safeAreaInsets` + `auxiliaryTop*Area`; floating fallback; display selection & screen-change observer |
| `Panel` | `NSPanel` subclass; fixed oversized transparent stage; ordering; lock/unlock; fullscreen |
| `BehaviorEngine` | Ambient/reactive state machine, attention-budget scheduler, reaction arbitration |
| `Inputs` | `CursorTracker` (global mouse monitor), `AudioActivityMonitor` (CoreAudio), `PowerMonitor` (IOKit), `Clock`, `SleepWake` |
| `Rendering` | SwiftUI `CreatureView` + body parts; animatable `Shape`s; `TimelineView` driver |
| `Settings` | `UserDefaults`-backed personality/mute/display/launch-at-login |

### 6.3 Window recipe (settled by research across shipping apps)
- `NSPanel`, style `[.borderless, .nonactivatingPanel]`
- `level = .statusBar + 8` (draws over the menu-bar/notch band, below `.screenSaver`)
- `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]`
- `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`,
  `hidesOnDeactivate = false`, `isMovable = false`, `isReleasedWhenClosed = false`
- `canBecomeKey/Main = false` (read-only HUD — Pip never takes focus)
- Ordered with `orderFrontRegardless()` so the app never activates
- `LSUIElement = true` — menu-bar-only, no Dock icon

### 6.4 The morph rule
The window stays **fixed and oversized** (full width × top half of screen,
top-centered). Only SwiftUI content animates inside it. Animating the `NSWindow`
frame is the #1 source of jank and is avoided. Pip's shape uses a `Shape` with
`animatableData` (squash/stretch + perch width), driven by one shared spring.
A black backing larger than the mask prevents spring-overshoot gaps.

### 6.5 Geometry (measured on the target machine)
- Built-in: 1512×982 logical, `safeAreaInsets.top = 32`, notch **185×32pt** at
  `(663.5, 950)`.
- Notch width = `frame.width − auxiliaryTopLeftArea.width − auxiliaryTopRightArea.width`
- Notch height = `safeAreaInsets.top`
- Non-notched (ultrawide CU34G2XP, 3440×1440): floating pill below the menu bar.
- Display chosen by stable `CGDisplayCreateUUIDFromDisplayID` UUID; rebuild on
  `didChangeScreenParametersNotification`.

### 6.6 Performance & battery budget
- Event-driven inputs; no polling faster than ~2Hz, most far slower.
- Rendering via a single `TimelineView`; capped to 30fps while animating, paused
  or ~1fps while napping / display asleep / screen locked.
- Music detection is a boolean (is output running), **not** audio capture — no
  CPU-heavy FFT and no permission.
- Target: idle CPU **< 1%**, memory < 60MB.

### 6.7 Risks & mitigations
| Risk | Mitigation |
|---|---|
| Novelty decay | Personality dial with a quiet, receding default; naps; hard mute |
| Distraction | Ambient only; never takes focus/input; attention budget |
| Battery/CPU | Event-driven, low fps, pause when hidden |
| macOS updates breaking it | **Public APIs only in v1**; graceful degradation |
| Multi-monitor confusion | Default to built-in notch; user-selectable display |
| TCC friction | v1 requests **zero** permissions |
| Scope creep | Anti-features list is binding; utility is a separate project |

---

## 7. Open questions (need answers before M1)

1. **Art direction** — Soft & Cozy (my default), Pixel-art retro, or Neon/cyber?
2. **Character sign-off** — Is **Pip** (soft blob, big eyes, perches on the notch
   lip and hangs down) the right creature? Name changeable.
3. **First milestone depth** — full v1 (idle + cursor + music + charging +
   time-of-day) or **minimal first** (window + geometry + idle life + cursor),
   then live with it a day before adding the rest?

## 8. What "done" looks like

A menu-bar-only app called Notchling. Pip lives at your notch. He breathes. He
blinks. He tracks your cursor, naps when you're heads-down, sways when music
plays, snuggles when you plug in, and wears a nightcap after midnight. He never
steals your cursor, never blocks a click, and disappears the moment you tell him
to. Idle CPU under 1%. You leave him running.
