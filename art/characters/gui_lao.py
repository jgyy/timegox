"""Old Gui, Herald of the Turtles (Part XII): a small, very old turtle-man who keeps the tallies of the turtles' shifts; a green-brown robe like a shell, scaly hands and a ledger.
Run: blender --background --python art/characters/gui_lao.py  ->  assets/characters/gui_lao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gui_lao.glb", {
    "age": 0.95, "build": 0.86, "scale": 0.88, "brow": 1.3, "beard": True, "beard_col": "c8c8b0", "beard_len": 0.5, "scales": "6a7a4a",
    "props": [("ledger", {"cover": "4a5a3a", "paper": "e8e0c8"})], "pose": "hold_l",
    "robe": "5a6a4a", "trim": "c8b878", "inner": "e8e4d0", "sash": "3a4a2a", "hair": "c8c8b0", "hair_style": "bald", "eyes": "3a3a2a"
})
