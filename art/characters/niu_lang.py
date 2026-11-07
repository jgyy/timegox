"""Niu Lang the Cowherd (Part VIII): a young herdsman of the Starfall Ferry who married the Weaver
Star and was parted from her by the Silver River.  A plain hemp robe under a straw rain cape, a
broad straw hat pushed back, a bamboo flute at his lips.
Run: blender --background --python art/characters/niu_lang.py  ->  assets/characters/niu_lang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/niu_lang.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.25, "build": 1.06, "jaw": 1.02, "skin": "e8c0a0",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["straw_cape", "flute"], "pose": "flute",
    "robe": "8a7a5a", "trim": "c8b890", "inner": "e8dcc0", "sash": "4a3a2a", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "5a3a20", "pants": "5a4a30", "boots": "3a2a1a", "hat": "straw", "hat_col": "c8a868", "embroidery": "c8b890",
    "collar2": "6a5a3a", "white_sole": False,
})
