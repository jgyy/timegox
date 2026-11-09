"""Xu Lan, Demon Lord Xu Mo's daughter (a fated encounter, scripts/fate.gd): pale, long black hair, a dark
red robe with a pale cloud brocade, crimson eyes the moon's blood left in her.
Run: blender --background --python art/characters/xu_lan.py  ->  assets/characters/xu_lan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xu_lan.glb", {
    "fem": True, "age": 0.0, "build": 0.9, "jaw": 0.86, "eye_size": 1.15, "lash": "120a0e",
    "hair_style": "long", "hair_len": 0.7, "hair": "120c12", "pin": "c02040",
    "robe": "7a1a2a", "trim": "e8c8d0", "inner": "f4e8ec", "sash": "2a0a12", "pants": "3a0c14", "boots": "1a0a0e",
    "eyes": "c02838", "skin": "f2dcd4", "brocade": "cloud", "embroidery": "d8d8f0",
})
