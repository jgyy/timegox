"""Lady Hao (Part XXIII): Fu Hao of Shang, queen, diviner and general, who led thirteen thousand against the Qiang and was buried with her axe: a woman
of forty in dark red with bronze-green trims, a short cape for the chariot, her hair bound up and pinned with bone.
Run: blender --background --python art/characters/fu_hao.py  ->  assets/characters/fu_hao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fu_hao.glb", {"fem": True, "age": 0.35, "build": 1.04, "lip": "a04a44", "eye_size": 1.05, "hair_len": 0.3, "scale": 1.05, "stern": True, "smile": False, "skin": "dcc4a8",
    "robe": "8a2a2a", "trim": "5a8a6a", "inner": "e8dcc8", "hair": "1a1614", "hair_style": "bun",
    "eyes": "4a3a2a", "sash": "5a8a6a", "ribbon": "c8a050", "boots": "3a2420", "pants": "4a1c1c",
    "jade": "5a8a6a", "pin": "e8e0d0", "sleeve_w": 1.1, "cape": "3a1a18", "brocade": "cloud", "brocade_col": "a84a3a"})
