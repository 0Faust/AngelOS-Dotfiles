# Relic / Sanctum — «Реликвия»

An optional pixel desktop skin with a 16-bit sacred/infernal gothic palette:
wrought iron, aged parchment, cinnabar and muted gilding. No new animation
loop, image shader, cursor, desktop widget or auto-hide rule.

## Optional cathedral wallpaper (reference-inspired)

`assets/relic/sanctum-cathedral.png` is a standalone 1672 × 941 pixel-art
cathedral wallpaper inspired by the supplied visual reference. It contains
**no UI**: the settings window, Halo, taskbar and desktop widgets are all
real QML components painted over it. Pick the PNG through **Settings →
Wallpaper** (or copy it to your normal wallpaper gallery). Changing the skin
does **not** silently replace a chosen wallpaper or disturb live-wallpaper
settings. This deliberately differs from an all-in-one concept image.

## Enable / disable

- **Settings → Appearance → Desktop skin → Реликвия** (the swatch shows a
  blackened reliquary with a gilded frame and carmine seal), or
- `angelos settingsSkin relic` via the existing shell IPC.
- `angelos settingsSkin classic`, `... win10`, `... windose`, `... stream`, or
  `... goldengate` returns to the selected desktop look immediately.

The icon set is forced to the built-in `angelos` pixel glyphs **only while
Relic is active**. `appearance.iconStyle` remains untouched; your former icon
set reappears automatically after switching away. Appearance's existing
dark/light/automatic mode picks Catacombs or Manuscript. The demon's separate
`Theme.realm = "hell"` still uses the original HellLook colours.

## Reference-facing components (second pass)

The user-provided image **Реликвия Sanctum_ интерфейс AngelOS(1).png** is a
1672 × 941 concept; the artwork is **not** used as a fake desktop screenshot.
The implemented pieces are independent, interactive Qt Quick components:

- `widgets/RelicHaloSeal.qml`: 70 × 70 art-pixel double ring, twelve golden
  rays and a cross over Halo's own event/clock/weather content. The original
  Halo timers, gestures, media and notifications remain intact.
- `widgets/RelicCross.qml`: reusable multi-tone pixel crucifix with hard
  outlines (launcher, settings heading and Halo).
- `assets/relic/relic-cathedral.svg`: original pixel-coordinate gothic
  cathedral thumbnail, separate from the 1672 × 941 wallpaper.
- `widgets/RelicSkinShowcase.qml`: live four-tile reference picker with an
  illustrated Relic preview, both palette buttons and a wallpaper shortcut.
  The six-skin native picker is still below it; choosing another skin hides
  the Relic-specific controls without modifying their preferences.
- `modules/settings/views/Win11View.qml`: crimson section selection,
  double gold sidebar seam and cross heading; all sidebar navigation,
  account, Ctrl+F search and new-window actions remain available.
- `modules/bar/parts/StartButton.qml`: accessible crimson/gilt Start button
  backed by the original `Shell.toggleStart` action; no screen-space overlay.
- `modules/bar/TaskbarWindow.qml`: double gold bar threads on all four
  possible edges, without changing screen reservations or auto-hide geometry.
- Existing wallpaper and live-wallpaper rendering are unchanged. The optional
  cathedral artwork is a separate image; selecting Relic never selects or
  overlays it on the desktop.

The system/music/weather **examples and numbers in the concept are illustrative**:
the real widgets and Halo continue to show live data from AngelOS. Widget
placement and visibility are user-configurable; selecting Relic does not
overwrite an existing layout to force screenshot-like coordinates.

## Pixel architecture and accessibility

- `Theme.u` defines the stepped cuts, three-layer frame, cross rivets, button
  displacement, gilt title rule, progress panes and taskbar rim.
- Deep mode: `#0e090d` backdrop, `#1e151d` iron, `#efe4d4` bone,
  `#c93848` carmine, `#cfa04a` gilding.
- Light mode: `#efe5d2` parchment, `#211514` ink, `#a62334` vermilion,
  `#9c6c1e` aged gold (decorative, not small label text).
- Label roles and CTA foregrounds are measured by `tests/relic-contrast.py`
  against WCAG's 4.5:1 text ratio.
- Existing `PxText` / `PxField` NativeRendering paths and the icon's
  `smooth: false` are retained; zoomed / Mac exceptions stay unchanged.

## Verify

From the checkout root:

```sh
python3 .config/quickshell/angelos/tests/relic-contrast.py
python3 .config/quickshell/angelos/tests/relic-contract.py
.config/quickshell/angelos/scripts/static-checks.sh "$PWD/.config/quickshell/angelos"
bash scripts/check.sh
.config/quickshell/angelos/scripts/qml-check.sh "$PWD/.config/quickshell/angelos"
```

The QML check needs the real Qt 6 Quickshell runtime **and a running Wayland
socket**. Where those are missing the upstream checker exits `2` (not a QML
compilation result). Run it on the target CachyOS/niri session before merging.

No changes are made to the 10 desktop widgets, live wallpapers, Pixel-Amethyst
cursor, serp text sharpness, or taskbar auto-hide logic.
