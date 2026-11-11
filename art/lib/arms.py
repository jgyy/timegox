"""The Eight Arms (the Hundred Arms release): the weapons the hero can carry, each built from code.

Every weapon is modelled standing up: the grip at the origin, its length along +Y (the point, the
head or the upper limb of the bow upwards), an edge or the face of a fan towards +Z.  The game hangs
it on the hero's ``sword`` bone (scripts/arms.gd), turned so that +Y lies along the line a jian is
held on, so every clip written for the blade carries any of them, and a clip that needs both hands
free puts it away by shrinking that bone, as it always did the sword.

    jian    the straight sword: the gentleman of arms
    sabre   the single-edged dao: the courage of arms
    spear   the qiang with its red tassel: the king of arms
    staff   the gun, a sweeper's broom handle shod with iron: the grandfather of arms
    fan     an iron-ribbed folding fan
    bow     a horn-and-sinew recurve, strung
    whip    the nine-section chain whip, hanging from its handle
    brush   the judge's brush: an iron brush as long as a forearm

Run any of art/weapons/*.py:  blender --background --python art/weapons/<id>.py  ->  assets/weapons/<id>.glb
"""
import math

import kit
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, METAL, WOOD, V, Builder, darken, lighten

GOLD = "d8b050"
STEEL = "dce8ff"


def _wrap(b, y0, y1, r, col, n=7):
    pts = [V(0, y0 + (y1 - y0) * k / (n - 1), 0) for k in range(n)]
    b.tube(pts, [r + (0.001 if k % 2 else 0.0) for k in range(n)], col, cls=WOOD, seg=8, cols=[col if k % 2 else darken(col, 0.3) for k in range(n)])


def _tassel(b, at, col, ln=0.14, n=7):
    at = V(at)
    b.tube([at, at + V(0, -ln * 0.4, 0.004)], [0.004, 0.004], col, cls=CLOTH, seg=5)
    b.ball(at + V(0, -ln * 0.4, 0.004), 0.008, GOLD, cls=METAL, seg=8, rings=5)
    for k in range(n):
        a = 2 * math.pi * k / n
        b.tube([at + V(0, -ln * 0.42, 0.004), at + V(math.cos(a) * 0.014, -ln, math.sin(a) * 0.014 + 0.004)], [0.0028, 0.001], lighten(col, 0.15), cls=CLOTH, seg=4)


def jian(b):
    hilt = "3a3048"
    _wrap(b, -0.09, 0.06, 0.0165, hilt)
    b.lathe(V(0, -0.1, 0), [(0.0001, -0.02), (0.018, -0.012), (0.022, 0.0), (0.014, 0.012)], GOLD, cls=METAL, seg=10)
    b.ellipsoid(V(0, 0.075, 0), (0.07, 0.018, 0.024), GOLD, cls=METAL, seg=14, rings=6)
    b.ball(V(0, 0.075, 0.0), 0.012, "50c0a0", cls=CRYSTAL, seg=8, rings=5)
    pts = [V(0, 0.09 + 0.8 * t, 0) for t in (0.0, 0.25, 0.5, 0.75, 0.92, 1.0)]
    b.tube(pts, [(0.024, 0.006), (0.0235, 0.006), (0.0225, 0.0058), (0.021, 0.0055), (0.016, 0.004), (0.002, 0.001)], STEEL, cls=METAL, seg=8, up=(0, 0, 1))
    b.tube([V(0, 0.1, 0), V(0, 0.84, 0)], [(0.003, 0.0068), (0.002, 0.004)], lighten(STEEL, 0.25), cls=METAL, seg=5, up=(0, 0, 1))
    b.tube([V(0, 0.12, 0), V(0, 0.86, 0)], [(0.0026, 0.0035), (0.0016, 0.002)], lighten(STEEL, 0.5), cls=CRYSTAL, seg=5, mat=MAT_GLOW, up=(0, 0, 1))
    _tassel(b, V(0, -0.11, 0), "e04050")


def sabre(b):
    """The dao: one edge, a broad blade that widens to the last third and curves back to its point,
    a disc guard, a ring pommel with a red cloth through it."""
    _wrap(b, -0.1, 0.06, 0.0175, "5a2a22")
    b.lathe(V(0, 0.07, 0), [(0.0001, -0.006), (0.042, -0.004), (0.045, 0.002), (0.02, 0.008)], GOLD, cls=METAL, seg=14, squash=(0.7, 1.0))
    # the blade: spine at -Z, edge at +Z, bellying forward and sweeping back to the point
    n = 12
    spine = []
    rad = []
    for k in range(n):
        t = k / (n - 1)
        y = 0.08 + 0.76 * t
        back = -0.05 * t * t                       # the curve of the back
        belly = 0.026 + 0.02 * math.sin(math.pi * min(1.0, t * 1.25)) ** 1.5
        w = belly * (1.0 - kit.ease(max(0.0, (t - 0.82) / 0.18)))
        spine.append(V(0, y, back + w))
        rad.append((0.0052 * (1.0 - 0.5 * t), max(0.002, w)))
    b.tube(spine, rad, "ccd4e0", cls=METAL, seg=8, up=(1, 0, 0))
    # the back of the blade, darker, and a bright ground edge
    b.tube([V(0, 0.1 + 0.6 * t, -0.05 * t * t + 0.003) for t in (0.0, 0.33, 0.66, 1.0)], [(0.006, 0.004)] * 4, "7a8494", cls=METAL, seg=5, up=(1, 0, 0))
    edge = [V(0, 0.1 + 0.7 * t, -0.05 * t * t + 2.0 * (0.026 + 0.02 * math.sin(math.pi * min(1.0, t * 1.25)) ** 1.5) - 0.004) for t in (0.0, 0.25, 0.5, 0.75, 0.9)]
    b.tube(edge, [(0.0016, 0.003)] * 5, "ffffff", cls=CRYSTAL, seg=4, mat=MAT_GLOW, up=(1, 0, 0))
    # ring pommel and its cloth
    for k in range(10):
        a = 2 * math.pi * k / 10
        a2 = 2 * math.pi * (k + 1) / 10
        b.tube([V(0, -0.135 + math.cos(a) * 0.03, math.sin(a) * 0.03), V(0, -0.135 + math.cos(a2) * 0.03, math.sin(a2) * 0.03)], [0.006, 0.006], GOLD, cls=METAL, seg=5)
    b.ribbon([V(0, -0.165, 0), V(0.01, -0.26, 0.03), V(-0.01, -0.36, 0.05), V(0.012, -0.45, 0.04)], [0.02, 0.026, 0.024, 0.012], (1, 0, 0.3), "d83a30", cls=CLOTH, col_end="a01c20")


def spear(b):
    """The qiang: a waxwood shaft a little taller than its bearer, a leaf-shaped head, and the red
    horsehair tassel under it that blurs the point and keeps the blood off the hands."""
    wood = "c8a468"
    pts = [V(0, -0.85 + 2.0 * k / 10, 0) for k in range(11)]
    b.tube(pts, [0.017 - 0.004 * k / 10 for k in range(11)], wood, cls=WOOD, seg=8, cols=[darken(wood, 0.08 * (k % 2)) for k in range(11)])
    b.lathe(V(0, -0.87, 0), [(0.0001, -0.03), (0.016, -0.01), (0.019, 0.02)], "8a8e98", cls=METAL, seg=8)
    top = V(0, 1.15, 0)
    b.lathe(top, [(0.016, 0.0), (0.02, 0.02), (0.012, 0.05)], GOLD, cls=METAL, seg=10)
    b.lathe(top + V(0, 0.05, 0), [(0.01, 0.0), (0.036, 0.07), (0.028, 0.16), (0.0001, 0.3)], STEEL, cls=METAL, seg=8, squash=(1.0, 0.24))
    b.tube([top + V(0, 0.07, 0), top + V(0, 0.33, 0)], [(0.004, 0.0105), (0.001, 0.003)], lighten(STEEL, 0.4), cls=CRYSTAL, seg=4, mat=MAT_GLOW, up=(0, 0, 1))
    for k in range(14):
        a = 2 * math.pi * k / 14
        ln = 0.16 + 0.04 * math.sin(k * 2.3)
        b.tube([top + V(math.cos(a) * 0.014, 0.0, math.sin(a) * 0.014), top + V(math.cos(a) * 0.05, -ln * 0.5, math.sin(a) * 0.05), top + V(math.cos(a) * 0.04, -ln, math.sin(a) * 0.04)],
               [0.006, 0.005, 0.0012], "d82a20" if k % 2 else "f05a3a", cls=HAIR, seg=4)


def staff(b):
    """The gun: the handle of a sweeper's broom, of white waxwood, shod with iron at both ends and
    bound with a strip of the blue cloth of the sect where the hands go."""
    wood = "d8c8a0"
    pts = [V(0, -0.8 + 1.7 * k / 12, 0.003 * math.sin(k * 1.3)) for k in range(13)]
    b.tube(pts, [0.0185] * 13, wood, cls=WOOD, seg=8, cols=[darken(wood, 0.06 * (k % 3 == 0)) for k in range(13)])
    for y in (-0.8, 0.9):
        s = 1.0 if y > 0 else -1.0
        b.lathe(V(0, y, 0), [(0.021, -0.06 * s), (0.022, 0.0), (0.0001, 0.012 * s)] if s > 0 else [(0.0001, 0.012 * s), (0.022, 0.0), (0.021, -0.06 * s)], "6a707c", cls=METAL, seg=10)
        b.lathe(V(0, y - 0.075 * s, 0), [(0.0215, -0.006), (0.0235, 0.0), (0.0215, 0.006)], GOLD, cls=METAL, seg=10)
    for y0 in (-0.06, 0.36):
        _wrap(b, y0, y0 + 0.14, 0.0205, "2a5aa8", n=8)


def fan(b):
    """An iron-ribbed folding fan, open: thirteen ribs from a pivot at the grip, a leaf of blue silk
    with a pale edge between them, and a tassel from the pivot.  Shut, it is a truncheon."""
    ribs = 13
    spread = 2.3
    ln = 0.34
    for k in range(ribs):
        a = (k / (ribs - 1) - 0.5) * spread
        tip = V(0, 0.02 + math.cos(a) * ln, math.sin(a) * ln)
        guard = k in (0, ribs - 1)
        b.tube([V(0, 0.0, 0), tip], [(0.004, 0.006) if guard else (0.0022, 0.0035), (0.003, 0.005) if guard else (0.0018, 0.003)], "2a2e3a" if guard else "5a606c", cls=METAL, seg=5, up=(1, 0, 0))
    rows = []
    cols = []
    for j, (rr, cc) in enumerate(((0.36, "2a5aa8"), (0.55, "3a7ad0"), (0.8, "5a9ae8"), (0.97, "e8f0ff"), (1.0, "ffffff"))):
        rows.append([V(0.0015 * (1 if i % 2 else -1), 0.02 + math.cos((i / 24 - 0.5) * spread) * ln * rr, math.sin((i / 24 - 0.5) * spread) * ln * rr) for i in range(25)])
        cols.append(kit.rgb(cc))
    b.sheet(rows, "3a7ad0", cls=CLOTH, cols=[c for c in cols for _ in range(25)], thickness=0.003)
    b.ball(V(0, 0.0, 0), 0.008, GOLD, cls=METAL, seg=8, rings=5)
    _wrap(b, -0.075, -0.005, 0.009, "2a2e3a", n=5)
    _tassel(b, V(0, -0.078, 0), "e8c040", ln=0.11)


def bow(b):
    """A recurve of horn, wood and sinew, strung: the grip at the origin, limbs above and below
    bending back at the ears, the string in front of the belly."""
    n = 15
    limb = []
    rad = []
    cols = []
    for k in range(n):
        t = k / (n - 1) * 2.0 - 1.0
        y = t * 0.56
        z = -0.13 * (1.0 - t * t) + 0.07 * max(0.0, abs(t) - 0.72) / 0.28
        limb.append(V(0, y, z))
        w = 0.016 - 0.008 * abs(t)
        rad.append((w * 1.15, w * 0.7))
        cols.append("8a5a34" if abs(t) > 0.16 else "3a2a22")
    b.tube(limb, rad, "8a5a34", cls=WOOD, seg=8, up=(1, 0, 0), cols=[kit.rgb(c) for c in cols])
    for s in (1, -1):
        b.tube([V(0, 0.2 * s, -0.117), V(0, 0.36 * s, -0.08)], [(0.0165, 0.0036), (0.013, 0.003)], "e8dcc0", cls=METAL, seg=5, up=(1, 0, 0))
        b.lathe(V(0, 0.56 * s, 0.07), [(0.006, -0.008), (0.009, 0.0), (0.004, 0.012)], "e8dcc0", cls=METAL, seg=6)
    b.tube([limb[0] + V(0, 0, 0.004), V(0, 0, 0.0), limb[-1] + V(0, 0, 0.004)], [0.0016, 0.0018, 0.0016], "f0ead8", cls=HAIR, seg=4)
    b.tube([V(0, -0.03, 0), V(0, 0.03, 0)], [0.003, 0.003], "c83a30", cls=CLOTH, seg=5)
    _wrap(b, -0.05, 0.05, 0.0178, "2a5aa8", n=6)
    grip = [V(0, -0.05 + 0.1 * k / 5, -0.13) for k in range(6)]
    b.tube(grip, [0.0185] * 6, "2a5aa8", cls=WOOD, seg=8)


def whip(b):
    """The nine-section whip: a short handle, nine rods of steel joined by rings, a dart at the end
    and a flag of red silk to track it by.  Modelled hanging from the handle in a slow curve."""
    _wrap(b, -0.02, 0.1, 0.0165, "3a2a22", n=6)
    b.lathe(V(0, -0.03, 0), [(0.0001, -0.014), (0.02, -0.004), (0.016, 0.01)], GOLD, cls=METAL, seg=10)
    b.lathe(V(0, 0.1, 0), [(0.017, 0.0), (0.021, 0.008), (0.01, 0.02)], GOLD, cls=METAL, seg=10)
    p = V(0, 0.12, 0)
    d = V(0, 1, 0)
    for k in range(9):
        a = 0.26 + 0.05 * k
        d = V(0, math.cos(a * (k + 1) * 0.55), math.sin(a * (k + 1) * 0.55)).normalized()
        q = p + d * 0.1
        b.tube([p + d * 0.012, p + d * 0.05, q - d * 0.012], [0.0052, 0.0064, 0.0052], "b8c0cc" if k % 2 else "98a0ae", cls=METAL, seg=6)
        b.ball(q, 0.0072, GOLD, cls=METAL, seg=6, rings=4)
        if k == 0:
            b.ribbon([q, q + V(0.0, -0.05, 0.02), q + V(0.01, -0.12, 0.0)], [0.012, 0.018, 0.006], (1, 0, 0), "d83a30", cls=CLOTH)
        p = q
    b.lathe(p + d * 0.005, [(0.006, 0.0), (0.012, 0.02), (0.0001, 0.085)], STEEL, cls=METAL, seg=6, rot=(math.atan2(d.z, d.y), 0, 0))
    b.ribbon([p, p + V(0.0, -0.06, -0.03), p + V(0.012, -0.15, -0.02), p + V(0.0, -0.22, -0.05)], [0.014, 0.024, 0.022, 0.008], (1, 0, 0.2), "e04a38", cls=CLOTH, col_end="a01c20")


def brush(b):
    """The judge's brush: an iron brush as long as a forearm, its hair forged to a point, with a ring
    at the butt to spin it on a finger and a drop of cinnabar ink that never dries."""
    b.tube([V(0, -0.09, 0), V(0, 0.2, 0)], [0.0105, 0.0115], "20242c", cls=METAL, seg=8)
    for y in (-0.085, 0.02, 0.19):
        b.lathe(V(0, y, 0), [(0.0115, -0.006), (0.0135, 0.0), (0.0115, 0.006)], GOLD, cls=METAL, seg=10)
    b.lathe(V(0, 0.2, 0), [(0.0125, 0.0), (0.019, 0.035), (0.016, 0.08), (0.0001, 0.17)], "2a2228", cls=HAIR, seg=10)
    b.lathe(V(0, 0.3, 0), [(0.0125, 0.0), (0.0001, 0.075)], "c8281c", cls=CRYSTAL, seg=8, mat=MAT_GLOW)
    for k in range(10):
        a = 2 * math.pi * k / 10
        a2 = 2 * math.pi * (k + 1) / 10
        b.tube([V(0, -0.112 + math.cos(a) * 0.02, math.sin(a) * 0.02), V(0, -0.112 + math.cos(a2) * 0.02, math.sin(a2) * 0.02)], [0.004, 0.004], GOLD, cls=METAL, seg=5)
    _tassel(b, V(0, -0.133, 0), "2a5aa8", ln=0.1, n=5)


ARMS = {"jian": jian, "sabre": sabre, "spear": spear, "staff": staff, "fan": fan, "bow": bow, "whip": whip, "brush": brush}


def export(name):
    kit.reset()
    b = Builder(name)
    ARMS[name](b)
    print("[art] weapons/%s: %d triangles" % (name, b.tri_count()))
    kit.finish_static(b, "weapons/%s.glb" % name, samples=10, dist=0.12, strength=0.4)
