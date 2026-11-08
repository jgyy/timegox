"""Little Qi of Tushan: a casters' child named after the boy born from the Stone Mother, with a toy hammer and soot on his nose.
Run: blender --background --python art/characters/little_qi.py  ->  assets/characters/little_qi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/little_qi.glb", {
    "age": 0.0, "build": 0.82, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85,
    "robe": "c8803a", "trim": "fff0d8", "inner": "fff8ec", "sash": "6a3a2a", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "3a2414", "props": [("hammer", {"head": "8a6a3a"})], "pose": "hold_r", "robe_len": "short", "pants": "6a3a2a",
})
