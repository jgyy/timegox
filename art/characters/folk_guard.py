"""A town guard (scripts/folk.gd): a lamellar coat over his robe and a halberd; he stands at the town gate by day and walks the walls by night.
Run: blender --background --python art/characters/folk_guard.py  ->  assets/characters/folk_guard.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_guard.glb", {"age": 0.35, "build": 1.2, "jaw": 1.15, "brow": 1.15, "stern": True, "robe": "6a2a2a", "trim": "d8c890", "inner": "e8e0cc", "sash": "2a2a30", "hair": "18140f", "hair_style": "topknot", "eyes": "2e2418", "armor": True, "metal": "7a7a80", "halberd": True})
