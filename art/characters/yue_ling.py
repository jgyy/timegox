"""Yue Ling, healer of the Lotus Seal: rose robe, long hair with ribbons and a jade pin.
Run: blender --background --python art/characters/yue_ling.py  ->  assets/characters/yue_ling.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yue_ling.glb", {
    "robe": "e86a9a", "trim": "ffe0ec", "inner": "fff4f8", "hair": "402030", "hair_style": "long",
    "eyes": "c04080", "sash": "a03060", "ribbon": "ffb0cc", "boots": "6a3048", "pants": "8a3a5a",
    "jade": "8af0c8", "pin": "8af0c8",
})
