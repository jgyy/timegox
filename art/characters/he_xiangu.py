"""He Xiangu of the Lotus (Part XII): the only woman among the Eight Immortals, fourteen for two thousand years, in pink and white with a lotus on a long stem.
Run: blender --background --python art/characters/he_xiangu.py  ->  assets/characters/he_xiangu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/he_xiangu.glb", {
    "fem": True, "age": 0.05, "eye_size": 1.36, "jaw": 0.84, "lip": "e08a9a", "hair_len": 0.75, "build": 0.92,
    "props": [("peach_branch", {"wood": "4a7a3a", "bloom": "ffb8d0", "fruit": "ffd0e0"})], "pose": "hold_l",
    "robe": "f0c8d8", "trim": "ffffff", "inner": "fff8fc", "sash": "6ab08a", "hair": "141018", "hair_style": "long", "eyes": "3a2a3a", "pin": "ffb8d0", "ribbon": "ff9ac0"
})
