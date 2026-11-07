"""Feline anatomy shared by the big-cat monsters (``art/monsters/tiger.py``, ``kaiming.py``).

``build()`` makes the tiger described in tiger.py - a long, low body with heavy shoulders and a
supple waist, broad paws, a round skull with a short muzzle, whisker pads and a cheek ruff, paired
stripes and the "king" mark, a ringed tail - and returns the Builder, the rig, the head frame and
the four clips, so a script can add to the body (more heads, armour, flames) before exporting.
"""
import math

import anatomy as A
from creature import quad_rig, tail_wave, weights_for, zero_pose
from kit import HAIR, MAT_PLAIN, V, Builder, b2g, env
from sculpt import catmull, fbm3, smooth, strand


def build(name="tiger"):
    BY = 0.8
    NECK = V(0, 1.02, 0.62)
    HEAD = V(0, 1.02, 0.96)
    TAIL = [(0, 0.92, -0.6), (0, 0.88, -0.86), (0, 0.72, -1.08), (0, 0.6, -1.32), (0, 0.66, -1.56)]
    r = quad_rig(BY, 0.42, -0.46, 0.15, NECK, HEAD, TAIL,
                 extra=[("ear.L", (0.1, 1.16, 0.74), (0.13, 1.24, 0.72), "head"), ("ear.R", (-0.1, 1.16, 0.74), (-0.13, 1.24, 0.72), "head")])
    b = Builder(name)
    body_bones = [n for n in r.bones if not n.startswith("ear") and n not in ("jaw", "root") and "_paw" not in n and "_lo" not in n]
    weights = weights_for(r, body_bones, sharp=3.0, k=3)

    sp = A.QuadSpec(hip_w=0.21, chest_w=0.22, chest_d=0.34, waist_d=0.24, waist_w=0.18, back_h=0.12, withers=0.05, neck_r=0.17, shade=(0.6, 1.0), seed=41)
    torso, spine_y = A.quad_body(b, r, sp, weights)


    def stripes(v, belly=True):
        """Paired stripes wrapping the flanks, narrowing towards the spine and breaking up on the
        belly; the belly and inner legs go pale and lose the tint."""
        p = b2g(v.co)
        c = v[b.cl]
        up = p.y - spine_y(p.z)
        wav = math.sin(p.z * 15.0 + 2.0 * math.sin(p.y * 6.0) + 0.6 * fbm3((p.x * 4, p.y * 4, p.z * 4), 2, 8))
        width = 0.75 + 0.2 * smooth(-0.3, 0.1, up)
        k = 1.0
        if wav > width and up > -0.28:
            k = 0.35
        pale = smooth(-0.22, -0.34, up) if belly else 0.0
        k = k * (1.0 - pale) + 1.3 * pale
        v[b.cl] = (min(1.0, c[0] * k), min(1.0, c[1] * k), min(1.0, c[2] * k), c[3])
        v[b.tl] = v[b.tl] * (1.0 - 0.8 * pale)


    for v in torso:
        stripes(v)
    legs = {}
    for nm in ("f", "h"):
        for sd in ("L", "R"):
            legs[nm + sd] = A.quad_leg(b, r, nm, sd, sp, spine_y, thick=1.2 if nm == "f" else 1.1, toes=4, claw_col="f0e8d8")
            for v in legs[nm + sd]:
                stripes(v, belly=False)

    # head: a round feline skull with whisker pads, a broad nose, small round ears and a cheek ruff
    hv = (HEAD - NECK).normalized()
    hf = A.HeadFrame(NECK + hv * 0.16 + V(0, 0.04, 0), hv + V(0, -0.1, 0))
    A.feline_head(b, hf, 1.25, eye_col="ffc020")
    for s in (1, -1):
        for k in range(6):
            root = hf.at(0.11 * s, -0.04 - k * 0.012, 0.0 - k * 0.012)
            strand(b, [root, root + hf.M @ V(0.06 * s, -0.01, -0.03), root + hf.M @ V(0.1 * s, -0.04 - 0.01 * k, -0.07)], 0.025, 0.003, (1.0, 1.0, 1.0), cls=HAIR, bone="head", flat=0.4, seg=5, per=3, tint=0.2, mat=MAT_PLAIN)
    # the "king" mark on the brow: three bars and a stroke
    for k in range(3):
        y = 0.1 + k * 0.025
        b.tube([hf.at(-0.04, y, 0.1 - k * 0.02), hf.at(0.04, y, 0.1 - k * 0.02)], [0.006, 0.006], (0.25, 0.25, 0.25), cls=HAIR, bone="head", seg=4, tint=1.0, mat=MAT_PLAIN)
    b.tube([hf.at(0, 0.1, 0.105), hf.at(0, 0.16, 0.06)], [0.006, 0.006], (0.25, 0.25, 0.25), cls=HAIR, bone="head", seg=4, tint=1.0, mat=MAT_PLAIN)
    # a short coat of clumps over the shoulders and back, a ruff at the throat
    A.fur(b, torso, 220, 0.05, 0.026, seed=44, bone_fn=weights, min_dist=0.04, col_root=(0.55, 0.55, 0.55), col_tip=(0.85, 0.85, 0.85),
          pred=lambda p, n: n.y > -0.2)
    for i in range(12):
        a = (i / 11 - 0.5) * 2.6
        root = V(math.sin(a) * 0.14, BY + 0.08 - abs(a) * 0.03, 0.62 + math.cos(a) * 0.05)
        strand(b, [root, root + V(math.sin(a) * 0.03, -0.08, 0.04), root + V(math.sin(a) * 0.05, -0.16, 0.02)], 0.03, 0.003, (1.0, 1.0, 1.0), cls=HAIR, bone="chest", flat=0.4, seg=5, per=3, tint=0.25, mat=MAT_PLAIN)
    # a long tail, ringed darker towards the tip
    tp = [V(p) for p in TAIL]
    core = catmull(tp, 3)
    tb = ["tail%d" % min(3, int(i / (len(core) - 1) * 3.999)) for i in range(len(core))]
    cols = [((0.8,) * 3 if (i // 2) % 2 == 0 else (0.35,) * 3) if i > len(core) * 0.5 else (0.75,) * 3 for i in range(len(core))]
    b.tube(core, [0.06 - 0.03 * i / len(core) for i in range(len(core))], (0.75, 0.75, 0.75), bones=tb, tint=1.0, seg=10, cls=HAIR, cols=cols)
    b.ball(core[-1], 0.035, (0.25, 0.25, 0.25), cls=HAIR, bone="tail3", seg=8, rings=6, tint=1.0)

    T_IDLE = 3.2


    def idle(t):
        w = 2 * math.pi / T_IDLE
        p = zero_pose(r)
        br = math.sin(t * w * 2)
        p["pelvis"] = ((0, 0, 0), (0, br * 0.008, 0))
        p["chest"] = ((br * 0.015, 0, 0), (0, br * 0.005, 0))
        p["neck"] = ((math.sin(t * w) * 0.04 - 0.08, math.sin(t * w) * 0.2, 0), (0, 0, 0))
        p["head"] = ((math.sin(t * w * 2) * 0.04, math.sin(t * w) * 0.12, 0), (0, 0, 0))
        p["jaw"] = ((0.03 + 0.05 * max(0.0, math.sin(t * w * 1.5)) ** 4, 0, 0), (0, 0, 0))
        p["ear.L"] = ((0, 0, -0.25 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
        p["ear.R"] = ((0, 0, 0.25 * max(0.0, math.sin(t * w * 3 + 1.0)) ** 8), (0, 0, 0))
        # the tail tip flicks, the rest sways slowly
        tail_wave(p, 4, t, w * 1.5, 0.12, curl=0.12)
        p["tail3"] = ((0.3 + 0.25 * max(0.0, math.sin(t * w * 2)) ** 3, 0, 0), (0, 0, 0))
        for sd in ("L", "R"):
            p["h_up." + sd] = ((-0.05, 0, 0), (0, 0, 0))
            p["h_lo." + sd] = ((0.08, 0, 0), (0, 0, 0))
        return p


    def attack(t):
        """A crouch, a pounce with both forepaws raised and claws out, and the bite."""
        k = t / 0.6
        e = env(k)
        crouch = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.42, k))
        leap = math.sin(min(1.0, max(0.0, (k - 0.28) * 1.8)) * math.pi)
        p = idle(0.0)
        p["root"] = ((0, 0, 0), (0, -0.08 * crouch + 0.15 * leap, 0.6 * leap))
        p["pelvis"] = ((0.15 * crouch - 0.3 * leap, 0, 0), (0, 0, 0))
        p["chest"] = ((0.2 * crouch - 0.35 * leap, 0, 0), (0, 0, 0))
        p["neck"] = ((0.25 * leap, 0, 0), (0, 0, 0))
        p["jaw"] = ((0.85 * leap, 0, 0), (0, 0, 0))
        for sd in ("L", "R"):
            p["f_up." + sd] = ((-1.2 * leap + 0.25 * crouch, 0, 0), (0, 0, 0))
            p["f_lo." + sd] = ((-0.3 * leap, 0, 0), (0, 0, 0))
            p["h_up." + sd] = ((0.5 * leap - 0.35 * crouch, 0, 0), (0, 0, 0))
            p["h_lo." + sd] = ((0.4 * crouch, 0, 0), (0, 0, 0))
        tail_wave(p, 4, t, 14.0, 0.15 + 0.15 * e)
        return p


    def hurt(t):
        e = env(t / 0.55)
        p = idle(0.0)
        p["root"] = ((0, 0, 0), (0, 0, -0.2 * e))
        p["chest"] = ((-0.25 * e, 0, 0.1 * e), (0, 0, 0))
        p["neck"] = ((-0.4 * e, 0.25 * e, 0), (0, 0, 0))
        p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
        for sd in ("L", "R"):
            p["ear." + sd] = ((0.7 * e, 0, 0), (0, 0, 0))
        return p


    def cast(t):
        """Head thrown back in a roar that shakes the ground."""
        e = env(t / 0.6)
        p = idle(0.0)
        p["pelvis"] = ((-0.1 * e, 0, 0), (0, 0, 0))
        p["neck"] = ((-0.5 * e, 0, 0), (0, 0, 0))
        p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
        p["jaw"] = ((1.0 * e, 0, 0), (0, 0, 0))
        for sd in ("L", "R"):
            p["ear." + sd] = ((0.5 * e, 0, 0), (0, 0, 0))
        tail_wave(p, 4, t, 10.0, 0.3, curl=0.5 * e)
        return p



    clips = {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}
    return b, r, hf, clips
