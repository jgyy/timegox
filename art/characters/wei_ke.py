"""Wei Ke, General of Jin (Part XXVIII): the general who, when his father was dying and asked that a favourite concubine
be buried with him, followed instead what the old man had said in his right mind and saw her married; and who won the
field of Fushi because an old man knotted the grass in front of Du Hui; a lean, upright officer in dark blue lamellar over
a grey robe, a short black beard, a general's topknot.
Run: blender --background --python art/characters/wei_ke.py  ->  assets/characters/wei_ke.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/wei_ke.glb", {"fem": False, "age": 0.5, "build": 1.04, "jaw": 1.05, "brow": 1.2, "stern": True, "smile": False, "skin": "c8a680",
    "robe": "5a5e68", "trim": "2a3a6a", "inner": "e0d8c8", "sash": "2a3a6a", "pants": "2e3038", "boots": "1e1c1a", "armor": True, "metal": "3a4a7a",
    "hair": "18161a", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.25, "beard_col": "18161a"})
