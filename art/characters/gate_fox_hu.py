"""Old Hu the Gate-Fox (Part XI): a grey celestial fox who has kept the lesser gate of the sky for
two thousand years, mostly asleep and never once fooled.  Grey fox ears, two grey tails tipped
with white hanging behind, a grey beard, a gatekeeper's dark robes trimmed with bronze, and a
lantern for the night watch.
Run: blender --background --python art/characters/gate_fox_hu.py  ->  assets/characters/gate_fox_hu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gate_fox_hu.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.8, "brow": 1.25, "build": 0.95, "beard": True, "beard_col": "d4d2cc", "beard_len": 0.9,
    # race (art/lib/race.py): an old fox's grey ears and two tails
    "ears": "fox", "ear_col": "8c8a90", "ear_inner": "e4dcd4", "ear_tip": "38363c",
    "tails": 2, "tail_col": "8e8c92", "tail_tip": "f2f0ee",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("lantern", {"col": "e8a040", "frame": "4a3020", "glow": "ffd070"})], "pose": "hold_l",
    "robe": "2c3040", "trim": "b08a50", "inner": "e8e2d4", "sash": "6a4a2a", "collar2": "8a6a3a",
    "hair": "a8a6aa", "hair_style": "topknot", "guan": "b08a50", "eyes": "c89030",
})
