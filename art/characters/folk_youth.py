"""A young man of the towns (scripts/folk.gd): a plain robe and a topknot; an apprentice, a runner, a carpenter's boy, a courier between the towns.
Run: blender --background --python art/characters/folk_youth.py  ->  assets/characters/folk_youth.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_youth.glb", {"age": 0.15, "build": 1.0, "jaw": 1.0, "robe": "5a7a5a", "trim": "e4dcc8", "inner": "f0eadc", "sash": "3a3a2a", "hair": "16120e", "hair_style": "topknot", "eyes": "2e2014"})
