"""Cai Yong (Part XXXVII): the scholar and musician of the Later Han who heard a paulownia log cracking under a cook's
pot in Wu, knew it for fine timber, pulled it out and made the Scorched-Tail Qin (Book of the Later Han). A stooped,
long-handed man of fifty-five in a scholar's plum-grey robe with one sleeve singed, his head carried a little to one
side, thin greying hair in a scholar's knot and a wisp of beard.
Run: blender --background --python art/characters/cai_yong.py  ->  assets/characters/cai_yong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cai_yong.glb", {"age": 0.62, "build": 0.88, "jaw": 0.94, "brow": 1.05, "smile": True, "skin": "d4b898", "robe": "6a5a7a", "trim": "2e2630", "inner": "e4e0d4", "sash": "3a3044", "pants": "545060", "shoes": "sandals", "hair": "5a5652", "hair_style": "topknot", "eyes": "2a221a", "beard": True, "beard_len": 0.5, "beard_col": "8a8680", "brow_col": "5a5652", "robe_len": "long"})
