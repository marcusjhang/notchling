# HANDOVER — Notchling

Hand this file to any fresh agent session. It is self-contained: what we're
building, what's already done, and the exact next commands.

---

## 1. Where things stand

| Thing | Status |
|---|---|
| Public repo | **https://github.com/marcusjhang/notchling** (public, `main`) |
| Superset project | `notchling` → `/Users/marcusjhang/.superset/projects/notchling` |
| Product design spec | ✅ committed — `docs/superpowers/specs/2026-09-26-notchling-pip-design.md` |
| PSF factory | ✅ scaffolded, tuned, `psf validate` green |
| Project contract | ✅ `AGENTS.md` (hard rules + required package layout) |
| Deterministic gate | ✅ `scripts/check.sh` — **green on `main` @ `d8acc0e`, 57 tests** |
| Code | ✅ **M0–M6 implemented.** `Package.swift`, `Sources/NotchlingCore` (pure), `Sources/Notchling` (app), `Sources/NotchlingProbe`, `Tests/NotchlingCoreTests` |
| Packaged app | ✅ `bash scripts/package.sh` → `dist/Notchling.app` (LSUIElement, ad-hoc signed) |

**RESUME HERE (2026-09-26).** All six milestones are merged to `main` and the
deterministic gate passes. What remains is **manual, human verification of the
M5+M6 acceptance**, which the automated verifier cannot judge (no GUI, no real
CPU measurement):

1. Run it: `swift run Notchling` or `bash scripts/package.sh && open dist/Notchling.app`.
2. Confirm: one menu-bar creature icon, no Dock icon, no window; menu has
   personality (exactly one checked), Mute, Launch at Login, Quit; Quit removes the
   item; settings survive relaunch; Mute stops all motion; idle CPU < ~1%; napping
   and display-sleep pause animation.
3. Art direction is still an **open decision** (see §8). By owner request Pip was
   shrunk from 56pt to **34pt** (`Sources/NotchlingCore/PipPlacement.swift`,
   `figureHeight`) after the first local look.

Factory state: `psf status` — **W-14179d13 (M5+M6) is `VERIFY` (attempt 3/3)** and
its work was merged to `main` from branch `psf/W-14179d13` (pushed as
`origin/psf/W-14179d13`) because review kept looping on the manual acceptance
criteria. After your manual pass, record it:
`psf outcome W-14179d13 --accepted`.

---

## 2. What we're building

**Notchling** is a macOS menu-bar companion: a small, hand-drawn creature named
**Pip** lives in the MacBook notch. Pip perches on the notch lip, hangs down
against the wallpaper, breathes, blinks, looks around, naps, and quietly reacts to
music, charging, the cursor, and the time of day. Cute-first, ambient, zero
permissions, hard mute.

Read the full design: `docs/superpowers/specs/2026-09-26-notchling-pip-design.md`.
Read the binding rules: `AGENTS.md`.

---

## 3. Environment (verified on this machine)

- MacBook Pro `Mac16,8`, M4 Pro, 24 GB, **macOS 15.6 (24G84)**
- **Xcode 26.3**, **Swift 6.2.4**
- Built-in notched display: 1512×982 logical, `safeAreaInsets.top = 32`,
  notch **185×32 pt** at `(663.5, 950)`
- External ultrawide `CU34G2XP` 3440×1440, **no notch** (floating-pill fallback)
- `psf 0.1.0` at `~/.local/bin/psf`
- harness: `opencode 1.18.32`, model `deepseek/deepseek-flash`

---

## 4. The factory

Configured in `factory/factory.yml`:

- runner: `subprocess` → `python -m psf.adapters.opencode --model deepseek/deepseek-flash --permissions workspace`
- gates: `spec_approval: true`, `verify_quorum: 2`,
  **`verify_command: "bash scripts/check.sh"`**
- limits: `max_attempts: 3`, `max_minutes: 30`
- mode: `hitl`; feedback: `off`

`scripts/check.sh` is the deterministic gate. It fails the build unless:
1. `NotchlingCore` contains **no** `import AppKit|SwiftUI|Cocoa`
2. no private-API references (`SkyLight`, `MediaRemote`, `dlopen`, `CGS*`)
3. `swift build` succeeds
4. `swift test` passes
5. `swift run NotchlingProbe` runs

Lifecycle: `INTAKE → TRIAGE → SPEC → SPEC_REVIEW → READY → BUILD → VERIFY(×2) → REVIEW → HANDOFF → DONE`.

---

## 5. Milestones & copy-paste goals

**All done and merged to `main` (G1–G6).** Kept below for reference only — do not
re-run them unless you are intentionally rebuilding a milestone. Run them **in
order**; each builds on the merged result of the last.

### G1 — M0: skeleton, panel, geometry, probe, tests
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M0: create the Swift Package skeleton for a macOS notch companion app. Follow docs/superpowers/specs/2026-09-26-notchling-pip-design.md and AGENTS.md. Deliver: Package.swift (swift-tools-version 6.0, platform macOS 14, zero third-party dependencies) with targets NotchlingCore (pure logic: notch geometry math plus display selection, no AppKit/SwiftUI imports), Notchling (app executable: an NSPanel overlay positioned at the top-center notch using the exact panel recipe in AGENTS.md, with a minimal placeholder SwiftUI view), NotchlingProbe (headless executable that prints computed geometry for each attached screen and for synthetic notched and non-notched inputs), and Tests/NotchlingCoreTests. Behavior: a notched screen yields a 185x32 notch rect at origin (663.5, 950); a non-notched screen yields a floating pill rect below the menu bar; display selection prefers the notched built-in display. bash scripts/check.sh must pass."
```

### G2 — M1: static Pip character
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M1: the static Pip character. In Sources/Notchling add a SwiftUI vector Pip: a small round creature perching on the bottom lip of the notch and hanging down, drawn from custom Shapes (body with squash/stretch-ready animatableData, big head, two large eyes with catchlights, tuft, ears, two tiny arms gripping the notch lip, cream belly, soft dark outline). About 40-70pt tall, anchored top-center on the notch rect, readable on light and dark wallpapers, with a matching contentShape so hit-testing follows the drawn silhouette. Keep placement/size math in NotchlingCore and unit-test it (figure rect centered on the notch, hanging below it). bash scripts/check.sh must pass."
```

### G3 — M2: idle life + behavior engine + personality
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M2: ambient idle life and the behavior engine. In NotchlingCore add a deterministic, clock-injected BehaviorEngine: continuous breathing, randomized micro-behaviors (blink, look around, ear/tuft twitch, weight shift, stretch, yawn), and a mood arc idle to doze to nap to wake governed by an attention budget. Add a Personality enum (quiet, companion, playful) with per-personality micro-behavior cadence and nap delay. Drive the SwiftUI creature from the engine via one TimelineView and one shared spring; breathing always runs. Unit-test with seeded randomness and an injected clock: expected sequence, budget respected, personality changes cadence. bash scripts/check.sh must pass."
```

### G4 — M3: reactivity (cursor, hover, click)
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M3: reactivity. Add cursor tracking with a global NSEvent .mouseMoved monitor (no permissions) so Pip eyes and head follow the cursor within limits and he perks up when it is near; add hover to emerge further from the notch, and a click bounce with squash and stretch. Keep arbitration in NotchlingCore (ReactionState; priority reactive over mood over micro), put inputs behind a protocol so they are testable, and unit-test the transitions. bash scripts/check.sh must pass."
```

### G5 — M4: system reactions
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M4: system reactions. Add: music sway when the default audio output device is running (CoreAudio kAudioDevicePropertyDeviceIsRunningSomewhere boolean only, no audio capture, no permission); a warm glow and snuggle when charging (IOKit power source); and time-of-day moods (perky morning, nightcap after about 23:00). Monitoring must be event-driven and cheap; inject clocks and system state behind protocols and unit-test the reaction triggers. bash scripts/check.sh must pass."
```

### G6 — M5+M6: polish + packaging
```
psf run --git --harness opencode --model deepseek/deepseek-flash --permissions workspace --no-ask "Notchling milestone M5+M6: polish and packaging. Add a menu-bar item with a creature icon and a menu (personality quiet/companion/playful, Mute, Launch at Login, Quit), persist settings in UserDefaults, handle multiple displays (prefer the notched built-in, floating pill on the ultrawide) and rebuild the panel on NSApplication.didChangeScreenParametersNotification, handle screen sleep/lock/wake, and package Notchling.app (Info.plist with LSUIElement true, icon, ad-hoc codesign). Keep idle CPU under about 1 percent and pause animation while napping or when the screen is asleep. Add scripts/package.sh. bash scripts/check.sh must pass."
```

---

## 6. The loop for every goal

```bash
cd /Users/marcusjhang/.superset/projects/notchling

# 1. run (background + log; a full run is ~6 nested agent calls, can take minutes)
nohup psf run --git --harness opencode --model deepseek/deepseek-flash \
  --permissions workspace --no-ask "<GOAL>" > /tmp/psf.log 2>&1 &
tail -f /tmp/psf.log

# 2. check state
psf status
psf log | tail -40

# 3. inspect the handoff: worktree on branch psf/<W-id>, changes NOT committed
ls .psf/worktrees/                 # e.g. W-1a2b3c4d
cd .psf/worktrees/<W-id>
bash scripts/check.sh              # independent re-run of the gate
swift run NotchlingProbe           # see the geometry it computed
git status --short; git diff

# 4. accept: commit in the worktree, merge into main, push
git add -A && git commit -m "M0: <what it does>"
cd /Users/marcusjhang/.superset/projects/notchling
git merge --no-ff psf/<W-id> -m "Merge <W-id>: <milestone>"
git push origin main

# 5. record the outcome (factory self-improvement signal)
psf outcome <W-id> --accepted
```

If verification fails, the factory loops back to BUILD automatically (up to 3
attempts), then marks the item `BLOCKED`. Inspect with `psf log`, fix the goal or
the acceptance, and re-run.

---

## 7. Gotchas (already learned the hard way)

1. **`SPEC_REVIEW` has no resume command.** Default `psf run` auto-approves the
   spec as `owner`; `--no-approve` stops the run and it *cannot* be resumed. Use
   the default and review the **handoff** instead.
2. **`verify_command` is `shlex.split` and run without a shell** — so no `&&`.
   That is exactly why the gate is `bash scripts/check.sh`.
3. **PSF git handoffs are uncommitted.** The implement agent is told "Do not
   commit", so the `psf/<id>` branch has no commits and `git diff HEAD` may show
   only untracked file names for greenfield work. **You must commit in the
   worktree, then merge.** The files themselves are real — inspect them.
4. **Push auth:** plain `git push` over SSH authenticates as GitHub account
   `maekuss`, which does **not** have access. The repo belongs to `marcusjhang`.
   The remote is already set to HTTPS (`https://github.com/marcusjhang/notchling.git`)
   and `gh auth setup-git` is configured. Do not switch it back to SSH.
5. **`.psf/` is gitignored** (local ledger + worktrees + durability db). Never commit it.
6. **Nested harness is fine** — `opencode run --dir <ws> --auto --model deepseek/deepseek-flash`
   was smoke-tested and works.
7. **The verifier cannot see a GUI.** Deterministic verification is compile +
   unit tests + the headless probe. Visual/cute judgment is manual — run the app
   and look at it.
8. **`gates.verify_quorum: 2`** means the verifier runs twice per attempt. Runs are
   not instant; budget `max_minutes: 30` per work item.

---

## 8. Open decisions (the human should confirm before/at G2)

1. **Art direction** — Soft & Cozy (assumed default: warm-grey body `#ECE7DE`,
   dark outline, cream belly `#FFF8EE`, coral inner-ears `#F2A9A0`), **or**
   Pixel-art retro, **or** Neon/cyber.
2. **Character sign-off** — is **Pip** (soft round blob, big eyes, perches on the
   notch lip and hangs down) the right creature? Name is changeable.
3. **Scope** — build M0–M3, live with it a day, then continue (recommended), or
   push straight through M0–M6.

---

## 9. Definition of done

A menu-bar-only `Notchling.app`. Pip lives at the notch: breathes, blinks, tracks
the cursor, naps when you're heads-down, sways when music plays, snuggles when you
plug in, wears a nightcap after midnight. He never steals the cursor, never blocks
a click, and vanishes when told. **Idle CPU under 1%.** You leave him running.

---

## 10. Key files

```
AGENTS.md                                   # binding project contract for agents
README.md                                   # public-facing overview
docs/superpowers/specs/2026-09-26-notchling-pip-design.md   # the product plan
factory/factory.yml                         # factory config (gate, limits, harness)
factory/agents/*.md                         # role prompts (triage/spec/implement/verify/review)
scripts/check.sh                            # deterministic verify gate
eval/tasks.json, eval/holdout.json          # factory eval fixtures (currently template)
```
