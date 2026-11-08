"""Race features for the peoples of the Nine Heavens and the Nine Springs: the Yumin (the Feathered
Folk), the dragon-kin of the Rain Ministry, the celestial foxes, the Jiaoren (the Pearl-Weepers)
and others.  ``person.build`` calls in here only when a character script asks for one of these
options, so every other character is built exactly as before.

Options (all optional; colours are hex strings or tuples):

* ``wings``: the colour of a pair of folded feathered wings rooted between the shoulder blades:
  rows of marginal, lesser, median and greater coverts over long secondaries and primaries that
  droop down the back to about knee height, broad over the shoulders and narrowing down the back
  inside the swing of the sleeves.  ``wing_tip`` colours the ends of the flight feathers (the
  primaries most), ``wing_bar`` paints hawk-like bars across them and ``wing_span`` scales the
  wings (about 1.0).  The chest carries the root; lower down the wing follows the torso as the
  robe does, and its lower part is passed partly to ``cape``, ``cape2`` and ``robe_b``, so it
  sways when the character walks and trails when it runs.  (Best with hair that is not "long":
  the wings hang where a long curtain of hair would.)
* ``crest``: the colour of a fan of long feathers rising from the crown and sweeping back (the
  Feathered People of the Shan Hai Jing have "long heads"); ``crest_tip``, ``crest_len`` (metres,
  about 0.26), ``crest_n`` (3-5 feathers), ``crest_up`` (0 swept back .. 1 upright) and
  ``crest_spread``.  (Not with the "topknot" style, whose knot sits where the crest grows.)
* ``ears``: "fox" (tall triangular furred ears on top of the head with a lighter, cupped inner ear
  and tufts of fur) or "fin" (fan-shaped fins with webbed rays where human ears are);
  ``ear_col``, ``ear_inner`` (the inner ear, or the fins' pale edge), ``ear_tip`` (fox) and
  ``ear_size``.  Both sit on the hair of any style (fins grow out through long hair).  Fins
  replace the human ears, fox ears keep them; ``human_ears`` overrides that.
* ``tails``: the number of fluffy fox tails (1-9) from under the sash at the back: one or two hang
  down behind and curl up at the ends, three or more rise in a fan behind the back, alternate
  tails standing further back; ``tail_col``, ``tail_tip`` (the contrasting tip), ``tail_len``,
  ``tail_r``.  Weighted to the hips, ``robe_b`` and the cape chain so they sway.
* ``scales``: the colour of small overlapping scales on the cheekbones, rising towards the temples,
  and on the backs of the hands (dragon-kin, merfolk), glossy like enamel.
* ``whiskers``: the colour of two long dragon whiskers (barbels) curving down and out from the
  upper lip.
* ``horns: "antler"``: branching deer antlers - the dragon's horns, one of its nine resemblances -
  in ``horn_col``, sized by ``antler_size``.  (``horns: True`` keeps the curved horns.)

Coordinates are Godot space like the rest of the kit: the model faces +Z and +X is its left.
"""

import math

from mathutils import Matrix

import face as facelib
from face import HC, MOUTH_Y, RX
from garment import WRI
from kit import CRYSTAL, HAIR, MAT_PLAIN, METAL, SKIN, STONE, V, darken, lighten, look_frame, mix, rgb
from sculpt import catmull, clamp, loft, morph_sphere, path_dirs, smooth, strand

OPTIONS = ("wings", "crest", "ears", "tails", "scales", "whiskers")


def wanted(o):
    """True when the character asks for any of the features ``build`` adds."""
    return any(o.get(k) for k in OPTIONS)


def hides_ears(o):
    """Fins grow where the human ears are, so a head with fins is built without them."""
    if not o.get("ears"):
        return False
    return not o.get("human_ears", o["ears"] != "fin")


def head(b, o, bone="head", eye_bone="eyes"):
    """``face.head`` without the human ears."""
    f = facelib.Face(o)
    morph_sphere(b, HC, f.shape, f.colour, cls=SKIN, bone=bone, seg=34, rings=26)
    facelib.nose(b, f, bone)
    facelib.mouth(b, f, o, bone)
    facelib.eyes(b, f, o, eye_bone, bone)
    if f.age > 0.3:
        facelib.wrinkles(b, f, bone)
    return f


def build(b, o, f, s):
    """Every feature the options ask for.  `f` is the Face and `s` the hair's Scalp (both None on
    an animal head, which takes only the wings and tails)."""
    if o.get("wings"):
        wings(b, o)
    if o.get("tails"):
        tails(b, o)
    if f is None:
        return
    if o.get("crest"):
        crest(b, o, f, s)
    if o.get("ears") == "fox":
        fox_ears(b, o, f, s)
    elif o.get("ears") == "fin":
        fin_ears(b, o, f, s)
    if o.get("scales"):
        scales(b, o, f)
    if o.get("whiskers"):
        whiskers(b, o, f)


# ---------------------------------------------------------------- helpers
def _dvec(x, y, z):
    return V(x, y, z).normalized()


def _bez(pts, t):
    """A point of the quadratic or cubic Bezier curve through control points `pts`."""
    u = 1.0 - t
    if len(pts) == 3:
        return pts[0] * (u * u) + pts[1] * (2.0 * u * t) + pts[2] * (t * t)
    return pts[0] * (u * u * u) + pts[1] * (3.0 * u * u * t) + pts[2] * (3.0 * u * t * t) + pts[3] * (t * t * t)


def _bez_tan(pts, t):
    u = 1.0 - t
    if len(pts) == 3:
        d = (pts[1] - pts[0]) * (2.0 * u) + (pts[2] - pts[1]) * (2.0 * t)
    else:
        d = (pts[1] - pts[0]) * (3.0 * u * u) + (pts[2] - pts[1]) * (6.0 * u * t) + (pts[3] - pts[2]) * (3.0 * t * t)
    return d.normalized()


def _on_head(f, s, d):
    """The point of the hair (or, bald, of the skull) in direction d from the head's centre."""
    if s is not None and s.style != "bald":
        return s.pt(d)
    return HC + f.shape(d)


def _orient(n, tilt=0.0):
    """Euler angles (Godot order) turning local +Z onto the normal n, then tipping it down by
    `tilt` (a shingle's lower edge lifts off the surface)."""
    return (-math.asin(max(-1.0, min(1.0, n.y))) + tilt, math.atan2(n.x, n.z), 0.0)


def feather(b, pts, width, col, col_tip=None, nrm=(0, 0, -1), bones=None, bone=None,
            kind="flight", n=7, asym=0.0, bar=None, bars=0, tip_from=0.55, thick=0.004):
    """One feather along the Bezier curve through `pts` (root, one or two control points, tip),
    its vane facing `nrm`, with a raised, paler rachis down the middle.  `kind`: "flight" (a quill
    end, a long vane and a rounded point), "covert" (short and round) or "plume" (narrow at the
    root, widening to the end).  `asym` narrows one vane (the leading one of a primary); `bar`
    and `bars` paint bands across the vane (a hawk's barring).  `bones(p)` weights each row by
    its centre."""
    pts = [V(p) for p in pts]
    nh = V(nrm).normalized()
    rows = []
    cols = []
    bl = []
    for j in range(n):
        t = j / (n - 1)
        cen = _bez(pts, t)
        tan = _bez_tan(pts, t)
        side = tan.cross(nh)
        if side.length < 1e-6:
            side, _ = look_frame(tan)
        side.normalize()
        nn = side.cross(tan).normalized()
        if kind == "flight":
            w = (0.28 + 0.72 * smooth(0.0, 0.22, t)) * math.sqrt(max(0.0, 1.0 - (max(0.0, t - 0.62) / 0.38) ** 2))
        elif kind == "covert":
            w = (0.45 + 0.55 * smooth(0.0, 0.35, t)) * math.sqrt(max(0.0, 1.0 - (max(0.0, t - 0.5) / 0.5) ** 2))
        else:
            w = smooth(-0.15, 0.7, t) ** 0.8 * math.sqrt(max(0.0, 1.0 - (max(0.0, t - 0.72) / 0.28) ** 2))
        w = width * max(0.06, w)
        # asym > 0 narrows the vane on the +side (tan x nrm), < 0 the one on the -side
        wl = w * (1.0 - max(0.0, -asym)) * (1.0 + 0.25 * max(0.0, asym))
        wr = w * (1.0 - max(0.0, asym)) * (1.0 + 0.25 * max(0.0, -asym))
        rows.append([cen - side * wl - nn * (wl * 0.1), cen + nn * (w * 0.14), cen + side * wr - nn * (wr * 0.1)])
        c = mix(col, col_tip, smooth(tip_from, 1.0, t)) if col_tip is not None else rgb(col)
        if bar is not None and bars > 0 and t > 0.1 and math.sin(t * math.pi * bars * 2.0) > 0.35:
            c = mix(c, bar, 0.8)
        cols.append([darken(c, 0.06), lighten(c, 0.2), darken(c, 0.06)])
        bl.append(bones(cen) if bones is not None else bone)
    b.sheet(rows, col, cls=HAIR, bones=bl, cols=cols, thickness=thick)


# ---------------------------------------------------------------- wings
def _wing_w(p):
    """The chest carries the root of the wing; lower down the wing hangs along the back and
    follows the torso as the robe does (spine, then hips), and its lower part is passed more and
    more to the cape bones and the back panel of the skirt, so it sways and trails behind."""
    y = p.y
    wc = clamp((y - 1.0) / 0.2)
    wh = clamp((0.95 - y) / 0.25)
    ws = max(0.0, 1.0 - wc - wh)
    k = smooth(1.3, 0.55, y)
    kb = smooth(1.05, 0.55, y)
    keep = 1.0 - 0.32 * k
    return {"chest": wc * keep, "spine": ws * keep, "hips": wh * keep * (1.0 - 0.5 * kb), "robe_b": 0.3 * kb, "cape": 0.2 * k, "cape2": 0.1 * k}


def wings(b, o):
    col = rgb(o["wings"])
    tipc = rgb(o.get("wing_tip", lighten(col, 0.35)))
    bar = o.get("wing_bar")
    span = o.get("wing_span", 1.0)
    for s in (1, -1):
        _wing(b, s, col, tipc, None if bar is None else rgb(bar), span)


def _wing(b, s, col, tipc, bar, span):
    """One folded wing.  It hangs from an arm that rises from the root between the shoulder blades
    to the wrist (the bend of the wing) behind the shoulder; the feathers swell out a little over
    the shoulder blade and then taper in to the primary tips at about knee height, so seen from
    behind the pair is broad across the shoulders and narrows down the back, inside the swing of
    the sleeves' hanging pockets."""
    nh = V(-0.3 * s, 0.1, -1.0).normalized()           # the wing faces back and a little inwards
    R = V(0.085 * s, 1.4, -0.122)
    C = V((0.085 + 0.065 * span) * s, 1.4 + 0.12 * span, -0.15)
    W = V((0.085 + 0.105 * span) * s, 1.4 + 0.165 * span, -0.19)

    def arm(w):
        return _bez((R, C, W), w)

    def flight(u):
        """Control points of the flight feather at u (0 innermost .. 1 outermost)."""
        r = arm(0.12 + 0.88 * u)
        ln = span * (0.46 + 0.64 * u ** 1.15)
        tip = V((0.05 + 0.05 * u) * s, r.y - ln, -0.16 - 0.08 * u)
        c1 = r + V((0.008 + 0.05 * u ** 1.4) * s, -0.28 * ln, -0.025)
        c2 = tip + V((0.004 + 0.022 * u) * s, 0.36 * ln, -0.02)
        return [r, c1, c2, tip]

    # a dark membrane under the feathers, so no gap between them shows the robe through
    rows = []
    bl = []
    for j in range(7):
        t = j / 6
        row = [_bez(flight(c / 3), min(0.97, t)) - nh * 0.006 for c in range(4)]
        rows.append(row)
        bl.append(_wing_w(sum(row, V(0, 0, 0)) / len(row)))
    b.sheet(rows, darken(col, 0.15), cls=HAIR, bones=bl, cols=[darken(col, 0.12 + 0.12 * (j / 6)) for j in range(7)], thickness=0.004)
    # flight feathers: tertials and secondaries along the forearm, primaries from the hand; the
    # inner feathers lie over the outer ones as on a folded bird's wing, and the primaries' narrow
    # leading vanes make the outer edge
    N = 12
    for i in range(N):
        u = i / (N - 1)
        lift = 0.0018 * (N - 1 - i)
        pts = [p + nh * (lift * k) for p, k in zip(flight(u), (1.0, 0.85, 0.7, 0.5))]
        ct = mix(col, tipc, 0.15 + 0.85 * smooth(0.3, 0.9, u))
        feather(b, pts, 0.036 - 0.006 * u, col, ct, nh, bones=_wing_w, n=12 if bar is not None else 8, asym=0.25 * u * s,
                bar=bar, bars=5, tip_from=0.4 - 0.15 * u)
    # coverts in rows over the roots of the flight feathers: greater, median, lesser, marginal
    for row, (cnt, start, ln, width, lift, shade) in enumerate((
            (10, 0.02, 0.3, 0.036, 0.024, 0.0),
            (9, 0.055, 0.17, 0.032, 0.036, 0.05),
            (8, 0.08, 0.11, 0.028, 0.046, 0.09),
            (7, 0.1, 0.065, 0.024, 0.055, 0.13))):
        for i in range(cnt):
            u = i / (cnt - 1)
            a = arm(0.03 + 0.97 * u)
            d = (_bez(flight(min(1.0, u * 1.02)), 0.3) - a).normalized()
            r0 = a + d * (start * span * (0.6 if row == 3 else 1.0)) + V(0, 0.012 if row == 3 else 0.0, 0)
            l2 = ln * span * (1.0 - 0.18 * u) if row == 0 else ln * span
            tip = r0 + d * l2
            lf = lift + 0.0012 * (cnt - 1 - i)
            c = lighten(col, shade)
            feather(b, [r0 + nh * lf, r0.lerp(tip, 0.5) + nh * (lf + 0.008), tip + nh * (lf * 0.55)], width, c,
                    lighten(c, 0.16) if bar is None else mix(c, bar, 0.6), nh, bones=_wing_w, kind="covert", n=5, tip_from=0.5)
    # the leading edge over the arm bones, rounded, from the root to the bend of the wing
    pts = [arm(w) + nh * 0.035 for w in (0.0, 0.18, 0.36, 0.55, 0.72, 0.87, 1.0)]
    pts.append(W + nh * 0.03 + V(0.012 * s, -0.03, -0.006))
    b.tube(pts, [0.014, 0.022, 0.027, 0.03, 0.03, 0.028, 0.025, 0.017], lighten(col, 0.1), cls=HAIR, bones=[_wing_w(p) for p in pts], seg=8)


# ---------------------------------------------------------------- crest
def crest(b, o, f, s):
    """A fan of long plumes from the crown, rising a little and sweeping back past the back of the
    head, so the head looks long; spread sideways, their vanes lying back over the hair (seen
    broad from behind and above, as long strokes from the side).  `crest_up` raises them."""
    col = rgb(o["crest"])
    tipc = rgb(o.get("crest_tip", lighten(col, 0.3)))
    n = max(3, min(5, int(o.get("crest_n", 5))))
    L = o.get("crest_len", 0.26)
    up = o.get("crest_up", 0.3)
    spread = o.get("crest_spread", 0.42 if n > 3 else 0.3)
    p0 = _on_head(f, s, _dvec(0.0, 1.0, 0.1))
    root = p0 - (p0 - HC).normalized() * 0.008
    wd = 0.022 * (L / 0.26) ** 0.4
    for i in range(n):
        a = (i / (n - 1) - 0.5) * 2.0
        yaw = a * spread
        el = 0.36 + 0.85 * up - 0.12 * abs(a)
        dirv = V(math.sin(yaw) * math.cos(el), math.sin(el), -math.cos(yaw) * math.cos(el))
        li = L * (1.0 - 0.22 * abs(a))
        r0 = root + V(a * 0.014, -0.002 * abs(a), -0.006 * abs(a))
        ctrl = r0 + dirv * (li * 0.55) + V(0.0, 0.02 * li, 0.0)
        tip = r0 + dirv * li + V(0.0, -0.14 * li * (1.0 - up), 0.0)
        # the vanes lie back over the head, the outer ones turned to face the sides
        nrm = V(0.0, 1.0, 0.0) - dirv * dirv.y
        nrm = Matrix.Rotation(-a * 1.05, 3, dirv) @ nrm.normalized()
        feather(b, [r0, ctrl, tip], wd, col, tipc, nrm, bone="head", kind="plume", n=7, tip_from=0.45)
    # short feathers over the roots
    for i in range(4):
        a = (i / 3 - 0.5) * 2.0
        r0 = root + V(a * 0.016, 0.003, 0.024)
        tip = r0 + V(a * 0.014, 0.022, -0.055)
        feather(b, [r0, r0.lerp(tip, 0.5) + V(0, 0.01, 0.0), tip], 0.016, col, lighten(col, 0.15), V(0, 0.9, 0.4), bone="head", kind="covert", n=4)


# ---------------------------------------------------------------- ears
def fox_ears(b, o, f, s):
    """Tall triangular fox ears standing on the head: a furred shell, flat and cupped in front,
    a lighter inner ear and tufts of pale fur in the opening, the tips darker."""
    col = rgb(o.get("ear_col", o.get("hair", "d86a30")))
    inner = rgb(o.get("ear_inner", mix(col, "f8e8e0", 0.6)))
    tipc = rgb(o.get("ear_tip", darken(col, 0.35)))
    k = o.get("ear_size", 1.0)
    H, W0, D0 = 0.12 * k, 0.042 * k, 0.021 * k
    for sd in (1, -1):
        p0 = _on_head(f, s, _dvec(0.5 * sd, 0.84, 0.12))
        base = p0 - (p0 - HC).normalized() * 0.008
        A = V(0.4 * sd, 1.0, -0.08).normalized()
        F = V(0.18 * sd, 0.0, 1.0)
        F = (F - A * A.dot(F)).normalized()
        S = A.cross(F).normalized()

        def frame(t):
            c = base + A * (H * t) - F * (0.014 * k * t * t)
            w = W0 * max(0.03, 1.0 - t) ** 0.85 * (1.0 + 0.18 * math.sin(math.pi * t))
            dd = D0 * max(0.05, 1.0 - t) ** 0.7
            return c, w, dd

        def front(sa, dd):
            # the front of the ear is cupped: its rim stands forward of the hollow in the middle
            return dd * (0.4 * sa - 0.55 * sa * sa) if sa > 0.0 else dd * sa

        rings = []
        cols = []
        for t in (0.0, 0.1, 0.22, 0.36, 0.5, 0.64, 0.78, 0.9, 1.0):
            c, w, dd = frame(t)
            ring = []
            for j in range(12):
                a = 2.0 * math.pi * j / 12
                ring.append(c + S * (math.cos(a) * w) + F * front(math.sin(a), dd))
            rings.append(ring)
            cols.append(mix(col, tipc, smooth(0.6, 0.95, t)))
        loft(b, rings, col, cls=HAIR, cols=cols, bone="head", cap0=True, cap1=True, cap_push=0.4)
        rows = []
        rc = []
        for t in (0.05, 0.18, 0.33, 0.48, 0.63, 0.78, 0.9):
            c, w, dd = frame(t)
            row = []
            for ca in (-0.78, -0.4, 0.0, 0.4, 0.78):
                sa = math.sqrt(1.0 - ca * ca)
                row.append(c + S * (ca * w * 0.98) + F * (front(sa, dd) + 0.0015))
            rows.append(row)
            rc.append([mix(inner, col, 0.35), inner, darken(inner, 0.12), inner, mix(inner, col, 0.35)])
        b.sheet(rows, inner, cls=HAIR, bone="head", cols=rc, thickness=0.002)
        for j in range(3):
            q = base + A * (H * 0.1) + S * (W0 * 0.3 * (j - 1)) + F * 0.001
            strand(b, [q, q + A * (0.022 * k) + F * 0.006 + S * (0.004 * (j - 1)), q + A * (0.04 * k) + F * 0.007 + S * (0.008 * (j - 1))],
                   0.0065 * k, 0.0012, lighten(inner, 0.5), cls=HAIR, bone="head", seg=4, per=2)


def fin_ears(b, o, f, s):
    """Fan-shaped fins where the human ears were: bony rays fanning back from a root beside the
    cheek, a webbed membrane between them that pales to a translucent edge, scalloped between the
    rays.  Over long hair the fins grow out through the hair."""
    col = rgb(o.get("ear_col", "4aa8a0"))
    edge = rgb(o.get("ear_inner", lighten(col, 0.6)))
    k = o.get("ear_size", 1.0)
    Lf = 0.105 * k
    for sd in (1, -1):
        e = HC + V(RX * f.wide * 0.97 * sd, -0.018, -0.008)
        out = 0.012
        if s is not None and s.style == "long":
            # the hair falls over the side of the head: root the fin on its surface
            q = s.pt(_dvec(math.sin(1.66) * sd, 0.18, math.cos(1.66)))
            rc = math.hypot(q.x - HC.x, q.z - HC.z) + 0.022
            out = max(out, rc - abs(e.x - HC.x))
        root = e + V((0.004 + out * 0.5) * sd, 0.008, 0.012)
        B = V(0.5 * sd, 0.0, -1.0).normalized()
        U = V(0.0, 1.0, 0.0)
        N = B.cross(U).normalized()
        if N.x * sd < 0:
            N = -N
        root = root + N * (out * 0.5)
        thetas = [math.radians(a) for a in (62, 40, 18, -4, -26, -48)]

        def at(th, r, scallop=1.0):
            ln = Lf * (0.6 + 0.4 * smooth(-0.9, 1.1, th)) * scallop
            return root + (B * math.cos(th) + U * math.sin(th)) * (ln * r) + N * (0.014 * k * r * r * ln / Lf)

        cols_th = []
        for j in range(len(thetas) * 2 - 1):
            if j % 2 == 0:
                cols_th.append((thetas[j // 2], 1.0))
            else:
                cols_th.append(((thetas[j // 2] + thetas[j // 2 + 1]) * 0.5, 0.8))
        rows = []
        rcols = []
        for r in (0.1, 0.4, 0.72, 1.0):
            rows.append([at(th, r, 1.0 - (1.0 - sc) * r ** 3) for th, sc in cols_th])
            rcols.append(mix(col, edge, smooth(0.0, 1.0, r) * 0.9))
        b.sheet(rows, col, cls=CRYSTAL, bone="head", cols=rcols, thickness=0.002)
        for th in thetas:
            pts = [root + N * 0.001, at(th, 0.5) + N * 0.0016, at(th, 1.03) + N * 0.0016]
            strand(b, pts, 0.0026 * k, 0.0007, darken(col, 0.12), col_tip=lighten(col, 0.25), cls=STONE, bone="head", seg=4, per=2)
        b.ellipsoid(root, (0.007 * k, 0.015 * k, 0.01 * k), darken(col, 0.05), cls=SKIN, bone="head", seg=10, rings=6, rot=(0.0, math.atan2(B.x, B.z), 0.0))


# ---------------------------------------------------------------- tails
def tails(b, o):
    """Fox tails from under the sash at the back.  One or two hang down behind and curl up at the
    ends; three or more rise in a fan behind the back like the nine-tailed fox of the Classic of
    Mountains and Seas, alternate tails standing further back so neighbours do not run into each
    other where they are thickest."""
    n = max(1, min(9, int(o["tails"])))
    col = rgb(o.get("tail_col", o.get("ear_col", "e8e4dc")))
    tipc = rgb(o.get("tail_tip", "fbfaf6"))
    L = o.get("tail_len", 0.58)
    R = o.get("tail_r", 0.1 if n <= 3 else (0.09 if n <= 6 else 0.08))
    if n == 1:
        phis = [math.pi - 0.4]
    elif n == 2:
        phis = [math.pi - 0.6, math.pi + 0.6]
    else:
        pmax = min(1.75, 0.55 + 0.14 * n)
        phis = [-pmax + 2.0 * pmax * i / (n - 1) for i in range(n)]
    for i, phi in enumerate(phis):
        row = 0 if n < 3 else (i - n // 2) % 2
        back = 0.45 if n < 3 else (0.62 if row == 0 else 0.42)
        ln = L * (1.0 - 0.08 * row) * ((1.0 - 0.12 * abs(math.sin(phi))) if n >= 3 else 1.0)
        _tail(b, phi, ln, R, col, tipc, back, i)


def _tail(b, phi, L, R, col, tipc, back, seed):
    """One fox tail: it leaves the robe below the sash going back, sweeps out along its fan angle
    `phi` (0 straight up, +/-pi/2 sideways, pi hanging down) and curls at the end, back and up;
    thin at the root, full and round through the middle, tapering to a pale point, with clumps of
    fur round it."""
    out = V(math.sin(phi), math.cos(phi), 0.0)
    bk = V(0.0, 0.0, -1.0)
    upk = 0.6 * (1.0 - math.cos(phi)) * 0.5 - 0.25 * max(0.0, math.cos(phi)) ** 2
    curl = (bk * 0.75 + V(0.0, upk, 0.0)).normalized()
    root = V(0.05 * math.sin(phi), 0.955, -0.112)
    m = 16
    centres = []
    for j in range(m + 1):
        t = j / m
        centres.append(root + bk * (L * back * math.sin(t * math.pi * 0.5) ** 0.8) + out * (L * 0.8 * t ** 1.45) + curl * (L * 0.3 * smooth(0.4, 1.0, t) ** 1.5))
    tans = path_dirs(centres)
    nrm, _ = look_frame(tans[0])
    down = max(0.0, -math.cos(phi))
    rings = []
    vcols = []
    bones = []
    for j, c in enumerate(centres):
        t = j / m
        if j > 0:
            q = tans[j - 1].rotation_difference(tans[j])
            nrm = (q @ nrm).normalized()
        bi = tans[j].cross(nrm).normalized()
        r = R * (0.3 + 0.7 * smooth(0.0, 0.36, t)) * max(0.03, 1.0 - smooth(0.55, 1.0, t)) ** 0.55
        base = mix(col, tipc, smooth(0.64, 0.78, t))
        ring = []
        rc = []
        for i in range(12):
            a = 2.0 * math.pi * i / 12
            fl = (0.15 * math.sin(6 * a + 15 * t + seed) + 0.07 * math.sin(11 * a - 9 * t + seed * 2.0)) * smooth(0.05, 0.3, t)
            ring.append(c + nrm * (math.cos(a) * r * (1.0 + fl)) + bi * (math.sin(a) * r * (1.0 + fl)))
            rc.append(lighten(base, fl * 0.5) if fl > 0.0 else darken(base, -fl * 0.8))
        rings.append(ring)
        vcols.append(rc)
        k = smooth(0.06, 0.8, t)
        bones.append({"hips": 1.0 - (0.38 + 0.25 * down) * k, "robe_b": 0.25 * down * k, "cape": 0.22 * k * (1.0 - down), "cape2": 0.16 * k})
    loft(b, rings, col, cls=HAIR, col_fn=lambda p, j, i: vcols[j][i], bones=bones, cap0=True, cap1=True, cap_push=0.5)
    # a wisp of longer hair at the point
    tip = centres[-1]
    d = tans[-1]
    for w in range(3):
        a = 2.0 * math.pi * w / 3 + seed
        off = nrm * (math.cos(a) * 0.006) + d.cross(nrm) * (math.sin(a) * 0.006)
        strand(b, [tip - d * 0.045 + off, tip + d * 0.008 + off * 1.5, tip + d * 0.036 + off * 0.6], 0.011, 0.0015, tipc, cls=HAIR, bones=[bones[-1]] * 3, seg=4, per=2)


# ---------------------------------------------------------------- scales, whiskers, antlers
def _head_normal(f, d):
    """Outward normal of the sculpted head at direction d (finite differences)."""
    t1, _ = look_frame(d)
    t2 = d.cross(t1).normalized()
    e = 0.01
    a = f.shape((d + t1 * e).normalized()) - f.shape((d - t1 * e).normalized())
    c = f.shape((d + t2 * e).normalized()) - f.shape((d - t2 * e).normalized())
    n = a.cross(c).normalized()
    return n if n.dot(d) > 0.0 else -n


def scales(b, o, f):
    """Patches of small overlapping scales: a band from the cheekbone below the outer corner of the
    eye up to the temple, and the backs of the hands.  Each scale is tipped so its lower edge
    lifts over the next, paler on top and darker at the edge; glossy like enamel."""
    col = rgb(o["scales"])
    hi = lighten(col, 0.22)
    lo = darken(col, 0.32)
    for sd in (1, -1):
        # two staggered rows over the cheekbone, rising towards the temple in front of the locks of
        # hair that frame the face, the outer row further round towards the ear; smaller at the ends
        for row, cnt in ((0, 5), (1, 4)):
            for j in range(cnt):
                t = (j + 0.5 * row) / 4.0
                az = math.radians(40.0 + 21.0 * t + 8.0 * row)
                el = math.radians(-27.0 + 22.0 * t - 1.0 * row)
                d = V(math.sin(az) * sd * math.cos(el), math.sin(el), math.cos(az) * math.cos(el))
                p = HC + f.shape(d)
                n = _head_normal(f, d)
                size = (1.0 - 0.15 * row) * (1.0 - 0.3 * abs(t - 0.55) * 2.0)
                b.ellipsoid(p + n * 0.0015, (0.0088 * size, 0.0074 * size, 0.0022 * size), hi, cls=METAL, bone="head", rot=_orient(n, 0.32), seg=6, rings=4, mat=MAT_PLAIN, col2=lo)
        # the back of the hand faces outwards
        hb = "hand." + ("L" if sd > 0 else "R")
        wr = V(WRI.x * sd, WRI.y, WRI.z) + V(0.004 * sd, -0.018, 0.004)
        L = 0.085
        for t, zs in ((0.25, (-0.3, 0.3)), (0.45, (0.0,)), (0.66, (-0.26, 0.26))):
            c = wr + V(0.002 * sd * t, -L * t, 0.006 * t)
            th = 0.016 - 0.003 * t
            w = 0.026 + 0.012 * t
            for z in zs:
                x = th * max(0.0, 1.0 - abs(z) ** 2.6) ** (1.0 / 2.6)
                p = c + V((x + 0.0014) * sd, 0.0, z * w)
                n = V(sd, 0.0, z * 0.5).normalized()
                size = 1.0 - 0.2 * t
                b.ellipsoid(p, (0.008 * size, 0.0068 * size, 0.002), hi, cls=METAL, bone=hb, rot=_orient(n, 0.3), seg=6, rings=4, mat=MAT_PLAIN, col2=lo)


def whiskers(b, o, f):
    """Two long dragon whiskers from beside the nostrils, curving out, down and a little back."""
    col = rgb(o["whiskers"])
    for sd in (1, -1):
        r = HC + f.surface(0.013 * sd, MOUTH_Y + 0.013) + V(0.0, 0.0, 0.003)
        pts = [r, r + V(0.03 * sd, 0.004, 0.012), r + V(0.075 * sd, -0.01, 0.02), r + V(0.12 * sd, -0.045, 0.018), r + V(0.15 * sd, -0.09, 0.01), r + V(0.165 * sd, -0.13, -0.004)]
        strand(b, pts, 0.0032, 0.0008, col, col_tip=lighten(col, 0.35), cls=HAIR, bone="head", seg=5, per=3)


def antlers(b, o, top):
    """Branching antlers swept back from the head: a burr at the base, a main beam with a brow
    tine forward, two tines rising from it and a fork at the top, paling towards the points."""
    hcol = rgb(o.get("horn_col", "c8b890"))
    tip_col = lighten(hcol, 0.4)
    k = o.get("antler_size", 1.0)
    for sd in (1, -1):
        base = V(0.06 * sd, top - 0.04, 0.03)
        beam = [base, base + V(0.03 * sd, 0.07, -0.015) * k, base + V(0.065 * sd, 0.14, -0.05) * k, base + V(0.09 * sd, 0.205, -0.11) * k, base + V(0.1 * sd, 0.25, -0.18) * k]
        strand(b, beam, 0.017 * k, 0.004 * k, hcol, col_tip=tip_col, cls=STONE, bone="head", seg=8, per=4)
        burr = beam[0].lerp(beam[1], 0.12)
        ax = (beam[1] - beam[0]).normalized()
        b.tube([burr + ax * 0.005, burr - ax * 0.005], [0.022 * k, 0.022 * k], darken(hcol, 0.25), cls=STONE, bone="head", seg=10, cap0=False, cap1=False)
        cp = catmull(beam, 4)
        for t, dv, r in ((0.22, V(0.012 * sd, 0.045, 0.06), 0.009), (0.5, V(0.035 * sd, 0.07, 0.035), 0.008), (0.74, V(0.045 * sd, 0.06, -0.005), 0.007), (0.9, V(-0.01 * sd, 0.05, 0.02), 0.006)):
            q = cp[int(round(t * (len(cp) - 1)))]
            strand(b, [q, q + dv * (0.5 * k) + V(0.0, 0.006, 0.0) * k, q + dv * k], r * k, 0.0018 * k, mix(hcol, tip_col, t * 0.6), col_tip=tip_col, cls=STONE, bone="head", seg=6, per=3)
