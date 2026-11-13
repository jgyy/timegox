"""Exoskeletons for the monster scripts: the jointed legs, claws, spines and shields of crabs,
spiders, scorpions, mantises and other many-legged things.

An arthropod limb is not a string of beads.  Each segment (podomere) is a stiff tube of cuticle
that runs nearly straight from joint to joint; its near end narrows to a condyle that sits inside
the cup of the segment before it, and its far end flares a little into a rim, so a leg reads as a
row of telescoping tubes of different lengths and thicknesses with a pinch of dark membrane at
each joint (references: arthropod leg anatomy - coxa, trochanter, femur, patella, tibia,
metatarsus, tarsus in spiders; coxa, basis, ischium, merus, carpus, propodus, dactylus in crabs,
the merus the largest; the chela is the dactylus closing against an outgrowth of the propodus).
Segments are seldom round: crab legs are flat plates on edge, a scorpion's tail segments are boxes
with keels (carinae) along their corners, a mantis's femur is a blade with rows of spines.

The parts here are lofted (sculpt.loft) through rings whose cross-section is an ellipse with
optional keels and a flattened underside, so the cel shading draws clean planes and the ink line a
clean silhouette.  Everything is greyscale with tint weight 1 (the game recolours it); values follow
the creature rule of a darker back and a paler belly, with the joints dark.

``CHITIN`` is the surface class used for these shells: the actor shader overlays a world-aligned
grid on the scale class (0.3), which on a large smooth shell reads as a tablecloth, so cuticle is
given a class of its own that the shader leaves plain (and still outlines).

Everything is in Godot space, like the rest of the kit.
"""

import math

from mathutils import Matrix

from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, V, mix, rgb
from sculpt import TAU, bump, catmull, fbm3, loft, morph_sphere, section, smooth

CHITIN = 0.1


def grey(v):
    return (v, v, v)


# ---------------------------------------------------------------- cross-sections
def profile(w, h, keels=(), flat=0.0, flat_top=0.0, square=0.0):
    """Cross-section angle -> radius: an ellipse `w` across and `h` deep (angle 0 is the back),
    `keels` = [(angle, height), ...] ridges running along the segment, `flat` flattens the
    underside, `flat_top` the back, `square` pushes the ellipse towards a rounded box (the tail
    segments of a scorpion)."""

    def f(a):
        c, s = math.cos(a), math.sin(a)
        if square > 0.0:
            # superellipse: |c/h|^m + |s/w|^m = r^-m
            m = 2.0 + 3.0 * square
            r = (abs(c / h) ** m + abs(s / w) ** m) ** (-1.0 / m)
        else:
            r = 1.0 / math.sqrt((c / h) ** 2 + (s / w) ** 2)
        for ang, k in keels:
            r *= 1.0 + k * max(0.0, math.cos(a - ang)) ** 14
        if flat > 0.0 and c < 0.0:
            r *= 1.0 - flat * (-c) ** 3
        if flat_top > 0.0 and c > 0.0:
            r *= 1.0 - flat_top * c ** 4
        return r

    return f


def _frame(d, up):
    d = V(d).normalized()
    u = V(up)
    u = u - d * u.dot(d)
    if u.length < 1e-5:
        u = V(0, 1, 0) - d * d.y if abs(d.y) < 0.95 else V(0, 0, 1) - d * d.z
    return d, u.normalized()


# ---------------------------------------------------------------- one podomere
def segment(b, a, c, w, h=None, bone=None, up=(0.0, 1.0, 0.0), n=14, rings=9, neck=0.28, neck_len=0.14, swell=0.08, swell_at=0.45,
            taper=0.15, rim=0.06, keels=(), flat=0.0, flat_top=0.0, square=0.0, col=0.8, back=0.1, belly=0.12, joint=0.4, tint=1.0,
            cls=CHITIN, mat=0, bend=None, cap0=0.35, cap1=0.25, col_fn=None, w1=None, h1=None):
    """One segment of exoskeleton from joint `a` to joint `c`, `w` across and `h` deep at its widest
    (`w1`/`h1` at the far end if it changes shape), its back towards `up`.  The near end narrows to
    a condyle (`neck`, over `neck_len` of the length), the body swells a little at `swell_at` and
    tapers (`taper`) to a slightly flared rim at the far end.  `bend` = a vector bows the segment's
    middle sideways (a curved femur, a finger).  Coloured `col` with a paler back (`back`), a paler
    belly (`belly`: arthropods are pale underneath) and dark joints (`joint`).  Returns the verts."""
    a, c = V(a), V(c)
    h = w if h is None else h
    w1 = w if w1 is None else w1
    h1 = h if h1 is None else h1
    L = (c - a).length
    if L < 1e-6:
        return []
    d0, u0 = _frame(c - a, up)
    centres = []
    for j in range(rings + 1):
        t = j / rings
        p = a.lerp(c, t)
        if bend is not None:
            p = p + V(bend) * math.sin(math.pi * t)
        centres.append(p)
    rings_pts = []
    params = []
    for j, p in enumerate(centres):
        t = j / rings
        tan = (centres[min(rings, j + 1)] - centres[max(0, j - 1)]).normalized()
        k = (1.0 - neck * (1.0 - smooth(0.0, neck_len, t))) * (1.0 + swell * bump(t, swell_at, 0.55)) * (1.0 - taper * t)
        k *= 1.0 + rim * smooth(0.8, 0.97, t)
        ww = (w + (w1 - w) * t) * k
        hh = (h + (h1 - h) * t) * k
        rings_pts.append(section(p, tan, profile(ww, hh, keels, flat, flat_top, square), n, up=u0))
        params.append(t)

    def colf(p, j, i):
        t = params[j]
        ang = TAU * i / n
        cy = math.cos(ang)
        if col_fn is not None:
            return col_fn(t, ang)
        v = col * (1.0 + back * smooth(0.2, 0.95, cy)) * (1.0 - 0.1 * smooth(-0.1, -0.7, cy))
        v = v + (0.97 - v) * belly * smooth(-0.35, -0.9, cy)
        v *= 1.0 - joint * (1.0 - smooth(0.0, neck_len * 1.1, t))
        v *= 1.0 - joint * 0.45 * smooth(0.9, 1.0, t)
        return grey(min(1.0, v))

    bone_fn = None
    if callable(bone):
        bone_fn = bone
        bone = None
    return loft(b, rings_pts, grey(col), cls=cls, bone=bone, bone_fn=bone_fn, col_fn=colf, tint=tint, mat=mat, cap0=True, cap1=True,
                cap_push=0.3 if cap1 else 0.0)


def dorsal(d, out, world_up=(0.0, 1.0, 0.0)):
    """The back of a leg segment running along `d` in a leg that reaches out along `out` (a
    horizontal direction) and bends in the vertical plane through it: up for a level segment,
    outwards for one that hangs straight down, so the cross-section turns with the leg."""
    d = V(d).normalized()
    o = V(out)
    o = V(o.x, 0.0, o.z).normalized()
    wu = V(world_up)
    n_p = o.cross(wu)
    up = d.cross(n_p)
    if up.length < 1e-6:
        return wu
    up.normalize()
    if up.dot(wu + o * 0.5) < 0.0:
        up = -up
    return up


def limb(b, joints, widths, bones, up=(0.0, 1.0, 0.0), heights=None, overlap=0.35, styles=None, out=None, **kw):
    """A jointed limb through `joints` (n+1 points for n segments) with one width (and height) per
    segment, one bone per segment (rigid: an exoskeleton bends only at its joints), and optional
    per-segment keyword overrides in `styles`.  Each segment starts a little inside the rim of the
    one before (`overlap` x its width), so the condyle sits in the cup.  With `out` (the leg's
    outward direction) each segment's back follows the leg round its bends (`dorsal`)."""
    res = []
    n = len(joints) - 1
    for i in range(n):
        a, c = V(joints[i]), V(joints[i + 1])
        w = widths[i]
        h = heights[i] if heights is not None else w
        if i > 0:
            a = a - (c - a).normalized() * (overlap * w)
        st = dict(kw)
        if styles is not None and styles[i]:
            st.update(styles[i])
        u = st.pop("up", None)
        if u is None:
            u = dorsal(c - a, out) if out is not None else up
        res.append(segment(b, a, c, w, h, bone=bones[i], up=u, **st))
    return res


# ---------------------------------------------------------------- spines, setae, fingers
def spine(b, base, d, length, width, bone, col0=0.55, col1=0.25, tint=1.0, cls=CHITIN, curve=None, seg=6, mat=0):
    """A stiff spine or seta: a tapered horn from `base` along `d`, optionally curved by `curve`."""
    base = V(base)
    d = V(d).normalized()
    mid = base + d * (length * 0.5)
    if curve is not None:
        mid = mid + V(curve) * length * 0.25
    tip = base + d * length + (V(curve) * length * 0.35 if curve is not None else V(0, 0, 0))
    pts = [base - d * width * 0.6, mid, tip]
    c0 = grey(col0) if isinstance(col0, (int, float)) else rgb(col0)
    c1 = grey(col1) if isinstance(col1, (int, float)) else rgb(col1)
    return b.tube(pts, [width, width * 0.55, 0.0006], c0, cls=cls, bone=bone, seg=seg, cols=[c0, mix(c0, c1, 0.5), c1], tint=tint, mat=mat)


def spine_row(b, a, c, side, count, length, width, bone, t0=0.15, t1=0.85, rake=0.6, grow=0.0, alt=0.0, **kw):
    """A row of spines along the segment a->c on the side `side` (a vector), raked towards c."""
    a, c = V(a), V(c)
    d = (c - a).normalized()
    sv = V(side)
    sv = (sv - d * sv.dot(d)).normalized()
    out = []
    for k in range(count):
        t = t0 + (t1 - t0) * (k / max(1, count - 1))
        ln = length * (1.0 + grow * (t - 0.5)) * (1.0 - alt * (k % 2))
        p = a.lerp(c, t)
        out += spine(b, p, (sv + d * rake).normalized(), ln, width, bone, **kw)
    return out


def finger(b, pts, w, h, bone, up=(0.0, 1.0, 0.0), col0=0.8, col1=0.12, tint=1.0, tint_tip=0.0, tip_from=0.55, cls=CHITIN, n=12, per=4,
           teeth=0, teeth_side=None, teeth_len=0.02, teeth_col="f0e8d8", mat=0, power=1.0):
    """A tapering, curved claw finger (a crab's dactyl or pollex, a scorpion's chela finger, a
    talon) lofted through control points `pts`: `w` across and `h` deep at the root, pointed at the
    tip, darkening from `col0` to `col1` (and from tinted to untinted) beyond `tip_from`.  `teeth`
    blunt denticles line the cutting edge on `teeth_side`."""
    cp = catmull([V(p) for p in pts], per)
    m = len(cp)
    rings = []
    ts = []
    upv = V(up)
    for j, p in enumerate(cp):
        t = j / (m - 1)
        tan = (cp[min(m - 1, j + 1)] - cp[max(0, j - 1)]).normalized()
        k = (1.0 - t ** power * 0.97)
        rings.append(section(p, tan, profile(max(0.0008, w * k), max(0.0008, h * k)), n, up=upv))
        ts.append(t)
    c0 = grey(col0) if isinstance(col0, (int, float)) else rgb(col0)
    c1 = grey(col1) if isinstance(col1, (int, float)) else rgb(col1)

    def colf(p, j, i):
        t = ts[j]
        cy = math.cos(TAU * i / n)
        cc = mix(c0, c1, smooth(tip_from, 1.0, t))
        return tuple(min(1.0, x * (1.0 + 0.08 * cy)) for x in cc)

    out = loft(b, rings, c0, cls=cls, bone=bone, col_fn=colf, tint=tint, mat=mat, cap0=True, cap1=True, cap_push=0.2)
    # the tip loses its tint (claw tips keep their own dark colour): the rings come first in the
    # loft's vertex order, then the root cap (2n + 1 verts), then the tip cap
    if tint_tip != tint:
        for idx, v in enumerate(out):
            if idx < m * n:
                t = ts[idx // n]
            elif idx < m * n + 2 * n + 1:
                t = 0.0
            else:
                t = 1.0
            v[b.tl] = tint + (tint_tip - tint) * smooth(tip_from, 1.0, t)
    if teeth and teeth_side is not None:
        tsd = V(teeth_side).normalized()
        for k in range(teeth):
            t = 0.12 + 0.62 * k / max(1, teeth - 1)
            j = int(t * (m - 1))
            p = cp[j]
            tan = (cp[min(m - 1, j + 1)] - cp[max(0, j - 1)]).normalized()
            sv = (tsd - tan * tsd.dot(tan)).normalized()
            kk = (1.0 - t * 0.97)
            ln = teeth_len * (1.25 if k % 3 == 1 else 0.85) * (1.0 - 0.3 * t)
            base = p + sv * (h * kk * 0.7)
            b.tube([base - sv * ln * 0.3, base + sv * ln * 0.55 + tan * ln * 0.1, base + sv * ln + tan * ln * 0.2], [ln * 0.45, ln * 0.3, 0.0006],
                   teeth_col, cls=0.9, bone=bone, seg=6, mat=MAT_PLAIN)
    return out


# ---------------------------------------------------------------- shields
def closed_catmull(pts, per=6):
    """Catmull-Rom resample of a closed loop of points (the first point is not repeated)."""
    n = len(pts)
    out = []
    for i in range(n):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        for k in range(per):
            t = k / per
            t2 = t * t
            t3 = t2 * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    return out


def outline_radius(pts, samples=720):
    """Polar radius table of a closed top-view outline given as (x, z) points round the centre
    (any order round the circle): returns r(theta), theta = atan2(x, z) (0 = forward, +pi/2 = +x)."""
    cp = closed_catmull([V(x, 0.0, z) for x, z in pts], 8)
    angs = []
    for p in cp:
        angs.append((math.atan2(p.x, p.z), math.hypot(p.x, p.z)))
    angs.sort()
    table = []
    for k in range(samples):
        th = -math.pi + TAU * k / samples
        # nearest neighbours in angle (the outline is star-shaped round the centre)
        lo = None
        hi = None
        for a, r in angs:
            if a <= th:
                lo = (a, r)
            if a >= th and hi is None:
                hi = (a, r)
        if lo is None:
            lo = (angs[-1][0] - TAU, angs[-1][1])
        if hi is None:
            hi = (angs[0][0] + TAU, angs[0][1])
        f = 0.0 if hi[0] - lo[0] < 1e-9 else (th - lo[0]) / (hi[0] - lo[0])
        table.append(lo[1] + (hi[1] - lo[1]) * f)

    def r(theta):
        x = (theta + math.pi) / TAU * samples
        i = int(math.floor(x)) % samples
        f = x - math.floor(x)
        return table[i] + (table[(i + 1) % samples] - table[i]) * f

    return r


def shield(b, c, radius, top, under, bone, col_fn, dome=2.4, rim_lift=0.0, offset=None, seg=96, rings=40, tint=1.0, cls=CHITIN, mat=0):
    """A carapace from a top-view outline: `radius(theta)` the outline's polar radius, `top` the
    height of the dome over the rim and `under` the depth below it, `dome` the squareness of the
    vertical section (2 = an ellipse, more gives a flatter top and a steeper edge), `rim_lift`
    raises the rim's edge into a lip.  `offset(theta, phi, p)` may push a point along the surface
    normal (grooves and swellings), `col_fn(theta, phi, p)` paints it (phi from -pi/2 under to +pi/2
    on top).  Returns the verts."""
    c = V(c)

    def shape(d):
        th = math.atan2(d.x, d.z)
        ph = math.asin(max(-1.0, min(1.0, d.y)))
        R = radius(th)
        cphi = max(0.0, math.cos(ph))
        sphi = math.sin(ph)
        e = 2.0 / dome
        if sphi >= 0.0:
            hr = R * (cphi ** e)
            y = top * (sphi ** e)
            lift = rim_lift(th) if callable(rim_lift) else rim_lift
            y += lift * top * math.exp(-((ph - 0.12) / 0.08) ** 2)
        else:
            hr = R * (cphi ** 0.7)
            y = -under * ((-sphi) ** 1.4)
        p = V(math.sin(th) * hr, y, math.cos(th) * hr)
        if offset is not None:
            nn = V(math.sin(th) * cphi / max(R, 1e-3), sphi / max(top if sphi >= 0 else under, 1e-3), math.cos(th) * cphi / max(R, 1e-3))
            if nn.length > 1e-6:
                p = p + nn.normalized() * offset(th, ph, p)
        return p

    def colf(lp, d):
        th = math.atan2(d.x, d.z)
        ph = math.asin(max(-1.0, min(1.0, d.y)))
        return col_fn(th, ph, lp)

    return morph_sphere(b, c, shape, colf, cls=cls, bone=bone, seg=seg, rings=rings, tint_fn=lambda lp, d: tint, mat=mat)


# ---------------------------------------------------------------- eyes
def bead_eye(b, c, r, bone, fwd=(0.0, 0.0, 1.0), col="141018", glow=None, accent=True, glint=True):
    """A glossy simple eye (an ocellus, a spider's or crab's eye): a dark dome with a tinted iris
    glow deep in it (the accent colour when `accent`) and a catchlight.  Returns nothing."""
    c = V(c)
    f = V(fwd).normalized()
    b.ellipsoid(c, (r, r, r), col, cls=CRYSTAL, bone=bone, seg=14, rings=10, mat=MAT_PLAIN)
    if glow is not None or accent:
        old = b.cur_pal
        tint = 0.0
        g = glow or "e8e8e8"
        if accent:
            b.cur_pal = 1.0
            tint = 1.0
            g = "e8e8e8"
        b.ellipsoid(c + f * (r * 0.62), (r * 0.55, r * 0.55, r * 0.5), g, cls=CRYSTAL, bone=bone, seg=10, rings=6, mat=MAT_GLOW, tint=tint)
        b.cur_pal = old
        b.ellipsoid(c + f * (r * 0.8), (r * 0.26, r * 0.26, r * 0.24), "080608", cls=CRYSTAL, bone=bone, seg=8, rings=5, mat=MAT_PLAIN)
    if glint:
        side = f.cross(V(0, 1, 0))
        side = side.normalized() if side.length > 1e-4 else V(1, 0, 0)
        b.ellipsoid(c + f * (r * 0.78) + V(0, r * 0.38, 0) + side * (r * 0.25), (r * 0.17, r * 0.15, r * 0.1), "ffffff", cls=CRYSTAL, bone=bone, seg=6,
                    rings=4, mat=MAT_GLOW)


def stalk_eye(b, base, tip, r, bone, out=(1.0, 0.0, 0.0), col=0.82, cornea="1c1620", tint=1.0):
    """A crab's stalked compound eye: a stout stalk from `base` to `tip`, thickening a little under
    the cornea, which caps the end as a dark, glossy, slightly elongated dome turned towards `out`
    (not a ball on a stick), with the accent colour glowing in its pseudopupil and a catchlight."""
    from creature import euler_yxz
    base, tip = V(base), V(tip)
    d = (tip - base).normalized()
    segment(b, base, tip, r * 0.78, r * 0.78, bone=bone, up=out, neck=0.1, swell=0.0, taper=-0.12, rim=0.18, col=col, joint=0.25, n=12, rings=6,
            tint=tint)
    o = V(out)
    o = (o - d * o.dot(d)).normalized()
    look = (d * 0.55 + o).normalized()
    c = tip + d * (r * 0.35) + o * (r * 0.12)
    rot = euler_yxz(rot_to(look, d))
    b.ellipsoid(c, (r * 0.95, r * 1.05, r * 0.9), cornea, cls=CRYSTAL, bone=bone, rot=rot, seg=14, rings=10, mat=MAT_PLAIN)
    old = b.cur_pal
    b.cur_pal = 1.0
    b.ellipsoid(c + look * (r * 0.78), (r * 0.36, r * 0.36, r * 0.18), "e8e8e8", cls=CRYSTAL, bone=bone, rot=rot, seg=10, rings=6, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = old
    b.ellipsoid(c + look * (r * 0.86), (r * 0.16, r * 0.16, r * 0.1), "0a080a", cls=CRYSTAL, bone=bone, rot=rot, seg=8, rings=5, mat=MAT_PLAIN)
    b.ellipsoid(c + look * (r * 0.7) + d * (r * 0.42), (r * 0.15, r * 0.12, r * 0.08), "ffffff", cls=CRYSTAL, bone=bone, rot=rot, seg=6, rings=4, mat=MAT_GLOW)


def rot_to(d, up=(0.0, 1.0, 0.0)):
    """Matrix whose columns are (side, up, d): local +Z along d."""
    d = V(d).normalized()
    u = V(up)
    u = u - d * u.dot(d)
    if u.length < 1e-5:
        u = V(1, 0, 0) - d * d.x
    u.normalize()
    s = u.cross(d).normalized()
    return Matrix((s, u, d)).transposed()


def hair_streaks(p, scale=30.0, seed=5):
    """0..1 streaky noise for painting setae (fine hair) into a coat's greys."""
    return fbm3((p[0] * scale, p[1] * scale * 0.35, p[2] * scale), 2, seed)
