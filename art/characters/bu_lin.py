"""Bu Lin the Fruit-Trader (towns): one of the Deathless of the root-groves, dark-skinned and unhurried, with a basket of fruit that never spoils.
Run: blender --background --python art/characters/bu_lin.py  ->  assets/characters/bu_lin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bu_lin.glb", {
    "age": 0.4, "build": 1.02, "jaw": 1.0, "skin": "4e3628", "lip": "8a4a48",
    "props": [("basket", {"col": "b89a60", "fill": "d8a040"})], "pose": "hold_l", "robe_len": "short",
    "robe": "8a7a3a", "trim": "e8dcb0", "inner": "f0e8d0", "sash": "4a6a2a", "hair": "141010", "hair_style": "topknot", "eyes": "3a2a1a", "pants": "4a4030"
})
