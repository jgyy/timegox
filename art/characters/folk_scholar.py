"""A scholar of the towns (scripts/folk.gd): a scholar's black cap and a long blue robe; he reads in the morning, teaches the children and writes letters for anybody who cannot.
Run: blender --background --python art/characters/folk_scholar.py  ->  assets/characters/folk_scholar.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_scholar.glb", {"age": 0.32, "build": 0.9, "jaw": 0.95, "robe": "4a5a7a", "trim": "e8e4d8", "inner": "f4f2ea", "sash": "2a2a3a", "hair": "141210", "hair_style": "topknot", "eyes": "2a2018", "hat": "scholar", "hat_col": "1a1a20"})
