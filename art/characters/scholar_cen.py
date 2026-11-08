"""Scholar Cen, who failed at the Dragon Gate: a lanky examination candidate in a scholar's hat and spectacles, clutching the essay that did not pass, for the seventh time.
Run: blender --background --python art/characters/scholar_cen.py  ->  assets/characters/scholar_cen.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/scholar_cen.glb", {
    "age": 0.4, "build": 0.85, "brow": 0.95, "eye_size": 1.1,
    "robe": "6a5a8a", "trim": "e8e0d0", "inner": "f4f0e8", "sash": "c8a860", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "2a2a3a", "hat": "scholar", "hat_col": "1a1a24", "props": ["scroll", "spectacles"], "pose": "hold_l",
})
