#!/usr/bin/env python3
"""Verify every small-text surface in Relic's two palettes is >= WCAG 4.5:1."""

import pathlib
import re

THEME = pathlib.Path(__file__).resolve().parents[1] / "config" / "Theme.qml"
source = THEME.read_text(encoding="utf-8")
fragment = source.split("function relicFor(isDark)", 1)[1].split(
    "readonly property var relicPalette", 1
)[0]
dark, light = fragment.split("}) : ({", 1)


def palette(part):
    return dict(re.findall(r'\b(\w+):\s*"(#[0-9a-fA-F]{6})"', part))


def luminance(hex_color):
    rgb = [int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return sum(c * w for c, w in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(a, b):
    high, low = sorted((luminance(a), luminance(b)), reverse=True)
    return (high + 0.05) / (low + 0.05)


checks = 0
for mode, data in (("Catacombs", palette(dark)), ("Manuscript", palette(light))):
    for fore in ("text", "textDim"):
        for back in ("face", "faceAlt", "sunken"):
            ratio = contrast(data[fore], data[back])
            assert ratio >= 4.5, f"{mode}: {fore}/{back} {ratio:.2f}:1"
            checks += 1
    ratio = contrast(data["selectText"], data["accent"])
    assert ratio >= 4.5, f"{mode}: selected text/accent {ratio:.2f}:1"
    checks += 1
    print(f"{mode}: text, dim text, selected CTA all >= 4.5:1")

print(f"Relic contrast: {checks} pairs passed")
