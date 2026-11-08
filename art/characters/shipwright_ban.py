"""Shipwright Ban (Part XII): Landfall's boat-builder, broad and sunburnt, in a leather apron with a mallet, scraping barnacles off boats left on the sand.
Run: blender --background --python art/characters/shipwright_ban.py  ->  assets/characters/shipwright_ban.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shipwright_ban.glb", {
    "age": 0.4, "build": 1.16, "jaw": 1.08, "brow": 1.15, "beard": True, "beard_col": "2a2018", "beard_len": 0.3,
    "props": [("apron", {"col": "7a5434", "strap": "3a2818"}), ("hammer", {"head": "6a5a4a", "handle": "6a4a2a"})], "robe_len": "short",
    "robe": "8a6a4a", "trim": "4a3a2a", "inner": "d8c8a8", "sash": "3a2a1a", "hair": "1a1410", "hair_style": "topknot", "eyes": "2a1a10", "pants": "5a4a3a", "bracers": "4a3a2a"
})
