"""Magpie bridge (Part VIII ending): on the seventh night of the seventh month every magpie in the
world flies up to the Star River and makes a bridge of its own wings so that the Cowherd and the
Weaver can meet.  A shallow arch of magpies three abreast, wing over wing like roof tiles, each bird
black with a blue-green sheen on the flight feathers, a white belly and shoulder patch and a long
graduated tail; star dust trails off the wingtips and a ribbon of the river glows beneath.
Run: blender --background --python art/props/magpiebridge.py  ->  assets/props/magpiebridge.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, METAL, V, Builder, mix  # noqa: E402
from sculpt import catmull, smooth  # noqa: E402

kit.reset()
rnd = random.Random(77)
b = Builder("magpiebridge")
SPAN = 4.2      # half-length of the arch along x
RISE = 1.5      # height of the crown above the abutments
INK = "12121a"
SHEEN = "1e4a78"
TEAL = "1a6a6a"
WHITE = "eef0f4"


def arch(t):
    """Point on the arch centre-line for t in [-1, 1]: a flattened catenary-like curve."""
    x = t * SPAN
    y = RISE * (1.0 - abs(t) ** 1.7)
    return V(x, y, 0.0)


def magpie(p, fwd, span, flap):
    """A magpie in flight seen from above: wings spread across the deck, tail streaming back.
    fwd is the flight direction (across the bridge), span the wing length, flap a dihedral angle."""
    fwd = V(fwd).normalized()
    side = V(0, 1, 0).cross(fwd).normalized()
    up = fwd.cross(side).normalized()
    b.cur_pal = 0.0
    b.ellipsoid(p, (0.07, 0.06, 0.12), INK, cls=HAIR, seg=8, rings=4, rot=(0, math.atan2(fwd.x, fwd.z), 0))
    b.cur_pal = 1.0
    b.ellipsoid(p - up * 0.03 + fwd * 0.02, (0.05, 0.035, 0.08), WHITE, cls=HAIR, seg=6, rings=4, rot=(0, math.atan2(fwd.x, fwd.z), 0))
    hd = p + fwd * 0.13 + up * 0.02
    b.cur_pal = 0.0
    b.ball(hd, 0.045, INK, cls=HAIR, seg=7, rings=5)
    b.cone(hd + fwd * 0.06, 0.013, 0.05, "28282c", cls=METAL, seg=5, rot=(math.pi / 2, math.atan2(fwd.x, fwd.z), 0))
    for s in (1, -1):
        b.ball(hd + side * 0.028 * s + fwd * 0.02 + up * 0.012, 0.007, "f8f0e0", cls=CRYSTAL, seg=4, rings=3)
        root = p + side * 0.05 * s + fwd * 0.03
        elbow = root + side * span * 0.45 * s + up * span * flap * 0.5 + fwd * 0.03
        tip = elbow + side * span * 0.55 * s + up * span * flap - fwd * 0.1
        # the arm: a flattened leading edge from shoulder through wrist to the hand
        b.cur_pal = 0.0
        b.tube([root, elbow, tip], [0.035, 0.026, 0.01], INK, cls=HAIR, seg=6, flat=0.35, up=up)
        # white scapular patch, the secondaries trailing back off the arm, the primaries fanned at the hand
        b.cur_pal = 1.0
        b.ellipsoid(root.lerp(elbow, 0.35) + up * 0.02, (0.06, 0.012, 0.04), WHITE, cls=HAIR, seg=5, rings=3)
        b.cur_pal = 0.5
        for k in range(4):
            q = root.lerp(elbow, 0.15 + 0.27 * k)
            b.leaf(q, q - fwd * 0.17 + side * 0.02 * s - up * 0.01, 0.1, INK, col_tip=SHEEN, side=side * s, cls=HAIR, curl=0.04, n=3)
        for k in range(4):
            a = 0.35 + 0.28 * k
            d = (side * s * math.sin(a) - fwd * math.cos(a)).normalized()
            q = elbow.lerp(tip, 0.25 + 0.25 * k)
            b.leaf(q, q + d * span * (0.38 + 0.04 * k), 0.095, INK, col_tip=mix(SHEEN, TEAL, k / 3), side=side * s, cls=HAIR, curl=0.04, n=3)
    # long graduated tail: overlapping flat blades with an iridescent green-blue sheen
    b.cur_pal = 0.5
    for k in range(3):
        o = (k - 1) * 0.03
        b.leaf(p - fwd * 0.08 + side * o * 0.5, p - fwd * (0.42 - 0.08 * abs(k - 1)) + side * o * 1.6 - up * 0.04, 0.05, INK, col_tip=TEAL, side=side, cls=HAIR, curl=0.03, n=3)

# the birds: three files along the arch, alternate files flying opposite ways, overlapping wings
n_along = 8
for row, z in enumerate((-0.5, 0.0, 0.5)):
    for i in range(n_along):
        t = -1.0 + 2.0 * (i + 0.5 * (row % 2)) / (n_along - 0.5)
        t = max(-0.98, min(0.98, t))
        c = arch(t) + V(0, 0.05 * math.sin(i * 2.3 + row), z)
        fwd = V(0, 0, 1 if (i + row) % 2 == 0 else -1)
        fwd = (fwd + V(rnd.uniform(-0.15, 0.15), 0, 0)).normalized()
        magpie(c, fwd, 0.5 + 0.05 * rnd.random(), 0.12 + 0.1 * math.sin(i * 1.7 + row))

# star dust trailing from the wingtips and a glowing ribbon of the Star River below the arch
b.cur_pal = 1.0
for k in range(48):
    t = rnd.uniform(-1, 1)
    p = arch(t) + V(rnd.uniform(-0.2, 0.2), rnd.uniform(-0.35, -0.05), rnd.choice((-1, 1)) * rnd.uniform(0.75, 1.1))
    b.ball(p, rnd.uniform(0.012, 0.03), mix("fff4c0", "a0c8ff", rnd.random()), cls=CRYSTAL, seg=4, rings=3, mat=MAT_GLOW)
river = catmull([V(-SPAN * 1.3, -0.4, 0.9), V(-SPAN * 0.5, -0.55, -0.3), V(SPAN * 0.4, -0.5, 0.4), V(SPAN * 1.3, -0.4, -0.8)], 6)
for k, off in enumerate((-0.25, 0.0, 0.25)):
    pts = [q + V(0, 0.02 * k, off) for q in river]
    b.tube(pts, [0.07 - 0.02 * abs(k - 1) * smooth(0.0, 1.0, abs(q.x) / SPAN) for q in pts], mix("80b0ff", "f0e0ff", k / 2), cls=CRYSTAL, seg=5, mat=MAT_GLOW)
# the two abutments where the lovers step on: small clouds of light
for s in (1, -1):
    for k in range(5):
        a = k / 5 * 2 * math.pi
        b.ball(arch(s) + V(math.cos(a) * 0.25, -0.1 + 0.05 * (k % 2), math.sin(a) * 0.35), 0.18, "f4f0ff", cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)

def star(c, r, col):
    """A bright star: a glowing core with a soft halo and four long diffraction glints."""
    b.ball(c, r, col, cls=CRYSTAL, seg=10, rings=6, mat=MAT_GLOW)
    b.ball(c, r * 1.9, mix(col, "ffffff", 0.5), cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        d = V(math.cos(a), math.sin(a), 0)
        b.leaf(c - d * r * 0.5, c + d * r * (5.0 if k % 2 == 0 else 3.5), r * 0.5, col, side=V(0, 0, 1), cls=CRYSTAL, col_tip="ffffff", curl=0.0, n=3, mat=MAT_GLOW)


# Altair (the Cowherd, golden) and Vega (the Weaver, blue-white) burning at either end of the arch
star(arch(-1.0) + V(-0.4, 1.4, 0), 0.12, "ffd070")
star(arch(1.0) + V(0.4, 1.4, 0), 0.13, "b8d8ff")
# loose feathers drifting down off the bridge
b.cur_pal = 0.5
for k in range(10):
    p = arch(rnd.uniform(-0.9, 0.9)) + V(0, -rnd.uniform(0.3, 1.2), rnd.uniform(-0.6, 0.6))
    d = V(rnd.uniform(-1, 1), rnd.uniform(-0.3, 0.3), rnd.uniform(-1, 1)).normalized()
    b.leaf(p, p + d * 0.1, 0.03, INK if k % 3 else WHITE, cls=HAIR, col_tip=SHEEN, curl=0.2, n=3)

print("[art] magpiebridge: %d triangles" % b.tri_count())
kit.finish_static(b, "props/magpiebridge.glb", samples=10, dist=0.6, strength=0.4, target_tris=0)
