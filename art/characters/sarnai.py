"""Grandmother Sarnai, keeper of the Felt Hearth of the horse-folk (the New Fire release): a small, weathered old
woman in a wine-red robe belted with yellow, a felt hat with a fur brim, turquoise at her collar.
Run: blender --background --python art/characters/sarnai.py  ->  assets/characters/sarnai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sarnai.glb", {"fem": True, "age": 0.85, "build": 1.0, "eye_size": 1.0, "cheek": 1.25, "skin": "c89a78", "smile": True,
    "robe": "8a2a3a", "trim": "e8c050", "inner": "f0e0c0", "sash": "d8a020", "pants": "3a2420", "boots": "5a3a24", "hair": "d8d4cc", "hair_style": "bun",
    "eyes": "3a2a1a", "hat": "felt", "hat_col": "6a2a2a", "hat_trim": "e8dcc0", "beads": "3aa0a0", "brocade": "cloud", "brocade_col": "c8903a"})
