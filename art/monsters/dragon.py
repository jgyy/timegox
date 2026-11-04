"""Dragon: an eastern lung (Azure Dragon King, Frost Wyrm, Bone Wyrm, Ink Dragon ...).  A long
scaled body on a ten-bone spine that undulates as it hovers, antlers, whiskers, a flowing mane,
small clawed legs and a hinged jaw.
Run: blender --background --python art/monsters/dragon.py  ->  assets/monsters/dragon.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import catmull, chain_weights, claws, eyes, fangs, zero_pose  # noqa: E402
from kit import HAIR, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
N = 10
P = []
for i in range(N + 1):
    P.append(V(0.38 * math.sin(i * 0.85), 1.75 - i * 0.1 + 0.28 * math.sin(i * 0.9 + 0.4), 0.9 - i * 0.34))
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
for i in range(N):
    r.bone("seg%d" % i, P[i], P[i + 1], "root" if i == 0 else "seg%d" % (i - 1))
H0 = P[0]
r.bone("head", H0, H0 + V(0, 0.08, 0.5), "seg0")
r.bone("jaw", H0 + V(0, -0.08, 0.12), H0 + V(0, -0.14, 0.55), "head")
for li, seg in ((0, 1), (1, 6)):
    for s, sd in ((1, "L"), (-1, "R")):
        base = P[seg] + V(0.14 * s, -0.12, 0)
        r.bone("leg%d.%s" % (li, sd), base, base + V(0.18 * s, -0.25, 0.08), "seg%d" % seg)
        r.bone("foot%d.%s" % (li, sd), base + V(0.18 * s, -0.25, 0.08), base + V(0.22 * s, -0.42, 0.16), "leg%d.%s" % (li, sd))

b = Builder("dragon")
pts, idx = catmull(P, per=5)
radii = []
for k, f in enumerate(idx):
    t = f / N
    radii.append(0.2 * (1 - t) ** 0.8 + 0.035 + 0.03 * math.sin(t * math.pi))
bw = [chain_weights("seg", f, N) for f in idx]
b.tube(pts, radii, (0.75, 0.75, 0.75), cls=SCALE, bones=bw, tint=1.0, seg=14, cols=[(0.62 + 0.15 * math.sin(k * 0.6), 0.62 + 0.15 * math.sin(k * 0.6), 0.62 + 0.15 * math.sin(k * 0.6)) for k in range(len(pts))])
# pale belly plates along the underside
belly = [p + V(0, -rr * 0.55, 0) for p, rr in zip(pts, radii)]
b.tube(belly, [rr * 0.62 for rr in radii], "f0e0b0", cls=SCALE, bones=bw, tint=0.35, seg=10, flat=0.6, up=(0, 0, 1))
# dorsal fin / mane along the spine
for k in range(2, len(pts) - 2, 2):
    p = pts[k]
    t = idx[k] / N
    d = (pts[k + 1] - pts[k - 1]).normalized()
    up = V(0, 1, 0)
    side = d.cross(up).normalized()
    h = 0.22 * (1 - t) + 0.06
    b.leaf(p + up * radii[k] * 0.8, p + up * (radii[k] + h) - d * 0.12, 0.08, (0.45, 0.45, 0.45), side=side, cls=HAIR, bone=bw[k], tint=1.0, col_tip=(0.85, 0.85, 0.85))
# tail tuft
tip = pts[-1]
for k in range(7):
    a = k / 7 * 2 * math.pi
    b.leaf(tip, tip + V(math.cos(a) * 0.15, math.sin(a) * 0.15, -0.35), 0.07, (0.5, 0.5, 0.5), cls=HAIR, bone="seg%d" % (N - 1), tint=1.0, col_tip=(0.9, 0.9, 0.9))
# head: skull, long snout, brow ridges, nostrils
hb = "head"
b.ellipsoid(H0 + V(0, 0.06, 0.08), (0.2, 0.17, 0.22), (0.8, 0.8, 0.8), cls=SCALE, bone=hb, tint=1.0, seg=18, rings=10)
b.ellipsoid(H0 + V(0, 0.02, 0.36), (0.13, 0.09, 0.22), (0.85, 0.85, 0.85), cls=SCALE, bone=hb, tint=1.0, seg=16, rings=8)
b.ellipsoid(H0 + V(0, 0.07, 0.56), (0.1, 0.07, 0.06), (0.9, 0.9, 0.9), cls=SCALE, bone=hb, tint=1.0, seg=12, rings=6)
for s in (1, -1):
    b.ball(H0 + V(0.05 * s, 0.1, 0.6), 0.02, "200810", cls=SKIN, bone=hb, seg=8, rings=5)
    b.tube([H0 + V(0.06 * s, 0.17, 0.3), H0 + V(0.13 * s, 0.2, 0.16), H0 + V(0.17 * s, 0.17, 0.02)], [0.03, 0.035, 0.015], (0.55, 0.55, 0.55), cls=SCALE, bone=hb, tint=1.0, seg=8)
    # antlers: a main beam with two tines
    a0 = H0 + V(0.09 * s, 0.2, 0.02)
    a1 = a0 + V(0.12 * s, 0.22, -0.12)
    a2 = a1 + V(0.08 * s, 0.2, -0.22)
    b.tube([a0, a1, a2], [0.03, 0.022, 0.006], "e8d8a8", cls=STONE, bone=hb, seg=8)
    b.tube([a1, a1 + V(0.12 * s, 0.08, 0.06)], [0.016, 0.004], "e8d8a8", cls=STONE, bone=hb, seg=6)
    b.tube([a0.lerp(a1, 0.5), a0.lerp(a1, 0.5) + V(0.02 * s, 0.14, 0.08)], [0.014, 0.004], "e8d8a8", cls=STONE, bone=hb, seg=6)
    # long drooping whiskers
    w0 = H0 + V(0.08 * s, 0.02, 0.58)
    b.tube([w0, w0 + V(0.18 * s, -0.04, 0.05), w0 + V(0.36 * s, -0.22, -0.05), w0 + V(0.45 * s, -0.5, -0.2)], [0.012, 0.01, 0.007, 0.002], "f0e0a0", cls=HAIR, bone=hb, seg=6)
    # cheek mane
    for k in range(4):
        root = H0 + V(0.16 * s, 0.0 - k * 0.04, 0.05 - k * 0.04)
        b.leaf(root, root + V(0.22 * s, -0.08 - k * 0.04, -0.25), 0.07, (0.45, 0.45, 0.45), side=(0, 1, 0), cls=HAIR, bone=hb, tint=1.0, col_tip=(0.85, 0.85, 0.85))
eyes(b, H0 + V(0, 0.12, 0.27), 0.11, 0.035, iris="ffcf30", bone=hb, slit=True, glow=True, rot_y=0.8, h=0.75)
fangs(b, [H0 + V(0.07, -0.04, 0.48), H0 + V(-0.07, -0.04, 0.48), H0 + V(0.09, -0.03, 0.36), H0 + V(-0.09, -0.03, 0.36)], 0.07, hb)
# lower jaw with tongue and teeth
b.ellipsoid(H0 + V(0, -0.1, 0.34), (0.1, 0.04, 0.2), (0.95, 0.95, 0.95), cls=SCALE, bone="jaw", tint=1.0, seg=12, rings=6)
b.ellipsoid(H0 + V(0, -0.075, 0.33), (0.07, 0.012, 0.16), "c03040", cls=SKIN, bone="jaw", seg=10, rings=4)
fangs(b, [H0 + V(0.06, -0.08, 0.46), H0 + V(-0.06, -0.08, 0.46)], 0.05, "jaw", down=False)
# legs with talons
for li in (0, 1):
    for s, sd in ((1, "L"), (-1, "R")):
        lg = "leg%d.%s" % (li, sd)
        ft = "foot%d.%s" % (li, sd)
        b.tube([r.head(lg), r.tail(lg)], [0.06, 0.045], (0.7, 0.7, 0.7), cls=SCALE, bone=lg, tint=1.0, seg=10)
        b.tube([r.head(ft), r.tail(ft)], [0.045, 0.035], (0.7, 0.7, 0.7), cls=SCALE, bone=ft, tint=1.0, seg=10)
        claws(b, r.tail(ft) + V(0, -0.02, 0.02), True, ft, n=4, spread=0.025, length=0.07)
        b.leaf(r.head(lg), r.head(lg) + V(0.05 * s, 0.05, -0.2), 0.05, (0.5, 0.5, 0.5), cls=HAIR, bone=lg, tint=1.0)

T_IDLE = 3.0


def idle(t, amp=1.0):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, math.sin(t * w) * 0.1, 0))
    for i in range(N):
        p["seg%d" % i] = ((math.sin(t * w - i * 0.7) * 0.05 * amp, math.sin(t * w - i * 0.6) * 0.13 * amp, math.sin(t * w * 2 - i * 0.5) * 0.04), (0, 0, 0))
    p["head"] = ((math.sin(t * w) * 0.08, -math.sin(t * w - 0.0) * 0.1, 0), (0, 0, 0))
    p["jaw"] = ((0.1 + 0.08 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    for li in (0, 1):
        for sd, s in (("L", 1), ("R", -1)):
            p["leg%d.%s" % (li, sd)] = ((math.sin(t * w + li) * 0.2, 0, 0), (0, 0, 0))
            p["foot%d.%s" % (li, sd)] = ((0.3 + math.sin(t * w + li + 1) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0, 0.5)
    p["root"] = ((0, 0, 0), (0, -0.1 * lunge, 0.5 * lunge))
    p["seg0"] = ((0.25 * e - 0.35 * lunge, 0, 0), (0, 0, 0))
    p["seg1"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["head"] = ((0.3 * lunge - 0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.9 * lunge, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0, 0.5)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.25 * e))
    p["seg0"] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["seg1"] = ((-0.2 * e, 0.15 * e, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0.2 * e), (0, 0, 0))
    p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 1.0 + e)
    p["root"] = ((0, 0, 0), (0, 0.25 * e, 0))
    p["seg0"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((1.0 * e, 0, 0), (0, 0, 0))
    return p


print("[art] dragon: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/dragon.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.45)
