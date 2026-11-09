"""A cook of the towns (scripts/folk.gd): a big man in a cook's apron with his sleeves tied back, who works the stove of an inn or a noodle stall from dawn to late.
Run: blender --background --python art/characters/folk_cook.py  ->  assets/characters/folk_cook.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_cook.glb", {"age": 0.5, "build": 1.38, "cheek": 1.4, "jaw": 1.1, "smile": True, "robe": "e8e0d0", "trim": "8a6a50", "inner": "f6f2ea", "sash": "6a4a2a", "hair": "1a1612", "hair_style": "bun", "eyes": "2e2014", "props": [("apron", {"col": "f0ece0", "strap": "8a7a60"})]})
