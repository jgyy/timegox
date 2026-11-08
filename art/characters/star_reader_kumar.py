"""Star-Reader Kumar of the Temple of the Fallen Stars at Shazhou: a scholar from far beyond the western desert in indigo robes sewn with stars, with his star charts.
Run: blender --background --python art/characters/star_reader_kumar.py  ->  assets/characters/star_reader_kumar.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/star_reader_kumar.glb", {
    "age": 0.65, "build": 0.95, "brow": 1.1, "eye_size": 1.0, "beard": True, "beard_len": 0.8, "beard_col": "6a6460",
    "robe": "2e2e6a", "trim": "e8d8a0", "inner": "e8e4f0", "sash": "c8a040", "hair": "4a4440", "hair_style": "topknot",
    "eyes": "3a2a1a", "hat": "hood", "hat_col": "e8e4d8", "props": ["scroll"], "pose": "hold_l", "embroidery": "f0e0a0", "beads": "c8a040",
})
