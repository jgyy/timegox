"""Cao Guojiu, the Court Official Who Resigned (Part XII): the Empress's brother, once a minister of the Court, in an official's robe and winged cap, holding the court tablet he broke in two.
Run: blender --background --python art/characters/cao_guojiu.py  ->  assets/characters/cao_guojiu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cao_guojiu.glb", {
    "age": 0.5, "build": 1.0, "jaw": 0.98, "brow": 1.1, "beard": True, "beard_col": "1a1a20", "beard_len": 0.6,
    "props": [("ledger", {"cover": "e8e0c8", "paper": "f0e8d0"})], "pose": "hold_both", "hat": "scholar", "hat_col": "141418",
    "robe": "3a3a6a", "trim": "d8c070", "inner": "ece8dc", "sash": "c8a040", "hair": "141418", "hair_style": "topknot", "eyes": "2a2a2a", "embroidery": "d8c070"
})
