"""Little Hua of Qingshi Village (towns): a small girl with a red ribbon who follows the hero about asking about sword fights.
Run: blender --background --python art/characters/child_hua.py  ->  assets/characters/child_hua.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/child_hua.glb", {
    "fem": True, "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.72, "head_scale": 1.18, "jaw": 0.85,
    "robe": "e0705a", "trim": "fff0e0", "inner": "fff8f0", "sash": "f0c050", "hair": "201814", "hair_style": "twin_buns",
    "eyes": "4a2a1a", "ribbon": "e83a3a", "robe_len": "short", "pants": "e8b060",
})
