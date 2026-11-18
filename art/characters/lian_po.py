"""Lian Po, General of Zhao (Part XXXVIII): the old general who swore to shame Lin Xiangru in the road and ended by carrying thorn rods to his gate (Records of the Historian). One of the three who stand above Lin Feng (betters.gd). A broad old man of sixty-five built like a gatehouse, in worn ochre leather and iron-grey, white beard to the chest.
Run: blender --background --python art/characters/lian_po.py  ->  assets/characters/lian_po.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lian_po.glb", {"age": 0.8, "build": 1.25, "jaw": 1.1, "brow": 1.15, "smile": False, "skin": "b8906a", "robe": "7a6a4a", "trim": "4a4a52", "inner": "5a5248", "sash": "4a3a2a", "pants": "5a4a3a", "shoes": "boots", "hair": "c8c8c4", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.45, "beard_col": "d0d0cc", "brow_col": "c8c8c4", "robe_len": "long"})
