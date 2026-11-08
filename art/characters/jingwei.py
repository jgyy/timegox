"""Jingwei, the Flame Emperor's Daughter (Part XII): the girl who drowned in the Eastern Sea and came back as a bird to fill it with stones; speckled wings, a white crest, red feet, a white robe with red trim and a pebble in her hand.
Run: blender --background --python art/characters/jingwei.py  ->  assets/characters/jingwei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/jingwei.glb", {
    "fem": True, "age": 0.0, "eye_size": 1.4, "jaw": 0.84, "build": 0.88, "hair_len": 0.55,
    "wings": "6a5a52", "wing_tip": "f2ece4", "wing_bar": "2a2424", "crest": "f6f2ec", "crest_tip": "e05a3a", "crest_len": 0.18,
    "props": [("pearl", {"col": "c8b8a8"})], "pose": "hold_l", "robe_len": "short", "boots": "d83a2a",
    "robe": "f2ece4", "trim": "d83a2a", "inner": "ffffff", "sash": "d83a2a", "hair": "2a2220", "hair_style": "short", "eyes": "2a2018", "monotone": True
})
