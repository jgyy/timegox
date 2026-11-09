"""A farmer's wife of the towns (scripts/folk.gd): hair in a bun, an apron over a short robe and sandals; she feeds the hens, washes at the river and sells greens at the market.
Run: blender --background --python art/characters/folk_farmwife.py  ->  assets/characters/folk_farmwife.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_farmwife.glb", {"fem": True, "age": 0.38, "build": 1.0, "cheek": 1.15, "smile": True, "robe": "8a5a4a", "trim": "eadcc4", "inner": "f2ead8", "sash": "5a6a3a", "hair": "1e1814", "hair_style": "bun", "pin": "b08a40", "eyes": "3a2a1a", "props": [("apron", {"col": "d8ccb0", "strap": "7a6048"})], "robe_len": "short", "shoes": "sandals"})
