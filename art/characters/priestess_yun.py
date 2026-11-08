"""Wayfarer-Priestess Yun, keeper of Cloudfoot's shrine to Xiu, god of roads: a travelling priestess in white with a horsetail whisk and a lacquered pin.
Run: blender --background --python art/characters/priestess_yun.py  ->  assets/characters/priestess_yun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/priestess_yun.glb", {
    "fem": True, "age": 0.4, "build": 0.92, "eye_size": 1.15,
    "robe": "e8e4d8", "trim": "8a6a3a", "inner": "f8f6f0", "sash": "6a8a5a", "hair": "1a1418", "hair_style": "bun", "pin": "c8a040",
    "eyes": "3a3a3a", "props": ["fly_whisk"], "pose": "hold_r", "beads": "8a5a3a",
})
