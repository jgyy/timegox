"""Lantern-Maker Xi (towns): Yanggu's lantern-maker, a cheerful young man with paper and paint on his sleeves, holding up a red lantern.
Run: blender --background --python art/characters/lantern_xi.py  ->  assets/characters/lantern_xi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lantern_xi.glb", {
    "age": 0.2, "build": 0.96, "jaw": 0.94, "smile": True,
    "props": [("lantern", {"col": "e84a2a", "frame": "5a3a20", "glow": "ffc070"})], "pose": "hold_l", "robe_len": "short",
    "robe": "d84a2a", "trim": "f0d070", "inner": "fff2e0", "sash": "3a2a1a", "hair": "1a1410", "hair_style": "topknot", "eyes": "2a1a10", "pants": "6a3a2a"
})
