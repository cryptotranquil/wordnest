#!/usr/bin/env python3
"""Regenerate Android launcher icons from the approved WordNest emblem.

Requires Pillow: python3 -m pip install Pillow
Run from the repository root: python3 tools/create_android_launcher_icons.py
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / 'design/brand/wordnest_brand_identity_emblem/screen.png'
res = root / 'android/app/src/main/res'
emblem = Image.open(source).convert('RGBA')

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                      ('xxhdpi', 144), ('xxxhdpi', 192)]:
    emblem.resize((size, size), Image.Resampling.LANCZOS).save(
        res / f'mipmap-{density}' / 'ic_launcher.png')

# The center 72dp of an adaptive icon is the safe zone on all launchers.
# Place the full approved design there, retaining its logo and wordmark.
foreground = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
foreground.alpha_composite(emblem.resize((288, 288), Image.Resampling.LANCZOS), (72, 72))
foreground.save(res / 'drawable-nodpi' / 'ic_launcher_foreground.png')
