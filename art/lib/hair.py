"""Hair for the characters: a scalp cap cut along a natural hairline, then locks routed over the
skull and hanging under gravity.

Reference points (stylised game characters): hair has *volume* above the skull, the bangs are
separate locks with gaps so the eyes and brows read through them, side locks frame the face, and
long hair falls in a few large clumps made of smaller strands rather than as one sheet.  The old
hair was an ellipsoid helmet with spikes pushed into it.

A lock is described by directions from the head centre (unit vectors, Godot space).  It starts on
the cap, follows the skull towards its target direction, and may then hang (``drop``) with a
little outward flare and a curl at the tip.  Locks are flattened ribbons-with-thickness whose
flat side lies on the head.
"""

import math

from mathutils import Vector

from face import HC, RY, EYE_Y
from kit import CLOTH, CRYSTAL, HAIR, METAL, V, darken, hsv, lighten, mix, rgb, to_hsv
from sculpt import bump, clamp, fbm3, morph_sphere, smooth, strand

LIFT = 0.13   # how far the hair stands off the skull at the crown (fraction of the radius)
CLUMP = 1.32  # stylised hair is a few big clumps, not many thin strands (references: CG Cookie
              # "big, medium and small forms"; BlenderNation "flat-modeling anime hair")


def dvec(x, y, z):
    return Vector((x, y, z)).normalized()


def slerp(a, b, t):
    v = a * (1.0 - t) + b * t
    if v.length < 1e-6:
        v = a
    return v.normalized()


class Scalp:
    def __init__(self, f, hc, style, o):
        self.f = f
        self.hc = rgb(hc)
        self.dk = darken(hc, 0.3)
        self.lt = lighten(hc, 0.16)
        # dark hair catches a coloured sheen (blue-black, plum-black, chestnut) instead of grey
        hh, hs, hv = to_hsv(hc)
        if hv < 0.35:
            self.lt = mix(self.lt, o.get("sheen", hsv(hh, 0.55, 0.45) if hs > 0.15 else (0.25, 0.3, 0.5)), 0.6)
        self.style = style
        self.o = o
        # gathered styles sit closer to the head (combed back tight)
        self.lift = {"topknot": 0.095, "bun": 0.075, "long": 0.125, "wild": 0.16}.get(style, LIFT)

    # ---- the hairline: how far down the hair reaches in each horizontal direction
    def line(self, d):
        h = math.hypot(d.x, d.z)
        fz = d.z / h if h > 1e-6 else 0.0
        if fz >= 0.0:
            t = 0.08 + 0.5 * fz ** 1.6
        else:
            t = 0.08 - 0.72 * (-fz) ** 0.85
        # sideburns dip down in front of the ears
        t -= 0.22 * bump(fz, 0.22, 0.18)
        return t

    def cov(self, d):
        t = self.line(d)
        return smooth(t - 0.04, t + 0.08, d.y)

    def pt(self, d, extra=0.0):
        """A point on the hair surface in direction d (extra lifts it further)."""
        k = self.cov(d)
        p = self.f.shape(d)
        crown = smooth(-0.3, 0.9, d.y)
        thick = (self.lift * (0.45 + 0.55 * crown)) * k - 0.04 * (1.0 - k)
        return HC + p * (1.0 + thick) + p.normalized() * extra

    def colour(self, p, d):
        # strands: noise stretched along the direction hair runs (from the crown down)
        q = (d.x * 14.0, d.y * 3.0, d.z * 14.0)
        n = fbm3(q, 3, 5)
        c = mix(self.dk, self.lt, n)
        # darker roots near the hairline and underneath
        c = mix(c, self.dk, (1.0 - smooth(-0.6, 0.5, d.y)) * 0.35)
        return mix(self.hc, c, 0.75)


def shell_normal(p):
    """The normal anime hair is lit with near the head (the Spring Thunder release): that of a sphere
    round the skull, so the cap and the fringe shade as one smooth helmet of hair and the highlight
    ring runs round it in one clean band (references: the "spherical normals for hair" set-up of
    gacha-style shaders; Kuro Games' Wuthering Waves rendering notes)."""
    d = p - (HC + Vector((0.0, -0.02, -0.012)))
    return d.normalized() if d.length > 1e-6 else Vector((0, 1, 0))


def cap(b, s, bone="head"):
    vs = morph_sphere(b, HC, lambda d: s.pt(d) - HC, s.colour, cls=HAIR, bone=bone, seg=30, rings=22)
    b.set_normals(vs, shell_normal, 0.85)


def lock(b, s, d0, d1, width, col=None, steps=6, drop=0.0, flare=0.0, curl=0.0, extra=0.006, bones=None, bone="head", flat=0.32, tip=None, sway=None):
    """One lock from direction d0 over the head to d1, then hanging `drop` metres."""
    col = col if col is not None else s.hc
    pts = []
    for k in range(steps + 1):
        t = k / steps
        d = slerp(d0, d1, t)
        pts.append(s.pt(d, extra * (0.4 + 0.6 * math.sin(math.pi * min(1.0, t * 1.2)))))
    if drop > 0.0:
        end = pts[-1]
        out = (end - HC)
        out.y = 0.0
        out = out.normalized() if out.length > 1e-6 else Vector((0, 0, -1))
        n = max(3, int(drop / 0.07))
        for k in range(1, n + 1):
            t = k / n
            p = end + Vector((0, -drop * t, 0)) + out * (flare * math.sin(t * math.pi * 0.6) + 0.012 * t)
            if sway is not None:
                p = p + Vector(sway) * t * t
            if curl and t > 0.8:
                p = p + out * (-curl * (t - 0.8) * 5.0) + Vector((0, curl * (t - 0.8) * 2.0, 0))
            pts.append(p)
    if tip is not None:
        pts.append(pts[-1] + Vector(tip))
    bl = None
    if bones is not None:
        bl = [bones(p) for p in pts]
    up = (pts[0] - HC).normalized()
    return strand(b, pts, width * CLUMP, width * 0.1, col, col_tip=lighten(col, 0.12), cls=HAIR, bone=None if bl else bone, bones=bl, flat=flat, seg=6, per=2, up=up, power=1.5)


def back_weight(y_top=1.62, y_bot=1.36):
    """Head near the skull, the hair_tail bone lower down and hair_tail2 below the shoulders, so long
    hair swings and its ends follow a beat later."""

    def fn(p):
        k = clamp((y_top - p.y) / (y_top - y_bot))
        if k <= 0.0:
            return {"head": 1.0}
        k2 = clamp((y_bot - 0.02 - p.y) / 0.22)
        if k2 > 0.0:
            return {"hair_tail": 1.0 - k2, "hair_tail2": k2}
        return {"head": 1.0 - k, "hair_tail": k}

    return fn


# ---------------------------------------------------------------- parts shared by the styles
def bangs(b, s, n=9, length=1.0, part=0.0, swept=0.0, spread=1.0):
    """Forelocks: separate tapered locks over the forehead with gaps between them.  `part` moves
    the parting (-1..1), `swept` sweeps the tips sideways."""
    f = s.f
    for i in range(n):
        u = i / (n - 1) - 0.5                       # -0.5 .. 0.5 across the forehead
        x0 = (u * 0.9 + part * 0.2) * spread
        root = dvec(x0 * 0.55, 0.9, 0.45)
        # the locks fall away from the parting and end just above the brows
        side = math.copysign(1.0, u - part * 0.2) if abs(u - part * 0.2) > 0.04 else 0.0
        tip_x = (u * 1.05 + swept * 0.25 + side * 0.08) * spread * 0.098
        tip_y = EYE_Y + 0.028 + (0.016 + 0.01 * abs(u)) * (1.0 / max(0.4, length)) - (0.01 if i % 3 == 1 else 0.0)
        surf = f.surface(tip_x, tip_y)
        tip = HC + surf + Vector((0, 0, 0.012 + 0.008 * (1.0 - abs(u) * 2)))
        mid_d = dvec(tip_x * 0.8, 0.5, 0.85)
        p0 = s.pt(root, 0.004)
        p1 = s.pt(mid_d, 0.012 + 0.006 * math.cos(u * 3))
        pts = [p0, p0.lerp(p1, 0.55) + Vector((0, 0.008, 0.012)), p1, tip.lerp(p1, 0.35) + Vector((0, 0, 0.006)), tip]
        col = (s.hc, s.dk, s.lt)[i % 3] if i % 4 else s.hc
        w = (0.017 + 0.005 * math.cos(i * 1.7)) * (1.15 if abs(u) < 0.2 else 1.0) * CLUMP
        vs = strand(b, pts, w, 0.0012, col, col_tip=lighten(col, 0.12), cls=HAIR, bone="head", flat=0.32, seg=6, per=3, up=(0, 0.3, 1), power=1.3)
        if vs:
            b.set_normals(vs, shell_normal, 0.7)


def side_locks(b, s, length=0.2, n=2, fwd=0.0, width=0.021):
    """Locks framing the face from the temples, in front of the ears."""
    for sd in (1, -1):
        for k in range(n):
            root = dvec(0.62 * sd, 0.55 - k * 0.12, 0.55 - k * 0.15)
            over = dvec(0.95 * sd, 0.1 - k * 0.05, 0.42 - k * 0.12)
            p0 = s.pt(root, 0.004)
            p1 = s.pt(over, 0.012)
            ln = length * (1.0 - 0.25 * k)
            pts = [p0, p1, p1 + Vector((0.004 * sd, -ln * 0.4, 0.012 + fwd * 0.3)), p1 + Vector((-0.004 * sd, -ln * 0.8, 0.02 + fwd)), p1 + Vector((-0.012 * sd, -ln, 0.016 + fwd))]
            bones = [{"head": 1.0}] * 3 + [{"head": 0.7, "neck": 0.3}, {"head": 0.55, "neck": 0.45}]
            col = s.hc if k == 0 else s.dk
            strand(b, pts, width * (1.0 - 0.15 * k), 0.0015, col, col_tip=lighten(col, 0.1), cls=HAIR, bones=bones, flat=0.35, seg=6, per=3, up=(sd, 0, 0.3), power=1.3)


def crown_whorl(b, s, n=16, toward=None, length=1.0, rows=2, skip_front=0.0):
    """Top and side locks radiating from the crown (or towards a gathering point).  Locks
    within `skip_front` (cosine) of straight ahead are left to the bangs."""
    for r in range(rows):
        for i in range(n):
            a = (i + 0.5 * r) / n * 2 * math.pi
            if skip_front > 0.0 and math.cos(a) > 1.0 - skip_front:
                continue
            d0 = dvec(math.sin(a) * (0.18 + 0.12 * r), 1.0, math.cos(a) * (0.18 + 0.12 * r) - 0.08)
            ylow = s.line(dvec(math.sin(a), 0.0, math.cos(a))) + 0.12 + 0.06 * r
            d1 = dvec(math.sin(a), ylow, math.cos(a))
            if toward is not None:
                d0, d1 = d1, toward
            col = (s.hc, s.dk, s.lt)[(i + r) % 3]
            lock(b, s, d0, d1, (0.026 - 0.004 * r) * length, col, steps=6, extra=0.004 + 0.004 * r)


def curtain(b, s, length, span=1.75, n=25, rows=10, flare=0.045, clumps=8, y0=0.18, bone_fn=None, col_tip=None):
    """The mass of long hair falling down the back: one continuous sheet from round the back of the
    head, falling under gravity over the nape and shoulders, its ends cut into pointed clumps.  Big
    forms first, then the separate locks laid on top for detail (references: CG Cookie hair
    modelling, "big, medium and small forms"; 80.lv "hairstyle modelling for an anime-like
    character").  It replaces the old look of long hair as a row of separate dreadlocks."""
    bw = bone_fn or back_weight()
    tip_c = col_tip or s.lt
    grid = []
    lens = []
    for i in range(n):
        u = i / (n - 1)
        # pointed clumps along the bottom edge, the middle of the back longest
        k = (u * clumps) % 1.0
        tooth = 1.0 - abs(k - 0.5) * 2.0
        lens.append(length * (0.8 + 0.2 * tooth ** 1.5) * (1.0 - 0.28 * abs(u - 0.5) ** 1.6 * 4.0 * 0.5))
    for j in range(rows):
        t = j / (rows - 1)
        row = []
        for i in range(n):
            u = i / (n - 1)
            az = math.pi + (u - 0.5) * 2.0 * span
            d = dvec(math.sin(az), y0, math.cos(az))
            top = s.pt(d, 0.004)
            out = V(math.sin(az), 0.0, math.cos(az))
            p = top + V(0.0, -lens[i] * t, 0.0) + out * (flare * math.sin(min(1.0, t * 1.4) * math.pi * 0.5) + 0.02 * t)
            # rest on the back and shoulders instead of passing through them
            if p.y < 1.56:
                back_z = -0.135 - 0.01 * smooth(1.5, 1.2, p.y)
                if p.z > back_z and math.cos(az) < 0.0:
                    p = V(p.x, p.y, back_z + (p.z - back_z) * 0.15)
                sx = 0.11 + 0.06 * smooth(1.56, 1.45, p.y)
                if abs(p.x) < sx and abs(math.sin(az)) > 0.6:
                    p = V(math.copysign(sx, p.x), p.y, p.z)
            row.append(p)
        grid.append(row)
    cols = []
    for j in range(rows):
        t = j / (rows - 1)
        rc = []
        for i in range(n):
            base = mix(s.dk, s.hc, smooth(0.0, 0.25, t))
            base = mix(base, tip_c, smooth(0.55, 1.0, t) * 0.55)
            # each clump a little lighter down its middle, darker at its parting
            k = (i / (n - 1) * 8) % 1.0
            base = lighten(base, 0.06 * (1.0 - abs(k - 0.5) * 2.0)) if (i // 3) % 2 else darken(base, 0.05)
            rc.append(base)
        cols.append(rc)
    bones = [bw(sum(row, Vector()) / len(row)) for row in grid]
    b.sheet(grid, s.hc, cls=HAIR, bones=bones, cols=cols, thickness=0.016)


# ---------------------------------------------------------------- styles
def style_topknot(b, s, o):
    """Hair combed up into a knot on the crown, held by a small metal crown (guan) and a pin, with
    a high tail hanging from it, parted forelocks and long face-framing locks."""
    knot = V(0, HC.y + RY + 0.045, -0.03)
    tdir = (knot - HC).normalized()
    crown_whorl(b, s, n=18, toward=tdir, rows=2)
    # back of the head: locks swept up from the nape
    for i in range(10):
        a = math.pi * 0.62 + i / 9 * math.pi * 0.76
        d0 = dvec(math.sin(a) * 0.9, -0.35, math.cos(a))
        lock(b, s, d0, tdir, 0.024, (s.hc, s.dk)[i % 2], steps=7, extra=0.004)
    b.ellipsoid(knot, (0.042, 0.034, 0.045), s.hc, cls=HAIR, bone="head", seg=16, rings=10)
    for k in range(5):
        a = k / 5 * 2 * math.pi
        strand(b, [knot + V(math.sin(a) * 0.04, -0.02, math.cos(a) * 0.04), knot + V(math.sin(a + 1) * 0.03, 0.03, math.cos(a + 1) * 0.03), knot + V(math.sin(a + 2) * 0.012, 0.035, math.cos(a + 2) * 0.012)], 0.013, 0.004, s.dk, cls=HAIR, bone="head", flat=0.4, seg=6, per=3)
    metal = o.get("guan", "e8c050")
    b.lathe(knot + V(0, -0.012, 0), [(0.03, 0.0), (0.034, 0.012), (0.036, 0.03), (0.026, 0.05), (0.008, 0.058)], metal, cls=METAL, bone="head", seg=16, squash=(1.0, 1.15), folds=(8, 0.08, 0.0))
    b.tube([knot + V(-0.085, 0.022, 0.005), knot + V(0.085, 0.03, 0.005)], [0.0045, 0.0035], o.get("pin", "c8a050"), cls=METAL, bone="head", seg=6)
    b.ball(knot + V(-0.088, 0.022, 0.005), 0.009, o.get("jade", "6af0b0"), cls=CRYSTAL, bone="head", seg=8, rings=6)
    # the high tail: one full tail falling from the knot, with a few loose locks round it
    tw = back_weight(knot.y - 0.02, knot.y - 0.3)
    core = [knot + V(0, -0.005, -0.035), knot + V(0, -0.07, -0.1), knot + V(0, -0.21, -0.14), knot + V(0, -0.37, -0.14), knot + V(0.0, -0.53, -0.12)]
    strand(b, core, 0.036, 0.004, s.hc, col_tip=s.lt, cls=HAIR, bones=[tw(p) for p in core], flat=0.7, seg=10, per=3, power=0.9)
    for k in range(6):
        a = k / 6 * 2 * math.pi
        off = V(math.sin(a) * 0.022, 0, math.cos(a) * 0.014)
        pts = [q + off * (0.4 + 0.6 * i / 4) for i, q in enumerate(core)]
        pts[-1] = pts[-1] + V(math.sin(a) * 0.012, 0.03 * (k % 2), 0)
        strand(b, pts, 0.017, 0.0015, (s.hc, s.dk, s.lt)[k % 3], col_tip=s.lt, cls=HAIR, bones=[tw(p) for p in pts], flat=0.55, seg=6, per=3, power=1.2)
    bangs(b, s, n=7, part=0.0, length=0.8, spread=0.85)
    side_locks(b, s, length=0.17, n=2, width=0.027)


def style_long(b, s, o):
    """Long flowing hair, half up: crown locks back into a small bun, the rest falling to the
    waist in clumps, forelocks and long side locks over the shoulders."""
    crown_whorl(b, s, n=18, rows=2, skip_front=0.6)
    bw = back_weight()
    curtain(b, s, o.get("hair_len", 0.58) * 1.02 + 0.06, bone_fn=bw)
    n = 11
    for i in range(n):
        u = i / (n - 1)
        a = math.pi * 0.55 + u * math.pi * 0.9
        d0 = dvec(math.sin(a) * 0.5, 0.75, math.cos(a) * 0.6)
        d1 = dvec(math.sin(a), -0.15, math.cos(a))
        drop = o.get("hair_len", 0.58) * (0.82 + 0.18 * math.sin(i * 2.3)) * (1.0 - 0.35 * abs(u - 0.5))
        col = (s.hc, s.dk, s.lt)[i % 3]
        lock(b, s, d0, d1, 0.03, col, steps=5, drop=drop, flare=0.035, curl=0.01, bones=bw, extra=0.006, flat=0.35, sway=(math.sin(a) * 0.04, 0, -0.02))
    bun = V(0, HC.y + 0.06, -0.12)
    b.ellipsoid(bun, (0.036, 0.03, 0.026), s.dk, cls=HAIR, bone="head", seg=12, rings=8)
    b.tube([bun + V(-0.07, 0.03, 0.0), bun + V(0.08, -0.02, -0.01)], [0.0035, 0.003], o.get("pin", "6af0b0"), cls=CRYSTAL, bone="head", seg=6)
    b.ball(bun + V(0.082, -0.022, -0.01), 0.008, o.get("pin", "6af0b0"), cls=CRYSTAL, bone="head", seg=8, rings=6)
    bangs(b, s, n=9, part=-0.25, swept=0.3, length=0.9)
    side_locks(b, s, length=0.32, n=2, fwd=0.03, width=0.018)


def style_bun(b, s, o):
    """Combed back tight into a low coiled bun with a hairpin (elders, women of the village)."""
    bun = V(0, HC.y + 0.035, -0.135)
    tdir = (bun - HC).normalized()
    for i in range(22):
        a = i / 22 * 2 * math.pi
        if math.cos(a) < -0.85:
            continue
        d0 = dvec(math.sin(a), s.line(dvec(math.sin(a), 0, math.cos(a))) + 0.1, math.cos(a))
        lock(b, s, d0, tdir, 0.024, (s.hc, s.dk, s.lt)[i % 3], steps=7, extra=0.003)
    # the coil: a spiral of strands
    pts = []
    for k in range(40):
        t = k / 39
        a = t * 4.5 * math.pi
        r = 0.05 * (1.0 - 0.6 * t)
        pts.append(bun + V(math.cos(a) * r, math.sin(a) * r * 0.85, -0.012 - 0.03 * t))
    strand(b, pts, 0.017, 0.006, s.hc, col_tip=s.lt, cls=HAIR, bone="head", flat=0.7, seg=7, per=1)
    b.ellipsoid(bun + V(0, 0, 0.005), (0.048, 0.042, 0.03), s.dk, cls=HAIR, bone="head", seg=14, rings=8)
    pin = o.get("pin", "6af0b0")
    b.tube([bun + V(-0.09, 0.03, -0.02), bun + V(0.09, -0.02, -0.03)], [0.004, 0.003], pin, cls=CRYSTAL, bone="head", seg=6)
    b.ball(bun + V(-0.094, 0.032, -0.02), 0.01, pin, cls=CRYSTAL, bone="head", seg=8, rings=6)
    # a few loose wisps at the temples soften the line
    for sd in (1, -1):
        root = s.pt(dvec(0.8 * sd, 0.35, 0.45), 0.002)
        strand(b, [root, root + V(0.006 * sd, -0.05, 0.015), root + V(0.0, -0.1, 0.02)], 0.008, 0.001, s.hc, cls=HAIR, bone="head", flat=0.4, seg=5, per=3)
    if not o.get("no_bangs", False):
        bangs(b, s, n=5, part=0.0, length=0.55, spread=0.7)


def style_wild(b, s, o):
    """Untamed, chunky locks standing out and back (smiths, nomads, beasts of men)."""
    crown_whorl(b, s, n=14, rows=1, skip_front=0.5)
    for i in range(16):
        a = math.pi * 0.35 + i / 15 * math.pi * 1.3
        d0 = dvec(math.sin(a) * 0.4, 0.8, math.cos(a) * 0.4)
        p0 = s.pt(d0, 0.01)
        out = V(math.sin(a), 0.0, math.cos(a))
        ln = 0.1 + 0.05 * math.sin(i * 1.9)
        tip = p0 + out * ln + V(0, -0.02 - 0.06 * (1 - abs(math.cos(a))), -0.04)
        strand(b, [p0, p0.lerp(tip, 0.5) + V(0, 0.03, 0), tip], 0.03, 0.002, (s.hc, s.dk, s.lt)[i % 3], col_tip=s.lt, cls=HAIR, bone="head", flat=0.4, seg=6, per=3)
    bangs(b, s, n=7, part=0.3, swept=-0.5, length=0.75)
    side_locks(b, s, length=0.12, n=1, width=0.02)


def style_bald(b, s, o):
    """A shaved crown; elders keep a white fringe around the back and sides."""
    if o.get("beard", False) or o.get("age", 0.0) > 0.4:
        fr = rgb(o.get("beard_col", o.get("hair", "e8e8f0")))
        for row in range(2):
            for i in range(19):
                a = math.pi * 0.34 + (i + 0.5 * row) / 18 * math.pi * 1.32
                d = dvec(math.sin(a), 0.12 - row * 0.16, math.cos(a))
                root = HC + s.f.shape(d) * 1.015
                out = V(math.sin(a), 0, math.cos(a))
                below = HC + s.f.shape(dvec(math.sin(a), -0.25 - row * 0.2, math.cos(a) * 1.1)) * 1.04
                strand(b, [root, root.lerp(below, 0.5) + out * 0.008, below + out * 0.004], 0.014, 0.002, fr if (i + row) % 2 else darken(fr, 0.12), col_tip=lighten(fr, 0.1), cls=HAIR, bone="head", flat=0.4, seg=6, per=3, up=out)


def style_twin_buns(b, s, o):
    """A maid's double buns: the hair parted in the middle and combed up into two coiled buns on
    the crown, each wrapped with a ribbon and pierced by a pin, short tails hanging below them."""
    for sd in (1, -1):
        bun = V(0.075 * sd, HC.y + 0.12, -0.03)
        tdir = (bun - HC).normalized()
        for i in range(11):
            a = (i / 10) * math.pi * 0.9 * sd + (math.pi * 0.05 * sd)
            d0 = dvec(math.sin(a), s.line(dvec(math.sin(a), 0, math.cos(a))) + 0.1, math.cos(a))
            lock(b, s, d0, tdir, 0.022, (s.hc, s.dk, s.lt)[i % 3], steps=7, extra=0.003)
        pts = []
        for k in range(30):
            t = k / 29
            a = t * 4.0 * math.pi * sd
            r = 0.04 * (1.0 - 0.55 * t)
            pts.append(bun + V(math.cos(a) * r, 0.01 + 0.03 * t, math.sin(a) * r))
        strand(b, pts, 0.016, 0.006, s.hc, col_tip=s.lt, cls=HAIR, bone="head", flat=0.7, seg=6, per=1)
        b.ellipsoid(bun, (0.042, 0.032, 0.042), s.dk, cls=HAIR, bone="head", seg=12, rings=8)
        rc = o.get("ribbon", o.get("pin", "e04060"))
        ring = [bun + V(math.cos(t) * 0.044, -0.018, math.sin(t) * 0.044) for t in [i / 14 * 2 * math.pi for i in range(15)]]
        b.tube(ring, [0.006] * 15, rc, cls=CLOTH, bone="head", seg=4, cap0=False, cap1=False)
        b.tube([bun + V(-0.06 * sd, 0.03, 0.0), bun + V(0.06 * sd, -0.01, 0.0)], [0.003, 0.003], o.get("pin", "6af0b0"), cls=CRYSTAL, bone="head", seg=5)
        tw = back_weight(HC.y + 0.08, HC.y - 0.2)
        for k in range(3):
            root = bun + V(0.02 * (k - 1), -0.03, -0.02)
            pts2 = [root, root + V(0.01 * sd, -0.1, -0.02), root + V(0.02 * sd, -0.2, -0.01)]
            strand(b, pts2, 0.012, 0.002, s.hc, cls=HAIR, bones=[tw(q) for q in pts2], flat=0.5, seg=5, per=3)
    bangs(b, s, n=7, part=0.0, length=0.7, spread=0.8)
    side_locks(b, s, length=0.18, n=1, width=0.014)


def style_braid(b, s, o):
    """Hair drawn back into one long three-strand braid down the back, tied with a cord."""
    crown_whorl(b, s, n=16, rows=2, skip_front=0.5)
    nape = V(0, HC.y - 0.07, -0.11)
    tdir = (nape - HC).normalized()
    for i in range(9):
        a = math.pi * 0.6 + i / 8 * math.pi * 0.8
        lock(b, s, dvec(math.sin(a), 0.4, math.cos(a)), tdir, 0.024, (s.hc, s.dk)[i % 2], steps=6, extra=0.003)
    n = 16
    bw = back_weight(HC.y - 0.05, HC.y - 0.35)
    length = o.get("hair_len", 0.55)
    for k in range(3):
        pts = []
        for j in range(n):
            t = j / (n - 1)
            a = t * 9.0 * math.pi + k * 2.0 * math.pi / 3
            pts.append(nape + V(math.sin(a) * 0.016 * (1 - 0.4 * t), -length * t, -0.02 - 0.02 * t + math.cos(a) * 0.01))
        strand(b, pts, 0.02 * (1.0 - 0.1 * k), 0.008, (s.hc, s.dk, s.lt)[k], cls=HAIR, bones=[bw(q) for q in pts], flat=0.8, seg=6, per=1)
    end = nape + V(0, -length, -0.04)
    b.tube([end + V(0, 0.012, 0), end - V(0, 0.012, 0)], [0.02, 0.02], o.get("pin", "c02020"), cls=CLOTH, bone="hair_tail", seg=6)
    strand(b, [end - V(0, 0.012, 0), end + V(0.01, -0.07, 0.0), end + V(0.0, -0.12, 0.01)], 0.016, 0.003, s.lt, cls=HAIR, bone="hair_tail", flat=0.5, seg=5, per=3)
    bangs(b, s, n=8, part=0.2, swept=0.2, length=0.8)
    side_locks(b, s, length=0.22, n=1, width=0.015)


def style_short(b, s, o):
    """Short cropped hair, a little tousled, for working folk and young men."""
    s.lift = 0.06
    crown_whorl(b, s, n=18, rows=2, length=0.85, skip_front=0.4)
    for i in range(12):
        a = math.pi * 0.5 + i / 11 * math.pi
        d0 = dvec(math.sin(a) * 0.6, 0.5, math.cos(a) * 0.6)
        d1 = dvec(math.sin(a), -0.2, math.cos(a))
        lock(b, s, d0, d1, 0.022, (s.hc, s.dk, s.lt)[i % 3], steps=5, extra=0.004)
    bangs(b, s, n=9, part=0.35, swept=-0.4, length=0.55)


STYLES = {"topknot": style_topknot, "long": style_long, "bun": style_bun, "wild": style_wild, "bald": style_bald,
          "twin_buns": style_twin_buns, "braid": style_braid, "short": style_short}


def build(b, f, style, hair_col, o):
    """Hair in `style` for face `f`.  Returns the Scalp (hats use it to sit on the hair)."""
    s = Scalp(f, hair_col, style, o)
    if style != "bald":
        cap(b, s)
    STYLES.get(style, style_topknot)(b, s, o)
    if o.get("ahoge", False) and style != "bald":
        root = s.pt(dvec(0.05, 1.0, 0.1), 0.0)
        strand(b, [root, root + V(0.01, 0.05, 0.02), root + V(0.04, 0.07, 0.06), root + V(0.06, 0.04, 0.08)], 0.009, 0.001, s.hc, cls=HAIR, bone="head", flat=0.45, seg=6, per=4)
    return s


def top_y(s):
    """Height of the top of the hair (where a hat sits)."""
    return s.pt(Vector((0, 1, 0))).y
