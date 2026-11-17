"""The wife of Yue Yangzi (Part XXXIV): her name is not in the Book of the Later Han, only what she said. A woman of
thirty at a loom in a farmhouse of Henan, in undyed hemp with her sleeves tied back, her hair in a plain bun under a
cloth; she does not smile to please, and she stands as somebody stands who has a web waiting.
Run: blender --background --python art/characters/yangzi_wife.py  ->  assets/characters/yangzi_wife.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yangzi_wife.glb", {"fem": True, "age": 0.3, "build": 0.98, "eye_size": 1.1, "smile": False, "stern": True, "skin": "e0c4a4",
    "robe": "b8ac90", "trim": "6a6250", "inner": "ece6d6", "sash": "5a4a3a", "pants": "8a8068", "shoes": "sandals",
    "hair": "18140f", "hair_style": "bun", "eyes": "2a2018", "hat": "headcloth", "hat_col": "8a8470", "robe_len": "short"})
