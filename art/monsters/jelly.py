"""Jelly: drifting jellyfish of the abyss and the formless jellies of the Primordial Chaos.  A domed
bell over a darker subumbrella, its rim cut into lappets with a glowing sense organ in each notch,
eight radial canals and four horseshoe gonads glowing through it, four long oral arms frilled into
ruffled curtains, a fringe of fine rim tentacles and a curtain of long beaded tentacles, each a
bone chain that waves as the bell pulses.  Tinted by the game per enemy; the glow keeps its own colour.
Run: blender --background --python art/monsters/jelly.py  ->  assets/monsters/jelly.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import chain_rig, glow_ball, wave_chain, zero_pose  # noqa: E402
from sculpt import catmull, strand  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from creature import add, smooth  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.55
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("bell", (0, Y - 0.2, 0), (0, Y + 0.35, 0), "root")
N_T = 10
tent = []
for k in range(N_T):
    a = 2 * math.pi * k / N_T
    top = V(math.cos(a) * 0.48, Y - 0.12, math.sin(a) * 0.48)
    pts = [top + V(math.cos(a) * 0.04 * j, -0.28 * j, math.sin(a) * 0.04 * j) for j in range(5)]
    tent.append((chain_rig(r, "t%d_" % k, pts, "bell"), pts))
arms = []
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.4
    top = V(math.cos(a) * 0.1, Y - 0.15, math.sin(a) * 0.1)
    pts = [top + V(math.cos(a) * 0.05 * j, -0.3 * j, math.sin(a) * 0.05 * j) for j in range(4)]
    arms.append((chain_rig(r, "a%d_" % k, pts, "bell"), pts))
b = Builder("jelly")

# the bell: an outer dome with a gentle flare and a scalloped rim of lappets, a darker inner
# bell (the subumbrella) under it, glowing radial canals and four horseshoe gonads seen through it
prof = [(0.56, -0.12), (0.6, -0.05), (0.58, 0.08), (0.5, 0.22), (0.36, 0.33), (0.18, 0.39), (0.001, 0.41)]
prof = [(0.56, -0.12), (0.6, -0.06), (0.6, 0.02), (0.57, 0.1), (0.5, 0.21), (0.4, 0.3), (0.27, 0.37), (0.13, 0.405), (0.001, 0.415)]
b.lathe(V(0, Y, 0), prof, (0.9, 0.9, 0.9), cls=SKIN, bone="bell", seg=48, col_top=(0.72, 0.72, 0.72), tint=1.0, folds=(16, 0.035, 0.0))
b.lathe(V(0, Y, 0), [(0.5, -0.1), (0.5, -0.02), (0.46, 0.08), (0.38, 0.17), (0.2, 0.27), (0.001, 0.3)], (0.62, 0.62, 0.62), cls=SKIN, bone="bell", seg=40, tint=1.0, cap_bottom=False)
for k in range(16):
    a = 2 * math.pi * k / 16
    b.ellipsoid(V(math.cos(a) * 0.58, Y - 0.13, math.sin(a) * 0.58), (0.075, 0.032, 0.05), (1.0, 1.0, 1.0), cls=SKIN, bone="bell", tint=1.0, seg=10, rings=6, rot=(0, -a, 0))
    # sense organ (rhopalium) in each notch between lappets
    a2 = a + math.pi / 16
    b.cur_pal = 1.0  # the sense organs in the rim notches glow in the accent colour
    b.ball(V(math.cos(a2) * 0.57, Y - 0.1, math.sin(a2) * 0.57), 0.013, "f4f4f4", cls=CRYSTAL, bone="bell", seg=6, rings=4, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = 0.0
for k in range(8):
    a = 2 * math.pi * k / 8 + 0.2
    canal = []
    for j in range(7):
        t = j / 6
        rr = 0.05 + t * 0.52
        y = Y + 0.4 - (rr / 0.6) ** 2 * 0.47
        canal.append(V(math.cos(a) * rr * 1.01, y + 0.008, math.sin(a) * rr * 1.01))
    b.tube(canal, [0.007] * 7, "f0d0ff", cls=CRYSTAL, bone="bell", seg=4, mat=MAT_GLOW)
for k in range(4):
    a = 2 * math.pi * k / 4
    shoe = []
    for j in range(9):
        t = j / 8 * math.pi
        shoe.append(V(math.cos(a) * 0.17 + math.cos(a + math.pi / 2) * math.cos(t) * 0.08, Y + 0.12 + 0.02 * math.sin(t), math.sin(a) * 0.17 + math.sin(a + math.pi / 2) * math.cos(t) * 0.08) + V(math.cos(a), 0, math.sin(a)) * math.sin(t) * 0.07)
    b.cur_pal = 1.0  # the four horseshoe gonads glow through the bell in the accent colour
    b.tube(shoe, [0.022] * 9, "f4f4f4", cls=CRYSTAL, bone="bell", seg=6, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = 0.0
glow_ball(b, V(0, Y + 0.05, 0), 0.1, "ffe8ff", "bell")
# a pair of eyes so the spirit has a face
for s in (1, -1):
    b.eye(V(0.16 * s, Y + 0.12, 0.52), 0.05, "40e0ff", side=s, bone="bell", rot_y=0.35, h=1.2, glow=True, accent=True)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# oral arms: long frilled curtains - each a pair of crossed ribbons whose edges ruffle
for names, pts in arms:
    fine = catmull(pts, 3)
    bones = [names[min(len(names) - 1, int(i / (len(fine) - 1) * len(names)))] for i in range(len(fine))]
    for c3 in range(3):
        rows = []
        for i, q in enumerate(fine):
            t = i / (len(fine) - 1)
            ang = c3 * math.pi / 3 + t * 1.3
            sv = V(math.cos(ang), 0, math.sin(ang))
            nv = V(-math.sin(ang), 0, math.cos(ang))
            w = 0.11 * (1.0 - 0.45 * t)
            # the outer edge of each curtain is longer than its spine, so it ruffles
            ruffle = 0.035 * math.sin(i * 2.6 + c3) * (0.5 + t)
            rows.append([q - sv * w + nv * ruffle, q - sv * w * 0.5 - nv * ruffle * 0.4, q, q + sv * w * 0.5 + nv * ruffle * 0.4, q + sv * w - nv * ruffle])
        b.sheet(rows, (0.9, 0.9, 0.9), bones=bones, cols=[(0.8 + 0.2 * (i / (len(fine) - 1)),) * 3 for i in range(len(fine))], tint=1.0, thickness=0.006)
    for i in range(1, len(fine), 3):
        b.ball(fine[i] + V(0.05, 0, 0.02), 0.012, "ffd0ff", cls=CRYSTAL, bone=bones[i], seg=5, rings=3, mat=MAT_GLOW)
b.cur_pal = 0.0  # the tentacles share the bell's colour, paler
# trailing tentacles: thin tubes with glowing beads, and a fringe of fine rim tentacles
for names, pts in tent:
    bones = [names[0]] + [names[min(j, len(names) - 1)] for j in range(len(pts) - 1)]
    out = V(pts[0].x, 0, pts[0].z).normalized()
    side_v = V(-out.z, 0, out.x)
    for o3 in (-1, 0, 1):
        off = side_v * (0.035 * o3) + out * (0.01 * abs(o3))
        tp = [q + off * (1.0 + 0.6 * j) for j, q in enumerate(pts)]
        tp[-1] = tp[-1] + V(0, -0.12 - 0.06 * abs(o3), 0)
        b.tube(tp, [0.012, 0.009, 0.007, 0.005, 0.0015], (0.95, 0.95, 0.95), cls=SKIN, bones=bones, tint=0.7, seg=5)
    for j in (1, 2, 3):
        b.ball(pts[j], 0.011, "ffd0ff", cls=CRYSTAL, bone=names[min(j, len(names) - 1)], seg=6, rings=4, mat=MAT_GLOW)
for k in range(32):
    a = 2 * math.pi * k / 32 + 0.05
    root = V(math.cos(a) * 0.59, Y - 0.14, math.sin(a) * 0.59)
    ln = 0.18 + 0.08 * math.sin(k * 1.7)
    strand(b, [root, root + V(math.cos(a) * 0.02, -ln * 0.5, math.sin(a) * 0.02), root + V(math.cos(a) * 0.01, -ln, math.sin(a) * 0.01)], 0.006, 0.0015, (0.95, 0.95, 0.95), cls=CRYSTAL, bone="bell", seg=4, per=3, tint=1.0, mat=MAT_PLAIN)

T_IDLE = 2.4


def pulse_pose(t, speed, amp):
    p = zero_pose(r)
    ph = t * speed
    pul = math.sin(ph)
    p["bell"] = ((0, 0, 0), (0, 0.06 * math.sin(ph - 0.6), 0), (1.0 + 0.06 * pul, 1.0 - 0.08 * pul, 1.0 + 0.06 * pul))
    p["root"] = ((0, 0, 0), (0, 0.05 * math.sin(ph - 2.0), 0))
    for k, (names, _) in enumerate(tent):
        wave_chain(p, names, t + k * 0.13, speed, amp, axis=0, lag=0.9, grow=0.3)
    for k, (names, _) in enumerate(arms):
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
    add(p, "root", (0.1 * f, 0, 0.15 * f), (0, -1.38 * f + 0.04 * math.sin(math.pi * smooth(0.7, 0.86, k)), 0))
    p["bell"] = (p["bell"][0], p["bell"][1], (1.0 + 0.35 * f, 1.0 - 0.55 * f, 1.0 + 0.35 * f))
    for k2, (names, _) in enumerate(tent):
        a = 2 * math.pi * k2 / N_T
        for j, nm in enumerate(names):
            add(p, nm, (-math.sin(a) * 1.2 * f / (j + 1), 0.0, math.cos(a) * 1.2 * f / (j + 1)))
    return p

print("[art] jelly: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/jelly.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.35)
