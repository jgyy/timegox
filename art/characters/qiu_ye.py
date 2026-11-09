"""Qiu Ye, the second son of a ruined house of Cloudfoot (a fated encounter, scripts/fate.gd): the
proud outer disciple the sweeper outpaced; a high tail under a silver crown, dark green and silver silks and his
grandfather's jian.
Run: blender --background --python art/characters/qiu_ye.py  ->  assets/characters/qiu_ye.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/qiu_ye.glb", {
    "fem": False, "age": 0.0, "build": 1.0, "jaw": 1.0, "brow": 1.05, "stern": True,
    "hair_style": "topknot", "hair": "121418", "guan": "c8ccd8", "pin": "a8acb8", "jade": "8ad8c8",
    "robe": "2e5a48", "trim": "c8ccd8", "inner": "eef0ec", "sash": "18281f", "pants": "1a2a22", "boots": "1a1c20",
    "eyes": "2a3a34", "sword": True, "embroidery": "c8ccd8",
})
