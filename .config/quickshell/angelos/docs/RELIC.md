# Relic / Sanctum — «Реликвия»

An optional pixel desktop skin with a 16-bit sacred/infernal gothic palette:
wrought iron, aged parchment, cinnabar and muted gilding. No new animation
loop, image shader, wallpaper, cursor, desktop widget or auto-hide rule.

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
.config/quickshell/angelos/scripts/static-checks.sh "$PWD/.config/quickshell/angelos"
.config/quickshell/angelos/scripts/qml-check.sh "$PWD/.config/quickshell/angelos"
```

The last check needs the real Qt 6 Quickshell runtime **and a running Wayland
socket**. Where those are missing the upstream checker exits `2` (not a QML
compilation result). Run it on the target CachyOS/niri session before merging.

No changes are made to the 10 desktop widgets, live wallpapers, Pixel-Amethyst
cursor, serp text sharpness, or taskbar auto-hide logic.
