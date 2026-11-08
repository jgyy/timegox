"""Little Yu of Longmen, who feeds the carp: a small boy named after Yu the Great, with a bowl of rice for the carp that are going to be dragons.
Run: blender --background --python art/characters/carp_boy_yu.py  ->  assets/characters/carp_boy_yu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/carp_boy_yu.glb", {
    "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85,
    "robe": "e0a040", "trim": "fff0d8", "inner": "fff8ec", "sash": "2a6a8a", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "3a2414", "props": [("bowl", {"col": "f0f0e8", "soup": "f8f4e8"})], "pose": "hold_both", "robe_len": "short", "pants": "2a6a8a",
})
