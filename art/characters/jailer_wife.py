"""Mistress Wu, the Jailer's Wife (Part XXVI): who took Hua Tuo his soup in the jail of Wei, and stood over a brazier with
his book: what good did it do him?  A plain, sturdy woman of thirty or so in a rust-red jacket with a brown apron, a white
headcloth over her bun, holding the bowl she carried the soup in.
Run: blender --background --python art/characters/jailer_wife.py  ->  assets/characters/jailer_wife.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/jailer_wife.glb", {"fem": True, "age": 0.32, "build": 1.0, "jaw": 0.98, "brow": 0.9, "smile": False, "skin": "d8b494",
    "robe": "8a4a3a", "trim": "e8dcc4", "inner": "f2ece0", "sash": "5a3a2a", "pants": "3a2a24", "boots": "2a201c", "hair": "241c1a", "hair_style": "bun",
    "hat": "headcloth", "hat_col": "efe8dc", "hat_trim": "b8a890", "eyes": "3a2a20", "props": [("apron", {"col": "6a4a30", "strap": "3a2818"}), "bowl"], "pose": "hold_both"})
