"""Liu Ying, the Marsh Hag's apprentice (a fated encounter, scripts/fate.gd): fourteen, two loops of hair,
a green-grey robe under an apron of herb pockets, and a basket of things nobody else would pick.
Run: blender --background --python art/characters/liu_ying.py  ->  assets/characters/liu_ying.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/liu_ying.glb", {
    "fem": True, "age": 0.0, "build": 0.86, "scale": 0.94, "eye_size": 1.3, "jaw": 0.86,
    "hair_style": "twin_buns", "hair": "241a12", "ribbon": "6a8a4a", "pin": "8ac06a",
    "robe": "6a7a5a", "trim": "c8d0a8", "inner": "eef0e0", "sash": "3a4a2a", "pants": "4a5040", "boots": "2a2a20",
    "eyes": "3a5a2a", "robe_len": "short", "props": ["apron", ("basket", {"fill": "6a8a3a"})], "pose": "hold_l",
})
