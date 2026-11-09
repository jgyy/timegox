"""A porter of the towns (scripts/folk.gd): a broad-shouldered young man in a short robe and leg wraps who carries the towns' loads on a shoulder pole all day long.
Run: blender --background --python art/characters/folk_porter.py  ->  assets/characters/folk_porter.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_porter.glb", {"age": 0.3, "build": 1.35, "jaw": 1.15, "brow": 1.1, "robe": "8a7a5a", "trim": "ded2b6", "inner": "e8dcc4", "sash": "3a2e22", "hair": "16120e", "hair_style": "short", "eyes": "2e2014", "robe_len": "short", "wraps": "b0a080", "shoes": "sandals"})
