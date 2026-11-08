"""Wei, Who Collected Taxes for the Court (towns): a former tax-clerk of the Court, now carrying noodles at Cloudfoot; a faded official's robe, a scholar's cap and a bowl of soup.
Run: blender --background --python art/characters/clerk_wei.py  ->  assets/characters/clerk_wei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/clerk_wei.glb", {
    "age": 0.6, "build": 0.92, "brow": 1.05, "jaw": 0.94, "beard": True, "beard_col": "3a3430", "beard_len": 0.45,
    "props": [("bowl", {"col": "f0f0e8", "soup": "c09060"})], "pose": "hold_both", "hat": "scholar", "hat_col": "2a2a30",
    "robe": "4a4a5a", "trim": "a8a090", "inner": "e0dcd0", "sash": "6a5a4a", "hair": "3a3430", "hair_style": "topknot", "eyes": "2a2a2a"
})
