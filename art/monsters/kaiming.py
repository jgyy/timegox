"""Kaiming (new in Part VIII): Kaiming, Beast of the Nine Gates, who guards the gates of Kunlun - in
the Classic of Mountains and Seas a tiger the size of a temple with nine human faces, one watching
each gate.  The feline body of art/lib/feline.py (sculpted in clay, its stripes painted into the
greys) with a crescent of eight stern human faces rising round its own like a mane - each a
sculpted face with a brow, cheekbones, a nose, lips, eyes under their lids and a topknot - with
tongues of flame between them, gilded plates on its shoulders and a gate-ring through its nose.
Tinted by the game per enemy; the faces, gold and flames keep their colours.
Clips: the tiger's idle, walk, attack (a pounce), hurt, die and roar (cast).
Run: blender --background --python art/monsters/kaiming.py  ->  assets/monsters/kaiming.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import feline  # noqa: E402
from kit import HAIR, MAT_GLOW, MAT_PLAIN, METAL, SKIN, V, darken, mix  # noqa: E402
from sculpt import blob3, morph_sphere, smooth  # noqa: E402

kit.reset()
creature.realtime()
b, r, hf, clips = feline.build("kaiming")
SKINC = (0.9, 0.76, 0.64)
HAIRC = "1a1418"


def face(c, fwd, k, bone):
    """A small stern human face looking along `fwd`: brow ridge, eye sockets, cheekbones, a nose
    with nostril wings, lips and a chin, sculpted on a deformed sphere; eyes under lids, brows,
    and hair drawn up into a topknot."""
    M = A.frame_m(fwd, (0, 1, 0))

    def shape(d):
        p = V(d.x * 0.062, d.y * 0.08, d.z * 0.066) * k
        # the jaw narrows to the chin
        p.x *= 1.0 - 0.32 * smooth(0.0, -1.0, d.y)
        off = 0.0
        q = p / k
        off += 0.008 * blob3(q, (0, 0.02, 0.06), (0.04, 0.012, 0.02))           # brow ridge
        off += 0.014 * blob3(q, (0, -0.005, 0.068), (0.01, 0.022, 0.02))       # nose
        off += 0.006 * blob3(q, (0, -0.03, 0.062), (0.016, 0.006, 0.012))      # upper lip
        off += 0.005 * blob3(q, (0, -0.06, 0.055), (0.018, 0.012, 0.015))      # chin
        for s in (1, -1):
            off -= 0.007 * blob3(q, (0.022 * s, 0.008, 0.06), (0.012, 0.009, 0.012))   # sockets
            off += 0.006 * blob3(q, (0.04 * s, -0.012, 0.045), (0.015, 0.012, 0.015))  # cheekbones
        return M @ (p + p.normalized() * off * k)

    def col(p, d):
        lip = smooth(0.012, 0.004, abs(d.y + 0.38)) * smooth(0.2, 0.1, abs(d.x)) * smooth(0.6, 0.9, d.z)
        return mix(mix(SKINC, darken(SKINC, 0.25), smooth(0.2, -0.6, d.z) * 0.6), (0.62, 0.3, 0.3), lip)

    morph_sphere(b, c, shape, col, cls=SKIN, bone=bone, seg=18, rings=14)
    f = M @ V(0, 0, 1)
    up = M @ V(0, 1, 0)
    side = M @ V(1, 0, 0)
    for s in (1, -1):
        A.animal_eye(b, c + M @ V(0.022 * s * k, 0.008 * k, 0.056 * k), f + side * 0.15 * s, 0.009 * k, "4a2a18", bone, pupil="round", almond=0.55, side=s, lid="1a0e0a")
        b.tube([c + M @ V(0.01 * s * k, 0.024 * k, 0.062 * k), c + M @ V(0.034 * s * k, 0.026 * k, 0.055 * k)], [0.003 * k, 0.002 * k], HAIRC, cls=HAIR, bone=bone, seg=4, mat=MAT_PLAIN)
    # hair: a cap over the crown drawn up into a topknot
    b.ellipsoid(c + up * 0.032 * k - f * 0.012 * k, (0.066 * k, 0.055 * k, 0.066 * k), HAIRC, cls=HAIR, bone=bone, rot=A.euler_of(M), seg=14, rings=8)
    b.ball(c + up * 0.09 * k - f * 0.02 * k, 0.022 * k, HAIRC, cls=HAIR, bone=bone, seg=10, rings=6)


# eight faces in a crescent round the beast's own head, each watching its own gate, with flames
# of mane between them
centre = hf.c - hf.f * 0.13 + hf.u * 0.02
for i in range(8):
    a = (i / 7 - 0.5) * 4.3
    pos = centre + hf.r * (math.sin(a) * 0.22) + hf.u * (math.cos(a) * 0.2)
    look = (hf.r * math.sin(a) * 0.75 + hf.u * math.cos(a) * 0.55 + hf.f * 0.7).normalized()
    face(pos, look, 0.95, "neck1")
    for j in range(2):
        root = pos - look * 0.05 + hf.u * 0.04
        A.lock(b, root, (hf.u * 0.8 - hf.f * 0.6 + hf.r * math.sin(a + j * 0.6) * 0.4).normalized(), -hf.f, 0.16 - 0.04 * j, 0.035, "ff7020", "ffe080",
               bone="neck1", lift=0.4, rise=0.2, cls=HAIR, mat=MAT_GLOW, tint=0.0)
# gilded plates on the shoulders and a gate-ring through the nose
for sd, s in (("L", 1), ("R", -1)):
    sc = r.bones["shoulder." + sd][0]
    for k in range(3):
        b.superquad(sc + V(0.05 * s, -0.04 - k * 0.07, 0.05 - k * 0.04), (0.07, 0.045, 0.014), "e0b040", e=0.4, cls=METAL, bone="shoulder." + sd,
                    rot=(0, 1.3 * s, -0.4 * s), seg=8, rings=5)
nose = hf.at(0, -0.035, 0.2 * 1.15)
ring = [nose + hf.f * 0.0 + hf.u * (-0.045 + math.cos(t) * 0.04) + hf.r * (math.sin(t) * 0.04) for t in [i / 16 * 2 * math.pi for i in range(17)]]
b.tube(ring, [0.007] * 17, "e0b040", cls=METAL, bone="head", seg=6, cap0=False, cap1=False)

print("[art] kaiming: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/kaiming.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
