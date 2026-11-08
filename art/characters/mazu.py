"""Mazu, Who Brings the Boats Home (Part XII): Lin Moniang, the fisherman's daughter who became the goddess of the sea, young, in a red robe with gold trim and a pearled crown, a red lantern in her hand.
Run: blender --background --python art/characters/mazu.py  ->  assets/characters/mazu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/mazu.glb", {
    "fem": True, "age": 0.1, "eye_size": 1.3, "jaw": 0.86, "lip": "d05050", "hair_len": 0.7, "build": 0.95,
    "props": [("lantern", {"col": "e8402a", "frame": "6a2a1a", "glow": "ffb070"})], "pose": "hold_l", "crown": True,
    "robe": "c8302a", "trim": "f0c850", "inner": "fff2e0", "sash": "f0c850", "hair": "141018", "hair_style": "bun", "eyes": "3a2418", "pin": "f0e0a0", "embroidery": "f0c850"
})
