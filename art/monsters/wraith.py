"""Wraith: the ghosts of the graveyards (Bog Wraiths, the Willow Widow, the Hungry Ghosts, the
Thousand Unforgotten, Echo Shades ...).

Designed silhouette first, after the ghosts of Chinese tales: tall, hunched and footless, its
cloth hanging from a few points - the crown of the head, the shoulders, the wrists - and falling
straight under its own weight: a peaked hood, a burial robe that pales as it falls and dissolves
at the hem into long tattered strips streaming back like mist, and long hanging sleeves out of
which reach the thin, long-fingered hands of a hungry ghost.  It wears the dead's white
cross-collar under its robe, a straw mourning rope at the waist and a paper talisman on its
breast, and long black hair spills out of the hood over its shoulders (the female ghost of the
tales).  The face is left almost empty, the way the scariest ghosts are drawn: a dark void
under the hood and two eyes burning in it.  Ghost-fire drifts round the hem.  The robe takes the
enemy's colour; bone, hair, paper and the eyes keep their own.
Run: blender --background --python art/monsters/wraith.py  ->  assets/monsters/wraith.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add, chain_rig, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, loft, section, smooth  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(23)
Y = 1.2
HEM = Y - 0.52
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.3, 0), (0, Y + 0.4, 0), "root")
r.bone("head", (0, Y + 0.46, 0.04), (0, Y + 0.76, 0.1), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.22 * s, Y + 0.33, 0.02), (0.4 * s, Y + 0.08, 0.26), "body")
    r.bone("fore." + sd, (0.4 * s, Y + 0.08, 0.26), (0.48 * s, Y + 0.05, 0.62), "arm." + sd)
STRIPS = []
for k in range(16):
    a = (k / 16) * 2 * math.pi + 0.1
    out = V(math.sin(a), 0.0, math.cos(a))
    back = 0.5 - 0.5 * math.cos(a)          # 0 in front, 1 behind
    ln = (0.16 + 0.3 * back) * (1.0 if k % 2 else 0.68) * (1.0 + 0.15 * math.sin(k * 2.7))
    root = V(out.x * 0.33, HEM + 0.06, out.z * 0.29 - 0.04)
    pts = [root + out * (0.025 * j) + V(0, -ln * j / 3, -0.035 * back * j - 0.01 * j * j) for j in range(4)]
    STRIPS.append((chain_rig(r, "s%d_" % k, pts, "body"), pts, a, out))
b = Builder("wraith")


def body_w(p):
    if p.y < Y + 0.4:
        return {"body": 1.0}
    k = smooth(Y + 0.4, Y + 0.52, p.y)
    return {"body": 1.0 - k, "head": k}


# ---------------------------------------------------------------- the burial robe: solid, falling in folds, paler as it falls
rings = []
cols = []
ys = [Y + 0.44 - (Y + 0.44 - HEM) * j / 13 for j in range(14)]
for j, y in enumerate(ys):
    t = j / 13
    # shoulders, a narrower chest, then the cloth flares to the hem
    rw = 0.25 - 0.03 * math.sin(math.pi * min(1.0, t * 2.2)) + 0.13 * t ** 1.6
    rd = 0.19 - 0.02 * math.sin(math.pi * min(1.0, t * 2.2)) + 0.12 * t ** 1.6
    cz = 0.05 * (1.0 - t) - 0.05 * t

    def prof(a, t=t, rw=rw, rd=rd):
        fold = 1.0 + (0.035 + 0.06 * t) * math.sin(a * 7.0 + t * 2.0) + 0.02 * t * math.sin(a * 13.0)
        c_, s_ = math.cos(a), math.sin(a)
        return fold / math.sqrt((c_ / rd) ** 2 + (s_ / rw) ** 2)

    rings.append(section(V(0, y, cz), V(0, -1, 0), prof, 40, up=V(0, 0, 1)))
    cols.append(0.74 + 0.24 * t ** 1.3)


def robe_col(p, j, i):
    v = cols[j] * (0.94 + 0.08 * fbm3((p.x * 6, p.y * 6, p.z * 6), 2, 3))
    return (v, v, v)


loft(b, rings, (0.6, 0.6, 0.6), cls=CLOTH, col_fn=robe_col, bone_fn=body_w, tint=1.0, cap0=True, cap1=True, cap_push=0.25)


def strip(pts, widths, bones_, c0, c1, thick=0.022, fade=None):
    """A tattered strip of the robe: a flat, solid tongue of cloth tapering to a torn point."""
    n = len(pts)
    rr = []
    rc = []
    for j in range(n):
        d = (pts[min(n - 1, j + 1)] - pts[max(0, j - 1)]).normalized()
        w = widths[j]
        rr.append(section(pts[j], d, lambda a, w=w: 1.0 / math.sqrt((math.cos(a) / max(1e-4, thick)) ** 2 + (math.sin(a) / max(1e-4, w)) ** 2), 10,
                          up=V(pts[j].x, 0, pts[j].z).normalized() if V(pts[j].x, 0, pts[j].z).length > 1e-3 else V(0, 0, 1)))
        t = j / (n - 1)
        rc.append(c0 + (c1 - c0) * t)
    # (with `fade` the strip pales towards white as it falls below that height: the robe turning to mist)
    tf = (lambda p: 1.0 - 0.6 * smooth(fade, fade - 0.42, p.y)) if fade is not None else None
    return loft(b, rr, (0.8, 0.8, 0.8), cls=CLOTH, cols=[(v, v, v) for v in rc], bones=bones_, tint=1.0, tint_fn=tf, cap0=True, cap1=True, cap_push=0.4)


# the hem tatters into long strips streaming back like mist, palest at their torn points
for names, pts, a, out in STRIPS:
    fine = []
    fb = []
    for j in range(len(pts) - 1):
        for k in range(3):
            fine.append(pts[j].lerp(pts[j + 1], k / 3))
            fb.append({names[j]: 1.0})
    fine.append(pts[-1])
    fb.append({names[-1]: 1.0})
    m = len(fine)
    strip(fine, [0.1 * (1.0 - (i / (m - 1)) ** 1.6) + 0.004 for i in range(m)], fb, 0.94, 1.0, fade=HEM)

# ---------------------------------------------------------------- the dead's white cross-collar, the mourning rope, the talisman
b.cur_pal = 0.0
for k, (side, col_) in enumerate(((1, "ece6da"), (-1, "ece6da"))):
    pts = [V(0.13 * side, Y + 0.44, 0.08), V(0.03 * side, Y + 0.3, 0.2), V(-0.08 * side, Y + 0.12, 0.2)]
    if side < 0:
        # (laid left over right, the way the dead are dressed)
        pts = [p_ + V(0, 0, 0.012) for p_ in pts]
    b.tube(pts, [(0.035, 0.012), (0.035, 0.012), (0.03, 0.012)], col_, cls=CLOTH, bone="body", seg=8, up=(0, 0, 1))
belt = [V(math.sin(2 * math.pi * i / 28) * 0.24, Y - 0.02 + 0.015 * math.sin(i * 1.3), math.cos(2 * math.pi * i / 28) * 0.2 - 0.0) for i in range(29)]
b.tube(belt, [0.016] * 29, "b8a070", cls=CLOTH, bone="body", seg=6, cap0=False, cap1=False)
kc = V(0.08, Y - 0.03, 0.2)
b.ellipsoid(kc, (0.03, 0.024, 0.02), "a89060", cls=CLOTH, bone="body", seg=8, rings=5)
for dx in (-0.02, 0.025):
    b.tube([kc, kc + V(dx, -0.12, 0.02), kc + V(dx * 1.5, -0.24, 0.0)], [0.012, 0.011, 0.006], "b8a070", cls=CLOTH, bone="body", seg=5)
# a yellow paper talisman pinned to the breast, written in red
tc = V(-0.06, Y + 0.18, 0.225)
b.sheet([[tc + V(-0.04, -0.12, 0.0), tc + V(0.04, -0.12, 0.0)], [tc + V(-0.04, 0.0, 0.01), tc + V(0.04, 0.0, 0.01)], [tc + V(-0.04, 0.11, 0.0), tc + V(0.04, 0.11, 0.0)]],
        "e8cc58", cls=CLOTH, bone="body", cols=["dcbc48", "e8cc58", "e8cc58"], thickness=0.003)
for k in range(5):
    y0 = 0.08 - k * 0.042
    b.tube([tc + V(-0.018, y0, 0.012), tc + V(0.018, y0 - 0.012, 0.012)], [0.004, 0.004], "c01818", cls=CLOTH, bone="body", seg=4, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the hood: a deep peaked cowl, a void for a face, two burning eyes
hood = Clay(0.022, "wraith_hood")
hood.ellipsoid(V(0, Y + 0.62, 0.0), (0.2, 0.24, 0.22), bones={"head": 1.0}, tag="hood")
hood.chain([V(0, Y + 0.76, -0.05), V(0, Y + 0.88, -0.14), V(0, Y + 0.92, -0.25)], [0.13, 0.07, 0.025], bones={"head": 1.0}, tag="hood")
for s in (1, -1):
    hood.chain([V(0.13 * s, Y + 0.58, 0.02), V(0.2 * s, Y + 0.44, -0.02), V(0.24 * s, Y + 0.38, -0.04)], [0.1, 0.09, 0.08], bones=lambda p, t: body_w(p), tag="drape")
hood.chain([V(0, Y + 0.56, -0.12), V(0, Y + 0.42, -0.18), V(0, Y + 0.34, -0.17)], [0.14, 0.13, 0.11], bones=lambda p, t: body_w(p), tag="drape")


FACE = V(0, Y + 0.6, 0.17)


def hood_col(p, info):
    # the inside of the face opening is dark; the cowl itself a little lighter than the robe
    q = p - FACE
    inside = math.sqrt((q.x / 0.15) ** 2 + (q.y / 0.19) ** 2 + (q.z / 0.16) ** 2)
    v = 0.78 + 0.08 * smooth(Y + 0.4, Y + 0.85, p.y)
    if inside < 0.95 and info.n.z > -0.2:
        v = 0.1
    return (v, v, v)


def hood_tint(p, info):
    q = p - FACE
    inside = math.sqrt((q.x / 0.15) ** 2 + (q.y / 0.19) ** 2 + (q.z / 0.16) ** 2)
    return 0.0 if inside < 0.95 and info.n.z > -0.2 else 1.0


# the face opening, carved out of the cowl
hood.ellipsoid(FACE, (0.12, 0.16, 0.12), bones={"head": 1.0}, tag="hood", neg=True)
hood.build(b, hood_col, cls=CLOTH, tint_fn=hood_tint)
hit = A.surface(b)
h = hit(V(0, Y + 0.6, 1.0), V(0, 0, -1), 2.0)
fc = h[0] if h is not None else V(0, Y + 0.6, 0.1)
# the void at the back of the opening, nothing but dark, framed by a heavy rolled edge of cowl
b.ellipsoid(fc + V(0, -0.005, -0.03), (0.11, 0.15, 0.04), "07060c", cls=SKIN, bone="head", seg=18, rings=12, mat=MAT_PLAIN)
lip = []
for i in range(25):
    a = i / 24 * 2 * math.pi
    lip.append(FACE + V(math.sin(a) * 0.125, math.cos(a) * 0.165, 0.09 - 0.04 * (1.0 - math.cos(a)) * 0.5))
b.tube(lip, [0.032 if math.cos(i / 24 * 2 * math.pi) > -0.3 else 0.024 for i in range(25)], (0.88, 0.88, 0.88), cls=CLOTH, bone="head", tint=1.0, seg=8, cap0=False, cap1=False)
b.cur_pal = 1.0
for s in (1, -1):
    c = V(0.05 * s, FACE.y + 0.015, max(fc.z + 0.03, FACE.z - 0.05))
    b.ellipsoid(c, (0.038, 0.016, 0.012), (1.0, 1.0, 1.0), cls=CLOTH, bone="head", tint=1.0, rot=(0, 0, -0.22 * s), seg=12, rings=6, mat=MAT_GLOW)
    b.ellipsoid(c + V(0, 0, 0.006), (0.016, 0.007, 0.006), (1.0, 1.0, 1.0), cls=CLOTH, bone="head", tint=0.25, rot=(0, 0, -0.22 * s), seg=8, rings=5, mat=MAT_GLOW)
b.cur_pal = 0.0
# long black hair spilling out of the hood over the shoulders and down the breast
for s in (1, -1):
    for k in range(3):
        root = FACE + V(0.115 * s - 0.012 * k * s, 0.06 - 0.07 * k, 0.05 - 0.01 * k)
        dn = V(0.17 * s + 0.03 * k * s, -1.0, 0.2 - 0.05 * k).normalized()
        A.lock(b, root, dn, V(s * 0.3, 0.0, 1.0), 0.3 + 0.08 * k, 0.04, "1a1620", "2a2634", bone={"head": 0.4, "body": 0.6}, lift=0.12, rise=0.04,
               thick=0.35, tint=0.0, cls=HAIR, steps=7, seg=7, bend=0.05 * s, droop=0.15)

# ---------------------------------------------------------------- long hanging sleeves, and the hungry ghost's hands reaching out of them
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    fo = r.bones["fore." + sd]
    a0, a1, a2 = V(ar[0]), V(ar[1]), V(fo[1])
    cuff = a1.lerp(a2, 0.72)
    path = [a0 + V(-0.03 * s, 0.02, 0), a1, a1.lerp(a2, 0.4), cuff]
    rr = []
    rc = []
    for j, pc in enumerate(path):
        t = j / (len(path) - 1)
        d = (path[min(len(path) - 1, j + 1)] - path[max(0, j - 1)]).normalized()
        w = 0.085 + 0.07 * t
        drop = 0.09 + 0.26 * t * t      # the sleeve hangs far below the arm as it opens

        def prof(a, w=w, drop=drop):
            c_, s_ = math.cos(a), math.sin(a)
            # a teardrop hanging down: round above, drawn out below
            base = 1.0 / math.sqrt((c_ / w) ** 2 + (s_ / w) ** 2)
            return base + (drop * (-c_) ** 3 if c_ < 0 else 0.0)

        rr.append(section(pc, d, prof, 16, up=V(0, 1, 0)))
        rc.append(0.74 + 0.2 * t)
    bones_ = ["arm." + sd, "arm." + sd, {"arm." + sd: 0.4, "fore." + sd: 0.6}, "fore." + sd]
    loft(b, rr, (0.6, 0.6, 0.6), cls=CLOTH, cols=[(v, v, v) for v in rc], bones=bones_, tint=1.0, cap0=True, cap1=False, cap_push=0.3)
    # the sleeve's opening, dark inside, and tatters hanging from its hem
    b.ellipsoid(cuff + V(0, -0.07, 0.0), (0.1, 0.16, 0.03), "0c0a10", cls=SKIN, bone="fore." + sd, rot=(0.0, math.atan2((a2 - a1).x, (a2 - a1).z), 0.0),
                seg=12, rings=8, mat=MAT_PLAIN)
    for k in range(3):
        root = cuff + V((k - 1) * 0.06, -0.2 - 0.04 * (k % 2), -0.02)
        strip([root, root + V(0.01 * (k - 1), -0.12, -0.03), root + V(0.02 * (k - 1), -0.26, -0.06)], [0.04, 0.03, 0.005], ["fore." + sd] * 3, 0.88, 1.0, thick=0.014,
              fade=root.y)
    d = (a2 - a1).normalized()
    A.bony_hand(b, a2 - d * 0.06, d + V(0, -0.25, 0), 1.45, "fore." + sd, col="d8d0bc", spread=1.3, curl=0.55, side=s)

# ---------------------------------------------------------------- ghost-fire drifting round the hem
b.cur_pal = 1.0
for k in range(4):
    a = k / 4 * 2 * math.pi + 0.4
    c = V(math.sin(a) * 0.5, HEM - 0.1 + 0.1 * math.sin(k * 2.0), math.cos(a) * 0.42)
    A.blade(b, c - V(0, 0.05, 0), c + V(0.02 * math.sin(a), 0.1, 0.0), 0.04, (1.0, 1.0, 1.0), (0.85, 0.85, 0.85), bone="body", curl=0.05, thick=0.8,
            tint=1.0, cls=CLOTH, mat=MAT_GLOW, steps=4, seg=8, point=0.9)
b.cur_pal = 0.0

T_IDLE = 3.0


def drift(p, t, speed, amp):
    for k, (names, _, _, _) in enumerate(STRIPS):
        wave_chain(p, names, t + k * 0.3, speed, amp, axis=0, lag=0.8, grow=0.35)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    drift(p, t, w * 2, 0.14)
    p["body"] = ((0.08 + math.sin(t * w) * 0.04, math.sin(t * w + 0.8) * 0.08, 0), (0, 0.08 * math.sin(t * w), 0))
    p["head"] = ((0.12 + math.sin(t * w * 2) * 0.05, math.sin(t * w) * 0.18, math.sin(t * w + 1.1) * 0.08), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.12, 0, 0), (0, 0, 0))
        p["fore." + sd] = ((math.sin(t * w * 2 + s) * 0.12, 0, 0), (0, 0, 0))
    return p


def attack(t):
    """It lunges, both hands clawing forward out of the sleeves."""
    k = t / 0.55
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    drift(p, t, 14.0, 0.3)
    p["root"] = ((0, 0, 0), (0, 0.1 * lunge, 0.6 * lunge))
    p["body"] = ((0.3 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["arm." + sd] = ((-0.9 * e, 0, 0), (0, 0, 0))
        p["fore." + sd] = ((-0.4 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    drift(p, t, 22.0, 0.25 * e)
    p["body"] = ((-0.35 * e, 0, 0.15 * e), (0, 0, -0.2 * e))
    p["head"] = ((-0.4 * e, 0.3 * e, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    drift(p, t, 10.0, 0.35)
    p["body"] = ((-0.2 * e, 0, 0), (0, 0.25 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-1.4 * e, 0, -0.5 * e * s), (0, 0, 0))
    return p


T_WALK = 1.6


def walk(t):
    """Glides forward: leaning in, the strips streaming back, the arms trailing."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    drift(p, t, w * 2, 0.2)
    for k, (names, _, a_, _) in enumerate(STRIPS):
        for j, nm in enumerate(names):
            add(p, nm, (0.22 + 0.05 * j, 0, 0))
    add(p, "body", (0.22, 0, 0), (0, 0.05 * math.sin(t * w * 2), 0))
    add(p, "head", (-0.12, 0, 0))
    for sd in ("L", "R"):
        add(p, "arm." + sd, (0.45, 0, 0))
    return p


def die(t):
    """A last reach; the robe empties and collapses onto the ground."""
    k = min(1.0, t / 1.2)
    reach = math.sin(math.pi * smooth(0.0, 0.35, k))
    f = smooth(0.25, 0.85, k) ** 1.3
    p = idle(0.0)
    drift(p, t, 6.0, 0.25 * (1.0 - f))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-0.9 * reach + 0.8 * f, 0, s_ * 0.5 * f))
        add(p, "fore." + sd, (0.4 * f, 0, 0))
    add(p, "head", (0.3 * f - 0.4 * reach, 0.5 * f, 0.3 * f))
    p["body"] = ((0.25 * f, 0, 0), (0, -1.0 * f, -0.1 * f), (1.0 + 0.15 * f, 1.0 - 0.5 * f, 1.0 + 0.15 * f))
    return p


print("[art] wraith: %d triangles" % b.tri_count())
# the robe carries its own values (dark at the shoulders, pale where it fades at the hem): no coat split
kit.finish_rigged(b, r, "monsters/wraith.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  coat=False, samples=12, dist=0.25, strength=0.4)
