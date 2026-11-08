"""Little Dou of the Dawn Market (Part IX): a small boy with a topknot and a hand drum who means to shoot the sun, just a little, so it goes to bed.
Run: blender --background --python art/characters/little_dou.py  ->  assets/characters/little_dou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/little_dou.glb", {
    "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85,
    "robe": "e0a040", "trim": "fff0d8", "inner": "fff8ec", "sash": "c8402a", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "3a2414", "props": ["drum"], "pose": "hold_l", "robe_len": "short", "pants": "c8402a",
})
