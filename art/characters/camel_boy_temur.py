"""Camel-Boy Temur of Shazhou: a quick nomad boy in a fur hat with a camel whip, who knows every camel in the yard by name and temper.
Run: blender --background --python art/characters/camel_boy_temur.py  ->  assets/characters/camel_boy_temur.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/camel_boy_temur.glb", {
    "age": 0.0, "build": 0.82, "eye_size": 1.4, "scale": 0.72, "head_scale": 1.18, "jaw": 0.85,
    "robe": "8a6a4a", "trim": "e8c890", "inner": "f0e0c0", "sash": "6a2a2a", "hair": "1a1410", "hair_style": "wild",
    "eyes": "3a2414", "hat": "fur", "hat_col": "8a6a40", "props": ["whip"], "pose": "hold_r", "robe_len": "short", "pants": "4a3a2a", "boots": "4a3020",
})
