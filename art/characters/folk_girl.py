"""A girl of the towns (scripts/folk.gd): twin buns tied with red ribbon and a short robe; she plays in the square, flies kites in the fields and follows the lantern-lighter round at dusk.
Run: blender --background --python art/characters/folk_girl.py  ->  assets/characters/folk_girl.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_girl.glb", {"fem": True, "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.18, "jaw": 0.85, "robe": "d86a7a", "trim": "fff0e8", "inner": "fff8f2", "sash": "f0c050", "hair": "1e1814", "hair_style": "twin_buns", "eyes": "4a2a1a", "ribbon": "e83a3a", "robe_len": "short", "pants": "f0c8a8"})
