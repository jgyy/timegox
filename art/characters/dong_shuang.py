"""Dong Shuang, Maid of the Jasper Pool (Part VIII): handmaiden of the Queen Mother of the West,
keeper of the peaches of immortality.  A jade-green robe over pale silk, hair in a double bun with
jade pins, a flowering peach branch in her hand.
Run: blender --background --python art/characters/dong_shuang.py  ->  assets/characters/dong_shuang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/dong_shuang.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.3, "jaw": 0.88, "build": 0.94,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["peach_branch"], "pose": "hold_l",
    "robe": "4a9a7a", "trim": "f0f8f0", "inner": "f8fcf4", "sash": "e0a0b0", "hair": "1a1418", "hair_style": "twin_buns",
    "eyes": "3a7a5a", "pin": "6af0b0", "embroidery": "f8e0a0", "collar2": "8ad0b0", "crown": False,
})
