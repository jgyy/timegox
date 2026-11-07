"""Phoenix / great bird (Ash Phoenix, Thunder Roc, Garden Crane, Jade Emperor of Ruin ...).
A hovering bird with a teardrop body under a coat of contour feathers, two-bone wings fanned with
primaries, secondaries and two rows of coverts, a hackled neck, a hooked two-part beak with a
cere, a bare eye ring and a plumed crest, scaled legs with jointed toes and hooked talons, and long
eyed tail plumes on a three-bone chain.
Run: blender --background --python art/monsters/phoenix.py  ->  assets/monsters/phoenix.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import catmull, chain_weights, eyes, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, METAL, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import morph_sphere, scatter, smooth, strand  # noqa: E402

kit.reset()
BODY = V(0, 1.45, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", BODY + V(0, 0, -0.25), BODY + V(0, 0.05, 0.2), "root")
r.bone("neck", BODY + V(0, 0.05, 0.2), BODY + V(0, 0.35, 0.36), "body")
r.bone("head", BODY + V(0, 0.35, 0.36), BODY + V(0, 0.42, 0.62), "neck")
for s, sd in ((1, "L"), (-1, "R")):
    sh = BODY + V(0.14 * s, 0.12, 0.08)
    el = sh + V(0.55 * s, 0.08, -0.08)
    tp = el + V(0.75 * s, -0.02, -0.18)
    r.bone("wing.%s" % sd, sh, el, "body")
    r.bone("wing2.%s" % sd, el, tp, "wing.%s" % sd)
    r.bone("leg.%s" % sd, BODY + V(0.08 * s, -0.15, 0.0), BODY + V(0.09 * s, -0.42, 0.06), "body")
TAIL = [BODY + V(0, -0.02, -0.28), BODY + V(0, -0.12, -0.7), BODY + V(0, -0.32, -1.15), BODY + V(0, -0.6, -1.55)]
for i in range(3):
    r.bone("tail%d" % i, TAIL[i], TAIL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))

b = Builder("phoenix")
# body: a teardrop (full breast, tapering to the tail), paler underneath, then a coat of small
# contour feathers laid back over it
def body_shape(d):
    p = V(d.x * 0.2, d.y * 0.22, d.z * 0.34)
    if d.z < 0:
        p.x *= 1.0 - 0.45 * smooth(0.0, 1.0, -d.z)
        p.y *= 1.0 - 0.35 * smooth(0.0, 1.0, -d.z)
    p.y += 0.05 * smooth(0.2, 1.0, d.z) * (1.0 if d.y < 0 else 0.3)   # deep keel of the breast
    return p


body_v = morph_sphere(b, BODY, body_shape, lambda p, d: (0.7 + 0.3 * smooth(0.3, -0.7, d.y),) * 3, cls=CLOTH, bone="body", seg=24, rings=16, tint_fn=lambda p, d: 1.0)
for pos, nrm in scatter(b, body_v, 110, seed=4, min_dist=0.05):
    g = V(0, -0.15, -1.0)
    g = (g - nrm * g.dot(nrm)).normalized()
    A.feather(b, pos - nrm * 0.005, pos + g * 0.11 + nrm * 0.02, 0.04, (0.72, 0.72, 0.72), col_tip=(0.98, 0.98, 0.98), side=g.cross(nrm), bone="body", tint=1.0, barbs=False, curl=0.15, mat=MAT_PLAIN)
# neck: a loft ruffed with hackle feathers
neck_pts = [BODY + V(0, 0.05, 0.2), BODY + V(0, 0.22, 0.3), BODY + V(0, 0.36, 0.38)]
b.tube(neck_pts, [0.12, 0.09, 0.085], (0.85, 0.85, 0.85), bones=[{"body": 0.5, "neck": 0.5}, "neck", {"neck": 0.4, "head": 0.6}], tint=1.0, seg=14)
for j in range(3):
    c = neck_pts[0].lerp(neck_pts[2], 0.15 + j * 0.3)
    for k in range(10):
        a = k / 10 * 2 * math.pi
        out = V(math.sin(a), 0.2, math.cos(a) * 0.8).normalized()
        A.feather(b, c + out * 0.08, c + out * 0.13 + V(0, -0.12, -0.05), 0.035, (0.78, 0.78, 0.78), col_tip=(1, 1, 1), bone="neck", tint=1.0, barbs=False, curl=0.1, mat=MAT_PLAIN)
# head: round skull, a hooked two-part beak with a cere, a bare eye ring and a plumed crest
H = BODY + V(0, 0.4, 0.42)
morph_sphere(b, H, lambda d: V(d.x * 0.095, d.y * 0.1, d.z * 0.125) + V(0, 0, 0.012 * max(0.0, d.z)), lambda p, d: (0.88 + 0.1 * d.y,) * 3, cls=CLOTH, bone="head", seg=18, rings=12, tint_fn=lambda p, d: 1.0)
b.ellipsoid(H + V(0, 0.005, 0.105), (0.045, 0.035, 0.03), "e8c060", cls=SKIN, bone="head", seg=10, rings=6)
upper = [H + V(0, 0.01, 0.11), H + V(0, 0.0, 0.2), H + V(0, -0.03, 0.26), H + V(0, -0.075, 0.27)]
strand(b, upper, 0.042, 0.004, "f0c040", col_tip="c08020", cls=METAL, bone="head", flat=0.8, seg=10, per=4, up=(1, 0, 0))
lower = [H + V(0, -0.035, 0.1), H + V(0, -0.045, 0.18), H + V(0, -0.05, 0.22)]
strand(b, lower, 0.03, 0.004, "d8a030", cls=METAL, bone="head", flat=0.6, seg=8, per=3, up=(1, 0, 0))
for s in (1, -1):
    b.ellipsoid(H + V(0.06 * s, 0.03, 0.06), (0.03, 0.03, 0.02), "e05030", cls=SKIN, bone="head", seg=10, rings=6, rot=(0, 0.9 * s, 0))
    b.ellipsoid(H + V(0.022 * s, 0.015, 0.2), (0.006, 0.004, 0.008), "201008", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
eyes(b, H + V(0, 0.03, 0.07), 0.065, 0.026, iris="ff6020", bone="head", slit=False, glow=True, rot_y=0.9, h=0.9)
for k in range(7):
    a = (k - 3) * 0.16
    root = H + V(math.sin(a) * 0.05, 0.08, -0.02)
    tip = root + V(math.sin(a) * 0.16, 0.28 - abs(k - 3) * 0.035, -0.3)
    A.feather(b, root, tip, 0.03, (0.7, 0.7, 0.7), col_tip=(1, 1, 1), side=(1, 0, 0), bone="head", tint=1.0, curl=0.2)
    b.ball(tip, 0.02, "fff0a0", cls=CRYSTAL, bone="head", seg=8, rings=5, mat=MAT_GLOW)
# wings: a covered arm, then rows of feathers - long primaries off the hand, secondaries along
# the forearm, shorter coverts overlapping them - fanned like a real wing
for s, sd in ((1, "L"), (-1, "R")):
    w1 = "wing.%s" % sd
    w2 = "wing2.%s" % sd
    sh, el, tp = r.head(w1), r.tail(w1), r.tail(w2)
    b.tube([sh, sh.lerp(el, 0.5) + V(0, 0.02, 0), el, el.lerp(tp, 0.5), tp], [0.08, 0.065, 0.05, 0.035, 0.015], (0.8, 0.8, 0.8), bones=[{"body": 0.3, w1: 0.7}, w1, {w1: 0.5, w2: 0.5}, w2, w2], tint=1.0, seg=10)
    rows = (("primary", 10, 0.75, 0.62, 0.0), ("secondary", 12, 0.48, 0.72, 0.02), ("covert", 14, 0.28, 0.88, 0.035), ("lesser", 14, 0.15, 0.95, 0.05))
    for name, n, ln, shd, lift in rows:
        for k in range(n):
            u = k / (n - 1)
            if name == "primary":
                base = el.lerp(tp, 0.2 + 0.8 * u)
                bone = w2
                d = V(0.55 * s * u + 0.05 * s, -0.08, -1.0 + 0.6 * u).normalized()
                length = ln * (0.8 + 0.4 * u)
            else:
                base = sh.lerp(el, u) if u < 0.75 else el.lerp(tp, (u - 0.75) * 1.6)
                bone = w1 if u < 0.7 else {w1: 0.5, w2: 0.5}
                d = V(0.15 * s * u, -0.06, -1.0).normalized()
                length = ln * (0.75 + 0.35 * u)
            tipp = base + d * length + V(0, lift, 0)
            col = (shd * 0.8,) * 3
            A.feather(b, base + V(0, lift, 0), tipp, (0.06 if name != "lesser" else 0.04) + 0.015 * u, col, col_tip=(1.0, 1.0, 1.0) if name == "primary" else (shd,) * 3, side=V(1, 0, 0), bone=bone, tint=1.0, curl=0.06, barbs=name == "primary")
    # legs: feathered thighs, scaled shanks, three toes forward and one back, hooked talons
    lg = "leg.%s" % sd
    top, ank = r.head(lg), r.tail(lg)
    for k in range(5):
        a = k / 5 * 2 * math.pi
        out = V(math.sin(a), 0, math.cos(a))
        A.feather(b, top + out * 0.04, top + out * 0.06 + V(0, -0.14, -0.02), 0.03, (0.8, 0.8, 0.8), col_tip=(1, 1, 1), bone=lg, tint=1.0, barbs=False, mat=MAT_PLAIN)
    shank = [top.lerp(ank, t) for t in (0.4, 0.7, 1.0)]
    b.tube(shank, [0.022, 0.02, 0.018], "c89030", cls=SCALE, bone=lg, seg=8)
    for k in range(4):
        q = top.lerp(ank, 0.45 + k * 0.15)
        b.tube([q + V(0, 0.004, 0), q - V(0, 0.004, 0)], [0.024, 0.024], "a87020", cls=SCALE, bone=lg, seg=8, cap0=False, cap1=False)
    for k in range(4):
        a = (k - 1) * 0.45 if k < 3 else math.pi
        d = V(math.sin(a), -0.3, math.cos(a)).normalized()
        t1 = ank + d * 0.05
        t2 = t1 + d * 0.035 + V(0, -0.01, 0)
        b.tube([ank, t1, t2], [0.014, 0.011, 0.009], "c89030", cls=SCALE, bone=lg, seg=6)
        strand(b, [t2, t2 + d * 0.02 + V(0, 0.006, 0), t2 + d * 0.035 - V(0, 0.025, 0)], 0.008, 0.001, "403020", cls=STONE, bone=lg, seg=5, per=3)
# tail plumes: long feathers on the tail chain, each ending in a glowing eye spot
pts, idx = catmull(TAIL, per=4)
for k in range(9):
    a = (k - 4) * 0.13
    pp = [p + V(math.sin(a) * (0.05 + 0.45 * f / 3), 0.02 * abs(k - 4), 0) for p, f in zip(pts, idx)]
    ws = [0.025 + 0.045 * (f / 3) for f in idx]
    b.ribbon(pp, ws, (1, 0, 0) if abs(a) < 0.2 else (math.cos(a), 0, -math.sin(a) * 0.3), (0.8, 0.8, 0.8), cls=HAIR, bones=[chain_weights("tail", f, 3) for f in idx], tint=1.0, col_end=(1.0, 1.0, 1.0))
    b.tube(pp, [0.006] * len(pp), (0.95, 0.95, 0.95), cls=HAIR, bones=[chain_weights("tail", f, 3) for f in idx], tint=0.5, seg=4)
    b.ellipsoid(pp[-1] + V(0, 0.01, 0.05), (0.055, 0.014, 0.065), "fff4b0", cls=CRYSTAL, bone="tail2", seg=10, rings=5, mat=MAT_GLOW)
    b.ellipsoid(pp[-1] + V(0, 0.016, 0.05), (0.025, 0.01, 0.03), "ff6030", cls=CRYSTAL, bone="tail2", seg=8, rings=4, mat=MAT_GLOW)

FLAP = 1.0


def idle(t, strength=1.0):
    w = 2 * math.pi / FLAP
    f = math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, -f * 0.08, 0))
    p["body"] = ((0.05 * f, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.05 * f, math.sin(t * w / 3) * 0.15, 0), (0, 0, 0))
    p["head"] = ((0.05 * f, math.sin(t * w / 3) * 0.1, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((0.1 * f, 0, -s * f * 0.6 * strength), (0, 0, 0))
        p["wing2.%s" % sd] = ((0, -s * 0.1, -s * math.sin(t * w - 0.9) * 0.45 * strength), (0, 0, 0))
        p["leg.%s" % sd] = ((0.6, 0, 0), (0, 0, 0))
    for i in range(3):
        p["tail%d" % i] = ((math.sin(t * w - i * 0.8) * 0.08, math.sin(t * w / 2 - i) * 0.06, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    dive = math.sin(min(1.0, k * 1.4) * math.pi)
    p = idle(t * 2, 1.2)
    p["root"] = ((0, 0, 0), (0, -0.3 * dive, 0.5 * dive))
    p["body"] = ((0.4 * dive, 0, 0), (0, 0, 0))
    p["neck"] = ((0.3 * dive - 0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((-0.3 * e, 0.5 * s * e, -s * 0.9 * e), (0, 0, 0))
        p["leg.%s" % sd] = ((-0.9 * dive, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t, 0.4)
    p["root"] = ((0, 0, 0), (0, 0.1 * e, -0.3 * e))
    p["body"] = ((-0.35 * e, 0, 0.15 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.3 * e, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 0.3)
    p["root"] = ((0, 0, 0), (0, 0.2 * e, 0))
    p["body"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((0.2 * e, 0, s * 0.9 * e), (0, 0, 0))
        p["wing2.%s" % sd] = ((0, 0, s * 0.5 * e), (0, 0, 0))
    return p


print("[art] phoenix: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/phoenix.glb", {"idle": (FLAP * 3, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.4)
