"""Xiao Lan the herb-picker (towns): a girl from the hills with a basket of herbs on her arm and a green headscarf.
Run: blender --background --python art/characters/herb_lan.py  ->  assets/characters/herb_lan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/herb_lan.glb", {
    "fem": True, "age": 0.1, "eye_size": 1.3, "build": 0.94,
    "robe": "6a9a5a", "trim": "f0f0e0", "inner": "fafaf0", "sash": "c8a050", "hair": "2a1a14", "hair_style": "braid",
    "eyes": "3a4a2a", "props": [("basket", {"fill": "5a9a3a"})], "pose": "hold_l", "pin": "e0c050",
})
