"""Duke Huan of Cai, Who Was Not Ill (Part XXVI): the duke of the Han Feizi who told Bian Que four times that he was not
ill, and died of it; a proud man past his middle years in an aubergine court robe worked with gold clouds, a gold crown on
his topknot, a thin moustache and beard, grey to the lips.
Run: blender --background --python art/characters/duke_huan.py  ->  assets/characters/duke_huan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/duke_huan.glb", {"fem": False, "age": 0.55, "build": 1.08, "jaw": 1.04, "brow": 1.15, "stern": True, "smile": False, "skin": "c4b8a4",
    "robe": "5e3452", "trim": "e0c060", "inner": "f0e8d8", "sash": "e0c060", "pants": "2e1a28", "boots": "1e1418", "brocade": "cloud", "brocade_col": "8a5a7a",
    "hair": "2a2228", "hair_style": "topknot", "crown": True, "eyes": "3a2a2a", "beard": True, "beard_len": 0.3, "beard_col": "2a2228",
    "sleeve_w": 1.2})
