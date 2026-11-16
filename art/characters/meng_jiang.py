"""Meng Jiang (Part XXXII): who sewed winter clothes for a husband taken to build the wall, walked the length of the
country to bring them, was told at the foot of it that he was under it, and wept until eight hundred li of wall came
down. A country-woman of twenty-five in undyed mourning hemp, a headcloth, road-dust to the knee, and a bundle of
quilted clothes that she has not put down.
Run: blender --background --python art/characters/meng_jiang.py  ->  assets/characters/meng_jiang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/meng_jiang.glb", {"fem": True, "age": 0.1, "build": 1.0, "lip": "b06a62", "eye_size": 1.15, "smile": False, "skin": "e0c0a0",
    "robe": "d8d0bc", "trim": "a89c84", "inner": "ece6d6", "sash": "8a7e68", "pants": "b0a690", "boots": "5a4a3a",
    "hair": "1a1614", "hair_style": "bun", "eyes": "2e2420", "hat": "headcloth", "hat_col": "e4dcc8",
    "props": [("cloth_sack", {"col": "5a6a7a", "cord": "8a7e68"})], "pose": "hold_both"})
