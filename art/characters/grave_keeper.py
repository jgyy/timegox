"""The Gravekeeper of the Graveyard of Sword Saints: ash-grey mourning robes, a hood and a lantern-staff.
Run: blender --background --python art/characters/grave_keeper.py  ->  assets/characters/grave_keeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/grave_keeper.glb", {
    "robe": "5a5a60", "trim": "c8c8c0", "inner": "e8e4dc", "sash": "2a2a30", "hair": "8a8a90", "hair_style": "bun", "eyes": "8a9ab0",
    "hat": "hood", "hat_col": "3a3a42", "staff": True, "staff_gem": "a0f0e0", "beard": True, "beard_col": "a8a8b0", "embroidery": "c8c8c0",
})
