"""Ox-Head, runner of the Ten Courts of the underworld (Part VI): a towering brute in iron-studded
court livery with an ox's head, sweeping horns, a gold nose ring and a halberd.  Cloth is tinted per
enemy; the head keeps its own hide colour.  1.4x scale.
Run: blender --background --python art/monsters/oxhead.py  ->  assets/monsters/oxhead.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("monsters/oxhead.glb", {
    "robe": "a0a0a0", "trim": "e0e0e0", "inner": "707070", "sash": "4a4a4a", "pants": "505050", "boots": "2a2a2a",
    "sleeve": "909090", "beast_head": "ox", "head_col": "4a3028", "muzzle_col": "8a6a58", "eyes": "ff3818",
    "armor": True, "metal": "3a3440", "halberd": True, "cape": "8a8a8a", "tint_cloth": True, "scale": 1.4, "head_scale": 1.0,
    "embroidery": "c8a040", "folds": 10,
})
