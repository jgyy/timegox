"""A bronze-founder of Tushan for the towns' crowds (the New Fire release, the Casting Hearth): a short soot-brown
jacket with bracers, a leather apron to the knee and a sweat-cloth round the brow.
Run: blender --background --python art/characters/folk_founder.py  ->  assets/characters/folk_founder.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_founder.glb", {"fem": False, "age": 0.35, "build": 1.18, "jaw": 1.12, "brow": 0.9, "skin": "d0a078", "robe": "6a4a34", "trim": "c87a3a", "inner": "d8c8a8", "sash": "3a2a20",
    "pants": "3a2c24", "boots": "2a2420", "hair": "1a1410", "hair_style": "short", "eyes": "2a1a10", "hat": "headcloth", "hat_col": "8a3a2a", "hat_trim": "c87a3a",
    "sleeve_w": 0.7, "bracers": "5a3a24", "props": ["apron"]})
