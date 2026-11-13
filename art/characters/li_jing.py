"""Li Jing, the Pagoda-Bearing Heavenly King (Part XXVII): the general of heaven who carries a pagoda on the palm of his
left hand and has not set it down in three thousand years, because the day he does his son will remember what he owes
him; a tall, heavy-shouldered man in gilded armour over a dark red robe, a long black beard, a general's topknot, and
the pagoda on his palm.
Run: blender --background --python art/characters/li_jing.py  ->  assets/characters/li_jing.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/li_jing.glb", {"fem": False, "age": 0.55, "build": 1.14, "jaw": 1.1, "brow": 1.3, "stern": True, "smile": False, "skin": "caa27c",
    "robe": "6a1e1e", "trim": "d8b040", "inner": "e0d4c0", "sash": "d8b040", "pants": "3a1a1a", "boots": "2a1a14", "armor": True, "metal": "c8a040",
    "hair": "161418", "hair_style": "topknot", "eyes": "2a1e1a", "beard": True, "beard_len": 0.6, "beard_col": "161418",
    "props": ["pagoda"], "pose": "hold_l"})
