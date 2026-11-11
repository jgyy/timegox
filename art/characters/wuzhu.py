"""Wuzhu, the Masterless Edge (Part XXI, the Hundred Arms release; a lord of the story, fought in its own model): four thousand blades that nobody made and
nobody owns, in the shape of somebody: a tall figure the grey of drawn steel, plated like a pine-cone, bare-headed, with eyes like the flat of a polished sword and a jian in its hand.
Run: blender --background --python art/characters/wuzhu.py  ->  assets/characters/wuzhu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/wuzhu.glb", {"fem": False, "age": 0.0, "build": 1.04, "jaw": 1.0, "stern": False, "smile": False, "skin": "c8d0dc", "lip": "9aa4b4", "scale": 1.14,
    "robe": "8a94a8", "trim": "e8f0ff", "inner": "dce4f0", "sash": "5a6478", "pants": "5a6274", "boots": "3a4250", "hair": "e0e8f4", "hair_style": "long", "hair_len": 0.9, "eyes": "f0f8ff", "glow_eyes": True,
    "armor": True, "metal": "c0cad8", "bracers": "a8b2c4", "cape": "6a7488", "sword": True, "blade": "ffffff", "hilt": "8a94a8"})
