"""Tang of Shang (Part XXX): the lord who, walking in the fields, found a fowler with nets hung on all four sides praying
that everything under heaven should fall into them, had three sides taken down, and left one; of whom the lords south of
the Han said that his virtue reached even the birds and beasts. A broad, unhurried man of middle age in an undyed hemp
robe with a white border and a plain leather belt, a full black beard, a lord's topknot, walking without a guard.
Run: blender --background --python art/characters/cheng_tang.py  ->  assets/characters/cheng_tang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cheng_tang.glb", {"fem": False, "age": 0.5, "build": 1.1, "jaw": 1.08, "brow": 1.1, "smile": True, "skin": "c8a27a",
    "robe": "d8d0bc", "trim": "f4f0e6", "inner": "f0ece0", "sash": "6a4a30", "pants": "8a8272", "boots": "3a2e24",
    "hair": "18161a", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.4, "beard_col": "18161a"})
