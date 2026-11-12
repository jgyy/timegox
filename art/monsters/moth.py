"""Moth (new in Part V): the great lantern moths (Glow Moth, Lantern Moth Queen, Spider-Lily Moth,
Silver-Thread Moth, Mulberry Moth, Seven-Star Moth, Long-Noon Cicada ...).

After the giant silk moths (Saturniidae: the Atlas, the emperors): broad wings held in a shallow V,
the forewing a triangle whose tip hooks back (falcate), the hindwing rounded; each painted with the
family's pattern - a dark, furry base, a wavy antemedial line, an eyespot over the discal cell (here
it glows in the accent colour), a pale-edged postmedial line, a pale submarginal band and a dark
border - with the veins radiating from the root, and edged so the wing reads as a shape.  A thick,
furry thorax and a ruff behind the head, a plump abdomen of furred rings, big dark compound eyes, the
broad, feathered (bipectinate) antennae of the family, and short furry legs folded under the
thorax.  The wings take the enemy's colour, the fur its secondary; the eyespots glow.
Run: blender --background --python art/monsters/moth.py  ->  assets/monsters/moth.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import arthropod as X  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, V, Builder, Rig, env  # noqa: E402
from clay import Clay  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
C = V(0, 1.5, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", C + V(0, 0, -0.1), C + V(0, 0.02, 0.2), "root")
r.bone("abdomen", C + V(0, 0, -0.1), C + V(0, -0.15, -0.55), "body")
r.bone("head", C + V(0, 0.02, 0.2), C + V(0, 0.05, 0.36), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("fw.%s" % sd, C + V(0.08 * s, 0.06, 0.08), C + V(0.9 * s, 0.3, 0.25), "body")
    r.bone("hw.%s" % sd, C + V(0.08 * s, 0.02, -0.05), C + V(0.7 * s, -0.05, -0.35), "body")
    r.bone("ant.%s" % sd, C + V(0.04 * s, 0.1, 0.33), C + V(0.22 * s, 0.4, 0.6), "head")

b = Builder("moth")

# ---------------------------------------------------------------- body: fluffy thorax, ruff, furred abdomen
cl = Clay(0.013, "moth_body")
cl.ellipsoid(C + V(0, 0.02, 0.05), (0.15, 0.145, 0.19), bones={"body": 1.0}, tag="thorax")
cl.ellipsoid(C + V(0, 0.05, 0.17), (0.16, 0.135, 0.085), bones={"body": 0.7, "head": 0.3}, tag="ruff")
abd = [C + V(0, -0.0, -0.1)] + [C + V(0, -0.03 - k / 6 * 0.12, -0.15 - k / 6 * 0.33) for k in range(1, 7)]
for k in range(7):
    cl.ellipsoid(abd[k], ((0.145 - k / 6 * 0.07), (0.135 - k / 6 * 0.06), 0.07), rot=A.frame_m(abd[min(6, k + 1)] - abd[max(0, k - 1)]),
                 bones={"abdomen": min(1.0, 0.3 + k * 0.2), "body": max(0.0, 0.7 - k * 0.2)}, tag="abd", t=k)
cl.ellipsoid(C + V(0, 0.04, 0.27), (0.09, 0.085, 0.08), bones={"head": 1.0}, tag="head")


def moth_col(p, info):
    if info.tag == "abd":
        # pale bands between the furred rings
        return X.grey(0.78 + 0.16 * (0.5 + 0.5 * math.cos(info.t * 2 * math.pi)))
    if info.tag == "ruff":
        return X.grey(0.97)
    if info.tag == "head":
        return X.grey(0.8)
    return X.grey(0.86 - 0.08 * smooth(0.0, 0.8, info.n.y))


def moth_fluff(p, info):
    if info.tag == "head":
        return None
    nn = info.n
    w = fbm3((p.x * 14.0, p.y * 14.0, p.z * 14.0), 2, 4)
    u = -p.z * 22.0 + 0.5 * math.sin(math.atan2(nn.x, nn.y) * 7.0) + 1.2 * w
    k = u - math.floor(u)
    return nn * ((0.02 if info.tag in ("thorax", "ruff") else 0.01) * k ** 1.5)


b.cur_pal = 0.5          # the fur in the secondary colour
cl.build(b, moth_col, cls=CLOTH, tint_fn=lambda p, info: 0.85, post=moth_fluff)
b.cur_pal = 0.0
# big dark compound eyes with a soft sheen (no cartoon glints), short furry palps, the proboscis
# coiled tight under the head
for s in (1, -1):
    ec = C + V(0.062 * s, 0.058, 0.295)
    look = V(0.75 * s, 0.12, 0.65).normalized()
    rot = creature.euler_yxz(X.rot_to(look, V(0, 1, 0)))
    b.ellipsoid(ec, (0.05, 0.056, 0.04), "2a2232", cls=X.CHITIN, bone="head", rot=rot, seg=16, rings=10, mat=MAT_PLAIN)
    b.ellipsoid(ec + look * 0.018 + V(0, 0.02, 0), (0.032, 0.026, 0.024), "4c4258", cls=X.CHITIN, bone="head", rot=rot, seg=10, rings=6, mat=MAT_PLAIN)
coil = []
for k in range(14):
    a = k / 13 * 3.0 * math.pi
    rr = 0.026 * (1.0 - k / 18)
    coil.append(C + V(0, -0.07 - math.sin(a) * rr, 0.335 + math.cos(a) * rr * 0.6))
b.tube(coil, [0.005] * 14, "5a4030", cls=CRYSTAL, bone="head", seg=5, mat=MAT_PLAIN)
# feathered (bipectinate) antennae: a shaft with fine rami both sides, broad as a leaf in the middle
b.cur_pal = 0.5
for s, sd in ((1, "L"), (-1, "R")):
    a = "ant.%s" % sd
    h, tl = r.head(a), r.tail(a)
    shaft = [h, h.lerp(tl, 0.5) + V(0, 0.05, 0), tl + V(0.02 * s, 0.0, -0.04)]
    pts = A.catmull(shaft, 6)
    b.tube(pts, [0.009 * (1.0 - 0.6 * i / (len(pts) - 1)) for i in range(len(pts))], (0.62, 0.62, 0.62), cls=HAIR, bone=a, tint=0.8, seg=5)
    side = (tl - h).cross(V(0, 1, 0)).normalized()
    for k in range(16):
        t = 0.08 + k / 16 * 0.88
        i = min(len(pts) - 2, int(t * (len(pts) - 1)))
        p = pts[i].lerp(pts[i + 1], t * (len(pts) - 1) - i)
        ln = 0.085 * math.sin(math.pi * min(1.0, t * 1.05)) ** 0.8 + 0.01
        back = (pts[i] - pts[i + 1]).normalized()
        for sg in (1, -1):
            d = (side * sg + back * 0.55 + V(0, -0.1, 0)).normalized()
            b.tube([p, p + d * ln * 0.5 + V(0, 0.006, 0), p + d * ln], [0.0045, 0.003, 0.0008], (0.78, 0.78, 0.78), cls=HAIR, bone=a, tint=0.8, seg=4)
# short furry legs folded up under the thorax: a furred femur, a thin shin with a dark claw
for s in (1, -1):
    for k in range(3):
        root = C + V(0.05 * s, -0.1, 0.13 - k * 0.09)
        knee = root + V(0.09 * s, -0.02, 0.07 - k * 0.025)
        foot = knee + V(0.0, -0.07, 0.05 - k * 0.04)
        b.tube([root, root.lerp(knee, 0.5) + V(0, -0.01, 0), knee], [0.028, 0.03, 0.02], (0.72, 0.72, 0.72), cls=HAIR, bone="body", tint=0.85, seg=8)
        b.tube([knee, foot], [0.012, 0.006], (0.5, 0.5, 0.5), cls=HAIR, bone="body", tint=0.85, seg=6)
b.cur_pal = 0.0


# ---------------------------------------------------------------- wings
def polar_outline(samples):
    """samples: [(angle_deg, radius)] round the wing root, in order; returns R(angle_rad)."""
    s2 = sorted((math.radians(a), rr) for a, rr in samples)

    def R(th):
        if th <= s2[0][0]:
            return s2[0][1]
        for (a0, r0), (a1, r1) in zip(s2, s2[1:]):
            if a0 <= th <= a1:
                f = (th - a0) / (a1 - a0)
                f = f * f * (3.0 - 2.0 * f) * 0.35 + f * 0.65
                return r0 + (r1 - r0) * f
        return s2[-1][1]

    # (from the front edge round to the back one)
    return R, s2[-1][0], s2[0][0]


# angles from the wing's span axis: positive towards the front edge (costa), negative behind
FORE = polar_outline([(14.0, 0.5), (11.0, 0.84), (7.0, 0.97), (3.0, 1.0), (-2.0, 0.96), (-8.0, 0.88), (-20.0, 0.82), (-38.0, 0.78), (-56.0, 0.66),
                      (-70.0, 0.48), (-82.0, 0.3), (-88.0, 0.14)])
HIND = polar_outline([(-30.0, 0.18), (-38.0, 0.5), (-48.0, 0.66), (-62.0, 0.72), (-78.0, 0.68), (-94.0, 0.56), (-108.0, 0.4), (-118.0, 0.22)])


def wing_col(rho, th, th0, th1, spot):
    """Saturniid pattern in polar coordinates round the root (rho 0..1 to the margin)."""
    v = 0.84
    v = v * (1.0 - 0.32 * smooth(0.3, 0.12, rho))                                    # the dark, furry base
    wav = 0.025 * math.sin(th * 26.0)
    v *= 1.0 - 0.38 * smooth(0.025, 0.0, abs(rho - 0.34 - wav))                    # antemedial line
    pm = 0.72 + 0.03 * math.sin(th * 18.0)
    v *= 1.0 - 0.45 * smooth(0.022, 0.0, abs(rho - pm))                            # postmedial line, dark
    v += 0.14 * smooth(0.03, 0.0, abs(rho - pm - 0.04))                            # with a pale edge outside it
    v += 0.1 * smooth(0.04, 0.0, abs(rho - 0.86))                                  # pale submarginal band
    v *= 1.0 - 0.4 * smooth(0.91, 0.96, rho)                                       # dark border
    # veins radiating from the root
    vein = abs(math.sin((th - th0) / (th1 - th0) * math.pi * 6.0))
    v *= 1.0 - 0.12 * smooth(0.12, 0.0, vein) * smooth(0.2, 0.4, rho) * smooth(0.95, 0.85, rho)
    # a soft dark halo round the eyespot
    dr, dth, rad = spot
    d = math.hypot(rho - dr, (th - dth) * rho * 1.0)
    v *= 1.0 - 0.3 * smooth(rad * 1.6, rad * 1.1, d)
    return min(1.0, max(0.0, v))


def wing(bone, root, span_dir, chord_dir, up, outline, size, spot, nu=22, nv=18, camber=0.04):
    """A wing as a fine polar grid round its root (so the pattern resolves), with a solid edge."""
    R, th0, th1 = outline
    rows = []
    cols = []
    for j in range(nu + 1):
        rho = 0.03 + 0.97 * j / nu
        row = []
        crow = []
        for i in range(nv + 1):
            th = th0 + (th1 - th0) * i / nv
            rr = R(th) * size * rho
            p = root + span_dir * (math.cos(th) * rr) + chord_dir * (math.sin(th) * rr) + up * (camber * size * math.sin(math.pi * rho) * 0.5)
            row.append(p)
            g = wing_col(rho, th, th0, th1, spot)
            crow.append((g, g, g))
        rows.append(row)
        cols.append(crow)
    b.sheet(rows, cols[0][0], cls=CLOTH, bone=bone, tint=1.0, cols=cols, thickness=0.01)
    # the edge: a thin, solid border so the wing keeps an ink line round it, the front edge (the
    # costa) the stiffest
    b.tube(rows[-1], [0.007] * len(rows[-1]), X.grey(0.5), cls=X.CHITIN, bone=bone, tint=1.0, seg=5, cap0=False, cap1=False)
    lead = [rows[j][0] for j in range(nu + 1)]
    b.tube(lead, [0.004 + 0.009 * (1.0 - j / nu) for j in range(nu + 1)], X.grey(0.55), cls=X.CHITIN, bone=bone, tint=1.0, seg=5)
    # the eyespot: a dark ring, an iris glowing in the accent colour, a dark pupil and a white crescent
    dr, dth, rad = spot
    rr = R(dth) * size * dr
    c = root + span_dir * (math.cos(dth) * rr) + chord_dir * (math.sin(dth) * rr) + up * (camber * size * math.sin(math.pi * dr) * 0.5)
    rsz = rad * size
    rot = (0.0, 0.0, 0.0)
    nrm = span_dir.cross(chord_dir).normalized()
    if nrm.dot(up) < 0:
        nrm = -nrm
    rot = creature.euler_yxz(X.rot_to(chord_dir, nrm))
    b.disc(c + nrm * 0.006, rsz, "1a1018", cls=CRYSTAL, bone=bone, seg=20, rot=rot, thick=0.012)
    old = b.cur_pal
    b.cur_pal = 1.0
    b.disc(c + nrm * 0.008, rsz * 0.72, (1.0, 1.0, 1.0), cls=CRYSTAL, bone=bone, seg=18, rot=rot, mat=MAT_GLOW, col_rim=(0.7, 0.7, 0.7), thick=0.014, tint=1.0)
    b.cur_pal = old
    b.disc(c + nrm * 0.01, rsz * 0.3, "140c14", cls=CRYSTAL, bone=bone, seg=12, rot=rot, thick=0.016)
    b.disc(c + nrm * 0.012 + chord_dir * rsz * 0.25 + span_dir * rsz * 0.1, rsz * 0.12, "ffffff", cls=CRYSTAL, bone=bone, seg=8, rot=rot, mat=MAT_GLOW,
           thick=0.018)


for s, sd in ((1, "L"), (-1, "R")):
    # a shallow V: the wings rise from the root
    lift = math.radians(17.0)
    span = V(s * math.cos(lift), math.sin(lift), 0.0)
    chord = V(0, 0, 1)
    upv = span.cross(chord) * (-s)
    upv = upv if upv.y > 0 else -upv
    sp_f = (span + V(0, 0, 0.12)).normalized()
    wing("fw.%s" % sd, C + V(0.07 * s, 0.07, 0.1), sp_f, (chord - sp_f * chord.dot(sp_f)).normalized(), upv, FORE, 0.98, (0.55, math.radians(-26.0), 0.11))
    sp_h = (span + V(0, -0.1, -0.08)).normalized()
    wing("hw.%s" % sd, C + V(0.06 * s, 0.03, -0.04), sp_h, (chord - sp_h * chord.dot(sp_h)).normalized(), upv, HIND, 0.8, (0.52, math.radians(-70.0), 0.12))

FLAP = 0.8


def idle(t, amp=1.0):
    w = 2 * math.pi / FLAP
    f = math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, -f * 0.07 + math.sin(t * w / 4) * 0.1, 0))
    p["body"] = ((0.05 * f, math.sin(t * w / 4) * 0.1, 0), (0, 0, 0))
    p["abdomen"] = ((-0.06 * f, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, -s * (0.1 + f * 0.62) * amp), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, -s * (0.08 + math.sin(t * w - 0.5) * 0.5) * amp), (0, 0, 0))
        p["ant.%s" % sd] = ((math.sin(t * w / 2) * 0.1, 0, 0), (0, 0, 0))
    return p


def attack(t):
    e = env(t / 0.55)
    p = idle(t * 1.5, 1.2)
    p["root"] = ((0, 0, 0), (0, -0.2 * e, 0.45 * e))
    p["body"] = ((0.35 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t, 0.5)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.25 * e))
    p["body"] = ((-0.4 * e, 0, 0.3 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 0.4)
    p["body"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, s * 0.6 * e), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, s * 0.4 * e), (0, 0, 0))
    return p


T_WALK = 1.6


def walk(t):
    """Flutters forward: quicker beats, the body pitched into the flight, bobbing."""
    p = idle(t * FLAP * 4 / T_WALK, 1.15)
    add(p, "body", (0.25, 0, 0))
    add(p, "abdomen", (-0.1, 0, 0))
    add(p, "root", (0, 0, 0), (0, 0.04 * math.sin(2 * math.pi * t / T_WALK), 0))
    return p


def die(t):
    """The wings fold; the moth tumbles to the ground and lies with its wings spread flat."""
    k = min(1.0, t / 1.2)
    f = smooth(0.1, 0.7, k) ** 1.5
    p = idle(t * (1.0 - f), 1.0 - f)
    add(p, "root", (0.0, 0.0, 0.5 * f), (0, -1.85 * f + 0.05 * math.sin(math.pi * smooth(0.7, 0.85, k)), 0))
    add(p, "body", (0.2 * f, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "fw.%s" % sd, (0, 0, s_ * 0.2 * f))
        add(p, "hw.%s" % sd, (0, 0, s_ * 0.15 * f))
        add(p, "ant.%s" % sd, (0.5 * f, 0, 0))
    return p


# the moth reads small next to the other foes: scale it up (clips are rotations, so they still fit)
kit.scale_asset(b, r, 1.45)
print("[art] moth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/moth.glb", {"idle": (FLAP * 4, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=10, dist=0.2, strength=0.4)
