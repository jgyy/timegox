"""Old Qi of the Gold Market (Part XXXVI): the man of Qi who took the gold in a crowded market because he saw only the
gold (Liezi), grown old at the end of a digging he drove through a hill after one vein. A stooped man of
sixty-eight in a miner's short coat of ochre gone grey with rock dust, a rag round his brow, white stubble, and
the narrow eyes of somebody who has looked at one thing for eleven years.
Run: blender --background --python art/characters/old_qi.py  ->  assets/characters/old_qi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/old_qi.glb", {"age": 0.8, "build": 0.92, "jaw": 0.98, "brow": 1.18, "smile": False, "skin": "c0a080",
    "robe": "8a7a4a", "trim": "4a4230", "inner": "b8b0a0", "sash": "3a3428", "pants": "5a5444", "shoes": "sandals",
    "hair": "c8c6c0", "hair_style": "wild", "eyes": "33281c", "beard": True, "beard_len": 0.3, "beard_col": "d0cec8", "brow_col": "c0beb8", "robe_len": "short", "wraps": "6a6250"})
