"""Yue Ling, healer of the Lotus Seal: rose robe, long hair with ribbons and a jade pin.
Run: blender --background --python art/characters/yue_ling.py  ->  assets/characters/yue_ling.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
# the party: the twenty-one clips every person has, and what they do with the things of the world
person.export_person("characters/yue_ling.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.0, "lip": "e07a88", "eye_size": 1.34, "hair_len": 0.62,
    "robe": "e86a9a", "trim": "ffe0ec", "inner": "fff4f8", "hair": "402030", "hair_style": "long",
    "eyes": "c04080", "sash": "a03060", "ribbon": "ffb0cc", "boots": "6a3048", "pants": "8a3a5a",
    "jade": "8af0c8", "pin": "8af0c8",
}, clips=person.PARTY_CLIPS)
