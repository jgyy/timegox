"""Navid the Sogdian Merchant (towns): a caravan merchant who has crossed the desert forty times, in a belted kaftan and a fur-trimmed cap, an abacus in his hand.
Run: blender --background --python art/characters/navid.py  ->  assets/characters/navid.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/navid.glb", {
    "age": 0.5, "build": 1.06, "brow": 1.15, "jaw": 1.02, "beard": True, "beard_col": "2a1a14", "beard_len": 0.8, "skin": "c09068",
    "props": [("abacus", {"frame": "5a3a20", "beads": "c8a050"})], "pose": "hold_l", "hat": "fur", "hat_col": "6a3a2a",
    "robe": "8a3a5a", "trim": "f0c850", "inner": "f0e4d0", "sash": "e8a030", "hair": "1a1210", "hair_style": "short", "eyes": "2a1a10", "boots": "4a2a1a", "embroidery": "f0c850"
})
