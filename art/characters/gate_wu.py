"""Gate Disciple Wu (towns): the sect's gate warden in lamellar armour over a dark robe, a halberd planted beside him.
Run: blender --background --python art/characters/gate_wu.py  ->  assets/characters/gate_wu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gate_wu.glb", {
    "age": 0.3, "build": 1.2, "stern": True, "brow": 1.2, "beard": True, "beard_len": 0.35, "beard_col": "1a1418",
    "robe": "2a3a4a", "trim": "c8b070", "inner": "e8e4d8", "sash": "8a2a24", "hair": "1a1418", "hair_style": "topknot",
    "eyes": "2a2018", "armor": True, "metal": "7a7468", "halberd": True,
})
