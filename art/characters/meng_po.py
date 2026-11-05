"""Meng Po of the Naihe Bridge (Part VI): the old woman who brews the soup of forgetting, in plum and gold with silver hair in a bun.
Run: blender --background --python art/characters/meng_po.py  ->  assets/characters/meng_po.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/meng_po.glb", {
    "robe": "6a3a5a", "trim": "e0b860", "inner": "f0e0d0", "sash": "3a1a30", "hair": "d8d4dc", "hair_style": "bun",
    "pin": "e0b860", "eyes": "6a5a4a", "staff": True, "staff_gem": "ffd890", "collar2": "a05070", "embroidery": "f0d080",
})
