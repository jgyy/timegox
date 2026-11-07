"""Canine anatomy shared by ``art/monsters/beast.py`` (wolves and hounds) and ``fox.py``.

After the references on dog anatomy: a deep, narrow, keel-shaped chest reaching to the elbows and
a belly that tucks up to a slim waist; withers over the shoulder blades; long legs on four toes,
the stifle forward and the hock high behind; the neck carried forward and the head level with the
back.  The skull is domed with a clear *stop* in front of the eyes and a long tapering muzzle
ending in a black nose pad, with a separate lower jaw; the eyes are almond-shaped and slanted, the
ears tall and pointed.  The wolf wears a heavy ruff of long fur round the neck (sculpted locks
that belong to the silhouette, not a pelt of cards) and a bushy tail; the fox is slighter, with a
long narrow muzzle, big ears and (for the fox spirit) nine bushy tails.

Coat patterns are authored in the greys so any recolour still reads as the animal: the wolf's
dark saddle, pale underside, cheeks and inner legs, a facial mask and a dark tail tip; the fox's
white muzzle, throat and belly, black ear backs and stockings, and white tail tips.
"""
import math

import anatomy as A
from clay import Clay, limb_weights
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, mix
from sculpt import fbm3

PELT = CLOTH


def _sawtooth_fur(amp, freq, groom_t=True):
    """A displacement field that shingles a clay surface into backward-pointing clumps of fur."""
    def post(p, info, n=None):
        nn = info.n
        a = math.atan2(nn.x, nn.y)
        w = fbm3((p.x * 9.0, p.y * 9.0, p.z * 9.0), 2, 5)
        u = (info.t if groom_t else p.z) * freq + 0.35 * math.sin(a * 5.0) + 0.6 * w
        saw = (u - math.floor(u)) ** 1.6
        return nn * (amp * saw)
    return post


def build(name="beast", style="wolf", n_tails=1, res=0.0145):
    fox = style == "fox"
    H = 0.62 if fox else 0.8
    hip_z, sh_z = (-0.36, 0.3) if fox else (-0.42, 0.36)
    hw, sw = (0.095, 0.09) if fox else (0.12, 0.115)
    tail_n = 5
    tb = V(0, H - 0.02, hip_z - 0.08)
    if fox:
        tail = [tb + V(0, -0.05 * k * k * 0.3 + 0.03 * k, -0.17 * k) for k in range(tail_n + 1)]
    else:
        tail = [tb + V(0, -0.11 * k + 0.012 * k * k, -0.13 * k + 0.008 * k * k) for k in range(tail_n + 1)]
    neck0 = V(0, H + 0.05, sh_z + 0.05)
    neck1 = V(0, H + 0.12, sh_z + 0.17)
    headp = V(0, H + 0.14, sh_z + 0.25)
    snout = headp + V(0, -0.1, (0.36 if fox else 0.34))
    sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=hw, sh_w=sw, foot="digit", withers=0.05, neck=(neck1, headp), head=snout, tail=tail)
    for sd, s in (("L", 1), ("R", -1)):
        # long legs: the elbow sits at the bottom of the chest, the wrist low
        sk["el." + sd] = V(sw * s, 0.48 * H, sh_z - 0.07 * H)
        sk["wr." + sd] = V(sw * s, 0.15 * H, sh_z - 0.01 * H)
        sk["kn." + sd] = V(hw * s * 1.05, 0.55 * H, hip_z + 0.14 * H)
        sk["hk." + sd] = V(hw * s, 0.27 * H, hip_z - 0.13 * H)
    HC = headp + V(0, 0.0, 0.1)
    hf = A.HeadFrame(HC, V(0, -0.22, 1.0))
    K = 0.95 if fox else 1.15

    def hp(x, y, z):
        return hf.at(x * K, y * K, z * K)

    ears = [(hp(0.05, 0.06, -0.02), hp(0.065, 0.17, -0.03)), (hp(-0.05, 0.06, -0.02), hp(-0.065, 0.17, -0.03))]
    extra = []
    tails = []
    if n_tails > 1:
        base = tail[0]
        for k in range(n_tails):
            # a spray of tails behind the hips: spread round from side to side, the middle ones
            # raised high, the outer ones low and wide, each curling up at the tip
            u = k / (n_tails - 1) - 0.5
            az = u * 2.5
            el = 0.95 - 0.75 * abs(u) * 2 + 0.12 * math.sin(k * 2.1)
            ln = 1.0 - 0.15 * abs(math.sin(k * 2.3))
            pts = [base]
            for j in range(4):
                e2 = el + 0.12 * j * (1.0 - abs(u))
                a2 = az * (1.0 + 0.15 * j)
                d = V(math.sin(a2) * math.cos(e2), math.sin(e2), -math.cos(a2) * math.cos(e2))
                pts.append(pts[-1] + d * (0.15 * ln))
            tails.append(pts)
            prev = "pelvis"
            for j in range(4):
                extra.append(("ft%d_%d" % (k, j), pts[j], pts[j + 1], prev))
                prev = "ft%d_%d" % (k, j)
        sk.tail = [tail[0], tail[0] + V(0, 0.02, -0.06)]
    r, legs = quad_rig2(sk, ears=ears, extra=extra)
    r.bones["jaw"] = (hp(0, -0.045, -0.01), hp(0, -0.06, 0.19), "head")
    b = Builder(name)

    # ---------------------------------------------------------------- body
    c = Clay(res, name + "_body")
    if fox:
        A.clay_torso(c, sk, w=0.2, d=0.26, haunch=(0.19, 0.19, 0.2), tuck=0.06, withers=0.08, neck=(0.15, 0.13, 0.11), throat=0.12, chest_y=0.8)
    else:
        A.clay_torso(c, sk, w=0.19, d=0.29, haunch=(0.19, 0.2, 0.2), tuck=0.07, withers=0.1, neck=(0.19, 0.17, 0.14), throat=0.15, chest_y=0.78)
        # the mass of the ruff thickens the neck and the throat
        mid = sk["neck0"].lerp(sk["neck1"], 0.45)
        c.ellipsoid(mid + V(0, -0.02, -0.02), (0.18 * H, 0.2 * H, 0.16 * H), rot=(0.5, 0, 0), bones={"neck0": 0.7, "chest": 0.3}, tag="mane")
    for sd in ("L", "R"):
        A.clay_foreleg(c, sk, sd, g=0.72 if fox else 0.82, foot="paw", paw=0.78 if fox else 0.85, scap=0.9)
        A.clay_hindleg(c, sk, sd, g=0.75 if fox else 0.85, foot="paw", paw=0.78 if fox else 0.85)
    tail_clays = []
    if n_tails > 1:
        # every tail is its own clay so the brushes stay separate instead of webbing together
        for k, pts in enumerate(tails):
            ct = Clay(res, "%s_tail%d" % (name, k))
            ct.chain(pts, [0.03, 0.062, 0.082, 0.075, 0.042], bones=limb_weights(["ft%d_%d" % (k, j) for j in range(4)]), tag="tail%d" % k, t0=0.0, t1=4.0)
            tail_clays.append(ct)
    elif fox:
        A.clay_tail(c, sk, [0.04, 0.065, 0.08, 0.08, 0.07, 0.045])
    else:
        A.clay_tail(c, sk, [0.045, 0.06, 0.07, 0.068, 0.058, 0.04])
    # the head: a domed skull, a clear stop, a long tapering muzzle, wide cheekbones
    A.head_clay(c, hf, K, [
        ("ell", (0, 0.02, -0.015), (0.075, 0.07, 0.085), "head", False, False),
        ("ell", (0, 0.05, 0.045), (0.058, 0.04, 0.05), "head", False, False),
        ("ell", (0.05, -0.015, 0.02), (0.042, 0.038, 0.05), "head", True, False),
        ("ell", (0.068, -0.04, -0.03), (0.04, 0.05, 0.05), "ruff", True, False),
        ("ell", (0, -0.008, 0.09), (0.04, 0.038, 0.05), "muzzle", False, False),
        ("ell", (0, -0.016, 0.15), (0.032, 0.029, 0.05), "muzzle", False, False),
        ("ell", (0, -0.02, 0.198), (0.025, 0.023, 0.03), "muzzle", False, False),
        ("ell", (0.04, 0.03, 0.072), (0.02, 0.014, 0.017), "head", True, True),
    ])

    def head_local(p):
        return hf.M.transposed() @ (p - HC) / K

    def head_col(p, info):
        q = head_local(p)
        n = info.n
        if fox:
            v = 0.82
            white = max(smooth(-0.005, -0.03, q.y) * smooth(0.04, 0.09, q.z), smooth(0.04, 0.07, abs(q.x)) * smooth(-0.01, -0.035, q.y))
            white = max(white, smooth(-0.03, -0.06, q.y))
            dark = 0.0
            for s in (1, -1):
                # the dark tear line from the eye down the side of the muzzle
                dark = max(dark, smooth(0.007, 0.002, abs((q.y - 0.02) + 0.25 * (q.z - 0.08))) * smooth(0.045, 0.03, abs(q.x - 0.03 * s) * 1.0) * smooth(0.07, 0.1, q.z) * (1.0 if q.x * s > 0 else 0.0))
            dark = max(dark, smooth(0.205, 0.215, q.z) * 0.8)
            v = v * (1.0 - dark) + 0.15 * dark
            return (v * (1.0 - white) + 1.0 * white,) * 3
        # wolf: dark crown and muzzle top, pale cheeks, lips and eyebrow spots, darker mask
        v = 0.72 + 0.1 * smooth(0.06, -0.02, q.y)
        pale = max(smooth(0.0, -0.025, q.y) * smooth(0.05, 0.08, q.z), smooth(0.05, 0.075, abs(q.x)) * smooth(0.0, -0.03, q.y))
        pale = max(pale, smooth(-0.035, -0.06, q.y))
        for s in (1, -1):
            pale = max(pale, smooth(0.018, 0.008, math.hypot(q.x - 0.042 * s, q.y - 0.058)) * smooth(0.04, 0.07, q.z))
        top = smooth(0.0, 0.03, q.y) * smooth(0.08, 0.14, q.z)
        v = v * (1.0 - 0.35 * top)
        v = v * (1.0 - pale) + 0.95 * pale
        return (v, v, v)

    def col(p, info):
        tag = info.tag
        n = info.n
        if tag in ("head", "muzzle", "ruff"):
            return head_col(p, info)
        if tag.startswith("tail"):
            if n_tails > 1:
                t = info.t / 4.0
            else:
                t = info.t / (len(sk.tail) - 1)
            tip = smooth(0.7, 0.82, t)
            if fox:
                v = 0.8 * (1.0 - tip) + 1.0 * tip
            else:
                v = 0.6 - 0.12 * smooth(-0.2, 0.6, n.y) + 0.25 * smooth(-0.2, -0.8, n.y)
                v = v * (1.0 - tip) + 0.14 * tip
            return (v, v, v)
        if tag == "paw":
            return (0.1, 0.1, 0.1) if fox else (0.82, 0.82, 0.82)
        under = smooth(-0.1, -0.55, n.y)
        if tag in ("fleg", "hleg", "leg"):
            side = 1 if p.x > 0 else -1
            inner = smooth(0.1, -0.5, n.x * side)
            if fox:
                stock = smooth(1.15, 1.6, info.t) if tag != "leg" else 0.0
                v = 0.8 * (1.0 - stock) + 0.1 * stock
                w = inner * (1.0 - stock) * 0.8
                return (v * (1.0 - w) + 0.98 * w,) * 3
            v = 0.8 + 0.08 * smooth(1.0, 2.0, info.t if tag != "leg" else 0.0)
            front = smooth(0.3, 0.8, n.z) * smooth(1.0, 1.4, info.t) * (1.0 - smooth(2.3, 2.7, info.t)) if tag == "fleg" else 0.0
            v = v * (1.0 - 0.35 * front)
            w = max(inner, under) * 0.85
            return (v * (1.0 - w) + 0.92 * w,) * 3
        if tag == "mane":
            g = fbm3((p.x * 10.0, p.y * 10.0, p.z * 10.0), 2, 4)
            v = 0.86 + 0.1 * (g - 0.5) - 0.12 * smooth(0.6, 1.0, n.y)
            return (v * (1.0 - under) + 0.95 * under,) * 3
        # body and neck
        if tag == "neck":
            under = max(under, smooth(0.2, -0.3, n.y) * smooth(0.2, 0.8, n.z))
        if fox:
            v = 0.8 - 0.08 * smooth(0.0, 0.8, n.y)
            return (v * (1.0 - under) + 1.0 * under,) * 3
        # the wolf's saddle: dark along the back and over the shoulders, grizzled with noise
        sad = smooth(0.25, 0.75, n.y) * smooth(-0.5, -0.2, p.z) * (1.0 - smooth(0.25, 0.45, p.z))
        sad = max(sad, smooth(0.5, 0.9, n.y) * 0.6)
        g = fbm3((p.x * 12.0, p.y * 12.0, p.z * 12.0), 2, 9)
        v = 0.84 - 0.26 * sad + 0.1 * (g - 0.5)
        return (v * (1.0 - under) + 0.94 * under,) * 3

    def tint(p, info):
        cc = col(p, info)[0]
        return 1.0 - 0.7 * smooth(0.86, 0.97, cc)

    brush = _sawtooth_fur(0.018, 3.2)

    def post(p, info):
        if info.tag.startswith("tail"):
            return brush(p, info)
        if info.tag == "mane":
            # the ruff shingled into clumps that point back and down
            nn = info.n
            a = math.atan2(nn.x, nn.y)
            w = fbm3((p.x * 9.0, p.y * 9.0, p.z * 9.0), 2, 7)
            u = -p.z * 16.0 + 0.4 * math.sin(a * 6.0) + 0.7 * w - p.y * 4.0
            saw = (u - math.floor(u)) ** 1.8
            k = info.share("mane")
            return nn * (0.03 * saw * smooth(0.3, 0.7, k))
        return None

    c.build(b, col, cls=PELT, tint_fn=tint, post=post)
    for ct in tail_clays:
        ct.build(b, col, cls=PELT, tint_fn=tint, post=post)

    # ---------------------------------------------------------------- lower jaw, mouth, nose, eyes, ears
    j = Clay(res * 0.8, name + "_jaw")
    for s in (1, -1):
        j.chain([hp(0.042 * s, -0.05, -0.0), hp(0.024 * s, -0.056, 0.1), hp(0.008 * s, -0.052, 0.18)], [0.019, 0.016, 0.013], bones={"jaw": 1.0}, tag="jaw")

    def jaw_col(p, info):
        return mix((0.96, 0.96, 0.96) if not fox else (1.0, 1.0, 1.0), (0.42, 0.16, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u)))

    j.build(b, jaw_col, cls=PELT, tint_fn=lambda p, info: 0.3 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
    b.ellipsoid(hp(0, -0.036, 0.09), (0.022, 0.01, 0.085), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
    b.ellipsoid(hp(0, -0.048, 0.1), (0.02, 0.006, 0.07), "b04050", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
    for s in (1, -1):
        A.fang(b, hp(0.02 * s, -0.035, 0.175), -hf.u, 0.03 * K, 0.0055 * K, "head", back=-hf.f, curve=0.25)
        A.fang(b, hp(0.016 * s, -0.052, 0.16), hf.u, 0.022 * K, 0.005 * K, "jaw", back=-hf.f, curve=0.2)
    A.nose_pad(b, hp(0, -0.008, 0.226), hf.f + hf.u * 0.15, 0.034 * K, 0.026 * K, "1a1416", "head", kind="dog")
    for s in (1, -1):
        A.animal_eye(b, hp(0.04 * s, 0.03, 0.082), hf.f + hf.r * (0.45 * s) + hf.u * 0.12, 0.016 * K, "e0a020" if not fox else "f0b030", "head",
                     pupil="slit" if fox else "round", almond=0.58, slant=0.3, side=s)
    for s, sd in ((1, "L"), (-1, "R")):
        A.ear(b, hp(0.05 * s, 0.06, -0.02), hf.f * 0.85 + hf.r * (0.25 * s) + hf.u * 0.05, (0.15 if fox else 0.11) * K, (0.09 if fox else 0.07) * K, 0.03 * K,
              (0.12, 0.12, 0.12) if fox else (0.5, 0.5, 0.5), (0.97, 0.97, 0.97), "ear." + sd, up=hf.u + hf.r * (0.3 * s), point=0.9, cup=0.6,
              tint=1.0, tint_in=0.25, rim_col=None if fox else (0.3, 0.3, 0.3), side=s, tip_col=(0.1, 0.1, 0.1) if fox else None)
        # a tuft of pale fur inside the ear
        A.lock(b, hp(0.05 * s, 0.07, -0.005), hf.u + hf.f * 0.3, hf.f, 0.045 * K, 0.018 * K, (0.97,) * 3, (1.0,) * 3, bone="ear." + sd, lift=0.1, rise=0.1, tint=0.2)

    # ---------------------------------------------------------------- fur: cheek ruffs and (wolf) the neck ruff
    pale = (0.95, 0.95, 0.95)
    for s in (1, -1):
        for k in range(3):
            root = hp((0.068 + 0.004 * k) * s, -0.02 - 0.022 * k, -0.02 - 0.012 * k)
            groom = (-hf.f * 0.85 + hf.r * (0.3 * s) - hf.u * (0.3 + 0.2 * k)).normalized()
            A.lock(b, root, groom, hf.r * s, (0.07 - 0.006 * k) * K, (0.028 - 0.003 * k) * K, pale if fox else (0.9, 0.9, 0.9), (1.0,) * 3,
                   bone="head", lift=0.15, rise=0.15, thick=0.4, tint=0.3 if fox else 0.6, cls=HAIR)
    if not fox:
        # the ruff: two rows of broad locks lying back round the neck, longest under the throat
        NB = sk["neck0"]
        NT = sk["neck1"]
        for row in range(2):
            c0 = NT.lerp(NB, 0.35 + row * 0.5)
            rad = 0.16 * H * (1.0 + 0.15 * row)
            n_l = 9 + row * 2
            for i in range(n_l):
                a = (i + 0.5 * (row % 2)) / n_l * 2 * math.pi
                out = V(math.sin(a), math.cos(a) * 1.1, -0.15).normalized()
                root = c0 + V(math.sin(a) * rad * 0.85, math.cos(a) * rad * 0.9, 0.0)
                groom = (out * 0.25 + V(0, -0.45 if math.cos(a) < 0.3 else -0.15, -1.0)).normalized()
                ln = (0.12 + 0.03 * row + 0.05 * smooth(0.3, -0.9, math.cos(a))) * H / 0.8
                shade = 0.92 if math.cos(a) < -0.2 else 0.78
                w = {"neck0": 0.6, "chest": 0.4} if row else {"neck1": 0.5, "neck0": 0.5}
                A.lock(b, root, groom, out, ln, 0.075 * H / 0.8, (shade,) * 3, (min(1.0, shade + 0.1),) * 3, bone=w, lift=0.3, rise=0.08, thick=0.4, tint=1.0 if shade < 0.9 else 0.5, cls=HAIR)
        # a pale bib down the chest and tufts at the elbows and the back of the thighs
        for i in range(5):
            u = (i / 4 - 0.5) * 2
            root = V(u * 0.05, 0.62 * H, sh_z + 0.1 * H - abs(u) * 0.02)
            A.lock(b, root, V(u * 0.2, -1.0, 0.35), V(u * 0.3, -0.2, 1.0), 0.11 * H / 0.8, 0.04, (0.94,) * 3, (1.0,) * 3, bone="chest", lift=0.2, rise=0.12, tint=0.4, cls=HAIR)
        for sd, s in (("L", 1), ("R", -1)):
            el = sk["el." + sd]
            A.lock(b, el + V(0.0, 0.02, -0.025), V(0.1 * s, -0.7, -1.0), V(s, 0, 0), 0.06, 0.025, (0.85,) * 3, (0.95,) * 3, bone={"f_lo." + sd: 0.6, "f_up." + sd: 0.4}, lift=0.1, rise=0.05, cls=HAIR)
            kn = sk["kn." + sd]
            hk = sk["hk." + sd]
            for k in range(2):
                q = kn.lerp(hk, 0.2 + 0.3 * k) + V(0, 0, -0.04)
                A.lock(b, q, V(0.1 * s, -0.8, -0.6), V(s * 0.5, 0, -1.0), 0.07, 0.03, (0.85,) * 3, (0.95,) * 3, bone="h_lo." + sd, lift=0.1, rise=0.05, cls=HAIR)
        # the tail's brush: a few broad locks along its underside and a pointed dark tip
        tl = sk.tail
        for i in range(1, len(tl) - 1):
            d = (tl[i + 1] - tl[i - 1]).normalized()
            for k in range(3):
                a = (k - 1) * 0.9 + math.pi
                side = d.cross(V(0, 1, 0)).normalized()
                up = side.cross(d).normalized()
                out = (side * math.sin(a) + up * math.cos(a)).normalized()
                t = i / (len(tl) - 1)
                shade = 0.7 - 0.55 * smooth(0.6, 0.85, t)
                A.lock(b, tl[i] + out * 0.04, (d * 1.0 + out * 0.25).normalized(), out, 0.13, 0.06, (shade,) * 3, (shade + 0.08,) * 3,
                       bone={"tail%d" % (i - 1): 0.5, "tail%d" % min(i, len(tl) - 2): 0.5}, lift=0.25, rise=0.1, thick=0.4, cls=HAIR)
        A.lock(b, tl[-2].lerp(tl[-1], 0.6), (tl[-1] - tl[-2]).normalized(), V(0, 0, -1), 0.12, 0.05, (0.15,) * 3, (0.12,) * 3, bone="tail%d" % (len(tl) - 2), lift=0.1, rise=0.0, thick=0.5, cls=HAIR)
    else:
        # the fox's white bib
        for i in range(4):
            u = (i / 3 - 0.5) * 2
            A.lock(b, V(u * 0.04, 0.66 * H, sh_z + 0.11 * H), V(u * 0.2, -1.0, 0.3), V(u * 0.3, -0.2, 1.0), 0.08, 0.035, (1.0,) * 3, (1.0,) * 3, bone="chest", lift=0.2, rise=0.1, tint=0.15, cls=HAIR)
    # claws
    for sd in ("L", "R"):
        A.toe_claws(b, sk, sd, 0.022, 0.006, paw=0.78 if fox else 0.85, col0="2a2420", col1="8a8070")
        A.toe_claws(b, sk, sd, 0.02, 0.0055, hind=True, paw=0.72 if fox else 0.78, col0="2a2420", col1="8a8070")
    # fox-fire at the tail tips
    if n_tails > 1:
        for k, pts in enumerate(tails):
            tip = pts[-1] + (pts[-1] - pts[-2]).normalized() * 0.06
            b.ball(tip, 0.045, "ffd080", cls=CRYSTAL, bone="ft%d_3" % k, seg=12, rings=8, mat=MAT_GLOW)
            b.ball(tip, 0.07, "ff8040", cls=CRYSTAL, bone="ft%d_3" % k, seg=12, rings=8, mat=MAT_GLOW, tint=0.4)

    # ---------------------------------------------------------------- motion
    qm = QuadMotion(r, legs, T_walk=1.2 if fox else 1.3, stride=0.28 if fox else 0.36, lift=0.07, duty=0.6, bob=0.012, roll=0.03, yaw=0.05, crouch=0.02,
                    head_nod=0.05, head_low=0.12, neck_up=0.0, tail_amp=0.12, tail_lift=-0.1 if not fox else 0.05, tail_droop=0.15 if not fox else 0.0,
                    pounce="bite", pant=0.08 if not fox else 0.0, T_idle=4.0, rest_h=0.16 if fox else 0.19, lunge=0.5)

    def fan(p, t, speed, amp, spread=0.0):
        for k in range(n_tails):
            ph = t * speed + k * 0.55
            for jn in range(4):
                add(p, "ft%d_%d" % (k, jn), (math.sin(ph - jn * 0.8) * amp * (0.6 + jn * 0.3) - spread * 0.15, math.cos(ph - jn * 0.6) * amp * 0.6, (k / (n_tails - 1) - 0.5) * spread))

    if n_tails > 1:
        base_idle, base_walk, base_attack, base_hurt, base_die = qm.idle, qm.walk, qm.attack, qm.hurt, qm.die
        Ti, Tw = qm.st["T_idle"], qm.st["T_walk"]

        def idle(t):
            p = base_idle(t)
            fan(p, t, 2 * math.pi / Ti * 2, 0.12)
            return p

        def walk(t):
            p = base_walk(t)
            fan(p, t, 2 * math.pi / Tw, 0.14)
            return p

        def attack(t):
            p = base_attack(t)
            fan(p, t, 14.0, 0.2, spread=0.5 * math.sin(math.pi * min(1.0, t / 0.55)))
            return p

        def hurt(t):
            p = base_hurt(t)
            fan(p, t, 20.0, 0.1, spread=-0.4 * math.sin(math.pi * min(1.0, t / 0.55)))
            return p

        def die(t):
            p = base_die(t)
            k = smooth(0.2, 0.85, t / 1.2)
            for kk in range(n_tails):
                for jn in range(4):
                    add(p, "ft%d_%d" % (kk, jn), (0.25 * k, 0.0, 0.0))
            return p

        def cast(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = base_idle(0.0)
            add(p, "neck0", (-0.35 * e, 0, 0))
            add(p, "head", (-0.25 * e, 0, 0))
            add(p, "jaw", (0.5 * e, 0, 0))
            fan(p, t, 10.0, 0.12, spread=1.0 * e)
            return p

        clips = {"idle": (Ti, idle), "walk": (Tw, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}
    else:
        def howl(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = qm.idle(0.0)
            add(p, "body", (-0.12 * e, 0, 0))
            add(p, "neck0", (-0.5 * e, 0, 0))
            add(p, "head", (-0.35 * e, 0, 0))
            add(p, "jaw", (0.6 * e, 0, 0))
            return p

        clips = qm.clips({"cast": (0.6, howl)})
    return b, r, hf, clips
