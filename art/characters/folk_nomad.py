"""A caravan hand of Shazhou Oasis (scripts/folk.gd): a hooded desert robe against the sand and a broad sash; he waters the camels at the well and haggles in the shade.
Run: blender --background --python art/characters/folk_nomad.py  ->  assets/characters/folk_nomad.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_nomad.glb", {"age": 0.42, "build": 1.08, "jaw": 1.1, "beard": True, "beard_len": 0.35, "beard_col": "2a1e14", "skin": "d8a884", "robe": "c8a878", "trim": "8a3a2a", "inner": "f0e4cc", "sash": "3a6a7a", "hair": "1a120c", "hair_style": "short", "eyes": "2a1a10", "hat": "hood", "hat_col": "d8c098"})
