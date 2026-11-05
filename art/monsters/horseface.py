"""Horse-Face, Ox-Head's brother and fellow runner of the Ten Courts (Part VI): a long equine head
with a black mane and lateral eyes over the same court livery; carries a halberd.  Cloth is tinted
per enemy.  1.4x scale.
Run: blender --background --python art/monsters/horseface.py  ->  assets/monsters/horseface.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("monsters/horseface.glb", {
    "robe": "a0a0a0", "trim": "e0e0e0", "inner": "707070", "sash": "4a4a4a", "pants": "505050", "boots": "2a2a2a",
    "sleeve": "909090", "beast_head": "horse", "head_col": "6a4030", "muzzle_col": "a08070", "hair": "141010", "eyes": "ffb020",
    "armor": True, "metal": "3a3440", "halberd": True, "tint_cloth": True, "scale": 1.4, "head_scale": 1.0,
    "embroidery": "c8a040", "folds": 10,
})
