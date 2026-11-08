"""Steersman Hong of the Lost Fleet (Part XII): the ghost of Xu Fu's steersman, still at the wheel of a ship two thousand years aground; a pale, grey-bearded sailor of Qin with glowing eyes in a faded blue jacket.
Run: blender --background --python art/characters/steersman_hong.py  ->  assets/characters/steersman_hong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/steersman_hong.glb", {
    "age": 0.8, "build": 1.0, "brow": 1.2, "beard": True, "beard_col": "b8c0c8", "beard_len": 0.7, "skin": "c8d4dc", "glow_eyes": True,
    "props": [("oar", {"col": "6a6a70"})], "pose": "hold_r", "robe_len": "short", "hat": "hood", "hat_col": "3a4a5a",
    "robe": "4a5a6a", "trim": "a8b0b8", "inner": "d8dce0", "sash": "2a3038", "hair": "b8c0c8", "hair_style": "topknot", "eyes": "a8e0ff", "pants": "3a4048"
})
