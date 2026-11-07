"""The hermit of the Void Rift: violet hooded robes scattered with starlight, a long grey beard.
Run: blender --background --python art/characters/void_hermit.py  ->  assets/characters/void_hermit.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/void_hermit.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.7, "beard_len": 1.2,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("fly_whisk", {"side": 1, "hair": "d8d0f0"})],
    "robe": "3a2a6a", "trim": "b8a0ff", "inner": "d8d0f0", "sash": "201848", "hair": "c8c8d8", "hair_style": "bald", "eyes": "c8a0ff",
    "beard": True, "beard_col": "d8d8e8", "hat": "hood", "hat_col": "2a1e50", "staff": True, "staff_gem": "c0a0ff", "embroidery": "b8a0ff",
})
