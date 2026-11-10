"""Mozi (Mo Di), who asks of every thing what it is good for (Part XIX, the Hundred Works release): a gaunt, dark man in
plain black hemp cut short for walking, his legs bound with strips of cloth, bare-headed, with a staff worn smooth.
Run: blender --background --python art/characters/mo_di.py  ->  assets/characters/mo_di.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/mo_di.glb", {"fem": False, "age": 0.6, "build": 0.9, "jaw": 0.95, "cheek": 0.85, "brow": 1.2, "stern": True, "skin": "a87850",
    "robe": "26262a", "trim": "4a4a50", "inner": "8a8478", "sash": "5a4a3a", "pants": "2a2a2e", "boots": "8a7a50", "hair": "1a1a1c", "hair_style": "topknot", "eyes": "2a2018",
    "beard": True, "beard_len": 0.3, "beard_col": "2a2a2c", "robe_len": "short", "wraps": "8a8070", "staff": True, "staff_gem": "5a4a3a"})
