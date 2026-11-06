"""The Gatekeeper of the Celestial Gate: white and gold court robes, a crown, a ringed staff.
Run: blender --background --python art/characters/gate_keeper.py  ->  assets/characters/gate_keeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gate_keeper.glb", {
    "robe": "f0ece0", "trim": "e0b040", "inner": "ffffff", "sash": "c89830", "hair": "2a2a3a", "hair_style": "topknot", "eyes": "e0a030",
    "crown": True, "staff": True, "staff_gem": "fff0a0", "beard": True, "beard_col": "3a3a48", "embroidery": "f0c850", "stern": True,
})
