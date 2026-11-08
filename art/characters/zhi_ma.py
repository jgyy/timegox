"""Zhi Ma the Paper-Horse Maker of Youdu (Part XI): a shade craftsman who folds and paints the paper
horses, houses and servants that the living burn for their dead, so they arrive in the Dark
Capital with something to ride.  Pale grey-blue skin, glowing pale eyes, the undyed white of
mourning, a brush in one hand and a little paper horse in the other.
Run: blender --background --python art/characters/zhi_ma.py  ->  assets/characters/zhi_ma.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402  (first: it loads bpy, which provides mathutils)
import accessory as acc  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()
PAPER, RED, INK = "f4f1e8", "c8302a", "2a2a30"


def paper_horse(b, rig, o, tor):
    """A paper horse standing on his raised left palm: a folded white body and legs, a red saddle
    cloth and red paper mane and tail, eyes and bridle painted in ink."""
    S = 1.5
    c = acc.held_l() + V(0.0, 0.115, 0.045)
    bone = "hand.L"

    def at(x, y, z):
        return c + V(x, y, z) * S

    b.superquad(c, (0.052 * S, 0.024 * S, 0.021 * S), PAPER, e=0.35, cls=kit.CLOTH, bone=bone, seg=10, rings=6)
    b.superquad(at(0.0, 0.02, 0.0), (0.026 * S, 0.008 * S, 0.024 * S), RED, e=0.3, cls=kit.CLOTH, bone=bone, seg=8, rings=5)
    for sx in (1, -1):
        for sz in (1, -1):
            top = at(0.036 * sx, -0.012, 0.012 * sz)
            b.tube([top, top + V(0.004 * sx, -0.05, 0.0) * S], [0.006 * S, 0.0045 * S], PAPER, cls=kit.CLOTH, bone=bone, seg=5)
            b.ball(top + V(0.004 * sx, -0.052, 0.0) * S, 0.005 * S, INK, cls=kit.CLOTH, bone=bone, seg=5, rings=3)
    b.tube([at(0.038, 0.012, 0.0), at(0.058, 0.045, 0.0), at(0.066, 0.064, 0.0)], [0.014 * S, 0.012 * S, 0.011 * S], PAPER, cls=kit.CLOTH, bone=bone, seg=6)
    hd = at(0.082, 0.064, 0.0)
    b.superquad(hd, (0.026 * S, 0.011 * S, 0.01 * S), PAPER, e=0.4, cls=kit.CLOTH, bone=bone, rot=(0.0, 0.0, -0.35), seg=8, rings=5)
    for s in (1, -1):
        b.ball(hd + V(-0.004, 0.006, 0.0095 * s) * S, 0.0028 * S, INK, cls=kit.CLOTH, bone=bone, seg=5, rings=3, mat=kit.MAT_PLAIN)
        b.cone(hd + V(-0.016, 0.016, 0.006 * s) * S, 0.004 * S, 0.014 * S, PAPER, cls=kit.CLOTH, bone=bone, seg=4)
    b.ribbon([at(0.034, 0.03, 0.0), at(0.05, 0.058, 0.0), at(0.062, 0.08, 0.0)], [0.004 * S, 0.006 * S, 0.004 * S], (0, 0, 1), RED, bone=bone)
    b.ribbon([at(-0.05, 0.012, 0.0), at(-0.07, -0.01, 0.0), at(-0.078, -0.045, 0.0)], [0.006 * S, 0.007 * S, 0.003 * S], (0, 0, 1), RED, bone=bone)
    rein = [hd + V(0.012, -0.006, 0.0) * S, at(0.03, 0.03, 0.0)]
    for s in (1, -1):
        b.tube([q + V(0, 0, 0.011 * s) * S for q in rein], [0.0014, 0.0014], INK, cls=kit.CLOTH, bone=bone, seg=3)
    # a paper ruff of folded petals round the base of the neck
    for k in range(6):
        a = k / 6 * 2.0 * math.pi
        q = at(0.04, 0.016, 0.0) + V(0.0, math.cos(a) * 0.014, math.sin(a) * 0.016) * S
        b.leaf(q, q + V(0.012, math.cos(a) * 0.012, math.sin(a) * 0.014) * S, 0.007 * S, RED, cls=kit.CLOTH, bone=bone, n=3)


person.export_person("characters/zhi_ma.glb", {
    # face and build (see art/lib/face.py, garment.py): a shade's pale skin and glowing eyes
    "fem": False, "age": 0.5, "build": 0.92, "brow": 1.05, "skin": "ccd6de", "glow_eyes": True,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("brush", {"col": "3a2a1a"})], "pose": "hold_l", "extra": paper_horse,
    # the undyed white of mourning: keep the hemp greys chosen here
    "monotone": True,
    "robe": "ecebe4", "trim": "c6c2b6", "inner": "f8f8f4", "sash": "a6a08e", "pants": "d6d2c8", "boots": "8a867a",
    "collar2": "d6d2c6", "hair": "2a2a30", "hair_style": "topknot", "guan": "a6a08e", "pin": "8a867a", "eyes": "d0f0ff",
})
