"""A boy of the towns (scripts/folk.gd): short hair, a short robe and bare feet in sandals; he goes to the village teacher in the morning, runs about the square in the afternoon and is called home at dusk.
Run: blender --background --python art/characters/folk_boy.py  ->  assets/characters/folk_boy.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_boy.glb", {"age": 0.0, "build": 0.82, "eye_size": 1.42, "scale": 0.72, "head_scale": 1.18, "jaw": 0.85, "robe": "4a7aa8", "trim": "f0f0f0", "inner": "fafaf6", "sash": "d8a040", "hair": "1a1612", "hair_style": "short", "eyes": "3a2414", "robe_len": "short", "pants": "e0d0b0", "shoes": "sandals"})
