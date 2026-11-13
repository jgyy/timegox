"""Jelly: drifting jellyfish of the abyss and the formless jellies of the Primordial Chaos.  After the
sea nettle and the moon jelly (aquarium species notes; Invertebrate Anatomy OnLine's Aurelia):

* a smooth domed bell (the exumbrella) marked with a pale star of sixteen rays, darkening to a band
  at the rim, over a darker inner bell (the subumbrella) seen from below;
* a margin cut into rounded lappets, with a glowing sense organ (a rhopalium) in each of the eight
  deeper notches;
* four long oral arms from the middle of the underside - ruffled, lace-edged curtains that twist as
  they hang - the jelly's largest shape;
* long thin marginal tentacles in eight groups of three between the rhopalia, trailing in soft
  curves (drawn without ink lines, so they read as strands and not as sticks);
* the moon jelly's four horseshoe gonads glowing through the top of the bell; no eyes.

Each tentacle group and each arm is a bone chain that waves as the bell pulses.  Tinted by the game
per enemy: the bell takes the colour, the arms the secondary, the glows the accent.
Clips: idle (pulsing in place), walk (quicker pulses, leaning into the stroke), attack (a lunge with
the arms flung out), hurt, die (the bell sinks and spreads on the ground) and cast (a spinning pulse).
Run: blender --background --python art/monsters/jelly.py  ->  assets/monsters/jelly.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import add, chain_rig, glow_ball, smooth, wave_chain, zero_pose  # noqa: E402
from sculpt import catmull, loft  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, SKIN, THIN, V, Builder, Rig, env, euler_g, lin  # noqa: E402
from creature import euler_yxz  # noqa: E402
from mathutils import Matrix  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.55
R_RIM = 0.6
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("bell", (0, Y - 0.2, 0), (0, Y + 0.35, 0), "root")
N_G = 8                     # tentacle groups, between the eight rhopalia
tent = []
for k in range(N_G):
    a = 2 * math.pi * (k + 0.5) / N_G
    top = V(math.cos(a) * 0.56, Y - 0.12, math.sin(a) * 0.56)
    pts = [top + V(math.cos(a) * 0.05 * j, -0.3 * j, math.sin(a) * 0.05 * j) for j in range(5)]
    tent.append((chain_rig(r, "t%d_" % k, pts, "bell"), pts, a))
arms = []
for k in range(4):
    a = 2 * math.pi * k / 4 + math.pi / 4
    top = V(math.cos(a) * 0.08, Y - 0.16, math.sin(a) * 0.08)
    pts = [top + V(math.cos(a) * 0.06 * j, -0.28 * j, math.sin(a) * 0.06 * j) for j in range(5)]
    arms.append((chain_rig(r, "a%d_" % k, pts, "bell"), pts, a))
b = Builder("jelly")


def chain_w(names, f):
    """Weights along a bone chain at fractional bone position f (0 .. len(names))."""
    n = len(names)
    f = max(0.0, min(n - 1e-6, f))
    i = int(f)
    t = f - i
    if t > 0.7 and i < n - 1:
        k = (t - 0.7) / 0.3 * 0.5
        return {names[i]: 1.0 - k, names[i + 1]: k}
    if t < 0.3 and i > 0:
        k = 0.5 + t / 0.3 * 0.5
        return {names[i - 1]: 1.0 - k, names[i]: k}
    return {names[i]: 1.0}


# ---------------------------------------------------------------- the bell
PROF = [(0.0006, 0.43), (0.05, 0.4285), (0.12, 0.422), (0.25, 0.39), (0.37, 0.33), (0.47, 0.245), (0.545, 0.15), (0.585, 0.06), (0.6, -0.02), (0.59, -0.075)]
NA = 96
rings = []
for j, (rad, y) in enumerate(PROF):
    t = j / (len(PROF) - 1)
    ring = []
    for i in range(NA):
        a = 2 * math.pi * i / NA
        # sixteen shallow lappets round the margin, notched deeper at the eight rhopalia
        lap = abs(math.cos(8 * a))
        rr = rad
        yy = y
        if j >= len(PROF) - 2:
            k = 1.0 if j == len(PROF) - 1 else 0.4
            yy = y + k * 0.022 * (1.0 - lap)
            rr = rad * (1.0 - k * (0.02 * (1.0 - lap)))
        # shallow radial grooves between the rays of the star
        rr *= 1.0 + 0.012 * math.cos(16 * a) * smooth(0.0, 0.5, t)
        ring.append(V(math.cos(a) * rr, Y + yy, math.sin(a) * rr))
    rings.append(ring)


def bell_col(p, j, i):
    t = 1.0 - j / (len(PROF) - 1)      # (the rings run from the rim up to the crown)
    a = 2 * math.pi * i / NA
    ray = 0.5 + 0.5 * math.cos(16 * a)
    v = 0.86 + 0.08 * ray * smooth(0.15, 0.5, t) * (1.0 - smooth(0.8, 1.0, t))
    v += 0.06 * (1.0 - smooth(0.0, 0.3, t))           # a paler crown
    v -= 0.1 * smooth(0.72, 0.92, t)                  # a darker band towards the rim
    v += 0.08 * smooth(0.92, 1.0, t)                  # the thin rim itself pale
    return (v, v, v)


b.cur_pal = 0.0
loft(b, rings[::-1], (0.9, 0.9, 0.9), cls=SKIN, col_fn=bell_col, bone="bell", tint=1.0, cap0=False, cap1=False, closed=False)
# the subumbrella: a darker inner bell, open below
inner = []
for j, (rad, y) in enumerate(PROF[3:-1]):
    inner.append([V(math.cos(2 * math.pi * i / NA) * rad * 0.93, Y + y * 0.9 - 0.035, math.sin(2 * math.pi * i / NA) * rad * 0.93) for i in range(NA)])
loft(b, inner, (0.76, 0.76, 0.76), cls=SKIN, bone="bell", tint=1.0, cap0=True, cap1=False, inside=True, cap_push=0.12)
# the rim joins the two
rim = [[V(math.cos(2 * math.pi * i / NA) * PROF[-2][0] * f, Y + PROF[-2][1] + dy, math.sin(2 * math.pi * i / NA) * PROF[-2][0] * f) for i in range(NA)] for f, dy in ((0.985, 0.0), (0.93, PROF[-2][1] * 0.9 - 0.035 - PROF[-2][1]))]
loft(b, rim, (0.8, 0.8, 0.8), cls=SKIN, bone="bell", tint=1.0, cap0=False, cap1=False, closed=False)
# the sense organs in the deep notches, glowing in the accent colour
b.cur_pal = 1.0
for k in range(8):
    a = math.pi / 16 + k * math.pi / 4      # in every other notch between the lappets
    b.ball(V(math.cos(a) * 0.585, Y - 0.07, math.sin(a) * 0.585), 0.018, "f4f4f4", cls=CRYSTAL, bone="bell", seg=8, rings=5, mat=MAT_GLOW, tint=1.0)
# four horseshoe gonads glowing through the top of the bell
for k in range(4):
    a = 2 * math.pi * k / 4 + math.pi / 4
    shoe = []
    for j in range(11):
        t = j / 10 * math.pi * 1.4 - math.pi * 0.2
        c = V(math.cos(a), 0, math.sin(a)) * 0.2
        sv = V(-math.sin(a), 0, math.cos(a))
        q = c + sv * (math.cos(t) * 0.09) + V(math.cos(a), 0, math.sin(a)) * (math.sin(t) * 0.07)
        rad = q.length
        y = 0.43 - (rad / 0.6) ** 2 * 0.42
        shoe.append(V(q.x, Y + y + 0.006, q.z))
    b.tube(shoe, [0.022] * 11, "e0e0e0", cls=CRYSTAL, bone="bell", seg=6, mat=MAT_GLOW, tint=1.0)
b.cur_pal = 0.0
glow_ball(b, V(0, Y + 0.08, 0), 0.1, "ffe8ff", "bell")


# ---------------------------------------------------------------- the oral arms: ruffled curtains that twist as they hang
def membrane(rows, bones, col_fn, tint_fn):
    """A double-sided membrane (no ink line) through a grid of points; bones/colours per point."""
    nr, nc = len(rows), len(rows[0])
    verts = [p for row in rows for p in row]
    nrm = []
    for j in range(nr):
        for i in range(nc):
            pa = rows[j][min(nc - 1, i + 1)] - rows[j][max(0, i - 1)]
            pb = rows[min(nr - 1, j + 1)][i] - rows[max(0, j - 1)][i]
            nn = pa.cross(pb)
            nrm.append(nn.normalized() if nn.length > 1e-9 else V(1, 0, 0))
    faces = [(j * nc + i, j * nc + i + 1, (j + 1) * nc + i + 1, (j + 1) * nc + i) for j in range(nr - 1) for i in range(nc - 1)]
    cols = [lin(col_fn(j, i), SKIN + THIN) for j in range(nr) for i in range(nc)]
    tints = [tint_fn(j, i) for j in range(nr) for i in range(nc)]
    bw = [bones[j] for j in range(nr) for i in range(nc)]
    th = 0.004
    b.add([verts[k] + nrm[k] * th for k in range(len(verts))], faces, (0.9, 0.9, 0.9), SKIN, None, 0.0, 0, True, cols=cols, tints=tints, bones=bw, closed=False)
    b.add([verts[k] - nrm[k] * th for k in range(len(verts))], [tuple(reversed(f)) for f in faces], (0.9, 0.9, 0.9), SKIN, None, 0.0, 0, True,
          cols=[(c[0] * 0.85, c[1] * 0.85, c[2] * 0.85, c[3]) for c in cols], tints=tints, bones=bw, closed=False)


b.cur_pal = 0.0   # the arms are the bell's own colour, paler and more translucent
for ka, (names, pts, a0) in enumerate(arms):
    spine = catmull(pts, 7)
    n = len(spine)
    NW = 11
    rows = []
    bones = []
    for j, q in enumerate(spine):
        t = j / (n - 1)
        # a ribbon turning once round its spine as it hangs; its lace edges, longer than the
        # spine, fall into soft waves
        ang = a0 + t * math.pi * 2.0
        sv = V(math.cos(ang), 0, math.sin(ang))
        nv = V(-math.sin(ang), 0, math.cos(ang))
        w = 0.15 - 0.09 * t
        row = []
        for i in range(NW):
            u = i / (NW - 1) * 2.0 - 1.0
            ruff = 0.04 * abs(u) ** 2 * math.sin(t * 22.0 + u * 1.5 + ka) * (0.5 + t)
            row.append(q + sv * (u * w) + nv * ruff + V(0, -0.04 * abs(u) ** 2, 0))
        rows.append(row)
        bones.append(chain_w(names, t * len(names)))
    membrane(rows, bones, lambda j, i: (0.96 + 0.04 * abs(i / (NW - 1) * 2.0 - 1.0),) * 3,
             lambda j, i: 0.95 - 0.35 * abs(i / (NW - 1) * 2.0 - 1.0) ** 1.5)
    # small glowing beads down the spine of each arm
    b.cur_pal = 1.0
    for j in range(3, n - 2, 5):
        b.ball(spine[j], 0.012, "e8e8e8", cls=CRYSTAL, bone=chain_w(names, j / (n - 1) * len(names)), seg=6, rings=4, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = 0.0

# ---------------------------------------------------------------- marginal tentacles: eight groups of three, trailing in soft curves
for kg, (names, pts, a0) in enumerate(tent):
    out = V(math.cos(a0), 0, math.sin(a0))
    side = V(-math.sin(a0), 0, math.cos(a0))
    for o3 in (-1, 0, 1):
        ln = 1.08 + 0.14 * math.sin(kg * 1.7 + o3 * 2.3)
        ctrl = []
        for j in range(6):
            t = j / 5
            sway = 0.13 * math.sin(t * 2.6 + kg * 0.9 + o3 * 1.3) * t
            ctrl.append(pts[0] + side * (0.05 * o3 + sway) + out * (0.06 * t + 0.015 * o3 * t) + V(0, -ln * t, 0))
        cp = catmull(ctrl, 5)
        m = len(cp)
        radii = [0.011 * (1.0 - 0.85 * (k / (m - 1)) ** 0.8) + 0.0012 for k in range(m)]
        bones = [chain_w(names, (k / (m - 1)) * len(names) * (ln / 1.2)) for k in range(m)]
        cols = [(0.97, 0.97, 0.97)] * m
        b.tube(cp, radii, (0.97, 0.97, 0.97), cls=SKIN + THIN, bones=bones, seg=5, tint=0.75, cols=cols)

T_IDLE = 2.4


def pulse_pose(t, speed, amp):
    p = zero_pose(r)
    ph = t * speed
    pul = math.sin(ph)
    p["bell"] = ((0, 0, 0), (0, 0.06 * math.sin(ph - 0.6), 0), (1.0 + 0.06 * pul, 1.0 - 0.08 * pul, 1.0 + 0.06 * pul))
    p["root"] = ((0, 0, 0), (0, 0.05 * math.sin(ph - 2.0), 0))
    for k, (names, _, _) in enumerate(tent):
        wave_chain(p, names, t + k * 0.13, speed, amp, axis=0, lag=0.9, grow=0.3)
    for k, (names, _, _) in enumerate(arms):
        wave_chain(p, names, t + k * 0.3, speed, amp * 0.8, axis=2, lag=0.7)
    return p


def idle(t):
    return pulse_pose(t, 2 * math.pi / T_IDLE, 0.12)


def attack(t):
    k = t / 0.55
    e = env(k)
    p = pulse_pose(t, 14.0, 0.3 * e + 0.1)
    p["root"] = ((0.4 * e, 0, 0), (0, 0.1 * e, 0.45 * math.sin(min(1.0, k * 1.6) * math.pi)))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = pulse_pose(t, 20.0, 0.2 * e)
    p["bell"] = ((-0.3 * e, 0, 0.2 * e), (0, -0.05 * e, 0), (1.0 + 0.15 * e, 1.0 - 0.2 * e, 1.0 + 0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = pulse_pose(t, 8.0, 0.25)
    p["bell"] = ((0, t * 4.0, 0), (0, 0.2 * e, 0), (1.0 + 0.2 * e, 1.0 + 0.1 * e, 1.0 + 0.2 * e))
    return p


T_WALK = 1.2


def walk(t):
    """Swims: quicker pulses of the bell, leaning into the stroke, tentacles trailing."""
    p = pulse_pose(t, 2 * math.pi / T_WALK, 0.16)
    add(p, "root", (0.25, 0, 0), (0, 0.05 * math.sin(2 * math.pi * t / T_WALK), 0))
    return p


def die(t):
    """The light gutters; the bell sinks to the ground and spreads like a dropped cloth."""
    k = min(1.0, t / 1.2)
    f = smooth(0.1, 0.8, k) ** 1.3
    p = pulse_pose(t * (1.0 - 0.8 * f), 2 * math.pi / T_IDLE, 0.1 * (1.0 - f))
    # the pulse's bob dies away with it, so the bell ends at rest
    for nm in ("root", "bell"):
        p[nm] = (p[nm][0], tuple(x * (1.0 - f) for x in p[nm][1])) + tuple(p[nm][2:])
    tilt = 4.0 * f * (1.0 - f)          # it tips as it sinks and lies flat once down
    add(p, "root", (0.1 * tilt, 0, 0.15 * tilt), (0, -1.3 * f + 0.04 * math.sin(math.pi * smooth(0.7, 0.86, k)), 0))
    p["bell"] = (p["bell"][0], p["bell"][1], (1.0 + 0.35 * f, 1.0 - 0.55 * f, 1.0 + 0.35 * f))
    # tentacles and arms spread out flat on the ground round it: each chain turns outwards about
    # the horizontal axis square to its own direction (a true axis-angle turn, so the diagonal
    # ones lie flat too)
    for chains, spread in ((tent, (1.42, 0.12, 0.06, 0.03)), (arms, (1.5, 0.08, 0.04, 0.02))):
        for names, _, a in chains:
            axis = V(-math.sin(a), 0.0, math.cos(a))
            for j, nm in enumerate(names):
                M = Matrix.Rotation(spread[min(j, 3)] * f, 3, axis) @ euler_g(p[nm][0])
                p[nm] = (euler_yxz(M), p[nm][1])
    return p


print("[art] jelly: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/jelly.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.35)
