"""Courier Ma of the Nine Roads (towns): a lean post-rider in a short green jacket, boots and a straw hat, a gourd of water and a satchel strap.
Run: blender --background --python art/characters/courier_ma.py  ->  assets/characters/courier_ma.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/courier_ma.glb", {
    "age": 0.3, "build": 0.98, "jaw": 1.0,
    "props": [("gourd", {"col": "c89040", "cord": "3a6a4a"})], "hat": "straw", "hat_col": "c8a868", "robe_len": "short", "strap": "6a4a2a",
    "robe": "3a6a4a", "trim": "e8e0c8", "inner": "f0ece0", "sash": "8a4a2a", "hair": "1a1410", "hair_style": "topknot", "eyes": "2a1a10", "pants": "4a3a2a", "boots": "3a2a1a"
})
