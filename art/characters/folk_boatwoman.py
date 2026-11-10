"""A woman of the river boats for the towns' crowds (the New Fire release, the Boat Hearth): indigo jacket with the
sleeves rolled, wide black trousers, a blue headcloth with a white edge, and a boat-child's gourd at her sash.
Run: blender --background --python art/characters/folk_boatwoman.py  ->  assets/characters/folk_boatwoman.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_boatwoman.glb", {"fem": True, "age": 0.3, "build": 1.04, "eye_size": 1.14, "skin": "d8ae8a", "smile": True, "robe": "2a4a7a", "trim": "e8ecf0", "inner": "e8e8e0", "sash": "8a2a2a",
    "pants": "1a1c24", "boots": "3a3a40", "hair": "1a1418", "hair_style": "bun", "eyes": "2a1a14", "hat": "headcloth", "hat_col": "2a5a9a", "hat_trim": "f0f0f4",
    "sleeve_w": 0.72, "props": ["gourd"]})
