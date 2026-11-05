"""Sage Huo Rong of the Ashen Volcano: ember-red robes, a bald head and a white beard, a straw hat against the ash.
Run: blender --background --python art/characters/fire_sage.py  ->  assets/characters/fire_sage.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fire_sage.glb", {
    "robe": "b03a20", "trim": "f0a040", "inner": "f0d8b0", "sash": "4a1a10", "hair": "e8e0d8", "hair_style": "bald", "eyes": "e08020",
    "beard": True, "beard_col": "f0e8e0", "hat": "straw", "hat_col": "8a6a40", "staff": True, "staff_gem": "ff8030", "embroidery": "f0a040",
})
