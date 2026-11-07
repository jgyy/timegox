"""The Echo of Nuwa in the Primordial Chaos: luminous robes, crowned, with five-coloured ribbons.
Run: blender --background --python art/characters/nuwa_echo.py  ->  assets/characters/nuwa_echo.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/nuwa_echo.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.36, "hair_len": 0.7,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["five_colour_stone"], "pose": "hold_l",
    "robe": "fff0d8",
    "trim": "f0c850",
    "hair": "2a1a30",
    "hair_style": "long",
    "crown": True,
    "eyes": "c060ff",
    "sash": "c04050",
    "ribbon": "ff70d0",})
