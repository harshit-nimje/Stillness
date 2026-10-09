# Migration inventory — `Momentum.html` → Flutter

Phase 1 reverse-engineering notes for the Stillness port. The HTML is the source
of truth and was left untouched.

## Screens / states

| # | State | Web trigger | Flutter |
|---|---|---|---|
| 1 | Home / task view | `.home` | `screens/home_screen.dart` `_HomeBody` |
| 2 | Focus session | `.focusing` + `#stage` | `screens/focus_stage.dart` |
| 3 | Breathing | `.br` + `#bw` | `screens/breathe_overlay.dart` |
| 4 | Soundscape sheet | `#dSound` (Generated tab) | `sheets/sound_sheet.dart` `_generated` |
| 5 | Sound library | `#dSound` (Library tab) | `sheets/sound_sheet.dart` `_library` |
| 6 | Momentum / Life | `#dLife` | `sheets/life_sheet.dart` |
| 7 | Settings | `#dMore` | `sheets/settings_sheet.dart` |
| 8 | Morning ritual | `#dDay` | `sheets/day_sheet.dart` |
| 9 | Onboarding (9 pages / 4 replay) | `#ob` | `screens/onboarding.dart` |
| 10 | Toast | `#say` popover | `widgets/toast.dart` |
| 11 | Empty list | `#empty` | inline in `home_screen` |
| 12 | Completed tasks | `#done` details | inline "Done today, N" |
| 13 | Backup / restore | Settings `<details>` | `settings_sheet` + `AppState.restore` |
| 14 | Boot animations | `.boot` classes | rise/fade `TweenAnimationBuilder` |

## Data model (persisted, versioned, validated)

Key `stillness.v2`, migrated from `stillness.v1`. One JSON document; every field
clamped/validated by `clean()` in `models/stillness_data.dart`:

| Field | Type | Notes |
|---|---|---|
| `v` | int | schema version (2) |
| `name` | string ≤40 | |
| `last` | yyyy-mm-dd | last ritual day |
| `theme` | `auto\|light\|dark` | |
| `cfg.{f,b,l}` | num | focus 5–60, rest 1–30, long-rest 10–45 |
| `cfg.auto` | bool | auto-start next session |
| `tasks[]` | ≤500 | `id,t,done,tag,due(^\d\d:\d\d$),rec(d\|w),on,sp,rd` |
| `log[]` | ≤3000 | `[date, minutes 1–180]` |
| `joy[]` | ≤200 | `{d,t}` |
| `h[]` | ≤30 | `{id,n,k(g\|b),w(1..3)}` |
| `hd{}` | ≤120 keys | date → habit ids |
| `bank` | num 0–1e6 | time bank minutes |
| `u` | int | updated-at (last-writer-wins) |
| `ob` | bool | onboarding complete |

Backups are byte-compatible with the web app's JSON.

## Functionality inventory

**Tasks:** add (500 cap), complete (+5 bank, spawn recurrence, chime/flash/ring,
praise toast), uncomplete (−5 bank, un-spawn), edit inline, delete with Undo,
pin to top, tag-scope filter, expand/collapse, Alt+↑/↓ reorder, parse
`#tag @6pm *daily`, live hint, due reminders (60-min window, once/day), carried
over / hidden-until-date, done-today history, empty state.

**Focus:** focus/rest/long-rest phases, timestamp timer (background-safe),
auto-next, ring progress (dasharray 289), sun crossing the sky during a session,
phase chime/haptic/flash, +round(focus/2) bank per session, `log` append, title
countdown, Done completes the bound task.

**Breathe:** Box 4-4-4-4, 4-7-8, Even 5-5; canvas circle scale per phase;
phase label + countdown; exit.

**Sound (generated):** 6 scenes (Dawn/Rain/Sea/Woods/Hearth/Deep); 7 layer buses
(Pads/Bells/Rain/Sea/Wind/Wildlife/Hearth); noise beds, biquad filters, reverb,
scheduled bells/drops/chirps/crickets/crackles/pad chords; custom mix sliders;
volume; fade-out timer; scene tints the sky and redraws the logo.

**Library:** 41 curated tracks with categories, title, artist, source, licence;
category filter, list with playing equaliser, now-playing + licence link, seek,
prev/play/next, shuffle-free step, error → next track, loop flags, sleep fade.

**Sky:** clock keyframes, smoothstep interpolation, dark/light + tint mixing,
cached gradient + 5 hills, sun/moon path + halo + flash, stars, rain streaks,
mist, embers/fireflies, waves, 6 scene-art overlays, breathing circle.

**Momentum:** 14-day decaying score (log ×0.2 + habit weights), delta vs
yesterday, bar chart, time bank, Spend 15, build/quit habit lists, add/remove.

**Other:** theme auto/light/dark, name, stats, backup/restore, morning ritual,
onboarding + replay, wake lock, haptics, edge-to-edge, back handling.

## External resources

- **Fonts:** Hanken Grotesk (300–600) + Newsreader (300/400, italic) — bundled
  locally as variable TTFs.
- **Audio URLs:** the 41 library tracks (archive.org / Wikimedia Commons),
  preserved verbatim with licences.
- **Links:** track source/licence pages (opened via `url_launcher`).
- **SVG:** inline icons + logo marks + onboarding illustrations, preserved as
  vector artwork (flutter_svg) or rebuilt as Flutter animations where the SVG
  used SMIL.
- **Browser APIs → native:** `localStorage`→SharedPreferences; Canvas→CustomPainter;
  Web Audio→SoLoud; `navigator.wakeLock`→wakelock_plus;
  `navigator.vibrate`→HapticFeedback; `<dialog>`→modal sheet route;
  popover toast→overlay; view transitions→Flutter transitions.

## Migration risks / decisions

1. **Web Audio has no native equivalent** → SoLoud procedural engine (documented
   in README; all calls isolated in `sound_engine.dart`).
2. **`window.claude` cloud sync** doesn't exist in an APK → local-first (the
   web app's own fallback); Backup moves data.
3. **SMIL** unsupported by flutter_svg → Flutter animation of the same artwork.
4. **File inputs** → copy/paste JSON (primary path); file import optional.
5. **Material 3 avoided** — `uses-material-design: false`; no MaterialIcons
   font is bundled, so Material widgets relying on it were replaced (chevrons,
   `<select>` cycles); typography, colours and radii come from the CSS tokens.
