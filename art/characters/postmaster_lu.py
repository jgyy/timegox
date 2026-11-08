"""Postmaster Lu of the Cloudfoot post station: round, patient and ink-stained, with the post ledger of all nine roads under his arm.
Run: blender --background --python art/characters/postmaster_lu.py  ->  assets/characters/postmaster_lu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/postmaster_lu.glb", {
    "age": 0.6, "build": 1.25, "cheek": 1.2, "eye_size": 1.0, "beard": True, "beard_len": 0.25, "beard_col": "5a4a40",
    "robe": "6a4a3a", "trim": "e0d0b0", "inner": "f0e8d8", "sash": "2a4a6a", "hair": "3a3028", "hair_style": "topknot",
    "eyes": "3a2a1a", "hat": "qing", "hat_col": "1a2030", "props": ["ledger"], "pose": "hold_l", "badge": "c8a040",
})
