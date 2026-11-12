"""Feline anatomy shared by the big-cat monsters (``art/monsters/tiger.py``, ``kaiming.py``).

A big cat after the references (drawing tigers and lions, big-cat anatomy):

* **Silhouette.**  A long body hung between heavy forequarters and powerful haunches; the barrel
  wide; the shoulder blades ride above the line of the spine; the head right in front of the
  shoulders on a short, thick neck, carried about level with the back; legs long enough that the
  floor of the chest is at the elbows, massive in the forearm and thigh, then tapering to the
  wrist and hock before big round paws; a long tail carried low in a J.
* **Head.**  Compact and broad: a round skull that does not sit on the shoulders as a separate
  ball; a long, wide nose bridge running from between the eyes with almost no stop; the muzzle a
  protruding box, not two puffballs - whisker pads either side of a wide nose leather, a small
  chin tucked under them; the eyes high, about level with the top of the muzzle box, set beside
  the bridge and looking forward, round-pupilled; a wide ruff of fur on the cheeks that makes the
  head look bigger; small round ears set to the sides.  The mouth is closed at rest (the jaw is
  fitted under the whisker pads) and opens wide to roar.
* **Value.**  White above the eyes and over the cheeks, the whisker pads, chin, throat, belly and
  inner legs; black stripes that wrap the flanks and narrow towards the belly, ring the legs and
  the tail; dark lines from the eyes; the character "king" (wang) on the brow; black ear backs
  with a white spot (the ocelli); a black tail tip.  Painted in greys so every recolour (a jade
  lion, a snow tiger, a paper tiger) still reads as a great cat.

``build()`` returns the Builder, the rig, the head frame and the clips (idle, walk, attack, hurt,
die and a roar for cast), so a script can add to the body (more faces, armour, flames) before
exporting.
"""
import math

import anatomy as A
from clay import Clay, limb_weights
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth
from kit import CLOTH, MAT_PLAIN, SKIN, V, Builder, mix
from mammal import cat_nose, lip_line
from sculpt import fbm3

WHITE = (1.0, 1.0, 1.0)
# A short coat is painted matte (the toon shader's cloth class: a faint grain, no highlight band).
PELT = CLOTH


def _foreleg(c, sk, sd, H):
    """A big cat's foreleg: shoulder blade, a heavy upper arm and forearm tapering to a slim
    wrist, a short pastern and a broad round paw of four toes."""
    s = 1 if sd == "L" else -1
    sc, sh, el, wr, fb, ft = (sk[k + "." + sd] for k in ("sc", "sh", "el", "wr", "fb", "ft"))
    sb = "shoulder." + sd
    up, lo, mt, tb = "f_up." + sd, "f_lo." + sd, "f_meta." + sd, "f_toe." + sd
    c.ellipsoid(sc.lerp(sh, 0.45) + V(0.044 * H * s, 0, 0), (0.06 * H, 0.19 * H, 0.11 * H), rot=(0.35, 0, 0), bones={sb: 0.8, "chest": 0.2}, tag="leg")
    c.ellipsoid(sh.lerp(el, 0.5) + V(0.0, 0.0, -0.045 * H), (0.095 * H, 0.16 * H, 0.115 * H), rot=(-0.3, 0, 0), bones={up: 0.75, sb: 0.25}, tag="leg")
    c.chain([sh, el, wr, fb], [0.088 * H, 0.072 * H, 0.044 * H, 0.048 * H], bones=limb_weights([up, lo, mt]), tag="fleg", t0=0.0, t1=3.0)
    # the forearm: thick under the elbow, tapering to the wrist
    c.ellipsoid(el.lerp(wr, 0.3) + V(0.01 * H * s, 0.0, 0.018 * H), (0.068 * H, 0.13 * H, 0.066 * H), rot=(0.15, 0, 0), bones={lo: 1.0}, tag="fleg", t=1.3)
    c.ellipsoid(fb.lerp(ft, 0.3) + V(0, 0.014 * H, 0), (0.07 * H, 0.042 * H, 0.078 * H), bones={tb: 0.6, mt: 0.4}, tag="paw")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ball(fb.lerp(ft, 0.74) + V(u * 0.041 * H, 0.004 * H, -abs(u) * 0.02 * H), 0.027 * H, bones={tb: 1.0}, tag="paw")


def _hindleg(c, sk, sd, H):
    """A big cat's hind leg: the great thigh, the gaskin behind the shin, a slender hock and
    metatarsus and a round paw."""
    s = 1 if sd == "L" else -1
    hip, kn, hk, hb, ht = (sk[k + "." + sd] for k in ("hip", "kn", "hk", "hb", "ht"))
    up, lo, mt, tb = "h_up." + sd, "h_lo." + sd, "h_meta." + sd, "h_toe." + sd
    c.ellipsoid(hip.lerp(kn, 0.4) + V(0.025 * H * s, 0.0, -0.035 * H), (0.105 * H, 0.2 * H, 0.17 * H), rot=(-0.3, 0, 0), bones={up: 0.75, "pelvis": 0.25}, tag="leg")
    c.chain([hip, kn, hk, hb], [0.092 * H, 0.066 * H, 0.04 * H, 0.045 * H], bones=limb_weights([up, lo, mt]), tag="hleg", t0=0.0, t1=3.0)
    c.ellipsoid(kn.lerp(hk, 0.3) + V(0, 0.012 * H, -0.042 * H), (0.056 * H, 0.11 * H, 0.064 * H), rot=(-0.5, 0, 0), bones={lo: 1.0}, tag="hleg", t=1.3)
    c.ellipsoid(hb.lerp(ht, 0.3) + V(0, 0.013 * H, 0), (0.064 * H, 0.04 * H, 0.072 * H), bones={tb: 0.6, mt: 0.4}, tag="paw")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ball(hb.lerp(ht, 0.74) + V(u * 0.038 * H, 0.004 * H, -abs(u) * 0.018 * H), 0.025 * H, bones={tb: 1.0}, tag="paw")


def build(name="tiger", res=0.0145, head=True, extra=None):
    """The great cat.  `head` False leaves the neck without the cat's head (and its jaw, eyes and
    ears), for a script to put its own head(s) there; `extra` are more bones for quad_rig2."""
    H = 0.82
    sk = quad_skel(H=H, hip_z=-0.5, sh_z=0.4, hip_w=0.15, sh_w=0.15, foot="digit", withers=0.07, croup=0.0,
                   neck=(V(0, 0.92, 0.58), V(0, 0.94, 0.66)), head=V(0, 0.86, 1.0),
                   tail=[V(0, 0.81, -0.6), V(0, 0.75, -0.74), V(0, 0.64, -0.86), V(0, 0.51, -0.94), V(0, 0.39, -1.02), V(0, 0.32, -1.14), V(0, 0.33, -1.28)])
    for sd, s in (("L", 1), ("R", -1)):
        # the elbow at the floor of the chest, the wrist low, a short pastern
        sk["el." + sd] = V(0.15 * s, 0.4, 0.31)
        sk["wr." + sd] = V(0.15 * s, 0.12, 0.37)
        sk["fb." + sd] = V(0.15 * s, 0.035, 0.41)
        sk["ft." + sd] = V(0.15 * s, 0.022, 0.49)
        sk["kn." + sd] = V(0.155 * s, 0.45, -0.38)
        sk["hk." + sd] = V(0.15 * s, 0.22, -0.6)
        sk["hb." + sd] = V(0.15 * s, 0.035, -0.55)
        sk["ht." + sd] = V(0.15 * s, 0.022, -0.47)
    HC = V(0, 0.95, 0.79)                       # centre of the skull
    hf = A.HeadFrame(HC, V(0, -0.18, 1.0))
    K = 1.24                                    # head scale

    def hp(x, y, z):
        return hf.at(x * K, y * K, z * K)

    ear_base = (0.074, 0.074, -0.03)
    ears = [(hp(ear_base[0] * s, ear_base[1], ear_base[2]), hp(ear_base[0] * s * 1.15, ear_base[1] + 0.07, ear_base[2] - 0.005)) for s in (1, -1)]
    r, legs = quad_rig2(sk, ears=ears if head else None, extra=extra)
    # the jaw hinges at the back of the cheek, below and in front of the ear
    r.bones["jaw"] = (hp(0, -0.058, -0.005), hp(0, -0.085, 0.15), "head")
    b = Builder(name)

    # ---------------------------------------------------------------- body clay
    c = Clay(res, name + "_body")
    # torso: haunch, loin, a deep, wide keel of ribs, the brisket, and the withers where the
    # shoulder blades rise above the spine; a short thick neck straight into the back of the head
    A.clay_torso(c, sk, w=0.25, d=0.27, haunch=(0.22, 0.2, 0.21), withers=0.1, neck=(0.19, 0.175, 0.15), throat=0.14,
                 neck_pts=[V(0, 0.82, 0.4), V(0, 0.87, 0.55), V(0, 0.91, 0.66)])
    for sd in ("L", "R"):
        _foreleg(c, sk, sd, H)
        _hindleg(c, sk, sd, H)
    tail = sk.tail
    A.clay_tail(c, sk, [0.055, 0.045, 0.04, 0.038, 0.037, 0.036, 0.034])
    # the head: a broad round skull and forehead, wide cheekbones, the long broad bridge of the
    # nose, the muzzle box with its whisker pads either side of the nose, brows over the eyes,
    # sockets pressed in, and the cheek ruff
    A.head_clay(c, hf, K, [] if not head else [
        ("ell", (0, 0.028, -0.03), (0.098, 0.088, 0.1), "head", False, False),
        ("ell", (0, 0.044, 0.045), (0.074, 0.05, 0.062), "head", False, False),
        ("ell", (0.072, -0.012, 0.02), (0.05, 0.046, 0.06), "head", True, False),
        ("ell", (0.088, -0.045, -0.045), (0.052, 0.058, 0.058), "ruff", True, False),
        ("ell", (0.045, 0.06, 0.09), (0.03, 0.016, 0.026), "head", True, False),
        ("ell", (0, 0.03, 0.112), (0.044, 0.032, 0.062), "muzzle", False, False),
        ("ell", (0, -0.02, 0.122), (0.058, 0.042, 0.046), "muzzle", False, False),
        ("ell", (0.032, -0.045, 0.148), (0.035, 0.031, 0.031), "pad", True, False),
        ("ell", (0.043, -0.05, 0.1), (0.025, 0.022, 0.05), "pad", True, False),
        ("ell", (0, -0.054, 0.158), (0.022, 0.018, 0.022), "pad", False, False),
        ("ell", (0, 0.0, 0.166), (0.032, 0.024, 0.02), "muzzle", False, False),
        ("ell", (0.048, 0.036, 0.098), (0.026, 0.018, 0.02), "head", True, True),
    ])
    # the cheek ruff: soft tufts flaring back and out from the cheeks, the widest part of the head
    for s in ((1, -1) if head else ()):
        for k in range(3):
            root = hp((0.085 + 0.006 * k) * s, -0.03 - 0.03 * k, -0.04 - 0.012 * k)
            d = (-hf.f * 0.55 + hf.r * (0.7 * s) - hf.u * (0.15 + 0.32 * k)).normalized()
            ln = (0.075 - 0.008 * k) * K
            wd = (0.03 - 0.003 * k) * K
            c.chain([root, root + d * ln * 0.5, root + d * ln], [wd, wd * 0.8, wd * 0.38], bones={"head": 1.0} if k < 2 else {"head": 0.6, "neck1": 0.4},
                    tag="ruff", t0=0.0, t1=1.0)

    # ---------------------------------------------------------------- the coat
    def head_local(p):
        return hf.M.transposed() @ (p - HC) / K

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
        # wang), painted in the palette's accent colour as the cat's focal point
        k = 0.0
        if q.y > 0.06 and q.z > -0.05:
            for i in range(3):
                yy = 0.083 + 0.019 * i - 0.25 * (q.z - 0.04)
                k = max(k, smooth(0.0065, 0.0022, abs(q.y - yy)) * smooth(0.034 - 0.005 * i, 0.024 - 0.005 * i, abs(q.x)))
            k = max(k, smooth(0.0055, 0.002, abs(q.x)) * smooth(0.075, 0.088, q.y) * smooth(-0.02, 0.0, q.z) * (1.0 - smooth(0.06, 0.08, q.z)))
        return k

    def head_col(p, info):
        q = head_local(p)
        v = 0.8
        pad = info.share("pad")
        white = 0.0
        # the muzzle below the bridge, the whisker pads and the chin
        white = max(white, smooth(0.0, -0.022, q.y) * smooth(0.09, 0.12, q.z), smooth(0.4, 0.7, pad))
        # the white over each eye and the cheeks below the eyes, out into the ruff
        for s in (1, -1):
            white = max(white, smooth(0.026, 0.012, math.hypot(q.x - 0.052 * s, (q.y - 0.07) * 1.2)) * smooth(0.04, 0.08, q.z))
            white = max(white, smooth(0.05, 0.028, math.hypot((q.x - 0.07 * s) * 0.9, q.y + 0.03)) * smooth(-0.03, 0.03, q.z) * (1.0 - smooth(0.11, 0.13, q.z)))
        white = max(white, smooth(-0.05, -0.08, q.y))
        dark = 0.0
        # stripes on the cheeks and the ruff, sweeping back below the eyes
        for s in (1, -1):
            if q.x * s > 0.06 and q.z < 0.07:
                ph = (q.y + 0.4 * (q.z - 0.02)) * 40.0
                dark = max(dark, smooth(0.66, 0.8, 0.5 + 0.5 * math.cos(ph)) * smooth(0.065, 0.085, q.x * s))
        # the dark line from the inner corner of each eye down beside the bridge
        for s in (1, -1):
            along = (q.z - 0.1) / 0.05
            if 0.0 < along < 1.0:
                lx = 0.036 - 0.012 * along
                ly = 0.024 - 0.035 * along
                dark = max(dark, smooth(0.007, 0.0025, math.hypot(q.x * s - lx, q.y - ly)) * (1.0 - smooth(0.75, 1.0, along)))
        # broken stripes over the crown
        top = smooth(0.03, 0.09, q.y) * smooth(0.04, -0.06, q.z)
        dark = max(dark, 0.7 * stripes_body(p, 0.0) * top)
        # the lip line under the whisker pads
        dark = max(dark, smooth(0.5, 0.8, pad) * smooth(-0.064, -0.072, q.y))
        v = v * (1.0 - white) + 1.0 * white
        v = v * (1.0 - dark) + 0.12 * dark
        kw = king_w(q)
        v = v * (1.0 - kw) + 0.95 * kw
        return (v, v, v)

    def pal(p, info):
        if info.tag in ("head", "muzzle", "ruff", "pad") and king_w(head_local(p)) > 0.45:
            return 1.0
        return 0.0

    def col(p, info):
        tag = info.tag
        n = info.n
        if tag in ("head", "muzzle", "ruff", "pad"):
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
            return (0.92, 0.92, 0.92)
        if tag in ("fleg", "hleg", "leg"):
            side = 1 if p.x > 0 else -1
            inner = smooth(0.1, -0.5, n.x * side) * smooth(0.0, 0.5, info.t if tag != "leg" else 0.5)
            back = smooth(-0.3, -0.8, n.z) if tag == "fleg" else 0.0
            if tag == "leg":
                ring = stripes_body(p, 0.0) * 0.9
            else:
                ring = stripes_ring(p.y * 7.0 + (0.3 if tag == "hleg" else 0.0), p.z, 41 if tag == "fleg" else 43) * smooth(2.2, 1.4, info.t)
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

    c.build(b, col, cls=PELT, tint_fn=tint, smooth=1, pal_fn=pal)

    def cat_head():
        # ---------------------------------------------------------------- lower jaw, fitted under the whisker pads
        hit = A.surface(b)
        st = lip_line(hit, hf, K, [0.065, 0.085, 0.105, 0.125, 0.14, 0.155, 0.168], y_top=-0.02, y_bot=-0.11)
        j = Clay(res * 0.6, name + "_jaw")
        for k, (zq, yb, xb) in enumerate(st):
            f = k / max(1, len(st) - 1)
            hh = 0.024 * (1.0 - 0.3 * f)
            j.ellipsoid(hp(0, yb - hh * 0.5 + 0.005 + 0.004 * f, zq), (max(0.008, xb - 0.002) * K, hh * 0.5 * K, 0.02 * K), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
        if st:
            # the branches of the jaw back to the hinge, inside the cheeks
            z0, y0, x0 = st[0]
            for s in (1, -1):
                j.chain([hp(0.052 * s, -0.062, -0.01), hp(0.045 * s, -0.066, 0.05), hp(x0 * 0.85 * s, y0 - 0.008, z0)], [0.018 * K, 0.016 * K, 0.014 * K],
                        bones={"jaw": 1.0}, tag="jaw")
            # the chin, small and tucked under the pads
            zl, yl, xl = st[-1]
            j.ellipsoid(hp(0, yl - 0.014, zl - 0.006), (0.02 * K, 0.011 * K, 0.016 * K), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")

        def lip_y(zq):
            if not st:
                return -0.07
            if zq <= st[0][0]:
                return st[0][1]
            for (za, ya, _), (zb, yb2, _) in zip(st, st[1:]):
                if zq <= zb:
                    return ya + (yb2 - ya) * (zq - za) / max(1e-6, zb - za)
            return st[-1][1]

        def jaw_dark(p, info):
            q = head_local(p)
            front = smooth(0.04, 0.08, q.z)
            return max(smooth(lip_y(q.z) - 0.0005, lip_y(q.z) + 0.003, q.y) * front, smooth(0.15, 0.45, info.n.dot(hf.u)) * front)

        def jaw_col(p, info):
            return mix((0.97, 0.97, 0.97), (0.16, 0.06, 0.07), jaw_dark(p, info))

        j.build(b, jaw_col, cls=PELT, tint_fn=lambda p, info: 0.25 * (1.0 - jaw_dark(p, info)))
        # mouth: a dark roof (seen only when the jaw drops), a tongue, the canines and the incisors -
        # hanging below the lip line into the space the closed jaw fills
        b.ellipsoid(hp(0, lip_y(0.1) + 0.008, 0.095), (0.04 * K, 0.008 * K, 0.06 * K), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
        b.ellipsoid(hp(0, lip_y(0.1) - 0.004, 0.1), (0.026 * K, 0.006 * K, 0.05 * K), "b04050", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
        for s in (1, -1):
            A.fang(b, hp(0.024 * s, lip_y(0.14) + 0.014, 0.14), -hf.u, 0.017 * K, 0.0065 * K, "head", back=-hf.f, curve=0.2)
            A.fang(b, hp(0.02 * s, lip_y(0.135) - 0.01, 0.135), hf.u, 0.012 * K, 0.0055 * K, "jaw", back=-hf.f, curve=0.15)
        for k in range(4):
            u = (k / 3 - 0.5) * 2
            A.fang(b, hp(0.009 * u, lip_y(0.14) + 0.012, 0.142), -hf.u, 0.008 * K, 0.003 * K, "head", back=-hf.f, curve=0.0)
        # nose leather, eyes under their lids with the white patches above, whisker spots
        hn = hit(hp(0, 0.012, 0.4), -hf.f, 0.5)
        nose_at = hn[0] if hn is not None else hp(0, 0.012, 0.19)
        cat_nose(b, nose_at - hf.f * 0.004 * K, hf.f * 0.85 + hf.u * 0.3, 0.046 * K, 0.032 * K, "7a4a44", "head", depth=0.12)
        for s in (1, -1):
            A.animal_eye(b, hp(0.05 * s, 0.036, 0.1), hf.f + hf.r * (0.3 * s) + hf.u * 0.06, 0.0175 * K, "e8a020", "head", pupil="round",
                         almond=0.72, slant=0.16, side=s, lid="140a08", lid_w=0.15)
            for k in range(4):
                for m in range(4 - k // 2):
                    hw_ = hit(hp((0.022 + 0.0105 * m + 0.004 * k) * s, -0.026 - 0.0085 * k - 0.003 * m, 0.4), -hf.f, 0.5)
                    if hw_ is not None:
                        b.ball(hw_[0], 0.0022 * K, "2a1810", cls=SKIN, bone="head", seg=5, rings=3, mat=MAT_PLAIN)
        # ears: small, rounded, set to the sides; black backs with the white "eye spot"
        for s, sd in ((1, "L"), (-1, "R")):
            A.ear(b, hp(ear_base[0] * s, ear_base[1], ear_base[2]), hf.f * 0.75 + hf.r * (0.5 * s), 0.075 * K, 0.072 * K, 0.034 * K, (0.12, 0.12, 0.12), (0.95, 0.95, 0.95),
                  "ear." + sd, up=hf.u + hf.r * (0.3 * s), point=0.3, cup=0.55, tint=1.0, tint_in=0.3, spot=WHITE, side=s)
            A.lock(b, hp(ear_base[0] * s * 1.05, ear_base[1] + 0.008, ear_base[2] + 0.004), hf.u + hf.r * (0.3 * s) + hf.f * 0.1, hf.f, 0.035 * K, 0.016 * K,
                   (0.97,) * 3, (1.0,) * 3, bone="ear." + sd, lift=0.05, rise=0.02, thick=0.5, tint=0.25)


    if head:
        cat_head()

    # ---------------------------------------------------------------- claws
    for sd in ("L", "R"):
        A.toe_claws(b, sk, sd, 0.026, 0.0065, spread=0.041, paw=1.0)
        A.toe_claws(b, sk, sd, 0.022, 0.0055, hind=True, spread=0.038, paw=1.0)

    # ---------------------------------------------------------------- motion
    qm = QuadMotion(r, legs, T_walk=1.4, stride=0.42, lift=0.075, duty=0.64, bob=0.012, roll=0.035, yaw=0.06, head_nod=0.04,
                    head_low=0.06, tail_amp=0.1, tail_lift=-0.05, tail_droop=0.1, crouch=0.02, pounce="pounce", T_idle=4.0,
                    rest_h=0.2, lunge=0.5)
    # the mouth stays shut at rest and on the move (QuadMotion leaves it a crack open)
    raw_idle, raw_walk = qm.idle, qm.walk

    def shut_idle(t):
        p = raw_idle(t)
        add(p, "jaw", (-0.03, 0.0, 0.0))
        return p

    def shut_walk(t):
        p = raw_walk(t)
        add(p, "jaw", (-0.04, 0.0, 0.0))
        return p

    qm.idle, qm.walk = shut_idle, shut_walk

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
