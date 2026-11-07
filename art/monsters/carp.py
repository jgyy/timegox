"""Carp: the golden koi of the Hanging Falls and the river carp of the Nine Bends (Part VI).  A
deep-bodied fish hovering above the ground as if it swam through air: overlapping scales, a
dorsal fin, long flowing pectoral, pelvic and tail fins made of layered ribbons, barbels at the
mouth and a pearl-like eye.  The body is a five-bone chain so it swims with a travelling wave.
Tinted by the game per enemy; white patches (koi markings), eyes and barbels keep their colours.
Scales are painted as rows of overlapping cycloid scales with darker rims, a lateral
line runs down each flank, the gill cover has its edge, and fine rays stiffen every fin.
Run: blender --background --python art/monsters/carp.py  ->  assets/monsters/carp.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import chain_weights, eyes, zero_pose  # noqa: E402
from sculpt import smooth  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, V, Builder, Rig, env  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.05
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
zs = [0.75, 0.38, 0.0, -0.38, -0.72, -1.02]
for i in range(5):
    r.bone("body%d" % i, (0, Y, zs[i]), (0, Y, zs[i + 1]), "root" if i == 0 else "body%d" % (i - 1))
r.bone("tailfin", (0, Y, zs[5]), (0, Y, zs[5] - 0.4), "body4")
r.bone("jaw", (0, Y - 0.05, 0.62), (0, Y - 0.08, 0.86), "body0")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("pec." + sd, (0.18 * s, Y - 0.12, 0.42), (0.42 * s, Y - 0.3, 0.2), "body0")
    r.bone("pelv." + sd, (0.12 * s, Y - 0.2, -0.15), (0.3 * s, Y - 0.42, -0.35), "body2")
b = Builder("carp")


def body_bone(z):
    f = 0.0
    for i in range(5):
        if z <= zs[i] and z >= zs[i + 1]:
            f = i + (zs[i] - z) / (zs[i] - zs[i + 1])
            break
    if z > zs[0]:
        f = 0.0
    if z < zs[5]:
        f = 4.99
    return chain_weights("body", f, 5)


def koi(p):
    """Grey body (tinted) with white koi patches (untinted)."""
    n = math.sin(p.z * 5.5 + p.x * 9.0) * math.cos(p.z * 3.1 - p.y * 7.0)
    if n > 0.35 and p.y > Y - 0.05:
        return (1.0, 1.0, 1.0)
    v = 0.85 if p.y > Y else 1.05
    return (v, v, v)


# body: a lathe along z, deep in the middle, with a smooth taper into the tail stalk
prof = [(0.03, -1.05), (0.07, -0.9), (0.12, -0.7), (0.2, -0.4), (0.26, -0.05), (0.27, 0.25), (0.23, 0.5), (0.16, 0.7), (0.09, 0.82), (0.03, 0.88)]
verts = b.lathe(V(0, Y, 0), [(rr, z) for rr, z in prof], (0.9, 0.9, 0.9), cls=SCALE, seg=22, rot=(math.pi / 2, 0, 0), squash=(0.72, 1.0), tint=1.0, bone_fn=lambda p: body_bone(p.z))
b.recolor(verts, lambda p: (1.0, 1.0, 1.0) if math.sin(p.z * 5.5 + p.x * 9.0) * math.cos(p.z * 3.1 - p.y * 7.0) > 0.4 and p.y > Y + 0.05 else None, cls=SCALE)
for v in verts:
    c = v[b.cl]
    if c[0] > 0.95:
        v[b.tl] = 0.0
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# lips, mouth and barbels
b.ellipsoid(V(0, Y - 0.04, 0.86), (0.07, 0.05, 0.06), (0.8, 0.8, 0.8), cls=SKIN, bone="jaw", tint=1.0, seg=12, rings=6)
b.ellipsoid(V(0, Y - 0.05, 0.9), (0.04, 0.025, 0.02), "301018", cls=SKIN, bone="jaw", seg=10, rings=5)
for s in (1, -1):
    b.tube([V(0.05 * s, Y - 0.05, 0.86), V(0.14 * s, Y - 0.12, 0.88), V(0.22 * s, Y - 0.24, 0.84), V(0.26 * s, Y - 0.38, 0.8)], [0.01, 0.008, 0.006, 0.002], "e8d0a0", cls=SKIN, bones=["jaw", "jaw", "body0", "body0"], seg=5)
eyes(b, V(0, Y + 0.05, 0.66), 0.16, 0.045, iris="f0d060", slit=False, glow=False, bone="body0", rot_y=1.25, h=1.0)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# gill plate
for s in (1, -1):
    b.tube([V(0.17 * s, Y + 0.12, 0.5), V(0.21 * s, Y, 0.47), V(0.18 * s, Y - 0.12, 0.5)], [0.012, 0.014, 0.01], (0.7, 0.7, 0.7), bone="body0", tint=1.0, seg=6)


def fin(pts_root, pts_tip, col, bones, tint=1.0, rows=5):
    """A fin as a sheet between a root line and a tip line, with ray stripes."""
    grid = []
    for j in range(rows):
        t = j / (rows - 1)
        grid.append([V(pts_root[i]).lerp(V(pts_tip[i]), t) for i in range(len(pts_root))])
    vs = b.sheet(grid, col, cls=CLOTH, bones=[bones] * rows, tint=tint)
    return vs


b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# dorsal fin along the back
root = [V(0, Y + 0.24, 0.35), V(0, Y + 0.27, 0.1), V(0, Y + 0.25, -0.15), V(0, Y + 0.18, -0.4)]
tip = [V(0, Y + 0.32, 0.36), V(0, Y + 0.52, 0.02), V(0, Y + 0.5, -0.28), V(0, Y + 0.3, -0.5)]
fin(root, tip, (0.8, 0.8, 0.8), {"body1": 0.5, "body2": 0.5})
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# flowing tail: three long ribbons per lobe
for s in (1, -1):
    for k in range(3):
        sp = 0.15 + 0.12 * k
        b.ribbon([V(0, Y, -1.0), V(0, Y + s * sp, -1.22), V(0.02 * k, Y + s * (sp + 0.1), -1.48), V(0.04 * k, Y + s * (sp + 0.06), -1.72)], [0.06, 0.1, 0.09, 0.03], (0, 0, 1) if False else (1, 0, 0), (0.85, 0.85, 0.85), cls=CLOTH, bones=["body4", "tailfin", "tailfin", "tailfin"], tint=1.0, col_end=(1.0, 1.0, 1.0))
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# long pectoral and pelvic fins
for s, sd in ((1, "L"), (-1, "R")):
    b.ribbon([V(0.18 * s, Y - 0.12, 0.42), V(0.32 * s, Y - 0.22, 0.32), V(0.44 * s, Y - 0.34, 0.16), V(0.5 * s, Y - 0.46, 0.0)], [0.04, 0.09, 0.08, 0.02], (0, 0, 1), (0.85, 0.85, 0.85), bones=["body0", "pec." + sd, "pec." + sd, "pec." + sd], tint=1.0, col_end=(1.0, 1.0, 1.0))
    b.ribbon([V(0.12 * s, Y - 0.2, -0.15), V(0.2 * s, Y - 0.32, -0.25), V(0.26 * s, Y - 0.44, -0.4)], [0.03, 0.06, 0.02], (0, 0, 1), (0.85, 0.85, 0.85), bones=["body2", "pelv." + sd, "pelv." + sd], tint=1.0, col_end=(1.0, 1.0, 1.0))
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# scales: rows of overlapping cycloid scales painted over the body, each rim a shade darker, the
# lateral line running down the flank, darker along the back, silvery underneath
for v in verts:
    p = kit.b2g(v.co)
    c = v[b.cl]
    sx = (0.9 - p.z) * 9.0
    ang = math.atan2(p.y - Y, abs(p.x) + 1e-4)
    sy = ang * 3.2 + 0.5 * (math.floor(sx) % 2)
    fx, fy = sx - math.floor(sx), sy - math.floor(sy)
    rim = 1.0 - 0.22 * smooth(0.28, 0.48, math.hypot(fx - 0.3, fy - 0.5))
    lateral = 1.0 - 0.3 * smooth(0.015, 0.0, abs(p.y - Y - 0.02 - 0.03 * math.sin(p.z * 2.0)))
    back = 1.0 - 0.18 * smooth(Y + 0.1, Y + 0.25, p.y)
    k = rim * lateral * back * (1.0 if p.z < 0.62 else 1.08)
    v[b.cl] = (c[0] * k, c[1] * k, c[2] * k, c[3])
# the head: a smooth operculum (gill cover) with its edge, nostrils, and a glint of gold on the brow
for s in (1, -1):
    op = [V(0.2 * s, Y + 0.16, 0.56), V(0.25 * s, Y + 0.06, 0.52), V(0.25 * s, Y - 0.06, 0.52), V(0.2 * s, Y - 0.16, 0.56)]
    b.tube(op, [0.012, 0.016, 0.016, 0.01], (0.65, 0.65, 0.65), bone="body0", tint=1.0, seg=6)
    b.ellipsoid(V(0.07 * s, Y + 0.08, 0.8), (0.015, 0.01, 0.01), "201018", cls=SKIN, bone="body0", seg=6, rings=4, mat=MAT_PLAIN)
b.ellipsoid(V(0, Y + 0.18, 0.62), (0.08, 0.03, 0.1), "f0c050", cls=SCALE, bone="body0", seg=12, rings=6)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# fin rays across the dorsal fin, and fine rays in every tail ribbon
for k in range(9):
    t = k / 8
    i = min(2, int(t * 3))
    u = t * 3 - i
    r0 = root[i].lerp(root[i + 1], u)
    t0 = tip[i].lerp(tip[i + 1], u)
    b.tube([r0, t0], [0.006, 0.002], (0.55, 0.55, 0.55), cls=CLOTH, bone={"body1": 0.5, "body2": 0.5}, tint=1.0, seg=4, mat=MAT_PLAIN)
for s in (1, -1):
    for k in range(5):
        sp = 0.12 + 0.07 * k
        b.tube([V(0, Y, -1.02), V(0.01 * k, Y + s * sp, -1.3), V(0.02 * k, Y + s * (sp + 0.06), -1.62)], [0.006, 0.004, 0.002], (0.6, 0.6, 0.6), cls=CLOTH, bones=["body4", "tailfin", "tailfin"], tint=1.0, seg=4, mat=MAT_PLAIN)
# a sparkle of pearl bubbles trailing from the mouth
for k in range(5):
    b.ball(V(0.02 * math.sin(k * 2.0), Y + 0.06 + k * 0.09, 0.95 + 0.02 * k), 0.018 + 0.006 * (k % 2), "f0f8ff", cls=CRYSTAL, bone="jaw", seg=6, rings=4, mat=MAT_GLOW)


T_IDLE = 2.4


def swim(p, t, speed, amp, hover=0.05, fin=1.3, pelv=1.1, bob=0.5, fin_amp=1.0):
    """Travelling wave down the body.  Loops pass fin/pelv/bob ratios that give whole cycles."""
    for i in range(5):
        p["body%d" % i] = ((0, math.sin(t * speed - i * 0.9) * amp * (0.4 + i * 0.25), 0), (0, 0, 0))
    p["tailfin"] = ((0, math.sin(t * speed - 5 * 0.9) * amp * 1.8, 0), (0, 0, 0))
    p["root"] = ((math.sin(t * speed * bob) * 0.04, 0, 0), (0, math.sin(t * speed * bob) * hover, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["pec." + sd] = ((math.sin(t * speed * fin) * 0.3 * fin_amp, 0, math.sin(t * speed * fin + 0.5) * 0.25 * s * fin_amp), (0, 0, 0))
        p["pelv." + sd] = ((math.sin(t * speed * pelv + 1.0) * 0.2 * fin_amp, 0, 0), (0, 0, 0))


def idle(t):
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_IDLE * 2, 0.14, fin=1.5, pelv=1.0, bob=0.5)
    p["jaw"] = ((0.1 + 0.1 * max(0.0, math.sin(t * 2 * math.pi / T_IDLE * 3)), 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.5) * math.pi)
    p = zero_pose(r)
    # the thrash builds and settles with the strike instead of snapping back to the idle swim
    swim(p, t, 16.0, 0.08 + 0.14 * e)
    p["root"] = ((0.15 * lunge, 0, 0), (0, 0.1 * lunge, 0.6 * lunge))
    p["jaw"] = ((0.6 * lunge, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = zero_pose(r)
    swim(p, t, 20.0, 0.25 * e)
    p["root"] = ((-0.3 * e, 0, 0.4 * e), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = zero_pose(r)
    # leap: arch the body like a carp climbing the dragon gate
    for i in range(5):
        p["body%d" % i] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["tailfin"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["root"] = ((-0.5 * e, 0, 0), (0, 0.4 * e, 0))
    return p


T_WALK = 1.2


def walk(t):
    """Swims through the air: a stronger travelling wave and beating pectoral fins."""
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_WALK, 0.2, hover=0.04, fin=2.0, pelv=1.0, bob=1.0)
    add(p, "root", (0.06, 0, 0))
    return p


def die(t):
    """Thrashes, rolls belly-up and sinks to the ground."""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.8, k) ** 1.3
    roll = smooth(0.1, 0.6, k)
    p = zero_pose(r)
    swim(p, t, 20.0 * (1.0 - f) + 0.5, 0.25 * (1.0 - f), hover=0.05 * (1.0 - f), fin_amp=1.0 - f)
    add(p, "root", (0, 0, math.pi * roll), (0, -0.82 * f, 0))
    for i in range(5):
        add(p, "body%d" % i, (0.05 * f, 0, 0))
    return p

print("[art] carp: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/carp.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.45)
