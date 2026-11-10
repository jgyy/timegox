"""Gou Mang, Lord of Spring (Part XVII): the god of wood and spring who walks in front of the Spring Ox in every Lichun procession, a round-faced solemn youth in a robe of new-leaf green with a swallow's wings folded at his back, a willow-green ribbon in his hair and the willow switch he has whipped the ox with for three thousand years.
Run: blender --background --python art/characters/gou_mang.py  ->  assets/characters/gou_mang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gou_mang.glb", {
    "fem": False, "age": 0.05, "build": 0.92, "jaw": 0.88, "cheek": 1.2, "eye_size": 1.26, "smile": False,
    "robe": "5aa86a", "trim": "eef6d8", "inner": "fbfcf2", "sash": "2a5a3a", "pants": "3a6a44", "boots": "3a3a2a",
    "hair": "1a2a1e", "hair_style": "topknot", "eyes": "4aa860", "ribbon": "9ad870", "embroidery": "e8e090",
    "brocade": "plum", "brocade_col": "8ad08a",
    # a swallow's wings: blue-black flight feathers with white under them (art/lib/race.py)
    "wings": "1e2a44", "wing_tip": "f0ece0",
    "props": [("whip", {"col": "6a9a4a"})],
})
