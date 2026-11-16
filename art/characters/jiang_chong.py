"""Jiang Chong, the Finder (Part XXX): the envoy of the Emperor Wu of Han who was sent to dig for the dolls of the
witchcraft plot and found one under every floor he wished to, having brought them in his sleeve; whom the Crown Prince
killed, and for whom tens of thousands died. A sleek, smiling man in a robe of gauze over yellow silk of his own odd
cut, a tall cap with trailing ribbons, a small neat beard, and a little spade at his belt.
Run: blender --background --python art/characters/jiang_chong.py  ->  assets/characters/jiang_chong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/jiang_chong.glb", {"fem": False, "age": 0.4, "build": 1.02, "jaw": 0.92, "brow": 0.9, "smile": True, "skin": "d8b890",
    "robe": "c8a030", "trim": "5a1e4a", "inner": "f0e4c0", "sash": "5a1e4a", "pants": "6a5020", "boots": "2a1a20",
    "hair": "161418", "hair_style": "topknot", "eyes": "2a1e1a", "beard": True, "beard_len": 0.1, "beard_col": "161418"})
