"""Moth (new in Part V): a great lantern moth (Glow Moth, Lantern Moth Queen).  Four wings
painted with a dark basal patch, wavy cross-lines, a pale submarginal band and a dark border,
veins radiating from the root and closing the discal cell, and glowing eye spots; a thorax of
dense fur and a furred segmented abdomen, a ruff, faceted eyes, a coiled proboscis and palps,
six banded legs folded underneath and comb-like feathered antennae.
Run: blender --background --python art/monsters/moth.py  ->  assets/monsters/moth.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from clay import Clay  # noqa: E402
from sculpt import fbm3  # noqa: E402
from creature import add, smooth  # noqa: E402

kit.reset()
creature.realtime()
C = V(0, 1.5, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", C + V(0, 0, -0.1), C + V(0, 0.02, 0.2), "root")
r.bone("abdomen", C + V(0, 0, -0.1), C + V(0, -0.15, -0.55), "body")
r.bone("head", C + V(0, 0.02, 0.2), C + V(0, 0.05, 0.36), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("fw.%s" % sd, C + V(0.08 * s, 0.06, 0.08), C + V(0.9 * s, 0.25, 0.25), "body")
    r.bone("hw.%s" % sd, C + V(0.08 * s, 0.02, -0.05), C + V(0.7 * s, -0.1, -0.35), "body")
    r.bone("ant.%s" % sd, C + V(0.04 * s, 0.1, 0.33), C + V(0.22 * s, 0.4, 0.6), "head")

b = Builder("moth")
# thorax and abdomen sculpted in one: a thick, fluffy thorax (the fur shingled into soft clumps,
# not a pelt of strands), a tapering abdomen of furred rings, a small head and a collar ruff
cl = Clay(0.012, "moth_body")
cl.ellipsoid(C + V(0, 0.02, 0.05), (0.14, 0.14, 0.19), bones={"body": 1.0}, tag="thorax")
cl.ellipsoid(C + V(0, 0.04, 0.16), (0.15, 0.13, 0.08), bones={"body": 0.7, "head": 0.3}, tag="ruff")
abd = [C + V(0, -0.0, -0.1)] + [C + V(0, -0.03 - k / 6 * 0.12, -0.15 - k / 6 * 0.38) for k in range(1, 7)]
for k in range(7):
    cl.ellipsoid(abd[k], ((0.12 - k / 6 * 0.05), (0.11 - k / 6 * 0.04), 0.07), rot=A.frame_m(abd[min(6, k + 1)] - abd[max(0, k - 1)]), bones={"abdomen": min(1.0, 0.3 + k * 0.2), "body": max(0.0, 0.7 - k * 0.2)}, tag="abd", t=k)
cl.ellipsoid(C + V(0, 0.04, 0.27), (0.09, 0.085, 0.08), bones={"head": 1.0}, tag="head")


def moth_col(p, info):
    if info.tag == "abd":
        # pale bands between the rings of the abdomen
        return (0.82 + 0.15 * (0.5 + 0.5 * math.cos(info.t * 2 * math.pi)),) * 3
    if info.tag == "ruff":
        return (0.98, 0.98, 0.98)
    return (0.88, 0.88, 0.88)


def moth_fluff(p, info):
    if info.tag == "head":
        return None
    nn = info.n
    w = fbm3((p.x * 14.0, p.y * 14.0, p.z * 14.0), 2, 4)
    u = -p.z * 22.0 + 0.5 * math.sin(math.atan2(nn.x, nn.y) * 7.0) + 1.2 * w
    k = u - math.floor(u)
    return nn * ((0.016 if info.tag in ("thorax", "ruff") else 0.008) * k ** 1.5)


cl.build(b, moth_col, cls=CLOTH, tint_fn=lambda p, info: 0.7 if info.tag == "ruff" else 1.0, post=moth_fluff)
b.cur_pal = 0.0
# big compound eyes, a coiled proboscis and two palps
for s in (1, -1):
    A.compound_eye(b, C + V(0.07 * s, 0.06, 0.31), 0.05, "302040", "head")
    b.tube([C + V(0.02 * s, -0.02, 0.33), C + V(0.03 * s, -0.04, 0.38)], [0.012, 0.008], (0.8, 0.8, 0.8), cls=HAIR, bone="head", tint=0.6, seg=6)
coil = []
for k in range(16):
    a = k / 15 * 3.5 * math.pi
    rr = 0.04 * (1.0 - k / 20)
    coil.append(C + V(0, -0.06 - math.sin(a) * rr, 0.34 + math.cos(a) * rr * 0.6))
b.tube(coil, [0.006] * 16, "c8a060", cls=SKIN, bone="head", seg=5)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# six legs folded under the thorax, banded and spurred
for s in (1, -1):
    for k in range(3):
        root = C + V(0.05 * s, -0.08, 0.12 - k * 0.1)
        knee = root + V(0.12 * s, -0.08, 0.04 - k * 0.02)
        foot = knee + V(0.04 * s, -0.2, 0.02 - k * 0.04)
        b.tube([root, knee, foot], [0.014, 0.012, 0.006], (0.6, 0.6, 0.6), cls=HAIR, bone="body", tint=0.6, seg=6)
        b.ball(knee, 0.016, (0.85, 0.85, 0.85), cls=HAIR, bone="body", tint=0.6, seg=6, rings=4)
        b.tube([knee.lerp(foot, 0.4), knee.lerp(foot, 0.4) + V(0.03 * s, 0.02, 0)], [0.004, 0.001], (0.9, 0.9, 0.9), cls=HAIR, bone="body", tint=0.6, seg=3)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# feathered (pectinate) antennae: a shaft with paired comb branches
for s, sd in ((1, "L"), (-1, "R")):
    a = "ant.%s" % sd
    h, tl = r.head(a), r.tail(a)
    b.tube([h, h.lerp(tl, 0.5) + V(0, 0.04, 0), tl], [0.008, 0.007, 0.004], (0.6, 0.6, 0.6), bone=a, tint=0.6, seg=5)
    for k in range(12):
        t = 0.15 + k / 14
        p = h.lerp(tl, t) + V(0, 0.04 * math.sin(math.pi * t), 0)
        ln = 0.06 * math.sin(math.pi * min(1.0, t * 1.1))
        b.tube([p, p + V(ln * s, ln * 0.3, -ln * 0.8)], [0.004, 0.001], (0.8, 0.8, 0.8), cls=HAIR, bone=a, tint=0.6, seg=3)
        b.tube([p, p + V(-ln * 0.3 * s, ln, -ln * 0.2)], [0.004, 0.001], (0.8, 0.8, 0.8), cls=HAIR, bone=a, tint=0.6, seg=3)


def wing(bone, root, span, chord, sweep, s, shade_in, shade_out, spot):
    """A wing whose pattern is painted per vertex: a dark basal patch, wavy cross-lines, a pale
    submarginal band and a dark border; veins radiate from the root like a real moth's and a
    cross vein closes the discal cell; an eye spot glows."""
    rows = []
    cols = []
    n = 9
    m = 8
    for j in range(n):
        u = j / (n - 1)
        row = []
        crow = []
        for i in range(m):
            v = i / (m - 1)
            x = s * span * u
            w = chord * math.sin(math.pi * (0.15 + 0.85 * v)) * (1.0 - 0.35 * u) + 0.02
            z = sweep * u - w * (v - 0.4) * 1.6
            row.append(root + V(x, 0.05 * u * u, z))
            dist = math.hypot(u, (v - 0.4) * 0.8)
            sh = shade_in + (shade_out - shade_in) * u
            wave = math.sin(dist * 22.0 + v * 4.0)
            if dist < 0.25:
                sh *= 0.7
            elif wave > 0.85:
                sh *= 0.62
            if 0.78 < dist < 0.86:
                sh = min(1.0, sh * 1.25)
            if dist > 0.92:
                sh *= 0.55
            crow.append((sh, sh, sh))
        rows.append(row)
        cols.append(crow)
    b.sheet(rows, cols[0][0], cls=CLOTH, bone=bone, tint=1.0, cols=cols, thickness=0.008)
    for k in range(6):
        v = k / 5
        end = root + V(s * span * (0.85 + 0.1 * math.sin(v * 3)), 0.04, sweep * 0.9 - (v - 0.4) * chord * 1.4)
        b.tube([root, root.lerp(end, 0.45) + V(0, 0.012, 0), end], [0.005, 0.004, 0.002], (0.35, 0.35, 0.35), cls=CLOTH, bone=bone, tint=1.0, seg=4, mat=MAT_PLAIN)
    b.tube([root + V(s * span * 0.4, 0.016, sweep * 0.4 - chord * 0.25), root + V(s * span * 0.42, 0.016, sweep * 0.42 + chord * 0.25)], [0.004, 0.004], (0.35, 0.35, 0.35), cls=CLOTH, bone=bone, tint=1.0, seg=4, mat=MAT_PLAIN)
    sp = root + V(s * span * spot[0], 0.03 * spot[0] + 0.012, sweep * spot[0] + spot[1])
    b.disc(sp, chord * 0.22, (1.0, 0.9, 0.5), cls=CRYSTAL, bone=bone, seg=16, mat=MAT_GLOW, col_rim=(0.6, 0.3, 0.1), thick=0.02)
    b.disc(sp + V(0, 0.006, 0), chord * 0.09, "201020", cls=CRYSTAL, bone=bone, seg=12, thick=0.024)
    b.disc(sp + V(chord * 0.03 * s, 0.009, chord * 0.03), chord * 0.03, "ffffff", cls=CRYSTAL, bone=bone, seg=8, mat=MAT_GLOW, thick=0.026)


for s, sd in ((1, "L"), (-1, "R")):
    wing("fw.%s" % sd, C + V(0.06 * s, 0.07, 0.08), 0.95, 0.5, 0.2, s, 0.55, 0.95, (0.6, -0.05))
    wing("hw.%s" % sd, C + V(0.06 * s, 0.03, -0.06), 0.72, 0.42, -0.35, s, 0.5, 0.85, (0.55, 0.0))
    for k in range(3):
        root = C + V(0.07 * s, -0.08, 0.1 - k * 0.1)
        b.tube([root, root + V(0.12 * s, -0.15, 0.04), root + V(0.15 * s, -0.32, 0.0)], [0.012, 0.01, 0.005], (0.5, 0.5, 0.5), bone="body", tint=0.6, seg=5)

FLAP = 0.8


def idle(t, amp=1.0):
    w = 2 * math.pi / FLAP
    f = math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, -f * 0.07 + math.sin(t * w / 4) * 0.1, 0))
    p["body"] = ((0.05 * f, math.sin(t * w / 4) * 0.1, 0), (0, 0, 0))
    p["abdomen"] = ((-0.06 * f, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, -s * (0.25 + f * 0.75) * amp), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, -s * (0.2 + math.sin(t * w - 0.5) * 0.6) * amp), (0, 0, 0))
        p["ant.%s" % sd] = ((math.sin(t * w / 2) * 0.1, 0, 0), (0, 0, 0))
    return p


def attack(t):
    e = env(t / 0.55)
    p = idle(t * 1.5, 1.2)
    p["root"] = ((0, 0, 0), (0, -0.2 * e, 0.45 * e))
    p["body"] = ((0.35 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t, 0.5)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.25 * e))
    p["body"] = ((-0.4 * e, 0, 0.3 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 0.4)
    p["body"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, s * 0.6 * e), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, s * 0.4 * e), (0, 0, 0))
    return p


# the moth reads small next to the other foes: scale it up (clips are rotations, so they still fit)
T_WALK = 1.6


def walk(t):
    """Flutters forward: quicker beats, the body pitched into the flight, bobbing."""
    p = idle(t * FLAP * 4 / T_WALK, 1.15)
    add(p, "body", (0.25, 0, 0))
    add(p, "abdomen", (-0.1, 0, 0))
    add(p, "root", (0, 0, 0), (0, 0.04 * math.sin(2 * math.pi * t / T_WALK), 0))
    return p


def die(t):
    """The wings fold; the moth tumbles to the ground and lies with its wings spread flat."""
    k = min(1.0, t / 1.2)
    f = smooth(0.1, 0.7, k) ** 1.5
    p = idle(t * (1.0 - f), 1.0 - f)
    add(p, "root", (0.0, 0.0, 0.5 * f), (0, -1.85 * f + 0.05 * math.sin(math.pi * smooth(0.7, 0.85, k)), 0))
    add(p, "body", (0.2 * f, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "fw.%s" % sd, (0, 0, s_ * 0.2 * f))
        add(p, "hw.%s" % sd, (0, 0, s_ * 0.15 * f))
        add(p, "ant.%s" % sd, (0.5 * f, 0, 0))
    return p

kit.scale_asset(b, r, 1.45)
print("[art] moth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/moth.glb", {"idle": (FLAP * 4, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=10, dist=0.2, strength=0.4)
