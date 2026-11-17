# Dead Cells as a desktop skin — design and plan

**Goal:** Dead Cells becomes one desktop skin, picked like Classic / Win10 / Golden Gate, instead of three separate switches (palette, pixel HUD, preset buttons).

**Approved design (2026-11-16):** one card in "Desktop skin"; the skin owns the pixel HUD and the pixel icons; the palette stays adjustable in "Color scheme" and the card sets "Cells" when clicked.

## Calls made while planning

- The skin is the only source of the forged HUD: `Theme.pixelForge` no longer looks at `appearance.pixelStyle` or the flavour. The `pixelStyle` config field and its UI row go away, as do the "Dead Cells pixel presets" buttons.
- Icons derive from the skin (`Theme.iconStyle`), so no config is written on switch and the IPC path behaves like the card. The icon-style picker hides while the skin is on, with a note.
- A card click also writes `appearance.flavor = "deadcells"` so one click gives the whole look; the palette combo stays live for anyone who wants Cells frames over another palette.
- One-time migration on load: `skin === "classic"` with a saved Dead Cells look (`flavor` starting `deadcells`) becomes `skin = "deadcells"`, so nothing changes on screen.
- No commits: the working tree stays uncommitted until asked.

## Files

| File | Change |
|---|---|
| `config/Theme.qml` | `deadCellsSkin`, `iconStyle`, `pixelForge` from the skin; drop `deadCellsFlavor` |
| `config/SettingsSchema.qml` | drop `appearance.pixelStyle`; note `deadcells` on `settingsUi.skin` |
| `config/Config.qml` | migration `classic + deadcells look → deadcells skin` |
| `widgets/PxIcon.qml` | default `iconStyle` from `Theme.iconStyle` |
| `widgets/IconStyleCards.qml` | highlight follows `Theme.iconStyle` |
| `widgets/SettingsSkinCard.qml` | names + mini-drawing for `deadcells` |
| `modules/settings/catalog/Appearance.qml` | card in the row (6), drop the pixel-style row and the presets, note, hide the icon picker under the skin |
| `modules/Ipc.qml` | `deadcells` in the `settingsSkin` list, and it sets the Cells palette |
| `services/SettingsSearch.qml` | search keywords for the skin |

## Tasks

### Task 1: Theme derives the look from the skin

- [ ] Add `deadCellsSkin` (`settingsUi.skin === "deadcells"`), `iconStyle`, and make `pixelForge` `!macLook && !hell && deadCellsSkin`; remove `deadCellsFlavor`.
- [ ] `PxIcon` default `iconStyle: Theme.iconStyle`; `IconStyleCards.chosen` compares with `Theme.iconStyle`.
- [ ] Check: `qml-check` 0 errors.

### Task 2: The card and the settings page

- [ ] `SettingsSkinCard`: names entry for `deadcells`; a drawing — dark plate, double warm rim, rivets, a segmented bottom strip — in the same idiom as the others.
- [ ] `Appearance`: add `deadcells` to the row, 6→3→2 columns, note text; remove the "Pixel frame style (HUD)" choice and the "Dead Cells pixel presets" block; card click writes the Cells palette.
- [ ] Icon section: note instead of the picker while the skin is on.
- [ ] Check: `qml-check` 0 errors.

### Task 3: Schema, migration, IPC

- [ ] Schema: drop `pixelStyle`, document `deadcells` on `skin`.
- [ ] `Config._migrate()`: saved Dead Cells look under `classic` becomes `deadcells` (and `skinChosen = true`).
- [ ] `Ipc.settingsSkin`: accept `deadcells`, set the Cells palette; `SettingsSearch` keywords.
- [ ] Check: `qml-check` 0 errors.

### Task 4: Live

- [ ] Copy the seven touched files into `~/.config/quickshell/angelos`, applying the kit patches that live already carries (`SettingsSkinCard` `GoldenGate.setSkin`, `Theme` mac-tint lines) by hand where they overlap.
- [ ] `qml-check` live: 0 errors; `angelos restart`; screenshot of the desk and of Settings → Appearance.
- [ ] Verify: card is chosen, frames and icons are Dead Cells, palette shows Cells, the old rows are gone, switching to Classic brings the Win98 look back.

## Review focus

- Switching away from Dead Cells must restore the classic HUD and icon set (nothing may stay pinned).
- Settings search must still find the skin by "Dead Cells" and "пиксель".
- A saved config from before the change must not flash a different look on start.
- Golden Gate / Win10 / Windose / Stream must stay untouched by the new skin value.
