"""Pearl-Diver Yu Lan (Part XII): a young pearl-diver of Landfall in a short teal diving jacket, her hair tied up, a glowing pearl in her hand.
Run: blender --background --python art/characters/diver_yulan.py  ->  assets/characters/diver_yulan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/diver_yulan.glb", {
    "fem": True, "age": 0.1, "eye_size": 1.25, "jaw": 0.88, "build": 0.94,
    "props": [("pearl", {"col": "e8f8ff"})], "pose": "hold_l", "robe_len": "short",
    "robe": "2a8aa0", "trim": "f4f0e0", "inner": "f8f8f4", "sash": "e8c060", "hair": "121014", "hair_style": "bun", "eyes": "2a2a3a", "pants": "2a5a6a"
})
