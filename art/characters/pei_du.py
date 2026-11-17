"""Pei Du as a young man (Part XXXIV): a poor scholar whom a physiognomist had told he would starve, who found three
jade belts on the rail of the Xiangshan Temple and waited there for whoever had left them (the Tang Zhiyan). A slight
man of twenty-five in a scholar's robe of faded grey-green let down at the hem, thin in the face; he holds nothing,
because what he is minding is not his.
Run: blender --background --python art/characters/pei_du.py  ->  assets/characters/pei_du.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/pei_du.glb", {"age": 0.15, "build": 0.88, "jaw": 0.94, "brow": 1.0, "smile": True, "skin": "e0c8a8",
    "robe": "7a8a78", "trim": "4a5648", "inner": "ece8dc", "sash": "3a4238", "pants": "5a6456", "boots": "2e2a24",
    "hair": "16120e", "hair_style": "topknot", "eyes": "2a2018"})
