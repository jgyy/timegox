"""The Old Oil Seller (Part XXXIII): of Ouyang Xiu's telling, who set down his load to watch Chen Yaozi shoot, only
nodded a little, and then poured oil into a gourd through the hole of a coin without wetting the coin. An old
pedlar in a patched brown jacket and a straw hat, a gourd at his hip, and his whole shop on a pole across his
shoulders: two stoppered jars.
Run: blender --background --python art/characters/oil_seller.py  ->  assets/characters/oil_seller.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/oil_seller.glb", {"age": 0.85, "build": 0.98, "jaw": 0.98, "brow": 1.1, "smile": True, "skin": "c8a47c",
    "robe": "6a5238", "trim": "3e3022", "inner": "cfc6ae", "sash": "2e2418", "pants": "4a4032", "shoes": "sandals",
    "hair": "b8b4ac", "hair_style": "topknot", "eyes": "2e241a", "beard": True, "beard_len": 0.35, "beard_col": "c8c4bc", "brow_col": "b8b4ac",
    "hat": "straw", "robe_len": "short", "props": [("oil_yoke", {}), ("gourd", {"col": "c89a40"})]})
