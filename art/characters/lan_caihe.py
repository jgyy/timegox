"""Lan Caihe, Who Sings in the Street (Part XII): the strangest of the immortals, who sings in the market with one shoe off and gives every coin away; a blue robe, a flower basket and a happy face of nobody can say what age.
Run: blender --background --python art/characters/lan_caihe.py  ->  assets/characters/lan_caihe.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lan_caihe.glb", {
    "fem": True, "age": 0.15, "eye_size": 1.3, "jaw": 0.88, "smile": True, "ahoge": True, "build": 0.92,
    "props": [("basket", {"col": "b89a60", "fill": "ff9ac0"})], "pose": "hold_l", "robe_len": "short",
    "robe": "4a9ad0", "trim": "fff0c0", "inner": "f8f8ff", "sash": "e8a030", "hair": "1a1418", "hair_style": "twin_buns", "eyes": "2a3a5a", "pants": "3a5a8a"
})
