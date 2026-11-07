"""Dragon: an eastern lung (Azure Dragon King, Frost Wyrm, Bone Wyrm, Ink Dragon ...).  Built on
the "nine resemblances" of the loong: a horse-like head with a heavy brow and flared nostrils,
deer antlers, ox ears, a snake's body covered in rows of carp scales over a clam-ridged belly,
eagle talons, flame tufts at the elbows and tail, long whiskers and a beard, and the pearl it
chases.  The ten-bone spine undulates as it hovers.
Run: blender --background --python art/monsters/dragon.py  ->  assets/monsters/dragon.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import catmull, chain_weights, eyes, fangs, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import blob3, loft, morph_sphere, prof_d, section, smooth, strand  # noqa: E402

kit.reset()
N = 10
P = []
for i in range(N + 1):
    P.append(V(0.38 * math.sin(i * 0.85), 1.75 - i * 0.1 + 0.28 * math.sin(i * 0.9 + 0.4), 0.9 - i * 0.34))
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
for i in range(N):
    r.bone("seg%d" % i, P[i], P[i + 1], "root" if i == 0 else "seg%d" % (i - 1))
H0 = P[0]
r.bone("head", H0, H0 + V(0, 0.08, 0.5), "seg0")
r.bone("jaw", H0 + V(0, -0.08, 0.12), H0 + V(0, -0.14, 0.55), "head")
for li, seg in ((0, 1), (1, 6)):
    for s, sd in ((1, "L"), (-1, "R")):
        base = P[seg] + V(0.14 * s, -0.12, 0)
        r.bone("leg%d.%s" % (li, sd), base, base + V(0.18 * s, -0.25, 0.08), "seg%d" % seg)
        r.bone("foot%d.%s" % (li, sd), base + V(0.18 * s, -0.25, 0.08), base + V(0.22 * s, -0.42, 0.16), "leg%d.%s" % (li, sd))

b = Builder("dragon")
pts, idx = catmull(P, per=6)
n = len(pts)
radii = []
for k, f in enumerate(idx):
    t = f / N
    radii.append(0.2 * (1 - t) ** 0.8 + 0.035 + 0.03 * math.sin(t * math.pi))
bw = [chain_weights("seg", f, N) for f in idx]
frames = []
for i in range(n):
    tan = (pts[min(n - 1, i + 1)] - pts[max(0, i - 1)]).normalized()
    side = tan.cross(V(0, 1, 0))
    side = side.normalized() if side.length > 0.2 else V(1, 0, 0)
    up = side.cross(tan).normalized()
    if up.y < 0:
        up = -up
    frames.append((tan, side, up))
along = [0.0]
for i in range(1, n):
    along.append(along[-1] + (pts[i] - pts[i - 1]).length)


def carp_scales(p, j, i):
    """Rows of overlapping round scales (the carp's), each darker at its rim, paler underneath."""
    tan, side, up = frames[j]
    rel = (p - pts[j]).normalized()
    u = rel.dot(up)
    ang = math.atan2(rel.dot(side), u)
    rr = radii[j]
    sx = along[j] / (rr * 0.55 + 0.03)
    sy = ang * 2.2
    sy += 0.5 * (math.floor(sx) % 2)
    fx, fy = sx - math.floor(sx), sy - math.floor(sy)
    rim = smooth(0.25, 0.48, math.hypot(fx - 0.3, fy - 0.5))
    v = 0.6 + 0.2 * (0.5 + 0.5 * u) - 0.16 * rim
    return (v, v, v)


rings = [section(pts[i], frames[i][0], prof_d(radii[i] * 1.05, radii[i], 0.5), 18, up=frames[i][2]) for i in range(n)]
loft(b, rings, (0.75, 0.75, 0.75), cls=SCALE, col_fn=carp_scales, bones=bw, tint=1.0, cap0=False, cap1=True, cap_push=0.6)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# belly: segmented plates like a clam's ridges, pale and only partly tinted
for i in range(1, n - 1):
    if i % 2:
        continue
    tan, side, up = frames[i]
    rr = radii[i]
    band = [pts[i] - up * rr * 0.66 + side * rr * 0.85 * math.sin(a) - up * rr * 0.28 * math.cos(a) for a in [(-1.3 + 2.6 * k / 8) for k in range(9)]]
    b.tube(band, [(rr * 0.1, rr * 0.035)] * 9, "f0e0b0", cls=SCALE, bone=bw[i], tint=0.35, seg=6, up=tuple(tan))
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# dorsal crest: serrated spines along the back, a flowing mane of hair over the neck
for k in range(2, n - 2):
    tan, side, up = frames[k]
    t = idx[k] / N
    if k % 2 == 0:
        h = 0.2 * (1 - t) + 0.06
        root = pts[k] + up * radii[k] * 0.85
        b.leaf(root, root + up * h - tan * 0.1, 0.06, (0.45, 0.45, 0.45), side=tan, cls=STONE, bone=bw[k], tint=1.0, col_tip=(0.85, 0.85, 0.85), curl=0.05)
    if t < 0.35:
        for j in (-1, 1):
            root = pts[k] + up * radii[k] * 0.7 + side * radii[k] * 0.45 * j
            strand(b, [root, root + side * 0.06 * j + up * 0.05 - tan * 0.08, root + side * 0.14 * j - up * 0.06 - tan * 0.22], 0.03, 0.003, (0.5, 0.5, 0.5), col_tip=(0.9, 0.9, 0.9), cls=HAIR, bone=bw[k], flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# tail: a fan of flame-like tufts
tip = pts[-1]
tan = frames[-1][0]
for k in range(9):
    a = k / 9 * 2 * math.pi
    out = frames[-1][1] * math.cos(a) + frames[-1][2] * math.sin(a)
    strand(b, [tip, tip + out * 0.08 + tan * 0.12, tip + out * 0.16 + tan * 0.32 + V(0, 0.04, 0)], 0.04, 0.003, (0.5, 0.5, 0.5), col_tip=(0.95, 0.95, 0.95), cls=HAIR, bone="seg%d" % (N - 1), flat=0.35, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# head: a long horse-like face with a heavy brow, flared nostrils on a raised nose, cheek
# spikes, ox ears, deer antlers, long whiskers and a beard
hb = "head"
hf = A.HeadFrame(H0 + V(0, 0.06, 0.1), V(0, -0.06, 1.0))


def skull(d):
    p = V(d.x * 0.19, d.y * 0.15, d.z * 0.22)
    front = smooth(0.0, 1.0, d.z)
    p.z += 0.26 * front ** 1.3                    # the long snout
    p.x *= 1.0 - 0.38 * front ** 1.2
    p.y *= 1.0 - 0.32 * front
    q = p.copy()
    off = 0.0
    for s2 in (1, -1):
        off += 0.035 * blob3(q, (0.085 * s2, 0.1, 0.12), (0.05, 0.025, 0.07))    # brow ridges
        off += 0.03 * blob3(q, (0.05 * s2, 0.05, 0.44), (0.035, 0.03, 0.04))     # nostril bulbs
        off += 0.02 * blob3(q, (0.15 * s2, -0.04, 0.0), (0.04, 0.05, 0.06))      # cheeks
    off += 0.02 * blob3(q, (0, 0.11, 0.3), (0.03, 0.02, 0.1))                    # nose ridge
    return p + p.normalized() * off


morph_sphere(b, hf.c, skull, lambda p, d: (0.78 + 0.12 * d.y,) * 3, cls=SCALE, bone=hb, seg=28, rings=18, tint_fn=lambda p, d: 1.0, rot=hf.M)
for s in (1, -1):
    b.ellipsoid(hf.at(0.05 * s, 0.06, 0.47), (0.02, 0.018, 0.012), "200810", cls=SKIN, bone=hb, seg=8, rings=5, mat=MAT_PLAIN)
    b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # cheek spikes swept back
    for k in range(3):
        root = hf.at(0.16 * s, -0.02 - k * 0.04, 0.02 - k * 0.03)
        b.cone(root + hf.M @ V(0.05 * s, 0, -0.08), 0.02, 0.16 - k * 0.03, (0.6, 0.6, 0.6), cls=STONE, bone=hb, seg=6, rot=(-1.3, 0.5 * s, 0), tint=1.0)
    b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # ox ears
    ear = [hf.at(0.15 * s, 0.1, -0.06), hf.at(0.24 * s, 0.12, -0.1), hf.at(0.3 * s, 0.1, -0.14)]
    b.tube(ear, [(0.045, 0.012), (0.04, 0.01), (0.004, 0.003)], (0.6, 0.6, 0.6), cls=SCALE, bone=hb, seg=8, up=(0, 1, 0), tint=1.0)
    # deer antlers: a curved main beam with three tines
    a0 = hf.at(0.08 * s, 0.17, 0.02)
    beam = [a0, a0 + V(0.1 * s, 0.18, -0.08), a0 + V(0.16 * s, 0.34, -0.22), a0 + V(0.14 * s, 0.46, -0.38)]
    strand(b, beam, 0.03, 0.006, "e8d8a8", col_tip="fff4d8", cls=STONE, bone=hb, seg=8, per=4)
    for k, (tt, dv) in enumerate(((0.3, V(0.03 * s, 0.14, 0.08)), (0.55, V(0.12 * s, 0.1, 0.04)), (0.8, V(-0.02 * s, 0.14, 0.04)))):
        q = beam[int(tt * 3)].lerp(beam[min(3, int(tt * 3) + 1)], (tt * 3) % 1.0)
        strand(b, [q, q + dv * 0.5 + V(0, 0.02, 0), q + dv], 0.014, 0.003, "e8d8a8", col_tip="fff4d8", cls=STONE, bone=hb, seg=6, per=3)
    # long drooping whiskers from the upper lip
    w0 = hf.at(0.08 * s, 0.0, 0.44)
    strand(b, [w0, w0 + V(0.18 * s, -0.02, 0.05), w0 + V(0.36 * s, -0.2, -0.05), w0 + V(0.46 * s, -0.48, -0.2), w0 + V(0.5 * s, -0.62, -0.32)], 0.012, 0.002, "f0e0a0", cls=HAIR, bone=hb, seg=6, per=4)
    b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # cheek mane
    for k in range(5):
        root = hf.at(0.16 * s, 0.02 - k * 0.035, -0.02 - k * 0.04)
        strand(b, [root, root + V(0.12 * s, -0.04, -0.1), root + V(0.22 * s, -0.12 - k * 0.03, -0.28)], 0.035, 0.003, (0.45, 0.45, 0.45), col_tip=(0.85, 0.85, 0.85), cls=HAIR, bone=hb, flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# beard under the chin
for k in range(7):
    u = (k / 6 - 0.5)
    root = hf.at(u * 0.12, -0.1, 0.22 - abs(u) * 0.1)
    strand(b, [root, root + V(0, -0.1, 0.02), root + V(u * 0.06, -0.22, -0.02)], 0.022, 0.002, (0.55, 0.55, 0.55), col_tip=(0.9, 0.9, 0.9), cls=HAIR, bone="jaw", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
eyes(b, hf.at(0, 0.09, 0.16), 0.115, 0.036, iris="ffcf30", bone=hb, slit=True, glow=True, rot_y=0.8, h=0.75)
# rows of teeth along both jaws
for k in range(6):
    z = 0.42 - k * 0.055
    for s in (1, -1):
        x = (0.07 - k * 0.002) * s * (1.0 + k * 0.08)
        fangs(b, [hf.at(x, -0.07, z)], 0.07 if k == 0 else 0.035, hb)
        fangs(b, [hf.at(x * 0.95, -0.1, z - 0.02)], 0.05 if k == 0 else 0.03, "jaw", down=False)
# lower jaw with a tongue
b.ellipsoid(hf.at(0, -0.12, 0.26), (0.1, 0.04, 0.22), (0.95, 0.95, 0.95), cls=SCALE, bone="jaw", tint=1.0, seg=14, rings=6)
b.ellipsoid(hf.at(0, -0.095, 0.25), (0.07, 0.012, 0.18), "c03040", cls=SKIN, bone="jaw", seg=10, rings=4)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# legs: muscled upper limbs, scaled forearms, flame tufts at the elbows and eagle talons
for li in (0, 1):
    for s, sd in ((1, "L"), (-1, "R")):
        lg = "leg%d.%s" % (li, sd)
        ft = "foot%d.%s" % (li, sd)
        h, kn, an = r.head(lg), r.tail(lg), r.tail(ft)
        b.tube([h - V(0.06 * s, -0.04, 0), h, h.lerp(kn, 0.5), kn], [0.07, 0.07, 0.06, 0.045], (0.7, 0.7, 0.7), cls=SCALE, bones=[{lg: 0.5, "seg1" if li == 0 else "seg6": 0.5}, lg, lg, {lg: 0.5, ft: 0.5}], tint=1.0, seg=12)
        b.tube([kn, kn.lerp(an, 0.5), an], [0.045, 0.04, 0.035], (0.75, 0.75, 0.75), cls=SCALE, bone=ft, tint=1.0, seg=10)
        for k in range(4):
            root = kn + V(0, 0.01 * k, -0.01 * k)
            strand(b, [root, root + V(0.04 * s, 0.02, -0.08), root + V(0.08 * s, 0.06 - 0.03 * k, -0.18)], 0.025, 0.002, (0.5, 0.5, 0.5), col_tip=(0.9, 0.9, 0.9), cls=HAIR, bone=lg, flat=0.35, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
        # four talons: three forward, one back, each a jointed toe ending in a hooked claw
        for k in range(4):
            a = (k - 1) * 0.5 if k < 3 else math.pi
            d = V(math.sin(a), 0, math.cos(a))
            t0 = an + V(0, -0.02, 0)
            t1 = t0 + d * 0.05 + V(0, -0.02, 0)
            t2 = t1 + d * 0.04 + V(0, -0.015, 0)
            b.tube([t0, t1, t2], [0.016, 0.013, 0.011], (0.8, 0.8, 0.8), cls=SCALE, bone=ft, tint=1.0, seg=6)
            strand(b, [t2, t2 + d * 0.03 + V(0, 0.005, 0), t2 + d * 0.045 - V(0, 0.03, 0)], 0.009, 0.001, "f0e8d8", cls=STONE, bone=ft, seg=5, per=3)
# the pearl of wisdom it chases, held under the chin
b.ball(hf.at(0, -0.25, 0.42), 0.06, "ffffff", cls=CRYSTAL, bone="jaw", seg=14, rings=10, mat=MAT_GLOW, tint=0.3)

T_IDLE = 3.0


def idle(t, amp=1.0):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, math.sin(t * w) * 0.1, 0))
    for i in range(N):
        p["seg%d" % i] = ((math.sin(t * w - i * 0.7) * 0.05 * amp, math.sin(t * w - i * 0.6) * 0.13 * amp, math.sin(t * w * 2 - i * 0.5) * 0.04), (0, 0, 0))
    p["head"] = ((math.sin(t * w) * 0.08, -math.sin(t * w - 0.0) * 0.1, 0), (0, 0, 0))
    p["jaw"] = ((0.1 + 0.08 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    for li in (0, 1):
        for sd, s in (("L", 1), ("R", -1)):
            p["leg%d.%s" % (li, sd)] = ((math.sin(t * w + li) * 0.2, 0, 0), (0, 0, 0))
            p["foot%d.%s" % (li, sd)] = ((0.3 + math.sin(t * w + li + 1) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0, 0.5)
    p["root"] = ((0, 0, 0), (0, -0.1 * lunge, 0.5 * lunge))
    p["seg0"] = ((0.25 * e - 0.35 * lunge, 0, 0), (0, 0, 0))
    p["seg1"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["head"] = ((0.3 * lunge - 0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.9 * lunge, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0, 0.5)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.25 * e))
    p["seg0"] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["seg1"] = ((-0.2 * e, 0.15 * e, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0.2 * e), (0, 0, 0))
    p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 1.0 + e)
    p["root"] = ((0, 0, 0), (0, 0.25 * e, 0))
    p["seg0"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((1.0 * e, 0, 0), (0, 0, 0))
    return p


print("[art] dragon: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/dragon.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.45)
