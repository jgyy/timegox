"""Hu Xiao, a Fox of One Tail (towns): the youngest of the celestial foxes at the Gate of Heaven, orange-eared, with one bushy tail and a grin.
Run: blender --background --python art/characters/hu_xiao.py  ->  assets/characters/hu_xiao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hu_xiao.glb", {
    "fem": False, "age": 0.0, "eye_size": 1.42, "jaw": 0.84, "build": 0.86, "scale": 0.8, "head_scale": 1.12, "smile": True, "ahoge": True,
    "ears": "fox", "ear_col": "e0782a", "ear_inner": "fbe6d6", "ear_tip": "3a2018",
    "tails": 1, "tail_col": "e0782a", "tail_tip": "fbf6ee", "robe_len": "short",
    "robe": "e0782a", "trim": "fff0dc", "inner": "fff8ee", "sash": "3a8a84", "hair": "c8501e", "hair_style": "short", "eyes": "e0a030", "pants": "8a4a2a"
})
