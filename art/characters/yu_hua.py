"""Feather-Mother Yu Hua of Featherfall (Part XI): eldest of the Yumin, who remembers when the
Feathered Folk still flew between the branches of the world tree and the stars.  Great white
wings with gold-tipped primaries, a tall golden crest, white hair in a coil, white and gold robes
woven with clouds, and a staff crowned with a sky-blue gem.
Run: blender --background --python art/characters/yu_hua.py  ->  assets/characters/yu_hua.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yu_hua.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.8, "eye_size": 1.12, "jaw": 0.9, "lip": "c88a86",
    # race (art/lib/race.py): great wings and a tall crest
    "wings": "f6f5f0", "wing_tip": "e2b844", "wing_span": 1.18,
    "crest": "e8c450", "crest_tip": "fff0b8", "crest_len": 0.32, "crest_up": 0.8,
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cloud", "brocade_col": "e6d49a",
    # her staff (garment.staff)
    "staff": True, "staff_gem": "a8d8ff",
    # a white robe: keep the golds chosen here
    "monotone": True,
    "robe": "f3f1ea", "trim": "dcb24c", "inner": "fffdf6", "sash": "d4a83a", "pants": "c8b88e", "boots": "6a5a40",
    "collar2": "e6cf8e", "hair": "f0eee8", "hair_style": "bun", "pin": "e2b844", "eyes": "8a6a3a", "embroidery": "e8c860",
})
