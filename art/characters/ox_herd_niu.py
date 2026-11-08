"""Ah Niu the Ox-Herd (towns): Qingshi's cowherd boy, barefoot in a short brown jacket, playing a bamboo flute.
Run: blender --background --python art/characters/ox_herd_niu.py  ->  assets/characters/ox_herd_niu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ox_herd_niu.glb", {
    "age": 0.0, "build": 0.82, "eye_size": 1.4, "scale": 0.74, "head_scale": 1.16, "jaw": 0.86,
    "props": [("flute", {"col": "c8b060"})], "pose": "flute", "robe_len": "short", "hat": "straw", "hat_col": "c8a868",
    "robe": "8a6a3a", "trim": "e8d8b8", "inner": "f2ead8", "sash": "5a8a4a", "hair": "1a1410", "hair_style": "short", "eyes": "2a1a10", "pants": "6a5a3a"
})
