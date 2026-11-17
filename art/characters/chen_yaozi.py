"""Chen Yaozi (Part XXXIII): the Duke of Kangsu, the best archer of his day and well aware of it, who hit eight or
nine shots in ten in his own garden and asked an old oil seller why he only nodded. A broad man of thirty-five in
a court robe of dark red kilted up for shooting, bracers on both arms, a quiver strap across the chest and the
look of somebody who has never been told he was merely good.
Run: blender --background --python art/characters/chen_yaozi.py  ->  assets/characters/chen_yaozi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/chen_yaozi.glb", {"age": 0.35, "build": 1.1, "jaw": 1.06, "brow": 1.2, "stern": True, "skin": "dcc0a0",
    "robe": "7a2a26", "trim": "d8b860", "inner": "f0e8d8", "sash": "2a2a34", "pants": "3a2a2a", "boots": "241c1c",
    "hair": "141214", "hair_style": "topknot", "eyes": "241c16", "beard": True, "beard_len": 0.3, "beard_col": "1a1618",
    "bracers": "3a2a20", "strap": "3a2a20", "robe_len": "short", "embroidery": "d8b860"})
