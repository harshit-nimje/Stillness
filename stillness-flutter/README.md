# Stillness — Flutter (Android)

A faithful native port of the Stillness single-file web app (the attached
`Momentum.html`). Same product, same UI language, same features, same
interactions — reimplemented in Flutter/Dart instead of the browser.

> This is a **migration, not a redesign**. Where the browser had a concept with
> no direct native equivalent, the closest native equivalent was built (noted
> below) — no feature was silently dropped.

---

## Build

The project is delivered as Flutter **source** (`lib/`, `pubspec.yaml`,
`assets/`, and an Android manifest). Generate the platform scaffolding, drop
these files in, and build:

```bash
# 1. Scaffold the Android platform folder (creates android/, gradle wrapper, etc.)
flutter create --platforms=android --org com.stillness --project-name stillness .

# 2. Overwrite the generated manifest with the provided one
cp <this-repo>/android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

# 3. In android/app/build.gradle(.kts) set the SDK levels the audio engine needs
#    minSdkVersion = 23   (flutter_soloud + just_audio)
#    compileSdkVersion = 34
#    ndkVersion = flutter.ndkVersion

# 4. Fetch packages and run
flutter pub get
flutter run            # debug on a device
flutter build apk --release
```

The output APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

### Bundled fonts
`Hanken Grotesk` and `Newsreader` are bundled as variable TTFs under
`assets/fonts/` (weight and optical-size axes applied via `FontVariation`).
The APK does **not** load Google Fonts at runtime.

---

## Architecture

```
lib/
  main.dart                     edge-to-edge setup, load data, run
  app/stillness_app.dart        root shell, providers, lifecycle, overlay stack
  core/     tokens.dart         design tokens (the CSS :root, translated)
            type.dart           typography (serif/sans, clamp() roles)
  models/   stillness_data.dart StillnessData + clean()/migrate/validate
  data/     stillness_store.dart persistence (stillness.v2 in SharedPreferences)
  state/    app_state.dart      tasks, habits, momentum, day ritual, settings, backup, toasts
            focus.dart          focus session (timestamp-based)
            breathe.dart        breathing patterns + phase text
            audio.dart          generated soundscape + library, shared volume/sleep/tint
            onboarding.dart     onboarding answers/flow
  sky/      sky.dart            clock→colour math, controller, particle pools
            sky_painter.dart    Canvas renderer (gradient, hills, sun/moon, rain, art, breath)
            sky_view.dart       Ticker + CustomPaint host
  audio/    generated_scenes.dart  SC/LAY/G/CH tables, library track list
            sound_engine.dart      SoLoud-backed procedural synthesis
  widgets/  glass, dock, logo, toast, sheet, controls, icons, task_row
  sheets/   sound, life, settings, day
  screens/  home, focus_stage, breathe_overlay, onboarding
  theme/    theme_scope.dart    InheritedNotifier over the sky palette
```

**State management:** `provider` + `ChangeNotifier` — lightweight, enough for
the app's complexity, no framework for its own sake.

**Persistence:** the exact versioned-JSON-document model from the web app,
stored under `stillness.v2` (with a `stillness.v1` migration read). All data
passes through `StillnessData.clean()` — malformed storage or a bad import can
never crash the app. Backups are byte-compatible with the web app's JSON.

**Sky rendering:** a single `CustomPainter` repaints via the controller's
`Listenable`; the widget tree is never rebuilt per frame. The app-wide palette
(a glass/theming surface) is updated on a ~500ms throttle — matching the
original's `paintBg` cadence.

---

## Feature parity

| Area | Status |
|---|---|
| Tasks (add/complete/edit/delete/pin/tag/due/recur/carry-over/history/limits) | ✅ |
| `#tag`, `@6pm`, `*daily` parsing + live hint | ✅ |
| Focus sessions (focus/rest/long-rest, auto-next, timestamp timer, ring, sky sun-crossing) | ✅ |
| Breathing (Box 4-4-4-4, 4-7-8, Even 5-5) with canvas circle | ✅ |
| Generated soundscapes (Dawn/Rain/Sea/Woods/Hearth/Deep) + custom mix | ✅ native synthesis |
| Music library (41 curated tracks, categories, seek, prev/next, volume, fade timer, licence links) | ✅ |
| Dynamic sky (clock colours, sun/moon, stars, rain, waves, mist, embers/fireflies, scene art, tints) | ✅ |
| Momentum (habits build/quit, score, 14-day chart, time bank, spend) | ✅ |
| Settings (focus/rest/long-rest, auto, name, appearance, stats) | ✅ |
| Backup / restore | ✅ (clipboard + paste, as on web) |
| Morning ritual (day sheet, "let go" carry-over) | ✅ |
| Onboarding (9 pages, skip/back/replay, illustrations) | ✅ |
| Theme (auto/light/dark, dynamic palette from sky + scene tint) | ✅ |
| Toast / notifications, haptics, wake lock, edge-to-edge, back handling | ✅ |

---

## Known limitations (browser API → native)

1. **Web Audio → flutter_soloud.** There is no Web Audio API on Android, so the
   soundscape is synthesised with SoLoud: the same white/pink/brown noise
   buffers (identical Paul-Kellet / leaky-integrator formulas), the same
   seven layer buses and gains, biquad (high/low/bandpass) filters, a reverb
   bus, and scheduled one-shots (bells, drops, chirps/crickets, crackles, pad
   chords) with baked envelopes, driven by the same 400ms scheduler. SoLoud has
   no sample-accurate scheduler or convolution convolver, so event timing is
   scheduled in Dart and reverb uses SoLoud's freeverb instead of a generated
   impulse response. All SoLoud calls live in `lib/audio/sound_engine.dart` —
   if your pinned `flutter_soloud` version names a method differently, that is
   the only file to adjust. The app never crashes if audio fails to start: the
   engine degrades to silent and the UI still works.
2. **Claude cloud sync.** The original synced via `window.claude`. That runtime
   is not present in a standalone APK; the app is local-first (which is the
   original's own fallback). The account section says so, and Backup is the way
   to move data between devices.
3. **File pickers.** Library "＋ Add files" and the onboarding/backup "Open
   file" affordances on the web used `<input type=file>`. The primary backup
   path (copy/paste JSON) is fully implemented; file import can be added with
   `file_selector` if you want it.
4. **SMIL illustrations.** The onboarding SVGs used `<animate>`/`<animateMotion>`
   (unsupported by flutter_svg); they are rebuilt as Flutter animations of the
   same artwork and motion.

---

## Notes for review

The original `Momentum.html` is left completely untouched and remains the
reference implementation. This project is the port; compare states side by side
using the reference captures described in the migration notes.
