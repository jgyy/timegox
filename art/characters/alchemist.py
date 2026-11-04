"""Alchemist Mo: green robe, scholar's cap and a jade gourd at the belt.
Run: blender --background --python art/characters/alchemist.py  ->  assets/characters/alchemist.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/alchemist.glb", {
    "robe": "6fc08a",
    "trim": "e8f8e0",
    "hair": "2a2a3a",
    "hair_style": "bun",
    "hat": "scholar",
    "eyes": "4a7a5a",
    "sash": "3a6040",
    "beard": True,
    "beard_col": "3a3a40",})
