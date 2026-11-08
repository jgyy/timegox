"""Tide-Singer Hai Ge of Tearwater (Part XI): a Jiaoren who plays the tides of the sea under the
earth in and out on a bone flute, so that the pearl beds breathe.  Deep-blue fins and scales,
deep blue robes woven with waves at the hem and trimmed with silver-white, his dark hair tied up,
and his flute raised to play.
Run: blender --background --python art/characters/hai_ge.py  ->  assets/characters/hai_ge.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hai_ge.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "eye_size": 1.2, "jaw": 0.96, "build": 0.98,
    # race (art/lib/race.py): the Jiaoren's fins and scales
    "ears": "fin", "ear_col": "2a5ca8", "ear_inner": "b8d8fa", "scales": "2a4c96",
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "waves", "brocade_col": "4a78c0",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("flute", {"col": "e8e0cc"})], "pose": "flute",
    "robe": "1e3a78", "trim": "d8e4f0", "inner": "eef2fa", "sash": "8ab8c8", "collar2": "8ab8c8",
    "hair": "14223a", "hair_style": "topknot", "guan": "c8d4e4", "eyes": "3a7ad0", "embroidery": "c8d8f0",
})
