"""The Charcoal Seller (Part XXVII): the old man of Bai Juyi's poem, who cuts wood and burns charcoal on the south
mountain, his face the colour of smoke and ash, his temples grey and his ten fingers black, in thin clothes and hoping
for cold weather; a spare, bent old man in a single patched grey jacket, straw sandals, a carrying pole across his
shoulders with a sack of charcoal at each end.
Run: blender --background --python art/characters/charcoal_seller.py  ->  assets/characters/charcoal_seller.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/charcoal_seller.glb", {"fem": False, "age": 0.85, "build": 0.84, "jaw": 0.94, "brow": 1.1, "cheek": 1.2, "smile": False, "skin": "9a8470",
    "robe": "6a665e", "trim": "3a3834", "inner": "8a8478", "sash": "2a2826", "pants": "4a4640", "boots": "2a2620", "shoes": "sandals", "sleeve_w": 0.75,
    "hair": "b8b4ac", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.2, "beard_col": "b0aca4",
    "props": ["charcoal_yoke"]})
