"""The Widow of Mount Tai (Part XXV): the woman Confucius heard weeping by a grave at the foot of Mount Tai, whose husband's father, husband and
son had each been killed by the tiger, and who would not leave because there was no harsh government there: a woman of fifty in undyed mourning hemp
with a white headcloth and a grey bun, who has done her crying.
Run: blender --background --python art/characters/tai_widow.py  ->  assets/characters/tai_widow.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tai_widow.glb", {"fem": True, "age": 0.6, "build": 0.94, "jaw": 0.98, "brow": 1.05, "stern": True, "skin": "d4b494",
    "robe": "e4dfd0", "trim": "b8b09a", "inner": "f0ece0", "sash": "b0a888", "hair": "8a8684", "hair_style": "bun", "hat": "headcloth", "hat_col": "ece8dc", "hat_trim": "b8b09a",
    "eyes": "3a3028", "sleeve_w": 1.0})
