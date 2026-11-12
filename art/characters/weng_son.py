"""Weng the Younger (Part XXIV): the old man's son, who rode the horse that came back, broke his thigh, and was not taken when the
riders came for every sound man on the frontier: a youth of nineteen in a blue-grey riding coat with a red sash, his hair tied back.
Run: blender --background --python art/characters/weng_son.py  ->  assets/characters/weng_son.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/weng_son.glb", {"fem": False, "age": 0.12, "build": 1.0, "jaw": 1.0, "smile": True, "skin": "d8b898", "eye_size": 1.05,
    "robe": "6a7a8a", "trim": "3a4450", "inner": "e0d8c8", "sash": "b03a2a", "pants": "3a3a40", "boots": "2a2220", "hair": "1c1814", "hair_style": "tail", "eyes": "4a3a2a",
    "ribbon": "b03a2a", "sleeve_w": 0.9})
