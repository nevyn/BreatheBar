# BreatheBar — Agent Guide

> **Keep this file accurate.** If you change something this doc describes, update the relevant section.

BreatheBar is a macOS menu bar app for hourly breathing reminders. Core philosophy: **non-intrusive**. No notifications, no alerts, no Dock icon — just a subtle icon pulse the user can ignore until they're ready.

---

## Architecture in one paragraph

`AppState` (@Observable) owns a 5-second polling timer and all mutable state. `AppDelegate` wires `AppState` to the three AppKit controllers (`StatusItemController`, `BreathingWindowController`, `SettingsWindowController`) using `withObservationTracking`. Views are SwiftUI hosted inside AppKit windows — **don't try to manage windows from SwiftUI scenes**.

---

## State machine gotcha

Three booleans interact in a non-obvious way across `AppState` and `BreathingSettings`:

- `isPrimed` — within work hours, reminders active
- `isBreathingTime` — it's :55–:59, show the pulse
- `breathingDone` — user dismissed this hour's reminder

`markDone()` does **not** re-prime the scheduler. The scheduler only re-primes itself when the clock rolls past :00. This prevents the reminder re-firing within the same 5-minute window. If you touch the scheduler logic, read the comments in `AppState.updateScheduler()` carefully — it's been fixed at least twice.

---

## Things that look wrong but aren't

- **Dark appearance forced on the breathing panel** — intentional, so the ultra-thin material and petal colors look right on both light and dark system themes.
- **Animation values in `StatusItemController`** (damping, burst timing, hue step of 137°) — hand-tuned over iterations. Don't "fix" them without visual testing.
- **The :55–:59 window is fixed** — not a bug, not a missing settings option. It's a deliberate design constraint.
- **`LSUIElement = YES`** — the app has no Dock icon by design. Don't add a `WindowGroup` scene.

---

## Release

Automated via `.github/workflows/release.yml` on GitHub Release publish. Requires these repository secrets:

| Secret | Value |
|--------|-------|
| `CERTIFICATES_P12` | Base64-encoded Developer ID Application cert + key |
| `CERTIFICATES_P12_PASSWORD` | P12 export password |
| `NOTARIZATION_USERNAME` | Apple ID email |
| `NOTARIZATION_PASSWORD` | App-specific password |
| `NOTARIZATION_TEAM_ID` | `M4Q2TE45WT` |

To cut a release: bump `MARKETING_VERSION` in `project.pbxproj`, commit, push, create a GitHub Release with a `v`-prefixed tag. The workflow handles signing, notarization, stapling, and attaching the ZIP.

---

## Useful to know

- **DEBUG test helper** — there's a hidden "Test breathing time" menu item in debug builds to toggle state without waiting an hour.
- **No external dependencies** — keep it that way.
- **Settings** stored as a single JSON blob under key `"breathingSettings"` in `UserDefaults.standard`.
- **`@Observable`** (Swift 6 macro), not `ObservableObject`/`@Published`. Don't mix them.
