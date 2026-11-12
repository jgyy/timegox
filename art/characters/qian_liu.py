"""King Qian of the Sea-Wall (Part XXIV): Qian Liu of Wuyue, a salt-smuggler who became a king, built the sea-wall of Hangzhou of
bamboo baskets filled with stone, and had five hundred crossbowmen shoot three thousand arrows at the tidal bore: a broad man of sixty in sea-blue with gold
trims, a short grey beard and a small crown.
Run: blender --background --python art/characters/qian_liu.py  ->  assets/characters/qian_liu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/qian_liu.glb", {"fem": False, "age": 0.7, "build": 1.12, "jaw": 1.1, "brow": 1.15, "stern": True, "smile": True, "skin": "d0b090",
    "robe": "3a5a8a", "trim": "c8a050", "inner": "e8e0d0", "sash": "c8a050", "pants": "2a3a54", "boots": "1e2430", "hair": "8a8a8c", "hair_style": "topknot", "eyes": "3a3a3a",
    "beard": True, "beard_len": 0.22, "beard_col": "9a9a9c", "crown": True, "sleeve_w": 1.15, "cape": "24385a", "brocade": "cloud", "brocade_col": "5a7aa8"})
