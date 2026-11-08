"""Teacher Qin of the Thousand Names (Part XII): a thin, ink-stained schoolteacher of Landfall in a brown scholar's robe, a scroll of names under his arm and spectacles on his nose.
Run: blender --background --python art/characters/teacher_qin.py  ->  assets/characters/teacher_qin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/teacher_qin.glb", {
    "age": 0.45, "build": 0.9, "jaw": 0.9, "brow": 1.05, "beard": True, "beard_col": "2a2420", "beard_len": 0.4,
    "props": ["scroll", ("spectacles", {"col": "3a3020"})], "pose": "hold_l", "hat": "scholar", "hat_col": "2a2a30",
    "robe": "6a4a3a", "trim": "e8dcc0", "inner": "f2ece0", "sash": "2a3a4a", "hair": "1e1a18", "hair_style": "topknot", "eyes": "3a2a1a"
})
