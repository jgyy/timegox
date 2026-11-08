"""Furnace-Boy Dan (Part XII): an alchemist's apprentice who has been a boy for two thousand years, sooty, in a short orange jacket and an apron, a little bowl of cooling pills in his hands.
Run: blender --background --python art/characters/furnace_boy.py  ->  assets/characters/furnace_boy.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/furnace_boy.glb", {
    "age": 0.0, "build": 0.82, "eye_size": 1.4, "scale": 0.74, "head_scale": 1.18, "jaw": 0.86,
    "props": [("apron", {"col": "6a4a30", "strap": "3a2818"}), ("bowl", {"col": "8a6a4a", "soup": "e8a030"})], "pose": "hold_both", "robe_len": "short",
    "robe": "c87a3a", "trim": "f0e0c0", "inner": "f6eee0", "sash": "3a2a1a", "hair": "1a1410", "hair_style": "twin_buns", "eyes": "2a1a10", "pants": "5a4a3a"
})
