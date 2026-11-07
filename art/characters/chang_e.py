"""Chang'e of the Moon Palace (Part IX): the lady who swallowed the elixir of immortality so that a
thief would not have it, and has walked the moon round the sky alone ever since.  Layered robes of
moon-white and pale silver-blue with cloud brocade, a flowing mantle, long black hair with silver
ribbons and a sprig of golden osmanthus, and the Jade Rabbit held in her arms.
Run: blender --background --python art/characters/chang_e.py  ->  assets/characters/chang_e.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()

FUR, FUR2, EAR_IN = "f6f8ff", "dce4f4", "f0b8c8"


def rabbit_and_sprig(b, rig, o, tor):
    """The Jade Rabbit cradled against her chest in both arms (the hold_both pose brings the hands
    together here), and a sprig of osmanthus in her hair."""
    bone = "chest"
    c = V(0.0, 1.15, 0.31)
    b.ellipsoid(c, (0.075, 0.068, 0.095), FUR, cls=kit.HAIR, bone=bone, seg=18, rings=12, col2=FUR2)
    head = c + V(0.0, 0.075, 0.07)
    b.ellipsoid(head, (0.05, 0.047, 0.055), FUR, cls=kit.HAIR, bone=bone, seg=16, rings=10, col2=FUR2)
    b.ellipsoid(head + V(0.0, -0.012, 0.048), (0.022, 0.016, 0.014), FUR2, cls=kit.HAIR, bone=bone, seg=10, rings=6)
    b.ball(head + V(0.0, -0.004, 0.06), 0.006, "e08a9a", cls=kit.SKIN, bone=bone, seg=6, rings=4)
    for s in (1, -1):
        b.ball(head + V(0.028 * s, 0.012, 0.04), 0.009, "c0203a", cls=kit.CRYSTAL, bone=bone, seg=8, rings=5)
        root = head + V(0.022 * s, 0.035, -0.01)
        ear = [root, root + V(0.012 * s, 0.07, -0.03), root + V(0.02 * s, 0.13, -0.075)]
        b.tube(ear, [(0.016, 0.007), (0.02, 0.008), (0.006, 0.004)], FUR, cls=kit.HAIR, bone=bone, seg=8, up=(0, 0, 1))
        b.tube([q + V(0, 0, 0.004) for q in ear[:2]] + [ear[2] + V(0, -0.02, 0.012)], [(0.009, 0.003), (0.012, 0.003), (0.003, 0.002)], EAR_IN, cls=kit.SKIN, bone=bone, seg=6, up=(0, 0, 1))
        # forepaws resting on her wrist, hind feet tucked under
        b.ellipsoid(c + V(0.04 * s, -0.03, 0.08), (0.016, 0.014, 0.024), FUR, cls=kit.HAIR, bone=bone, seg=8, rings=5)
        b.ellipsoid(c + V(0.05 * s, -0.055, -0.02), (0.022, 0.018, 0.045), FUR2, cls=kit.HAIR, bone=bone, seg=8, rings=5)
    b.ball(c + V(0.0, 0.01, -0.095), 0.028, "ffffff", cls=kit.HAIR, bone=bone, seg=10, rings=6)
    # a sprig of osmanthus behind the left ear: dark glossy leaves and clusters of tiny gold flowers
    sp = V(0.11, 1.8, -0.06)
    for k in range(4):
        a = -0.6 + k * 0.45
        b.leaf(sp, sp + V(0.06 * math.cos(a), 0.05 * math.sin(a) + 0.02, -0.03), 0.018, "3a6a5a", cls=kit.FOLIAGE, bone="head", col_tip="5a8a70", n=4)
    for k in range(9):
        a = k * 2.4
        q = sp + V(0.02 * math.cos(a), 0.015 + 0.01 * math.sin(a * 1.3), 0.02 * math.sin(a))
        b.ball(q, 0.0065, "f8c048", cls=kit.CRYSTAL, bone="head", seg=6, rings=4, mat=kit.MAT_GLOW if k % 3 == 0 else kit.MAT_TOON)


person.export_person("characters/chang_e.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.36, "jaw": 0.84, "lip": "d87a8a", "hair_len": 0.82, "build": 0.94,
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cloud", "brocade_col": "d4deff",
    # the rabbit is held in both arms (person.POSES)
    "pose": "hold_both", "extra": rabbit_and_sprig,
    "robe": "e8eef8", "trim": "b8c8f0", "inner": "ffffff", "sash": "a8b8e8", "hair": "14141e", "hair_style": "long",
    "eyes": "5a6aa0", "ribbon": "c8d8ff", "pin": "e8f0ff", "embroidery": "f0d880", "collar2": "c8d0f0",
    "cape": "dce6ff", "flare": 1.2, "glow_eyes": False,
})
