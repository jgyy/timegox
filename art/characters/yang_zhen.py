"""Yang Zhen (Part XXXIV): the Confucius of West of the Passes, on his way to the governorship of Donglai, who was
brought ten catties of gold by night and said that Heaven knew, the spirits knew, he knew and the giver knew. A spare
man of fifty in a travelling robe of plain dark blue gone pale at the seams, a grey beard kept short, a roll of
somebody's petition in his hand; he owns nothing that shines.
Run: blender --background --python art/characters/yang_zhen.py  ->  assets/characters/yang_zhen.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yang_zhen.glb", {"age": 0.6, "build": 0.94, "jaw": 0.98, "brow": 1.15, "stern": True, "skin": "d8bc9c",
    "robe": "34425a", "trim": "8a8e96", "inner": "e8e4d8", "sash": "20242e", "pants": "2e3442", "boots": "2a2622",
    "hair": "8a8884", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.3, "beard_col": "a8a6a0", "brow_col": "8a8884",
    "props": [("scroll", {"paper": "ece0bc", "rod": "3a2a20"})], "pose": "hold_l"})
