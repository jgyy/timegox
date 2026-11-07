"""Bird anatomy shared by the winged monsters: ``phoenix.py``, ``magpie.py``, ``sun_crow.py`` and
``bifang.py``.

A bird after the references: a deep keeled breast and a back that slopes to the rump, sculpted in
clay (art/lib/clay.py) with its plumage painted into the greys as rows of scalloped feathers; an
S-curved neck; a round skull with the beak in two parts (the lower on the jaw bone); wings on
three-bone chains (arm, forearm, hand) carrying a few large solid feathers - primaries on the hand,
secondaries along the forearm, tertials at the elbow - with rows of coverts over their roots;
a fanned tail on its own chain; feathered thighs, scaled shanks and four toes with hooked talons.

Styles:
* "phoenix": a plumed crest, a long neck ruff and long tail plumes ending in glowing eyes.
* "magpie": black head, back and wings that take the enemy's colour, a white belly and white
  wing patches that keep theirs, a long graduated tail with a sheen.
* "sun_crow": Jinwu, the three-legged golden crow of the sun - a big crow with three legs, its
  wings and tail edged in tongues of sun-fire and a ring of fire behind it.
* "bifang": the one-legged crane of the Classic of Mountains and Seas - blue-green with red
  markings and a white beak, standing on its single leg, flames running along its wings.

``build()`` returns the Builder, the rig and the clips (idle, walk, attack, hurt, die, cast).
Hovering birds hover and flap; the bifang stands and hops on its one leg.
"""
import math

import anatomy as A
from clay import Clay, limb_weights
from creature import add, leg_ik, Poser, smooth, zero_pose
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig, mix
from sculpt import fbm3

STYLES = {
    #               scale  body y  neck  beak     legs  crest  tail
    "phoenix": dict(S=1.0, Y=1.45, neck=0.32, beak="hook", legs=2, tail="plumes", crest=True),
    "magpie": dict(S=0.85, Y=1.35, neck=0.2, beak="crow", legs=2, tail="long", crest=False),
    "sun_crow": dict(S=1.15, Y=1.55, neck=0.24, beak="crow", legs=3, tail="fan", crest=False),
    "bifang": dict(S=1.0, Y=1.02, neck=0.5, beak="crane", legs=1, tail="short", crest=True),
}


def build(name="phoenix", style="phoenix"):
    cf = STYLES[style]
    S = cf["S"]
    Y = cf["Y"]
    C = V(0, Y, 0)
    stand = style == "bifang"
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.3, 0))
    r.bone("body", C + V(0, 0, -0.2 * S), C + V(0, 0.04 * S, 0.2 * S), "root")
    # the neck rises in an S from the breast to the skull
    nl = cf["neck"]
    if stand:
        NK = [C + V(0, 0.08, 0.2) * S, C + V(0, 0.28, 0.24) * S, C + V(0, 0.48, 0.16) * S, C + V(0, 0.62, 0.24) * S]
    else:
        NK = [C + V(0, 0.08, 0.2) * S, C + V(0, 0.08 + nl * 0.55, 0.26) * S, C + V(0, 0.1 + nl, 0.3) * S, C + V(0, 0.14 + nl * 1.15, 0.38) * S]
    r.bone("neck0", NK[0], NK[1], "body")
    r.bone("neck1", NK[1], NK[2], "neck0")
    HCt = NK[3] + V(0, 0.02, 0.05) * S
    r.bone("head", NK[2], HCt + V(0, 0.0, 0.15) * S, "neck1")
    r.bone("jaw", HCt + V(0, -0.03, 0.04) * S, HCt + V(0, -0.05, 0.25) * S, "head")
    WING = {}
    for s, sd in ((1, "L"), (-1, "R")):
        sh = C + V(0.13 * s, 0.1, 0.08) * S
        el = sh + V(0.38 * s, 0.07, -0.06) * S
        wr = el + V(0.4 * s, 0.0, 0.07) * S
        tp = wr + V(0.3 * s, -0.02, -0.03) * S
        WING[sd] = (sh, el, wr, tp)
        r.bone("wing.%s" % sd, sh, el, "body")
        r.bone("wing2.%s" % sd, el, wr, "wing.%s" % sd)
        r.bone("wing3.%s" % sd, wr, tp, "wing2.%s" % sd)
    LEGS = []
    leg_sides = {1: [(0, "C")], 2: [(1, "L"), (-1, "R")], 3: [(1, "L"), (-1, "R"), (0, "C")]}[cf["legs"]]
    for s, sd in leg_sides:
        zoff = -0.07 * S if sd == "C" else 0.0
        hip = C + V(0.08 * s, -0.1, 0.02) * S + V(0, 0, zoff)
        if stand:
            kn = hip + V(0.0, -0.06, 0.12) * S
            ank = V(hip.x, 0.38, hip.z - 0.06 * S)
            ball = V(hip.x, 0.03, hip.z + 0.02 * S)
            toe = ball + V(0, -0.01, 0.12) * S
        else:
            kn = hip + V(0.01 * s, -0.12, 0.08) * S
            ank = kn + V(0.0, -0.18, -0.1) * S
            ball = ank + V(0, -0.12, 0.04) * S
            toe = ball + V(0, -0.02, 0.1) * S
        r.bone("leg.%s" % sd, hip, kn, "body")
        r.bone("shin.%s" % sd, kn, ank, "leg.%s" % sd)
        r.bone("tars.%s" % sd, ank, ball, "shin.%s" % sd)
        r.bone("toe.%s" % sd, ball, toe, "tars.%s" % sd)
        LEGS.append((s, sd, hip, kn, ank, ball, toe))
    TL = [C + V(0, 0.0, -0.28) * S]
    if cf["tail"] == "long":
        TL += [TL[0] + V(0, -0.06, -0.32) * S, TL[0] + V(0, -0.14, -0.66) * S, TL[0] + V(0, -0.24, -1.0) * S]
    elif cf["tail"] == "plumes":
        TL += [TL[0] + V(0, -0.1, -0.42) * S, TL[0] + V(0, -0.3, -0.85) * S, TL[0] + V(0, -0.58, -1.25) * S]
    else:
        TL += [TL[0] + V(0, -0.04, -0.15) * S, TL[0] + V(0, -0.08, -0.3) * S, TL[0] + V(0, -0.12, -0.45) * S]
    for i in range(3):
        r.bone("tail%d" % i, TL[i], TL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))

    b = Builder(name)
    hf = A.HeadFrame(HCt, V(0, -0.1, 1.0))

    def hp(x, y, z):
        return hf.at(x * S, y * S, z * S)

    # ---------------------------------------------------------------- body clay
    c = Clay(0.014 * S, name + "_body")
    c.ellipsoid(C + V(0, -0.02, 0.06) * S, (0.19 * S, 0.21 * S, 0.24 * S), bones={"body": 1.0}, tag="breast")
    c.ellipsoid(C + V(0, 0.05, -0.08) * S, (0.16 * S, 0.12 * S, 0.27 * S), bones={"body": 1.0}, tag="back")
    c.ellipsoid(C + V(0, -0.08, -0.08) * S, (0.15 * S, 0.14 * S, 0.2 * S), bones={"body": 1.0}, tag="belly")
    c.ellipsoid(C + V(0, 0.0, -0.27) * S, (0.09 * S, 0.07 * S, 0.12 * S), bones={"body": 0.5, "tail0": 0.5}, tag="back")
    nr = (0.08, 0.062, 0.052) if not stand else (0.07, 0.045, 0.04)
    c.chain([NK[0], NK[1], NK[2], NK[3]], [nr[0] * S, nr[1] * S, nr[2] * S, nr[2] * S], bones=limb_weights(["neck0", "neck1", "head"]), tag="neck", t0=0.0, t1=3.0)
    c.ellipsoid(hp(0, 0.0, -0.01), (0.075 * S, 0.075 * S, 0.085 * S), rot=hf.M, bones={"head": 1.0}, tag="head")
    for s, sd, hip, kn, ank, ball, toe in LEGS:
        # feathered thighs ("trousers") blending into the belly
        c.ellipsoid(hip.lerp(kn, 0.5), (0.06 * S, 0.09 * S, 0.07 * S), bones={"leg.%s" % sd: 0.8, "body": 0.2}, tag="thigh")

    def plumage(p, info):
        n = info.n
        tag = info.tag
        g = fbm3((p.x * 8.0, p.y * 8.0, p.z * 8.0), 2, 3)
        # scalloped rows of contour feathers, each a little darker at its edge
        sx = (p.z * 12.0 / S) + 0.5 * (math.floor(p.y * 14.0 / S) % 2)
        sy = p.y * 14.0 / S
        fx, fy = sx - math.floor(sx), sy - math.floor(sy)
        scal = smooth(0.32, 0.5, math.hypot(fx - 0.5, fy - 0.8) * 1.2)
        v = 0.86 - 0.1 * scal + 0.05 * (g - 0.5)
        under = smooth(-0.1, -0.6, n.y) if tag in ("breast", "belly", "thigh") else 0.0
        if style == "magpie":
            white = smooth(-0.15, -0.45, n.y) * (1.0 if tag in ("belly", "breast", "thigh") else 0.0) * smooth(Y + 0.05 * S, Y - 0.05 * S, p.y)
            v = 0.2 + 0.06 * (1.0 - scal)
            return (v * (1.0 - white) + 0.97 * white,) * 3
        if style == "sun_crow":
            # golden: bright greys that take the enemy's colour, a little deeper on the back
            v = 0.86 + 0.06 * (1.0 - scal) - 0.08 * smooth(0.3, 0.9, n.y) + 0.06 * under
            return (v, v, v)
        if style == "bifang":
            # blue-green, a pale breast and red bars down the neck
            v = 0.78 - 0.08 * scal
            if tag == "neck":
                bar = smooth(0.7, 0.85, 0.5 + 0.5 * math.cos(info.t * 9.0)) * smooth(0.3, 0.6, n.dot(V(0, 0, 1)) * -1.0 + 0.5)
                return mix((v, v, v), (0.85, 0.15, 0.1), bar * 0.0)
            return (v * (1.0 - under) + 0.96 * under,) * 3
        return (v * (1.0 - under) + 0.97 * under,) * 3

    def tint(p, info):
        cc = plumage(p, info)
        if style == "magpie" and cc[0] > 0.9:
            return 0.0
        return 1.0 - 0.6 * smooth(0.9, 0.97, cc[0])

    c.build(b, plumage, cls=CLOTH, tint_fn=tint)
    if style == "bifang":
        # red markings on the neck and over the eye (they keep their colour)
        b.ellipsoid(hp(0, 0.07, -0.01), (0.05 * S, 0.02 * S, 0.06 * S), "d02010", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6)

    # ---------------------------------------------------------------- beak, eyes, crest
    b.cur_pal = 0.0
    if cf["beak"] == "crane":
        upper = [hp(0, 0.0, 0.07), hp(0, -0.01, 0.2), hp(0, -0.02, 0.33), hp(0, -0.035, 0.42)]
        A.horn(b, upper, 0.026 * S, "f4f0e0", "fffcf0", "head", r1=0.002, cls=STONE, seg=10, flat=0.75, up=(1, 0, 0))
        lower = [hp(0, -0.03, 0.07), hp(0, -0.038, 0.2), hp(0, -0.045, 0.38)]
        A.horn(b, lower, 0.018 * S, "e8e4d4", "fffcf0", "jaw", r1=0.002, cls=STONE, seg=8, flat=0.7, up=(1, 0, 0))
    else:
        hook = cf["beak"] == "hook"
        col0, col1 = ("e8b040", "a06818") if hook else ("2a2a30", "4a4a50")
        if style == "sun_crow":
            col0, col1 = ("f0c040", "c08018")
        upper = [hp(0, 0.01, 0.07), hp(0, 0.0, 0.14), hp(0, -0.02, 0.2), hp(0, -0.06 if hook else -0.035, 0.235 if hook else 0.25)]
        A.horn(b, upper, 0.04 * S, col0, col1, "head", r1=0.003, cls=STONE, seg=10, flat=0.8, up=(1, 0, 0))
        lower = [hp(0, -0.035, 0.07), hp(0, -0.045, 0.14), hp(0, -0.05, 0.2)]
        A.horn(b, lower, 0.028 * S, col0, col1, "jaw", r1=0.003, cls=STONE, seg=8, flat=0.7, up=(1, 0, 0))
        if hook:
            b.ellipsoid(hp(0, 0.01, 0.075), (0.042 * S, 0.03 * S, 0.025 * S), "e8a040", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=10, rings=6)
    iris = {"phoenix": "ff6020", "magpie": "2a2018", "sun_crow": "ffd030", "bifang": "f0c020"}[style]
    for s in (1, -1):
        A.animal_eye(b, hp(0.058 * s, 0.025, 0.035), hf.r * s + hf.f * 0.35, 0.022 * S, iris, "head", pupil="round", almond=0.9, side=s,
                     glow=style in ("phoenix", "sun_crow"), ring="e05030" if style == "phoenix" else None)
    if cf["crest"]:
        b.cur_pal = 1.0  # the crest crowns the head, the first focal point: the accent colour
        n_c = 7 if style == "phoenix" else 4
        for k in range(n_c):
            a = (k - (n_c - 1) / 2) * 0.16
            root = hp(math.sin(a) * 0.04, 0.07, -0.02)
            ln = (0.32 - abs(k - (n_c - 1) / 2) * 0.04) * S * (1.0 if style == "phoenix" else 0.6)
            tip = root + (hf.u * 0.75 - hf.f * 0.65 + hf.r * math.sin(a) * 0.6).normalized() * ln
            A.blade(b, root, tip, 0.03 * S, (0.75,) * 3, (1.0,) * 3, side=hf.r, bone="head", curl=0.12, thick=0.2)
            if style == "phoenix":
                b.ball(tip, 0.02 * S, "fff0a0", cls=CRYSTAL, bone="head", seg=8, rings=5, mat=MAT_GLOW)
        b.cur_pal = 0.0

    # ---------------------------------------------------------------- wings
    def wing_col(kind, u):
        if style == "magpie":
            if kind in ("covert",) and u < 0.55:
                return (0.97, 0.97, 0.97), (1.0, 1.0, 1.0), 0.0
            if kind == "primary":
                return (0.22, 0.22, 0.24), (0.97, 0.97, 0.97) if u > 0.5 else (0.3, 0.3, 0.32), 1.0
            return (0.24, 0.24, 0.26), (0.32, 0.32, 0.34), 1.0
        if style == "sun_crow":
            return (0.84, 0.84, 0.84), (0.6, 0.6, 0.6) if kind == "primary" else (0.95, 0.95, 0.95), 1.0
        if style == "bifang":
            return (0.72, 0.72, 0.72), (0.5, 0.5, 0.5) if kind == "primary" else (0.85, 0.85, 0.85), 1.0
        return (0.7, 0.7, 0.7), (1.0, 1.0, 1.0) if kind != "primary" else (0.45, 0.45, 0.45), 1.0

    for s, sd in ((1, "L"), (-1, "R")):
        sh, el, wr, tp = WING[sd]
        w1, w2, w3 = "wing.%s" % sd, "wing2.%s" % sd, "wing3.%s" % sd
        arm = [sh - V(0.05 * s, 0, 0) * S, sh, el, wr, tp]
        b.tube(arm, [0.05 * S, 0.042 * S, 0.032 * S, 0.024 * S, 0.01 * S], (0.8, 0.8, 0.8), cls=HAIR, tint=1.0, seg=10,
               bones=[{"body": 0.5, w1: 0.5}, w1, {w1: 0.5, w2: 0.5}, {w2: 0.5, w3: 0.5}, w3],
               cols=[(0.22,) * 3] * 5 if style == "magpie" else None)
        b.cur_pal = 0.5  # the flight feathers and coverts: the secondary colour, the wing's own
        # primaries: long feathers off the hand, fanning from the tip inwards
        for k in range(8):
            u = k / 7
            base = wr.lerp(tp, 1.0 - 0.85 * u)
            ang = 0.35 + 0.95 * u
            d = V(math.cos(ang) * s, -0.04, -math.sin(ang)).normalized()
            ln = (0.72 - 0.22 * u) * S
            c0, c1, tn = wing_col("primary", u)
            A.blade(b, base, base + d * ln, 0.1 * S, c0, c1, side=V(0, 1, 0).cross(d).normalized(), bone=w3 if u < 0.6 else {w3: 0.6, w2: 0.4},
                    curl=0.06, thick=0.12, tint=tn, point=0.35)
        # secondaries along the forearm, tertials at the elbow
        for k in range(8):
            u = k / 7
            base = wr.lerp(el, u)
            d = V(0.18 * s * (1.0 - u), -0.05, -1.0).normalized()
            ln = (0.48 - 0.06 * u) * S
            c0, c1, tn = wing_col("secondary", u)
            A.blade(b, base + V(0, 0.005, 0), base + d * ln, 0.095 * S, c0, c1, side=V(s, 0, 0), bone=w2 if u < 0.85 else {w2: 0.5, w1: 0.5},
                    curl=0.05, thick=0.12, tint=tn, point=0.2)
        for k in range(3):
            base = el.lerp(sh, 0.15 + 0.3 * k)
            d = V(0.05 * s, -0.08, -1.0).normalized()
            c0, c1, tn = wing_col("secondary", 1.0)
            A.blade(b, base + V(0, 0.01, 0), base + d * (0.36 - 0.06 * k) * S, 0.065 * S, c0, c1, side=V(s, 0, 0), bone=w1, curl=0.05, thick=0.12, tint=tn, point=0.2)
        # coverts: two rows of short feathers over the roots of the flight feathers
        for row in range(2):
            n_c = 10
            for k in range(n_c):
                u = k / (n_c - 1)
                base = sh.lerp(el, u * 2) if u < 0.5 else el.lerp(tp, (u - 0.5) * 1.6)
                d = V(0.12 * s, -0.05, -1.0).normalized()
                ln = (0.22 - 0.07 * row) * S
                c0, c1, tn = wing_col("covert", u)
                bone = w1 if u < 0.45 else (w2 if u < 0.8 else w3)
                A.blade(b, base + V(0, 0.022 + 0.014 * row, 0.03), base + d * ln + V(0, 0.022 + 0.014 * row, 0), 0.075 * S, c0, c1, side=V(s, 0, 0), bone=bone,
                        curl=0.08, thick=0.15, tint=tn, point=0.1)
        b.cur_pal = 0.0
        if style in ("sun_crow", "bifang"):
            # tongues of fire along the trailing edge of the wing, in the accent colour
            b.cur_pal = 1.0
            for k in range(7):
                u = k / 6
                base = el.lerp(tp, u) + V(0, 0.01, -0.3 * S * (1.0 - 0.4 * u))
                d = V(0.3 * s * u, 0.35, -1.0).normalized()
                A.lock(b, base, d, V(0, 1, 0), (0.24 - 0.08 * u) * S, 0.05 * S, "d0d0d0", "ffffff", bone=w2 if u < 0.5 else w3, lift=0.4, rise=0.3,
                       cls=HAIR, mat=MAT_GLOW, tint=1.0, bend=0.3 * s)
            b.cur_pal = 0.0

    # ---------------------------------------------------------------- tail
    tb = [{"tail0": 1.0}, {"tail1": 1.0}, {"tail2": 1.0}]
    if cf["tail"] == "plumes":
        b.cur_pal = 0.5
        for k in range(7):
            a = (k - 3) * 0.16
            pts = [TL[0], TL[1] + V(math.sin(a) * 0.15, 0.02 * abs(k - 3), 0) * S, TL[2] + V(math.sin(a) * 0.35, 0.03 * abs(k - 3), 0) * S, TL[3] + V(math.sin(a) * 0.55, 0.05 * abs(k - 3), 0) * S]
            for i in range(3):
                A.blade(b, pts[i], pts[i + 1], (0.05 + 0.025 * i) * S, (0.75,) * 3, (0.95,) * 3, side=V(1, 0, 0), bone=tb[i], curl=0.03, thick=0.15, point=0.0 if i < 2 else 0.3)
            b.ellipsoid(pts[3] + V(0, 0.012, 0.04) * S, (0.06 * S, 0.012 * S, 0.075 * S), "fff4b0", cls=CRYSTAL, bone="tail2", seg=10, rings=5, mat=MAT_GLOW)
            b.cur_pal = 1.0  # the eye of each plume in the accent colour
            b.ellipsoid(pts[3] + V(0, 0.02, 0.04) * S, (0.03 * S, 0.01 * S, 0.035 * S), "e8e8e8", cls=CRYSTAL, bone="tail2", seg=8, rings=4, mat=MAT_GLOW, tint=1.0)
            b.cur_pal = 0.5
        b.cur_pal = 0.0
    elif cf["tail"] == "long":
        for k in range(8):
            u = k / 7 - 0.5
            ln = 1.0 - abs(u) * 1.1
            root = TL[0] + V(u * 0.1, 0, 0) * S
            tip = root + V(u * 0.3, -0.24 * ln, -1.0 * ln) * S
            mid = root.lerp(tip, 0.5)
            A.blade(b, root, mid, 0.06 * S, (0.22, 0.24, 0.28), (0.25, 0.3, 0.36), side=V(1, 0, 0), bone={"tail0": 0.6, "tail1": 0.4}, curl=0.02, thick=0.12, point=0.0)
            A.blade(b, mid, tip, 0.065 * S, (0.25, 0.3, 0.36), (0.2, 0.28, 0.38), side=V(1, 0, 0), bone={"tail1": 0.5, "tail2": 0.5}, curl=0.02, thick=0.12, point=0.3)
    else:
        n_t = 9 if cf["tail"] == "fan" else 6
        ln = 0.5 if cf["tail"] == "fan" else 0.32
        for k in range(n_t):
            a = (k / (n_t - 1) - 0.5) * (1.1 if cf["tail"] == "fan" else 0.8)
            root = TL[0] + V(math.sin(a) * 0.05, 0, 0) * S
            tip = root + V(math.sin(a) * ln, -0.1, -math.cos(a) * ln) * S
            c0 = (0.85,) * 3 if style == "sun_crow" else (0.75,) * 3
            A.blade(b, root, tip, 0.08 * S, c0, (0.62,) * 3 if style == "sun_crow" else (0.5,) * 3, side=V(math.cos(a), 0, math.sin(a)), bone={"tail0": 0.4, "tail1": 0.6},
                    curl=0.04, thick=0.12, point=0.15)
            if style in ("sun_crow", "bifang"):
                b.cur_pal = 1.0
                A.lock(b, tip - V(0, 0, -0.02), (tip - root).normalized() + V(0, 0.3, 0), V(0, 1, 0), 0.16 * S, 0.04 * S, "d0d0d0", "ffffff", bone="tail2", lift=0.4, rise=0.3,
                       cls=HAIR, mat=MAT_GLOW, tint=1.0)
                b.cur_pal = 0.0

    # ---------------------------------------------------------------- legs: scaled shanks, toes, talons
    leg_col = {"phoenix": "c89030", "magpie": "2a2a30", "sun_crow": "c08a20", "bifang": "3a3a40"}[style]
    for s, sd, hip, kn, ank, ball, toe in LEGS:
        lg, sn, ts, tb2 = "leg.%s" % sd, "shin.%s" % sd, "tars.%s" % sd, "toe.%s" % sd
        b.tube([kn, kn.lerp(ank, 0.5), ank], [0.035 * S, 0.028 * S, 0.022 * S], leg_col, cls=SCALE, bones=[{lg: 0.5, sn: 0.5}, sn, {sn: 0.5, ts: 0.5}], seg=8)
        b.tube([ank, ank.lerp(ball, 0.5), ball], [0.022 * S, 0.018 * S, 0.02 * S], leg_col, cls=SCALE, bones=[{sn: 0.4, ts: 0.6}, ts, {ts: 0.5, tb2: 0.5}], seg=8)
        for k in range(4):
            a = (k - 1) * 0.5 if k < 3 else math.pi
            d = V(math.sin(a), 0, math.cos(a))
            ln = (0.1 if k < 3 else 0.05) * S * (1.4 if stand else 1.0)
            t1 = ball + d * ln * 0.55 + V(0, -0.01, 0) * S
            t2 = ball + d * ln + V(0, -0.015, 0) * S
            b.tube([ball, t1, t2], [0.014 * S, 0.012 * S, 0.01 * S], leg_col, cls=SCALE, bone=tb2, seg=6)
            A.claw(b, t2, d, 0.035 * S, 0.008 * S, tb2, down=V(0, -1, 0), hook=0.8, col0="2a2018", col1="6a5a40")

    if style == "bifang":
        for sd, sg in (("L", 1), ("R", -1)):
            sh, el, wr, tp = WING[sd]
            for k in range(5):
                q = sh.lerp(wr, 0.15 + 0.17 * k) + V(0, 0.045, -0.06 - 0.03 * (k % 2)) * S
                b.ellipsoid(q, (0.045 * S, 0.012 * S, 0.03 * S), "c82818", cls=HAIR, bone="wing.%s" % sd if k < 2 else "wing2.%s" % sd, seg=10, rings=5, mat=MAT_PLAIN)
        for k in range(4):
            b.ellipsoid(C + V(0.08 * ((k % 2) * 2 - 1), 0.12, -0.05 - 0.07 * k) * S, (0.03 * S, 0.012 * S, 0.04 * S), "c82818", cls=HAIR, bone="body", seg=10, rings=5, mat=MAT_PLAIN)

    if style == "sun_crow":
        # a ring of sun-fire behind the crow, its rays licking outwards
        ring_c = C + V(0, 0.15, -0.25) * S
        pts = [ring_c + V(math.cos(a) * 0.55, math.sin(a) * 0.55, 0) * S for a in [i / 24 * 2 * math.pi for i in range(25)]]
        b.tube(pts, [0.03 * S] * 25, "ffb030", cls=CRYSTAL, bone="body", seg=6, mat=MAT_GLOW, cap0=False, cap1=False)
        for k in range(12):
            a = k / 12 * 2 * math.pi
            base = ring_c + V(math.cos(a) * 0.55, math.sin(a) * 0.55, 0) * S
            A.lock(b, base, V(math.cos(a), math.sin(a), -0.2), V(0, 0, -1), 0.2 * S, 0.06 * S, "ff7020", "fff0a0", bone="body", lift=0.3, rise=0.1, cls=HAIR, mat=MAT_GLOW, tint=0.0)

    # ---------------------------------------------------------------- clips
    poser = Poser(r)

    def flap(p, t, T, amp, fold=0.0):
        w = 2 * math.pi / T
        f = math.sin(w * t)
        for sd, s in (("L", 1), ("R", -1)):
            add(p, "wing.%s" % sd, (0.05 * f, -0.12 * s * math.cos(w * t), -s * (amp * f + fold * 0.3)))
            add(p, "wing2.%s" % sd, (0.0, s * (0.15 * fold + 0.1 * max(0.0, -f)), -s * (amp * 0.6 * math.sin(w * t - 0.7) - 0.25 * fold)))
            add(p, "wing3.%s" % sd, (0.0, -s * (0.3 * fold + 0.15 * max(0.0, -f)), -s * amp * 0.5 * math.sin(w * t - 1.3)))

    def fold(p, k):
        """Hold the wings half open, drooping and swept back along the flanks."""
        for sd, sg in (("L", 1), ("R", -1)):
            add(p, "wing.%s" % sd, (0.0, 1.25 * sg * k, 0.05 * sg * k))
            add(p, "wing2.%s" % sd, (0.0, -0.2 * sg * k, -0.1 * sg * k))
            add(p, "wing3.%s" % sd, (0.0, 0.35 * sg * k, 0.0))

    def tail_sway(p, t, T, amp):
        w = 2 * math.pi / T
        for i in range(3):
            add(p, "tail%d" % i, (amp * 0.5 * math.sin(2 * w * t - i * 0.8), amp * math.sin(w * t - i * 0.7), 0.0))

    def tuck_legs(p, k=1.0):
        for s, sd, *_ in LEGS:
            add(p, "leg.%s" % sd, (0.5 * k, 0, 0))
            add(p, "shin.%s" % sd, (0.6 * k, 0, 0))
            add(p, "toe.%s" % sd, (0.8 * k, 0, 0))

    def look(p, t, T):
        w = 2 * math.pi / T
        add(p, "neck0", (0.04 * math.sin(2 * w * t), 0.12 * math.sin(w * t - 0.4), 0.0))
        add(p, "neck1", (0.03 * math.sin(2 * w * t + 1.0), 0.1 * math.sin(w * t - 0.2), 0.0))
        add(p, "head", (0.05 * math.sin(w * t * 2), 0.15 * math.sin(w * t), 0.06 * math.sin(w * t)))

    def plant_legs(p, offs=None):
        D = poser.fk(p)
        for i, (s, sd, hip, kn, ank, ball, toe) in enumerate(LEGS):
            o = offs[i] if offs else (0.0, 0.0, 0.0)
            res = leg_ik(r, D, ["leg.%s" % sd, "shin.%s" % sd, "tars.%s" % sd, "toe.%s" % sd], "body", ball + V(*o))
            for nm, val in res.items():
                p[nm] = val
        return p

    if not stand:
        T_IDLE, T_WALK = 2.4, 1.2

        def idle(t):
            p = zero_pose(r)
            w = 2 * math.pi / (T_IDLE / 2)
            add(p, "root", (0, 0, 0), (0, -0.07 * math.sin(w * t), 0))
            add(p, "body", (0.05 * math.sin(w * t), 0, 0))
            flap(p, t, T_IDLE / 2, 0.55)
            tail_sway(p, t, T_IDLE, 0.08)
            look(p, t, T_IDLE)
            tuck_legs(p, 0.6)
            return p

        def walk(t):
            p = zero_pose(r)
            w = 2 * math.pi / (T_WALK / 2)
            add(p, "root", (0, 0, 0), (0, -0.06 * math.sin(w * t), 0))
            add(p, "body", (0.28 + 0.04 * math.sin(w * t), 0, 0))
            add(p, "neck0", (-0.2, 0, 0))
            add(p, "head", (-0.1, 0, 0))
            flap(p, t, T_WALK / 2, 0.7)
            tail_sway(p, t, T_WALK, 0.06)
            tuck_legs(p, 1.0)
            return p

        def attack(t):
            k = t / 0.55
            ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.42, k))
            hit = smooth(0.3, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
            p = idle(t * 0.5)
            add(p, "root", (0, 0, 0), (0, 0.15 * ant - 0.25 * hit, -0.1 * ant + 0.55 * hit))
            add(p, "body", (-0.35 * ant + 0.45 * hit, 0, 0))
            add(p, "neck0", (-0.3 * ant + 0.3 * hit, 0, 0))
            add(p, "jaw", (0.6 * smooth(0.25, 0.4, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
            for s, sd, *_ in LEGS:
                add(p, "leg.%s" % sd, (-1.2 * hit - 0.5 + 0.2 * ant, 0, 0))
                add(p, "toe.%s" % sd, (-0.6 * hit, 0, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0.4 * s * ant - 0.3 * s * hit, s * 0.6 * ant))
            return p

        def hurt(t):
            k = t / 0.55
            e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
            p = idle(t * 0.3)
            add(p, "root", (0, 0, 0), (0, 0.1 * e, -0.3 * e))
            add(p, "body", (-0.35 * e, 0, 0.15 * e))
            add(p, "neck0", (-0.4 * e, 0.3 * e, 0))
            add(p, "head", (-0.2 * e, 0.2 * e, 0))
            add(p, "jaw", (0.4 * e, 0, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0, s * 0.5 * e))
            return p

        def die(t):
            """Wings go limp, the bird drops from the air and lies on its side, wings spread."""
            k = min(1.0, t / 1.2)
            drop = smooth(0.1, 0.62, k) ** 1.6
            roll = smooth(0.45, 0.85, k)
            bounce = 0.04 * math.sin(math.pi * smooth(0.62, 0.8, k)) * S
            p = zero_pose(r)
            ground = Y - 0.12 * S
            add(p, "root", (0.0, 0.0, 1.25 * roll), (-0.05 * roll, -ground * drop + bounce + 0.1 * S * roll, 0.0))
            flap(p, t * (1.0 - drop), 0.4, 0.5 * (1.0 - drop))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0.1 * drop, 0.0, (0.25 if s > 0 else -0.6) * drop))
                add(p, "wing2.%s" % sd, (0.0, 0.0, -0.15 * s * drop))
            add(p, "neck0", (0.5 * drop, 0.0, 0.0))
            add(p, "neck1", (0.4 * drop, -0.3 * roll, 0.0))
            add(p, "head", (0.3 * drop, 0.0, 0.3 * roll))
            add(p, "jaw", (0.3 * roll, 0, 0))
            tuck_legs(p, 0.3 + 0.7 * drop)
            for i in range(3):
                add(p, "tail%d" % i, (-0.1 * drop, 0.0, 0.0))
            return p

        def cast(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = idle(t * 0.4)
            add(p, "root", (0, 0, 0), (0, 0.2 * e, 0))
            add(p, "body", (-0.3 * e, 0, 0))
            add(p, "neck0", (-0.4 * e, 0, 0))
            add(p, "head", (-0.3 * e, 0, 0))
            add(p, "jaw", (0.5 * e, 0, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0.2 * e, 0, s * 0.9 * e))
                add(p, "wing2.%s" % sd, (0, 0, s * 0.4 * e))
            return p

        clips = {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}
    else:
        T_IDLE, T_WALK = 3.2, 0.8

        def stand_pose(t, T):
            p = zero_pose(r)
            w = 2 * math.pi / T
            br = math.sin(w * t * 2)
            add(p, "body", (0.03 * br, 0.04 * math.sin(w * t), 0.0), (0.0, 0.008 * br, 0.0))
            # wings folded along the body, feathers stirring; the flames lick along them
            fold(p, 0.95)
            flap(p, t, T / 2, 0.04)
            look(p, t, T)
            tail_sway(p, t, T, 0.05)
            return p

        def idle(t):
            return plant_legs(stand_pose(t, T_IDLE))

        def walk(t):
            """Hops on its one leg, wings beating once each hop for balance."""
            k = (t / T_WALK) % 1.0
            air = smooth(0.15, 0.3, k) * (1.0 - smooth(0.7, 0.85, k))
            # one crouch from landing (k = 0.83) to push-off (k = 0.17), deepest at k = 0
            crouch = bump((k + 0.5) % 1.0 - 0.5, 0.0, 0.17)
            p = stand_pose(t, T_WALK)
            hop = 0.16 * S * math.sin(math.pi * smooth(0.15, 0.85, k))
            add(p, "root", (0.0, 0.0, 0.0), (0.0, hop - 0.06 * S * crouch, 0.0))
            add(p, "body", (0.15 * crouch - 0.1 * air, 0.0, 0.0))
            add(p, "neck0", (-0.15 * crouch + 0.1 * air, 0.0, 0.0))
            fold(p, -0.45 * air)
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0.0, 0.0, -s * 0.5 * math.sin(2 * math.pi * k) * air))
            # the foot slides back on the ground (stance spans the crouch either side of k = 0)
            # and swings forward again in the air
            ks = (k + 0.15) % 1.0
            if ks < 0.3:
                dz = 0.08 * S * (1.0 - 2.0 * ks / 0.3)
            else:
                dz = 0.08 * S * (2.0 * smooth(0.3, 1.0, ks) - 1.0)
            dy = 0.1 * S * air
            p = plant_legs(p, [(0.0, dy - hop * 0.0, dz)])
            return p

        def attack(t):
            k = t / 0.55
            ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.4, k))
            hit = smooth(0.3, 0.4, k) * (1.0 - smooth(0.6, 1.0, k))
            p = stand_pose(t, T_IDLE)
            add(p, "body", (-0.25 * ant + 0.45 * hit, 0, 0))
            add(p, "neck0", (-0.4 * ant + 0.5 * hit, 0, 0))
            add(p, "neck1", (-0.3 * ant + 0.4 * hit, 0, 0))
            add(p, "head", (0.2 * ant + 0.2 * hit, 0, 0))
            add(p, "jaw", (0.4 * smooth(0.25, 0.38, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0, -s * 0.6 * (ant + hit)))
            return plant_legs(p)

        def hurt(t):
            k = t / 0.55
            e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
            p = stand_pose(t, T_IDLE)
            add(p, "body", (-0.3 * e, 0, 0.12 * e))
            add(p, "neck0", (-0.4 * e, 0.3 * e, 0))
            add(p, "head", (-0.2 * e, 0.2 * e, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0, -s * 0.9 * e))
            return plant_legs(p, [(0.0, 0.0, -0.05 * e)])

        def die(t):
            """The leg buckles; the crane topples onto its side, neck and wings sprawled."""
            k = min(1.0, t / 1.2)
            buckle = smooth(0.0, 0.4, k)
            fall = smooth(0.3, 0.75, k)
            p = stand_pose(0.0, T_IDLE)
            q = -0.15 * S
            a = 1.4 * fall
            add(p, "root", (0.0, 0.0, a), (q - math.cos(a) * q, -math.sin(a) * q - 0.45 * S * buckle * (1.0 - 0.3 * fall) - 0.25 * S * fall, 0.0))
            add(p, "neck0", (0.4 * buckle, -0.3 * fall, 0))
            add(p, "neck1", (0.5 * buckle, -0.4 * fall, 0))
            add(p, "head", (0.3 * buckle, 0, 0.3 * fall))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0, -s * 0.5 * fall))
            add(p, "leg.C", (0.9 * buckle, 0, 0))
            add(p, "shin.C", (-1.4 * buckle, 0, 0))
            add(p, "tars.C", (0.8 * buckle, 0, 0))
            return p

        def cast(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = stand_pose(t, T_IDLE)
            add(p, "neck0", (-0.35 * e, 0, 0))
            add(p, "head", (-0.4 * e, 0, 0))
            add(p, "jaw", (0.5 * e, 0, 0))
            for sd, s in (("L", 1), ("R", -1)):
                add(p, "wing.%s" % sd, (0, 0, s * 0.6 * e))
            return plant_legs(p)

        clips = {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}
    return b, r, clips


def bump(x, c, w):
    d = abs(x - c) / w
    return 0.5 + 0.5 * math.cos(math.pi * d) if d < 1.0 else 0.0
