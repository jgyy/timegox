"""Roll-Clerk Ning (towns): a shade of Youdu who keeps the rolls of the dead in perfect order; paper-pale, glowing-eyed, in a grey clerk's robe with a ledger.
Run: blender --background --python art/characters/roll_clerk_ning.py  ->  assets/characters/roll_clerk_ning.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/roll_clerk_ning.glb", {
    "fem": True, "age": 0.3, "eye_size": 1.2, "jaw": 0.88, "build": 0.92, "skin": "cad6de", "glow_eyes": True,
    "props": [("ledger", {"cover": "2a2a3a", "paper": "e8eef2"})], "pose": "hold_l", "hat": "scholar", "hat_col": "1a1a24",
    "robe": "4a4a5a", "trim": "c8d0d8", "inner": "e8ecf0", "sash": "2a2a34", "hair": "1a1a24", "hair_style": "bun", "eyes": "c8f0ff"
})
