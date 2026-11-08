"""Rain-Minister Ao Run of the Rain Ministry (Part XI): a dragon-kin official of the Nine Heavens who
keeps the ledger of how much rain falls on every county below, to the last drop.  Jade antlers
through his scholar's hat, blue-green scales on his cheekbones and the backs of his hands, a
dragon's long whiskers, slit golden eyes, deep-teal official robes woven with waves at the hem, a
rank badge, and the ledger of rain.
Run: blender --background --python art/characters/ao_run.py  ->  assets/characters/ao_run.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ao_run.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.45, "brow": 1.15, "jaw": 1.0, "build": 1.04, "slit_eyes": True,
    # race (art/lib/race.py): the dragon's antlers, scales and whiskers
    "horns": "antler", "horn_col": "5aae92", "scales": "3a8c8a", "whiskers": "6a9a8e",
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "waves", "brocade_col": "4a9890",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("ledger", {"cover": "1a3a3a", "paper": "eee4c8"})], "pose": "hold_l",
    "robe": "1e5a58", "trim": "c8e2da", "inner": "eef6f2", "sash": "c8a048", "hair": "142224", "hair_style": "topknot",
    "eyes": "d8b040", "hat": "scholar", "hat_col": "162224", "badge": "1a3a3a", "embroidery": "c8e0d0", "collar2": "d8b868",
})
