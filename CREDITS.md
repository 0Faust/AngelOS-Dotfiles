# Credits — 0Faust/AngelOS-Dotfiles

This fork is built on other people's work. Thank you.

## angelOS itself

- **MixaDoDs/AngelOS-Dotfiles** — the original angelOS shell, configs and
  installer: https://github.com/MixaDoDs/AngelOS-Dotfiles (MIT).
  This fork starts from upstream `89feddf` and adds personal patches on top.

## Features taken from Frostpix11/pc-kit-share

The following was taken, with thanks, from **Frostpix11**'s personal
angelOS kit: https://github.com/Frostpix11/pc-kit-share

The kit's author shares it openly and advises taking the individual
pieces you want ("Бери отдельные фишки, которые нравятся"). No license
file is published in that repository; everything below is used with
attribution and gratitude.

Taken as-is or adapted (2026-11-14):

- **Shell patches** (`files/patches/`): cursor-motion, dock-spacing,
  mac-cursor, mac-settings-lights, mac-tint, pixora-mac, skin-morph,
  stack-memory (window memory for Strip ↔ Desktop), privacy-capture
  (privacy while recording), game-detect, angel-game-quiet,
  halo-game-sleep, halo-game-notify, tray-menu-fresh, scene-handover.
  `codex-fixes`, `tray-pin` and `author-picks` were skipped by the kit
  itself — this base (`89feddf`) already has them.
- **Plugins** (`files/plugins/`): angelos-night-2004 (the Save point
  night), privacy-eye, mac-eq, celestia.
- **Codex plugins** (`files/codex-plugins/`): AngelOS Typer, AngelOS Room.
- **serp skin** (`files/serp-skin/`): the Serpantinum look over angelOS —
  islands, liquid glass, panels, its own widget faces. One hunk
  (`hunks/halo_pill.py`, the Halo's `pillY`) was adapted to the newer
  upstream shell, which added the `bar` skin.
- **Wallpapers** (`files/wallpapers/`): «Тихая гавань» (a layered
  day / dusk / night / dawn scene), linked into `~/Pictures/Celestia`.
- **The `kit` tool and its update watcher** (`kit/kit.py`,
  `kit-update.path`) — kept in `~/pc-kit` and used as-is.

Local copy of the kit: `~/pc-kit` (from
https://github.com/Frostpix11/pc-kit-share).

### serp skin / Serpantinum license note

The serp skin is partly based on **Serpantinum** by **ilyamiro**
(https://github.com/ilyamiro/serpantinum), licensed **AGPL-3.0** — the
liquid-glass shader and palettes come from there. If the serp skin is
redistributed, that license and attribution must be preserved.

## Personal patches on top of upstream

Added by this fork (not from pc-kit):

- lazy rare windows (LazyLoader for 7 modules, issue #168)
- SysmonWidget `/proc` polling 2s → 5s (issue #168)
- obs-watch only while a stream feature wants it (issue #168)
- angel-niri pin updated to `angelos-7b10b2c7` (live cursor / camera
  behind cursor, issue #166)
- sysmon dual-GPU monitoring (design: `docs/superpowers/specs/`)
