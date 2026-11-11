"""Sculpted heads for the characters: skull, jaw, cheeks, brow and eye sockets in one surface,
anime eyes set into the sockets, lids and lashes, nose, lips, ears and eyebrows.

The Spring Thunder release re-sculpts every face after the 3D anime characters of gacha games
(Genshin Impact, Honkai: Star Rail, Wuthering Waves, Zenless Zone Zero and their kind; see the
README's references):

* a large cranium and a short lower face: the eye line sits a little below the middle of the head,
  and nose, mouth and chin are packed into the lower part (the lower half of the skull is ``LOW`` of
  the upper);
* full cheeks (``Face.cheeks``): the face below the eyes and beside the nose carried forward, never
  past its middle, so the three-quarter outline swells at the cheek before the jaw draws in;
* a soft V jaw: full cheeks at the eyes and below them, tapering in straight lines to a small chin
  with a mass of its own (``Face.chin_mass``: rounded at the tip, the lowest point of the face, nearly
  level with the lower lip in profile, turning in a tight curve into an underside that rises to the
  throat; a man's broader and squarer), and a front of the face that is a gentle plane rather than
  the front of a ball;
* big eyes set wide (an eye's width or more between them): a dark, heavy upper lash line with a
  flick at the outer corner, a fine lower lash on the outer half only, a tall iris that is dark under
  the lid and bright at the bottom, a small pupil, a large highlight and a small one, and the
  shadow of the upper lid on the white of the eye;
* almost no nose: a small soft tip with a touch of colour and a shadow under it, no nostrils;
* a small mouth low on the face, the lips a line and a hint of colour;
* thin, high, long eyebrows;
* and the face *shaded from a smooth shape* (``Builder.set_normals``): the skin, nose and lips take
  their normals from an ellipsoid round the head, so the cel shading falls across the face as one
  clean shape the way an anime face is lit, and never in blotches round the nose and sockets.

All positions are in Godot space; the head's centre is ``HC``.  ``surface(x, y)`` finds the point
of the face at a given height and offset, so features sit *on* the sculpted surface instead of
floating in front of it.

The Hundred Hearths release brings the faces a step back towards life (the README's notes on it):

* a **wider lower jaw**: the V of the jaw tapers far less (``JAW_TAPER``), the corners of the jaw
  under the ears have a mass of their own (``JAW_CORNER``: the angle of the mandible, a man's squarer
  than a woman's), and the chin is broader, so the outline of the face from the front runs from the
  cheekbone down to a jaw nearly as wide before it turns in to the chin, instead of a heart drawn
  to a point;
* **smaller, more lifelike eyes** (``EYE_K``, and ``eyes``): about a fifth of the face's width each
  and one eye's width apart, as in life; an almond opening well under half as tall as it is wide; a
  *round* iris whose top the upper lid covers, a pupil in proportion, one small highlight; a thin
  upper lash line instead of the heavy wing, and eyebrows brought down to sit over the socket.
"""

import math

from mathutils import Matrix, Vector

from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, darken, lighten, mix, rgb
from sculpt import blob3, bump, clamp, morph_sphere, smooth, strand

HC = V(0.0, 1.71, 0.005)
RX = 0.094   # half width of the skull
RY = 0.134   # half height, crown to the centre
LOW = 0.88   # the lower half of the head (centre to chin) against the upper: a short anime jaw
RZF = 0.1    # half depth, front
RZB = 0.112  # half depth, back
EYE_Y = -0.012   # eye line, relative to HC: a little below the middle of the head
EYE_X = 0.0365   # half the distance between the eyes' centres: one eye's width between them, as in life
NOSE_Y = -0.05
MOUTH_Y = -0.078
CHIN_Y = -RY * LOW
# every eye's size against what its script asks for (Face.eye_r)
EYE_K = 0.86   # (0.8 until the Hollow Hills release: every eye a little larger again, about a fourteenth)
# the lower jaw (Face.skull): how much the face narrows from the cheeks to the chin, and how far the
# corners of the jaw (the angle of the mandible, below and in front of the ears) stand out
JAW_TAPER = 0.22
JAW_CORNER = 0.085
JAW_CORNER_F = 0.06
# full cheeks (Face.cheeks): how far forward, where (either side of the nose, below the eyes)
CHEEK = 0.017
CHEEK_M = 0.013
CHEEK_X = 0.058
CHEEK_Y = -0.05
# the chin's mass (Face.chin_mass): the profile below the mouth is a rounded box from CHIN_C down,
# CHIN_DROP deep (a man's CHIN_DROP_M), with corners as square as the exponent says
CHIN_C = -0.074
CHIN_DROP = 0.049
CHIN_DROP_M = 0.052
CHIN_N = 4.4
CHIN_N_M = 5.2


def smax(a, b, k):
    """Smooth maximum of a and b, blended over a width of k (polynomial; never less than max(a, b))."""
    h = clamp(0.5 + 0.5 * (a - b) / k)
    return b + (a - b) * h + k * h * (1.0 - h)


def eye_y_of(o):
    """The eye line of a face with options `o`, relative to HC: a woman's (and a child's) sits lower,
    at about 0.43 of the head's height from the chin, a man's nearer the real 0.45-0.47 (gacha
    proportion sheets; see the README's references)."""
    o = o or {}
    fem = o.get("fem", o.get("hair_style") == "long" and not o.get("beard", False) and not o.get("stern", False))
    return EYE_Y if fem else EYE_Y + 0.007


class Face:
    """Shape parameters of one face.  `jaw` < 1 narrows the jaw (youthful / feminine), `cheek`
    lifts the cheekbones, `brow` deepens the brow ridge (older, sterner), `chin` pushes the chin
    forward, `age` 0..1 adds hollows and lines."""

    def __init__(self, o):
        self.fem = o.get("fem", False)
        self.age = o.get("age", 0.0)
        self.jaw = o.get("jaw", 0.9 if self.fem else 1.0)
        self.cheek = o.get("cheek", 1.0)
        self.brow = o.get("brow", 0.35 if self.fem else 0.7)
        self.chin = o.get("chin", 0.8 if self.fem else 1.0)
        self.wide = o.get("face_w", 0.97 if self.fem else 1.0)
        self.skin = rgb(o.get("skin", "f5d6c2"))
        # (every eye a tenth smaller than its script asks for, since the Spring Thunder release: with
        # the bigger head and the chin's mass, the eyes the faces were first drawn with crowded them)
        # (and since the Hundred Hearths release the scripts' sizes are drawn together as well: the
        # biggest eyes of the cast are a quarter wider than the smallest, not half as wide again)
        self.eye_r = (1.0 + 0.45 * (o.get("eye_size", 1.3 if self.fem else 1.16) - 1.0)) * EYE_K / 0.9 * 0.98
        if "eye_size" not in o:
            self.eye_r *= 1.0 - 0.14 * self.age   # eyes look smaller as lids and brows sag
        # an elder's face keeps more of its bones: less of the anime softness
        self.soft = 1.0 - 0.6 * smooth(0.3, 0.9, self.age)
        self.eye_y = eye_y_of(o)

    # ---- the sculpted skull: unit direction -> local point
    def shape(self, d):
        return self.cheeks(self.features(self.chin_mass(self.skull(d), d)), d)

    def skull(self, d):
        """The skull before the chin is given its mass and before cheekbones, sockets and brow."""
        x, y, z = d.x, d.y, d.z
        rz = RZF if z >= 0 else RZB
        p = Vector((x * RX * self.wide, y * (RY if y >= 0 else RY * LOW), z * rz))
        low = clamp(-y)                      # 0 at the middle of the head, 1 at the chin
        soft = self.soft
        # cranium: fuller above the ears (the big anime skull), flatter at the sides
        p.x *= 1.0 + 0.05 * smooth(0.0, 0.6, y) - 0.01 * low
        # cheeks: full at the eyes and just below them, the widest part of the face
        p.x *= 1.0 + 0.035 * soft * bump(-y, 0.18, 0.2) * smooth(-0.1, 0.5, z)
        # jaw: a soft V, the lower face tapering to a small chin (the young and the women more)
        jt = smooth(0.3, 1.0, low) ** 1.25
        taper = JAW_TAPER - 0.24 * (self.jaw - 1.0) + 0.04 * soft
        p.x *= 1.0 - taper * jt
        # the corners of the jaw: the lower face keeps its width down to the angle of the mandible,
        # two thirds of the way from the eyes to the chin, and only then turns in
        p.x *= 1.0 + (JAW_CORNER_F if self.fem else JAW_CORNER) * (0.6 + 0.4 * self.jaw) * bump(low, 0.6, 0.3) * smooth(-0.55, 0.15, z)
        # back of the lower skull curves in to the neck
        if z < 0:
            p.z *= 1.0 - 0.55 * smooth(0.15, 0.95, low) * smooth(0.0, 0.6, -z)
        # the face is a gently curved plane, not the front of a ball
        if z > 0:
            flat = smooth(0.3, 0.95, z) * (1.0 - smooth(0.6, 1.0, abs(y)))
            p.z *= 1.0 - (0.06 + 0.035 * soft) * flat
        # the chin comes forward a little; the jaw line under it is clean
        if z > -0.2:
            p.z += (0.014 + 0.004 * soft) * self.chin * smooth(0.6, 0.97, low) * smooth(-0.2, 0.6, z)
            p.y -= 0.007 * smooth(0.75, 1.0, low) * smooth(0.25, 0.9, z)
        return p

    def features(self, p):
        """Cheekbones, cheeks, eye sockets, temples, brow, forehead, occiput and the mouth's fullness,
        pushed out along the direction from the head's centre."""
        soft = self.soft
        n = p.normalized() if p.length > 1e-6 else Vector((0, 1, 0))
        q = p.copy()
        off = 0.0
        for s in (1, -1):
            # cheekbones: soft on the young (a rounded cheek), more bone on the old
            off += 0.006 * self.cheek * (1.4 - soft) * blob3(q, (0.06 * s, -0.024, 0.07), (0.028, 0.022, 0.03))
            # soft cheeks in the young, hollows under the cheekbone in the old
            off += (0.005 * (1.0 - self.age) - 0.006 * self.age) * blob3(q, (0.052 * s, -0.056, 0.07), (0.024, 0.022, 0.03))
            # eye sockets: shallow (anime eyes are not deep-set)
            off -= (0.003 + 0.004 * (1.0 - soft)) * blob3(q, (EYE_X * s, self.eye_y + 0.003, 0.092), (0.02, 0.013, 0.03))
            # temples
            off -= 0.004 * blob3(q, (0.085 * s, 0.03, 0.04), (0.02, 0.03, 0.03))
        # brow ridge and forehead
        off += 0.007 * self.brow * blob3(q, (0.0, 0.026, 0.096), (0.06, 0.014, 0.03))
        off += 0.004 * blob3(q, (0.0, 0.08, 0.09), (0.07, 0.04, 0.04))
        # occiput
        off += 0.006 * blob3(q, (0.0, 0.03, -0.11), (0.06, 0.05, 0.03))
        # the mouth area pushed forward a touch (the teeth behind the lips)
        off += 0.004 * blob3(q, (0.0, MOUTH_Y + 0.004, 0.088), (0.026, 0.016, 0.03))
        return p + n * off

    def chin_mass(self, p, d):
        """The chin as a mass of its own: point `p` of the skull (direction `d`) -> moved.

        Anime chins are drawn small and sharp, but a 3D head shaped that way ends in the bottom of a
        ball: a needle from the front and, in profile, a chin that rolls back into the neck in one
        big curve.  The drawing guides build the profile as "two out, one in" (the brow out, the
        socket in, the cheekbone out, the jaw in under it, the tip of the chin out), and the chin as
        a small rounded mass below the mouth: the lowest point of the face, nearly level with the
        lower lip, turning in a tight curve into a short underside that runs back up to the throat;
        from the front, a rounded tip with some width at the end of straight V jaw lines (a woman's
        tapered and round, a man's broader and squarer, his jaw a little longer); see the README's
        references.

        So the lower front of the face is fitted to a rounded box in profile: the skull's midline
        below the mouth is pushed out, along rays from a point behind the mouth, to a superellipse
        (exponent CHIN_N) whose front is the face at the mouth and whose bottom is the chin, and the
        same push is given to every point at that height, less and less round the jaw towards the
        ears and none at the throat.  The chin's bottom is widened a little, and there is a slight
        hollow under the lower lip."""
        fem = self.fem
        if d.y > -0.45:
            return p
        k = self.chin / (0.8 if fem else 1.0)            # 1 at the default chin
        jw = self.jaw / (0.9 if fem else 1.0)            # 1 at the default jaw
        # the midline of the skull at this height, and where the rounded box puts it
        mz = math.sqrt(max(0.0, 1.0 - d.y * d.y))
        b = self.skull(Vector((0.0, d.y, mz)))
        cy = CHIN_C
        if b.y >= cy or b.z <= 1e-6:
            return p
        top = self.skull(Vector((0.0, CHIN_C / (RY * LOW), math.sqrt(max(0.0, 1.0 - (CHIN_C / (RY * LOW)) ** 2)))))
        az = top.z
        ay = (CHIN_DROP if fem else CHIN_DROP_M) * (0.94 + 0.06 * k)
        n = (CHIN_N if fem else CHIN_N_M) + 0.4 * (k - 1.0)
        vy, vz = b.y - cy, b.z
        lam = (abs(vy / ay) ** n + abs(vz / az) ** n) ** (-1.0 / n)
        dy, dz = vy * (lam - 1.0), vz * (lam - 1.0)
        # all of it at the front, less round the jaw, none at the sides or the throat
        ring = math.sqrt(d.x * d.x + d.z * d.z)
        front = smooth(0.15, 0.75, d.z / ring) * smooth(0.0, 0.3, ring) if ring > 1e-6 else 0.0
        # (and it eases in from the mouth down, so the face above it is untouched)
        ease = smooth(0.0, 0.012, cy - b.y)
        w = front * ease
        q = p.copy()
        q.y += dy * w
        q.z += dz * w
        # the lower face a little fuller from below the nose to the chin, all the way round the jaw (so
        # its lines run straight into the chin), and the chin a small rounded tip, not a point (a
        # man's broader)
        q.x *= 1.0 + (0.3 if fem else 0.42) * jw * smooth(-0.06, -0.118, b.y) * smooth(-0.06, 0.0, p.z)
        # the slight hollow between the lower lip and the chin
        q.z -= 0.001 * blob3(q, (0.0, MOUTH_Y - 0.013, 0.07), (0.017, 0.0055, 0.02))
        return q

    def cheeks(self, p, d):
        """Full anime cheeks: local point `p` -> moved.  The cheek line is what makes a face read soft
        or sharp, and it shows in neither the front view nor the profile but in the three-quarter
        view, the one a face is seen in most: there the far cheek swells out under the eye before
        the jaw draws in to the chin.  The modelling guides fill the cheek out forwards (along the
        face, not across it), so the outline from the front keeps its width; the shading stays one
        smooth shape (head(): the face takes the normals of an ellipsoid).  So the face below the eyes
        and beside the nose is carried forward, most on the young and on women, but never further
        forward than the middle of the face at that height (or the nose would sit in a hollow between
        two puffs)."""
        k = (CHEEK if self.fem else CHEEK_M) * (0.35 + 0.65 * self.soft)
        if k <= 0.0 or p.z <= 0.0 or d.y > 0.2:
            return p
        push = 0.0
        for s in (1, -1):
            g = math.exp(-((p.x - s * CHEEK_X) / 0.025) ** 2 - ((p.y - CHEEK_Y) / 0.024) ** 2)
            push += k * g * smooth(0.0, 0.04, p.z)
        if push < 1e-7:
            return p
        dm = Vector((0.0, d.y, math.sqrt(max(0.0, 1.0 - d.y * d.y))))
        mid = self.features(self.chin_mass(self.skull(dm), dm))
        room = max(0.0, mid.z - 0.0015 - p.z)
        q = p.copy()
        # (the push, or the room left if that is less, with a soft corner: never below nothing, never
        # beyond either)
        q.z += push * (1.0 - math.exp(-room / push))
        return q

    def shade_normal(self, p):
        """The normal an anime face is lit with at Godot-space point `p` (see head): that of an
        ellipsoid round the head, centred a little behind the face, so the whole face turns to the
        light as one smooth shape; a little of the jaw's true direction is kept under the cheeks so
        the face still reads as narrowing to the chin."""
        c = HC + Vector((0.0, -0.012, -0.03))
        d = p - c
        n = Vector((d.x / (RX * RX), d.y / (RY * RY), d.z / (0.115 * 0.115)))
        if n.length < 1e-9:
            return Vector((0, 0, 1))
        n.normalize()
        # under the cheeks the true surface faces down and out: keep a share of it so the jaw line
        # takes the light
        low = clamp((HC.y + EYE_Y - 0.03 - p.y) / 0.07)
        if low > 0.0:
            tn = Vector((d.x, d.y * 0.6, d.z)).normalized()
            n = (n * (1.0 - 0.35 * low) + tn * 0.35 * low).normalized()
        return n

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
            lid = blob3(p, (EYE_X * s, self.eye_y + 0.013, 0.09), (0.021, 0.007, 0.03))
            c = mix(c, mix(sk, "c88a80", 0.55), lid * 0.35)
            under = blob3(p, (EYE_X * s, self.eye_y - 0.014, 0.09), (0.018, 0.005, 0.03))
            c = mix(c, darken(sk, 0.12), under * (0.25 + 0.35 * self.age))
        c = mix(c, "f39a94", min(1.0, blush) * (0.42 if self.fem else 0.22))
        c = mix(c, mix(sk, "e8a090", 0.4), blob3(p, (0.0, NOSE_Y, 0.11), (0.012, 0.012, 0.03)) * 0.5)
        # a soft shadow under the jaw so the head separates from the neck
        c = mix(c, darken(sk, 0.18), smooth(0.7, 1.0, clamp(-d.y)) * smooth(-0.2, 0.4, -d.z + 0.3) * 0.55)
        # crown is hidden under hair; keep it a little darker so gaps never flash
        c = mix(c, darken(sk, 0.08), smooth(0.4, 0.9, d.y) * 0.5)
        return c


# ---------------------------------------------------------------- expression (the Hundred Arms release)
# A face that is to show what it feels needs more than a blink and a jaw.  Six bones are sculpted into
# every human head: one under each eyebrow (raised in surprise, drawn down and together in anger,
# tilted up at the inner end in sorrow), one at each corner of the mouth (up and out for a smile, down
# for grief), "lids" over the eye bone (the eyes narrow, widen or close into the arcs of a laugh) and
# "jaw" over the mouth bone (the mouth opens or thins).  No clip moves them: scripts/faces.gd poses
# them at runtime, over whatever the body is doing, so that every clip can be played with every face.
# The brows and the lips are weighted to them wholly, the skin beneath them partly: the cheek lifts
# with the corner of the mouth and the forehead follows the brow, the way a sculpted face would.
BROW_DY = (0.0265, 0.0225)     # brow line above the eye line (a woman's, a man's)
LIP_X = 0.0145
FACE_BONES = ("brow.L", "brow.R", "lip.L", "lip.R", "lids", "jaw")


def brow_y_of(o):
    return eye_y_of(o) + (BROW_DY[0] if o is not None and o.get("fem") else BROW_DY[1])


def expression_bones(r, o, parent="head"):
    """Add the six bones of expression to rig `r` (the eye and mouth bones hang from "lids" and
    "jaw": make them after this)."""
    ey = HC.y + eye_y_of(o)
    by = HC.y + brow_y_of(o)
    my = HC.y + MOUTH_Y
    for s, sd in ((1, "L"), (-1, "R")):
        r.bone("brow." + sd, (EYE_X * s, by, 0.094), (EYE_X * s, by + 0.03, 0.094), parent)
        r.bone("lip." + sd, (LIP_X * s, my, 0.092), (LIP_X * s, my + 0.03, 0.092), parent)
    r.bone("lids", (0, ey, 0.08), (0, ey + 0.05, 0.08), parent)
    r.bone("jaw", (0, my + 0.001, 0.09), (0, my + 0.03, 0.09), parent)


def expression_weights(f, bone="head"):
    """Weights for the skin of the head: mostly the head bone, and under each brow and round each
    corner of the mouth a share of that bone, falling off smoothly so nothing creases."""
    by = f.eye_y + (BROW_DY[0] if f.fem else BROW_DY[1])

    def fn(p):
        lp = p - HC
        if lp.z < 0.02:
            return {bone: 1.0}
        w = {}
        front = smooth(0.02, 0.06, lp.z)
        for s, sd in ((1, "L"), (-1, "R")):
            if lp.x * s < -0.004:
                continue
            kb = math.exp(-(((lp.x - EYE_X * s) / 0.024) ** 2 + ((lp.y - by - 0.004) / 0.013) ** 2)) * 0.5 * front
            kl = math.exp(-(((lp.x - (LIP_X + 0.008) * s) / 0.021) ** 2 + ((lp.y - MOUTH_Y - 0.004) / 0.019) ** 2)) * 0.55 * front
            side = smooth(-0.004, 0.006, lp.x * s)
            if kb * side > 0.02:
                w["brow." + sd] = kb * side
            if kl * side > 0.02:
                w["lip." + sd] = kl * side
        w[bone] = max(0.0, 1.0 - sum(w.values()))
        return w

    return fn


def head(b, o, bone="head", eye_bone="eyes"):
    """Build the head, neck excluded.  Returns the Face (for hair and hats to fit onto)."""
    f = Face(o)
    # (the Hundred Arms release: the skin under the brows and round the corners of the mouth is
    # sculpted on to the bones of expression, so a cheek rises with a smile: see expression_weights)
    skin = morph_sphere(b, HC, f.shape, f.colour, cls=SKIN, bone=bone, bone_fn=expression_weights(f) if bone == "head" else None, seg=34, rings=26)
    # the face, nose and lips are lit as one smooth shape (an elder's a little less: the age shows)
    b.set_normals(skin, f.shade_normal, 0.92 - 0.3 * (1.0 - f.soft))
    tip = nose(b, f, bone)
    b.set_normals(tip, f.shade_normal, 0.85)
    lips = mouth(b, f, o, bone)
    b.set_normals(lips, f.shade_normal, 0.8)
    ears(b, f, bone)
    eyes(b, f, o, eye_bone, bone)
    if f.age > 0.3:
        wrinkles(b, f, bone)
    return f


def nose(b, f, bone):
    """The anime nose: hardly a nose at all.  A low soft bridge running into a small tip with a touch
    of warmth on it, and a little shadow under it where the nostrils would be (no nostrils).  An
    elder's nose is a little stronger.  Returns the vertices (head() gives them the face's normals,
    so the nose shades with the face and shows as its tip and its shadow)."""
    sk = f.skin
    k = 1.0 + 0.5 * (1.0 - f.soft)
    top = f.surface(0.0, f.eye_y - 0.01)
    tip = f.surface(0.0, NOSE_Y + 0.004)
    tip = tip + Vector((0, 0.0, (0.006 if not f.fem else 0.0045) * k))
    mid = top.lerp(tip, 0.6) + Vector((0, 0, 0.0012 * k))
    pts = [HC + top + Vector((0, 0, -0.004)), HC + mid, HC + tip]
    tipc = mix(sk, "f0a090", 0.22)
    out = b.tube(pts, [(0.003, 0.003), (0.004, 0.0036), (0.0058 * k, 0.005)], sk, cls=SKIN, bone=bone, seg=8, cap0=False, cols=[sk, sk, tipc], mat=MAT_PLAIN)
    # the shadow under the tip
    out += b.ellipsoid(HC + tip + Vector((0.0, -0.0062, -0.003)), (0.0062, 0.0016, 0.004), mix(sk, "b07068", 0.5), cls=SKIN, bone=bone, seg=10, rings=4, mat=MAT_PLAIN)
    return out


def mouth(b, f, o, bone):
    """A small anime mouth low on the face: a fine dark line, its corners turned up a little when
    smiling, a thin upper lip and a lower lip that is mostly a hint of colour (fuller and rosier for
    women).  Returns the lip vertices (they shade with the face)."""
    lip = rgb(o.get("lip", "e0868a" if f.fem else mix(f.skin, "c07a74", 0.45)))
    w = (0.0135 if f.fem else 0.0155) * (1.0 + 0.2 * (1.0 - f.soft))
    y = MOUTH_Y
    upper = []
    lower = []
    line = []
    smile = 1 if o.get("smile", True) else -1
    for i in range(9):
        t = i / 8 - 0.5
        x = t * 2 * w
        sp = f.surface(x, y)
        curve = 0.0028 * (1.0 - (2 * t) ** 2)
        bow = 0.0008 * math.cos(t * 2 * math.pi * 2) * (1.0 - abs(2 * t))
        upper.append(HC + sp + Vector((0, 0.0018 + curve * 0.4 + bow, 0.0028)))
        lower.append(HC + f.surface(x * 0.85, y - 0.0045) + Vector((0, -0.0006 - curve * 0.35, 0.0032)))
        line.append(HC + sp + Vector((0, 0.0004 + 0.0018 * (2 * t) ** 2 * smile, 0.0036)))
    ur = [r * (0.8 if f.fem else 0.6) for r in (0.0008, 0.0012, 0.0016, 0.0018, 0.0017, 0.0018, 0.0016, 0.0012, 0.0008)]
    lr = [r * (1.0 if f.fem else 0.6) for r in (0.0008, 0.0015, 0.0021, 0.0026, 0.0028, 0.0026, 0.0021, 0.0015, 0.0008)]
    # the corners of the mouth ride on the lip bones (the Hundred Arms release): drawn up and out they
    # smile, drawn down they grieve, and the middle of the lips follows them part of the way
    lip_b = line_b = None
    if bone == "head":
        lip_b = []
        line_b = []
        for i in range(9):
            u = i / 4 - 1.0
            c = smooth(0.15, 1.0, abs(u)) * 0.92
            side = "lip.L" if u > 0 else "lip.R"
            lip_b.append({bone: 1.0 - c, side: c} if c > 0.0 else {bone: 1.0})
            line_b.append({"mouth": 1.0 - c, side: c} if c > 0.0 else {"mouth": 1.0})
    out = b.tube(upper, ur, mix(lip, f.skin, 0.45), cls=SKIN, bone=bone, bones=lip_b, seg=6, flat=0.5, up=(0, 0, 1), mat=MAT_PLAIN)
    out += b.tube(lower, lr, mix(lip, f.skin, 0.2) if f.fem else mix(lip, f.skin, 0.45), cls=SKIN, bone=bone, bones=lip_b, seg=6, flat=0.55, up=(0, 0, 1), mat=MAT_PLAIN)
    # the parting line rides on the mouth bone: scaling it tall opens the mouth when speaking
    b.tube(line, [0.0007, 0.0009, 0.001, 0.001, 0.001, 0.001, 0.001, 0.0009, 0.0007], darken(lip, 0.66), cls=SKIN, bone="mouth" if bone == "head" else bone, bones=line_b, seg=5, mat=MAT_PLAIN)
    return out


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
    """Anime eyes set into the (shallow) sockets: the white with the shadow of the upper lid across
    its top, a tall iris that is dark under the lid and bright at the bottom, with a darker rim and a
    lighter crescent, a small pupil of the iris's own deep colour, a large highlight towards the light
    and a small one under it; a dark, heavy upper lash line thickening to a flick at the outer corner
    (with a couple of lashes on a woman's), a fine lower lash on the outer half only, the crease of the
    upper lid, and a thin, long, high eyebrow.  Everything on the eye bone scales with the blink."""
    iris = rgb(o.get("eyes", "3a6ad8"))
    lash = rgb(o.get("lash", "1c1418"))
    hair = rgb(o.get("hair", "1a1a2a"))
    brow_col = rgb(o.get("brow_col", darken(hair, 0.15) if sum(hair) < 2.2 else mix(hair, "8a8070", 0.35)))
    k = f.eye_r
    # an almond opening well under half as tall as it is wide (a woman's a little more open)
    ew, eh = 0.0222 * k, (0.0128 if f.fem else 0.0116) * k
    # everything drawn round the eye (lids, lashes, the depth of the ball) is in proportion to it
    u_ = ew / 0.026
    glow = o.get("glow_eyes", False)
    slit = o.get("slit_eyes", False)
    stern = o.get("stern", False)
    for s in (1, -1):
        cx = EYE_X * s
        cy = f.eye_y
        sp = f.surface(cx, cy)
        nrm = f.normal(cx, cy)
        yaw = math.atan2(nrm.x, nrm.z) * 0.8
        R = Matrix.Rotation(yaw, 3, "Y")
        c = HC + sp + nrm * -0.0018

        def at(u, v, w=0.0):
            return c + R @ Vector((u, v, w))

        # the white: the shadow of the upper lid falls across its top
        b.ellipsoid(c, (ew, eh, 0.0065 * u_), "d0d4e2", cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=10, mat=MAT_PLAIN, col2="fbfbff")
        # iris: tall, a darker rim, dark under the lid and bright at the bottom
        # (round, as an iris is: the upper lid covers its top, and the white shows on both sides of it)
        ir = eh * 0.97
        icen = at(0.0, eh * 0.03, 0.0056 * u_)
        b.ellipsoid(icen, (ir * 0.98, ir, 0.0022), darken(iris, 0.66), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=8, mat=MAT_PLAIN)
        b.ellipsoid(icen + R @ Vector((0, -ir * 0.04, 0.0006)), (ir * 0.86, ir * 0.88, 0.0022), darken(iris, 0.42), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=18, rings=8,
                    mat=MAT_GLOW if glow else MAT_PLAIN, col2=lighten(iris, 0.2))
        # the bright crescent at the bottom of the iris, and a ring of lighter colour inside the rim
        b.ellipsoid(icen + R @ Vector((0, -ir * 0.46, 0.0012)), (ir * 0.6, ir * 0.3, 0.0016), lighten(iris, 0.35), cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=14, rings=6, mat=MAT_PLAIN)
        # pupil: small, of the iris's own deepest colour
        if slit:
            b.ellipsoid(icen + R @ Vector((0, 0, 0.0016)), (ir * 0.16, ir * 0.72, 0.0016), "0c0810", cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=10, rings=6, mat=MAT_PLAIN)
        else:
            b.ellipsoid(icen + R @ Vector((0, ir * 0.06, 0.0016)), (ir * 0.38, ir * 0.38, 0.0016), mix(darken(iris, 0.85), "0c0812", 0.7), cls=SKIN, bone=eye_bone, rot=(0, yaw, 0), seg=12, rings=6, mat=MAT_PLAIN)
        # one small highlight towards the light (up and out): the window in a living eye
        b.ellipsoid(icen + R @ Vector((ir * 0.34 * s, ir * 0.3, 0.0025)), (ir * 0.17, ir * 0.17, 0.0012), "ffffff", cls=CRYSTAL, bone=eye_bone, rot=(0, yaw, 0), seg=8, rings=4, mat=MAT_GLOW)
        # upper lid: a skin shell over the top of the eyeball
        lid = []
        for i in range(9):
            t = i / 8
            a = math.pi * (1.0 - t)
            lid.append(at(math.cos(a) * ew * 1.04, math.sin(a) * eh * 0.5 + eh * 0.56, (0.0045 + 0.002 * math.sin(a)) * u_))
        b.tube(lid, [r * u_ for r in (0.0024, 0.003, 0.0034, 0.0036, 0.0036, 0.0036, 0.0034, 0.003, 0.0024)], f.skin, cls=SKIN, bone=eye_bone, seg=6, flat=0.6, up=(0, 0, 1), mat=MAT_PLAIN)
        # upper lash line: heavy and dark, lifting to a flick past the outer corner
        ul = []
        rad = []
        for i in range(12):
            t = i / 11
            u = (t - 0.5) * 2.0          # -1 inner .. +1 outer (mirrored by s)
            x = u * ew * 1.08 * s
            y = eh * (0.78 - 0.36 * u * u) + eh * 0.16 * u
            ul.append(at(x, y, (0.0066 - 0.002 * u * u) * u_))
            # (a line, not a wing: thin at the inner corner, a little heavier over the outer half)
            rad.append((0.0009 + 0.0009 * math.sin(math.pi * clamp(t * 0.85 + 0.12)) + (0.0005 * smooth(0.6, 1.0, t) if f.fem else 0.0001 * smooth(0.6, 1.0, t))) * u_)
        flick = (0.0032 if f.fem else 0.0012) * u_
        ul.append(at(ew * 1.2 * s, eh * 0.3 + flick * 0.55, 0.0042 * u_))
        rad.append(0.0005 * u_)
        b.tube(ul, rad, lash, cls=HAIR, bone=eye_bone, seg=6, flat=0.62, up=(0, 0, 1), mat=MAT_PLAIN)
        if f.fem:
            # two lashes off the outer corner
            for j, (u0, ln) in enumerate(((0.62, 0.0026 * u_), (0.86, 0.0036 * u_))):
                root = at(u0 * ew * s, eh * (0.78 - 0.36 * u0 * u0) + eh * 0.16 * u0 + 0.0006, 0.0062 * u_)
                b.tube([root, root + R @ Vector((ln * 0.7 * s, ln * 0.55, 0.0)), root + R @ Vector((ln * 1.1 * s, ln * 0.8, -0.001))], [0.0007 * u_, 0.0005 * u_, 0.0002], lash, cls=HAIR, bone=eye_bone, seg=4, mat=MAT_PLAIN)
        # lower lash line: fine, on the outer half only
        ll = [at(((i / 6) * 0.62 + 0.36) * ew * s, -eh * (0.76 - 0.3 * ((i / 6) - 0.2) ** 2), 0.0055 * u_) for i in range(7)]
        b.tube(ll, [0.0003, 0.0004, 0.0005, 0.0005, 0.0005, 0.0005, 0.0003], mix(lash, f.skin, 0.55), cls=HAIR, bone=eye_bone, seg=5, mat=MAT_PLAIN)
        # lid crease
        cr = [at(((i / 5) * 1.2 - 0.3) * ew * s, eh * (1.3 - 0.2 * ((i / 5) - 0.45) ** 2), 0.004 * u_) for i in range(6)]
        b.tube(cr, [0.0002, 0.0003, 0.0004, 0.0004, 0.0003, 0.0002], darken(f.skin, 0.2), cls=SKIN, bone=bone, seg=5, mat=MAT_PLAIN)
        # eyebrow: thin, long and high, tapering to a fine tail; lower and angled down for stern faces
        bp = []
        for i in range(7):
            t = i / 6
            x = (EYE_X - 0.02 + t * 0.047) * s
            # (over the socket, an eye's height above the lid: nearer a man's eye than a woman's)
            y = f.eye_y + (0.0265 if f.fem else 0.0225) + 0.005 * math.sin(math.pi * t) - (0.007 * (1.0 - t) if stern else 0.0) - 0.004 * t
            sp2 = f.surface(x, y)
            bp.append(HC + sp2 + f.normal(x, y) * 0.0018)
        b.tube(bp, [r * (1.0 if f.fem else 1.35) for r in (0.0019, 0.0024, 0.0023, 0.002, 0.0016, 0.0011, 0.0005)], brow_col, cls=HAIR, bone=("brow.L" if s > 0 else "brow.R") if bone == "head" else bone, seg=6, flat=0.45, up=(0, 0, 1), mat=MAT_PLAIN)


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
    radii = [(0.062, 0.058), (0.054, 0.052), (0.051, 0.052), (0.05, 0.053)] if not f.fem else [(0.052, 0.048), (0.042, 0.041), (0.04, 0.041), (0.04, 0.043)]
    # the head's shadow on the neck under the chin, painted the anime way (a rosy band, not grey)
    b.tube(pts, radii, sk, cls=SKIN, bones=bones, seg=16, cols=[darken(sk, 0.1), sk, mix(sk, "c98478", 0.38), mix(sk, "c07a70", 0.5)])
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

