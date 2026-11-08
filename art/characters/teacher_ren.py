"""Old Teacher Ren of the Village School (towns): Qingshi's schoolmaster, white-bearded, with spectacles and a scroll, who has crossed out 'square' in the Court's primers.
Run: blender --background --python art/characters/teacher_ren.py  ->  assets/characters/teacher_ren.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/teacher_ren.glb", {
    "age": 0.85, "build": 0.9, "brow": 1.2, "beard": True, "beard_col": "e8e6e0", "beard_len": 1.0,
    "props": ["scroll", ("spectacles", {"col": "3a3020"})], "pose": "hold_l", "hat": "scholar", "hat_col": "2a2a30",
    "robe": "5a4a6a", "trim": "e8dcc0", "inner": "f2ece0", "sash": "2a3a4a", "hair": "e8e6e0", "hair_style": "topknot", "eyes": "3a2a1a"
})
