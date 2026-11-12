"""Bird anatomy shared by the winged monsters: ``phoenix.py`` (the phoenix and every other "bird" of the
game: hawks, cranes, herons, crows, swallows), ``magpie.py``, ``sun_crow.py`` and ``bifang.py``.

Built after the references (README, References: bird topography, raptor and corvid field marks, the
fenghuang, the golden pheasant, the red-crowned crane, "silhouette, then value, then colour"):

* **Silhouette first.**  The body is an egg - a deep keeled breast, a straight back sloping to the
  rump - and the neck is an S *hidden in the plumage*, so the head sits on the body (crows, magpies,
  hawks) or rises on a feathered column (the pheasant-like phoenix, the crane); never a bare tube.
* **The wing is the bird.**  Solid layered feather groups as on a real wing: a rounded leading edge
  (the marginal and lesser coverts over the arm), a row of median and a row of greater coverts, the
  secondaries along the forearm, three tertials at the elbow, the primaries fanned from the hand with
  their coverts over the roots and the alula at the wrist.  Each feather is a solid vane rolled a
  little so its outer edge rides under the next inner one (the innermost feather lies on top, the
  outermost primary at the bottom), so the wing reads as one shingled surface with a scalloped trailing
  edge; the outer primaries of the broad wings are emarginated, so the spread hand ends in slotted
  "fingers".  Every flight feather has a bone of its own: the wing folds the way a bird's does (the
  arm back along the flank, the forearm forward, the hand back again, every feather turning about its
  own quill to lie back along the body, the primaries under the secondaries) and flexes on the
  upstroke of each wingbeat.
* **A characterful head.**  A skull with a brow ridge over a large eye (the raptor's "fierce look"), a
  lofted beak (a hooked bill over a cere, a crow's heavy bill under its nasal bristles, a crane's
  dagger), the lower mandible on the jaw; the eye in its own colour (amber, gold, dark brown).
* **Value before colour.**  Darker back and wings, a pale throat, breast and belly, dark points
  (primaries, tail tips); the coat pass turns the pale greys into the palette's underside colour and
  the dark into its markings.  No spots: the plumage is smooth, and feathering shows where a painter
  would put it (the cape of hackles, the scapulars, the wing, the tail).

Styles:
* "phoenix": the fenghuang after its Ming pictures and the golden pheasant - a raptor-billed head
  with a crest of backswept plumes, a cape of rounded feathers laid over the nape and shoulders,
  broad fingered wings and a tail fan under five long plumes (three long, two shorter) that stream
  back and down, twisting to stand on edge so their flags and eyes show from the side.
* "magpie": the magpie of the bridge (Pica pica) - a crow's head and bill, black hood and back, a
  white belly and white scapulars, white flashes on the primaries, glossy secondaries and a long
  graduated tail.
* "sun_crow": Jinwu, the three-legged crow of the sun in the Han pictures - a raven's heavy bill and
  shaggy throat, three legs, a wedge tail, flame-tipped flight feathers and a flaming halo of the sun
  behind it.
* "bifang": the one-legged crane of the Classic of Mountains and Seas (Strassberg, A Chinese
  Bestiary: crane-like, one leg, red markings on a blue-green body, a white beak) - a crane's long
  S-neck and dagger bill, a red crown, red bars on the coverts, a bustle of long tertials over the
  tail, standing on its single leg with its wings folded, flames along the bustle and the primaries.

``build()`` returns the Builder, the rig and the clips (idle, walk, attack, hurt, die, cast).
Hovering birds hover and flap; the bifang stands and hops on its one leg.  A dying bird turns about
its own body, not about the ground under it: a small solve lays its spread wings on the ground, and
a frame that would sink a wing tip, a talon or the fallen sun into the ground is lifted clear, so
every death ends lying on the ground.
"""
import math

from mathutils import Matrix, Quaternion

import anatomy as A
from clay import Clay, limb_weights
from creature import Poser, add, euler_yxz, leg_ik, smooth, zero_pose
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, MAT_TOON, SKIN, STONE, V, Builder, Rig, euler_g, mix, rgb
from sculpt import catmull, loft, prof_d, prof_ellipse, section

# where a fallen bird's body comes to rest: the height of its middle above the ground, in S
DIE_REST = {"phoenix": 0.17, "magpie": 0.17, "sun_crow": 0.17, "bifang": 0.19}

STYLES = {
    "phoenix": dict(S=1.0, Y=1.45, neck="pheasant", beak="hook", legs=2, tail="plumes", crest="plumes", wing="eagle", head=1.15),
    "magpie": dict(S=0.85, Y=1.35, neck="short", beak="crow", legs=2, tail="long", crest=None, wing="corvid", head=1.05),
    "sun_crow": dict(S=1.15, Y=1.55, neck="short", beak="raven", legs=3, tail="wedge", crest=None, wing="corvid", head=1.05),
    "bifang": dict(S=1.0, Y=1.02, neck="crane", beak="crane", legs=1, tail="bustle", crest="crown", wing="crane", head=0.9),
}

# arm bone lengths, flight feathers (count, length, half-width), how many outer primaries are notched
# into fingers, and how far the spread hand fans
WINGS = {
    "eagle": dict(hum=0.29, fore=0.35, hand=0.2, np=10, Lp=0.66, wp=0.058, ns=11, Ls=0.43, ws=0.053, nt=3, Lt=0.36, fingers=6, notch=0.32, fan=1.42),
    "corvid": dict(hum=0.25, fore=0.3, hand=0.17, np=10, Lp=0.54, wp=0.048, ns=10, Ls=0.36, ws=0.047, nt=3, Lt=0.3, fingers=5, notch=0.4, fan=1.4),
    "crane": dict(hum=0.31, fore=0.39, hand=0.2, np=10, Lp=0.6, wp=0.05, ns=12, Ls=0.45, ws=0.05, nt=4, Lt=0.62, fingers=5, notch=0.34, fan=1.36),
}


# ---------------------------------------------------------------- small helpers
def frame(d, n):
    """An orthonormal frame (columns: d, n made square to d, d x n)."""
    d = V(d).normalized()
    n = V(n)
    n = (n - d * n.dot(d)).normalized()
    return Matrix((d, n, d.cross(n))).transposed()


def turn(d0, n0, d1, n1):
    """The rotation taking direction d0 (its 'up' n0) onto d1 (its 'up' n1)."""
    return frame(d1, n1) @ frame(d0, n0).transposed()


def put(p, nm, M, loc=(0.0, 0.0, 0.0)):
    """Set bone nm of pose p to the local rotation matrix M (and an offset)."""
    if nm in p:
        p[nm] = (euler_yxz(M), tuple(loc))


def qslerp(M, k):
    """The rotation M taken a share k of the way from the identity."""
    return Quaternion().slerp(M.to_quaternion(), max(0.0, min(1.0, k))).to_matrix()


def _vane(t, shape="round", notch=0.0):
    """Half-width of a feather vane (1 at its broadest) at t (0 quill .. 1 tip)."""
    w = 0.34 + 0.66 * smooth(0.0, 0.24, t)
    if shape == "round":
        e = max(0.0, t - 0.58) / 0.42
        w *= math.sqrt(max(0.0, 1.0 - e * e))
    elif shape == "blunt":
        e = max(0.0, t - 0.78) / 0.22
        w *= math.sqrt(max(0.0, 1.0 - e * e))
    elif shape == "point":
        w *= 1.0 - 0.97 * smooth(0.4, 1.0, t)
    elif shape == "hackle":
        w *= 1.0 - 0.97 * smooth(0.15, 1.0, t)
    elif shape == "plume":
        # a long plume: narrow along the shaft, opening into a broad rounded flag at the end
        w = 0.35 + 0.25 * smooth(0.0, 0.2, t) + 0.55 * smooth(0.55, 0.85, t)
        e = max(0.0, t - 0.86) / 0.14
        w *= math.sqrt(max(0.0, 1.0 - e * e))
    if notch:
        w *= 1.0 - notch * smooth(0.4, 0.56, t)
    return w


def quill(b, root, d, up, length, width, col, col_tip=None, bone=None, tint=1.0, curl=0.05, sweep=0.0, shape="round", notch=0.0,
          thick=0.12, seg=8, steps=8, back=0.0, cols=None, cls=HAIR, mat=MAT_TOON, bend=None):
    """A solid feather: a flattened vane from a narrow quill at `root` along `d`, its upper surface
    facing `up`, arching down along its length (`curl` x length at the tip), bending sideways
    (`sweep`, towards d x up) and shaped by `shape` (see ``_vane``); `notch` emarginates it (the
    vane steps in half way out, as on the outer primaries of eagles and crows).  `back` shifts the
    vane off the shaft (flight feathers have a narrow leading vane).  `cols` is a colour per step or
    a function of t; `bend` an optional function t -> offset Vector (S-curved plumes)."""
    root = V(root)
    d = V(d).normalized()
    up = V(up)
    up = (up - d * up.dot(d)).normalized()
    sv = d.cross(up)
    L = length
    pts = []
    for j in range(steps + 1):
        t = j / steps
        q = root + d * (L * t) - up * (curl * L * t * t) + sv * (sweep * L * t * t)
        if bend is not None:
            q = q + V(bend(t))
        pts.append(q)
    rings = []
    rcols = []
    for j, c in enumerate(pts):
        t = j / steps
        tan = (pts[min(steps, j + 1)] - pts[max(0, j - 1)]).normalized()
        u = (up - tan * up.dot(tan)).normalized()
        w = width * _vane(t, shape, notch)
        h = max(0.0006, min(w, width * 0.7) * thick)
        w = max(w, 0.0009)
        side = tan.cross(u)
        rings.append(section(c + side * (back * w), tan, prof_ellipse(w, h), seg, up=u))
        if cols is not None:
            rcols.append(cols(t) if callable(cols) else cols[min(len(cols) - 1, j)])
        else:
            rcols.append(mix(col, col_tip, t ** 1.4) if col_tip is not None else rgb(col))
    return loft(b, rings, col, cls=cls, cols=rcols, bone=bone, tint=tint, mat=mat, cap0=True, cap1=True, cap_push=0.25)


def airfoil_band(b, pts, chord, thick, fwd, up, bones, col_fn, tint=1.0, cls=HAIR, n=14):
    """The leading edge of a wing: a lofted airfoil (round leading edge, thin trailing edge) along
    `pts` with a chord, thickness, forward and up direction per point; `col_fn(p)` paints it."""
    rings = []
    rb = []
    for i, P in enumerate(pts):
        f = V(fwd[i]).normalized()
        u = V(up[i])
        u = (u - f * u.dot(f)).normalized()
        ring = []
        for k in range(n):
            a = 2 * math.pi * k / n
            x = math.cos(a)
            y = math.sin(a)
            xc = chord[i] * (0.3 * x if x > 0 else 0.7 * x)
            taper = 0.3 + 0.7 * (1.0 + x) * 0.5
            yc = thick[i] * (0.5 if y > 0 else 0.28) * y * taper
            ring.append(P + f * xc + u * yc)
        rings.append(ring)
        rb.append(bones[i])
    return loft(b, rings, (0.8, 0.8, 0.8), cls=cls, bones=rb, tint=tint, col_fn=lambda p, j, i: col_fn(p), cap0=True, cap1=True, cap_push=0.4)


def orient(d, up):
    """Godot Euler angles of the frame whose +Z runs along d and +Y as near `up` as it can."""
    z = V(d).normalized()
    y = V(up)
    y = (y - z * y.dot(z)).normalized()
    x = y.cross(z)
    return euler_yxz(Matrix((x, y, z)).transposed())


def beak(b, hf, S, path_up, rad_up, path_lo, rad_lo, col0, col1, jaw="jaw", head="head", tint=0.0, cls=STONE, seg=12, flat_up=0.75, flat_lo=0.6):
    """A two-part bill: the upper mandible lofted along `path_up` (head-frame points, x 0) with a
    rounded culmen and a flatter underside, the lower along `path_lo` on the jaw bone with a keel
    below and a flat top.  `rad_*` = [(half width, half height), ...] per point."""
    def run(path, rad, bone, flip, flat):
        pts = [hf.at(x * S, y * S, z * S) for (x, y, z) in path]
        n = len(pts)
        rings = []
        cols = []
        for i, c in enumerate(pts):
            d = (pts[min(n - 1, i + 1)] - pts[max(0, i - 1)]).normalized()
            up = hf.u * (-1.0 if flip else 1.0)
            rw, rh = rad[i]
            rings.append(section(c, d, prof_d(max(rw * S, 0.0008), max(rh * S, 0.0008), flat), seg, up=up))
            cols.append(mix(col0, col1, (i / (n - 1)) ** 1.5))
        return loft(b, rings, col0, cls=cls, cols=cols, bone=bone, tint=tint, cap0=True, cap1=True, cap_push=0.3)

    up = run(path_up, rad_up, head, False, flat_up)
    lo = run(path_lo, rad_lo, jaw, True, flat_lo)
    return up, lo


# ---------------------------------------------------------------- the wing
class Wing:
    """One wing: arm bones, a bone per flight feather, the feather layout in the spread (gliding)
    rest pose and the rotations that fold it along the flank."""

    def __init__(self, r, sd, s, S, sh, spec, cf):
        self.r = r
        self.sd = sd
        self.s = s
        self.S = S
        self.k = spec
        self.b1, self.b2, self.b3 = "wing.%s" % sd, "wing2.%s" % sd, "wing3.%s" % sd
        k = spec
        # the gliding wing: the humerus angled back, the forearm forward (the wrist leads the leading
        # edge), the hand swept back; a slight dihedral
        el = sh + V(0.94 * s, 0.1, -0.32).normalized() * (k["hum"] * S)
        wr = el + V(0.97 * s, 0.05, 0.24).normalized() * (k["fore"] * S)
        tp = wr + V(0.95 * s, 0.02, -0.3).normalized() * (k["hand"] * S)
        self.sh, self.el, self.wr, self.tp = sh, el, wr, tp
        r.bone(self.b1, sh, el, "body")
        r.bone(self.b2, el, wr, self.b1)
        r.bone(self.b3, wr, tp, self.b2)
        self.up0 = V(-0.1 * s, 1.0, 0.0).normalized()
        self.flight = []   # (bone, parent, root, dir, up, length, width, kind, index, count)
        self._layout()

    def _roll(self, d, up, ang):
        """Roll a feather's surface about its shaft so its outer edge rises (the inner neighbour
        then lies on top)."""
        sv = d.cross(up).normalized()
        return (up * math.cos(ang) - sv * (self.s * math.sin(ang))).normalized()

    def _layout(self):
        k = self.k
        S, s = self.S, self.s
        sh, el, wr, tp = self.sh, self.el, self.wr, self.tp
        up0 = self.up0
        hand = (tp - wr).normalized()
        trail = (-s * hand.cross(up0)).normalized()
        np_, ns, nt = k["np"], k["ns"], k["nt"]
        # primaries, p1 (inner, by the wrist) .. p10 (outer, at the tip of the hand)
        for i in range(np_):
            u = i / (np_ - 1)
            root = wr.lerp(tp, 0.06 + 0.94 * u ** 0.85) + V(0, -0.0045 * S * i, 0)
            ang = 0.1 + (k["fan"] - 0.1) * (1.0 - u) ** 1.25
            d = (hand * math.cos(ang) + trail * math.sin(ang)).normalized()
            d = (d - up0 * 0.05).normalized()
            L = k["Lp"] * S * (0.66 + 0.34 * smooth(0.0, 0.62, u) - 0.07 * smooth(0.82, 1.0, u))
            w = k["wp"] * S * (1.0 - 0.18 * u)
            up = self._roll(d, up0, 0.2)
            nm = "pri%d.%s" % (i, self.sd)
            self.r.bone(nm, root, root + d * (L * 0.5), self.b3)
            fing = i >= np_ - k["fingers"]
            self.flight.append(dict(bone=nm, parent=self.b3, root=root, d=d, up=up, L=L, w=w, kind="pri", i=i, n=np_,
                                    notch=k["notch"] * smooth(np_ - k["fingers"] - 1.0, np_ - 1.0, i) if fing else 0.0))
        # secondaries along the forearm, s1 by the wrist .. the innermost by the elbow
        for i in range(ns):
            u = i / (ns - 1)
            root = wr.lerp(el, 0.03 + 0.93 * u) + V(0, 0.003 * S + 0.0018 * S * i, -0.012 * S)
            d = V(0.24 * s * (1.0 - u) ** 1.5, -0.06, -1.0).normalized()
            L = k["Ls"] * S * (1.0 - 0.07 * u)
            w = k["ws"] * S
            up = self._roll(d, up0, 0.22)
            nm = "sec%d.%s" % (i, self.sd)
            self.r.bone(nm, root, root + d * (L * 0.5), self.b2)
            self.flight.append(dict(bone=nm, parent=self.b2, root=root, d=d, up=up, L=L, w=w, kind="sec", i=i, n=ns, notch=0.0))
        # tertials on the humerus by the elbow
        for i in range(nt):
            u = i / max(1, nt - 1)
            root = el.lerp(sh, 0.1 + 0.42 * u) + V(0, 0.02 * S + 0.004 * S * i, -0.012 * S)
            d = V(-0.06 * s * u, -0.08, -1.0).normalized()
            L = k["Lt"] * S * (1.0 - 0.12 * u)
            w = k["ws"] * S * 1.1
            up = self._roll(d, up0, 0.2)
            nm = "ter%d.%s" % (i, self.sd)
            self.r.bone(nm, root, root + d * (L * 0.5), self.b1)
            self.flight.append(dict(bone=nm, parent=self.b1, root=root, d=d, up=up, L=L, w=w, kind="ter", i=i, n=nt, notch=0.0))

    # ---- geometry
    def build(self, b, paint, slot=0.5, fire=None):
        """paint(kind, i, n) -> (col_root, col_tip, tint, cols or None[, palette slot]) for each
        feather kind: "pri", "sec", "ter", "gcov", "mcov", "pcov", "alula", "band"."""
        S, s = self.S, self.s
        old = b.cur_pal

        def pick(kind, i, n):
            pr = paint(kind, i, n)
            b.cur_pal = pr[4] if len(pr) > 4 else slot
            return pr[:4]

        for f in self.flight:
            c0, c1, tn, cols = pick(f["kind"], f["i"], f["n"])
            bustle = f["kind"] == "ter" and self.k.get("bustle")
            quill(b, f["root"], f["d"], f["up"], f["L"], f["w"], c0, c1, bone=f["bone"], tint=tn, cols=cols,
                  curl=(0.2 if bustle else 0.08) if f["kind"] == "ter" else 0.05, notch=f["notch"], shape="round",
                  back=0.18 if f["kind"] in ("pri", "sec") else 0.0, seg=8, steps=8)
            if fire is not None:
                fire(f)
        # coverts: a greater and a median covert over each secondary (they fold with it), a covert
        # over each inner primary, the alula at the wrist
        for f in self.flight:
            if f["kind"] == "sec":
                for row, (lk, off, wk) in enumerate(((0.44, 0.022, 1.05), (0.27, 0.042, 1.0))):
                    kind = "gcov" if row == 0 else "mcov"
                    c0, c1, tn, cols = pick(kind, f["i"], f["n"])
                    lift = V(0, (0.012 + 0.008 * row) * S + 0.0015 * S * f["i"], 0)
                    root = f["root"] + V(0, 0, off * S * (1.0 + 0.4 * row)) + lift
                    quill(b, root, f["d"], self._roll(f["d"], self.up0, 0.26), f["L"] * lk, f["w"] * wk, c0, c1, bone=f["bone"],
                          tint=tn, cols=cols, curl=0.04, shape="round", seg=7, steps=6)
            elif f["kind"] == "pri" and f["i"] < f["n"] - 1:
                c0, c1, tn, cols = pick("pcov", f["i"], f["n"])
                hand = (self.tp - self.wr).normalized()
                root = f["root"] + V(0, 0.012 * S, 0) + hand.cross(self.up0).normalized() * (0.012 * S * s)
                quill(b, root, f["d"], self._roll(f["d"], self.up0, 0.24), f["L"] * 0.3, f["w"] * 1.05, c0, c1, bone=f["bone"],
                      tint=tn, cols=cols, curl=0.04, shape="round", seg=7, steps=6)
        hand = (self.tp - self.wr).normalized()
        lead = (s * hand.cross(self.up0)).normalized()
        for i in range(3):
            c0, c1, tn, cols = pick("alula", i, 3)
            root = self.wr + V(0, 0.02 * S, 0) + lead * (0.02 * S) - hand * (0.01 * S * i)
            d = (hand * 0.92 + lead * 0.25 - self.up0 * 0.04).normalized()
            quill(b, root, d, self._roll(d, self.up0, 0.15), (0.15 - 0.03 * i) * S, 0.022 * S, c0, c1, bone=self.b3, tint=tn,
                  cols=cols, curl=0.03, shape="round", seg=6, steps=6)
        # the leading edge: marginal and lesser coverts over the arm, a rounded airfoil from the
        # shoulder (inside the body) out to the wrist
        pts, chord, thick, fwd, ups, bones = [], [], [], [], [], []
        arm = [self.sh - V(0.05 * s, 0.0, 0.0) * S, self.sh, self.el, self.wr, self.wr + hand * (0.035 * S)]
        n_seg = [3, 6, 7, 2]
        for a in range(4):
            for j in range(n_seg[a] + (1 if a == 3 else 0)):
                t = j / n_seg[a]
                q = arm[a].lerp(arm[a + 1], t)
                pts.append(q)
                g = (len(pts) - 1)
                tot = sum(n_seg)
                u = g / tot
                chord.append((0.2 - 0.11 * u) * S)
                thick.append((0.075 - 0.042 * u) * S)
                fd = V(0.1 * s * (1.0 - u), 0.0, 1.0) if a < 2 else (V(-0.25 * s, 0.0, 1.0) if a == 2 else lead)
                fwd.append(fd)
                ups.append(self.up0)
                if a == 0:
                    bones.append({"body": 1.0 - 0.5 * t, self.b1: 0.5 * t})
                elif a == 1:
                    bones.append({"body": 0.5 * (1.0 - smooth(0.0, 0.5, t)), self.b1: 1.0 - 0.5 * (1.0 - smooth(0.0, 0.5, t)) - 0.5 * smooth(0.7, 1.0, t), self.b2: 0.5 * smooth(0.7, 1.0, t)})
                elif a == 2:
                    bones.append({self.b1: 0.5 * (1.0 - smooth(0.0, 0.3, t)), self.b2: 1.0 - 0.5 * (1.0 - smooth(0.0, 0.3, t)) - 0.5 * smooth(0.75, 1.0, t), self.b3: 0.5 * smooth(0.75, 1.0, t)})
                else:
                    bones.append({self.b2: 0.5 * (1.0 - t), self.b3: 0.5 + 0.5 * t})
        c0, c1, tn, cols = pick("band", 0, 1)
        airfoil_band(b, pts, chord, thick, fwd, ups, bones, lambda p: c0, tint=tn)
        b.cur_pal = old

    # ---- folding
    def fold_rots(self):
        """Local rotations (3x3) of the arm and feather bones that fold the wing along the flank,
        and the offset that sets the folded wing off the body."""
        s = self.s
        nf = V(s, 0.12, 0.0).normalized()

        def inplane(v):
            v = V(v)
            return (v - nf * v.dot(nf)).normalized()

        W = {}
        W[self.b1] = turn(self.el - self.sh, self.up0, inplane((0.0, -0.4, -1.0)), nf)
        W[self.b2] = turn(self.wr - self.el, self.up0, inplane((0.0, 0.12, 1.0)), nf)
        W[self.b3] = turn(self.tp - self.wr, self.up0, inplane((0.0, -0.05, -1.0)), nf)
        out = {self.b1: W[self.b1], self.b2: W[self.b1].transposed() @ W[self.b2], self.b3: W[self.b2].transposed() @ W[self.b3]}
        for f in self.flight:
            u = f["i"] / max(1, f["n"] - 1)
            if f["kind"] == "pri":
                dt = (0.0, -0.1 - 0.06 * (1.0 - u) - (0.14 if self.k.get("bustle") else 0.0), -1.0)
            elif f["kind"] == "sec":
                dt = (0.0, -0.22 - 0.2 * u, -1.0)
            else:
                dt = (0.0, -0.3 - 0.25 * u, -1.0) if self.k.get("bustle") else (0.0, -0.2 - 0.1 * u, -1.0)
            Wf = turn(f["d"], f["up"], inplane(dt), nf)
            out[f["bone"]] = W[f["parent"]].transposed() @ Wf
        return out


# ---------------------------------------------------------------- the bird
def build(name="phoenix", style="phoenix"):
    cf = STYLES[style]
    S = cf["S"]
    Y = cf["Y"]
    C = V(0, Y, 0)
    stand = style == "bifang"
    HS = cf["head"]
    wk = dict(WINGS[cf["wing"]])
    if style == "bifang":
        wk["bustle"] = True
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.3, 0))
    r.bone("body", C + V(0, 0, -0.22 * S), C + V(0, 0.03 * S, 0.2 * S), "root")

    # ---------------------------------------------------------------- neck and head positions
    neck = cf["neck"]
    if neck == "pheasant":
        NK = [C + V(0, 0.08, 0.16) * S, C + V(0, 0.17, 0.22) * S, C + V(0, 0.25, 0.21) * S, C + V(0, 0.3, 0.26) * S]
        fwd = V(0, -0.12, 1.0)
    elif neck == "short":
        NK = [C + V(0, 0.07, 0.15) * S, C + V(0, 0.12, 0.2) * S, C + V(0, 0.155, 0.24) * S, C + V(0, 0.17, 0.29) * S]
        fwd = V(0, -0.1, 1.0)
    else:  # crane: a long S
        NK = [C + V(0, 0.07, 0.2) * S, C + V(0, 0.3, 0.3) * S, C + V(0, 0.52, 0.22) * S, C + V(0, 0.66, 0.3) * S]
        fwd = V(0, -0.18, 1.0)
    r.bone("neck0", NK[0], NK[1], "body")
    r.bone("neck1", NK[1], NK[2], "neck0")
    HC = NK[3] + V(0, 0.01, 0.02) * S
    hf = A.HeadFrame(HC, fwd)
    HK = S * HS

    def hp(x, y, z):
        return hf.at(x * HK, y * HK, z * HK)

    r.bone("head", NK[2], hp(0, 0, 0.16), "neck1")
    r.bone("jaw", hp(0, -0.022, 0.05), hp(0, -0.03, 0.2), "head")

    # ---------------------------------------------------------------- wings
    wings = {}
    for s, sd in ((1, "L"), (-1, "R")):
        sh = C + V(0.11 * s, 0.085, 0.07) * S
        wings[sd] = Wing(r, sd, s, S, sh, wk, cf)

    # ---------------------------------------------------------------- legs
    LEGS = []
    leg_sides = {1: [(0, "C")], 2: [(1, "L"), (-1, "R")], 3: [(1, "L"), (-1, "R"), (0, "C")]}[cf["legs"]]
    for s, sd in leg_sides:
        zoff = -0.07 * S if (sd == "C" and cf["legs"] == 3) else 0.0
        hip = C + V((0.085 if cf["legs"] == 3 else 0.07) * s, -0.06, -0.02) * S + V(0, 0, zoff)
        if stand:
            kn = hip + V(0.0, -0.12, 0.1) * S
            ank = V(hip.x, 0.46 * S, hip.z - 0.04 * S)
            ball = V(hip.x, 0.03, hip.z + 0.02 * S)
            toe = ball + V(0, -0.01, 0.13) * S
        else:
            kn = hip + V(0.01 * s, -0.11, 0.07) * S
            ank = kn + V(0.0, -0.17, -0.1) * S
            ball = ank + V(0, -0.11, 0.03) * S
            toe = ball + V(0, -0.02, 0.09) * S
        r.bone("leg.%s" % sd, hip, kn, "body")
        r.bone("shin.%s" % sd, kn, ank, "leg.%s" % sd)
        r.bone("tars.%s" % sd, ank, ball, "shin.%s" % sd)
        r.bone("toe.%s" % sd, ball, toe, "tars.%s" % sd)
        LEGS.append((s, sd, hip, kn, ank, ball, toe))

    # ---------------------------------------------------------------- tail chain
    tail = cf["tail"]
    T0 = C + V(0, 0.01, -0.27) * S
    if tail == "plumes":
        TL = [T0, T0 + V(0, 0.03, -0.3) * S, T0 + V(0, -0.04, -0.62) * S, T0 + V(0, -0.16, -0.94) * S, T0 + V(0, -0.25, -1.24) * S, T0 + V(0, -0.2, -1.5) * S]
    elif tail == "long":
        TL = [T0, T0 + V(0, -0.02, -0.3) * S, T0 + V(0, -0.06, -0.62) * S, T0 + V(0, -0.11, -0.95) * S]
    elif tail == "wedge":
        TL = [T0, T0 + V(0, -0.02, -0.18) * S, T0 + V(0, -0.04, -0.36) * S, T0 + V(0, -0.06, -0.54) * S]
    else:
        TL = [T0, T0 + V(0, -0.04, -0.12) * S, T0 + V(0, -0.08, -0.24) * S, T0 + V(0, -0.12, -0.36) * S]
    NT = len(TL) - 1
    for i in range(NT):
        r.bone("tail%d" % i, TL[i], TL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))
    tail_names = ["tail%d" % i for i in range(NT)]

    b = Builder(name)
    probes = []      # (bone, rest point): where the bird touches the ground when it falls

    # ---------------------------------------------------------------- plumage values
    # (greys on the dominant slot: the coat pass turns the pale into the underside colour and the
    # dark into the markings)
    if style == "phoenix":
        V_BACK, V_UNDER, V_HEAD = 0.8, 0.97, 0.86
    elif style == "magpie":
        V_BACK, V_UNDER, V_HEAD = 0.24, 0.97, 0.22
    elif style == "sun_crow":
        V_BACK, V_UNDER, V_HEAD = 0.84, 0.95, 0.8
    else:
        V_BACK, V_UNDER, V_HEAD = 0.8, 0.97, 0.84

    # ---------------------------------------------------------------- body clay
    c = Clay(0.013 * S, name + "_body")
    if style == "bifang":
        # a crane's body: long, slim and level, a little deeper at the breast
        c.ellipsoid(C + V(0, -0.0, 0.08) * S, (0.13 * S, 0.14 * S, 0.17 * S), bones={"body": 1.0}, tag="breast")
        c.ellipsoid(C + V(0, 0.02, -0.08) * S, (0.13 * S, 0.11 * S, 0.24 * S), bones={"body": 1.0}, tag="back")
        c.ellipsoid(C + V(0, -0.05, -0.08) * S, (0.11 * S, 0.1 * S, 0.18 * S), bones={"body": 1.0}, tag="belly")
    else:
        c.ellipsoid(C + V(0, -0.01, 0.07) * S, (0.145 * S, 0.165 * S, 0.18 * S), bones={"body": 1.0}, tag="breast")
        c.ellipsoid(C + V(0, 0.045, -0.04) * S, (0.13 * S, 0.085 * S, 0.24 * S), bones={"body": 1.0}, tag="back")
        c.ellipsoid(C + V(0, -0.055, -0.1) * S, (0.12 * S, 0.12 * S, 0.16 * S), bones={"body": 1.0}, tag="belly")
    c.ellipsoid(C + V(0, 0.0, -0.25) * S, (0.075 * S, 0.055 * S, 0.1 * S), bones={"body": 0.6, "tail0": 0.4}, tag="rump")
    for s in (1, -1):
        c.ellipsoid(C + V(0.085 * s, 0.07, 0.06) * S, (0.055 * S, 0.05 * S, 0.07 * S), bones={"body": 1.0}, tag="back")
    if neck == "crane":
        nr = (0.062, 0.041, 0.032, 0.036)
    elif neck == "short":
        nr = (0.1, 0.085, 0.07, 0.066)
    else:
        nr = (0.085, 0.062, 0.05, 0.05)
    c.chain([NK[0], NK[1], NK[2], NK[3]], [nr[0] * S, nr[1] * S, nr[2] * S, nr[3] * S], bones=limb_weights(["neck0", "neck1", "head"]), tag="neck", t0=0.0, t1=3.0)
    # the skull: a cranium, a brow over each eye, cheeks narrowing into the base of the bill
    brow = {"hook": 1.0, "crow": 0.6, "raven": 0.75, "crane": 0.25}[cf["beak"]]
    c.ellipsoid(hp(0, 0.008, -0.012), (0.06 * HK, 0.058 * HK, 0.075 * HK), rot=hf.M, bones={"head": 1.0}, tag="head")
    c.ellipsoid(hp(0, -0.008, 0.045), (0.042 * HK, 0.04 * HK, 0.045 * HK), rot=hf.M, bones={"head": 1.0}, tag="face")
    for s in (1, -1):
        c.ellipsoid(hp(0.035 * s, 0.037, 0.036), (0.024 * HK, 0.012 * HK * (0.6 + 0.4 * brow), 0.036 * HK), rot=hf.M, bones={"head": 1.0}, tag="brow")
        c.ellipsoid(hp(0.036 * s, -0.022, 0.012), (0.026 * HK, 0.03 * HK, 0.036 * HK), rot=hf.M, bones={"head": 1.0}, tag="face")
    for s, sd, hip, kn, ank, ball, toe in LEGS:
        # feathered thighs ("trousers") blending into the belly
        k_th = 0.75 if stand else 1.0
        c.ellipsoid(hip.lerp(kn, 0.55), (0.052 * S * k_th, 0.075 * S * k_th, 0.06 * S * k_th), bones={"leg.%s" % sd: 0.75, "body": 0.25}, tag="thigh")
        if not stand:
            c.ellipsoid(kn.lerp(ank, 0.35), (0.04 * S, 0.06 * S, 0.045 * S), bones={"shin.%s" % sd: 1.0}, tag="thigh")
        else:
            c.capsule(hip.lerp(kn, 0.5), kn.lerp(ank, 0.12), 0.034 * S, bones={"leg.%s" % sd: 0.5, "shin.%s" % sd: 0.5}, tag="thigh")

    def plumage(p, info):
        n = info.n
        tag = info.tag
        y = p.y - C.y
        under = 0.0
        if tag in ("breast", "belly", "thigh", "face"):
            under = smooth(0.05, -0.55, n.y) * (1.0 if tag != "face" else smooth(-0.1, -0.5, n.y))
        if tag == "neck":
            # the throat and the front of the neck are pale
            fr = n.dot(hf.f) if neck != "crane" else n.z
            under = smooth(0.15, 0.7, fr) * smooth(0.3, -0.3, n.y + 0.2)
        if style == "magpie":
            # black hood, breast, back and vent; a white belly and flanks
            white = 0.0
            if tag in ("belly", "breast", "thigh"):
                white = smooth(C.y - 0.0 * S, C.y - 0.07 * S, p.y) * smooth(0.15, -0.25, n.y)
                white *= smooth(0.17 * S, 0.06 * S, p.z) * smooth(-0.25 * S, -0.12 * S, p.z)
                if tag == "thigh":
                    white *= 0.0
            v = V_BACK * (1.0 - white) + V_UNDER * white
            return (v, v, v)
        v = V_BACK
        if tag in ("head", "brow", "face"):
            v = V_HEAD
        top = smooth(0.2, 0.9, n.y) * (0.0 if tag in ("belly", "thigh") else 1.0)
        v -= 0.06 * top
        if style == "bifang":
            # the crane's red crown and a red bar behind the eye (the markings: dark greys)
            if tag in ("head", "brow"):
                q = hf.M.transposed() @ (p - hf.c)
                crown = smooth(0.025 * HK, 0.045 * HK, q.y) * smooth(0.055 * HK, 0.02 * HK, abs(q.z + 0.005 * HK))
                v = v * (1.0 - crown) + 0.25 * crown
        if style == "phoenix" and tag == "rump":
            v = 0.9
        return (v * (1.0 - under) + V_UNDER * under,) * 3

    def tint(p, info):
        return 1.0

    c.build(b, plumage, cls=HAIR, tint_fn=tint)
    skin_hit = A.surface(b)

    # ---------------------------------------------------------------- the bill
    b.cur_pal = 0.0
    kind = cf["beak"]
    if kind == "hook":
        bc0, bc1 = "f0c050", "6a4818"
        beak(b, hf, HK,
             [(0, 0.008, 0.045), (0, 0.016, 0.09), (0, 0.006, 0.135), (0, -0.022, 0.163), (0, -0.05, 0.158)],
             [(0.03, 0.03), (0.026, 0.027), (0.018, 0.02), (0.01, 0.011), (0.002, 0.002)],
             [(0, -0.026, 0.05), (0, -0.032, 0.095), (0, -0.036, 0.13)],
             [(0.024, 0.014), (0.018, 0.011), (0.004, 0.004)], bc0, bc1)
        # the cere: waxy skin over the base of the bill
        b.cur_pal = 0.0
        b.ellipsoid(hp(0, 0.017, 0.056), (0.024 * HK, 0.014 * HK, 0.02 * HK), "f2b430", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=7)
    elif kind in ("crow", "raven"):
        bc0, bc1 = ("4e4e5c", "767688") if style == "magpie" else ("e8a838", "8a5018")
        big = 1.15 if kind == "raven" else 1.0
        beak(b, hf, HK,
             [(0, 0.012, 0.04), (0, 0.018, 0.1 * big), (0, 0.006, 0.16 * big), (0, -0.016, 0.2 * big), (0, -0.03, 0.212 * big)],
             [(0.03, 0.032), (0.024, 0.026), (0.015, 0.017), (0.007, 0.008), (0.002, 0.002)],
             [(0, -0.028, 0.045), (0, -0.032, 0.11 * big), (0, -0.03, 0.17 * big), (0, -0.032, 0.195 * big)],
             [(0.026, 0.014), (0.02, 0.012), (0.01, 0.007), (0.003, 0.003)], bc0, bc1)
        # nasal bristles: a tuft of stiff feathers over the nostrils at the base of the bill
        b.cur_pal = 0.0
        vb = V_HEAD * (0.9 if style == "magpie" else 0.95)
        for s in (1, -1):
            for j in range(3):
                root = hp(0.012 * s, 0.024 - 0.008 * j, 0.03)
                d = (hf.f * 1.0 - hf.u * 0.12 + hf.r * (0.12 * s)).normalized()
                quill(b, root, d, hf.u + hf.r * (0.4 * s), (0.07 - 0.012 * j) * HK, 0.014 * HK, (vb,) * 3, (vb * 0.9,) * 3, bone="head",
                      curl=0.08, shape="hackle", seg=6, steps=5)
    else:  # crane: a long straight dagger, white (the Bifang's white beak keeps its colour)
        bc0, bc1 = "f0ece0", "fffcf2"
        beak(b, hf, HK,
             [(0, 0.004, 0.04), (0, 0.004, 0.15), (0, -0.004, 0.27), (0, -0.016, 0.37), (0, -0.026, 0.42)],
             [(0.022, 0.025), (0.017, 0.019), (0.012, 0.013), (0.006, 0.006), (0.0015, 0.0015)],
             [(0, -0.024, 0.045), (0, -0.026, 0.16), (0, -0.028, 0.29), (0, -0.03, 0.39)],
             [(0.018, 0.011), (0.013, 0.009), (0.008, 0.006), (0.002, 0.002)], bc0, bc1)

    # ---------------------------------------------------------------- eyes
    iris = {"phoenix": "ff9a1a", "magpie": "5a3420", "sun_crow": "ffd23a", "bifang": "f2c41e"}[style]
    look = {"hook": 0.5, "crow": 0.3, "raven": 0.32, "crane": 0.22}[kind]
    for s in (1, -1):
        ec = hp(0.046 * s, 0.016, 0.034)
        A.animal_eye(b, ec, hf.r * s + hf.f * look, 0.022 * HK, iris, "head", pupil="round", almond=0.84, side=s,
                     glow=style in ("phoenix", "sun_crow"), lid="1a1210", lid_w=0.12, accent=False)

    # ---------------------------------------------------------------- crest
    if cf["crest"] == "plumes":
        # a crest of backswept plumes off the back of the crown (the golden pheasant's, the
        # fenghuang's), curling up at their ends into small flags; the dominant colour a little
        # paler, the very tips in the accent
        for k in range(5):
            a = (k - 2) * 0.16
            root = hp(math.sin(a) * 0.02, 0.044, -0.022 - 0.008 * abs(k - 2))
            L = (0.3 - 0.045 * abs(k - 2)) * HK
            d = (-hf.f * 0.93 + hf.u * 0.2 + hf.r * (math.sin(a) * 0.3)).normalized()
            up = hf.u + hf.f * 0.4
            up = (up - d * up.dot(d)).normalized()
            b.cur_pal = 0.0
            quill(b, root, d, up, L, 0.025 * HK, (0.9,) * 3, (0.97,) * 3, bone="head", curl=-0.2, shape="plume", seg=6, steps=9, thick=0.2)
            tipp = root + d * L + up * (0.2 * L)
            b.cur_pal = 1.0
            b.ellipsoid(tipp, (0.011 * HK, 0.006 * HK, 0.015 * HK), "e8e8e8", cls=CRYSTAL, bone="head", rot=orient(d + up * 0.6, up), seg=8, rings=5, mat=MAT_GLOW, tint=1.0)
            b.cur_pal = 0.0
    if style == "phoenix":
        # a cape over the nape and the shoulders (the golden pheasant's): three rows of broad
        # feathers laid on the sculpted neck and lifting off it a little as they fall over the
        # shoulders, the lowest row edged dark (the markings)
        hit = skin_hit
        axis = (NK[2] - NK[0]).normalized()
        for row, (tq, nk, ln, wd) in enumerate(((0.75, 7, 0.13, 0.04), (0.42, 9, 0.16, 0.048), (0.12, 11, 0.18, 0.054))):
            base = NK[0].lerp(NK[2], tq)
            for k in range(nk):
                a = math.pi + (k / (nk - 1) - 0.5) * (math.pi * 1.05)
                out = V(math.sin(a), 0.0, math.cos(a))
                out = (out - axis * out.dot(axis)).normalized()
                h = hit(base + out * (0.3 * S), -out)
                if h is None:
                    continue
                q, n = h
                g = V(0.0, -1.0, -0.45)
                g = (g - n * g.dot(n)).normalized()
                d = (g * 0.97 + n * 0.08).normalized()
                tip = (0.6,) * 3 if row == 2 else (0.9,) * 3
                wts = {"neck0": 0.3, "neck1": 0.7} if row == 0 else ({"neck0": 0.8, "neck1": 0.2} if row == 1 else {"neck0": 0.5, "body": 0.5})
                quill(b, q - n * (0.005 * S), d, n, ln * S, wd * S, (0.9,) * 3, tip, bone=wts, curl=0.12, shape="round", seg=7, steps=6, thick=0.2)
    if style == "sun_crow":
        # a raven's shaggy throat: pointed hackles laid on the throat under the bill
        for k in range(9):
            a = (k / 8 - 0.5) * 2.0
            base = NK[1].lerp(NK[3], 0.5)
            out = (hf.f * 0.25 - hf.u * 0.8 + hf.r * math.sin(a) * 0.9).normalized()
            h = skin_hit(base + out * (0.3 * S), -out)
            if h is None:
                continue
            q, n = h
            g = V(0.0, -1.0, 0.25)
            g = (g - n * g.dot(n)).normalized()
            quill(b, q - n * (0.004 * S), (g + n * 0.1).normalized(), n, (0.11 - 0.02 * abs(a)) * S, 0.03 * S, (V_HEAD,) * 3, (V_HEAD * 0.92,) * 3,
                  bone={"neck1": 0.6, "head": 0.4}, curl=0.1, shape="point", seg=6, steps=6, thick=0.2)

    # ---------------------------------------------------------------- wings
    def wing_paint(kind, i, n):
        u = i / max(1, n - 1)
        if style == "magpie":
            if kind == "pri":
                # the white flash: the inner webs of the primaries white, their tips and outer
                # edges black (pale greys on the dominant slot: the coat pass whitens them)
                return (0.97,) * 3, (0.2,) * 3, 1.0, (lambda t: (0.97 if t < 0.62 else 0.2,) * 3)
            if kind in ("pcov", "alula"):
                return (0.22,) * 3, (0.22,) * 3, 1.0, None
            if kind == "band":
                return (0.22,) * 3, None, 1.0, None
            # secondaries and their coverts take the secondary colour, dark and glossy
            return (0.62,) * 3, (0.46,) * 3, 1.0, None
        if style == "sun_crow":
            if kind == "pri":
                return (0.8,) * 3, (0.45,) * 3, 1.0, None
            if kind in ("sec", "ter"):
                return (0.86,) * 3, (0.6,) * 3, 1.0, None
            return (0.92,) * 3, (0.86,) * 3, 1.0, None
        if style == "bifang":
            if kind == "pri":
                return (0.55,) * 3, (0.3,) * 3, 1.0, None
            if kind == "ter":
                return (0.5,) * 3, (0.32,) * 3, 1.0, None
            if kind == "sec":
                return (0.62,) * 3, (0.42,) * 3, 1.0, None
            if kind == "mcov":
                # the red markings of the Shan Hai Jing: a red bar across the coverts
                return (0.92,) * 3, (0.86,) * 3, 1.0, None, 0.8
            return (0.86,) * 3, (0.8,) * 3, 1.0, None
        # phoenix: the coverts pale, the flight feathers deeper with dark tips
        if kind == "pri":
            return (0.82,) * 3, (0.38,) * 3, 1.0, None
        if kind in ("sec", "ter"):
            return (0.88,) * 3, (0.55,) * 3, 1.0, None
        if kind == "gcov":
            return (0.95,) * 3, (0.98,) * 3, 1.0, None
        return (0.97,) * 3, (0.97,) * 3, 1.0, None

    flames = []

    def wing_fire(f):
        if style not in ("sun_crow", "bifang"):
            return
        if f["kind"] == "pri" or (f["kind"] == "ter" and style == "bifang"):
            flames.append(f)

    for sd in ("L", "R"):
        slot = 0.0 if style == "magpie" else 0.5
        if style == "magpie":
            # the magpie's wing: the primaries and the band on the dominant slot (black and
            # white), the secondaries and their coverts in the secondary colour (blue gloss)
            w = wings[sd]
            b.cur_pal = 0.0
            w.build(b, lambda kind, i, n: wing_paint(kind, i, n), slot=0.0)
            continue
        wings[sd].build(b, wing_paint, slot=slot, fire=wing_fire)
    if style == "magpie":
        # glossy secondaries: put them (and their coverts, which ride on their bones) on the
        # secondary slot
        sec_bones = set()
        for w in wings.values():
            for f in w.flight:
                if f["kind"] in ("sec", "ter"):
                    sec_bones.add(f["bone"])
        for v in b.bm.verts:
            ws = v[b.dl]
            if not ws:
                continue
            gi = max(ws.items(), key=lambda kv: kv[1])[0]
            if b.groups[gi] in sec_bones:
                v[b.pl] = 0.5
    # flames licking off the flight feathers (the accent colour, glowing)
    b.cur_pal = 1.0
    for f in flames:
        tipp = f["root"] + f["d"] * (f["L"] * 0.97) - f["up"] * (0.05 * f["L"])
        ln = (0.2 if f["kind"] == "pri" else 0.36) * S * (0.7 + 0.3 * (f["i"] / max(1, f["n"] - 1)))
        probes.append((f["bone"], tipp + (f["d"] + f["up"] * 0.35).normalized() * ln + f["up"] * (0.3 * ln)))
        A.lock(b, tipp - f["d"] * (0.04 * S), (f["d"] + f["up"] * 0.35).normalized(), f["up"], ln, (0.034 if f["kind"] == "pri" else 0.05) * S, "d8d8d8", "ffffff",
               bone=f["bone"], lift=0.35, rise=0.25, cls=HAIR, mat=MAT_GLOW, tint=1.0, bend=0.25)
    b.cur_pal = 0.0

    # scapulars: broad feathers laid on the back over the root of each wing (the magpie's white)
    for s, sd in ((1, "L"), (-1, "R")):
        for k in range(4):
            h = skin_hit(C + V((0.06 + 0.018 * k) * s, 0.45, 0.075 - 0.065 * k) * S, V(0, -1, 0))
            if h is None:
                continue
            q, n = h
            g = V(0.3 * s, 0.0, -1.0)
            g = (g - n * g.dot(n)).normalized()
            d = (g + n * 0.06).normalized()
            vs = (0.97,) * 3 if style == "magpie" else (V_BACK - 0.02,) * 3
            vt = (0.97,) * 3 if style == "magpie" else (V_BACK - 0.08,) * 3
            quill(b, q - n * (0.006 * S), d, n, (0.2 + 0.035 * k) * S, 0.056 * S, vs, vt, bone="body", curl=0.1, shape="round", seg=7, steps=6, thick=0.18)

    # ---------------------------------------------------------------- tail
    def tail_w(t):
        f = max(0.0, min(NT - 1e-6, t * NT))
        i = int(f)
        u = f - i
        if u > 0.75 and i < NT - 1:
            k = (u - 0.75) / 0.25 * 0.5
            return {tail_names[i]: 1.0 - k, tail_names[i + 1]: k}
        if u < 0.25 and i > 0:
            k = 0.5 + u / 0.25 * 0.5
            return {tail_names[i - 1]: 1.0 - k, tail_names[i]: k}
        return {tail_names[i]: 1.0}

    TLEN = sum((TL[i + 1] - TL[i]).length for i in range(NT))

    def tail_fan(n, spread, lengths, width, c0, c1, droop=0.1, base_w=0.045, cols=None, shape="round", slot=0.5, roll=0.22):
        """A closed fan of rectrices, the central pair on top and each outer feather under its
        inner neighbour; each feather bends with the tail chain."""
        old = b.cur_pal
        b.cur_pal = slot
        for k in range(n):
            u = k / (n - 1) - 0.5
            a = u * spread
            root = TL[0] + V(math.sin(a) * base_w * S, -0.004 * abs(u) * S, 0.02 * S)
            L = lengths(abs(u) * 2.0) * S
            d = V(math.sin(a), -droop, -math.cos(a)).normalized()
            sgn = 1.0 if u >= 0 else -1.0
            sv = d.cross(V(0, 1, 0)).normalized()
            up = (V(0, 1, 0) * math.cos(roll) + sv * (sgn * math.sin(roll) * (1.0 if abs(u) > 0.01 else 0.0))).normalized()

            def bones(p, root=root, d=d):
                return tail_w(max(0.0, (p - root).dot(d)) / TLEN)
            quill(b, root, d, up, L, width * S, c0, c1, bone=bones, curl=0.04, shape=shape, seg=8, steps=8, cols=cols)
            tw = bones(root + d * L)
            probes.append((max(tw.items(), key=lambda kv: kv[1])[0], root + d * L))
        b.cur_pal = old

    if tail == "plumes":
        # a fan of rectrices under three long plumes (the fenghuang's), each plume sweeping down
        # and back on the tail chain and opening into a flag with an eye at its end
        tail_fan(12, 1.25, lambda a: 0.5 - 0.14 * a, 0.055, (0.86,) * 3, (0.5,) * 3, droop=0.18, slot=0.5)
        b.cur_pal = 0.5
        # (centre plume, then the pairs either side: lateral spread at the end, a drop, length)
        for k, (off, drop, lk) in enumerate(((0.0, 0.0, 1.0), (0.1, 0.05, 0.88), (-0.1, 0.05, 0.88), (0.2, 0.1, 0.68), (-0.2, 0.1, 0.68))):
            ctrl = []
            for i, q in enumerate(TL):
                t = i / (len(TL) - 1)
                ctrl.append(q + V(off * S * (0.25 + 1.6 * t * t), -drop * S * t * t + 0.03 * S * abs(off) * 5 * t, 0.0))
            fine = catmull(ctrl, 6)
            acc = [0.0]
            for i in range(len(fine) - 1):
                acc.append(acc[-1] + (fine[i + 1] - fine[i]).length)
            L_tot = acc[-1] * lk
            steps = 22
            samples = []
            for j in range(steps + 1):
                sl = L_tot * j / steps
                for i in range(len(fine) - 1):
                    if sl <= acc[i + 1] or i == len(fine) - 2:
                        u = min(1.0, (sl - acc[i]) / max(1e-6, acc[i + 1] - acc[i]))
                        samples.append((fine[i].lerp(fine[i + 1], u), (i + u) / (len(fine) - 1) * NT))
                        break
            side = V(1.0 if off >= 0 else -1.0, 0.0, 0.0)
            rings = []
            cols = []
            bones = []
            for j, (q, f) in enumerate(samples):
                t = j / steps
                tan = (samples[min(steps, j + 1)][0] - samples[max(0, j - 1)][0]).normalized()
                # the ribbon twists from lying flat at the root to standing on edge, so its broad
                # face (and its eye) is seen from the side as it streams out behind
                tw = smooth(0.04, 0.32, t) * math.pi * 0.5
                nv = V(0, 1, 0) * math.cos(tw) + side * math.sin(tw)
                nv = (nv - tan * tan.dot(nv)).normalized()
                w = 0.05 * S * _vane(t, "plume")
                # the long barbs of the flag: a softly serrated edge
                w *= 1.0 + 0.1 * smooth(0.5, 0.6, t) * math.sin(t * 70.0)
                h = max(0.0008, w * 0.13)
                rings.append(section(q, tan, prof_ellipse(max(w, 0.0009), h), 8, up=nv))
                # a pale shaft, two dark bars before the flag
                bar = smooth(0.05, 0.0, abs(t - 0.58)) + smooth(0.04, 0.0, abs(t - 0.68))
                v = 0.92 - 0.42 * min(1.0, bar)
                cols.append((v, v, v))
                fi = min(NT - 1e-6, f)
                ii = int(fi)
                uu = fi - ii
                bones.append({tail_names[ii]: 1.0 - uu * 0.5, tail_names[ii + 1]: uu * 0.5} if ii < NT - 1 else {tail_names[ii]: 1.0})
            loft(b, rings, (0.9, 0.9, 0.9), cls=HAIR, cols=cols, bones=bones, tint=1.0, cap0=True, cap1=True, cap_push=0.25)
            for jj in (steps // 2, steps * 3 // 4, steps):
                probes.append((max(bones[jj].items(), key=lambda kv: kv[1])[0], samples[jj][0]))
            # the eye of the plume: a glowing ocellus through the flag, seen from either side
            je = int(steps * 0.86)
            q_end, f_end = samples[je]
            tan = (samples[min(steps, je + 2)][0] - samples[je - 2][0]).normalized()
            nv = (side - tan * tan.dot(side)).normalized()
            eb = tail_names[min(NT - 1, int(f_end))]
            b.ellipsoid(q_end, (0.03 * S, 0.009 * S, 0.036 * S), "fff0b0", cls=CRYSTAL, bone=eb, rot=orient(tan, nv), seg=10, rings=5, mat=MAT_GLOW)
            b.cur_pal = 1.0
            b.ellipsoid(q_end, (0.016 * S, 0.012 * S, 0.019 * S), "e8e8e8", cls=CRYSTAL, bone=eb, rot=orient(tan, nv), seg=8, rings=4, mat=MAT_GLOW, tint=1.0)
            b.cur_pal = 0.5
        b.cur_pal = 0.0
    elif tail == "long":
        # the magpie's long graduated tail: the central pair longest, each pair outwards shorter,
        # held nearly closed so it reads as one long tapering blade
        tail_fan(10, 0.34, lambda a: 0.98 - 0.52 * a ** 1.3, 0.05, (0.4,) * 3, (0.3,) * 3, droop=0.12, slot=0.5)
    elif tail == "wedge":
        # a raven's wedge: the central feathers longest
        tail_fan(12, 0.9, lambda a: 0.55 - 0.2 * a ** 1.2, 0.05, (0.84,) * 3, (0.5,) * 3, droop=0.14, slot=0.5)
    else:
        # the crane's short tail, hidden under its bustle
        tail_fan(8, 0.8, lambda a: 0.26 - 0.06 * a, 0.045, (0.6,) * 3, (0.4,) * 3, droop=0.3, slot=0.5)
    # tail coverts over the base of the tail
    b.cur_pal = 0.0
    for k in range(5):
        u = k / 4 - 0.5
        root = C + V(u * 0.07, 0.05, -0.17) * S
        d = V(u * 0.5, -0.2, -1.0).normalized()
        vt = (V_BACK,) * 3 if style != "magpie" else (0.24,) * 3
        quill(b, root, d, V(0, 1, 0), 0.2 * S, 0.045 * S, vt, vt, bone={"body": 0.5, "tail0": 0.5}, curl=0.12, shape="round", seg=7, steps=6)

    # ---------------------------------------------------------------- legs: scaled shanks, toes, talons
    leg_col = {"phoenix": "d8a030", "magpie": "26262c", "sun_crow": "d09028", "bifang": "3a3a40"}[style]
    for s, sd, hip, kn, ank, ball, toe in LEGS:
        lg, sn, ts, tb2 = "leg.%s" % sd, "shin.%s" % sd, "tars.%s" % sd, "toe.%s" % sd
        sr = 0.024 if stand else 0.026
        if stand:
            # the crane's long bare tibia below its feathers
            b.tube([kn.lerp(ank, 0.04), kn.lerp(ank, 0.5), ank], [sr * 1.1 * S, sr * 0.85 * S, sr * 0.8 * S], leg_col, cls=SKIN, bones=[sn, sn, {sn: 0.5, ts: 0.5}], seg=8)
        b.tube([ank, ank.lerp(ball, 0.5), ball], [sr * 0.85 * S, sr * 0.7 * S, sr * 0.75 * S], leg_col, cls=SKIN, bones=[{sn: 0.4, ts: 0.6}, ts, {ts: 0.5, tb2: 0.5}], seg=8)
        # scutes: darker rings down the front of the shank
        for j in range(5 if not stand else 9):
            q = ank.lerp(ball, 0.1 + 0.8 * j / (4 if not stand else 8))
            b.ellipsoid(q + V(0, 0, 0.012 * S), (sr * 0.75 * S, 0.005 * S, sr * 0.5 * S), mix(leg_col, "000000", 0.25), cls=SKIN, bone=ts, seg=8, rings=4, mat=MAT_PLAIN)
        for k in range(4):
            a = (k - 1) * 0.42 if k < 3 else math.pi
            d = V(math.sin(a), 0, math.cos(a))
            ln = (0.1 if k < 3 else 0.05) * S * (1.4 if stand else 1.0)
            t1 = ball + d * ln * 0.55 + V(0, -0.008, 0) * S
            t2 = ball + d * ln + V(0, -0.014, 0) * S
            b.tube([ball, t1, t2], [0.014 * S, 0.012 * S, 0.01 * S], leg_col, cls=SKIN, bone=tb2, seg=6)
            A.claw(b, t2, d, 0.035 * S, 0.008 * S, tb2, down=V(0, -1, 0), hook=0.8, col0="2a2018", col1="6a5a40")
            probes.append((tb2, t2 + d * (0.035 * S) - V(0, 0.025 * S, 0)))

    # ---------------------------------------------------------------- the sun behind the crow
    if style == "sun_crow":
        # a flaming halo: a ring of the sun's fire behind the crow, tongues of flame licking off it
        ring_c = C + V(0, 0.16, -0.42) * S
        R0 = 0.62 * S
        TILT = Matrix.Identity(3)
        r.bone("sun", ring_c, ring_c + V(0, 0.3 * S, 0), "body")
        # the sun itself: a faint disc of light within the ring (additive: the crow stands dark
        # against it, as it does in the Han pictures)
        b.disc(ring_c - V(0, 0, 0.02 * S), R0 * 0.97, "3a1606", cls=CRYSTAL, bone="sun", seg=40, rot=(math.pi / 2, 0, 0), mat=MAT_GLOW,
               col_rim="a8480e", thick=0.004)

        def on_ring(a, rr, z=0.0):
            return ring_c + TILT @ V(math.cos(a) * rr, math.sin(a) * rr, z)

        axis_z = TILT @ V(0, 0, 1)
        pts = [on_ring(i / 32 * 2 * math.pi, R0) for i in range(33)]
        b.tube(pts, [(0.032 * S, 0.075 * S)] * 33, "ffb030", cls=CRYSTAL, bone="sun", seg=8, mat=MAT_GLOW, cap0=False, cap1=False, up=tuple(axis_z))
        pts2 = [on_ring(i / 32 * 2 * math.pi, R0 * 0.86, 0.01 * S) for i in range(33)]
        b.tube(pts2, [0.012 * S] * 33, "fff0a0", cls=CRYSTAL, bone="sun", seg=5, mat=MAT_GLOW, cap0=False, cap1=False)
        for k in range(16):
            a = k / 16 * 2 * math.pi + 0.1
            base = on_ring(a, R0)
            rad = TILT @ V(math.cos(a), math.sin(a), 0.0)
            ln = (0.22 if k % 2 == 0 else 0.14) * S
            A.lock(b, base, rad - axis_z * 0.55, -axis_z, ln, 0.06 * S, "ff7020", "fff0a0", bone="sun", lift=0.3, rise=0.1,
                   cls=HAIR, mat=MAT_GLOW, tint=0.0, bend=0.35)
            A.lock(b, base - axis_z * (0.03 * S), rad * 0.4 - axis_z, rad, ln * 0.8, 0.05 * S, "ff7020", "fff0a0",
                   bone="sun", lift=0.3, rise=0.1, cls=HAIR, mat=MAT_GLOW, tint=0.0, bend=0.2)

    # ---------------------------------------------------------------- what touches the ground
    for w in wings.values():
        for f in w.flight:
            probes.append((f["bone"], f["root"] + f["d"] * f["L"] - f["up"] * (0.06 * f["L"])))
            probes.append((f["bone"], f["root"] + f["d"] * (f["L"] * 0.5) - f["up"] * (0.02 * f["L"])))
        probes.append((w.b2, w.wr))
    for q in (hp(0, -0.04, 0.42 if kind == "crane" else 0.2), hp(0, 0.06, -0.06), hp(0, -0.06, 0.0), hp(0.05, 0.0, 0.0), hp(-0.05, 0.0, 0.0)):
        probes.append(("head", q))
    probes += [("neck1", NK[2]), ("neck0", NK[1]), ("body", C + V(0, -0.17, 0.06) * S), ("body", C + V(0, -0.15, -0.12) * S),
               ("body", C + V(0.14, -0.05, 0.0) * S), ("body", C + V(-0.14, -0.05, 0.0) * S)]
    for s, sd, hip, kn, ank, ball, toe in LEGS:
        probes += [("toe." + sd, toe), ("tars." + sd, ball), ("shin." + sd, ank)]
    probes += [(nm, TL[i + 1]) for i, nm in enumerate(tail_names)]

    # ---------------------------------------------------------------- clips
    poser = Poser(r)

    def lowest(p, pick=None):
        """The lowest probe (world y) of pose p, over the probes whose bone `pick` accepts."""
        D = poser.fk(p)
        lo = 1e9
        for bn, q in probes:
            if pick is not None and not pick(bn):
                continue
            lo = min(lo, (D[bn] @ q.to_4d()).y)
        return lo

    def wing_of(sd):
        w = wings[sd]
        names = {w.b1, w.b2, w.b3} | {f["bone"] for f in w.flight}
        return lambda bn: bn in names

    def off_ground(p, floor=0.01):
        """Lift pose p (by its root) just clear of the ground if any probe would go through it."""
        lo = lowest(p)
        if lo < floor:
            rot, loc = p["root"][0], p["root"][1]
            p["root"] = (rot, (loc[0], loc[1] + floor - lo, loc[2])) + tuple(p["root"][2:])
        return p

    def ground(pose_at, sides=("L", "R"), floor=0.03):
        """Solve a lying pose: pose_at(lz, dy) -> pose, with lz {side: wing raise} and dy a lift of
        the whole body.  Each wing is raised or lowered until its lowest feather just touches the
        ground, and the body is lifted if anything else would still go through it."""
        lz = {sd: 0.0 for sd in sides}
        dy = 0.0
        for _ in range(3):
            for sd in sides:
                lo_a, hi_a = -1.4, 1.4
                for _ in range(22):
                    mid = 0.5 * (lo_a + hi_a)
                    lz[sd] = mid
                    if lowest(pose_at(lz, dy), wing_of(sd)) < floor:
                        lo_a = mid
                    else:
                        hi_a = mid
                lz[sd] = hi_a
            others = lowest(pose_at(lz, dy), lambda bn: not any(wing_of(sd)(bn) for sd in sides))
            if others < floor - 0.002:
                dy += floor - others
            else:
                break
        return lz, dy
    folds = {}
    for w in wings.values():
        folds.update(w.fold_rots())
    wing_bones = set(folds)

    def wing_pose(p, k_fold, lift=None, extra=None, out=0.03):
        """Set every wing bone: a share `k_fold` of the fold, then the arm's own rotation
        `lift[sd]` = (pitch, sweep, raise) of the humerus (radians, mirrored per side) and
        `extra[sd]` = (forearm raise, hand raise)."""
        for w in wings.values():
            s = w.s
            for nm in [w.b1, w.b2, w.b3] + [f["bone"] for f in w.flight]:
                M = qslerp(folds[nm], k_fold)
                loc = (0.0, 0.0, 0.0)
                if nm == w.b1:
                    if lift is not None:
                        lx, ly, lz = lift.get(w.sd, (0.0, 0.0, 0.0))
                        M = euler_g((lx, ly * s, lz * s)) @ M
                    loc = (out * S * s * k_fold, 0.0, 0.0)
                elif nm in (w.b2, w.b3) and extra is not None:
                    e2, e3 = extra.get(w.sd, (0.0, 0.0))
                    M = M @ euler_g((0.0, 0.0, (e2 if nm == w.b2 else e3) * s))
                put(p, nm, M, loc)

    def flap(p, t, T, amp, base_fold=0.0, flex=0.4, raise_=0.0, sweep=0.0):
        """A wingbeat: the downstroke with the wing spread, the upstroke with the wrist flexed."""
        w_ = 2 * math.pi / T
        ph = w_ * t
        f = math.sin(ph)
        kf = base_fold + flex * max(0.0, -math.cos(ph)) ** 1.5
        lift = {}
        extra = {}
        for sd in ("L", "R"):
            lift[sd] = (0.18 * f - 0.05, sweep - 0.12 * math.cos(ph), -(amp * f) + raise_)
            extra[sd] = (-amp * 0.35 * math.sin(ph - 0.7), -amp * 0.45 * math.sin(ph - 1.3))
        wing_pose(p, kf, lift, extra)

    def tail_sway(p, t, T, amp):
        w_ = 2 * math.pi / T
        for i, nm in enumerate(tail_names):
            add(p, nm, (amp * 0.6 * math.sin(2 * w_ * t - i * 0.8), amp * math.sin(w_ * t - i * 0.7), 0.0))

    def tuck_legs(p, k=1.0):
        for s, sd, *_ in LEGS:
            add(p, "leg.%s" % sd, (0.55 * k, 0, 0))
            add(p, "shin.%s" % sd, (0.7 * k, 0, 0))
            add(p, "toe.%s" % sd, (0.9 * k, 0, 0))

    def look(p, t, T, k=1.0):
        w_ = 2 * math.pi / T
        add(p, "neck0", (0.04 * k * math.sin(2 * w_ * t), 0.12 * k * math.sin(w_ * t - 0.4), 0.0))
        add(p, "neck1", (0.03 * k * math.sin(2 * w_ * t + 1.0), 0.1 * k * math.sin(w_ * t - 0.2), 0.0))
        add(p, "head", (0.05 * k * math.sin(w_ * t * 2), 0.15 * k * math.sin(w_ * t), 0.06 * k * math.sin(w_ * t)))

    def plant_legs(p, offs=None):
        D = poser.fk(p)
        for i, (s, sd, hip, kn, ank, ball, toe) in enumerate(LEGS):
            o = offs[i] if offs else (0.0, 0.0, 0.0)
            res = leg_ik(r, D, ["leg.%s" % sd, "shin.%s" % sd, "tars.%s" % sd, "toe.%s" % sd], "body", ball + V(*o))
            for nm, val in res.items():
                p[nm] = val
        return p

    if not stand:
        T_IDLE, T_WALK = 2.4, 1.2

        def idle(t):
            p = zero_pose(r)
            w_ = 2 * math.pi / (T_IDLE / 2)
            add(p, "root", (0, 0, 0), (0, -0.07 * math.sin(w_ * t), 0))
            add(p, "body", (-0.12 + 0.05 * math.sin(w_ * t), 0, 0))
            add(p, "neck0", (0.1, 0, 0))
            flap(p, t, T_IDLE / 2, 0.55, flex=0.3)
            tail_sway(p, t, T_IDLE, 0.06)
            look(p, t, T_IDLE)
            tuck_legs(p, 0.6)
            return p

        def walk(t):
            p = zero_pose(r)
            w_ = 2 * math.pi / (T_WALK / 2)
            add(p, "root", (0, 0, 0), (0, -0.06 * math.sin(w_ * t), 0))
            add(p, "body", (0.22 + 0.04 * math.sin(w_ * t), 0, 0))
            add(p, "neck0", (-0.18, 0, 0))
            add(p, "head", (-0.1, 0, 0))
            flap(p, t, T_WALK / 2, 0.68, flex=0.5)
            tail_sway(p, t, T_WALK, 0.05)
            tuck_legs(p, 1.0)
            return p

        def attack(t):
            k = t / 0.55
            ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.42, k))
            hit = smooth(0.3, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
            p = idle(t * 0.5)
            add(p, "root", (0, 0, 0), (0, 0.15 * ant - 0.25 * hit, -0.1 * ant + 0.55 * hit))
            add(p, "body", (-0.35 * ant + 0.45 * hit, 0, 0))
            add(p, "neck0", (-0.3 * ant + 0.3 * hit, 0, 0))
            add(p, "jaw", (0.6 * smooth(0.25, 0.4, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
            for s, sd, *_ in LEGS:
                add(p, "leg.%s" % sd, (-1.2 * hit - 0.5 + 0.2 * ant, 0, 0))
                add(p, "toe.%s" % sd, (-0.6 * hit, 0, 0))
            # wings flung up and back, then mantled forward over the strike
            lift = {sd: (0.1 * hit, -0.3 * ant + 0.25 * hit, 0.75 * ant - 0.2 * hit) for sd in ("L", "R")}
            wing_pose(p, 0.15 * ant, lift, {sd: (0.2 * ant, 0.25 * ant) for sd in ("L", "R")})
            return p

        def hurt(t):
            k = t / 0.55
            e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
            p = idle(t * 0.3)
            add(p, "root", (0, 0, 0), (0, 0.1 * e, -0.3 * e))
            add(p, "body", (-0.35 * e, 0, 0.15 * e))
            add(p, "neck0", (-0.4 * e, 0.3 * e, 0))
            add(p, "head", (-0.2 * e, 0.2 * e, 0))
            add(p, "jaw", (0.4 * e, 0, 0))
            lift = {sd: (0.0, 0.0, 0.55 * e) for sd in ("L", "R")}
            wing_pose(p, 0.25 * e, lift, None)
            return p

        REST_H = DIE_REST[style]

        def die(t):
            """The wings go limp and the bird drops out of the air: it lands on its breast, rolls a
            little onto one side and lies still on the ground, wings spread on it, head turned
            aside.  (It turns about its own body, not about the ground under it, and the wings are
            laid on the ground by a small solve, so it ends lying on the ground, not sunk into it.)"""
            return off_ground(die_pose(t, min(1.0, t / 1.2), DIE_LZ, DIE_DY))

        def die_pose(t, k, lz, dy):
            drop = smooth(0.08, 0.6, k) ** 1.6
            settle = smooth(0.35, 0.72, k)
            bounce = 0.035 * S * math.sin(math.pi * smooth(0.6, 0.78, k))
            p = zero_pose(r)
            roll = 0.25 * settle
            R = euler_g((0.1 * settle, 0.0, roll))
            B = V(0.0, Y - (Y - REST_H * S) * drop + bounce + dy * settle, 0.0)
            put(p, "root", R, B - R @ C)
            beat = 0.5 * (1.0 - drop) ** 2 * math.sin(t * 9.0)
            lift = {sd: (0.0, 0.08 * settle, beat + lz[sd] * drop) for sd in ("L", "R")}
            wing_pose(p, 0.1, lift, {sd: (-0.08 * drop, -0.1 * drop) for sd in ("L", "R")})
            add(p, "neck0", (0.55 * drop, 0.3 * settle, 0.0))
            add(p, "neck1", (0.5 * drop, 0.4 * settle, 0.0))
            add(p, "head", (0.3 * drop, 0.25 * settle, 0.45 * settle))
            add(p, "jaw", (0.25 * settle, 0, 0))
            tuck_legs(p, 0.3 + 0.7 * drop)
            for nm in tail_names:
                add(p, nm, (0.06 * drop, 0.0, 0.0))
            if "sun" in r.bones:
                # the sun falls with the crow and lies flat round it, shrinking as it gutters
                h = r.bones["sun"][0]
                D = poser.fk(p)
                Rb = D["body"].to_3x3()
                ob = D["body"].translation
                tgt = V(0.0, 0.1 * S, -0.08 * S)
                flat = Matrix.Rotation(math.pi * 0.5, 3, "X")
                Rl = qslerp(Rb.transposed() @ flat, drop)
                loc = (Rb.transposed() @ (tgt - ob) - h) * drop
                sc = 1.0 - 0.3 * drop
                p["sun"] = (euler_yxz(Rl), tuple(loc), (sc, sc, sc))
            return p

        DIE_LZ, DIE_DY = ground(lambda lz, dy: die_pose(1.2, 1.0, lz, dy))

        def cast(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = idle(t * 0.4)
            add(p, "root", (0, 0, 0), (0, 0.2 * e, 0))
            add(p, "body", (-0.3 * e, 0, 0))
            add(p, "neck0", (-0.4 * e, 0, 0))
            add(p, "head", (-0.3 * e, 0, 0))
            add(p, "jaw", (0.5 * e, 0, 0))
            lift = {sd: (0.25 * e, 0.0, 0.95 * e) for sd in ("L", "R")}
            wing_pose(p, 0.0, lift, {sd: (0.3 * e, 0.2 * e) for sd in ("L", "R")})
            for nm in tail_names:
                add(p, nm, (-0.12 * e, 0.0, 0.0))
            return p

        clips = {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}
    else:
        T_IDLE, T_WALK = 3.2, 0.8

        def stand_pose(t, T, fold=1.0):
            p = zero_pose(r)
            w_ = 2 * math.pi / T
            br = math.sin(w_ * t * 2)
            add(p, "body", (0.03 * br, 0.04 * math.sin(w_ * t), 0.0), (0.0, 0.008 * br, 0.0))
            # wings folded along the body, the bustle stirring
            wing_pose(p, fold, {sd: (0.0, 0.0, 0.02 * br) for sd in ("L", "R")})
            look(p, t, T)
            tail_sway(p, t, T, 0.04)
            return p

        def idle(t):
            return plant_legs(stand_pose(t, T_IDLE))

        def walk(t):
            """Hops on its one leg, wings opening and beating once each hop for balance."""
            k = (t / T_WALK) % 1.0
            air = smooth(0.15, 0.3, k) * (1.0 - smooth(0.7, 0.85, k))
            crouch = bump((k + 0.5) % 1.0 - 0.5, 0.0, 0.17)
            p = stand_pose(t, T_WALK)
            hop = 0.16 * S * math.sin(math.pi * smooth(0.15, 0.85, k))
            add(p, "root", (0.0, 0.0, 0.0), (0.0, hop - 0.06 * S * crouch, 0.0))
            add(p, "body", (0.15 * crouch - 0.1 * air, 0.0, 0.0))
            add(p, "neck0", (-0.15 * crouch + 0.1 * air, 0.0, 0.0))
            beat = math.sin(2 * math.pi * k)
            lift = {sd: (0.1 * air, 0.0, (0.55 + 0.35 * beat) * air) for sd in ("L", "R")}
            wing_pose(p, 1.0 - 0.75 * air, lift, {sd: (0.15 * air * beat, 0.2 * air * beat) for sd in ("L", "R")})
            ks = (k + 0.15) % 1.0
            if ks < 0.3:
                dz = 0.08 * S * (1.0 - 2.0 * ks / 0.3)
            else:
                dz = 0.08 * S * (2.0 * smooth(0.3, 1.0, ks) - 1.0)
            dy = 0.1 * S * air
            return plant_legs(p, [(0.0, dy, dz)])

        def attack(t):
            k = t / 0.55
            ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.4, k))
            hit = smooth(0.3, 0.4, k) * (1.0 - smooth(0.6, 1.0, k))
            p = stand_pose(t, T_IDLE, fold=1.0 - 0.5 * (ant + hit))
            add(p, "body", (-0.25 * ant + 0.45 * hit, 0, 0))
            add(p, "neck0", (-0.4 * ant + 0.5 * hit, 0, 0))
            add(p, "neck1", (-0.3 * ant + 0.4 * hit, 0, 0))
            add(p, "head", (0.2 * ant + 0.2 * hit, 0, 0))
            add(p, "jaw", (0.4 * smooth(0.25, 0.38, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
            for w in wings.values():
                add(p, w.b1, (0.0, 0.0, 0.35 * (ant + hit) * w.s))
            return plant_legs(p)

        def hurt(t):
            k = t / 0.55
            e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
            p = stand_pose(t, T_IDLE, fold=1.0 - 0.6 * e)
            add(p, "body", (-0.3 * e, 0, 0.12 * e))
            add(p, "neck0", (-0.4 * e, 0.3 * e, 0))
            add(p, "head", (-0.2 * e, 0.2 * e, 0))
            for w in wings.values():
                add(p, w.b1, (0.0, 0.0, 0.6 * e * w.s))
            return plant_legs(p, [(0.0, 0.0, -0.05 * e)])

        REST_B = DIE_REST[style]

        def die(t):
            """The leg buckles and the crane sinks, then topples onto its side and lies on the
            ground, neck and half-open wings sprawled.  (It turns about its own body, so it ends
            lying on the ground and not sunk into it.)"""
            return off_ground(die_pose(min(1.0, t / 1.2), DIE_LZ, DIE_DY))

        def die_pose(k, lz, dy):
            buckle = smooth(0.0, 0.4, k)
            fall = smooth(0.3, 0.78, k)
            p = stand_pose(0.0, T_IDLE, fold=1.0 - 0.5 * fall)
            a = 1.32 * fall
            R = euler_g((0.0, 0.0, a))
            B = V(-0.3 * S * fall, (Y - 0.36 * S * buckle) * (1.0 - fall) + (REST_B * S + dy) * fall, 0.0)
            put(p, "root", R, B - R @ C)
            # the wings half open as it falls; the lower one is laid flat on the ground
            wing_pose(p, 1.0 - 0.5 * fall, {sd: (0.0, 0.0, (0.35 + lz[sd]) * fall) for sd in ("L", "R")})
            add(p, "neck0", (0.25 * buckle, -0.25 * fall, 0))
            add(p, "neck1", (0.3 * buckle, -0.3 * fall, 0))
            add(p, "head", (0.2 * buckle, 0, 0.3 * fall))
            # the foot stays planted while the leg buckles under the sinking body, and folds once it
            # topples
            folded = {"leg.C": 0.9, "shin.C": -1.4, "tars.C": 0.8, "toe.C": 0.0}
            planted = plant_legs({nm: v for nm, v in p.items()})
            for nm, fx in folded.items():
                x0 = planted[nm][0][0]
                put_x = x0 + (fx * buckle - x0) * fall
                p[nm] = ((put_x, 0.0, 0.0), (0.0, 0.0, 0.0))
            return p

        DIE_LZ, DIE_DY = ground(lambda lz, dy: die_pose(1.0, lz, dy))

        def cast(t):
            e = math.sin(math.pi * min(1.0, t / 0.6))
            p = stand_pose(t, T_IDLE, fold=1.0 - e)
            add(p, "neck0", (-0.35 * e, 0, 0))
            add(p, "head", (-0.4 * e, 0, 0))
            add(p, "jaw", (0.5 * e, 0, 0))
            for w in wings.values():
                add(p, w.b1, (0.15 * e, 0.0, 0.7 * e * w.s))
            return plant_legs(p)

        clips = {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}
    return b, r, clips


def bump(x, c, w):
    d = abs(x - c) / w
    return 0.5 + 0.5 * math.cos(math.pi * d) if d < 1.0 else 0.0
