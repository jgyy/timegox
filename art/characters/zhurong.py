"""Zhurong, Lord of the Southern Fire and of summer (Part XVIII, the New Fire release): a tall red god in vermilion
and gold armour, ember-eyed, crowned, with a mantle the colour of a forge mouth.
Run: blender --background --python art/characters/zhurong.py  ->  assets/characters/zhurong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhurong.glb", {"fem": False, "age": 0.35, "build": 1.24, "jaw": 1.12, "brow": 1.2, "stern": True, "skin": "d86a4a", "scale": 1.16,
    "robe": "b8281e", "trim": "f0c040", "inner": "ffe8b0", "sash": "f0a020", "pants": "5a1410", "boots": "3a1410", "hair": "ff7a20", "hair_style": "wild", "eyes": "ffd040", "glow_eyes": True,
    "cape": "e0501a", "armor": True, "metal": "e8b040", "crown": True, "beard": True, "beard_len": 0.5, "beard_col": "ff8a30", "brocade": "cloud", "brocade_col": "f0c040", "staff": True, "staff_gem": "ff6020"})
