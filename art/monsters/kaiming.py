"""Kaiming (new in Part VIII): Kaiming, Beast of the Nine Gates, who guards the gates of Kunlun - in
the Classic of Mountains and Seas a tiger the size of a temple with nine human faces, one watching
each gate.  The feline body of art/lib/feline.py with a crescent of eight human faces rising
round its own (each with eyes, brows, nose, mouth and a topknot), a flaming mane between them,
gilded plates on its shoulders and a gate-ring through its nose.  Tinted by the game per enemy;
the faces, gold and flames keep their colours.
Run: blender --background --python art/monsters/kaiming.py  ->  assets/monsters/kaiming.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import feline  # noqa: E402
from mathutils import Matrix  # noqa: E402
from kit import HAIR, MAT_GLOW, MAT_PLAIN, METAL, SKIN, V, darken  # noqa: E402
from sculpt import blob3, morph_sphere, strand  # noqa: E402

kit.reset()
b, r, hf, clips = feline.build("kaiming")
SKINC = "e8c8a8"


def face(c, fwd, k):
    """A small human face looking along `fwd`: a sculpted oval, eyes, brows, nose, mouth, hair."""
    f = V(fwd).normalized()
    side = f.cross(V(0, 1, 0)).normalized()
    up = side.cross(f).normalized()

    def shape(d):
        p = V(d.x * 0.07, d.y * 0.085, d.z * 0.07) * k
        p.x *= 1.0 - 0.35 * max(0.0, -d.y) ** 1.5
        q = p.copy()
        off = 0.006 * k * blob3(q, (0, -0.01 * k, 0.07 * k), (0.012 * k, 0.03 * k, 0.02 * k))
        return p + p.normalized() * off

    M = Matrix((-side, up, f)).transposed()
    morph_sphere(b, c, lambda d: M @ shape(d), lambda p, d: SKINC, cls=SKIN, bone="neck", seg=14, rings=10)
    front = c + f * 0.066 * k
    for s in (1, -1):
        b.eye(front + side * (-0.024 * s) * k + up * 0.012 * k, 0.012 * k, "c08020", side=s, bone="neck", rot_y=math.atan2(f.x, f.z), h=1.0, glow=False, mat=MAT_PLAIN)
        b.tube([front + side * (-0.012 * s) * k + up * 0.03 * k, front + side * (-0.038 * s) * k + up * 0.026 * k], [0.003 * k, 0.002 * k], "2a1a10", cls=HAIR, bone="neck", seg=4, mat=MAT_PLAIN)
    b.ellipsoid(front + up * -0.01 * k + f * 0.006 * k, (0.008 * k, 0.012 * k, 0.008 * k), darken(SKINC, 0.08), cls=SKIN, bone="neck", seg=6, rings=4, mat=MAT_PLAIN)
    b.tube([front + up * -0.035 * k + side * 0.012 * k, front + up * -0.035 * k - side * 0.012 * k], [0.003 * k, 0.003 * k], "a04050", cls=SKIN, bone="neck", seg=4, mat=MAT_PLAIN)
    b.ellipsoid(c + up * 0.05 * k - f * 0.01 * k, (0.07 * k, 0.05 * k, 0.07 * k), "1a1418", cls=HAIR, bone="neck", seg=12, rings=6)
    b.ball(c + up * 0.1 * k - f * 0.02 * k, 0.025 * k, "1a1418", cls=HAIR, bone="neck", seg=8, rings=5)


# eight faces in a crescent round the beast's own head, each watching its own gate
centre = hf.c + V(0, 0.02, -0.12)
for i in range(8):
    a = (i / 7 - 0.5) * 3.6
    c = centre + V(math.sin(a) * 0.3, 0.12 + 0.12 * math.cos(a), -0.05 * abs(math.sin(a)))
    face(c, V(math.sin(a) * 0.9, 0.15, math.cos(a)), 1.0)
    # flames of mane between the faces
    for j in range(3):
        root = c + V(0, 0.08, -0.06)
        strand(b, [root, root + V(math.sin(a) * 0.03, 0.08, -0.06), root + V(math.sin(a + j) * 0.06, 0.18, -0.12)], 0.025, 0.002, "ff8030", col_tip="ffe080", cls=HAIR, bone="neck", seg=5, per=3, mat=MAT_GLOW)
# gilded plates on the shoulders and a gate-ring through the nose
for s in (1, -1):
    for k in range(3):
        b.superquad(V(0.2 * s, 1.0 - k * 0.07, 0.4 - k * 0.05), (0.06, 0.04, 0.012), "e0b040", e=0.4, cls=METAL, bone="chest", rot=(0, 1.3 * s, -0.4 * s), seg=8, rings=5)
nose = hf.at(0, -0.03, 0.17)
ring = [nose + V(math.sin(t) * 0.045, -0.04 + math.cos(t) * 0.045, 0.0) for t in [i / 16 * 2 * math.pi for i in range(17)]]
b.tube(ring, [0.008] * 17, "e0b040", cls=METAL, bone="head", seg=6, cap0=False, cap1=False)

print("[art] kaiming: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/kaiming.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
