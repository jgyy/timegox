"""Sculpted heads for the characters: skull, jaw, cheeks, brow and eye sockets in one surface,
semi-realistic anime eyes set into the sockets, lids and lashes, nose, lips, ears and eyebrows.

Proportions follow the usual guides for stylised (anime-leaning) 3D characters: about seven
heads tall, eyes on the vertical middle of the head, one eye-width between the eyes, the base of
the nose halfway between brow and chin, the mouth a third of the way from nose to chin, the ears
between the brow line and the base of the nose.  The previous heads were two stacked ellipsoids
almost half a metre tall (under five heads to the body) with eyes pressed onto the surface.

All positions are in Godot space; the head's centre is ``HC``.  ``surface(x, y)`` finds the point
of the face at a given height and offset, so features sit *on* the sculpted surface instead of
floating in front of it.
"""

import math

from mathutils import Matrix, Vector

from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, darken, lighten, mix, rgb
from sculpt import blob3, clamp, morph_sphere, smooth, strand

HC = V(0.0, 1.71, 0.005)
RX = 0.094   # half width of the skull
RY = 0.134   # half height (crown to chin)
RZF = 0.102    # half depth, front
RZB = 0.112  # half depth, back
EYE_Y = -0.004   # eye line, relative to HC
EYE_X = 0.04
NOSE_Y = -0.048
MOUTH_Y = -0.074
CHIN_Y = -0.123


class Face:
    """Shape parameters of one face.  `jaw` < 1 narrows the jaw (youthful / feminine), `cheek`
    lifts the cheekbones, `brow` deepens the brow ridge (older, sterner), `chin` pushes the chin
    forward, `age` 0..1 adds hollows and lines."""

    def __init__(self, o):
        self.fem = o.get("fem", False)
        self.age = o.get("age", 0.0)
        self.jaw = o.get("jaw", 0.9 if self.fem else 1.0)
        self.cheek = o.get("cheek", 1.0)
        self.brow = o.get("brow", 0.6 if self.fem else 1.0)
        self.chin = o.get("chin", 0.8 if self.fem else 1.0)
        self.wide = o.get("face_w", 0.97 if self.fem else 1.0)
        self.skin = rgb(o.get("skin", "f5d6c2"))
        self.eye_r = o.get("eye_size", 1.3 if self.fem else 1.16)
        if "eye_size" not in o:
            self.eye_r *= 1.0 - 0.14 * self.age   # eyes look smaller as lids and brows sag

    # ---- the sculpted skull: unit direction -> local point
    def shape(self, d):
        x, y, z = d.x, d.y, d.z
        rz = RZF if z >= 0 else RZB
        p = Vector((x * RX * self.wide, y * (RY if y >= 0 else RY * 0.92), z * rz))
        low = clamp(-y)                      # 0 at the eye line, 1 at the chin
        # cranium: a little fuller above the ears, flatter at the sides
        p.x *= 1.0 + 0.04 * smooth(0.0, 0.6, y) - 0.05 * low * 0.2
        # jaw: the lower face tapers to a narrow, rounded chin
        jt = smooth(0.25, 1.0, low) ** 1.4
        p.x *= 1.0 - (0.36 - 0.24 * (self.jaw - 1.0)) * jt
        # back of the lower skull curves in to the neck
        if z < 0:
            p.z *= 1.0 - 0.55 * smooth(0.15, 0.95, low) * smooth(0.0, 0.6, -z)
        # the face is a gently curved plane, not the front of a ball
        if z > 0:
            flat = smooth(0.35, 0.95, z) * (1.0 - smooth(0.55, 1.0, abs(y)))
            p.z *= 1.0 - 0.06 * flat
        # chin and jawline pushed forward at the bottom of the face
        if z > -0.2:
            p.z += 0.016 * self.chin * smooth(0.55, 0.95, low) * smooth(-0.2, 0.6, z)
            p.y -= 0.006 * smooth(0.7, 1.0, low) * smooth(0.2, 0.9, z)
        n = p.normalized() if p.length > 1e-6 else Vector((0, 1, 0))
        q = p.copy()
        off = 0.0
        # cheekbones
        for s in (1, -1):
            off += 0.008 * self.cheek * blob3(q, (0.06 * s, -0.022, 0.07), (0.028, 0.022, 0.03))
            # soft cheeks in the young, hollows under the cheekbone in the old
            off += (0.004 * (1.0 - self.age) - 0.006 * self.age) * blob3(q, (0.055 * s, -0.06, 0.07), (0.022, 0.02, 0.03))
            # eye sockets
            off -= 0.007 * blob3(q, (EYE_X * s, EYE_Y + 0.004, 0.095), (0.02, 0.016, 0.03))
            # temples
            off -= 0.004 * blob3(q, (0.085 * s, 0.03, 0.04), (0.02, 0.03, 0.03))
        # brow ridge and forehead
        off += 0.007 * self.brow * blob3(q, (0.0, 0.03, 0.098), (0.06, 0.014, 0.03))
        off += 0.004 * blob3(q, (0.0, 0.08, 0.09), (0.07, 0.04, 0.04))
        # occiput
        off += 0.006 * blob3(q, (0.0, 0.03, -0.11), (0.06, 0.05, 0.03))
        # philtrum and mouth area pushed forward a touch (the teeth behind the lips)
        off += 0.006 * blob3(q, (0.0, MOUTH_Y + 0.004, 0.09), (0.03, 0.018, 0.03))
        return p + n * off

    def surface(self, x, y, front=True):
        """Point on the face at local (x, y), solved by iterating on the direction."""
        d = Vector((x / RX, y / RY, 0.0))
        zz = max(0.05, 1.0 - d.x * d.x - d.y * d.y)
        d.z = math.sqrt(zz) * (1 if front else -1)
        d.normalize()
        for _ in range(14):
            p = self.shape(d)
            err = Vector((x - p.x, y - p.y, 0.0))
            if err.length < 1e-6:
                break
            d = (d + Vector((err.x / RX, err.y / RY, 0.0)) * 0.9).normalized()
        return self.shape(d)

    def normal(self, x, y):
        e = 0.002
        a = self.surface(x + e, y)
        b = self.surface(x - e, y)
        c = self.surface(x, y + e)
        dd = self.surface(x, y - e)
        n = (a - b).cross(c - dd)
        if n.z < 0:
            n = -n
        return n.normalized()

    def colour(self, p, d):
        """Skin colouring: blush, warmer nose and ears, eyelid shading, a soft jaw shadow."""
        sk = self.skin
        c = sk
        blush = 0.0
        for s in (1, -1):
            blush += blob3(p, (0.056 * s, -0.04, 0.08), (0.022, 0.014, 0.03))
            lid = blob3(p, (EYE_X * s, EYE_Y + 0.02, 0.09), (0.024, 0.01, 0.03))
            c = mix(c, mix(sk, "c88a80", 0.55), lid * 0.35)
            under = blob3(p, (EYE_X * s, EYE_Y - 0.022, 0.09), (0.02, 0.006, 0.03))
            c = mix(c, darken(sk, 0.12), under * (0.25 + 0.35 * self.age))
        c = mix(c, "f39a94", min(1.0, blush) * (0.42 if self.fem else 0.22))
        c = mix(c, mix(sk, "e8a090", 0.4), blob3(p, (0.0, NOSE_Y, 0.11), (0.012, 0.012, 0.03)) * 0.5)
        # a soft shadow under the jaw so the head separates from the neck
        c = mix(c, darken(sk, 0.18), smooth(0.7, 1.0, clamp(-d.y)) * smooth(-0.2, 0.4, -d.z + 0.3) * 0.55)
        # crown is hidden under hair; keep it a little darker so gaps never flash
        c = mix(c, darken(sk, 0.08), smooth(0.4, 0.9, d.y) * 0.5)
        return c


def head(b, o, bone="head", eye_bone="eyes"):
    """Build the head, neck excluded.  Returns the Face (for hair and hats to fit onto)."""
    f = Face(o)
    morph_sphere(b, HC, f.shape, f.colour, cls=SKIN, bone=bone, seg=34, rings=26)
    nose(b, f, bone)
    mouth(b, f, o, bone)
    ears(b, f, bone)
    eyes(b, f, o, eye_bone, bone)
    if f.age > 0.3:
        wrinkles(b, f, bone)
    return f


def nose(b, f, bone):
    """A small bridge and a soft tip; nostrils as two darker dents under it."""
    sk = f.skin
    top = f.surface(0.0, EYE_Y - 0.004)
    tip = f.surface(0.0, NOSE_Y + 0.006)
    tip = tip + Vector((0, 0.0, 0.011 if not f.fem else 0.008))
    mid = top.lerp(tip, 0.55) + Vector((0, 0, 0.002))
    pts = [HC + top + Vector((0, 0, -0.004)), HC + mid, HC + tip]
    tipc = mix(sk, "e8a090", 0.18)
    b.tube(pts, [(0.0045, 0.0045), (0.0055, 0.005), (0.0075, 0.0065)], sk, cls=SKIN, bone=bone, seg=10, cap0=False, cols=[sk, sk, tipc], mat=MAT_PLAIN)
    for s in (1, -1):
        b.ellipsoid(HC + tip + Vector((0.0065 * s, -0.003, -0.005)), (0.0055, 0.0042, 0.006), sk, cls=SKIN, bone=bone, seg=10, rings=6, mat=MAT_PLAIN)
        b.ellipsoid(HC + tip + Vector((0.0042 * s, -0.0068, -0.002)), (0.0024, 0.0012, 0.0022), darken(sk, 0.35), cls=SKIN, bone=bone, seg=8, rings=4, mat=MAT_PLAIN)


def mouth(b, f, o, bone):
    """Upper and lower lip with a darker parting line; fuller and rosier for women."""
    lip = rgb(o.get("lip", "d9787a" if f.fem else mix(f.skin, "b86a68", 0.5)))
    w = 0.0165 if f.fem else 0.018
    y = MOUTH_Y
    upper = []
    lower = []
    line = []
    for i in range(9):
        t = i / 8 - 0.5
        x = t * 2 * w
        sp = f.surface(x, y)
        curve = 0.0035 * (1.0 - (2 * t) ** 2)
        # cupid's bow on the upper lip
        bow = 0.0012 * math.cos(t * 2 * math.pi * 2) * (1.0 - abs(2 * t))
        upper.append(HC + sp + Vector((0, 0.0028 + curve * 0.6 + bow, 0.0035)))
        lower.append(HC + f.surface(x * 0.92, y - 0.006) + Vector((0, -0.001 - curve * 0.4, 0.004)))
        line.append(HC + sp + Vector((0, 0.0005 + 0.0015 * (2 * t) ** 2 * (1 if o.get("smile", True) else -1), 0.0045)))
    b.tube(upper, [r * (1.0 if f.fem else 0.7) for r in (0.0012, 0.0018, 0.0024, 0.0027, 0.0025, 0.0027, 0.0024, 0.0018, 0.0012)], mix(lip, f.skin, 0.3), cls=SKIN, bone=bone, seg=7, flat=0.55, up=(0, 0, 1), mat=MAT_PLAIN)
    b.tube(lower, [r * (1.0 if f.fem else 0.7) for r in (0.0012, 0.0022, 0.003, 0.0036, 0.0038, 0.0036, 0.003, 0.0022, 0.0012)], lip if f.fem else mix(lip, f.skin, 0.3), cls=SKIN, bone=bone, seg=7, flat=0.6, up=(0, 0, 1), mat=MAT_PLAIN)
    # the parting line rides on the mouth bone: scaling it tall opens the mouth when speaking
    b.tube(line, [0.0012] * 9, darken(lip, 0.62), cls=SKIN, bone="mouth" if bone == "head" else bone, seg=5, mat=MAT_PLAIN)


def ears(b, f, bone):
    """Ears from brow line to nose base: a flattened shell with a helix rim and an inner fold."""
    sk = f.skin
    for s in (1, -1):
        c = HC + Vector((RX * f.wide * 0.97 * s, -0.018, -0.008))
        rot = Matrix.Rotation(0.32 * s, 3, "Y")
        shell = lambda d, s=s: rot @ Vector((d.x * 0.007, d.y * 0.029, d.z * 0.018)) + Vector((0.004 * s, 0.0, 0.0))
        morph_sphere(b, c, shell, lambda p, d: mix(sk, "e8a090", 0.2 * max(0.0, -d.x * s)), cls=SKIN, bone=bone, seg=14, rings=10)
        rim = []
        for i in range(10):
            a = -0.6 + i / 9 * 3.6
            rim.append(c + rot @ Vector((0.006 * s, math.cos(a) * 0.028, -math.sin(a) * 0.017 - 0.002)))
        b.tube(rim, [0.003, 0.004, 0.0045, 0.0045, 0.0045, 0.0042, 0.0038, 0.0035, 0.0035, 0.004], sk, cls=SKIN, bone=bone, seg=6)
        b.ellipsoid(c + rot @ Vector((0.006 * s, -0.022, -0.004)), (0.005, 0.009, 0.009), sk, cls=SKIN, bone=bone, seg=8, rings=6)
        b.ellipsoid(c + rot @ Vector((0.0075 * s, 0.002, -0.003)), (0.002, 0.012, 0.007), mix(sk, "d89888", 0.4), cls=SKIN, bone=bone, seg=8, rings=5, mat=MAT_PLAIN)


def eyes(b, f, o, eye_bone, bone):
    """Eyes set into the sockets: sclera, limbal ring, iris gradient, pupil, catch-lights, a thick
    upper lash line with a flick at the outer corner, a fine lower lash line, the crease of the
    upper lid and an eyebrow.  Everything on the eye bone scales with the blink."""
    iris = rgb(o.get("eyes", "3a6ad8"))
    lash = rgb(o.get("lash", "1c1418"))
    hair = rgb(o.get("hair", "1a1a2a"))
    brow_col = rgb(o.get("brow_col", darken(hair, 0.15) if sum(hair) < 2.2 else mix(hair, "8a8070", 0.35)))
    k = f.eye_r
    ew, eh = 0.0215 * k, 0.0175 * k
    glow = o.get("glow_eyes", False)
    slit = o.get("slit_eyes", False)
    stern = o.get("stern", False)
    for s in (1, -1):
        cx = EYE_X * s
        cy = EYE_Y
        sp = f.surface(cx, cy)
        nrm = f.normal(cx, cy)
        yaw = math.atan2(nrm.x, nrm.z)
        R = Matrix.Rotation(yaw, 3, "Y")
        c = HC + sp + nrm * -0.0015

        def at(u, v, w=0.0):
            return c + R @ Vector((u, v, w))

        # sclera, slightly off-white with a cool shadow under the lid
        b.ellipsoid(c, (ew, eh, 0.007), "f6f4f2", cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=10, mat=MAT_PLAIN, col2="d6d8e6")
        # iris: dark rim, gradient from shadowed top to a bright lower crescent
        ir = eh * 0.92
        icen = at(0.0, -eh * 0.04, 0.0058)
        b.ellipsoid(icen, (ir * 0.86, ir, 0.0022), darken(iris, 0.62), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=8, mat=MAT_PLAIN)
        b.ellipsoid(icen + R @ Vector((0, 0, 0.0006)), (ir * 0.76, ir * 0.88, 0.0022), lighten(iris, 0.08), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=8, mat=MAT_GLOW if glow else MAT_PLAIN, col2=darken(iris, 0.35))
        b.ellipsoid(icen + R @ Vector((0, -ir * 0.42, 0.0012)), (ir * 0.5, ir * 0.3, 0.0016), lighten(iris, 0.45), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=12, rings=6, mat=MAT_PLAIN)
        # pupil
        if slit:
            b.ellipsoid(icen + R @ Vector((0, 0, 0.0016)), (ir * 0.16, ir * 0.78, 0.0016), "0c0810", cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=10, rings=6, mat=MAT_PLAIN)
        else:
            b.ellipsoid(icen + R @ Vector((0, 0.0004, 0.0016)), (ir * 0.36, ir * 0.42, 0.0016), "120a16", cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=12, rings=6, mat=MAT_PLAIN)
        # catch-lights
        b.ellipsoid(icen + R @ Vector((ir * 0.32 * s, ir * 0.36, 0.0024)), (ir * 0.2, ir * 0.22, 0.0012), "ffffff", cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=8, rings=5, mat=MAT_GLOW)
        b.ellipsoid(icen + R @ Vector((-ir * 0.28 * s, -ir * 0.4, 0.0024)), (ir * 0.09, ir * 0.09, 0.001), "ffffff", cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=6, rings=4, mat=MAT_GLOW)
        # upper lid: a skin shell over the top of the eyeball
        lid = []
        for i in range(9):
            t = i / 8
            a = math.pi * (1.0 - t)
            lid.append(at(math.cos(a) * ew * 1.04, math.sin(a) * eh * 0.55 + eh * 0.5, 0.0045 + 0.002 * math.sin(a)))
        b.tube(lid, [0.0025, 0.0032, 0.0036, 0.0038, 0.0038, 0.0038, 0.0036, 0.0032, 0.0025], f.skin, cls=SKIN, bone=eye_bone, seg=6, flat=0.6, up=(0, 0, 1), mat=MAT_PLAIN)
        # upper lash line: thick in the middle, thickening into a flick at the outer corner
        ul = []
        rad = []
        for i in range(11):
            t = i / 10
            u = (t - 0.5) * 2.0          # -1 inner .. +1 outer (mirrored by s)
            x = u * ew * 1.06 * s
            y = eh * (0.72 - 0.42 * u * u) + eh * 0.12 * u
            ul.append(at(x, y, 0.0064 - 0.002 * u * u))
            rad.append(0.0011 + 0.0016 * math.sin(math.pi * clamp(t * 0.9 + 0.1)) + (0.0012 * smooth(0.7, 1.0, t) if f.fem else 0.0))
        flick = 0.006 if f.fem else 0.003
        ul.append(at(ew * 1.25 * s, eh * 0.18 + flick * 0.6, 0.004))
        rad.append(0.0007)
        b.tube(ul, rad, lash, cls=HAIR, bone=eye_bone, seg=6, flat=0.65, up=(0, 0, 1), mat=MAT_PLAIN)
        # lower lash line, faint and broken at the inner corner
        ll = [at(((i / 6) * 0.75 + 0.05) * ew * s, -eh * (0.8 - 0.25 * ((i / 6) - 0.3) ** 2), 0.0055) for i in range(7)]
        b.tube(ll, [0.0003, 0.0005, 0.0006, 0.0007, 0.0007, 0.0008, 0.0004], mix(lash, f.skin, 0.5), cls=HAIR, bone=eye_bone, seg=5, mat=MAT_PLAIN)
        # lid crease
        cr = [at(((i / 5) * 1.3 - 0.4) * ew * s, eh * (1.18 - 0.2 * ((i / 5) - 0.45) ** 2), 0.004) for i in range(6)]
        b.tube(cr, [0.0002, 0.0004, 0.0005, 0.0005, 0.0004, 0.0002], darken(f.skin, 0.18), cls=SKIN, bone=bone, seg=5, mat=MAT_PLAIN)
        # eyebrow: tapered from a soft inner head to a fine tail, angled down for stern faces
        bp = []
        for i in range(6):
            t = i / 5
            x = (EYE_X - 0.02 + t * 0.048) * s
            y = EYE_Y + 0.032 + 0.006 * math.sin(math.pi * t) - (0.006 * (1.0 - t) if stern else 0.0) - 0.003 * t
            sp2 = f.surface(x, y)
            bp.append(HC + sp2 + f.normal(x, y) * 0.0018)
        b.tube(bp, [0.0026, 0.0028, 0.0025, 0.0021, 0.0015, 0.0007], brow_col, cls=HAIR, bone=bone, seg=6, flat=0.45, up=(0, 0, 1), mat=MAT_PLAIN)


def wrinkles(b, f, bone):
    """Lines of age: crow's feet, nasolabial folds and a forehead line."""
    dk = darken(f.skin, 0.28)
    for s in (1, -1):
        for k in range(3):
            y0 = EYE_Y + 0.006 - k * 0.006
            pts = [HC + f.surface((EYE_X + 0.027 + j * 0.006) * s, y0 - j * 0.002 * (k - 1)) + Vector((0, 0, 0.0012)) for j in range(3)]
            b.tube(pts, [0.0006, 0.0007, 0.0003], dk, cls=SKIN, bone=bone, seg=4, mat=MAT_PLAIN)
        fold = [HC + f.surface((0.017 + j * 0.006) * s, NOSE_Y - j * 0.011) + Vector((0, 0, 0.0012)) for j in range(4)]
        b.tube(fold, [0.0008, 0.001, 0.0009, 0.0004], dk, cls=SKIN, bone=bone, seg=4, mat=MAT_PLAIN)
    fl = [HC + f.surface((j / 4 - 0.5) * 0.07, 0.068 + 0.003 * math.sin(j)) + Vector((0, 0, 0.0012)) for j in range(5)]
    b.tube(fl, [0.0004, 0.0008, 0.0008, 0.0008, 0.0004], dk, cls=SKIN, bone=bone, seg=4, mat=MAT_PLAIN)


def neck(b, f, o, bones):
    """Neck with the sternocleidomastoid slope into the collarbones (only the top shows)."""
    sk = f.skin
    pts = [V(0, 1.45, -0.006), V(0, 1.52, -0.002), V(0, 1.59, -0.008), V(0, 1.64, -0.012)]
    radii = [(0.062, 0.058), (0.054, 0.052), (0.051, 0.052), (0.05, 0.053)] if not f.fem else [(0.056, 0.052), (0.047, 0.046), (0.045, 0.046), (0.045, 0.048)]
    b.tube(pts, radii, sk, cls=SKIN, bones=bones, seg=16, cols=[darken(sk, 0.12), sk, darken(sk, 0.1), sk])
    # Adam's apple on men
    if not f.fem:
        b.ellipsoid(V(0, 1.56, 0.036), (0.009, 0.012, 0.008), sk, cls=SKIN, bone={"neck": 1.0}, seg=8, rings=6)


def beard(b, f, o, bone="head"):
    """A moustache from the upper lip and a beard of tapered locks from the jaw and chin, longer
    in the middle; elders' beards reach the chest and move with the neck."""
    bc = rgb(o.get("beard_col", "e8e8f0"))
    dk = darken(bc, 0.22)
    long = o.get("beard_len", 1.0)
    for s in (1, -1):
        root = HC + f.surface(0.006 * s, MOUTH_Y + 0.012) + Vector((0, 0, 0.006))
        m1 = HC + f.surface(0.026 * s, MOUTH_Y + 0.006) + Vector((0.004 * s, 0, 0.008))
        m2 = HC + f.surface(0.032 * s, MOUTH_Y - 0.02) + Vector((0.008 * s, -0.012 * long, 0.01))
        strand(b, [root, m1, m2, m2 + Vector((0.004 * s, -0.04 * long, 0.004))], 0.0052, 0.0006, bc, col_tip=lighten(bc, 0.1), cls=HAIR, bone=bone, flat=0.6, seg=6, up=(0, 0, 1))
    n = 13
    for i in range(n):
        u = i / (n - 1) - 0.5
        x = u * 0.105
        y = CHIN_Y + 0.05 * (abs(u) * 2) ** 1.4 + 0.012
        root = HC + f.surface(x, y) + Vector((0, 0, 0.002))
        ln = (0.09 + 0.16 * (1.0 - abs(u) * 1.6)) * long
        sway = Vector((u * 0.03, 0, 0))
        pts = [root, root + Vector((0, -ln * 0.3, 0.018)) + sway * 0.4, root + Vector((0, -ln * 0.66, 0.026)) + sway, root + Vector((-u * 0.02, -ln, 0.02)) + sway * 0.8]
        bones = [bone, bone, {bone: 0.7, "neck": 0.3}, {bone: 0.5, "neck": 0.5}]
        strand(b, pts, 0.011 - abs(u) * 0.006, 0.0008, bc if i % 3 else dk, col_tip=lighten(bc, 0.12), cls=HAIR, bones=bones, flat=0.55, seg=6, up=(0, 0, 1), power=1.4)
    # sideburns join beard to hair
    for s in (1, -1):
        for k in range(3):
            y = -0.02 - k * 0.026
            root = HC + f.surface((RX * 0.88 - k * 0.008) * s, y) + Vector((0.002 * s, 0, 0))
            strand(b, [root, root + Vector((-0.004 * s, -0.024, 0.008)), root + Vector((-0.008 * s, -0.05, 0.012))], 0.009, 0.001, dk, cls=HAIR, bone=bone, flat=0.5, seg=5)


def eye_line():
    return HC + Vector((0.0, EYE_Y, RZF * 0.9))


def crown_top():
    return HC + Vector((0.0, RY, -0.01))

