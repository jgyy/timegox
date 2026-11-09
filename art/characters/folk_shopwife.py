"""A shopkeeper of the towns (scripts/folk.gd): a cheerful woman in a long robe with a jade pin in her bun, who opens her shutters at dawn and calls her wares down the street.
Run: blender --background --python art/characters/folk_shopwife.py  ->  assets/characters/folk_shopwife.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_shopwife.glb", {"fem": True, "age": 0.48, "build": 1.1, "cheek": 1.25, "smile": True, "robe": "4a6a8a", "trim": "f0e4c8", "inner": "f6efe2", "sash": "c87a3a", "hair": "201a16", "hair_style": "bun", "pin": "4aa07a", "eyes": "3a2a1a"})
