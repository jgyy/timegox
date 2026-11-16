"""Princess Lechang of Chen (Part XXXII): the last king's sister, who broke a mirror with her husband when the city
fell, was carried north into the household of a great lord of the conquerors, and has sent an old servant to market with
her half every Lantern Festival since. A woman of thirty-odd in the plum silk of somebody else's house, worn plainly,
with her hair up as a married woman's and her own half of the mirror held where she can see it.
Run: blender --background --python art/characters/lechang.py  ->  assets/characters/lechang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lechang.glb", {"fem": True, "age": 0.22, "build": 0.95, "lip": "b85a66", "eye_size": 1.2, "smile": False, "skin": "f0d8c4",
    "robe": "6a3a58", "trim": "d8c0a0", "inner": "f4ece0", "sash": "3a2a44", "pants": "4a3048", "boots": "3a2830",
    "hair": "1c1618", "hair_style": "bun", "eyes": "3a2a2a", "pin": "c8a040", "embroidery": "c8a860",
    "props": [("half_mirror", {"side": -1})], "pose": "hold_l"})
