#!/usr/bin/env python3
"""Static integrity checks for Relic assets and bindings (not a QML runtime test)."""
from pathlib import Path
import json
import struct
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]

def read(rel):
    return (root / rel).read_text(encoding="utf-8")

wall = (root / "assets/relic/sanctum-cathedral.png").read_bytes()
assert wall[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", wall[16:24]) == (1672, 941)

svg = ET.parse(root / "assets/relic/relic-cathedral.svg")
assert svg.getroot().attrib["viewBox"] == "0 0 160 112"
assert svg.getroot().attrib["shape-rendering"] == "crispEdges"

tree = json.loads(read("modules/settings/tree.json"))
assert '"appearance/relic-preview"' in json.dumps(tree)
assert 'name: "relic-preview"' in read("modules/settings/catalog/Appearance.qml")

showcase = read("widgets/RelicSkinShowcase.qml")
assert 'Config.settingsUi.skin = tile.modelData.id' in showcase
assert 'Config.appearance.mode = "dark"' in showcase
assert 'Config.appearance.mode = "light"' in showcase
assert 'Shell.settingsPage = "wallpaper"' in showcase
assert 'relic-cathedral.svg' in showcase
assert '14%' not in showcase and '38%' not in showcase

halo = read("modules/halo/HaloWindow.qml")
assert 'relicHero: Theme.relic' in halo
assert "RelicHaloSeal" in halo
assert "Timer" not in read("widgets/RelicHaloSeal.qml")
bar = read("modules/bar/parts/StartButton.qml")
assert "Shell.toggleStart(root.screenName)" in bar
assert "start-btn.png" in bar
assert "readonly property bool autoHide: Config.bar.autoHide" in read("modules/bar/TaskbarWindow.qml")

theme = read("config/Theme.qml")
assert 'readonly property bool relic: Config.relicSkin' in theme
assert 'readonly property bool relicDark: relic && night' in theme
print("Relic contract: assets, interactive picker, palettes and shell hooks passed")

# the resting Halo's reliquary plaque (a new component, wired to the rest state only)
plaque = read("widgets/RelicPlaque.qml")
assert "property int tip" in plaque and "Theme.relicGold" in plaque
assert "Timer" not in plaque and "MouseArea" not in plaque and "Canvas" not in plaque
assert "RelicPlaque" in halo
assert "readonly property bool relicPlaque: Theme.relic && rest && !expanded && !inBar && !earsRest" in halo

# the widgets' gilded window frame (decoration only, Relic only)
win_qml = read("widgets/PxWindow.qml")
assert "widgetFrame9Slice" in win_qml and "relicTrim" not in win_qml
assert "frame.inset + Theme.u * (root.gilded ? 4 : 1)" in win_qml
assert "root.relic && root.titleRow && !root.closable" in win_qml

assert "relicPlate: true" in read("modules/desktop/DesktopWidgetHost.qml")
assert "relicPlate" not in read("modules/settings/SettingsView.qml")
assert "relicPlate" not in read("modules/halo/HaloWindow.qml")

# the widgets' word titles in the Relic (plugins and other skins keep their own names)
widgets = read("services/DesktopWidgets.qml")
assert "relicTitles" in widgets
assert 'clock: I18n.t("Часы", "Clock")' in widgets
assert 'picture: I18n.t("Картина", "Picture")' in widgets
assert "return relicTitles[info.title]" in widgets
