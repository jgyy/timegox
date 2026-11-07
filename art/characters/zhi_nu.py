"""Zhi Nu, the Weaver Star (Part VIII): the Jade Emperor's granddaughter who weaves the clouds and
the sunset, parted from the Cowherd by the Silver River.  Layered robes the blue of the night sky
trimmed with silver, long hair crowned with seven stars, ribbons of cloud, a shuttle in her hand.
Run: blender --background --python art/characters/zhi_nu.py  ->  assets/characters/zhi_nu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhi_nu.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.36, "jaw": 0.86, "lip": "e07a90", "hair_len": 0.72,
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cloud", "brocade_col": "c8d0ff",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("shuttle", {"col": "e8e8ff"}), "star_crown"],
    "robe": "3a4a9a", "trim": "e8ecff", "inner": "f4f6ff", "sash": "c8d0ff", "hair": "14142a", "hair_style": "long",
    "eyes": "6a8af0", "ribbon": "c8d8ff", "pin": "e8f0ff", "embroidery": "f0f0ff", "collar2": "8090e0", "sleeve_w": 1.15,
    "glow_eyes": False, "flare": 1.15,
})
