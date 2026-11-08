"""Scholar Wang (towns): a thin young examination candidate in a scholar's hat with a fan and a scroll, failing the exams with great dignity.
Run: blender --background --python art/characters/scholar_wang.py  ->  assets/characters/scholar_wang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/scholar_wang.glb", {
    "age": 0.2, "build": 0.88, "jaw": 0.95, "eye_size": 1.15,
    "robe": "e8e4d0", "trim": "3a5a8a", "inner": "f8f6f0", "sash": "3a5a8a", "hair": "1a1a20", "hair_style": "topknot",
    "eyes": "2a2a3a", "hat": "scholar", "hat_col": "1a1a24", "props": ["folding_fan", "scroll"], "pose": "hold_l", "brocade": "plum", "brocade_col": "c8d0e0",
})
