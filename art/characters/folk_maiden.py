"""A young woman of the towns (scripts/folk.gd): long hair tied back with a ribbon and a long robe; a weaver, a tea-picker, a dyer's daughter.
Run: blender --background --python art/characters/folk_maiden.py  ->  assets/characters/folk_maiden.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_maiden.glb", {"fem": True, "age": 0.15, "build": 0.95, "eye_size": 1.15, "smile": True, "robe": "a86a8a", "trim": "f6eadc", "inner": "fbf5ec", "sash": "5a7aa0", "hair": "1a1410", "hair_style": "long", "eyes": "3a2418", "ribbon": "e85a6a"})
