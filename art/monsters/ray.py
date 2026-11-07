"""Ray: the manta rays that glide through the sky over the Sea of Clouds (Sky Manta Sovereign and
its shoals) and the abyss.  A broad diamond body with two great wings that ripple from root to
tip, curled cephalic fins framing the mouth, a pale belly with gill slits, a dorsal ridge and a
long whip tail.  Tinted by the game per enemy; the belly and eyes keep their colours.
The back is mottled with pale rosettes and a dark margin; spiracles sit behind raised eye
bulges, tubercles run down the spine, a serrated barb rides the tail and the wing edges glow.
Run: blender --background --python art/monsters/ray.py  ->  assets/monsters/ray.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import chain_rig, wave_chain, zero_pose  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.4
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y, -0.4), (0, Y, 0.5), "root")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("wing1." + sd, (0.25 * s, Y, 0.0), (0.75 * s, Y, -0.1), "body")
    r.bone("wing2." + sd, (0.75 * s, Y, -0.1), (1.3 * s, Y, -0.3), "wing1." + sd)
    r.bone("ceph." + sd, (0.18 * s, Y, 0.45), (0.22 * s, Y - 0.08, 0.7), "body")
tail = chain_rig(r, "tail", [V(0, Y, -0.55), V(0, Y, -0.95), V(0, Y - 0.02, -1.4), V(0, Y - 0.05, -1.9)], "body")
b = Builder("ray")


def wing_w(p):
    ax = abs(p.x)
    sd = "L" if p.x > 0 else "R"
    if ax < 0.25:
        return {"body": 1.0}
    if ax < 0.75:
        k = (ax - 0.25) / 0.5
        return {"body": 1.0 - k, "wing1." + sd: k}
    k = min(1.0, (ax - 0.75) / 0.55)
    return {"wing1." + sd: 1.0 - k, "wing2." + sd: k}


# the body: a grid sheet shaped into a diamond with a domed centre (top tinted, belly pale)
NX, NZ = 17, 11
top = []
bot = []
for j in range(NZ):
    z = 0.62 - j * 1.1 / (NZ - 1)
    half = 1.3 * math.sin(math.pi * min(1.0, (0.62 - z) / 1.1 * 1.05 + 0.02)) ** 0.8 * (1.0 - 0.25 * (0.62 - z))
    rt = []
    rb = []
    for i in range(NX):
        u = i / (NX - 1) * 2 - 1
        x = u * half
        dome = 0.16 * (1 - abs(u)) ** 1.5 * math.sin(math.pi * (j + 0.5) / NZ)
        sweep = -0.18 * abs(u) ** 2
        rt.append(V(x, Y + dome + 0.01, z + sweep))
        rb.append(V(x, Y - dome * 0.5 - 0.01, z + sweep))
    top.append(rt)
    bot.append(rb)
b.sheet(top, (0.75, 0.75, 0.75), cls=SCALE, bone="body", tint=1.0, thickness=0.02)
b.sheet(bot, "f0f0f0", cls=SCALE, bone="body", thickness=0.01)
# the sheets were bound to the body; re-bind every vertex across body and wing bones by its span
for v in b.bm.verts:
    w = wing_w(kit.b2g(v.co))
    v[b.dl].clear()
    for nm, wt in w.items():
        if wt > 1e-4:
            v[b.dl][b.gi(nm)] = wt
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# dorsal ridge and gill slits
b.tube([V(0, Y + 0.17, 0.3), V(0, Y + 0.19, 0.0), V(0, Y + 0.12, -0.45)], [0.05, 0.06, 0.03], (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=8)
for s in (1, -1):
    for k in range(4):
        b.tube([V((0.12 + k * 0.03) * s, Y - 0.04, 0.3 - k * 0.05), V((0.16 + k * 0.03) * s, Y - 0.04, 0.26 - k * 0.05)], [0.006, 0.006], "6a6a7a", cls=SKIN, bone="body", seg=4)
    sd = "L" if s > 0 else "R"
    cp = r.bones["ceph." + sd]
    b.tube([cp[0], V(cp[0]).lerp(V(cp[1]), 0.5) + V(0.03 * s, 0.03, 0), cp[1]], [(0.05, 0.02), (0.045, 0.018), (0.01, 0.008)], (0.7, 0.7, 0.7), cls=SCALE, bone="ceph." + sd, tint=1.0, seg=8)
    b.eye(V(0.22 * s, Y + 0.05, 0.4), 0.04, "a0f0ff", side=s, bone="body", rot_y=1.2, h=1.0, glow=True)
b.ellipsoid(V(0, Y - 0.02, 0.6), (0.14, 0.03, 0.03), "302028", cls=SKIN, bone="body", seg=10, rings=4)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# whip tail with a sting
tp = [r.head(n) for n in tail] + [r.tail(tail[-1])]
b.tube(tp, [0.05, 0.035, 0.02, 0.006], (0.7, 0.7, 0.7), cls=SCALE, bones=[tail[0], tail[0], tail[1], tail[2]], tint=1.0, seg=7)
# markings: a scatter of pale rosettes on the back and a dark margin round the disc
for v in b.bm.verts:
    p = kit.b2g(v.co)
    c = v[b.cl]
    if p.y < Y + 0.005 or c[3] < 0.2:
        continue
    spot = fbm3((p.x * 7.0, 0.0, p.z * 7.0), 2, 5)
    k = 1.0
    if spot > 0.62:
        k = 1.35
    elif 0.57 < spot <= 0.62:
        k = 0.7
    edge = math.hypot(p.x / 1.3, (p.z - 0.0) / 0.7)
    k *= 1.0 - 0.3 * smooth(0.82, 0.98, edge)
    v[b.cl] = (min(1.0, c[0] * k), min(1.0, c[1] * k), min(1.0, c[2] * k), c[3])
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# spiracles behind the eyes, a row of tubercles down the back, and a serrated barb on the tail
for s in (1, -1):
    b.ellipsoid(V(0.2 * s, Y + 0.07, 0.25), (0.03, 0.012, 0.04), "302028", cls=SKIN, bone="body", seg=8, rings=4)
    b.ellipsoid(V(0.22 * s, Y + 0.06, 0.4), (0.06, 0.05, 0.06), (0.75, 0.75, 0.75), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
for k in range(7):
    b.cone(V(0, Y + 0.2 - k * 0.01, 0.2 - k * 0.1), 0.02, 0.05, (0.85, 0.85, 0.85), cls=STONE, bone="body", tint=1.0, seg=6, rot=(-0.4, 0, 0))
barb = tp[1].lerp(tp[2], 0.3)
d = (tp[2] - tp[1]).normalized()
b.tube([barb, barb + d * 0.18 + V(0, 0.03, 0)], [0.015, 0.002], "e8e0d0", cls=STONE, bone=tail[1], seg=6)
for k in range(5):
    q = barb + d * (0.03 + k * 0.03) + V(0, 0.01 + 0.004 * k, 0)
    for s in (1, -1):
        b.cone(q + V(0.012 * s, 0, 0), 0.004, 0.02, "e8e0d0", cls=STONE, bone=tail[1], seg=4, rot=(0, 0, -1.4 * s))
# a faint bioluminescent rim along the wing edges
for s in (1, -1):
    edge = []
    for j in range(9):
        t = j / 8
        z = 0.5 - t * 1.0
        half = 1.25 * math.sin(math.pi * min(1.0, (0.62 - z) / 1.1 * 1.05 + 0.02)) ** 0.8 * (1.0 - 0.25 * (0.62 - z))
        edge.append(V(half * s * 0.98, Y + 0.02, z - 0.18 * 0.96))
    b.tube(edge, [0.008] * 9, "a0f0ff", cls=CRYSTAL, bones=[wing_w(p) for p in edge], seg=4, mat=MAT_GLOW)


T_IDLE = 2.6


def flap(p, t, speed, amp):
    for sd, s in (("L", 1), ("R", -1)):
        p["wing1." + sd] = ((0, 0, math.sin(t * speed) * amp * s), (0, 0, 0))
        p["wing2." + sd] = ((0, 0, math.sin(t * speed - 0.9) * amp * 1.2 * s), (0, 0, 0))
        p["ceph." + sd] = ((math.sin(t * speed * 2) * 0.15, 0, 0), (0, 0, 0))
    wave_chain(p, tail, t, speed, 0.2, axis=1, lag=0.8)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    flap(p, t, w, 0.35)
    p["body"] = ((math.sin(t * w) * 0.05, 0, math.sin(t * w + 1.4) * 0.05), (0, math.sin(t * w + 1.2) * 0.12, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    dive = math.sin(min(1.0, k * 1.5) * math.pi)
    p = zero_pose(r)
    flap(p, t, 16.0, 0.2 + 0.3 * e)
    p["body"] = ((0.4 * dive, 0, 0), (0, -0.3 * dive, 0.6 * dive))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = zero_pose(r)
    flap(p, t, 22.0, 0.25 * e)
    p["body"] = ((-0.3 * e, 0, 0.4 * e), (0, 0.1 * e, -0.2 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = zero_pose(r)
    flap(p, t, 6.0, 0.7 * e)
    p["body"] = ((-0.5 * e, 0, 0), (0, 0.35 * e, 0))
    return p


T_WALK = 1.3


def walk(t):
    """Glides forward on deeper wingbeats, banking a little with each stroke."""
    w = 2 * math.pi / T_WALK
    p = zero_pose(r)
    flap(p, t, w, 0.45)
    add(p, "body", (0.12 + 0.05 * math.sin(t * w), 0, 0.08 * math.sin(t * w)), (0, 0.08 * math.sin(t * w + 1.2), 0))
    return p


def die(t):
    """Stalls, side-slips and settles flat on the ground, the wing tips curling."""
    k = min(1.0, t / 1.2)
    f = smooth(0.1, 0.75, k) ** 1.4
    p = zero_pose(r)
    flap(p, t, 6.0 * (1.0 - f) + 0.5, 0.3 * (1.0 - f))
    add(p, "body", (0.3 * f * (1.0 - f) * 2.0, 0, 0.4 * f * (1.0 - smooth(0.6, 0.88, k))), (0, -1.95 * f + 0.04 * math.sin(math.pi * smooth(0.72, 0.88, k)), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "wing2." + sd, (0, 0, s_ * 0.25 * f))
    return p

kit.scale_asset(b, r, 1.45)
print("[art] ray: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/ray.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.3, strength=0.4)
