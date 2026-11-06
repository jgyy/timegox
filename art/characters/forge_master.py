"""Forgemaster Ou Lan of Heaven's Forge: a soot-dark smith's coat with bronze armour plates, wild hair and a beard.
Run: blender --background --python art/characters/forge_master.py  ->  assets/characters/forge_master.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/forge_master.glb", {
    "robe": "5a3a2a", "trim": "d08a40", "inner": "a88a70", "sash": "2a1a10", "hair": "3a2018", "hair_style": "wild", "eyes": "f0a040",
    "armor": True, "metal": "b07a40", "beard": True, "beard_col": "4a2a18", "stern": True, "embroidery": "d08a40",
})
