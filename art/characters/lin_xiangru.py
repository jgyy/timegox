"""Lin Xiangru (Part XXXVIII): the minister of Zhao who brought the jade of He back whole from Qin, faced its king down at Mianchi, and turned his carriage aside for General Lian Po (Records of the Historian). A slight, neat man of forty in a minister's sage-green robe and plain cap, clean-shaven, who looks as if he is about to be amused.
Run: blender --background --python art/characters/lin_xiangru.py  ->  assets/characters/lin_xiangru.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_xiangru.glb", {"age": 0.4, "build": 0.82, "jaw": 0.92, "brow": 0.98, "smile": True, "skin": "d8b898", "robe": "7a8a6a", "trim": "3a4a34", "inner": "e0dcd0", "sash": "c8b070", "pants": "5a6a52", "shoes": "boots", "hair": "1c1a18", "hair_style": "topknot", "eyes": "2a2018", "brow_col": "1c1a18", "robe_len": "long"})
