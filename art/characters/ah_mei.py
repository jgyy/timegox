"""Ah Mei the Lantern-Maker (Part IX): a young lantern-maker of the Dawn Market at Yanggu, who sells
paper lanterns to the pilgrims who climb the Valley of Sunrise by night.  A vermilion work robe
with lantern-gold trims under a cream apron, hair in twin buns tied with gold ribbons, freckles,
a lit paper lantern in her hand and a carrying pole of unsold lanterns over her shoulder.
Run: blender --background --python art/characters/ah_mei.py  ->  assets/characters/ah_mei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()

PAPER = ("e84a3a", "f0b040", "e86a8a")


def lantern_pole(b, rig, o, tor):
    """A bamboo carrying pole over the right shoulder with three small paper lanterns hanging from
    its back end: the stock she could not sell, because there has been no night to sell it in."""
    bone = {"chest": 0.7, "upper_arm.R": 0.3}
    front = V(-0.2, 1.36, 0.34)
    back = V(-0.2, 1.56, -0.62)
    b.tube([front, V(-0.2, 1.5, 0.0), back], [0.012, 0.013, 0.011], "b8a060", cls=kit.WOOD, bone=bone, seg=8)
    for k in range(4):
        q = front.lerp(back, 0.1 + 0.27 * k)
        b.tube([q + V(0, 0.006, 0), q - V(0, 0.006, 0)], [0.015, 0.015], "8a7040", cls=kit.WOOD, bone=bone, seg=8, cap0=False, cap1=False)
    for k in range(3):
        top = V(-0.2, 1.5, -0.2).lerp(back, 0.2 + 0.36 * k)
        drop = 0.12 + 0.05 * (k % 2)
        b.tube([top, top + V(0, -drop, 0)], [0.002, 0.002], "5a3a20", cls=kit.CLOTH, bone=bone, seg=3)
        c = top + V(0, -drop - 0.09, 0)
        col = PAPER[k]
        b.lathe(c, [(0.015, -0.075), (0.055, -0.06), (0.068, 0.0), (0.055, 0.06), (0.015, 0.075)], col, cls=kit.CLOTH, bone=bone, seg=14, folds=(9, 0.05, 0.0))
        for y in (-0.075, 0.075):
            b.lathe(c + V(0, y, 0), [(0.022, -0.008), (0.022, 0.008)], "5a3a20", cls=kit.WOOD, bone=bone, seg=10)
        b.tube([c + V(0, -0.085, 0), c + V(0, -0.15, 0)], [0.005, 0.002], "c02020", cls=kit.CLOTH, bone=bone, seg=4)


person.export_person("characters/ah_mei.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.18, "eye_size": 1.32, "jaw": 0.88, "build": 0.95, "smile": True, "marks": "freckles",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("lantern", {"col": "e8503a", "glow": "ffd070"}), ("apron", {"col": "efe4cc", "strap": "a06a3a"})], "pose": "hold_l",
    "extra": lantern_pole,
    "robe": "c8442e", "trim": "f0c060", "inner": "f8f0e0", "sash": "f0c060", "hair": "1a1210", "hair_style": "twin_buns",
    "ribbon": "ffc860", "pin": "f0c060", "eyes": "4a2a1a", "lip": "d86a5a", "embroidery": "f8d070", "collar2": "e89048",
    "pants": "6a2a20", "boots": "3a2418", "robe_len": "short", "wraps": "efe4cc",
})
