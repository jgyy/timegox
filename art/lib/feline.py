"""Feline anatomy shared by the big-cat monsters (``art/monsters/tiger.py``, ``kaiming.py``).

A big cat after the references (drawing tigers and lions): a long, low body hung between heavy
forequarters and powerful haunches; the shoulder blades ride above the line of the spine and roll
with every step; the head sits directly in front of the shoulders on a short thick neck; a broad
round skull with wide cheekbones, a short muzzle with fat whisker pads, a broad nose, small
rounded ears set to the sides and a heavy ruff of fur on the cheeks; thick forearms on broad
round paws; a long tail carried low in a J.

The body is sculpted in clay (art/lib/clay.py) as one skin over the muscle masses, and the coat
is painted into the greys so a recolour still reads as a tiger: a pale belly, throat, inner legs,
muzzle and eye spots; stripes that wrap the flanks and narrow towards the belly, ring the legs
and the tail; the "king" mark on the brow; dark ear backs with a white spot; a black tail tip.

``build()`` returns the Builder, the rig, the head frame and the clips (idle, walk, attack, hurt,
die and a roar for cast), so a script can add to the body (more faces, armour, flames) before
exporting.
"""
import math

import anatomy as A
from clay import Clay
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth
from kit import CLOTH, MAT_PLAIN, SKIN, V, Builder, mix
from sculpt import fbm3

WHITE = (1.0, 1.0, 1.0)
# A short coat is painted matte (the toon shader's cloth class: a faint grain, no highlight band);
# the long fur of ruffs, tufts and manes uses the hair class with its sheen.
PELT = CLOTH


def build(name="tiger", res=0.0145):
    H = 0.8
    sk = quad_skel(H=H, hip_z=-0.5, sh_z=0.4, hip_w=0.15, sh_w=0.15, foot="digit", withers=0.07, croup=0.0,
                   neck=(V(0, 0.9, 0.58), V(0, 0.92, 0.66)), head=V(0, 0.84, 1.0),
                   tail=[V(0, 0.79, -0.6), V(0, 0.73, -0.74), V(0, 0.62, -0.86), V(0, 0.49, -0.94), V(0, 0.37, -1.02), V(0, 0.3, -1.14), V(0, 0.31, -1.28)])
    # heavy forearms: the elbow sits a little lower and further back on a big cat
    for sd, s in (("L", 1), ("R", -1)):
        sk["el." + sd] = V(0.15 * s, 0.38, 0.32)
        sk["wr." + sd] = V(0.15 * s, 0.11, 0.38)
        sk["fb." + sd] = V(0.15 * s, 0.035, 0.41)
        sk["ft." + sd] = V(0.15 * s, 0.022, 0.49)
        sk["kn." + sd] = V(0.155 * s, 0.43, -0.4)
        sk["hk." + sd] = V(0.15 * s, 0.2, -0.6)
        sk["hb." + sd] = V(0.15 * s, 0.035, -0.55)
        sk["ht." + sd] = V(0.15 * s, 0.022, -0.47)
    HC = V(0, 0.93, 0.79)                       # centre of the skull
    hf = A.HeadFrame(HC, V(0, -0.22, 1.0))
    K = 1.15                                    # head scale

    def hp(x, y, z):
        return hf.at(x * K, y * K, z * K)

    ears = [(hp(0.085, 0.07, -0.035), hp(0.1, 0.15, -0.04)), (hp(-0.085, 0.07, -0.035), hp(-0.1, 0.15, -0.04))]
    r, legs = quad_rig2(sk, ears=ears)
    # the jaw hinges below and in front of the ear, at the back of the cheek
    r.bones["jaw"] = (hp(0, -0.055, -0.01), hp(0, -0.09, 0.16), "head")
    b = Builder(name)

    # ---------------------------------------------------------------- body clay
    c = Clay(res, name + "_body")
    # torso: haunch, loin, a deep keel of ribs, the brisket, and the withers where the shoulder
    # blades rise above the spine; a short thick neck straight into the back of the head
    A.clay_torso(c, sk, w=0.25, d=0.275, haunch=(0.22, 0.2, 0.21), withers=0.1, neck=(0.19, 0.175, 0.15), throat=0.14,
                 neck_pts=[V(0, 0.8, 0.4), V(0, 0.85, 0.55), V(0, 0.89, 0.66)])
    for sd in ("L", "R"):
        # heavy forequarters on broad round paws, powerful haunches
        A.clay_foreleg(c, sk, sd, g=1.0, foot="paw", paw=1.0)
        A.clay_hindleg(c, sk, sd, g=1.0, foot="paw", paw=1.0)
    # the tail: a long even rope, carried low
    tail = sk.tail
    A.clay_tail(c, sk, [0.055, 0.045, 0.04, 0.038, 0.037, 0.036, 0.034])
    # the head: a broad round skull, wide cheekbones and cheek ruffs, a short muzzle with fat
    # whisker pads, a flat nose bridge; eye sockets pressed in
    A.head_clay(c, hf, K, [
        ("ell", (0, 0.02, -0.02), (0.11, 0.095, 0.115), "head", False, False),
        ("ell", (0, 0.045, 0.06), (0.085, 0.055, 0.07), "head", False, False),
        ("ell", (0.075, -0.03, 0.03), (0.055, 0.05, 0.065), "head", True, False),
        ("ell", (0.1, -0.06, -0.05), (0.05, 0.065, 0.06), "ruff", True, False),
        ("ball", (0.032, -0.045, 0.152), 0.038, "muzzle", True, False),
        ("ell", (0.045, 0.035, 0.1), (0.028, 0.02, 0.022), "head", True, True),
        ("ell", (0, -0.005, 0.13), (0.05, 0.045, 0.07), "muzzle", False, False),
        ("ell", (0, 0.022, 0.16), (0.033, 0.022, 0.05), "muzzle", False, False),
    ])

    # ---------------------------------------------------------------- the coat
    def spine_y(z):
        # top line: low croup, a dip behind the shoulders, the withers
        return 0.8 + 0.03 * math.exp(-((z - 0.3) / 0.15) ** 2) - 0.02 * math.exp(-((z + 0.1) / 0.2) ** 2)

    def head_local(p):
        return hf.M.transposed() @ (p - HC)

    def stripes_body(p, under):
        # vertical bands wrapping the flanks: thick over the back, narrowing and breaking up
        # towards the belly, a little wavy, some forked
        w = fbm3((p.x * 2.5, p.y * 2.5, p.z * 2.5), 2, 17)
        # stripes slant back as they run down the flank and curl round the haunch
        ph = p.z * 9.0 + (0.8 - p.y) * 2.2 + 0.7 * math.sin(p.y * 6.0 + p.z * 3.0) + 2.2 * (w - 0.5)
        ph += 1.2 * math.exp(-((p.z + 0.45) / 0.18) ** 2) * (0.75 - p.y) * 3.0
        band = max(0.5 + 0.5 * math.cos(2 * math.pi * ph), 0.92 * (0.5 + 0.5 * math.cos(2 * math.pi * (ph + 0.24))) * smooth(0.45, 0.6, w))
        top = smooth(0.62, 0.8, p.y)
        thr = 0.7 - 0.08 * top + 0.25 * under
        brk = smooth(0.3, 0.42, fbm3((p.x * 6.0 + 3.0, p.y * 6.0, p.z * 6.0), 2, 23))
        return smooth(thr, thr + 0.05, band) * brk

    def stripes_ring(t, x, seed, freq=1.0):
        w = fbm3((t * 3.0, x * 4.0, seed), 2, seed)
        band = 0.5 + 0.5 * math.cos(2 * math.pi * (t * freq + 0.8 * (w - 0.5)))
        return smooth(0.74, 0.8, band)

    def king_w(q):
        # the king mark: three bars across the brow and a stroke down the middle (the character
        # wang), painted in the palette's accent colour as the tiger's focal point
        k = 0.0
        if q.y > 0.055 and q.z > -0.06:
            for i in range(3):
                yy = 0.075 + 0.022 * i
                k = max(k, smooth(0.008, 0.002, abs(q.y - yy - 0.01 * q.z)) * smooth(0.045 - 0.006 * i, 0.03 - 0.006 * i, abs(q.x)))
            k = max(k, smooth(0.008, 0.002, abs(q.x)) * smooth(0.06, 0.08, q.y) * smooth(-0.04, 0.0, q.z))
        return k

    def head_col(p, info):
        q = head_local(p) / K
        under = smooth(-0.02, -0.07, q.y + 0.03 * (q.z > 0.08)) if q.z > -0.02 else 0.0
        v = 0.8
        # white: muzzle and whisker pads, the chin and throat, a spot over each eye, the cheeks
        white = 0.0
        white = max(white, smooth(0.11, 0.14, q.z) * smooth(0.01, -0.03, q.y))
        white = max(white, under)
        for s in (1, -1):
            white = max(white, smooth(0.028, 0.012, math.hypot(q.x - 0.045 * s, q.y - 0.075)) * smooth(0.04, 0.08, q.z))
            white = max(white, smooth(0.05, 0.03, math.hypot(q.x - 0.085 * s, (q.y + 0.04) * 1.2)) * smooth(-0.04, 0.02, q.z))
        dark = 0.0
        # cheek stripes sweeping back below the eyes
        for s in (1, -1):
            if q.x * s > 0.055 and q.z < 0.08:
                ph = (q.y + 0.35 * (q.z - 0.02)) * 38.0
                dark = max(dark, smooth(0.65, 0.8, 0.5 + 0.5 * math.cos(ph)) * smooth(0.06, 0.08, q.x * s) * (1.0 - white))
        # dark tear line and lip line
        for s in (1, -1):
            dark = max(dark, smooth(0.008, 0.002, abs((q.x - 0.03 * s) - 0.35 * (q.z - 0.1) * s)) * smooth(0.06, 0.04, q.y) * smooth(0.0, 0.03, q.y) * smooth(0.07, 0.11, q.z))
        top = smooth(0.0, 0.1, q.y) * smooth(0.02, -0.08, q.z)
        dark = max(dark, 0.5 * stripes_body(p, 0.0) * top)
        v = 0.8 * (1.0 - dark) + 0.12 * dark
        v = v * (1.0 - white) + 1.0 * white
        kw = king_w(q)
        v = v * (1.0 - kw) + 0.95 * kw
        return (v, v, v)

    def pal(p, info):
        if info.tag in ("head", "muzzle", "ruff") and king_w(head_local(p) / K) > 0.45:
            return 1.0
        return 0.0

    def col(p, info):
        tag = info.tag
        n = info.n
        if tag in ("head", "muzzle", "ruff"):
            return head_col(p, info)
        if tag == "tail":
            t = info.t / (len(tail) - 1)
            tip = smooth(0.86, 0.9, t)
            ring = stripes_ring(t * 8.0, p.x, 31) * smooth(0.25, 0.35, t)
            under = smooth(-0.2, -0.8, n.y) * (1.0 - smooth(0.4, 0.6, t))
            v = 0.8 * (1.0 - ring) + 0.12 * ring
            v = v * (1.0 - under) + 0.97 * under
            return (v * (1.0 - tip) + 0.1 * tip,) * 3
        if tag == "paw":
            return (0.9, 0.9, 0.9)
        if tag in ("fleg", "hleg", "leg"):
            side = 1 if p.x > 0 else -1
            inner = smooth(0.1, -0.5, n.x * side) * smooth(0.0, 0.5, info.t if tag != "leg" else 0.5)
            back = smooth(-0.3, -0.8, n.z) if tag == "fleg" else 0.0
            v = 0.8
            if tag == "leg":
                ring = stripes_body(p, 0.0) * 0.9
            else:
                t = info.t
                ring = stripes_ring(p.y * 7.0 + (0.3 if tag == "hleg" else 0.0), p.z, 41 if tag == "fleg" else 43) * smooth(2.2, 1.4, t)
            v = 0.8 * (1.0 - ring) + 0.12 * ring
            white = max(inner, back * 0.8)
            v = v * (1.0 - white) + 0.97 * white
            return (v, v, v)
        # body and neck: pale underneath, stripes over the back and flanks
        under = smooth(-0.15, -0.55, n.y)
        if tag == "neck":
            under = max(under, smooth(0.2, -0.3, n.y) * smooth(0.3, 0.9, n.z))
        s = stripes_body(p, under)
        v = 0.8 * (1.0 - s) + 0.12 * s
        v = v * (1.0 - under) + 0.98 * under
        return (v, v, v)

    def tint(p, info):
        # the pale coat keeps most of its own colour; orange and stripes take the enemy's
        if pal(p, info) > 0.5:
            return 1.0
        cc = col(p, info)[0]
        return 1.0 - 0.75 * smooth(0.88, 0.97, cc)

    body = c.build(b, col, cls=PELT, tint_fn=tint, smooth=1, pal_fn=pal)

    # ---------------------------------------------------------------- lower jaw (its own part)
    j = Clay(res * 0.8, name + "_jaw")
    for s in (1, -1):
        j.chain([hp(0.058 * s, -0.06, -0.02), hp(0.038 * s, -0.072, 0.07), hp(0.014 * s, -0.074, 0.14)], [0.024, 0.021, 0.019], bones={"jaw": 1.0}, tag="jaw")
    j.ellipsoid(hp(0, -0.078, 0.12), (0.034, 0.022, 0.035), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
    def jaw_col(p, info):
        # the inside of the mouth (facing up at the palate) is dark pink, the chin white
        return mix((0.97, 0.97, 0.97), (0.42, 0.16, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u)))

    j.build(b, jaw_col, cls=PELT, tint_fn=lambda p, info: 0.25 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
    # mouth: dark inside (seen only when the jaw drops), a tongue, canines
    b.ellipsoid(hp(0, -0.058, 0.08), (0.042, 0.016, 0.07), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
    b.ellipsoid(hp(0, -0.066, 0.085), (0.026, 0.008, 0.055), "b04050", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
    for s in (1, -1):
        A.fang(b, hp(0.027 * s, -0.05, 0.15), -hf.u, 0.036 * K, 0.007 * K, "head", back=-hf.f, curve=0.2)
        A.fang(b, hp(0.022 * s, -0.07, 0.135), hf.u, 0.024 * K, 0.006 * K, "jaw", back=-hf.f, curve=0.15)
    # nose leather, eyes under their lids, whisker spots
    A.nose_pad(b, hp(0, 0.006, 0.198), hf.f - hf.u * 0.5, 0.042 * K, 0.028 * K, "8a5a52", "head", kind="cat")
    for s in (1, -1):
        A.animal_eye(b, hp(0.047 * s, 0.033, 0.112), hf.f + hf.r * (0.32 * s) + hf.u * 0.1, 0.021 * K, "e8a020", "head", pupil="round",
                     almond=0.7, slant=0.18, side=s, tear=(0.05 * K, (hf.f * 0.4 - hf.u + hf.r * 0.25 * s).normalized()))
        for k in range(3):
            for m in range(3):
                b.ball(hp((0.025 + 0.012 * m) * s, -0.028 - 0.011 * k, 0.183 - 0.008 * m), 0.0035 * K, "2a1810", cls=SKIN, bone="head", seg=5, rings=3, mat=MAT_PLAIN)
    # ears: small, rounded, set to the sides; black backs with the white "eye spot"
    for s, sd in ((1, "L"), (-1, "R")):
        A.ear(b, hp(0.085 * s, 0.075, -0.035), hf.f * 0.7 + hf.r * (0.55 * s), 0.08 * K, 0.075 * K, 0.035 * K, (0.12, 0.12, 0.12), (0.95, 0.95, 0.95),
              "ear." + sd, up=hf.u + hf.r * (0.25 * s), point=0.35, cup=0.5, tint=1.0, tint_in=0.3, spot=WHITE, side=s)
    # the cheek ruff: broad locks sweeping back and down from the cheeks (sideburns)
    for s in (1, -1):
        for k in range(3):
            root = hp((0.1 + 0.004 * k) * s, -0.035 - 0.028 * k, -0.025 - 0.012 * k)
            groom = (-hf.f * 0.9 + hf.r * (0.25 * s) - hf.u * (0.3 + 0.2 * k)).normalized()
            A.lock(b, root, groom, hf.r * s, (0.075 - 0.008 * k) * K, (0.034 - 0.003 * k) * K, (0.97, 0.97, 0.97), (1.0, 1.0, 1.0),
                   bone="head", lift=0.15, rise=0.12, thick=0.4, tint=0.3)
    # chin tuft
    A.lock(b, hp(0, -0.1, 0.09), -hf.u * 0.8 - hf.f * 0.6, -hf.f, 0.05, 0.022, (0.97,) * 3, (1.0,) * 3, bone="jaw", lift=0.2, rise=0.1, thick=0.4, tint=0.25)
    # elbow tufts and a few belly-fringe locks in the pale coat
    for sd, s in (("L", 1), ("R", -1)):
        el = sk["el." + sd]
        A.lock(b, el + V(0.0, 0.02, -0.03), V(0.15 * s, -0.7, -1.0), V(s, 0, 0), 0.075, 0.03, (0.95,) * 3, (1.0,) * 3, bone={"f_lo." + sd: 0.6, "f_up." + sd: 0.4}, lift=0.1, rise=0.05, tint=0.3)
    for k in range(5):
        z = -0.2 + k * 0.1
        A.lock(b, V(0.0, 0.5, z), V(0, -0.45, -1.0), V(0, -1, 0), 0.08, 0.04, (0.97,) * 3, (1.0,) * 3,
               bone={"body": 1.0}, lift=0.1, rise=0.05, tint=0.3)

    # ---------------------------------------------------------------- claws
    for sd in ("L", "R"):
        A.toe_claws(b, sk, sd, 0.03, 0.007)
        A.toe_claws(b, sk, sd, 0.026, 0.006, hind=True, paw=0.92)

    # ---------------------------------------------------------------- motion
    qm = QuadMotion(r, legs, T_walk=1.4, stride=0.42, lift=0.075, duty=0.64, bob=0.012, roll=0.035, yaw=0.06, head_nod=0.04,
                    head_low=0.06, tail_amp=0.1, tail_lift=-0.05, tail_droop=0.1, crouch=0.02, pounce="pounce", T_idle=4.0,
                    rest_h=0.2, lunge=0.5)

    def roar(t):
        e = math.sin(math.pi * min(1.0, t / 0.6))
        p = qm.idle(0.0)
        add(p, "neck0", (-0.35 * e, 0, 0))
        add(p, "head", (-0.3 * e, 0, 0))
        add(p, "jaw", (0.9 * e, 0, 0))
        for e2 in ("ear.L", "ear.R"):
            add(p, e2, (0.5 * e, 0, 0))
        return p

    clips = qm.clips({"cast": (0.6, roar)})
    return b, r, hf, clips
