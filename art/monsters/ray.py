"""Ray: the manta rays that glide through the sky over the Sea of Clouds (Sky Manta Sovereign and
its shoals), the Great Wind Kite and Kun of the Northern Darkness.  After the manta (the Florida
Museum and Manta Trust species profiles):

* a broad diamond: two great pectoral wings, their leading edges bowed forward from the head and
  their trailing edges hollowed, ending in long pointed tips swept back like sickles;
* a thick domed body in the middle (the side view is a body with wings, not a flat triangle),
  thinning quickly into the wings, flat underneath;
* the head in front of the wings: a wide mouth at the very front between two cephalic fins, rolled
  into horns as a manta rolls them when it swims, and the eyes on the sides of the head behind them;
* a whip of a tail, shorter than the span, with a small dorsal fin at its root;
* a manta's colours: a dark back with pale shoulder chevrons curving back from behind the eyes,
  darker margins to the wings, a white belly with the gill slits and a few dark spots.

The back takes the enemy's colour (a hide: assets.gd NATURAL), the chevrons its underside colour and
the margins its markings; the belly stays white.  Wings ripple from root to tip.
Clips: idle (gliding on slow wingbeats), walk (deeper beats, banking), attack (a diving lunge),
hurt, die (stalls and settles flat on the ground) and cast (rears up, wings raised).
Run: blender --background --python art/monsters/ray.py  ->  assets/monsters/ray.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import add, chain_rig, wave_chain, zero_pose  # noqa: E402
from sculpt import catmull, loft, smooth  # noqa: E402
from kit import SKIN, MAT_PLAIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.4
SPAN = 1.36
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y, -0.4), (0, Y, 0.5), "root")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("wing1." + sd, (0.25 * s, Y, 0.0), (0.75 * s, Y - 0.02, -0.1), "body")
    r.bone("wing2." + sd, (0.75 * s, Y - 0.02, -0.1), (1.3 * s, Y - 0.08, -0.35), "wing1." + sd)
    r.bone("ceph." + sd, (0.19 * s, Y - 0.02, 0.54), (0.17 * s, Y - 0.1, 0.78), "body")
tail = chain_rig(r, "tail", [V(0, Y + 0.01, -0.6), V(0, Y, -0.88), V(0, Y - 0.02, -1.2), V(0, Y - 0.05, -1.55)], "body")
b = Builder("ray")


def wing_w(p):
    ax = abs(p.x)
    sd = "L" if p.x > 0 else "R"
    if ax < 0.24:
        return {"body": 1.0}
    if ax < 0.7:
        k = smooth(0.24, 0.7, ax)
        return {"body": 1.0 - k, "wing1." + sd: k}
    k = smooth(0.7, 1.15, ax)
    return {"wing1." + sd: 1.0 - k, "wing2." + sd: k}


# ---------------------------------------------------------------- the disc: spanwise sections
def z_front(x):
    x = abs(x)
    if x <= 0.2:
        return 0.62 - 0.12 * (x / 0.2) ** 2
    return 0.5 - 0.92 * ((x - 0.2) / (SPAN - 0.2)) ** 1.5 + 0.06 * math.sin(math.pi * min(1.0, (x - 0.2) / 0.7)) * (1.0 - smooth(0.6, 1.1, x))


def z_back(x):
    x = abs(x)
    if x <= 0.28:
        return -0.62 + 0.08 * (x / 0.28) ** 2
    u = min(1.0, (SPAN - x) / (SPAN - 0.28))
    return -0.44 + 0.15 * math.sin(math.pi * min(1.0, u * 1.05)) - 0.1 * smooth(0.5, 0.28, x)


def thick(x):
    x = abs(x)
    body = 0.33 * math.exp(-(x / 0.2) ** 2)
    wing = 0.075 * (1.0 - smooth(0.2, SPAN, x)) ** 1.6 + 0.012
    return max(body, wing) + 0.04 * math.exp(-(x / 0.3) ** 2)


def y_mid(x):
    u = abs(x) / SPAN
    return Y + 0.03 * (1.0 - u) - 0.07 * u * u


NS, NC = 141, 72
xs = [SPAN * math.copysign(abs(-1.0 + 2.0 * k / (NS - 1)) ** 1.0, -1.0 + 2.0 * k / (NS - 1)) for k in range(NS)]
xs = [max(-SPAN * 0.995, min(SPAN * 0.995, x)) for x in xs]


def section(x):
    zf, zb = z_front(x), z_back(x)
    if zf - zb < 0.02:
        zf, zb = zf + 0.01, zb - 0.01
    t = thick(x)
    yc = y_mid(x)
    pts = []
    # the thickest point lies a third back on a wing, nearer the middle on the body
    peak = 0.35 if abs(x) > 0.3 else 0.45
    for i in range(NC):
        a = 2 * math.pi * i / NC
        u = 0.5 - 0.5 * math.cos(a)                 # 0 at the front edge .. 1 at the back edge
        top = math.sin(a) >= 0
        # a domed back, a flatter belly; the section's depth peaks at `peak`
        prof = (math.sin(math.pi * u ** (math.log(0.5) / math.log(peak)))) ** 0.75
        y = yc + (0.62 if top else -0.38) * t * prof
        z = zf + (zb - zf) * u
        pts.append(V(x, y, z))
    return pts


def chevron(x, z):
    """The pale shoulder patches: two across the shoulders behind the head, their front edges
    following the leading edge of the wings, a dark band down the middle between them."""
    ax = abs(x)
    front = z_front(ax) - 0.1 - 0.05 * smooth(0.1, 0.45, ax)
    d = math.hypot((ax - 0.3) / 0.22, (z - (front - 0.13)) / 0.12)
    return smooth(1.0, 0.6, d) * smooth(0.06, 0.13, ax) * smooth(0.0, 0.04, front - z)


def back_col(q, j, i):
    if q.y < y_mid(q.x):
        # the belly: white, with a few dark spots between the gill slits and a charcoal margin
        spot = 0.0
        for (sx, sz, sr) in ((0.06, 0.05, 0.035), (-0.09, 0.0, 0.03), (0.02, -0.14, 0.028), (-0.04, 0.15, 0.022)):
            spot = max(spot, smooth(sr, sr * 0.6, math.hypot(q.x - sx, q.z - sz)))
        rim = smooth(0.82, 1.0, abs(q.x) / SPAN) * 0.35
        v = 0.97 * (1.0 - 0.75 * spot) * (1.0 - rim)
        return (v, v, v)
    u = abs(q.x) / SPAN
    v = 0.62 - 0.06 * smooth(0.0, 0.3, u)
    # darker margins and wing tips (the markings)
    edge = smooth(0.7, 1.0, u) + 0.6 * smooth(0.04, 0.0, abs(q.z - z_front(q.x)) - 0.02) * smooth(0.3, 0.6, u)
    v *= 1.0 - 0.4 * min(1.0, edge)
    # the pale chevrons (the underside colour)
    ch = chevron(q.x, q.z)
    v = v * (1.0 - ch) + 0.95 * ch
    return (v, v, v)


def tint_of(q):
    return 0.0 if q.y < y_mid(q.x) else 1.0


rings = [section(x) for x in xs]
b.cur_pal = 0.0
loft(b, rings, (0.6, 0.6, 0.6), cls=SKIN, col_fn=back_col, bone_fn=wing_w, tint_fn=tint_of, cap0=True, cap1=True, cap_push=0.15)


def surf(x, z, top=True):
    """Height of the back (or the belly) at (x, z)."""
    zf, zb = z_front(x), z_back(x)
    u = max(0.0, min(1.0, (z - zf) / (zb - zf)))
    peak = 0.35 if abs(x) > 0.3 else 0.45
    prof = (math.sin(math.pi * u ** (math.log(0.5) / math.log(peak)))) ** 0.75
    return y_mid(x) + (0.62 if top else -0.38) * thick(x) * prof


# ---------------------------------------------------------------- the head
# the mouth: a wide dark slit across the front of the head, its lips pale
mz = z_front(0.0)
b.ellipsoid(V(0, Y - 0.025, mz - 0.01), (0.15, 0.03, 0.03), "1a1418", cls=SKIN, bone="body", seg=16, rings=6, mat=MAT_PLAIN)
b.cur_pal = 0.0
lip = [V(math.sin(a) * 0.16, Y - 0.025 + math.cos(a) * 0.04, mz - 0.012 + 0.012 * abs(math.cos(a))) for a in [math.pi * 0.5 + i / 16 * math.pi * 2 for i in range(17)]]
b.tube(lip, [0.012] * 17, (0.8, 0.8, 0.8), cls=SKIN, bone="body", seg=6, cap0=False, cap1=False, tint=1.0)
for s, sd in ((1, "L"), (-1, "R")):
    # the cephalic fins, rolled into horns: forward, then curling down and in
    cp = [V(0.19 * s, Y - 0.005, 0.53), V(0.215 * s, Y - 0.02, 0.64), V(0.205 * s, Y - 0.055, 0.74), V(0.165 * s, Y - 0.1, 0.79), V(0.12 * s, Y - 0.13, 0.77)]
    radii = [(0.05, 0.035), (0.042, 0.03), (0.032, 0.024), (0.02, 0.016), (0.006, 0.006)]
    cps = catmull(cp, 4)
    rr = []
    for k in range(len(cps)):
        f = k / (len(cps) - 1) * (len(radii) - 1)
        i0 = int(min(len(radii) - 2, f))
        t = f - i0
        rr.append((radii[i0][0] + (radii[i0 + 1][0] - radii[i0][0]) * t, radii[i0][1] + (radii[i0 + 1][1] - radii[i0][1]) * t))
    cols = [(0.55 - 0.15 * (k / (len(cps) - 1)),) * 3 for k in range(len(cps))]
    b.tube(cps, rr, (0.55, 0.55, 0.55), cls=SKIN, bones=[{"body": 1.0 - min(1.0, k / 3.0), "ceph." + sd: min(1.0, k / 3.0)} for k in range(len(cps))],
           seg=10, tint=1.0, cols=cols, up=(0, 1, 0))
    # the eye on the side of the head behind the horn
    ep = V(0.215 * s, surf(0.215, 0.44) - 0.035, 0.44)
    A.animal_eye(b, ep, V(1.0 * s, 0.05, 0.25), 0.03, "2a2a34", "body", pupil="round", almond=0.95, side=s, lid="1a1418", lid_w=0.1, accent=False)
    # gill slits on the belly
    for k in range(5):
        gx = (0.12 + 0.015 * k) * s
        gz = 0.3 - 0.045 * k
        a0 = V(gx, surf(gx, gz, False) - 0.004, gz)
        a1 = V(gx + 0.05 * s, surf(gx + 0.05 * s, gz - 0.02, False) - 0.004, gz - 0.02)
        b.tube([a0, a1], [0.006, 0.006], "5a5560", cls=SKIN, bone="body", seg=4, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the tail: a whip with a small dorsal fin at its root
tp = [r.head(n) for n in tail] + [r.tail(tail[-1])]
b.tube(tp, [(0.05, 0.035), (0.03, 0.022), (0.015, 0.012), (0.004, 0.004)], (0.55, 0.55, 0.55), cls=SKIN,
       bones=[{"body": 0.6, tail[0]: 0.4}, tail[0], tail[1], tail[2]], tint=1.0, seg=8, up=(0, 1, 0))
fin_root = V(0, surf(0.0, -0.56) - 0.012, -0.56)
b.cur_pal = 0.0
b.ellipsoid(fin_root + V(0, 0.035, -0.03), (0.012, 0.06, 0.075), (0.5, 0.5, 0.5), cls=SKIN, bone="body", rot=(0.55, 0, 0), seg=10, rings=8, tint=1.0)


T_IDLE = 2.6


def flap(p, t, speed, amp):
    for sd, s in (("L", 1), ("R", -1)):
        p["wing1." + sd] = ((0, 0, math.sin(t * speed) * amp * s), (0, 0, 0))
        p["wing2." + sd] = ((0, 0, math.sin(t * speed - 0.9) * amp * 1.2 * s), (0, 0, 0))
        p["ceph." + sd] = ((math.sin(t * speed * 2) * 0.12, 0, 0), (0, 0, 0))
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
    add(p, "body", (0.3 * f * (1.0 - f) * 2.0, 0, 0.2 * f * (1.0 - smooth(0.4, 0.7, k))), (0, -1.88 * f + 0.04 * math.sin(math.pi * smooth(0.72, 0.88, k)), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "wing2." + sd, (0, 0, s_ * 0.25 * f))
        add(p, "ceph." + sd, (-0.55 * f, 0, 0))
    return p


kit.scale_asset(b, r, 1.45)
print("[art] ray: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/ray.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.3, strength=0.4)
