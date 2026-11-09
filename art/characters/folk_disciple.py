"""An outer disciple of the Azure Cloud Sect (scripts/folk.gd): the sect's blue and white, a topknot and a practice sword; they sweep the courtyards, train in the yard and file in to meals.
Run: blender --background --python art/characters/folk_disciple.py  ->  assets/characters/folk_disciple.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_disciple.glb", {"age": 0.2, "build": 1.0, "jaw": 1.0, "robe": "3a6aa8", "trim": "f0f4ff", "inner": "ffffff", "sash": "2a3a5a", "hair": "121014", "hair_style": "topknot", "eyes": "2a2a3a", "sword": True})
