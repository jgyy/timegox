"""Hanfu and the body parts that show from under it: torso, crossed collar, waist sash, pleated
skirt, hanging sleeves, hands, trousers and boots, capes, lamellar armour, hats and weapons.

Reference (Han-style dress): an inner robe whose white collar shows at the neck; an outer robe
crossed *left over right* so the collar makes a "y" from the left shoulder to the right hip; a
wide sash high on the waist tied in front with long tails; a skirt falling in pleats with its
front edge running on from the collar down to the hem; and wide sleeves that hang in a rounded
pocket below the wrist.  Shoulders are soft and sloping.

Coordinates are Godot space with the character facing +Z, +X the character's left.  Angles around
the body are measured from the front (+Z) towards the left (+X).
"""

import math

from mathutils import Vector

from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, METAL, SKIN, STONE, WOOD, V, darken, lighten, lin, mix, rgb
from sculpt import bump, catmull, clamp, fbm3, loft, section, smooth, strand

HIP_Y = 0.92
SHO = V(0.19, 1.44, 0.0)
ELB = V(0.24, 1.17, -0.01)
WRI = V(0.27, 0.93, 0.03)
KNEE = V(0.105, 0.5, 0.02)
ANK = V(0.105, 0.1, -0.01)


# ---------------------------------------------------------------- the torso
class Torso:
    """Cross-sections of the clothed torso: a superellipse (square-ish shoulders and chest,
    rounder waist) whose width and depth change with height."""

    # y, half width, half depth, front shift, squareness exponent
    TABLE = [
        (0.9, 0.168, 0.126, 0.0, 2.2),
        (0.98, 0.16, 0.12, 0.004, 2.2),
        (1.06, 0.158, 0.118, 0.006, 2.3),
        (1.16, 0.17, 0.124, 0.008, 2.5),
        (1.26, 0.186, 0.13, 0.01, 2.7),
        (1.34, 0.19, 0.126, 0.008, 2.5),
        (1.4, 0.184, 0.116, 0.004, 2.45),
        (1.445, 0.152, 0.096, 0.0, 2.3),
        (1.475, 0.118, 0.08, 0.0, 2.2),
        (1.505, 0.074, 0.064, 0.0, 2.1),
        (1.525, 0.06, 0.058, 0.0, 2.0),
        (1.548, 0.056, 0.055, 0.003, 2.0),
    ]

    def __init__(self, o):
        self.fem = o.get("fem", False)
        self.build_k = o.get("build", 1.0)

    def params(self, y):
        T = self.TABLE
        if y <= T[0][0]:
            row = T[0]
            return row[1], row[2], row[3], row[4]
        for i in range(len(T) - 1):
            a, b = T[i], T[i + 1]
            if a[0] <= y <= b[0]:
                t = (y - a[0]) / (b[0] - a[0])
                t = t * t * (3 - 2 * t)
                w = a[1] + (b[1] - a[1]) * t
                d = a[2] + (b[2] - a[2]) * t
                z = a[3] + (b[3] - a[3]) * t
                e = a[4] + (b[4] - a[4]) * t
                k = self.build_k
                if y > 1.1:
                    w *= 1.0 + (k - 1.0) * 0.8
                if self.fem:
                    w *= 0.93 if y > 1.3 else (0.94 if y > 1.0 else 1.0)
                return w, d, z, e
        row = T[-1]
        return row[1], row[2], row[3], row[4]

    def radius(self, y, a):
        w, d, _, e = self.params(y)
        s, c = abs(math.sin(a)), abs(math.cos(a))
        r = (((s / w) ** e) + ((c / d) ** e)) ** (-1.0 / e)
        if self.fem and 1.2 < y < 1.38:
            # a soft bust line under the robe
            r *= 1.0 + 0.1 * bump(y, 1.29, 0.08) * (max(0.0, math.cos(a)) ** 2) * (0.6 + 0.4 * math.cos(2 * (abs(a) - 0.45)))
        return r

    def point(self, y, a, out=0.0):
        _, _, z, _ = self.params(y)
        r = self.radius(y, a) + out
        return V(math.sin(a) * r, y, math.cos(a) * r + z)

    def normal(self, y, a):
        e = 0.01
        p0 = self.point(y, a - e)
        p1 = self.point(y, a + e)
        q0 = self.point(y - e, a)
        q1 = self.point(y + e, a)
        n = (p1 - p0).cross(q1 - q0)
        out = self.point(y, a) - V(0, y, self.params(y)[2])
        if n.dot(out) < 0:
            n = -n
        return n.normalized()


def torso_w(p):
    y = p.y
    wh = clamp((1.12 - y) / 0.16)
    wc = clamp((y - 1.2) / 0.16)
    ws = max(0.0, 1.0 - wh - wc)
    w = {"hips": wh, "spine": ws, "chest": wc}
    ax = abs(p.x)
    k = clamp((ax - 0.13) / 0.07) * clamp((y - 1.3) / 0.1)
    if k > 0:
        side = "L" if p.x > 0 else "R"
        for nm in list(w):
            w[nm] *= 1.0 - k * 0.65
        w["upper_arm." + side] = k * 0.65
    if y > 1.48:
        t = clamp((y - 1.48) / 0.06)
        w = {"chest": 1.0 - 0.5 * t, "neck": 0.5 * t}
    return w


def skirt_w(p):
    t = clamp((1.0 - p.y) / 0.7)
    a = math.atan2(p.x, p.z)
    cf = max(0.0, math.cos(a)) ** 2
    cb = max(0.0, -math.cos(a)) ** 2
    cl = max(0.0, math.sin(a)) ** 2
    cr = max(0.0, -math.sin(a)) ** 2
    k = t ** 0.8
    return {"hips": max(0.02, 1.0 - k), "robe_f": k * cf, "robe_b": k * cb, "robe_l": k * cl, "robe_r": k * cr}


def drape(a, y, top, n_major=7, n_minor=17, depth=1.0, phase=0.0):
    """Fold displacement for cloth hanging from height `top`: a few big soft folds plus many
    small ones, deepening downwards, with a little noise so no two folds are alike."""
    t = clamp((top - y) / 0.6)
    big = math.sin(a * n_major + phase + 0.6 * math.sin(a * 3.0))
    small = math.sin(a * n_minor + phase * 1.7 + 1.3 * math.sin(a * 5.0 + y * 4.0))
    nz = fbm3((math.cos(a) * 2.0, y * 3.0, math.sin(a) * 2.0), 2, 9) - 0.5
    return depth * (t ** 0.8) * (0.022 * big + 0.008 * small + 0.01 * nz)


def body(b, o, tor, robe, trim, inner, gold):
    """The upper robe on the torso, with draped folds below the chest."""
    rings = []
    ys = [0.9, 0.94, 0.98, 1.02, 1.06, 1.1, 1.15, 1.2, 1.25, 1.3, 1.34, 1.38, 1.41, 1.435, 1.455, 1.475, 1.49, 1.505, 1.518, 1.53, 1.54, 1.548]
    n = 34
    for y in ys:
        ring = []
        for i in range(n):
            a = 2 * math.pi * i / n
            fold = drape(a, y, 1.3, 6, 14, 0.5) if y < 1.3 else 0.0
            ring.append(tor.point(y, a, fold))
        rings.append(ring)
    hi = lighten(robe, 0.07)

    def col(p, j, i):
        a = 2 * math.pi * i / n
        y = ys[j]
        fold = drape(a, y, 1.3, 6, 14, 0.5) if y < 1.3 else 0.0
        c = mix(darken(robe, 0.04), hi, smooth(0.95, 1.45, y))
        # fold valleys darker, ridges lighter
        c = lighten(c, fold * 3.0) if fold > 0 else darken(c, -fold * 6.0)
        return c

    loft(b, rings, robe, cls=CLOTH, col_fn=col, bone_fn=torso_w, cap0=False, cap1=False)


def band(b, pts, normals, width, thick, col, cols=None, bone_fn=None, bone=None, n=8, cls=CLOTH, tint=0.0):
    """A flat band with real thickness lying on a surface: collars, belts, straps, hem trims."""
    rings = []
    for k, p in enumerate(pts):
        a = pts[max(0, k - 1)]
        c = pts[min(len(pts) - 1, k + 1)]
        tng = (Vector(c) - Vector(a)).normalized()
        nrm = Vector(normals[k]).normalized()
        side = tng.cross(nrm).normalized()
        nrm = side.cross(tng).normalized()
        ring = []
        for i in range(n):
            ang = 2 * math.pi * i / n
            ring.append(Vector(p) + side * (math.cos(ang) * width) + nrm * (math.sin(ang) * thick))
        rings.append(ring)
    return loft(b, rings, col, cls=cls, cols=cols, bone_fn=bone_fn, bone=bone, cap0=True, cap1=True, cap_push=0.4, tint=tint)


def collar(b, o, tor, robe, trim, inner, gold):
    """Crossed collar: the white inner collar at the neck, the wide trimmed outer lapel from the
    back of the neck over the left shoulder and down across the chest to the right hip."""
    mid = rgb(o.get("collar2", mix(o.get("sash", darken(robe, 0.5)), robe, 0.35)))

    def path(a0, y0, a1, y1, n, curve=0.0):
        ps = []
        ns = []
        for k in range(n):
            t = k / (n - 1)
            a = a0 + (a1 - a0) * t
            y = y0 + (y1 - y0) * (t ** (1.0 + curve))
            ps.append(tor.point(y, a, 0.006))
            ns.append(tor.normal(y, a))
        return ps, ns

    # inner (white) collar: around the back of the neck and down to a V at the throat
    ps, ns = path(math.pi * 0.98, 1.542, -math.pi * 0.98, 1.542, 26)
    band(b, ps, ns, 0.018, 0.007, inner, bone_fn=torso_w)
    ps, ns = path(-0.6, 1.535, 0.42, 1.36, 10, 0.4)
    band(b, ps, ns, 0.017, 0.006, inner, bone_fn=torso_w)
    # outer collar: back of the neck round to the left front, then diagonally to the right hip
    ps1, ns1 = path(math.pi * 0.98, 1.53, 0.55, 1.522, 12)
    ps2, ns2 = path(0.55, 1.522, -1.0, 1.0, 22, 0.15)
    ps = ps1 + ps2[1:]
    ns = ns1 + ns2[1:]
    cols = [mix(trim, gold, 0.55) if (k % 4 == 1 and k > 10) else rgb(trim) for k in range(len(ps))]
    band(b, ps, ns, 0.028, 0.008, trim, cols=cols, bone_fn=torso_w)
    # a narrow band of the middle layer just inside the outer lapel
    ps3 = [p + n * -0.002 + (ps2[min(len(ps2) - 1, k + 1)] - ps2[max(0, k - 1)]).normalized().cross(n) * 0.03 for k, (p, n) in enumerate(zip(ps2[:14], ns2[:14]))]
    band(b, ps3, ns2[:14], 0.01, 0.006, mid, bone_fn=torso_w)
    return ps2[-1]


def sash(b, o, tor, sash_col, gold):
    """Wide sash on the waist with a woven pattern, a cord belt, a bow knot with long tails and a
    jade pendant on a tasselled cord."""
    n = 40
    lo, hi = 0.97, 1.075
    rings = []
    ys = [lo, lo + 0.012, (lo + hi) / 2, hi - 0.012, hi]
    for y in ys:
        out = 0.012 if y in (lo, hi) else 0.016
        rings.append([tor.point(y, 2 * math.pi * i / n, out) for i in range(n)])
    patt = lighten(sash_col, 0.3)

    def col(p, j, i):
        a = 2 * math.pi * i / n
        if j in (1, 3):
            return mix(sash_col, gold, 0.5)
        return patt if (j == 2 and math.sin(a * 18.0) > 0.6) else sash_col

    loft(b, rings, sash_col, cls=CLOTH, col_fn=col, bone="hips", cap0=False, cap1=False)
    # cord belt just below
    ring = [tor.point(0.955, 2 * math.pi * i / 30, 0.014) for i in range(31)]
    b.tube(ring, [0.0055] * 31, darken(sash_col, 0.3), cls=CLOTH, bone="hips", seg=6, cap0=False, cap1=False)
    # bow knot at the front left with two loops and two long tails
    kc = tor.point(1.02, 0.28, 0.03)
    b.ellipsoid(kc, (0.026, 0.024, 0.016), lighten(sash_col, 0.1), cls=CLOTH, bone="hips", seg=12, rings=8)
    for s in (1, -1):
        loop = [kc + V(0.0, 0.0, 0.004), kc + V(0.04 * s, 0.03, 0.008), kc + V(0.07 * s, 0.012, 0.006), kc + V(0.05 * s, -0.012, 0.004), kc + V(0.006 * s, -0.004, 0.004)]
        b.tube(catmull(loop, 3), [(0.016, 0.006)] * len(catmull(loop, 3)), sash_col, cls=CLOTH, bone="hips", seg=8, up=(0, 0, 1))
    for k, (dx, ln) in enumerate(((0.012, 0.48), (-0.02, 0.4))):
        top = kc + V(dx, -0.015, 0.005)
        pts = [top, top + V(dx * 0.5, -ln * 0.3, 0.02), top + V(dx, -ln * 0.65, 0.03), top + V(dx * 1.4 + 0.01, -ln, 0.03)]
        cp = catmull(pts, 3)
        bones = [{"hips": 1.0 - clamp((top.y - p.y) / 0.25), "robe_f": clamp((top.y - p.y) / 0.25)} for p in cp]
        nrm = [V(0, 0, 1)] * len(cp)
        cols = [mix(sash_col, lighten(sash_col, 0.25), i / (len(cp) - 1)) for i in range(len(cp))]
        band(b, cp, nrm, 0.022 - 0.003 * k, 0.005, sash_col, cols=cols, bone_fn=lambda p, bl=bones, cp=cp: bl[min(range(len(cp)), key=lambda i: (cp[i] - p).length)])
        # fringe at the end
        end = cp[-1]
        for f in range(5):
            x = (f / 4 - 0.5) * 0.036
            b.tube([end + V(x, 0, 0), end + V(x * 1.1, -0.04, 0.003)], [0.0025, 0.001], gold, cls=CLOTH, bone="robe_f", seg=4)
    # jade pendant (pei) on a cord with a knot and tassel
    jade = o.get("jade", "6af0b0")
    top = tor.point(0.96, -0.5, 0.02)
    cord = [top, top + V(0.004, -0.06, 0.01), top + V(0.002, -0.12, 0.014)]
    b.tube(cord, [0.0028] * 3, "b8302a", cls=CLOTH, bones=[{"hips": 1}, {"hips": 0.5, "robe_f": 0.5}, {"robe_f": 1}], seg=5)
    pc = cord[-1] + V(0, -0.03, 0.004)
    b.lathe(pc, [(0.0001, -0.028), (0.022, -0.016), (0.026, 0.0), (0.02, 0.018), (0.0001, 0.026)], jade, cls=CRYSTAL, bone="robe_f", seg=12, squash=(1.0, 0.35))
    b.ellipsoid(pc + V(0, 0, 0.008), (0.008, 0.008, 0.002), lighten(jade, 0.3), cls=CRYSTAL, bone="robe_f", seg=8, rings=5)
    for f in range(6):
        x = (f / 5 - 0.5) * 0.02
        b.tube([pc + V(x * 0.3, -0.028, 0), pc + V(x, -0.1, 0.004)], [0.0022, 0.0009], "c83a30", cls=CLOTH, bone="robe_f", seg=4)


def skirt(b, o, tor, robe, trim, inner, gold, lapel_end):
    """Pleated lower robe from the sash to the ankles; the front edge continues the collar line at
    the right front, with an inner skirt showing through, a trimmed and embroidered hem."""
    n = 52
    ys = [1.0, 0.92, 0.84, 0.76, 0.66, 0.56, 0.46, 0.36, 0.28, 0.21, 0.17]
    open_c = -0.62          # the overlap opening sits at the right front
    open_w = 0.42
    flare = o.get("flare", 1.0)

    def r_at(y, a):
        base = tor.radius(min(max(y, 0.9), 1.0), a) + 0.012
        k = clamp((1.0 - y) / 0.85)
        return base * (1.0 + (0.42 * flare) * k ** 1.15) + drape(a, y, 1.0, 8, 23, 1.3, 0.4)

    def ang(i):
        return open_c + open_w * 0.5 + (2 * math.pi - open_w) * i / n

    rings = []
    for y in ys:
        ring = []
        for i in range(n + 1):
            a = ang(i)
            z = tor.params(min(max(y, 0.9), 1.0))[2]
            r = r_at(y, a)
            # the hem lifts a little at the front so the shoes show
            yy = y + (0.02 * max(0.0, math.cos(a)) if y < 0.25 else 0.0)
            ring.append(V(math.sin(a) * r, yy, math.cos(a) * r * 0.86 + z))
        rings.append(ring)
    verts_rows = rings

    def col(p, j, i):
        a = ang(i)
        y = ys[j]
        d = drape(a, y, 1.0, 8, 23, 1.3, 0.4)
        c = mix(robe, darken(robe, 0.16), clamp((1.0 - y) / 0.85))
        return lighten(c, d * 2.2) if d > 0 else darken(c, -d * 5.0)

    # open sheet with an inside face: build as a loft that is not closed around (n+1 columns)
    _open_loft(b, verts_rows, col, inner_col=darken(robe, 0.35))
    # hem trim with a cloud scallop of embroidery
    hp = [p + V(0, 0.012, 0) for p in verts_rows[-1]]
    hn = []
    for i, p in enumerate(hp):
        q = p - V(0, p.y, 0)
        hn.append(q.normalized() if q.length > 1e-6 else V(0, 0, 1))
    hcols = [mix(trim, gold, 0.7) if (math.sin(ang(i) * 22.0) > 0.55) else rgb(trim) for i in range(len(hp))]
    band(b, hp, hn, 0.016, 0.006, trim, cols=hcols, bone_fn=skirt_w)
    # trim down both edges of the opening
    for side in (0, n):
        pts = [row[side] for row in verts_rows]
        pts = [lapel_end] + pts if side == 0 else pts
        nr = []
        for p in pts:
            q = V(p.x, 0, p.z)
            nr.append(q.normalized() if q.length > 1e-6 else V(0, 0, 1))
        band(b, pts, nr, 0.016, 0.006, trim, bone_fn=skirt_w)
    # inner skirt seen through the opening
    prof = []
    for y in ys[:-1]:
        prof.append((r_at(y, open_c) * 0.93, y))
    b.lathe(V(0, 0, 0.004), [(rr, y) for rr, y in reversed(prof)], inner, seg=24, squash=(1.0, 0.82), bone_fn=skirt_w, cap_bottom=False, cap_top=False, folds=(11, 0.03, 0.2))


def _open_loft(b, rows, col_fn, inner_col):
    """A sheet through rows of points (not closed around) with a darker inside face."""
    nr = len(rows)
    nc = len(rows[0])
    verts = []
    cols = []
    bones = []
    for j, row in enumerate(rows):
        for i, p in enumerate(row):
            verts.append(Vector(p))
            cols.append(lin(col_fn(p, j, i), CLOTH))
            bones.append(skirt_w(Vector(p)))
    faces = []
    for j in range(nr - 1):
        for i in range(nc - 1):
            a = j * nc + i
            faces.append((a, a + nc, a + nc + 1, a + 1))
    b.add(verts, faces, (1, 1, 1), CLOTH, None, 0.0, 0, True, cols=cols, bones=bones, closed=False)
    inn = []
    icol = []
    for j, row in enumerate(rows):
        for i, p in enumerate(row):
            q = Vector(p)
            c = V(0, q.y, 0)
            inn.append(c + (q - c) * 0.975)
            icol.append(lin(mix(inner_col, darken(inner_col, 0.2), j / (nr - 1)), CLOTH))
    b.add(inn, [tuple(reversed(f)) for f in faces], (1, 1, 1), CLOTH, None, 0.0, 0, True, cols=icol, bones=bones, closed=False)


# ---------------------------------------------------------------- arms
def sleeve(b, o, s, sleeve_col, trim, inner, gold):
    """Upper sleeve, then the wide hanfu sleeve hanging in a rounded pocket below the wrist, its
    opening lined and trimmed."""
    sd = "L" if s > 0 else "R"
    ua = "upper_arm." + sd
    fa = "forearm." + sd
    sh = V(SHO.x * s, SHO.y, SHO.z)
    el = V(ELB.x * s, ELB.y, ELB.z)
    wr = V(WRI.x * s, WRI.y, WRI.z)
    width = o.get("sleeve_w", 1.0)
    # upper sleeve: soft, slightly baggy, folds at the inside of the elbow
    up_pts = [sh + V(-0.05 * s, -0.012, 0.0), sh + V(-0.005 * s, -0.04, 0.0), sh.lerp(el, 0.5), el + V(0, -0.03, 0)]
    up_r = [(0.056, 0.054), (0.062, 0.06), (0.066, 0.065), (0.07, 0.07)]
    b.tube(up_pts, up_r, sleeve_col, cls=CLOTH, bones=[{"chest": 0.5, ua: 0.5}, {"chest": 0.2, ua: 0.8}, ua, {ua: 0.6, fa: 0.4}], seg=16, cap0=False, cap1=False, cols=[lighten(sleeve_col, 0.05), sleeve_col, sleeve_col, darken(sleeve_col, 0.05)])
    # the big sleeve
    axis = (wr - el).normalized()
    ts = [-0.12, 0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.12, 1.22]
    rings = []
    bones = []
    hang = 0.2 * width
    cols = []
    for k, t in enumerate(ts):
        c = el.lerp(wr, min(t, 1.0)) + axis * max(0.0, t - 1.0) * 0.24
        tt = max(0.0, t)
        rw = (0.072 + 0.07 * min(1.0, tt) ** 0.9) * width
        rb = (0.072 + 0.17 * min(1.0, tt) ** 1.2) * width   # towards the back the pocket deepens
        rf = (0.072 + 0.04 * min(1.0, tt)) * width

        def prof(a, rw=rw, rb=rb, rf=rf):
            c2, s2 = math.cos(a), math.sin(a)
            rh = rf if c2 >= 0 else rb
            return 1.0 / math.sqrt((c2 / rh) ** 2 + (s2 / rw) ** 2)

        ring = section(c, axis, prof, 18, up=V(0, 0, 1))
        # the back of the pocket hangs lower, the front stops at the wrist
        out = []
        for p in ring:
            rel = p - c
            back = clamp(-rel.z / max(rb, 1e-4))
            extra = hang * smooth(0.5, 1.2, t) * back ** 1.6
            fold = 0.006 * math.sin(math.atan2(rel.x, rel.z) * 7.0 + t * 2.0) * t
            out.append(p + axis * extra + rel.normalized() * fold)
        rings.append(out)
        bones.append({ua: 0.7, fa: 0.3} if t < 0 else ({ua: 0.4, fa: 0.6} if t == 0.0 else fa))
        cols.append(mix(sleeve_col, darken(sleeve_col, 0.12), t / 1.22))
    loft(b, rings, sleeve_col, cls=CLOTH, bones=bones, cols=cols, cap0=False, cap1=False)
    # lining just inside the opening
    lin_rings = []
    for ring in rings[-3:]:
        c = sum(ring, Vector()) / len(ring)
        lin_rings.append([c + (p - c) * 0.95 for p in ring])
    loft(b, lin_rings, darken(inner, 0.15), cls=CLOTH, bone=fa, cap0=False, cap1=False, inside=True)
    # trim at the opening
    end = rings[-1]
    c = sum(end, Vector()) / len(end)
    tp = [p + (p - c).normalized() * 0.004 - axis * 0.01 for p in end] + [end[0] + (end[0] - c).normalized() * 0.004 - axis * 0.01]
    tn = [axis] * len(tp)
    tcols = [mix(trim, gold, 0.6) if k % 3 == 0 else rgb(trim) for k in range(len(tp))]
    band(b, tp, [(p - c).normalized() for p in tp], 0.014, 0.005, trim, cols=tcols, bone=fa)
    # inner robe cuff around the wrist
    b.tube([el.lerp(wr, 0.55), wr + V(0, -0.012, 0)], [0.038, 0.036], inner, cls=CLOTH, bone=fa, seg=12)
    b.tube([wr + V(0, -0.004, 0), wr + V(0, -0.02, 0)], [0.039, 0.039], mix(inner, trim, 0.4), cls=CLOTH, bone=fa, seg=12, cap0=False, cap1=False)
    return tn


def hand(b, o, s, skin):
    """A hand hanging at the side, palm towards the thigh: palm, knuckles, three-jointed fingers
    curling slightly, a thumb with its muscle pad, nails."""
    sd = "L" if s > 0 else "R"
    hb = "hand." + sd
    wr = V(WRI.x * s, WRI.y, WRI.z) + V(0.004 * s, -0.018, 0.004)
    sk = rgb(skin)
    nail = mix(sk, "ffe8e0", 0.5)
    k = o.get("hand_k", 1.0)
    L = 0.085 * k
    # palm: a flattened box-ish loft, wider at the knuckles
    rings = []
    for t in (0.0, 0.3, 0.65, 1.0):
        c = wr + V(0.002 * s * t, -L * t, 0.006 * t)
        w = (0.026 + 0.012 * t) * k   # half width across (z)
        th = (0.016 - 0.003 * t) * k  # half thickness (x)
        ring = []
        for i in range(14):
            a = 2 * math.pi * i / 14
            ca, sa = math.cos(a), math.sin(a)
            r = 1.0 / ((abs(ca) / th) ** 2.6 + (abs(sa) / w) ** 2.6) ** (1 / 2.6)
            ring.append(c + V(ca * r * s, 0, sa * r))
        rings.append(ring)
    loft(b, rings, sk, cls=SKIN, bone=hb, cap0=True, cap1=False, cols=[darken(sk, 0.04), sk, sk, sk])
    knuck = wr + V(0.002 * s, -L, 0.006)
    # fingers: index (front) to little (back)
    spec = ((0.025, 0.074, 0.0085), (0.0085, 0.082, 0.0088), (-0.008, 0.077, 0.0084), (-0.023, 0.062, 0.0074))
    curl = o.get("curl", 0.35)
    for z, ln, r in spec:
        ln *= k
        r *= k
        base = knuck + V(0, 0.004, z * 1.05)
        d = V(0, -1, 0)
        pts = [base]
        seg_l = (ln * 0.42, ln * 0.33, ln * 0.25)
        ang = 0.0
        p = base
        for j, sl in enumerate(seg_l):
            ang += curl * (0.5 + 0.35 * j)
            d = V(-math.sin(ang) * s, -math.cos(ang), 0.0)
            p = p + d * sl
            pts.append(p)
        radii = [r, r * 0.95, r * 0.86, r * 0.72]
        b.tube(pts, radii, sk, cls=SKIN, bone=hb, seg=6)
        # knuckle bumps and the nail
        b.ellipsoid(base + V(0.004 * s, 0.0, 0.0), (r * 0.9, r * 0.8, r * 1.05), sk, cls=SKIN, bone=hb, seg=8, rings=5)
        tip = pts[-1]
        b.ellipsoid(tip + V(0.0035 * s, 0.006, 0), (0.0018, r * 0.85, r * 0.75), nail, cls=SKIN, bone=hb, seg=8, rings=5)
    # thumb: from the base of the palm forward and down, with the fleshy pad
    tb = wr + V(-0.002 * s, -0.025 * k, 0.024 * k)
    b.ellipsoid(tb + V(-0.004 * s, -0.008, -0.004), (0.012 * k, 0.022 * k, 0.014 * k), sk, cls=SKIN, bone=hb, seg=10, rings=6)
    tp = [tb, tb + V(-0.008 * s, -0.026 * k, 0.016 * k), tb + V(-0.012 * s, -0.048 * k, 0.022 * k), tb + V(-0.014 * s, -0.064 * k, 0.02 * k)]
    b.tube(tp, [0.0105 * k, 0.0095 * k, 0.0085 * k, 0.0072 * k], sk, cls=SKIN, bone=hb, seg=8)
    b.ellipsoid(tp[-1] + V(-0.002 * s, 0.005, 0.004), (0.006, 0.007, 0.0018), nail, cls=SKIN, bone=hb, seg=8, rings=5, rot=(0, 0.6 * s, 0))
    return wr + V(0, -L * 0.6, 0.01)


# ---------------------------------------------------------------- legs
def legs(b, o, pants, boots, trim):
    """Trousers and cloud-toed boots: shaft, cuff band, shaped foot, sole and upturned toe."""
    for s, sd in ((1, "L"), (-1, "R")):
        hip = V(0.1 * s, HIP_Y - 0.02, 0)
        kn = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        th, sh, ft = "thigh." + sd, "shin." + sd, "foot." + sd
        b.tube([hip, hip.lerp(kn, 0.5), kn, kn.lerp(an, 0.35)], [0.088, 0.078, 0.063, 0.059], pants, cls=CLOTH, bones=[th, th, {th: 0.5, sh: 0.5}, sh], seg=14)
        # boot shaft, slightly flared at the top, creased at the ankle
        top = kn.lerp(an, 0.32)
        b.tube([top, kn.lerp(an, 0.6), kn.lerp(an, 0.85), an + V(0, -0.02, 0.005)], [0.066, 0.058, 0.054, 0.056], boots, cls=CLOTH, bones=[sh, sh, sh, {sh: 0.5, ft: 0.5}], seg=14, cols=[lighten(boots, 0.05), boots, darken(boots, 0.08), boots])
        b.tube([top + V(0, 0.016, 0), top - V(0, 0.016, 0)], [0.07, 0.07], trim, cls=CLOTH, bone=sh, seg=14, cap0=False, cap1=False)
        for k in range(3):
            q = kn.lerp(an, 0.8 + k * 0.05)
            b.tube([q + V(0.0, 0.002, 0.0), q - V(0, 0.002, 0)], [0.057, 0.057], darken(boots, 0.18), cls=CLOTH, bone=sh, seg=12, cap0=False, cap1=False)
        # foot: a loft from heel to toe, low and narrow at the toe
        fc = []
        rows = []
        for t, (zz, hh, ww) in enumerate(((-0.06, 0.06, 0.042), (-0.01, 0.07, 0.046), (0.05, 0.055, 0.048), (0.11, 0.04, 0.044), (0.16, 0.03, 0.034), (0.19, 0.025, 0.022))):
            c = V(ANK.x * s, 0.022 + hh * 0.5, zz)
            fc.append(c)
            rows.append([c + V(math.sin(2 * math.pi * i / 14) * ww, math.cos(2 * math.pi * i / 14) * hh * 0.5, 0) for i in range(14)])
        loft(b, rows, boots, cls=CLOTH, bones=[{sh: 0.3, ft: 0.7}, ft, ft, ft, ft, ft], cols=[darken(boots, 0.12), boots, boots, lighten(boots, 0.04), boots, boots])
        # sole
        sole = []
        for t in range(7):
            z = -0.075 + t * 0.045
            w = 0.044 if t < 5 else 0.03
            sole.append((V(ANK.x * s, 0.012, z), w))
        b.tube([q for q, _ in sole], [(w, 0.012) for _, w in sole], "e8e0d0" if o.get("white_sole", True) else darken(boots, 0.5), cls=CLOTH, bone=ft, seg=10, up=(0, 1, 0))
        # cloud toe curling up
        toe = [V(ANK.x * s, 0.03, 0.17), V(ANK.x * s, 0.055, 0.205), V(ANK.x * s, 0.085, 0.205), V(ANK.x * s, 0.09, 0.185)]
        b.tube(toe, [0.02, 0.016, 0.01, 0.004], trim, cls=CLOTH, bone=ft, seg=8)


# ---------------------------------------------------------------- cape, armour
def cape(b, o, cc):
    """A cape hanging from the shoulders in folds, its hem curving round."""
    rows = []
    bones = []
    cols = []
    n = 10
    m = 13
    for j in range(n):
        t = j / (n - 1)
        y = 1.47 - t * 1.04
        half = 0.19 + t * 0.15
        z = -0.13 - t * 0.17
        row = []
        for i in range(m):
            u = i / (m - 1) - 0.5
            fold = 0.025 * t * math.sin(u * math.pi * 6.0 + 0.5) + 0.01 * t * math.sin(u * math.pi * 13.0)
            row.append(V(u * 2 * half, y + abs(u) * 0.04 * (1 + t) - (0.03 * (1 - (2 * u) ** 2) if j == n - 1 else 0.0), z - (1 - (u * 2) ** 2) * 0.04 + fold))
        rows.append(row)
        if t < 0.12:
            bones.append({"chest": 1.0})
        elif t < 0.5:
            k = (t - 0.12) / 0.38
            bones.append({"chest": 1 - k, "cape": k})
        else:
            k = (t - 0.5) / 0.5
            bones.append({"cape": 1 - k, "cape2": k})
        cols.append(mix(cc, darken(cc, 0.32), t))
    b.sheet(rows, cc, bones=bones, cols=cols, thickness=0.014)
    trim = o.get("trim", "f0e0c0")
    hem = rows[-1]
    b.tube([p + V(0, 0.004, 0) for p in hem], [0.008] * len(hem), trim, cls=CLOTH, bones=[bones[-1]] * len(hem), seg=6, cap0=True, cap1=True)
    for s in (1, -1):
        b.lathe(V(0.11 * s, 1.455, -0.085), [(0.0001, -0.008), (0.026, -0.004), (0.026, 0.004), (0.0001, 0.009)], "f0c850", cls=METAL, bone="chest", seg=14, rot=(math.pi / 2, 0, 0))
        b.ball(V(0.11 * s, 1.455, -0.075), 0.008, o.get("jade", "6af0b0"), cls=CRYSTAL, bone="chest", seg=8, rings=5)


def armour(b, o, tor, metal):
    """Lamellar armour: rows of small overlapping plates on the shoulders, a lamellar cuirass with
    round 'mirror' guards and rivets, and plated tassets over the hips."""
    mt = rgb(metal)
    dk = darken(mt, 0.35)
    # pauldrons: three curved shells overlapping down the upper arm, each covering its outer half
    for s, sd in ((1, "L"), (-1, "R")):
        sh = V(SHO.x * s, SHO.y, SHO.z)
        el = V(ELB.x * s, ELB.y, ELB.z)
        axis = (el - sh).normalized()
        for row in range(3):
            c = sh + axis * (0.01 + 0.055 * row) + V(0.0, 0.03 - 0.01 * row, 0)
            rr = 0.095 - 0.008 * row
            rows = []
            for j in range(4):
                t = j / 3
                cc = c + axis * (0.06 * t)
                ring = []
                for i in range(9):
                    a = -1.9 + 3.8 * i / 8
                    out = V(s * math.cos(a) * 0.9 + 0.1 * s, math.sin(a) * 0.0 + 0.45 * math.cos(a), math.sin(a))
                    out = (out - axis * out.dot(axis)).normalized()
                    ring.append(cc + out * (rr + 0.012 * t))
                rows.append(ring)
            w = {"chest": 0.3, "upper_arm." + sd: 0.7} if row == 0 else {"upper_arm." + sd: 1.0}
            b.sheet(rows, mt, cls=METAL, bones=[w] * 4, cols=[lighten(mt, 0.15), mt, mt, dk], thickness=0.012)
            edge = rows[-1]
            b.tube(edge, [0.006] * len(edge), "c8a040", cls=METAL, bones=[w] * len(edge), seg=4)
    # cuirass: lamellae laced in horizontal rows round the chest and back, hugging the robe, with
    # a small round plaque over the sternum and leather straps over the shoulders
    ys = [1.15, 1.18, 1.21, 1.24, 1.27, 1.3, 1.33, 1.36, 1.39]
    n = 40
    rings = [[tor.point(y, 2 * math.pi * i / n, 0.014) for i in range(n)] for y in ys]

    def lam(p, j, i):
        c = mt if j % 2 == 0 else mix(mt, dk, 0.5)
        if i % 4 == 0:
            c = darken(c, 0.2)
        return c

    loft(b, rings, mt, cls=METAL, col_fn=lam, bone_fn=torso_w, cap0=False, cap1=False)
    for y in (ys[0], ys[-1]):
        ring = [tor.point(y, 2 * math.pi * i / 30, 0.02) for i in range(31)]
        b.tube(ring, [0.007] * 31, "4a3020", cls=CLOTH, bones=[torso_w(p) for p in ring], seg=5, cap0=False, cap1=False)
    for s in (1, -1):
        strap = [tor.point(1.39, 0.5 * s, 0.018), tor.point(1.46, 0.75 * s, 0.012), tor.point(1.47, math.pi - 0.75 * s, 0.012), tor.point(1.39, math.pi - 0.5 * s, 0.018)]
        b.tube(strap, [(0.016, 0.004)] * 4, "4a3020", cls=CLOTH, bones=[torso_w(p) for p in strap], seg=6, up=(0, 1, 0))
    c = tor.point(1.28, 0.0, 0.02)
    b.lathe(c, [(0.0001, -0.004), (0.032, -0.003), (0.034, 0.002), (0.02, 0.005), (0.0001, 0.006)], lighten(mt, 0.3), cls=METAL, bone="chest", seg=16, rot=(math.pi / 2, 0, 0))
    # tassets
    for k in range(9):
        a = (k / 8 - 0.5) * 3.6
        top = tor.point(0.97, a, 0.03)
        for r in range(3):
            c = top + V(0, -0.04 - r * 0.05, 0) + (top - V(0, top.y, 0)).normalized() * (0.01 + r * 0.012)
            b.superquad(c, (0.028, 0.026, 0.005), mt if (k + r) % 2 else dk, e=0.4, cls=METAL, bone=skirt_w(c), rot=(0, a, 0), seg=8, rings=5)


# ---------------------------------------------------------------- hats and head ornaments
def hat(b, o, kind, top):
    """`top` is the height of the top of the hair."""
    hc = o.get("hat_col")
    if kind == "straw":
        col = rgb(hc or "d8c080")
        base = top - 0.05
        prof = [(0.4, 0.0), (0.37, 0.02), (0.3, 0.05), (0.2, 0.1), (0.1, 0.16), (0.03, 0.2), (0.001, 0.215)]
        verts = b.lathe(V(0, base, -0.01), prof, col, cls=WOOD, bone="head", seg=40, cap_bottom=True)
        b.recolor(verts, lambda p: darken(col, 0.18) if math.sin(math.hypot(p.x, p.z + 0.01) * 160.0) > 0.6 else None)
        b.tube([V(math.sin(2 * math.pi * i / 40) * 0.4, base - 0.002, -0.01 + math.cos(2 * math.pi * i / 40) * 0.4) for i in range(41)], [0.007] * 41, darken(col, 0.3), cls=WOOD, bone="head", seg=5, cap0=False, cap1=False)
        b.ball(V(0, base + 0.215, -0.01), 0.014, darken(col, 0.25), cls=WOOD, bone="head", seg=8, rings=5)
        for side in (1, -1):
            strand(b, [V(0.11 * side, base + 0.02, 0.0), V(0.1 * side, 1.62, 0.07), V(0.04 * side, 1.58, 0.1), V(0.0, 1.575, 0.105)], 0.003, 0.003, "6a4a2a", cls=CLOTH, bone="head", seg=4, per=3)
    elif kind == "scholar":
        col = rgb(hc or "1a1a22")
        base = top - 0.07
        b.lathe(V(0, base, -0.02), [(0.112, 0.0), (0.116, 0.05), (0.108, 0.09), (0.07, 0.12), (0.001, 0.13)], col, cls=CLOTH, bone="head", seg=24)
        b.lathe(V(0, base + 0.06, -0.075), [(0.05, 0.0), (0.055, 0.05), (0.03, 0.09), (0.001, 0.1)], darken(col, 0.1), cls=CLOTH, bone="head", seg=16)
        b.tube([V(-0.115, base + 0.005, -0.02), V(0.115, base + 0.005, -0.02)], [0.008, 0.008], lighten(col, 0.1), cls=CLOTH, bone="head", seg=6)
        for side in (1, -1):
            b.superquad(V(0.2 * side, base + 0.075, -0.075), (0.11, 0.016, 0.004), col, e=0.25, cls=CLOTH, bone="head", rot=(0, 0, 0.05 * side))
    elif kind == "hood":
        col = rgb(hc or "6a5a8a")
        rows = []
        for j in range(9):
            t = j / 8
            y = top + 0.03 - t * 0.36
            r = 0.15 + 0.03 * math.sin(t * math.pi) + 0.06 * t
            row = []
            for i in range(17):
                a = math.pi * 0.42 + (i / 16) * math.pi * 1.16
                fold = 0.008 * math.sin(i * 1.9 + j) * t
                row.append(V(math.sin(a) * (r + fold), y, math.cos(a) * (r + fold) - 0.03 - 0.02 * t))
            rows.append(row)
        bones = [{"head": 1.0} if j < 5 else {"head": 0.6, "neck": 0.4} for j in range(9)]
        b.sheet(rows, col, bones=bones, cols=[mix(col, darken(col, 0.3), j / 8) for j in range(9)], thickness=0.016)
        rim = [rows[j][0] for j in range(9)]
        rim2 = [rows[j][-1] for j in range(9)]
        b.tube(rim, [0.012] * 9, darken(col, 0.2), cls=CLOTH, bones=bones, seg=6)
        b.tube(rim2, [0.012] * 9, darken(col, 0.2), cls=CLOTH, bones=bones, seg=6)
        b.ellipsoid(V(0, top - 0.05, -0.08), (0.15, 0.1, 0.12), col, cls=CLOTH, bone="head", seg=18, rings=10)
    elif kind == "fur":
        col = rgb(hc or "c8b8a0")
        base = top - 0.06
        verts = b.lathe(V(0, base, -0.015), [(0.13, 0.0), (0.145, 0.03), (0.14, 0.09), (0.11, 0.13), (0.001, 0.15)], col, cls=HAIR, bone="head", seg=28, folds=(19, 0.05, 0.0))
        b.recolor(verts, lambda p: lighten(col, 0.15) if fbm3((p.x * 60, p.y * 30, p.z * 60), 2, 3) > 0.55 else None, cls=HAIR)
        b.lathe(V(0, base - 0.012, -0.015), [(0.15, 0.0), (0.155, 0.02), (0.15, 0.045), (0.13, 0.05)], lighten(col, 0.1), cls=HAIR, bone="head", seg=28, folds=(31, 0.06, 0.3), cap_bottom=False)
    elif kind == "qing":
        col = rgb(hc or "2a2a30")
        base = top - 0.06
        b.lathe(V(0, base, -0.02), [(0.17, 0.0), (0.175, 0.03), (0.12, 0.045), (0.11, 0.1), (0.07, 0.14), (0.001, 0.15)], col, cls=CLOTH, bone="head", seg=28)
        b.lathe(V(0, base + 0.04, -0.02), [(0.115, 0.0), (0.09, 0.08), (0.001, 0.115)], "c02a20", cls=HAIR, bone="head", seg=28, folds=(24, 0.12, 0.0))
        b.ball(V(0, base + 0.165, -0.02), 0.022, "e8c050", cls=METAL, bone="head", seg=10, rings=6)
        strand(b, [V(0, base + 0.15, -0.05), V(0, base + 0.1, -0.15), V(0, base - 0.05, -0.22)], 0.016, 0.004, "3a8a7a", cls=HAIR, bone="head", flat=0.35, seg=6)


def crown(b, o, top):
    """A small gold coronet with points and a red jewel."""
    gold = "f0c850"
    y = top - 0.035
    b.lathe(V(0, y, -0.03), [(0.06, 0.0), (0.064, 0.02), (0.058, 0.035)], gold, cls=METAL, bone="head", seg=20, cap_bottom=False, cap_top=False)
    for i in range(7):
        a = (i / 6 - 0.5) * 2.4
        b.cone(V(math.sin(a) * 0.062, y + 0.06, -0.03 + math.cos(a) * 0.05), 0.012, 0.055 - 0.012 * abs(a), gold, cls=METAL, bone="head", seg=6)
        b.ball(V(math.sin(a) * 0.062, y + 0.09 - 0.012 * abs(a), -0.03 + math.cos(a) * 0.05), 0.006, "fff0b0", cls=METAL, bone="head", seg=6, rings=4)
    b.ball(V(0, y + 0.03, 0.025), 0.013, "ff4050", cls=CRYSTAL, bone="head", seg=10, rings=6, mat=MAT_GLOW)


# ---------------------------------------------------------------- weapons
def sword(b, bone, grip, blade, hilt, tassel="e04050"):
    """A jian held in the hand: wrapped grip, pommel, guard, long double-edged blade with a ridge,
    a faint glowing edge and a tassel."""
    g = V(grip)
    d = V(0, -0.25, 1.0).normalized()
    up = V(1, 0, 0)
    grip_pts = [g - d * 0.09 + d * (k / 6) * 0.15 for k in range(7)]
    b.tube(grip_pts, [0.016, 0.017, 0.016, 0.017, 0.016, 0.017, 0.016], hilt, cls=WOOD, bone=bone, seg=8, cols=[hilt if k % 2 else darken(hilt, 0.3) for k in range(7)])
    b.lathe(g - d * 0.1, [(0.0001, -0.02), (0.018, -0.012), (0.022, 0.0), (0.014, 0.012)], "d8b050", cls=METAL, bone=bone, seg=10, rot=(math.atan2(-d.y, d.z) + math.pi / 2, 0, 0))
    b.ellipsoid(g + d * 0.075, (0.07, 0.018, 0.024), "d8b050", cls=METAL, bone=bone, rot=(math.atan2(-d.y, d.z), 0, 0), seg=14, rings=6)
    b.ball(g + d * 0.075 + V(0, 0.0, 0.0), 0.012, "50c0a0", cls=CRYSTAL, bone=bone, seg=8, rings=5)
    pts = [g + d * (0.09 + 0.8 * t) for t in (0.0, 0.25, 0.5, 0.75, 0.92, 1.0)]
    b.tube(pts, [(0.024, 0.006), (0.0235, 0.006), (0.0225, 0.0058), (0.021, 0.0055), (0.016, 0.004), (0.002, 0.001)], blade, cls=METAL, bone=bone, seg=8, up=up)
    b.tube([g + d * 0.1, g + d * 0.84], [(0.003, 0.0068), (0.002, 0.004)], lighten(blade, 0.25), cls=METAL, bone=bone, seg=5, up=up)
    b.tube([g + d * 0.12, g + d * 0.86], [(0.0026, 0.0035), (0.0016, 0.002)], lighten(blade, 0.5), cls=CRYSTAL, bone=bone, seg=5, mat=MAT_GLOW, up=up)
    tp = [g - d * 0.1, g - d * 0.12 + V(0, -0.06, 0), g - d * 0.14 + V(0, -0.13, 0)]
    b.tube(tp, [0.004, 0.004, 0.004], tassel, cls=CLOTH, bone=bone, seg=5)
    for k in range(7):
        x = (k / 6 - 0.5) * 0.022
        b.tube([tp[-1] + V(x * 0.3, 0, 0), tp[-1] + V(x, -0.09, 0.004 * k)], [0.0028, 0.001], lighten(tassel, 0.15), cls=CLOTH, bone=bone, seg=4)


def scabbard(b, col):
    pts = [V(0.2, 0.99, -0.04), V(0.235, 0.82, -0.12), V(0.27, 0.64, -0.2)]
    b.tube(pts, [(0.024, 0.011), (0.022, 0.01), (0.018, 0.008)], col, cls=WOOD, bones=[{"hips": 1}, {"hips": 0.6, "robe_l": 0.4}, {"hips": 0.4, "robe_l": 0.6}], seg=10, up=(1, 0, 0))
    for t in (0.0, 0.45, 1.0):
        q = pts[0].lerp(pts[-1], t)
        b.tube([q + V(0, 0.012, 0.0), q - V(0, 0.012, 0)], [(0.027, 0.014), (0.027, 0.014)], "d8b050", cls=METAL, bones=[{"hips": 0.6, "robe_l": 0.4}] * 2, seg=10, cap0=False, cap1=False, up=(1, 0, 0))


def staff(b, hc, gem):
    """A gnarled wooden staff with a gold claw holding a glowing gem."""
    pts = [hc + V(0.004 * math.sin(k * 1.7), -0.8 + k * 0.1, 0.004 * math.cos(k * 2.3)) for k in range(15)]
    b.tube(pts, [0.019 - 0.002 * (k % 3 == 0) for k in range(15)], "7a5a3a", cls=WOOD, bone="hand.R", seg=8, cols=[darken("7a5a3a", 0.15 * (k % 2)) for k in range(15)])
    top = pts[-1]
    for k in range(3):
        y = top.y - 0.12 - k * 0.025
        b.tube([V(top.x, y, top.z), V(top.x, y - 0.012, top.z)], [0.022, 0.022], "c83a30", cls=CLOTH, bone="hand.R", seg=8, cap0=False, cap1=False)
    for i in range(6):
        a = 2 * math.pi * i / 6
        strand(b, [top, top + V(math.cos(a) * 0.035, 0.03, math.sin(a) * 0.035), top + V(math.cos(a) * 0.045, 0.085, math.sin(a) * 0.045), top + V(math.cos(a) * 0.015, 0.12, math.sin(a) * 0.015)], 0.008, 0.003, "c8a050", cls=METAL, bone="hand.R", seg=5, per=3)
    b.ball(top + V(0, 0.075, 0), 0.034, gem, cls=CRYSTAL, bone="hand.R", seg=14, rings=10, mat=MAT_GLOW)


def halberd(b, hc2):
    b.tube([hc2 + V(0, -0.9, 0), hc2 + V(0, 0.95, 0)], [0.022, 0.02], "4a3020", cls=WOOD, bone="hand.R", seg=8)
    top2 = hc2 + V(0, 0.95, 0)
    b.lathe(top2 + V(0, 0.02, 0), [(0.026, 0.0), (0.04, 0.05), (0.03, 0.2), (0.0001, 0.38)], "c8ccd8", cls=METAL, bone="hand.R", seg=6, squash=(1.0, 0.3))
    b.tube([top2 + V(0, 0.02, 0), top2 + V(0.0, 0.06, 0.18), top2 + V(0.0, -0.08, 0.3)], [(0.006, 0.03), (0.008, 0.06), (0.004, 0.01)], "c8ccd8", cls=METAL, bone="hand.R", seg=6, up=(1, 0, 0))
    for k in range(8):
        x = (k / 7 - 0.5) * 0.05
        b.tube([top2 + V(x * 0.3, -0.03, 0), top2 + V(x, -0.26 - 0.04 * math.sin(k), -0.03)], [0.007, 0.002], "c02a20" if k % 2 else "ff6040", cls=HAIR, bone="hand.R", seg=4)


def talisman(b, f_hc):
    """A yellow paper talisman pasted to the forehead, brushed with red script."""
    top = f_hc + V(0, 0.115, 0.075)
    pts = [top, top + V(0, -0.06, 0.03), top + V(0.004, -0.13, 0.04), top + V(0.008, -0.2, 0.034)]
    tal = b.ribbon(pts, [0.026, 0.026, 0.025, 0.024], (1, 0, 0), "f0d860", bone="head", col_end="e8c850")
    b.recolor(tal, lambda p: "c02018" if abs(p.x) < 0.008 and int(p.y * 80) % 3 != 0 else ("c02018" if abs(abs(p.x) - 0.018) < 0.003 else None))



# ---------------------------------------------------------------- ornaments and monstrous extras
def court_beads(b, tor, col="8a4a2a", marker="3aa070"):
    """A Qing court necklace (chaozhu): a long loop of beads with larger marker beads every
    quarter and a counterweight tassel down the back."""
    n = 54
    for i in range(n):
        t = i / n
        a = 2 * math.pi * t
        y = 1.5 - 0.32 * (0.5 + 0.5 * math.cos(a)) ** 1.5
        p = tor.point(y, math.pi * 0.9 * math.sin(a), 0.02)
        big = i % (n // 4) == 0
        b.ball(p, 0.014 if big else 0.009, marker if big else col, cls=CRYSTAL if big else WOOD, bone=torso_w(p), seg=8, rings=5)
    back = tor.point(1.36, math.pi, 0.03)
    b.ellipsoid(back, (0.025, 0.04, 0.01), marker, cls=CRYSTAL, bone="chest", seg=8, rings=5)
    b.ribbon([back, back + V(0, -0.1, -0.01), back + V(0, -0.18, -0.02)], [0.012, 0.012, 0.004], (1, 0, 0), "c8a040", bone="chest")


def rank_badge(b, tor, col="2a2a4a", bird="f0c050"):
    """A mandarin square on the chest: a dark embroidered panel with a gold border and a bird."""
    c = tor.point(1.28, 0.0, 0.025)
    n = tor.normal(1.28, 0.0)
    b.superquad(c, (0.085, 0.085, 0.006), col, e=0.15, cls=CLOTH, bone={"chest": 0.6, "spine": 0.4}, rot=(math.atan2(-n.y, n.z), 0, 0), seg=12, rings=6)
    for i in range(4):
        a0 = i * math.pi / 2 + math.pi / 4
        p0 = c + V(math.cos(a0) * 0.11, math.sin(a0) * 0.11, 0.008)
        p1 = c + V(math.cos(a0 + math.pi / 2) * 0.11, math.sin(a0 + math.pi / 2) * 0.11, 0.008)
        b.tube([p0, p1], [0.005, 0.005], "e0b040", cls=METAL, bone="chest", seg=4)
    b.ellipsoid(c + V(0, 0.01, 0.01), (0.03, 0.02, 0.004), bird, cls=METAL, bone="chest", seg=8, rings=4)
    b.leaf(c + V(-0.02, 0.0, 0.012), c + V(-0.06, -0.05, 0.012), 0.012, bird, side=(0, 0, 1), cls=METAL, bone="chest")
    b.leaf(c + V(0.02, 0.02, 0.012), c + V(0.05, 0.05, 0.012), 0.01, bird, side=(0, 0, 1), cls=METAL, bone="chest")


def claw_nails(b, s, col="1a1418", length=0.05):
    """Long hooked nails on every finger (demons, corpses)."""
    sd = "L" if s > 0 else "R"
    wr = V(WRI.x * s, WRI.y, WRI.z) + V(0.004 * s, -0.018, 0.004)
    knuck = wr + V(0.002 * s, -0.085, 0.006)
    for z, ln in ((0.025, 0.074), (0.0085, 0.082), (-0.008, 0.077), (-0.023, 0.062)):
        tip = knuck + V(-0.02 * s, -ln * 0.95, z * 1.05 + 0.006)
        b.tube([tip, tip + V(-0.006 * s, -length * 0.6, 0.004), tip + V(-0.02 * s, -length, 0.0)], [0.006, 0.004, 0.0008], col, cls=STONE, bone="hand." + sd, seg=5)


def bracers(b, s, col, studs="c8a040"):
    """Leather bracers laced over the forearm under the sleeve."""
    sd = "L" if s > 0 else "R"
    el = V(ELB.x * s, ELB.y, ELB.z)
    wr = V(WRI.x * s, WRI.y, WRI.z)
    pts = [el.lerp(wr, 0.55), el.lerp(wr, 0.8), wr + V(0, -0.005, 0)]
    b.tube(pts, [0.046, 0.044, 0.042], col, cls=CLOTH, bone="forearm." + sd, seg=12)
    for k in range(4):
        q = pts[0].lerp(pts[2], 0.15 + 0.23 * k)
        b.ball(q + V(0.04 * s, 0, 0.018), 0.007, studs, cls=METAL, bone="forearm." + sd, seg=6, rings=4)


def demon_tail(b, col, tip_col="ff4020"):
    """A long whip tail from under the robe at the back, ending in a barbed spade."""
    pts = [V(0, 0.95, -0.14), V(0, 0.75, -0.3), V(0.08, 0.5, -0.45), V(0.18, 0.32, -0.42), V(0.22, 0.22, -0.28)]
    bones = [{"hips": 1.0}, {"hips": 0.5, "robe_b": 0.5}, {"robe_b": 1.0}, {"robe_b": 1.0}, {"robe_b": 1.0}]
    strand(b, pts, 0.04, 0.012, col, cls=SKIN, bones=bones, seg=8, per=4)
    tip = pts[-1]
    b.lathe(tip + V(0.02, 0.02, 0.06), [(0.0001, -0.05), (0.05, -0.01), (0.03, 0.04), (0.0001, 0.07)], tip_col, cls=STONE, bone="robe_b", seg=6, squash=(1.0, 0.3), rot=(math.pi / 2, 0, 0))
