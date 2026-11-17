"""The boy Li Bai (Part XXXIII): ten years old, who put down his book at the school on Xiang'er Mountain because it
was slow, and went off down the stream. A boy in a schoolboy's short blue robe a size too large, his hair in a
topknot coming undone, and the book he did not finish rolled in his hand, because he could not quite leave it.
Run: blender --background --python art/characters/li_bai.py  ->  assets/characters/li_bai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/li_bai.glb", {"age": 0.0, "build": 0.84, "eye_size": 1.4, "scale": 0.74, "head_scale": 1.17, "jaw": 0.86, "brow": 1.05, "skin": "e4c8a8",
    "robe": "5a7a9a", "trim": "e8e4d8", "inner": "f6f2e8", "sash": "8a3a2a", "pants": "d8ccb0", "shoes": "sandals",
    "hair": "16120e", "hair_style": "topknot", "eyes": "2e2016", "robe_len": "short",
    "props": [("scroll", {"paper": "ece0bc", "rod": "6a4428"})], "pose": "hold_l"})
