"""Hu Qingyi, the Ninth-Tail Matron of the Moon-Fox Pavilion (Part XI): eldest of the celestial
foxes who keep the gate of the sky, nine thousand years in the Way and every one of them shown in
a tail.  White fox ears tipped with silver, nine white tails fanned behind her like a moonlit
cloud, silver-white hair, robes of violet and silver with cloud brocade, and a folding fan.
Run: blender --background --python art/characters/hu_qingyi.py  ->  assets/characters/hu_qingyi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hu_qingyi.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.3, "jaw": 0.85, "cheek": 1.1, "lip": "d07a8a", "hair_len": 0.55, "build": 0.94,
    # race (art/lib/race.py): a celestial fox's ears and nine tails
    "ears": "fox", "ear_col": "f4f2f6", "ear_inner": "f2d8e0", "ear_tip": "aab0c4",
    "tails": 9, "tail_col": "f2f0f5", "tail_tip": "c4cadc",
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cloud", "brocade_col": "b8a8e0",
    # signature props (art/lib/accessory.py)
    "props": [("folding_fan", {"col": "f6f2fa", "ribs": "4a3a5a", "painted": "8a70b8"})],
    "robe": "6a4c9a", "trim": "eceaf6", "inner": "faf8ff", "sash": "c8d4ec", "hair": "e8e6ee", "hair_style": "long",
    "eyes": "9a72c8", "pin": "c8d0e8", "embroidery": "e4e4f4", "collar2": "a8b8e0", "flare": 1.12,
})
