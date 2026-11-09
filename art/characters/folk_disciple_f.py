"""An outer disciple of the Azure Cloud Sect (scripts/folk.gd): the sect's blue and white, long hair tied with a white ribbon and a practice sword.
Run: blender --background --python art/characters/folk_disciple_f.py  ->  assets/characters/folk_disciple_f.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_disciple_f.glb", {"fem": True, "age": 0.18, "build": 0.95, "eye_size": 1.18, "robe": "4a7ab8", "trim": "f4f6ff", "inner": "ffffff", "sash": "2a3a5a", "hair": "141218", "hair_style": "long", "eyes": "2a2a3a", "ribbon": "f4f6ff", "sword": True})
