"""Canine anatomy shared by ``art/monsters/beast.py`` (wolves and hounds) and ``fox.py``.

After the references on wolves, foxes and how artists build them (see the scripts' docstrings):

* **Silhouette.**  A wolf is lean and long-legged: a deep, narrow, keel-shaped chest whose floor
  is at the elbows, the ground below it a little further away than the chest is deep; a belly
  that tucks up to the loins; the head carried level with the back on a neck the ruff makes
  nearly as wide as the head; a long brush of a tail carried down or straight, never curled.
  A fox is slighter, on thin legs, with a big head of ears and a tail as long as its body.
* **Head.**  The wolf's skull is broad with a flat forehead and a gentle stop (flatter than a
  dog's); the muzzle is as long as the skull and broad, not a fox's needle; the mouth is closed
  at rest - an upper lip that hangs a little over the lower jaw along a dark lip line rising to
  the corner under the eye - and opens only to bite or howl, when the teeth and a dark mouth
  show.  Almond eyes set obliquely at the stop, under a brow; pointed ears set wide.  The fox's
  muzzle is narrow with a flat nasal bridge, its eyes have slit pupils and its ears are large.
* **Value.**  The wolf: dark guard hairs along the back, the mane and the top of the tail (a
  saddle), a darker crown and muzzle bridge, pale cheeks, lips, eyebrow spots, throat, belly and
  inner legs, a dark tail tip.  The fox: white muzzle, cheeks, throat and belly, black lips, a
  dark tear line, black ear backs and stockings, a white tail tip.  All in greys, so a recolour
  still reads (the coat pass turns the pale greys into the underside colour, the dark into the
  markings).
* **Fur.**  Big smooth forms; locks only where the coat leaves the outline - the ruff, cheeks,
  elbows, the brush of the tail - broad and groomed one way (art/lib/mammal.py).
"""
import math

import anatomy as A
from clay import Clay, limb_weights
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth
from kit import CLOTH, HAIR, MAT_PLAIN, SKIN, V, Builder, mix
from mammal import ChainFrame, brush, flame, lip_line
from sculpt import fbm3

PELT = CLOTH


def build(name="beast", style="wolf", n_tails=1, res=0.0145):
    fox = style == "fox"
    H = 0.62 if fox else 0.8
    hip_z, sh_z = (-0.36, 0.3) if fox else (-0.42, 0.36)
    hw, sw = (0.09, 0.085) if fox else (0.115, 0.105)
    tb = V(0, H - 0.03, hip_z - 0.09)
    if fox:
        # the fox carries its brush out behind, a little below the back, the end lifting
        tail = [tb + V(0, 0.03 * k - 0.016 * k * k + 0.004 * k * k * k, -0.16 * k) for k in range(6)]
    else:
        # the wolf's hangs: back and down from the croup, nearly to the hocks, the end swinging back
        tail = [tb, tb + V(0, -0.075, -0.08), tb + V(0, -0.17, -0.13), tb + V(0, -0.27, -0.155), tb + V(0, -0.37, -0.16), tb + V(0, -0.45, -0.15)]
    neck0 = V(0, H + 0.05, sh_z + 0.05)
    neck1 = V(0, H + (0.1 if fox else 0.11), sh_z + 0.15)
    headp = V(0, H + (0.12 if fox else 0.13), sh_z + (0.2 if fox else 0.23))
    snout = headp + V(0, -0.1, 0.34)
    sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=hw, sh_w=sw, foot="digit", withers=0.05, neck=(neck1, headp), head=snout, tail=tail)
    for sd, s in (("L", 1), ("R", -1)):
        # long legs: the elbow at the floor of the chest, the wrist low, the hock high behind
        sk["el." + sd] = V(sw * s, 0.47 * H, sh_z - 0.07 * H)
        sk["wr." + sd] = V(sw * s, 0.15 * H, sh_z - 0.01 * H)
        sk["kn." + sd] = V(hw * s * 1.05, 0.55 * H, hip_z + 0.14 * H)
        sk["hk." + sd] = V(hw * s, 0.27 * H, hip_z - 0.13 * H)
    HC = headp + V(0, 0.0, 0.09)
    hf = A.HeadFrame(HC, V(0, -0.2, 1.0))
    K = 0.98 if fox else 1.27

    def hp(x, y, z):
        return hf.at(x * K, y * K, z * K)

    ear_base = (0.05, 0.058, -0.03) if fox else (0.047, 0.064, -0.016)
    ears = [(hp(ear_base[0] * s, ear_base[1], ear_base[2]), hp(ear_base[0] * s * 1.3, ear_base[1] + 0.11, ear_base[2] - 0.01)) for s in (1, -1)]
    extra = []
    tails = []
    if n_tails > 1:
        base = tail[0]
        for k in range(n_tails):
            # a fan of brushes behind the hips like a peacock's train: the middle ones raised high,
            # the outer ones lower and wider, every one curling up and out at the end
            u = k / (n_tails - 1) - 0.5
            az = u * 3.0
            el = 0.78 - 1.05 * abs(u) + 0.05 * math.sin(k * 2.1)
            ln = 1.0 - 0.12 * abs(math.sin(k * 2.3))
            pts = [base]
            for j in range(4):
                e2 = el + j * (0.16 + 0.24 * abs(u))
                a2 = az * (1.0 + 0.06 * j * j)
                d = V(math.sin(a2) * math.cos(e2), math.sin(e2), -math.cos(a2) * math.cos(e2))
                pts.append(pts[-1] + d * (0.16 * ln))
            tails.append(pts)
            prev = "pelvis"
            for j in range(4):
                extra.append(("ft%d_%d" % (k, j), pts[j], pts[j + 1], prev))
                prev = "ft%d_%d" % (k, j)
        sk.tail = [tail[0], tail[0] + V(0, 0.02, -0.06)]
    r, legs = quad_rig2(sk, ears=ears, extra=extra)
    # the jaw hinges at the back of the mouth, below and in front of the ear
    r.bones["jaw"] = (hp(0, -0.046, -0.005), hp(0, -0.056, 0.18), "head")
    b = Builder(name)

    # ---------------------------------------------------------------- body
    c = Clay(res, name + "_body")
    if fox:
        A.clay_torso(c, sk, w=0.2, d=0.27, haunch=(0.19, 0.2, 0.2), tuck=0.05, withers=0.08, neck=(0.16, 0.14, 0.115), throat=0.13, chest_y=0.8)
    else:
        A.clay_torso(c, sk, w=0.19, d=0.27, haunch=(0.19, 0.2, 0.2), tuck=0.07, withers=0.1, neck=(0.16, 0.135, 0.11), throat=0.1, chest_y=0.79)
    for sd in ("L", "R"):
        A.clay_foreleg(c, sk, sd, g=0.7 if fox else 0.8, foot="paw", paw=0.74 if fox else 0.82, scap=0.9)
        A.clay_hindleg(c, sk, sd, g=0.74 if fox else 0.84, foot="paw", paw=0.74 if fox else 0.82)
    tail_clays = []
    tail_frames = []
    if n_tails > 1:
        # every brush its own clay so they stay apart instead of webbing together
        for k, pts in enumerate(tails):
            ct = Clay(res * 1.12, "%s_tail%d" % (name, k))
            ct.chain(pts, [0.03, 0.066, 0.082, 0.07, 0.018], bones=limb_weights(["ft%d_%d" % (k, j) for j in range(4)]), tag="tail%d" % k, t0=0.0, t1=4.0)
            tail_clays.append(ct)
            tail_frames.append(ChainFrame(pts))
    elif fox:
        A.clay_tail(c, sk, [0.035, 0.06, 0.078, 0.08, 0.066, 0.018])
    else:
        A.clay_tail(c, sk, [0.04, 0.056, 0.066, 0.064, 0.05, 0.016])
    main_tail = ChainFrame(sk.tail)

    # the head: a broad skull with a flat forehead and a gentle stop, wide cheekbones, a long
    # muzzle tapering a little to the nose, the upper lip hanging over the lower jaw at the sides
    if fox:
        head_parts = [
            ("ell", (0, 0.02, -0.02), (0.066, 0.058, 0.075), "head", False, False),
            ("ell", (0, 0.036, 0.04), (0.046, 0.03, 0.05), "head", False, False),
            ("ell", (0.044, -0.012, 0.012), (0.036, 0.034, 0.048), "head", True, False),
            ("ell", (0.06, -0.03, -0.03), (0.034, 0.04, 0.045), "ruff", True, False),
            ("ell", (0, -0.004, 0.095), (0.033, 0.032, 0.05), "muzzle", False, False),
            ("ell", (0, -0.012, 0.155), (0.025, 0.025, 0.055), "muzzle", False, False),
            ("ell", (0, -0.016, 0.196), (0.02, 0.021, 0.034), "muzzle", False, False),
            ("ell", (0.0145, -0.031, 0.135), (0.0145, 0.0145, 0.08), "lip", True, False),
            ("ell", (0, -0.03, 0.178), (0.017, 0.014, 0.04), "lip", False, False),
            ("ell", (0.038, 0.026, 0.074), (0.017, 0.012, 0.015), "head", True, True),
        ]
    else:
        head_parts = [
            ("ell", (0, 0.026, -0.022), (0.068, 0.068, 0.08), "head", False, False),
            ("ell", (0, 0.042, 0.035), (0.05, 0.038, 0.048), "head", False, False),
            ("ell", (0.03, 0.05, 0.066), (0.02, 0.012, 0.018), "head", True, False),
            ("ell", (0.048, -0.01, 0.018), (0.038, 0.036, 0.05), "head", True, False),
            ("ell", (0.066, -0.03, -0.03), (0.044, 0.05, 0.05), "ruff", True, False),
            ("ell", (0, -0.01, 0.092), (0.045, 0.046, 0.05), "muzzle", False, False),
            ("ell", (0, -0.015, 0.14), (0.036, 0.036, 0.05), "muzzle", False, False),
            ("ell", (0, -0.018, 0.178), (0.029, 0.029, 0.032), "muzzle", False, False),
            ("ell", (0.021, -0.034, 0.13), (0.018, 0.018, 0.078), "lip", True, False),
            ("ell", (0.041, 0.03, 0.074), (0.019, 0.013, 0.016), "head", True, True),
            ("ell", (0, 0.062, 0.104), (0.03, 0.02, 0.022), "head", False, True),
        ]
    A.head_clay(c, hf, K, head_parts)
    # fur where it leaves the outline, sculpted as soft tufts that melt into the skin: the cheek
    # ruffs sweeping back below the ears and, on the wolf, the ruff hanging round the neck
    # fur where it leaves the outline, each its own clay so the big forms under it cannot swallow
    # its lobes: the cheek ruffs sweeping back below the ears and, on the wolf, the ruff round the
    # neck - a collar of overlapping tufts that melt into one another with a scalloped edge
    fur = Clay(res * 0.9, name + "_ruff")
    for s in (1, -1):
        # the cheek ruffs: the fur of the cheeks flaring back and out below the ears (melted into
        # the head, so the face widens into a heart shape seen from the front)
        for k in range(3):
            root = hp((0.048 + 0.005 * k) * s, -0.012 - 0.022 * k, -0.035 - 0.01 * k)
            d = (-hf.f * 0.72 + hf.r * (0.55 * s) - hf.u * (0.12 + 0.3 * k)).normalized()
            ln = (0.072 - 0.008 * k) * K
            wd = (0.022 - 0.002 * k) * K
            c.chain([root, root + d * ln * 0.5, root + d * ln], [wd, wd * 0.78, wd * 0.36], bones={"head": 1.0} if k < 2 else {"head": 0.6, "neck1": 0.4},
                    tag="ruff", t0=0.0, t1=1.0)
    if not fox:
        NB = sk["neck0"]
        NT = sk["neck1"]
        axis = (NT - NB).normalized()
        upn = V(1, 0, 0).cross(axis).normalized()
        if upn.y < 0:
            upn = -upn
        for row in range(3):
            c0 = NT.lerp(NB, -0.05 + 0.5 * row) + V(0, -0.01, 0)
            n_l = 12
            for i in range(n_l):
                a = (i + 0.5 * (row % 2)) / n_l * 2 * math.pi
                ca = math.cos(a)
                if ca > (0.7 if row < 2 else 0.85):
                    continue  # the crest of the neck stays smooth
                out = (upn * ca + V(1, 0, 0) * math.sin(a)).normalized()
                down = smooth(0.2, -0.9, ca)
                root = c0 + out * 0.045 * H / 0.8
                d = (-axis * (1.0 - 0.45 * down) + V(0, -1, 0) * (0.2 + 0.55 * down) + out * 0.8).normalized()
                ln = (0.14 + 0.025 * row + 0.05 * down) * H / 0.8
                wd = (0.055 + 0.005 * row) * H / 0.8
                bw = {"neck1": 0.7, "head": 0.3} if row == 0 else ({"neck1": 0.4, "neck0": 0.6} if row == 1 else {"neck0": 0.5, "chest": 0.5})
                fur.chain([root, root + d * ln * 0.5, root + d * ln], [wd, wd * 0.84, wd * 0.38], bones=bw, tag="mane", t0=0.0, t1=1.0)

    def head_local(p):
        return hf.M.transposed() @ (p - HC) / K

    def brow_spot(q):
        if fox:
            return 0.0
        w = 0.0
        for s in (1, -1):
            w = max(w, smooth(0.016, 0.008, math.hypot(q.x - 0.04 * s, q.y - 0.054)) * smooth(0.035, 0.06, q.z))
        return w

    def head_col(p, info):
        q = head_local(p)
        lip = info.share("lip")
        if fox:
            v = 0.8
            # white: the lower half of the muzzle, the cheeks and everything under the jaw line
            white = smooth(-0.004, -0.018, q.y + 0.12 * max(0.0, 0.06 - q.z)) * smooth(0.03, 0.07, q.z)
            white = max(white, smooth(0.042, 0.062, abs(q.x)) * smooth(0.0, -0.02, q.y) * smooth(-0.07, -0.04, q.z))
            white = max(white, smooth(-0.03, -0.05, q.y))
            # the dark tear line from the inner corner of the eye down the side of the muzzle
            dark = 0.0
            for s in (1, -1):
                along = (q.z - 0.08) / 0.07
                if 0.0 < along < 1.0 and q.x * s > 0.0:
                    ly = 0.016 - 0.03 * along
                    lx = 0.03 - 0.008 * along
                    dark = max(dark, smooth(0.008, 0.003, math.hypot(abs(q.x) - lx, q.y - ly)) * (1.0 - smooth(0.7, 1.0, along)))
            v = v * (1.0 - white) + 1.0 * white
            v = v * (1.0 - dark) + 0.16 * dark
            # black lips
            v = v * (1.0 - smooth(0.4, 0.8, lip) * smooth(-0.0415, -0.0445, q.y)) + 0.1 * smooth(0.4, 0.8, lip) * smooth(-0.0415, -0.0445, q.y)
            return (v, v, v)
        v = 0.74
        # a darker crown and bridge of the muzzle, grizzled with the dark guard hairs
        crown = smooth(0.015, 0.05, q.y) * (1.0 - smooth(0.05, 0.09, q.z))
        bridge = smooth(0.005, 0.022, q.y + 0.1 * (q.z - 0.1)) * smooth(0.07, 0.11, q.z) * smooth(0.035, 0.015, abs(q.x))
        v -= 0.1 * crown + 0.16 * bridge
        # pale cheeks, lips and chin, the pale spots over the eyes
        pale = smooth(-0.006, -0.022, q.y) * smooth(0.04, 0.075, q.z)
        pale = max(pale, smooth(0.046, 0.066, abs(q.x)) * smooth(0.004, -0.02, q.y))
        pale = max(pale, smooth(-0.036, -0.056, q.y))
        pale = max(pale, brow_spot(q))
        v = v * (1.0 - pale) + 0.95 * pale
        # black lips along the edge of the upper lip
        lipk = smooth(0.4, 0.8, lip) * smooth(-0.0455, -0.05, q.y)
        v = v * (1.0 - lipk) + 0.12 * lipk
        return (v, v, v)

    def col(p, info):
        tag = info.tag
        n = info.n
        if tag in ("head", "muzzle", "ruff", "lip"):
            return head_col(p, info)
        if tag.startswith("tail"):
            if n_tails > 1:
                t = info.t / 4.0
                tip = smooth(0.66, 0.8, t)
                v = 0.8 - 0.06 * smooth(-0.2, 0.7, n.dot(V(0, 1, 0)))
                return (v * (1.0 - tip) + 1.0 * tip,) * 3
            t = info.t / (len(sk.tail) - 1)
            fr = main_tail.at(info.t)
            topk = n.dot(fr[3])
            if fox:
                tip = smooth(0.8, 0.88, t)
                v = 0.8 - 0.05 * smooth(-0.2, 0.7, topk)
                return (v * (1.0 - tip) + 1.0 * tip,) * 3
            # the wolf's brush: a dark streak along the top, pale beneath, a black tip
            tip = smooth(0.78, 0.9, t)
            v = 0.74 - 0.18 * smooth(0.2, 0.8, topk) * smooth(0.0, 0.2, t) + 0.18 * smooth(-0.2, -0.8, topk)
            return (v * (1.0 - tip) + 0.15 * tip,) * 3
        if tag == "paw":
            return (0.12, 0.12, 0.12) if fox else (0.84, 0.84, 0.84)
        under = smooth(-0.1, -0.55, n.y)
        if tag in ("fleg", "hleg", "leg"):
            side = 1 if p.x > 0 else -1
            inner = smooth(0.1, -0.5, n.x * side)
            if fox:
                # black stockings up the lower legs
                stock = smooth(1.2, 1.55, info.t) if tag != "leg" else 0.0
                v = 0.8 * (1.0 - stock) + 0.12 * stock
                w = inner * (1.0 - stock) * 0.85
                return (v * (1.0 - w) + 0.98 * w,) * 3
            v = 0.8 + 0.06 * smooth(1.0, 2.0, info.t if tag != "leg" else 0.0)
            # a dark line down the front of the forearm (as many wolves have)
            front = smooth(0.4, 0.85, n.z) * smooth(1.05, 1.35, info.t) * (1.0 - smooth(2.2, 2.6, info.t)) if tag == "fleg" else 0.0
            v = v * (1.0 - 0.3 * front)
            w = max(inner, under) * 0.85
            return (v * (1.0 - w) + 0.93 * w,) * 3
        if tag == "mane":
            # the ruff: dark guard hairs over the nape and shoulders, pale at the throat
            nape = smooth(0.2, 0.75, n.y)
            throat = smooth(0.1, -0.5, n.y) * smooth(-0.2, 0.5, n.z)
            v = 0.8 - 0.2 * nape
            return (v * (1.0 - throat) + 0.95 * throat,) * 3
        if tag == "neck":
            under = max(under, smooth(0.2, -0.3, n.y) * smooth(0.2, 0.8, n.z))
        if fox:
            v = 0.8 - 0.06 * smooth(0.0, 0.8, n.y)
            return (v * (1.0 - under) + 1.0 * under,) * 3
        # the wolf's saddle: dark along the back from the withers to the tail, over the shoulders
        sad = smooth(0.3, 0.8, n.y) * smooth(-0.62, -0.3, p.z) * (1.0 - smooth(0.3, 0.5, p.z))
        sad = max(sad, smooth(0.55, 0.92, n.y) * 0.7)
        g = fbm3((p.x * 7.0, p.y * 7.0, p.z * 7.0), 2, 9)
        v = 0.82 - 0.24 * sad + 0.06 * (g - 0.5)
        return (v * (1.0 - under) + 0.94 * under,) * 3

    def tint(p, info):
        cc = col(p, info)[0]
        if info.share("lip") > 0.4 and cc < 0.2:
            return 0.15  # black lips keep their colour
        return 1.0 - 0.7 * smooth(0.88, 0.98, cc) if fox else 1.0 - 0.55 * smooth(0.9, 0.98, cc)

    def post(p, info):
        tag = info.tag
        if tag.startswith("tail"):
            if n_tails > 1:
                k = int(tag[4:])
                return brush(tail_frames[k], n_locks=6, amp=0.011, twist=0.8, t_end=4.0, phase=k * 0.9)(p, info)
            return brush(main_tail, n_locks=7, amp=0.012 if not fox else 0.011, twist=0.5)(p, info)
        return None

    c.build(b, col, cls=PELT, tint_fn=tint, post=post)
    fur.build(b, col, cls=PELT, tint_fn=tint)
    for ct in tail_clays:
        ct.build(b, col, cls=PELT, tint_fn=tint, post=post)

    # ---------------------------------------------------------------- the lower jaw (its own part)
    j = Clay(res * 0.6, name + "_jaw")
    jw = 0.85 if fox else 1.0
    # the jaw is fitted under the lip line of the muzzle as built: at every station its top tucks
    # a little inside the upper lip and its sides are flush with it, so the closed mouth is one
    # muzzle with a line along it (and the jaw can still drop to bite)
    hit0 = A.surface(b)
    zs = [0.06, 0.085, 0.11, 0.135, 0.16, 0.18] if not fox else [0.06, 0.085, 0.11, 0.135, 0.16, 0.18, 0.195]
    st = lip_line(hit0, hf, K, zs)
    jh = 0.024 if not fox else 0.018
    for k, (zq, yb, xb) in enumerate(st):
        f = k / max(1, len(st) - 1)
        hh = jh * (1.0 - 0.35 * f)
        j.ellipsoid(hp(0, yb - hh * 0.5 + 0.004, zq), (max(0.006, xb - 0.0015) * K, hh * 0.5 * K, 0.022 * K), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
    for s in (1, -1):
        # the branches of the jaw back to the hinge, under the cheek
        if st:
            z0, y0, x0 = st[0]
            j.chain([hp(0.04 * s * jw, -0.046, -0.005), hp(x0 * 0.85 * s, y0 - jh * 0.4, z0)], [0.016 * K * jw, 0.012 * K], bones={"jaw": 1.0}, tag="jaw")

    def jaw_dark(p, info):
        # the lower lip is black along its top edge and the mouth dark inside: only the chin and the
        # sides of the jaw below the lip line are pale fur
        q = head_local(p)
        # (behind the corner of the mouth the jaw is under the cheek: fur, not lip)
        front = smooth(0.04, 0.075, q.z)
        lipk = (smooth(-0.044, -0.04, q.y) if not fox else smooth(-0.041, -0.037, q.y)) * front
        return max(lipk, smooth(0.15, 0.45, info.n.dot(hf.u)) * front)

    def jaw_col(p, info):
        return mix((0.96, 0.96, 0.96), (0.13, 0.08, 0.08), jaw_dark(p, info))

    def jaw_tint(p, info):
        return 0.35 * (1.0 - jaw_dark(p, info))

    j.build(b, jaw_col, cls=PELT, tint_fn=jaw_tint)
    # the mouth: a dark roof (seen only when the jaw drops) and a tongue on the jaw
    mk = 0.75 if fox else 1.0
    b.ellipsoid(hp(0, -0.036 if fox else -0.038, 0.1), (0.02 * K * mk, 0.007 * K, 0.08 * K), "2a0e12", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
    ty = (st[2][1] if len(st) > 2 else -0.046) - 0.002
    b.ellipsoid(hp(0, ty, 0.11), (0.014 * K * mk, 0.004 * K, 0.06 * K), "a03848", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
    def lip_y(zq):
        """Height of the lip line (head-local) at zq, from the fitted stations."""
        if not st:
            return -0.045
        if zq <= st[0][0]:
            return st[0][1]
        for (za, ya, _), (zb, yb2, _) in zip(st, st[1:]):
            if zq <= zb:
                return ya + (yb2 - ya) * (zq - za) / max(1e-6, zb - za)
        return st[-1][1]

    tk = 0.85 if fox else 1.0
    for s in (1, -1):
        # the teeth hang below the lip line into the space the closed jaw fills, so they are hidden
        # at rest and bared when it drops: a long canine, cheek teeth behind it, the lower canine
        A.fang(b, hp(0.015 * s * tk, lip_y(0.16) + 0.012, 0.16), -hf.u, 0.0125 * K, 0.0045 * K, "head", back=-hf.f, curve=0.25)
        A.fang(b, hp(0.012 * s * tk, lip_y(0.15) - 0.01, 0.15), hf.u, 0.012 * K, 0.004 * K, "jaw", back=-hf.f, curve=0.2)
        for k in range(2 if fox else 3):
            zz = 0.13 - 0.028 * k
            A.fang(b, hp((0.016 + 0.002 * k) * s * tk, lip_y(zz) + 0.008, zz), -hf.u, 0.0085 * K, 0.004 * K, "head", back=-hf.f, curve=0.0)
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        zz = (0.172 if not fox else 0.182) - 0.004 * abs(u)
        A.fang(b, hp(0.0065 * u * tk, lip_y(zz) + 0.008, zz), -hf.u, 0.0085 * K, 0.0028 * K, "head", back=-hf.f, curve=0.0)
    A.nose_pad(b, hp(0, -0.01, 0.204 if not fox else 0.226), hf.f + hf.u * 0.15, (0.034 if not fox else 0.026) * K, (0.026 if not fox else 0.02) * K, "161214", "head", kind="dog")
    for s in (1, -1):
        A.animal_eye(b, hp(0.041 * s if not fox else 0.038 * s, 0.03 if not fox else 0.026, 0.079 if not fox else 0.078),
                     hf.f + hf.r * (0.5 * s) + hf.u * 0.1, (0.0158 if not fox else 0.0142) * K, "e0a020" if not fox else "f0b030", "head",
                     pupil="slit" if fox else "round", almond=0.56, slant=0.32, side=s, lid="140c0a", lid_w=0.16)
    for s, sd in ((1, "L"), (-1, "R")):
        eb = hp(ear_base[0] * s, ear_base[1], ear_base[2])
        if fox:
            A.ear(b, eb, hf.f * 0.85 + hf.r * (0.3 * s) + hf.u * 0.05, 0.15 * K, 0.1 * K, 0.03 * K, (0.12, 0.12, 0.12), (0.97, 0.97, 0.97), "ear." + sd,
                  up=hf.u + hf.r * (0.32 * s), point=0.9, cup=0.65, tint=0.4, tint_in=0.15, side=s)
        else:
            A.ear(b, eb, hf.f * 0.85 + hf.r * (0.28 * s) + hf.u * 0.05, 0.1 * K, 0.074 * K, 0.03 * K, (0.5, 0.5, 0.5), (0.96, 0.96, 0.96), "ear." + sd,
                  up=hf.u + hf.r * (0.3 * s), point=0.75, cup=0.6, tint=1.0, tint_in=0.25, rim_col=(0.28, 0.28, 0.28), side=s)
        # a soft tuft of pale fur inside the ear
        A.lock(b, hp(ear_base[0] * s * 1.08, ear_base[1] + 0.006, ear_base[2] + 0.006), hf.u + hf.f * 0.12 + hf.r * (0.3 * s), hf.f,
               0.035 * K if not fox else 0.05 * K, 0.016 * K, (0.97,) * 3, (1.0,) * 3, bone="ear." + sd, lift=0.05, rise=0.02, thick=0.5, tint=0.2)

    # ---------------------------------------------------------------- fur at the silhouette: cheeks, ruff, elbows, the brush
    pale = (0.95, 0.95, 0.95)
    hit = A.surface(b)

    def on_skin(target, out, reach=0.3):
        """The point of the sculpted skin seen from outside along `out` (and its normal)."""
        out = out.normalized()
        h = hit(target + out * reach, -out, reach * 2.0)
        return h if h is not None else (target, out)

    if not fox:
        for sd, s in (("L", 1), ("R", -1)):
            el = sk["el." + sd]
            A.lock(b, el + V(0.0, 0.02, -0.025), V(0.1 * s, -0.7, -1.0), V(s, 0, 0), 0.06, 0.026, (0.86,) * 3, (0.94,) * 3,
                   bone={"f_lo." + sd: 0.6, "f_up." + sd: 0.4}, lift=0.1, rise=0.05, cls=HAIR)
            kn = sk["kn." + sd]
            hk = sk["hk." + sd]
            for k in range(2):
                q = kn.lerp(hk, 0.2 + 0.3 * k) + V(0, 0, -0.04)
                A.lock(b, q, V(0.1 * s, -0.8, -0.6), V(s * 0.5, 0, -1.0), 0.07, 0.03, (0.86,) * 3, (0.94,) * 3, bone="h_lo." + sd, lift=0.1, rise=0.05, cls=HAIR)
        # the end of the brush: a dark, pointed tuft
        tl = sk.tail
        A.lock(b, tl[-2].lerp(tl[-1], 0.5), (tl[-1] - tl[-2]).normalized(), V(0, 0, -1), 0.1, 0.045, (0.16,) * 3, (0.12,) * 3,
               bone="tail%d" % (len(tl) - 2), lift=0.05, rise=0.0, thick=0.55, cls=HAIR)
    else:
        if n_tails == 1:
            tl = sk.tail
            A.lock(b, tl[-2].lerp(tl[-1], 0.5), (tl[-1] - tl[-2]).normalized(), V(0, 1, 0), 0.1, 0.05, (1.0,) * 3, (1.0,) * 3,
                   bone="tail%d" % (len(tl) - 2), lift=0.05, rise=0.0, thick=0.55, tint=0.2, cls=HAIR)
    # claws
    for sd in ("L", "R"):
        A.toe_claws(b, sk, sd, 0.02, 0.0055, paw=0.74 if fox else 0.82, col0="2a2420", col1="8a8070")
        A.toe_claws(b, sk, sd, 0.018, 0.005, hind=True, paw=0.68 if fox else 0.75, col0="2a2420", col1="8a8070")
    if n_tails > 1:
        for k, pts in enumerate(tails):
            # the pointed white tip of each brush, and a tongue of fox-fire licking up from it
            d = (pts[-1] - pts[-2]).normalized()
            A.lock(b, pts[-1] - d * 0.03, d, V(0, 1, 0).cross(d).normalized() if abs(d.y) < 0.95 else V(1, 0, 0), 0.09, 0.045, (1.0,) * 3, (1.0,) * 3,
                   bone="ft%d_3" % k, lift=0.05, rise=0.0, thick=0.6, tint=0.15, cls=HAIR)
            tip = pts[-1] + d * 0.04
            up = (d + V(0, 1.4, 0)).normalized()
            flame(b, tip, up, 0.17, "ft%d_3" % k, bend=1.0 if k % 2 else -1.0)

    # ---------------------------------------------------------------- motion
    qm = QuadMotion(r, legs, T_walk=1.2 if fox else 1.3, stride=0.28 if fox else 0.36, lift=0.07, duty=0.6, bob=0.012, roll=0.03, yaw=0.05, crouch=0.02,
                    head_nod=0.05, head_low=0.1, neck_up=0.0, tail_amp=0.12, tail_lift=-0.05 if not fox else 0.05, tail_droop=0.05 if not fox else 0.0,
                    pounce="bite", pant=0.0, T_idle=4.0, rest_h=0.16 if fox else 0.19, lunge=0.5)

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

    def fan(p, t, speed, amp, spread=0.0):
        for k in range(n_tails):
            ph = t * speed + k * 0.55
            for jn in range(4):
                add(p, "ft%d_%d" % (k, jn), (math.sin(ph - jn * 0.8) * amp * (0.6 + jn * 0.3) - spread * 0.15, math.cos(ph - jn * 0.6) * amp * 0.6,
                                             (k / (n_tails - 1) - 0.5) * spread))

    if n_tails > 1:
        base_idle, base_walk, base_attack, base_hurt, base_die = qm.idle, qm.walk, qm.attack, qm.hurt, qm.die
        Ti, Tw = qm.st["T_idle"], qm.st["T_walk"]

        def idle(t):
            p = base_idle(t)
            fan(p, t, 2 * math.pi / Ti * 2, 0.1)
            return p

        def walk(t):
            p = base_walk(t)
            fan(p, t, 2 * math.pi / Tw, 0.12)
            return p

        def attack(t):
            p = base_attack(t)
            fan(p, t, 14.0, 0.16, spread=0.5 * math.sin(math.pi * min(1.0, t / 0.55)))
            return p

        def hurt(t):
            p = base_hurt(t)
            fan(p, t, 20.0, 0.08, spread=-0.4 * math.sin(math.pi * min(1.0, t / 0.55)))
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
            fan(p, t, 10.0, 0.1, spread=1.0 * e)
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
