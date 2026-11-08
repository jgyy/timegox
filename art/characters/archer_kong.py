"""Archery-Master Kong (towns): master of the archers' hall at Yanggu where Hou Yi practised; leather bracers, a quiver strap and the stance of somebody who has looked down an arrow for forty years.
Run: blender --background --python art/characters/archer_kong.py  ->  assets/characters/archer_kong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/archer_kong.glb", {
    "age": 0.6, "build": 1.08, "brow": 1.25, "jaw": 1.05, "stern": True, "beard": True, "beard_col": "3a3028", "beard_len": 0.6,
    "bracers": "5a3a20", "strap": "5a3a20", "robe_len": "short",
    "robe": "6a5a3a", "trim": "d8c890", "inner": "eee6d4", "sash": "8a2a1a", "hair": "3a3028", "hair_style": "topknot", "eyes": "2a2018", "pants": "4a3a2a", "boots": "3a2a1a"
})
