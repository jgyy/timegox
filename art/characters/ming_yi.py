"""Lantern-Magistrate Ming Yi of Youdu (Part XI): a shade who has judged the lanterns of the Dark
Capital for nine hundred years, deciding which of the dead may carry a light down the Yellow
Springs and which must walk in the dark.  Pale grey-blue skin, glowing pale eyes, a magistrate's
robes of black and silver with a rank badge, a scholar's hat, and a lantern of cold white fire.
Run: blender --background --python art/characters/ming_yi.py  ->  assets/characters/ming_yi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ming_yi.glb", {
    # face and build (see art/lib/face.py, garment.py): a shade's pale skin and glowing eyes
    "fem": False, "age": 0.4, "brow": 1.15, "stern": True, "skin": "c8d4dc", "glow_eyes": True,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("lantern", {"col": "dfe8ee", "frame": "1a1a22", "glow": "c8f0ff"})], "pose": "hold_l", "badge": "14141c",
    "robe": "1a1a22", "trim": "c0c8d4", "inner": "e8ecf0", "sash": "8a96a8", "collar2": "5a6474",
    "hair": "1a1a22", "hair_style": "topknot", "hat": "scholar", "hat_col": "0e0e12", "eyes": "c8f0ff", "embroidery": "d0d8e4",
})
