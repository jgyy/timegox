"""Outer Disciple Xiao Qing (towns): a girl who climbed the mountain because of the stories about Lin Feng, in the sect's blue, with a broom of her own.
Run: blender --background --python art/characters/xiao_qing.py  ->  assets/characters/xiao_qing.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xiao_qing.glb", {
    "fem": True, "age": 0.05, "eye_size": 1.34, "jaw": 0.86, "build": 0.9, "smile": True,
    "props": [("broom", {"col": "a08a50", "twigs": "c8a868"})], "pose": "hold_r", "robe_len": "short",
    "robe": "7aa0d0", "trim": "f0f4ff", "inner": "f8faff", "sash": "2a3a6a", "hair": "141418", "hair_style": "twin_buns", "eyes": "2a2a3a", "pants": "4a5a7a"
})
