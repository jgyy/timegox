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
from creature import chain_rig, glow_ball, wave_chain, zero_pose  # noqa: E402
from sculpt import catmull, strand  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
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
b.lathe(V(0, Y, 0), prof, (0.85, 0.85, 0.85), cls=CRYSTAL, bone="bell", seg=32, col_top=(1.0, 1.0, 1.0), tint=1.0, folds=(16, 0.04, 0.0))
b.lathe(V(0, Y, 0), [(0.5, -0.1), (0.48, 0.02), (0.38, 0.17), (0.2, 0.27), (0.001, 0.3)], (0.6, 0.6, 0.6), cls=CRYSTAL, bone="bell", seg=28, tint=1.0, cap_bottom=False)
for k in range(16):
    a = 2 * math.pi * k / 16
    b.ellipsoid(V(math.cos(a) * 0.58, Y - 0.13, math.sin(a) * 0.58), (0.07, 0.035, 0.05), (0.95, 0.95, 0.95), cls=CRYSTAL, bone="bell", tint=1.0, seg=8, rings=5, rot=(0, -a, 0))
    # sense organ (rhopalium) in each notch between lappets
    a2 = a + math.pi / 16
    b.ball(V(math.cos(a2) * 0.57, Y - 0.1, math.sin(a2) * 0.57), 0.013, "fff8a0", cls=CRYSTAL, bone="bell", seg=6, rings=4, mat=MAT_GLOW)
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
    b.tube(shoe, [0.022] * 9, "fff0ff", cls=CRYSTAL, bone="bell", seg=6, mat=MAT_GLOW)
glow_ball(b, V(0, Y + 0.05, 0), 0.1, "ffe8ff", "bell")
# a pair of eyes so the spirit has a face
for s in (1, -1):
    b.eye(V(0.16 * s, Y + 0.12, 0.52), 0.05, "40e0ff", side=s, bone="bell", rot_y=0.35, h=1.2, glow=True)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# oral arms: long frilled curtains - each a pair of crossed ribbons whose edges ruffle
for names, pts in arms:
    fine = catmull(pts, 3)
    bones = [names[min(len(names) - 1, int(i / (len(fine) - 1) * len(names)))] for i in range(len(fine))]
    for side in ((1, 0, 0), (0, 0, 1)):
        sv = V(side)
        rows = []
        for i, q in enumerate(fine):
            t = i / (len(fine) - 1)
            w = 0.09 * (1.0 - 0.5 * t)
            ruffle = 0.025 * math.sin(i * 2.2) * (0.4 + t)
            rows.append([q - sv * w + V(0, 0, ruffle), q, q + sv * w - V(0, 0, ruffle)])
        b.sheet(rows, (0.9, 0.9, 0.9), bones=bones, cols=[(0.85 + 0.15 * (i / (len(fine) - 1)),) * 3 for i in range(len(fine))], tint=1.0, thickness=0.006)
    for i in range(1, len(fine), 3):
        b.ball(fine[i] + V(0.05, 0, 0.02), 0.012, "ffd0ff", cls=CRYSTAL, bone=bones[i], seg=5, rings=3, mat=MAT_GLOW)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# trailing tentacles: thin tubes with glowing beads, and a fringe of fine rim tentacles
for names, pts in tent:
    bones = [names[0]] + [names[min(j, len(names) - 1)] for j in range(len(pts) - 1)]
    b.tube(pts, [0.022, 0.018, 0.014, 0.01, 0.003], (0.9, 0.9, 0.9), cls=CRYSTAL, bones=bones, tint=1.0, seg=6)
    for j in (1, 2, 3):
        b.ball(pts[j], 0.02, "ffd0ff", cls=CRYSTAL, bone=names[min(j, len(names) - 1)], seg=6, rings=4, mat=MAT_GLOW)
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
    p["root"] = ((0, 0, 0), (0, 0.08 * math.sin(ph * 0.5), 0))
    for k, (names, _) in enumerate(tent):
        wave_chain(p, names, t + k * 0.13, speed, amp, axis=0, lag=0.9, grow=0.3)
    for k, (names, _) in enumerate(arms):
        wave_chain(p, names, t + k * 0.3, speed * 0.7, amp * 0.8, axis=2, lag=0.7)
    return p


def idle(t):
    return pulse_pose(t, 2 * math.pi / T_IDLE, 0.12)


def attack(t):
    k = t / 0.6
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


print("[art] jelly: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/jelly.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.35)
